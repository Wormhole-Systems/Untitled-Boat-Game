local RunService = game:GetService("RunService")

local Weapon = {}
--Weapon.__index = Weapon

Weapon.Metatable = {__index = Weapon}

function Weapon.new()
	local newWeapon = {}
	setmetatable(newWeapon, Weapon.Metatable)	
	
	newWeapon.Name = "Weapon"
	newWeapon.Damage = 0
	newWeapon.AttackSpeed = 2 --frequency in Hertz
	
	return newWeapon
end

--[[
function Weapon:PlayAnimation(anim, animationTracks)
	for _, a in pairs(animationTracks) do
		if a ~= anim then
			a:Stop()
		end
	end
	if anim then anim:Play() end
end
]]

function Weapon:Initialize(humanoid)
	
end

function Weapon:Uninitialize()
	
end

function Weapon:AttemptAttack(player, tool, direction, seed)
	local valid, timeo = self:ValidateAttack(tool)
	if valid then
		self:Attack(player, tool, direction, seed)
		self:Rearm(tool, timeo)
	end
end

--verifies whether the weapon can attack again
function Weapon:ValidateAttack(tool)
	
	local nowTime = tick()
	local toReturn = false
	local lastFireVal = tool.Configuration.LastAttackClient
	
	if not RunService:IsClient() then
		lastFireVal = tool.Configuration.LastAttackServer
	end
	
	local speed = self.AttackSpeed
	local dif = nowTime - lastFireVal.Value
	toReturn = dif > 1/speed
	return toReturn, nowTime
end

--updates values after a weapon has fired
function Weapon:Rearm(tool, timeo)
	local lastFireVal = tool.Configuration.LastAttackClient
	
	if not RunService:IsClient() then
		lastFireVal = tool.Configuration.LastAttackServer
	end
	
	lastFireVal.Value = timeo
end

function Weapon:Attack(player, tool, direction, seed) 
	
end

return Weapon.new()
