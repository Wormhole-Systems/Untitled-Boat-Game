local player = game.Players.LocalPlayer
local parent = script.Parent
local weaponNameUI = parent.WeaponName
local ammoUI = parent.Ammo
local ammo = ammoUI.Ammo

local changeFunc

local function charChildAdded(thing)
	if (thing:IsA("Tool")) then
		weaponNameUI.Text = thing.Name
		parent.Visible = true
		if (thing.Configuration:FindFirstChild("ReloadingClient")) then --if it's a firearm
			ammoUI.Visible = true
			
			--local module = require(thing.Module.Value) --get the module of the firearm
			
			local magVal = thing.Configuration.MagStateClient
						
			--local magSiPri = module.MagazineSizePrimary
			
			ammo.MagStateLabel.Text = magVal.Value
			--ammoPri.MagSizeLabel.Text = "/"..magSiPri
			
			changeFunc = magVal.Changed:Connect(function (newVal)
				ammo.MagStateLabel.Text = newVal
			end)
			

			local maxMag = require(thing.Configuration.Module.Value).MagazineSize
			--print(thing.Configuration.Module.Value.Name)
			--print(maxMag)
			ammo.MagSizeLabel.Text = "/"..maxMag
			
		else
			ammo.Visible = false
		end
	end
end

local function charChildRemoved(thing)
	if (thing:IsA("Tool")) then
		if changeFunc then
			changeFunc:Disconnect()
			changeFunc = nil
		end
		parent.Visible = false
	end
	
end

local function charAdded(char)
	char.ChildAdded:Connect(charChildAdded)
	char.ChildRemoved:Connect(charChildRemoved)
end

script.Parent.Visible = false

player.CharacterAdded:Connect(charAdded)

charAdded(player.Character)