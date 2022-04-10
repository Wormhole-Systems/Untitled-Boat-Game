local RunService = game:GetService("RunService")

local module = require(game:GetService("ReplicatedStorage").Framework.Projectiles.Projectiles)

RunService.Heartbeat:Connect(module.UpdateProjectiles)