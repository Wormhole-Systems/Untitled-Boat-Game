-- Services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local debris = game.Workspace.Debris
local missileForces = ServerStorage:WaitForChild("Miscellaneous"):WaitForChild("Missile Forces")
local missiles = 
{
	Missile1 = ServerStorage:WaitForChild("Vehicles"):WaitForChild("Helicopter"):WaitForChild("Missile1"),
	Missile2 = ServerStorage:WaitForChild("Vehicles"):WaitForChild("Helicopter"):WaitForChild("Missile2")
}
local welds = 
{
	Missile1 = missiles.Missile1.PrimaryPart.CFrame:inverse() * ServerStorage.Vehicles.Helicopter.Hull.CFrame,
	Missile2 = missiles.Missile2.PrimaryPart.CFrame:inverse() * ServerStorage.Vehicles.Helicopter.Hull.CFrame,
}

-- Fire missile invoker
local fireMissile = game:GetService("ReplicatedStorage"):WaitForChild("Invokers"):WaitForChild("Vehicle"):WaitForChild("FireMissile")

local pointIsInWater do
	local Vector3_new = Vector3.new
	local waterEnum = Enum.Material.Water
	local VOXEL_SIZE = 4
	pointIsInWater = function(pos)
		local voxelPos = workspace.Terrain:WorldToCell(pos)
		local voxelRegion = Region3.new(voxelPos*VOXEL_SIZE, (voxelPos + Vector3_new(1, 1, 1)) * VOXEL_SIZE)
		local materialMap, occupancyMap = workspace.Terrain:ReadVoxels(voxelRegion, VOXEL_SIZE)
		local voxelMaterial = materialMap[1][1][1]
		return voxelMaterial == waterEnum
	end
end

fireMissile.OnServerEvent:Connect(function(player, helicopter, missileNum, mouseHit)
	if helicopter.Name == player.Name and player.Character and player.Character:FindFirstChildOfClass("Humanoid") and
		player.Character.Humanoid.SeatPart and player.Character.Humanoid.SeatPart.Parent == helicopter and
		helicopter:FindFirstChild("Missile"..missileNum) and mouseHit then
		
		-- Detach missile
		local missileModel = helicopter:FindFirstChild("Missile"..missileNum)
		local missile = missileModel.Force
		missileModel.PrimaryPart.Weld.Part0 = nil
		missileModel.Parent = debris
		for _, v in pairs(missileModel:GetDescendants()) do
			if v:IsA("BasePart") then
				v:SetNetworkOwner()
				v.CanCollide = false
				if v.Parent.Name == "Secondary" then
					v.BrickColor = player.TeamColor
				end
			end
		end
		
		-- Add forces
		for _, v in pairs(missileForces:GetChildren()) do
			v:Clone().Parent = missile
		end
		
		
		missile.AntiGravity.Force = Vector3.new(0, missile:GetMass() * game.Workspace.Gravity, 0)
		missile.BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		missile.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		missile.Smoke.Enabled = true

		spawn(function()
			local speed = helicopter.Configuration.MaxForwardSpeed.Value * 1.25
			while missile.Parent do
				missile.BodyGyro.CFrame = CFrame.new(missile.Position, mouseHit.p)
				missile.BodyVelocity.Velocity = missile.CFrame.LookVector * speed
				RunService.Heartbeat:Wait()
			end
		end)
					
		-- Explode upon contact
		missile.Touched:Connect(function(hit)
			if not hit:IsDescendantOf(helicopter) then
				local hitPoint = missile.Position + missile.CFrame.LookVector * missile.Size.Z/2
				
				-- Ignore if in water (have to subtract by a substantial amount for it to subtract properly for some stupid reason)
				if not hit.CanCollide or (hit.Name == "Terrain" and pointIsInWater(hitPoint - Vector3.new(0, 15, 0))) then
					--print("hit water")
					mouseHit = mouseHit + missile.CFrame.LookVector * 1000
					return
				end
				
				-- Destroy missle and create explosion
				missileModel:Destroy()
				local explosion = Instance.new("Explosion")
				explosion.BlastRadius = 50
				explosion.DestroyJointRadiusPercent = 0
				explosion.Position = hitPoint
				explosion.Parent = game.Workspace.Debris
				
				-- Do damage on contacted models
				local damagedItems = {}
				explosion.Hit:Connect(function(hitPart, distance)
					local damagedItem = hitPart:FindFirstAncestorWhichIsA("Model")
					if damagedItems[damagedItem] or damagedItem:FindFirstChildOfClass("ForceField") then
						return
					end
					damagedItems[damagedItem] = true
					
					if damagedItem:FindFirstChild("Humanoid") then
						local distanceFactor = distance / explosion.BlastRadius -- get the distance as a value between 0 and 1
						distanceFactor = 1 - distanceFactor -- flip the amount, so that lower == closer == more damage
						damagedItem.Humanoid:TakeDamage(100 * distanceFactor) -- TakeDamage to respect ForceFields
					end
					--TODO: damage to vehicles and enemies only 
				end)
				
				-- Cleanup explosion
				delay(5, function()
					explosion:Destroy()
					damagedItems = {}
				end)
			end
		end)
		
		delay(10, function()
			-- Destroy current missile & explosion
			missileModel:Destroy()
			
			if helicopter.Parent then
				-- Add a new missile back in its place
				local newMissile = missiles["Missile"..missileNum]:Clone()
				newMissile.PrimaryPart.Weld:Destroy()
				newMissile.Parent = helicopter
				for _, v in pairs(newMissile:GetDescendants()) do
					if v:IsA("BasePart") then
						v:SetNetworkOwner(player)
					end
				end
				local weld = Instance.new("Weld")
				weld.Name = "Weld"
				weld.C0 = welds["Missile"..missileNum]
				weld.Part0 = newMissile.PrimaryPart
				weld.Part1 = helicopter.PrimaryPart	
				weld.Parent = newMissile.PrimaryPart
			end
		end)
	end
end)
