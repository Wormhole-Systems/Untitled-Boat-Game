--[[
	NOTE: Due to its substantial differences from other vehicles (such has having mouse-based movement, 
	  	  BodyGyro behavioral differences), this class does not inherit from Vehicle or AerialVehicle. 
		  However, it is still placed under AerialVehicle in the vehicle framework hierarchy for 
		  organizational purposes only.
--]]

local SpyPlane = {}
SpyPlane.__index = SpyPlane

-- Services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Take damage function
local takeDamage = require(script.Parent.Parent).TakeDamage

-- Constants
local HIGH_HEALTH_COLOR = Color3.new(0, 170, 0)
local MEDIUM_HEALTH_COLER = Color3.new(255, 85, 0)
local LOW_HEALTH_COLOR = Color3.new(170, 0, 0)
	
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

-- Preset vector values
local zeroVector = Vector3_new(0, 0, 0)
local maxVector = Vector3_new(huge, huge, huge)

-- The script cloned into the occupant of the pilot's seat
local gyroAdjuster = ServerStorage:WaitForChild("HelperScripts"):WaitForChild("GyroAdjuster")

function SpyPlane.new(model, spawnCFrame)
	local newSpyPlane = {}
	setmetatable(newSpyPlane, SpyPlane)
	
	newSpyPlane.Name = "Spy Plane"
	
	-- Class Attributes
	newSpyPlane.CurrentSpeed = 0
	newSpyPlane.MaxReverseSpeed = 0
	newSpyPlane.TakeoffSpeed = 75
	newSpyPlane.MaxForwardSpeed = 300
	newSpyPlane.MaxGyroPower = 1000
	newSpyPlane.MaxHealth = 75
	newSpyPlane.CurrentHealth = newSpyPlane.MaxHealth
	newSpyPlane.CurrentPilotScript = nil
	newSpyPlane.Running = true
	
	-- Specific Spy Plane Attributes
	newSpyPlane.Model = newSpyPlane:Spawn(model, spawnCFrame)
	newSpyPlane.ChangeGyro = newSpyPlane.Model:WaitForChild("ChangeGyro")
	newSpyPlane.DriverSeat = newSpyPlane.Model:WaitForChild("Driver")
	newSpyPlane.Engine = newSpyPlane.Model:WaitForChild("Engine")
	newSpyPlane.TakeDamageEvent = newSpyPlane.Model:WaitForChild("TakeDamage")
	newSpyPlane.HealthBar = newSpyPlane.Engine:WaitForChild("Info"):WaitForChild("Health")
	newSpyPlane.BodyForce = newSpyPlane.Engine:WaitForChild("BodyForce")
	newSpyPlane.BodyVelocity = newSpyPlane.Engine:WaitForChild("BodyVelocity")
	newSpyPlane.BodyGyro = newSpyPlane.Engine:WaitForChild("BodyGyro")
	newSpyPlane.OriginalCFrame = newSpyPlane.Engine.CFrame
	newSpyPlane.BodyGyro.CFrame = newSpyPlane.Engine.CFrame
	
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
		local previousVelocity, crashLandingForce, crashLanding = zeroVector, zeroVector, false
		while self.Running do
			local _, _t = RunService.Heartbeat:Wait()
			local pilotInSeat = self.CurrentPilotScript ~= nil and not self.CurrentPilotScript.Disabled
				
			-- Throttle the speed of the plane
			if self.DriverSeat.Throttle > 0 then
				if pilotInSeat then
					self:Accelerate()
				else
					self:Stop() -- crash landing initiated
				end
			elseif self.DriverSeat.Throttle < 0 then
				self:Decelerate()
			else
				if not pilotInSeat then
					self:Stop()  -- crash landing initiated
				end
			end
			
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
			local t = speedRatio * 50
			self.BodyGyro.MaxTorque = not crashLanding and Vector3_new(t, t, t) or (self.DriverSeat.Position.Y > 0 and maxVector or zeroVector)
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
		end
		
		-- Disconnect event connections to prevent memory leaks
		self.TakeDamageConn:Disconnect()
		self.GyroChangedConn:Disconnect()
	end)
end

--------------------------------
--[[ Helper Functions Below --]]
--------------------------------

function SpyPlane:Spawn(model, spawnCFrame)
	local newModel = model:Clone()
	newModel:SetPrimaryPartCFrame(spawnCFrame)
	newModel.Parent = game.Workspace
	return newModel
end

function SpyPlane:Destroy()
	self.Running = false -- terminate the loop in the thread
	self.StartUpChangedConn:Disconnect()
	self.Model:Destroy()
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
	self.CurrentSpeed = clamp(self.CurrentSpeed + 1*self.DriverSeat.ThrottleFloat, self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function SpyPlane:Decelerate()
	self.CurrentSpeed = clamp(self.CurrentSpeed + 1.5*self.DriverSeat.ThrottleFloat, self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function SpyPlane:Stop()
	self.CurrentSpeed = clamp(self.CurrentSpeed - 0.5 , self.MaxReverseSpeed, self.MaxForwardSpeed)
end

function SpyPlane:HandleEvents()
	-- Handle changes in gyro
	self.GyroChangedConn = self.ChangeGyro.OnServerEvent:Connect(function(player, newGyroCFrame, rollDir)
		-- Ensure that the player calling the event is the one sitting in the driver's seat
		if player and player.Character and player.Character.Humanoid and player.Character.Humanoid == self.DriverSeat.Occupant then
			local a, b = self.Engine.CFrame.LookVector, newGyroCFrame.LookVector
			local dot, cross = a:Dot(b), a:Cross(b)
			local angle = atan2(sqrt(cross:Dot(cross)), dot)
			self.BodyGyro.CFrame = newGyroCFrame * CFrame_Angles(0, 0, self.CurrentSpeed > self.TakeoffSpeed and angle*rollDir or 0)
		end
	end)
	
	-- Handle starting up/turning off of the spy plane
	self.StartUpChangedConn = self.DriverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = self.DriverSeat.Occupant
		if not occupant and self.CurrentPilotScript then -- if the pilot has jumped out
			-- Eject the pilot
			local oldPilot = self.CurrentPilotScript.Parent
			local oldPilotPlayer = game.Players:GetPlayerFromCharacter(oldPilot)
			oldPilotPlayer.CameraMinZoomDistance = 10
			delay(0.1, function()
				oldPilotPlayer.CameraMaxZoomDistance = 10
				if oldPilot:FindFirstChild("HumanoidRootPart") then
					oldPilot.HumanoidRootPart.CFrame = oldPilot.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
				end
				--oldPilot.HumanoidRootPart.Anchored = true
			end)
			
			-- Destroy the pilot's gyro adjuster script for the plane
			self.CurrentPilotScript:Destroy()
			self.CurrentPilotScript = nil
		else
			if self.Running then
				-- Grant the pilot the ability to adjust the plane's gyro
				self.CurrentPilotScript = gyroAdjuster:Clone()
				self.CurrentPilotScript:WaitForChild("EventPointer").Value = self.ChangeGyro
				self.CurrentPilotScript.Parent = occupant.Parent
				self.CurrentPilotScript.Disabled = false
				
				-- Adjust the camera zoom setting
				local pilot = game.Players:GetPlayerFromCharacter(occupant.Parent)
				pilot.CameraMaxZoomDistance = 20
				delay(0.1, function() pilot.CameraMinZoomDistance = 20 end)
			end	
		end
	end)
	
	self.TakeDamageConn = self.TakeDamageEvent.Event:Connect(function(damageAmount)
		takeDamage(self, damageAmount)
	end)
end

return SpyPlane