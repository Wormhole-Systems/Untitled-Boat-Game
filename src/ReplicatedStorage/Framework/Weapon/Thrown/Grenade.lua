local Thrown = require(script.Parent)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local ServerStorage 
local damageRegister 

if RunService:IsServer() then
	ServerStorage = game:GetService("ServerStorage")
	damageRegister = ServerStorage.Invokers.Score.RegisterDamageServer
end

local projectileModule = require(ReplicatedStorage.Framework.Projectiles.Projectiles)

local grenadeModel = ReplicatedStorage.Assets.Projectiles.Thrown.Grenade
local throwGrenadeFunc = ReplicatedStorage.Invokers.ThrowGrenade
	
local Grenade = {}
Grenade.Metatable = {__index = Grenade}
setmetatable(Grenade, {__index = Thrown})

function Grenade.new()
	local newThrown = Thrown.new()
	setmetatable(newThrown, Grenade.Metatable)
	
	newThrown.FuseTime = 3
	newThrown.Damage = 5
	newThrown.PelletCount = 100
	newThrown.Radius = 20
	newThrown.PelletSpeed = 3000
	newThrown.MaxAmmo = 50000
	newThrown.AttackSpeed = .66
	newThrown.ProjectileSize = .1
	
	newThrown.ThrowSpeed = 100
	
	return newThrown
end

function Grenade:Attack(player, dir, seed)
	local character = player.Character
	local grenadeClone = grenadeModel:Clone()
	grenadeClone.Parent = character
	
	-- Apply weld
	local leftHand, leftGrip = character.LeftHand, grenadeClone.LeftGrip
	leftGrip.Part0 = leftHand
	leftGrip.Part1 = grenadeClone.Body
	leftGrip.Parent = leftHand
	
	for _, v in pairs(grenadeClone:GetChildren()) do
		v:SetNetworkOwner(player)
	end
	
	local direction = throwGrenadeFunc:InvokeClient(player, grenadeClone)
	
	-- Detach grenade first if sitting in a seat so that the player doesn't lose network ownership of it
	if character.Humanoid.Sit then
		player.Character.LeftHand.LeftGrip:Destroy()
	end
	-- Revoke network ownership back to the server
	for _, v in pairs(grenadeClone:GetChildren()) do
		v:SetNetworkOwner(nil)
	end
	-- Detach grenade after revoking network ownership if not in a seat
	if not character.Humanoid.Sit then
		player.Character.LeftHand.LeftGrip:Destroy()
	end
	
	-- Color and move grenade
	grenadeClone.Parent = game.Workspace
	grenadeClone.TeamIndicator.Transparency = 0
	grenadeClone.TeamIndicator.BrickColor = player.TeamColor
	grenadeClone.Body.CanCollide = true
	--grenadeClone.Body.Velocity = direction * self.ThrowSpeed + leftHand.Velocity
	
	grenadeClone.Body.Velocity = dir.LookVector * self.ThrowSpeed
	
	-- Set timer to explode
	delay(self.FuseTime, function()
		Grenade.Explode(self, grenadeClone, player, seed) 
	end)
end

function Grenade:Explode(model, player, seed)
	if not model or not model.Parent then return end
	
	local rand = Random.new(seed)
	local pellets = {}
	
	model.PrimaryPart = model.Body
	local origin = model.PrimaryPart.Position
	print("Grenade pellet count: FUCK ", self.PelletCount)
	for i = 1, self.PelletCount do
		local pelletDirection = Vector3.new(rand:NextNumber()-1/2, rand:NextNumber()-1/2, rand:NextNumber()-1/2).Unit
		local pelletOrigin = origin + pelletDirection * 1
		local projectile = {
			Player = player,
			Tool = model,
			Position = pelletOrigin, --tool.Barrel.BarrelEnd.WorldPosition,
			Origin = pelletOrigin,
			Velocity = pelletDirection * self.PelletSpeed + model.PrimaryPart.Velocity,
			MaxDistance = self.Radius,
			Size = self.ProjectileSize,
			--no droprate for default value
			DrawFunc = Grenade.DrawBullet,
			ContactHandler = Grenade.PelletContact
		}
		if RunService:IsClient() then
			Grenade.DrawBullet(nil, origin, origin + pelletDirection * 1/60)
		end
		pellets[#pellets + 1] = projectile
	end
	
	local explosion = Instance.new("Explosion", game.Workspace)
	explosion.BlastRadius = 10
	explosion.DestroyJointRadiusPercent = 0
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.Position = model.Body.Position
	
	model:Destroy()
	--addProjectiles:Fire(pellets, tick())
	projectileModule.AddProjectiles(pellets)
end

function Grenade.PelletContact(self, part, pos)
	if RunService:IsServer() then
		local offsetPosition = pos - part.Position
			if part.Parent:IsA("Model") and part.Parent.PrimaryPart then
				offsetPosition = pos - part.Parent.PrimaryPart.Position
			end
		damageRegister:Fire(self.Player, part.Parent, self.Tool, self.Origin, self.Damage)
	end
end

function Grenade.DrawBullet(self, p1, p2, minDist)
	print("vehk")
	local dist = (p2-p1).Magnitude
	local totalDif = self.DistanceTraveled + dist 
	
	--if the end of the line is within range
	if totalDif > minDist then
		local dif = p2 - p1
		local dir = dif.Unit
		local originDist = math.max(minDist - self.DistanceTraveled, 0)
		local beamLength = totalDif - originDist
		
		local beam = Grenade.MakeBeam()
		local size = self.Size
		beam.Size = Vector3.new(self.Size, self.Size, beamLength)
		beam.CFrame = CFrame.new(p1 + dir * originDist, p2) * CFrame.new(0, 0, -beamLength/2)
		beam.Parent = game.Workspace.Debris
		Debris:AddItem(beam, .05)
	end
end

return Grenade.new()
