local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local halfScreenPoint = game.Workspace.CurrentCamera.ViewportSize.X/2

-- Services
local UserInputService = game:GetService("UserInputService")

-- Event to signal to the server to adjust the spy plane's gyro
local changeGyro = script:WaitForChild("EventPointer").Value

if not UserInputService.KeyboardEnabled then
	mouse.Move:Connect(function()
		changeGyro:FireServer(mouse.Hit, mouse.X < halfScreenPoint and 1 or mouse.X > halfScreenPoint and -1 or 0)
	end)
end

mouse.Idle:Connect(function()
	changeGyro:FireServer(mouse.Hit, mouse.X < halfScreenPoint and 1 or mouse.X > halfScreenPoint and -1 or 0)
end)
