local NauticalVehicle = require(script.Parent)

local Hovercraft = {}
Hovercraft.__index = Hovercraft
setmetatable(Hovercraft, NauticalVehicle)

function Hovercraft.new(model)
	local newHovercraft = NauticalVehicle.new(model)
	setmetatable(newHovercraft, Hovercraft)
	
	-- Hovercraft specific attributes
	newHovercraft.Name = "Hovercraft"
	
	newHovercraft.CurrentAltitude = 0.5
	
	return newHovercraft
end

return Hovercraft