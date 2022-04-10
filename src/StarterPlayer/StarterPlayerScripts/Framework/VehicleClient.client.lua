-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Folders
local workspaceVehicles = game.Workspace:WaitForChild("Vehicles")
local vehicleEvents = ReplicatedStorage:WaitForChild("Invokers"):WaitForChild("Vehicle")
local vehicle = ReplicatedStorage:WaitForChild("Framework"):WaitForChild("Vehicle")

-- Dictionary of all of the vehicle classes
local vehicleModules = {}
vehicleModules[vehicle.Name] = require(vehicle)
for _, v in pairs(vehicle:GetDescendants()) do
	vehicleModules[v.Name] = require(v)
end

-- Variable to keep track of the current vehicle
local currentVehicle = nil

vehicleEvents.InitializeVehicle.OnClientEvent:Connect(function(vehicleType, vehicleModel)
	if vehicleModel then
		if currentVehicle then
			currentVehicle:Destroy(true)
		end
		currentVehicle = vehicleModules[vehicleType].new(vehicleModel)
		currentVehicle:Initialize()
	end
end)

vehicleEvents.DestroyVehicle.OnClientEvent:Connect(function(shouldDestroyModel)
	if currentVehicle then
		currentVehicle:Destroy(shouldDestroyModel)
		currentVehicle = nil
	end
end)