local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local event = ReplicatedStorage.Invokers.Score.RegisterKillRemote

local tools = require(ReplicatedFirst.GameTools)

local frame =  script.Parent
local killList = frame.Kills
local killProto = script.KillCell

local protoHeight = killProto.Size.Y

local listProto = tools.Queue

local FEED_SIZE = 6
--amount of time a record will show up on the feed for
local KILL_DISPLAY_TIME = 10

local killQueue = listProto.new()

local tweenStyle = Enum.EasingStyle.Quart
local tweenTime = .25

local transparencyTweenfo = TweenInfo.new(tweenTime, tweenStyle, Enum.EasingDirection.InOut, 0, false, 0)

local function tweenKillTransparency(thing, transp, tTime)
	
	local tweenfo = TweenInfo.new(tTime, tweenStyle, Enum.EasingDirection.InOut, 0, false, 0)
	
	local tweeno = TweenService:Create(thing, transparencyTweenfo, {BackgroundTransparency = 1})
	local tweenKiller = TweenService:Create(thing.KillerLabel, transparencyTweenfo, {TextTransparency = transp})
	local tweenVictim = TweenService:Create(thing.VictimLabel, transparencyTweenfo, {TextTransparency = transp})
	local tweenView = TweenService:Create(thing.WeaponView, transparencyTweenfo, {ImageTransparency = transp})
	
	return {tweeno, tweenKiller, tweenVictim, tweenView}
end

local function playTweens (tweens)
	for _, v in pairs (tweens) do
		v:Play()
	end
end

local function popKillQueue()
	local killThing = killQueue:pop()
	
	killThing.kill:TweenPosition(UDim2.new(0,0,-protoHeight.Scale, -protoHeight.Offset), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, tweenTime, false,
		function()
			killThing.kill:Destroy()
		end)
	--local tweeno = TweenService:Create(killThing.kill, transparencyTweenfo, {BackgroundTransparency = 1})
	
	playTweens(tweenKillTransparency(killThing.kill, 1, tweenTime))
	
end

--killer and victim can be models or Player objects
local function registerKill(killer, victim, weapon)
	local killClone = killProto:Clone()
	
	killClone.KillerLabel.Text = killer.Name
	killClone.VictimLabel.Text = victim.Name
	
	if killer:IsA("Player") then
		killClone.KillerLabel.TextColor3 = killer.TeamColor.Color
	end
	if victim:IsA("Player") then
		killClone.VictimLabel.TextColor3 = victim.TeamColor.Color
	end
	
	local weaponView = killClone.WeaponView
	--local camera = Instance.new("Camera", weaponView)
	--camera.CFrame = CFrame.new(Vector3.new(0, 0, -5), Vector3.new())
	
	local weaponClone = weapon:Clone()
	--weaponClone.Handle.CFrame = CFrame.new(Vector3.new(), Vector3.new(1, 0, 0))
	--weaponClone.Parent = weaponView
	--tools.setViewportFrameContent2(weaponView, weaponClone, CFrame.new(Vector3.new(), Vector3.new(1, 0, 0)), CFrame.new(Vector3.new(0, 0, -3), Vector3.new()))
	tools.setViewportFrameContent(weaponView, weaponClone, Vector3.new(1, 0, 0), true)
	killQueue:push({kill = killClone, stamp = tick()})
	
	local size = killQueue:size()
		
	killClone.Position = UDim2.new(0,0,protoHeight.Scale * size, protoHeight.Offset * size)
	killClone.Parent = killList
	
	playTweens(tweenKillTransparency(killClone, 0, tweenTime))
	
	--TODO: implement timing out of killfeed stuff
	delay(KILL_DISPLAY_TIME, function()
		local killThing = killQueue:peek()
		--if the last timestamp in the queue happens after K_D_T seconds before the current time
		if killThing.stamp <= tick() - KILL_DISPLAY_TIME then
		--if tick() - killThing.stamp > KILL_DISPLAY_TIME then
			popKillQueue()
			--killQueue:pop().kill:Destroy()
		end
	end)
	
	--add animations here
	for i = killQueue.first, killQueue.last do
		local index = i - killQueue.first
		local unindex = killQueue:size() - index - 1 --get the index, but invert it relative to the size of the queue
		local indexio = index + killQueue.first
		local killo = killQueue[indexio]
		killo.kill:TweenPosition(UDim2.new(0,0,protoHeight.Scale*unindex, protoHeight.Offset*unindex), Enum.EasingDirection.InOut, Enum.EasingStyle.Quart, tweenTime, false, nil)
	end
	
	if killQueue:size() > FEED_SIZE then
		popKillQueue()
	end
end

--still gotta fix this
--frame.Size = UDim2.new(frame.Size.X, protoHeight.Scale * FEED_SIZE, protoHeight.Offset * FEED_SIZE)
frame.BackgroundTransparency = 1
playTweens(tweenKillTransparency(killProto, 1, 0))
event.OnClientEvent:Connect(registerKill)