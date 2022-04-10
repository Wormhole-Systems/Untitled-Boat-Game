local weapon = require(script.Parent)

local RunService = game:GetService("RunService")

local thrown = {}
thrown.Metatable = {__index = thrown}
setmetatable(thrown, {__index = weapon})

function thrown.new()
	local newThrown = weapon.new()
	setmetatable(newThrown, thrown.Metatable)
	
	newThrown.MaxAmmo = 5
	
	return newThrown
end

--function swingAnimation

function thrown:AttemptAttack(player, tool, direction, seed)
	if (RunService:IsServer()) then
		local config = tool.Configuration
		local valid, timeo = self:ValidateAttack(config)
		print(tostring(valid))
		if valid then
			local lastFireVal = config.LastAttack
			config.Ammo.Value = config.Ammo.Value - 1
			lastFireVal.Value = timeo
			self:Attack(player, direction, seed)
			self:Rearm(tool,  timeo)
		end
	end
end

--verifies whether the weapon can attack again
function thrown:ValidateAttack(config)
	
	local nowTime = tick()
	local toReturn = false
	local lastFireVal = config.LastAttack
	
	local speed = self.AttackSpeed
	local dif = nowTime - lastFireVal.Value
	print (dif.." - ".. 1/speed)
	toReturn = dif > 1/speed and config.Ammo.Value > 0
	return toReturn, nowTime
end

--updates values after a weapon has fired
function thrown:Rearm(tool, timeo)
	local config = tool.Configuration
end

function thrown:Attack(player, direction, seed) 
	print("Okoko")
end

return thrown.new()
