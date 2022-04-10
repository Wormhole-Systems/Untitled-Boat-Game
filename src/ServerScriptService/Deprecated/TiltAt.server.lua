-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

-- Constants
local TWEEN_TIME = 0.25
local ROTATION_LIMIT_WAIST = math.pi/180 * 40
local ROTATION_LIMIT_WAIST_ADS = math.pi/180 * 89
local ROTATION_LIMIT_NECK = math.pi/180 * 10
local ZERO_ANGLE = CFrame.Angles(0, 0, 0)
local ZERO_VECTOR3 = Vector3.new()

-- Micro-optimizations
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local toObjectSpace = CFrame_new().ToObjectSpace
local asin = math.asin
local clamp = math.clamp
local Vector2_new = Vector2.new
local clamp = math.clamp
local acos = math.acos
local atan2 = math.atan2
local sqrt = math.sqrt

-- Enums
local enumSwimming = Enum.HumanoidStateType.Swimming
local enumFalling = Enum.HumanoidStateType.Freefall

-- Reference model values to make derive rotation off of
local reference = ServerStorage.Models.R15
local originalWaistCFrame, originalNeckCFrame = reference.UpperTorso.Waist.C0, reference.Head.Neck.C0

-- Keep track of the active tweens for each player
local tweens = {}

-- The type of tween used
local tweenInfo = TweenInfo.new(TWEEN_TIME)

ReplicatedStorage.Invokers.TiltAt.OnServerEvent:Connect(function(player, direction, isAiming)
	-- Find player's character
	local character = player.Character
	if character and character.Parent ~= nil then
		-- Find humanoid and waist joint
		local humanoid = character:FindFirstChild("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local upperTorso = character:WaitForChild("UpperTorso")
		local waist = upperTorso and upperTorso:FindFirstChild("Waist")
		local neck = character:FindFirstChild("Head") and character["Head"]:FindFirstChild("Neck")
		
		if humanoid and humanoid.Health > 0 and hrp and waist and neck then
			-- Calculate the offsets
			local waistOffset, neckOffset
			local humState = humanoid:GetState()
			if isAiming or humState ~= enumSwimming or humanoid.MoveDirection == ZERO_VECTOR3 then
				local rotationLimitWaist = (isAiming and humState ~= enumFalling) and ROTATION_LIMIT_WAIST_ADS or ROTATION_LIMIT_WAIST
				waistOffset = CFrame_Angles(0, clamp(-asin(direction.X), -ROTATION_LIMIT_WAIST, ROTATION_LIMIT_WAIST), 0) * CFrame_Angles(clamp(asin(direction.Y), -rotationLimitWaist, rotationLimitWaist), 0, 0)
				neckOffset = CFrame_Angles(0, clamp(-asin(direction.X), -ROTATION_LIMIT_NECK, ROTATION_LIMIT_NECK), isAiming and -math.pi/180 * 20 or 0) * CFrame_Angles(clamp(asin(direction.Y), -ROTATION_LIMIT_NECK, ROTATION_LIMIT_NECK), 0, 0)
			else
				waistOffset = ZERO_ANGLE
				neckOffset = ZERO_ANGLE
			end
			
			-- Apply the offset to the waist
			local rotateWaistTween = TweenService:Create(waist, tweenInfo, {C0 = CFrame_new(waist.C0.p) * waistOffset})
			if tweens[player.UserId.."Waist"] then
				tweens[player.UserId.."Waist"]:Cancel()
				tweens[player.UserId.."Waist"]:Destroy()
				tweens[player.UserId.."Waist"] = nil
			end
			tweens[player.UserId.."Waist"] = rotateWaistTween
			rotateWaistTween:Play()
			
			-- Applay the offset to the neck
			local rotateNeckTween = TweenService:Create(neck, tweenInfo, {C0 = CFrame_new(neck.C0.p) * neckOffset})
			if tweens[player.UserId.."Neck"] then
				tweens[player.UserId.."Neck"]:Cancel()
				tweens[player.UserId.."Neck"]:Destroy()
				tweens[player.UserId.."Neck"] = nil
			end
			tweens[player.UserId.."Neck"] = rotateNeckTween
			rotateNeckTween:Play()
		end
		--[[
		if humanoid and humanoid.Health > 0 and waist and neck then
			if humanoid:GetState() ~= Enum.HumanoidStateType.Swimming then
				-- Vector to compare the camera's LookVector with
				local hrpLookVector = character.HumanoidRootPart.CFrame.LookVector
				local dot, y, lookingForward = tiltAt:Dot(hrpLookVector), atan2(tiltAt.Y, sqrt(tiltAt.X^2 + tiltAt.Z^2)), 1
				y = clamp(y, -ROTATION_LIMIT, ROTATION_LIMIT)
				if dot < 0 then
					lookingForward = -1
					tiltAt = -tiltAt
					dot = tiltAt:Dot(hrpLookVector)
				end
				
				-- Determine direction
				local direction = (tiltAt.Z * hrpLookVector.X) - (tiltAt.X * hrpLookVector.Z)
				local dir = (direction > 0 and 1 or (direction < 0 and -1 or 0)) * lookingForward
				
				-- Determine angle
				local angle = acos(Vector2_new(tiltAt.X, tiltAt.Z).Unit:Dot(Vector2_new(hrpLookVector.X, hrpLookVector.Z).Unit))
				angle = clamp(angle, 0, ROTATION_LIMIT)
				
				-- Create the offset
				local offset = CFrame_Angles(y,- angle * dir, 0)
				
				-- Apply the offset to the waist
				local rotateWaistTween = TweenService:Create(waist, tweenInfo, {C` = originalWaistCFrame * offset - Vector3.new(0, character.LowerTorso.Size.Z/2, 0)})
				if tweens[player.UserId.."Waist"] then
					tweens[player.UserId.."Waist"]:Destroy()
				end
				tweens[player.UserId] = rotateWaistTween
				rotateWaistTween:Play()
				
				-- Applay the offset to the neck
				local rotateNeckTween = TweenService:Create(neck, tweenInfo, {C1 = originalNeckCFame * offset})
				if tweens[player.UserId.."Neck"] then
					tweens[player.UserId.."Neck"]:Destroy()
				end
				tweens[player.UserId.."Neck"] = rotateNeckTween
				rotateNeckTween:Play()
			else
				waist.C1 = originalWaistCFrame
				neck.C1 = originalNeckCFrame
			end
			
		end
		--]]
	end
end)