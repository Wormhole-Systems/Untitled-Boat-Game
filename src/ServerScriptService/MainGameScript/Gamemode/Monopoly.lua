local Monopoly = setmetatable({}, require(script.Parent))

-- [[ Services ]] --
local Players = game.Players
local Teams = game:GetService("Teams")

-- [[ Constants ]] -- 
local MAX_CAPTURE_REQUIREMENT = Monopoly.Configurations.REQUIRED_AMOUNT_TO_CAPTURE
local CAPTURE_SPEED_PER_PLAYER = Monopoly.Configurations.CAPTURE_SPEED_PER_PLAYER
local MAX_OIL_TO_WIN = Monopoly.Configurations.MAX_OIL_TO_WIN
local UNCAPTURED_COLOR = Color3.fromRGB(160, 160, 160)
local IS_STUDIO = game:GetService("RunService"):IsStudio()

-- [[ Micro-Optimizations ]] --
local UDim2_new = UDim2.new
local clamp = math.clamp
local abs = math.abs

-- [[ Static Values ]] --
Monopoly.Name = "Monopoly"
Monopoly.Codename = "KOTH"
Monopoly.Description = "The oil rigs are leaking! \n\
					 	Be the team to maintain control over the majority\n\
					 	of them throughout the duration of the round to win!"

-- [[ Map References ]]
local oilRigGroup = game.Workspace:WaitForChild("Map"):WaitForChild("OilRigs")
local oilRigs = oilRigGroup:GetChildren()
local alpha, bravo

-- [[ Tables ]] --
local oilRigConnections = {} -- connections for entering/leaving an oil rig
local captured = {}			 -- stores how much of each rig is captured
local capturedBy = {}		 -- keeps track of which rig is captured by which team
local lastCaptureVisual = {} -- keep track of when the last visual was updated for each oil rig


local function isTouching(mainPart, otherPart)
	for _, v in pairs(mainPart:GetTouchingParts()) do
		if v == otherPart then
			return true
		end
	end
	return false
end

-- [[ Public Functions ]] --
function Monopoly:Initialize()
	getmetatable(Monopoly):Initialize()
	
	alpha, bravo = Teams["Alpha"],Teams["Bravo"]
	captured[alpha], captured[bravo] = 0, 0 -- percentages
	
	-- Set up oil rigs
	for _, oilRig in pairs(oilRigs) do
		-- Create a connection to allow :GetTouchingParts to be used
		oilRigConnections[#oilRigConnections + 1] = oilRig.PrimaryPart.Touched:Connect(function() end)
		oilRig.PrimaryPart.Info.Enabled = true
	end
end

local shouldUpateScore = true
function Monopoly:Update()
	-- For each oil rig
	for _, oilRig in pairs(oilRigs) do
		-- Count the number of alpha and bravo team members near it
		local numAlpha, numBravo = 0, 0
		for _, p in pairs(oilRig.PrimaryPart:GetTouchingParts()) do
			if p.Name == "Head" then
				local character = p.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if player and player.Team then
					if player.Team == alpha then
						numAlpha = numAlpha + 1
					elseif player.Team == bravo then
						numBravo = numBravo + 1
					end
				end
			end
		end
		
		local info = oilRig.PrimaryPart.Info
		local activeGUI
		if numAlpha > 0 and numBravo == 0 then
			captured[oilRig] = clamp(captured[oilRig] + numAlpha, 0, MAX_CAPTURE_REQUIREMENT)
			info.Alpha.Visible = captured[oilRig] ~= MAX_CAPTURE_REQUIREMENT
			info.Bravo.Visible = false
			
			-- Fill up capturing bar if inecessary
			if captured[oilRig] == MAX_CAPTURE_REQUIREMENT then
				capturedBy[oilRig] = alpha
				info.RigName.Visible = true
				info.RigName.BackgroundColor3 = alpha.TeamColor.Color
			else
				-- Capturing effect
				activeGUI = info.Alpha.ProgressTop
				if not lastCaptureVisual[oilRig] then lastCaptureVisual[oilRig] = tick() end
				if tick() - lastCaptureVisual[oilRig] >= 1 then
					info.RigName.Visible = not info.RigName.Visible
					lastCaptureVisual[oilRig] = tick()
				end
			end
		elseif numBravo > 0 and numAlpha == 0 then
			-- Bravo is capturing
			captured[oilRig] = clamp(captured[oilRig] + numBravo, 0, MAX_CAPTURE_REQUIREMENT)
			info.Alpha.Visible = false
			info.Bravo.Visible = captured[oilRig] ~= MAX_CAPTURE_REQUIREMENT
			
			-- Fill up capturing bar if inecessary
			if captured[oilRig] == MAX_CAPTURE_REQUIREMENT then
				capturedBy[oilRig] = bravo
				info.RigName.Visible = true
				info.RigName.BackgroundColor3 = bravo.TeamColor.Color
			else
				-- Capturing effect
				activeGUI = info.Bravo.ProgressTop
				if not lastCaptureVisual[oilRig] then lastCaptureVisual[oilRig] = tick() end
				if tick() - lastCaptureVisual[oilRig] >= 1 then
					info.RigName.Visible = not info.RigName.Visible
					lastCaptureVisual[oilRig] = tick()
				end
			end
		else
			-- Nobody is capturing
			captured[oilRig] = 0
			info.RigName.Visible = true
			info.Alpha.Visible = false
			info.Bravo.Visible = false
		end
		
		-- Progress the capturing UI update
		if activeGUI then
			activeGUI.Size = UDim2_new(captured[oilRig]/MAX_CAPTURE_REQUIREMENT, 0, 1, 0)
		end
		
		-- Add to team scores
		if shouldUpateScore and capturedBy[oilRig] then
			local closestEnemy = IS_STUDIO and math.floor(MAX_OIL_TO_WIN/#oilRigs) or math.huge
			local enemyTeam = capturedBy[oilRig] == alpha and bravo or alpha
			for _, v in pairs(enemyTeam:GetPlayers()) do
				local distance = math.floor(v:DistanceFromCharacter(oilRig.PrimaryPart.Position))
				if distance and distance < closestEnemy then
					closestEnemy = distance
				end
			end
			Monopoly.TeamManager:AddTeamScore(capturedBy[oilRig], closestEnemy)
		end
	end
	
	-- Update score timer
	if shouldUpateScore then
		shouldUpateScore = false
		delay(5, function()
			shouldUpateScore = true
		end)
	end
end

function Monopoly:Finalize()
	-- Disconnect all events
	for _, v in pairs(oilRigConnections) do
		v:Disconnect()
	end
	
	-- Cleanup memory
	captured[alpha], captured[bravo] = nil, nil
	oilRigConnections = {}
	captured = {}
	capturedBy = {}
	lastCaptureVisual = {}
	alpha, bravo = nil, nil
	
	-- Make BillboardGuis invisible
	for _, oilRig in pairs(oilRigs) do
		oilRig.PrimaryPart.Info.Enabled = false
		oilRig.PrimaryPart.Info.RigName.BackgroundColor3 = UNCAPTURED_COLOR
	end
end

function Monopoly:IsRoundOver()
	return Monopoly.TeamManager:GetScore(alpha) >= MAX_OIL_TO_WIN or Monopoly.TeamManager:GetScore(bravo) >= MAX_OIL_TO_WIN
end

function Monopoly:GetWinningTeam()
	local alphaPoints, bravoPoints = Monopoly.TeamManager:GetScore(alpha), Monopoly.TeamManager:GetScore(bravo)
	return alphaPoints > bravoPoints and alpha or (bravoPoints > alphaPoints and bravo or nil)
end

return Monopoly
