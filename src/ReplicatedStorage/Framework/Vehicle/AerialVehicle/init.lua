local Vehicle = require(script.Parent)

local AerialVehicle = {}
AerialVehicle.__index = AerialVehicle
setmetatable(AerialVehicle, Vehicle)

-- Services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")

-- Constants
local ZERO_VECTOR = Vector3.new(0, 0, 0)
local MAX_VECTOR = Vector3.new(math.huge, math.huge, math.huge)

-- Micro-optimizations
local clamp = math.clamp
local rad = math.rad

function AerialVehicle.new(model, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	local newAerialVehicle = Vehicle.new(model, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	setmetatable(newAerialVehicle, AerialVehicle)
	
	newAerialVehicle.MinAltitude = -140
	newAerialVehicle.MaxAltitude = 500
	newAerialVehicle.MaxForwardSpeedCache = newAerialVehicle.MaxForwardSpeed
	newAerialVehicle.CurrentAltitude = 0
	newAerialVehicle.Direction = 0
	newAerialVehicle.ForwardRotationDirection = -1
	newAerialVehicle.RotorSpeed = 0
	newAerialVehicle.CurrentPilot = nil
	newAerialVehicle.StartedUp = false
		
	return newAerialVehicle
end

function AerialVehicle:IncreaseAltitude()
	self.CurrentAltitude = clamp(self.CurrentAltitude + 0.25, self.MinAltitude, self.MaxAltitude)
	self.MaxForwardSpeed = self.CurrentAltitude > 0 and self.MaxForwardSpeedCache or self.MaxForwardSpeedCache/100
end

function AerialVehicle:DecreaseAltitude()
	self.CurrentAltitude = clamp(self.CurrentAltitude - 0.25, self.MinAltitude, self.MaxAltitude)
	self.MaxForwardSpeed = self.CurrentAltitude > 0 and self.MaxForwardSpeedCache or self.MaxForwardSpeedCache/100
end

function AerialVehicle:HandleAltitudeAdjustment()
	-- Handle changes in altitude
	local function changeAltitude(direction)
		-- Ensure that the player calling the event is the one sitting in the pilot's seat
		if self.CurrentPilot then
			self.Direction = direction
			if direction == 1 then -- if instructed to go upwards
				-- Increase altitude while up key is down
				while self.Direction == 1 and self.DriverSeat.Occupant do
					if self.StartedUp then
						self:IncreaseAltitude()
					end
					wait()
				end
			elseif direction == -1 then -- if instructed to go downwards
				-- Decrease altitude while down key is down
				while self.Direction == -1 and self.DriverSeat.Occupant do
					if self.StartedUp then
						self:DecreaseAltitude()
					end
					wait()
				end
			else -- If player let go of up or down key
				self.CurrentAltitude = self.Engine.CFrame.Position.Y -- maintain current altitude
			end
		end
	end
	
	local function handleIncreaseAltitudeRequest(input, gameProcessedEvent)
		if gameProcessedEvent and input.KeyCode ~= Enum.KeyCode.E then return end
		if input.KeyCode == Enum.KeyCode.Q then
			changeAltitude(-1)
		elseif input.KeyCode == Enum.KeyCode.E then
			changeAltitude(1)
		end
	end
	local function handleAltitudeSteadyRequest(input, gameProcessedEvent)
		if gameProcessedEvent and input.KeyCode ~= Enum.KeyCode.E then return end
		if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
			changeAltitude(0)
		end
	end
	
	-- Handle starting up/turning off of the aerial vehicle
	local inputBegan, inputEnded
	self.DriverSeatChanged = function()
		local occupant = self.DriverSeat.Occupant

		if not self.Running or (not occupant and self.CurrentPilot) then -- if the pilot has jumped out
			-- Disallow altitude adjustments requests
			if inputBegan and inputEnded then
				inputBegan:Disconnect()
				inputEnded:Disconnect()
			end
			
			-- Destroy the class's reference to the current pilot
			self.CurrentPilot = nil
			self:SetStartedUp(false)
			
			-- Decelerate the rotors to 0
			while (not self.Running or not self.CurrentPilot) and self.RotorSpeed > 0 do
				for _, r in pairs(self.Rotors) do
					if r.Parent then
						r.HingeConstraint.TargetAngle = r.HingeConstraint.TargetAngle + self.RotorSpeed
						if self.EngineSound then
							self.EngineSound.PlaybackSpeed = self.RotorSpeed/300 * 0.5 + 0.5
							self.EngineSound.Volume = self.RotorSpeed/300 * 2
						end
					else
						break
					end
				end
				self.RotorSpeed = clamp(self.RotorSpeed - (self.RotorSpeed > 15 and 0.5 or 0.1), 0, 300)
				self.BodyPosition.MaxForce = Vector3.new(0, self.Mass * workspace.Gravity * self.RotorSpeed/150,0)
				self.BodyGyro.MaxTorque = Vector3.new(0, self.Mass * workspace.Gravity * self.RotorSpeed/300, 0)
				self.BodyGyro.CFrame = self.Engine.CFrame
				RunService.Heartbeat:Wait()
			end
			if self.EngineSound and not self.CurrentPilot then self.EngineSound:Stop() end
		elseif occupant and not self.CurrentPilot then
			if self.Running then
				-- Adjust the camera zoom setting
				local pilot = game.Players:GetPlayerFromCharacter(occupant.Parent)
				self.CurrentPilot = pilot
				
				-- Don't let gravity pull down the aerial vehicle
				self.BodyPosition.Position = self.Engine.Position
				self.CurrentAltitude = self.Engine.Position.Y
				
				-- Allow altitude adjustment requests
				inputBegan = UserInputService.InputBegan:Connect(handleIncreaseAltitudeRequest)
				inputEnded = UserInputService.InputEnded:Connect(handleAltitudeSteadyRequest)
				
				-- Start up, enable body movers, and spin the rotors
				self.StartedUp = true
				if self.EngineSound then self.EngineSound:Play() end
				self:SetStartedUp(true)
				while self.CurrentPilot and self.Rotors do
					for _, r in pairs(self.Rotors) do
						if r.Parent then
							r.HingeConstraint.TargetAngle = r.HingeConstraint.TargetAngle + self.RotorSpeed
							if self.EngineSound then
								self.EngineSound.PlaybackSpeed = self.RotorSpeed/300 * 0.5 + 0.5
								self.EngineSound.Volume = clamp(self.RotorSpeed/300 * 4, 0, 2)
							end
						else
							self.CurrentPilot  = nil
							break
						end
					end
					self.RotorSpeed = clamp(self.RotorSpeed + 0.25, 0, 300)
					if self.RotorSpeed >= 15 then
						self:SetStartedUp(true)
					else
						self:SetStartedUp(false)
					end
					RunService.Heartbeat:Wait()
				end
			end
		end
	end
	self.DriverSeatChanged()
	self.StartUpChangedConn = self.DriverSeat:GetPropertyChangedSignal("Occupant"):Connect(self.DriverSeatChanged)
end

function AerialVehicle:SetStartedUp(startedUp)
	self.StartedUp = startedUp
	self.BodyGyro.MaxTorque = startedUp and MAX_VECTOR or ZERO_VECTOR
	self.BodyVelocity.MaxForce = startedUp and Vector3.new(math.huge, 0, math.huge) or  ZERO_VECTOR
	self.BodyPosition.MaxForce = startedUp and Vector3.new(0, math.huge, 0) or Vector3.new(0, self.Mass * workspace.Gravity, 0)
end

return AerialVehicle
