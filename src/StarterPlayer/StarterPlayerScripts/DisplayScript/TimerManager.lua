local TimerManager = {}

-- Micro-optimizations
local max = math.max
local floor = math.floor
local stringf = string.format

-- [[ Local Variables ]] --
local timeObject = game.Workspace:WaitForChild("Status"):WaitForChild("Timer")
local screenGui = script.Parent.ScreenGui
local timer = screenGui.ScoreFrame.Timer
local events = game.ReplicatedStorage.RoundEvents
local displayTimerInfo = events.DisplayTimerInfo

local waiting = false

-- [[ Local Functions ]] --
local function onTimeChanged(newValue)
	if waiting then
		timer.Text = "(1/2)"
	else
		local currentTime = max(0, newValue)
		local minutes = floor(currentTime / 60)-- % 60
		local seconds = floor(currentTime) % 60
		timer["Text"].Text = stringf("%02d:%02d", minutes, seconds)
	end
end

local function onDisplayTimerInfo(intermission, waitingForPlayers)
	waiting = waitingForPlayers
	timer.Intermission.Visible = intermission
	timer.WaitingForPlayers.Visible = waitingForPlayers
end

-- [[ Event Bindings ]] --
timeObject.Changed:connect(onTimeChanged)
displayTimerInfo.OnClientEvent:connect(onDisplayTimerInfo)

return TimerManager
