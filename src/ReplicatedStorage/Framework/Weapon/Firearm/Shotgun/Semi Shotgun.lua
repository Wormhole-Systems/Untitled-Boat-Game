local Firearm = require(script.Parent)

local Pistol = {}
--Pistol.__index = Pistol
--setmetatable(Pistol, Firearm)
Pistol.Metatable = {__index = Pistol}
setmetatable(Pistol, {__index = Firearm})

function Pistol.new()
	local newPistol = Firearm.new()
	setmetatable(newPistol, Pistol.Metatable)
	
	newPistol.Damage = 3
	newPistol.AttackSpeed = 3.333
	newPistol.MagazineSize = 6
	newPistol.ReloadTime = 1
	--[[
	newPistol.Spread = 10
	newPistol.PelletCount = 100
	--]]
	----[[
	newPistol.Spread = 10
	newPistol.PelletCount = 14
	--]]
	newPistol.ProjectileRange = 100
	
	return newPistol
end

return Pistol.new()
