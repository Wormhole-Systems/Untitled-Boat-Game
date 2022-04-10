local PlayerManager = {}

-- [[ Constants ]] --
local ZOMBIE_COLOR = Color3.fromRGB(80, 109, 84)

-- [[ Roblox Services ]] --
local Players = game.Players
local Teams = game:GetService("Teams")

-- [[ Game Services ]] --
local Configurations = require(game.ServerStorage.Configurations)
local TeamManager = require(script.Parent.TeamManager)
local DisplayManager = require(script.Parent.DisplayManager)

-- [[ Local Variables ]] --
local events = game.ReplicatedStorage.RoundEvents
local resetMouseIcon = events.ResetMouseIcon
local changeTeam = events.ChangeTeam
local playersCanSpawn = false
local gameRunning = false
local currentLeaderstats = {}

-- [[ Local Functions ]] --
local function loadCharacter(player)
	if player.Team and player.Team.Name == "Infected" then
		local humanoidDescription = game.Players:GetHumanoidDescriptionFromUserId(player.UserId > 0 and player.UserId or 7155946)
		
		-- Change body colors
		humanoidDescription.HeadColor = ZOMBIE_COLOR
		humanoidDescription.LeftArmColor = ZOMBIE_COLOR
		humanoidDescription.LeftLegColor = ZOMBIE_COLOR
		humanoidDescription.RightArmColor = ZOMBIE_COLOR
		humanoidDescription.RightLegColor = ZOMBIE_COLOR
		humanoidDescription.TorsoColor = ZOMBIE_COLOR
		
		-- Change animations
		humanoidDescription.ClimbAnimation = 619535091
		humanoidDescription.FallAnimation = 619535616
		humanoidDescription.IdleAnimation = 619535834
		humanoidDescription.JumpAnimation = 619536283
		humanoidDescription.RunAnimation = 619536621
		humanoidDescription.SwimAnimation = 619537096
		humanoidDescription.WalkAnimation = 619537468
		
		player:LoadCharacterWithHumanoidDescription(humanoidDescription)
		local character = player.Character or player.CharacterAdded:Wait()
		character:WaitForChild("Humanoid").WalkSpeed = 10		
	else
		player:LoadCharacter()
	end
end

local function onPlayerAdded(player)
	-- Setup leaderboard stats
	local leaderstats = Instance.new('Folder')
	leaderstats.Name = 'leaderstats'
	leaderstats.Parent = player
	
	-- Add current round's leaderboard stats
	for _, v in pairs(currentLeaderstats) do
		v:Clone().Parent = leaderstats
	end
			
	-- Add player to team if not in intermission
	if playersCanSpawn then
		TeamManager:AssignPlayerToTeam(player)
	end
	
	-- Respawn manager
	player.CharacterAdded:connect(function(character)
		player.CameraMinZoomDistance = 10
		player.CameraMaxZoomDistance = 10
		character:WaitForChild('Humanoid').Died:connect(function()
			wait(Configurations.RESPAWN_TIME)
			if playersCanSpawn then
				loadCharacter(player)
			end
		end)
	end)
		
	-- Check if player should be spawned	
	if playersCanSpawn then
		loadCharacter(player)
	else
		DisplayManager:StartIntermission(player)
	end	
end

local function onPlayerRemoving(player)
	if playersCanSpawn then return end
	
end

local function onChangeTeamRequest(player, teamName)
	if type(teamName) ~= "string" then return end
	local team = Teams:FindFirstChild(teamName)
	if not playersCanSpawn and team and #team:GetPlayers() < #game.Players:GetPlayers()/2 then
		player.Neutral = false
		player.TeamColor = Teams:FindFirstChild(teamName).TeamColor
		return true
	end
	return false
end

-- [[ Public Functions ]] --
function PlayerManager:ClearLeaderstats()
	-- Clear leaderstats for all players
	for _, player in pairs(Players:GetPlayers()) do
		if player:FindFirstChild("leaderstats") then
			player.leaderstats:ClearAllChildren()
		end
	end
	
	currentLeaderstats = {}
end

function PlayerManager:AddLeaderstatValue(value)
	for _, player in pairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			value:Clone().Parent = leaderstats
		end
	end
	table.insert(currentLeaderstats, value)
end

function PlayerManager:SetGameRunning(running)
	gameRunning = running
end

function PlayerManager:AllowPlayerSpawn(allow)
	playersCanSpawn = allow
end

function PlayerManager:LoadPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		loadCharacter(player)
	end
end

function PlayerManager:DestroyPlayers()
	for _, player in pairs(Players:GetPlayers()) do
		player.Character:Destroy()
		for _, item in pairs(player.Backpack:GetChildren()) do
			item:Destroy()
		end
	end
	resetMouseIcon:FireAllClients()
end

function PlayerManager:AddPlayerScore(player, score)
	player.leaderstats.Captures.Value = player.leaderstats.Captures.Value + score
end

-- [[ Event & Function Binding ]] --
Players.PlayerAdded:Connect(onPlayerAdded)
changeTeam.OnServerInvoke = onChangeTeamRequest

return PlayerManager