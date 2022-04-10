local NauticalVehicle = require(script.Parent)

local Submarine = {}
Submarine.__index = Submarine
setmetatable(Submarine, NauticalVehicle)

-- Services
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")

-- Micro-Optimizations
local clamp = math.clamp

function Submarine.new(model)
	local newSubmarine = NauticalVehicle.new(model)
	setmetatable(newSubmarine, Submarine)
	
	-- Submarine specific attributes
	newSubmarine.Name = "Submarine"
	newSubmarine.CurrentAltitude = -5
	newSubmarine.MinAltitude = -140
	newSubmarine.MaxAltitude = 0
	newSubmarine.Direction = 0
	newSubmarine.ForwardRotationDirection = 0
	newSubmarine:HandleAltitudeAdjustment()
	
	newSubmarine.Engine:FindFirstChildOfClass("Sound"):Play()
	
	return newSubmarine
end

function Submarine:IncreaseAltitude()
	self.CurrentAltitude = clamp(self.CurrentAltitude + 0.25, self.MinAltitude, self.MaxAltitude)
end

function Submarine:DecreaseAltitude()
	self.CurrentAltitude = clamp(self.CurrentAltitude - 0.25, self.MinAltitude, self.MaxAltitude)
end

function Submarine:HandleAltitudeAdjustment()
	-- Handle changes in altitude
	local function changeAltitude(direction)
		-- Ensure that the player calling the event is the one sitting in the pilot's seat
		if self.CurrentDriver then
			self.Direction = direction
			if direction == 1 then -- if instructed to go upwards
				-- Increase altitude while up key is down
				while self.Direction == 1 and self.DriverSeat.Occupant do
					self:IncreaseAltitude()
					wait()
				end
			elseif direction == -1 then -- if instructed to go downwards
				-- Decrease altitude while down key is down
				while self.Direction == -1 and self.DriverSeat.Occupant do
					self:DecreaseAltitude()
					wait()
				end
			else -- If player let go of up or down key
				self.CurrentAltitude = self.Engine.CFrame.Position.Y -- maintain current altitude
			end
		end
	end
	UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent and input.KeyCode ~= Enum.KeyCode.E then return end
		if input.KeyCode == Enum.KeyCode.Q then
			changeAltitude(-1)
		elseif input.KeyCode == Enum.KeyCode.E then
			changeAltitude(1)
		end
	end)
	UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent and input.KeyCode ~= Enum.KeyCode.E then return end
		if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
			changeAltitude(0)
		end
	end)
end

return Submarine