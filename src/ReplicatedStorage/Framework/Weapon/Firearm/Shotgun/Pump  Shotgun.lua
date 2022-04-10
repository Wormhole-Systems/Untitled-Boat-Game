local Firearm = require(script.Parent)

local PumpShotgun = {}
--PumpShotgun.__index = PumpShotgun
--setmetatable(PumpShotgun, Firearm)
PumpShotgun.Metatable = {__index = PumpShotgun}
setmetatable(PumpShotgun, {__index = Firearm})

function PumpShotgun.new()
	local newPumpShotgun = Firearm.new()
	setmetatable(newPumpShotgun, PumpShotgun.Metatable)
	
	newPumpShotgun.Damage = 3
	newPumpShotgun.AttackSpeed = 1
	newPumpShotgun.MagazineSize = 6
	newPumpShotgun.ReloadTime = 1.01
	--[[
	newPumpShotgun.Spread = 10
	newPumpShotgun.PelletCount = 100
	--]]
	----[[
	newPumpShotgun.Spread = 10
	newPumpShotgun.PelletCount = 14
	--]]
	newPumpShotgun.ProjectileRange = 100
	
	return newPumpShotgun
end

return PumpShotgun.new()
