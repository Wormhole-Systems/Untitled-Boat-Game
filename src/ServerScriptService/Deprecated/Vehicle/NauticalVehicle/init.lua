local Vehicle = require(script.Parent)

local NauticalVehicle = {}
NauticalVehicle.__index = NauticalVehicle
setmetatable(NauticalVehicle, Vehicle)

function NauticalVehicle.new(model, spawnCFrame, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	local newNauticalVehicle = Vehicle.new(model, spawnCFrame, turnRadius, rotationAngle, maxReverseSpeed, maxForwardSpeed, maxHealth)
	setmetatable(newNauticalVehicle, NauticalVehicle)
	
	return newNauticalVehicle
end

return NauticalVehicle
