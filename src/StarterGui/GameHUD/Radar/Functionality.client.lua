-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Constants
local MAX_RADIUS_DISTANCE = 100
local TEAMMATE_COLOR = Color3.new(0, 200, 0)
local ENEMY_COLOR = Color3.new(200, 0, 0)
local IDEAL_SIZE = Vector2.new(.15, .25)

-- Micro-optimizations
local Vector2_new = Vector2.new
local UDim2_new = UDim2.new
local acos = math.acos
local sin = math.sin
local cos = math.cos

-- Player and camera variables
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local camera = game.Workspace.CurrentCamera

-- Events
local changeRadarEnabled = script.Parent:WaitForChild("ChangeRadarEnabled")
local updateRadarConn

-- Radar object references
local radar = script.Parent
local points = radar:WaitForChild("Points")
local point = radar:WaitForChild("Point")
local radarRadius = radar.AbsoluteSize.X/2 - 10

-- Function that shows location of nearby teammates and enemies
local function updateRadar()
	if not character.Parent then return end
	
	-- Local character and camera values used for determining relative position of others from local player
	local myPos = Vector2_new(humanoidRootPart.Position.X, humanoidRootPart.Position.Z)
	local lookVector = camera.CFrame.LookVector
	local myLookVector = Vector2_new(lookVector.X, lookVector.Z).Unit
	
	local players = Players:GetPlayers()
	for i = 1, #players do
		local v = players[i]
		-- Only other players
		if v ~= player and v.Character 
		 and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0
		 and v.Character:FindFirstChild("HumanoidRootPart") then
			local otherHRP = v.Character.HumanoidRootPart.Position
			local otherPos = Vector2_new(otherHRP.X, otherHRP.Z)
			local distance = (myPos - otherPos).Magnitude
			if distance <= MAX_RADIUS_DISTANCE then
				-- Find that player's point on the radar or create one if needed
				local plrPoint = points:FindFirstChild(v.Name)
				if not plrPoint then
					-- Create the point on the radar for this player if not already there
					plrPoint = point:Clone()
					plrPoint.Name = v.Name
					plrPoint.Visible = true
					plrPoint.BackgroundColor3 = v.TeamColor == player.TeamColor and TEAMMATE_COLOR or ENEMY_COLOR
					plrPoint.Parent = points
				end
				
				-- Calculate angle between 
				local otherLookVector = (otherPos - myPos).Unit
				local dir = myLookVector.X * otherLookVector.Y - myLookVector.Y * otherLookVector.X
				local angle = acos(myLookVector:Dot(otherLookVector)) * (dir < 0 and -1 or (dir > 0 and 1 or 0))
				
				-- Calculate x and y positions on the radar based on the angle
				local hypotenuse = distance/MAX_RADIUS_DISTANCE * radarRadius
				local sinAngle, cosAngle = sin(angle), cos(angle)
				local x, y = hypotenuse * sinAngle, -hypotenuse * cosAngle
				
				-- Set/update its position
				plrPoint.Position = point.Position + UDim2_new(0, x, 0, y)
				
			else
				-- Remove any existing points that are outside the range
				if points:FindFirstChild(v.Name) then
					points[v.Name]:Destroy()
				end
			end
		else
			-- Remove any existing points that are outside the range
			if points:FindFirstChild(v.Name) then
				points[v.Name]:Destroy()
			end
		end
	end
end

-- Bind events
changeRadarEnabled.Event:Connect(function(enabled)
	radar.Visible = enabled
	updateRadarConn = enabled and RunService.RenderStepped:Connect(updateRadar) or (updateRadarConn and updateRadarConn:Disconnect() or nil)
	if not enabled then
		points:ClearAllChildren()
	end
end)

player.CharacterAdded:Connect(function(char)
	character = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

Players.PlayerRemoving:Connect(function(player)
	if points:FindFirstChild(player.Name) then
		points[player.Name]:Destroy()
	end
end)

local function resizeRadar()
	local viewSize = camera.ViewportSize
	local factoredSize = viewSize * IDEAL_SIZE
	local lesserSize = math.min(factoredSize.X, factoredSize.Y)
	
	radar.Size = UDim2.new(0, lesserSize, 0, lesserSize)
	radar.Position = UDim2.new(0, 5, 1, -(lesserSize + 5))
	radarRadius = radar.AbsoluteSize.X/2 - 10
end

resizeRadar()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeRadar)
changeRadarEnabled:Fire(true)