local NauticalVehicle = require(script.Parent)

local Battleship = {}
Battleship.__index = Battleship
setmetatable(Battleship, NauticalVehicle)

function Battleship.new(model)
	local newBattleship = NauticalVehicle.new(model)
	setmetatable(newBattleship, Battleship)
	
	-- Battleship specific attributes
	newBattleship.Name = "Battleship"
	newBattleship.CurrentAltitude = 3
	
	return newBattleship
end

return Battleship