local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local other = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Other")
local debris = workspace:WaitForChild("Debris")

local function getNumberAttribute(instance, attributeName: string, p: number)
	local attribute = instance:GetAttribute(attributeName)

	if typeof(attribute) == "number" then
		return attribute
	end

	return p
end

local function getBeamUpVector(unit: Vector3, upVector: Vector3)
	local v = upVector - unit * upVector:Dot(unit)

	if v.Magnitude <= 0.001 then
		v = createVector(0, 1, 0) - unit * (createVector(0, 1, 0)):Dot(unit)
	end

	if v.Magnitude <= 0.001 then
		v = createVector(0, 0, 1) - unit * (createVector(0, 0, 1)):Dot(unit)
	end

	return v.Unit
end

local function getBeamCleanupTime(folder)
	local v = 5

	for _, emitter in ipairs(folder:GetDescendants()) do
		if not emitter:IsA("ParticleEmitter") then
			continue
		end

		local emitDelay = emitter:GetAttribute("EmitDelay")
		v = math.max(v, (typeof(emitDelay) ~= "number" and 0 or emitDelay) + math.max(emitter.Lifetime.Max, 1) + 1)
	end

	return v
end

return function(instance)
	local zeusBeam = other:FindFirstChild("ZeusBeam")

	if not (zeusBeam and zeusBeam:IsA("BasePart")) then
		return nil
	end

	local lookVector = instance.CFrame.LookVector

	if lookVector.Magnitude <= 0.001 then
		return nil
	end

	local unit = lookVector.Unit
	local clone = zeusBeam:Clone()
	clone.CollisionGroup = "Debris"
	clone.CanCollide = false
	clone.CanQuery = false
	clone.CanTouch = false
	clone.Anchored = true
	local v = instance.Position + unit * (clone.Size.X * 0.5)
	local beamUpVector = getBeamUpVector(unit, instance.CFrame.UpVector)
	clone.CFrame = CFrame.fromMatrix(v, unit, beamUpVector)
	clone.Parent = debris

	for _, emitter in ipairs(clone:GetDescendants()) do
		if not emitter:IsA("ParticleEmitter") then
			continue
		end

		local emitDelay = emitter:GetAttribute("EmitDelay")
		local v2 = typeof(emitDelay) ~= "number" and 0 or emitDelay
		local v3 = emitter
		task.delay(v2, function()
			if not v3.Parent then
				return
			end

			local emitCount = v3:GetAttribute("EmitCount")
			local v4 = typeof(emitCount) ~= "number" and 0 or emitCount

			if v4 > 0 then
				v3:Emit(v4)
				return
			end

			v3.Enabled = true
			task.delay(0.15, function()
				if v3.Parent then
					v3.Enabled = false
				end
			end)
		end)
	end

	Debris:AddItem(clone, (getBeamCleanupTime(clone)))
	return clone
end