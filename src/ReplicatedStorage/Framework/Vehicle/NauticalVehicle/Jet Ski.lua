local NauticalVehicle = require(script.Parent)

local JetSki = {}
JetSki.__index = JetSki
setmetatable(JetSki, NauticalVehicle)

function JetSki.new(model)
	local newJetSki = NauticalVehicle.new(model)
	setmetatable(newJetSki, JetSki)
	
	-- Jet ski boat specific attributes
	newJetSki.Name = "Jet Ski"
	
	newJetSki.CurrentAltitude = 0.5
	
	return newJetSki
end

return JetSki