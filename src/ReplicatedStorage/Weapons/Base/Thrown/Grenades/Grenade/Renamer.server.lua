local parent = script.Parent

parent.AncestryChanged:Connect(function (child, par)
	if child == parent and par.Name == "Backpack" then
		parent.Name = "Thrown"
	end
end)