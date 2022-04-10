local MapManager = {}

-- [[ Local Variables ]] --
local mapSave = Instance.new('Folder')
mapSave.Name = 'MapSave'
mapSave.Parent = game.ServerStorage

-- [[ Functions ]] --
function MapManager:SaveMap()
	for _, child in pairs(game.Workspace.Map:GetChildren()) do
		if not child:IsA('Camera') and not child:IsA("Terrain") 
		   and not child.Name == "FlagStandAlpha" and not child.Name == "FlagStandBravo" then
			local copy = child:Clone()
			if copy then
				copy.Parent = mapSave
			end	
		end
	end
end

function MapManager:ClearMap()
	for _, child in pairs(game.Workspace.Map:GetChildren()) do
		if not child:IsA('Camera') and not child:IsA("Terrain") then
			child:Destroy()
		end
	end
end

function MapManager:LoadMap()
	spawn(function()
		for _, child in pairs(mapSave:GetChildren()) do
			local copy = child:Clone()
			copy.Parent = game.Workspace
		end
	end)
end
	
return MapManager
