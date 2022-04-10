-- Services
local RunService = game:GetService("RunService")

-- Gamemode status
local gamemode = game.Workspace:WaitForChild("Status"):WaitForChild("Gamemode")

-- Oil rig billboard GUIs
local oilRigs = {game.Workspace:WaitForChild("Map"):WaitForChild("OilRigs"):WaitForChild("OilRig1"):WaitForChild("Range"):WaitForChild("Info"), 
		   		 game.Workspace:WaitForChild("Map"):WaitForChild("OilRigs"):WaitForChild("OilRig2"):WaitForChild("Range"):WaitForChild("Info"), 
		   		 game.Workspace:WaitForChild("Map"):WaitForChild("OilRigs"):WaitForChild("OilRig3"):WaitForChild("Range"):WaitForChild("Info")}

-- Screen GUIs
local oilRigsUI = {script.Parent:WaitForChild("OilRig1"),
				   script.Parent:WaitForChild("OilRig2"),
				   script.Parent:WaitForChild("OilRig3")}

local function updateMonopolyGUI()
	for i = 1, #oilRigs do
		oilRigsUI[i].RigName.Visible = oilRigs[i].RigName.Visible
		oilRigsUI[i].ImageColor3 = oilRigs[i].RigName.BackgroundColor3
		oilRigsUI[i].Alpha.Visible = oilRigs[i].Alpha.Visible
		oilRigsUI[i].Alpha.ProgressTop.Size = oilRigs[i].Alpha.ProgressTop.Size
		oilRigsUI[i].Bravo.Visible = oilRigs[i].Bravo.Visible
		oilRigsUI[i].Bravo.ProgressTop.Size = oilRigs[i].Bravo.ProgressTop.Size
	end
end

local updateMonopolyGUIConn

local function gamemodeChanged(newGamemode)
	if updateMonopolyGUIConn then
		updateMonopolyGUIConn:Disconnect()
	end
	
	local isMonopoly = newGamemode == "Monopoly"
	script.Parent.Visible = isMonopoly
	updateMonopolyGUIConn = isMonopoly and RunService.RenderStepped:Connect(updateMonopolyGUI) or nil
end

gamemode.Changed:Connect(gamemodeChanged)
gamemodeChanged(gamemode.Value)