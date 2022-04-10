AerialVehicle = require(script.Parent)

local Helicopter = {}
Helicopter.__index = Helicopter
setmetatable(Helicopter, AerialVehicle)

-- Static variables
Helicopter.TurnRadius = math.rad(75)
Helicopter.RotationAngle = 5
Helicopter.MaxReverseSpeed = -50
Helicopter.MaxForwardSpeed = 200
Helicopter.MaxHealth = 300

-- Services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Micro-optimizations
local CFrame_new = CFrame.new
local Vector3_new = Vector3.new
local clamp = math.clamp
local rad = math.rad

-- Missile references
Helicopter.Missile1 = ServerStorage:WaitForChild("Vehicles"):WaitForChild("GenericHelicopter"):WaitForChild("Missile1")
Helicopter.Missile2 = ServerStorage:WaitForChild("Vehicles"):WaitForChild("GenericHelicopter"):WaitForChild("Missile2")

local pointIsInWater = nil
do
	local waterEnum = Enum.Material.Water
	local VOXEL_SIZE = 4
	pointIsInWater = function(pos)
		local voxelPos = workspace.Terrain:WorldToCell(pos)
		local voxelRegion = Region3.new(voxelPos*VOXEL_SIZE, (voxelPos + Vector3_new(1,1,1))*VOXEL_SIZE)
		local materialMap, occupancyMap = workspace.Terrain:ReadVoxels(voxelRegion, VOXEL_SIZE)
		local voxelMaterial = materialMap[1][1][1]
		return voxelMaterial == waterEnum
	end
end

function Helicopter.new(model, spawnCFrame)
	local newHelicopter = AerialVehicle.new(model, spawnCFrame, Helicopter.TurnRadius, Helicopter.RotationAngle, 
																Helicopter.MaxReverseSpeed, Helicopter.MaxForwardSpeed,
																Helicopter.MaxHealth)
	setmetatable(newHelicopter, Helicopter)
	
	newHelicopter.Name = "Helicopter"
	
	-- Helicopter specific attributes
	newHelicopter.CurrentMissile = 1
	newHelicopter.StartedUp = false
	newHelicopter.ChangeAltitude = newHelicopter.Model:WaitForChild("ChangeAltitude")
	newHelicopter.ShootMissile = newHelicopter.Model:WaitForChild("FireMissile")
	newHelicopter.MissilesDebounce = {true, true}
	newHelicopter.CurrentMissile = 1
	
	-- Handle player interaction with the vehicle (client -> server)
	newHelicopter:HandleAltitudeAdjustment()
	newHelicopter:HandleEvents()
	
	return newHelicopter
end


function Helicopter:HandleEvents()
	self.ShootMissileConn = self.ShootMissile.OnServerEvent:Connect(function(player, mouseHit)
		if self.StartedUp and mouseHit and self.MissilesDebounce[self.CurrentMissile] then
			-- Debounce it so that it can't be spammed
			local currentMissileNum = self.CurrentMissile
			self.MissilesDebounce[currentMissileNum] = false
			
			-- Release and fire the missile in the given direction
			local missile = self.Model:FindFirstChild("Missile"..currentMissileNum)
			local part1 = missile.Weld.Part1
			missile.CanCollide = false
			missile.Weld:Destroy()
			missile.Parent = game.Workspace.Debris
			missile.AntiGravity.Force = Vector3_new(0, missile:GetMass() * game.Workspace.Gravity, 0)
			missile.BodyVelocity.MaxForce = Vector3_new(math.huge, math.huge, math.huge)
			missile.BodyGyro.MaxTorque = Vector3_new(math.huge, math.huge, math.huge)
			missile.Smoke.Enabled = true
			
			-- Enable particles
			--[[
			for _, v in pairs(missile.Effects:GetChildren()) do
				if v:IsA("Smoke") then
					v.Enabled = true
				end
			end
			--]]
			spawn(function()
				while missile.Parent do
					missile.BodyGyro.CFrame = CFrame_new(missile.Position, mouseHit.p)
					missile.BodyVelocity.Velocity = missile.CFrame.LookVector * Helicopter.MaxForwardSpeed * 1.25
					RunService.Heartbeat:Wait()
				end
			end)
						
			-- Explode upon contact
			missile.Touched:Connect(function(hit)
				if not hit:IsDescendantOf(self.Model) then
					local hitPoint = missile.Position + missile.CFrame.LookVector * missile.Size.Z/2
					
					-- Ignore if in water (have to subtract by a substantial amount for it to subtract properly for some stupid reason)
					if hit.Name == "Terrain" and pointIsInWater(hitPoint - Vector3_new(0, 15, 0)) then
						--print("hit water")
						return
					end
					
					-- Destroy missle and create explosion
					missile:Destroy()
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
				missile:Destroy()
				
				-- Add a new missile back in its place
				local newMissile = Helicopter["Missile"..currentMissileNum]:Clone()
				newMissile.Weld.Part1 = part1
				newMissile.Parent = self.Model
				
				-- Allow the new missile to be fired
				self.MissilesDebounce[currentMissileNum] = true
			end)
			
			-- Set current missile on to next missile
			self.CurrentMissile = self.CurrentMissile%2 + 1
		end
	end)
end

return Helicopter