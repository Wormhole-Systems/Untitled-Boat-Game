-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Current gamemode value
local gamemode = game.Workspace:WaitForChild("Status"):WaitForChild("Gamemode")

-- Turret controller for client -> server
local rotateVehicleTurretServer = ReplicatedStorage:WaitForChild("Invokers"):WaitForChild("Weapon"):WaitForChild("RotateVehicleTurretServer")

-- Constants
local TURRET_TAG = "Turret"
local TURRET_CONTROLLER = game:GetService("ServerStorage"):WaitForChild("HelperScripts"):WaitForChild("ControllerTurret")

-- Table to keep track of all the turret and their event connections in the workspace
local turretSeatConnections = {}

-- Changes network ownership of a model to the assigned owner
local function assignNetworkOwnership(model, newOwner)
	for _, v in pairs(model:GetDescendants()) do
		if v:IsA("BasePart") and v.Name ~= "TurretBase" then
			v:SetNetworkOwner(newOwner)
		end
	end
end

local function createConnection(turret)
	-- The current occupant of the turret
	local currentOccupant = nil
	
	-- Determines whether the turret is part of a vehicle or not
	local isVehicleTurret = turret.Parent:FindFirstChildOfClass("VehicleSeat") ~= nil
		
	-- Constraints
	local pivotConstraint = turret:WaitForChild("Pivot"):WaitForChild("PivotConstraint")
	local verticalConstraint = turret:WaitForChild("Handle"):WaitForChild("VerticalConstraint")	
	
	-- Make sure it belongs to the server initially
	if not isVehicleTurret then
		assignNetworkOwnership(turret, nil)
	end
	
	-- Handle change in turrent owner based on who sits in the seat
	local seat = turret:WaitForChild("Seat")
	turretSeatConnections[turret] = seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if occupant then
			local player = game.Players:GetPlayerFromCharacter(occupant.Parent)
			if player then
				-- Disable turrets during Zombies gamemode
				if gamemode.Value == "Zombies" then return end
				
				-- Update reference to the current occupant
				currentOccupant = occupant
				
				-- Remove old turret controller if it already exists in the player's character
				if occupant.Parent:FindFirstChild("ControllerTurret") then
					occupant.Parent["ControllerTurret"]:Destroy()	
				end
				
				-- Set sitting animation to be of one with hands out
				--occupant.Parent.Animate.sit.SitAnim.AnimationId = "rbxassetid://4536805497"
				
				-- Tighten hinge connections
				pivotConstraint.ActuatorType = Enum.ActuatorType.Servo
				verticalConstraint.ActuatorType = Enum.ActuatorType.Servo
				
				-- Give network ownership to the player
				if not isVehicleTurret then
					assignNetworkOwnership(turret, player)
				end
								
				-- Grant control access to the player
				local controller = TURRET_CONTROLLER:Clone()
				controller.PivotConstraintObject.Value = pivotConstraint
				controller.VerticalConstraintObject.Value = verticalConstraint
				controller.Parent = occupant.Parent
			end
		else
			-- Give network ownership back to the server and loosen up hinge connections
			if not isVehicleTurret then
				assignNetworkOwnership(turret, nil)
			end
			pivotConstraint.ActuatorType = Enum.ActuatorType.None
			verticalConstraint.ActuatorType = Enum.ActuatorType.None
			
			-- Remove control access from the former occupant of the turret
			if currentOccupant and currentOccupant.Parent and currentOccupant.Parent:FindFirstChild("ControllerTurret") then
				currentOccupant.Parent["ControllerTurret"].Disable.Value = true
			end
			
			-- Set sitting animation back to the normal one
			--currentOccupant.Parent.Animate.sit.SitAnim.AnimationId = "rbxassetid://2506281703"
				
			currentOccupant = nil
		end
	end)
end

-- Create connections for the original turrets in the world
local spawns = CollectionService:GetTagged(TURRET_TAG) -- original spawns in the world
for _, t in pairs(CollectionService:GetTagged(TURRET_TAG)) do
	if t:IsDescendantOf(game.Workspace) then
		createConnection(t)
	end
end
-- Add a new spawn to connections when a new spawn is detected in the world
CollectionService:GetInstanceAddedSignal(TURRET_TAG):Connect(function(newTurret)
	createConnection(newTurret)
end)
-- Removes spawn touch connections when a spawn is removed from the world
CollectionService:GetInstanceRemovedSignal(TURRET_TAG):Connect(function(oldTurret)
	if turretSeatConnections[oldTurret] then
		turretSeatConnections[oldTurret]:Disconnect()
		turretSeatConnections[oldTurret] = nil
	end
end)

rotateVehicleTurretServer.OnServerEvent:Connect(function(player, turret, pivotConstraintTargetAngle, verticalConstraintTargetAngle)
	if player.Character and turret and turret:FindFirstChild("Seat") and turret.Seat.Occupant and turret.Seat.Occupant.Parent == player.Character then
		local turretNetworkOwner = turret.Seat:GetNetworkOwner()
		if turretNetworkOwner ~= player then
			turret.Pivot.PivotConstraint.TargetAngle = pivotConstraintTargetAngle
			turret.Handle.VerticalConstraint.TargetAngle = verticalConstraintTargetAngle
		end
	end
end)