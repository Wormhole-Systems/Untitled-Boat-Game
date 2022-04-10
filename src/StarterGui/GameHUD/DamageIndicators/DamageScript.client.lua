
-- Micro-Optimizations
local Vector2_new = Vector2.new
local UDim2_new = UDim2.new
local atan2 = math.atan2
local sin = math.sin
local cos = math.cos
local deg = math.deg
local pi = math.pi

local TOPBAR_HEIGHT = 36
local CENTER_POS = Vector2_new(.5, .5)
local IDEAL_SIZE = Vector2_new(.15, .3)

local HIT_MARKDER_TIME = .1
local DAMAGE_INDICATOR_TIME = 3
local INDICATOR_DISTANCE = 100 --distance from the center of the indicator

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

local damageEvent = ReplicatedStorage.Invokers.Score.RegisterDamage

local frame = script.Parent
local indicators = frame.DamageIndicators

local hitMarker = script.Parent.HitMarker
local indicatorProto = script.DamageIndicator

local lastHitTime = 0
local function activateHitMarker()
	lastHitTime = tick()
	hitMarker.Visible = true
	delay(HIT_MARKDER_TIME, function()
		if tick() >= lastHitTime + HIT_MARKDER_TIME then
			hitMarker.Visible = false
		end
	end)
end

local function positionIndicator(indicator, damageOrigin, cameraCFrame)
	local character = player.Character
	if not character or not character.Parent then return end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	----[[
	local damageOffset = damageOrigin - hrp.Position
	
	local lateralOffset = Vector2_new(damageOffset.X, damageOffset.Z)
	local offsetAngle = atan2(lateralOffset.Y, lateralOffset.X)
	
	local camLookLateral = Vector2_new(cameraCFrame.LookVector.X, cameraCFrame.LookVector.Z)
	local camAngle = atan2(camLookLateral.Y, camLookLateral.X)
	
	local damageAngle = (offsetAngle - camAngle - pi/2)
	indicator.Position = UDim2_new(0.5,
		cos(damageAngle) * INDICATOR_DISTANCE - indicator.AbsoluteSize.X/2,
		0.5,
		sin(damageAngle) * INDICATOR_DISTANCE - indicator.AbsoluteSize.Y/2)
	indicator.Rotation = deg(damageAngle) + 90
	--]]
	--[[
	local lateralOffset = Vector2_new(damageOrigin.X, damageOrigin.Z)
	local camLookLateral = Vector2_new(cameraCFrame.LookVector.X, cameraCFrame.LookVector.Z).Unit
	local hrpLateral = Vector2_new(hrp.Position.X, hrp.Position.Z)
	
	local differenceLateral = (lateralOffset - hrpLateral).Unit
	local dir = camLookLateral.X * differenceLateral.Y - camLookLateral.Y * differenceLateral.X
	local angle = math.acos(camLookLateral:Dot(differenceLateral)) * (dir < 0 and -1 or (dir > 0 and 1 or 0))
	
	local sinAngle, cosAngle = sin(angle), cos(angle)
	local x, y = INDICATOR_DISTANCE * sinAngle, -INDICATOR_DISTANCE * cosAngle
	
	indicator.Position = UDim2_new(0.5,
		x - (indicator.AbsoluteSize.X)/2,
		0.5,
		y - (indicator.AbsoluteSize.Y)/2)
	indicator.Rotation = deg(angle)
	--]]
end

local function addDamageIndicator(offset)
	local indicatorClone = indicatorProto:Clone()
	indicatorClone.Parent = indicators
	
	local connection = camera:GetPropertyChangedSignal("CFrame"):Connect(function()
		positionIndicator(indicatorClone, offset, camera.CFrame)
	end)
	positionIndicator(indicatorClone, offset, camera.CFrame)
	
	delay(DAMAGE_INDICATOR_TIME, function()
		connection:Disconnect()
		indicatorClone:Destroy()
	end)
end


local function resize(guiObject, camera, minSizes)
	local viewSize = camera.ViewportSize
	local factoredSize = viewSize * minSizes
	local lesserSize = math.min(factoredSize.X, factoredSize.Y)
	guiObject.Size = UDim2_new(0, lesserSize, 0, lesserSize - TOPBAR_HEIGHT)
end

local function reposition(guiobject, pos)
	guiobject.Position = UDim2_new(
		pos.X - guiobject.Size.X.Scale/2, 
		-guiobject.Size.X.Offset/2,
		pos.Y - guiobject.Size.Y.Scale/2,
		-(guiobject.Size.Y.Offset)/2 - TOPBAR_HEIGHT/2)
end

local function setSizeConstraint(guiObject, camera, minSizes)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			resize(guiObject, camera, minSizes)
			reposition(guiObject, CENTER_POS)
		end)
	resize(guiObject, camera, minSizes)
	reposition(guiObject, CENTER_POS)
end

setSizeConstraint(script.Parent, game.Workspace.CurrentCamera, IDEAL_SIZE)
damageEvent.OnClientEvent:Connect(function(hitter, hittee, weapon, location, damage)
	if hitter == player then
		activateHitMarker()
	end
	if hittee == player then 
		addDamageIndicator(location)
	end
end)