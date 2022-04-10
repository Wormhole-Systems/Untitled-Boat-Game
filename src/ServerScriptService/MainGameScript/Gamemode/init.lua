local Gamemode = {}
Gamemode.__index = Gamemode

-- [[ Roblox Services ]] --
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

-- [[ Game Services ]] --
local GameManager = script.Parent:WaitForChild("GameManager")
Gamemode.Configurations = require(ServerStorage.Configurations)
Gamemode.TeamManager = require(GameManager.TeamManager)
Gamemode.PlayerManager = require(GameManager.PlayerManager)
Gamemode.DisplayManager = require(GameManager.DisplayManager)

-- [[ Static Values ]] --
Gamemode.Name = "Gamemode"
Gamemode.Codename = "GM"
Gamemode.Description = "This is the description for a gamemode."

-- [[ Teams ]] --
local winningTeam
local team1Name, team1Color = "Alpha", BrickColor.new("Bright red")
local team2Name, team2Color = "Bravo", BrickColor.new("Bright blue")

-- [[ Leaderstat Values ]] --
local kills = Instance.new("IntValue")
kills.Name = "KOs"
local deaths = Instance.new("IntValue")
deaths.Name = "WOs"

-- [[ Public Functions ]]--
function Gamemode:Initialize()
	Gamemode.TeamManager:AddTeam(team1Name, team1Color)
	Gamemode.TeamManager:AddTeam(team2Name, team2Color)
	Gamemode.DisplayManager:StartIntermission(team1Name, team1Color.Color, team2Name, team2Color.Color)
end

function Gamemode:AreTeamsTied()
	return Gamemode.TeamManager:AreTeamsTied()
end

function Gamemode:AddLeaderstatValues()
	Gamemode.PlayerManager:AddLeaderstatValue(kills)
	Gamemode.PlayerManager:AddLeaderstatValue(deaths)
end

-- [[ Abstract Methods ]] --
function Gamemode:Update()
	return
end

function Gamemode:Finalize()
	return
end

function Gamemode:IsRoundOver()
	return
end

function Gamemode:GetWinningTeam()
	return
end

return Gamemode
