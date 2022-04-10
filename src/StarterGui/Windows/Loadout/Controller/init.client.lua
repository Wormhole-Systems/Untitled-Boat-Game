local player = game.Players.LocalPlayer

-- Roblox Services
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Market = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Game Services
local tools = require(ReplicatedFirst.GameTools)
local Gui3D = require(script:WaitForChild("3DGui"))

local invokers = ReplicatedStorage.Invokers.Loadout
local setLoadoutFunc = invokers.SetLoadout
local setAppearanceEvent = invokers.SetAppearance


local blur = Lighting.Blur

local weapons = ReplicatedStorage.Weapons

local HUD = player.PlayerGui.GameHUD

local runAnim = script:WaitForChild("RunAnim")
local animationsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Animations"):WaitForChild("Weapon"):WaitForChild("Firearm")
local assaultAnims, shotgunAnims, pistolAnims = animationsFolder:FindFirstChild("Assault", true), 
								  				animationsFolder:FindFirstChild("Shotgun", true), 
								 				animationsFolder:FindFirstChild("Pistol", true)
local currentWeapon, currentPose

local frame = script.Parent
local nameLabel = frame.NameLabel
local weaponList = frame.WeaponList
local charView = frame.CharacterDisplay
local loadoutList = frame.LoadoutList
local weaponButton = script.WeaponButton
local classDropdown = script.ClassDropdown
local charViewAnimated = nil

local loadoutButton = frame.Parent.LoadoutButton

local easingStyle = Enum.EasingStyle.Quart
local tweenTime = .3

local loadout = player.Loadout

--points to which slot is currently using the weaponslist, or nil if not at all
local activeButton

nameLabel.Text = player.Name

local tweenInProgress = false

--opens the weapon catalogue bar
local function openWeaponList()
	tweenInProgress = true
	weaponList.Visible = true
	weaponList:TweenSize(UDim2.new(0.333, -20, 1, -30), Enum.EasingDirection.Out, easingStyle, tweenTime, false, nil)
	charView:TweenSizeAndPosition(UDim2.new(0.333, -20, 1, -30), UDim2.new(0.667, 4, 0, 15), Enum.EasingDirection.Out, easingStyle, tweenTime, false, 
		function()
			tweenInProgress = false
		end)
end

--collapses the weapon catalogue bar
local function closeWeaponList()
	tweenInProgress = true
	weaponList:TweenSize(UDim2.new(0, 0, 1, -30), Enum.EasingDirection.In, easingStyle, tweenTime, false, function ()
		weaponList.Visible = false
	end)
	charView:TweenSizeAndPosition(UDim2.new(0.666, -25, 1, -30), UDim2.new(0.333, 10, 0, 15), Enum.EasingDirection.In, easingStyle, tweenTime, false,
		function ()
			for _, v in pairs (weaponList:GetChildren()) do
				if v:IsA("Frame") then
					v:Destroy()
				end
			end	
			activeButton = nil
			tweenInProgress = false
		end)
	
end

--resizes the canvas size of the weapon list according to the length of its children
local function resizeLoadoutCanvas()
	local sizeSum = UDim.new()
	for _, v in pairs(weaponList:GetChildren()) do
		if v:IsA("GuiObject") and v.Visible then
			sizeSum = sizeSum + v.Size.Y
		end
	end
	weaponList.CanvasSize = UDim2.new(UDim.new(), sizeSum)
end

function openWindow()
	HUD.Enabled = false
	frame.Visible = true
	frame:TweenPosition(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, easingStyle, tweenTime, false, nil)
	
	blur.Enabled = true
	
	local tweenfo = TweenInfo.new(tweenTime, easingStyle, Enum.EasingDirection.In)
	local tween = TweenService:Create(blur, tweenfo, {Size = 30})
	tween:Play()
	
	ContextActionService:BindAction("Close Loadout", closeWindowAction, false, Enum.KeyCode.Escape, Enum.KeyCode.Tilde, Enum.KeyCode.Q)
	RunService:BindToRenderStep("UpdateViewport", 201, function()
		charViewAnimated:Update()
	end)
end

function closeWindow()
	HUD.Enabled = true
	frame:TweenPosition(UDim2.new(-1, 0, 0, 0), Enum.EasingDirection.Out, easingStyle, tweenTime, true,
			function()
				frame.Visible = false
			end)
		closeWeaponList()
	local tweenfo = TweenInfo.new(tweenTime, easingStyle, Enum.EasingDirection.Out)
	local tween = TweenService:Create(blur, tweenfo, {Size = 0})
	tween:Play()
	ContextActionService:UnbindAction("Close Loadout")
	RunService:UnbindFromRenderStep("UpdateViewport")
end

local lastPoseAnim
local function playPoseAnimation(weapon)
	if not weapon or not charViewAnimated then return end
	
	-- Stop playing the current pose animation, if any
	if lastPoseAnim then
		lastPoseAnim:Stop()
		lastPoseAnim:Destroy()
	end
	
	-- Find and play the new pose animation that corresponds with currentWeapon
	local poseAnim = animationsFolder:FindFirstChild(weapon.Name, true)
	if not poseAnim or not poseAnim:IsA("Folder") then
		if weapon:FindFirstChild("ControllerAuto") or weapon.Configuration.Module.Value.Parent.Name == "Sniper" then
			poseAnim = assaultAnims
		elseif weapon:FindFirstChild("ControllerShotgun") then
			poseAnim = shotgunAnims
		elseif weapon:FindFirstChild("ControllerSemiAuto") then
			poseAnim = pistolAnims
		end
	end
	
	if poseAnim and poseAnim:IsA("Folder") then
		lastPoseAnim = charViewAnimated:LoadAnimation(poseAnim.EquipIdle)
		lastPoseAnim:Play()
	end
end

--updates the appearance of the button of the specified slot with the specified weapon
local function setSlotWeapon(slotName, weapon)
	local slotButton = loadoutList:FindFirstChild(slotName)
	
	if not slotButton then return end
	
	local display = slotButton.WeaponDisplay
	--[[
	for _,v in pairs (display:GetChildren()) do
		if v ~= display.CurrentCamera then
			v:Destroy()
		end
	end
	]]
	if weapon.Name ~= "Grenade" then -- temporarily not going to include the grenade
		local weaponClone = weapon:Clone()
		--weaponClone.Parent = display
		--weaponClone.Handle.CFrame = CFrame.new(Vector3.new(), Vector3.new(0, 1 , 0))
		--tools.setViewportFrameContent2(display, weaponClone, CFrame.new(Vector3.new(), Vector3.new(1, 0 , 0)), CFrame.new(Vector3.new(0, 0, -3), Vector3.new()))
		tools.setViewportFrameContent(display, weaponClone, Vector3.new(1,0,0))
	end
	
	slotButton.WeaponName.Text = weapon.Name
end

--sets the values of the loadout
local function setLoadout(wepType, weapon)
	
	local packID = weapon.Parent.Parent.Parent.Configuration.ProductID.Value
	
	local loadoutWeapon = player.Loadout:FindFirstChild(wepType)
	if not loadoutWeapon then
		error("Weapon type \""..wepType.."\" not found")
	end
	
	local hasPass, success, message
	if packID ~= 0 then
		success, message = pcall(function ()
			hasPass = Market:UserOwnsGamePassAsync(player.UserId, packID)
		end) 
	else
		hasPass = true
		success = true
	end
	
	print("Clientside check ID: "..packID.." Success: "..tostring(success).." Has Pass: "..tostring(hasPass))
	
	if success then
		print("Success")
		if hasPass then
			print("has pass")
			local oldWeapon = loadoutWeapon.Value
			--preemptively set the appearance of the button
			setSlotWeapon(wepType, weapon)
			
			if charViewAnimated then
				charViewAnimated.equipTool(weapon:Clone())
				if wepType == "Primary" or wepType == "Secondary" then
					currentWeapon = weapon
					playPoseAnimation(weapon)
				end
			end
			
			print("Requesting server validation for loadout change")
			
			--invoke the server loadout eqip function
			local serverSuccess, serverHasPass = setLoadoutFunc:InvokeServer(wepType, weapon)
			
			if serverSuccess then
				print("Server check successful")
				if serverHasPass then
					print("Player has the pass. Loadout change permitted")
					
				else
					print("Player does not have pass. Reverting change")
					--if the player didn't actually have the pass
					Market:PromptGamePassPurchase(player, packID)
					setSlotWeapon(wepType, oldWeapon)
				end
			else
				print("Server check failed")
				--server market check failed
				setSlotWeapon(wepType, oldWeapon)
			end
			
		else
			print("Client has decided player does not have pass")
			Market:PromptGamePassPurchase(player, packID)
		end
	end
end

--opens up the weapons list and displays weapons of the specified slot slot
local function showWeapons(wepType)
	openWeaponList()
	
	--table of weapon Dropdowns indexed by weapon class name
	local weaponTable = {}
	
	--iterate over the weapon packs
	for _, pack in pairs(weapons:GetChildren()) do
		--either the Primary or Secondary folder, depending on wepType
		local folder = pack:FindFirstChild(wepType)
		
		if folder then
			local config = pack:FindFirstChild("Configuration")
			
			--iterate over the weapon classes in each pack
			for _, class in pairs(folder:GetChildren()) do
				if class ~= config then
					local classdrop = weaponTable[class.Name]
					local dropContent
					--if we haven't made a dropdown for this class yet
					if not classdrop then
						classdrop = classDropdown:Clone()
						local dropButton = classdrop.Button
						dropButton.Text = class.Name
						
						dropContent = dropButton.Content
						
						--the dropdown function of the thing
						dropButton.MouseButton1Click:Connect(function ()
							local open = dropButton.Open
							if not open.Value then --clicking when not open (expanding)
								local children = dropContent:GetChildren()
								--iterating over the buttons in the dropdown
								for _, v in pairs (children) do
									if v:IsA("TextButton") then
										v.Visible = true
										v:TweenSize(weaponButton.Size, Enum.EasingDirection.Out, easingStyle, tweenTime/2, false, nil)
									end
								end
								
								local numButtons = #children - 1 --number of buttons = children - UILayout
								local ySize = weaponButton.Size.Y
								classdrop:TweenSize(UDim2.new(UDim.new(1,0),UDim.new(ySize.Scale*numButtons, ySize.Offset*numButtons) + classDropdown.Button.Size.Y),
									Enum.EasingDirection.Out, easingStyle, tweenTime/2, false, nil)
							else --clicking when open (collapsing)
								for _, v in pairs (dropContent:GetChildren()) do
									if v:IsA("TextButton") then
										v:TweenSize(UDim2.new(weaponButton.Size.X, UDim2.new()), Enum.EasingDirection.In, easingStyle, tweenTime/2, false,
											function()
												v.Visible = false
											end)
									end
								end
								classdrop:TweenSize(UDim2.new(UDim.new(1,0),classDropdown.Button.Size.Y), Enum.EasingDirection.In, easingStyle, tweenTime/2, false, nil)
							end
							open.Value = not open.Value
							resizeLoadoutCanvas()
						end)
					end
					
					dropContent = classdrop.Button.Content
					
					local classChildren = class:GetChildren()
					
					--making the buttons for each weapon
					for _, weapon in pairs(classChildren)do
						local butto = weaponButton:Clone()
						butto.Text = weapon.Name
						
						butto.BackgroundColor3 = config.PackColor.Value
						--when clicked set the weapon in the loadout to the clicked button
						butto.MouseButton1Click:Connect(function ()
							setLoadout(wepType, weapon)
							closeWeaponList()
						end)
						butto.Parent = dropContent
					end
					
					local ySize = weaponButton.Size.Y
					classdrop.Size = UDim2.new(UDim.new(1,0),UDim.new(ySize.Scale*#classChildren, ySize.Offset*#classChildren) + classDropdown.Button.Size.Y)
					
					classdrop.Parent = weaponList
				end	
			end
		end
		
	end
	resizeLoadoutCanvas()
end

--iterate over the buttons in loadoutList and make them work with their assigned weapon slots
for _, v in pairs(loadoutList:GetChildren()) do
	if v:IsA("TextButton") then
		
		local display = v:FindFirstChild("WeaponDisplay")
		if display then
			local camera = Instance.new("Camera", display)
			display.CurrentCamera = camera
			camera.CFrame = CFrame.new(Vector3.new(0, -5, 0), Vector3.new())
		end
		
		--bind the clicking event
		v.MouseButton1Click:Connect(function ()
			if not tweenInProgress then
				if activeButton ~= v then
					if activeButton then
						closeWeaponList()
						wait(tweenTime + .01)
					end
					activeButton = v
					showWeapons(v.Name)
				else
					closeWeaponList()
				end
			end
		end)
	end
end

--for the toggling
local function toggleVisibility()
	--frame.Visible = not frame.Visible
	if frame.Visible then
		closeWindow()
	else
		openWindow()
	end
end

function closeWindowAction(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		closeWindow()
	end
end

local function toggleLoadout(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		toggleVisibility()
	end
end
ContextActionService:BindAction("Toggle Loadout", toggleLoadout, false, Enum.KeyCode.M)

loadoutButton.MouseButton1Click:Connect(toggleVisibility)

--set the initial slot buttons
for _, slot in pairs(loadout:GetChildren()) do
	if slot.Value then
		setSlotWeapon(slot.Name, slot.Value)
	end
end

frame.Position = UDim2.new(-1, 0, 0, 0)
frame.Visible = false
closeWeaponList()

setAppearanceEvent.OnClientEvent:Connect(function(newChar)
	-- New mthod with the Gui3D library
	if not charViewAnimated then
		-- Create new animatable character view
		charViewAnimated = Gui3D.new(newChar)
		charViewAnimated.Parent = charView
		charViewAnimated.setOrientation(Vector3.new(20, 20, 7.5))
	else
		charViewAnimated.setModel(newChar) -- update the model
	end
	
	-- Play running and positing animations
	local anim = charViewAnimated:LoadAnimation(runAnim)
	anim:Play()
	playPoseAnimation(currentWeapon)
end)