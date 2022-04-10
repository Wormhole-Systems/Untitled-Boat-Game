local ReplicatedStorage = game:GetService("ReplicatedStorage")
local invokers = ReplicatedStorage.Invokers.Weapon

local fireEvent = invokers.FireWeapon
local reloadEvent = invokers.ReloadWeapon

local module = require(ReplicatedStorage.Framework.FireWeaponModule)

module.InitializeModules(ReplicatedStorage.Framework.Weapon)

local function fireServer(player, tool, dir, seed)
	fireEvent:FireAllClients(player, tool, dir, seed)
	module.FireWeapon(player, tool, dir, seed)
end

local function reloadServer(player, tool)
	reloadEvent:FireAllClients(player, tool)
	module.ReloadWeapon(player, tool)
end

fireEvent.OnServerEvent:Connect(fireServer)
reloadEvent.OnServerEvent:Connect(reloadServer)
