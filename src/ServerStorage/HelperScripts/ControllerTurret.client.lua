-- Constants
local BASE_ANGLE_DELTA = CFrame.Angles(0, math.pi, math.pi/2)

-- Services
local UserInputService = game:GetService("UserInputService")
local ContextAction = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local invokers = ReplicatedStorage.Invokers.Weapon

local fireModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Framework.FireWeaponClientModule)

-- Player and character
local player = game.Players.LocalPlayer
local character = script.Parent
local camera = game.Workspace.CurrentCamera
local mouse = player:GetMouse()

-- Hinge constraints
local pivotConstraint = script:WaitForChild("PivotConstraintObject").Value
local verticalConstraint = script:WaitForChild("VerticalConstraintObject").Value

-- Base part that turret is pivoting on
local base = pivotConstraint.Attachment1.Parent

-- Reference to the turret
local turret = pivotConstraint.Attachment0.Parent.Parent
local gun = turret
local isVehicleTurret = turret.Parent:FindFirstChildOfClass("VehicleSeat") ~= nil
local seat = turret.Seat
local config = turret.Configuration
local reloading = config.Reloading
local module = require(config.Module.Value)
local magState = config.MagStateClient

local rotateVehicleTurretServer, vehicleOwner
if isVehicleTurret then
	rotateVehicleTurretServer = ReplicatedStorage.Invokers.Weapon.RotateVehicleTurretServer
	vehicleOwner = turret.Parent.Configuration.Owner
end

--the way we can tell the player has dismounted the turret
local dismountEvent = script:WaitForChild("Disable").Changed

-- All event connections
local connections = {}

-- Micro-Optimizations
local deg = math.deg
local atan2 = math.atan2

local equipped = false

local equipADSAnim = nil
local equipIdleAnim = nil
local fireAnim = nil
local reloadAnim = nil
local animations = {equipADSAnim, equipIdleAnim, fireAnim, reloadAnim}

-- Filter everything in case something comes in between and messes up the angle calculation
mouse.TargetFilter = workspace

-- Rotates turret based on mouse hit position
local function rotateTurret()
	local targetPosition = mouse.Hit.Position
	if targetPosition then
		local objectSpacePosition = (base.CFrame * BASE_ANGLE_DELTA):PointToObjectSpace(targetPosition)
		pivotConstraint.TargetAngle = deg(atan2(-objectSpacePosition.X, -objectSpacePosition.Z))
		verticalConstraint.TargetAngle = -deg(atan2(objectSpacePosition.Y, (objectSpacePosition.X^2 + objectSpacePosition.Z^2)^0.5))
		if isVehicleTurret and vehicleOwner.Value ~= player then
			rotateVehicleTurretServer:FireServer(turret, pivotConstraint.TargetAngle, verticalConstraint.TargetAngle)
		end
	end
end

local function playAnimation(anim) -- send nothing to stop all animations
	for _, a in pairs(animations) do
		if a ~= anim then
			a:Stop()
		end
	end
	if anim then anim:Play() end
end

local function tryAttack()
	shared.lastShot = tick()
	
	local tock = tick() * 10000
	
	--local activeAnim = magState.Value == 0 and reloadAnim or fireAnim
	local magStateBeforeFiring
	--[[
	if activeAnim == reloadAnim then
		playAnimation(activeAnim)
	else
 		magStateBeforeFiring = magState.Value
	end
	
	]]
	fireModule.FireWeaponLocal(player, turret, camera.CFrame, tock)
	--fireModule.FireWeaponLocal(player, turret, turret.Barrel.CFrame, tock)
	
	--[[
	if activeAnim ~= reloadAnim and magState.Value ~= magStateBeforeFiring then
		playAnimation(activeAnim)
	end
	activeAnim.Stopped:Wait()
	if equipped then
		playAnimation(equipIdleAnim)
	end
	]]
	
end

local function firePrimary(actionName, inputState, inputObj)
	if (inputState == Enum.UserInputState.Begin) then
		
		local firing = true 
		
		local stopConnection
		local unequipStop
		local reloadStop
		
		local function stopFiring()
			ContextAction:UnbindAction("StopShooting")
			unequipStop:Disconnect()
			reloadStop:Disconnect()
			firing = false
		end
		
		ContextAction:BindAction(
			"StopShooting",
			function(actName, inpState, inpObj)
				if inpState == Enum.UserInputState.End then
					stopFiring()
				end
				--print("Change detected ".. tostring(inpState))
			end,
			false,
			Enum.UserInputType.MouseButton1)
			
			unequipStop = dismountEvent:Connect(stopFiring)
			reloadStop = reloading.Changed:Connect(function (val)
			if val then
				stopFiring()
			end
		end)
		
		repeat
			spawn(function() tryAttack() end)
			
			if magState.Value <= 0 then
				stopFiring()
			end
			wait(1/module.AttackSpeed)
		until not firing
	end
end

local function reload(actionName, inputState, inputObj)
	if (inputState == Enum.UserInputState.Begin) then
		fireModule.ReloadWeaponLocal(player, gun)
		
		--playAnimation(reloadAnim)
		--reloadAnim.Stopped:Wait()
		if equipped then
			--playAnimation(equipIdleAnim)
		end
		
	end
end

local function playerEnter()
	--tracks = module:Initialize(humanoid)
	equipped = true
	
	-- Set sitting animation to be of one with hands out
	--character.Animate.sit.SitAnim.AnimationId = "rbxassetid://4536805497"
	
	ContextAction:BindAction("ShootPrimary", firePrimary, true, Enum.UserInputType.MouseButton1)
	ContextAction:BindAction("Reload", reload, true, Enum.KeyCode.R)
end

-- For mobile control
if not UserInputService.KeyboardEnabled then
	connections[#connections + 1] = mouse.Move:Connect(rotateTurret)
end

-- Rotate the turret accordingly whenever the mouse moves
connections[#connections + 1] = mouse.Idle:Connect(rotateTurret)

-- Cleanup before destroying
connections[#connections + 1] = dismountEvent:Connect(function()
	mouse.TargetFilter = nil
	
	-- Set sitting animation back to normal
	--character.Animate.sit.SitAnim.AnimationId = "rbxassetid://2506281703"
	
	-- Disonnect all connections
	for _, v in pairs(connections) do
		v:Disconnect()
	end
	connections = {}
	script:Destroy()
end)

playerEnter()