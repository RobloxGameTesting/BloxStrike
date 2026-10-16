local createVector = vector.create
local Enums = require(script.Parent.Parent.Enums)
local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
require(script.Parent.Parent.Simulation.Types)
local v = {}

local function isFiniteNumber(value) -- 4 equivalent calls inferred from this helper
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

local function isFiniteVector3(data) -- 1 equivalent call inferred from this helper
	local v2

	if typeof(data) == "Vector3" then
		local x = data.X

		if typeof(x) == "number" and x == x and x > -1e999 then
			v2 = x < 1e999
		else
			v2 = false
		end

		if v2 then
			local y = data.Y

			if typeof(y) == "number" and y == y and y > -1e999 then
				v2 = y < 1e999
			else
				v2 = false
			end

			if v2 then
				local z = data.Z

				if typeof(z) == "number" and z == z and z > -1e999 then
					return z < 1e999
				else
					return false
				end
			end
		end
	else
		return false
	end

	return v2
end

local function isFiniteCFrame(cframe)
	if typeof(cframe) ~= "CFrame" then
		return false
	end

	for _, v2 in { cframe:GetComponents() } do
		if not isFiniteNumber(v2) then -- inferred equivalent call
			return false
		end
	end

	return true
end

local function angularVelocity(previousCFrame: CFrame, cframe: CFrame, p: number)
	local axisAngle, v2 = previousCFrame.Rotation:ToObjectSpace(cframe.Rotation):ToAxisAngle()

	if not isFiniteNumber(v2) or v2 <= 1e-9 then -- inferred equivalent call
		return createVector(0, 0, 0), 0
	end

	local vectorToWorldSpace = previousCFrame:VectorToWorldSpace(axisAngle)
	local magnitude = vectorToWorldSpace.Magnitude

	if magnitude <= 1e-9 then
		return createVector(0, 0, 0), 0
	end

	return vectorToWorldSpace / magnitude * (v2 / p), v2
end

local function makeRecord(instance, value: number)
	assert(Serial.isUInt32(instance.Id) and instance.Id > 0, "mover ID must be a non-zero u32")
	assert(isFiniteCFrame(instance.PreviousCFrame), "mover PreviousCFrame must be finite")
	assert(isFiniteCFrame(instance.CFrame), "mover CFrame must be finite")
	local size = instance.Size
	local v2

	if typeof(size) == "Vector3" then
		local x = size.X

		if typeof(x) == "number" and x == x and x > -1e999 then
			v2 = x < 1e999
		else
			v2 = false
		end

		if v2 then
			local y = size.Y

			if typeof(y) == "number" and y == y and y > -1e999 then
				v2 = y < 1e999
			else
				v2 = false
			end

			if v2 then
				local z = size.Z

				if typeof(z) == "number" and z == z and z > -1e999 then
					v2 = z < 1e999
				else
					v2 = false
				end
			end
		end
	else
		v2 = false
	end

	if v2 then
		if instance.Size.X > 0 and instance.Size.Y > 0 then
			v2 = instance.Size.Z > 0
		else
			v2 = false
		end
	end

	assert(v2, "mover Size must be a finite positive Vector3")
	local surfaceFriction = instance.SurfaceFriction or 1
	assert(
		isFiniteNumber(surfaceFriction) and surfaceFriction >= 0, -- inferred equivalent call
		"mover surface friction must be finite and nonnegative"
	)
	local angularVelocity2, rotationAngle = angularVelocity(instance.PreviousCFrame, instance.CFrame, value)
	return (table.freeze({
		Id = instance.Id,
		Kind = Enums.SupportKind.Mover,
		SourceId = instance.Id,
		PreviousCFrame = instance.PreviousCFrame,
		CFrame = instance.CFrame,
		Size = instance.Size,
		LinearVelocity = (instance.CFrame.Position - instance.PreviousCFrame.Position) / value,
		AngularVelocity = angularVelocity2,
		RotationAngle = rotationAngle,
		BoundingRadius = (instance.Size * 0.5).Magnitude,
		SurfaceFriction = surfaceFriction,
		Pushes = instance.Pushes == true
	}))
end

function v.Build(value: number, list)
	assert(isFiniteNumber(value) and value > 0, "mover-frame delta time must be finite and positive") -- inferred equivalent call
	assert(typeof(list) == "table", "mover inputs must be a table")
	local records = table.create(#list)

	for k, v2 in list do
		records[k] = makeRecord(v2, value)
	end

	table.sort(records, function(a, b)
		return a.Id < b.Id
	end)
	local id = 0
	local byId = {}

	for _, v2 in records do
		assert(id < v2.Id, string.format("duplicate mover ID %d", v2.Id))
		id = v2.Id
		byId[v2.Id] = v2
	end

	table.freeze(records)
	table.freeze(byId)
	return (table.freeze({ Records = records, ById = byId }))
end

function v.SampleCFrame(p, value: number)
	local v2

	if typeof(value) == "number" and value == value and value > -1e999 then
		v2 = value < 1e999
	else
		v2 = false
	end

	if v2 then
		if value >= 0 then
			v2 = value <= 1
		else
			v2 = false
		end
	end

	assert(v2, "invalid mover time fraction")

	if value <= 0 then
		return p.PreviousCFrame
	end

	if value >= 1 then
		return p.CFrame
	end

	return p.PreviousCFrame:Lerp(p.CFrame, value)
end

function v.VelocityAtPoint(p, data: Vector3, value: number?)
	assert(isFiniteVector3(data), "surface point must be a finite Vector3") -- inferred equivalent call
	local cframe = v.SampleCFrame(p, value or 1)
	return p.LinearVelocity + p.AngularVelocity:Cross(data - cframe.Position)
end

function v.ResolveSupportMotion(p, data)
	if data.Kind ~= Enums.SupportKind.Mover or data.SourceId == 0 then
		return nil
	end

	local v2 = p.ById[data.SourceId]

	if v2 == nil then
		return nil
	end

	local pointToWorldSpace = v2.PreviousCFrame:PointToWorldSpace(data.Anchor)
	local pointToWorldSpace2 = v2.CFrame:PointToWorldSpace(data.Anchor)
	return {
		Kind = Enums.SupportKind.Mover,
		SourceId = v2.Id,
		Delta = pointToWorldSpace2 - pointToWorldSpace,
		Velocity = v.VelocityAtPoint(v2, pointToWorldSpace2, 1)
	}
end

return table.freeze(v)