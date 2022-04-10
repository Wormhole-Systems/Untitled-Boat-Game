local CollectionService = game:GetService("CollectionService")
local ContextAction = game:GetService("ContextActionService")

--local TEST_MODE = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local invokers = ReplicatedStorage.Invokers.Weapon

local fireEvent = invokers.FireWeapon
local reloadEvent = invokers.ReloadWeapon

local equipped = false
local tool = script.Parent
local config = tool:WaitForChild("Configuration")
local reloading = config.Reloading
local barrelEnd = tool:WaitForChild("Barrel").BarrelEnd
local player = game:GetService("Players").LocalPlayer
local camera = game.Workspace.CurrentCamera
local humanoid = player.Character:WaitForChild("Humanoid")
local hrp = player.Character:WaitForChild("HumanoidRootPart")
local hasToolOut = player:WaitForChild("HasToolOut")
local ads = player:WaitForChild("ADS")
local magState = config.MagState

-- Animations
local equipADSAnim = humanoid:LoadAnimation(script:WaitForChild("EquipADS"))
local equipIdleAnim = humanoid:LoadAnimation(script:WaitForChild("EquipIdle"))
local fireAnim = humanoid:LoadAnimation(script:WaitForChild("Fire"))
local reloadAnim = humanoid:LoadAnimation(script:WaitForChild("Reload"))
local animations = {equipADSAnim, equipIdleAnim, fireAnim, reloadAnim}

local fireModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Framework.FireWeaponClientModule)

local function playAnimaition(anim, keepAnim) -- send nothing to stop all animations
	for _, a in pairs(animations) do
		if a ~= anim and a ~= keepAnim then
			a:Stop()
		end
	end
	if anim then anim:Play() end
end

local connections = {}

local function firePrimary(actionName, inputState, inputObj)
	if (inputState == Enum.UserInputState.Begin) then
		if not ads.Value then 
			shared.lastShot = tick()
			ads.Value = true
			return
		end
		shared.lastShot = tick()
		
		local u = camera.CFrame.LookVector
		local v = (hrp.Position + humanoid.CameraOffset) - camera.CFrame.p
		local rayOrigin = camera.CFrame.p + (u:Dot(v)/(u.Magnitude^2)) * u
		local camRay = Ray.new(rayOrigin, u * 10000)
		local part, spot, norm = game.Workspace:FindPartOnRayWithIgnoreList(camRay, CollectionService:GetTagged("ProjectileIgnore"), false, true)
		--print("Barrel position on client:", barrelEnd.WorldPosition)
		
		local activeAnim = magState.Value == 0 and reloadAnim or fireAnim
		local magStateBeforeFiring
		if activeAnim == reloadAnim then
			playAnimaition(activeAnim)
		else
			magStateBeforeFiring = magState.Value
		end
		
		fireModule.FireWeaponLocal(player, spot, tick())
		
		if activeAnim ~= reloadAnim and magState.Value ~= magStateBeforeFiring then
			playAnimaition(activeAnim)
		end
		activeAnim.Stopped:Wait()
		if equipped then
			playAnimaition(ads.Value and equipADSAnim or equipIdleAnim)
		end
	end
end

local function reload(actionName, inputState, inputObj)
	if (inputState == Enum.UserInputState.Begin) then
		reloadEvent:FireServer(tool)
		playAnimaition(reloadAnim)
		reloadAnim.Stopped:Wait()
		if equipped then
			playAnimaition(ads.Value and equipADSAnim or equipIdleAnim)
		end
	end
end

--make the firing connection when equipping the gun
tool.Equipped:Connect(function (mouse)
	equipped = true
	playAnimaition(ads.Value and equipADSAnim or equipIdleAnim)
	
	ContextAction:BindAction("ShootPrimary", firePrimary, true, Enum.UserInputType.MouseButton1)
	ContextAction:BindAction("Reload", reload, true, Enum.KeyCode.R)
end)

tool.Unequipped:Connect(function()
	equipped = false
	playAnimaition() -- stop all animations
	
	ContextAction:UnbindAction("ShootPrimary")
	ContextAction:UnbindAction("Reload")
end)

local adsChangedConn = ads.Changed:Connect(function(isAiming)
	if not equipped then return end
	if isAiming then
		if reloadAnim.IsPlaying then
			reloadAnim.Stopped:Wait()
			if not ads.Value then return end
		end
		playAnimaition(equipADSAnim)
	else
		if hasToolOut.Value then
			if reloadAnim.IsPlaying then
				reloadAnim.Stopped:Wait()
				if ads.Value then return end
			end
			playAnimaition(equipIdleAnim)
		end
	end
end)

-- Clean up to prevent memory leaks
local diedConn; diedConn = humanoid.Died:Connect(function()
	adsChangedConn:Disconnect()
	diedConn:Disconnect()
end)
