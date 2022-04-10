-- Services
local Players = game:GetService("Players")

-- Variables
local setLoadoutAppearance = game:GetService("ReplicatedStorage"):WaitForChild("Invokers"):WaitForChild("Loadout"):WaitForChild("SetAppearance")
local dummy = game:GetService("ServerStorage"):WaitForChild("Models"):WaitForChild("Dummy")

Players.PlayerAdded:Connect(function(player)
	local hasToolOut = Instance.new("BoolValue")
	hasToolOut.Name = "HasToolOut"
	hasToolOut.Parent = player
	
	local needsVehicleMouse = Instance.new("BoolValue")
	needsVehicleMouse.Name = "NeedsVehicleMouse"
	needsVehicleMouse.Parent = player
	
	local ads = Instance.new("BoolValue")
	ads.Name = "ADS"
	ads.Parent = player
	
	local function addCharacterToReplicatedStorage(player)
		local char = dummy:Clone()
		char.Name = " "
		char.Parent = game.Workspace
		local humanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
		char.Humanoid:ApplyDescription(humanoidDescription)
		wait(1)
		char.Parent = nil
		setLoadoutAppearance:FireClient(player, char)
		wait(2)
		char:Destroy() -- get rid of it just in case it's wasting memory
	end
	
	-- Add character to Replicated Storage
	addCharacterToReplicatedStorage(player)
	player.CharacterAdded:Connect(function()
		addCharacterToReplicatedStorage(player)
	end)
end)

local function playerRemoving(player)
	
end

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		playerRemoving(player)
	end
end)
Players.PlayerRemoving:Connect(playerRemoving)