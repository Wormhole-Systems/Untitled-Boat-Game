local NauticalVehicle = require(script.Parent)

local Submarine = {}
Submarine.__index = Submarine
setmetatable(Submarine, NauticalVehicle)

-- Static Variables
Submarine.TurnRadius = 1
Submarine.RotationAngle = 5
Submarine.MaxReverseSpeed = -5
Submarine.MaxForwardSpeed = 25
Submarine.MaxHealth = 200

-- Services
local ServerStorage = game:GetService("ServerStorage")

-- Micro-optimizations
local clamp = math.clamp

-- The script cloned into the occupant of the driver's seat
local vehicleControllingHelper = ServerStorage:WaitForChild("HelperScripts"):WaitForChild("VehicleControllingHelper")

function Submarine.new(model, spawnCFrame)
	local newSubmarine = NauticalVehicle.new(model, spawnCFrame, Submarine.TurnRadius, Submarine.RotationAngle, 
														   Submarine.MaxReverseSpeed, Submarine.MaxForwardSpeed,
														   Submarine.MaxHealth)
	setmetatable(newSubmarine, Submarine)
	
	newSubmarine.Name = "Submarine"
	newSubmarine.CurrentAltitude = 0
	newSubmarine.MinAltitude = -140
	newSubmarine.MaxAltitude = 0
	newSubmarine.Direction = 0
	newSubmarine.ForwardRotationDirection = 0
	newSubmarine.CurrentDriverScript = nil
	newSubmarine.ChangeAltitude = newSubmarine.Model:WaitForChild("ChangeAltitude")
	newSubmarine.FireTorpedo = newSubmarine.Model:WaitForChild("FireTorpedo")
	newSubmarine:HandleAltitudeAdjustment()
	
	return newSubmarine
end

function Submarine:IncreaseAltitude()
	self.CurrentAltitude = clamp(self.CurrentAltitude + 0.25, self.MinAltitude, self.MaxAltitude)
end

function Submarine:DecreaseAltitude()
	self.CurrentAltitude = clamp(self.CurrentAltitude - 0.25, self.MinAltitude, self.MaxAltitude)
end

function Submarine:HandleAltitudeAdjustment()
	self.AltitudeChangedConn = self.ChangeAltitude.OnServerEvent:Connect(function(player, direction)
		-- Ensure that the player calling the event is the one sitting in the driver's seat
		if player and player.Character and player.Character.Humanoid and player.Character.Humanoid == self.DriverSeat.Occupant then
			self.Direction = direction
			if direction == 1 then -- if instructed to go upwards
				spawn(function()
					-- Increase altitude while up key is down
					while self.Direction == 1 and self.DriverSeat.Occupant do
						self:IncreaseAltitude()
						wait()
					end
				end)
			elseif direction == -1 then -- if instructed to go downwards
				spawn(function()
					-- Decrease altitude while down key is down
					while self.Direction == -1 and self.DriverSeat.Occupant do
						self:DecreaseAltitude()
						wait()
					end
				end)
			else
				-- If player let go of up or down key
				self.CurrentAltitude = self.Engine.CFrame.Position.Y
			end
		end
	end)
	
	-- Handle starting up/turning off of the submarine
	self.StartUpChangedConn = self.DriverSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = self.DriverSeat.Occupant
		if not occupant and self.CurrentDriverScript then -- if the driver has jumped out
			-- Eject the driver
			local oldDriver = self.CurrentDriverScript.Parent
			delay(0.1, function()
				oldDriver.HumanoidRootPart.CFrame = oldDriver.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
			end)
			
			-- Destroy the driver's altitude adjuster script for the submarine
			self.CurrentDriverScript:Destroy()
			self.CurrentDriverScript = nil
		else
			-- Grant the driver the ability to adjust the heli's altitude
			self.CurrentDriverScript = vehicleControllingHelper:Clone()
			self.CurrentDriverScript:WaitForChild("ChangeAltitude").Value = self.ChangeAltitude
			self.CurrentDriverScript:WaitForChild("FireMissile").Value = self.FireTorpedo
			self.CurrentDriverScript.Parent = occupant.Parent
			self.CurrentDriverScript.Disabled = false
		end
	end)
end

return Submarine