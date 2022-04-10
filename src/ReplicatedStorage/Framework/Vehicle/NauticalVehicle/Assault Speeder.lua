local NauticalVehicle = require(script.Parent)

local AssaultSpeeder = {}
AssaultSpeeder.__index = AssaultSpeeder
setmetatable(AssaultSpeeder, NauticalVehicle)

function AssaultSpeeder.new(model)
	local newAssaultSpeeder = NauticalVehicle.new(model)
	setmetatable(newAssaultSpeeder, AssaultSpeeder)
	
	-- Rescue boat specific attributes
	newAssaultSpeeder.Name = "Assault Speeder"
		
	return newAssaultSpeeder
end

return AssaultSpeeder