local Firearm = require(script.Parent)

local Pistol = {}
--Pistol.__index = Pistol
--setmetatable(Pistol, Firearm)
Pistol.Metatable = {__index = Pistol}
setmetatable(Pistol, {__index = Firearm})

function Pistol.new()
	local newPistol = Firearm.new()
	setmetatable(newPistol, Pistol.Metatable)
	
	newPistol.Damage = 4
	newPistol.AttackSpeed = 7
	newPistol.MagazineSize = 40
	newPistol.ReloadTime = 2.75
	--[[
	newPistol.Spread = 10
	newPistol.PelletCount = 100
	--]]
	----[[
	newPistol.Spread = 2
	newPistol.PelletCount = 1
	--]]
	newPistol.AimZoom = 4
	newPistol.ProjectileRange = 1000
	
	return newPistol
end

return Pistol.new()
