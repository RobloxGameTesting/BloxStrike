local createVector = vector.create
local RunService = game:GetService("RunService")
local cframe = CFrame.Angles(-1.5707963267948966, 0, 0)
local v = { ["Right Arm"] = "RightGlove", ["Left Arm"] = "LeftGlove" }
local v2 = { ["Right Arm"] = "RightHand", ["Left Arm"] = "LeftHand" }

local function applyGloveConfig(clone, motor6D, scales, offsets, rotations)
	local character = scales and scales:FindFirstChild("Character")
	local character2 = offsets and offsets:FindFirstChild("Character")
	local character3 = rotations and rotations:FindFirstChild("Character")
	local size = character and character.Value or createVector(1, 1, 1)
	local value = character2 and character2.Value or createVector(0, 0, -0.025)
	local value2 = character3 and character3.Value or createVector(0, 0, 0)
	local vector = Vector3.new(math.rad(value2.X), math.rad(value2.Y), (math.rad(value2.Z)))
	local v3 = cframe * CFrame.Angles(vector.X, vector.Y, vector.Z)
	clone.Size = size
	motor6D.C0 = CFrame.new(value)
	motor6D.C1 = clone.PivotOffset * v3
end

return function(list, instance, parent, p)
	local clones = {}

	for _, part in ipairs(list) do
		if not part:IsA("BasePart") then
			continue
		end

		local v3 = v2[part.Name]
		local child = v3 and instance:FindFirstChild(v3)

		if not child then
			continue
		end

		local clone = part:Clone()
		clone.Name = v[part.Name]
		clone.CastShadow = false
		clone.CanCollide = false
		clone.CanTouch = false
		clone.Anchored = false
		clone.CanQuery = false
		clone.Massless = true

		if p and p.collisionGroup then
			clone.CollisionGroup = p.collisionGroup
		end

		local rotations = clone:FindFirstChild("Rotations")
		local offsets = clone:FindFirstChild("Offsets")
		local scales = clone:FindFirstChild("Scales")
		local motor6D = Instance.new("Motor6D")
		motor6D.Name = "GloveAttachment"
		motor6D.Part0 = child
		motor6D.Part1 = clone
		motor6D.Parent = clone
		clone.Parent = parent
		applyGloveConfig(clone, motor6D, scales, offsets, rotations)
		local isStudio = RunService:IsStudio()

		for _, v4 in ipairs({
			scales and scales:FindFirstChild("Character"),
			offsets and offsets:FindFirstChild("Character"),
			rotations and rotations:FindFirstChild("Character")
		}) do
			if isStudio then
				v4:GetPropertyChangedSignal("Value"):Connect(function()
					applyGloveConfig(clone, motor6D, scales, offsets, rotations)
				end)
			else
				v4:Destroy()
			end
		end

		table.insert(clones, clone)
	end

	return clones
end