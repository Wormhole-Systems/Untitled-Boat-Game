local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local event = ReplicatedStorage.Invokers.Loadout.SetAppearance

event.OnServerEvent:Connect(function (player, huma)
	print("bepman")
	if huma.Parent and Players:GetPlayerFromCharacter(huma.Parent) then return end
	local oldParent = huma.Parent.Parent
	huma.Parent.Parent = game.Workspace
	huma:ApplyDescription(Players:GetHumanoidDescriptionFromUserId(player.UserId))
	huma.Parent.Parent = oldParent
end)