local createVector = vector.create
local DestructibleFrame = require(script.Parent.DestructibleFrame)
local Geometry = require(script.Parent.Geometry)
require(script.Parent.TopologyBuilder)
require(script.Parent.Parent.Simulation.Types)
local class = {}
class.__index = class

local function stanceTopology(topology, p) -- 4 equivalent calls inferred from this helper
	if p == "Standing" then
		return topology.Standing
	elseif p == "Ducking" then
		return topology.Ducking
	end

	error(string.format("unsupported collision stance %s", (tostring(p))), 3)
end

local function gridCandidates(p, p2, vector: Vector3, vector2: Vector3) -- 2 equivalent calls inferred from this helper
	local scratch = p.Scratch
	local stamp = scratch.Stamp + 1

	if stamp >= 2147483647 then
		table.clear(scratch.Seen)
		stamp = 1
	end

	scratch.Stamp = stamp
	p2.Grid:QueryInto(
		vector,
		vector2,
		p2.Records,
		scratch.Indices,
		scratch.Seen,
		stamp,
		scratch.Sources,
		scratch.Cursors
	)
	return scratch.Indices
end

local function queryCandidates(p, p2, vector: Vector3, vector2: Vector3)
	local scratch = p.Scratch
	local boundsMin = scratch.BoundsMin
	local boundsMax = scratch.BoundsMax

	if
		boundsMin == nil
		or boundsMax == nil
		or vector.X < boundsMin.X
		or vector.Y < boundsMin.Y
		or vector.Z < boundsMin.Z
		or vector2.X > boundsMax.X
		or vector2.Y > boundsMax.Y
		or vector2.Z > boundsMax.Z
	then
		return gridCandidates(p, p2, vector, vector2) -- inferred equivalent call
	else
		local clone = scratch.BoundsLists[p2]

		if clone == nil then
			clone = table.clone(gridCandidates(p, p2, boundsMin, boundsMax)) -- inferred equivalent call
			scratch.BoundsLists[p2] = clone
		end

		local indices = scratch.Indices
		table.clear(indices)
		local records = p2.Records
		local count = 0

		for _, v in clone do
			local record = records[v]
			local aabbMin = record.AabbMin
			local aabbMax = record.AabbMax

			if not (vector.X <= aabbMax.X and vector2.X >= aabbMin.X and vector.Y <= aabbMax.Y and vector2.Y >= aabbMin.Y) then
				continue
			end

			if not (vector.Z <= aabbMax.Z and vector2.Z >= aabbMin.Z) then
				continue
			end

			count += 1
			indices[count] = v
		end

		return indices
	end
end

local function recordIsActive(destructibles, record) -- 4 equivalent calls inferred from this helper
	local destructibleIndex = record.DestructibleIndex
	return destructibleIndex == nil or DestructibleFrame.IsActive(destructibles, destructibleIndex)
end

local function recordIsIgnored(record, p) -- 1 equivalent call inferred from this helper
	return p ~= nil and p.Kind == record.Kind and p.SourceId == record.SourceId
end

local function assertPosition(vector: Vector3, p: string) -- 7 equivalent calls inferred from this helper
	if not Geometry.IsFiniteVector3(vector) then
		error(string.format("%s must be a finite Vector3", p))
	end
end

local function assertTimeFraction(p: number) -- 5 equivalent calls inferred from this helper
	local v = p == p and p >= 0 and p <= 1
	assert(v, "collision time fraction must be normalized")
end

local function assertTimeInterval(p: number, p2: number) -- 1 equivalent call inferred from this helper
	assertTimeFraction(p) -- inferred equivalent call
	assertTimeFraction(p2) -- inferred equivalent call
	assert(p <= p2, "collision time interval is reversed")
end

local function replaceNarrow(data, data2, record, data3, magnitude: number, hitTieDistance: number)
	if data == nil or data2 == nil then
		return true
	end

	if data3.StartSolid ~= data2.StartSolid then
		return data3.StartSolid
	end

	if hitTieDistance < math.abs(data3.Fraction - data2.Fraction) * magnitude then
		return data3.Fraction < data2.Fraction
	end

	if record.SourceId ~= data.SourceId then
		return record.SourceId < data.SourceId
	end

	if record.Kind ~= data.Kind then
		return record.Kind < data.Kind
	end

	if record.ElementId ~= data.ElementId then
		return record.ElementId < data.ElementId
	end

	if data3.PlaneId ~= data2.PlaneId then
		return data3.PlaneId < data2.PlaneId
	end

	if data3.Normal.X ~= data2.Normal.X then
		return data3.Normal.X < data2.Normal.X
	end

	if data3.Normal.Y == data2.Normal.Y then
		return data3.Normal.Z < data2.Normal.Z
	end

	return data3.Normal.Y < data2.Normal.Y
end

local function detailed(data, data2)
	local minkowskiPlaneKind = nil
	local sourceShape

	if data.RecordType == "Hull" then
		sourceShape = data.SourceShape

		for _, plane in data.Planes do
			if plane.PlaneId ~= data2.PlaneId then
				continue
			end

			minkowskiPlaneKind = plane.MinkowskiPlaneKind
			break
		end
	end

	local v = {
		Fraction = data2.Fraction,
		Normal = data2.Normal,
		StartSolid = data2.StartSolid,
		AllSolid = data2.AllSolid,
		PlaneId = data2.PlaneId,
		SourceId = data.SourceId,
		Kind = data.Kind,
		DestructibleIndex = data.DestructibleIndex,
		ElementId = data.ElementId,
		SurfaceFriction = data.SurfaceFriction,
		ResolvedPosition = data2.ResolvedPosition,
		PenetrationDepth = data2.PenetrationDepth,
		SourceShape = sourceShape,
		MinkowskiPlaneKind = minkowskiPlaneKind,
		RecordType = data.RecordType,
		Climbable = data.RecordType == "Hull" and data.Climbable,
		BuildMode = data.RecordType ~= "Hull" and "walkMeshTriangle" or data.BuildMode,
		SourceCFrame = 0,
		SourceSize = 0,
		Planes = 0
	}
	local sourceCFrame

	if data.RecordType == "Hull" then
		sourceCFrame = data.SourceCFrame
	end

	v.SourceCFrame = sourceCFrame
	local sourceSize

	if data.RecordType == "Hull" then
		sourceSize = data.SourceSize
	end

	v.SourceSize = sourceSize
	local planes

	if data.RecordType == "Hull" then
		planes = data.Planes
	end

	v.Planes = planes
	return v
end

local object = setmetatable({}, { __mode = "k" })

function class.new(topology, list)
	assert(table.isfrozen(topology), "collision topology must be immutable")
	assert(
		table.isfrozen(topology.Config) and table.isfrozen(topology.Stats) and table.isfrozen(topology.Standing) and table.isfrozen(topology.Standing.Records) and table.isfrozen(topology.Standing.Grid) and table.isfrozen(topology.Ducking) and table.isfrozen(topology.Ducking.Records) and table.isfrozen(topology.Ducking.Grid),
		"collision topology contains mutable stance data"
	)
	assert(table.isfrozen(list), "destructible frame must be immutable")
	local v, v2 = DestructibleFrame.Validate(list.Epoch, list.Revision, list.Count, list.ActiveBits)
	assert(v, v2)
	local v3 = list.Epoch >= 1 and list.Epoch <= 65535
	assert(v3, "destructible-frame epoch must fit non-zero u16")
	assert(list.Epoch == topology.Epoch, "destructible frame belongs to a different topology epoch")
	assert(list.Count == topology.DestructibleCount, "destructible frame has the wrong source count")
	local scratch = object[topology]

	if scratch == nil then
		scratch = {
			Indices = {},
			Seen = {},
			Sources = {},
			Cursors = {},
			Stamp = 0,
			BoundsLists = {},
			Regions = {},
			RegionCount = 0
		}
		object[topology] = scratch
	end

	return (table.freeze((setmetatable({
		Topology = topology,
		Destructibles = list,
		Scratch = scratch
	}, class))))
end

local boundsLists = {}

function class.SetMovementBounds(p, vector: Vector3, vector2: Vector3)
	assertPosition(vector, "movement bounds minimum") -- inferred equivalent call
	assertPosition(vector2, "movement bounds maximum") -- inferred equivalent call
	local scratch = p.Scratch
	local regions = scratch.Regions
	local v = math.floor(vector.X / 1)
	local v2 = math.floor(vector.Y / 1)
	local v3 = math.floor(vector.Z / 1)
	local v4 = v + 32768 + (v2 + 32768) * 65536 + (v3 + 32768) * 65536 * 65536
	local region = regions[v4]

	if region == nil then
		if scratch.RegionCount >= 512 then
			table.clear(regions)
			scratch.RegionCount = 0
		end
	else
		local min = region.Min
		local max = region.Max

		if
			vector.X >= min.X
			and vector.Y >= min.Y
			and vector.Z >= min.Z
			and vector2.X <= max.X
			and vector2.Y <= max.Y
			and vector2.Z <= max.Z
		then
			local lists = region.Lists
			scratch.BoundsMin = min
			scratch.BoundsMax = max
			scratch.BoundsLists = lists
			return
		end
	end

	if region == nil then
		scratch.RegionCount += 1
	end

	local v5 = {
		Min = Vector3.new(v * 1, v2 * 1, v3 * 1),
		Max = vector2 + createVector(1, 1, 1),
		Lists = {}
	}
	regions[v4] = v5
	local min = v5.Min
	local max = v5.Max
	local lists = v5.Lists
	scratch.BoundsMin = min
	scratch.BoundsMax = max
	scratch.BoundsLists = lists
end

function class.ClearMovementBounds(p)
	local scratch = p.Scratch
	scratch.BoundsMin = nil
	scratch.BoundsMax = nil
	scratch.BoundsLists = boundsLists
end

local function sweepDetailed(p, vector: Vector3, vector2: Vector3, p2, p3, p4: number, p5: number, flag: boolean)
	assertPosition(vector, "sweep start") -- inferred equivalent call
	assertPosition(vector2, "sweep end") -- inferred equivalent call
	assertTimeInterval(p4, p5) -- inferred equivalent call
	local magnitude = (vector2 - vector).Magnitude
	local config = p.Topology.Config
	assert(magnitude <= config.MaxSweepDistance, "collision sweep exceeds the configured maximum distance")
	local v = stanceTopology(p.Topology, p2) -- inferred equivalent call
	local segmentBounds, v2 = Geometry.SegmentBounds(vector, vector2, config.BroadphasePadding)
	local v3 = queryCandidates(p, v, segmentBounds, v2)
	local v4 = nil
	local v5 = nil

	for _, v6 in v3 do
		local record = v.Records[v6]

		if
			recordIsIgnored(record, p3) -- inferred equivalent call
			or not recordIsActive(p.Destructibles, record) -- inferred equivalent call
			or not (record.RecordType ~= "Walkmesh" or flag)
		then
			continue
		end

		local v7

		if record.RecordType == "Hull" then
			v7 = Geometry.SweepConvex(record, vector, vector2, config)
		else
			v7 = Geometry.SweepTriangle(record, vector, vector2, config)
		end

		if not (v7 ~= nil and replaceNarrow(v4, v5, record, v7, magnitude, config.HitTieDistance)) then
			continue
		end

		v5 = v7
		v4 = record
	end

	if v4 and v5 then
		return (detailed(v4, v5))
	end

	return nil
end

function class:SweepDetailed(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return (sweepDetailed(self, vector, vector2, p, p2, p3, p4, false))
end

function class:SweepWithFloorSupportDetailed(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return (sweepDetailed(self, vector, vector2, p, p2, p3, p4, true))
end

local function sweepResult(data)
	if data == nil then
		return {
			Fraction = 1,
			Normal = createVector(0, 1, 0),
			StartSolid = false,
			AllSolid = false
		}
	end

	return {
		Fraction = data.Fraction,
		Normal = data.Normal,
		StartSolid = data.StartSolid,
		AllSolid = data.AllSolid,
		SourceId = data.SourceId,
		Kind = data.Kind,
		SourceShape = data.SourceShape,
		MinkowskiPlaneKind = data.MinkowskiPlaneKind,
		RecordType = data.RecordType,
		Climbable = data.Climbable,
		BuildMode = data.BuildMode,
		SourceCFrame = data.SourceCFrame,
		SourceSize = data.SourceSize,
		Planes = data.Planes,
		PlaneId = data.PlaneId,
		SurfaceFriction = data.SurfaceFriction,
		SurfaceVelocity = createVector(0, 0, 0),
		ResolvedPosition = data.ResolvedPosition,
		PenetrationDepth = data.PenetrationDepth
	}
end

function class:Sweep(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return (sweepResult(self:SweepDetailed(vector, vector2, p, p2, p3, p4)))
end

function class:SweepWithFloorSupport(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return (sweepResult(self:SweepWithFloorSupportDetailed(vector, vector2, p, p2, p3, p4)))
end

function class:IsClear(vector: Vector3, p, p2: number)
	assertPosition(vector, "clearance position") -- inferred equivalent call
	assertTimeFraction(p2) -- inferred equivalent call
	local config = self.Topology.Config
	local v = stanceTopology(self.Topology, p) -- inferred equivalent call
	local vector2 = Vector3.new(config.BroadphasePadding, config.BroadphasePadding, config.BroadphasePadding)
	local v2 = queryCandidates(self, v, vector - vector2, vector + vector2)

	for _, v3 in v2 do
		local record = v.Records[v3]

		if
			record.RecordType == "Hull"
			and recordIsActive(self.Destructibles, record) -- inferred equivalent call
			and Geometry.ContainsConvex(record, vector, config.ContactEpsilon)
		then
			return false
		end
	end

	return true
end

function class:CanMove(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	local sweepDetailed2 = self:SweepDetailed(vector, vector2, p, p2, p3, p4)
	local v

	if sweepDetailed2 == nil then
		return (self:IsClear(vector2, p, p4))
	else
		v = not sweepDetailed2.StartSolid

		if v then
			if sweepDetailed2.Fraction >= 1 then
				return (self:IsClear(vector2, p, p4))
			else
				return false
			end
		end
	end

	return v
end

local function groundWinner(object2, p, config, vector: Vector3, vector2: Vector3, flag: boolean)
	local magnitude = (vector2 - vector).Magnitude
	local segmentBounds, v = Geometry.SegmentBounds(vector, vector2, config.BroadphasePadding)
	local v2 = queryCandidates(object2, p, segmentBounds, v)
	local v3 = nil
	local v4 = nil

	for _, v5 in v2 do
		local record = p.Records[v5]

		if not recordIsActive(object2.Destructibles, record) then -- inferred equivalent call
			continue
		end

		local v6

		if record.RecordType == "Hull" then
			v6 = Geometry.SweepConvexSupport(record, vector, vector2, config.WalkableFloor, flag, config)
		else
			v6 = Geometry.SweepTriangleSupport(record, vector, vector2, config)
		end

		if not (v6 ~= nil and v6.Normal.Y >= config.WalkableFloor and replaceNarrow(
			v3,
			v4,
			record,
			v6,
			magnitude,
			config.HitTieDistance
		)) then
			continue
		end

		v4 = v6
		v3 = record
	end

	return v3, v4
end

function class:FindGround(vector: Vector3, p, p2: number, p3: number, p4)
	assertPosition(vector, "ground-query position") -- inferred equivalent call
	assertTimeFraction(p3) -- inferred equivalent call
	local v = p2 == p2 and p2 >= 0 and p2 <= self.Topology.Config.MaxSweepDistance
	assert(v, "invalid ground distance")
	local config = self.Topology.Config
	local v2 = stanceTopology(self.Topology, p) -- inferred equivalent call
	local v3 = math.min(config.GroundProbeStartBump, config.MaxSweepDistance - p2)
	local v4 = vector + Vector3.new(0, v3, 0)
	local v5 = vector - Vector3.new(0, p2, 0)
	local v6, v7 = groundWinner(self, v2, config, v4, v5, p4 ~= nil)

	if v7 ~= nil and v7.StartSolid and v7.ResolvedPosition == nil then
		local v8 = math.max(v3, p2, config.FloorStartSolidRecoveryDepth - config.FloorContactEpsilon)
		local v9 = vector + Vector3.new(0, v8, 0)
		local sweepDetailed2 = self:SweepDetailed(vector, v9, p, nil, p3, p3)

		if sweepDetailed2 ~= nil then
			if sweepDetailed2.StartSolid then
				v9 = vector
			else
				v9 = vector:Lerp(v9, sweepDetailed2.Fraction)
			end
		end

		local v10 = v9 - Vector3.new(0, p2 + v8, 0)
		local v11, v12 = groundWinner(self, v2, config, v9, v10, false)

		if v12 ~= nil and not v12.AllSolid then
			v4 = v9
			v5 = v10
			v6 = v11
			v7 = v12
		end
	end

	if v7 == nil or v6 == nil then
		return nil
	end

	local resolvedPosition = v7.ResolvedPosition

	if not resolvedPosition then
		if v7.StartSolid then
			resolvedPosition = vector
		else
			resolvedPosition = v4:Lerp(v5, v7.Fraction)
		end
	end

	if self:IsClear(resolvedPosition, p, p3) then
		return {
			Position = resolvedPosition,
			Normal = v7.Normal,
			SurfaceFriction = v6.SurfaceFriction,
			Support = {
				Kind = v6.Kind,
				SourceId = v6.SourceId,
				Anchor = resolvedPosition,
				Velocity = createVector(0, 0, 0)
			}
		}
	end

	return nil
end

local object2 = setmetatable({}, { __mode = "k" })

local function climbableIndices(p)
	local result = object2[p]

	if result ~= nil then
		return result
	end

	result = {}

	for k, record in p.Records do
		if record.RecordType == "Hull" and record.Climbable then
			result[#result + 1] = k
		end
	end

	object2[p] = result
	return result
end

local function ladderFaceContains(record, vector: Vector3, contactEpsilon: number)
	for _, plane in record.Planes do
		if contactEpsilon < vector:Dot(plane.Normal) - plane.Distance then
			return false
		end
	end

	return true
end

function class.FindLadder(p, vector: Vector3, p2, p3: number, p4: number)
	assertPosition(vector, "ladder-query position") -- inferred equivalent call
	assertTimeFraction(p4) -- inferred equivalent call
	local v = p3 == p3 and p3 >= 0 and p3 <= p.Topology.Config.MaxSweepDistance
	assert(v, "invalid ladder distance")
	local config = p.Topology.Config
	local v2 = stanceTopology(p.Topology, p2) -- inferred equivalent call

	if p.Topology.HasClimbable == false then
		return nil
	end

	local vector2 = Vector3.new(p3, p3, p3)
	local v3 = vector - vector2
	local v4 = vector + vector2
	local v5 = 1e999
	local v6 = nil
	local v7 = nil

	for _, v8 in climbableIndices(v2) do
		local record = v2.Records[v8]
		local aabbMin = record.AabbMin
		local aabbMax = record.AabbMax

		if
			v3.X > aabbMax.X
			or v4.X < aabbMin.X
			or v3.Y > aabbMax.Y
			or v4.Y < aabbMin.Y
			or v3.Z > aabbMax.Z
			or v4.Z < aabbMin.Z
		then
			continue
		end

		if not recordIsActive(p.Destructibles, record) then -- inferred equivalent call
			continue
		end

		for _, ladderPlane in record.LadderPlanes do
			if math.abs(ladderPlane.Normal.Y) >= config.WalkableFloor then
				continue
			end

			local v9 = vector:Dot(ladderPlane.Normal) - ladderPlane.Distance

			if
				v9 < -config.ContactEpsilon
				or p3 + config.ContactEpsilon < v9
				or not ladderFaceContains(record, vector - ladderPlane.Normal * v9, config.ContactEpsilon)
			then
				continue
			end

			local v10 = math.max(v9, 0)

			if not (v10 < v5 - config.HitTieDistance or math.abs(v10 - v5) <= config.HitTieDistance and (v6 == nil or record.SourceId < v6.SourceId or record.SourceId == v6.SourceId and v7 ~= nil and ladderPlane.PlaneId < v7.PlaneId)) then
				continue
			end

			v7 = ladderPlane
			v6 = record
			v5 = v10
		end
	end

	if v6 == nil or v7 == nil then
		return nil
	end

	return {
		Normal = v7.Normal,
		SourceId = v6.SourceId,
		Kind = v6.Kind,
		Velocity = createVector(0, 0, 0)
	}
end

return table.freeze(class)