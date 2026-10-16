local createVector = vector.create
local Enums = require(script.Parent.Parent.Enums)
require(script.Parent.Parent.Simulation.Types)
local Geometry = require(script.Parent.Geometry)
local MoverFrame = require(script.Parent.MoverFrame)
local MoverProxyCache = require(script.Parent.MoverProxyCache)
require(script.Parent.TopologyConfig)
require(script.Parent.World)
local class = {}
class.__index = class

local function isFiniteNumber(value)
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

local function assertPosition(vector: Vector3, p: string) -- 11 equivalent calls inferred from this helper
	if not Geometry.IsFiniteVector3(vector) then
		error(string.format("%s must be a finite Vector3", p))
	end
end

local function assertTimeFraction(value: number) -- 4 equivalent calls inferred from this helper
	local v

	if typeof(value) == "number" and value == value and value > -1e999 then
		v = value < 1e999
	else
		v = false
	end

	if v then
		if value >= 0 then
			v = value <= 1
		else
			v = false
		end
	end

	assert(v, "collision time fraction must be normalized")
end

local function assertTimeInterval(value: number, value2: number) -- 4 equivalent calls inferred from this helper
	assertTimeFraction(value) -- inferred equivalent call
	assertTimeFraction(value2) -- inferred equivalent call
	assert(value <= value2, "collision time interval is reversed")
end

local function identityLess(data, data2) -- 1 equivalent call inferred from this helper
	if data.SourceId ~= data2.SourceId then
		return data.SourceId < data2.SourceId
	end

	if data.Kind ~= data2.Kind then
		return data.Kind < data2.Kind
	end

	if data.ElementId == data2.ElementId then
		return data.PlaneId < data2.PlaneId
	end

	return data.ElementId < data2.ElementId
end

local function shouldReplace(data, data2, vector: Vector3)
	if data == nil then
		return true
	end

	if data2.StartSolid ~= data.StartSolid then
		return data2.StartSolid
	end

	if math.abs(data2.Fraction - data.Fraction) > 1e-9 then
		return data2.Fraction < data.Fraction
	end

	local v = -vector:Dot(data2.Normal)
	local v2 = -vector:Dot(data.Normal)

	if math.abs(v - v2) > 1e-9 then
		return v2 < v
	end

	return identityLess(data2, data) -- inferred equivalent call
end

local function endpointDetailed(endpointMover, vector: Vector3, vector2: Vector3, value: number, vector3: Vector3, startSolid: boolean, flag: boolean, planeId: number)
	local record = endpointMover.Record
	local fraction = math.clamp(value, 0, 1)
	local lerped = vector:Lerp(vector2, fraction)
	return {
		Fraction = fraction,
		Normal = vector3,
		StartSolid = startSolid,
		AllSolid = flag,
		PlaneId = planeId,
		SourceId = record.Id,
		Kind = Enums.SupportKind.Mover,
		DestructibleIndex = nil,
		ElementId = 0,
		SurfaceFriction = record.SurfaceFriction,
		SurfaceVelocity = MoverFrame.VelocityAtPoint(record, lerped, 1),
		SourceShape = "Block",
		RecordType = "Hull",
		BuildMode = "dynamicMoverObb",
		SourceCFrame = record.CFrame,
		SourceSize = record.Size
	}
end

local function staticDetailed(data)
	return {
		Fraction = data.Fraction,
		Normal = data.Normal,
		StartSolid = data.StartSolid,
		AllSolid = data.AllSolid,
		PlaneId = data.PlaneId,
		SourceId = data.SourceId,
		Kind = data.Kind,
		DestructibleIndex = data.DestructibleIndex,
		ElementId = data.ElementId,
		SurfaceFriction = data.SurfaceFriction,
		SurfaceVelocity = createVector(0, 0, 0),
		ResolvedPosition = data.ResolvedPosition,
		PenetrationDepth = data.PenetrationDepth,
		SourceShape = data.SourceShape,
		MinkowskiPlaneKind = data.MinkowskiPlaneKind,
		RecordType = data.RecordType,
		Climbable = data.Climbable,
		BuildMode = data.BuildMode,
		SourceCFrame = data.SourceCFrame,
		SourceSize = data.SourceSize,
		Planes = data.Planes
	}
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
		SurfaceVelocity = data.SurfaceVelocity,
		ResolvedPosition = data.ResolvedPosition,
		PenetrationDepth = data.PenetrationDepth
	}
end

local function ignoredMover(record, p) -- 1 equivalent call inferred from this helper
	return p ~= nil and p.Kind == Enums.SupportKind.Mover and p.SourceId == record.Id
end

local function assertCurrentPoseInterval(p: number, p2: number) -- 4 equivalent calls inferred from this helper
	local v = p == 1 and p2 == 1
	assert(v, "mover collision supports only the committed current-pose time fraction 1")
end

function class.new(static, list, p)
	assert(table.isfrozen(static), "static collision world must be immutable")
	assert(
		table.isfrozen(list) and table.isfrozen(list.Records) and table.isfrozen(list.ById),
		"mover frame must be immutable"
	)

	for _, list2 in list.Records do
		assert(table.isfrozen(list2), "mover frame contains a mutable record")
	end

	local v = p ~= nil and p.Cache ~= nil
	assert(v, "mover world requires an instance-owned proxy cache")
	local cache = p.Cache
	cache:BeginComposition()
	local endpointMovers = table.create(#list.Records)

	for k, record in list.Records do
		endpointMovers[k] = cache:BindEndpoint(record, static.Topology.Config)
	end

	table.freeze(endpointMovers)
	return (table.freeze((setmetatable(
		{
			Static = static,
			Movers = list,
			EndpointMovers = endpointMovers,
			Config = static.Topology.Config
		},
		class
	))))
end

function class:SweepMoversDetailed(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	assertPosition(vector, "mover sweep start") -- inferred equivalent call
	assertPosition(vector2, "mover sweep end") -- inferred equivalent call
	assertTimeInterval(p3, p4) -- inferred equivalent call
	assertCurrentPoseInterval(p3, p4) -- inferred equivalent call
	local v = vector2 - vector
	local v2 = nil

	for _, endpointMover in self.EndpointMovers do
		if ignoredMover(endpointMover.Record, p2) then -- inferred equivalent call
			continue
		end

		local sweepEndpoint, normal, startSolid, allSolid, planeId = MoverProxyCache.SweepEndpoint(
			endpointMover,
			vector,
			vector2,
			p,
			self.Config
		)

		if sweepEndpoint == nil then
			continue
		end

		local v3 = endpointDetailed(
			endpointMover,
			vector,
			vector2,
			sweepEndpoint,
			normal,
			startSolid,
			allSolid,
			planeId
		)

		if shouldReplace(v2, v3, v) then
			v2 = v3
		end
	end

	return v2
end

function class:SweepDetailed(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	assertPosition(vector, "composite sweep start") -- inferred equivalent call
	assertPosition(vector2, "composite sweep end") -- inferred equivalent call
	assertTimeInterval(p3, p4) -- inferred equivalent call
	local v = vector2 - vector
	local sweepDetailed = self.Static:SweepDetailed(vector, vector2, p, p2, p3, p4)
	local v2

	if sweepDetailed ~= nil then
		v2 = staticDetailed(sweepDetailed)
	end

	local sweepMoversDetailed = self:SweepMoversDetailed(vector, vector2, p, p2, p3, p4)

	if sweepMoversDetailed ~= nil and shouldReplace(v2, sweepMoversDetailed, v) then
		return sweepMoversDetailed
	end

	return v2
end

function class:Sweep(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return (sweepResult(self:SweepDetailed(vector, vector2, p, p2, p3, p4)))
end

function class:SweepWithFloorSupportDetailed(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	assertPosition(vector, "composite floor sweep start") -- inferred equivalent call
	assertPosition(vector2, "composite floor sweep end") -- inferred equivalent call
	assertTimeInterval(p3, p4) -- inferred equivalent call
	local v = vector2 - vector
	local sweepWithFloorSupportDetailed = self.Static:SweepWithFloorSupportDetailed(vector, vector2, p, p2, p3, p4)
	local v2

	if sweepWithFloorSupportDetailed ~= nil then
		v2 = staticDetailed(sweepWithFloorSupportDetailed)
	end

	local sweepMoversDetailed = self:SweepMoversDetailed(vector, vector2, p, p2, p3, p4)

	if sweepMoversDetailed ~= nil and shouldReplace(v2, sweepMoversDetailed, v) then
		return sweepMoversDetailed
	end

	return v2
end

function class:SweepWithFloorSupport(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return (sweepResult(self:SweepWithFloorSupportDetailed(vector, vector2, p, p2, p3, p4)))
end

local function moversAreClear(p, vector: Vector3, p2)
	for _, endpointMover in p.EndpointMovers do
		if MoverProxyCache.ContainsEndpoint(endpointMover, vector, p2, p.Config) then
			return false
		end
	end

	return true
end

function class:IsClear(vector: Vector3, p, value: number)
	assertPosition(vector, "composite clearance position") -- inferred equivalent call
	assertTimeFraction(value) -- inferred equivalent call
	assertCurrentPoseInterval(value, value) -- inferred equivalent call
	return self.Static:IsClear(vector, p, value) and moversAreClear(self, vector, p)
end

function class:CanMove(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	assertPosition(vector, "composite sweep start") -- inferred equivalent call
	assertPosition(vector2, "composite sweep end") -- inferred equivalent call
	assertTimeInterval(p3, p4) -- inferred equivalent call
	local sweepDetailed = self.Static:SweepDetailed(vector, vector2, p, p2, p3, p4)
	local sweepMoversDetailed = self:SweepMoversDetailed(vector, vector2, p, p2, p3, p4)

	if sweepMoversDetailed == nil then
		sweepMoversDetailed = sweepDetailed
	elseif not shouldReplace(sweepDetailed, sweepMoversDetailed, vector2 - vector) then
		sweepMoversDetailed = sweepDetailed
	end

	local v

	if sweepMoversDetailed == nil then
		return (self:IsClear(vector2, p, p4))
	else
		v = not sweepMoversDetailed.StartSolid

		if v then
			if sweepMoversDetailed.Fraction >= 1 then
				return (self:IsClear(vector2, p, p4))
			else
				return false
			end
		end
	end

	return v
end

local function groundIdentityLess(mover: number, id: number, p) -- 1 equivalent call inferred from this helper
	if id == p.Support.SourceId then
		return mover < p.Support.Kind
	end

	return id < p.Support.SourceId
end

function class:FindGround(vector: Vector3, p, value: number, value2: number, p2)
	assertPosition(vector, "composite ground position") -- inferred equivalent call
	assertTimeFraction(value2) -- inferred equivalent call
	assertCurrentPoseInterval(value2, value2) -- inferred equivalent call
	local v

	if typeof(value) == "number" and value == value and value > -1e999 then
		v = value < 1e999
	else
		v = false
	end

	if v then
		if value >= 0 then
			v = value <= self.Config.MaxSweepDistance
		else
			v = false
		end
	end

	assert(v, "invalid ground distance")
	local ground = self.Static:FindGround(vector, p, value, value2, p2)
	local v2 = ground == nil and 1e999 or vector.Y - ground.Position.Y
	local v3 = vector + Vector3.new(
		0,
		math.min(self.Config.GroundProbeStartBump, self.Config.MaxSweepDistance - value),
		0
	)
	local v4 = vector - Vector3.new(0, math.min(value + self.Config.ContactEpsilon, self.Config.MaxSweepDistance), 0)
	local v5 = ground

	for _, endpointMover in self.EndpointMovers do
		local sweepEndpoint, normal, v6 = MoverProxyCache.SweepEndpoint(endpointMover, v3, v4, p, self.Config)

		if sweepEndpoint == nil or (v6 or normal.Y < self.Config.WalkableFloor) then
			continue
		end

		local lerped = v3:Lerp(v4, sweepEndpoint)
		local v7 = vector.Y - lerped.Y
		local record = endpointMover.Record
		local v8 = v5 == nil or v7 < v2 - self.Config.HitTieDistance

		if not v8 and v5 ~= nil and math.abs(v7 - v2) <= self.Config.HitTieDistance then
			if math.abs(normal.Y - v5.Normal.Y) > 1e-9 then
				v8 = normal.Y > v5.Normal.Y
			else
				v8 = groundIdentityLess(Enums.SupportKind.Mover, record.Id, v5) -- inferred equivalent call
			end
		end

		if not v8 then
			continue
		end

		v5 = {
			Position = lerped,
			Normal = normal,
			SurfaceFriction = record.SurfaceFriction,
			Support = {
				Kind = Enums.SupportKind.Mover,
				SourceId = record.Id,
				Anchor = record.CFrame:PointToObjectSpace(lerped),
				Velocity = MoverFrame.VelocityAtPoint(record, lerped, 1)
			}
		}
		v2 = v7
	end

	if
		v5 == nil
		or v5 ~= ground and not self.Static:IsClear(v5.Position, p, value2)
		or not moversAreClear(self, v5.Position, p)
	then
		return nil
	end

	return v5
end

function class:FindLadder(vector: Vector3, p, p2: number, p3: number)
	assertCurrentPoseInterval(p3, p3) -- inferred equivalent call
	return self.Static:FindLadder(vector, p, p2, p3)
end

function class.FindMoverPush(p, vector: Vector3, p2, p3: number, p4: number)
	assertPosition(vector, "mover push position") -- inferred equivalent call
	local v

	if p2 == "Ducking" then
		v = p.Config.DuckingHalfSize
	else
		v = p.Config.StandingHalfSize
	end

	local magnitude = v.Magnitude

	for _, endpointMover in p.EndpointMovers do
		local record = endpointMover.Record

		if record.Id <= p3 or not record.Pushes or record.PreviousCFrame == record.CFrame then
			continue
		end

		local v2 = record.BoundingRadius + magnitude
		local vector2 = vector - record.CFrame.Position
		local dot = vector2:Dot(vector2)

		if v2 * v2 < dot then
			continue
		end

		local v3 = (record.CFrame * record.PreviousCFrame:Inverse()):PointToWorldSpace(vector) - vector
		local magnitude2 = v3.Magnitude

		if magnitude2 <= p.Config.ContactEpsilon then
			continue
		end

		local v4 = v3 / magnitude2
		local v5, v6 = MoverProxyCache.PushExitDistances(endpointMover, vector, v4, p2, p.Config, p4)

		if v5 ~= nil and v5 ~= 1e999 and not (v6 < v5) then
			return record.Id, v4 * math.max(magnitude2, v5)
		end
	end

	return nil, createVector(0, 0, 0)
end

function class.PenetratesMover(p, p2: number, vector: Vector3, p3)
	for _, endpointMover in p.EndpointMovers do
		if endpointMover.Record.Id == p2 then
			return MoverProxyCache.PenetratesEndpoint(endpointMover, vector, p3, p.Config)
		end
	end

	return false
end

function class:SetMovementBounds(vector: Vector3, vector2: Vector3)
	self.Static:SetMovementBounds(vector, vector2)
end

function class:ClearMovementBounds()
	self.Static:ClearMovementBounds()
end

return table.freeze(class)