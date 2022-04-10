
local ContextAction = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local humanoid
local camera = game.Workspace.CurrentCamera
local fireWeaponClient = require(player.PlayerScripts.Framework.FireWeaponClientModule)

local grenadeModel = ReplicatedStorage.Assets.Projectiles.Thrown.Grenade
local throwAnim = ReplicatedStorage.Assets.Animations.Weapon.Thrown.Grenade.Throw
local onMobile = game:GetService("UserInputService").TouchEnabled
local throwGrenadeMobileConn

local function throwThrown(weapon, dir)
	fireWeaponClient.FireWeaponLocal(player, weapon, dir, tick() * 10000)
end

local function throwAction(_, inputState, _)
	if inputState == Enum.UserInputState.Begin and humanoid and not humanoid.Sit then
		local thrownItem = player.Backpack:FindFirstChild("Thrown")
		if thrownItem then
			throwThrown(thrownItem, camera.CFrame)
		end
	end
end

ReplicatedStorage.Invokers.ThrowGrenade.OnClientInvoke = function(grenade)
	-- Play grenade throwing animation
	local throwAnimTrack = humanoid:LoadAnimation(throwAnim)
	throwAnimTrack:Play()
	throwAnimTrack:AdjustSpeed(1)
	
	-- Wait for the signal from the animation that the grenade can be let go of
	throwAnimTrack.Stopped:Wait()
	
	grenade.Pin:Destroy()
	grenade.Body.CanCollide = true
	
	return -grenade.Body.CFrame.LookVector
end

player.CharacterAdded:Connect(function (char)
	ContextAction:BindAction("Throw Weapon", throwAction, false, Enum.KeyCode.G)
	
	if onMobile and not throwGrenadeMobileConn then
		throwGrenadeMobileConn = player.PlayerGui:WaitForChild("GameHUD"):WaitForChild("ThrownStatus"):WaitForChild("ClickableButton").MouseButton1Click:Connect(function()
			throwAction(nil, Enum.UserInputState.Begin)
		end)
	end
	
	
	humanoid = char:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		ContextAction:UnbindAction("Throw Weapon")
	end)
end)