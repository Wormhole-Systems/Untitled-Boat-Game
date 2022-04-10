local module = {}

--table of pre-required modules
local modules = {}

--initializes the modules table by requiring the entire Weapon directory
local function initializeModules(mod)
	--create a list of modules to require
	local weaponMod = mod
	local libs = weaponMod:GetDescendants()
	table.insert(libs, weaponMod)
	--iterate over the list of modules and put them in modules, indexed by module name
	for _, m in pairs(libs) do
		--print("Initializing module "..m.Name)
		local success, module = pcall(function() return require(m).new() end)
		if success then 
			modules[m.Name] = module
		else
			print("Error initializing module "..m.Name..":")
			print(module)
		end
	end
end

--function that implements FireWeapon event in ReplicatedStorage.Invoker
--fires a given weapon server-side
local function fireWeapon (player, tool, spot, seed)
	--local tool = player.Character:FindFirstChildOfClass("Tool")	
	--print("Barrel position on server:", barrelPos)
	--print("Firing weapon toolName: "..tool.Name.. " Modulename: "..tool.Module.Value.Name)
	--get the respective module implementation for that weapon
	local weaponModule = modules[tool.Configuration.Module.Value.Name]
	
	weaponModule:AttemptAttack(player, tool, spot, seed)
end

local function reloadWeapon (player, tool)
	--print("Reloading weapon toolName: "..tool.Name.. " Modulename: "..tool.Configuration.Module.Value.Name)
	--get the respective module implementation for that weapon
	local weaponModule = modules[tool.Configuration.Module.Value.Name]
	weaponModule:Reload(player, tool)
end

module.Modules = modules
module.InitializeModules = initializeModules
module.FireWeapon = fireWeapon
module.ReloadWeapon = reloadWeapon

return module
