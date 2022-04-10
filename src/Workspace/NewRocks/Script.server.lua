local smoothRocks = game.Workspace:WaitForChild("RocksSmooth"):GetChildren()
local numSmoothRocks = #smoothRocks

local rand = Random.new()

local rocksToReplace = game.Workspace:WaitForChild("Map"):WaitForChild("BaseAlpha"):WaitForChild("BaseRocks")

for _, v in pairs(rocksToReplace:GetChildren()) do
	local newRock = smoothRocks[rand:NextInteger(1, numSmoothRocks)]:Clone()
	newRock.Size = v.Size
	newRock.Orientation = v.Orientation
	newRock.CFrame = v.CFrame
	v:Destroy()
	newRock.Parent = script.Parent
end