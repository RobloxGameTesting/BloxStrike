--!native
local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
game:GetService("Workspace")
local grenadeParticles = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GrenadeParticles")
local innerFire = grenadeParticles:WaitForChild("InnerFire")
local outerFire = grenadeParticles:WaitForChild("OuterFire")
local v = {}

local function FlatDistance(position: Vector3, vector: Vector3) -- 3 equivalent calls inferred from this helper
	return (Vector3.new(position.X, 0, position.Z) - Vector3.new(vector.X, 0, vector.Z)).Magnitude
end

local function GetCenter(voxels) -- 2 equivalent calls inferred from this helper
	local vector = createVector(0, 0, 0)

	for _, v2 in ipairs(voxels) do
		vector += v2.Position
	end

	if #voxels > 0 then
		vector /= #voxels
	end

	return vector
end

local function DisableEmitters(instance)
	for _, part in ipairs(instance:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		for _, emitter in ipairs(part:GetDescendants()) do
			if emitter:IsA("ParticleEmitter") then
				emitter.Enabled = false
			end
		end
	end
end

local function GetSurfaceCFrame(position: Vector3, vector: Vector3)
	local unit = vector.Unit

	if math.abs(unit.Y) > 0.99 then
		return CFrame.new(position)
	end

	local unit2

	if math.abs(unit.X) >= math.abs(unit.Z) then
		unit2 = Vector3.new(unit.X, unit.Y, 0).Unit
	else
		unit2 = Vector3.new(0, unit.Y, unit.Z).Unit
	end

	local vector2 = Vector3.new(unit2.X, 0, unit2.Z)

	if vector2.Magnitude < 0.01 then
		return CFrame.new(position)
	end

	local unit3 = vector2.Unit
	local vector3 = Vector3.new(unit3.Z, 0, -unit3.X)
	local unit4 = vector3:Cross(unit2).Unit
	return CFrame.fromMatrix(position, vector3, unit2, -unit4)
end

local function CreateVoxel(position: Vector3, sizeX: number, sizeZ: number, normal: Vector3, flag: boolean, parent)
	local clone = (flag and innerFire or outerFire):Clone()
	clone.Name = flag and "InnerFireVoxel" or "OuterFireVoxel"
	clone.Size = Vector3.new(sizeX, 0.2, sizeZ)
	clone.CFrame = GetSurfaceCFrame(position, normal)
	clone.Anchored = true
	clone.CanCollide = false
	clone.CanQuery = false
	clone.CanTouch = false
	clone.CastShadow = false
	clone.Parent = parent

	for _, emitter in ipairs(clone:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Enabled = true
		end
	end

	return clone
end

local CreateVoxelFire = {}

function CreateVoxelFire:Create()
	debug.profilebegin("VFX.VoxelFire.Create")
	local folder = Instance.new("Folder")
	folder.Name = "VoxelFire_" .. self.FireId
	v[self.FireId] = folder
	debug.profilebegin("VFX.VoxelFire.Create.CalculateCenter")
	local vector = GetCenter(self.Voxels) -- inferred equivalent call
	debug.profileend()
	local identity = CFrame.identity
	debug.profilebegin("VFX.VoxelFire.Create.CreateVoxels")
	local v2 = 1e999
	local v3 = nil
	local size = createVector(0, 0, 0)

	for _, voxel in ipairs(self.Voxels) do
		local v4 = FlatDistance(voxel.Position, vector) <= 4 -- inferred equivalent call
		local voxel2 = CreateVoxel(voxel.Position, voxel.SizeX, voxel.SizeZ, voxel.Normal, v4, folder)
		local vector2 = FlatDistance(voxel.Position, self.Position) -- inferred equivalent call

		if not (vector2 < v2) then
			continue
		end

		size = voxel2.Size
		identity = voxel2.CFrame
		v3 = voxel2
		v2 = vector2
	end

	folder.Parent = workspace:WaitForChild("Debris")
	debug.profileend()

	if v3 then
		debug.profilebegin("VFX.VoxelFire.Create.LandingBurstTween")
		local vector2 = Vector3.new(size.X, 10, size.Z)
		local cframe = identity + identity.UpVector * ((vector2.Y - size.Y) / 2)
		v3.Size = vector2
		v3.CFrame = cframe
		TweenService:Create(v3, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = size,
			CFrame = identity
		}):Play()
		debug.profileend()
	end

	task.delay(self.Duration, function()
		if v[self.FireId] then
			CreateVoxelFire.Destroy(self.FireId)
		end
	end)
	debug.profileend()
end

function CreateVoxelFire.Destroy(p: string)
	debug.profilebegin("VFX.VoxelFire.Destroy")
	local v2 = v[p]

	if v2 then
		DisableEmitters(v2)
		task.delay(2, function()
			if v2.Parent then
				v2:Destroy()
			end
		end)
		v[p] = nil
	end

	debug.profileend()
end

function CreateVoxelFire.Update(p)
	debug.profilebegin("VFX.VoxelFire.Update")
	local parent2 = v[p.FireId]

	if not parent2 then
		debug.profileend()
		return
	end

	DisableEmitters(parent2)
	task.delay(0.3, function()
		debug.profilebegin("VFX.VoxelFire.Update.DelayedRebuild")

		if not parent2.Parent then
			debug.profileend()
			return
		end

		for _, part in ipairs(parent2:GetChildren()) do
			if part:IsA("BasePart") then
				part:Destroy()
			end
		end

		if #p.Voxels == 0 then
			debug.profileend()
			return
		end

		local vector = GetCenter(p.Voxels) -- inferred equivalent call
		local parent = parent2.Parent
		parent2.Parent = nil

		for _, voxel in ipairs(p.Voxels) do
			local v2 = FlatDistance(voxel.Position, vector) <= 4 -- inferred equivalent call
			CreateVoxel(voxel.Position, voxel.SizeX, voxel.SizeZ, voxel.Normal, v2, parent2)
		end

		parent2.Parent = parent
		debug.profileend()
	end)
	debug.profileend()
end

function CreateVoxelFire.DestroyAll()
	debug.profilebegin("VFX.VoxelFire.DestroyAll")

	for k, v2 in pairs(v) do
		if v2.Parent then
			v2:Destroy()
		end

		v[k] = nil
	end

	debug.profileend()
end

return CreateVoxelFire