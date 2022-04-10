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
	newPistol.AttackSpeed = 14
	newPistol.MagazineSize = 60
	newPistol.ReloadTime = 2.75
	--[[
	newPistol.Spread = 10
	newPistol.PelletCount = 100
	--]]
	----[[
	newPistol.Spread = 4
	newPistol.PelletCount = 1
	--]]
	newPistol.ProjectileRange = 600
	
	return newPistol
end

return Pistol.new()
