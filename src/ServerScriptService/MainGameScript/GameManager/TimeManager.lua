local TimeManager = {}

-- [[ Local Variables ]] --
local startTime = 0
local duration = 0

-- [[ Initialization ]] --
local timer = game.Workspace:WaitForChild("Status"):WaitForChild("Timer")

-- [[ Public Functions ]] --
function TimeManager:StartTimer(newDuration)
	startTime = tick()
	duration = newDuration
	spawn(function()
		repeat
			if duration == newDuration then
				timer.Value = duration - (tick() - startTime)
			else
				break
			end
			wait()
		until timer.Value <= 0
		timer.Value = 0
	end)
end

function TimeManager:TimerDone()
	return tick() - startTime >= duration
end

return TimeManager
