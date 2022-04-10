local Firearm = require(script.Parent)

local Pistol = {}
--Pistol.__index = Pistol
--setmetatable(Pistol, Firearm)
Pistol.Metatable = {__index = Pistol}
setmetatable(Pistol, {__index = Firearm})

function Pistol.new()
	local newPistol = Firearm.new()
	setmetatable(newPistol, Pistol.Metatable)
	
	newPistol.Damage = 2
	newPistol.AttackSpeed = 15
	newPistol.MagazineSize = 100000000
	newPistol.ReloadTime = 0
	--[[
	newPistol.Spread = 10
	newPistol.PelletCount = 100
	--]]
	----[[
	newPistol.Spread = 2
	newPistol.PelletCount = 1
	--]]
	newPistol.ProjectileRange = 1000
	newPistol.ProjectileSize = .5
	return newPistol
end

return Pistol.new()
