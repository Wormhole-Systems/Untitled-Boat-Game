local NauticalVehicle = require(script.Parent)

local RescueBoat = {}
RescueBoat.__index = RescueBoat
setmetatable(RescueBoat, NauticalVehicle)

function RescueBoat.new(model)
	local newRescueBoat = NauticalVehicle.new(model)
	setmetatable(newRescueBoat, RescueBoat)
	
	-- Rescue boat specific attributes
	newRescueBoat.Name = "Rescue Boat"
	
	return newRescueBoat
end

return RescueBoat