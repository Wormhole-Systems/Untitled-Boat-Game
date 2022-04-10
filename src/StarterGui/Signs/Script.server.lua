-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

-- Game Services
local GameTools = require(ReplicatedFirst:WaitForChild("GameTools"))

-- Vehicles folder
local vehicles = ServerStorage:WaitForChild("Vehicles")

-- Bravo base vehicles
local baseAlpha = game.Workspace.Map.BaseAlpha.VehicleSpawners
local alphaColor = BrickColor.new("Bright red")
local bravoColor = BrickColor.new("Bright blue")

local function processSign(viewport, vehicleType, vehicleColor)
	local vehicle = vehicles[vehicleType]:Clone()
	for _, v in pairs(vehicle:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Anchored = true
			if v.Parent.Name == "Secondary" then
				v.BrickColor = vehicleColor
			end
		end
	end
	vehicle:BreakJoints()
	vehicle.PrimaryPart = vehicle.Hull
	
	GameTools.setViewportFrameContent(viewport, vehicle, Vector3.new(1, 0, 0), false, true)
end

for _, v in pairs(CollectionService:GetTagged("Spawn")) do
	if v:FindFirstChild("Sign") then
		local surfaceGui = script.SurfaceGui:Clone()
		surfaceGui.Adornee = v.Sign.Board
		surfaceGui.Parent = script.Parent
		
		processSign(surfaceGui.ViewportFrame, v["Type"].Value, v:IsDescendantOf(baseAlpha) and alphaColor or bravoColor)
	end
end

script:Destroy()