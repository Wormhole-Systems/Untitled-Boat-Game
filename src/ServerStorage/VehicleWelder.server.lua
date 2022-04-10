local function weldBetween(a, b)
	local weld = Instance.new("Weld")
	weld.Name = a.Name..b.Name.."Weld"
	weld.C0 = a.CFrame:inverse() * b.CFrame
	weld.Part0 = a
	weld.Part1 = b	
	weld.Parent = a
	return weld
end

local vehicle = game.Workspace["Parachute"]
for _, v in pairs(vehicle:GetDescendants()) do
	if v:IsA("BasePart") and v ~= vehicle.PrimaryPart then
		v.Anchored = false
		weldBetween(v, vehicle.PrimaryPart)
	end
end

-- [[ General Welder ]] --
local function weldBetween(a, b)
	local weld = Instance.new("Weld")
	weld.Name = a.Name..b.Name.."Weld"
	weld.C0 = a.CFrame:inverse() * b.CFrame
	weld.Part0 = a
	weld.Part1 = b	
	weld.Parent = a
	return weld
end
weldBetween(game.Workspace["Submarine"].Particle, game.Workspace["Submarine"].Hull)

local model = game.Workspace.Fins
local main = game.Workspace.Submarine.Rotor
for _, v in pairs(model:GetDescendants()) do
	if v:IsA("BasePart") then
		v.Anchored = false
		weldBetween(v, main)
	end
end