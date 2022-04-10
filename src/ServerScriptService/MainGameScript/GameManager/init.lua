local GameManager = {}

-- [[ Gamemodes ]] --
local gamemodes = {}
local gamemodesFolder = script.Parent:WaitForChild("Gamemode")
--for _, v in pairs(gamemodesFolder:GetChildren()) do table.insert(gamemodes, require(v)) end
----[[
local ctf = require(gamemodesFolder["CTF"])
local elimination = require(gamemodesFolder["Elimination"])
local monopoly = require(gamemodesFolder["Monopoly"])
local zombies = require(gamemodesFolder["Zombies"])
gamemodes = {ctf, zombies, monopoly, elimination}
--]]
local currentGamemode = nil
local gamemodeObject = game.Workspace:WaitForChild("Status"):WaitForChild("Gamemode")

-- [[ Roblox Services ]] --
local Players = game.Players

-- [[ Game Services ]] --
local Configurations = require(game.ServerStorage.Configurations)
local TeamManager = require(script.TeamManager)
local PlayerManager = require(script.PlayerManager)
local MapManager = require(script.MapManager)
local TimeManager = require(script.TimeManager)
local DisplayManager = require(script.DisplayManager)

-- [[ Local Variables ]] --
local intermissionRunning = false
local enoughPlayers = false
local gameRunning = false
local events = game:GetService("ReplicatedStorage").RoundEvents
local captureFlag = events.CaptureFlag
local returnFlag = events.ReturnFlag
local destroyVehicle = game:GetService("ReplicatedStorage").Invokers.Vehicle.DestroyVehicle

-- [[ Public Functions ]] --
function GameManager:Initialize()
	--MapManager:SaveMap()
end

function GameManager:InitializeGamemode(gamemodeNumber)
	currentGamemode = gamemodes[gamemodeNumber]
	currentGamemode:Initialize()
	gamemodeObject.Value = currentGamemode.Name
	TeamManager:Initialize()
	--TeamManager:ShuffleTeams()
end

function GameManager:RunIntermission(gamemodeNumber)
	intermissionRunning = true
	TimeManager:StartTimer(Configurations.INTERMISSION_DURATION)
	--DisplayManager:StartIntermission() -- done inside gamemode initialization now
	enoughPlayers = Players.NumPlayers >= Configurations.MIN_PLAYERS	
	DisplayManager:UpdateTimerInfo(true, not enoughPlayers)
	spawn(function()
		repeat
			if enoughPlayers and Players.NumPlayers < Configurations.MIN_PLAYERS then
				enoughPlayers = false
			elseif not enoughPlayers and Players.NumPlayers >= Configurations.MIN_PLAYERS then
				enoughPlayers = true
			end
			DisplayManager:UpdateTimerInfo(true, not enoughPlayers)
			wait(.5)
		until intermissionRunning == false
	end)
	
	wait(Configurations.INTERMISSION_DURATION)
	intermissionRunning = false
end

function GameManager:StopIntermission()
	--intermissionRunning = false
	DisplayManager:UpdateTimerInfo(false, false)
	DisplayManager:StopIntermission()
end

function GameManager:GameReady()
	return Players.NumPlayers >= Configurations.MIN_PLAYERS
end

function GameManager:StartRound()
	currentGamemode:AddLeaderstatValues()
	TeamManager:ShuffleTeams()
	PlayerManager:AllowPlayerSpawn(true)
	PlayerManager:LoadPlayers()
	gameRunning = true
	PlayerManager:SetGameRunning(true)
	TimeManager:StartTimer(Configurations["ROUND_DURATION_"..currentGamemode.Codename] or Configurations.ROUND_DURATION)
end

function GameManager:Update()
	currentGamemode:Update()
end

function GameManager:RoundOver()
	local gamemodeCriteriaWin = currentGamemode:IsRoundOver()
	if gamemodeCriteriaWin then
		local winningTeam = currentGamemode:GetWinningTeam()
		if winningTeam then
			DisplayManager:DisplayVictory(winningTeam)
		else
			DisplayManager:DisplayVictory('Tie')
		end
		return true
	end
	if TimeManager:TimerDone() then
		local winningTeam = currentGamemode:GetWinningTeam()
		if winningTeam then
			DisplayManager:DisplayVictory(winningTeam)
		else
			DisplayManager:DisplayVictory('Tie')
		end
		return true
	end
	return false
end

function GameManager:RoundCleanup()
	PlayerManager:SetGameRunning(false)
	TimeManager:StartTimer(Configurations.END_GAME_WAIT)
	wait(Configurations.END_GAME_WAIT)
	destroyVehicle:FireAllClients(true)
	game.Workspace.Vehicles:ClearAllChildren()
	currentGamemode:Finalize()
	PlayerManager:ClearLeaderstats()
	PlayerManager:AllowPlayerSpawn(false)
	PlayerManager:DestroyPlayers()
	DisplayManager:DisplayVictory(nil)
	TeamManager:ClearTeams()
	--TeamManager:ShuffleTeams()
	--MapManager:ClearMap()
	--MapManager:LoadMap()
end

return GameManager
