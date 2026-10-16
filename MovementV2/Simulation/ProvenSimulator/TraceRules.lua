local createVector = vector.create
require(script.Parent.Parent.ProvenTypes)

local function getWallClipNormal(vector: Vector3, p)
	if vector.Y >= p.WalkableFloor or math.abs(vector.Y) > 0.0001 then
		return vector
	end

	local vector2 = Vector3.new(vector.X, 0, vector.Z)

	if vector2.Magnitude <= 1e-6 then
		return vector
	end

	return vector2.Unit
end

local function getTraceCylinderAxis(data) -- 1 equivalent call inferred from this helper
	local hullRecord = data and data.hullRecord

	if not hullRecord or hullRecord.sourceShape ~= "Cylinder" then
		return nil
	end

	local sourceCFrame = hullRecord.sourceCFrame

	if typeof(sourceCFrame) == "CFrame" then
		return sourceCFrame.RightVector
	end

	return nil
end

local function getWallConstraintNormal(unit: Vector3, p) -- 1 equivalent call inferred from this helper
	if not (unit.Y < p.WalkableFloor) or unit.Y >= p.WalkableFloor or math.abs(unit.Y) > 0.0001 then
		return unit
	end

	local vector = Vector3.new(unit.X, 0, unit.Z)

	if vector.Magnitude <= 1e-6 then
		return unit
	end

	unit = vector.Unit
	return unit
end

local function isFloorSupportTrace(p) -- 2 equivalent calls inferred from this helper
	local hullRecord = p and p.hullRecord

	if not hullRecord then
		return false
	end

	if hullRecord.isFloorSupport == true then
		return true
	end

	local buildMode = hullRecord.buildMode
	return buildMode == "floorGridCell"
		or buildMode == "floorGridPatch"
		or buildMode == "walkMeshTriangle"
		or buildMode == "walkMeshCell"
end

local function getResolvedSupportPosition(data, vector: Vector3) -- 1 equivalent call inferred from this helper
	if not data then
		return vector
	end

	if isFloorSupportTrace(data) then -- inferred equivalent call
		return data.endPos
	end

	if data.startSolid or data.allSolid then
		return vector
	end

	return data.endPos
end

local function isCylinderWalkableGroundTrace(data, p)
	if not data or data.fraction >= 1 or data.normal.Y < p.WalkableFloor then
		return false
	end

	local hullRecord = data.hullRecord

	if hullRecord == nil or hullRecord.sourceShape ~= "Cylinder" then
		return true
	end

	local traceCylinderAxis = getTraceCylinderAxis(data) -- inferred equivalent call

	if traceCylinderAxis == nil or traceCylinderAxis.Magnitude <= 1e-6 then
		return false
	end

	local unit = traceCylinderAxis.Unit
	return math.abs(unit.Y) < p.WalkableFloor or math.abs((data.normal:Dot(unit))) >= 0.85
end

local function isWalkableGround(data, p) -- 1 equivalent call inferred from this helper
	return (isCylinderWalkableGroundTrace(data, p))
end

local function getTraceGroundNormal(p) -- 1 equivalent call inferred from this helper
	if p == nil or not (p.normal.Magnitude > 1e-6) then
		return nil
	end

	return p.normal
end

return table.freeze({
	GROUND_PROBE_START_BUMP = 0.03,
	getTraceNormalY = function(p, p2: number)
		if p == nil then
			return p2
		end

		return p.normal.Y
	end,
	isPointTestBlocked = function(data)
		return data.startSolid or data.allSolid or data.fraction ~= 1
	end,
	getTraceClipNormal = function(p, p2)
		local normal = p.normal

		if not (normal.Y < p2.WalkableFloor) or normal.Y >= p2.WalkableFloor or math.abs(normal.Y) > 0.0001 then
			return normal
		end

		local vector = Vector3.new(normal.X, 0, normal.Z)

		if vector.Magnitude <= 1e-6 then
			return normal
		end

		normal = vector.Unit
		return normal
	end,
	getWallConstraintNormal = getWallConstraintNormal,
	getTraceSurfaceVelocity = function(p)
		local hullRecord = p.hullRecord

		if hullRecord then
			return hullRecord.surfaceVelocity
		end

		return createVector(0, 0, 0)
	end,
	getTraceSurfaceFriction = function(p, p2)
		local hullRecord = p.hullRecord

		if hullRecord then
			return hullRecord.surfaceFriction
		end

		return p2.SurfaceFrictionDefault
	end,
	getImpactWallConstraintNormal = function(p, p2)
		if not p or p.normal.Y >= p2.WalkableFloor then
			return createVector(0, 0, 0)
		end

		local normal = p.normal

		if normal.Y < p2.WalkableFloor and not (normal.Y >= p2.WalkableFloor or math.abs(normal.Y) > 0.0001) then
			local vector = Vector3.new(normal.X, 0, normal.Z)

			if not (vector.Magnitude <= 1e-6) then
				normal = vector.Unit
			end
		end

		return getWallConstraintNormal(normal, p2) -- inferred equivalent call
	end,
	isDynamicWallContactRecord = function(p)
		if p == nil then
			return true
		end

		local buildMode = p.buildMode
		return typeof(buildMode) == "string" and string.sub(buildMode, 1, 7) == "dynamic"
	end,
	isFloorSupportTrace = isFloorSupportTrace,
	isDynamicPlayerSupportTrace = function(p)
		local hullRecord

		if p ~= nil then
			hullRecord = p.hullRecord
		end

		return hullRecord ~= nil and hullRecord.buildMode == "dynamicPlayerAabb"
	end,
	isRecoverableFloorSupportTrace = function(p, p2, p3: number)
		if not isFloorSupportTrace(p) or p.normal.Y < p2.WalkableFloor then -- inferred equivalent call
			return false
		end

		local floorPenetrationDepth = p.floorPenetrationDepth
		return typeof(floorPenetrationDepth) == "number" and floorPenetrationDepth <= p3
	end,
	getResolvedSupportPosition = getResolvedSupportPosition,
	isWalkableGround = isWalkableGround,
	getTraceGroundNormal = getTraceGroundNormal,
	getTraceMinkowskiPlaneKind = function(p)
		if p == nil then
			return nil
		end

		return p.minkowskiPlaneKind
	end,
	isRampPrimitiveHullRecord = function(p)
		return p ~= nil
			and (p.buildMode == "primitiveLocalHullPlanes" and (p.sourceShape == "Wedge" or p.sourceShape == "CornerWedge") or p.buildMode == "authoredHullPlanes")
	end,
	getLandingSnapDistance = function(vector: Vector3, p)
		if not p then
			return 1e999
		end

		local vector2 = vector - p.endPos
		local traceGroundNormal = getTraceGroundNormal(p) -- inferred equivalent call

		if traceGroundNormal then
			return (math.max(0, vector2:Dot(traceGroundNormal.Unit)))
		end

		return (math.max(0, vector2.Y))
	end,
	shouldRejectAirLanding = function(vector: Vector3, vector2: Vector3?, p: number, p2: number, p3: number)
		if not (vector2 and vector2.Magnitude > 1e-6) then
			return p3 < vector.Y
		end

		local dot = vector:Dot(vector2.Unit)

		if p <= p2 then
			return p3 < dot
		end

		return -p3 < dot
	end,
	supportTraceMatchesPosition = function(data, vector: Vector3, p)
		if not isWalkableGround(data, p) then -- inferred equivalent call
			return false
		end

		local resolvedSupportPosition = getResolvedSupportPosition(data, vector) -- inferred equivalent call
		local v = resolvedSupportPosition.X - vector.X
		local v2 = resolvedSupportPosition.Y - vector.Y
		local v3 = resolvedSupportPosition.Z - vector.Z
		local v4 = p.PositionSnapEpsilon * p.PositionSnapEpsilon
		return v * v + v2 * v2 + v3 * v3 <= v4
	end
})