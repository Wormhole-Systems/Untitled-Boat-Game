AerialVehicle = require(script.Parent)

local Blimp = {}
Blimp.__index = Blimp
setmetatable(Blimp, AerialVehicle)

function Blimp.new(model)
	local newBlimp = AerialVehicle.new(model)
	setmetatable(newBlimp, Blimp)
	
	newBlimp.Name = "Blimp"
	
	-- Handle player interaction with the vehicle
	newBlimp:HandleAltitudeAdjustment()
	
	return newBlimp
end

return Blimp