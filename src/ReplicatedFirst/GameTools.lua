local module = {}

--copied and edited from the Roblox wiki because i'm lazy
local function weldBetween(a, b)
    --Make a new Weld
    local weld = Instance.new("Weld")
	local pos = a.CFrame:inverse() * b.CFrame
    weld.Part0 = a
    weld.Part1 = b
    --Get the CFrame of b relative to a.
    weld.C0 = pos
    --Return the reference to the weld so that you can change it later.
    weld.Parent = a
end

--converts c from the proportion between a[1] and b[1] to the proportion between a[2] and b[2]
local function pointSlope(a, b, c)
	local progress = (c - a[1])/(b[1] - a[1])
	return progress * (b[2] - a[2]) + a[2]
end

local function weldModel(model)
	for _, v in pairs (model:GetChildren()) do
		if v:IsA("BasePart") and v ~= model.PrimaryPart then
			local weld = Instance.new("Weld", model.PrimaryPart)
			weld.Part0 = model.PrimaryPart
			weld.Part1 = v
			weld.C1 = v.CFrame - model.PrimaryPart.CFrame
		end
	end
end

local function weldTool(model)
	for _, v in pairs (model:GetChildren()) do
		if v:IsA("BasePart") and v ~= model.Handle then
			weldBetween(model.Handle, v)
		end
	end
end

--[[performs binary search on list, searching for parameter targ, using valueGet as a function that determines the target parameter
PRECONDITION: list must be a sorted array, with numbered indexes only; no dictionary entries
		list cannot contain multiple entries that satisfy valueGet
		
Primarily used for item IDs

ex: 
	local codId = Cod.Id
	local dex = search(fishInventory, cod.Id, function(fish) return fish.Id end)
]]
local function search(list, targ, valueGet)
	local dex1 = 1
	local dex2 = #list
	while (dex1 <= dex2) do
		if (valueGet(list[dex1]) == targ) then return dex1 
		elseif	(valueGet(list[dex2]) == targ) then return dex2
		end
		
		local midP = math.floor((dex1 + dex2)/2)
		local midV = list[midP]
		
		local midParam = valueGet(midV)
		if (midParam == targ) then return midP 
		elseif (targ < midParam) then
			dex1 = dex1 + 1
			dex2 = midP - 1
		elseif (targ > midParam) then
			dex1 = midP + 1
			dex2 = dex2 - 1
		end
	end
	return -1
end

--[[
	returns a string representation of list. stringFunc is function (i) that returns how i is to be represented in string form
]]
local function arrayToString(list, stringFunc)
	local toReturn = "["
	
	for i, v in ipairs(list)do
		toReturn = toReturn..stringFunc(v)
		if (i < #list) then
			toReturn = toReturn..", "
		end
	end
	toReturn = toReturn.."]"
	return toReturn
end

--[[
	Creates a shallow copy of toCopy, from index dex1 to dex2
	toCopy must be a numeric array
--]]
local function copy (toCopy, dex1, dex2)
	local toReturn = {}
	for i = dex1, dex2 do
		table.insert(toReturn, toCopy[i])
	end
	return toReturn
end

--[[
	returns a merge-sorted copy of list, based on the paramater of each element provided by valueGet
	
--]]
local function sort(list, valueGet)
	local length = #list
	if (length <= 1) then return list
	else
		local midPoint = math.floor(length/2)
		local a1 = copy(list, 1, midPoint)
		local a2 = copy(list, midPoint + 1, length)
		
		--print("Subsec: "..arrayToString(a1).." "..arrayToString(a2))		
		
		if (#a1 > 1) then a1 = sort(a1, valueGet) end
		if (#a2 > 1) then a2 = sort(a2, valueGet) end
		
		--combining
		local toReturn = {}
		
		while (#a1 > 0 or #a2 > 0) do
			if (#a1 > 0 and #a2 > 0) then
				local val1 = valueGet(a1[1])
				local val2 = valueGet(a2[1])
				if (val1 <= val2) then
					table.insert(toReturn, a1[1])
					table.remove(a1,1)
				else
					table.insert(toReturn, a2[1])
					table.remove(a2,1)
				end
			elseif (#a1 <= 0) then
				table.insert(toReturn, a2[1])
				table.remove(a2,1)
			elseif (#a2 <= 0) then
				table.insert(toReturn, a1[1])
				table.remove(a1,1)
			end
		end
		--print("Result"..arrayToString(toReturn))
		return toReturn
	end
	
end

local function distanceWithin(p1, p2, limit)
	return (p1 - p2).Magnitude <= limit
end

local Queue = {}
Queue.meta = {__index = Queue}
function Queue.new ()
	local o = {first = 0, last = -1}
	setmetatable(o, Queue.meta)
	return o
end
function Queue:push(value)
	self.first = self.first - 1
	self[self.first] = value
end
function Queue:pop()
	if self.first > self.last then error("Queue is empty") end
	local value = self[self.last]
	self[self.last] = nil
	self.last = self.last - 1
	return value
end
function Queue:peek()
	return self[self.last]
end
function Queue:size()
	return self.last - self.first + 1
end

local function setViewportFrameContent2(frame, object, lookVector, zoomedOut, isVehicle)
	frame:ClearAllChildren()
	local model = object
	local mainCFrame = CFrame.new()
	--if not a model then convert to a model
	if not object:IsA("Model") then
		model = Instance.new("Model")
		model.Name = object.Name
		for _, v in pairs(object:GetChildren()) do
			if not v:IsA("BasePart") and not v:IsA("Model") and not v:IsA("Folder") then
				v:Destroy()
			else
				v.Parent = model
			end
		end
		--setting stuff if the object is a tool
		if object:IsA("Tool") and object.RequiresHandle then
			model.PrimaryPart = model.Handle
			--set the cframe of the handle based on toolgrip
			local handleCFrame = CFrame.fromMatrix(object.GripPos, object.GripRight, object.GripUp, -object.GripForward)
			mainCFrame = CFrame.new(Vector3.new(), lookVector) * (handleCFrame - handleCFrame.p)
			model:SetPrimaryPartCFrame(mainCFrame)
		end
		object:Destroy()
	else
		for _, v in pairs(object:GetChildren()) do
			if not v:IsA("BasePart") and not v:IsA("Model") and not v:IsA("Folder") then
				v:Destroy()
			end
		end
	end
	
	local modelSize = model:GetExtentsSize()
	local offset = model:GetModelCFrame().p - model.PrimaryPart.CFrame.p
	--centering the model based on model extent size
	if model.PrimaryPart then
		--model:SetPrimaryPartCFrame(objectCFrame)
		--model:SetPrimaryPartCFrame(mainCFrame * CFrame.new(- modelSize/2) + offset + Vector3.new(0, modelSize.Y/2, 0))
		model:SetPrimaryPartCFrame(mainCFrame - offset/2)
	end
	model.Parent = frame
	
	--camera time
	local camera = Instance.new("Camera", frame)
	
	--calculate the needed distance between the camera and the model based on model height and FOV
	local distHeight = modelSize.X/math.tan(camera.FieldOfView)
	
	--local viewSize = camera.ViewportSize
	--local horizFOV = viewSize.X / viewSize.Y * camera.FieldOfView
	
	local viewSize = frame.Size
	local horizFOV = viewSize.X.Scale / viewSize.Y.Scale * camera.FieldOfView
	
	local distWidth = modelSize.Y/math.tan(horizFOV)
	
	local trueDist = zoomedOut and math.max(distWidth, distHeight) or math.min(distWidth, distHeight)
	
	if not isVehicle then
		camera.CFrame = CFrame.new(Vector3.new(0,0, -trueDist), Vector3.new())
	else
		--camera.CFrame = CFrame.new(Vector3.new(modelSize.Z, modelSize.Y, -modelSize.X), Vector3.new())
		local originPos = model:GetModelCFrame().p
		camera.CFrame = CFrame.new(originPos + Vector3.new(modelSize.Z, modelSize.Y, -modelSize.X), originPos)
		local difference = originPos - camera.CFrame.p
		camera.CFrame = camera.CFrame + difference/3
	end
	frame.CurrentCamera = camera
end

local function setViewportFrameContent(frame, object, objectCFrame, cameraCFrame)
	for _, v in pairs (frame:GetChildren()) do
		v:Destroy()
	end
	
	local camera = Instance.new("Camera", frame)
	camera.CFrame = cameraCFrame
	frame.CurrentCamera = camera
	
	local model = object
	
	--if not a model then convert to a model
	if not object:IsA("Model") then
		model = Instance.new("Model")
		model.Name = object.Name
		for _, v in pairs(object:GetChildren()) do
			if not v:IsA("BasePart") then
				v:Destroy()
			else
				v.Parent = model
			end
		end
		if object:IsA("Tool") and object.RequiresHandle then
			
			model.PrimaryPart = model.Handle
		end
		object:Destroy()
	end
	
	if model.PrimaryPart then
		model:SetPrimaryPartCFrame(objectCFrame)
	end
	
	model.Parent = frame
end

-- Borrowed from RobxSoft
-- https://devforum.roblox.com/t/easy-way-to-put-accessories-on-a-rig-thats-in-a-viewport-frame/297941/2
local function addAccoutrement(character, accoutrement)
	local attachment = accoutrement.Handle:FindFirstChildOfClass("Attachment")
	local weld = Instance.new("Weld")
	weld.Name = "AccessoryWeld"
	weld.Part0 = accoutrement.Handle
	if attachment then
		local other = character:FindFirstChild(tostring(attachment), true)
		weld.C0 = attachment.CFrame
		weld.C1 = other.CFrame
		weld.Part1 = other.Parent
	else
		weld.C1 = CFrame.new(0, character.Head.Size.Y / 2, 0) * accoutrement.AttachmentPoint:inverse()
		weld.Part1 = character.Head
	end
	accoutrement.Handle.CFrame = weld.Part1.CFrame * weld.C1 * weld.C0:inverse()
	accoutrement.Parent = character
	weld.Parent = accoutrement.Handle
end

module.setViewportFrameContent = setViewportFrameContent2
--module.setViewportFrameContent2 = setViewportFrameContent
module.Queue = Queue
module.search = search
module.weldBetween = weldBetween
module.weldModel = weldModel
module.weldTool = weldTool
module.five = 6
module.sort = sort
module.copy = copy
module.sort = sort
module.arrayToString = arrayToString
module.distanceWithin = distanceWithin
module.pointSlope = pointSlope
module.addAccoutrement = addAccoutrement

return module