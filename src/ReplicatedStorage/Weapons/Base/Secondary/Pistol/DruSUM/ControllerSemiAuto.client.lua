local CollectionService = game:GetService("CollectionService")
local ContextAction = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

--local TEST_MODE = true

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local invokers = ReplicatedStorage.Invokers.Weapon

local fireEvent = invokers.FireWeapon
local reloadEvent = invokers.ReloadWeapon

local equipped = false
local tool = script.Parent
local config = tool:WaitForChild("Configuration")
local reloading = config.Reloading
local player = game:GetService("Players").LocalPlayer
local camera = game.Workspace.CurrentCamera
local character = player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local hasToolOut = player:WaitForChild("HasToolOut")
local ads = player:WaitForChild("ADS")
local magState = config.MagStateClient

local module = require(config.Module.Value)

-- Animations
local assets = ReplicatedStorage.Assets
local animFolder = assets.Animations.Weapon.Firearm
--local anims = animFolder:FindFirstChild("Pistol")
local anims = animFolder:FindFirstChild(tool.Name)
if not anims then
	anims = animFolder:FindFirstChild(script.Parent.Configuration.Module.Value.Parent.Name == "Pistol" and "Pistol" or "Assault")
end

local equipADSAnim = humanoid:LoadAnimation(anims.EquipADS)
local equipIdleAnim = humanoid:LoadAnimation(anims.EquipIdle)
local fireAnim = humanoid:LoadAnimation(anims.Fire)
local reloadAnim = humanoid:LoadAnimation(anims.Reload)
local animations = {equipADSAnim, equipIdleAnim, fireAnim, reloadAnim}

local fireModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Framework.FireWeaponClientModule)

local function playAnimation(anim) -- send nothing to stop all animations
	for _, a in pairs(animations) do
		if a ~= anim then
			a:Stop()
		end
	end
	if anim then anim:Play() end
end


local function firePrimary(actionName, inputState, inputObj)
	if (inputState == Enum.UserInputState.Begin) then
		if not ads.Value then 
			shared.lastShot = tick()
			ads.Value = true
			return
		end
		shared.lastShot = tick()
		--[[
		local u = camera.CFrame.LookVector
		local v = (hrp.Position + humanoid.CameraOffset) - camera.CFrame.p
		local rayOrigin = camera.CFrame.p + (u:Dot(v)/(u.Magnitude^2)) * u
		local camRay = Ray.new(rayOrigin, u * 10000)
		local part, spot, norm = game.Workspace:FindPartOnRayWithIgnoreList(camRay, CollectionService:GetTagged("ProjectileIgnore"), false, true)
		]]
		--print("Barrel position on client:", barrelEnd.WorldPosition)
		
		local activeAnim = magState.Value == 0 and reloadAnim or fireAnim
		local magStateBeforeFiring
		if activeAnim == reloadAnim then
		else
			magStateBeforeFiring = magState.Value
		end
		
		
		fireModule.FireWeaponLocal(player, tool, camera.CFrame, tick()* 10000)
		
		
		if activeAnim ~= reloadAnim and magState.Value ~= magStateBeforeFiring then
			playAnimation(activeAnim)
		end
		activeAnim.Stopped:Wait()
		if equipped then
			playAnimation(ads.Value and equipADSAnim or equipIdleAnim)
		end
		
	end
end

local function reload(actionName, inputState, inputObj)
	if (inputState == Enum.UserInputState.Begin) then
		reloadEvent:FireServer(tool)
		
		if magState.Value < module.MagazineSize then
			playAnimation(reloadAnim)
			reloadAnim.Stopped:Wait()
			if equipped then
				playAnimation(ads.Value and equipADSAnim or equipIdleAnim)
			end
		end
	end
end

--make the firing connection when equipping the gun
local mobileButtonTapConn
tool.Equipped:Connect(function (mouse)
	--tracks = module:Initialize(humanoid)
	equipped = true
	playAnimation(ads.Value and equipADSAnim or equipIdleAnim)
	
	ContextAction:BindAction("ShootPrimary", firePrimary, false, Enum.UserInputType.MouseButton1)
	ContextAction:BindAction("Reload", reload, false, Enum.KeyCode.R)
	if UserInputService.TouchEnabled then
		mobileButtonTapConn = UserInputService.TouchTapInWorld:Connect(function(_, processed)
			if processed or not ads.Value then return end
			firePrimary(nil, Enum.UserInputState.Begin)
		end)
	end
end)

tool.Unequipped:Connect(function()
	equipped = false
	playAnimation() -- stop all animations
	
	ContextAction:UnbindAction("ShootPrimary")
	ContextAction:UnbindAction("Reload")
	if mobileButtonTapConn then
		mobileButtonTapConn:Disconnect()
		mobileButtonTapConn = nil
	end
	
	-- Fix issue where default equip animation is playing sometimes when unequipping
	for _, v in pairs(humanoid:GetPlayingAnimationTracks()) do
		if v.Name == "ToolNoneAnim" then
			v:Stop()
			v:Destroy()
		end
	end
end)

local adsChangedConn = ads.Changed:Connect(function(isAiming)
	
	if not equipped then playAnimation()  return end
	if isAiming then
		if reloadAnim.IsPlaying then
			reloadAnim.Stopped:Wait()
			if not ads.Value then return end
		end
		playAnimation(equipADSAnim)
	else
		if hasToolOut.Value then
			if reloadAnim.IsPlaying then
				reloadAnim.Stopped:Wait()
				if ads.Value then return end
			end
			playAnimation(equipIdleAnim)
		end
	end
	
end)

-- Clean up to prevent memory leaks
local diedConn; diedConn = humanoid.Died:Connect(function()
	adsChangedConn:Disconnect()
	diedConn:Disconnect()
end)
