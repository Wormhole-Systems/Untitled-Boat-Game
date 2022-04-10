local Vehicle = {}
Vehicle.__index = Vehicle

local gameTools = require(game:GetService("ReplicatedFirst").GameTools)

-- Local Player
local localPlayer = game.Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local needsVehicleMouse = localPlayer:WaitForChild("NeedsVehicleMouse")
local camera = game.Workspace.CurrentCamera

-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local HIGH_HEALTH_COLOR = Color3.new(0, 170, 0)
local MEDIUM_HEALTH_COLOR = Color3.new(255, 85, 0)
local LOW_HEALTH_COLOR = Color3.new(170, 0, 0)

-- Micro-Optimizations
local clamp = math.clamp
local rad = math.rad
local sin = math.sin
local floor = math.floor
local fromEulerAnglesYXZ = CFrame.fromEulerAnglesYXZ
local Vector3_new = Vector3.new
local CFrameNew = CFrame.new()
local solveIK

function Vehicle.new(model)
	local newVehicle = {}
	setmetatable(newVehicle, Vehicle)	
	
	-- Class Attributes
	local configFolder = model.Configuration
	newVehicle.Model = model
	newVehicle.TurnRadius = rad(configFolder.TurnRadiusDegrees.Value)
	newVehicle.RotationAngle = configFolder.PitchRotationDegrees.Value
	newVehicle.MaxReverseSpeed = -configFolder.MaxReverseSpeed.Value
	newVehicle.MaxForwardSpeed = configFolder.MaxForwardSpeed.Value
		
	-- Values Used For Calculating Movement
	newVehicle.Yaw = 0
	newVehicle.CurrentSpeed = 0
	newVehicle.CurrentAltitude = 0
	newVehicle.ForwardRotationDirection = 1
	
	-- Specific Vehicle Attributes
	newVehicle.DriverSeat = newVehicle.Model:WaitForChild("Driver")
	newVehicle.Engine = newVehicle.Model:WaitForChild("Engine")
	newVehicle.EngineSound = newVehicle.Model.Hull:FindFirstChildOfClass("Sound")
	newVehicle.Particle = newVehicle.Model:FindFirstChild("Particle") and newVehicle.Model.Particle.ParticleEmitter
	newVehicle.BodyPosition = newVehicle.Engine:WaitForChild("BodyPosition")
	newVehicle.BodyVelocity = newVehicle.Engine:WaitForChild("BodyVelocity")
	newVehicle.BodyGyro = newVehicle.Engine:WaitForChild("BodyGyro")
	newVehicle.OriginalCFrame = newVehicle.Engine.CFrame
	newVehicle.BodyGyro.CFrame = newVehicle.Engine.CFrame
	newVehicle.BodyPosition.Position = newVehicle.Engine.CFrame.p
	
	-- Values for determing if the vehicle can move
	local size = model:GetExtentsSize()
	local vehicleCFrame = model:GetBoundingBox()
	local engineCFrame = newVehicle.Engine.CFrame
	local frontCheckCFrame = vehicleCFrame * CFrame.new(0, -size.Y/2, -size.Z/2)
	local backCheckCFrame = vehicleCFrame * CFrame.new(0, -size.Y/2, size.Z/2)
	--print(frontCheckCFrame.p, ";", backCheckCFrame.p)
	newVehicle.FrontCheckVector = engineCFrame:PointToObjectSpace(frontCheckCFrame.p)
	newVehicle.BackCheckVector = engineCFrame:PointToObjectSpace(backCheckCFrame.p)
	
	-- Constitutes whether the vehicle should be moving or not
	newVehicle.Running = true
	newVehicle.StartedUp = true
	
	-- Calculate and set vehicle mass
	newVehicle.Mass = 0
	for _, v in pairs(newVehicle.Model:GetDescendants()) do
		if v:IsA("BasePart") then
			newVehicle.Mass = newVehicle.Mass + v:GetMass()
		end
	end
	
	-- Set up the rotors (if any)
	newVehicle.RotorSpeed = 0
	newVehicle.Rotors = {}
	for _, v in pairs(newVehicle.Model:GetChildren()) do
		if v:FindFirstChildOfClass("HingeConstraint") then
			table.insert(newVehicle.Rotors, v)
		end 
	end
	if #newVehicle.Rotors == 0 then newVehicle.Rotors = nil end
	
	-- Entering/exiting driver or pilot seat
	local cameraDistance = configFolder.CameraDistance.Value
	local function driverSeatChanged()
		if newVehicle.DriverSeat.Occupant 
		   and localPlayer == Players:GetPlayerFromCharacter(newVehicle.DriverSeat.Occupant.Parent) then
			CollectionService:AddTag(model, "IgnoreCamera")
			mouse.TargetFilter = newVehicle.Model
		else
			if localPlayer.Character and not localPlayer.Character.Humanoid.SeatPart then
				CollectionService:RemoveTag(model, "IgnoreCamera")
				mouse.TargetFilter = nil
				camera.FieldOfView = 70
			end
		end
	end
	driverSeatChanged()
	newVehicle.SeatOccoupantChangedConn = newVehicle.DriverSeat:GetPropertyChangedSignal("Occupant"):Connect(driverSeatChanged)
		
	return newVehicle
end

function Vehicle:Initialize()
	spawn(function()
		-- Keep track of values for the "bounce" effect
		local x, frequency, maxHeight = 0, 2, 0.25
		local throttleChangedConn = self.DriverSeat:GetPropertyChangedSignal("Throttle"):Connect(function()
			if not self.StartedUp then return end
			if self.DriverSeat.Throttle == 0 then
				x = 0
				frequency = 2
				maxHeight = 0.25
				--TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = 70}):Play()
			else
				frequency = 8
				maxHeight = 0.5
				--TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = 85}):Play()
			end
		end)
		
		local particle, engineSound = self.Particle, self.EngineSound
		-- While the vehicle is not destroyed
		while self.Running do
			local t = RunService.Heartbeat:Wait()
			
			-- Check if the vehicle can move first
			local canMove, hitSurfaceNormal = self:CheckIfCanMove(self.DriverSeat.Throttle)
			-- Handle Throttling and Inertia
			if canMove then
				if self.DriverSeat.Throttle > 0 and self.StartedUp then
					self:Accelerate()
				elseif self.DriverSeat.Throttle < 0 and self.StartedUp then
					self:Decelerate()
				else
					self:Stop()
				end
				
				-- FOV adjustments based on speed
				if self.DriverSeat.Occupant then
					camera.FieldOfView = 70 + 15*(self.CurrentSpeed >= 0 and self.CurrentSpeed/self.MaxForwardSpeed or self.CurrentSpeed/self.MaxReverseSpeed)
				end
			else
				-- force stop if trying to move into a part
				self.CurrentSpeed = 0
				TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = 70}):Play()
			end
						
			-- Move the boat in the direction at its looking with the newly throttled speed
			self:Move(self.Engine.CFrame.LookVector * self.CurrentSpeed)
			
			if self.StartedUp then
				-- Calculate how much the boat has turned left or right from the original orientation
				self.Yaw = self.Yaw - self.TurnRadius * self.DriverSeat.SteerFloat * (self.DriverSeat.Throttle >= 0 and 1 or -1)
				-- Get pitch and roll values as well
				local pitch = rad(self.DriverSeat.ThrottleFloat * self.RotationAngle * self.CurrentSpeed/self.MaxForwardSpeed) * self.ForwardRotationDirection
				local roll = -rad(self.DriverSeat.SteerFloat * self.RotationAngle)
				-- Control the gyro of the boat
				self:Rotate(self.DriverSeat.Throttle > 0 and pitch or pitch/2, self.Yaw, roll)
				
				-- Adjust altitude
				self.BodyPosition.Position = Vector3_new(0, self.CurrentAltitude + sin(frequency * x) * maxHeight + maxHeight/3, 0)
				x = x + t -- increment time
			else
				self:Rotate(0, self.Yaw, 0)
			end
			
			-- Particle effect
			if particle and self.CurrentSpeed > 0 then
				particle.SpreadAngle = Vector2.new(gameTools.pointSlope({0, 45}, {self.MaxForwardSpeed, 22.5}, self.CurrentSpeed), 22.5)
				local speedMin = gameTools.pointSlope({0, 0}, {self.MaxForwardSpeed, 20}, self.CurrentSpeed)
				local speedMax = gameTools.pointSlope({0, 0}, {self.MaxForwardSpeed, 30}, self.CurrentSpeed)
				particle.Speed = NumberRange.new(speedMin, speedMax)
				local lifeMin = gameTools.pointSlope({0, 0.1}, {self.MaxForwardSpeed, .75}, self.CurrentSpeed)
				local lifeMax = gameTools.pointSlope({0, 0.2}, {self.MaxForwardSpeed, 1}, self.CurrentSpeed)
				particle.Lifetime = NumberRange.new(lifeMin, lifeMax)
			end
			
			-- Sound
			if engineSound then
				if not self.Rotors then
					if not engineSound.IsPlaying then
						engineSound:Play()
					end
					engineSound.PlaybackSpeed = self.CurrentSpeed/self.MaxForwardSpeed + 1
					engineSound.Volume = engineSound.PlaybackSpeed + 0.5
				end
				engineSound.MaxDistance = math.abs(self.CurrentSpeed)/self.MaxForwardSpeed * 10000 + 100
			end
		end
		
		-- Disconnect any event connections to prevent memory leaks
		throttleChangedConn:Disconnect()
		if self.AltitudeChangedConn then
			self.AltitudeChangedConn:Disconnect()
		end
		if self.ShootMissileConn then
			self.ShootMissileConn:Disconnect()
		end
	end)
end

--------------------------------
--[[ Helper Functions Below ]]--
--------------------------------

function Vehicle:Destroy(shouldDestroyModel)
	self.StartedUp = false
	if not shouldDestroyModel then
		-- Wait for it to stop moving, then terminate the vehicle's main thread
		repeat wait() until self.CurrentSpeed <= 0
	end
	self.Running = false -- terminate the loop in the thread
	if self.Particle then
		self.Particle.Enabled = false
	end
	if self.DriverSeatChanged then -- make an aerial vehicle fall
		self.DriverSeatChanged()
	end
	if self.StartUpChangedConn then
		self.StartUpChangedConn:Disconnect()
	end
	if self.misslePermissionConn then
		self.misslePermissionConn:Disconnect()
	end
	if self.fireMissileConn then
		self.fireMissileConn:Disconnect()
	end
	self.SeatOccoupantChangedConn:Disconnect()
	if localPlayer.Character then
		camera.FieldOfView = 70
		localPlayer.CameraMinZoomDistance = 10
		delay(0.1, function() localPlayer.CameraMaxZoomDistance = 10 end)
	end
	
	if shouldDestroyModel then
		self.Model:Destroy()
	end
	mouse.TargetFilter = nil
	self = nil
end

function Vehicle:CheckIfCanMove(dir)
	if dir == 0 then return true end
	
	local engineCFrame = self.Engine.CFrame
	local ray = Ray.new(engineCFrame:PointToWorldSpace(dir > 0 and self.FrontCheckVector or self.BackCheckVector), (engineCFrame.LookVector - Vector3.new(0, 0.5, 0)).Unit * dir * 2)
	local hit, _, surfaceNormal = workspace:FindPartOnRay(ray, self.Model, false, true)

	return hit == nil or not hit.CanCollide, surfaceNormal
end

function Vehicle:Move(direction)
	self.BodyVelocity.Velocity = direction
end

function Vehicle:Rotate(pitch, yaw, roll)
	self.BodyGyro.CFrame = self.OriginalCFrame * fromEulerAnglesYXZ(pitch, yaw, roll)
end

function Vehicle:Accelerate()
	self.CurrentSpeed = clamp(self.CurrentSpeed + 0.5 * self.DriverSeat.ThrottleFloat, self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function Vehicle:Decelerate()
	self.CurrentSpeed = clamp(self.CurrentSpeed + self.DriverSeat.ThrottleFloat, self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function Vehicle:Stop()
	self.CurrentSpeed = floor(self.CurrentSpeed > 0 and self.CurrentSpeed - 1 or self.CurrentSpeed < 0 and self.CurrentSpeed + 1 or 0)
end



return Vehicle