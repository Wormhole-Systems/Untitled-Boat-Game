local Vehicle = require(script.Parent)

local RunService = game:GetService("RunService")

local clamp = math.clamp

local NauticalVehicle = {}
NauticalVehicle.__index = NauticalVehicle
setmetatable(NauticalVehicle, Vehicle)

function NauticalVehicle.new(model, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	local newNauticalVehicle = Vehicle.new(model, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	setmetatable(newNauticalVehicle, NauticalVehicle)
	
	if newNauticalVehicle.Rotors then
		newNauticalVehicle:HandleStartupChange()
	end
	
	-- Enable body movers
	newNauticalVehicle.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	newNauticalVehicle.BodyPosition.MaxForce = Vector3.new(0, math.huge, 0)
	newNauticalVehicle.BodyVelocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	
	return newNauticalVehicle
end

function NauticalVehicle:HandleStartupChange()
	-- Handle starting up/turning off of the submarine
	local function driverSeatChanged()
		local occupant = self.DriverSeat.Occupant
		if not occupant and self.CurrentDriver then -- if the driver has jumped out
			-- Destroy the reference to the old driver
			self.CurrentDriver = nil
						
			-- Decelerate the rotors to 0
			while not self.CurrentDriver and self.RotorSpeed > 0 do
				for _, r in pairs(self.Rotors) do
					if r.Parent then
						r.HingeConstraint.TargetAngle = r.HingeConstraint.TargetAngle + self.RotorSpeed
					else
						break
					end
				end
				self.RotorSpeed = clamp(self.RotorSpeed - (self.RotorSpeed > 15 and 0.5 or 0.1), 0, 300)
				RunService.Heartbeat:Wait()
			end
			if self.Particle and not self.CurrentDriver then self.Particle.Enabled = false end
		elseif occupant and not self.CurrentDriver then
			if self.Running then
				-- Adjust the camera zoom setting
				local driver = game.Players:GetPlayerFromCharacter(occupant.Parent)
				self.CurrentDriver = driver
				
				if self.Particle then self.Particle.Enabled = true end
				
				-- Start up and spin the rotors
				while self.CurrentDriver do
					for _, r in pairs(self.Rotors) do
						if r.Parent then
							r.HingeConstraint.TargetAngle = r.HingeConstraint.TargetAngle + self.RotorSpeed
						else
							self.CurrentDriver = nil
							break
						end
					end
					self.RotorSpeed = clamp(self.RotorSpeed + 0.05, 0, 300)
					RunService.Heartbeat:Wait()
				end
			end
		end
	end
	driverSeatChanged()
	self.StartUpChangedConn = self.DriverSeat:GetPropertyChangedSignal("Occupant"):Connect(driverSeatChanged)
end

return NauticalVehicle
