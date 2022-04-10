local folder = game:GetService("ServerStorage").Projectiles

local RunService = game:GetService("RunService")

local projectiles = {}
--[[
	format for projectiles:
		player
		position
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
	Position = nil,
	Velocity = nil,
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
local function addProjectiles(projs, t)
	--print("Received a batch of "..#projs.." projectiles to add")
	--print(tick() - t)
	for _, p in pairs(projs) do
		addProjectile(p)
	end
end

local function updateProjectiles(elapsedTimeo)
	--print(#projectiles)
	--iterate over all the projectiles
	for i, p in pairs (projectiles) do
		--local displacement = p.Velocity * elapsedTimeo + (Vector3.new(0, 1, 0) * p.DropRate * math.pow(elapsedTimeo, 2))/2 --calculating total displacement using kinematic equation
		--update new velocity to account for grav accel
		local velUnit = p.Velocity.Unit
		local speed = p.Velocity.Magnitude
		local dist = math.min(speed * elapsedTimeo, p.MaxDistance - p.DistanceTraveled)
		local disp = velUnit * dist
		
		--raycasting and shit
		local ray = Ray.new(p.Position, disp)
		local hitPart, hitPos = game.Workspace:FindPartOnRayWithIgnoreList(ray, {p.Player.Character, game.Workspace.Debris}, false, p.IgnoreWater)
		
		if p.DrawFunc then
			p.DrawFunc(p.Position, hitPos)
		end
		
		if hitPart then
			print("Projectile hit:", hitPart.Name)
			p:ContactHandler(hitPart, hitPos, p.Player)
			table.remove(projectiles, i)
		end
		
		p.DistanceTraveled = p.DistanceTraveled + dist
		if p.DistanceTraveled >= p.MaxDistance then
			table.remove(projectiles, i)
			print("Projectile timed out. Removing")
		end
		
		
		p.Position = p.Position + disp
		p.Velocity = p.Velocity + Vector3.new(0, -1, 0) * p.DropRate * elapsedTimeo
	end
end 

RunService.Heartbeat:Connect(updateProjectiles)
folder.AddProjectile.Event:Connect(addProjectile)
folder.AddProjectiles.Event:Connect(addProjectiles)

--[[
	
	local projectile = {
			["Player"] = player, 
			["Position"] = tool.Barrel.BarrelEnd.WorldPosition,
			["Velocity"] = pelletDirection * self.ProjectileSpeed,
			--no droprate for default value
			["DrawFunc"] = DrawBullet,
			["ContactHandler"] = BulletContact
		}
	
local projectileProto = {
	["Player"] = nil,
	["Position"] = nil,
	["Velocity"] = nil,
	["DropRate"] = game.Workspace.Gravity,
	["DistanceTraveled"] = 0,
	["MaxDistance"] = 1000,
	["DrawFunc"] = nil,
	["ContactHandler"] = nil,
	["IgnoreWater"] = false
}
	
function updateProjectiles(elapsedTimeo)
	--iterate over all the projectiles
	for i, p in pairs (projectiles) do
		--local displacement = p.Velocity * elapsedTimeo + (Vector3.new(0, 1, 0) * p.DropRate * math.pow(elapsedTimeo, 2))/2 --calculating total displacement using kinematic equation
		--update new velocity to account for grav accel
		local velUnit = p["Velocity"].Unit
		local speed = p["Velocity"].Magnitude
		local dist = math.min(speed * elapsedTimeo, p["MaxDistance"] - p["DistanceTraveled"])
		local disp = velUnit * dist
		
		--raycasting and shit
		local ray = Ray.new(p["Position"], disp)
		local hitPart, hitPos, hitNorm = game.Workspace:FindPartOnRay(ray, p["Player.Character"], false, p["IgnoreWater"])
		
		p.DrawFunc(p["Position"], hitPos)
		
		if hitPart then
			print("Projectile hit a thing!")
			p.ContactHandler(hitPart, hitPos, p["Player"])
			table.remove(projectiles, i)
		end
		
		p["Position"] = p["Position"] + disp
		p["Velocity"] = p["Velocity"] + Vector3.new(0, 1, 0) * p["DropRate"] * elapsedTimeo
	end
end
]]