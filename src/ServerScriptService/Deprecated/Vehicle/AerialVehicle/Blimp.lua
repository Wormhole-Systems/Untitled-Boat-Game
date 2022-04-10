AerialVehicle = require(script.Parent)

local Blimp = {}
Blimp.__index = Blimp
setmetatable(Blimp, AerialVehicle)

-- Static variables
Blimp.TurnRadius = math.rad(75)
Blimp.RotationAngle = 5
Blimp.MaxReverseSpeed = -50
Blimp.MaxForwardSpeed = 200
Blimp.MaxHealth = 300

function Blimp.new(model, spawnCFrame)
	local newBlimp = AerialVehicle.new(model, spawnCFrame, Blimp.TurnRadius, Blimp.RotationAngle, 
														   Blimp.MaxReverseSpeed, Blimp.MaxForwardSpeed,
														   Blimp.MaxHealth)
	setmetatable(newBlimp, Blimp)
	
	newBlimp.Name = "Blimp"
	
	return newBlimp
end

return Blimp