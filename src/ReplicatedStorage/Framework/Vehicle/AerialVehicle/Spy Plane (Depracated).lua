--[[
	NOTE: Due to its substantial differences from other vehicles (such has having mouse-based movement, 
	  	  BodyGyro behavioral differences), this class does not inherit from Vehicle or AerialVehicle. 
		  However, it is still placed under AerialVehicle in the vehicle framework hierarchy for 
		  organizational purposes only.
--]]

local SpyPlane = {}
SpyPlane.__index = SpyPlane

function SpyPlane.new(model)
	local newSpyPlane = {}
	setmetatable(newSpyPlane, SpyPlane)
	
	newSpyPlane.Name = "Spy Plane"
	
	-- Class Attributes
	newSpyPlane.Model = model
		
	return newSpyPlane
end

function SpyPlane:Initialize()
	
end

--------------------------------
--[[ Helper Functions Below ]]--
--------------------------------

function SpyPlane:Destroy(shouldDestroyModel)
	if shouldDestroyModel then
		self.Model:Destroy()
	end
	self = nil
end

function SpyPlane:Move(pilotInSeat, direction)

end

function SpyPlane:Accelerate()
	
end

function SpyPlane:Decelerate()
	
end

function SpyPlane:Stop()
	
end

function SpyPlane:HandleEvents()
	
end

return SpyPlane