local Players = game:GetService("Players")
--local ReplicatedFirst = game:GetService("ReplicatedFirst")

local player = Players.LocalPlayer

--local gameTools = require(ReplicatedFirst.GameTools)

local loadout = player.Loadout
local thrownAmmoHUD = player.PlayerGui.GameHUD.ThrownStatus

local weaponDisplay = script.Parent.WeaponDisplay
local ammoDisplay = script.Parent.AmmoDisplay

local function charAdd(character)
	local ammoVal = player.Backpack:WaitForChild("Thrown").Configuration.Ammo
	ammoDisplay.Text = "x"..ammoVal.Value
	--gameTools.setViewportFrameContent(weaponDisplay, loadout.Thrown.Value:Clone(), Vector3.new(0,0,-1), true)
	ammoVal.Changed:Connect(function(value)
		ammoDisplay.Text = "x"..value
	end)
end

charAdd(player.Character)
player.CharacterAdded:Connect(charAdd)