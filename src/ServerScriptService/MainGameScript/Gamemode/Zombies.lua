local Zombies = setmetatable({}, require(script.Parent))

-- [[ Constants ]] --
local FOG_END_ORIGINAL = 100000
local TIME_OF_DAY_ORIGINAL = "17:25:00"
local WATER_COLOR_ORIGINAL = Color3.fromRGB(6, 88, 111)

local FOG_END_GAMEMODE = 500
local TIME_OF_DAY_GAMEMODE = "19:00:00"
local WATER_COLOR_GAMEMODE = Color3.fromRGB(80, 109, 84)

-- Map references
local survivorsVehicleSpawners = game.Workspace.Map.BaseAlpha.VehicleSpawners
local survivorsSpawn = game.Workspace.Map.BaseAlpha.SpawnPoints
local zombiesSpawns = game.Workspace.Map.BaseBravo.SpawnPoints
local zombiesBaseSecondaryParts = game.Workspace.Map.BaseBravo.Building.Secondary

-- [[ Roblox Services ]] --
local Teams = game:GetService("Teams")

-- [[ Zombies Leaderstats ]]--
local captured = Instance.new("StringValue") -- percentage
captured.Name = "Captured"

-- [[ Static Values ]] --
Zombies.Name = "Zombies"
Zombies.Codename = "ZOMB"
Zombies.Description = "Bravo has been infected by a deadly virus!\n\
					   Alpha is shot on supplies and must protect itself\n\
					   before the infected Bravo zombies take them all down!"

-- [[ Teams ]] --
local winningTeam
local survivorsName, survivorsColor = "Survivors", BrickColor.new("Crimson")
local zombiesName, zombiesColor = "Infected", BrickColor.new("Slime green")
local survivorAdded, survivorRemoved, zombieAdded, zombieRemoved
local numSurvivors, numZombies = 0, 0
local characterAddedConnections = {}
local playerSpawnConnections = {}

-- [[ Public Functions ]] --
function Zombies:Initialize()
	local survivors = Zombies.TeamManager:AddTeam(survivorsName, survivorsColor)
	local zombies = Zombies.TeamManager:AddTeam(zombiesName, zombiesColor)
	Zombies.DisplayManager:StartIntermission(survivorsName, survivorsColor.Color, zombiesName, zombiesColor.Color)

	-- Players entering and removing from team connections
	numSurvivors, numZombies = #survivors:GetPlayers(), #zombies:GetPlayers()
	
	survivorAdded = survivors.PlayerAdded:Connect(function(player)
		numSurvivors = #survivors:GetPlayers()
		Zombies.TeamManager:AddTeamScore(survivors, 1)
		
		playerSpawnConnections[player] = player.CharacterAdded:Connect(function(character)	
			local damangeDebounce = Instance.new("BoolValue")
			damangeDebounce.Name = "DamageDebounce"
			damangeDebounce.Parent = character
			
			character:WaitForChild("Health"):Destroy()
			if character:FindFirstChildOfClass("ForceField") then
				character:FindFirstChildOfClass("ForceField"):Destroy()
			end
			local humanoid = character:WaitForChild("Humanoid")
			local leftFoot = character:WaitForChild("LeftFoot")
			humanoid.Died:Connect(function()
				player.TeamColor = zombiesColor
			end)
			humanoid.Touched:Connect(function(touched)
				if leftFoot.Position.Y <= 0 and not damangeDebounce.Value then
					damangeDebounce.Value = true
					while leftFoot.Position.Y <= 0 do
						humanoid:TakeDamage(10)
						wait(0.5)
					end
					damangeDebounce.Value = false
				end
			end)
			
			playerSpawnConnections[player]:Disconnect()
			playerSpawnConnections[player] = nil
		end)
	end)
	survivorRemoved = survivors.PlayerRemoved:Connect(function(player)
		numSurvivors = #survivors:GetPlayers()
		Zombies.TeamManager:AddTeamScore(survivors, -1)
		if playerSpawnConnections[player] then
			playerSpawnConnections[player]:Disconnect()
			playerSpawnConnections[player] = nil
		end
	end)
	zombieAdded = zombies.PlayerAdded:Connect(function(player)
		numZombies = #zombies:GetPlayers()
		Zombies.TeamManager:AddTeamScore(zombies, 1)
		characterAddedConnections[#characterAddedConnections + 1] = player.CharacterAdded:Connect(function(character)
			if character:FindFirstChildOfClass("ForceField") then
				character:FindFirstChildOfClass("ForceField"):Destroy()
			end
			local humanoid = character:WaitForChild("Humanoid")
			humanoid.Touched:Connect(function(touchedPart)
				if touchedPart:IsA("BasePart") then
					local playerTouched = game.Players:GetPlayerFromCharacter(touchedPart.Parent)
					local playerChar = playerTouched and playerTouched.Character
					if playerTouched and playerTouched.Team and playerTouched.Team == survivors and not playerChar.DamageDebounce.Value then
						playerChar.DamageDebounce.Value = true
						playerChar.Humanoid:TakeDamage(5)
						wait(2)
						playerChar.DamageDebounce.Value = false
					end
				end
			end)
		end)
	end)
	zombieRemoved = zombies.PlayerRemoved:Connect(function()
		numZombies = #zombies:GetPlayers()
		Zombies.TeamManager:AddTeamScore(zombies, -1)
	end)
	Zombies.TeamManager:AddTeamScore(survivors, numSurvivors)
	Zombies.TeamManager:AddTeamScore(zombies, numZombies)
	
	-- Make map look spooky
	game.Lighting.FogEnd = FOG_END_GAMEMODE
	game.Lighting.TimeOfDay = TIME_OF_DAY_GAMEMODE
	game.Workspace.Terrain.WaterColor = WATER_COLOR_GAMEMODE
	
	-- Disallow vehicle spawning in survivors' base
	for _, v in pairs(survivorsVehicleSpawners:GetChildren()) do
		v.Touch.Value = true
		v.Transparency = 0.5
	end
	
	-- Update the spawn points of Bravo's base to be for the Zombies' team
	for _, v in pairs(survivorsSpawn:GetChildren()) do
		v.TeamColor = survivorsColor
	end
	
	-- Update the spawn points of Bravo's base to be for the Zombies' team
	for _, v in pairs(zombiesSpawns:GetChildren()) do
		v.TeamColor = zombiesColor
	end
	
	-- Change the secondary colors of the Zombies' base to a zombie color
	for _, v in pairs(zombiesBaseSecondaryParts:GetChildren()) do
		v.BrickColor = zombiesColor
	end
end

function Zombies:Finalize()
	-- Disconnect events
	survivorAdded:Disconnect()
	survivorRemoved:Disconnect()
	zombieAdded:Disconnect()
	zombieRemoved:Disconnect()
	for _, v in pairs(characterAddedConnections) do
		v:Disconnect()
	end
	for _, v in pairs(playerSpawnConnections) do
		v:Disconnect()
	end
	characterAddedConnections = {}
	playerSpawnConnections = {}
	
	-- Make map look normal again
	game.Lighting.FogEnd = FOG_END_ORIGINAL
	game.Lighting.TimeOfDay = TIME_OF_DAY_ORIGINAL
	game.Workspace.Terrain.WaterColor = WATER_COLOR_ORIGINAL	
	
	-- Allow vehicle spawning in survivors's base again
	for _, v in pairs(survivorsVehicleSpawners:GetChildren()) do
		v.Touch.Value = false
		v.Transparency = 0
	end
	
	-- Update the spawn points of Alpha's base back to normal
	for _, v in pairs(survivorsSpawn:GetChildren()) do
		v.TeamColor = BrickColor.new("Bright red")
	end
	
	-- Change the spawn points of Bravo's base back to normal
	for _, v in pairs(zombiesSpawns:GetChildren()) do
		v.TeamColor = BrickColor.new("Bright blue")
	end
	
	-- Change the secondary colors of the Bravo base back to normal
	for _, v in pairs(zombiesBaseSecondaryParts:GetChildren()) do
		v.BrickColor = BrickColor.new("Really blue")
	end
end

function Zombies:IsRoundOver()
	return numSurvivors == 0 and numZombies == 0
end

function Zombies:GetWinningTeam()
	return numSurvivors > 0 and Teams:FindFirstChild(survivorsName) or Teams:FindFirstChild(zombiesName)
end

return Zombies
