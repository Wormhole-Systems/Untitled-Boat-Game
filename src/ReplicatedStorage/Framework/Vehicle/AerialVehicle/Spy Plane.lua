--[[
	NOTE: Due to its substantial differences from other vehicles (such has having mouse-based movement, 
	  	  BodyGyro behavioral differences), this class does not inherit from Vehicle or AerialVehicle. 
		  However, it is still placed under AerialVehicle in the vehicle framework hierarchy for 
		  organizational purposes only.
--]]

local SpyPlane = {}
SpyPlane.__index = SpyPlane

-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Player mouse used to control gyro
local localPlayer = game.Players.LocalPlayer
local mouse = localPlayer:GetMouse()
local camera = game.Workspace.CurrentCamera

-- Micro-optimizations
local abs = math.abs
local rad = math.rad
local clamp = math.clamp
local floor = math.floor
local atan2 = math.atan2
local sqrt = math.sqrt
local huge = math.huge
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local huge_torque = 1

-- Preset values
local zeroVector = Vector3_new(0, 0, 0)
local maxVector = Vector3_new(huge, huge, huge)
local maxTorqueVector = Vector3_new(huge_torque, huge_torque, huge_torque)
local halfScreenPoint = game.Workspace.CurrentCamera.ViewportSize.X/2

function SpyPlane.new(model)
	local newSpyPlane = {}
	setmetatable(newSpyPlane, SpyPlane)
	
	newSpyPlane.Name = "Spy Plane"
	
	-- Class Attributes
	local configFolder = model.Configuration
	newSpyPlane.MaxReverseSpeed = -configFolder.MaxReverseSpeed.Value
	newSpyPlane.MaxForwardSpeed = configFolder.MaxForwardSpeed.Value
	
	-- Values Used For Calculating Movement
	newSpyPlane.CurrentSpeed = 0
	newSpyPlane.TakeoffSpeed = 75
	newSpyPlane.MaxGyroPower = 1000
	newSpyPlane.CurrentPilot = nil
	newSpyPlane.Running = true
	newSpyPlane.StartedUp = false
	
	-- Specific Spy Plane Attributes
	newSpyPlane.Model = model
	newSpyPlane.EngineSound = newSpyPlane.Model.PrimaryPart:FindFirstChildOfClass("Sound")
	newSpyPlane.DriverSeat = newSpyPlane.Model:WaitForChild("Driver")
	newSpyPlane.Engine = newSpyPlane.Model:WaitForChild("Engine")
	newSpyPlane.BodyForce = newSpyPlane.Engine:WaitForChild("BodyForce")
	newSpyPlane.BodyVelocity = newSpyPlane.Engine:WaitForChild("BodyVelocity")
	newSpyPlane.BodyGyro = newSpyPlane.Engine:WaitForChild("BodyGyro")
	newSpyPlane.BodyGyro.CFrame = newSpyPlane.Engine.CFrame
	
	-- Enable body movers
	--[[
	newSpyPlane.BodyVelocity.MaxForce = zeroVector
	newSpyPlane.BodyGyro.MaxTorque = zeroVector
	newSpyPlane.BodyGyro.P = 0
	newSpyPlane.BodyGyro.D = 0
	--]]
	
	newSpyPlane.Mass = 0
	for _, v in pairs(newSpyPlane.Model:GetDescendants()) do
		if v:IsA("BasePart") then 
			newSpyPlane.Mass = newSpyPlane.Mass + v:GetMass()
		end
	end
	
	newSpyPlane:HandleEvents()
		
	return newSpyPlane
end

function SpyPlane:Initialize()
	spawn(function()
		self.EngineSound:Play()
		local previousVelocity, crashLandingForce, crashLanding = zeroVector, zeroVector, false
		while self.Running do
			local _t = RunService.Heartbeat:Wait()
			local pilotInSeat = self.StartedUp
				
			-- Throttle the speed of the plane
			if pilotInSeat then
				if self.DriverSeat.Throttle > 0 then
					self:Accelerate()
				elseif self.DriverSeat.Throttle < 0 then
					self:Decelerate()
				end
			else
				self:Stop() -- crash landing initiated
			end
			
			-- Adjust sound properties
			self.EngineSound.PlaybackSpeed = self.CurrentSpeed/self.MaxForwardSpeed
			self.EngineSound.Volume = self.EngineSound.PlaybackSpeed + 0.5
			
			-- Move the plane in the direction that it's looking in with the newly throttled speed
			if not pilotInSeat and not crashLanding then
				crashLanding = true
				-- multiplied by 3 because planes fall a little more gracefully due to aerodynamics
				crashLandingForce = self.Mass * (self.Engine.Velocity - previousVelocity)/_t -- mass * acceleration = mass * deltaV/t
				--print(crashLandingForce.Magnitude)
			elseif pilotInSeat and crashLanding then
				crashLanding = false
			end
			--print("Crash Landing:", crashLanding)
			
			-- Configure gyro's power based on speed
			local speedRatio = self.CurrentSpeed/self.MaxForwardSpeed
			local t = speedRatio * 20000
			self.BodyGyro.MaxTorque = not crashLanding and Vector3_new(t/10, t, t) or (self.DriverSeat.Position.Y > 0 and maxTorqueVector or zeroVector)
			self.BodyGyro.P = pilotInSeat and speedRatio * self.MaxGyroPower or (self.CurrentSpeed > 0 and self.MaxGyroPower or 0)
			self.BodyGyro.D = (not crashLanding or self.CurrentSpeed == 0) and 500 or 100
			self.BodyVelocity.MaxForce = (pilotInSeat and self.CurrentSpeed == self.MaxForwardSpeed) and maxVector or Vector3_new(huge, self.CurrentSpeed * self.Mass, huge)
			
			self:Move(pilotInSeat, pilotInSeat and (self.Engine.CFrame.LookVector * self.CurrentSpeed) or 
			  							   		   (crashLandingForce * speedRatio))
		   											--(crashLandingForce * (self.CurrentSpeed > 0 and 1 or 0)))
			-- Adjust gyro to be looking towards the velocity
			if crashLanding then
				self.BodyGyro.CFrame = CFrame_new(zeroVector, self.Engine.Velocity.Unit)
			end
			previousVelocity = self.Engine.Velocity
			
			-- Adjust camera field of view accordingly
			if pilotInSeat then
				camera.FieldOfView = 70 + 15 * self.CurrentSpeed/self.MaxForwardSpeed
			end
		end
		
		-- Disconnect event to prevent memory leaks
		self.StartUpChangedConn:Disconnect()
		
		-- Stop engine sound
		self.EngineSound:Stop()
	end)
end

--------------------------------
--[[ Helper Functions Below ]]--
--------------------------------

function SpyPlane:Destroy(shouldDestroyModel)
	if not shouldDestroyModel then
		-- Wait for it to stop moving, then terminate the vehicle's main thread
		repeat wait() until self.CurrentSpeed <= 0
	end
	self.Running = false -- terminate the loop in the thread
	self.StartedUp = false
	self.StartUpChangedConn:Disconnect()
	if self.MouseInputChangedEvent then
		self.MouseInputChangedEvent:Disconnect()
	end
	if shouldDestroyModel then
		self.Model:Destroy()
	end
	self = nil
end

function SpyPlane:Move(pilotInSeat, direction)
	if pilotInSeat then
		self.BodyVelocity.Velocity = direction
		self.BodyForce.Force = zeroVector
	else
		self.BodyVelocity.MaxForce = zeroVector
		self.BodyForce.Force = direction
	end
end

function SpyPlane:Accelerate()
	self.CurrentSpeed = clamp(self.CurrentSpeed + 1.5*self.DriverSeat.ThrottleFloat, self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function SpyPlane:Decelerate()
	self.CurrentSpeed = clamp(self.CurrentSpeed + 1.5*self.DriverSeat.ThrottleFloat, self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function SpyPlane:Stop()
	self.CurrentSpeed = clamp(self.CurrentSpeed - 0.5 , 0, self.MaxForwardSpeed)
end

function SpyPlane:HandleEvents()
	-- Handle changes in gyro
	local function changeGyro(newGyroCFrame, rollDir)
		if self.StartedUp then
			-- Ensure that the player calling the event is the one sitting in the driver's seat
			local a, b = self.Engine.CFrame.LookVector, newGyroCFrame.LookVector
			local dot, cross = a:Dot(b), a:Cross(b)
			local angle = atan2(sqrt(cross:Dot(cross)), dot)
			self.BodyGyro.CFrame = newGyroCFrame * CFrame_Angles(0, 0, self.CurrentSpeed > self.TakeoffSpeed and angle*rollDir or 0)
		end
	end
	
	-- Handle starting up/turning off of the spy plane
	local mouseInputChangedEvent
	self.StartUpChangedConn = self.DriverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = self.DriverSeat.Occupant
		if occupant and localPlayer == Players:GetPlayerFromCharacter(occupant.Parent) then
			self.StartedUp = true
			CollectionService:AddTag(self.Model, "IgnoreCamera")
			if UserInputService.KeyboardEnabled then
				self.MouseInputChangedEvent = mouse.Idle:Connect(function()
					changeGyro(mouse.Hit, mouse.X < halfScreenPoint and 1 or mouse.X > halfScreenPoint and -1 or 0)
				end)
			else
				self.MouseInputChangedEvent = mouse.Move:Connect(function()
					changeGyro(mouse.Hit, mouse.X < halfScreenPoint and 1 or mouse.X > halfScreenPoint and -1 or 0)
				end)
			end
		else
			self.StartedUp = false
			CollectionService:RemoveTag(self.Model, "IgnoreCamera")
			camera.FieldOfView = 70
			if self.MouseInputChangedEvent then
				self.MouseInputChangedEvent:Disconnect()
				self.MouseInputChangedEvent = nil
			end
		end
	end)
end

return SpyPlane