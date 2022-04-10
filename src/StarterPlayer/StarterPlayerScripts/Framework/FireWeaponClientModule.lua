local ReplicatedStorage = game:GetService("ReplicatedStorage")
local invokers = ReplicatedStorage.Invokers.Weapon

local fireEvent = invokers.FireWeapon
local reloadEvent = invokers.ReloadWeapon

local fireModule = require(ReplicatedStorage.Framework.FireWeaponModule)

fireModule.InitializeModules(ReplicatedStorage.Framework.Weapon)

local module = {}

local function fireWeaponLocal(player, tool, dir, seed)
	fireModule.FireWeapon(player, tool, dir, seed)
	fireEvent:FireServer(tool, dir, seed)
end

local function reloadWeaponLocal(player, tool)
	fireModule.ReloadWeapon(player, tool)
	reloadEvent:FireServer(tool)
end

local function fireWeaponClients(player, tool, dir, seed)
	if player ~= game.Players.LocalPlayer then
		fireModule.FireWeapon(player, tool, dir, seed)
	end
end

local function reloadWeaponClients(player, tool)
	if player ~= game.Players.LocalPlayer then
		fireModule.ReloadWeapon(player, tool)
	end	
end

module.FireWeaponLocal = fireWeaponLocal
module.FireWeaponClients = fireWeaponClients
module.ReloadWeaponLocal = reloadWeaponLocal
module.ReloadWeaponClients = reloadWeaponClients

return module