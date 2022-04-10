-- Services
local PhysicsService = game:GetService("PhysicsService")

-- Ragdoll whose physics the players' characters will emulate upon death
local sampleRagdoll = game:GetService("ServerStorage"):WaitForChild("Models"):WaitForChild("R15")

local function getAttachment0(character, attachmentName)
	for _, child in pairs(character:GetChildren()) do
		local attachment = child:FindFirstChild(attachmentName)
		if attachment then
			return attachment
		end
	end
end

local function ragdollDeath(character)
	-- Make it to where the characters cannot collide with the border
	local bodyParts = character:GetDescendants()
	for i = 1, #bodyParts do
		if bodyParts[i]:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(bodyParts[i], "CannotCollideWithBorder")
		end
	end
	
	local humanoid = character:WaitForChild("Humanoid")
	--humanoid.HealthDisplayDistance = false
	humanoid.BreakJointsOnDeath = false -- allow the joints to stay together
		
	humanoid.Died:Connect(function()
		character.HumanoidRootPart.CanCollide = false
		--character.HumanoidRootPart.Anchored = true
		local descendants = character:GetDescendants()
		for i = 1, #descendants do
			local d = descendants[i]
			--[[
			if d:IsA("Motor6D") then -- if it is a joint
				-- Create a ball socket constraint with the same attachments as the joint
				local name, part0 = d.Name, d.Part0
				local attachment0 = d.Parent:FindFirstChild(name.."Attachment") or d.Parent:FindFirstChild(name.."RigAttachment")
				local attachment1 = part0:FindFirstChild(name.."Attachment") or part0:FindFirstChild(name.."RigAttachment")
				if attachment0 and attachment1 then
					local ballSocketConstraint = Instance.new("BallSocketConstraint")
					ballSocketConstraint.LimitsEnabled = true
					ballSocketConstraint.UpperAngle = 45
					ballSocketConstraint.TwistLimitsEnabled = true
					ballSocketConstraint.TwistLowerAngle = -45
					ballSocketConstraint.TwistUpperAngle = 45
					ballSocketConstraint.Attachment0, ballSocketConstraint.Attachment1 = attachment0, attachment1
					ballSocketConstraint.Parent = d.Parent
					d:Destroy()
				end	
			--]]
			if d:IsA("Motor6D") then -- if it is a joint
				-- Search for its attachments
				local name, part0 = d.Name, d.Part0
				local attachment0 = d.Parent:FindFirstChild(name.."Attachment") or d.Parent:FindFirstChild(name.."RigAttachment")
				local attachment1 = part0:FindFirstChild(name.."Attachment") or part0:FindFirstChild(name.."RigAttachment")
				
				-- If they can be found
				if attachment0 and attachment1 then
					-- Use the sample ragdoll model to create appropriate hinge and ball socket constraints
					local reference = sampleRagdoll:FindFirstChild(d.Parent.Name)
					local referenceHingeConstraint, referenceBallSocketConstraint
					
					if reference then
						referenceHingeConstraint = reference:FindFirstChildOfClass("HingeConstraint")
						referenceBallSocketConstraint = reference:FindFirstChildOfClass("BallSocketConstraint")
					end
					
					if referenceHingeConstraint then
						local hingeConstraint = referenceHingeConstraint:Clone()
						hingeConstraint.Attachment0 = attachment0
						hingeConstraint.Attachment1 = attachment1
						hingeConstraint.Parent = d.Parent
					end
					
					if referenceBallSocketConstraint then
						local ballSocketConstraint = referenceBallSocketConstraint:Clone()
						ballSocketConstraint.Attachment0 = attachment0
						ballSocketConstraint.Attachment1 = attachment1
						ballSocketConstraint.Parent = d.Parent
					end
					
					local noCollisionConstraint = Instance.new("NoCollisionConstraint")
					noCollisionConstraint.Part0 = attachment0.Parent
					noCollisionConstraint.Part1 = attachment1.Parent
					noCollisionConstraint.Parent = d.Parent
							
					d:Destroy() -- destroy the actual joint since it is no longer needed for ragdolling
				end
			elseif d:IsA("Accoutrement") then -- if it is an accessory
				-- Re-attach it
				for _, v in pairs(d:GetChildren()) do
					if v:IsA("BasePart") then
						local attachment1 = v:FindFirstChildOfClass("Attachment")
						local attachment0 = getAttachment0(character, attachment1.Name)
						if attachment0 and attachment1 then
							local constraint = Instance.new("HingeConstraint")
							constraint.Attachment0 = attachment0
							constraint.Attachment1 = attachment1
							constraint.LimitsEnabled = true
							constraint.UpperAngle = 0 -- simulate weld by making it difficult for constraint to move
							constraint.LowerAngle = 0
							constraint.Parent = character
						end
					end
				end
			elseif d:IsA("Attachment") then -- if it is an attachment
				-- reduce ragdoll spasms
				d.Axis = Vector3.new(0, 1, 0)
				d.SecondaryAxis = Vector3.new(0, 0, 1)
				d.Rotation = Vector3.new(0, 0, 0)
			end
		end
	end)
end
	
game.Players.PlayerAdded:Connect(function(player)	
	player.CharacterAdded:Connect(ragdollDeath)
end)
