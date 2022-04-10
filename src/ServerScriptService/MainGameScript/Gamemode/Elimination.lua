local Elimination = setmetatable({}, require(script.Parent))

-- [[ Static Values ]] --
Elimination.Name = "Elimination"
Elimination.Codename = "ELIM"
Elimination.Description = "Get as many KOs as you can!\nThe team with the most KOs wins!"

-- [[ Public Functions ]] --
function Elimination:Initialize()
	getmetatable(Elimination):Initialize()
end

function Elimination:Update()
	return
end

function Elimination:Finalize()
	return
end

function Elimination:IsRoundOver()
	return false
end

function Elimination:GetWinningTeam()
	return
end

return Elimination
