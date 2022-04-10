-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local TWEEN_TIME = 0.25
local ROTATION_LIMIT_WAIST = math.pi/180 * 40
local ROTATION_LIMIT_WAIST_ADS = math.pi/180 * 89
local ROTATION_LIMIT_NECK = math.pi/180 * 10
local ZERO_ANGLE = CFrame.Angles(0, 0, 0)
local ZERO_VECTOR3 = Vector3.new()
local ENUM_SWIMMING = Enum.HumanoidStateType.Swimming
local ENUM_FALLING = Enum.HumanoidStateType.Freefall

-- Micro-Optimizations
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local clamp = math.clamp
local asin = math.asin

-- Player, character, and camera variables
local player = Players.LocalPlayer
local playerName = player.Name
local playerUserId = player.UserId
local ads = player:WaitForChild("ADS")
local camera = game.Workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local characterWaist = character:WaitForChild("UpperTorso"):WaitForChild("Waist")
local characterNeck = character:WaitForChild("Head"):WaitForChild("Neck")
local state, camPitch, camYaw = ENUM_SWIMMING, 0, 0

-- Character tilting event
local characterTilt = ReplicatedStorage:WaitForChild("Invokers"):WaitForChild("CharacterTilt")
local tiltValues = {}
local tweens = {} -- Keep track of the active tweens for each player
local tweenInfo = TweenInfo.new(TWEEN_TIME) -- The type of tween used

-- Inverse kinematics chache values for characters grabbing onto steering wheels/handlebars while driving
local R_SHOULDER_C0_CACHE, R_ELBOW_C0_CACHE, L_SHOULDER_C0_CACHE, L_ELBOW_C0_CACHE = {}, {}, {}, {}
local R_UPPER_LENGTH, R_LOWER_LENGTH, L_UPPER_LENGTH, L_LOWER_LENGTH = {}, {}, {}, {}

local function tiltCharacter(waist, neck, userId, state, velocity, isAiming, pitch, yaw)
	local waistOffset, neckOffset
	if state ~= ENUM_SWIMMING or velocity == 0 or isAiming then
		local rotationLimitWaist = (isAiming and state ~= ENUM_FALLING) and ROTATION_LIMIT_WAIST_ADS or ROTATION_LIMIT_WAIST
		waistOffset = CFrame_Angles(clamp(pitch, -rotationLimitWaist, rotationLimitWaist), clamp(yaw, -ROTATION_LIMIT_WAIST, ROTATION_LIMIT_WAIST), 0)
		neckOffset = CFrame_Angles(clamp(pitch, -ROTATION_LIMIT_NECK, ROTATION_LIMIT_NECK), clamp(yaw, -ROTATION_LIMIT_NECK, ROTATION_LIMIT_NECK), isAiming and -math.pi/180 * 20 or 0)
	else
		waistOffset = ZERO_ANGLE
		neckOffset = ZERO_ANGLE
	end
	
	--[[
	waist.C0 = CFrame_new(waist.C0.p) * waistOffset
	neck.C0 = CFrame_new(neck.C0.p) * neckOffset
	--]]
	
	----[[
	-- Apply the offset to the waist
	local rotateWaistTween = TweenService:Create(waist, tweenInfo, {C0 = CFrame_new(waist.C0.p) * waistOffset})
	local waistKey, neckKey = userId.."Waist", userId.."Neck"
	if tweens[waistKey] then
		tweens[waistKey]:Cancel()
		tweens[waistKey]:Destroy()
		tweens[waistKey] = nil
	end
	tweens[waistKey] = rotateWaistTween
	rotateWaistTween:Play()
	
	-- Applay the offset to the neck
	local rotateNeckTween = TweenService:Create(neck, tweenInfo, {C0 = CFrame_new(neck.C0.p) * neckOffset})
	if tweens[neckKey] then
		tweens[neckKey]:Cancel()
		tweens[neckKey]:Destroy()
		tweens[neckKey] = nil
	end
	tweens[neckKey] = rotateNeckTween
	rotateNeckTween:Play()
	--]]
end

local previousLookVector, previousADSValue, previousHumanoidState = nil
camera:GetPropertyChangedSignal("CFrame"):Connect(function()
	if not humanoidRootPart or not humanoidRootPart.Parent or humanoid.Health <= 0 then return end
	local camCFrame = camera.CFrame
	state = humanoid:GetState()
	if camCFrame.LookVector ~= previousLookVector or ads.Value ~= previousADSValue or state ~= previousHumanoidState then
		previousLookVector = camCFrame.LookVector
		previousADSValue = ads.Value
		previousHumanoidState = state
		
		local direction = (humanoidRootPart.CFrame:inverse() * camCFrame).LookVector
		camPitch, camYaw = asin(direction.Y), -asin(direction.X)
		characterTilt:FireServer(state, humanoid.MoveDirection.Magnitude, ads.Value, camPitch, camYaw)
		tiltCharacter(characterWaist, characterNeck, playerUserId, state, humanoid.MoveDirection.Magnitude, ads.Value, camPitch, camYaw)
	end
end)

-- Update the rotation of all other players' characters
characterTilt.OnClientEvent:Connect(function(v, state, velocity, isAiming, pitch, yaw, r_shoulder, r_elbow, l_shoulder, l_elblow)
	if v ~= player then
		if v.Character and v.Character.Parent then
			local vWaist = v.Character:FindFirstChild("UpperTorso") and v.Character.UpperTorso:FindFirstChild("Waist")
			local vNeck = v.Character:FindFirstChild("Head") and v.Character.Head:FindFirstChild("Neck")
			if vWaist and vNeck then
				tiltCharacter(vWaist, vNeck, v.UserId, state, velocity, isAiming, pitch, yaw)
			end
			if r_shoulder and r_elbow and l_shoulder and l_elblow then
				
			end
		end
	end
end)

--[[
RunService.Stepped:Connect(function()
	-- Update other characters' rotations
	local players = Players:GetPlayers()
	for i = 1, #players do
		local v = players[i]
		if v ~= player then
			local tiltVal = tiltValues[v.Name]
			if tiltVal and v.Character and v.Character.Parent then
				local vWaist = v.Character:FindFirstChild("UpperTorso") and v.Character.UpperTorso:FindFirstChild("Waist")
				local vNeck = v.Character:FindFirstChild("Head") and v.Character.Head:FindFirstChild("Neck")
				if vWaist and vNeck then
					tiltCharacter(vWaist, vNeck, v.UserId, tiltVal[1], tiltVal[2], tiltVal[3], tiltVal[4], tiltVal[5])
				end
			end
		end
	end
	
	-- Update local character's rotations
	if characterWaist and characterWaist.Parent and characterNeck and characterNeck.Parent then
		tiltCharacter(characterWaist, characterNeck, state, humanoid.MoveDirection.Magnitude, ads.Value, camPitch, camYaw)
	end
end)
--]]

player.CharacterAdded:Connect(function(newCharacter)
	humanoid = newCharacter:WaitForChild("Humanoid")
	humanoidRootPart = newCharacter:WaitForChild("HumanoidRootPart")
	characterWaist = newCharacter:WaitForChild("UpperTorso"):WaitForChild("Waist")
	characterNeck = newCharacter:WaitForChild("Head"):WaitForChild("Neck")
end)

Players.PlayerRemoving:Connect(function(playerRemoving)
	local waistKey, neckKey = playerRemoving.UserId.."Waist", playerRemoving.UserId.."Neck"
	if tweens[waistKey] then
		tweens[waistKey]:Cancel()
		tweens[waistKey]:Destroy()
		tweens[waistKey] = nil
	end
	if tweens[neckKey] then
		tweens[neckKey]:Cancel()
		tweens[neckKey]:Destroy()
		tweens[neckKey] = nil
	end
	if R_SHOULDER_C0_CACHE[playerRemoving.UserId] then
		R_SHOULDER_C0_CACHE[playerRemoving.UserId] = nil
		R_ELBOW_C0_CACHE[playerRemoving.UserId] = nil
		L_SHOULDER_C0_CACHE[playerRemoving.UserId] = nil
		L_ELBOW_C0_CACHE[playerRemoving.UserId] = nil
		R_UPPER_LENGTH[playerRemoving.UserId] = nil
		R_LOWER_LENGTH[playerRemoving.UserId] = nil
		L_UPPER_LENGTH[playerRemoving.UserId] = nil
		L_LOWER_LENGTH[playerRemoving.UserId] = nil
	end
end)
------------------------------------------------------------------------------------------------------------------
--										HANDS ON STEERING WHEELS/HANDLEBARS										--
------------------------------------------------------------------------------------------------------------------

-- Shoutout to LMH_Hutch for this Inverse Kinematic logic
-- Retrieved from: https://devforum.roblox.com/t/2-joint-2-limb-inverse-kinematics/252399
local function solveIK(originCF, targetPos, l1, l2)	
	-- build intial values for solving
	local localized = originCF:pointToObjectSpace(targetPos)
	local localizedUnit = localized.unit
	local l3 = localized.magnitude
	
	-- build a "rolled" planeCF for a more natural arm look
	local axis = Vector3.new(0, 0, -1):Cross(localizedUnit)
	local angle = math.acos(-localizedUnit.Z)
	local planeCF = originCF * CFrame.fromAxisAngle(axis, angle)
	
	-- case: point is to close, unreachable
	-- action: push back planeCF so the "hand" still reaches, angles fully compressed
	if l3 < math.max(l2, l1) - math.min(l2, l1) then
		return planeCF * CFrame.new(0, 0,  math.max(l2, l1) - math.min(l2, l1) - l3), -math.pi/2, math.pi
		
	-- case: point is to far, unreachable
	-- action: for forward planeCF so the "hand" still reaches, angles fully extended
	elseif l3 > l1 + l2 then
		return planeCF * CFrame.new(0, 0, l1 + l2 - l3), math.pi/2, 0
		
	-- case: point is reachable
	-- action: planeCF is fine, solve the angles of the triangle
	else
		local a1 = -math.acos((-(l2 * l2) + (l1 * l1) + (l3 * l3)) / (2 * l1 * l3))
		local a2 = math.acos(((l2  * l2) - (l1 * l1) + (l3 * l3)) / (2 * l2 * l3))

		return planeCF, a1 + math.pi/2, a2 - a1
	end
end	

RunService.Stepped:Connect(function()
	local players = Players:GetPlayers()
	for i = 1, #players do
		if players[i].Character and players[i].Character:FindFirstChildOfClass("Humanoid") and players[i].Character.Humanoid.SeatPart
		   and players[i].Character.Humanoid.SeatPart:FindFirstChild("LeftHand") and players[i].Character.Humanoid.SeatPart:FindFirstChild("RightHand") then
			local id = players[i].UserId
			local character = players[i].Character
			local upperTorso = character["UpperTorso"]
			local rightShoulder = character["RightUpperArm"]["RightShoulder"]
			local rightElbow = character["RightLowerArm"]["RightElbow"]
			local leftShoulder = character["LeftUpperArm"]["LeftShoulder"]
			local leftElbow	= character["LeftLowerArm"]["LeftElbow"]
			
			if not R_SHOULDER_C0_CACHE[id] then
				local rightWrist = character["RightHand"]["RightWrist"]
				local leftWrist = character["LeftHand"]["LeftWrist"]
				
				R_SHOULDER_C0_CACHE[id] = rightShoulder.C0
				R_ELBOW_C0_CACHE[id] = rightElbow.C0
				L_SHOULDER_C0_CACHE[id] = leftShoulder.C0
				L_ELBOW_C0_CACHE[id] = leftElbow.C0
				R_UPPER_LENGTH[id] = math.abs(rightShoulder.C1.Y) + math.abs(rightElbow.C0.Y)
				R_LOWER_LENGTH[id] = math.abs(rightElbow.C1.Y) + math.abs(rightWrist.C0.Y) + math.abs(rightWrist.C1.Y)
				L_UPPER_LENGTH[id] = math.abs(leftShoulder.C1.Y) + math.abs(leftElbow.C0.Y)
				L_LOWER_LENGTH[id] = math.abs(leftElbow.C1.Y) + math.abs(leftWrist.C0.Y) + math.abs(leftWrist.C1.Y)
			end
						
			local shoulderCFrame = upperTorso.CFrame * R_SHOULDER_C0_CACHE[id]
			local goalPosition = players[i].Character.Humanoid.SeatPart.RightHand.WorldPosition
			local planeCF, shoulderAngle, elbowAngle = solveIK(shoulderCFrame, goalPosition, R_UPPER_LENGTH[id], R_LOWER_LENGTH[id])
			
			rightShoulder.Transform = rightShoulder.C0:inverse() * upperTorso.CFrame:toObjectSpace(planeCF) * CFrame_Angles(shoulderAngle, 0, 0)
			rightElbow.Transform = rightElbow.C0:inverse() * R_ELBOW_C0_CACHE[id] * CFrame_Angles(elbowAngle, 0, 0)
			
			shoulderCFrame = upperTorso.CFrame * L_SHOULDER_C0_CACHE[id]
			goalPosition = players[i].Character.Humanoid.SeatPart.LeftHand.WorldPosition
			planeCF, shoulderAngle, elbowAngle = solveIK(shoulderCFrame, goalPosition, L_UPPER_LENGTH[id], L_LOWER_LENGTH[id])
			
			leftShoulder.Transform = leftShoulder.C0:inverse() * upperTorso.CFrame:toObjectSpace(planeCF) * CFrame_Angles(shoulderAngle, 0, 0)
			leftElbow.Transform = leftElbow.C0:inverse() * L_ELBOW_C0_CACHE[id] * CFrame_Angles(elbowAngle, 0, 0)
		end
	end
end)