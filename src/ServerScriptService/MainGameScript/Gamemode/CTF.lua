local CTF = setmetatable({}, require(script.Parent))

-- [[ Roblox Services ]] --
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

-- [[ Events ]] --
local events = game:GetService("ReplicatedStorage"):WaitForChild("RoundEvents")
local captureFlag = events:WaitForChild("CaptureFlag")
local returnFlag = events:WaitForChild("ReturnFlag")
local captureFlagConn, returnFlagConn

-- [[ Flag Models ]]--
local models = ServerStorage:WaitForChild("Models")
local flagStandAlpha = models:WaitForChild("FlagStandAlpha")
local flagStandBravo = models:WaitForChild("FlagStandBravo")
local flagAlpha, flagBravo

-- [[ CTF Leaderstats ]]--
local captures = Instance.new("IntValue")
captures.Name = "Captures"

-- [[ Teams ]] --
local teams = {}

-- [[ Static Values ]] --
CTF.Name = "Capture the Flag"
CTF.Codename = "CTF"
CTF.Description = "Steal the enemy team's flag from their base and\n\
						bring it back to your base successfully for a capture.\n\
						The team with the most amount of captures wins!"

-- [[ Private Functions ]] --
local function onCaptureFlag(player)
	CTF.PlayerManager:AddPlayerScore(player, 1)
	CTF.TeamManager:AddTeamScore(player.Team, 1)
	CTF.DisplayManager:DisplayNotification(player.Team.Name, 'Captured Flag!')
end

local function onReturnFlag(flagTeam)
	CTF.DisplayManager:DisplayNotification(flagTeam, 'Flag Returned!')
end

-- [[ Public Functions ]]--
function CTF:Initialize()
	getmetatable(CTF):Initialize()
	
	-- Bind events
	captureFlagConn = captureFlag.Event:Connect(onCaptureFlag)
	returnFlagConn = returnFlag.Event:Connect(onReturnFlag)
	
	-- Add flags
	flagAlpha = flagStandAlpha:Clone()
	flagAlpha:SetPrimaryPartCFrame(flagAlpha.CFrameValue.Value)
	flagAlpha.Parent = game.Workspace.Map
	flagBravo = flagStandBravo:Clone()
	flagBravo:SetPrimaryPartCFrame(flagBravo.CFrameValue.Value)
	flagBravo.Parent = game.Workspace.Map
		
	-- Add teams
	for _, v in pairs(Teams:GetTeams()) do
		table.insert(teams, v)
	end
end

function CTF:Finalize()
	-- Unbind events
	captureFlagConn:Disconnect()
	returnFlagConn:Disconnect()
	
	-- Destroy flags
	flagAlpha:Destroy()
	flagBravo:Destroy()
	
	-- Clear teams
	teams = {}
	winningTeam = nil
end

function CTF:AddLeaderstatValues()
	getmetatable(CTF):AddLeaderstatValues()
	CTF.PlayerManager:AddLeaderstatValue(captures)
end

function CTF:IsRoundOver()
	local score
	winningTeam, score = CTF.TeamManager:GetWinningTeam()
	return score >= CTF.Configurations.CAPS_TO_WIN
end

function CTF:GetWinningTeam()
	return winningTeam
end

return CTF
