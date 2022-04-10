local NauticalVehicle = require(script.Parent)

local Lifeboat = {}
Lifeboat.__index = Lifeboat
setmetatable(Lifeboat, NauticalVehicle)

function Lifeboat.new(model)
	local newLifeboat = NauticalVehicle.new(model)
	setmetatable(newLifeboat, Lifeboat)
	
	-- Lifeboat specific attributes
	newLifeboat.Name = "Lifeboat"
	
	newLifeboat.CurrentAltitude = 0.5
	
	return newLifeboat
end

return Lifeboat