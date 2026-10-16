local CompositeWorld = require(script.Parent.Parent.Collision.CompositeWorld)
local Config = require(script.Parent.Parent.Config)
local DoorSwing = require(script.Parent.Parent.DoorSwing)
local Enums = require(script.Parent.Parent.Enums)
local MoverFrame = require(script.Parent.Parent.Collision.MoverFrame)
local MoverDescriptorCodec = require(script.Parent.Parent.MoverDescriptorCodec)
local MoverProxyCache = require(script.Parent.Parent.Collision.MoverProxyCache)
local MoverTrajectory = require(script.Parent.Parent.MoverTrajectory)
local Serial = require(script.Parent.Parent.Serial)
local Config2 = require(script.Parent.Parent.Simulation.Config)
local MoverComposer = {}
MoverComposer.__index = MoverComposer
local frozen = table.freeze({})

local function effectiveTick(p) -- 7 equivalent calls inferred from this helper
	return p.EffectiveTick
end

local function earlierTick(p: number?, p2: number) -- 4 equivalent calls inferred from this helper
	if p == nil or Serial.deltaUInt32(p2, p) < 0 then
		return p2
	end

	return p
end

local function nextRevision(p: number) -- 3 equivalent calls inferred from this helper
	if Serial.UInt32Max <= p then
		return 1
	end

	return p + 1
end

local function sameGeometry(descriptor, data) -- 1 equivalent call inferred from this helper
	return descriptor.Id == data.Id
		and descriptor.Size == data.Size
		and descriptor.CollisionOffset == data.CollisionOffset
		and descriptor.SurfaceFriction == data.SurfaceFriction
		and descriptor.Behavior == data.Behavior
end

local function sameCollisionDescriptor(data, data2)
	local v

	if
		data.Id == data2.Id
		and data.Size == data2.Size
		and data.CollisionOffset == data2.CollisionOffset
		and data.SurfaceFriction == data2.SurfaceFriction
	then
		v = data.Behavior == data2.Behavior
	else
		v = false
	end

	if v then
		if
			data.StartPose == data2.StartPose
			and data.TargetPose == data2.TargetPose
			and data.EffectiveTick == data2.EffectiveTick
			and data.StartTick == data2.StartTick
			and data.DurationTicks == data2.DurationTicks
			and data.Moving == data2.Moving
			and data.Active == data2.Active
		then
			return data.Revision == data2.Revision
		else
			return false
		end
	end

	return v
end

local function posesMatch(cframe: CFrame?, cframe2: CFrame?) -- 1 equivalent call inferred from this helper
	if cframe == nil or cframe2 == nil then
		return cframe == cframe2
	end

	if (cframe.Position - cframe2.Position).Magnitude > 0.00001 then
		return false
	end

	local _, v = cframe.Rotation:ToObjectSpace(cframe2.Rotation):ToAxisAngle()
	return math.abs(v) <= 0.00001
end

local function stanceBoundingRadius(p) -- 2 equivalent calls inferred from this helper
	local v

	if p == "Ducking" then
		v = Config2.Default.PlayerSizeDucking
	else
		v = Config2.Default.PlayerSizeStanding
	end

	return (v * 0.5).Magnitude
end

local function distanceSquaredToSegment(vector: Vector3, position: Vector3, position2: Vector3)
	local vector2 = position2 - position
	local dot = vector2:Dot(vector2)

	if dot <= 1e-12 then
		local vector3 = vector - position
		return vector3:Dot(vector3)
	end

	local vector3 = vector - (position + vector2 * math.clamp((vector - position):Dot(vector2) / dot, 0, 1))
	return vector3:Dot(vector3)
end

local function recordMayAffectPosition(record, vector: Vector3, p) -- 1 equivalent call inferred from this helper
	local v = record.BoundingRadius + stanceBoundingRadius(p) + 0.25 -- inferred equivalent call
	return distanceSquaredToSegment(vector, record.PreviousCFrame.Position, record.CFrame.Position) <= v * v
end

local function descriptorMayAffectPosition(data, position: Vector3, stance) -- 3 equivalent calls inferred from this helper
	local v = (data.Size * 0.5).Magnitude + data.CollisionOffset.Position.Magnitude + stanceBoundingRadius(stance) + 0.25 -- inferred equivalent call
	return distanceSquaredToSegment(position, data.StartPose.Position, data.TargetPose.Position) <= v * v
end

local function appendDescriptor(p, data)
	local v, v2 = MoverTrajectory.Validate(data)

	if not v then
		return false, v2
	end

	local v3 = p[data.Id]

	if v3 == nil then
		v3 = { Descriptors = {}, Speculative = frozen }
		p[data.Id] = v3
	else
		local descriptor = v3.Descriptors[#v3.Descriptors]

		if descriptor ~= nil and not sameGeometry(descriptor, data) then -- inferred equivalent call
			return false, "MoverGeometryChangedInsideRegistration"
		end
	end

	v3.Descriptors[#v3.Descriptors + 1] = data
	return true, nil
end

local function resolve(p, p2: number, flag: boolean?)
	local v = nil

	for _, descriptor in p.Descriptors do
		if Serial.deltaUInt32(p2, effectiveTick(descriptor)) >= 0 then -- inferred equivalent call
			v = descriptor
		end
	end

	if flag == true then
		for _, v2 in p.Speculative do
			if Serial.deltaUInt32(p2, effectiveTick(v2)) >= 0 then -- inferred equivalent call
				v = v2
			end
		end
	end

	return v
end

local function resolvePose(p, p2: number, flag: boolean?)
	local v = resolve(p, p2, flag)

	if v == nil then
		return nil, nil
	end

	return v, MoverTrajectory.EvaluateTick(v, p2)
end

local function predictedPose(p, p2: number) -- 2 equivalent calls inferred from this helper
	if p == nil then
		return nil
	end

	local v = resolve(p, p2, true)

	if v == nil or not v.Active then
		return nil
	end

	return MoverTrajectory.EvaluateTick(v, p2)
end

local function firstPoseDifference(p, p2, p3: number, lastComposedTick: number)
	local deltaUInt32 = Serial.deltaUInt32(lastComposedTick, p3)

	if deltaUInt32 < 0 then
		return nil
	end

	if deltaUInt32 > 1024 then
		p3 = Serial.addUInt32(lastComposedTick, -1024)
		deltaUInt32 = 1024
	end

	for i = 0, deltaUInt32 do
		local v = Serial.addUInt32(p3, i)

		if not posesMatch(predictedPose(p, v), predictedPose(p2, v)) then -- inferred equivalent call
			return v
		end
	end

	return nil
end

local function changeTick(p)
	return p.AffectedTick
end

local function pruneByAge(list, callback, p: number, p2: number)
	if #list < 2 then
		return
	end

	local v = nil

	for k, v2 in list do
		if p2 < Serial.deltaUInt32(p, callback(v2)) then
			v = k
		end
	end

	local v2 = 1

	for k, v3 in list do
		local deltaUInt32 = Serial.deltaUInt32(p, callback(v3))

		if not (k == v or deltaUInt32 < 0 or deltaUInt32 <= p2) then
			continue
		end

		list[v2] = v3
		v2 += 1
	end

	for i = #list, v2, -1 do
		list[i] = nil
	end
end

local function pruneAll(state, p: number, horizonTicks: number)
	pruneByAge(state._revisionChanges, changeTick, p, horizonTicks)

	for _, track in state._tracks do
		pruneByAge(track.Descriptors, effectiveTick, p, horizonTicks)
	end
end

local function cloneTrack(p) -- 2 equivalent calls inferred from this helper
	return { Descriptors = table.clone(p.Descriptors), Speculative = p.Speculative }
end

local function cloneTracks(tracks)
	local result = {}

	for k, item in tracks do
		result[k] = cloneTrack(item) -- inferred equivalent call
	end

	return result
end

local function publishSpeculation(p, p2: number, p3) -- 4 equivalent calls inferred from this helper
	if p._replaySource ~= nil then
		return
	end

	local v = p3.Speculative[#p3.Speculative]

	if v == nil then
		MoverTrajectory.ClearClientSpeculativeDescriptor(p2)
	else
		MoverTrajectory.InstallClientSpeculativeDescriptor(v)
	end
end

local function commitStagedRevision(state, tracks, revision: number, latestCommitTick: number, affectedTick: number)
	state._tracks = tracks
	state._revision = revision
	state._latestCommitTick = latestCommitTick
	state._revisionChanges[#state._revisionChanges + 1] = {
		Revision = revision,
		AffectedTick = affectedTick
	}
	local horizonTicks = state._horizonTicks

	if horizonTicks ~= nil then
		pruneAll(state, latestCommitTick, horizonTicks)
	end
end

local function compareId(p, p2)
	return p.Id < p2.Id
end

local function validateHeader(p, p2, p3)
	if not Serial.isNonZeroUInt16(p) then
		return false, "InvalidMoverEpoch"
	end

	if not Serial.isUInt32(p2) then
		return false, "InvalidMoverRevision"
	end

	if Serial.isUInt32(p3) then
		return true, nil
	end

	return false, "InvalidMoverServerTick"
end

local function checkNextRevision(data, p, p2, p3)
	local epoch = data._epoch
	local revision = data._revision

	if epoch == nil or revision == nil then
		return false, "MoverBaselineRequired"
	end

	if p ~= epoch then
		return false, "MoverEpochMismatch"
	end

	local deltaUInt32 = Serial.deltaUInt32(p2, revision)

	if deltaUInt32 <= 0 then
		return false, nil
	end

	if deltaUInt32 ~= 1 then
		return false, "MoverRevisionGap"
	end

	local v = assert(data._latestCommitTick)

	if Serial.deltaUInt32(p3, v) < 0 then
		return false, "MoverCommitTickRegressed"
	end

	return true, nil
end

function MoverComposer.new()
	return (setmetatable({
		_tracks = {},
		_revisionChanges = {},
		_proxyCache = MoverProxyCache.new()
	}, MoverComposer))
end

function MoverComposer:ForkPrediction()
	local v = MoverComposer.new()
	v._replaySource = self
	local epoch = self._epoch
	local revision = self._revision
	v._epoch = epoch
	v._revision = revision
	local baselineServerTick = self._baselineServerTick
	local latestCommitTick = self._latestCommitTick
	v._baselineServerTick = baselineServerTick
	v._latestCommitTick = latestCommitTick
	v._revisionChanges = table.clone(self._revisionChanges)
	local horizonHz = self._horizonHz
	local horizonTicks = self._horizonTicks
	v._horizonHz = horizonHz
	v._horizonTicks = horizonTicks
	v._lastComposedTick = self._lastComposedTick

	for k, track in self._tracks do
		v._tracks[k] = cloneTrack(track) -- inferred equivalent call
		v._proxyCache:ReserveContactMover(k)
	end

	return v
end

function MoverComposer:ForkControls()
	local forkPrediction = self:ForkPrediction()
	forkPrediction._controlsFork = true
	return forkPrediction
end

function MoverComposer:AdoptReplay(state, p)
	local v = state._replaySource == p and p._replaySource == self
	assert(v, "unrelated mover replay")
	local v2 = self._epoch == state._epoch and self._revision == state._revision
	assert(v2, "mover controls not committed")
	state._replaySource = self
end

local function syncReplaySpeculation(data)
	local replaySource = data._replaySource

	if replaySource == nil or data._controlsFork then
		return
	end

	for k, track in data._tracks do
		local track2 = replaySource._tracks[k]

		if track2 ~= nil and track.Speculative ~= track2.Speculative then
			track.Speculative = track2.Speculative
		end
	end
end

local function installPresentation(state, lastComposedTick: number)
	local v = Serial.addUInt32(lastComposedTick, -1)
	local v2 = {}

	for _, track in state._tracks do
		local v3 = resolve(track, lastComposedTick, true)
		local v4

		if v3 == nil then
			v3 = nil
		else
			v4 = MoverTrajectory.EvaluateTick(v3, lastComposedTick)
		end

		if v3 ~= nil and v4 ~= nil and v3.Active then
			local v5 = resolve(track, v, true)
			local v6

			if v5 ~= nil then
				v6 = MoverTrajectory.EvaluateTick(v5, v)
			end

			MoverTrajectory.InstallClientResolvedPose(v3, lastComposedTick, v6 or v4, v4)
		end

		local v5 = nil

		for _, descriptor in track.Descriptors do
			if Serial.deltaUInt32(lastComposedTick, descriptor.EffectiveTick) >= 0 then
				v5 = descriptor
			end
		end

		if v5 ~= nil then
			v2[#v2 + 1] = v5
		end
	end

	MoverTrajectory.InstallClientResolved(lastComposedTick, v2)
end

function MoverComposer:CommitPrediction(data)
	assert(data._replaySource == self, "mover replay belongs to a different composer")
	local v = self._epoch == data._epoch and self._revision == data._revision
	assert(v, "mover controls changed during replay")
	local lastComposedTick = data._lastComposedTick
	local _lastComposedTick = self._lastComposedTick

	if
		lastComposedTick == nil
		or _lastComposedTick ~= nil and Serial.deltaUInt32(lastComposedTick, _lastComposedTick) <= 0
	then
		return
	end

	self._lastComposedTick = lastComposedTick

	if self._replaySource == nil then
		installPresentation(self, lastComposedTick)
	end
end

function MoverComposer:Revision()
	return self._revision
end

function MoverComposer:Reset()
	table.clear(self._tracks)
	self._epoch = nil
	self._revision = nil
	self._baselineServerTick = nil
	self._latestCommitTick = nil
	self._lastComposedTick = nil
	table.clear(self._revisionChanges)
	self._horizonHz = nil
	self._horizonTicks = nil
	self._proxyCache:Reset()

	if self._replaySource == nil then
		MoverTrajectory.ResetClientDescriptors()
	end
end

function MoverComposer:IsPredictionStateAffected(items, p, p2)
	if type(p2) == "table" and p2.Kind == Enums.SupportKind.Mover and items[p2.SourceId] == true then
		return true
	end

	if type(p) ~= "table" or typeof(p.Position) ~= "Vector3" then
		return true
	end

	for k in items do
		local track = self._tracks[k]

		if track == nil then
			return true
		end

		for _, descriptor in track.Descriptors do
			if descriptorMayAffectPosition(descriptor, p.Position, p.Stance) then -- inferred equivalent call
				return true
			end
		end

		for _, v in track.Speculative do
			if descriptorMayAffectPosition(v, p.Position, p.Stance) then -- inferred equivalent call
				return true
			end
		end
	end

	return false
end

function MoverComposer:PredictDoorUse(instance, vector: Vector3, p: number, p2: number)
	if not Serial.isUInt32(p) or p2 % 1 ~= 0 or p2 <= 0 then
		return nil, "MoverDoorPredictionClockInvalid"
	end

	local attribute = instance:GetAttribute(MoverTrajectory.Attributes.Id)

	if not Serial.isUInt32(attribute) or attribute == 0 then
		return nil, "MoverDoorIdentityUnavailable"
	end

	local track = self._tracks[attribute]

	if track == nil then
		return nil, "MoverDoorTrackUnavailable"
	end

	local v = resolve(track, p, true)
	local targetPose

	if v == nil then
		v = nil
	else
		targetPose = MoverTrajectory.EvaluateTick(v, p)
	end

	if v == nil or targetPose == nil or not v.Active then
		return nil, "MoverDoorPoseUnavailable"
	end

	local revision = nextRevision(v.Revision) -- inferred equivalent call

	if v.Moving then
		if MoverTrajectory.TickAlpha(v, p) < 1 or #track.Speculative >= 2 then
			return nil, "MoverDoorAlreadyMoving"
		end

		revision = nextRevision(revision) -- inferred equivalent call
		targetPose = v.TargetPose
	end

	local doorClosedPivot = instance:GetAttribute("DoorClosedPivot")

	if typeof(doorClosedPivot) ~= "CFrame" then
		return nil, "MoverDoorClosedPoseUnavailable"
	end

	local _, v2 = doorClosedPivot:ToObjectSpace(targetPose):ToOrientation()
	local openAngle = DoorSwing.OpenAngle

	if math.abs(v2) >= DoorSwing.ClosedAngleEpsilon then
		openAngle = 0
	else
		local position = (doorClosedPivot * CFrame.Angles(0, openAngle, 0) * v.CollisionOffset).Position
		local position2 = (doorClosedPivot * CFrame.Angles(0, -openAngle, 0) * v.CollisionOffset).Position

		if not ((position - vector).Magnitude >= (position2 - vector).Magnitude) then
			openAngle = -openAngle
		end
	end

	local targetPose2 = doorClosedPivot * CFrame.Angles(0, openAngle, 0)
	local v3 = math.abs(openAngle - v2)

	if v3 < DoorSwing.TargetEpsilon then
		return nil, "MoverDoorTargetAlreadyReached"
	end

	local durationTicks = math.max(1, (math.ceil(DoorSwing.durationSeconds(v3) * p2)))
	local v4 = Serial.addUInt32(p, 1)
	local v5 = {
		Id = v.Id,
		Size = v.Size,
		CollisionOffset = v.CollisionOffset,
		SurfaceFriction = v.SurfaceFriction,
		StartPose = targetPose,
		TargetPose = targetPose2,
		EffectiveTick = v4,
		StartTick = Serial.addUInt32(v4, 1),
		DurationTicks = durationTicks,
		StartServerTime = workspace:GetServerTimeNow(),
		DurationSeconds = durationTicks / p2,
		Moving = true,
		Active = true,
		Behavior = v.Behavior,
		Revision = revision
	}
	local canonicalize, v6 = MoverDescriptorCodec.canonicalize(v5)

	if canonicalize == nil then
		return nil, v6
	end

	local clone = table.clone(track.Speculative)
	clone[#clone + 1] = canonicalize
	track.Speculative = table.freeze(clone)
	publishSpeculation(self, attribute, track) -- inferred equivalent call
	return { ServerTick = v4, TargetAngle = openAngle, MoverId = attribute, Revision = revision }, nil
end

function MoverComposer:RejectDoorUse(p: number, p2: number)
	if not Serial.isUInt32(p) or p == 0 or not Serial.isUInt32(p2) or p2 == 0 then
		return nil, "MoverDoorRejectionIdentityInvalid"
	end

	local track = self._tracks[p]

	if track == nil then
		return nil, nil
	end

	for k, v in track.Speculative do
		if v.Revision ~= p2 then
			continue
		end

		local v2 = table.move(track.Speculative, 1, k - 1, 1, {})
		local speculative

		if #v2 == 0 then
			speculative = frozen
		else
			speculative = table.freeze(v2)
		end

		track.Speculative = speculative
		publishSpeculation(self, p, track) -- inferred equivalent call
		return v.EffectiveTick, nil
	end

	return nil, nil
end

local function equivalentBaseline(state, p: number, items)
	for k in items do
		if state._tracks[k] == nil then
			return false
		end
	end

	for k, track in state._tracks do
		local item = items[k]
		local v = nil

		for k2, descriptor in track.Descriptors do
			if Serial.deltaUInt32(p, effectiveTick(descriptor)) >= 0 then -- inferred equivalent call
				v = k2
			end
		end

		local count = 0

		for k2, descriptor in track.Descriptors do
			local active

			if k2 == v then
				active = descriptor.Active
			else
				active = false
			end

			if (v == nil or v < k2) and Serial.deltaUInt32(effectiveTick(descriptor), p) > 0 then -- inferred equivalent call
				local descriptor2 = track.Descriptors[k2 + 1]
				active = descriptor2 == nil or effectiveTick(descriptor2) ~= effectiveTick(descriptor) -- inferred equivalent call
			end

			if not active then
				continue
			end

			count += 1
			local v2

			if item then
				v2 = item.Descriptors[count]
			end

			if
				v2 == nil
				or not sameCollisionDescriptor(descriptor, v2)
				or descriptor.StartServerTime ~= v2.StartServerTime
				or descriptor.DurationSeconds ~= v2.DurationSeconds
			then
				return false
			end
		end

		if (item and #item.Descriptors or 0) ~= count then
			return false
		end
	end

	return true
end

function MoverComposer:ConsumeBaseline(epoch, revision, p, items, items2)
	local v, v2

	if Serial.isNonZeroUInt16(epoch) then
		if Serial.isUInt32(revision) then
			if Serial.isUInt32(p) then
				v = true
			else
				v = false
				v2 = "InvalidMoverServerTick"
			end
		else
			v = false
			v2 = "InvalidMoverRevision"
		end
	else
		v = false
		v2 = "InvalidMoverEpoch"
	end

	if not v then
		return false, v2
	end

	if type(items) ~= "table" then
		return false, "MoverDescriptorsNotTable"
	end

	if items2 ~= nil and (type(items2) ~= "table" or next(items2) ~= nil) then
		return false, "MoverProgressUnsupported"
	end

	local tracks = {}

	for _, item in items do
		local v3, v4 = appendDescriptor(tracks, item)

		if not v3 then
			return false, v4
		end
	end

	if self._epoch == epoch and self._revision == revision and equivalentBaseline(self, p, tracks) then
		local latestCommitTick = self._latestCommitTick

		if latestCommitTick ~= nil and Serial.deltaUInt32(p, latestCommitTick) > 0 then
			self._latestCommitTick = p
		end

		local horizonTicks = self._horizonTicks

		if horizonTicks ~= nil then
			pruneAll(self, assert(self._latestCommitTick), horizonTicks)
		end

		return true, nil, nil, nil, false
	else
		self._tracks = tracks
		self._proxyCache:Reset()

		for k in tracks do
			self._proxyCache:ReserveContactMover(k)
		end

		self._epoch = epoch
		self._revision = revision
		self._baselineServerTick = p
		self._latestCommitTick = p
		self._revisionChanges = {
			{ Revision = revision, AffectedTick = p }
		}

		if self._replaySource == nil then
			MoverTrajectory.InstallClientBaseline(items, p)
		end

		return true, nil, nil, nil, true
	end
end

local function settleSpeculation(state, p: number?)
	local speculative = state.Speculative

	if #speculative == 0 then
		return p
	end

	local revision = state.Descriptors[#state.Descriptors].Revision
	local v = false
	local v2 = {}

	for _, v3 in speculative do
		if v or not (Serial.deltaUInt32(revision, v3.Revision) < 0) then
			if not v then
				local v4 = false

				for _, descriptor in state.Descriptors do
					if descriptor.Revision == v3.Revision then
						v4 = sameCollisionDescriptor(v3, descriptor)
					end
				end

				v = not v4
			end

			p = earlierTick(p, v3.EffectiveTick) -- inferred equivalent call
		else
			v2[#v2 + 1] = v3
		end
	end

	if #v2 == #speculative then
		return p
	end

	local speculative2

	if #v2 == 0 then
		speculative2 = frozen
	else
		speculative2 = table.freeze(v2)
	end

	state.Speculative = speculative2
	return p
end

function MoverComposer:ConsumeDelta(p, revision, latestCommitTick, list)
	local v, v2

	if Serial.isNonZeroUInt16(p) then
		if Serial.isUInt32(revision) then
			if Serial.isUInt32(latestCommitTick) then
				v = true
			else
				v = false
				v2 = "InvalidMoverServerTick"
			end
		else
			v = false
			v2 = "InvalidMoverRevision"
		end
	else
		v = false
		v2 = "InvalidMoverEpoch"
	end

	if not v then
		return nil, v2, false
	end

	local v3, v4 = checkNextRevision(self, p, revision, latestCommitTick)

	if not v3 then
		return nil, v4, false
	end

	if type(list) ~= "table" or #list == 0 then
		return nil, "MoverDeltaEmpty", false
	end

	local tracks = cloneTracks(self._tracks)
	local result = {}
	local v5 = {}

	for _, v6 in list do
		local v7, v8 = appendDescriptor(tracks, v6)

		if not v7 then
			return nil, v8, false
		end

		result[v6.Id] = true
		local id = v6.Id
		local v9 = v5[v6.Id]
		local v10 = effectiveTick(v6) -- inferred equivalent call

		if v9 ~= nil and not (Serial.deltaUInt32(v10, v9) < 0) then
			v10 = v9
		end

		v5[id] = v10
	end

	local lastComposedTick = self._lastComposedTick
	local v6 = nil
	local v7 = nil

	for k in result do
		local v8 = settleSpeculation(tracks[k], v5[k])
		v6 = earlierTick(v6, v8) -- inferred equivalent call

		if lastComposedTick == nil then
			v7 = earlierTick(v7, v8) -- inferred equivalent call
		else
			local v9 = firstPoseDifference(self._tracks[k], tracks[k], v8, lastComposedTick)

			if v9 ~= nil then
				v7 = earlierTick(v7, v9) -- inferred equivalent call
			end
		end
	end

	commitStagedRevision(self, tracks, revision, latestCommitTick, assert(v6))

	for k in result do
		self._proxyCache:ReserveContactMover(k)
	end

	if self._replaySource == nil then
		MoverTrajectory.InstallClientDelta(list, latestCommitTick)

		for k in result do
			publishSpeculation(self, k, self._tracks[k]) -- inferred equivalent call
		end
	end

	return v7, nil, v7 == nil, result
end

function MoverComposer.ConsumeProgress(_, p, p2, p3, _)
	local flag, v

	if Serial.isNonZeroUInt16(p) then
		if Serial.isUInt32(p2) then
			if Serial.isUInt32(p3) then
				flag = true
			else
				flag = false
				v = "InvalidMoverServerTick"
			end
		else
			flag = false
			v = "InvalidMoverRevision"
		end
	else
		flag = false
		v = "InvalidMoverEpoch"
	end

	if flag then
		return nil, "MoverProgressUnsupported", false
	end

	return nil, v, false
end

function MoverComposer:ComposeTick(p: number, flag: boolean?)
	local baselineServerTick = self._baselineServerTick

	if
		flag == true
		and baselineServerTick ~= nil
		and Serial.isUInt32(p)
		and Serial.deltaUInt32(p, baselineServerTick) < 0
	then
		return baselineServerTick
	end

	return p
end

local function predictLocalHold(state, track, data, cframe: CFrame, cframe2: CFrame, serverTick: number, data2)
	local contactState = data2.ContactState

	if contactState == nil or data.Behavior ~= "StopOnBlock" or not data.Moving or cframe == cframe2 then
		return nil, nil
	end

	if not descriptorMayAffectPosition(data, contactState.Position, contactState.Stance) then -- inferred equivalent call
		return nil, nil
	end

	local v = MoverFrame.Build(data2.StepSeconds, {
		{
			Id = data.Id,
			PreviousCFrame = MoverTrajectory.CollisionPose(data, cframe),
			CFrame = MoverTrajectory.CollisionPose(data, cframe2),
			Size = data.Size,
			SurfaceFriction = data.SurfaceFriction
		}
	})
	local v2 = { Id = 0, Position = contactState.Position, Stance = contactState.Stance }
	local config = data2.StaticWorld.Topology.Config

	if state._proxyCache:FindEarliestStationaryContact(v.ById[data.Id], { v2 }, config) == nil then
		return nil, nil
	end

	local v3 = MoverDescriptorCodec.canonicalize({
		Id = data.Id,
		Size = data.Size,
		CollisionOffset = data.CollisionOffset,
		SurfaceFriction = data.SurfaceFriction,
		StartPose = cframe,
		TargetPose = cframe,
		EffectiveTick = serverTick,
		StartTick = serverTick,
		DurationTicks = 0,
		StartServerTime = workspace:GetServerTimeNow(),
		DurationSeconds = 0,
		Moving = false,
		Active = true,
		Behavior = data.Behavior,
		Revision = nextRevision(data.Revision) -- inferred equivalent call
	})

	if v3 == nil then
		return nil, nil
	end

	local clone = table.clone(track.Speculative)
	clone[#clone + 1] = v3
	track.Speculative = table.freeze(clone)
	publishSpeculation(state, data.Id, track) -- inferred equivalent call
	return v3, MoverTrajectory.EvaluateTick(v3, serverTick)
end

local function compose(state, data, flag: boolean)
	syncReplaySpeculation(state)
	local serverTick = data.ServerTick
	local previousServerTick = data.PreviousServerTick
	local stepSeconds = data.StepSeconds

	if not (Serial.isUInt32(serverTick) and Serial.isUInt32(previousServerTick)) then
		return nil, "MoverComposerTickInvalid"
	end

	local revision = state._revision
	local baselineServerTick = state._baselineServerTick

	if revision == nil or baselineServerTick == nil then
		return nil, "MoverBaselineRequired"
	end

	if data.Mapping.TopologyEpoch ~= state._epoch then
		return nil, "MoverEpochMismatch"
	end

	if Serial.deltaUInt32(serverTick, baselineServerTick) < 0 and data.Speculative ~= true then
		return nil, "MoverFrameOutsideRetention"
	end

	local tick = MoverComposer.ComposeTick(state, serverTick, data.Speculative)

	if tick ~= serverTick then
		previousServerTick = tick
		serverTick = previousServerTick
		previousServerTick = serverTick
	end

	local simulationHz = data.Mapping.SimulationHz

	if state._horizonHz ~= simulationHz then
		state._horizonHz = simulationHz
		state._horizonTicks = Config.derive(simulationHz).PredictionReplayTicks
	end

	local v = assert(state._horizonTicks)
	local v2 = assert(state._latestCommitTick)
	pruneByAge(state._revisionChanges, changeTick, v2, v)
	local moverRevision = data.MoverRevision

	if moverRevision ~= nil then
		if not Serial.isUInt32(moverRevision) then
			return nil, "MoverRevisionInvalid"
		end

		if revision ~= moverRevision then
			local v3 = false

			for _, revisionChange in state._revisionChanges do
				if revisionChange.Revision == moverRevision then
					v3 = true
				elseif v3 and Serial.deltaUInt32(serverTick, revisionChange.AffectedTick) >= 0 then
					return nil, "MoverRevisionUnavailable"
				end
			end

			if not v3 then
				return nil, "MoverRevisionUnavailable"
			end
		end
	end

	local v3 = not flag and state._replaySource == nil
	local v4 = {}
	local v5 = {}
	local v6 = {}

	for k, track in state._tracks do
		local v7 = resolve(track, serverTick, true)
		local v8

		if v7 == nil then
			v7 = nil
		else
			v8 = MoverTrajectory.EvaluateTick(v7, serverTick)
		end

		pruneByAge(track.Descriptors, effectiveTick, v2, v)

		if v7 == nil then
			continue
		end

		if v3 then
			local v9 = nil

			for _, descriptor in track.Descriptors do
				if Serial.deltaUInt32(serverTick, descriptor.EffectiveTick) >= 0 then
					v9 = descriptor
				end
			end

			if v9 ~= nil then
				v6[#v6 + 1] = v9
			end
		end

		if v7.Active then
			local v9 = resolve(track, previousServerTick, true)
			local v10

			if v9 ~= nil then
				v10 = MoverTrajectory.EvaluateTick(v9, previousServerTick)
			end

			if v10 == nil and v8 ~= nil and v7.EffectiveTick == serverTick then
				v10 = v8
			end

			if v10 == nil or v8 == nil then
				return nil, "MoverReplayPoseUnavailable"
			end

			if v3 then
				local v11, v12 = predictLocalHold(state, track, v7, v10, v8, serverTick, data)

				if v11 ~= nil and v12 ~= nil then
					v8 = v12
					v7 = v11
				end

				MoverTrajectory.InstallClientResolvedPose(v7, serverTick, v10, v8)
			end

			v4[#v4 + 1] = {
				Id = k,
				PreviousCFrame = MoverTrajectory.CollisionPose(v7, v10),
				CFrame = MoverTrajectory.CollisionPose(v7, v8),
				Size = v7.Size,
				SurfaceFriction = v7.SurfaceFriction,
				Pushes = v7.Behavior == "Pusher"
			}
		elseif not flag and v < Serial.deltaUInt32(v2, v7.EffectiveTick) then
			v5[#v5 + 1] = k
		end
	end

	if #v5 > 0 then
		for _, v7 in v5 do
			state._tracks[v7] = nil
			state._proxyCache:Retire(v7)
		end

		if state._replaySource == nil then
			MoverTrajectory.RetireClientDescriptors(v5)
		end
	end

	table.sort(v4, compareId)
	local v7 = MoverFrame.Build(stepSeconds, v4)

	if v3 then
		MoverTrajectory.InstallClientResolved(serverTick, v6)
	end

	if not flag then
		state._lastComposedTick = serverTick
	end

	local query = CompositeWorld.new(data.StaticWorld, v7, { Cache = state._proxyCache })
	return {
		Query = query,
		MoverSensitiveAt = function(p, p2)
			for _, record in v7.Records do
				if record.PreviousCFrame ~= record.CFrame and recordMayAffectPosition(record, p, p2) then -- inferred equivalent call
					return true
				end
			end

			return false
		end,
		ResolveSupportMotion = function(p)
			return MoverFrame.ResolveSupportMotion(v7, p)
		end,
		CanOccupyAtEnd = function(p, p2, p3)
			return query:CanMove(p2, p3, p.Stance, nil, 1, 1)
		end
	}, nil
end

function MoverComposer.Compose(p, p2)
	return compose(p, p2, false)
end

local class = {}
class.__index = class

function class:ComposeTick(p: number, flag: boolean?)
	return MoverComposer.ComposeTick(self._composer, p, flag)
end

function class:Compose(p)
	return compose(self._composer, p, true)
end

function MoverComposer:ValidationView()
	local validationView = self._validationView

	if validationView == nil then
		validationView = setmetatable({ _composer = self }, class)
		self._validationView = validationView
	end

	return validationView
end

function MoverComposer:Destroy()
	self:Reset()
end

return MoverComposer