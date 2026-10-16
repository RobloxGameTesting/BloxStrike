local createVector = vector.create
local TopologyConfig = require(script.Parent.TopologyConfig)
local v = {
	IsFiniteVector3 = function(data)
		if typeof(data) ~= "Vector3" then
			return false
		end

		local x = data.X
		local y = data.Y
		local z = data.Z
		return x - x == 0 and y - y == 0 and z - z == 0
	end,
	Min = function(vector: Vector3, vector2: Vector3)
		return (Vector3.new(
			math.min(vector.X, vector2.X),
			math.min(vector.Y, vector2.Y),
			(math.min(vector.Z, vector2.Z))
		))
	end,
	Max = function(vector: Vector3, vector2: Vector3)
		return (Vector3.new(
			math.max(vector.X, vector2.X),
			math.max(vector.Y, vector2.Y),
			(math.max(vector.Z, vector2.Z))
		))
	end,
	ExpandBounds = function(vector: Vector3, vector2: Vector3, vector3: Vector3)
		return vector - vector3, vector2 + vector3
	end
}

function v.SegmentBounds(vector: Vector3, vector2: Vector3, p: number)
	local vector3 = Vector3.new(p, p, p)
	return v.Min(vector, vector2) - vector3, v.Max(vector, vector2) + vector3
end

local function movementPlane(p, plane, p2)
	local normal = plane.Normal

	if normal.Y >= p2.WalkableFloor or math.abs(normal.Y) > 0.0001 then
		return normal, plane.Distance
	end

	if plane.FlatNormal ~= nil and plane.FlatDistance ~= nil then
		return plane.FlatNormal, plane.FlatDistance
	end

	local vector = Vector3.new(normal.X, 0, normal.Z)

	if vector.Magnitude <= 1e-6 then
		return normal, plane.Distance
	end

	local unit = vector.Unit
	local v2 = -1e999

	for _, vector2 in p.Points or {} do
		v2 = math.max(v2, vector2:Dot(unit))
	end

	if v2 == -1e999 then
		unit = normal
	end

	if v2 == -1e999 then
		return unit, plane.Distance
	end

	return unit, v2
end

function v.ContainsConvex(p, vector: Vector3, p2: number)
	local v2 = math.max(p2, TopologyConfig.Default.BrushEpsilon)

	for _, plane in p.Planes do
		local v3, v4 = movementPlane(p, plane, TopologyConfig.Default)

		if vector:Dot(v3) - v4 >= -v2 then
			return false
		end
	end

	return true
end

local function preferPlane(p: number, plane, p2: number, p3, magnitude: number, data) -- 1 equivalent call inferred from this helper
	if p3 == nil then
		return true
	end

	if math.abs(p - p2) * magnitude > data.BrushEpsilon then
		return p2 < p
	end

	return plane.PlaneId < p3.PlaneId
end

local function sweepConvexInternal(p, vector: Vector3, vector2: Vector3, data, p2: number?, flag: boolean?)
	local vector3 = vector2 - vector
	local magnitude = vector3.Magnitude
	local v2 = (p2 == nil or flag == false) and 0 or data.SupportEdgeOwnershipTolerance
	local v3 = -1e999
	local v4 = nil
	local v5 = -1e999
	local v6 = false
	local v7 = false
	local v8 = nil
	local v9 = -1
	local v10 = 1
	local v11 = nil
	local v12 = nil

	for _, plane in p.Planes do
		local v13, v14 = movementPlane(p, plane, data)
		local v15 = vector:Dot(v13) - v14
		local v16 = v15 + vector3:Dot(v13)

		if v2 > 0 and v13.Y < p2 then
			v15 -= v2
			v16 -= v2
		end

		if
			v3 + data.BrushEpsilon < v15
			or math.abs(v15 - v3) <= data.BrushEpsilon and (v4 == nil or plane.PlaneId < v4.PlaneId)
		then
			v12 = v13
			v4 = plane
		end

		v3 = math.max(v3, v15)
		v5 = math.max(v5, v16)
		v6 = v6 or v15 > 0
		v7 = v7 or v16 > 0

		if v15 > 0 and v16 > 0 then
			return nil
		end

		if not (v15 > 0 or v16 > 0) then
			continue
		end

		if v16 < v15 then
			local v17 = math.max(0, (v15 - data.BrushEpsilon) / (v15 - v16))

			if preferPlane(v17, plane, v9, v8, magnitude, data) then -- inferred equivalent call
				v11 = v13
				v8 = plane
			end

			v9 = math.max(v9, v17)
		else
			v10 = math.min(v10, (math.min(1, (v15 + data.BrushEpsilon) / (v15 - v16))))
		end
	end

	if v6 then
		if v8 == nil or v9 < 0 or v10 <= v9 then
			return nil
		end

		return {
			Fraction = math.max(0, v9),
			Normal = v11 or v8.Normal,
			StartSolid = false,
			AllSolid = false,
			PlaneId = v8.PlaneId,
			ResolvedPosition = nil,
			PenetrationDepth = nil
		}
	else
		local normal = v12 or createVector(0, 1, 0)

		if v7 and v3 < v5 and data.ContactEpsilon < magnitude and vector3.Unit:Dot(normal) > 0.25 then
			return nil
		end

		return {
			Fraction = 0,
			Normal = normal,
			StartSolid = true,
			AllSolid = not v7 and v5 < v3,
			PlaneId = v4 == nil and 0 or v4.PlaneId,
			ResolvedPosition = nil,
			PenetrationDepth = nil
		}
	end
end

function v.SweepConvex(p, vector: Vector3, vector2: Vector3, p2)
	return (sweepConvexInternal(p, vector, vector2, p2, nil, nil))
end

function v.SweepConvexSupport(p, vector: Vector3, vector2: Vector3, p2: number, flag: boolean, p3)
	return (sweepConvexInternal(p, vector, vector2, p3, p2, flag))
end

local function insideTriangleEdge(vector: Vector3, vector2: Vector3, vector3: Vector3, normal: Vector3, p: number) -- 2 equivalent calls inferred from this helper
	local vector4 = vector3 - vector2
	local magnitude = vector4.Magnitude
	return magnitude <= 1e-6 or vector4:Cross(vector - vector2):Dot(normal) >= -math.max(p, magnitude * p)
end

function v.TriangleContactContains(data, vector: Vector3, p: number)
	local v2 = insideTriangleEdge(vector, data.A, data.B, data.Normal, p) -- inferred equivalent call

	if not v2 then
		return v2
	end

	v2 = insideTriangleEdge(vector, data.B, data.C, data.Normal, p) -- inferred equivalent call

	if not v2 then
		return v2
	end

	local c = data.C
	local a = data.A
	local normal = data.Normal
	local vector2 = a - c
	local magnitude = vector2.Magnitude
	return magnitude <= 1e-6 or vector2:Cross(vector - c):Dot(normal) >= -math.max(p, magnitude * p)
end

local function sweepTriangleInternal(p, vector: Vector3, vector2: Vector3, data, flag: boolean)
	local v2 = vector:Dot(p.Normal) - p.Distance
	local v3 = vector2:Dot(p.Normal) - p.Distance

	if v2 < -data.FloorContactEpsilon then
		if -v2 > data.FloorStartSolidRecoveryDepth then
			return nil
		end

		local resolvedPosition = vector - p.Normal * v2

		if v.TriangleContactContains(p, resolvedPosition, data.FloorTriangleEdgeSlop) then
			return {
				Fraction = 0,
				Normal = p.Normal,
				StartSolid = true,
				AllSolid = v3 < -data.FloorContactEpsilon,
				PlaneId = 1,
				ResolvedPosition = resolvedPosition,
				PenetrationDepth = -v2
			}
		end

		return nil
	else
		local fraction

		if flag then
			if data.FloorSupportContactEpsilon < v3 then
				return nil
			end

			local v4 = v2 - v3
			fraction = not (math.abs(v4) > 1e-6 and v3 <= 0) and 0.999999 or math.max(0, (math.min(0.999999, v2 / v4)))
		else
			if -data.FloorContactEpsilon <= v3 then
				return nil
			end

			local v4 = v2 - v3

			if math.abs(v4) <= 1e-6 then
				return nil
			else
				fraction = math.max(0, (math.min(1, v2 / v4)))
			end
		end

		local vector3 = vector:Lerp(vector2, fraction)
		local v4 = vector3 - p.Normal * (vector3:Dot(p.Normal) - p.Distance)

		if not v.TriangleContactContains(p, v4, data.FloorTriangleEdgeSlop) then
			return nil
		end

		local v5 = {
			Fraction = fraction,
			Normal = p.Normal,
			StartSolid = false,
			AllSolid = false,
			PlaneId = 1,
			ResolvedPosition = nil,
			PenetrationDepth = 0
		}
		local penetrationDepth

		if flag and v3 < 0 then
			penetrationDepth = -v3
		end

		v5.PenetrationDepth = penetrationDepth
		return v5
	end
end

function v.SweepTriangle(p, vector: Vector3, vector2: Vector3, p2)
	return (sweepTriangleInternal(p, vector, vector2, p2, false))
end

function v.SweepTriangleSupport(p, vector: Vector3, vector2: Vector3, p2)
	return (sweepTriangleInternal(p, vector, vector2, p2, true))
end

return table.freeze(v)