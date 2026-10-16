--!native
local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local smoke = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GrenadeParticles"):WaitForChild("Smoke")
local v = {
	Terrorists = Color3.fromRGB(185, 170, 145),
	["Counter-Terrorists"] = Color3.fromRGB(155, 170, 190)
}
local v2 = {}
local v3 = {}
local v4 = {}
local v5 = {}
local connection = nil

local function StopEmitterLoop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function StartEmitterLoop() -- 1 equivalent call inferred from this helper
	if connection then
		return
	end

	connection = RunServiceController.BindToHeartbeat("VFX.CreateVoxelSmoke.Emitters", function()
		local now = tick()

		for k, v6 in pairs(v5) do
			if k.Parent and v6.isActive and not v6.emissionStopped then
				if not v6.lifetimeExtended then
					v6.lifetimeExtended = true
					v6.activatedTime = now

					for _, emitter in ipairs(v6.emitters) do
						if emitter and emitter.Parent then
							emitter.Lifetime = NumberRange.new(1e999)
						end
					end
				end

				local v7 = now - v6.activatedTime

				if v7 >= 0.8 then
					v6.emissionStopped = true
					v5[k] = nil
				elseif not (0.1 + 0.30000000000000004 * (v7 / 0.8) > now - v6.lastEmitTime) then
					v6.lastEmitTime = now

					for _, emitter in ipairs(v6.emitters) do
						if emitter and emitter.Parent then
							emitter:Emit(1)
						end
					end
				end
			else
				v5[k] = nil
			end
		end

		if next(v5) == nil and connection then
			connection:Disconnect()
			connection = nil
		end
	end)
end

local function SetVoxelEmitting(p, flag: boolean) -- 3 equivalent calls inferred from this helper
	local voxel = p.voxel

	if flag then
		v5[voxel] = p
		StartEmitterLoop() -- inferred equivalent call
	else
		v5[voxel] = nil

		if next(v5) == nil and connection then
			connection:Disconnect()
			connection = nil
		end
	end
end

local function RayIntersectsAABB(vector: Vector3, vector2: Vector3, minimum: Vector3, maximum: Vector3, p: number)
	local v6 = 0
	local v7

	if math.abs(vector2.X) < 0.0001 then
		if vector.X < minimum.X or vector.X > maximum.X then
			return false
		else
			v7 = p
		end
	else
		local v8 = 1 / vector2.X
		local v9 = (minimum.X - vector.X) * v8
		local v10 = (maximum.X - vector.X) * v8

		if v10 < v9 then
			v10, v9 = v9, v10
		end

		v6 = math.max(v6, v9)
		v7 = math.min(p, v10)

		if v7 < v6 then
			return false
		end
	end

	if math.abs(vector2.Y) < 0.0001 then
		if vector.Y < minimum.Y or vector.Y > maximum.Y then
			return false
		end
	else
		local v8 = 1 / vector2.Y
		local v9 = (minimum.Y - vector.Y) * v8
		local v10 = (maximum.Y - vector.Y) * v8

		if v10 < v9 then
			v10, v9 = v9, v10
		end

		v6 = math.max(v6, v9)
		v7 = math.min(v7, v10)

		if v7 < v6 then
			return false
		end
	end

	if math.abs(vector2.Z) < 0.0001 then
		if vector.Z < minimum.Z or vector.Z > maximum.Z then
			return false
		end
	else
		local v8 = 1 / vector2.Z
		local v9 = (minimum.Z - vector.Z) * v8
		local v10 = (maximum.Z - vector.Z) * v8

		if v10 < v9 then
			v10, v9 = v9, v10
		end

		v6 = math.max(v6, v9)

		if math.min(v7, v10) < v6 then
			return false
		end
	end

	return v6 <= p
end

local function ConfigureEmitter(p, p2: number, color: Color3?)
	local numberSequenceKeypoints = {}

	for _, keypoint in ipairs(p.Size.Keypoints) do
		table.insert(
			numberSequenceKeypoints,
			NumberSequenceKeypoint.new(keypoint.Time, keypoint.Value * p2, keypoint.Envelope * p2)
		)
	end

	p.Size = NumberSequence.new(numberSequenceKeypoints)

	if color then
		p.Color = ColorSequence.new(color)
	end

	p.Enabled = false
end

local function CreateVoxel(position: Vector3, size: number, folder, color: Color3?)
	local clone = smoke:Clone()
	clone.Name = "SmokeVoxel"
	clone.Size = Vector3.new(size, size, size)
	clone.Position = position
	clone.Anchored = true
	clone.CanCollide = false
	clone.CanQuery = false
	clone.CanTouch = false
	clone.CastShadow = false
	clone.Parent = folder
	local scaleFactor = size / 4
	local emitters = {}

	for _, emitter in ipairs(clone:GetDescendants()) do
		if not emitter:IsA("ParticleEmitter") then
			continue
		end

		ConfigureEmitter(emitter, scaleFactor, color)
		table.insert(emitters, emitter)
	end

	for _, billboardGui in ipairs(clone:GetChildren()) do
		if billboardGui:IsA("BillboardGui") then
			billboardGui:Destroy()
		end
	end

	local halfSize = size / 2
	local vector = Vector3.new(halfSize, halfSize, halfSize)
	v3[clone] = {
		voxel = clone,
		emitters = emitters,
		isActive = false,
		lastEmitTime = 0,
		scaleFactor = scaleFactor,
		teamColor = color,
		lifetimeExtended = false,
		activatedTime = 0,
		emissionStopped = false,
		minimum = position - vector,
		maximum = position + vector
	}
	return clone
end

local function DestroyVoxels(children)
	for _, part in ipairs(children) do
		if not part:IsA("BasePart") then
			continue
		end

		v4[part] = nil
		v5[part] = nil
		v3[part] = nil
		part:Destroy()
	end
end

local function DeploySmoke(folder, deployTime: number)
	debug.profilebegin("VFX.VoxelSmoke.DeploySmoke")
	local vector = createVector(0, 0, 0)
	local parts = {}

	for _, part in ipairs(folder:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		vector += part.Position
		table.insert(parts, part)
	end

	if #parts == 0 then
		debug.profileend()
		return
	end

	local vector2 = vector / #parts
	local v6 = 0

	for _, v7 in ipairs(parts) do
		local magnitude = (v7.Position - vector2).Magnitude

		if v6 < magnitude then
			v6 = magnitude
		end
	end

	local v7 = v6 == 0 and 1 or v6

	for _, v8 in ipairs(parts) do
		local v9 = (v8.Position - vector2).Magnitude / v7 * deployTime
		local v10 = v8
		task.delay(v9, function()
			if not v10.Parent then
				return
			end

			local v11 = v3[v10]

			if v11 then
				v11.isActive = true
				v4[v10] = v11
				local voxel = v11.voxel
				v5[voxel] = v11

				if connection then
					return
				else
					connection = RunServiceController.BindToHeartbeat("VFX.CreateVoxelSmoke.Emitters", function()
						local now = tick()

						for k, v12 in pairs(v5) do
							if k.Parent and v12.isActive and not v12.emissionStopped then
								if not v12.lifetimeExtended then
									v12.lifetimeExtended = true
									v12.activatedTime = now

									for _, emitter in ipairs(v12.emitters) do
										if emitter and emitter.Parent then
											emitter.Lifetime = NumberRange.new(1e999)
										end
									end
								end

								local v13 = now - v12.activatedTime

								if v13 >= 0.8 then
									v12.emissionStopped = true
									v5[k] = nil
								elseif not (0.1 + 0.30000000000000004 * (v13 / 0.8) > now - v12.lastEmitTime) then
									v12.lastEmitTime = now

									for _, emitter in ipairs(v12.emitters) do
										if emitter and emitter.Parent then
											emitter:Emit(1)
										end
									end
								end
							else
								v5[k] = nil
							end
						end

						if next(v5) == nil and connection then
							connection:Disconnect()
							connection = nil
						end
					end)
				end
			end
		end)
	end

	debug.profileend()
end

local function FadeOutSmoke(instance)
	debug.profilebegin("VFX.VoxelSmoke.FadeOutSmoke")
	local children = instance:GetChildren()

	for _, part in ipairs(children) do
		if not part:IsA("BasePart") then
			continue
		end

		local v6 = v3[part]

		if not v6 then
			continue
		end

		v6.isActive = false
		v4[part] = nil
		SetVoxelEmitting(v6, false) -- inferred equivalent call

		for _, emitter in ipairs(v6.emitters) do
			if emitter and emitter.Parent then
				emitter.Enabled = false
			end
		end
	end

	task.delay(6, function()
		debug.profilebegin("VFX.VoxelSmoke.FadeOutSmoke.DelayedCleanup")
		DestroyVoxels(children)

		if next(v5) == nil and connection then
			connection:Disconnect()
			connection = nil
		end

		if instance.Parent then
			instance:Destroy()
		end

		debug.profileend()
	end)
	debug.profileend()
end

local CreateVoxelSmoke = {}

function CreateVoxelSmoke.Create(data)
	debug.profilebegin("VFX.VoxelSmoke.Create")
	local folder = Instance.new("Folder")
	folder.Name = "VoxelSmoke_" .. data.SmokeId
	v2[data.SmokeId] = folder
	local teamColor = data.Team and v[data.Team]
	debug.profilebegin("VFX.VoxelSmoke.Create.CreateVoxels")

	for _, voxel in ipairs(data.Voxels) do
		CreateVoxel(voxel.Position, voxel.Size, folder, teamColor)
	end

	debug.profileend()
	folder.Parent = Workspace:WaitForChild("Debris")
	DeploySmoke(folder, data.DeployTime)
	task.delay(data.Duration, function()
		if v2[data.SmokeId] then
			FadeOutSmoke(folder)
			v2[data.SmokeId] = nil
		end
	end)
	debug.profileend()
end

function CreateVoxelSmoke:Destroy()
	debug.profilebegin("VFX.VoxelSmoke.Destroy")
	local v6 = v2[self]

	if v6 then
		FadeOutSmoke(v6)
		v2[self] = nil
	end

	debug.profileend()
end

function CreateVoxelSmoke.DestroyAll()
	debug.profilebegin("VFX.VoxelSmoke.DestroyAll")

	for k, v6 in pairs(v2) do
		DestroyVoxels(v6:GetChildren())
		v6:Destroy()
		v2[k] = nil
	end

	if next(v5) == nil and connection then
		connection:Disconnect()
		connection = nil
	end

	debug.profileend()
end

function CreateVoxelSmoke.Disrupt(vector: Vector3, p: number, duration: number)
	debug.profilebegin("VFX.VoxelSmoke.Disrupt")

	for _, v6 in pairs(v2) do
		for _, part in ipairs(v6:GetChildren()) do
			if not part:IsA("BasePart") or p < (part.Position - vector).Magnitude then
				continue
			end

			local v7 = v3[part]

			if not (v7 and v7.isActive) then
				continue
			end

			v7.isActive = false
			v4[part] = nil
			SetVoxelEmitting(v7, false) -- inferred equivalent call
			local scaleFactor = v7.scaleFactor

			for _, emitter in ipairs(v7.emitters) do
				if emitter and emitter.Parent then
					emitter:Destroy()
				end
			end

			v7.emitters = {}
			local teamColor = v7.teamColor
			local parent = part
			task.delay(duration, function()
				debug.profilebegin("VFX.VoxelSmoke.Disrupt.RestoreEmitters")

				if not (v3[parent] and parent.Parent) then
					debug.profileend()
					return
				end

				local clones = {}

				for _, emitter in ipairs(smoke:GetDescendants()) do
					if not emitter:IsA("ParticleEmitter") then
						continue
					end

					local clone = emitter:Clone()
					ConfigureEmitter(clone, scaleFactor, teamColor)
					clone.Parent = parent
					table.insert(clones, clone)
				end

				v7.emitters = clones
				v7.lastEmitTime = 0
				v7.isActive = true
				v7.lifetimeExtended = false
				v7.activatedTime = 0
				v7.emissionStopped = false
				v4[parent] = v7
				SetVoxelEmitting(v7, true) -- inferred equivalent call
				debug.profileend()
			end)
		end
	end

	debug.profileend()
end

function CreateVoxelSmoke.DoesRayIntersectActiveSmoke(vector: Vector3, vector2: Vector3, p: number)
	for _, v6 in pairs(v4) do
		if RayIntersectsAABB(vector, vector2, v6.minimum, v6.maximum, p) then
			return true
		end
	end

	return false
end

return CreateVoxelSmoke