
local IGNORE_TAG = "ProjectileIgnore"

local Players = game:GetService("Players")
local Collections = game:GetService("CollectionService")

local function tagCharHats(char)
	for _,v in pairs (char:GetChildren()) do
		--if the thing is a hat then tag all the children of the hat as toIgnore
		if v:IsA("Accoutrement") then
			Collections:AddTag(v, IGNORE_TAG)
		end
	end
end

local function connectHatTagger(player)
	player.CharacterAppearanceLoaded:Connect(tagCharHats)
end


Players.PlayerAdded:Connect(connectHatTagger)