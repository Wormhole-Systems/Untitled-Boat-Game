-- [[ Game Manager ]]--
local gameManager = require(script:WaitForChild("GameManager"))
gameManager:Initialize()

-- [[ Gamemodes ]] --
local currentGamemode, numGamemodes = 0, #script:WaitForChild("Gamemode"):GetChildren()

-- Set up game attributes
game.Players.CharacterAutoLoads = false

while true do
	-- Select the new gamemode and initialize it
	currentGamemode = currentGamemode%numGamemodes + 1
	gameManager:InitializeGamemode(currentGamemode)
	
	-- Go into intermission until ready-up criteria is met
	repeat
		gameManager:RunIntermission()
	until gameManager:GameReady()
		
	-- Start the round with the selected gamemode
	gameManager:StopIntermission()
	gameManager:StartRound()
	
	-- Go into round progress mode until round over criteria is met
	repeat
		gameManager:Update()
		wait()
	until gameManager:RoundOver()
	
	-- Cleanup the map and round dependencies
	gameManager:RoundCleanup()
end