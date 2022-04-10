AerialVehicle = require(script.Parent)

local Helicopter = {}
Helicopter.__index = Helicopter
setmetatable(Helicopter, AerialVehicle)

-- Services
local Players = game.Players
local UserInputService = game:GetService("UserInputService")

-- Local player
local localPlayer = game.Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- Missile firing event
local fireMissile = game:GetService("ReplicatedStorage"):WaitForChild("Invokers"):WaitForChild("Vehicle"):WaitForChild("FireMissile")

function Helicopter.new(model, spawnCFrame)
	local newHelicopter = AerialVehicle.new(model)
	setmetatable(newHelicopter, Helicopter)
	
	newHelicopter.Name = "Helicopter"
	
	-- Helicopter specific attributes
	newHelicopter.CurrentMissile = 1
	newHelicopter.StartedUp = false
	
	-- Handle player interaction with the vehicle
	newHelicopter:HandleAltitudeAdjustment()
	newHelicopter:HandleEvents()
	
	return newHelicopter
end


function Helicopter:HandleEvents()
	local function updateMissileFiringPermissions()
		if self.DriverSeat.Occupant and localPlayer == Players:GetPlayerFromCharacter(self.DriverSeat.Occupant.Parent) then
			self.fireMissileConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
				if gameProcessedEvent then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 and self.Model:FindFirstChild("Missile"..self.CurrentMissile) and mouse.Hit then
					fireMissile:FireServer(self.Model, self.CurrentMissile, mouse.Hit)
					self.CurrentMissile = self.CurrentMissile%2 + 1
				end
			end)
		else
			if self.fireMissileConn then
				self.fireMissileConn:Disconnect()
			end
		end
	end
	updateMissileFiringPermissions()
	self.misslePermissionConn = self.DriverSeat:GetPropertyChangedSignal("Occupant"):Connect(updateMissileFiringPermissions)
end

return Helicopter