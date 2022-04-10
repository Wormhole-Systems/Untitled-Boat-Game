--[[
	 Manages the spawning of vehicles
	 Keeps track of the active vehicle each player has spawned
	 Ensures that each player is only assigned one active vehicle
--]]

-- Constants
local SPAWN_TAG = "Spawn"
local HIGH_HEALTH_COLOR = Color3.new(0, 170, 0)
local MEDIUM_HEALTH_COLOR = Color3.new(255, 85, 0)
local LOW_HEALTH_COLOR = Color3.new(170, 0, 0)

-- Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Vehicle models and events
local vehicles = ServerStorage:WaitForChild("Vehicles")
local workspaceVehicles = game.Workspace:WaitForChild("Vehicles")
local vehicleEvents = ReplicatedStorage:WaitForChild("Invokers"):WaitForChild("Vehicle")
local initializeVehicle = vehicleEvents:WaitForChild("InitializeVehicle")
local destroyVehicle = vehicleEvents:WaitForChild("DestroyVehicle")

-- Keep track of died connections
local diedConnections = {}

-- Updates a vehicles owner tag to the given owner's name
local function updateOwnershipTag(vehicle, name, teamColor)
	name = name:sub(#name, #name):lower() == "s" and name.."'" or name.."'s"
	vehicle.Engine.Info.Owner.Text = name.." "..vehicle.Configuration.Type.Value
	vehicle.Engine.Info.Owner.TextColor3 = teamColor
	if vehicle:FindFirstChild("Secondary") then
		for _, v in pairs(vehicle["Secondary"]:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Color = teamColor
			end
		end
	end
end

-- Fixes bug by setting network ownership back to the player after they die
local function setupBugFixWithNetworkOwnership(vehicle, player)
	if diedConnections[vehicle] then
		diedConnections[vehicle]:Disconnect()
		diedConnections[vehicle] = nil
	end
	
	diedConnections[vehicle] = player.Character.Humanoid.Died:Connect(function()
		for _, v in pairs(vehicle:GetDescendants()) do
			if v:IsA("BasePart") then
				v:SetNetworkOwner(player)
			end
		end
		diedConnections[vehicle]:Disconnect()
		diedConnections[vehicle] = nil
	end)
end

-- Give network ownership of the vehicle to the player who spawned it
local function assignNetworkOwnership(vehicle, player)
	--vehicle["Driver"]:SetNetworkOwner(player)
	for _, v in pairs(vehicle:GetDescendants()) do
		if v:IsA("BasePart") then
			v:SetNetworkOwner(player)
		end
	end		
	setupBugFixWithNetworkOwnership(vehicle, player)
end


-- Retrieves the Region3 for a given part w.r.t. its CFrame
local function getRegion3(cf, size)
	local abs = math.abs
	
	local sx, sy, sz = size.X, size.Y, size.Z
	local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:components()

	local wsx = 0.5 * (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz)
	local wsy = 0.5 * (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz)
	local wsz = 0.5 * (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz)
	
	local minx = x - wsx
	local miny = y - wsy
	local minz = z - wsz

	local maxx = x + wsx
	local maxy = y + wsy
	local maxz = z + wsz
   
	local minv, maxv = Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
	
	return Region3.new(minv, maxv)
end

--[[ 
	Connect a button to a touched event
	Actually spawn a vehicle into the world
--]]
local spawnConnections = {}
local function createConnection(spawnButton)
	-- Add name to its respective sign
	if spawnButton:FindFirstChild("Sign") then
		local vehicleName = script.VehicleName:Clone()
		vehicleName.Text = spawnButton["Type"].Value:upper()
		vehicleName.Parent = spawnButton.Sign.Board.SurfaceGui
	end
	
	-- Vehicle's spawning related calculations
	local vehicleType = spawnButton["Type"].Value
	local vehicleToSpawn = vehicles:FindFirstChild(vehicleType)
	local spawnPosition = spawnButton.CFrame * spawnButton["SpawnOffsetPosition"].Value
	local spawnCFrame = CFrame.new(spawnPosition, spawnPosition + spawnButton.CFrame.LookVector) * CFrame.Angles(0, math.rad(spawnButton["SpawnOffsetRotation"].Value), 0)
	
	local extentsSize = vehicleToSpawn:GetExtentsSize()
	local needsShorterBounds = (vehicleType == "Spy Plane" 
								or vehicleType == "Helicopter" 
								or vehicleType == "Chinook" 
								or vehicleType == "Blimp"
								or vehicleType == "Submarine")
	local spawnRegion = getRegion3(needsShorterBounds and spawnCFrame - Vector3.new(0, extentsSize.Y/4 ,0)or spawnCFrame, 
								   needsShorterBounds and extentsSize/2 or extentsSize)
	--local offset = vehicleToSpawn:GetPrimaryPartCFrame().p - vehicleToSpawn:GetModelCFrame().p
	local offset = vehicleToSpawn:GetPrimaryPartCFrame().p - vehicleToSpawn:GetBoundingBox().p
	local centeredPos = spawnCFrame * Vector3.new(offset.X, offset.Y, -offset.Z)
	spawnCFrame = CFrame.new(centeredPos, centeredPos + spawnCFrame.LookVector)
		
	--[[
	if vehicleType == "Helicopter" then
		local part = Instance.new("Part")
		part.Anchored = true
		part.CanCollide = false
		part.CFrame = spawnCFrame
		part.Size = Vector3.new(1, 1, 1)
		part.Parent = game.Workspace
		print(spawnCFrame.p)
	end
	
	local part = Instance.new("Part")
	part.Transparency = 0.2
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = spawnRegion.CFrame
	part.Size = spawnRegion.Size
	part.Parent = game.Workspace
	--]]
	
	spawnConnections[spawnButton] = spawnButton.Touched:Connect(function(hit)
		if not spawnButton.Touch.Value then
			local player = hit and hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
			--[[
			for _, v in pairs(game.Workspace:FindPartsInRegion3(spawnRegion, game.Workspace.Map.TriangleTerrain, 1000)) do
				print(v:GetFullName())
				v:Destroy()
			end
			--]]
			if player and #game.Workspace:FindPartsInRegion3(spawnRegion, game.Workspace.Map.TriangleTerrain, 1) == 0 then
				-- Start debounce
				spawnButton.Touch.Value = true
				spawnButton.Transparency = 0.5
				
				-- Destroy the previously owned vehicle
				if workspaceVehicles:FindFirstChild(player.Name) then
					workspaceVehicles:FindFirstChild(player.Name):Destroy()
				end
				
				-- Create the new vehicle model
				local newVehicle = vehicleToSpawn:Clone()
				newVehicle.Name = player.Name
				newVehicle.Configuration.Owner.Value = player
				newVehicle:SetPrimaryPartCFrame(spawnCFrame)
				newVehicle.Parent = workspaceVehicles
				
				--[[ Setup the health system for it ]]--
				
				-- Updates the health bar of a given vehicle based on the current health
				local lastVisible = tick()
				local function updateHealthBar(model, currentHealth, maxHealth)
					model.Engine.Info.Enabled = true
					model.Engine.Info.Active = true
					lastVisible = tick()
					delay(2, function()
						if tick() - lastVisible >= 1.99 then
							model.Engine.Info.Enabled = false
							model.Engine.Info.Active = false
						end
					end)
					
					local healthRatio = currentHealth/maxHealth
					local healthBar = model.Engine.Info.Health
					-- Adjust size and color
					healthBar:TweenSize(UDim2.new(healthRatio, 0, 0.15, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.25, true)
					if healthRatio > 0.66 then
						healthBar.BackgroundColor3 = HIGH_HEALTH_COLOR
					elseif healthRatio >= 0.33 and healthRatio <= 0.66 then
						healthBar.BackgroundColor3 = MEDIUM_HEALTH_COLOR
					else
						healthBar.BackgroundColor3 = LOW_HEALTH_COLOR
					end
				end

				local currentHealthValue = Instance.new("NumberValue")
				local maxHealth = newVehicle.Configuration.MaxHealth.Value
				currentHealthValue.Name = "CurrentHealth"
				currentHealthValue.Value = maxHealth
				currentHealthValue.Parent = newVehicle.Configuration
				local healthChangedEvent; healthChangedEvent = currentHealthValue.Changed:Connect(function(newHealth)
					updateHealthBar(newVehicle, newHealth, maxHealth)
					if newHealth <= 0 then
						--newVehicle:BreakJoints()
						local smoke = Instance.new("Smoke")
						smoke.Color = Color3.fromRGB(108, 108, 108)
						smoke.RiseVelocity = 2
						smoke.Size = 5
						smoke.Parent = newVehicle.Engine
						
						destroyVehicle:FireClient(player, false)
						
						healthChangedEvent:Disconnect()
					end
				end)		
				
				-- Set network ownership of the vehicle to the player
				assignNetworkOwnership(newVehicle, player)
					
				-- Update the label on the vehicle with the user's name
				updateOwnershipTag(newVehicle, player.Name, player.TeamColor.Color)
								
				-- Grant the player access to control the vehicle
				initializeVehicle:FireClient(player, vehicleType, newVehicle)
				
				-- End debounce once there are no obstructions in the spawning area
				repeat wait(0.1) until #game.Workspace:FindPartsInRegion3(spawnRegion, game.Workspace.Map.TriangleTerrain, 1) == 0
				spawnButton.Touch.Value = false
				spawnButton.Transparency = 0
			end
		end
	end)
end

-- Create connections for the original spawns in the world
local spawns = CollectionService:GetTagged(SPAWN_TAG) -- original spawns in the world
for _, s in pairs(CollectionService:GetTagged(SPAWN_TAG)) do
	createConnection(s)
end
-- Add a new spawn to connections when a new spawn is detected in the world
CollectionService:GetInstanceAddedSignal(SPAWN_TAG):Connect(function(newSpawn)
	createConnection(newSpawn)
end)

-- Removes spawn touch connections when a spawn is removed from the world
CollectionService:GetInstanceRemovedSignal(SPAWN_TAG):Connect(function(oldSpawn)
	if spawnConnections[oldSpawn] then
		spawnConnections[oldSpawn]:Disconnect()
		spawnConnections[oldSpawn] = nil
	end
end)

--[[
	Takes care of the case where a player's boat is occupied by someone else when they spawn a new one
	Don't want to destroy old boat
--]]
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local currentSeat = nil
		character:WaitForChild("Humanoid").Seated:Connect(function(active, currentSeatPart)
			-- Keep track of the latest seat for later bug fixing purposes
			if currentSeatPart then
				currentSeat = currentSeatPart
			end
			
			if active and currentSeatPart:IsA("VehicleSeat") and currentSeatPart.Name == "Driver" then
				-- Get vehicle that the player is a part of
				local newActiveVehicle = currentSeatPart.Parent
				
				-- Enable vehicle mouse if necessary
				local vehicleType = newActiveVehicle.Configuration.Type.Value
				player.NeedsVehicleMouse.Value = vehicleType == "Submarine" or vehicleType == "Helicopter" or vehicleType == "Spy Plane"
				
				-- Adjust camera distance to vehicle's required one
				local cameraDistance = newActiveVehicle.Configuration.CameraDistance.Value
				player.CameraMaxZoomDistance = cameraDistance
				delay(0.1, function() player.CameraMinZoomDistance = cameraDistance end)
				
				-- Checks between old owner and new owner
				local oldOwner = newActiveVehicle.Configuration.Owner.Value
				if player == oldOwner then return end
				
				-- Survivors should not be able to take Zombies' vehicles
				if player.Team and player.Team.Name == "Survivors" then return end
				
				-- Checks to see if the vehicle isn't dead
				if newActiveVehicle.Engine:FindFirstChildOfClass("Smoke") then return end
				
				-- Remove the old owner's ownership of the vehicle
				if oldOwner then
					destroyVehicle:FireClient(oldOwner, false)
				end
								
				-- Set network ownership of the vehicle to the player
				assignNetworkOwnership(newActiveVehicle, player)
				
				-- Remove new owner's current vehicle (if any) and assign ownership to new vehicle
				if workspaceVehicles:FindFirstChild(player.Name) then
					workspaceVehicles[player.Name]:Destroy()
				end
				newActiveVehicle.Name = player.Name
				newActiveVehicle.Configuration.Owner.Value = player
				updateOwnershipTag(newActiveVehicle, player.Name, player.TeamColor.Color)
				initializeVehicle:FireClient(player, newActiveVehicle.Configuration.Type.Value, newActiveVehicle)
			elseif not active and currentSeat then
				player.NeedsVehicleMouse.Value = false
				local driver = currentSeat.Parent:FindFirstChild("Driver") or currentSeat.Parent.Parent:FindFirstChild("Driver")
				if not driver then return end
				
				if player.Character then
					local vehicleType = driver.Parent.Configuration.Type.Value
					if vehicleType == "Submarine" or vehicleType == "Helicopter" or vehicleType == "Chinook" then
						player.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 10, 0)
					end
				end
				player.CameraMinZoomDistance = 10
				delay(0.1, function() player.CameraMaxZoomDistance = 10 end)
				
				-- Brute force bug fix for an engine bug where it sometimes forcibly removes network ownership from boat owner
				-- when jumping out of a seat in the boat after having equipped a weapon while sitting
				local vehicleNetworkOwner = driver.Parent.Configuration.Owner.Value
				wait()
				if currentSeat:GetNetworkOwner() ~= vehicleNetworkOwner then
					assignNetworkOwnership(vehicleNetworkOwner)
				end
				
				currentSeat = nil
			end
		end)
	end)
end)