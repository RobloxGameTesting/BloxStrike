local createVector = vector.create
return function(list, instance)
	local clones = {}

	for _, part in ipairs(list) do
		if not part:IsA("BasePart") then
			continue
		end

		local child = instance:FindFirstChild(part.Name)

		if not child then
			continue
		end

		local scales = part:FindFirstChild("Scales")
		local offsets = part:FindFirstChild("Offsets")
		local rotations = part:FindFirstChild("Rotations")
		local camera = scales and scales:FindFirstChild("Camera")
		local camera2 = offsets and offsets:FindFirstChild("Camera")
		local camera3 = rotations and rotations:FindFirstChild("Camera")
		local value = camera and camera.Value
		local value2 = camera2 and camera2.Value or createVector(0, 0, 0)
		local value3 = camera3 and camera3.Value or createVector(0, 0, 0)
		local vector = Vector3.new(math.rad(value3.X), math.rad(value3.Y), (math.rad(value3.Z)))
		local clone = part:Clone()
		clone.CastShadow = false
		clone.CanCollide = false
		clone.CanTouch = false
		clone.Anchored = true
		clone.CanQuery = false
		clone.Name = "Glove"
		local scales2 = clone:FindFirstChild("Scales")
		local offsets2 = clone:FindFirstChild("Offsets")
		local rotations2 = clone:FindFirstChild("Rotations")

		if scales2 then
			scales2:Destroy()
		end

		if offsets2 then
			offsets2:Destroy()
		end

		if rotations2 then
			rotations2:Destroy()
		end

		clone.Size = Vector3.new(
			child.Size.X * (not value and 1 or value.X or 1),
			child.Size.Y * (not value and 1 or value.Y or 1),
			child.Size.Z * (value and value.Z or 1)
		)
		local v = child.Size.Z / 2 - clone.Size.Z / 2
		local v2 = CFrame.new(value2) * CFrame.new(0, 0, -v * 1.035) * clone.PivotOffset * CFrame.Angles(vector.X, vector.Y, vector.Z)
		clone.Parent = child
		local weldConstraint = Instance.new("WeldConstraint", clone)
		weldConstraint.Part0 = child
		weldConstraint.Part1 = clone
		clone.CFrame = child.CFrame * v2
		clone.Anchored = false
		table.insert(clones, clone)
	end

	return clones
end