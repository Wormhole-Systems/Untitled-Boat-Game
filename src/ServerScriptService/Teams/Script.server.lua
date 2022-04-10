local codenameFolder = game:GetService("ReplicatedStorage"):WaitForChild("GenerateCodename")
local funcRemote = codenameFolder.GenerateCodenameRemote
local funcBind = codenameFolder.GenerateCodename

local _PREFIXES = "Jumping Laughing Solid Screaming Crying Sneezing Raging Psycho Venom Punished Cyborg Stupid Fat Jelly Liquid Solidus Big Ghost"
local _ROOTS = "Cactus Snake Ocelot Mama Boss Octopus Mantis Wolf Raven Ninja Bear Koala Hawk Platypus Beaver Ghost Echidna"

local prefixes = {}
for word in _PREFIXES:gmatch("%w+") do table.insert(prefixes, word) end

local roots = {}
for word in _ROOTS:gmatch("%w+") do table.insert(roots, word) end

local function generateCodename()
	local rand = Random.new()
	local prefixIndex = rand:NextInteger(1, #prefixes)
	local rootIndex = rand:NextInteger(1, #roots)
	return prefixes[prefixIndex].." ".. roots[rootIndex]
end

funcRemote.OnServerInvoke = function (player)
	return generateCodename()
end

funcBind.OnInvoke = function (player)
	return generateCodename()
end