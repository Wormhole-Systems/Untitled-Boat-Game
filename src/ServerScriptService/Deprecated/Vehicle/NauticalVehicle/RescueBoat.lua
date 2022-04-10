local NauticalVehicle = require(script.Parent)

local RescueBoat = {}
RescueBoat.__index = RescueBoat
setmetatable(RescueBoat, NauticalVehicle)

-- Static Variables
RescueBoat.TurnRadius = 1
RescueBoat.RotationAngle = 5
RescueBoat.MaxReverseSpeed = -20
RescueBoat.MaxForwardSpeed = 100
RescueBoat.MaxHealth = 100


function RescueBoat.new(model, spawnCFrame)
	local newRescueBoat = NauticalVehicle.new(model, spawnCFrame, RescueBoat.TurnRadius, RescueBoat.RotationAngle, 
														    RescueBoat.MaxReverseSpeed, RescueBoat.MaxForwardSpeed,
														    RescueBoat.MaxHealth)
	setmetatable(newRescueBoat, RescueBoat)
	
	newRescueBoat.Name = "Rescue Boat"
	
	return newRescueBoat
end

return RescueBoat