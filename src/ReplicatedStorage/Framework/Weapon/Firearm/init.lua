local Weapon = require(script.Parent)

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local isClient = RunService:IsClient()

local muzzleFlash = ReplicatedStorage.Assets.Projectiles.MuzzleFlash

--local localPlayer = game.Players.LocalPlayer
--local ads = localPlayer:WaitForChild("ADS")

local ServerStorage
local killRegister
local damageRegister
if RunService:IsServer() then
	ServerStorage = game:GetService("ServerStorage")
	killRegister = ServerStorage.Invokers.Score.RegisterKillServer
	damageRegister = ServerStorage.Invokers.Score.RegisterDamageServer
end

local projectiles = game:GetService("ReplicatedStorage").Framework.Projectiles
local projectileBeam = ReplicatedStorage.Assets.Projectiles.Default.ProjectileTrail

local register

local Firearm = {}
--Firearm.__index = Firearm
Firearm.Metatable = {__index = Firearm}
setmetatable(Firearm, {__index = Weapon})

local projectileModule = require(ReplicatedStorage.Framework.Projectiles.Projectiles)

function Firearm.new()
	local newFirearm = Weapon.new()
	setmetatable(newFirearm, Firearm.Metatable)
	
	newFirearm.Spread = 0 --number of degrees the angle can be off by
	newFirearm.PelletCount = 1
	newFirearm.MagazineSize = 10
	newFirearm.ReloadTime = 2 --in seconds
	newFirearm.ProjectileSpeed = 3000
	newFirearm.Recoil = .1
	newFirearm.ProjectileRange = 300
	newFirearm.IsReloading = false
	newFirearm.AimZoom = 2
	newFirearm.ProjectileSize = .1
	
	--[[
	local pistolAnimations = ReplicatedStorage.Assets.Animations.Pistol
	
	local equipADSAnim = pistolAnimations.EquipADS
	local equipIdleAnim = pistolAnimations.EquipIdle
	local fireAnim = pistolAnimations.Fire
	local reloadAnim = pistolAnimations.Reload
	
	newFirearm.EquipADSAnimation = equipADSAnim
	newFirearm.EquipIdleAnimation = equipIdleAnim
	newFirearm.FireAnimation = fireAnim
	newFirearm.ReloadAnimation = reloadAnim
	
	newFirearm.Animations = {equipADS = equipADSAnim, equipIdle = equipIdleAnim, fire = fireAnim, reload = reloadAnim}
	]]
	return newFirearm
end

--initializes values on first equip
function Firearm:Initialize(humanoid)
	--local animationTracks = {}
	--for i, v in pairs(self.Animations) do
	--	animationTracks[i] = humanoid:LoadAnimation(v)
	--end
	-- Exit out of ADS mode if in it
	--ads.Value = false
	
	-- Play idle equip animation
	--self:PlayAnimation(animationTracks["equipIdle"], animationTracks)
	--return animationTracks
end
function getReloadState(config)
	local reloadState
	if RunService:IsServer() then
		reloadState = config.ReloadingServer
	else
		reloadState = config.ReloadingClient
	end
	return reloadState
end
function getMagState(config)
	local magStateVal
	if RunService:IsServer() then
		magStateVal = config.MagStateServer
	else
		magStateVal = config.MagStateClient
	end
	return magStateVal
end

--attmpets to attack
function Firearm:AttemptAttack(player, tool, camCFrame, seed)
	local reloading = getReloadState(tool.Configuration)
	local valid, timeo, empty = self:ValidateAttack(tool)
	if valid and player.Character.Humanoid.Health > 0 then
		--[[if the gun was already reloading while attempting to fire,
			but could fire again (because there was still ammo in the mag,
			then interrupt the reload and fire 
			]]
		reloading.Value = false
		self:Attack(player, tool, camCFrame, seed)
		--reset the weapon's values 
		self:Rearm(tool, timeo)
	else
		--print("Was not a valid shot: ".. tostring(valid).. " " .. tostring(empty))
		--reloads if the mag for the given attack was already empty
		if (empty)and RunService:IsClient() then
			--self:Reload(player, tool)
		end
	end
end

--returns whether the gun can fire again, the new timestamp, and whether the mag was empty for that attack
function Firearm:ValidateAttack(tool)
	local config = tool.Configuration
	
	local nowTime = tick()
	local toReturn = false
	local lastFireVal = config.LastAttackClient
	
	if not isClient then
		lastFireVal = tool.Configuration.LastAttackServer
	end
	
	local speed = self.AttackSpeed
	local magStateVal = getMagState(config)
	
	local dif = nowTime - lastFireVal.Value
	local empty = magStateVal.Value <= 0 --see if the magazine for the given attack is empty
	
	toReturn = dif > 1/speed and not empty 
	--print(dif.."/".. tostring(1/speed))
	return toReturn, nowTime, empty
end

--updates values after a weapon has fired
function Firearm:Rearm(tool, timeo)
	local config = tool.Configuration
	
	local lastFireVal = config.LastAttackClient
	
	if not isClient then
		lastFireVal = tool.Configuration.LastAttackServer
	end
	
	local magStateVal = getMagState(config)
	
	lastFireVal.Value = timeo --reset last fire timestamp
	magStateVal.Value = magStateVal.Value - 1 --decrement ammo
end

function Firearm:Reload(player, tool)
	--print("attempting to reload")
	local reloadSound = tool.Handle:FindFirstChild("Reload")
	
	local config = tool.Configuration
	
	local reloading = getReloadState(config)
	local magStateVal = getMagState(config)
	print("REloaDING "..magStateVal.Name)
	--make sure we're not already reloading
	if not reloading.Value and magStateVal.Value < self.MagazineSize then
		--print("Reload initiated")
		--do animation stuff
		reloading.Value = true
		local interrupted = false
		local interruptConnection
		
		local unequipEvent
		if tool:IsA("Tool") then
			unequipEvent = tool.Unequipped:Connect(function()
				reloading.Value = false
			end)
		end
		
		--adds an event to check whether the reloading state has been changed to false
		--i.e. when the reload gets cancelled
		interruptConnection = reloading.Changed:Connect(function (val)
			if not val then
				--interrupt the reload and animation
				if interruptConnection then
					interruptConnection:Disconnect()
				end
				interrupted = true
				print("reload cancelled")
				if reloadSound then
					reloadSound:Stop()
				end
			end
			if unequipEvent then unequipEvent:Disconnect() end
		end)
		
		if reloadSound then
			reloadSound:Play()
		end
		-- Play reload animation
		--self:PlayAnimation(animationTracks["reloadAnim"], animationTracks)
		--wait for the duration of time it takes to reload
		wait(self.ReloadTime)
		--check to see if the reload was not cancelled while waiting
		if not interrupted then
			
			magStateVal.Value = self.MagazineSize
			interruptConnection:Disconnect()
			reloading.Value = false
			if unequipEvent then unequipEvent:Disconnect() end
			print("Reloaded " ..magStateVal.Name .."!")
		else
			--print("Reload was already cancelled")
		end
	end
end

function Firearm:SelectBarrelEnd(tool)
	local state = getMagState(tool.Configuration)
	local shotNum = self.MagazineSize - state.Value
	shotNum = shotNum
	local barrels = tool:FindFirstChild("Barrels", true):GetChildren()
	return barrels[shotNum%(#barrels) + 1]:FindFirstChild("BarrelEnd", true)
end

--called to make the server shoot stuff
function Firearm:Attack(player, tool, aimCframe, seed)
	local character = player.Character
	local u = aimCframe.LookVector
	local v = (character.HumanoidRootPart.Position + character.Humanoid.CameraOffset) - aimCframe.p
	local rayOrigin = aimCframe.p + (u:Dot(v)/(u.Magnitude^2)) * u
	local camRay = Ray.new(rayOrigin, u * 10000)
	
	local _, spot = game.Workspace:FindPartOnRayWithIgnoreList(camRay, CollectionService:GetTagged("ProjectileIgnore"), false, true)
	local barrelEnd = self:SelectBarrelEnd(tool)
	local barrel = barrelEnd.Parent
	local origin = barrelEnd.WorldPosition
	
	local camCFrame = CFrame.new(origin, spot)

	--print ("Firing firearm")
	local rand = Random.new(seed)
	local pellets = {}
	
	local spreadAdjusted = math.pi/180
	local spreadRadius = self.Spread/2
	
	for i = 1, self.PelletCount do
		local spreadAngleX = CFrame.Angles(rand:NextNumber() * spreadRadius * spreadAdjusted, 0, 0)
		local spreadAngleZ = CFrame.Angles(0, 0, rand:NextNumber()*2*math.pi)
		
		local pelletDirection = (camCFrame * spreadAngleZ * spreadAngleX ).LookVector
		
		local projectile = {
			Player = player,
			Tool = tool,
			Position = origin, --tool.Barrel.BarrelEnd.WorldPosition,
			Origin = origin,
			Velocity = pelletDirection * self.ProjectileSpeed + barrel.Velocity,
			Size = self.ProjectileSize,
			MaxDistance = self.ProjectileRange,
			--no droprate for default value
			DrawFunc = Firearm.DrawBullet,
			ContactHandler = Firearm.BulletContact
		}
		--if isClient then
		--	Firearm.DrawBullet(nil, origin, origin + pelletDirection * 1/60)
		--end
		pellets[#pellets + 1] = projectile
	end
	--addProjectiles:Fire(pellets, tick())
	projectileModule.AddProjectiles(pellets)
	
	if isClient then
		local flash = muzzleFlash:Clone()
		--print(tostring(origin)..")("..tostring(origin - tool.Barrel.CFrame.UpVector)..")("..tostring(tool.Barrel.CFrame.UpVector))
		
		local muzzleOrigin = origin + aimCframe.LookVector * muzzleFlash.Size.Y/2
		--flash.CFrame = CFrame.new(muzzleOrigin, muzzleOrigin - aimCframe.UpVector)
		flash.CFrame = CFrame.fromMatrix(muzzleOrigin, CFrame.fromAxisAngle(aimCframe.LookVector, 2*math.pi*rand:NextNumber())*aimCframe.UpVector, aimCframe.LookVector)
		
		flash.Parent = game.Workspace.Debris
		flash.Size = muzzleFlash.Size * .75
		Debris:AddItem(flash, 0.05)
		
		local shootSound = tool.Handle:FindFirstChild("Fire")
		if shootSound and shootSound:IsA("Sound") then
			shootSound:Play()
		end
	end
	
	
	-- Play firing animation
	--self:PlayAnimation(animationTracks["fire"], animationTracks)
end

function Firearm.DrawBullet(self, p1, p2, minDist)
	
	local dist = (p2-p1).Magnitude
	local totalDif = self.DistanceTraveled + dist 
	
	--if the end of the line is within range
	if totalDif > minDist then
		local dif = p2 - p1
		local dir = dif.Unit
		local originDist = math.max(minDist - self.DistanceTraveled, 0)
		local beamLength = totalDif - originDist
		
		local beam = Firearm.MakeBeam()
		local size = self.Size
		beam.Size = Vector3.new(self.Size, self.Size, beamLength)
		beam.CFrame = CFrame.new(p1 + dir * originDist, p2) * CFrame.new(0, 0, -beamLength/2)
		beam.Parent = game.Workspace.Debris
		Debris:AddItem(beam, .05)
	end
end

function Firearm.BulletContact(self, part, pos)
	if RunService:IsServer() then
		local offsetPosition = pos - part.Position
		if part.Parent:IsA("Model") and part.Parent.PrimaryPart then
			offsetPosition = pos - part.Parent.PrimaryPart.Position
		end
		damageRegister:Fire(self.Player, part.Parent, self.Tool, self.Origin, self.Damage)
	end
end

function Firearm.MakeBeam()
	--[[
	local part = Instance.new("Part")
	part.Material = "Neon"
	part.Anchored = true
	part.Locked = true
	part.CanCollide = false
	return part
	]]
	return projectileBeam:Clone()
end

return Firearm.new()
