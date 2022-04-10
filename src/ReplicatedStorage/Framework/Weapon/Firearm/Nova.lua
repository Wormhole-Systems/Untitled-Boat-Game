local Firearm = require(script.Parent)

local Pistol = {}
--Pistol.__index = Pistol
--setmetatable(Pistol, Firearm)
Pistol.Metatable = {__index = Pistol}
setmetatable(Pistol, {__index = Firearm})

function Pistol.new()
	local newPistol = Firearm.new()
	setmetatable(newPistol, Pistol.Metatable)
	
	newPistol.Damage = 1
	newPistol.AttackSpeed = 5
	newPistol.MagazineSize = 20
	newPistol.ReloadTime = .5
	--[[
	newPistol.Spread = 10
	newPistol.PelletCount = 100
	--]]
	----[[
	newPistol.Spread = 360
	newPistol.PelletCount = 100
	--]]
	newPistol.ProjectileRange = 30
	
	return newPistol
end

return Pistol.new()
