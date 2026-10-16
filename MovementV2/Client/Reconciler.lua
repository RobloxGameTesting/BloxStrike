local createVector = vector.create
local Enums = require(script.Parent.Parent.Enums)
local Mapping = require(script.Parent.Parent.Mapping)
local OwnerSnapshotCodec = require(script.Parent.Parent.OwnerSnapshotCodec)
local Quantization = require(script.Parent.Parent.Quantization)
local Serial = require(script.Parent.Parent.Serial)
local StateCodec = require(script.Parent.Parent.StateCodec)
require(script.Parent.Parent.Types)
local State = require(script.Parent.Parent.Simulation.State)
local PredictionRing = require(script.Parent.PredictionRing)
local v = bit32.bor(State.fieldMask("Position"), State.fieldMask("Velocity"))
local class = {}
class.__index = class

local function cloneTopology(topology, topologyRevision: number?) -- 2 equivalent calls inferred from this helper
	return {
		Epoch = topology.Epoch,
		Fingerprint = topology.Fingerprint,
		DestructibleRevision = topologyRevision or topology.DestructibleRevision,
		MoverRevision = topology.MoverRevision
	}
end

local function advanceValidatedMoverRevision(p, validatedMoverRevision: number) -- 3 equivalent calls inferred from this helper
	local _validatedMoverRevision = p._validatedMoverRevision

	if _validatedMoverRevision == nil or Serial.deltaUInt32(validatedMoverRevision, _validatedMoverRevision) > 0 then
		p._validatedMoverRevision = validatedMoverRevision
	end
end

local function recordAcceptedSnapshot(p, data)
	p._lastSequence = data.Sequence
	p._lastServerTick = data.ServerTick
	p._lastProcessedCommand = data.LastProcessedCommand
	p._lastSnapshotState = State.clone(data.State)
	p._lastSnapshotSupport = State.cloneSupport(data.Support)
	p._lastTopologyRevision = data.Topology.DestructibleRevision
	p._lastMoverRevision = data.Topology.MoverRevision
	advanceValidatedMoverRevision(p, data.Topology.MoverRevision) -- inferred equivalent call
end

local function replayAnchor(snapshot, p, p2, serverTick: number, commandNumber: number, topologyRevision: number) -- 2 equivalent calls inferred from this helper
	return {
		Snapshot = snapshot,
		State = State.clone(p),
		Support = State.cloneSupport(p2),
		ServerTick = serverTick,
		CommandNumber = commandNumber,
		TopologyRevision = topologyRevision
	}
end

local function snapshotReplayAnchor(snapshot) -- 2 equivalent calls inferred from this helper
	return replayAnchor( -- inferred equivalent call
		snapshot,
		snapshot.State,
		snapshot.Support,
		snapshot.ServerTick,
		snapshot.LastProcessedCommand,
		snapshot.Topology.DestructibleRevision
	)
end

local function validSupport(data)
	local v2

	if
		typeof(data) == "table"
		and type(data.Kind) == "number"
		and data.Kind % 1 == 0
		and data.Kind >= Enums.SupportKind.None
		and data.Kind <= Enums.SupportKind.Max
	then
		v2 = Serial.isUInt32(data.SourceId)

		if v2 then
			if (data.Kind == Enums.SupportKind.None) == (data.SourceId == 0) then
				return Quantization.isFiniteVector3(data.Anchor) and Quantization.isFiniteVector3(data.Velocity)
			else
				return false
			end
		end
	else
		return false
	end

	return v2
end

local function angleError(lookYaw: number, lookYaw2: number) -- 1 equivalent call inferred from this helper
	return (math.abs((lookYaw - lookYaw2 + 3.141592653589793) % 6.283185307179586 - 3.141592653589793))
end

local function tailResult(data, data2, droppedCommandCount: number, metrics)
	local v2 = {
		LastProcessedCommand = data.LastProcessedCommand,
		ServerTick = data.ServerTick,
		TailCommandNumber = 0,
		TailServerTick = 0,
		State = 0,
		Support = 0,
		ReplayCount = 0,
		DroppedCommandCount = 0,
		Metrics = 0
	}
	local tailCommandNumber

	if data2 == nil then
		tailCommandNumber = data.LastProcessedCommand
	else
		tailCommandNumber = data2.Command.CommandNumber
	end

	v2.TailCommandNumber = tailCommandNumber
	local tailServerTick

	if data2 == nil then
		tailServerTick = data.ServerTick
	else
		tailServerTick = data2.ServerTick
	end

	v2.TailServerTick = tailServerTick
	local state

	if data2 == nil then
		state = State.clone(data.State)
	else
		state = State.clone(data2.PostState)
	end

	v2.State = state
	local support

	if data2 == nil then
		support = State.cloneSupport(data.Support)
	else
		support = State.cloneSupport(data2.PostSupport)
	end

	v2.Support = support
	v2.DroppedCommandCount = droppedCommandCount
	v2.Metrics = metrics
	return v2
end

local function zeroMetrics()
	return {
		ComparedAtAck = false,
		SynthesizedInput = false,
		PlayerContactCorrection = false,
		ReconciliationMode = "Reuse",
		ReconciliationWorkSeconds = 0,
		ReconciliationElapsedSeconds = 0,
		ReconciliationSliceCount = 0,
		ReconciliationMaximumSliceSeconds = 0,
		ReplayCount = 0,
		DroppedCommandCount = 0,
		AcknowledgedCommandDelta = 0,
		ServerTickDelta = 0,
		ServerHeldTickCount = 0,
		TailCompared = false,
		TailServerTickDelta = 0,
		TailPosition = 0,
		PresentationPositionDelta = createVector(0, 0, 0),
		TailHorizontalPosition = 0,
		TailVerticalPosition = 0,
		TailVelocity = 0,
		TailVerticalVelocity = 0,
		TailSupportAnchor = 0,
		TailSupportVelocity = 0,
		TailSupportKindMismatch = 0,
		TailSupportSourceMismatch = 0,
		TailGroundMismatch = false,
		TailStanceMismatch = false,
		CanonicalStateMismatchCount = 0,
		CanonicalStateMismatchMask = 0,
		CanonicalSupportMismatch = false,
		TickRealigned = false,
		ReplayBarrier = "None",
		Position = 0,
		HorizontalPosition = 0,
		Velocity = 0,
		LookYaw = 0,
		VerticalLook = 0,
		DuckAmount = 0,
		Stamina = 0,
		SupportAnchor = 0,
		SupportVelocity = 0,
		SupportKindMismatch = 0,
		SupportSourceMismatch = 0,
		TopologyRevisionDelta = 0
	}
end

local function canonicalStateMismatch(lastSnapshotState, state) -- 1 equivalent call inferred from this helper
	local canonicalize, v2 = StateCodec.canonicalize(lastSnapshotState)
	assert(canonicalize ~= nil, v2 or "predicted state could not be canonicalized")
	return State.canonicalMismatch(canonicalize, state)
end

local function measure(data, data2)
	local v2 = zeroMetrics()
	v2.SynthesizedInput = bit32.band(data.Flags, Enums.OwnerSnapshotFlags.SynthesizedInput) ~= 0

	if data2 == nil then
		return v2
	end

	local v3 = data2.PostState.Position - data.State.Position
	v2.ComparedAtAck = true
	local canonicalStateMismatchCount, canonicalStateMismatchMask = canonicalStateMismatch(data2.PostState, data.State) -- inferred equivalent call
	v2.CanonicalStateMismatchCount = canonicalStateMismatchCount
	v2.CanonicalStateMismatchMask = canonicalStateMismatchMask
	local canonicalizeSupport, v4 = OwnerSnapshotCodec.canonicalizeSupport(data2.PostSupport)
	assert(canonicalizeSupport ~= nil, v4 or "predicted support could not be canonicalized")
	v2.CanonicalSupportMismatch = canonicalizeSupport.Kind ~= data.Support.Kind
		or canonicalizeSupport.SourceId ~= data.Support.SourceId
		or canonicalizeSupport.Anchor ~= data.Support.Anchor
		or canonicalizeSupport.Velocity ~= data.Support.Velocity
	v2.Position = v3.Magnitude
	v2.HorizontalPosition = Vector2.new(v3.X, v3.Z).Magnitude
	v2.Velocity = (data2.PostState.Velocity - data.State.Velocity).Magnitude
	v2.LookYaw = angleError(data2.PostState.LookYaw, data.State.LookYaw) -- inferred equivalent call
	v2.VerticalLook = math.abs(data2.PostState.VerticalLook - data.State.VerticalLook)
	v2.DuckAmount = math.abs(data2.PostState.DuckAmount - data.State.DuckAmount)
	v2.Stamina = math.abs(data2.PostState.Stamina - data.State.Stamina)
	v2.SupportAnchor = (data2.PostSupport.Anchor - data.Support.Anchor).Magnitude
	v2.SupportVelocity = (data2.PostSupport.Velocity - data.Support.Velocity).Magnitude
	v2.SupportKindMismatch = data2.PostSupport.Kind == data.Support.Kind and 0 or 1
	v2.SupportSourceMismatch = data2.PostSupport.SourceId == data.Support.SourceId and 0 or 1
	v2.TopologyRevisionDelta = math.abs((Serial.deltaUInt32(data2.TopologyRevision, data.Topology.DestructibleRevision)))
	return v2
end

function class.new(p, ring)
	local v2, v3 = Mapping.validate(p)
	assert(v2, v3 or "invalid command mapping")
	return (setmetatable(
		{
			_mapping = Mapping.clone(p),
			_ring = ring,
			_requiresWorldReplay = false,
			_entryScratch = {}
		},
		class
	))
end

local function clearReplayHistory(p, flag: boolean) -- 2 equivalent calls inferred from this helper
	if not flag then
		p._lastSequence = nil
		p._lastServerTick = nil
		p._lastProcessedCommand = nil
		p._lastTopologyRevision = nil
		p._lastMoverRevision = nil
	end

	p._validatedMoverRevision = nil
	p._pendingReplay = nil
	p._lastSnapshotState = nil
	p._lastSnapshotSupport = nil
	table.clear(p._entryScratch)
end

function class:reset(p)
	self._completedReplayAnchor = nil
	local v2, v3 = Mapping.validate(p)
	assert(v2, v3 or "invalid command mapping")
	self._mapping = Mapping.clone(p)
	self._ring:reset(p)
	self._requiresWorldReplay = false
	self._lastSequence = nil
	self._lastServerTick = nil
	self._lastProcessedCommand = nil
	self._lastTopologyRevision = nil
	self._lastMoverRevision = nil
	clearReplayHistory(self, true) -- inferred equivalent call
end

function class:reconfigure(data)
	self._completedReplayAnchor = nil
	local v2, v3 = Mapping.validate(data)
	assert(v2, v3 or "invalid command mapping")
	assert(data.Generation == self._mapping.Generation, "cannot reconfigure a different reconciliation generation")
	assert(data.SimulationHz == self._mapping.SimulationHz, "cannot reconfigure the reconciliation rate")
	local requiresWorldReplay

	if
		data.ActorId == self._mapping.ActorId
		and data.TopologyEpoch == self._mapping.TopologyEpoch
		and data.TopologyFingerprint == self._mapping.TopologyFingerprint
	then
		requiresWorldReplay = data.PlayerCollisionsEnabled ~= self._mapping.PlayerCollisionsEnabled
	else
		requiresWorldReplay = false
	end

	self._mapping = Mapping.clone(data)
	self._requiresWorldReplay = requiresWorldReplay
	clearReplayHistory(self, requiresWorldReplay) -- inferred equivalent call
end

function class:markMoverRevisionValidated(validatedMoverRevision: number)
	if not Serial.isUInt32(validatedMoverRevision) then
		return false, "InvalidMoverRevision"
	end

	advanceValidatedMoverRevision(self, validatedMoverRevision) -- inferred equivalent call
	local completedReplayAnchor = self._completedReplayAnchor

	if
		completedReplayAnchor ~= nil
		and completedReplayAnchor.WorldInvalidRevision ~= nil
		and Serial.deltaUInt32(validatedMoverRevision, completedReplayAnchor.WorldInvalidRevision) >= 0
	then
		completedReplayAnchor.WorldInvalidFromTick = nil
		completedReplayAnchor.WorldInvalidRevision = nil
	end

	return true, nil
end

function class:hasPendingReplay()
	return self._pendingReplay ~= nil
end

function class:cancelPendingReplay()
	self._pendingReplay = nil
end

function class:discardReplayContinuation()
	self._completedReplayAnchor = nil
end

function class:invalidateWorldReplayFromTick(worldInvalidFromTick: number, worldInvalidRevision: number)
	local completedReplayAnchor = self._completedReplayAnchor

	if completedReplayAnchor == nil then
		return
	end

	if Serial.deltaUInt32(worldInvalidFromTick, completedReplayAnchor.ServerTick) <= 0 then
		self._completedReplayAnchor = nil
		return
	end

	if
		completedReplayAnchor.WorldInvalidFromTick == nil
		or Serial.deltaUInt32(worldInvalidFromTick, completedReplayAnchor.WorldInvalidFromTick) < 0
	then
		completedReplayAnchor.WorldInvalidFromTick = worldInvalidFromTick
	end

	if
		completedReplayAnchor.WorldInvalidRevision == nil
		or Serial.deltaUInt32(worldInvalidRevision, completedReplayAnchor.WorldInvalidRevision) > 0
	then
		completedReplayAnchor.WorldInvalidRevision = worldInvalidRevision
	end
end

function class:retainReplayPrefixBeforePush(p: number)
	local completedReplayAnchor = self._completedReplayAnchor

	if completedReplayAnchor == nil or self._pendingReplay ~= nil then
		return
	end

	local v2 = self._ring:get(Serial.addUInt32(p, -self._ring:capacity()))

	if v2 == nil then
		return
	end

	if
		v2.Command.CommandNumber ~= Serial.addUInt32(completedReplayAnchor.CommandNumber, 1)
		or v2.ServerTick ~= Serial.addUInt32(completedReplayAnchor.ServerTick, 1)
		or completedReplayAnchor.InvalidFromTick ~= nil
		and Serial.deltaUInt32(v2.ServerTick, completedReplayAnchor.InvalidFromTick) >= 0
		or completedReplayAnchor.WorldInvalidFromTick ~= nil
		and Serial.deltaUInt32(v2.ServerTick, completedReplayAnchor.WorldInvalidFromTick) >= 0
	then
		self._completedReplayAnchor = nil
		return
	end

	completedReplayAnchor.State = State.clone(v2.PostState)
	completedReplayAnchor.Support = State.cloneSupport(v2.PostSupport)
	completedReplayAnchor.ServerTick = v2.ServerTick
	completedReplayAnchor.CommandNumber = v2.Command.CommandNumber
	completedReplayAnchor.TopologyRevision = v2.TopologyRevision
end

function class:retainedReplayAnchor(p, p2: number?)
	local completedReplayAnchor = self._completedReplayAnchor

	if
		completedReplayAnchor == nil
		or completedReplayAnchor.Snapshot ~= p
		or completedReplayAnchor.CommandNumber == p.LastProcessedCommand
		or p.Sequence ~= self._lastSequence
		or self._requiresWorldReplay
		or p2 == nil
		or not (Serial.deltaUInt32(p2, completedReplayAnchor.ServerTick) > 0)
	then
		return nil
	end

	return completedReplayAnchor
end

function class:forkForNewerOwner(data)
	local pendingReplay = self._pendingReplay

	if pendingReplay == nil then
		return nil
	end

	local snapshot = pendingReplay.Snapshot

	if
		data.Generation ~= snapshot.Generation
		or data.Topology.Epoch ~= snapshot.Topology.Epoch
		or data.Topology.Fingerprint ~= snapshot.Topology.Fingerprint
		or not Serial.isNewerUInt32(data.Sequence, snapshot.Sequence)
		or Serial.deltaUInt32(data.ServerTick, snapshot.ServerTick) < 0
		or Serial.deltaUInt32(data.Topology.DestructibleRevision, snapshot.Topology.DestructibleRevision) < 0
		or Serial.deltaUInt32(data.Topology.MoverRevision, snapshot.Topology.MoverRevision) < 0
		or Serial.deltaUInt32(data.LastProcessedCommand, pendingReplay.TailCommandNumber) <= 0
		or self._ring:get(data.LastProcessedCommand) == nil
	then
		return nil
	end

	local clone = table.clone(self)
	clone._pendingReplay = nil
	clone._entryScratch = {}
	return (setmetatable(clone, class))
end

function class:lastAcceptedSequence()
	return self._lastSequence
end

function class:retiredReplayCommandNumber()
	local pendingReplay = self._pendingReplay

	if pendingReplay == nil or not (pendingReplay.RetiredCount > 0) then
		return nil
	end

	return pendingReplay.AnchorCommandNumber
end

local function invalidatePendingReplay(state, p: number, flag: boolean)
	local completedReplayAnchor = state._completedReplayAnchor
	local invalidFromTick

	if flag and completedReplayAnchor ~= nil then
		invalidFromTick = Serial.addUInt32(
			completedReplayAnchor.ServerTick,
			Serial.deltaUInt32(p, completedReplayAnchor.State.MovementTick)
		)
	else
		invalidFromTick = p
	end

	if
		completedReplayAnchor == nil
		or not (Serial.deltaUInt32(invalidFromTick, completedReplayAnchor.ServerTick) <= 0)
	then
		if
			completedReplayAnchor ~= nil
			and (completedReplayAnchor.InvalidFromTick == nil or Serial.deltaUInt32(
				invalidFromTick,
				completedReplayAnchor.InvalidFromTick
			) < 0)
		then
			completedReplayAnchor.InvalidFromTick = invalidFromTick
		end
	else
		state._completedReplayAnchor = nil
	end

	local pendingReplay = state._pendingReplay

	if pendingReplay == nil then
		return false
	end

	local movementTick

	if flag then
		movementTick = pendingReplay.AnchorState.MovementTick
	else
		movementTick = pendingReplay.AnchorServerTick
	end

	local movementTick2

	if flag then
		movementTick2 = pendingReplay.Snapshot.State.MovementTick
	else
		movementTick2 = pendingReplay.Snapshot.ServerTick
	end

	local deltaUInt32 = Serial.deltaUInt32(p, movementTick)

	if deltaUInt32 <= 0 and Serial.deltaUInt32(p, movementTick2) > 0 then
		pendingReplay.InvalidatedReason = "ReplayEventOutsideRetention"
		return false
	end

	if deltaUInt32 < 1 or #pendingReplay.Staged < deltaUInt32 then
		return true
	end

	local v2 = pendingReplay.Staged[deltaUInt32 - 1]
	local clone = State.clone
	local v3

	if v2 == nil then
		v3 = pendingReplay.AnchorState
	else
		v3 = v2.State
	end

	pendingReplay.State = clone(v3)
	local cloneSupport = State.cloneSupport
	local v4

	if v2 == nil then
		v4 = pendingReplay.AnchorSupport
	else
		v4 = v2.Support
	end

	pendingReplay.Support = cloneSupport(v4)
	local topologyRevision

	if v2 == nil then
		topologyRevision = pendingReplay.AnchorTopologyRevision
	else
		topologyRevision = v2.TopologyRevision
	end

	pendingReplay.TopologyRevision = topologyRevision
	local tailCommandNumber

	if v2 == nil then
		tailCommandNumber = pendingReplay.AnchorCommandNumber
	else
		tailCommandNumber = v2.Entry.Command.CommandNumber
	end

	pendingReplay.TailCommandNumber = tailCommandNumber
	pendingReplay.TailServerTick = Serial.addUInt32(pendingReplay.AnchorServerTick, deltaUInt32 - 1)
	pendingReplay.NextIndex = deltaUInt32

	for i = #pendingReplay.Staged, deltaUInt32, -1 do
		pendingReplay.Staged[i] = nil
	end

	return true
end

function class.invalidatePendingReplayFromTick(p, p2: number)
	return (invalidatePendingReplay(p, p2, false))
end

function class.invalidatePendingReplayFromMovementTick(p, p2: number)
	return (invalidatePendingReplay(p, p2, true))
end

local function retireReplayPrefix(p, state, p2: number)
	if p2 <= 0 then
		return true
	end

	if #state.Staged < p2 then
		return false
	end

	for i = 1, p2 do
		if p._ring:get(state.Entries[i].Command.CommandNumber) ~= nil then
			return false
		end
	end

	local v2 = state.Staged[p2]
	state.AnchorState = State.clone(v2.State)
	state.AnchorSupport = State.cloneSupport(v2.Support)
	state.AnchorServerTick = v2.ServerTick
	state.AnchorCommandNumber = v2.Entry.Command.CommandNumber
	state.AnchorTopologyRevision = v2.TopologyRevision
	state.RetiredCount += p2
	state.NextIndex -= p2
	local entries = state.Entries
	local staged = state.Staged
	local count = #entries
	local count2 = #staged
	table.move(entries, p2 + 1, count, 1)
	table.move(staged, p2 + 1, count2, 1)

	for i = count, count - p2 + 1, -1 do
		entries[i] = nil
	end

	for i = count2, count2 - p2 + 1, -1 do
		staged[i] = nil
	end

	return true
end

local function appendReplayEntries(state, pendingReplay)
	local entries = pendingReplay.Entries
	local lastProcessedCommand

	if #entries == 0 then
		lastProcessedCommand = pendingReplay.Snapshot.LastProcessedCommand
	else
		lastProcessedCommand = entries[#entries].Command.CommandNumber
	end

	local entriesAfter = state._ring:entriesAfter(lastProcessedCommand, state._entryScratch)
	local newestCommandNumber = state._ring:newestCommandNumber()

	if newestCommandNumber ~= nil and Serial.deltaUInt32(newestCommandNumber, lastProcessedCommand) > #entriesAfter then
		return false, "PredictionHistoryGap"
	end

	if not retireReplayPrefix(state, pendingReplay, #entries + #entriesAfter - state._ring:capacity()) then
		return false, "ReplayHistoryOverflow"
	end

	if #entriesAfter > 0 and entriesAfter[1].Command.CommandNumber ~= Serial.addUInt32(lastProcessedCommand, 1) then
		return false, "PredictionHistoryGap"
	end

	for _, v2 in entriesAfter do
		entries[#entries + 1] = PredictionRing.cloneEntry(v2)
	end

	return true, nil
end

local function advancePendingReplay(state, callback, callback2, value)
	local pendingReplay = state._pendingReplay

	if pendingReplay == nil then
		return nil, "ReplayNotPending"
	end

	if pendingReplay.InvalidatedReason ~= nil then
		return nil, pendingReplay.InvalidatedReason
	end

	local minimumSteps = 1e999
	local maximumSteps = 1e999
	local maximumSeconds = 1e999

	if type(value) == "number" then
		if value ~= value or value < 1 or value == 1e999 then
			return nil, "InvalidReplayStepBudget"
		end

		maximumSteps = math.floor(value)
		minimumSteps = maximumSteps
	elseif value ~= nil then
		if
			type(value.MinimumSteps) ~= "number"
			or value.MinimumSteps ~= value.MinimumSteps
			or value.MinimumSteps % 1 ~= 0
			or value.MinimumSteps < 1
			or value.MinimumSteps == 1e999
			or type(value.MaximumSteps) ~= "number"
			or value.MaximumSteps ~= value.MaximumSteps
			or value.MaximumSteps % 1 ~= 0
			or value.MaximumSteps < value.MinimumSteps
			or value.MaximumSteps == 1e999
			or type(value.MaximumSeconds) ~= "number"
			or value.MaximumSeconds ~= value.MaximumSeconds
			or value.MaximumSeconds < 0
			or value.MaximumSeconds == 1e999
		then
			return nil, "InvalidReplayBudget"
		end

		minimumSteps = value.MinimumSteps
		maximumSteps = value.MaximumSteps
		maximumSeconds = value.MaximumSeconds
	end

	local v2, v3 = appendReplayEntries(state, pendingReplay)

	if not v2 then
		return nil, v3
	end

	local v4 = math.min(#pendingReplay.Entries, pendingReplay.NextIndex + maximumSteps - 1)
	local lastTime = os.clock()
	local count = 0

	for i = pendingReplay.NextIndex, v4 do
		local entry = pendingReplay.Entries[i]
		local v5 = Serial.addUInt32(pendingReplay.TailServerTick, 1)
		local v6, topologyRevision, v7 = callback(
			v5,
			cloneTopology(pendingReplay.Snapshot.Topology, pendingReplay.TopologyRevision), -- inferred equivalent call
			pendingReplay.State,
			pendingReplay.Support,
			entry.Command.CommandNumber
		)

		if v6 == nil then
			return nil, v7 or "WorldFrameUnavailable"
		end

		if topologyRevision == nil or not Serial.isUInt32(topologyRevision) then
			return nil, "WorldFrameRevisionUnavailable"
		end

		if Serial.deltaUInt32(topologyRevision, pendingReplay.TopologyRevision) < 0 then
			return nil, "WorldFrameRevisionRegressed"
		end

		pendingReplay.TopologyRevision = topologyRevision
		local topology = cloneTopology(pendingReplay.Snapshot.Topology, pendingReplay.TopologyRevision) -- inferred equivalent call
		local state2, support, v8 = callback2(
			pendingReplay.State,
			pendingReplay.Support,
			entry.Command,
			1 / state._mapping.SimulationHz,
			v5,
			topology,
			v6
		)
		local v9, v10 = StateCodec.validate(state2)

		if not v9 then
			return nil, v10 or "InvalidReplayState"
		end

		if not validSupport(support) then
			return nil, "InvalidReplaySupport"
		end

		local dependencyMask = v8 or 0

		if
			not Serial.isUInt32(dependencyMask)
			or bit32.band(dependencyMask, (bit32.bnot(PredictionRing.Dependency.ValidMask))) ~= 0
		then
			return nil, "InvalidReplayDependencyMask"
		end

		pendingReplay.State = state2
		pendingReplay.Support = support
		pendingReplay.Staged[#pendingReplay.Staged + 1] = {
			Entry = entry,
			ServerTick = v5,
			State = state2,
			Support = support,
			TopologyRevision = pendingReplay.TopologyRevision,
			DependencyMask = dependencyMask
		}
		pendingReplay.TailCommandNumber = entry.Command.CommandNumber
		pendingReplay.TailServerTick = v5
		pendingReplay.NextIndex = i + 1
		count += 1
		pendingReplay.Metrics.ReplayCount += 1

		if minimumSteps <= count and maximumSeconds <= os.clock() - lastTime then
			break
		end
	end

	if pendingReplay.NextIndex <= #pendingReplay.Entries then
		return nil, "ReplayPending"
	end

	local snapshot = pendingReplay.Snapshot
	local droppedCommandCount = state._ring:dropThrough(snapshot.LastProcessedCommand)

	for _, v5 in pendingReplay.Staged do
		if state._ring:get(v5.Entry.Command.CommandNumber) == nil then
			continue
		end

		local v6, v7 = state._ring:replacePrediction(
			v5.Entry.Command.CommandNumber,
			v5.ServerTick,
			v5.State,
			v5.Support,
			v5.TopologyRevision,
			v5.DependencyMask
		)
		assert(v6, v7 or "retained staged prediction disappeared")
	end

	state._requiresWorldReplay = false
	recordAcceptedSnapshot(state, snapshot)
	state._completedReplayAnchor = replayAnchor( -- inferred equivalent call
		snapshot,
		pendingReplay.AnchorState,
		pendingReplay.AnchorSupport,
		pendingReplay.AnchorServerTick,
		pendingReplay.AnchorCommandNumber,
		pendingReplay.AnchorTopologyRevision
	)
	state._pendingReplay = nil
	return {
		LastProcessedCommand = snapshot.LastProcessedCommand,
		ServerTick = snapshot.ServerTick,
		TailCommandNumber = pendingReplay.TailCommandNumber,
		TailServerTick = pendingReplay.TailServerTick,
		State = State.clone(pendingReplay.State),
		Support = State.cloneSupport(pendingReplay.Support),
		ReplayCount = pendingReplay.Metrics.ReplayCount,
		DroppedCommandCount = droppedCommandCount,
		Metrics = pendingReplay.Metrics
	}, nil
end

function class.resume(p, callback, callback2, p2)
	return advancePendingReplay(p, callback, callback2, p2)
end

function class:accept(snapshot, callback, callback2, flag: boolean?, flag2: boolean?, p, flag3: boolean?, p2: number?, callback3)
	local v2 = flag3 or self._requiresWorldReplay

	if self._pendingReplay ~= nil then
		return nil, "ReplayAlreadyPending"
	end

	if snapshot.Generation ~= self._mapping.Generation then
		return nil, "GenerationMismatch"
	end

	if
		snapshot.Topology.Epoch ~= self._mapping.TopologyEpoch
		or snapshot.Topology.Fingerprint ~= self._mapping.TopologyFingerprint
	then
		return nil, "TopologyMismatch"
	end

	if flag then
		if
			self._lastSequence == nil
			or snapshot.Sequence ~= self._lastSequence
			or snapshot.ServerTick ~= self._lastServerTick
			or snapshot.LastProcessedCommand ~= self._lastProcessedCommand
			or snapshot.Topology.DestructibleRevision ~= self._lastTopologyRevision
			or snapshot.Topology.MoverRevision ~= self._lastMoverRevision
		then
			return nil, "AcceptedSnapshotIdentityMismatch"
		end
	else
		if self._lastSequence ~= nil and not Serial.isNewerUInt32(snapshot.Sequence, self._lastSequence) then
			return nil, "SnapshotNotNewer"
		end

		if self._lastServerTick ~= nil and Serial.deltaUInt32(snapshot.ServerTick, self._lastServerTick) < 0 then
			return nil, "ServerTickRegressed"
		end

		if
			self._lastProcessedCommand ~= nil
			and Serial.deltaUInt32(snapshot.LastProcessedCommand, self._lastProcessedCommand) < 0
		then
			return nil, "AcknowledgementRegressed"
		end

		if
			self._lastTopologyRevision ~= nil
			and Serial.deltaUInt32(snapshot.Topology.DestructibleRevision, self._lastTopologyRevision) < 0
		then
			return nil, "TopologyRevisionRegressed"
		end

		if
			self._lastMoverRevision ~= nil
			and Serial.deltaUInt32(snapshot.Topology.MoverRevision, self._lastMoverRevision) < 0
		then
			return nil, "MoverRevisionRegressed"
		end
	end

	if
		not flag
		and not v2
		and self._lastProcessedCommand ~= nil
		and self._lastServerTick ~= nil
		and snapshot.LastProcessedCommand == self._lastProcessedCommand
		and self._ring:get(snapshot.LastProcessedCommand) == nil
		and self._lastSnapshotState ~= nil
		and self._lastSnapshotSupport ~= nil
		and select(1, canonicalStateMismatch(self._lastSnapshotState, snapshot.State)) == 0
		and self._lastSnapshotSupport.Kind == snapshot.Support.Kind
		and self._lastSnapshotSupport.SourceId == snapshot.Support.SourceId
		and self._lastSnapshotSupport.Anchor == snapshot.Support.Anchor
		and self._lastSnapshotSupport.Velocity == snapshot.Support.Velocity
		and snapshot.Topology.DestructibleRevision == self._lastTopologyRevision
		and (snapshot.Topology.MoverRevision == self._lastMoverRevision or self._validatedMoverRevision ~= nil and Serial.deltaUInt32(
			snapshot.Topology.MoverRevision,
			self._validatedMoverRevision
		) <= 0)
	then
		local deltaUInt32 = Serial.deltaUInt32(snapshot.ServerTick, self._lastServerTick)
		local entriesAfter = self._ring:entriesAfter(snapshot.LastProcessedCommand, self._entryScratch)
		local v3 = entriesAfter[#entriesAfter]
		local v4 = true

		for _, v5 in entriesAfter do
			if not (bit32.band(v5.DependencyMask, PredictionRing.Dependency.Mover) ~= 0 or deltaUInt32 ~= 0 and callback3 ~= nil and not callback3(
				v5.PostState,
				v5.Command,
				Serial.addUInt32(v5.ServerTick, deltaUInt32)
			)) then
				continue
			end

			v4 = false
			break
		end

		if v4 and deltaUInt32 >= 0 and deltaUInt32 <= self._ring:capacity() then
			if deltaUInt32 > 0 then
				local shiftServerTicksAfter, v5 = self._ring:shiftServerTicksAfter(
					snapshot.LastProcessedCommand,
					deltaUInt32
				)

				if not shiftServerTicksAfter then
					return nil, v5
				end
			end

			local metrics = zeroMetrics()
			metrics.ReplayBarrier = "AcknowledgementHeld"
			metrics.TickRealigned = deltaUInt32 > 0
			metrics.ServerHeldTickCount = deltaUInt32
			self._lastSequence = snapshot.Sequence
			self._completedReplayAnchor = snapshotReplayAnchor(snapshot) -- inferred equivalent call
			self._lastServerTick = snapshot.ServerTick
			advanceValidatedMoverRevision(self, snapshot.Topology.MoverRevision) -- inferred equivalent call
			self._lastMoverRevision = snapshot.Topology.MoverRevision
			return tailResult(snapshot, v3, 0, metrics), nil
		end
	end

	local v3 = self._ring:get(snapshot.LastProcessedCommand)
	local metrics = measure(snapshot, v3)
	local v4

	if flag then
		v4 = self:retainedReplayAnchor(snapshot, p2)
	end

	local lastProcessedCommand

	if v4 == nil then
		lastProcessedCommand = snapshot.LastProcessedCommand
	else
		lastProcessedCommand = v4.CommandNumber
	end

	local serverTick

	if v4 == nil then
		serverTick = snapshot.ServerTick
	else
		serverTick = v4.ServerTick
	end

	local destructibleRevision

	if v4 == nil then
		destructibleRevision = snapshot.Topology.DestructibleRevision
	else
		destructibleRevision = v4.TopologyRevision
	end

	local entriesAfter = self._ring:entriesAfter(lastProcessedCommand, self._entryScratch)

	if #entriesAfter > 0 and entriesAfter[1].Command.CommandNumber ~= Serial.addUInt32(lastProcessedCommand, 1) then
		return nil, "PredictionHistoryGap"
	end

	local v5

	if #entriesAfter > 0 then
		v5 = entriesAfter[#entriesAfter]
	end

	local v6 = bit32.band(metrics.CanonicalStateMismatchMask, (bit32.bnot(v)))
	local v7

	if metrics.CanonicalStateMismatchCount > 0 and v6 == 0 and metrics.Position <= 0.0001 then
		v7 = metrics.Velocity <= 0.0001
	else
		v7 = false
	end

	local v8

	if flag2 == true then
		if metrics.CanonicalStateMismatchCount == 0 then
			v8 = true
		elseif v6 == 0 and metrics.Position <= 0.0625 then
			v8 = metrics.Velocity <= 2
		else
			v8 = false
		end
	else
		v8 = false
	end

	local v9

	if
		flag2 == true
		and metrics.SupportKindMismatch == 0
		and metrics.SupportSourceMismatch == 0
		and metrics.SupportAnchor <= 0.0625
	then
		v9 = metrics.SupportVelocity <= 2
	else
		v9 = false
	end

	local v10

	if
		flag2 == true
		and v5 ~= nil
		and metrics.CanonicalStateMismatchCount > 0
		and v6 == 0
		and (v5.PostState.Position - snapshot.State.Position).Magnitude <= 0.0625
	then
		v10 = (v5.PostState.Velocity - snapshot.State.Velocity).Magnitude <= 2
	else
		v10 = false
	end

	local v11

	if v8 and v9 then
		v11 = metrics.CanonicalStateMismatchCount > 0 or (metrics.CanonicalSupportMismatch or v10 and v9)
	else
		v11 = v10 and v9
	end

	local validatedMoverRevision = self._validatedMoverRevision
	local v12

	if validatedMoverRevision == nil then
		v12 = false
	else
		v12 = Serial.deltaUInt32(snapshot.Topology.MoverRevision, validatedMoverRevision) <= 0
	end

	local v13 = v3 == nil and 0 or Serial.deltaUInt32(snapshot.ServerTick, v3.ServerTick)
	local v14 = true

	for _, v15 in entriesAfter do
		if not (bit32.band(v15.DependencyMask, PredictionRing.Dependency.Mover) ~= 0 or v15.TopologyRevision ~= snapshot.Topology.DestructibleRevision or v13 ~= 0 and callback3 ~= nil and not callback3(
			v15.PostState,
			v15.Command,
			Serial.addUInt32(v15.ServerTick, v13)
		)) then
			continue
		end

		v14 = false
		break
	end

	local v15 = not (flag or v2)

	if v15 then
		if
			v3 == nil
			or v3.ServerTick == snapshot.ServerTick
			or not (math.abs(v13) <= self._ring:capacity())
			or v3.TopologyRevision ~= snapshot.Topology.DestructibleRevision
			or metrics.CanonicalStateMismatchCount ~= 0
		then
			v15 = false
		else
			v15 = not metrics.CanonicalSupportMismatch

			if v15 then
				if self._lastTopologyRevision == snapshot.Topology.DestructibleRevision then
					if self._lastMoverRevision == snapshot.Topology.MoverRevision or v12 then
						v15 = v14
					else
						v15 = v12
					end
				else
					v15 = false
				end
			end
		end
	end

	local replayBarrier = flag and "AcceptedWorldChange"
		or v2 and "WorldChange"
		or v3 == nil and "PredictionMissing"
		or v3.ServerTick ~= snapshot.ServerTick and (v15 and "TickRealignFastPath" or "PredictionTick")
		or v3.TopologyRevision ~= snapshot.Topology.DestructibleRevision and "PredictionTopology"
		or metrics.CanonicalStateMismatchCount ~= 0 and not (v7 or v11) and "StateMismatch"
		or metrics.CanonicalSupportMismatch and not v11 and "SupportMismatch"
		or self._lastTopologyRevision ~= snapshot.Topology.DestructibleRevision and "DestructibleRevision"
		or (self._lastMoverRevision == snapshot.Topology.MoverRevision or v12) and "None"
		or "MoverRevision"
	metrics.ReplayBarrier = replayBarrier
	metrics.TickRealigned = replayBarrier == "TickRealignFastPath"

	if replayBarrier == "None" or metrics.TickRealigned then
		if metrics.TickRealigned then
			local shiftServerTicksAfter, v16 = self._ring:shiftServerTicksAfter(snapshot.LastProcessedCommand, v13)

			if not shiftServerTicksAfter then
				return nil, v16
			end
		end

		local droppedCommandCount = self._ring:dropThrough(snapshot.LastProcessedCommand)
		self._completedReplayAnchor = snapshotReplayAnchor(snapshot) -- inferred equivalent call
		recordAcceptedSnapshot(self, snapshot)
		return tailResult(snapshot, v5, droppedCommandCount, metrics), nil
	else
		if
			v3 == nil
			or v3.ServerTick ~= snapshot.ServerTick
			or v3.TopologyRevision ~= snapshot.Topology.DestructibleRevision
		then
			v11 = false
		elseif v7 or v11 then
			v11 = not metrics.CanonicalSupportMismatch
		end

		local clone = State.clone
		local postState

		if v4 == nil then
			if v11 then
				postState = v3.PostState
			else
				postState = snapshot.State
			end
		else
			postState = v4.State
		end

		local clone2 = clone(postState)
		local cloneSupport = State.cloneSupport
		local postSupport

		if v4 == nil then
			if v11 then
				postSupport = v3.PostSupport
			else
				postSupport = snapshot.Support
			end
		else
			postSupport = v4.Support
		end

		local support = cloneSupport(postSupport)
		local entries = table.create(#entriesAfter)

		for _, v16 in entriesAfter do
			entries[#entries + 1] = PredictionRing.cloneEntry(v16)
		end

		self._pendingReplay = {
			Snapshot = snapshot,
			AnchorState = clone2,
			AnchorSupport = support,
			AnchorServerTick = serverTick,
			AnchorCommandNumber = lastProcessedCommand,
			AnchorTopologyRevision = destructibleRevision,
			RetiredCount = 0,
			InvalidatedReason = nil,
			Metrics = metrics,
			Entries = entries,
			NextIndex = 1,
			Staged = table.create(#entriesAfter),
			State = clone2,
			Support = support,
			TopologyRevision = destructibleRevision,
			TailCommandNumber = lastProcessedCommand,
			TailServerTick = serverTick
		}
		local completedReplayAnchor = self._completedReplayAnchor

		if
			flag
			and p2 ~= nil
			and completedReplayAnchor ~= nil
			and completedReplayAnchor.Snapshot == snapshot
			and not self._requiresWorldReplay
		then
			local pendingReplay = self._pendingReplay

			for k, entry in entries do
				if
					entry.ServerTick ~= Serial.addUInt32(pendingReplay.TailServerTick, 1)
					or entry.Command.CommandNumber ~= Serial.addUInt32(pendingReplay.TailCommandNumber, 1)
					or Serial.deltaUInt32(entry.ServerTick, p2) >= 0
					or completedReplayAnchor.InvalidFromTick ~= nil
					and Serial.deltaUInt32(entry.ServerTick, completedReplayAnchor.InvalidFromTick) >= 0
					or completedReplayAnchor.WorldInvalidFromTick ~= nil
					and Serial.deltaUInt32(entry.ServerTick, completedReplayAnchor.WorldInvalidFromTick) >= 0
				then
					break
				end

				pendingReplay.Staged[k] = {
					Entry = entry,
					ServerTick = entry.ServerTick,
					State = entry.PostState,
					Support = entry.PostSupport,
					TopologyRevision = entry.TopologyRevision,
					DependencyMask = entry.DependencyMask
				}
				local postState2 = entry.PostState
				local postSupport2 = entry.PostSupport
				pendingReplay.State = postState2
				pendingReplay.Support = postSupport2
				pendingReplay.TopologyRevision = entry.TopologyRevision
				local serverTick2 = entry.ServerTick
				local commandNumber = entry.Command.CommandNumber
				pendingReplay.TailServerTick = serverTick2
				pendingReplay.TailCommandNumber = commandNumber
				pendingReplay.NextIndex = k + 1
			end
		end

		local v16, v17 = advancePendingReplay(self, callback, callback2, p)

		if v16 == nil and v17 ~= "ReplayPending" then
			self._pendingReplay = nil
		end

		return v16, v17
	end
end

return table.freeze(class)