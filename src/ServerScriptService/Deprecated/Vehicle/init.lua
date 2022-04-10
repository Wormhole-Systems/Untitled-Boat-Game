local Vehicle = {}
Vehicle.__index = Vehicle

-- Services
local RunService = game:GetService("RunService")

-- Constants
local HIGH_HEALTH_COLOR = Color3.new(0, 170, 0)
local MEDIUM_HEALTH_COLER = Color3.new(255, 85, 0)
local LOW_HEALTH_COLOR = Color3.new(170, 0, 0)

-- Micro-Optimizations
local clamp = math.clamp
local rad = math.rad
local sin = math.sin
local floor = math.floor
local fromEulerAnglesYXZ = CFrame.fromEulerAnglesYXZ
local Vector3_new = Vector3.new

function Vehicle.new(model, spawnCFrame, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	local newVehicle = {}
	setmetatable(newVehicle, Vehicle)	
	
	-- Class Attributes
	newVehicle.Model = newVehicle:Spawn(model, spawnCFrame)
	newVehicle.TurnRadius = turnRadius and rad(turnRadius) or rad(1)
	newVehicle.RotationAngle = rotationAngle or 5
	newVehicle.MaxReverseSpeed = maxReverseSpeed or -20
	newVehicle.MaxForwardSpeed = maxForwardSpeed or 100
	newVehicle.MaxHealth = maxHealth or 100
	newVehicle.CurrentHealth = maxHealth or 100
		
	-- Values Used For Calculating Movement
	newVehicle.Yaw = 0
	newVehicle.CurrentSpeed = 0
	newVehicle.CurrentAltitude = 0
	newVehicle.ForwardRotationDirection = 1
	
	-- Specific Vehicle Attributes
	newVehicle.DriverSeat = newVehicle.Model:WaitForChild("Driver")
	newVehicle.Engine = newVehicle.Model:WaitForChild("Engine")
	newVehicle.TakeDamageEvent = newVehicle.Model:WaitForChild("TakeDamage")
	newVehicle.HealthBar = newVehicle.Engine:WaitForChild("Info"):WaitForChild("Health")
	newVehicle.BodyPosition = newVehicle.Engine:WaitForChild("BodyPosition")
	newVehicle.BodyVelocity = newVehicle.Engine:WaitForChild("BodyVelocity")
	newVehicle.BodyGyro = newVehicle.Engine:WaitForChild("BodyGyro")
	newVehicle.OriginalCFrame = newVehicle.Engine.CFrame
	newVehicle.BodyGyro.CFrame = newVehicle.Engine.CFrame
	newVehicle.BodyPosition.Position = newVehicle.Engine.CFrame.p
	
	
	-- Event handling
	newVehicle:HandleEnvironmentalEvents()
	
	-- Constitutes whether the vehicle should be moving or not
	newVehicle.Running = true
	newVehicle.StartedUp = true
	
	return newVehicle
end

function Vehicle:Initialize()
	spawn(function()
		-- Keep track of values for the "bounce" effect
		local x, frequency, maxHeight = 0, 2, 0.25
		local throttleChangedConn = self.DriverSeat:GetPropertyChangedSignal("Throttle"):Connect(function()
			if self.DriverSeat.Throttle == 0 then
				x = 0
				frequency = 2
				maxHeight = 0.25
			else
				frequency = 8
				maxHeight = 0.5
			end
		end)
		
		-- While the vehicle is not destroyed
		while self.Running do
			local t = RunService.Heartbeat:Wait()
			
			-- Handle Throttling and Inertia
			if self.DriverSeat.Throttle > 0 and self.StartedUp then
				self:Accelerate()
			elseif self.DriverSeat.Throttle < 0 and self.StartedUp then
				self:Decelerate()
			else
				self:Stop()
			end
			
			-- Move the boat in the direction at its looking with the newly throttled speed
			self:Move(self.Engine.CFrame.LookVector * self.CurrentSpeed)
			
			if self.StartedUp then
				-- Calculate how much the boat has turned left or right from the original orientation
				self.Yaw = self.Yaw - self.TurnRadius * self.DriverSeat.SteerFloat * (self.DriverSeat.Throttle >= 0 and 1 or -1)
				-- Get pitch and roll values as well
				local pitch = rad(self.DriverSeat.ThrottleFloat * self.RotationAngle) * self.ForwardRotationDirection
				local roll = -rad(self.DriverSeat.SteerFloat * self.RotationAngle)
				-- Control the gyro of the boat
				self:Rotate(pitch, self.Yaw, roll)
				
				-- Adjust altitude
				self.BodyPosition.Position = Vector3_new(0, self.CurrentAltitude + sin(frequency * x) * maxHeight + maxHeight/3, 0)
				x = x + t -- increment time
			else
				self:Rotate(0, self.Yaw, 0)
			end
		end
		
		-- Disconnect any event connections to prevent memory leaks
		throttleChangedConn:Disconnect()
		self.TakeDamageConn:Disconnect()
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

function Vehicle:Spawn(model, spawnCFrame)
	local newModel = model:Clone()
	newModel:SetPrimaryPartCFrame(spawnCFrame)
	newModel.Parent = game.Workspace
	return newModel
end

function Vehicle:Destroy()
	self.Running = false -- terminate the loop in the thread
	if self.StartUpChangedConn then
		self.StartUpChangedConn:Disconnect()
	end
	self.Model:Destroy()
	self = nil
end

function Vehicle:Move(direction)
	self.BodyVelocity.Velocity = direction
end

function Vehicle:Rotate(pitch, yaw, roll)
	self.BodyGyro.CFrame = self.OriginalCFrame * fromEulerAnglesYXZ(pitch, yaw, roll)
end

function Vehicle:Accelerate()
	self.CurrentSpeed = clamp(self.CurrentSpeed + 0.5*self.DriverSeat.ThrottleFloat, self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function Vehicle:Decelerate()
	self.CurrentSpeed = clamp(self.CurrentSpeed + 1*self.DriverSeat.ThrottleFloat, self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function Vehicle:Stop()
	self.CurrentSpeed = floor(self.CurrentSpeed > 0 and self.CurrentSpeed - 1 or self.CurrentSpeed < 0 and self.CurrentSpeed + 1 or 0)
end

function Vehicle:TakeDamage(damageAmount)
	damageAmount = damageAmount/2
	-- Change health and calculate ratio
	self.CurrentHealth = clamp(self.CurrentHealth - damageAmount, 0, self.MaxHealth)
	--print("damage dealt:", damageAmount.."; new hp:", self.CurrentHealth)
	local healthRatio = self.CurrentHealth/self.MaxHealth
	
	-- Adjust size and color
	self.HealthBar:TweenSize(UDim2.new(healthRatio, 0, 0.3, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
	if healthRatio > 0.66 then
		self.HealthBar.BackgroundColor3 = HIGH_HEALTH_COLOR
	elseif healthRatio >= 0.33 and healthRatio <= 0.66 then
		self.HealthBar.BackgroundColor3 = MEDIUM_HEALTH_COLER
	else
		self.HealthBar.BackgroundColor3 = LOW_HEALTH_COLOR
	end
	
	-- Destroy vehicle if equal to 0
	if healthRatio == 0 then
		--self.Model:BreakJoints()
		local smoke = Instance.new("Smoke")
		smoke.Color = Color3.fromRGB(108, 108, 108)
		smoke.RiseVelocity = 2
		smoke.Size = 5
		smoke.Parent = self.Engine
		
		-- If it is an aerial vehicle, destroy its extra controller
		if self.CurrentPilotScript then
			self.CurrentPilotScript.Disabled = true
		end
		
		-- Make sure vehicle can no longer be controlled
		-- Wait for it to stop moving, then terminate the vehicle's main thread
		self.StartedUp = false
		repeat wait() until self.CurrentSpeed <= 0
		self.Running = false
	end
end

function Vehicle:HandleEnvironmentalEvents()
	self.TakeDamageConn = self.TakeDamageEvent.Event:Connect(function(damageAmount)
		self:TakeDamage(damageAmount)
	end)
end

return Vehicle