local createVector = vector.create
local Enums = require(script.Parent.Parent.Enums)
require(script.Parent.Parent.Types)
require(script.Parent.PlayerHullClearance)
local DeterminismTrace = require(script.Parent.DeterminismTrace)
local class = {}
class.__index = class

local function currentStance(p: string) -- 6 equivalent calls inferred from this helper
	if p == "crouching" then
		return "Ducking"
	end

	return "Standing"
end

local function newTrace(state)
	local tracePool = state.TracePool

	if tracePool == nil then
		return {}
	end

	local tracesUsed = state.TracesUsed + 1
	state.TracesUsed = tracesUsed
	local v = tracePool[tracesUsed]

	if v == nil then
		v = {}
		tracePool[tracesUsed] = v
	end

	return v
end

local function newRecord(state)
	local recordPool = state.RecordPool

	if recordPool == nil then
		return {}
	end

	local recordsUsed = state.RecordsUsed + 1
	state.RecordsUsed = recordsUsed
	local v = recordPool[recordsUsed]

	if v == nil then
		v = {}
		recordPool[recordsUsed] = v
	end

	return v
end

local function writeTrace(p, fraction: number, endPos: Vector3, normal: Vector3, startSolid: boolean, allSolid: boolean, planeId, minkowskiPlaneKind, hullRecord, penetrationDepth) -- 2 equivalent calls inferred from this helper
	p.fraction = fraction
	p.endPos = endPos
	p.normal = normal
	p.startSolid = startSolid
	p.allSolid = allSolid
	p.planeNum = planeId
	p.minkowskiPlaneKind = minkowskiPlaneKind
	p.hullRecord = hullRecord
	p.floorPenetrationDepth = penetrationDepth
	return p
end

local function emptyTrace(p, endPos: Vector3) -- 4 equivalent calls inferred from this helper
	local v = newTrace(p)
	v.fraction = 1
	v.endPos = endPos
	v.normal = createVector(0, 0, 0)
	v.startSolid = false
	v.allSolid = false
	v.planeNum = nil
	v.minkowskiPlaneKind = nil
	v.hullRecord = nil
	v.floorPenetrationDepth = nil
	return v
end

local function minkowskiPlaneKind(data)
	if data.MinkowskiPlaneKind ~= nil then
		return data.MinkowskiPlaneKind
	end

	if data.Planes == nil or data.PlaneId == nil then
		return nil
	end

	for _, plane in data.Planes do
		if plane.PlaneId == data.PlaneId then
			return plane.MinkowskiPlaneKind
		end
	end

	return nil
end

local function hullRecord(p, data, vector: Vector3?, supportAnchor: Vector3?)
	if data.SourceId == nil then
		return nil
	end

	local recordType = data.RecordType
	local kind = data.Kind
	local v = newRecord(p)
	v.sourceId = data.SourceId
	v.kind = kind
	v.sourceShape = data.SourceShape
	v.buildMode = data.BuildMode
		or recordType == "Walkmesh" and "walkMeshTriangle"
		or kind == Enums.SupportKind.Mover and "dynamicMoverObb"
		or kind == Enums.SupportKind.Player and "dynamicPlayerAabb"
		or nil
	v.climbable = data.Climbable == true
	v.sourceCFrame = data.SourceCFrame
	v.sourceSize = data.SourceSize
	v.surfaceVelocity = vector or createVector(0, 0, 0)
	v.surfaceFriction = data.SurfaceFriction or 1
	v.supportAnchor = supportAnchor
	v.isFloorSupport = recordType == "Walkmesh" or kind == Enums.SupportKind.Walkmesh
	v.allowsPlayerDepenetration = kind ~= Enums.SupportKind.Mover
	return v
end

local function fromSweep(state, vector: Vector3, endPos: Vector3, data)
	if data.Fraction >= 1 and not (data.StartSolid or data.AllSolid) then
		return emptyTrace(state, endPos) -- inferred equivalent call
	else
		local fraction = math.clamp(data.Fraction, 0, 1)
		local resolvedPosition = data.ResolvedPosition

		if typeof(resolvedPosition) ~= "Vector3" then
			resolvedPosition = vector:Lerp(endPos, fraction)
		end

		local minkowskiPlaneKind2 = minkowskiPlaneKind(data)
		local hullRecord2 = hullRecord(state, data, data.SurfaceVelocity, nil)
		return writeTrace( -- inferred equivalent call
			newTrace(state),
			fraction,
			resolvedPosition,
			data.Normal,
			data.StartSolid,
			data.AllSolid,
			data.PlaneId,
			minkowskiPlaneKind2,
			hullRecord2,
			data.PenetrationDepth
		)
	end
end

local v = {}

local function fromGround(p, vector: Vector3, endPos: Vector3, data)
	if data == nil then
		return emptyTrace(p, endPos) -- inferred equivalent call
	else
		local vector2 = endPos - vector
		local dot = vector2:Dot(vector2)
		local fraction = not (dot > 1e-12) and 0 or math.clamp((data.Position - vector):Dot(vector2) / dot, 0, 0.999999)
		local support = data.Support
		local v2 = v
		table.clear(v2)
		v2.SourceId = support.SourceId
		v2.Kind = support.Kind
		v2.RecordType = support.Kind == Enums.SupportKind.Walkmesh and "Walkmesh" or "Hull"
		v2.BuildMode = support.Kind == Enums.SupportKind.Walkmesh and "walkMeshTriangle"
			or support.Kind == Enums.SupportKind.Mover and "dynamicMoverObb"
			or support.Kind == Enums.SupportKind.Player and "dynamicPlayerAabb"
			or nil
		v2.SurfaceFriction = data.SurfaceFriction
		local hullRecord2 = hullRecord(p, v2, support.Velocity, support.Anchor)
		return writeTrace(newTrace(p), fraction, data.Position, data.Normal, false, false, nil, nil, hullRecord2, nil) -- inferred equivalent call
	end
end

local function groundQuery(state, vector: Vector3, vector2: Vector3, p: string, flag: boolean)
	local v2 = vector - Vector3.new(0, state.Config.GroundProbeStartBump or 0.03, 0)
	local v3 = math.max(0, v2.Y - vector2.Y)
	local groundBases = state.GroundBases

	if groundBases == nil then
		groundBases = {}
		state.GroundBases = groundBases
		state.GroundDistances = {}
		state.GroundStances = {}
		state.GroundRecoveries = {}
		state.GroundResults = {}
		state.GroundCount = 0
	end

	local groundDistances = state.GroundDistances
	local groundStances = state.GroundStances
	local groundRecoveries = state.GroundRecoveries
	local groundResults = state.GroundResults
	local v4 = currentStance(p) -- inferred equivalent call
	local v5 = false
	local v6 = nil

	for i = 1, state.GroundCount do
		if not (groundBases[i] == v2 and groundDistances[i] == v3 and groundStances[i] == v4 and groundRecoveries[i] == flag) then
			continue
		end

		v6 = groundResults[i]
		v5 = true
		break
	end

	if not v5 then
		local query = state.Query
		local v7

		if flag then
			v7 = state.RecoverySupport
		end

		v6 = query:FindGround(v2, v4, v3, 1, v7)
		local groundCount = state.GroundCount + 1
		state.GroundCount = groundCount
		groundBases[groundCount] = v2
		groundDistances[groundCount] = v3
		groundStances[groundCount] = v4
		groundRecoveries[groundCount] = flag
		groundResults[groundCount] = v6
	end

	if
		vector.X ~= vector.X
		or vector.Y ~= vector.Y
		or vector.Z ~= vector.Z
		or vector2.X ~= vector2.X
		or vector2.Y ~= vector2.Y
		or vector2.Z ~= vector2.Z
	then
		error(
			string.format(
				"proven simulator issued a non-finite ground query: %s -> %s",
				tostring(vector),
				(tostring(vector2))
			),
			2
		)
	end

	local v7 = fromGround(state, vector, vector2, v6)
	DeterminismTrace.collision(state.Trace, "collision.findGround", vector, vector2, v7, 3)
	return v7
end

local function retainedPlayerGroundQuery(data, vector: Vector3, vector2: Vector3, p: string)
	local findPlayerGround = data.Query.FindPlayerGround

	if findPlayerGround == nil then
		return nil
	end

	local v2 = vector - Vector3.new(0, data.Config.GroundProbeStartBump or 0.03, 0)
	local v3 = math.max(0, v2.Y - vector2.Y)
	local playerGround = findPlayerGround(data.Query, v2, currentStance(p), v3) -- inferred equivalent call

	if playerGround == nil then
		return nil
	end

	local v4 = fromGround(data, vector, vector2, playerGround)
	DeterminismTrace.collision(data.Trace, "collision.findPlayerGround", vector, vector2, v4, 3)
	return v4
end

function class.new(query, config, recoverySupport, trace, vector: Vector3?, playerStanceProbe)
	return (setmetatable({
		Query = query,
		Config = config,
		RecoverySupport = recoverySupport,
		Trace = trace,
		RetainedGroundSurfaceVelocity = vector,
		PlayerStanceProbe = playerStanceProbe
	}, class))
end

local v2 = nil

function class.acquire(query, config, recoverySupport, p, retainedGroundSurfaceVelocity: Vector3?, playerStanceProbe)
	if p ~= nil then
		return class.new(query, config, recoverySupport, p, retainedGroundSurfaceVelocity, playerStanceProbe)
	end

	local selected = v2

	if selected == nil then
		selected = class.new(query, config, recoverySupport, nil, retainedGroundSurfaceVelocity, playerStanceProbe)
		selected.TracePool = {}
		selected.RecordPool = {}
		v2 = selected
	end

	selected.Query = query
	selected.Config = config
	selected.RecoverySupport = recoverySupport
	selected.Trace = nil
	selected.RetainedGroundSurfaceVelocity = retainedGroundSurfaceVelocity
	selected.PlayerStanceProbe = playerStanceProbe
	selected.TracesUsed = 0
	selected.RecordsUsed = 0
	selected.SweepCount = 0
	selected.GroundCount = 0
	return selected
end

function class.GetRetainedGroundSurfaceVelocity(p)
	return p.RetainedGroundSurfaceVelocity
end

function class.ResolveGroundTrace(p, p2, vector: Vector3)
	local hullRecord2

	if p2 ~= nil then
		hullRecord2 = p2.hullRecord
	end

	if hullRecord2 == nil or typeof(hullRecord2.kind) ~= "number" or typeof(hullRecord2.sourceId) ~= "number" then
		return nil
	end

	if hullRecord2.kind == Enums.SupportKind.None or hullRecord2.sourceId == 0 then
		return nil
	end

	local supportAnchor = hullRecord2.supportAnchor

	if typeof(supportAnchor) ~= "Vector3" then
		if hullRecord2.kind == Enums.SupportKind.Mover and typeof(hullRecord2.sourceCFrame) == "CFrame" then
			supportAnchor = hullRecord2.sourceCFrame:PointToObjectSpace(vector)
		else
			supportAnchor = vector
		end
	end

	local velocity = typeof(hullRecord2.surfaceVelocity) ~= "Vector3" and createVector(0, 0, 0)
		or hullRecord2.surfaceVelocity
	return {
		Position = vector,
		Normal = p2.normal,
		SurfaceFriction = hullRecord2.surfaceFriction or p.Config.SurfaceFrictionDefault,
		Support = {
			Kind = hullRecord2.kind,
			SourceId = hullRecord2.sourceId,
			Anchor = supportAnchor,
			Velocity = velocity
		}
	}
end

local function sweepTrace(state, p: string, p2: string, vector: Vector3, endPos: Vector3, p3: string)
	local query = state.Query
	local v3 = query[p]

	if v3 == nil then
		return (fromSweep(state, vector, endPos, query[p2](query, vector, endPos, currentStance(p3), nil, 1, 1))) -- inferred equivalent call
	end

	local v4 = currentStance(p3) -- inferred equivalent call
	local sweepNames = state.SweepNames

	if sweepNames == nil then
		sweepNames = {}
		state.SweepNames = sweepNames
		state.SweepStarts = {}
		state.SweepFinishes = {}
		state.SweepStances = {}
		state.SweepHits = {}
		state.SweepCount = 0
	end

	local sweepStarts = state.SweepStarts
	local sweepFinishes = state.SweepFinishes
	local sweepStances = state.SweepStances
	local sweepHits = state.SweepHits
	local v5 = false
	local v6 = nil

	for i = 1, state.SweepCount do
		if not (sweepNames[i] == p and sweepStarts[i] == vector and sweepFinishes[i] == endPos and sweepStances[i] == v4) then
			continue
		end

		v6 = sweepHits[i]
		v5 = true
		break
	end

	if not v5 then
		v6 = v3(query, vector, endPos, v4, nil, 1, 1)
		local sweepCount = state.SweepCount + 1
		state.SweepCount = sweepCount
		sweepNames[sweepCount] = p
		sweepStarts[sweepCount] = vector
		sweepFinishes[sweepCount] = endPos
		sweepStances[sweepCount] = v4
		sweepHits[sweepCount] = v6
	end

	if v6 ~= nil then
		return (fromSweep(state, vector, endPos, v6))
	end

	return emptyTrace(state, endPos) -- inferred equivalent call
end

function class:Sweep(vector: Vector3, vector2: Vector3, p: string, _)
	local v3 = sweepTrace(self, "SweepDetailed", "Sweep", vector, vector2, p)
	DeterminismTrace.collision(self.Trace, "collision.sweep", vector, vector2, v3, 3)
	return v3
end

function class:SweepWithFloorSupport(vector: Vector3, vector2: Vector3, p: string)
	local v3 = sweepTrace(self, "SweepWithFloorSupportDetailed", "SweepWithFloorSupport", vector, vector2, p)
	DeterminismTrace.collision(self.Trace, "collision.sweepWithFloor", vector, vector2, v3, 3)
	return v3
end

function class:SupportSweep(vector: Vector3, vector2: Vector3, p: string, p2: number?, flag: boolean?)
	local v3 = retainedPlayerGroundQuery(self, vector, vector2, p)

	if v3 ~= nil then
		return v3
	end

	local sweepWithFloorSupport = self:SweepWithFloorSupport(vector, vector2, p)

	if sweepWithFloorSupport.fraction < 1 and (p2 == nil or p2 <= sweepWithFloorSupport.normal.Y) then
		return sweepWithFloorSupport
	end

	local v4 = groundQuery(self, vector, vector2, p, flag == true)

	if v4.fraction < 1 then
		return v4
	end

	return sweepWithFloorSupport
end

function class.WalkableSupportSweep(p, vector: Vector3, vector2: Vector3, p2: string, _: number, flag: boolean?)
	local v3 = retainedPlayerGroundQuery(p, vector, vector2, p2)

	if v3 == nil then
		return (groundQuery(p, vector, vector2, p2, flag == true))
	end

	return v3
end

function class.FloorSupportSweep(p, vector: Vector3, endPos: Vector3, p2: string, _: number?)
	local v3 = groundQuery(p, vector, endPos, p2, false)
	local hullRecord2 = v3.hullRecord

	if hullRecord2 ~= nil and hullRecord2.isFloorSupport == true then
		return v3
	end

	return emptyTrace(p, endPos) -- inferred equivalent call
end

function class:PointTest(endPos: Vector3, p: string, flag: boolean?)
	local sweep = self:Sweep(endPos, endPos, p)
	local playerStanceProbe = self.PlayerStanceProbe

	if flag ~= true or playerStanceProbe == nil or sweep.startSolid or sweep.allSolid then
		return sweep
	end

	local sourceId = playerStanceProbe(endPos, currentStance(p)) -- inferred equivalent call

	if sourceId == nil then
		return sweep
	end

	sweep = newTrace(self)
	sweep.fraction = 1
	sweep.endPos = endPos
	sweep.normal = createVector(0, 0, 0)
	sweep.startSolid = false
	sweep.allSolid = false
	sweep.planeNum = nil
	sweep.minkowskiPlaneKind = nil
	sweep.hullRecord = nil
	sweep.floorPenetrationDepth = nil
	sweep.fraction = 0
	sweep.startSolid = true
	sweep.allSolid = true
	sweep.hullRecord = hullRecord(self, { SourceId = sourceId, Kind = Enums.SupportKind.Player }, nil, nil)
	DeterminismTrace.collision(self.Trace, "collision.playerStanceClearance", endPos, endPos, sweep, 3)
	return sweep
end

function class.BeginStepBounds(p, vector: Vector3, vector2: Vector3, p2: number, p3: number)
	local query = p.Query

	if query.SetMovementBounds == nil then
		return
	end

	local config = p.Config
	local v3 = (vector2.Magnitude + p2) * p3 + 1.5
	local vector3 = Vector3.new(v3, v3 + math.max(config.MaxStepHeight, config.GroundProbeDistance), v3)
	query:SetMovementBounds(vector - vector3, vector + vector3)
end

function class.HasUniformGroundSurfaces(_, _: Vector3, _: string, _: number)
	return false
end

function class.HasClimbableNear(p, vector: Vector3, p2: string, p3: number)
	local findLadder = p.Query.FindLadder
	return findLadder ~= nil and findLadder(p.Query, vector, currentStance(p2), p3, 1) ~= nil -- inferred equivalent call
end

function class.CanonicalizeExpandedBlockCornerTrace(_, p, _: Vector3, _: string)
	return p
end

return table.freeze(class)