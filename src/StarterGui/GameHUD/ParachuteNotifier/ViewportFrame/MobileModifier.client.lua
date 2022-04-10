if not game:GetService("UserInputService").KeyboardEnabled then -- if user is on mobile
	-- get rid of the E key notifier and re-center the parachute model
	script.Parent:WaitForChild("Note"):Destroy()
	script.Parent:WaitForChild("Parachute").Position = Vector3.new(0, 2.5, 0)
end
script:Destroy()