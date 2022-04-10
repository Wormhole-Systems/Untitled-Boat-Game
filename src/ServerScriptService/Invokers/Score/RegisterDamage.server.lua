
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local clamp = math.clamp

local func = ServerStorage.Invokers.Score.RegisterDamageServer
local remoteFunc = ReplicatedStorage.Invokers.Score.RegisterDamage

local registerKill = ServerStorage.Invokers.Score.RegisterKillServer

--hitter and hittee are models
func.Event:Connect(function(hitter, hittee, weapon, location, damage)
	local hitterPlayer 
	if hitter:IsA("Player") then
		hitterPlayer = hitter 
	else 
		hitterPlayer = Players:GetPlayerFromCharacter(hitter)
	end
		
	local huma = hittee:FindFirstChildOfClass("Humanoid")
	if huma then
		local wasAlive = huma.Health > 0
		local oldHealth = huma.Health
				
		local vPlayer
		if hittee:IsA("Player") then
			vPlayer = hittee
		else 
			vPlayer = Players:GetPlayerFromCharacter(hittee)
		end		
		
		if hitterPlayer then 
			remoteFunc:FireClient(hitterPlayer, hitterPlayer, vPlayer, weapon, location, damage)
		end
		if vPlayer then
			remoteFunc:FireClient(vPlayer, hitterPlayer, vPlayer, weapon, location, damage)
		end
		
		huma:TakeDamage(damage)
		--make sure the kill register only fires on a fresh death
		if huma.Health <= 0 and wasAlive then
			registerKill:Fire(hitterPlayer or hitter, vPlayer or hittee, weapon)
		end	
	else -- For vehicle damage
		
		local configFolder
		while hittee ~= game.Workspace do
			if hittee:FindFirstChild("TurretBase") then
				configFolder = hittee:FindFirstChild("Configuration")
				break
			elseif hittee.Parent == game.Workspace.Vehicles then
				configFolder = hittee:FindFirstChild("Configuration")
				break
			end
			hittee = hittee.Parent
		end
		
		if hitterPlayer and configFolder and configFolder:FindFirstChild("Owner") and configFolder.Owner.Value and configFolder.Owner.Value.TeamColor ~= hitterPlayer.TeamColor then
			--print("sent signal to damage", takeDamageEvent.Parent.Name, "by", self.Damage, "hp")
			configFolder.CurrentHealth.Value = clamp(configFolder.CurrentHealth.Value - damage, 0, configFolder.MaxHealth.Value)
		end
	end
end)
