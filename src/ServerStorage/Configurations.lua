local Configurations = {}

local isStudio = game:GetService("RunService"):IsStudio()

-- [[ General ]]--
Configurations.ROUND_DURATION = 5 * 60 								-- Seconds
Configurations.RESPAWN_TIME = 5 									-- Seconds
Configurations.MIN_PLAYERS = isStudio and 1 or 2 					-- 1 in studio testing, 2 in actual game
Configurations.INTERMISSION_DURATION = isStudio and 10 or 15 		-- 5 seconds in studio testing, 15 in actual game
Configurations.END_GAME_WAIT = isStudio and 5 or 10					-- 5 seconds in studio testing, 10 in actual game

-- [[ Capture the Flag ]] --
Configurations.ROUND_DURATION_CTF = 5 * 60							-- Seconds
Configurations.CAPS_TO_WIN = 3
Configurations.REQUIRE_RETURN_BEFORE_CAP = true
Configurations.FLAG_RESPAWN_TIME = 15 								-- Seconds
Configurations.RETURN_FLAG_ON_DROP = false
Configurations.FLAG_RETURN_ON_TOUCH = true

-- [[ Monopoly ]] --
Configurations.ROUND_DURATION_KOTH = 5 * 60							-- Seconds
Configurations.CAPTURE_SPEED_PER_PLAYER = 1
Configurations.REQUIRED_AMOUNT_TO_CAPTURE = isStudio and 100 or 1000
Configurations.MAX_OIL_TO_WIN = 1000

return Configurations
