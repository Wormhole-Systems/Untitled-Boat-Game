--[[
	 Manages the spawning of vehicles
	 Keeps track of the active vehicle each player has spawned
	 Ensures that each player is only assigned one active vehicle
	 Clear vehicles when the round comes to an end
--]]

-- Constants
local SPAWN_TAG = "Spawn"

-- Services
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Vehicle models and modules
local vehicles = ServerStorage:WaitForChild("Vehicles")
local vehicle = ServerScriptService:WaitForChild("Framework"):WaitForChild("Vehicle")

-- Table of all of the vehicle classes
local vehicleModules = {}
vehicleModules[vehicle.Name] = require(vehicle)
for _, v in pairs(vehicle:GetDescendants()) do
	vehicleModules[v.Name] = require(v)
end

-- Table to keep track of current vehicle for each player
local playerVehicles = {}

-- Event to clear vehicles (typically called at the end of a round)
game:GetService("ReplicatedStorage"):WaitForChild("RoundEvents"):WaitForChild("ClearVehicles").Event:Connect(function()
	for i, v in pairs(playerVehicles) do
		v:Destroy()
		playerVehicles[i] = nil
	end
	playerVehicles = {}
end)

-- Updates a vehicles owner tag to the given owner's name
local function updateOwnershipTag(ownerTag, name, vehicleName, teamColor)
	name = name:sub(#name, #name):lower() == "s" and name.."'" or name.."'s"
	ownerTag.Text = name.." "..vehicleName
	ownerTag.TextColor3 = teamColor
end

--[[ 
	Connect a button to a touched event
	Actually spawn a vehicle into the world
--]]
local spawnConnections = {}
local function createConnection(spawnButton)
	local vehicleToSpawn = vehicles:FindFirstChild(spawnButton["Vehicle"].Value)
	local vehicleType = spawnButton["Type"].Value
	local spawnPos = spawnButton.Position + spawnButton.CFrame.LookVector * (5 + vehicleToSpawn.PrimaryPart.Size.Z/2)
	if vehicleType ~= "Helicopter" and vehicleType ~= "Blimp" and vehicleType ~= "Chinook" and vehicleType ~= "SpyPlane" then
		spawnPos = Vector3.new(spawnPos.X, 0, spawnPos.Z) -- spawn at y = 0
	else
		spawnPos = spawnPos + Vector3.new(0, vehicleToSpawn.PrimaryPart.Size.Y/2, 0) -- spawn on the ground
	end
	
	local spawnCFrame = CFrame.new(spawnPos, spawnPos + spawnButton.CFrame.LookVector)
	local region3Size = 0.5 * vehicleToSpawn.PrimaryPart.Size
	local spawnRegion = Region3.new(spawnPos - region3Size, spawnPos + region3Size)
	
	spawnConnections[spawnButton] = spawnButton.Touched:Connect(function(hit)
		if not spawnButton.Touch.Value then
			local player = hit and hit.Parent and Players:GetPlayerFromCharacter(hit.Parent)
			if player and #game.Workspace:FindPartsInRegion3(spawnRegion, nil, 1) == 0 then
				spawnButton.Touch.Value = true
				spawnButton.Transparency = 0.5
				
				local newVehicle = vehicleModules[spawnButton["Type"].Value].new(vehicleToSpawn, spawnCFrame)
				newVehicle.TeamColor = player.TeamColor
				newVehicle:Initialize()
				for _, v in pairs(newVehicle.Model:GetChildren()) do
					if v:IsA("BasePart") then
						v:SetNetworkOwner(player)
					end
				end
				if playerVehicles[player.UserId] then
					playerVehicles[player.UserId]:Destroy()
					playerVehicles[player.UserId] = nil -- force an early garbage collection
				end
				playerVehicles[player.UserId] = newVehicle
				
				-- Update the label on the vehicle with the user's name
				updateOwnershipTag(newVehicle.Engine.Info.Owner, player.Name, newVehicle.Name, player.TeamColor.Color)
				
				repeat wait(0.1) until #game.Workspace:FindPartsInRegion3(spawnRegion, nil, 1) == 0
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
		local humanoid = character:WaitForChild("Humanoid")
		local humanoidSeatChangedConn, humanoidDiedConn
		
		humanoidSeatChangedConn = humanoid.Seated:Connect(function(active, currentSeatPart)
			if active and currentSeatPart:IsA("VehicleSeat") then
				local newActiveVehicle, oldOwnerId
				for i, v in pairs(playerVehicles) do
					if i ~= player.UserId and v.DriverSeat == currentSeatPart then
						--print(player.UserId, i)
						newActiveVehicle = v
						oldOwnerId = i
						break
					end
				end
				
				if newActiveVehicle then
					local activeVehicle = playerVehicles[player.UserId]
					if activeVehicle then
						activeVehicle:Destroy()
						playerVehicles[player.UserId] = nil
					end
					playerVehicles[oldOwnerId] = nil
					playerVehicles[player.UserId] = newActiveVehicle
					newActiveVehicle.TeamColor = player.TeamColor
					updateOwnershipTag(newActiveVehicle.Engine.Info.Owner, player.Name, newActiveVehicle.Name, player.TeamColor.Color)
				end
			end
		end)
	end)
end)