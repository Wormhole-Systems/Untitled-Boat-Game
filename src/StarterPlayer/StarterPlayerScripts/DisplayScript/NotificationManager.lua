local NotificationManager = {}

-- [[ Local Variables ]] --
local scoreFrame = script.Parent.ScreenGui.ScoreFrame
local victoryFrame = script.Parent.ScreenGui.VictoryMessage
local events = game.ReplicatedStorage.RoundEvents
local displayNotification = events.DisplayNotification
local displayVictory = events.DisplayVictory
local displayScore = events.DisplayScore
local resetMouseIcon = events.ResetMouseIcon
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local mouseIcon = mouse.Icon

-- [[ Local Functions ]] --
local function onDisplayNotification(teamName, message)
	local notificationFrame = scoreFrame[teamName].Notification
	notificationFrame.Text = message
	notificationFrame:TweenSize(UDim2.new(1,0,1,0), Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad, .25, false)
	wait(1.5)
	notificationFrame:TweenSize(UDim2.new(1,0,0,0), Enum.EasingDirection.Out,
		Enum.EasingStyle.Quad, .1, false)
end

local function onScoreChange(team, score)
	scoreFrame[team.Name]["Text"].Text = score
end

local function onDisplayVictory(winningTeam)
	if winningTeam then
		victoryFrame.Visible = true
		if winningTeam == 'Tie' then
			victoryFrame.Tie.Visible = true
		else
			victoryFrame.Win.Visible = true
			local winningFrame = victoryFrame.Win[winningTeam.Name]
			winningFrame.Visible = true
		end
	end
end

local function onResetMouseIcon()
	mouse.Icon = mouseIcon
end

-- [[ Event Bindings ]] --
displayNotification.OnClientEvent:connect(onDisplayNotification)
displayVictory.OnClientEvent:connect(onDisplayVictory)
displayScore.OnClientEvent:connect(onScoreChange)
resetMouseIcon.OnClientEvent:connect(onResetMouseIcon)

return NotificationManager
