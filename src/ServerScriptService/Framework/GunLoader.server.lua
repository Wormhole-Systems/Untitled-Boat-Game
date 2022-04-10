local ReplicatedStorage = game:GetService("ReplicatedStorage")

local weapons = ReplicatedStorage:WaitForChild("Weapons")
local assets = ReplicatedStorage:WaitForChild("Assets")
local sounds = assets:WaitForChild("Sounds")
local weaponSounds = sounds:WaitForChild("Weapon")
local gunSounds = weaponSounds:WaitForChild("Firearm")
for _,v in pairs (gunSounds:GetChildren()) do
	print(v.Name)
end

for _, pack in pairs (weapons:GetChildren()) do
	for _, slot in pairs (pack:GetChildren()) do
		if not slot:IsA("Configuration") then --make sure the folder isn't a config for the pack metadata
			for _, class in pairs(slot:GetChildren()) do --iterate over weapon classes 
				for _, gun in pairs(class:GetChildren()) do
					if gun:IsA("Tool") then
						local config = gun:FindFirstChild("Configuration")
						local magState = config:FindFirstChild("MagStateServer")
						if magState then
							local module = require(config.Module.Value)
							local magSize = module.MagazineSize
							config.MagStateServer.Value = magSize
							config.MagStateClient.Value = magSize
						end
						print(gun.Name .. " " .. class.Name)
						local gunSoundFolder = gunSounds:FindFirstChild(gun.Name)
						if not gunSoundFolder then --if there's no sound folder for the gun then get its generic gun class sounds
							gunSoundFolder = gunSounds:FindFirstChild(class.Name)
							print("No sound folder for "..gun.Name.." found")
							if not gunSoundFolder then --super generic gun sound for guns
								gunSoundFolder = gunSounds:FindFirstChild("Gun")
							end
						end
						
						if gunSoundFolder then
							for _, sound in pairs(gunSoundFolder:GetChildren()) do
								sound:Clone().Parent = gun.Handle
								print("Cloning " .. sound.Name .. " into " .. gun.name)
							end
						else 
							print("No sound folder for this weapon or class found")
						end
					end
				end
			end
		end
	end
end