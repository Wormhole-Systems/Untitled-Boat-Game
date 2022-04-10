AerialVehicle = require(script.Parent)

local Chinook = {}
Chinook.__index = Chinook
setmetatable(Chinook, AerialVehicle)

-- Static variables
Chinook.TurnRadius = math.rad(75)
Chinook.RotationAngle = 5
Chinook.MaxReverseSpeed = -50
Chinook.MaxForwardSpeed = 200
Chinook.MaxHealth = 300

function Chinook.new(model, spawnCFrame)
	local newChinook = AerialVehicle.new(model, spawnCFrame, Chinook.TurnRadius, Chinook.RotationAngle, 
															 Chinook.MaxReverseSpeed, Chinook.MaxForwardSpeed,
															 Chinook.MaxHealth)
	setmetatable(newChinook, Chinook)
	
	newChinook.Name = "Chinook"
	
	return newChinook
end

return Chinook