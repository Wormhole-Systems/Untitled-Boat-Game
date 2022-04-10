local player = game.Players.LocalPlayer
local char = player.Character

local nameTag = script.Parent.NameDisplay
local maxHealthbar = script.Parent.Health
local healthbar = maxHealthbar.HealthBar
local healthNum = maxHealthbar.HealthNumber

nameTag.Text = player.Name

local function resetHealthbar(humanoid)
	local newH = humanoid.Health
	local max = humanoid.MaxHealth
	healthNum.Text = newH
	healthbar:TweenSize(
		UDim2.new(
			UDim.new(
				math.max(newH/max - 2 * healthbar.Position.X.Scale, 0), 0),
			healthbar.Size.Y), 
		Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, .1, true, nil)
end

local function charAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	resetHealthbar(humanoid)
	humanoid.HealthChanged:Connect(function ()
		resetHealthbar(humanoid)
	end)
	
end

player.CharacterAdded:Connect(charAdded)
charAdded(player.Character)