local createVector = vector.create
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.Parent.Config)
local Mapping = require(script.Parent.Parent.Mapping)
local PlayerBroadphase = require(script.Parent.Parent.Simulation.PlayerBroadphase)
local Quantization = require(script.Parent.Parent.Quantization)
local RootFrame = require(script.Parent.Parent.RootFrame)
local RemoteActorIdentity = require(script.Parent.Parent.RemoteActorIdentity)
local RemoteSnapshotCodec = require(script.Parent.Parent.RemoteSnapshotCodec)
local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
local class = {}
class.__index = class
local class2 = {}
class2.__index = class2

local function cloneActor(data)
	return {
		UserId = data.UserId,
		ActorId = data.ActorId,
		Generation = data.Generation,
		Position = data.Position,
		Velocity = data.Velocity,
		LookYaw = data.LookYaw,
		VerticalLook = data.VerticalLook,
		MovementMode = data.MovementMode,
		Stance = data.Stance,
		OnGround = data.OnGround,
		DuckAmount = data.DuckAmount,
		SupportKind = data.SupportKind,
		SupportSourceId = data.SupportSourceId
	}
end

local function restoredStudioUserId(p: number)
	if p == 0 or not RunService:IsStudio() or Players:GetPlayerByUserId(p) ~= nil then
		return p
	end

	local v = -p

	if Players:GetPlayerByUserId(v) == nil then
		return p
	end

	return v
end

local function restoreStudioActor(p)
	if not RunService:IsStudio() then
		return p
	end

	local actor = cloneActor(p)
	local userId = actor.UserId

	if userId ~= 0 and RunService:IsStudio() and Players:GetPlayerByUserId(userId) == nil then
		local v = -userId

		if Players:GetPlayerByUserId(v) ~= nil then
			userId = v
		end
	end

	actor.UserId = userId
	return actor
end

local function actorStatesEqual(actor, data)
	if
		actor.UserId == data.UserId
		and actor.ActorId == data.ActorId
		and actor.Generation == data.Generation
		and actor.Position == data.Position
		and actor.Velocity == data.Velocity
		and actor.LookYaw == data.LookYaw
		and actor.VerticalLook == data.VerticalLook
		and actor.MovementMode == data.MovementMode
		and actor.Stance == data.Stance
		and actor.OnGround == data.OnGround
		and actor.DuckAmount == data.DuckAmount
		and actor.SupportKind == data.SupportKind
	then
		return actor.SupportSourceId == data.SupportSourceId
	else
		return false
	end
end

local function shortestAngleLerp(lookYaw: number, lookYaw2: number, p: number) -- 1 equivalent call inferred from this helper
	return lookYaw + ((lookYaw2 - lookYaw + 3.141592653589793) % 6.283185307179586 - 3.141592653589793) * p
end

local function makePose(actor, serverTick: number, topologyRevision: number, interpolationAlpha: number, extrapolatedSeconds: number, vector: Vector3?, vector2: Vector3?, p: number?, p2: number?, p3: number?, options)
	local v = options or {}
	v.UserId = actor.UserId
	v.ActorId = actor.ActorId
	v.Generation = actor.Generation
	v.Position = vector or actor.Position
	v.Velocity = vector2 or actor.Velocity
	v.LookYaw = p or actor.LookYaw
	v.VerticalLook = p2 or actor.VerticalLook
	v.MovementMode = actor.MovementMode
	v.Stance = actor.Stance
	v.OnGround = actor.OnGround
	v.DuckAmount = p3 or actor.DuckAmount
	v.SupportKind = actor.SupportKind
	v.SupportSourceId = actor.SupportSourceId
	v.SourceServerTick = serverTick
	v.TopologyRevision = topologyRevision
	v.InterpolationAlpha = interpolationAlpha
	v.ExtrapolatedSeconds = extrapolatedSeconds
	v.VisualRootPosition = RootFrame.simulationToVisualRootPosition(v.Position, v.DuckAmount)
	return v
end

local function sampleVisualRoot(state) -- 2 equivalent calls inferred from this helper
	local visualRoot = state.VisualRoot

	if visualRoot == nil then
		visualRoot = RootFrame.simulationToVisualRootPosition(state.Actor.Position, state.Actor.DuckAmount)
		state.VisualRoot = visualRoot
	end

	return visualRoot
end

local function interpolateSample(data, data2, value: number, p)
	local interpolationAlpha = math.clamp(value, 0, 1)
	local actor

	if interpolationAlpha < 0.5 then
		actor = data.Actor
	else
		actor = data2.Actor
	end

	local serverTick

	if interpolationAlpha < 0.5 then
		serverTick = data.ServerTick
	else
		serverTick = data2.ServerTick
	end

	local topologyRevision

	if interpolationAlpha < 0.5 then
		topologyRevision = data.TopologyRevision
	else
		topologyRevision = data2.TopologyRevision
	end

	local v = makePose(
		actor,
		serverTick,
		topologyRevision,
		interpolationAlpha,
		0,
		data.Actor.Position:Lerp(data2.Actor.Position, interpolationAlpha),
		data.Actor.Velocity:Lerp(data2.Actor.Velocity, interpolationAlpha),
		shortestAngleLerp(data.Actor.LookYaw, data2.Actor.LookYaw, interpolationAlpha), -- inferred equivalent call
		data.Actor.VerticalLook + (data2.Actor.VerticalLook - data.Actor.VerticalLook) * interpolationAlpha,
		data.Actor.DuckAmount + (data2.Actor.DuckAmount - data.Actor.DuckAmount) * interpolationAlpha,
		p
	)
	v.VisualRootPosition = sampleVisualRoot(data):Lerp(sampleVisualRoot(data2), interpolationAlpha) -- inferred equivalent call
	return v
end

local function validateClock(p: number, value: number?)
	if not Serial.isUInt32(p) then
		return nil, "InvalidCurrentServerTick"
	end

	local v = value or 0

	if Quantization.isFinite(v) and not (v < 0 or v >= 1) then
		return v, nil
	end

	return nil, "InvalidTickFraction"
end

local function relativeTick(serverTick: number, p: number) -- 8 equivalent calls inferred from this helper
	return Serial.deltaUInt32(serverTick, p)
end

function class2.new(p)
	local v, v2 = Mapping.validate(p)
	assert(v, v2 or "invalid command mapping")
	local derive = Config.derive(p.SimulationHz)
	local remoteHistoryTicks

	if RunService:IsStudio() then
		remoteHistoryTicks = math.max(derive.RemoteHistoryTicks, (math.ceil(p.SimulationHz * 0.75)))
	else
		remoteHistoryTicks = derive.RemoteHistoryTicks
	end

	local maxSamplesPerActor = math.max(2, math.ceil(remoteHistoryTicks / derive.RemoteSnapshotEveryTicks) + 2)
	return (setmetatable({
		_mapping = Mapping.clone(p),
		_config = derive,
		_retentionHistoryTicks = remoteHistoryTicks,
		_maxSamplesPerActor = maxSamplesPerActor,
		_actors = {},
		_actorIdToKey = {},
		_orderedActorKeys = table.freeze({}),
		_actorOrderDirty = false,
		_frames = {},
		_baselineActorsByActorId = {},
		_retainedBaselines = {},
		_retainedBaselineOrder = {},
		_heldDeltas = {},
		_collisionBroadphase = PlayerBroadphase.new(),
		_collisionQueryActorIds = {},
		_collisionQueryActorKeys = {},
		_presentationPoseByActorKey = {}
	}, class2))
end

function class2:sharesStream(data)
	local mapping = self._mapping
	return mapping.TopologyEpoch == data.TopologyEpoch
		and mapping.TopologyFingerprint == data.TopologyFingerprint
		and mapping.SimulationHz == data.SimulationHz
end

function class2:getCollisionPoseByActorId(p: number, p2: number, p3: number?)
	local v = self._actorIdToKey[p]

	if v == nil then
		return nil, "ActorIdNotBuffered"
	end

	local collisionPose, v2 = self:getCollisionPose(v, p2, p3)

	if collisionPose == nil or collisionPose.ActorId == p then
		return collisionPose, v2
	end

	return nil, "ActorIdInactive"
end

function class2:actorKeys()
	if not self._actorOrderDirty then
		return self._orderedActorKeys
	end

	local v = {}

	for k in self._actors do
		table.insert(v, k)
	end

	table.sort(v, RemoteActorIdentity.keyLess)
	self._orderedActorKeys = table.freeze(v)
	self._actorOrderDirty = false
	return self._orderedActorKeys
end

function class2:latestServerTick()
	return self._latestServerTick
end

function class2:latestCompleteServerTick()
	return self._latestCompleteServerTick
end

function class2:queryCollisionActorKeys(vector: Vector3, vector2: Vector3)
	local query = self._collisionBroadphase:query(vector, vector2, self._collisionQueryActorIds)
	local collisionQueryActorKeys = self._collisionQueryActorKeys
	table.clear(collisionQueryActorKeys)

	for _, v in query do
		local v2 = self._actorIdToKey[v]

		if v2 ~= nil then
			collisionQueryActorKeys[#collisionQueryActorKeys + 1] = v2
		end
	end

	return collisionQueryActorKeys
end

local function forgetActorId(state, p, p2: number) -- 3 equivalent calls inferred from this helper
	state._collisionBroadphase:remove(p2)

	if state._actorIdToKey[p2] == p then
		state._actorIdToKey[p2] = nil
	end
end

function class2:forgetActor(p)
	local actor = self._actors[p]

	if actor == nil then
		return
	end

	for _, v in actor.ActorIdsByGeneration do
		forgetActorId(self, p, v) -- inferred equivalent call
	end

	self._collisionFrame = nil
	self._actors[p] = nil
	self._presentationPoseByActorKey[p] = nil
	self._actorOrderDirty = true
end

local frozen = table.freeze({})
local v = {}
local v2 = {}

function class2:_prune()
	local latestServerTick = self._latestServerTick

	if latestServerTick == nil then
		return
	end

	local retentionHistoryTicks = self._retentionHistoryTicks

	for k, frame in self._frames do
		if retentionHistoryTicks < Serial.deltaUInt32(latestServerTick, frame.ServerTick) then
			self._frames[k] = nil
		end
	end

	for k, actor in self._actors do
		local sample = actor.Samples[#actor.Samples]
		local v3 = actor.Activity[#actor.Activity]
		local v4

		if v3 == nil then
			v4 = false
		else
			v4 = not v3.Active
		end

		if
			sample == nil
			or not (v4 and retentionHistoryTicks < Serial.deltaUInt32(latestServerTick, sample.ServerTick))
		then
			local samples = actor.Samples
			local count = #samples
			local count2 = 0

			while
				count - count2 > 1
				and not (count - count2 <= self._maxSamplesPerActor and Serial.deltaUInt32(
					latestServerTick,
					samples[count2 + 1].ServerTick
				) <= retentionHistoryTicks)
			do
				count2 += 1
			end

			if count2 > 0 then
				table.move(samples, count2 + 1, count, 1)

				for i = count - count2 + 1, count do
					samples[i] = nil
				end
			end

			local activity = actor.Activity
			local count3 = #activity
			local count4 = 0

			while
				count3 - count4 > 1
				and not (Serial.deltaUInt32(latestServerTick, activity[count4 + 2].ServerTick) <= retentionHistoryTicks)
			do
				count4 += 1
			end

			if count4 > 0 then
				table.move(activity, count4 + 1, count3, 1)

				for i = count3 - count4 + 1, count3 do
					activity[i] = nil
				end
			end

			local values = v
			table.clear(values)

			for _, sample2 in samples do
				local actor2 = sample2.Actor
				local v5 = values[actor2.Generation]

				if v5 == nil then
					values[actor2.Generation] = actor2.ActorId
				elseif v5 ~= actor2.ActorId then
					values[actor2.Generation] = frozen
					v2[actor2.Generation] = v2[actor2.Generation] or {}
					v2[actor2.Generation][v5] = true
					v2[actor2.Generation][actor2.ActorId] = true
				end
			end

			for k2, v5 in actor.ActorIdsByGeneration do
				local v6 = values[k2]
				local v7

				if v6 == v5 then
					v7 = true
				elseif v6 == frozen then
					v7 = v2[k2][v5] == true
				else
					v7 = false
				end

				if v7 then
					continue
				end

				actor.ActorIdsByGeneration[k2] = nil
				forgetActorId(self, k, v5) -- inferred equivalent call
			end

			table.clear(v2)
		else
			for _, v5 in actor.ActorIdsByGeneration do
				forgetActorId(self, k, v5) -- inferred equivalent call
			end

			self._collisionFrame = nil
			self._actors[k] = nil
			self._presentationPoseByActorKey[k] = nil
			self._actorOrderDirty = true
		end
	end
end

local function upsertActorSample(actor, p)
	local samples = actor.Samples

	for i = #samples, 1, -1 do
		local sample = samples[i]

		if sample.ServerTick == p.ServerTick then
			if not (sample.Sequence ~= p.Sequence and Serial.isNewerUInt32(p.Sequence, sample.Sequence)) then
				return false
			end

			samples[i] = p
			return true
		elseif Serial.deltaUInt32(p.ServerTick, sample.ServerTick) > 0 then
			table.insert(samples, i + 1, p)
			return true
		end
	end

	table.insert(samples, 1, p)
	return true
end

local function continuesRun(data, data2) -- 2 equivalent calls inferred from this helper
	local active = data.Active and data2.Active

	if active then
		if data.Generation == data2.Generation then
			active = data.ActorId == data2.ActorId
		else
			active = false
		end
	end

	return active
end

local function linkRuns(activity, p: number)
	for i = p, #activity do
		local v3 = activity[i]
		local v4 = activity[i - 1]
		local runStart

		if v4 == nil then
			runStart = v3
		elseif continuesRun(v4, v3) then -- inferred equivalent call
			runStart = v4.RunStart
		else
			runStart = v3
		end

		v3.RunStart = runStart
	end
end

local function upsertActivityEvent(p, p2)
	local activity = p.Activity

	for i = #activity, 1, -1 do
		local v3 = activity[i]

		if v3.ServerTick == p2.ServerTick then
			if not (v3.Sequence ~= p2.Sequence and Serial.isNewerUInt32(p2.Sequence, v3.Sequence)) then
				return false
			end

			activity[i] = p2
			linkRuns(activity, i)
			return true
		elseif Serial.deltaUInt32(p2.ServerTick, v3.ServerTick) > 0 then
			table.insert(activity, i + 1, p2)
			linkRuns(activity, i + 1)
			return true
		end
	end

	table.insert(activity, 1, p2)
	linkRuns(activity, 1)
	return true
end

local function activeEvent(data) -- 2 equivalent calls inferred from this helper
	return {
		Sequence = data.Sequence,
		ServerTick = data.ServerTick,
		Active = true,
		Generation = data.Actor.Generation,
		ActorId = data.Actor.ActorId
	}
end

local function inactiveEvent(p, sequence: number) -- 2 equivalent calls inferred from this helper
	return {
		Sequence = sequence,
		ServerTick = p.ServerTick,
		Active = false,
		Generation = 0,
		ActorId = 0
	}
end

local function refreshCollisionIndex(p, actor)
	p._collisionFrame = nil
	local v3 = actor.Activity[#actor.Activity]

	if v3 == nil or not v3.Active then
		for _, v4 in actor.ActorIdsByGeneration do
			p._collisionBroadphase:remove(v4)
		end
	else
		for _, v4 in actor.ActorIdsByGeneration do
			if v4 ~= v3.ActorId then
				p._collisionBroadphase:remove(v4)
			end
		end

		for i = #actor.Samples, 1, -1 do
			local sample = actor.Samples[i]

			if not (sample.Actor.Generation == v3.Generation and sample.Actor.ActorId == v3.ActorId) then
				continue
			end

			p._collisionBroadphase:upsert(sample.Actor.ActorId, sample.Actor.Position)
			return
		end
	end
end

local function reconcileCompleteFrames(object, key, actor, actorId: number)
	for k, frame in object._frames do
		if not (frame.AuthoritativeLifecycle and (frame.Kind == "Baseline" and not frame.SeenActorKeys[key] or (frame.RemovedActorKeys[key] or frame.RemovedActorIds[actorId]) and not frame.SeenActorKeys[key])) then
			continue
		end

		upsertActivityEvent(actor, inactiveEvent(frame, k)) -- inferred equivalent call
	end
end

local function applyFrameLifecycle(state, sequence: number, state2)
	if state2.AuthoritativeLifecycle then
		return
	end

	state2.AuthoritativeLifecycle = true
	local latestCompleteServerTick = state._latestCompleteServerTick

	if latestCompleteServerTick == nil or Serial.isNewerUInt32(state2.ServerTick, latestCompleteServerTick) then
		state._latestCompleteServerTick = state2.ServerTick
	end

	if state2.Kind == "Delta" and state2.BaselineSequence == state._baselineSequence then
		for k, actor2 in state._baselineActorsByActorId do
			if state2.SeenActorIds[k] or state2.RemovedActorIds[k] then
				continue
			end

			if RunService:IsStudio() then
				actor2 = cloneActor(actor2)
				local userId = actor2.UserId

				if userId ~= 0 and RunService:IsStudio() and Players:GetPlayerByUserId(userId) == nil then
					local v3 = -userId

					if Players:GetPlayerByUserId(v3) ~= nil then
						userId = v3
					end
				end

				actor2.UserId = userId
			end

			local key = RemoteActorIdentity.key(actor2)
			state2.SeenActorKeys[key] = true
			state2.SeenActorIds[k] = true
			local actor = state._actors[key]
			local v3

			if actor ~= nil then
				v3 = actor.Samples[#actor.Samples]
			end

			local v4

			if actor ~= nil then
				v4 = actor.Activity[#actor.Activity]
			end

			if not (actor ~= nil and (v3 == nil or not actorStatesEqual(v3.Actor, actor2) or v4 == nil or not v4.Active or v4.ActorId ~= k or v4.Generation ~= actor2.Generation)) then
				continue
			end

			local v5 = {
				Sequence = sequence,
				ServerTick = state2.ServerTick,
				TopologyRevision = state2.TopologyRevision,
				Actor = actor2
			}
			upsertActorSample(actor, v5)
			upsertActivityEvent(actor, activeEvent(v5)) -- inferred equivalent call
			refreshCollisionIndex(state, actor)
		end
	end

	for k in state2.RemovedActorIds do
		local v3 = state._actorIdToKey[k]

		if v3 ~= nil then
			state2.RemovedActorKeys[v3] = true
		end
	end

	for k, actor in state._actors do
		if not (state2.Kind == "Baseline" and not state2.SeenActorKeys[k] or state2.RemovedActorKeys[k] and not state2.SeenActorKeys[k]) then
			continue
		end

		upsertActivityEvent(actor, inactiveEvent(state2, sequence)) -- inferred equivalent call
		refreshCollisionIndex(state, actor)
	end
end

local function retainBaseline(state, p: number, p2)
	local retainedBaselineOrder = state._retainedBaselineOrder

	if state._retainedBaselines[p] ~= nil then
		return
	end

	local v3 = #retainedBaselineOrder + 1

	for k, v4 in retainedBaselineOrder do
		if not Serial.isNewerUInt32(v4, p) then
			continue
		end

		v3 = k
		break
	end

	table.insert(retainedBaselineOrder, v3, p)
	state._retainedBaselines[p] = p2

	while #retainedBaselineOrder > 3 do
		state._retainedBaselines[table.remove(retainedBaselineOrder, 1)] = nil
	end
end

local function admitCompleteFrame(object, sequence: number, frame)
	if frame.Kind == "Baseline" then
		local baselineActorsByActorId = {}

		for k, v3 in frame.BaselineActorsByActorId do
			baselineActorsByActorId[k] = cloneActor(v3)
		end

		retainBaseline(object, sequence, baselineActorsByActorId)
		local baselineSequence = object._baselineSequence

		if baselineSequence == nil or Serial.isNewerUInt32(sequence, baselineSequence) then
			object._baselineActorsByActorId = baselineActorsByActorId
			object._baselineSequence = sequence
			object._lastAppliedSequence = sequence
			applyFrameLifecycle(object, sequence, frame)
		end
	else
		local baselineSequence = object._baselineSequence
		local lastAppliedSequence = object._lastAppliedSequence

		if
			baselineSequence ~= nil
			and lastAppliedSequence ~= nil
			and frame.BaselineSequence == baselineSequence
			and Serial.isNewerUInt32(sequence, lastAppliedSequence)
		then
			applyFrameLifecycle(object, sequence, frame)
			object._lastAppliedSequence = sequence
		end
	end
end

local function generationsAreChronological(actor, p, serverTick: number)
	local v3 = next(actor.ActorIdsByGeneration)

	if v3 == p.Generation and next(actor.ActorIdsByGeneration, v3) == nil then
		return true
	end

	for _, sample in actor.Samples do
		local deltaUInt16 = Serial.deltaUInt16(p.Generation, sample.Actor.Generation)
		local deltaUInt32 = Serial.deltaUInt32(serverTick, sample.ServerTick)

		if deltaUInt16 > 0 and deltaUInt32 <= 0 or deltaUInt16 < 0 and deltaUInt32 >= 0 then
			return false
		end
	end

	return true
end

local function expandSnapshotRecords(object, data)
	local result = table.create(#data.Actors + #data.Deltas)

	for _, actor in data.Actors do
		local v3 = #result + 1

		if RunService:IsStudio() then
			actor = cloneActor(actor)
			local userId = actor.UserId

			if userId ~= 0 and RunService:IsStudio() and Players:GetPlayerByUserId(userId) == nil then
				local v4 = -userId

				if Players:GetPlayerByUserId(v4) ~= nil then
					userId = v4
				end
			end

			actor.UserId = userId
		end

		result[v3] = actor
	end

	local baselineActorsByActorId = object._baselineActorsByActorId

	if data.Kind == "Delta" then
		baselineActorsByActorId = object._retainedBaselines[data.BaselineSequence]

		if baselineActorsByActorId == nil then
			return nil, nil, "RemoteBaselineRequired"
		end

		for _, delta in data.Deltas do
			local v3 = baselineActorsByActorId[delta.ActorId]

			if v3 == nil then
				return nil, nil, "RemoteDeltaActorMissingFromBaseline"
			end

			local v4, v5 = RemoteSnapshotCodec.applyDeltaToCanonicalBaseline(v3, delta, true)

			if v4 == nil then
				return nil, nil, v5
			end

			local v6 = #result + 1

			if RunService:IsStudio() then
				v4 = cloneActor(v4)
				local userId = v4.UserId

				if userId ~= 0 and RunService:IsStudio() and Players:GetPlayerByUserId(userId) == nil then
					local v7 = -userId

					if Players:GetPlayerByUserId(v7) ~= nil then
						userId = v7
					end
				end

				v4.UserId = userId
			end

			result[v6] = v4
		end
	elseif #data.Deltas > 0 or #data.RemovedActorIds > 0 then
		return nil, nil, "RemoteBaselineHasDeltaRecords"
	end

	local result2 = table.create(#data.RemovedActorIds)

	for k, removedActorId in data.RemovedActorIds do
		local v3 = baselineActorsByActorId[removedActorId]
		local v4

		if v3 == nil then
			v4 = object._actorIdToKey[removedActorId]
		else
			local key = RemoteActorIdentity.key

			if RunService:IsStudio() then
				v3 = cloneActor(v3)
				local userId = v3.UserId

				if userId ~= 0 and RunService:IsStudio() and Players:GetPlayerByUserId(userId) == nil then
					local v5 = -userId

					if Players:GetPlayerByUserId(v5) ~= nil then
						userId = v5
					end
				end

				v3.UserId = userId
			end

			v4 = key(v3)
		end

		result2[k] = v4
	end

	return result, result2, nil
end

local function holdDelta(object, data)
	local heldDeltas = object._heldDeltas
	local latestServerTick = object._latestServerTick

	for i = #heldDeltas, 1, -1 do
		local v3

		if latestServerTick == nil then
			v3 = false
		else
			v3 = Serial.deltaUInt32(latestServerTick, heldDeltas[i].ServerTick) > object._retentionHistoryTicks
		end

		if v3 or heldDeltas[i].Sequence == data.Sequence and heldDeltas[i].ChunkIndex == data.ChunkIndex then
			table.remove(heldDeltas, i)
		end
	end

	if #heldDeltas >= 24 then
		table.remove(heldDeltas, 1)
	end

	heldDeltas[#heldDeltas + 1] = data
end

local function releaseHeldDeltas(object, sequence: number)
	local heldDeltas = object._heldDeltas
	local v3 = {}

	for i = #heldDeltas, 1, -1 do
		if heldDeltas[i].BaselineSequence == sequence then
			v3[#v3 + 1] = table.remove(heldDeltas, i)
		end
	end

	table.sort(v3, function(a, b)
		return Serial.isNewerUInt32(b.Sequence, a.Sequence)
	end)

	for _, v4 in v3 do
		object:pushDecoded(v4)
	end
end

function class2:pushDecoded(data)
	if
		data.Topology.Epoch ~= self._mapping.TopologyEpoch
		or data.Topology.Fingerprint ~= self._mapping.TopologyFingerprint
	then
		return nil, "TopologyMismatch"
	end

	if data.Kind == "Delta" and self._retainedBaselines[data.BaselineSequence] == nil then
		local baselineSequence = self._baselineSequence

		if baselineSequence ~= nil and not Serial.isNewerUInt32(data.BaselineSequence, baselineSequence) then
			return nil, "RemoteBaselineRequired"
		end

		holdDelta(self, data)
		return nil, "RemoteDeltaHeld"
	else
		local v3, v4, v5 = expandSnapshotRecords(self, data)

		if v3 == nil or v4 == nil then
			return nil, v5
		end

		local frame = self._frames[data.Sequence]

		if
			frame ~= nil
			and (frame.Kind ~= data.Kind or frame.BaselineSequence ~= data.BaselineSequence or frame.ServerTick ~= data.ServerTick or frame.TopologyRevision ~= data.Topology.DestructibleRevision or frame.ChunkCount ~= data.ChunkCount)
		then
			return nil, "ConflictingRemoteFrame"
		end

		if frame ~= nil and frame.ReceivedChunks[data.ChunkIndex] then
			return nil, "DuplicateRemoteChunk"
		end

		local latestServerTick = self._latestServerTick

		if latestServerTick == nil then
			self._latestServerTick = data.ServerTick
			self._latestTopologyRevision = data.Topology.DestructibleRevision
		else
			if Serial.deltaUInt32(latestServerTick, data.ServerTick) > self._retentionHistoryTicks then
				return nil, "RemoteSnapshotTooOld"
			end

			if Serial.isNewerUInt32(data.ServerTick, latestServerTick) then
				if
					self._latestTopologyRevision ~= nil
					and Serial.deltaUInt32(data.Topology.DestructibleRevision, self._latestTopologyRevision) < 0
				then
					return nil, "TopologyRevisionRegressed"
				end

				self._latestServerTick = data.ServerTick
				self._latestTopologyRevision = data.Topology.DestructibleRevision
			end
		end

		if frame == nil then
			frame = {
				Kind = data.Kind,
				BaselineSequence = data.BaselineSequence,
				ServerTick = data.ServerTick,
				TopologyRevision = data.Topology.DestructibleRevision,
				ChunkCount = data.ChunkCount,
				ReceivedChunks = {},
				ReceivedChunkCount = 0,
				SeenActorKeys = {},
				SeenActorIds = {},
				RemovedActorKeys = {},
				RemovedActorIds = {},
				BaselineActorsByActorId = {},
				AuthoritativeLifecycle = false
			}
			self._frames[data.Sequence] = frame
		end

		for _, v6 in v3 do
			local key = RemoteActorIdentity.key(v6)

			if frame.SeenActorKeys[key] then
				return nil, "DuplicateRemoteActorUserId"
			end

			if frame.SeenActorIds[v6.ActorId] or frame.RemovedActorIds[v6.ActorId] then
				return nil, "DuplicateRemoteActorId"
			end

			local v7 = self._actorIdToKey[v6.ActorId]

			if v7 ~= nil and v7 ~= key then
				return nil, "ConflictingActorId"
			end

			local actor = self._actors[key]

			if actor == nil then
				continue
			end

			local v8 = actor.ActorIdsByGeneration[v6.Generation]

			if v8 ~= nil and v8 ~= v6.ActorId then
				return nil, "ActorIdChangedWithinGeneration"
			end
		end

		for _, removedActorId in data.RemovedActorIds do
			if frame.SeenActorIds[removedActorId] or frame.RemovedActorIds[removedActorId] then
				return nil, "DuplicateRemovedRemoteActorId"
			end
		end

		local count = 0

		for _, v6 in v3 do
			local key = RemoteActorIdentity.key(v6)
			local actor = self._actors[key]
			local v7 = actor == nil or actor.ActorIdsByGeneration[v6.Generation] == nil

			if actor == nil then
				actor = {
					Generation = v6.Generation,
					ActorId = v6.ActorId,
					ActorIdsByGeneration = 0,
					Samples = 0,
					Activity = 0
				}
				local actorIdsByGeneration = { [v6.Generation] = v6.ActorId }
				actor.ActorIdsByGeneration = actorIdsByGeneration
				actor.Samples = {}
				actor.Activity = {}
				self._actors[key] = actor
				self._actorOrderDirty = true
			else
				if not generationsAreChronological(actor, v6, data.ServerTick) then
					continue
				end

				if v6.Generation == actor.Generation then
					if v6.ActorId ~= actor.ActorId then
						return nil, "ActorIdChangedWithinGeneration"
					end
				elseif Serial.deltaUInt16(v6.Generation, actor.Generation) > 0 then
					actor.Generation = v6.Generation
					actor.ActorId = v6.ActorId
				end
			end

			actor.ActorIdsByGeneration[v6.Generation] = v6.ActorId
			self._actorIdToKey[v6.ActorId] = key

			if v7 then
				reconcileCompleteFrames(self, key, actor, v6.ActorId)
			end

			local v8 = {
				Sequence = data.Sequence,
				ServerTick = data.ServerTick,
				TopologyRevision = data.Topology.DestructibleRevision,
				Actor = cloneActor(v6)
			}

			if not upsertActorSample(actor, v8) then
				continue
			end

			upsertActivityEvent(actor, activeEvent(v8)) -- inferred equivalent call
			refreshCollisionIndex(self, actor)
			count += 1
		end

		for _, v6 in v3 do
			frame.SeenActorKeys[RemoteActorIdentity.key(v6)] = true
			frame.SeenActorIds[v6.ActorId] = true
		end

		for _, v6 in v4 do
			frame.RemovedActorKeys[v6] = true
		end

		for _, removedActorId in data.RemovedActorIds do
			frame.RemovedActorIds[removedActorId] = true
		end

		if data.Kind == "Baseline" then
			for _, actor in data.Actors do
				frame.BaselineActorsByActorId[actor.ActorId] = cloneActor(actor)
			end
		end

		frame.ReceivedChunks[data.ChunkIndex] = true
		frame.ReceivedChunkCount += 1
		local v6

		if frame.ReceivedChunkCount == frame.ChunkCount then
			admitCompleteFrame(self, data.Sequence, frame)
			v6 = data.Kind == "Baseline"
		else
			v6 = false
		end

		self:_prune()

		if v6 and self._retainedBaselines[data.Sequence] ~= nil and #self._heldDeltas > 0 then
			releaseHeldDeltas(self, data.Sequence)
		end

		return count, nil
	end
end

local function lowerBound(list, p: number, p2: number)
	local v3 = #list + 1
	local v4 = 1

	while v4 < v3 do
		local v5 = (v4 + v3) // 2

		if relativeTick(list[v5].ServerTick, p) < p2 then -- inferred equivalent call
			v4 = v5 + 1
		else
			v3 = v5
		end
	end

	return v4
end

local function upperBound(activity, p: number, p2: number)
	local v3 = #activity + 1
	local v4 = 1

	while v4 < v3 do
		local v5 = (v4 + v3) // 2

		if relativeTick(activity[v5].ServerTick, p) <= p2 then -- inferred equivalent call
			v4 = v5 + 1
		else
			v3 = v5
		end
	end

	return v4
end

local function activityWindow(p, p2: number, p3: number)
	local activity = p.Activity
	local v3 = upperBound(activity, p2, p3) - 1
	local v4 = activity[v3]

	if v4 == nil or not v4.Active then
		return nil, nil, nil, nil
	end

	local generation = v4.Generation
	local actorId = v4.ActorId
	local runStart = v4.RunStart
	local v5

	if runStart == nil then
		local v6 = v3

		while v6 > 1 do
			if not continuesRun(activity[v6 - 1], v4) then -- inferred equivalent call
				break
			end

			v6 -= 1
		end

		v5 = relativeTick(activity[v6].ServerTick, p2) -- inferred equivalent call
	else
		v5 = math.max(relativeTick(runStart.ServerTick, p2), relativeTick(activity[1].ServerTick, p2)) -- inferred equivalent call
	end

	for i = v3 + 1, #activity do
		local v6 = activity[i]

		if not v6.Active or v6.Generation ~= generation or v6.ActorId ~= actorId then
			return generation, actorId, v5, relativeTick(v6.ServerTick, p2)
		end
	end

	return generation, actorId, v5, nil
end

local function inWindow(p, p2: number, p3: number, p4: number, p5: number, p6: number?) -- 3 equivalent calls inferred from this helper
	local actor = p.Actor
	return actor.Generation == p3 and actor.ActorId == p4 and p5 <= p2 and (p6 == nil or p2 < p6)
end

local function bracketActivityWindow(samples, p: number, p2: number, p3: number, p4: number, p5: number, p6: number?)
	local v3 = nil

	for i = #samples, 1, -1 do
		local v4 = samples[i]

		if not inWindow(v4, relativeTick(v4.ServerTick, p), p3, p4, p5, p6) then -- inferred equivalent call
			continue
		end

		v3 = v4
		break
	end

	if v3 == nil then
		return nil, nil, 0, nil
	end

	local v4 = lowerBound(samples, p, p2)
	local v5 = nil
	local v6 = 0

	for i = v4 - 1, 1, -1 do
		local v7 = samples[i]
		local v8 = relativeTick(v7.ServerTick, p) -- inferred equivalent call

		if not inWindow(v7, v8, p3, p4, p5, p6) then -- inferred equivalent call
			continue
		end

		v6 = v8
		v5 = v7
		break
	end

	for i = v4, #samples do
		local v7 = samples[i]
		local v8 = relativeTick(v7.ServerTick, p) -- inferred equivalent call

		if not inWindow(v7, v8, p3, p4, p5, p6) then -- inferred equivalent call
			continue
		end

		if v8 == p2 then
			return v7, nil, 0, v3
		end

		if v5 == nil then
			return nil, nil, 0, v3
		end

		local v9 = v8 - v6
		return v5, v7, v9 <= 0 and 0 or math.clamp((p2 - v6) / v9, 0, 1), v3
	end

	if v5 == nil then
		return nil, nil, 0, v3
	end

	return v5, nil, 1, v3
end

local function renderPoseFromSorted(p, p2, p3: number, p4: number, p5)
	local v3 = p4 - p._config.RenderInterpolationTicks
	local v4, v5, v6, v7 = activityWindow(p2, p3, v3)

	if v4 == nil or v5 == nil or v6 == nil then
		return nil, "RemoteRenderPoseInactive"
	end

	local v8, v9, v10, v11 = bracketActivityWindow(p2.Samples, p3, v3, v4, v5, v6, v7)

	if v8 == nil or v11 == nil then
		return nil, "RemoteRenderPoseUnavailable"
	end

	if v9 ~= nil then
		return interpolateSample(v8, v9, v10, p5), nil
	end

	local v12 = relativeTick(v8.ServerTick, p3) -- inferred equivalent call
	local v13 = p4 - p._config.RenderInterpolationTicks - v12
	local extrapolatedSeconds = math.clamp(v13, 0, p._config.MaxRemoteExtrapolationTicks) / p._mapping.SimulationHz
	local v14 = p._config.MaxRemoteExtrapolationTicks < v13
	return
		makePose(
			v8.Actor,
			v8.ServerTick,
			v8.TopologyRevision,
			1,
			extrapolatedSeconds,
			v8.Actor.Position + v8.Actor.Velocity * extrapolatedSeconds,
			v14 and createVector(0, 0, 0) or nil,
			nil,
			nil,
			nil,
			p5
		),
		nil
end

local function collisionPoseFromSorted(state)
	local collisionPoseActivity = state.Activity[#state.Activity]

	if collisionPoseActivity == nil or not collisionPoseActivity.Active then
		return nil, "RemoteCollisionPoseInactive"
	end

	for i = #state.Samples, 1, -1 do
		local sample = state.Samples[i]

		if not (sample.Actor.Generation == collisionPoseActivity.Generation and sample.Actor.ActorId == collisionPoseActivity.ActorId) then
			continue
		end

		if
			state.CollisionPoseSample ~= sample
			or state.CollisionPoseActivity ~= collisionPoseActivity
			or state.CollisionPose == nil
		then
			state.CollisionPoseSample = sample
			state.CollisionPoseActivity = collisionPoseActivity
			state.CollisionPose = makePose(sample.Actor, sample.ServerTick, sample.TopologyRevision, 1, 0)
		end

		return state.CollisionPose, nil
	end

	return nil, "RemoteCollisionPoseUnavailable"
end

local function sortedHistory(p, p2, p3: number, value: number?)
	local v3, v4

	if Serial.isUInt32(p3) then
		v3 = value or 0

		if not (Quantization.isFinite(v3) and not (v3 < 0 or v3 >= 1)) then
			v3 = nil
			v4 = "InvalidTickFraction"
		end
	else
		v4 = "InvalidCurrentServerTick"
	end

	if v3 == nil then
		return nil, nil, v4
	end

	local actor = p._actors[p2]

	if actor == nil or #actor.Samples == 0 then
		return nil, nil, "ActorNotBuffered"
	end

	return actor, v3, nil
end

function class2:getCollisionPose(p, p2: number, value: number?)
	local v3, v4

	if Serial.isUInt32(p2) then
		v3 = value or 0

		if not (Quantization.isFinite(v3) and not (v3 < 0 or v3 >= 1)) then
			v3 = nil
			v4 = "InvalidTickFraction"
		end
	else
		v4 = "InvalidCurrentServerTick"
	end

	local v5

	if v3 == nil then
		v3 = nil
	else
		v5 = self._actors[p]

		if v5 == nil or #v5.Samples == 0 then
			v5 = nil
			v4 = "ActorNotBuffered"
			v3 = nil
		else
			v4 = nil
		end
	end

	if v5 == nil or v3 == nil then
		return nil, v4
	end

	return collisionPoseFromSorted(v5)
end

function class2:getPresentationPoses(p, p2: number, value: number?)
	local v3, v4

	if Serial.isUInt32(p2) then
		v3 = value or 0

		if not (Quantization.isFinite(v3) and not (v3 < 0 or v3 >= 1)) then
			v3 = nil
			v4 = "InvalidTickFraction"
		end
	else
		v4 = "InvalidCurrentServerTick"
	end

	local v5

	if v3 == nil then
		v3 = nil
	else
		v5 = self._actors[p]

		if v5 == nil or #v5.Samples == 0 then
			v5 = nil
			v4 = "ActorNotBuffered"
			v3 = nil
		else
			v4 = nil
		end
	end

	if v5 == nil or v3 == nil then
		return nil, nil, v4
	end

	local v6 = self._presentationPoseByActorKey[p]
	local v7, v8 = renderPoseFromSorted(self, v5, p2, v3, v6)

	if v7 ~= nil and v6 == nil then
		self._presentationPoseByActorKey[p] = v7
	end

	local v9, v10 = collisionPoseFromSorted(v5)
	local v11

	if v7 == nil and v9 == nil then
		v11 = v8 or v10
	end

	return v7, v9, v11
end

function class:actorKeys()
	return self._actorKeys
end

function class:getCollisionPose(p, p2: number, value: number?)
	local v3, v4

	if Serial.isUInt32(p2) then
		v3 = value or 0

		if not (Quantization.isFinite(v3) and not (v3 < 0 or v3 >= 1)) then
			v3 = nil
			v4 = "InvalidTickFraction"
		end
	else
		v4 = "InvalidCurrentServerTick"
	end

	if v3 == nil then
		return nil, v4
	end

	local pos = self._poses[p]

	if pos == nil then
		return nil, "ActorNotBuffered"
	end

	return pos, nil
end

function class:getCollisionPoseByActorId(p: number, p2: number, p3: number?)
	local v3 = self._actorIdToKey[p]

	if v3 == nil then
		return nil, "ActorIdNotBuffered"
	end

	return self:getCollisionPose(v3, p2, p3)
end

function class:queryCollisionActorKeys(vector: Vector3, vector2: Vector3)
	local query = self._broadphase:query(vector, vector2, self._queryActorIds)
	local queryActorKeys = self._queryActorKeys
	table.clear(queryActorKeys)

	for _, v3 in query do
		queryActorKeys[#queryActorKeys + 1] = self._actorIdToKey[v3]
	end

	return queryActorKeys
end

function class2:captureCollisionFrame()
	local collisionFrame = self._collisionFrame

	if collisionFrame ~= nil then
		return collisionFrame
	end

	local broadphase = PlayerBroadphase.new()
	local v3 = {}
	local clones = {}
	local v4 = {}

	for k, actor in self._actors do
		local v5 = collisionPoseFromSorted(actor)

		if v5 == nil then
			continue
		end

		v3[#v3 + 1] = k
		clones[k] = table.freeze(table.clone(v5))
		v4[v5.ActorId] = k
		broadphase:upsert(v5.ActorId, v5.Position)
	end

	table.sort(v3, RemoteActorIdentity.keyLess)
	local object = setmetatable({
		_actorKeys = table.freeze(v3),
		_poses = table.freeze(clones),
		_actorIdToKey = table.freeze(v4),
		_broadphase = broadphase,
		_queryActorIds = {},
		_queryActorKeys = {}
	}, class)
	self._collisionFrame = object
	return object
end

table.freeze(class)
return table.freeze(class2)