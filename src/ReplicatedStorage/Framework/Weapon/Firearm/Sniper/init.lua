local Firearm = require(script.Parent)

local Pistol = {}
--Pistol.__index = Pistol
--setmetatable(Pistol, Firearm)
Pistol.Metatable = {__index = Pistol}
setmetatable(Pistol, {__index = Firearm})

function Pistol.new()
	local newPistol = Firearm.new()
	setmetatable(newPistol, Pistol.Metatable)
	
	newPistol.AttackSpeed = .25
	newPistol.MagazineSize = 20
	newPistol.ReloadTime = 2
	--[[
	newPistol.Spread = 10
	newPistol.PelletCount = 100
	--]]
	----[[
	newPistol.Spread = 1.5
	newPistol.PelletCount = 1
	--]]
	newPistol.AimZoom = 8
	newPistol.ProjectileRange = 1000
	newPistol.ProjectileSpeed = 5000
	return newPistol
end

return Pistol.new()
