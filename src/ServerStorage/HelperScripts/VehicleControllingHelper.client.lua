local UserInputerService = game:GetService("UserInputService")
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

local changeAltitude = script:WaitForChild("ChangeAltitude").Value
local shootMissile = script:WaitForChild("FireMissile").Value

UserInputerService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent and input.KeyCode ~= Enum.KeyCode.E then return end
	if input.KeyCode == Enum.KeyCode.Q then
		--print("Sending signal to go down")
		changeAltitude:FireServer(-1)
	elseif input.KeyCode == Enum.KeyCode.E then
		--print("Sending signal to go up")
		changeAltitude:FireServer(1)
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 and shootMissile then
		--print("Sending signal to fire missile/torpedo")
		mouse.TargetFilter = game.Workspace.Terrain
		shootMissile:FireServer(mouse.Hit)
		mouse.TargetFilter = nil
	end
end)

UserInputerService.InputEnded:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent and input.KeyCode ~= Enum.KeyCode.E then return end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
		changeAltitude:FireServer(0)
		--print("Holding altitude steady")
	end
end)