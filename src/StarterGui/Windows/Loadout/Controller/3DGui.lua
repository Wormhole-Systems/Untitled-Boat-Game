--/
-- Richard's 3D Gui Master Script V1. (Written by Onogork, 2018)
--	Used to create 3D gui frames using the new ViewportFrames!
-- Modified by nilVector in 2019; Modifications marked with KingedPawn signature
--/
local prefix = "[3D Gui by Onogork] - ";
local svcWorkspace = game:GetService("Workspace");
-- Where the 3DGuis are created ¬
local origin = Vector3.new(0,10000,0);
local cameraOrigin = origin + Vector3.new(0, 1, 0)
--
local _Gui3D = {};
_Gui3D.__index = _Gui3D;
-- Create Frame : Make a viewport frame with the model and camera already set up.
function _Gui3D.new(paramModel)
	local _gui = {}; setmetatable(_gui, _Gui3D);
	-- Create defaults.
	_gui.Orientation = Vector3.new(0,0,0);
	_gui.Zoom = 1;
	_gui.CorrespondingAnimatedParts = {}
	_gui.Tool = nil
	
	--
	local function setModel(paramModel)
		-- Clean up existing memory
		--[[
		if (_gui.Frame) then _gui.Frame:Destroy(); end;
		if (_gui.Camera) then _gui.Camera:Destroy(); end;
		if (_gui.Model) then _gui.Model:Destroy(); end;
		if (_gui.Dummy) then _gui.Dummy:Destroy(); end;
		if (_gui.Animator) then _gui.Animator:Destroy(); end;
		--]]
		
		--/
		-- To ensure that our parts align with any animated parts.
		local paramModel = paramModel:Clone();
		local partcount = 1;
		for _,value in pairs(paramModel:GetDescendants()) do
			if (value:IsA("BasePart")) then
				local tag = Instance.new("IntValue");
				tag.Name = "PartTag"..tostring(partcount);
				tag.Value = partcount;
				partcount = partcount + 1;
				tag.Parent = value;
			end;
		end;
		
		--/
		-- Create a clone in workspace to run any required animations.
		local function checkForAnimator()
			local humanoid, animationcontroller = paramModel:FindFirstChildWhichIsA("Humanoid"), paramModel:FindFirstChildWhichIsA("AnimationController");
			return humanoid or animationcontroller;
		end;
		local animator = checkForAnimator();
		if (animator) then		
			local animationDummy = paramModel:Clone();
			-- Weld all attachments to the animation dummy to update their position without the humanoid.
			local function weldAttachments()
				local accessorys = {};
				for _,value in pairs(animationDummy:GetDescendants()) do
					local parent = value.Parent.Parent;
					if (value:IsA("Attachment") and parent:IsA("Accessory")) then
						
						local sub = value.Name;
						local tab = accessorys[tostring(sub)];
						if (tab == nil) then tab = {}; end;
						
						print("Added ".. parent.Name.. " to table for ".. sub);
						table.insert(tab, parent);	
						accessorys[tostring(sub)] = tab;			
					end;
				end;
				
				for _,value in pairs(animationDummy:GetDescendants()) do
					local parent = value.Parent.Parent;
					if (value:IsA("Attachment") and parent:IsA("Model")) then
						local sub = value.Name;
						local tab = accessorys[tostring(sub)];
						if (tab) then
							for _, accessory in pairs(tab) do
								local weld = Instance.new("Motor6D");
								weld.Parent = value.Parent;
								weld.Part0 = value.Parent;
								weld.Part1 = accessory:FindFirstChildWhichIsA("Part");
								weld.C0 = CFrame.new(accessory.AttachmentPos * 0.5); 
							end;
						end;
					end;
				end;
			end;
			weldAttachments();
			-- Remove humanoid and replace with animation controller. Less demanding.
			if (animator:IsA("Humanoid")) then 
				animationDummy:FindFirstChildWhichIsA("Humanoid"):Destroy();
				animator = Instance.new("AnimationController", animationDummy);
			end;
			animationDummy:SetPrimaryPartCFrame(CFrame.new(origin));
			animationDummy.PrimaryPart.Anchored = true;
			animationDummy.Parent = svcWorkspace;
			_gui.Dummy = animationDummy;
			_gui.Animator = animator;
		end;
		--/
		-- Create a clone for the ViewPortFrame.
		local model = paramModel:Clone();
		
		-- KingedPawn
		for _, v in pairs(model:GetDescendants()) do
			if (v:IsA("IntValue") and string.sub(v.Name, 1, 7) == "PartTag") then
				local corresponding = _gui.Dummy:FindFirstChild(v.Name, true);
				if (corresponding) then
					_gui.CorrespondingAnimatedParts[v.Parent] = corresponding.Parent;
					corresponding:Destroy();
					v:Destroy();
				end;
			end;
		end;
		
		-- Remove humanoid or animation controller from the viewport model.
		-- NOOOOO (signed, KingedPawn)
		--[[
		local humanoid, animationController = model:FindFirstChildWhichIsA("Humanoid"), 
			model:FindFirstChildWhichIsA("AnimationController");
		if (humanoid) then humanoid:Destroy(); end; 
		if (animationController) then animationController:Destroy(); end;
		--]]
		--
		local function findModelCentre()
			local prim = paramModel:GetPrimaryPartCFrame().p;
			local minX, minY, minZ, maxX, maxY, maxZ;
			for _,value in pairs(paramModel:GetDescendants()) do
				if (	value:IsA("BasePart")
					and value ~= paramModel.PrimaryPart
				--[[	and value.Parent.ClassName ~= "Accessory"
					and value.Parent.ClassName ~= "Accoutrement"]]) then
					local position, size, mesh = value.Position, value.Size, value:FindFirstChildWhichIsA("SpecialMesh");
					if (mesh) then position = position + mesh.Offset; size = mesh.Scale; end;
					-- Using CFrames to simply apply offsets on an angle.
					local high = 
						(CFrame.new(position) * 
						CFrame.Angles(math.rad(value.Orientation.X), math.rad(value.Orientation.Y), math.rad(value.Orientation.Z))) *
						CFrame.new((size/2));
					local low = (CFrame.new(position) *
						CFrame.Angles(math.rad(value.Orientation.X), math.rad(value.Orientation.Y), math.rad(value.Orientation.Z))) *
						CFrame.new(-(size/2));
					-- Calculate local highs and lows.
					local max, min = high.p, low.p;
					local hiX, hiY, hiZ = math.max(max.X,min.X), math.max(max.Y,min.Y), math.max(max.Z,min.Z);
					local loX, loY, loZ = math.min(max.X,min.X), math.min(max.Y,min.Y), math.min(max.Z, min.Z);
					-- Fix global highs and lows.
					if (minX == nil or minX > loX) then minX = loX; end;
					if (maxX == nil or maxX < hiX) then maxX = hiX; end;
					if (minY == nil or minY > loY) then minY = loY; end;
					if (maxY == nil or maxY < hiY) then maxY = hiY; end;
					if (minZ == nil or minZ > loZ) then minZ = loZ; end;
					if (maxZ == nil or maxZ < hiZ) then maxZ = hiZ; end;	
				end;							
			end;
			local min, max = Vector3.new(minX,minY,minZ), Vector3.new(maxX, maxY,maxZ);
			local result = min:Lerp(max, 0.5);
			local offset = (result) - prim;
			return result, max-min, offset;
		end;
		local modelCentre, modelSize, modelOffset = findModelCentre(model);
		local maxAxis = math.max(modelSize.X, modelSize.Y, modelSize.Z);
		_gui.LargestAxis = maxAxis;
		model:SetPrimaryPartCFrame(CFrame.new(origin) * CFrame.new(-modelOffset));
		--/
		-- Create ViewportFrame.
		local frame = Instance.new("ViewportFrame");
		frame.Size = UDim2.new(1, 0, 1, 0);
		frame.SizeConstraint = Enum.SizeConstraint.RelativeYY;
		frame.Position = UDim2.new(0.5, 0, 0.5, 0);
		frame.AnchorPoint = Vector2.new(0.5, 0.5);
		frame.BackgroundTransparency = 1;
		--/
		-- Create camera.
		local camera = Instance.new("Camera");
		camera.CameraType = Enum.CameraType.Scriptable;
		camera.Parent = frame;
		frame.CurrentCamera = camera;
		frame.CurrentCamera.CFrame = CFrame.new(cameraOrigin) * CFrame.Angles(0,math.rad(180),0) * CFrame.new(0,0,maxAxis * 1.25);
		model.Parent = frame;
		--/
		-- Apply changes to data.
		_gui.Camera = camera;
		_gui.Frame = frame;
		_gui.Model = model;
		
		paramModel:Destroy()
	end;
	setModel(paramModel);
	-- Frame : Returns the Roblox ViewportFrame instance. (For fine tuning).
	function _gui.getFrame()
		return _gui.Frame;
	end;
	-- Camera : Returns the Roblox Camera instance. (For fine tuning).
	function _gui.getCamera()
		return _gui.Camera;
	end;
	-- Zoom : Distance from the model.
	function _gui.setZoom(paramNumber)
		if (tonumber(paramNumber) == nil) then error(prefix.. ".setZoom() requires a numerical value."); end;
		_gui.Zoom = paramNumber;
	end;
	function _gui.getZoom()
		return _gui.Zoom;
	end;
	-- Orientations : Rotation of camera in respect to the model.
	function _gui.setOrientation(paramVector3)
		if (typeof(paramVector3) ~= "Vector3") then error(prefix.. ".setOrientation([]) requires a Vector3 value."); end;
		_gui.Orientation = paramVector3;
	end;
	function _gui.getOrientation()
		return _gui.Orientation;
	end;
	-- Model : The model being displayed in the frame.
	function _gui.setModel(paramModel)
		-- Clean up old model.
		if (_gui.Model) then _gui.Model:Destroy(); end;
		if (_gui.Dummy) then _gui.Dummy:Destroy(); end;
		if (_gui.Frame) then _gui.Frame:Destroy(); end;
		if (_gui.Camera) then _gui.Camera:Destroy(); end;
		_gui.LargestAxis = 0; _gui.Model = nil; _gui.Dummy = nil; _gui.CorrespondingAnimatedParts = {}
		-- Replace with new one.
		setModel(paramModel);
	end;
	function _gui.getModel() 
		return _gui.Model, _gui.Dummy;
	end;
	-- KingedPawn; Tool : The tool equipped by the character in the frame.
	function _gui.equipTool(tool)
		if (not tool:IsA("Tool") or not _gui.Dummy:FindFirstChild("RightHand")) then return end;
		
		-- Clean up the tool so that we only have BaseParts and Welds
		for _, v in pairs(tool:GetDescendants()) do
			if not (v:IsA("BasePart") or v:IsA("Model") or v:IsA("Weld") or v:IsA("ManualWeld") or v:IsA("Motor6D")) then
				v:Destroy()
			end
		end
		
		-- Remove current tool
		if (_gui.Tool) then
			for _, toolPart in pairs(_gui.Tool:GetDescendants()) do
				if (toolPart:IsA("BasePart") and _gui.CorrespondingAnimatedParts[toolPart]) then
					_gui.CorrespondingAnimatedParts[toolPart]:Destroy();
					_gui.CorrespondingAnimatedParts[toolPart] = nil;
					toolPart:Destroy();
				else
					if (not (toolPart:IsA("Weld") or toolPart:IsA("Model") or toolPart:IsA("Motor6D"))) then
						toolPart:Destroy()
					end;
				end;
			end;
			
			if (_gui.Dummy:FindFirstChildOfClass("Tool")) then _gui.Dummy:FindFirstChildOfClass("Tool"):Destroy(); end;
			if (_gui.Model:FindFirstChildOfClass("Tool")) then _gui.Model:FindFirstChildOfClass("Tool"):Destroy(); end;
		end;
		_gui.Tool = tool;
		
		-- Add tools to both the dummy and viewport model
		local toolClone = tool:Clone();
		tool.Parent = _gui.Model;
		toolClone.Parent = _gui.Dummy;
		
		-- Weld the dummy's tool to its right hand so that the CFrame copying can be done properly
		local rightGrip = Instance.new("Weld");
		rightGrip.Name = "RightGrip";
		rightGrip.C0 = CFrame.Angles(-math.pi/2, 0, 0);
		rightGrip.C1 = toolClone.Grip;
		rightGrip.Part0 = _gui.Dummy["RightHand"];
		rightGrip.Part1 = toolClone.Handle;
		rightGrip.Parent = _gui.Dummy["RightHand"];
		
		-- Correspond the tools' parts with one another
		local toolDescendants, toolCloneDescendants = tool:GetDescendants(), toolClone:GetDescendants();
		for i = 1, #toolDescendants do
			local toolPart = toolDescendants[i];
			if (toolPart:IsA("BasePart")) then
				_gui.CorrespondingAnimatedParts[toolPart] = toolCloneDescendants[i];
			end;
		end;
	end;
	-- Parent : Set the parent.
	_gui.Parent = nil;
	--					
	return _gui;			
end;
-- Animations : Play animations just like you would with Humanoids and AnimationControllers.
function _Gui3D:LoadAnimation(paramAnimation)
	local animator = self.Animator;
	if (animator == nil) then warn(prefix.. ":LoadAnimation() can only be used on models with AnimationControllers or Humanoids."); return nil; end;
	return animator:LoadAnimation(paramAnimation);
end;
function _Gui3D:GetPlayingAnimationTracks()
	local animator = self.Animator;
	if (animator == nil) then warn(prefix.. ":GetPlayingAnimationTracks() can only be used on models with AnimationControllers or Humanoids."); return nil; end;
	return animator:GetPlayingAnimationTracks();
end;
-- Update : Update the frame using data.
function _Gui3D:Update()
	local model, animator = self.Model, self.Dummy;
	local frame, camera = self.Frame, self.Camera;
	local zoom, orientation, largestAxis = self.Zoom, self.Orientation, self.LargestAxis;
	local correspondingAnimatedParts = self.CorrespondingAnimatedParts;
	
	if (frame and camera) then
		-- Set parent.
		frame.Parent = self.Parent;
		-- Update camera.
		camera.CFrame =
			CFrame.new(origin) *
			CFrame.Angles(math.rad(orientation.X),math.rad(orientation.Y + 180), math.rad(orientation.Z)) *
			CFrame.new(0,0,(largestAxis * 1.25)/zoom);
	end;
	-- Update frame.
	--[[
	if (frame.Visible and animator) then
		for _,value in pairs(animator:GetDescendants()) do
			if (value:IsA("BasePart")) then
				for _,tag in pairs(value:GetChildren()) do
					if (tag:IsA("IntValue") and string.sub(tag.Name,1, 7) == "PartTag") then
						local part = model:FindFirstChild(tag.Name, true).Parent;
						local target = animator:GetPrimaryPartCFrame():toObjectSpace(value.CFrame);
						part.CFrame = model:GetPrimaryPartCFrame() * target;
						break;
					end;
				end;														
			end;
		end;
	end;	
	--]]
	
	-- KingedPawn; O(n) solution which is way better than the original O(n^3) solution above
	if (frame and frame.Visible and model and animator) then
		for _, part in pairs(model:GetDescendants()) do
			if (part:IsA("BasePart") and correspondingAnimatedParts[part]) then
				local target = animator:GetPrimaryPartCFrame():toObjectSpace(correspondingAnimatedParts[part].CFrame);
				part.CFrame = model:GetPrimaryPartCFrame() * target;
			end;
		end;
	end;
end;
-- Destroy : Destroy the frame like you would with Instances.
function _Gui3D:Destroy()
	if (self.Frame) then self.Frame:Destroy(); end;
	if (self.Camera) then self.Camera:Destroy(); end;
	if (self.Animator) then self.Animator:Destroy(); end;
	if (self.Model) then self.Model:Destroy(); end;
	if (self.Dummy) then self.Dummy:Destroy(); end;
	self.Orientation, self.Zoom, self.CorrespondingAnimatedParts = nil, nil, nil;
	self.Destroyed = true;
end;
--
return _Gui3D;
--/