local CollectionService = game:GetService("CollectionService")
local ContextAction = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--local TEST_MODE = true

local invokers = ReplicatedStorage.Invokers.Weapon

local fireEvent = invokers.FireWeapon
local reloadEvent = invokers.ReloadWeapon

local equipped = false
local tool = script.Parent
local config = tool:WaitForChild("Configuration")
local reloading = config.Reloading
local player = game:GetService("Players").LocalPlayer
local character = (player.Character and player.Character.Parent ~= nil and player.Character) or player.CharacterAdded:Wait()
local camera = game.Workspace.CurrentCamera
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local hasToolOut = player:WaitForChild("HasToolOut")
local ads = player:WaitForChild("ADS")
local magState = config.MagStateClient
local module = require(config.Module.Value)

-- Animations
local assets = ReplicatedStorage.Assets
local animFolder = assets.Animations.Weapon.Firearm
--local anims = animFolder:FindFirstChild("Shotgun")
local anims = animFolder:FindFirstChild(tool.Name)
if not anims then
	anims = animFolder:FindFirstChild("Shotgun")
end

local equipADSAnim = humanoid:LoadAnimation(anims.EquipADS)
local equipIdleAnim = humanoid:LoadAnimation(anims.EquipIdle)
local fireAnim = humanoid:LoadAnimation(anims["Fire"][script.Parent.Name])
local reloadAnim1 = humanoid:LoadAnimation(anims.Reload1)
local reloadAnim2 = humanoid:LoadAnimation(anims.Reload2)
local reloadAnim3 = humanoid:LoadAnimation(anims["Reload3"][script.Parent.Name])
local animations = {equipADSAnim, equipIdleAnim, fireAnim, reloadAnim1, reloadAnim2, reloadAnim3}

local fireModule = require(game:GetService("Players").LocalPlayer.PlayerScripts.Framework.FireWeaponClientModule)
local function playAnimation(anim) -- send nothing to stop all animations
	for _, a in pairs(animations) do
		if a ~= anim then
			a:Stop()
		end
	end
	if anim then anim:Play() end
end

local function playReloadAnimations()
	playAnimation(reloadAnim1)
	reloadAnim1.Stopped:Wait()
	playAnimation(reloadAnim2)
	repeat
		wait()
	until
		not equipped or magState.Value == module.MagazineSize
	if equipped then
		playAnimation(reloadAnim3)
		reloadAnim3.Stopped:Wait()
		playAnimation(ads.Value and equipADSAnim or equipIdleAnim)
	end
end

local connections = {}

local function firePrimary(actionName, inputState, inputObj)
	if (inputState == Enum.UserInputState.Begin) then
		if not ads.Value then 
			shared.lastShot = tick()
			ads.Value = true
			return
		end
		--[[
		local u = camera.CFrame.LookVector
		local v = (hrp.Position + humanoid.CameraOffset) - camera.CFrame.p
		local rayOrigin = camera.CFrame.p + (u:Dot(v)/(u.Magnitude^2)) * u
		local camRay = Ray.new(rayOrigin, u * 10000)
		local part, spot, norm = game.Workspace:FindPartOnRayWithIgnoreList(camRay, CollectionService:GetTagged("ProjectileIgnore"), false, true)
		]]
		--print("Barrel position on client:", barrelEnd.WorldPosition)
		
		shared.lastShot = tick()
	
		--print("Barrel position on client:", barrelEnd.WorldPosition)
		local tock = tick() * 10000
		
		local activeAnim = magState.Value == 0 and reloadAnim1 or fireAnim
		local magStateBeforeFiring
		
		if activeAnim == reloadAnim1 then
			spawn(function() playReloadAnimations() end)
		else
	 		magStateBeforeFiring = magState.Value
		end
		
		fireModule.FireWeaponLocal(player, tool, camera.CFrame, tick() * 10000)
		
		if activeAnim ~= reloadAnim1 and magState.Value ~= magStateBeforeFiring then
			playAnimation(activeAnim)
			activeAnim.Stopped:Wait()
			if equipped then
				playAnimation(ads.Value and equipADSAnim or equipIdleAnim)
			end
		end
	
	end
end

local function reload(actionName, inputState, inputObj)
	if (inputState == Enum.UserInputState.Begin) then
		reloadEvent:FireServer(tool)
		
		if magState.Value < module.MagazineSize then
			playReloadAnimations()
		end
		-- Incrementally changing approach
		--[[
		local magStateChanged; magStateChanged = magState.Changed:Connect(function(count)
			if equipped then
				if count < module.MagazineSize then
					playAnimation(reloadAnim2)
				else
					playAnimation(reloadAnim3)
					reloadAnim3.Stopped:Wait()
					if equipped then
						playAnimation(ads.Value and equipADSAnim or equipIdleAnim)
					end
				end
			else
				magStateChanged:Disconnect()
			end
		end)
		magStateChanged:Disconnect()
		--]]
		
	end
end

--make the firing connection when equipping the gun
local mobileButtonTapConn
tool.Equipped:Connect(function (mouse)
	--tracks = module:Initialize(humanoid)
	equipped = true
	
	-- Apply weld
	if tool.Handle:FindFirstChildOfClass("Motor6D") then
		local pumpGrip = tool.Handle:FindFirstChildOfClass("Motor6D")
		pumpGrip.Part0 = tool.Handle
		pumpGrip.Part1 = tool.Pump
		pumpGrip.Parent = tool.Handle
	end
	
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
	
	if not equipped then playAnimation() return end
	if isAiming then
		if reloadAnim1.IsPlaying then
			reloadAnim1.Stopped:Wait()
			if not ads.Value then return end
		end
		if reloadAnim2.IsPlaying then
			reloadAnim2.Stopped:Wait()
			if not ads.Value then return end
		end
		if reloadAnim3.IsPlaying then
			reloadAnim3.Stopped:Wait()
			if not ads.Value then return end
		end
		playAnimation(equipADSAnim)
	else
		if hasToolOut.Value then
			if reloadAnim1.IsPlaying then
				reloadAnim1.Stopped:Wait()
				if ads.Value then return end
			end
			if reloadAnim2.IsPlaying then
				reloadAnim2.Stopped:Wait()
				if ads.Value then return end
			end
			if reloadAnim3.IsPlaying then
				reloadAnim3.Stopped:Wait()
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
