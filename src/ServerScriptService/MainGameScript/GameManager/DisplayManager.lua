local DisplayManager = {}

-- [[ Roblox Services ]] --
local Players = game.Players

-- [[ Local Variables ]] --
local events = game.ReplicatedStorage.RoundEvents
local displayIntermission = events.DisplayIntermission
local displayNotification = events.DisplayNotification
local displayTimerInfo = events.DisplayTimerInfo
local displayVictory = events.DisplayVictory
local displayScore = events.DisplayScore
local StarterGui = game.StarterGui

-- [[ Public Functions ]] --
local team1Name, team1Color, team2Name, team2Color
function DisplayManager:StartIntermission(...)
	local args = {...}
	local player = (typeof(args[1]) == "Instance" and args[1].Parent == game.Players) and args[1] or nil
	if player then
		displayIntermission:FireClient(player, true, team1Name, team1Color, team2Name, team2Color)
	else
		team1Name, team1Color, team2Name, team2Color = args[1], args[2], args[3], args[4]
		displayIntermission:FireAllClients(true, team1Name, team1Color, team2Name, team2Color)
	end
end

function DisplayManager:StopIntermission(player)
	if player then
		displayIntermission:FireClient(player, false)
	else
		displayIntermission:FireAllClients(false)
	end
end

function DisplayManager:DisplayNotification(teamColor, message)
	displayNotification:FireAllClients(teamColor, message)
end

function DisplayManager:UpdateTimerInfo(isIntermission, waitingForPlayers)
	displayTimerInfo:FireAllClients(isIntermission, waitingForPlayers)
end

function DisplayManager:DisplayVictory(winningTeam)
	displayVictory:FireAllClients(winningTeam)
end

function DisplayManager:UpdateScore(team, score)
	displayScore:FireAllClients(team, score)
end

return DisplayManager
