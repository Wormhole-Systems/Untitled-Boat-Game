-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Constants
local ADS_CAMERA_TWEEN_TIME = 0.25
local CAMERA_FOV_NORMAL = 70
local LAST_SHOT_IDLE_TIME = 1.5
local CAMERA_OFFSET_NORMAL = Vector3.new()
local CAMERA_TWEEN_INFO = TweenInfo.new(ADS_CAMERA_TWEEN_TIME)
local MOUSE_ICON_OG = ""
local MOUSE_ICON_NONE = "rbxassetid://33410686"
local MOUSE_ICON_CROSSHAIR = "rbxassetid://1871997087"

-- Adjusted variables over time
local camera_fov_ads = 50
local camera_offset_ads = Vector3.new(2.75, 0, 5)

-- Character related stuff
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Camera related stuff
local camera = game.Workspace.CurrentCamera
local playerModule = player.PlayerScripts:WaitForChild("PlayerModule")
local cameras = require(playerModule):GetCameras()
local mouseLockController = cameras.activeMouseLockController
local gameHUD = player:WaitForChild("PlayerGui"):WaitForChild("GameHUD")

-- Mobile related variables
local isOnMobile = UserInputService.TouchEnabled
local crosshairMobile = script:WaitForChild("CrosshairMobile")

-- BoolValues
local hasToolOut = player:WaitForChild("HasToolOut")
hasToolOut.Value = false
local ads = player:WaitForChild("ADS")
ads.Value = false
local needsVehicleMouse = player:WaitForChild("NeedsVehicleMouse")
needsVehicleMouse.Value = false
local mouseLockOffsetObj = playerModule.CameraModule.MouseLockController.CameraOffset

-- Keep track of event connections to disconnect whenever the player dies
local connections = {}

---------------------------------------------------------------------------------------------------
--								Equipping/Unequipping Tool										 --
---------------------------------------------------------------------------------------------------

-- Determine whether the player has a tool equipped or not
local function changeEquipStatus(child)
	if child:IsA("Tool") then
		local isToolEquipped = child.Parent == character
		hasToolOut.Value = isToolEquipped
		
		-- Update FOV and Camera Offset values for the new tool
		if isToolEquipped then
			camera_fov_ads = child.Configuration.FOV.Value
			camera_offset_ads = child.Configuration.CameraOffset.Value
		end
		
		-- Turn off ADS and Update Mouse Icon accordingly
		ads.Value = false
		mouse.Icon = isToolEquipped and (ads.Value and MOUSE_ICON_CROSSHAIR or (needsVehicleMouse.Value and MOUSE_ICON_OG or MOUSE_ICON_NONE)) or (needsVehicleMouse.Value and MOUSE_ICON_OG or MOUSE_ICON_NONE)
	end
end

connections[#connections + 1] = character.ChildAdded:Connect(changeEquipStatus)
connections[#connections + 1] = character.ChildRemoved:Connect(changeEquipStatus)
connections[#connections + 1] = needsVehicleMouse.Changed:Connect(function(vehicleMouseNeeded)
	mouse.Icon = hasToolOut.Value and (ads.Value and MOUSE_ICON_CROSSHAIR or (vehicleMouseNeeded and MOUSE_ICON_OG or MOUSE_ICON_NONE)) or (vehicleMouseNeeded and MOUSE_ICON_OG or MOUSE_ICON_NONE)
end)
---------------------------------------------------------------------------------------------------
--									Entering/Exiting ADS										 --
---------------------------------------------------------------------------------------------------

local isInTurret, holdingDownADS = false, false

if not isOnMobile then
	-- When right-cliking while having a gun equipped, go in ADS mode
	local holdingDownADS = false
	connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if hasToolOut.Value and input.UserInputType == Enum.UserInputType.MouseButton2 and not isInTurret then
			ads.Value = true
			holdingDownADS = true
		end
	end)
	
	-- When letting go of right-click, exit ADS mode
	connections[#connections + 1] = UserInputService.InputEnded:Connect(function(input, processed)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 and not isInTurret then
			ads.Value = false
			holdingDownADS = false
			shared.lastShot = nil
		end
	end)
else
	-- Mobile tap to enter ADS connection
	connections[#connections + 1] = UserInputService.TouchTapInWorld:Connect(function(_, processedByUI)
		if processedByUI then return end
		if hasToolOut.Value and not isInTurret then
			shared.lastShot = tick()
			ads.Value = true
		end
	end)
	
	-- A way to stay in ADS when panning the camera around
	--[[
	connections[#connections + 1] = UserInputService.TouchPan:Connect(function(_, _, _, _, processedByUI)
		if processedByUI then return end
		if hasToolOut.Value and ads.Value then
			shared.lastShot = tick()
		end
	end)
	--]]
end

connections[#connections + 1] = humanoid.Seated:Connect(function(active, seatPart)
	isInTurret = active and seatPart and (seatPart.Parent:FindFirstChild("Pivot") or seatPart.Parent:FindFirstChild("Handle"))
	ads.Value = isInTurret
end)

---------------------------------------------------------------------------------------------------
--									Adjusting Camera to ADS										 --
---------------------------------------------------------------------------------------------------

-- Force exits out of ADS mode of the player hasn't been shooting for a while
local function determineLastShotInactivity()
	if shared.lastShot and tick() - shared.lastShot > LAST_SHOT_IDLE_TIME then
		shared.lastShot = nil
		ads.Value = false
	end
end

-- Tweens and connections to cancel/disconnect so that there's no overriding
local fovTween, offsetTween, fovTweenCompletedConn, lastShotConn
connections[#connections + 1] = ads.Changed:Connect(function(isAiming)
	-- Cancel & remove existing tweens
	if fovTween then fovTween:Cancel() fovTween:Destroy() fovTween = nil end
	if offsetTween then offsetTween:Cancel() offsetTween:Destroy() offsetTween = nil end
	if fovTweenCompletedConn then fovTweenCompletedConn:Disconnect() fovTweenCompletedConn = nil end
	if lastShotConn then lastShotConn:Disconnect() lastShotConn = nil end
	if not isAiming and not holdingDownADS then shared.lastShot = nil end
	
	-- Make sure camera is in mouse lock mode before tweening
	if isAiming then
		mouseLockController:SetIsMouseLocked(true)
	end
	
	-- Add mobile crosshair if necessary
	crosshairMobile.Parent = (isOnMobile and isAiming) and gameHUD or script
	
	-- Create and run ADS transition into/out of tweens
	fovTween = TweenService:Create(camera, CAMERA_TWEEN_INFO, {FieldOfView = isAiming and camera_fov_ads or CAMERA_FOV_NORMAL})
	if not isAiming then
		fovTweenCompletedConn = fovTween.Completed:Connect(function()
			mouseLockController:SetIsMouseLocked(false)
		end)
	end
	fovTween:Play()
	if (not humanoid.Sit or not humanoid.SeatPart:IsA("VehicleSeat")) or not isAiming then
		-- don't offset camera if player is in a vehicle driver seat, but at keast get out of ads if requested to
		local camera_offset_ads_final = humanoid:GetState() ~= Enum.HumanoidStateType.Swimming and camera_offset_ads or camera_offset_ads + Vector3.new(0, 2, 0)
		offsetTween = TweenService:Create(mouseLockOffsetObj, CAMERA_TWEEN_INFO, {Value = isAiming and camera_offset_ads_final or CAMERA_OFFSET_NORMAL })
		offsetTween:Play()
	end
	
	-- Change character properties accordingly
	--humanoid.JumpPower = (isAiming and not isInTurret) and 0 or 50
	--humanoid.WalkSpeed = (isAiming and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming) and 6 or 16
	
	-- Update Mouse Icon accordingly
	mouse.Icon = isAiming and MOUSE_ICON_CROSSHAIR or (needsVehicleMouse.Value and MOUSE_ICON_OG or MOUSE_ICON_NONE) --(hasToolOut.Value and MOUSE_ICON_NONE or MOUSE_ICON_OG)
		
	-- Exit out of ADS after a certain amount of inactivity if the player triggered it by shooting
	if isAiming and shared.lastShot then
		lastShotConn = RunService.RenderStepped:Connect(determineLastShotInactivity)
	end
end)

-- Disconnect all connections to prevent memory leaks
connections[#connections + 1] = humanoid.Died:Connect(function()
	--mouse.Icon = MOUSE_ICON_OG -- reset back to original mouse
	hasToolOut.Value = false
	ads.Value = false -- remove from ADS mode if in it
	crosshairMobile:Destroy()
	for _, v in pairs(connections) do
		v:Disconnect()
	end
	connections = {}
	if lastShotConn then lastShotConn:Disconnect() lastShotConn = nil end
end)

-- Start with a normal camera when first spawning
ads.Value = false
mouseLockController:SetIsMouseLocked(false)
mouse.Icon = MOUSE_ICON_NONE
camera.FieldOfView = CAMERA_FOV_NORMAL
mouseLockOffsetObj.Value = CAMERA_OFFSET_NORMAL
player.CameraMinZoomDistance = 10
wait(0.1)
player.CameraMaxZoomDistance = 10

--[[
				LOOK AT ALL THIS UNECESSARILY COMPLICATED MATH I DID BELOW 
					WHEN I COULD'VE JUST DONE WHAT I DID ABOVE
--]]

--[[
-- Constants
local ADS_CHARACTER_TWEEN_TIME = 0.1
local CHARACTER_TWEEN_INFO = TweenInfo.new(ADS_CHARACTER_TWEEN_TIME)

local FRONT_VECTOR = Vector2.new(0, -1)

-- Micro-optimizations
local clamp = math.clamp
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local vectorToWorldSpace = CFrame.new().VectorToWorldSpace
local Vector3_new = Vector3.new
local Vector2_new = Vector2.new
local acos = math.acos
local atan2 = math.atan2
local sqrt = math.sqrt
local rad = math.rad
local deg = math.deg

-- Current character X and Y angles and their mouse sensitivities in ADS
local xAngle, xSensitivity = 0, 0.05
local yAngle, ySensitivity = 0, 0.10

local function mouseMovement(input)
	if input and input.UserInputType == Enum.UserInputType.MouseMovement then
		xAngle = xAngle - input.Delta.x * xSensitivity
		if xAngle <= -360 then xAngle = xAngle + 360 end
		if xAngle >= 360 then xAngle = xAngle - 360 end
		yAngle = clamp(yAngle - input.Delta.y * ySensitivity, -40, 40)
	end
end


local function getCFrameForOffset(offset)
	-- Set rotated start CFrame inside head
	local startCFrame = CFrame_new(humanoidRootPart.CFrame.p + Vector3_new(0, 2, 0)) * CFrame_Angles(0, rad(xAngle), 0) * CFrame_Angles(rad(yAngle), 0, 0)
	
	-- Calculate camera CFrame and Focus
	local cameraCFrame = startCFrame + vectorToWorldSpace(startCFrame, offset)
	local cameraFocus = startCFrame + vectorToWorldSpace(startCFrame, Vector3_new(offset.X, offset.Y, -50000))
	
	-- Set camera CFrame
	return CFrame_new(cameraCFrame.p, cameraFocus.p)
end

local isZooming = false
local hrpTween
local function adsMovement()
	--print("running")
	-- Keep mouse behavior to be locked in the center
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	
	-- Set the new camera CFrame based on the ADS offset
	if not isZooming then
		camera.CFrame = getCFrameForOffset(CAMERA_OFFSET_ADS)
	end
	
	--humanoidRootPart.CFrame = CFrame_new(humanoidRootPart.CFrame.p) * CFrame.fromEulerAnglesXYZ(0, rad(xAngle), 0)
	if hrpTween then hrpTween:Cancel() hrpTween:Destroy() hrpTween = nil end
	hrpTween = TweenService:Create(humanoidRootPart, CHARACTER_TWEEN_INFO, {CFrame = CFrame_new(humanoidRootPart.CFrame.p) * CFrame.fromEulerAnglesXYZ(0, rad(xAngle), 0)})
	hrpTween:Play()
	
	if shared.lastShot and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and tick() - shared.lastShot > 3 then
		ads.Value = false
	end
end

-- Mouse and ADS event connections
local mouseMovementConn, adsMovementConn
ads.Changed:Connect(function(isAiming)
	-- Update x and y angles to where the root part is currently facing	
	local camLookVector = camera.CFrame.LookVector
	local lookVectorXZ = Vector2_new(camLookVector.X, camLookVector.Z).Unit
	local dir = FRONT_VECTOR.X * lookVectorXZ.Y - FRONT_VECTOR.Y * lookVectorXZ.X 
	xAngle = deg(acos(FRONT_VECTOR:Dot(lookVectorXZ))) * (dir < 0 and 1 or (dir > 0 and -1 or 0))
	yAngle = clamp(deg(atan2(camLookVector.Y, sqrt(camLookVector.X^2 + camLookVector.Z^2))), -40, 40)
	
	-- Create zooming effect
	isZooming = true
	camera.CameraType = "Scriptable" -- to allow for zooming in/out
	local adjustFOVTween = TweenService:Create(camera, CAMERA_TWEEN_INFO, {FieldOfView = isAiming and CAMERA_FOV_ADS or CAMERA_FOV_NORMAL})
	local adjustCameraTween = TweenService:Create(camera, CAMERA_TWEEN_INFO, {CFrame = getCFrameForOffset(isAiming and CAMERA_OFFSET_ADS or CAMERA_OFFSET_NORMAL)})
	adjustFOVTween:Play()
	adjustCameraTween:Play()
	
	-- Once the zooming is finished, clear the debounce and bring camera back to normal
	adjustCameraTween.Completed:Connect(function()
		isZooming = false
		adjustFOVTween:Destroy()
		adjustCameraTween:Destroy()
		if not isAiming then
			camera.CameraType = "Custom"
			humanoid.AutoRotate = true
			humanoid.JumpPower = 50
			humanoid.WalkSpeed = 16
			if hrpTween then hrpTween:Cancel() hrpTween:Destroy() hrpTween = nil end
		end
	end)
	
	-- Connect or disconnect mouse and ads movement events based on whether the player is aiming or not
	mouseMovementConn = isAiming and UserInputService.InputChanged:Connect(mouseMovement) or mouseMovementConn:Disconnect()
	adsMovementConn = isAiming and RunService.RenderStepped:Connect(adsMovement) or adsMovementConn:Disconnect()
	
	-- Change character movement values
	if isAiming then
		humanoid.AutoRotate = true
		humanoid.JumpPower = 0
		humanoid.WalkSpeed = 6
	end
end)
--]]