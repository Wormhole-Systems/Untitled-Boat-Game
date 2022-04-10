local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local UserInputService = game:GetService("UserInputService")

local gameTools = require(ReplicatedFirst.GameTools)

local MAX_TOOLS = 5

local player = Players.LocalPlayer
local backpack = player.Backpack
local character = player.Character

--[[a table of tools and their GUI buttons
	Format is:
		Indexed numerically
		Value: {tool = ***
				button = ***
				connection = ***}
]]
local tools = {}

local frame = script.Parent
local selector = frame.Selector
local weaponButton = script.WeaponButton

local buttonSizeX = weaponButton.Size.X

local easingStyle = Enum.EasingStyle.Quart
local tweenTime = .2

local toolNumSelected = 0

--searches for the given tool or button and returns the number that indexes it
local function searchForNum(param)
	for i, v in ipairs(tools) do
		if v.tool == param or v.button == param then
			return i
		end
	end
	return nil
end

local function getButtonDisplacement(toolNum, selectedNum)
	local dispFactor = toolNum - selectedNum
	local xOffset = UDim.new(buttonSizeX.Scale * dispFactor, buttonSizeX.Offset * dispFactor)
	if toolNum > selectedNum then
		xOffset = xOffset + selector.Size.X - buttonSizeX
	end
	return xOffset
end

local function repositionButton(button, toolNum, selectedNum)
	button:TweenSizeAndPosition(
				weaponButton.Size,
				UDim2.new(
					selector.Position.X + getButtonDisplacement(toolNum, selectedNum),
					weaponButton.Position.Y),
				Enum.EasingDirection.InOut,
				easingStyle,
				tweenTime,
				true,
				nil)
end

local function repositionButtons()
	if tools[toolNumSelected] then
		tools[toolNumSelected].button:TweenSizeAndPosition(selector.Size, selector.Position, Enum.EasingDirection.InOut, easingStyle, tweenTime, true, nil)
	end
	for i = 1, 10 do
		if tools[i] and i ~= toolNumSelected then
			repositionButton(tools[i].button, i, toolNumSelected)
		end
	end
end

local function countInventory()
	local count = 0
	for i = 1, 10 do
		if tools[i] then
			count = count + 1
		end
	end
	return count
end

local function repositionButtonsUnequipped()
	local count = countInventory()
	local midPoint = math.ceil(count/2)
	for i = 1, 10 do
		local stuff = tools[i]
		if stuff and stuff.button then
			local j = i
			--simulate the gap by subtracting 1
			if i <= midPoint then
				j = j - 1
			end
			repositionButton(stuff.button, j, midPoint)
		end
	end
end

local function onEquip(tool)
	toolNumSelected = searchForNum(tool)
	local stuff = tools[toolNumSelected]
	stuff.connection:Disconnect()
	stuff.connection = stuff.button.MouseButton1Click:Connect(function ()
		character.Humanoid:UnequipTools()
	end)
	repositionButtons()
end


local function seatValid(huma)
	local seat = huma.SeatPart
	return not seat or (seat and not seat:IsA("VehicleSeat"))
end



local function onUnequip(tool)
	local stuff = tools[searchForNum(tool)]
	stuff.connection:Disconnect() 
	--rebind the equipping function
	stuff.connection = stuff.button.MouseButton1Click:Connect(function()
		local huma = character:FindFirstChild("Humanoid")
		if huma and seatValid(huma) then
			huma:EquipTool(tool)
		end
	end)
	repositionButtonsUnequipped()
end

local function clearInventory()
	for i = 1, 10 do
		local stuff = tools[i]
		if stuff then
			stuff.button:Destroy()
		end
		tools[i] = nil
	end
end

local function toolAdded(tool)
	local index
	local finished = false
	--find the next available slot in the inventory
	for i = 1, 10 do
		if tools[i] == nil and not finished then
			index = i
			finished = true
		end
	end
	if index then 
		local buttonClone = weaponButton:Clone()
		buttonClone.Position = UDim2.new(selector.Position.X + getButtonDisplacement(index, toolNumSelected), weaponButton.Position.Y)
		
		local connec = buttonClone.MouseButton1Click:Connect(function()
			local huma = character:FindFirstChild("Humanoid")
			if huma and seatValid(huma) then
				huma:EquipTool(tools[index].tool)
			end
		end)
		buttonClone.Parent = frame
		tools[index] = {tool = tool, button = buttonClone, connection = connec}
		--[[
		gameTools.setViewportFrameContent2(
			buttonClone.WeaponView, 
			tool:Clone(), 
			CFrame.new(Vector3.new(), Vector3.new(1, 0, 0)), 
			CFrame.new(Vector3.new(0, 0, -5), Vector3.new()))
		]]
		buttonClone.ToolNumber.Text = index
		
		gameTools.setViewportFrameContent(buttonClone.WeaponView, tool:Clone(), Vector3.new(1, 0 , 0), true)
	end
	repositionButtons()
end

local function childAdd(childo)
	if childo:IsA("Tool") and not searchForNum(childo) then
		toolAdded(childo)
	end
end

local function toolRemoved(tool)
	local index = searchForNum(tool)
	tools[index].button:Destroy()
	tools[index] = nil
end

local function childRemoved(childo)
	if childo:IsA("Tool") and searchForNum(childo) and childo.Parent ~= backpack and childo.Parent ~= character then
		toolRemoved(childo)
	end
end

local function connectSeating(char)
	local huma = char:WaitForChild("Humanoid")
	if huma then
		huma:GetPropertyChangedSignal("SeatPart"):Connect(function ()
			local seat = huma.SeatPart
			if seat and seat:IsA("VehicleSeat") then
				huma:UnequipTools()
			end
		end)
	end
end

local function charConnect(char)
	character = char
	character.ChildAdded:Connect(function (childo)
		childAdd(childo)
		if childo:IsA("Tool") then
			local huma = char.Humanoid
			local seat = huma.SeatPart
			if seatValid(huma) then
				onEquip(childo)	
			else
				huma:UnequipTools()
			end
			
		end
	end)
	character.ChildRemoved:Connect(function (childo)
		toolNumSelected = 0
		if childo:IsA("Tool") then
			onUnequip(childo)
		end
		childRemoved(childo)
	end)
	backpack = player.Backpack
	backpack.ChildAdded:Connect(childAdd)
	backpack.ChildAdded:Connect(childRemoved)
	connectSeating(char)
	local huma = character:WaitForChild("Humanoid")
	--huma.Died:Connect(clearInventory)
	clearInventory()
	for _, v in pairs(backpack:GetChildren()) do
		if v:IsA("Tool") then
			toolAdded(v)
		end
	end
	repositionButtonsUnequipped()
end

if UserInputService.KeyboardEnabled then
	UserInputService.InputBegan:Connect(function (obj, processed)
		local key = obj.KeyCode.Value - 48 --if 1 on the numbar is pressed, key will be 1
		local stuff = tools[key]
		if stuff and stuff.tool then
			local tool = stuff.tool
			local huma = character:FindFirstChild("Humanoid")
			local currentTool = character:FindFirstChildWhichIsA("Tool")
			local seat = huma.SeatPart
			if huma and seatValid(huma) then
				if stuff.tool ~= currentTool then
					huma:EquipTool(stuff.tool)
				else 
					huma:UnequipTools()
				end
			end
		end
	end)
end

player.CharacterAdded:Connect(charConnect)
charConnect(character)