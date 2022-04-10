local FlagStandManager = {}

-- [[ Roblox Services ]] --
local Players = game.Players

-- [[ Game Services ]] --
local Configurations = require(game.ServerStorage.Configurations)

-- Local Variables
local flagObjects = {}
local flagCarriers = {}
local events = game.ReplicatedStorage.RoundEvents
local captureFlag = events.CaptureFlag
local returnFlag = events.ReturnFlag

-- [[ Local Functions ]] --
local makeFlag

local function destroyFlag(flagObject)
	if flagObject.Flag then flagObject.Flag:Destroy() end
	for player, object in pairs(flagCarriers) do
		if object == flagObject then
			flagCarriers[player] = nil
		end
	end
end

local function onCarrierDied(player)
	local flagObject = flagCarriers[player]
	if flagObject then
		local flagPole = flagObject.FlagPole
		local flagBanner = flagObject.FlagBanner
		
		flagPole.CanCollide = true
		flagBanner.CanCollide = true
		flagPole.Anchored = false
		flagBanner.Anchored = false
		
		if flagPole:FindFirstChild("PlayerFlagWeld") then
			flagPole.PlayerFlagWeld:Destroy()
		end
		
		flagObject.PickedUp = false		
		
		flagCarriers[player] = nil
		
		if Configurations.RETURN_FLAG_ON_DROP then
			wait(Configurations.FLAG_RESPAWN_TIME)
			if not flagObject.AtSpawn and not flagObject.PickedUp then
				destroyFlag(flagObject)
				makeFlag(flagObject)
				returnFlag:Fire(flagObject.Team.Name)
			end
		end
	end
end

local function pickupFlag(player, flagObject)
	flagCarriers[player] = flagObject
	flagObject.AtSpawn = false
	flagObject.PickedUp = true
	
	local torso
	if player.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
		torso = player.Character:FindFirstChild('Torso')
	else
		torso = player.Character:FindFirstChild('UpperTorso')
	end
	local flagPole = flagObject.FlagPole
	local flagBanner = flagObject.FlagBanner
	
	flagPole.Anchored = false
	flagBanner.Anchored = false
	flagPole.CanCollide = false
	flagBanner.CanCollide = false
	local weld = Instance.new('Weld')
	weld.Name = 'PlayerFlagWeld'
	weld.Part0 = flagPole
	weld.Part1 = torso
	weld.C0 = CFrame.new(0, 0, -1) * CFrame.Angles(0, 0, math.rad(40))
	weld.Parent = flagPole
end

local function bindFlagTouched(flagObject)
	local flagPole = flagObject.FlagPole
	local flagBanner = flagObject.FlagBanner
	flagObject.FlagTouched = flagPole.Touched:connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if not player then return end
		if not player.Character then return end
		local humanoid = player.Character:FindFirstChild('Humanoid')
		if not humanoid then return end
		if humanoid.Health <= 0 then return end
		if flagBanner.BrickColor ~= player.TeamColor and not flagObject.PickedUp then
			pickupFlag(player, flagObject)
			local humanoidDiedConn; humanoidDiedConn = humanoid.Died:Connect(function()
				onCarrierDied(player)
				humanoidDiedConn:Disconnect()
			end)
		elseif flagBanner.BrickColor == player.TeamColor and not flagObject.AtSpawn and Configurations.FLAG_RETURN_ON_TOUCH then
			destroyFlag(flagObject)
			makeFlag(flagObject)
			returnFlag:Fire(flagObject.Team.Name)
		end
	end)
end

function makeFlag(flagObject)
	flagObject.Flag = flagObject.FlagCopy:Clone()
	flagObject.Flag.Parent = flagObject.FlagContainer
	flagObject.FlagPole = flagObject.Flag.FlagPole
	flagObject.FlagBanner = flagObject.Flag.FlagBanner
	flagObject.FlagBanner.CanCollide = false
	flagObject.AtSpawn = true
	flagObject.PickedUp = false
	bindFlagTouched(flagObject)
end

local function bindBaseTouched(flagObject)
	local flagBase = flagObject.FlagBase
	flagObject.BaseTouched = flagBase.Touched:connect(function(otherPart)
		local player = Players:GetPlayerFromCharacter(otherPart.Parent)
		if not player then return end
		if flagBase.BrickColor == player.TeamColor and flagCarriers[player] then
			captureFlag:Fire(player)
			local otherFlag = flagCarriers[player]
			destroyFlag(otherFlag)
			makeFlag(otherFlag)
		end
	end)
end

-- [[ Public Functions ]] --
function FlagStandManager:Init(container)
	local flagObject = {}
	
	local success, message = pcall(function()
		flagObject.AtSpawn = true	
		flagObject.PickedUp = false
		flagObject.TeamColor = container.FlagStand.BrickColor
		flagObject.Flag = container.Flag
		flagObject.FlagPole = container.Flag.FlagPole
		flagObject.FlagBanner = container.Flag.FlagBanner
		flagObject.FlagBase = container.FlagStand
		flagObject.FlagCopy = container.Flag:Clone()	
		flagObject.FlagContainer = container
		
		for _, v in pairs(game.Teams:GetTeams()) do
			if v.TeamColor == flagObject.TeamColor then
				flagObject.Team = v
				break
			end
		end
	end)
	if not success then
		warn("Flag object not built correctly. Please load fresh template to see how flag stand is expected to be made.")
	end
	
	bindBaseTouched(flagObject)
	destroyFlag(flagObject)
	makeFlag(flagObject)
	
	table.insert(flagObjects, flagObject)
	
	-- Flag destroyed event
	local destroyedConn
	destroyedConn = container.AncestryChanged:Connect(function()
		if container.Parent == nil then
			flagObject.FlagTouched:Disconnect()
			flagObject.BaseTouched:Disconnect()
			destroyedConn:Disconnect()
			
			for i, v in pairs(flagObjects) do
				if v == flagObject then
					table.remove(flagObjects, i)
				end
			end
			
			flagObject = nil
		end
	end)
end

return FlagStandManager
