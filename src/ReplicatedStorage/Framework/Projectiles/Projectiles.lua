local module = {}

local RunService = game:GetService("RunService")
local Collections = game:GetService("CollectionService")

local IGNORE_TAG = "ProjectileIgnore"

local projectiles = shared.Projectiles

if not projectiles then
	shared.Projectiles = {}
	projectiles = shared.Projectiles
end


--[[
	format for projectiles:
		player
		position
		origin
		direction
		speed
		drop rate
		distance traveled
		max distance
		drawfunc
		contact handler
]]

local projectileProto = {
	Player = nil,
	Tool = nil,
	Position = nil,
	Velocity = nil,
	Origin = nil,
	Damage = 10,
	DropRate = game.Workspace.Gravity,
	DistanceTraveled = 0,
	MaxDistance = 1000,
	DrawFunc = nil,
	ContactHandler = nil,
	IgnoreWater = false
}

local projectileMeta = {
	__index = projectileProto
}

--inserts a projectile
local function addProjectile(proj)
	setmetatable(proj, projectileMeta)
	table.insert(projectiles, proj)
	--[[
	for i, v in pairs(proj) do
		print(i)
	end
	]]
end

--inserts a set of projectiles
local function addProjectiles(projs)
	--print("Received a batch of "..#projs.." projectiles to add")
	--print(tick() - t)
	for _, p in pairs(projs) do
		addProjectile(p)
	end
end

local function updateProjectiles(dTime)
	local ignoreTable = Collections:GetTagged(IGNORE_TAG)
	table.insert(ignoreTable, game.Workspace.Terrain)
	local numIgnored = #ignoreTable
	--print(#projectiles)
	--iterate over all the projectiles
	for i, p in pairs (projectiles) do
		ignoreTable[numIgnored + 1] = p.Player.Character
		ignoreTable[numIgnored + 2] = p.Tool
		--local displacement = p.Velocity * elapsedTimeo + (Vector3.new(0, 1, 0) * p.DropRate * math.pow(elapsedTimeo, 2))/2 --calculating total displacement using kinematic equation
		--update new velocity to account for grav accel
		local velUnit = p.Velocity.Unit
		local speed = p.Velocity.Magnitude
		local dist = math.min(speed * dTime, p.MaxDistance - p.DistanceTraveled)
		local disp = velUnit * dist
		
		--raycasting and shit
		local ray = Ray.new(p.Position, disp)
		--local hitPart, hitPos = game.Workspace:FindPartOnRayWithIgnoreList(ray, {p.Player.Character, game.Workspace.Debris}, false, p.IgnoreWater)
		local hitPart, hitPos = game.Workspace:FindPartOnRayWithIgnoreList(ray, ignoreTable, false, p.IgnoreWater)
		if p.DrawFunc and RunService:IsClient() then
			p:DrawFunc(p.Position, hitPos, 5)
		end
		
		if hitPart then
			--print("Projectile hit:", hitPart.Name)
			p:ContactHandler(hitPart, hitPos)
			table.remove(projectiles, i)
		end
		
		p.DistanceTraveled = p.DistanceTraveled + dist
		if p.DistanceTraveled >= p.MaxDistance then
			table.remove(projectiles, i)
			--print("Projectile timed out. Removing")
		end
		
		p.Position = p.Position + disp
		p.Velocity = p.Velocity + Vector3.new(0, -1, 0) * p.DropRate * dTime
	end
end

module.AddProjectile = addProjectile
module.AddProjectiles = addProjectiles
module.UpdateProjectiles = updateProjectiles

return module
