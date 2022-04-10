AerialVehicle = require(script.Parent)

local Chinook = {}
Chinook.__index = Chinook
setmetatable(Chinook, AerialVehicle)

function Chinook.new(model)
	local newChinook = AerialVehicle.new(model)
	setmetatable(newChinook, Chinook)
	
	newChinook.Name = "Chinook"
		
	-- Handle player interaction with the vehicle
	newChinook:HandleAltitudeAdjustment()
	
	return newChinook
end

return Chinook