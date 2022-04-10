-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Parachute model
local parachuteModel = ServerStorage:WaitForChild("Models"):WaitForChild("Parachute")

-- Deploy Parachute Event
local deployParachuteEvent = ReplicatedStorage:WaitForChild("Invokers"):WaitForChild("DeployParachute")

deployParachuteEvent.OnServerEvent:Connect(function(player, deployed)
	if player.Character then
		local humanoid = player.Character:FindFirstChild("Humanoid")
		local upperTorso = player.Character:FindFirstChild("UpperTorso")
		if humanoid and upperTorso then
			wait()
			if deployed and humanoid.Health > 0 and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
				if not game.Workspace.Debris:FindFirstChild(player.Name.."Parachute") then
					local newParachuteModel = parachuteModel:Clone()
					newParachuteModel.Name = player.Name.."Parachute"
					newParachuteModel.Chute.BrickColor = player.TeamColor
					newParachuteModel.Parent = game.Workspace.Debris
				
					local parachuteWeld = Instance.new('Weld')
					parachuteWeld.Name = "ParachuteWeld"
					parachuteWeld.Part0 = newParachuteModel:WaitForChild("Handle")
					parachuteWeld.Part1 = upperTorso
					parachuteWeld.C0 = CFrame.new(0, 0, -1.5)
					parachuteWeld.Parent = upperTorso
				end
			else
				local playerParachute = game.Workspace.Debris:FindFirstChild(player.Name.."Parachute")
				if playerParachute then
					playerParachute:Destroy()
				end
				local playerParachuteWeld = upperTorso:FindFirstChild("ParachuteWeld")
				if playerParachuteWeld then
					playerParachuteWeld:Destroy()
				end
				local playerParachuteBodyForce = upperTorso:FindFirstChild("ParachuteForce")
				if playerParachuteBodyForce then
					playerParachuteBodyForce:Destroy()
				end
			end
		end
	end
end)

