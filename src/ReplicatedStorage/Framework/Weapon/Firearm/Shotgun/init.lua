local Firearm = require(script.Parent)

local Shotgun = {}
--Shotgun.__index = Shotgun
--setmetatable(Shotgun, Firearm)
Shotgun.Metatable = {__index = Shotgun}
setmetatable(Shotgun, {__index = Firearm})

function Shotgun.new()
	local newShotgun = Firearm.new()
	setmetatable(newShotgun, Shotgun.Metatable)
	
	newShotgun.Damage = 3
	newShotgun.AttackSpeed = 2
	newShotgun.MagazineSize = 6
	newShotgun.ReloadTime = 1
	--[[
	newShotgun.Spread = 10
	newShotgun.PelletCount = 100
	--]]
	----[[
	newShotgun.Spread = 10
	newShotgun.PelletCount = 14
	--]]
	newShotgun.ProjectileRange = 100
	
	return newShotgun
end

function Shotgun:Reload(player, tool)
	--print("attempting to reload")
	
	local config = tool.Configuration
	
	local reloading = config.Reloading
	local magState = config.MagState
	--make sure we're not already reloading
	if not reloading.Value and magState.Value < self.MagazineSize then
		--print("Reload initiated")
		--do animation stuff
		reloading.Value = true
		local amount = self.MagazineSize - magState.Value
		local interrupted = false
		local interruptConnection
		--adds an event to check whether the reloading state has been changed to false
		--i.e. when the reload gets cancelled
		interruptConnection = reloading.Changed:Connect(function (val)
			if not val then
				--interrupt the reload and animation
				if interruptConnection then
					interruptConnection:Disconnect()
				end
				interrupted = true
				--print("reload cancelled")
			end
		end)
		-- Play reload animation
		--self:PlayAnimation(animationTracks["reloadAnim"], animationTracks)
		--wait for the duration of time it takes to reload
		wait(self.ReloadTime * amount)
		--check to see if the reload was not cancelled while waiting
		if not interrupted then
			magState.Value = self.MagazineSize
			interruptConnection:Disconnect()
			reloading.Value = false
			--print("Reloaded!")
		else
			--print("Reload was already cancelled")
		end
	end
end
	
return Shotgun.new()
