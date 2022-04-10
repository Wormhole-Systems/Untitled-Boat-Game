local ReplicatedStorage = game:GetService("ReplicatedStorage")
local invokers = ReplicatedStorage.Invokers.Weapon

local fireEvent = invokers.FireWeapon
local reloadEvent = invokers.ReloadWeapon

local module = require(script.Parent.FireWeaponClientModule)

fireEvent.OnClientEvent:Connect(module.FireWeaponClients)
reloadEvent.OnClientEvent:Connect(module.ReloadWeaponClients)