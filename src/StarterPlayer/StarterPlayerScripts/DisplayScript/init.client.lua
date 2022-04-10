-- Constants
local INTERMISSION_CAMERA_DISTANCE = 750

-- Roblox Services
local RunService = game:GetService('RunService')

-- Game Services
local NotificationManager = require(script.NotificationManager)
local TimerManager = require(script.TimerManager)

-- Local Variables
local events = game.ReplicatedStorage.RoundEvents
local displayIntermission = events.DisplayIntermission
local changeTeam = events.ChangeTeam
local camera = game.Workspace.CurrentCamera
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = script.ScreenGui
local scoreFrame = screenGui:WaitForChild("ScoreFrame")
local winFrame = screenGui:WaitForChild("VictoryMessage"):WaitForChild("Win")
local map = game.Workspace:WaitForChild("Map")
local alphaBase, bravoBase = map:WaitForChild("BaseAlpha"), map:WaitForChild("BaseBravo")
local gameHUD, changeRadarEnabled
local firstTeamName, secondTeamName = "Team1", "Team2"

local inIntermission = false

-- Initialization
game.StarterGui.ResetPlayerGuiOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Change team UI
local teamSelect = screenGui.TeamSelect
local team1, team2, cannotUnbalance = teamSelect.Team1, teamSelect.Team2, teamSelect.CannotUnbalance
local team1NumPlayers, team2NumPlayers = team1.NumPlayers, team2.NumPlayers
local teamChangeConnections = {}

local function startIntermission(team1Name, team1Color, team2Name, team2Color)
	-- Make win frame invisible again
	winFrame.Parent.Visible = false
	winFrame.Visible = false
	winFrame[firstTeamName].Visible = false
	winFrame[secondTeamName].Visible = false
	winFrame.Parent.Tie.Visible = false
	
	-- Update score and win frames
	scoreFrame[firstTeamName].Name = team1Name
	scoreFrame[secondTeamName].Name = team2Name
	scoreFrame[team1Name]["Text"].TextColor3 = team1Color
	scoreFrame[team2Name]["Text"].TextColor3 = team2Color
	winFrame[firstTeamName].Name = team1Name
	winFrame[secondTeamName].Name = team2Name
	winFrame[team1Name].Text = team1Name.." "
	winFrame[team1Name].TextColor3 = team1Color
	winFrame[team1Name].Size = UDim2.new(0, winFrame[team1Name].TextBounds.X + 15, 0, 50)
	winFrame[team2Name].Text = team2Name.." "
	winFrame[team2Name].TextColor3 = team2Color
	winFrame[team2Name].Size = UDim2.new(0, winFrame[team2Name].TextBounds.X + 15, 0, 50)
	firstTeamName, secondTeamName = team1Name, team2Name

	-- Team changing UI implementation
	teamSelect.Visible = true
	team1.Text, team1.BackgroundColor3, team2.Text, team2.BackgroundColor3 = team1Name, team1Color, team2Name, team2Color
	
	local firstTeam, secondTeam = game.Teams:FindFirstChild(team1Name), game.Teams:FindFirstChild(team2Name)
	local numPlayers = #game.Players:GetPlayers()
	local maxPlayers = math.ceil(numPlayers/2)
	
	local lastFail
	local function onTeamChangeRequest(newTeam)
		if player.Team and player.Team == newTeam then return end
		cannotUnbalance.Visible = false
		local success = changeTeam:InvokeServer(newTeam.Name)
		if not success then
			lastFail = tick()
			cannotUnbalance.Visible = true
			delay(2, function()
				if tick() - lastFail >= 1.99 then
					cannotUnbalance.Visible = false
				end
			end)
		end
	end
	
	local function updateMaxLabels()
		team1NumPlayers.Text = "("..#firstTeam:GetPlayers().."/"..maxPlayers..")"
		team2NumPlayers.Text = "("..#secondTeam:GetPlayers().."/"..maxPlayers..")"
	end
	
	local function onNumPlayersChanged()
		numPlayers = #game.Players:GetPlayers()
		maxPlayers = math.ceil(numPlayers/2)
		updateMaxLabels()
	end
	
	-- Team change event connections
	updateMaxLabels()
	teamChangeConnections[#teamChangeConnections + 1] = team1.MouseButton1Click:Connect(function() onTeamChangeRequest(firstTeam) end)
	teamChangeConnections[#teamChangeConnections + 1] = team2.MouseButton1Click:Connect(function() onTeamChangeRequest(secondTeam) end)
	teamChangeConnections[#teamChangeConnections + 1] = firstTeam.PlayerAdded:Connect(updateMaxLabels)
	teamChangeConnections[#teamChangeConnections + 1] = firstTeam.PlayerRemoved:Connect(updateMaxLabels)
	teamChangeConnections[#teamChangeConnections + 1] = secondTeam.PlayerAdded:Connect(updateMaxLabels)
	teamChangeConnections[#teamChangeConnections + 1] = secondTeam.PlayerRemoved:Connect(updateMaxLabels)
	teamChangeConnections[#teamChangeConnections + 1] = game.Players.PlayerAdded:Connect(onNumPlayersChanged)
	teamChangeConnections[#teamChangeConnections + 1] = game.Players.PlayerRemoving:Connect(onNumPlayersChanged)
	
	-- Find flag to circle. Default to circle center of map
	local possiblePoints = {}
	table.insert(possiblePoints, Vector3.new(0, 50, 0))
	
	if alphaBase:FindFirstChild("FlagStand") then
		table.insert(possiblePoints, alphaBase.FlagStand.Position)
	end
	if bravoBase:FindFirstChild("FlagStand") then
		table.insert(possiblePoints, bravoBase.FlagStand.Position)
	end
	
	-- Disable radar
	if gameHUD and changeRadarEnabled then
		gameHUD.Enabled = false
		changeRadarEnabled:Fire(false)
	end
	
	local focalPoint = possiblePoints[math.random(#possiblePoints)]
	camera.CameraType = Enum.CameraType.Scriptable
	camera.Focus = CFrame.new(focalPoint)
	
	local angle = 0
	game.Lighting.Blur.Enabled = true
	RunService:BindToRenderStep('IntermissionRotate', Enum.RenderPriority.Camera.Value, function()
		local cameraPosition = focalPoint + Vector3.new(INTERMISSION_CAMERA_DISTANCE * math.cos(angle), 20, INTERMISSION_CAMERA_DISTANCE * math.sin(angle))
		camera.CFrame = CFrame.new(cameraPosition, focalPoint)
		angle = angle + math.rad(.25)
	end)	
end

local function stopIntermission()		
	game.Lighting.Blur.Enabled = false
	RunService:UnbindFromRenderStep('IntermissionRotate')
	camera.CameraType = Enum.CameraType.Custom
	if not changeRadarEnabled then
		gameHUD = playerGui:WaitForChild("GameHUD")
		changeRadarEnabled = gameHUD:WaitForChild("Radar"):WaitForChild("ChangeRadarEnabled")
		wait()
	end
	gameHUD.Enabled = true
	changeRadarEnabled:Fire(true)
	teamSelect.Visible = false
	for _, v in pairs(teamChangeConnections) do
		v:Disconnect()
	end
	teamChangeConnections = {}
end

local function onDisplayIntermission(display, team1Name, team1Color, team2Name, team2Color)
	if display and not inIntermission then
		inIntermission = true
		startIntermission(team1Name, team1Color, team2Name, team2Color)
	end	
	if not display and inIntermission then
		inIntermission = false
		stopIntermission()
	end
end

-- Event Bindings
displayIntermission.OnClientEvent:Connect(onDisplayIntermission)