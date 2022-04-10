local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Market = game:GetService("MarketplaceService")

local func = ReplicatedStorage.Invokers.Loadout.SetLoadout

--[[args
	weaponSlot - a String with the name of the weapon slot to change to
		Primary
		Secondary
		Thrown
	weapon - the prototype tool found in the Weapons folder of ReplicatedStorage to clone
	
	returns whether the gamepass check was a success then whether the player has the pass
--]]
local function setLoadout(player, weaponSlot, weapon)
	local packID = weapon.Parent.Parent.Parent.Configuration.ProductID.Value
	
	local hasPass, success, message
	if packID ~= 0 then
		success, message = pcall(function ()
			hasPass = Market:UserOwnsGamePassAsync(player.UserId, packID)
		end) 
	else
		hasPass = true
		success = true
	end
	
	
	if success then
		if hasPass then
			local loadout = player.Loadout
			local slot = loadout:FindFirstChild(weaponSlot)
			if slot then
				slot.Value = weapon
				return true, true
			else
				error("Weapon slot \""..weaponSlot.."\" not found")
			end
		else
			return true, false
		end
	else 
		return false
	end
end

func.OnServerInvoke = setLoadout