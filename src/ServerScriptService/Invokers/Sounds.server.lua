local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Deploy Parachute Event
local playSound = ReplicatedStorage:WaitForChild("Invokers"):WaitForChild("Sounds"):WaitForChild("PlaySound")
local adjustSoundVolume = ReplicatedStorage:WaitForChild("Invokers"):WaitForChild("Sounds"):WaitForChild("AdjustSoundVolume")

playSound.OnServerEvent:Connect(function(player, sound, playing)
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player then
			playSound:FireClient(v, sound, playing)
		end
	end
end)

adjustSoundVolume.OnServerEvent:Connect(function(player, sound, volume)
	for _, v in pairs(Players:GetPlayers()) do
		if v ~= player then
			playSound:FireClient(v, sound, volume)
		end
	end
end)