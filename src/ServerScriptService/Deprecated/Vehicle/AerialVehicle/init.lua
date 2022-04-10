local Vehicle = require(script.Parent)

local AerialVehicle = {}
AerialVehicle.__index = AerialVehicle
setmetatable(AerialVehicle, Vehicle)

-- Services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Constants
local ZERO_VECTOR = Vector3.new(0, 0, 0)
local MAX_VECTOR = Vector3.new(0, math.huge, 0)

-- Micro-optimizations
local clamp = math.clamp
local rad = math.rad

-- The script cloned into the occupant of the pilot's seat
local vehicleControllingHelper = ServerStorage:WaitForChild("HelperScripts"):WaitForChild("VehicleControllingHelper")

function AerialVehicle.new(model, spawnCFrame, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	local newAerialVehicle = Vehicle.new(model, spawnCFrame, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	setmetatable(newAerialVehicle, AerialVehicle)
	
	newAerialVehicle.MinAltitude = -140
	newAerialVehicle.MaxAltitude = 200
	newAerialVehicle.CurrentAltitude = 0
	newAerialVehicle.Direction = 0
	newAerialVehicle.ForwardRotationDirection = -1
	newAerialVehicle.RotorSpeed = 0
	newAerialVehicle.CurrentPilotScript = nil
	newAerialVehicle.StartedUp = false
	newAerialVehicle.ChangeAltitude = newAerialVehicle.Model:WaitForChild("ChangeAltitude")
	
	-- Set up the rotors
	newAerialVehicle.Rotors = {}
	for _, v in pairs(newAerialVehicle.Model:GetChildren()) do
		if v:FindFirstChildOfClass("ManualWeld") then
			table.insert(newAerialVehicle.Rotors, v)
		end
	end
	
	return newAerialVehicle
end

function AerialVehicle:IncreaseAltitude()
	self.CurrentAltitude = clamp(self.CurrentAltitude + 0.25, self.MinAltitude, self.MaxAltitude)
end

function AerialVehicle:DecreaseAltitude()
	self.CurrentAltitude = clamp(self.CurrentAltitude - 0.25, self.MinAltitude, self.MaxAltitude)
end

function AerialVehicle:HandleAltitudeAdjustment()
	-- Handle changes in altitude
	self.AltitudeChangedConn = self.ChangeAltitude.OnServerEvent:Connect(function(player, direction)
		-- Ensure that the player calling the event is the one sitting in the pilot's seat
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
			else -- If player let go of up or down key
				self.CurrentAltitude = self.Engine.CFrame.Position.Y -- maintain current altitude
			end
		end
	end)
	
	-- Handle starting up/turning off of the aerial vehicle
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
					oldPilot.HumanoidRootPart.CFrame = oldPilot.HumanoidRootPart.CFrame + Vector3.new(0, 10, 0)
				end
			end)
			
			-- Destroy the pilot's altitude adjuster script for the heli
			self.CurrentPilotScript:Destroy()
			self.CurrentPilotScript = nil
			self.StartedUp = false
			self.BodyPosition.MaxForce = ZERO_VECTOR -- succumb the vehicle to gravity
			
			-- Decelerate the rotors to 0
			while not self.CurrentPilotScript and self.RotorSpeed > 0 do
				for _, r in pairs(self.Rotors) do
					if r:FindFirstChild("ManualWeld") then
						r.ManualWeld.C0 = r.ManualWeld.C0 * CFrame.Angles(0, self.RotorSpeed, 0)
					end
				end
				self.RotorSpeed = clamp(self.RotorSpeed - rad(1/20), 0, 0.38)
				RunService.Heartbeat:Wait()
			end
		else
			if self.Running then
				-- Grant the pilot the ability to adjust the heli's altitude
				self.CurrentPilotScript = vehicleControllingHelper:Clone()
				self.CurrentPilotScript:WaitForChild("ChangeAltitude").Value = self.ChangeAltitude
				self.CurrentPilotScript:WaitForChild("FireMissile").Value = self.ShootMissile
				self.CurrentPilotScript.Parent = occupant.Parent
				
				-- Adjust the camera zoom setting
				local pilot = game.Players:GetPlayerFromCharacter(occupant.Parent)
				pilot.CameraMaxZoomDistance = 60
				delay(0.1, function() pilot.CameraMinZoomDistance = 60 end)
				
				-- Don't let gravity pull down the heli
				self.BodyPosition.Position = self.Engine.Position
				
				-- Start up and spin the rotors
				while self.CurrentPilotScript do
					for _, r in pairs(self.Rotors) do
						if r.Parent then
							r.ManualWeld.C0 = r.ManualWeld.C0 * CFrame.Angles(0, self.RotorSpeed, 0)
						else
							break
						end
					end
					local rotorAcceleration = self.CurrentPilotScript.Disabled and -rad(1/10) or rad(1/10)
					self.RotorSpeed = clamp(self.RotorSpeed + rotorAcceleration, 0, 0.38)
					if self.RotorSpeed >= 0.38 then
						self.StartedUp = true
						self.BodyPosition.MaxForce = MAX_VECTOR
					else
						self.StartedUp = false
						self.BodyPosition.MaxForce = ZERO_VECTOR
					end
					RunService.Heartbeat:Wait()
				end
			end
		end
	end)
end


return AerialVehicle
