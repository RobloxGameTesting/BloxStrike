local createVector = vector.create
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Catalog = require(script.Parent.Parent.Collision.Catalog)
local TopologyBuilder = require(script.Parent.Parent.Collision.TopologyBuilder)
local Config = require(script.Parent.Parent.Config)
local ControlCodec = require(script.Parent.Parent.ControlCodec)
local DamageTag = require(script.Parent.Parent.DamageTag)
local ActionLockTimeline = require(script.Parent.Parent.ActionLockTimeline)
local DiagnosticProtocol = require(script.Parent.Parent.DiagnosticProtocol)
local Enums = require(script.Parent.Parent.Enums)
local Mapping = require(script.Parent.Parent.Mapping)
local OwnerSnapshotCodec = require(script.Parent.Parent.OwnerSnapshotCodec)
local RemoteSnapshotCodec = require(script.Parent.Parent.RemoteSnapshotCodec)
local Serial = require(script.Parent.Parent.Serial)
local Simulation = require(script.Parent.Parent.Simulation)
local Config2 = require(script.Parent.Parent.Simulation.Config)
local DeterminismTrace = require(script.Parent.Parent.Simulation.DeterminismTrace)
local PlayerContacts = require(script.Parent.Parent.Simulation.PlayerContacts)
local RuntimeSettings = require(script.Parent.Parent.Simulation.RuntimeSettings)
require(script.Parent.Parent.Simulation.Types)
local Transport = require(script.Parent.Parent.Transport)
require(script.Parent.Parent.Types)
local WorldComposer = require(script.Parent.WorldComposer)
local CommandState = require(script.Parent.CommandState)
local CommandStream = require(script.Parent.CommandStream)
local CommandUplink = require(script.Parent.CommandUplink)
local DestructibleTimeline = require(script.Parent.DestructibleTimeline)
local DeterminismTraceCapture = require(script.Parent.DeterminismTraceCapture)
local PlayerContactAdapter = require(script.Parent.PlayerContactAdapter)
local PredictionErrorSmoother = require(script.Parent.PredictionErrorSmoother)
local RootFrame = require(script.Parent.Parent.RootFrame)
local PredictionPacing = require(script.Parent.PredictionPacing)
local CommandClock = require(script.Parent.CommandClock)
local OwnerCommandFeedback = require(script.Parent.OwnerCommandFeedback)
local OwnerReplay = require(script.Parent.OwnerReplay)
local OwnerRecovery = require(script.Parent.OwnerRecovery)
local DamageTagReplay = require(script.Parent.DamageTagReplay)
local ActionLockReplay = require(script.Parent.ActionLockReplay)
local PredictionRing = require(script.Parent.PredictionRing)
local Reconciler = require(script.Parent.Reconciler)
local RemoteBuffer = require(script.Parent.RemoteBuffer)
local RemoteClock = require(script.Parent.RemoteClock)
local RuntimeDiagnostics = require(script.Parent.RuntimeDiagnostics)
require(script.Parent.RuntimeTypes)
local class = {}
class.__index = class

local function newReconciliationReplayBudget() -- 1 equivalent call inferred from this helper
	return { MinimumSteps = 1, MaximumSteps = 16, MaximumSeconds = 0.0005 }
end

local function beginReconciliationTiming() -- 1 equivalent call inferred from this helper
	return { StartedAt = os.clock(), WorkSeconds = 0, SliceCount = 0, MaximumSliceSeconds = 0 }
end

local function recordReconciliationSlice(state, p: number) -- 2 equivalent calls inferred from this helper
	local v = math.max(os.clock() - p, 0)
	state.WorkSeconds += v
	state.SliceCount += 1
	state.MaximumSliceSeconds = math.max(state.MaximumSliceSeconds, v)
end

local function applyReconciliationTiming(metrics, data) -- 2 equivalent calls inferred from this helper
	metrics.ReconciliationWorkSeconds = data.WorkSeconds
	metrics.ReconciliationElapsedSeconds = math.max(os.clock() - data.StartedAt, data.WorkSeconds)
	metrics.ReconciliationSliceCount = data.SliceCount
	metrics.ReconciliationMaximumSliceSeconds = data.MaximumSliceSeconds
end

local function cloneMapping(data) -- 2 equivalent calls inferred from this helper
	return (table.freeze(Mapping.clone(data)))
end

local function sameMappingIdentity(data, data2) -- 2 equivalent calls inferred from this helper
	return data.Generation == data2.Generation
		and data.ActorId == data2.ActorId
		and data.SimulationHz == data2.SimulationHz
		and data.TopologyEpoch == data2.TopologyEpoch
		and data.TopologyFingerprint == data2.TopologyFingerprint
end

local function isPlayerCollisionPolicyRemap(data, mapping) -- 1 equivalent call inferred from this helper
	return sameMappingIdentity(data, mapping) and data.PlayerCollisionsEnabled ~= mapping.PlayerCollisionsEnabled -- inferred equivalent call
end

local clone = Simulation.State.clone
local cloneSupport = Simulation.State.cloneSupport

local function finiteSpeed(value) -- 3 equivalent calls inferred from this helper
	return type(value) == "number" and value == value and math.abs(value) < 1e999
end

local forCommand = CommandState.forCommand
local serverTimeAtTick = CommandState.serverTimeAtTick

local function defaultMapRoot(p)
	return Catalog.FindReplica(p.TopologyEpoch, p.TopologyFingerprint) or Workspace:FindFirstChild("Map")
end

local function stanceHalfSize(stance) -- 2 equivalent calls inferred from this helper
	local default = Config2.Default
	local v

	if stance == "Ducking" then
		v = default.PlayerSizeDucking
	else
		v = default.PlayerSizeStanding
	end

	return v * 0.5
end

local function withinPlayerContactMargin(p, p2)
	local v = stanceHalfSize(p.Stance) -- inferred equivalent call
	local v2 = v + stanceHalfSize(p2.Stance) -- inferred equivalent call
	local v3 = PlayerContacts.DefaultContactEpsilon + PlayerContacts.DefaultSeparationSkin
	local v4 = p.Position - p2.Position
	return math.abs(v4.X) <= v2.X + v3 and math.abs(v4.Y) <= v2.Y + v3 and math.abs(v4.Z) <= v2.Z + v3
end

function class.new(options)
	assert(RunService:IsClient(), "MovementV2 Client.Runtime is client-only")
	local v = type(options) == "table" and type(options.SampleInput) == "function"
	assert(v, "SampleInput callback is required")
	local object = setmetatable({
		_options = options,
		_started = false,
		_connections = {},
		_status = "Stopped",
		_statusFromPredictionFailure = false,
		_collisionComposer = options.CollisionComposer,
		_presentationContextScratch = {
			Mapping = nil,
			ServerTick = nil,
			TickFraction = 0,
			LocalPlayerContactCritical = false,
			Status = "Stopped",
			Reason = nil
		},
		_localPresentationContextScratch = {
			Mapping = nil,
			ServerTick = nil,
			TickFraction = 0,
			LocalPlayerContactCritical = false,
			Status = "Stopped",
			Reason = nil
		},
		_remotePresentationPool = {},
		_remotePresentations = {},
		_accumulatorSeconds = 0,
		_topologyRetrySeconds = 0,
		_pendingDeltas = {},
		_pendingMoverDeltas = {},
		_pendingMoverReplayIds = {},
		_damageTagsByMovementTick = {},
		_pendingActionLockReplay = false,
		_reconciliationReplayBudget = newReconciliationReplayBudget(), -- inferred equivalent call
		_lastHistoryRecoveryRequestAt = 0,
		_lastOwnerAppliedAt = 0,
		_lastPredictionHitchAt = 0,
		_contactActorIds = {},
		_seenJumpCommands = {},
		_seenJumpOrder = {},
		_lastWarningAtByMessage = {},
		_commandResyncRequestedAt = 0,
		_discardNextAdvanceDelta = false
	}, class)
	object._uplink = CommandUplink.new({
		OnPacketSent = function(p: number, flag: boolean)
			local mapping = object._mapping
			local onCommandPacketSent = object._options.OnCommandPacketSent

			if mapping ~= nil and onCommandPacketSent ~= nil then
				onCommandPacketSent(mapping.Generation, p, flag)
			end
		end,
		Warn = function(p: string)
			object:_warn(p)
		end
	})
	object._diagnostics = RuntimeDiagnostics.new(object)
	object._traceCapture = DeterminismTraceCapture.new({
		Report = function(p, p2, p3)
			object._diagnostics:reportIssue(p, p2, p3)
		end,
		Warn = function(p: string)
			object:_warn(p)
		end
	})
	return object
end

local function annotateReconciliation(metrics, data, lastAcceptedOwnerSnapshot, p, state, support, lastPredictedServerTick: number?, lastAcceptedOwnerSnapshot2)
	metrics.ReconciliationMode = data.ReplayCount == 0 and metrics.ReplayBarrier == "AcknowledgementHeld" and "Reuse"
		or lastAcceptedOwnerSnapshot.LastProcessedCommand == Serial.UInt32Max and "Initial"
		or p == nil and "Reanchor"
		or data.ReplayCount > 0 and "Replay"
		or "Reuse"
	metrics.ReplayCount = data.ReplayCount
	metrics.DroppedCommandCount = data.DroppedCommandCount

	if
		lastAcceptedOwnerSnapshot2 ~= nil
		and lastAcceptedOwnerSnapshot2.LastProcessedCommand ~= Serial.UInt32Max
		and lastAcceptedOwnerSnapshot.LastProcessedCommand ~= Serial.UInt32Max
	then
		metrics.AcknowledgedCommandDelta = math.max(
			Serial.deltaUInt32(
				lastAcceptedOwnerSnapshot.LastProcessedCommand,
				lastAcceptedOwnerSnapshot2.LastProcessedCommand
			),
			0
		)
		metrics.ServerTickDelta = math.max(
			Serial.deltaUInt32(lastAcceptedOwnerSnapshot.ServerTick, lastAcceptedOwnerSnapshot2.ServerTick),
			0
		)
		metrics.ServerHeldTickCount = math.max(metrics.ServerTickDelta - metrics.AcknowledgedCommandDelta, 0)
	end

	if state == nil or support == nil then
		return
	end

	metrics.TailCompared = true

	if lastPredictedServerTick ~= nil then
		metrics.TailServerTickDelta = Serial.deltaUInt32(data.TailServerTick, lastPredictedServerTick)
	end

	local v = data.State.Position - state.Position
	local v2 = data.State.Velocity - state.Velocity
	metrics.TailPosition = v.Magnitude
	metrics.TailHorizontalPosition = Vector2.new(v.X, v.Z).Magnitude
	metrics.TailVerticalPosition = v.Y
	metrics.TailVelocity = v2.Magnitude
	metrics.TailVerticalVelocity = v2.Y
	metrics.TailSupportAnchor = (data.Support.Anchor - support.Anchor).Magnitude
	metrics.TailSupportVelocity = (data.Support.Velocity - support.Velocity).Magnitude
	metrics.TailSupportKindMismatch = data.Support.Kind == support.Kind and 0 or 1
	metrics.TailSupportSourceMismatch = data.Support.SourceId == support.SourceId and 0 or 1
	metrics.TailGroundMismatch = data.State.OnGround ~= state.OnGround
	metrics.TailStanceMismatch = data.State.Stance ~= state.Stance
end

function class:_warn(p: string)
	local now = os.clock()

	if now - (self._lastWarningAtByMessage[p] or -1e999) < 5 then
		return
	end

	self._lastWarningAtByMessage[p] = now
	self._diagnostics:reportWarning(p)
	local onWarning = self._options.OnWarning

	if onWarning == nil then
		DiagnosticProtocol.outputWarning(`[MovementV2.Client] {p}`)
	else
		onWarning(p)
	end
end

function class:_setStatus(status, reason: string?)
	self._statusFromPredictionFailure = false

	if self._status == status and self._reason == reason then
		return
	end

	self._diagnostics:recordStatusChange(self._status)
	self._status = status
	self._reason = reason
	local onStatusChanged = self._options.OnStatusChanged

	if onStatusChanged ~= nil then
		onStatusChanged(status, reason)
	end
end

function class:getStatus()
	return self._status, self._reason
end

function class:getMapping()
	return self._mapping
end

function class:_refreshPresentedState(p)
	if self._state == nil or self._support == nil then
		self._presentedState = nil
		self._previousPresentedState = nil
		self._presentedSupport = nil
	else
		local v = clone(self._state)
		self._presentedState = v

		if p ~= nil then
			v = clone(p)
		end

		self._previousPresentedState = v
		self._presentedSupport = cloneSupport(self._support)
	end
end

function class:getPredictedState()
	if self._state == nil or self._support == nil then
		return nil, nil, self._lastPredictedServerTick
	end

	return clone(self._state), cloneSupport(self._support), self._lastPredictedServerTick
end

function class:getRemoteViewTick()
	local presentationClock, v = self:_presentationClock()
	local config = self._config

	if presentationClock == nil or config == nil then
		return nil
	end

	return presentationClock + v - config.RenderInterpolationTicks
end

function class:rejectDoorPrediction(p: number, p2: number)
	local collisionComposer = self._collisionComposer

	if collisionComposer == nil or type(collisionComposer.RejectDoorUse) ~= "function" then
		return false, "MoverComposerUnavailable"
	end

	local pendingMoverReplayTick2, v = collisionComposer:RejectDoorUse(p, p2)

	if v ~= nil then
		return false, v
	end

	if pendingMoverReplayTick2 == nil then
		return true, nil
	end

	OwnerReplay.invalidateWorld(self)
	local reconciler = self._reconciler

	if self._pendingReconciliationInstall ~= nil and reconciler ~= nil then
		reconciler:invalidatePendingReplayFromTick(pendingMoverReplayTick2)
	end

	local pendingMoverReplayTick = self._pendingMoverReplayTick

	if pendingMoverReplayTick == nil or Serial.deltaUInt32(pendingMoverReplayTick2, pendingMoverReplayTick) < 0 then
		self._pendingMoverReplayTick = pendingMoverReplayTick2
	end

	self._pendingMoverReplayIds[p] = true
	return true, nil
end

function class:_localClockAnchor()
	local lastPredictedServerTick = self._lastPredictedServerTick
	local config = self._config

	if lastPredictedServerTick == nil or config == nil then
		return lastPredictedServerTick, 0
	end

	return lastPredictedServerTick, (math.clamp(self._accumulatorSeconds / config.StepSeconds, 0, 0.999999))
end

function class:_presentationClock()
	local remoteClock = self._remoteClock

	if remoteClock == nil then
		return nil, 0
	end

	return remoteClock:current()
end

function class:_localPlayerContactCritical()
	local mapping = self._mapping

	if mapping == nil or not mapping.PlayerCollisionsEnabled then
		return false
	end

	local support = self._support

	if support == nil or support.Kind ~= Enums.SupportKind.Player or support.SourceId == 0 then
		return next(self._contactActorIds) ~= nil
	end

	return true
end

function class:_playerContactNearStateAtTick(p, p2: number)
	local mapping = self._mapping
	local remoteBuffer = self._remoteBuffer

	if mapping == nil or not mapping.PlayerCollisionsEnabled or remoteBuffer == nil then
		return false
	end

	local v = PlayerContacts.DefaultContactEpsilon + PlayerContacts.DefaultSeparationSkin
	local v2 = Config2.Default.PlayerSizeStanding + Vector3.new(v, v, v)

	for _, v3 in remoteBuffer:queryCollisionActorKeys(p.Position - v2, p.Position + v2) do
		local collisionPose = remoteBuffer:getCollisionPose(v3, p2, 0)

		if
			collisionPose ~= nil
			and collisionPose.ActorId ~= mapping.ActorId
			and withinPlayerContactMargin(p, collisionPose)
		then
			return true
		end
	end

	return false
end

function class:_presentationContext()
	local presentationClock, tickFraction = self:_presentationClock()
	return {
		Mapping = self._mapping,
		ServerTick = presentationClock,
		TickFraction = tickFraction,
		LocalPlayerContactCritical = self:_localPlayerContactCritical(),
		Status = self._status,
		Reason = self._reason
	}
end

function class:_sendBaselineRequest(p: number, p2: number, p3: string)
	local channels = self._channels

	if channels == nil then
		return
	end

	local encodeBaselineRequest, v = ControlCodec.encodeBaselineRequest(p, p2)

	if encodeBaselineRequest == nil then
		self:_warn(`failed to encode destructible baseline request: {v}`)
		return
	end

	self:_sendDueCommands(true)
	channels.Control:FireServer(encodeBaselineRequest)
	self:_setStatus("WaitingForBaseline", p3)
end

function class:_sendMappingRequest(requestedMappingGeneration: number)
	if not (self._retiredGeneration ~= requestedMappingGeneration and self._requestedMappingGeneration ~= requestedMappingGeneration) then
		return
	end

	local channels = self._channels

	if channels == nil then
		return
	end

	local encodeMappingRequest, v = ControlCodec.encodeMappingRequest(requestedMappingGeneration)

	if encodeMappingRequest == nil then
		self:_warn(`failed to encode mapping request: {v}`)
		return
	end

	self:_sendDueCommands(true)
	self._diagnostics:recordMappingRequest()
	self._requestedMappingGeneration = requestedMappingGeneration
	channels.Control:FireServer(encodeMappingRequest)
end

function class:_sendCommandResyncRequest(p: number, flag: boolean?)
	local mapping = self._mapping
	local channels = self._channels

	if mapping == nil or channels == nil or not Serial.isUInt32(p) then
		return false
	end

	local pendingCommandResyncThrough = self._pendingCommandResyncThrough or p

	if self._pendingCommandResyncThrough == pendingCommandResyncThrough and flag ~= true then
		return true
	end

	local encodeCommandResyncRequest, v = ControlCodec.encodeCommandResyncRequest(
		mapping.Generation,
		pendingCommandResyncThrough
	)

	if encodeCommandResyncRequest == nil then
		self:_warn(`failed to encode command resync request: {v}`)
		return false
	end

	self:_sendDueCommands(true)
	self._diagnostics:recordResyncRequest()
	self._pendingCommandResyncThrough = pendingCommandResyncThrough
	self._commandResyncRequestedAt = os.clock()
	channels.Control:FireServer(encodeCommandResyncRequest)
	return true
end

function class:_canPredict()
	if
		(self._status == "Running" or self._status == "WaitingForInput" or self._status == "WaitingForAuthority" or self._status == "WaitingForBaseline")
		and self._mapping ~= nil
		and self._topology ~= nil
		and self._timeline ~= nil
		and self._state ~= nil
		and self._support ~= nil
		and self._lastPredictedServerTick ~= nil
	then
		return self._lastAcceptedOwnerSnapshot ~= nil
	else
		return false
	end
end

function class:_sendGrenadeTransitionRequest(data)
	local mapping = self._mapping
	local channels = self._channels
	local weaponSelectRequestId = data.WeaponSelectRequestId
	local weaponSelectIdentifier = data.WeaponSelectIdentifier
	local grenadeThrowIdentifier = data.GrenadeThrowIdentifier
	local grenadeThrowAnimation = data.GrenadeThrowAnimation

	if
		mapping == nil
		or channels == nil
		or weaponSelectRequestId == nil
		or weaponSelectIdentifier == nil
		or grenadeThrowIdentifier == nil
		or grenadeThrowAnimation == nil
	then
		return false
	end

	local encodeGrenadeTransitionRequest, v = ControlCodec.encodeGrenadeTransitionRequest(
		mapping.Generation,
		data.CommandNumber,
		weaponSelectRequestId,
		weaponSelectIdentifier,
		grenadeThrowIdentifier,
		grenadeThrowAnimation,
		data.LookYaw,
		data.VerticalLook
	)

	if encodeGrenadeTransitionRequest == nil then
		self:_warn(`failed to encode grenade transition: {v}`)
		return false
	end

	channels.Control:FireServer(encodeGrenadeTransitionRequest)
	return true
end

function class:requestMapping(queuedMappingGeneration: number)
	if not Serial.isNonZeroUInt16(queuedMappingGeneration) then
		return false, "InvalidGeneration"
	end

	if self._retiredGeneration == queuedMappingGeneration then
		return false, "GenerationRetired"
	end

	if self._channels == nil then
		self._queuedMappingGeneration = queuedMappingGeneration
		return true, nil
	end

	self._queuedMappingGeneration = nil
	local mapping = self._mapping

	if mapping == nil or mapping.Generation ~= queuedMappingGeneration then
		self:_setStatus("WaitingForMapping", "RequestedCharacterGeneration")
	end

	self._requestedMappingGeneration = nil
	self:_sendMappingRequest(queuedMappingGeneration)
	return true, nil
end

function class:_disposeTimeline()
	if self._timelineConnection ~= nil then
		self._timelineConnection:Disconnect()
		self._timelineConnection = nil
	end

	if self._timeline ~= nil then
		self._timeline:destroy()
		self._timeline = nil
	end
end

function class:_clearGenerationState()
	self:_disposeTimeline()
	self._commandStream = nil
	self._predictionRing = nil
	self._traceCapture:reset(nil)
	self._reconciler = nil
	self._state = nil
	self._support = nil
	self:_refreshPresentedState()
	self._lastPredictedServerTick = nil
	self._lastWeaponSelectionCommand = nil
	self._accumulatorSeconds = 0
	self._cachedStaticFrame = nil
	self._cachedStaticWorld = nil
	self._pendingBaseline = nil
	table.clear(self._pendingDeltas)
	self._pendingMoverBaseline = nil
	table.clear(self._pendingMoverDeltas)
	self._pendingMoverReplayTick = nil
	self._pendingMoverReplayRevision = nil
	table.clear(self._pendingMoverReplayIds)
	table.clear(self._damageTagsByMovementTick)
	self._pendingDamageTagReplayMovementTick = nil
	self._actionLocks = nil
	self._pendingActionLockReplay = false
	self._pendingDiscontinuity = nil
	self._pendingOwnerSnapshot = nil
	self._pendingReconciliationInstall = nil
	self._lastHistoryRecoveryRequestAt = 0
	self._lastAcceptedOwnerSnapshot = nil
	self._requestedMappingGeneration = nil
	self._queuedMappingGeneration = nil
	table.clear(self._contactActorIds)
	table.clear(self._seenJumpCommands)
	table.clear(self._seenJumpOrder)
	self._lastAuthoritativeJumpCommand = nil
	self._uplink:resetGeneration()
	self._pendingCommandResyncThrough = nil
	self._commandResyncRequestedAt = 0
	local collisionComposer = self._collisionComposer

	if collisionComposer ~= nil then
		collisionComposer:Reset()
	end
end

function class:retireGeneration(retiredGeneration: number)
	if not Serial.isNonZeroUInt16(retiredGeneration) then
		return false, "InvalidGeneration"
	end

	local mapping = self._mapping

	if mapping ~= nil and mapping.Generation ~= retiredGeneration then
		return false, "GenerationMismatch"
	end

	self._retiredGeneration = retiredGeneration
	self._mapping = nil
	self._config = nil
	self._predictionPacingPolicy = nil
	self._commandClock = nil
	self._topologyRetrySeconds = 0
	self:_clearGenerationState()
	self:_setStatus("WaitingForMapping", "GenerationUnbound")
	return true, nil
end

function class:_bindCollisionSources(timeline, collisionComposer)
	self._timeline = timeline
	self._collisionComposer = collisionComposer
end

function class:_ensureTopology(p)
	local topology = self._topology

	if topology ~= nil and topology.Epoch == p.TopologyEpoch and topology.Fingerprint == p.TopologyFingerprint then
		return true, nil
	end

	local v = (self._options.ResolveMapRoot or defaultMapRoot)(p)

	if v == nil then
		return false, "ReplicatedMapUnavailable"
	end

	local topologyBuild = self._topologyBuild

	if
		topologyBuild == nil
		or topologyBuild.Epoch ~= p.TopologyEpoch
		or topologyBuild.Fingerprint ~= p.TopologyFingerprint
	then
		local barriers = v:FindFirstChild("Barriers")

		if barriers == nil or not (#barriers:GetDescendants() >= TopologyBuilder.LargeSourceCount) then
			local published, v2 = Catalog.ReadPublished(v, self._options.OnWarning)

			if published == nil then
				return false, v2
			end

			if
				published.Manifest.Epoch ~= p.TopologyEpoch
				or published.Manifest.Fingerprint ~= p.TopologyFingerprint
			then
				return false, "ReplicatedManifestDoesNotMatchMapping"
			end

			local topology2 = TopologyBuilder.Build(published, Config2.Default)

			if topology2.Epoch ~= p.TopologyEpoch or topology2.Fingerprint ~= p.TopologyFingerprint then
				return false, "BuiltTopologyDoesNotMatchMapping"
			end

			self._topology = topology2
			return true, nil
		else
			local topologyBuild2 = {
				Epoch = p.TopologyEpoch,
				Fingerprint = p.TopologyFingerprint,
				Result = nil,
				Error = nil
			}
			self._topologyBuild = topologyBuild2
			task.spawn(function()
				local frameYielder = TopologyBuilder.createFrameYielder(0.008)

				local function yieldIfNeeded()
					frameYielder()

					if self._topologyBuild ~= topologyBuild2 then
						error("TopologyBuildSuperseded")
					end
				end

				local success, result = pcall(function()
					local published, v2 = Catalog.ReadPublished(v, self._options.OnWarning, yieldIfNeeded)

					if published == nil then
						return v2
					end

					if
						published.Manifest.Epoch == topologyBuild2.Epoch
						and published.Manifest.Fingerprint == topologyBuild2.Fingerprint
					then
						return TopologyBuilder.Build(published, Config2.Default, nil, yieldIfNeeded)
					end

					return "ReplicatedManifestDoesNotMatchMapping"
				end)

				if not success then
					topologyBuild2.Error = `TopologyBuildFailed: {result}`
				elseif typeof(result) == "string" then
					topologyBuild2.Error = result
				elseif result.Epoch == topologyBuild2.Epoch and result.Fingerprint == topologyBuild2.Fingerprint then
					topologyBuild2.Result = result
				else
					topologyBuild2.Error = "BuiltTopologyDoesNotMatchMapping"
				end
			end)
			return false, "TopologyBuilding"
		end
	else
		if topologyBuild.Result == nil and topologyBuild.Error == nil then
			return false, "TopologyBuilding"
		end

		self._topologyBuild = nil

		if topologyBuild.Result == nil then
			return false, topologyBuild.Error
		end

		self._topology = topologyBuild.Result
		return true, nil
	end
end

function class:_initializeGeneration(p)
	self._lastResyncOwnerSnapshot = nil
	local topology, v = self:_ensureTopology(p)

	if not topology then
		self:_setStatus("WaitingForTopology", v)
		return false, v
	end

	local v2 = assert(self._topology)
	self:_disposeTimeline()
	local timeline = DestructibleTimeline.new(p.SimulationHz, v2.Epoch, v2.DestructibleCount)
	self._timeline = timeline
	self._timelineConnection = timeline.BaselineNeeded:Connect(function(p2, p3, p4)
		if self._timeline == timeline then
			self:_sendBaselineRequest(p2, p3, p4)
		end
	end)
	self._config = Config.derive(p.SimulationHz)
	self._predictionPacingPolicy = PredictionPacing.policyFromConfig(self._config)
	self._commandClock = CommandClock.new(self._config)
	self._lastOwnerCommandFeedback = nil
	self._commandStream = CommandStream.new(p)
	self._uplink:fillBudget(self._config)
	self._predictionRing = PredictionRing.new(p)
	self._traceCapture:reset(self._config)
	self._reconciler = Reconciler.new(p, self._predictionRing)
	self._observerMapping = nil
	self:_ensureRemoteStreams(p, false)
	self._state = nil
	self._support = nil
	self:_refreshPresentedState()
	self._lastPredictedServerTick = nil
	self._lastWeaponSelectionCommand = nil
	self._pendingReconciliationInstall = nil
	self._lastHistoryRecoveryRequestAt = 0
	self._accumulatorSeconds = 0
	self._topologyRetrySeconds = 0
	table.clear(self._contactActorIds)
	table.clear(self._seenJumpCommands)
	table.clear(self._seenJumpOrder)
	self._lastAuthoritativeJumpCommand = nil
	self:_setStatus("WaitingForBaseline", "InitialDestructibleBaseline")
	return true, nil
end

function class:retryTopology()
	local mapping = self._mapping

	if mapping == nil then
		return false, "MappingUnavailable"
	end

	if self._timeline ~= nil then
		return true, nil
	end

	local v, v2 = self:_initializeGeneration(mapping)

	if v then
		self:_drainPendingCollisionControls()
		self:_tryInstallDiscontinuity()
	end

	return v, v2
end

function class:_applyMapping(data)
	local v, v2 = Mapping.validate(data)

	if not v then
		self:_warn(`rejected movement mapping: {v2}`)
		return
	end

	if self._retiredGeneration == data.Generation then
		return
	end

	local mapping = self._mapping

	if mapping ~= nil then
		local deltaUInt16 = Serial.deltaUInt16(data.Generation, mapping.Generation)

		if deltaUInt16 < 0 then
			return
		end

		if deltaUInt16 == 0 then
			if isPlayerCollisionPolicyRemap(data, mapping) then -- inferred equivalent call
				local commandStream = self._commandStream
				local reconciler = self._reconciler

				if commandStream == nil or reconciler == nil then
					self._mapping = nil
					self:_applyMapping(data)
					return
				else
					self._mapping = cloneMapping(data) -- inferred equivalent call
					commandStream:reconfigure(data)
					reconciler:reconfigure(data)
					self._traceCapture:reset(self._config)
					table.clear(self._contactActorIds)
					self._pendingReconciliationInstall = nil
					self._lastHistoryRecoveryRequestAt = 0
					self._requestedMappingGeneration = nil
					self._queuedMappingGeneration = nil
					self._pendingDiscontinuity = nil
					self._pendingOwnerSnapshot = nil
					local state = self._state
					local support = self._support

					if
						not data.PlayerCollisionsEnabled
						and state ~= nil
						and support ~= nil
						and support.Kind == Enums.SupportKind.Player
					then
						local state2 = clone(state)
						state2.Velocity = PlayerContacts.toWorldVelocity(state.Velocity, support)
						state2.OnGround = false
						state2.GroundNormal = createVector(0, 1, 0)
						state2.GroundSurfaceFriction = RuntimeSettings.getMovementConfig(data.SimulationHz).SurfaceFrictionDefault
						self._state = state2
						self._support = {
							Kind = Enums.SupportKind.None,
							SourceId = 0,
							Anchor = createVector(0, 0, 0),
							Velocity = createVector(0, 0, 0)
						}
					end

					if self:_canPredict() then
						self:_setStatus("Running", nil)
					else
						self:_setStatus("WaitingForAuthority", "PlayerCollisionPolicyChanged")
					end

					return
				end
			elseif sameMappingIdentity(data, mapping) then -- inferred equivalent call
				self._requestedMappingGeneration = nil
				self._queuedMappingGeneration = nil

				if self._timeline == nil then
					self:retryTopology()
				end

				local lastAcceptedOwnerSnapshot = self._lastAcceptedOwnerSnapshot

				if lastAcceptedOwnerSnapshot == nil or lastAcceptedOwnerSnapshot.Generation ~= data.Generation then
					self:_sendDueCommands(true)
				else
					self:_sendRecoveryCommands(lastAcceptedOwnerSnapshot.LastProcessedCommand)
				end

				return
			else
				self:_warn("received conflicting mapping for the active generation")
				self:_sendMappingRequest(data.Generation)
				return
			end
		end
	end

	self:_clearGenerationState()
	self._config = Config.derive(data.SimulationHz)
	self._predictionPacingPolicy = PredictionPacing.policyFromConfig(self._config)

	if self._commandClock ~= nil then
		self._commandClock:reset()
		self._lastOwnerCommandFeedback = nil
	end

	self._observerMapping = nil
	self._mapping = cloneMapping(data) -- inferred equivalent call
	self._retiredGeneration = nil
	self._lastPredictionHitchAt = 0
	self._lastOwnerAppliedAt = 0
	table.clear(self._lastWarningAtByMessage)
	self._uplink:resetCounters()
	self._diagnostics:resetGeneration()
	self:_initializeGeneration(data)
end

function class:_applyBaseline(pendingBaseline)
	local timeline = self._timeline

	if timeline == nil then
		self._pendingBaseline = pendingBaseline
		return false
	end

	local v, v2, v3 = timeline:consumeBaseline(pendingBaseline.ServerTick, pendingBaseline.Frame)

	if not v then
		self:_warn(`rejected destructible baseline: {v2}`)
		return false
	end

	if v3 then
		OwnerReplay.invalidateWorld(self)
	end

	self._pendingBaseline = nil
	return true
end

function class:_deferDestructibleDelta(p, p2: number)
	local config = self._config or Config.Default

	if #self._pendingDeltas >= config.PredictionReplayTicks then
		table.clear(self._pendingDeltas)
		self:_sendBaselineRequest(p.Epoch, p2, "PendingDestructibleHistoryOverflow")
	else
		self._pendingDeltas[#self._pendingDeltas + 1] = p
	end
end

function class:_deferMoverDelta(p)
	local config = self._config or Config.Default

	if not (#self._pendingMoverDeltas >= config.PredictionReplayTicks) then
		self._pendingMoverDeltas[#self._pendingMoverDeltas + 1] = p
		return
	end

	table.clear(self._pendingMoverDeltas)
	local mapping = self._mapping

	if mapping ~= nil then
		self:_sendMappingRequest(mapping.Generation)
	end
end

function class:_applyDelta(data)
	OwnerReplay.invalidateWorld(self)
	local timeline = self._timeline

	if timeline == nil then
		self:_deferDestructibleDelta(data, 0)
		return false
	end

	local v, v2 = timeline:consumeDelta(data.Epoch, data.Revision, data.ServerTick, data.Indices)

	if not v then
		self:_warn(`rejected destructible delta: {v2}`)
		return false
	end

	local v3

	if self._predictionRing ~= nil then
		v3 = self._predictionRing:newestCommandNumber()
	end

	local v4

	if v3 ~= nil then
		v4 = self._predictionRing:get(v3)
	end

	local v5

	if v4 == nil then
		v5 = false
	else
		v5 = Serial.deltaUInt32(v4.ServerTick, data.ServerTick) >= 0
	end

	local v6 = self._pendingDiscontinuity ~= nil
	self:_tryInstallDiscontinuity()

	if self._pendingReconciliationInstall ~= nil then
		return true
	end

	local v7 = v6 and self._pendingDiscontinuity == nil
	local pendingOwnerSnapshot = self._pendingOwnerSnapshot

	if pendingOwnerSnapshot ~= nil and self._state ~= nil then
		self._pendingOwnerSnapshot = nil
		v7 = self:_handleOwnerSnapshot(pendingOwnerSnapshot) or v7
	end

	if v5 and not v7 then
		self:_setStatus("WaitingForAuthority", "DestructibleChangedInsidePrediction")
		local mapping = self._mapping

		if mapping ~= nil then
			self:_sendMappingRequest(mapping.Generation)
		end
	end

	return true
end

function class:_applyMoverBaseline(data)
	local collisionComposer = self._collisionComposer
	local mapping = self._mapping

	if collisionComposer == nil or mapping == nil or data.Epoch ~= mapping.TopologyEpoch then
		return false
	end

	local v, v2, v3, v4, v5 = collisionComposer:ConsumeBaseline(
		data.Epoch,
		data.Revision,
		data.ServerTick,
		data.Descriptors,
		data.ProgressAnchors
	)

	if not v then
		self:_warn(`rejected mover baseline: {v2}`)
		return false
	end

	if v5 ~= false then
		OwnerReplay.invalidateWorld(self)
	end

	if v3 ~= nil then
		self:_queueMoverReplay(v3, data.Revision, v4)
	end

	self:_applyPendingMoverDeltas()

	if v3 ~= nil and self._state ~= nil then
		return true
	end

	self:_tryInstallDiscontinuity()
	self:_installOwnerSnapshotAfterControls()
	return true
end

function class:_applyPendingMoverDeltas()
	local pendingMoverDeltas = self._pendingMoverDeltas
	self._pendingMoverDeltas = {}

	for k, pendingMoverDelta in pendingMoverDeltas do
		if self:_applyMoverDelta(pendingMoverDelta) then
			continue
		end

		for i = k + 1, #pendingMoverDeltas do
			self._pendingMoverDeltas[#self._pendingMoverDeltas + 1] = pendingMoverDeltas[i]
		end

		break
	end
end

function class:_markMoverRevisionValidated(p: number)
	local reconciler = self._reconciler

	if reconciler == nil then
		return false
	end

	local v, v2 = reconciler:markMoverRevisionValidated(p)

	if not v then
		self:_warn(`could not validate mover revision: {v2 or "unknown"}`)
	end

	return v
end

function class:_applyMoverDelta(data)
	local collisionComposer = self._collisionComposer
	local mapping = self._mapping

	if collisionComposer == nil or mapping == nil then
		self:_deferMoverDelta(data)
		return false
	end

	if data.Epoch ~= mapping.TopologyEpoch then
		return false
	end

	local v, v2, v3, v4

	if data.Kind == "MoverProgress" then
		v, v2, v3, v4 = collisionComposer:ConsumeProgress(data.Epoch, data.Revision, data.ServerTick, data.Streams)
	else
		v, v2, v3, v4 = collisionComposer:ConsumeDelta(data.Epoch, data.Revision, data.ServerTick, data.Descriptors)
	end

	if v2 == "MoverBaselineRequired" then
		self:_deferMoverDelta(data)
		return false
	end

	if v2 == nil then
		if v ~= nil then
			self:_queueMoverReplay(v, data.Revision, v4)
			return true
		end

		if v3 then
			if self._pendingMoverReplayTick == nil then
				self:_markMoverRevisionValidated(data.Revision)
			else
				self._pendingMoverReplayRevision = data.Revision
			end
		end

		return true
	else
		self:_warn(`rejected mover delta: {v2}`)
		self:_sendMappingRequest(mapping.Generation)
		return false
	end
end

function class:_queueMoverReplay(pendingMoverReplayTick: number, pendingMoverReplayRevision: number, items)
	OwnerReplay.invalidateWorldFromTick(self, pendingMoverReplayTick, pendingMoverReplayRevision)
	local _pendingMoverReplayTick = self._pendingMoverReplayTick

	if _pendingMoverReplayTick == nil or Serial.deltaUInt32(pendingMoverReplayTick, _pendingMoverReplayTick) < 0 then
		self._pendingMoverReplayTick = pendingMoverReplayTick
	end

	local _pendingMoverReplayRevision = self._pendingMoverReplayRevision

	if
		_pendingMoverReplayRevision == nil
		or Serial.deltaUInt32(pendingMoverReplayRevision, _pendingMoverReplayRevision) > 0
	then
		self._pendingMoverReplayRevision = pendingMoverReplayRevision
	end

	if items ~= nil then
		for k in items do
			self._pendingMoverReplayIds[k] = true
		end
	end
end

function class:_flushPendingMoverReplay()
	local pendingMoverReplayTick = self._pendingMoverReplayTick

	if pendingMoverReplayTick == nil then
		return false
	end

	local pendingMoverReplayRevision = self._pendingMoverReplayRevision
	local pendingMoverReplayIds = self._pendingMoverReplayIds
	self._pendingMoverReplayTick = nil
	self._pendingMoverReplayRevision = nil
	self._pendingMoverReplayIds = {}
	local mapping = self._mapping

	if mapping == nil then
		return false
	end

	local predictionRing = self._predictionRing
	local v

	if predictionRing ~= nil then
		v = predictionRing:newestCommandNumber()
	end

	local v2

	if v ~= nil then
		v2 = predictionRing:get(v)
	end

	local collisionComposer = self._collisionComposer
	local v3

	if predictionRing == nil or v2 == nil or not (Serial.deltaUInt32(v2.ServerTick, pendingMoverReplayTick) >= 0) then
		v3 = false
	else
		v3 = next(pendingMoverReplayIds) == nil
			or collisionComposer == nil
			or type(collisionComposer.IsPredictionStateAffected) ~= "function"
			or predictionRing:anyEntryAtOrAfterServerTick(pendingMoverReplayTick, function(p)
				return collisionComposer:IsPredictionStateAffected(pendingMoverReplayIds, p.PostState, p.PostSupport)
			end)
	end

	if v3 then
		local v4 = self._pendingDiscontinuity ~= nil
		self:_tryInstallDiscontinuity()
		local v5 = v4 and self._pendingDiscontinuity == nil
		local pendingOwnerSnapshot = self._pendingOwnerSnapshot

		if pendingOwnerSnapshot ~= nil and self._state ~= nil then
			self._pendingOwnerSnapshot = nil
			v5 = self:_handleOwnerSnapshot(pendingOwnerSnapshot, true)

			if self._pendingReconciliationInstall ~= nil then
				self._pendingReconciliationInstall.MoverRevisionToValidate = pendingMoverReplayRevision
				return true
			end
		end

		if v3 and not v5 then
			local lastAcceptedOwnerSnapshot = self._lastAcceptedOwnerSnapshot

			if lastAcceptedOwnerSnapshot ~= nil then
				local v6
				v5, v6 = self:_installSnapshot(lastAcceptedOwnerSnapshot, false, true, nil, nil, pendingMoverReplayTick)

				if v6 == "ReplayPending" then
					local pendingReconciliationInstall = self._pendingReconciliationInstall

					if pendingReconciliationInstall ~= nil then
						pendingReconciliationInstall.MoverRevisionToValidate = pendingMoverReplayRevision
					end

					return true
				end
			end

			if not v5 then
				self:_setStatus("WaitingForAuthority", "MoverChangedBeforePredictedTail")
				self:_sendMappingRequest(mapping.Generation)
			end
		end

		if v5 and pendingMoverReplayRevision ~= nil then
			self:_markMoverRevisionValidated(pendingMoverReplayRevision)
		end

		return v5
	else
		if pendingMoverReplayRevision ~= nil then
			self:_markMoverRevisionValidated(pendingMoverReplayRevision)
		end

		return false
	end
end

function class:_applyDamageTagForStep(p)
	local v = Serial.addUInt32(p.MovementTick, 1)
	local v2 = self._damageTagsByMovementTick[v]

	if v2 == nil then
		return p
	end

	local v3 = clone(p)
	v3.VelocityModifier = DamageTag.apply(v3.VelocityModifier, v2)
	return v3
end

function class:_stateForCommand(p, p2, p3: number, flag: boolean)
	return forCommand(
		p,
		p2,
		p3,
		self._options.ResolveBaseMoveSpeed,
		flag,
		ActionLockTimeline.isLockedAt(self._actionLocks, p3)
	)
end

function class:_pruneDamageTagsThrough(p: number)
	for k in self._damageTagsByMovementTick do
		if Serial.deltaUInt32(p, k) >= 0 then
			self._damageTagsByMovementTick[k] = nil
		end
	end

	local pendingDamageTagReplayMovementTick = self._pendingDamageTagReplayMovementTick

	if pendingDamageTagReplayMovementTick ~= nil and Serial.deltaUInt32(p, pendingDamageTagReplayMovementTick) >= 0 then
		self._pendingDamageTagReplayMovementTick = nil
	end
end

function class:_queueDamageTag(data)
	local mapping = self._mapping

	if mapping == nil or data.Generation ~= mapping.Generation then
		if self._retiredGeneration ~= data.Generation then
			self:_sendMappingRequest(data.Generation)
		end
	else
		local lastAcceptedOwnerSnapshot = self._lastAcceptedOwnerSnapshot

		if
			lastAcceptedOwnerSnapshot ~= nil
			and Serial.deltaUInt32(lastAcceptedOwnerSnapshot.State.MovementTick, data.ApplyMovementTick) >= 0
		then
			return
		end

		local v = self._damageTagsByMovementTick[data.ApplyMovementTick]
		local velocityModifier

		if v == nil then
			velocityModifier = data.VelocityModifier
		else
			velocityModifier = DamageTag.apply(v, data.VelocityModifier)
		end

		if v == velocityModifier then
			return
		end

		self._damageTagsByMovementTick[data.ApplyMovementTick] = velocityModifier
		local reconciler = self._reconciler

		if reconciler ~= nil then
			reconciler:invalidatePendingReplayFromMovementTick(data.ApplyMovementTick)
		end

		local movementTick

		if self._state ~= nil then
			movementTick = self._state.MovementTick
		end

		if movementTick == nil or Serial.deltaUInt32(movementTick, data.ApplyMovementTick) < 0 then
			return
		end

		local pendingDamageTagReplayMovementTick = self._pendingDamageTagReplayMovementTick
		local movementTick2

		if lastAcceptedOwnerSnapshot == nil then
			movementTick2 = pendingDamageTagReplayMovementTick
		else
			movementTick2 = lastAcceptedOwnerSnapshot.State.MovementTick
		end

		if
			pendingDamageTagReplayMovementTick == nil
			or movementTick2 == nil
			or Serial.deltaUInt32(data.ApplyMovementTick, movementTick2) < Serial.deltaUInt32(
				pendingDamageTagReplayMovementTick,
				movementTick2
			)
		then
			self._pendingDamageTagReplayMovementTick = data.ApplyMovementTick
		end
	end
end

function class:_flushPendingDamageTagReplay()
	return DamageTagReplay.flush(self)
end

function class:_drainPendingCollisionControls()
	if self._pendingReconciliationInstall ~= nil then
		return
	end

	local pendingBaseline = self._pendingBaseline

	if
		pendingBaseline ~= nil and not self:_applyBaseline(pendingBaseline)
		or (self._timeline == nil or self._timeline:needsBaseline())
	then
		return
	end

	local pendingDeltas = self._pendingDeltas
	self._pendingDeltas = {}

	for k, pendingDelta in pendingDeltas do
		if not (not self:_applyDelta(pendingDelta) or self._pendingReconciliationInstall ~= nil) then
			continue
		end

		for i = k + 1, #pendingDeltas do
			self._pendingDeltas[#self._pendingDeltas + 1] = pendingDeltas[i]
		end

		if self._pendingReconciliationInstall ~= nil then
			return
		end

		break
	end

	local pendingMoverBaseline = self._pendingMoverBaseline

	if pendingMoverBaseline ~= nil then
		self._pendingMoverBaseline = nil
		self:_applyMoverBaseline(pendingMoverBaseline)

		if self._pendingReconciliationInstall ~= nil then
			return
		end
	end

	self:_applyPendingMoverDeltas()
	self:_flushPendingMoverReplay()
	self:_tryInstallDiscontinuity()
	self:_installOwnerSnapshotAfterControls()
end

function class:_installOwnerSnapshotAfterControls()
	local pendingOwnerSnapshot = self._pendingOwnerSnapshot

	if pendingOwnerSnapshot ~= nil and self._state ~= nil and self:_remoteContactFrameReady(pendingOwnerSnapshot) then
		self._pendingOwnerSnapshot = nil
		self:_handleOwnerSnapshot(pendingOwnerSnapshot)
	end
end

function class:_remoteContactFrameReady(p)
	local mapping = self._mapping

	if mapping == nil or not mapping.PlayerCollisionsEnabled then
		return true
	end

	local remoteBuffer = self._remoteBuffer
	local v

	if remoteBuffer ~= nil then
		v = remoteBuffer:latestCompleteServerTick()
	end

	return v ~= nil and Serial.deltaUInt32(v, p.ServerTick) >= 0
end

function class:_composeWorld(p: number, p2: number?, p3: number?, p4, flag: boolean?, p5, p6)
	return WorldComposer.compose(self, p, p2, p3, p4, flag, p5, p6)
end

function class:_resolveSupportMotion(p, p2, p3, p4)
	local v = p4 or self._remoteBuffer

	if v ~= nil and p3.Kind == Enums.SupportKind.Player then
		return PlayerContactAdapter.resolvePlayerSupportMotion(
			p2,
			p3,
			v,
			p.ServerTick,
			assert(self._config).StepSeconds
		)
	end

	local resolveSupportMotion = p.Composed.ResolveSupportMotion

	if resolveSupportMotion == nil then
		return nil
	end

	return (resolveSupportMotion(p3))
end

function class:_simulate(p, p2, p3, p4, p5, p6)
	local v = assert(self._config)
	local v2 = assert(self._mapping)
	local v3 = p6 or assert(self._remoteBuffer)
	local supportMotion = self:_resolveSupportMotion(p4, p, p2, p6)
	local movementConfig = RuntimeSettings.getMovementConfig(v.SimulationHz)
	local v4, v5 = PlayerContactAdapter.bindStanceProbe(v2, p4.ServerTick, v3, movementConfig)
	local v6, v7, v8 = Simulation.step(
		p,
		p2,
		p3,
		v.StepSeconds,
		p4.Composed.Query,
		supportMotion,
		movementConfig,
		p5,
		v4
	)

	if v2.PlayerCollisionsEnabled then
		local position = v6.Position
		local solve = PlayerContactAdapter.solve(
			p,
			p2,
			v6,
			v7,
			v8,
			v2,
			p4.ServerTick,
			v3,
			p4.Composed.Query,
			p4.Composed.CanOccupyAtEnd,
			movementConfig,
			p5
		)

		if v5 ~= nil then
			for k in v5 do
				solve.ContactActorIds[k] = true
				solve.NearbyPlayer = true
			end
		end

		DeterminismTrace.checkpoint(p5, "runtime.playerContacts.final", solve.State, solve.Support, nil)
		self._traceCapture:finish(p5)
		return
			solve.State,
			solve.Support,
			solve.Events,
			solve.ContactActorIds,
			solve.ExternalDisplacement,
			solve.NearbyPlayer,
			solve.State.Position - position
	else
		DeterminismTrace.checkpoint(p5, "runtime.playerContacts.final", v6, v7, nil)
		self._traceCapture:finish(p5)
		return v6, v7, v8, {}, 0, false, createVector(0, 0, 0)
	end
end

local function predictionDependencyMask(p, stateForCommand, simulate, p2, p3, items, flag: boolean)
	local v = 0

	if p2.Kind == Enums.SupportKind.Player or p3.Kind == Enums.SupportKind.Player or next(items) ~= nil or flag then
		v = bit32.bor(v, PredictionRing.Dependency.Player)
	end

	local moverSensitiveAt = p.Composed.MoverSensitiveAt

	if
		moverSensitiveAt ~= nil
		and (moverSensitiveAt(stateForCommand.Position, stateForCommand.Stance) or moverSensitiveAt(simulate.Position, simulate.Stance))
	then
		return (bit32.bor(v, PredictionRing.Dependency.Mover))
	end

	return v
end

function class:_rememberJumpEvent(p: number)
	if not Serial.isUInt32(p) or p == Serial.UInt32Max or self._seenJumpCommands[p] then
		return false
	end

	self._seenJumpCommands[p] = true
	local seenJumpOrder = self._seenJumpOrder
	seenJumpOrder[#seenJumpOrder + 1] = p

	if #seenJumpOrder > 64 then
		local v = table.remove(seenJumpOrder, 1)

		if v ~= self._lastAuthoritativeJumpCommand then
			self._seenJumpCommands[v] = nil
		end
	end

	return true
end

function class:_dispatchStepEvents(p, p2: number)
	if p.Jumped and not self:_rememberJumpEvent(p2) then
		p.Jumped = false
	end

	local onStepEvents = self._options.OnStepEvents

	if onStepEvents ~= nil then
		onStepEvents(p, self:_presentationContext())
	end
end

function class:_recoverAuthoritativeJump(p)
	local lastJumpCommandNumber = p.State.LastJumpCommandNumber

	if lastJumpCommandNumber == Serial.UInt32Max or lastJumpCommandNumber == self._lastAuthoritativeJumpCommand then
		return
	end

	self._lastAuthoritativeJumpCommand = lastJumpCommandNumber

	if self._seenJumpCommands[lastJumpCommandNumber] then
		return
	end

	self:_dispatchStepEvents({
		Jumped = true,
		Landed = false,
		LeftGround = true,
		ImpactVelocityY = nil,
		Blocked = false,
		StartSolid = false
	}, lastJumpCommandNumber)
end

local function simulateReplayStep(object, generation: number, p, p2, p3, p4, p5, p6)
	local v = object._traceCapture:begin(generation, p4.CommandNumber, p5.ServerTick)
	local v2 = serverTimeAtTick(p, p5.ServerTick, assert(object._config).StepSeconds)
	local stateForCommand = object:_stateForCommand(object:_applyDamageTagForStep(p2), p4, v2, true)
	local simulate, v3, _, v4, _, v5 = object:_simulate(stateForCommand, p3, p4, p5, v, p6)
	return simulate, v3, predictionDependencyMask(p5, stateForCommand, simulate, p3, v3, v4, v5), v4
end

function class:_commitSnapshotInstall(lastAcceptedOwnerSnapshot, data, p, playerContactCorrection: boolean, contactActorIds)
	local state = self._state
	local support = self._support
	local lastPredictedServerTick = self._lastPredictedServerTick
	local _lastAcceptedOwnerSnapshot = self._lastAcceptedOwnerSnapshot
	data.Metrics.PlayerContactCorrection = playerContactCorrection
	annotateReconciliation(
		data.Metrics,
		data,
		lastAcceptedOwnerSnapshot,
		p,
		state,
		support,
		lastPredictedServerTick,
		_lastAcceptedOwnerSnapshot
	)
	self._traceCapture:onSnapshotCommitted(
		lastAcceptedOwnerSnapshot,
		p,
		data.Metrics,
		self._diagnostics:reportingEnabled()
	)
	local canPredict = self:_canPredict()
	local v = math.clamp(self._accumulatorSeconds / assert(self._config).StepSeconds, 0, 1)
	local position

	if not (self._presentedState == nil or self._previousPresentedState == nil) then
		position = RootFrame.cframe(self._previousPresentedState):Lerp(RootFrame.cframe(self._presentedState), v).Position
	end

	self._state = data.State
	self._support = data.Support
	local v2 = state == nil and 1e999
		or math.abs((math.atan2(
			math.sin(data.State.LookYaw - state.LookYaw),
			(math.cos(data.State.LookYaw - state.LookYaw))
		)))
	local v3 = state == nil
		or (data.State.Position - state.Position).Magnitude > 0.0001
		or data.State.Stance ~= state.Stance
		or v2 > 0.0001

	if state == nil or self._presentedState == nil or self._previousPresentedState == nil then
		self:_refreshPresentedState()
	elseif v3 then
		local v4 = clone(self._previousPresentedState)
		v4.Position += data.State.Position - state.Position
		v4.LookYaw += data.State.LookYaw - state.LookYaw
		self:_refreshPresentedState(v4)
	elseif data.Metrics.ReconciliationMode ~= "Reuse" then
		self._presentedState = clone(data.State)
		self._presentedSupport = cloneSupport(data.Support)
	end

	if position ~= nil then
		local position2 = RootFrame.cframe(assert(self._previousPresentedState)):Lerp(
			RootFrame.cframe(assert(self._presentedState)),
			v
		).Position
		data.Metrics.PresentationPositionDelta = position2 - position
	end

	self._lastPredictedServerTick = data.TailServerTick
	self._contactActorIds = contactActorIds
	self._lastAcceptedOwnerSnapshot = lastAcceptedOwnerSnapshot
	self:_pruneDamageTagsThrough(lastAcceptedOwnerSnapshot.State.MovementTick)
	local pendingDamageTagReplayMovementTick = self._pendingDamageTagReplayMovementTick

	if
		data.ReplayCount > 0
		and pendingDamageTagReplayMovementTick ~= nil
		and Serial.deltaUInt32(data.State.MovementTick, pendingDamageTagReplayMovementTick) >= 0
	then
		self._pendingDamageTagReplayMovementTick = nil
	end

	local pendingCommandResyncThrough = self._pendingCommandResyncThrough

	if
		pendingCommandResyncThrough ~= nil
		and Serial.deltaUInt32(lastAcceptedOwnerSnapshot.LastProcessedCommand, pendingCommandResyncThrough) >= 0
	then
		self._pendingCommandResyncThrough = nil
		self._commandResyncRequestedAt = 0
	end

	self:_recoverAuthoritativeJump(lastAcceptedOwnerSnapshot)
	self._lastOwnerAppliedAt = os.clock()
	self._uplink:onOwnerApplied(lastAcceptedOwnerSnapshot.LastProcessedCommand)
	self._diagnostics:recordOwnerApplied(lastAcceptedOwnerSnapshot, data, p)

	if not canPredict then
		local v4 = assert(self._config)
		self._accumulatorSeconds = math.min(self._accumulatorSeconds, v4.StepSeconds * 0.999999)
		self._discardNextAdvanceDelta = true
	end

	self:_setStatus("Running", nil)
	local onReconciled = self._options.OnReconciled

	if onReconciled ~= nil then
		onReconciled(data.Metrics, self:_presentationContext())
	end

	return true, nil
end

function class:_installSnapshot(snapshot, flag: boolean, flag2: boolean?, flag3: boolean?, callback, p: number?)
	local mapping = self._mapping
	local timeline = self._timeline
	local reconciler = self._reconciler
	local commandStream = self._commandStream

	if mapping == nil or timeline == nil or reconciler == nil or commandStream == nil then
		return false, "GenerationContextUnavailable"
	end

	if snapshot.Generation ~= mapping.Generation then
		return false, "GenerationMismatch"
	end

	if
		snapshot.Topology.Epoch ~= mapping.TopologyEpoch
		or snapshot.Topology.Fingerprint ~= mapping.TopologyFingerprint
	then
		return false, "TopologyMismatch"
	end

	if not (flag or flag2) then
		local v, v2 = OwnerRecovery.prepare(self, snapshot)

		if not v then
			return false, v2
		end
	end

	if flag2 and p == nil then
		reconciler:discardReplayContinuation()
	end

	local checkWorld = OwnerReplay.checkWorld
	local v

	if flag2 then
		v = p
	end

	local v2 = checkWorld(self, snapshot, v)

	if v2 ~= nil then
		return false, v2
	end

	if flag then
		if snapshot.LastProcessedCommand == Serial.UInt32Max then
			commandStream:reset(mapping)
			reconciler:reset(mapping)
		else
			self:_sendMappingRequest(mapping.Generation)
			return false, "InitialDiscontinuityDoesNotPrecedeCommandZero"
		end
	end

	local predictedAtAck

	if self._predictionRing then
		predictedAtAck = self._predictionRing:get(snapshot.LastProcessedCommand) or nil
	end

	local playerContactNearStateAtTick = self:_playerContactNearStateAtTick(snapshot.State, snapshot.ServerTick)

	if not playerContactNearStateAtTick then
		if predictedAtAck == nil then
			playerContactNearStateAtTick = false
		else
			playerContactNearStateAtTick = self:_playerContactNearStateAtTick(
				predictedAtAck.PostState,
				snapshot.ServerTick
			)
		end
	end

	local v3 = {}
	local collisionFrame = nil
	local collisionComposer2 = nil
	local timing = beginReconciliationTiming() -- inferred equivalent call
	local startedAt = timing.StartedAt
	debug.profilebegin("MovementV2.Client.ReconciliationReplay")
	local accept, v4 = reconciler:accept(snapshot, function(p2, _, p3)
		if collisionFrame == nil and (mapping.PlayerCollisionsEnabled or self._collisionComposer ~= nil) then
			collisionFrame = assert(self._remoteBuffer):captureCollisionFrame()
		end

		local collisionComposer = self._collisionComposer

		if
			collisionComposer2 == nil
			and collisionComposer ~= nil
			and type(collisionComposer.ForkPrediction) == "function"
		then
			collisionComposer2 = collisionComposer:ForkPrediction()
		end

		local world, v4 = self:_composeWorld(p2, nil, nil, p3, nil, collisionFrame, collisionComposer2)

		if world == nil then
			return nil, nil, v4
		end

		return world, world.Destructibles.Revision, nil
	end, function(p2, p3, p4, _, _, _, p5)
		local v4, v5, v6, v7 = simulateReplayStep(self, mapping.Generation, snapshot, p2, p3, p4, p5, collisionFrame)
		v3 = v7
		return v4, v5, v6
	end, flag2, playerContactNearStateAtTick, self._reconciliationReplayBudget, flag3, p, function(p2, p3, p4)
		return self:_stateForCommand(p2, p3, serverTimeAtTick(snapshot, p4, assert(self._config).StepSeconds), true) == p2
	end)
	debug.profileend()
	recordReconciliationSlice(timing, startedAt) -- inferred equivalent call

	if accept == nil then
		if v4 == "ReplayPending" then
			self._pendingReconciliationInstall = {
				Snapshot = snapshot,
				PredictedAtAck = predictedAtAck,
				PlayerContactAtAck = playerContactNearStateAtTick,
				MoverRevisionToValidate = nil,
				Timing = timing,
				CollisionFrame = collisionFrame,
				CollisionComposer = collisionComposer2,
				FreshCollisionFrames = {}
			}

			if callback ~= nil then
				callback()
			end
		end

		return false, v4
	else
		if collisionComposer2 ~= nil then
			self._collisionComposer:CommitPrediction(collisionComposer2)
		end

		if callback ~= nil then
			callback()
		end

		applyReconciliationTiming(accept.Metrics, timing) -- inferred equivalent call
		return self:_commitSnapshotInstall(snapshot, accept, predictedAtAck, playerContactNearStateAtTick, v3)
	end
end

function class:_resumePendingReconciliation()
	local v, v2, v3 = OwnerReplay.tryAdvance(self)

	if v then
		return v2 == true, v3
	end

	local pendingReconciliationInstall = self._pendingReconciliationInstall
	local reconciler = self._reconciler
	local mapping = self._mapping

	if pendingReconciliationInstall == nil or reconciler == nil or mapping == nil then
		return false, "ReconciliationReplayUnavailable"
	end

	if pendingReconciliationInstall.Snapshot.Generation == mapping.Generation then
		local v4 = {}
		local now = os.clock()
		debug.profilebegin("MovementV2.Client.ReconciliationReplay")
		local v5, v6 = reconciler:resume(function(p, _, p2, _, p3)
			local world, v5 = self:_composeWorld(
				p,
				nil,
				nil,
				p2,
				nil,
				pendingReconciliationInstall.FreshCollisionFrames[p3] or pendingReconciliationInstall.CollisionFrame,
				pendingReconciliationInstall.CollisionComposer
			)

			if world == nil then
				return nil, nil, v5
			end

			return world, world.Destructibles.Revision, nil
		end, function(p, p2, p3, _, _, _, p4)
			local v5, v6, v7, v8 = simulateReplayStep(
				self,
				mapping.Generation,
				pendingReconciliationInstall.Snapshot,
				p,
				p2,
				p3,
				p4,
				pendingReconciliationInstall.FreshCollisionFrames[p3.CommandNumber] or pendingReconciliationInstall.CollisionFrame
			)
			v4 = v8
			return v5, v6, v7
		end, self._reconciliationReplayBudget)
		debug.profileend()
		recordReconciliationSlice(pendingReconciliationInstall.Timing, now) -- inferred equivalent call

		if v5 == nil then
			if v6 == "ReplayPending" then
				local retiredReplayCommandNumber = reconciler:retiredReplayCommandNumber()

				if
					retiredReplayCommandNumber == nil
					or retiredReplayCommandNumber == pendingReconciliationInstall.CollisionFramesRetiredThrough
				then
					return false, "ReplayPending"
				end

				for k in pendingReconciliationInstall.FreshCollisionFrames do
					if Serial.deltaUInt32(k, retiredReplayCommandNumber) <= 0 then
						pendingReconciliationInstall.FreshCollisionFrames[k] = nil
					end
				end

				pendingReconciliationInstall.CollisionFramesRetiredThrough = retiredReplayCommandNumber
				return false, v6
			else
				reconciler:cancelPendingReplay()
				self._pendingReconciliationInstall = nil
				return false, v6
			end
		else
			self._pendingReconciliationInstall = nil

			if pendingReconciliationInstall.CollisionComposer ~= nil then
				self._collisionComposer:CommitPrediction(pendingReconciliationInstall.CollisionComposer)
			end

			applyReconciliationTiming(v5.Metrics, pendingReconciliationInstall.Timing) -- inferred equivalent call
			local commitSnapshotInstall, v7 = self:_commitSnapshotInstall(
				pendingReconciliationInstall.Snapshot,
				v5,
				pendingReconciliationInstall.PredictedAtAck,
				pendingReconciliationInstall.PlayerContactAtAck,
				v4
			)

			if commitSnapshotInstall and self._pendingDiscontinuity == pendingReconciliationInstall.Snapshot then
				self._pendingDiscontinuity = nil
			end

			if commitSnapshotInstall and pendingReconciliationInstall.MoverRevisionToValidate ~= nil then
				self:_markMoverRevisionValidated(pendingReconciliationInstall.MoverRevisionToValidate)
			end

			return commitSnapshotInstall, v7
		end
	else
		reconciler:cancelPendingReplay()
		self._pendingReconciliationInstall = nil
		return false, "GenerationMismatch"
	end
end

function class:_tryInstallDiscontinuity()
	if self._pendingReconciliationInstall ~= nil then
		return
	end

	local pendingDiscontinuity = self._pendingDiscontinuity

	if pendingDiscontinuity == nil then
		if self._state == nil and self._timeline ~= nil and not self._timeline:needsBaseline() then
			self:_setStatus("WaitingForState", "ReliableDiscontinuityUnavailable")
		end
	else
		local v, v2 = self:_installSnapshot(pendingDiscontinuity, self._state == nil)

		if v then
			self._pendingDiscontinuity = nil
			self:_installOwnerSnapshotAfterControls()
		else
			if v2 == "SnapshotNotNewer" then
				self._pendingDiscontinuity = nil
				return
			elseif v2 == "ReplayPending" then
				return
			end

			if
				v2 ~= "CommandLeadResync"
				and v2 ~= "BaselineRequired"
				and v2 ~= "DestructibleFrameOutsideRetention"
				and v2 ~= "DestructibleRevisionMismatch"
				and v2 ~= "MoverBaselineRequired"
				and v2 ~= "MoverRevisionUnavailable"
				and v2 ~= "MoverFrameOutsideRetention"
				and v2 ~= "GenerationContextUnavailable"
			then
				self:_warn(`could not install reliable discontinuity: {v2}`)
			end
		end
	end
end

function class:_handleOwnerSnapshot(pendingOwnerSnapshot, flag: boolean?)
	local mapping = self._mapping

	if mapping == nil or pendingOwnerSnapshot.Generation ~= mapping.Generation then
		self:_sendMappingRequest(pendingOwnerSnapshot.Generation)
		return false
	end

	OwnerCommandFeedback.observe(self, pendingOwnerSnapshot, os.clock())

	if self._pendingReconciliationInstall ~= nil then
		self:_queueOwnerSnapshot(pendingOwnerSnapshot)
		return false
	end

	if self._state == nil then
		self._pendingOwnerSnapshot = pendingOwnerSnapshot
		self:_sendMappingRequest(pendingOwnerSnapshot.Generation)
		return false
	else
		local v, v2 = self:_installSnapshot(pendingOwnerSnapshot, false, nil, flag)

		if v then
			return true
		end

		if
			v2 == "SnapshotNotNewer"
			or v2 == "CommandLeadResync"
			or v2 == "DestructibleFrameOutsideRetention"
			or v2 == "ReplayPending"
		then
			return false
		end

		if v2 == "BaselineRequired" then
			self._pendingOwnerSnapshot = pendingOwnerSnapshot
			self:_setStatus("WaitingForBaseline", "BaselineRequired")
		elseif v2 == "DestructibleRevisionMismatch" then
			self._pendingOwnerSnapshot = pendingOwnerSnapshot
			self:_setStatus("WaitingForAuthority", "AwaitingDestructibleDelta")
		elseif v2 == "MoverBaselineRequired" or v2 == "MoverRevisionUnavailable" then
			self._pendingOwnerSnapshot = pendingOwnerSnapshot
			self:_setStatus("WaitingForAuthority", "AwaitingMoverDescriptor")
		elseif v2 == "MoverFrameOutsideRetention" then
			self:_sendMappingRequest(mapping.Generation)
		else
			self:_warn(`rejected owner snapshot: {v2}`)
		end

		return false
	end
end

function class:_queueOwnerSnapshot(pendingOwnerSnapshot)
	OwnerCommandFeedback.observe(self, pendingOwnerSnapshot, os.clock())
	OwnerRecovery.observe(self, pendingOwnerSnapshot)
	local _pendingOwnerSnapshot = self._pendingOwnerSnapshot

	if
		_pendingOwnerSnapshot == nil
		or _pendingOwnerSnapshot.Generation ~= pendingOwnerSnapshot.Generation
		or Serial.isNewerUInt32(pendingOwnerSnapshot.Sequence, _pendingOwnerSnapshot.Sequence)
	then
		self._pendingOwnerSnapshot = pendingOwnerSnapshot
	end
end

function class:_ensureObserverRemoteStreams(p)
	if self._mapping ~= nil then
		return false
	end

	local observerMapping = self._observerMapping
	local remoteBuffer = self._remoteBuffer

	if
		observerMapping ~= nil
		and remoteBuffer ~= nil
		and self._remoteClock ~= nil
		and remoteBuffer:sharesStream(observerMapping)
		and observerMapping.TopologyEpoch == p.Topology.Epoch
		and observerMapping.TopologyFingerprint == p.Topology.Fingerprint
	then
		return true
	end

	local v = {
		Generation = 65535,
		ActorId = 4294967295,
		SimulationHz = Config.DefaultSimulationHz,
		TopologyEpoch = p.Topology.Epoch,
		TopologyFingerprint = p.Topology.Fingerprint,
		PlayerCollisionsEnabled = false
	}
	local v2, v3 = Mapping.validate(v)

	if not v2 then
		self:_warn(`could not derive observer remote mapping: {v3}`)
		return false
	end

	self._observerMapping = table.freeze(v)
	self:_ensureRemoteStreams(v, true)
	return true
end

function class:_ensureRemoteStreams(p, flag: boolean)
	local remoteBuffer = self._remoteBuffer
	local remoteClock = self._remoteClock

	if remoteBuffer == nil or remoteClock == nil or not remoteBuffer:sharesStream(p) then
		self._remoteBuffer = RemoteBuffer.new(p)
		self._remoteClock = RemoteClock.new(Config.derive(p.SimulationHz), flag)
	else
		remoteBuffer:forgetActor(Players.LocalPlayer.UserId)
		remoteClock:setSpectator(flag)
	end
end

function class:_applyRemoteSnapshot(p)
	local mapping = self._mapping
	local remoteBuffer = self._remoteBuffer

	if mapping == nil then
		if not self:_ensureObserverRemoteStreams(p) then
			return
		end

		local v = assert(self._remoteBuffer)
		local _, v2 = v:pushDecoded(p)
		local latestServerTick = v:latestServerTick()

		if v2 == nil and latestServerTick ~= nil then
			local remoteClock = self._remoteClock

			if remoteClock ~= nil then
				remoteClock:observe(latestServerTick, os.clock())
			end
		end
	else
		if
			remoteBuffer == nil
			or not remoteBuffer:sharesStream(mapping)
			or p.Topology.Epoch ~= mapping.TopologyEpoch
			or p.Topology.Fingerprint ~= mapping.TopologyFingerprint
		then
			return
		end

		local _, v = remoteBuffer:pushDecoded(p)

		if v == nil then
			local remoteClock = self._remoteClock
			local latestServerTick = remoteBuffer:latestServerTick()

			if remoteClock ~= nil and latestServerTick ~= nil then
				remoteClock:observe(latestServerTick, os.clock())
			end
		end

		if v == "RemoteBaselineRequired" then
			self._diagnostics:recordRemoteRejected("RemoteBaselineRequired")
		elseif v ~= nil and v ~= "DuplicateRemoteChunk" and v ~= "RemoteSnapshotTooOld" and v ~= "RemoteDeltaHeld" then
			self._diagnostics:recordRemoteRejected(v)
			self:_warn(`rejected remote snapshot: {v}`)
		end
	end
end

function class:_handleRemoteSnapshot(buf)
	local decoded = RemoteSnapshotCodec.decode(buf)

	if decoded == nil then
		return
	end

	self._diagnostics:recordRemoteSnapshot(decoded.Sequence)
	local mapping = self._mapping

	if mapping ~= nil then
		local onRemoteSnapshotReceived = self._options.OnRemoteSnapshotReceived

		if onRemoteSnapshotReceived ~= nil then
			onRemoteSnapshotReceived(mapping.Generation, decoded.Sequence, {
				Bytes = buffer.len(buf),
				Kind = decoded.Kind,
				FullActorCount = #decoded.Actors,
				DeltaActorCount = #decoded.Deltas,
				RemovedActorCount = #decoded.RemovedActorIds,
				ChunkCount = decoded.ChunkCount
			})
		end
	end

	self:_applyRemoteSnapshot(decoded)
end

function class:_handleControl(buf)
	local decoded, v = ControlCodec.decode(buf)

	if decoded == nil then
		self:_warn(`rejected movement control: {v}`)
		return
	end

	if decoded.Kind == "Mapping" then
		self:_applyMapping(decoded.Mapping)
		return
	end

	if decoded.Kind == "GenerationUnbound" then
		self:retireGeneration(decoded.Generation)
		return
	end

	if decoded.Kind == "DamageTag" then
		self:_queueDamageTag(decoded)
		return
	end

	if decoded.Kind == "ActionLocks" then
		ActionLockReplay.queue(self, decoded)
		return
	end

	local v2 = self._pendingReconciliationInstall ~= nil
	local v3 = v2 or self._pendingMoverBaseline ~= nil or #self._pendingMoverDeltas > 0

	if decoded.Kind == "Discontinuity" then
		local mapping = self._mapping
		local onOwnerSnapshotReceived = self._options.OnOwnerSnapshotReceived

		if onOwnerSnapshotReceived ~= nil and mapping ~= nil and decoded.Snapshot.Generation == mapping.Generation then
			onOwnerSnapshotReceived(decoded.Snapshot.Generation, decoded.Snapshot.Sequence, {
				Bytes = buffer.len(buf),
				Kind = "Discontinuity"
			})
		end

		if mapping == nil or decoded.Snapshot.Generation ~= mapping.Generation then
			self._pendingDiscontinuity = decoded.Snapshot
			self:_sendMappingRequest(decoded.Snapshot.Generation)
		else
			OwnerRecovery.observe(self, decoded.Snapshot)
			self._pendingDiscontinuity = decoded.Snapshot
			self:_tryInstallDiscontinuity()
		end
	elseif decoded.Kind == "DestructibleBaseline" then
		self._pendingBaseline = { ServerTick = decoded.ServerTick, Frame = decoded.Frame }
		self:_drainPendingCollisionControls()
	elseif decoded.Kind == "DestructibleDelta" then
		local v4 = {
			Epoch = decoded.Epoch,
			Revision = decoded.Revision,
			ServerTick = decoded.ServerTick,
			Indices = decoded.Indices
		}

		if v2 or self._pendingBaseline ~= nil or #self._pendingDeltas > 0 then
			self:_deferDestructibleDelta(v4, decoded.Revision)
		else
			self:_applyDelta(v4)
		end
	elseif decoded.Kind == "MoverBaseline" then
		if v3 then
			self._pendingMoverBaseline = decoded
		else
			self:_applyMoverBaseline(decoded)
		end
	elseif decoded.Kind == "MoverDelta" or decoded.Kind == "MoverProgress" then
		if v3 then
			self:_deferMoverDelta(decoded)
		else
			self:_applyMoverDelta(decoded)
		end
	end
end

function class:_sendDueCommands(flag: boolean?)
	self._uplink:sendDue(self._commandStream, self._config, self._channels, flag)
end

function class:_sendRecoveryCommands(p: number)
	if self._pendingCommandResyncThrough ~= nil then
		return
	end

	self._uplink:sendRecovery(self._commandStream, self._config, self._channels, p)
end

function class:_recoverStalledCommands()
	local pendingReconciliationInstall = self._pendingReconciliationInstall
	local choose = OwnerCommandFeedback.choose
	local lastAcceptedOwnerSnapshot = self._lastAcceptedOwnerSnapshot
	local pendingOwnerSnapshot = self._pendingOwnerSnapshot
	local v

	if pendingReconciliationInstall then
		v = pendingReconciliationInstall.Snapshot
	end

	local chosen = choose(lastAcceptedOwnerSnapshot, pendingOwnerSnapshot, v)
	self._uplink:recoverStalled(
		chosen,
		self._commandStream,
		self._config,
		self._channels,
		self._lastOwnerAppliedAt,
		self._pendingCommandResyncThrough ~= nil
	)
end

function class:_buildCommandInput(p, data, p2: number, p3: number, p4)
	local resolveScopedState = self._options.ResolveScopedState
	local clone2

	if resolveScopedState == nil then
		clone2 = p
	else
		clone2 = table.clone(p)
		clone2.Buttons = Enums.Buttons.with(p.Buttons, Enums.Buttons.Scoped, resolveScopedState())
	end

	local consumePendingWeaponSelection = self._options.ConsumePendingWeaponSelection
	local v, v2

	if consumePendingWeaponSelection == nil then
		v2 = false
	else
		v = consumePendingWeaponSelection()

		if v == nil then
			v2 = false
		else
			v2 = true
		end
	end

	if v == nil then
		local getUnresolvedWeaponSelection = self._options.GetUnresolvedWeaponSelection
		local lastWeaponSelectionCommand = self._lastWeaponSelectionCommand

		if
			getUnresolvedWeaponSelection ~= nil
			and (lastWeaponSelectionCommand == nil or Serial.deltaUInt32(p2, lastWeaponSelectionCommand) >= p4.CommandPacketEveryTicks)
		then
			v = getUnresolvedWeaponSelection()
		end
	end

	local weaponMoveSpeed = data.WeaponMoveSpeed
	local weaponScopedMoveSpeed = data.WeaponScopedMoveSpeed

	if v ~= nil then
		if clone2 == p then
			clone2 = table.clone(p)
		end

		clone2.WeaponSelectRequestId = v.RequestId
		clone2.WeaponSelectIdentifier = v.Identifier
		clone2.GrenadeThrowIdentifier = v.GrenadeThrowIdentifier
		clone2.GrenadeThrowAnimation = v.GrenadeThrowAnimation
		local resolveWeaponSpeedProfile = self._options.ResolveWeaponSpeedProfile

		if resolveWeaponSpeedProfile ~= nil then
			local weaponSpeedProfile, v3 = resolveWeaponSpeedProfile(v)

			if finiteSpeed(weaponSpeedProfile) and finiteSpeed(v3) then -- inferred equivalent call
				weaponMoveSpeed = math.clamp(weaponSpeedProfile, 0, Config2.Default.MaxBaseMoveSpeed)
				weaponScopedMoveSpeed = math.clamp(v3, 0, Config2.Default.MaxBaseMoveSpeed)
				clone2.PredictedWeaponMoveSpeed = weaponMoveSpeed
				clone2.PredictedWeaponScopedMoveSpeed = weaponScopedMoveSpeed
			end
		end
	end

	local resolveBaseMoveSpeed = self._options.ResolveBaseMoveSpeed

	if resolveBaseMoveSpeed == nil then
		return clone2, v, v2
	end

	local baseMoveSpeed = resolveBaseMoveSpeed(
		data.BaseMoveSpeed,
		p3,
		weaponMoveSpeed,
		weaponScopedMoveSpeed,
		Enums.Buttons.has(clone2.Buttons, Enums.Buttons.Scoped)
	)

	if finiteSpeed(baseMoveSpeed) then -- inferred equivalent call
		if clone2 == p then
			clone2 = table.clone(p)
		end

		clone2.PredictedBaseMoveSpeed = math.clamp(baseMoveSpeed, 0, Config2.Default.MaxBaseMoveSpeed)
	end

	return clone2, v, v2
end

function class:_stepPrediction(frameSampleAlpha: number)
	if not self:_canPredict() then
		return false, self._reason or self._status
	end

	local mapping = assert(self._mapping)
	local v = assert(self._commandStream)
	local v2 = assert(self._predictionRing)
	local v3 = assert(self._state)
	local v4 = assert(self._support)
	local v5 = assert(self._config)

	if v2:isFull() and os.clock() - self._lastHistoryRecoveryRequestAt >= 1 then
		self._lastHistoryRecoveryRequestAt = os.clock()
		self:_sendMappingRequest(mapping.Generation)
	end

	local lastSampledCommandNumber = v:lastSampledCommandNumber()
	local v6 = lastSampledCommandNumber == nil and 0 or Serial.addUInt32(lastSampledCommandNumber, 1)
	local lastPredictedServerTick = self._lastPredictedServerTick

	if lastPredictedServerTick == nil then
		return false, "AuthoritativeTickUnavailable"
	end

	local v7 = Serial.addUInt32(lastPredictedServerTick, 1)
	local lastAcceptedOwnerSnapshot = self._lastAcceptedOwnerSnapshot

	if lastAcceptedOwnerSnapshot == nil then
		return false, "AuthoritativeTimeUnavailable"
	end

	local scheduledServerTime = serverTimeAtTick(lastAcceptedOwnerSnapshot, v7, v5.StepSeconds)
	local predict, v8 = assert(self._timeline):predict(v7)

	if predict == nil then
		return false, v8
	end

	debug.profilebegin("MovementV2.Client.ComposeWorld")
	local world, v9 = self:_composeWorld(v7, predict.Revision, nil, v3, true)
	debug.profileend()

	if world == nil then
		return false, v9
	end

	local input = self._options.SampleInput({
		Mapping = mapping,
		ServerTick = v7,
		ScheduledServerTime = scheduledServerTime,
		StepSeconds = v5.StepSeconds,
		FrameSampleAlpha = frameSampleAlpha,
		State = assert(self._presentedState),
		Support = assert(self._presentedSupport)
	})

	if input == nil then
		return false, "InputUnavailable"
	end

	local commandInput, v10, v11 = self:_buildCommandInput(input, v3, v6, scheduledServerTime, v5)
	local sample, v12 = v:sample(commandInput)

	if sample == nil then
		if v11 and v10 ~= nil then
			local restorePendingWeaponSelection = self._options.RestorePendingWeaponSelection

			if restorePendingWeaponSelection ~= nil then
				restorePendingWeaponSelection(v10)
			end
		end

		return false, `InputRejected:{v12 or "Unknown"}`
	else
		if v10 ~= nil then
			self._lastWeaponSelectionCommand = sample.CommandNumber
		end

		if sample.CommandNumber ~= v6 then
			return false, "SampledCommandOrderMismatch"
		end

		local v13 = self._traceCapture:begin(mapping.Generation, sample.CommandNumber, v7)
		local stateForCommand = self:_stateForCommand(
			self:_applyDamageTagForStep(v3),
			sample,
			scheduledServerTime,
			false
		)
		local pendingReconciliationInstall = self._pendingReconciliationInstall

		if
			pendingReconciliationInstall ~= nil
			and (mapping.PlayerCollisionsEnabled or self._collisionComposer ~= nil)
		then
			pendingReconciliationInstall.FreshCollisionFrames[sample.CommandNumber] = assert(self._remoteBuffer):captureCollisionFrame()
		end

		local simulate, support, v14, contactActorIds, v15, v16, v17 = self:_simulate(stateForCommand, v4, sample, world, v13)
		self._traceCapture:observePredictedStep(
			mapping.Generation,
			sample,
			v7,
			stateForCommand,
			v4,
			simulate,
			support,
			v14
		)
		assert(self._reconciler):retainReplayPrefixBeforePush(sample.CommandNumber)
		local v18, v19 = v2:push(
			sample,
			v7,
			simulate,
			support,
			predict.Revision,
			true,
			(predictionDependencyMask(world, stateForCommand, simulate, v4, support, contactActorIds, v16))
		)

		if not v18 then
			return false, v19
		end

		if sample.GrenadeThrowIdentifier ~= nil then
			self:_sendGrenadeTransitionRequest(sample)
		end

		self._state = simulate
		self._support = support
		self:_refreshPresentedState(v3)
		self._lastPredictedServerTick = v7
		self._contactActorIds = contactActorIds

		if PlayerContacts.DefaultContactEpsilon < v15 then
			local onPlayerContactCorrection = self._options.OnPlayerContactCorrection

			if onPlayerContactCorrection ~= nil then
				if PredictionErrorSmoother.ContactMinDistance < v15 then
					local v20 = assert(self._previousPresentedState)
					v20.Position += v17
				end

				onPlayerContactCorrection(v15, self:_presentationContext(), v17)
			end
		end

		self:_dispatchStepEvents(v14, sample.CommandNumber)
		self._diagnostics:recordPredictedStep(sample, v7, frameSampleAlpha, stateForCommand, simulate, support, v14)
		return true, nil
	end
end

function class:_present()
	local presentationContextScratch = self._presentationContextScratch
	local presentationClock, tickFraction = self:_presentationClock()
	presentationContextScratch.Mapping = self._mapping
	presentationContextScratch.ServerTick = presentationClock
	presentationContextScratch.TickFraction = tickFraction
	presentationContextScratch.LocalPlayerContactCritical = self:_localPlayerContactCritical()
	presentationContextScratch.Status = self._status
	presentationContextScratch.Reason = self._reason
	local state = self._state
	local support = self._support
	local presentRemotes = self._options.PresentRemotes
	local remoteBuffer = self._remoteBuffer
	local mapping = self._mapping
	local playerCollisionsEnabled

	if mapping == nil then
		playerCollisionsEnabled = false
	else
		playerCollisionsEnabled = mapping.PlayerCollisionsEnabled
	end

	local remotePresentations = self._remotePresentations
	local remotePresentationPool = self._remotePresentationPool
	local count = 0
	local count2 = 0
	local count3 = 0
	local userId = Players.LocalPlayer.UserId
	table.clear(remotePresentations)

	if remoteBuffer ~= nil and presentationContextScratch.ServerTick ~= nil then
		for _, v in remoteBuffer:actorKeys() do
			local presentationPoses, v2 = remoteBuffer:getPresentationPoses(
				v,
				presentationContextScratch.ServerTick,
				presentationContextScratch.TickFraction
			)

			if presentRemotes == nil then
				presentationPoses = nil
			end

			if v ~= userId and presentRemotes ~= nil then
				count += 1

				if presentationPoses == nil then
					if v2 == nil then
						count3 += 1
					else
						count2 += 1
					end
				end
			end

			local v3 = v2 or presentationPoses

			if not (v3 ~= nil and (mapping == nil or v3.ActorId ~= mapping.ActorId)) then
				continue
			end

			local v4

			if v2 == nil then
				v4 = false
			elseif playerCollisionsEnabled then
				if
					self._contactActorIds[v3.ActorId] == true
					or support ~= nil and support.Kind == Enums.SupportKind.Player and support.SourceId == v3.ActorId
				then
					v4 = true
				elseif state == nil then
					v4 = false
				else
					v4 = withinPlayerContactMargin(state, v2)
				end
			else
				v4 = playerCollisionsEnabled
			end

			presentationContextScratch.LocalPlayerContactCritical = presentationContextScratch.LocalPlayerContactCritical
				or v4

			if presentRemotes == nil then
				continue
			end

			local v5 = #remotePresentations + 1
			local v6 = remotePresentationPool[v5]

			if v6 == nil then
				v6 = {
					UserId = v3.UserId,
					ActorId = v3.ActorId,
					Generation = v3.Generation,
					RenderPose = presentationPoses
				}
				remotePresentationPool[v5] = v6
			else
				v6.UserId = v3.UserId
				v6.ActorId = v3.ActorId
				v6.Generation = v3.Generation
				v6.RenderPose = presentationPoses
			end

			remotePresentations[v5] = v6
		end
	end

	self._diagnostics:recordRemotePresentation(count, count2, count3, count2 + count3 > 0)
	local presentLocal = self._options.PresentLocal

	if presentLocal ~= nil and self._presentedState ~= nil and self._presentedSupport ~= nil then
		local localClockAnchor, tickFraction2 = self:_localClockAnchor()
		local localPresentationContextScratch = self._localPresentationContextScratch
		localPresentationContextScratch.Mapping = presentationContextScratch.Mapping
		localPresentationContextScratch.ServerTick = localClockAnchor
		localPresentationContextScratch.TickFraction = tickFraction2
		localPresentationContextScratch.LocalPlayerContactCritical = presentationContextScratch.LocalPlayerContactCritical
		localPresentationContextScratch.Status = presentationContextScratch.Status
		localPresentationContextScratch.Reason = presentationContextScratch.Reason
		presentLocal(
			self._presentedState,
			self._presentedSupport,
			localPresentationContextScratch,
			self._previousPresentedState or self._presentedState
		)
	end

	if presentRemotes ~= nil then
		debug.profilebegin("MovementV2.Client.PresentRemotes")
		presentRemotes(remotePresentations, presentationContextScratch)
		debug.profileend()
	end
end

function class:_updateReplayBudget(p: number)
	local config = self._config
	local v = config == nil and 1
		or math.ceil(math.min(p, config.MaxPredictionFrameTicks * config.StepSeconds) / config.StepSeconds * 1.1)
	local maximumSteps = config == nil and 16 or math.max(16, math.ceil(config.MaxPredictionFrameTicks * 1.1) + 2)
	self._reconciliationReplayBudget.MaximumSteps = maximumSteps
	self._reconciliationReplayBudget.MinimumSteps = math.min(maximumSteps, v + 2)
end

function class:_advanceReplayAndControls()
	local v = self._pendingReconciliationInstall ~= nil

	if v then
		local _, v2 = self:_resumePendingReconciliation()

		if v2 ~= nil and v2 ~= "ReplayPending" and v2 ~= "ReplayEventOutsideRetention" then
			self:_warn(`could not resume reconciliation replay: {v2}`)
			local mapping = self._mapping

			if mapping ~= nil then
				self:_sendMappingRequest(mapping.Generation)
			end
		end
	end

	if self._pendingReconciliationInstall ~= nil or v then
		return v
	end

	self:_drainPendingCollisionControls()
	self:_flushPendingMoverReplay()
	self:_flushPendingDamageTagReplay()
	ActionLockReplay.flush(self)
	return v
end

function class:_installQueuedOwnerSnapshot(flag: boolean)
	local pendingOwnerSnapshot = self._pendingOwnerSnapshot
	local v

	if self._status == "WaitingForBaseline" then
		v = true
	elseif self._status == "WaitingForAuthority" and self._reason ~= nil then
		v = string.sub(self._reason, 1, 7) == "Awaiting"
	else
		v = false
	end

	if
		pendingOwnerSnapshot ~= nil
		and self._pendingReconciliationInstall == nil
		and not flag
		and not v
		and self:_remoteContactFrameReady(pendingOwnerSnapshot)
	then
		self._pendingOwnerSnapshot = nil
		self:_handleOwnerSnapshot(pendingOwnerSnapshot)
	end
end

function class:_enterPredictionFailureStatus(value: string?)
	if value == "InputUnavailable" or value ~= nil and string.sub(value, 1, 14) == "InputRejected:" then
		self._accumulatorSeconds = 0
		self:_setStatus("WaitingForInput", value)
	elseif
		value == "BaselineRequired"
		or value == "DestructibleRevisionMismatch"
		or value == "DestructibleFrameOutsideRetention"
	then
		self:_setStatus("WaitingForBaseline", value)
	else
		self:_setStatus("WaitingForAuthority", value)
	end

	self._statusFromPredictionFailure = true
end

function class:_drainPrediction(frameSeconds: number, flag: boolean)
	local config = self._config

	if not self:_canPredict() or config == nil then
		return
	end

	local accumulatorSeconds = self._accumulatorSeconds
	local commandClock = self._commandClock
	local v = commandClock == nil and 1 or commandClock:rate(os.clock())
	local plan = PredictionPacing.plan(self._accumulatorSeconds, frameSeconds, assert(self._predictionPacingPolicy), v)
	local admittedSeconds = plan.AdmittedSeconds
	self._accumulatorSeconds = plan.AccumulatorSeconds
	local discardedSeconds = plan.DiscardedSeconds
	local guaranteedSteps = plan.GuaranteedSteps
	local maxSteps = plan.MaxSteps
	local v2 = guaranteedSteps * config.StepSeconds
	local _accumulatorSeconds = self._accumulatorSeconds
	local v3 = discardedSeconds > 0 or v2 + config.StepSeconds < _accumulatorSeconds
	local lastTime = os.clock()
	local v4 = math.min(0.00075, admittedSeconds * 0.15)
	debug.profilebegin("MovementV2.Client.PredictionDrain")
	local count = 0
	local v5 = false

	while self._accumulatorSeconds >= config.StepSeconds and not (maxSteps <= count) do
		if plan.MinimumSteps <= count and os.clock() - lastTime >= plan.WorkCeilingSeconds then
			v5 = true
			break
		end

		if
			guaranteedSteps <= count
			and (flag or self._pendingReconciliationInstall ~= nil or v4 <= os.clock() - lastTime)
		then
			break
		end

		local v6 = config.StepSeconds - accumulatorSeconds + count * config.StepSeconds
		local v7, v8 = self:_stepPrediction(not (admittedSeconds > 0) and 1 or math.clamp(v6 / admittedSeconds, 0, 1))

		if v7 then
			if self._statusFromPredictionFailure then
				self:_setStatus("Running", nil)
			end

			self._accumulatorSeconds -= config.StepSeconds
			count += 1
		else
			self:_sendDueCommands(true)
			self:_enterPredictionFailureStatus(v8)
			break
		end
	end

	debug.profileend()
	self._diagnostics:recordPredictionFrame(count, discardedSeconds, v5)
	local predictionWorkSeconds = os.clock() - lastTime
	local now = os.clock()

	if v3 and now - self._lastPredictionHitchAt >= 0.25 then
		self._lastPredictionHitchAt = now
		local frozen = table.freeze({
			FrameSeconds = frameSeconds,
			DiscardedSeconds = discardedSeconds,
			BacklogBeforeSeconds = _accumulatorSeconds,
			BacklogAfterSeconds = self._accumulatorSeconds,
			StepsDrained = count,
			GuaranteedStepBudget = guaranteedSteps,
			StepBudget = maxSteps,
			PredictionWorkSeconds = predictionWorkSeconds,
			OwnerSnapshotAgeSeconds = self._lastOwnerAppliedAt <= 0 and -1 or now - self._lastOwnerAppliedAt,
			ServerTick = self._lastPredictedServerTick,
			Status = self._status
		})
		self._diagnostics:reportPredictionHitch(frozen)
		local onPredictionHitch = self._options.OnPredictionHitch

		if onPredictionHitch ~= nil then
			onPredictionHitch(frozen)
		end
	end
end

function class:advance(value: number)
	local v = typeof(value) == "number" and value == value and value >= 0 and value < 1e999
	assert(v, "invalid delta")

	if self._discardNextAdvanceDelta then
		self._discardNextAdvanceDelta = false
		value = 0
	end

	local pendingCommandResyncThrough = self._pendingCommandResyncThrough

	if pendingCommandResyncThrough ~= nil and os.clock() - self._commandResyncRequestedAt >= 0.5 then
		self:_sendCommandResyncRequest(pendingCommandResyncThrough, true)
	end

	self:_updateReplayBudget(value)
	local prepareInputFrame = self._options.PrepareInputFrame

	if prepareInputFrame ~= nil then
		prepareInputFrame()
	end

	local v2 = self:_advanceReplayAndControls()
	self:_installQueuedOwnerSnapshot(v2)

	if self._status == "WaitingForTopology" then
		self._topologyRetrySeconds += value

		if self._topologyRetrySeconds >= 0.25 then
			self._topologyRetrySeconds %= 0.25
			self:retryTopology()
		end
	end

	self:_drainPrediction(value, v2)
	self:_recoverStalledCommands()
	self:_sendDueCommands()
	self._diagnostics:emitNetcodeSummary()
end

function class:render(value: number?)
	local v

	if value == nil then
		v = true
	elseif typeof(value) == "number" and value == value and value >= 0 then
		v = value < 1e999
	else
		v = false
	end

	assert(v, "invalid render delta")
	local remoteClock = self._remoteClock

	if remoteClock ~= nil then
		remoteClock:advance(value, os.clock())
	end

	self:_present()
end

function class:start()
	if self._started then
		return
	end

	self._started = true
	self._channels = Transport.getClientChannels()
	self._requestedMappingGeneration = nil
	local v = assert(self._channels)
	self._traceCapture:bind(v)
	self._connections[#self._connections + 1] = v.Control.OnClientEvent:Connect(function(p)
		self:_handleControl(p)
	end)
	self._connections[#self._connections + 1] = v.Diagnostics.OnClientEvent:Connect(function(data)
		if typeof(data) ~= "table" or data.Kind ~= "MovementFailure" or type(data.Message) ~= "string" then
			return
		end

		warn(`[MovementV2] server movement simulation failed at tick {tostring(data.ServerTick)}; your movement was held:\n{data.Message}`)
	end)
	self._connections[#self._connections + 1] = v.Trace.OnClientEvent:Connect(function(p)
		local lastAcceptedOwnerSnapshot = self._lastAcceptedOwnerSnapshot
		local traceCapture = self._traceCapture
		local v2

		if lastAcceptedOwnerSnapshot ~= nil then
			v2 = lastAcceptedOwnerSnapshot.Sequence
		end

		traceCapture:handleServerTrace(p, v2)
	end)

	for _, v2 in self._diagnostics:connectOutput(v) do
		self._connections[#self._connections + 1] = v2
	end

	self._connections[#self._connections + 1] = v.OwnerSnapshot.OnClientEvent:Connect(function(buf)
		local decoded = OwnerSnapshotCodec.decode(buf)

		if decoded ~= nil then
			self._diagnostics:recordOwnerSnapshotReceived()
			local mapping = self._mapping
			local onOwnerSnapshotReceived = self._options.OnOwnerSnapshotReceived

			if onOwnerSnapshotReceived ~= nil and mapping ~= nil and decoded.Generation == mapping.Generation then
				onOwnerSnapshotReceived(decoded.Generation, decoded.Sequence, {
					Bytes = buffer.len(buf),
					Kind = "OwnerSnapshot"
				})
			end

			self:_queueOwnerSnapshot(decoded)
		end
	end)
	self._connections[#self._connections + 1] = v.RemoteSnapshot.OnClientEvent:Connect(function(p)
		self:_handleRemoteSnapshot(p)
	end)
	local formatted = `MovementV2.Client.Runtime.{tostring(self)}`
	self._renderStepName = formatted
	RunService:BindToRenderStep(formatted, Enum.RenderPriority.Camera.Value - 2, function(p)
		debug.profilebegin("MovementV2.Client.Advance")
		self:advance(p)
		debug.profileend()
		debug.profilebegin("MovementV2.Client.Render")
		self:render(p)
		debug.profileend()
	end)
	local queuedMappingGeneration = self._queuedMappingGeneration

	if queuedMappingGeneration == nil and self._options.ResolveGeneration ~= nil then
		queuedMappingGeneration = self._options.ResolveGeneration()
	end

	if queuedMappingGeneration == nil and self._mapping ~= nil then
		queuedMappingGeneration = self._mapping.Generation
	end

	if self._mapping == nil then
		self:_setStatus("WaitingForMapping", nil)
	else
		self:_setStatus("WaitingForAuthority", "RuntimeStarted")
	end

	if queuedMappingGeneration ~= nil then
		local mapping, v2 = self:requestMapping(queuedMappingGeneration)

		if not mapping then
			self:_warn(`could not request startup mapping: {v2}`)
		end
	end
end

function class:stop()
	if not self._started then
		return
	end

	self:_sendDueCommands(true)
	self._started = false

	for _, connection in self._connections do
		connection:Disconnect()
	end

	table.clear(self._connections)
	self._diagnostics:clearOutput()
	self._traceCapture:bind(nil)
	local renderStepName = self._renderStepName

	if renderStepName ~= nil then
		RunService:UnbindFromRenderStep(renderStepName)
		self._renderStepName = nil
	end

	self._channels = nil
	self._pendingCommandResyncThrough = nil
	self._commandResyncRequestedAt = 0
	self:_setStatus("Stopped", nil)
end

function class:destroy()
	self:stop()
	self:_disposeTimeline()
	local collisionComposer = self._collisionComposer

	if collisionComposer ~= nil then
		collisionComposer:Reset()
	end

	self._mapping = nil
	self._topology = nil
	self._topologyBuild = nil
	self._cachedStaticFrame = nil
	self._cachedStaticWorld = nil
	self._state = nil
	self._support = nil
	self._traceCapture:reset(nil)
	table.clear(self._damageTagsByMovementTick)
	self._pendingDamageTagReplayMovementTick = nil
	self._actionLocks = nil
	self._pendingActionLockReplay = false
	self:_refreshPresentedState()
end

return table.freeze(class)