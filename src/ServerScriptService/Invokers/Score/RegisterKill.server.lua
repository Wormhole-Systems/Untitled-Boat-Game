local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServerEvent = ServerStorage.Invokers.Score.RegisterKillServer
local RemoteEvent = ReplicatedStorage.Invokers.Score.RegisterKillRemote

ServerEvent.Event:Connect(function (killer, victim, weapon)
	
	RemoteEvent:FireAllClients(killer, victim, weapon)
end)