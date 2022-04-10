local TeamManager = {}

-- [[ Roblox Services ]] --
local Teams = game.Teams
local Players = game.Players

-- [[ Game Services ]] --
local Configurations = require(game.ServerStorage.Configurations)
local DisplayManager = require(script.Parent.DisplayManager)

-- [[ Local Variables ]] --
local teamScores = {}
local teams = {}

-- [[ Public Functions ]] --
function TeamManager:Initialize()
	teamScores = {}
	teams = Teams:GetTeams()
	for _, team in pairs(teams) do
		teamScores[team] = 0
	end
end

function TeamManager:AddTeam(name, color)
	local newTeam = Instance.new("Team")
	newTeam.Name = name
	newTeam.AutoAssignable = false
	newTeam.TeamColor = color
	newTeam.Parent = Teams
	teamScores[newTeam] = 0
	return newTeam
end

function TeamManager:ClearTeams()
	for _, team in pairs(teams) do
		teamScores[team] = 0
		DisplayManager:UpdateScore(team, 0)
	end
	Teams:ClearAllChildren()
	teams = {}
	for _, v in pairs(game.Players:GetPlayers()) do
		v.Neutral = true
		v.Team = nil
		v.TeamColor = BrickColor.new("White")
	end
end

function TeamManager:GetWinningTeam()
	local winningTeamScore = -1
	local winningTeam = nil
	for _, team in pairs(teams) do
		if teamScores[team] > winningTeamScore then
			winningTeamScore = teamScores[team]
			winningTeam = team
		elseif teamScores[team] == winningTeamScore then
			winningTeamScore = 0
			winningTeam = nil
			break
		end
	end
	return winningTeam, winningTeamScore
end

function TeamManager:AreTeamsTied()
	local teams = Teams:GetTeams()
	local highestScore = 0
	local tied = false
	for _, team in pairs(teams) do
		if teamScores[team] == highestScore then
			tied = true
		elseif teamScores[team] > highestScore then
			tied = false
			highestScore = teamScores[team]
		end
	end
	return tied
end

function TeamManager:AssignPlayerToTeam(player)
	local smallestTeam
	local lowestCount = math.huge
	for _, team in pairs(teams) do
		local numPlayersInTeam = #team:GetPlayers()
		if numPlayersInTeam < lowestCount then
			smallestTeam = team
			lowestCount = numPlayersInTeam
		end
	end
	if smallestTeam then
		player.Neutral = false
		player.TeamColor = smallestTeam.TeamColor
	end
end

function TeamManager:ShuffleTeams()
	local players = Players:GetPlayers()
	while #players > 0 do
		local rIndex = math.random(1, #players)
		local player = table.remove(players, rIndex)
		if player.Neutral or not player.Team then
			TeamManager:AssignPlayerToTeam(player)
		end
	end
end

function TeamManager:AddTeamScore(team, score)
	teamScores[team] = teamScores[team] + score
	DisplayManager:UpdateScore(team, teamScores[team])
end

function TeamManager:GetScore(team)
	return teamScores[team]
end

return TeamManager
