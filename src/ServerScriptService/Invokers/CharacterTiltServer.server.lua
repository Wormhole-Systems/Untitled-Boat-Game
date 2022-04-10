-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Constants
local UPDATES_PER_SECOND = 3
local WAIT_TIME = 1/UPDATES_PER_SECOND

-- Character tilting event
local characterTilt = ReplicatedStorage:WaitForChild("Invokers"):WaitForChild("CharacterTilt")

-- Table to keep track of the rotation values of each player
local tiltValues = {}

-- Remove a player's entry from the tilt values table if he/she leaves
Players.PlayerRemoving:Connect(function(player)
	tiltValues[player.UserId] = nil
end)

-- Update a player's rotation in the table
characterTilt.OnServerEvent:Connect(function(player, ...)
	-- Create/update the player's entry in the array containing tilt information
	tiltValues[player.Name] = {...}
	characterTilt:FireAllClients(player, ...)
end)

-- Broadcast periodic updates
--[[
while true do
	characterTilt:FireAllClients(tiltValues)
	wait(WAIT_TIME)
end
--]]