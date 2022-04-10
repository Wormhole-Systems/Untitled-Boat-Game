local MAX_BOARDING_DISTANCE = 10
local SEAT_TAG = "Seat"

local Collections = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local canBoard = script:WaitForChild("CanBoard")
local player = game.Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()
local ads = player:WaitForChild("ADS")
local needsVehicleMouse = player:WaitForChild("NeedsVehicleMouse")

local isOnMobile = game:GetService("UserInputService").TouchEnabled
local gameTools = require(game:GetService("ReplicatedFirst").GameTools)

local seats = Collections:GetTagged(SEAT_TAG)

local nearestSeat
local lastInfoBillboardGui

local guiProto = player.PlayerGui.BoardingGui
local gui
local TWEEN_TIME = .2

local vehiclesFolder = game.Workspace:WaitForChild("Vehicles")
local notSpeedBasedVehicleSounds = {
	Helicopter = true,
	Chinook = true,
	Hovercraft = true,
	Submarine = true
}

--add a new seat to seats when a new seat is detected in the world
Collections:GetInstanceAddedSignal(SEAT_TAG):Connect(function (newSeat)
	table.insert(seats, newSeat)
end)

--refreshes seats when a seat is removed from the world
Collections:GetInstanceRemovedSignal(SEAT_TAG):Connect(function ()
	seats = Collections:GetTagged(SEAT_TAG)
end)

--recalculates the nearest seat
local function getNearestSeat()
	local nearest = nil
	local nearestDist = MAX_BOARDING_DISTANCE
	for _, v in pairs (seats) do
		if not v.Occupant then
			local dist = (humanoidRootPart.Position - v.Position).Magnitude
			if dist < nearestDist then
				nearest = v
				nearestDist = dist
			end
		end
	end
	return nearest
end

--get on the nearest seat
local function boardVehicle(name, state, input)
	if state == Enum.UserInputState.Begin and canBoard.Value then
		nearestSeat = getNearestSeat()
		if nearestSeat and (not nearestSeat.Occupant) and humanoid.Health > 0 then
			nearestSeat:Sit(humanoid)
		end
	end
end

humanoid:GetPropertyChangedSignal("Sit"):Connect(function ()
	canBoard.Value = not humanoid.Sit
end)

if not isOnMobile then
	ContextActionService:BindAction("Board", boardVehicle, false, Enum.KeyCode.E)
end

--puts ths ui away
local function clearGui()
	if gui then
		local tweenfo = TweenInfo.new(TWEEN_TIME)
		local tween = TweenService:Create(gui, tweenfo, {Size = UDim2.new(0,0,0,0)})
		local toDelete = gui
		tween.Completed:Connect(function()
			toDelete.Enabled = false
			toDelete:Destroy()
			tween:Destroy()
		end)
		tween:Play()
		gui = nil
		
		if isOnMobile then
			ContextActionService:UnbindAction("BoardMobile")
		end
	end
end

--updates the ui
local function updateNearestDisplay()
	local newNear = getNearestSeat()
	if newNear and canBoard.Value then
		if newNear ~= nearestSeat then 
			--put code here
			
			--tween stuff
			clearGui()
			gui = guiProto:Clone()
			gui.Enabled = true
			gui.Size = UDim2.new(0,0,0,0)
			gui.Adornee = newNear
			gui.Parent = guiProto.Parent
			local tweenfo = TweenInfo.new(TWEEN_TIME)
			local tween = TweenService:Create(gui, tweenfo, {Size = UDim2.new(3,0,3,0)})
			tween.Completed:Connect(function()
				tween:Destroy()
			end)
			tween:Play()
			
			
			if isOnMobile then
				ContextActionService:UnbindAction("BoardMobile")
				ContextActionService:BindAction("BoardMobile", boardVehicle, true)
			end
		end
	else
		--put the ui away
		clearGui()
	end
	nearestSeat = newNear
	
	-- Vehicle information popup
	if lastInfoBillboardGui and not lastInfoBillboardGui.Active then
		lastInfoBillboardGui.Enabled = false
	end
	if ads.Value or needsVehicleMouse.Value then
		local target = mouse.Target
		local infoBillboardGui
		if target and target:IsDescendantOf(game.Workspace.Vehicles) then
			while target ~= game.Workspace do
				if target:FindFirstChild("Engine") and target.Engine:FindFirstChildOfClass("BillboardGui") then
					if humanoid.SeatPart and target.Name == player.Name then
						break
					end
					infoBillboardGui = target.Engine:FindFirstChildOfClass("BillboardGui")
					break
				end
				target = target.Parent
			end
		elseif target and target.Parent and (target.Parent:FindFirstChildOfClass("Humanoid") or  (target.Parent.Parent and target.Parent.Parent:FindFirstChildOfClass("Humanoid"))) then
			local hum = target.Parent:FindFirstChildOfClass("Humanoid") or target.Parent.Parent:FindFirstChildOfClass("Humanoid")
			if hum ~= humanoid and hum.SeatPart and hum.SeatPart.Parent:FindFirstChild("Engine") and hum.SeatPart.Parent.Engine:FindFirstChildOfClass("BillboardGui") then
				infoBillboardGui =  hum.SeatPart.Parent.Engine:FindFirstChildOfClass("BillboardGui")
			end
		end
		lastInfoBillboardGui = infoBillboardGui
		if infoBillboardGui then
			infoBillboardGui.Enabled = true
		end
	end
	
	-- Vehicle sounds
	local vehicles = vehiclesFolder:GetChildren()
	for i = 1, #vehicles do
		local vehicle = vehicles[i]
		if vehicle.Name ~= player.Name then
			local engineSound = vehicle.PrimaryPart and vehicle.PrimaryPart:FindFirstChildOfClass("Sound")
			local speed = vehicle.PrimaryPart and vehicle.PrimaryPart.Velocity.Magnitude or 0
			if engineSound then
				if vehicle:FindFirstChild("Configuration") then
					local vehicleType = vehicle.Configuration.Type.Value
					if notSpeedBasedVehicleSounds[vehicleType] then
						if vehicle.Driver.Occupant then
							if not engineSound.IsPlaying then engineSound.PlaybackSpeed = 0.5 engineSound:Play() end
							engineSound.PlaybackSpeed = math.clamp(engineSound.PlaybackSpeed + 0.001, 0.5, 1)
							engineSound.Volume = math.clamp(engineSound.PlaybackSpeed, 0, 1)
						else
							if engineSound.Volume > 0 then
								engineSound.PlaybackSpeed = math.clamp(engineSound.PlaybackSpeed - 0.001, 0.5, 1)
								engineSound.Volume = 4 * engineSound.PlaybackSpeed - 1
							else
								engineSound:Stop()
							end
						end
					else
						if not engineSound.IsPlaying then engineSound:Play() end
						local speedRation = speed/vehicle.Configuration.MaxForwardSpeed.Value
						engineSound.PlaybackSpeed = speedRation + (vehicleType ~= "Spy Plane" and 1 or 0)
						engineSound.Volume = engineSound.PlaybackSpeed + (vehicleType ~= "Spy Plane" and 0.5 or 0)
						engineSound.MaxDistance = math.abs(speedRation) * 10000 + 100
					end
				end
			else
				local sound = vehicle:FindFirstChild("Engine") and vehicle.Engine:FindFirstChildOfClass("Sound")
				if sound and not sound.IsPlaying then
					sound:Play()
				end
			end
			
			if vehicle:FindFirstChild("Particle") then
				local particle = vehicle.Particle.ParticleEmitter
				if notSpeedBasedVehicleSounds[vehicle.Configuration.Type.Value] then
					if engineSound then
						particle.Enabled = engineSound.Volume > 0
					else
						particle.Enabled = speed > 0
					end
				end
				if particle.Enabled then
					local maxForwardSpeed = vehicle.Configuration.MaxForwardSpeed.Value
					particle.SpreadAngle = Vector2.new(gameTools.pointSlope({0, 45}, {maxForwardSpeed, 22.5}, speed), 22.5)
					local speedMin = gameTools.pointSlope({0, 0}, {maxForwardSpeed, 20}, speed)
					local speedMax = gameTools.pointSlope({0, 0}, {maxForwardSpeed, 30}, speed)
					particle.Speed = NumberRange.new(speedMin, speedMax)
					local lifeMin = gameTools.pointSlope({0, 0.1}, {maxForwardSpeed, .75}, speed)
					local lifeMax = gameTools.pointSlope({0, 0.2}, {maxForwardSpeed, 1}, speed)
					particle.Lifetime = NumberRange.new(lifeMin, lifeMax)
				end
			end
		end
	end
end


--every engine tick we recalculate the nearest seat
local connection = RunService.RenderStepped:Connect(updateNearestDisplay)
humanoid.Died:Connect(function()
	if lastInfoBillboardGui and not lastInfoBillboardGui.Active then
		lastInfoBillboardGui.Enabled = false
	end
	clearGui()
	connection:Disconnect()
end)


