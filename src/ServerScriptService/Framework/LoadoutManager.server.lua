local Players = game:GetService("Players")

local loadoutFolder = game:GetService("ServerStorage").Loadout

Players.PlayerAdded:Connect(function (player)
	--spawn in the loadout folder on player join
	local loadout = loadoutFolder.Loadout:Clone()
	loadout.Parent = player
	
	player.CharacterAdded:Connect(function (char)
		local priProto = loadout.Primary.Value
		local secProto = loadout.Secondary.Value
		local throwProto = loadout.Thrown.Value
		
		local priModule
		local secModule
		
		if priProto then
			local priClone = priProto:Clone()
			priModule = priProto.Configuration.Module.Value
			priClone.Configuration.Module.Value = priModule
			priClone.Parent = player.Backpack
		end	
		if secProto then
			local secClone = secProto:Clone()
			secModule = secProto.Configuration.Module.Value
			secClone.Configuration.Module.Value = secModule
			secClone.Parent = player.Backpack
		end
		if throwProto then
			local throwClone = throwProto:Clone()
			local throwModule = throwProto.Configuration.Module.Value
			local throwmod = require(throwModule)
			throwClone.Configuration.Module.Value = throwModule
			throwClone.Parent = player.Backpack
			throwClone.Configuration.Ammo.Value = throwmod.MaxAmmo
		end
		
		--[[
		--initializing the thrown config folder
		local thrownFolderClone = loadoutFolder.Thrown:Clone()
		thrownFolderClone.Parent = player.Backpack
		local thrownLeft = thrownFolderClone.ThrownAmmo
		--set up the max ammo of the thrown thing
		if throwModule then
			local throwmod = require(throwModule)
			thrownLeft.Value = throwmod.MaxAmmo
		end
		]]
		
		--checking for tool equip
		char.ChildAdded:Connect(function (thing)
			if thing:IsA("Tool")then
				if char.Humanoid.Sit then
					local vehicleOwner = char.Humanoid.SeatPart.Parent.Configuration.Owner.Value
					if player ~= vehicleOwner then
						delay(1/30, function()
							for _, v in pairs(char.Humanoid.SeatPart.Parent:GetDescendants()) do
								if v:IsA("BasePart") then
									v:SetNetworkOwner(vehicleOwner)
								end
							end
						end)
					end
				end
				local config = thing:FindFirstChild("Configuration")
				if config then
					local modVal = config:FindFirstChild("Module")
					--if this is a weapon with a module in its config then
					if modVal then
						local module = modVal.Value
						if not (module and (module.Name == priModule.Name or module.Name == secModule.Name)) then
							print(player.Name .. " just equipped a thing they're not supposed to have!")
						end
					end
				end
			end
		end)
	end)
end)