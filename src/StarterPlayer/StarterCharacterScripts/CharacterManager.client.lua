--[[
	- Handles the oxygen level for the caracter
	- Controls different walkspeeds the player can be depending on character actions
--]]

-- Constants
local MAX_OXYGEN = 100
local OXYGEN_DAMAGE = 0.5
local WALKSPEED_SPRINTING = 21
local WALKSPEED_NORMAL = 16
local WALKSPEED_SWIMMING = 16
local WALKSPEED_ADS = 6
local MIN_HEIGHT_FOR_FALL_DAMAGE = 25
local DOWNWARD_DISTANCE_CHECK = Vector3.new(0, -MIN_HEIGHT_FOR_FALL_DAMAGE, 0)

-- Special adjuments to the walkspeed values based on whether or not player is on the Zombies team
if game.Players.LocalPlayer.Team.Name == "Infected" then
	WALKSPEED_SPRINTING = 10
	WALKSPEED_NORMAL = 10
	WALKSPEED_SWIMMING = 16
	WALKSPEED_ADS = 10
end
	
-- Services
local UserInputService = game:GetService("UserInputService")

-- Player values
local ads = game.Players.LocalPlayer:WaitForChild("ADS")
local hasToolOut = game.Players.LocalPlayer:WaitForChild("HasToolOut")

-- Map values
local gamemode = game.Workspace.Status.Gamemode

-- Character values
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")

-- Oxygen meter UI
local oxygenMeter = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("GameHUD"):WaitForChild("OxygenMeter")
local oxygenLeftBar = oxygenMeter:WaitForChild("OxygenLeft")

-- Oxygen meter values
local oxygenLeft = MAX_OXYGEN
local previousOxygenLeftValue

-- HumanoidStateType Enums
local freefallState = Enum.HumanoidStateType.Freefall
local landedState = Enum.HumanoidStateType.Landed
local swimmingState = Enum.HumanoidStateType.Swimming

-- Parachute variables
local parachuteNotifier = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("GameHUD"):WaitForChild("ParachuteNotifier")
local deployParachuteEvent = game:GetService("ReplicatedStorage"):WaitForChild("Invokers"):WaitForChild("DeployParachute")
local lastState, maxHeight
local canParachute = false
local parachuteBodyForce
local deployParachuteKeyboardConn, deployParachuteMobileConn

local function disableParachutingPrompt()
	-- Disable parachuting and Disconnect and remove connections
	parachuteNotifier:TweenPosition(UDim2.new(1, 0, 0.5, -37), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1)
	if deployParachuteKeyboardConn then
		deployParachuteKeyboardConn:Disconnect()
		deployParachuteKeyboardConn = nil
	end
	if deployParachuteMobileConn then
		deployParachuteMobileConn:Disconnect()
		deployParachuteMobileConn = nil
	end
end

local function deployParachute(state)
	disableParachutingPrompt()
	if not canParachute then return end
	if state ~= freefallState then return end -- in case of a false positive
	if humanoid.SeatPart then return end -- in case they meant to press E to get into a seat instead
	
	deployParachuteEvent:FireServer(true)
	parachuteBodyForce = Instance.new("BodyVelocity")
	parachuteBodyForce.MaxForce = Vector3.new(0, math.huge, 0)
	parachuteBodyForce.Name = "ParachuteForce"
	parachuteBodyForce.Velocity = Vector3.new(0, -math.abs(humanoidRootPart.Velocity.Y/5), 0)
	if parachuteBodyForce.Velocity.Y > -10 then
		parachuteBodyForce.Velocity = Vector3.new(0, -10, 0)
	end
	parachuteBodyForce.Parent = humanoidRootPart
end

while true do
	local state = humanoid:GetState()
	-- [[ Oxygen Level Check ]] --
	
	-- Check how much oxygen is left
	if head.Position.Y < -2 and (not humanoid.SeatPart or 
							   (humanoid.SeatPart.Parent 
								and humanoid.SeatPart.Parent:FindFirstChild("Engine") 
								and (humanoid.SeatPart.Parent.Configuration.Type.Value ~= "Submarine" 
								or humanoid.SeatPart.Parent.Engine:FindFirstChild("Smoke")))) then
		oxygenLeft = oxygenLeft - OXYGEN_DAMAGE
	else
		oxygenLeft = oxygenLeft + OXYGEN_DAMAGE
	end
	if oxygenLeft < 0 then oxygenLeft = 0 end
	if oxygenLeft > MAX_OXYGEN then oxygenLeft = MAX_OXYGEN end
	
	-- If oxygen needs to be updated
	if gamemode.Value ~= "Zombies" then
		if oxygenLeft ~= previousOxygenLeftValue then
			-- Update oxygen value to current one
			previousOxygenLeftValue = oxygenLeft 
			
			-- Calculate new amount of oxygen left and update its display accordingly
			local oxygenRatio = oxygenLeft/MAX_OXYGEN
			--oxygenLeftBar:TweenSizeAndPosition(UDim2.new(1, 0, 1 - oxygenRatio, 0), UDim2.new(0, 0, oxygenRatio, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1)
			oxygenLeftBar.Size = UDim2.new(1, 0, 1 - oxygenRatio, 0)
			oxygenLeftBar.Position = UDim2.new(0, 0, oxygenRatio, 0)
			
			-- Kill the player if they've been uderwater for too long
			if oxygenRatio == 0 then
				humanoid:TakeDamage(humanoid.MaxHealth)
			end
		end
		if oxygenLeft == MAX_OXYGEN and oxygenMeter.Position.X.Offset == -50 then
			oxygenMeter:TweenPosition(UDim2.new(1, 0, 0.5, -75), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1)
		elseif oxygenLeft ~= MAX_OXYGEN and oxygenMeter.Position.X.Offset == 0 then
			oxygenMeter:TweenPosition(UDim2.new(1, -50, 0.5, -75), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.5)
		end
	end
	-- [[ Walkspeed Management ]] --
	humanoid.WalkSpeed = WALKSPEED_NORMAL
	humanoid.JumpPower = 50
	if state == swimmingState then
		humanoid.WalkSpeed = WALKSPEED_SWIMMING
	elseif ads.Value then
		humanoid.WalkSpeed = WALKSPEED_ADS
		humanoid.JumpPower = hasToolOut.Value and 0 or 50
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		humanoid.WalkSpeed = WALKSPEED_SPRINTING
		humanoid.JumpPower = 55
	end
	
	-- [[ Parachute Management ]] --
	if state == freefallState and humanoidRootPart.Velocity.Y < 0 and humanoidRootPart.Position.Y > MIN_HEIGHT_FOR_FALL_DAMAGE and (not maxHeight or maxHeight < humanoidRootPart.Position.Y) then
		maxHeight = humanoidRootPart.Position.Y
		local parachuteRayCheck = Ray.new(humanoidRootPart.Position, DOWNWARD_DISTANCE_CHECK)
		local hit = workspace:FindPartOnRay(parachuteRayCheck, character)
		if not hit then	-- if not too close to a ground surface already	
			-- Show parachute notifier
			canParachute = true
			parachuteNotifier:TweenPosition(UDim2.new(1, -75, 0.5, -37), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1)
			deployParachuteKeyboardConn = UserInputService.InputBegan:Connect(function(key)
				if key.KeyCode == Enum.KeyCode.E then
					deployParachute(state)
				end
			end)
			deployParachuteMobileConn = parachuteNotifier.ClickableButton.Activated:Connect(function()
				deployParachute(state)
			end)
		end
	elseif state ~= lastState and lastState == freefallState and maxHeight then -- if they landed
		local fallHeight = maxHeight - humanoidRootPart.Position.Y
		maxHeight = nil
		if not parachuteBodyForce and fallHeight >= MIN_HEIGHT_FOR_FALL_DAMAGE and canParachute then
			local fellInWater = state == swimmingState
			local damage = math.floor((fellInWater and fallHeight/10 or fallHeight/5))
			humanoid:TakeDamage(damage)
			if not fellInWater then
				WALKSPEED_NORMAL = WALKSPEED_NORMAL/2
				WALKSPEED_SPRINTING = WALKSPEED_SPRINTING/2
				delay(1, function() WALKSPEED_NORMAL = WALKSPEED_NORMAL * 2; WALKSPEED_SPRINTING = WALKSPEED_SPRINTING * 2 end)
			end
			local fallSound = fellInWater and script.Splash:Clone() or script.Fall:Clone()
			fallSound.Volume = math.clamp(damage/10, 0, 5)
			fallSound.Parent = humanoidRootPart
			fallSound:Play()
			fallSound.Ended:Connect(function()
				fallSound:Destroy()
			end)
		elseif parachuteBodyForce then
			parachuteBodyForce:Destroy()
			parachuteBodyForce = nil
			deployParachuteEvent:FireServer(false)
		end
		
		canParachute = false
		if parachuteNotifier.Position.X ~= 0 then
			disableParachutingPrompt()
		end
	end
	
	lastState = state
	wait()
end