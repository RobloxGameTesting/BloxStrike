local createVector = vector.create
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Config = require(script.Parent.Parent.Config)
local DiagnosticProtocol = require(script.Parent.Parent.DiagnosticProtocol)
local Enums = require(script.Parent.Parent.Enums)
local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
local ProvenMath = require(script.Parent.Parent.Simulation.ProvenMath)
local RuntimeSettings = require(script.Parent.Parent.Simulation.RuntimeSettings)
local State = require(script.Parent.Parent.Simulation.State)
require(script.Parent.Parent.Simulation.Types)
require(script.Parent.Parent.Transport)
local CorrectionDiagnostics = require(script.Parent.CorrectionDiagnostics)
local DiagnosticOutput = require(script.Parent.DiagnosticOutput)
local PredictionErrorSmoother = require(script.Parent.PredictionErrorSmoother)
require(script.Parent.PredictionRing)
require(script.Parent.Reconciler)
require(script.Parent.RuntimeTypes)
local frozen = table.freeze({
	OwnerCorrection = 5,
	Reconciliation = 5,
	TraceComparison = 0.5,
	PredictionHitch = 10,
	RuntimeWarning = 5,
	NetcodeSummary = 10
})
local class = {}
class.__index = class
local output = DiagnosticProtocol.output

local function materialAckCorrection(metrics)
	return metrics.ComparedAtAck
		and (metrics.Position >= 0.01 or metrics.Velocity >= 0.1 or metrics.SupportAnchor >= 0.01 or metrics.SupportVelocity >= 0.1 or metrics.LookYaw >= 0.004363323129985824 or metrics.VerticalLook >= 0.004363323129985824 or metrics.DuckAmount >= 0.01 or metrics.Stamina >= 0.01 or metrics.SupportKindMismatch > 0 or metrics.SupportSourceMismatch > 0)
end

local function materialTailCorrection(metrics) -- 1 equivalent call inferred from this helper
	return metrics.TailCompared
		and (metrics.TailPosition >= 0.01 or metrics.TailVelocity >= 0.1 or metrics.TailSupportAnchor >= 0.01 or metrics.TailSupportVelocity >= 0.1 or metrics.TailSupportKindMismatch > 0 or metrics.TailSupportSourceMismatch > 0 or (metrics.TailGroundMismatch or metrics.TailStanceMismatch))
end

local function presentationSnapCorrection(metrics) -- 1 equivalent call inferred from this helper
	return metrics.TailCompared and PredictionErrorSmoother.isHardSnapCorrection(metrics)
end

local function mappingLabel(data)
	if data == nil then
		return "mapping=nil"
	end

	return string.format(
		"mapping generation=%u actor=%u simulationHz=%d topologyEpoch=%u topologyFingerprint=%u playerCollisions=%s",
		data.Generation,
		data.ActorId,
		data.SimulationHz,
		data.TopologyEpoch,
		data.TopologyFingerprint,
		(tostring(data.PlayerCollisionsEnabled))
	)
end

local function supportIdentityLabel(p) -- 3 equivalent calls inferred from this helper
	if p == nil then
		return "nil"
	end

	return `{p.Kind}:{p.SourceId}`
end

local function vectorLabel(velocity: Vector3) -- 8 equivalent calls inferred from this helper
	return string.format("(%+.8f,%+.8f,%+.8f)", velocity.X, velocity.Y, velocity.Z)
end

local function stateLabel(p: string, state)
	if state == nil then
		return `{p}=nil`
	end

	local v = vectorLabel(state.Position) -- inferred equivalent call
	local v2 = vectorLabel(state.Velocity) -- inferred equivalent call
	return string.format(
		"%s pos=%s vel=%s yaw=%+.8f verticalLook=%+.8f baseSpeed=%.5f weaponProfile=%.5f/%.5f velocityModifier=%.6f mode=%s stance=%s onGround=%s groundNormal=%s wallNormal=%s friction=%.6f duck=%.6f duckMs=%.3f isDucking=%s duckSpeed=%.6f duckCooldown=%.6f stamina=%.6f lastJumpCmd=%u buttons=0x%02X jumpBuffer=%d jumpHull=%s stuckTicks=%d",
		p,
		v,
		v2,
		state.LookYaw,
		state.VerticalLook,
		state.BaseMoveSpeed,
		state.WeaponMoveSpeed,
		state.WeaponScopedMoveSpeed,
		state.VelocityModifier,
		state.MovementMode,
		state.Stance,
		tostring(state.OnGround),
		vectorLabel(state.GroundNormal), -- inferred equivalent call
		vectorLabel(state.WallNormal), -- inferred equivalent call
		state.GroundSurfaceFriction,
		state.DuckAmount,
		state.DuckTimeMsecs,
		tostring(state.IsDucking),
		state.DuckSpeed,
		state.DuckCooldownSeconds,
		state.Stamina,
		state.LastJumpCommandNumber,
		state.PreviousButtons,
		state.JumpBufferTicksRemaining,
		tostring(state.JumpHullActive),
		state.StuckStepTicks
	)
end

local function supportLabel(p: string, support)
	if support == nil then
		return `{p}=nil`
	end

	return string.format(
		"%s kind=%d source=%u anchor=%s velocity=%s",
		p,
		support.Kind,
		support.SourceId,
		vectorLabel(support.Anchor), -- inferred equivalent call
		vectorLabel(support.Velocity)
	)
end

local function snapshotIdentity(data) -- 2 equivalent calls inferred from this helper
	return {
		Generation = data.Generation,
		Sequence = data.Sequence,
		CommandNumber = data.LastProcessedCommand,
		ServerTick = data.ServerTick
	}
end

local function tailIdentity(runtime) -- 2 equivalent calls inferred from this helper
	local lastAcceptedOwnerSnapshot = runtime._lastAcceptedOwnerSnapshot
	local sequence

	if lastAcceptedOwnerSnapshot ~= nil then
		sequence = lastAcceptedOwnerSnapshot.Sequence
	end

	local commandNumber

	if lastAcceptedOwnerSnapshot ~= nil then
		commandNumber = lastAcceptedOwnerSnapshot.LastProcessedCommand
	end

	return { Sequence = sequence, CommandNumber = commandNumber }
end

local function signedHorizontalAngle(vector: Vector3, vector2: Vector3) -- 2 equivalent calls inferred from this helper
	if vector.Magnitude <= 1e-6 or vector2.Magnitude <= 1e-6 then
		return 0
	end

	return (math.atan2(vector.X * vector2.Z - vector.Z * vector2.X, (vector:Dot(vector2))))
end

local function newWindow()
	return {
		BarrierCounts = {},
		ReplayCommands = 0,
		ReplayEvents = 0,
		StallSamples = 0,
		StalledFlagSamples = 0,
		StalledRun = 0,
		LongestStalledRun = 0,
		DepthSum = 0,
		DepthSamples = 0,
		WorstDepth = nil,
		StepsDrained = 0,
		Frames = 0,
		MaxStepsInFrame = 0,
		DiscardedSeconds = 0,
		CeilingBreaks = 0,
		RemoteFramesSeen = 0,
		RemoteSequenceGaps = 0,
		RemoteBaselineRejects = 0,
		RemoteOtherRejects = 0,
		RemoteActorSamples = 0,
		RemoteStaleSamples = 0,
		RemoteMissingSamples = 0,
		RemoteBlindFrames = 0,
		RemoteBlindRunStartedAt = nil,
		RemoteLongestBlindSeconds = 0,
		StatusDwellSeconds = {},
		StatusEnteredAt = os.clock(),
		ResyncRequests = 0,
		MappingRequests = 0,
		CommandPacketsBase = 0,
		RecoveryPacketsBase = 0,
		SendDeferralsBase = 0,
		MaxCorrection = 0,
		CorrectionCount = 0
	}
end

function class.new(runtime)
	local now = os.clock()
	return (setmetatable({
		_runtime = runtime,
		_output = DiagnosticOutput.new(),
		_window = newWindow(),
		_summaryAt = now,
		_ownerReceived = 0,
		_ownerApplied = 0,
		_replayTotal = 0,
		_replayMax = 0,
		_reconciliationCount = 0,
		_lastSummaryAt = 0,
		_lastAnomalyAt = 0,
		_lastReportAtByKind = {},
		_airStrafeHeaderPrinted = false,
		_airStrafeLineCount = 0
	}, class))
end

function class:reportingEnabled()
	return DiagnosticProtocol.shouldReport(Players.LocalPlayer)
end

function class:_resetWindow()
	local window = newWindow()
	window.RemoteBlindRunStartedAt = self._window.RemoteBlindRunStartedAt
	local counters = self._runtime._uplink:counters()
	window.CommandPacketsBase = counters.PacketsSent
	window.RecoveryPacketsBase = counters.RecoveryPacketsSent
	window.SendDeferralsBase = counters.BudgetDeferrals
	self._window = window
end

function class:resetGeneration()
	self._ownerReceived = 0
	self._ownerApplied = 0
	self._replayTotal = 0
	self._replayMax = 0
	self._reconciliationCount = 0
	self._lastSummaryAt = 0
	self._lastAnomalyAt = 0
	table.clear(self._lastReportAtByKind)
	self:_resetWindow()
	self._remoteLastSequence = nil
end

function class:reportIssue(kind, value: string, options)
	local runtime = self._runtime
	local channels = runtime._channels

	if channels == nil or not self:reportingEnabled() then
		return
	end

	local now = os.clock()
	local v = self._lastReportAtByKind[kind] or -1e999
	local v2 = frozen[kind] or 5

	if now - v < v2 then
		return
	end

	self._lastReportAtByKind[kind] = now
	local mapping = runtime._mapping
	local v3 = options or {}
	local diagnostics = channels.Diagnostics
	local v4 = {
		Version = DiagnosticProtocol.Version,
		Kind = kind,
		Generation = 0,
		ActorId = 0,
		Sequence = 0,
		CommandNumber = 0,
		ServerTick = 0,
		ClientServerTime = 0,
		ClientLog = 0
	}
	local generation = v3.Generation

	if not generation then
		if mapping == nil then
			generation = nil
		else
			generation = mapping.Generation
		end
	end

	v4.Generation = generation
	local actorId = v3.ActorId

	if not actorId then
		if mapping == nil then
			actorId = nil
		else
			actorId = mapping.ActorId
		end
	end

	v4.ActorId = actorId
	v4.Sequence = v3.Sequence
	v4.CommandNumber = v3.CommandNumber
	v4.ServerTick = v3.ServerTick or runtime._lastPredictedServerTick
	v4.ClientServerTime = Workspace:GetServerTimeNow()
	v4.ClientLog = string.sub(value, 1, DiagnosticProtocol.MaxClientLogBytes)
	diagnostics:FireServer(v4)
end

function class:reportWarning(p: string)
	if not self:reportingEnabled() then
		return
	end

	local runtime = self._runtime
	local v = string.format(
		"issue=RuntimeWarning message=%s status=%s statusReason=%s clientServerTime=%.6f accumulatorMs=%.3f",
		p,
		runtime._status,
		tostring(runtime._reason),
		Workspace:GetServerTimeNow(),
		runtime._accumulatorSeconds * 1000
	)
	local mapping = runtime._mapping
	self:reportIssue("RuntimeWarning", table.concat({
		v,
		mapping == nil and "mapping=nil" or string.format(
			"mapping generation=%u actor=%u simulationHz=%d topologyEpoch=%u topologyFingerprint=%u playerCollisions=%s",
			mapping.Generation,
			mapping.ActorId,
			mapping.SimulationHz,
			mapping.TopologyEpoch,
			mapping.TopologyFingerprint,
			(tostring(mapping.PlayerCollisionsEnabled))
		),
		stateLabel("predictedTail", runtime._state),
		supportLabel("predictedTailSupport", runtime._support)
	}, "\n"), tailIdentity(runtime)) -- inferred equivalent call
end

function class:reportPredictionHitch(data)
	if not self:reportingEnabled() then
		return
	end

	local runtime = self._runtime
	local v = string.format(
		"issue=PredictionHitch likelyCause=ClientFrameStallOrPredictionDebt frameMs=%.3f discardedMs=%.3f backlogBeforeMs=%.3f backlogAfterMs=%.3f drained=%d guaranteed=%d hardCap=%d predictionWorkMs=%.3f ownerAgeMs=%.3f status=%s statusReason=%s accumulatorMs=%.3f",
		data.FrameSeconds * 1000,
		data.DiscardedSeconds * 1000,
		data.BacklogBeforeSeconds * 1000,
		data.BacklogAfterSeconds * 1000,
		data.StepsDrained,
		data.GuaranteedStepBudget,
		data.StepBudget,
		data.PredictionWorkSeconds * 1000,
		data.OwnerSnapshotAgeSeconds * 1000,
		data.Status,
		tostring(runtime._reason),
		runtime._accumulatorSeconds * 1000
	)
	local mapping = runtime._mapping
	self:reportIssue("PredictionHitch", table.concat({
		v,
		mapping == nil and "mapping=nil" or string.format(
			"mapping generation=%u actor=%u simulationHz=%d topologyEpoch=%u topologyFingerprint=%u playerCollisions=%s",
			mapping.Generation,
			mapping.ActorId,
			mapping.SimulationHz,
			mapping.TopologyEpoch,
			mapping.TopologyFingerprint,
			(tostring(mapping.PlayerCollisionsEnabled))
		),
		stateLabel("predictedTail", runtime._state),
		supportLabel("predictedTailSupport", runtime._support)
	}, "\n"), tailIdentity(runtime)) -- inferred equivalent call
end

function class:recordStatusChange(p)
	local now = os.clock()
	local window = self._window
	local statusDwellSeconds = window.StatusDwellSeconds
	statusDwellSeconds[p] = (statusDwellSeconds[p] or 0) + (now - window.StatusEnteredAt)
	window.StatusEnteredAt = now
end

function class:recordOwnerSnapshotReceived()
	self._ownerReceived += 1
end

function class:recordOwnerFeedback(p)
	local window = self._window
	local bufferDepth = p.BufferDepth
	window.DepthSum += bufferDepth
	window.DepthSamples += 1

	if window.WorstDepth == nil or bufferDepth < window.WorstDepth then
		window.WorstDepth = bufferDepth
	end

	if bufferDepth < 0 then
		window.StallSamples += 1
	end

	if bit32.band(p.Flags, Enums.OwnerSnapshotFlags.Stalled) == 0 then
		window.StalledRun = 0
		return
	end

	window.StalledFlagSamples += 1
	window.StalledRun += 1
	window.LongestStalledRun = math.max(window.LongestStalledRun, window.StalledRun)
end

function class:recordRemoteSnapshot(remoteLastSequence: number)
	local window = self._window
	local _remoteLastSequence = self._remoteLastSequence

	if _remoteLastSequence == nil then
		self._remoteLastSequence = remoteLastSequence
		window.RemoteFramesSeen += 1
	elseif Serial.isNewerUInt32(remoteLastSequence, _remoteLastSequence) then
		window.RemoteSequenceGaps += Serial.deltaUInt32(remoteLastSequence, _remoteLastSequence) - 1
		self._remoteLastSequence = remoteLastSequence
		window.RemoteFramesSeen += 1
	end
end

function class:recordRemoteRejected(p: string)
	if p == "RemoteBaselineRequired" then
		self._window.RemoteBaselineRejects += 1
	else
		self._window.RemoteOtherRejects += 1
	end
end

function class:recordRemotePresentation(p: number, p2: number, p3: number, flag: boolean)
	local window = self._window
	window.RemoteActorSamples += p
	window.RemoteStaleSamples += p2
	window.RemoteMissingSamples += p3

	if not flag then
		window.RemoteBlindRunStartedAt = nil
		return
	end

	window.RemoteBlindFrames += 1
	local remoteBlindRunStartedAt = window.RemoteBlindRunStartedAt

	if remoteBlindRunStartedAt == nil then
		remoteBlindRunStartedAt = os.clock()
		window.RemoteBlindRunStartedAt = remoteBlindRunStartedAt
	end

	local remoteLongestBlindSeconds = os.clock() - remoteBlindRunStartedAt

	if window.RemoteLongestBlindSeconds < remoteLongestBlindSeconds then
		window.RemoteLongestBlindSeconds = remoteLongestBlindSeconds
	end
end

function class:recordPredictionFrame(maxStepsInFrame: number, p: number, flag: boolean)
	local window = self._window
	window.Frames += 1
	window.StepsDrained += maxStepsInFrame
	window.DiscardedSeconds += p

	if window.MaxStepsInFrame < maxStepsInFrame then
		window.MaxStepsInFrame = maxStepsInFrame
	end

	if flag then
		window.CeilingBreaks += 1
	end
end

function class:recordResyncRequest()
	self._window.ResyncRequests += 1
end

function class:recordMappingRequest()
	self._window.MappingRequests += 1
end

function class:_recordReplayWindow(p)
	local window = self._window
	local replayBarrier = p.Metrics.ReplayBarrier
	window.BarrierCounts[replayBarrier] = (window.BarrierCounts[replayBarrier] or 0) + 1

	if p.ReplayCount > 0 then
		window.ReplayEvents += 1
		window.ReplayCommands += p.ReplayCount
	end

	if p.Metrics.Position > window.MaxCorrection then
		window.MaxCorrection = p.Metrics.Position
	end

	if p.Metrics.Position > 0.01 then
		window.CorrectionCount += 1
	end
end

function class:_reportOwnerCorrection(data, data2, data3, p: number, p2: number, p3: number, p4: number?, p5: number)
	local runtime = self._runtime
	local metrics = data2.Metrics
	local predictionRing = runtime._predictionRing
	local v

	if runtime._remoteClock ~= nil then
		v = runtime._remoteClock:diagnostics()
	end

	local v2, v3, v4 = runtime._uplink:peekBudget(runtime._config, p)
	local counters = runtime._uplink:counters()
	local lastRecoveryAcknowledgedCommand = runtime._uplink:lastRecoveryAcknowledgedCommand()
	local command

	if data3 ~= nil then
		command = data3.Command
	end

	local v5 = -1
	local success, result = pcall(function()
		return Players.LocalPlayer:GetNetworkPing()
	end)

	if success and typeof(result) == "number" then
		v5 = result
	end

	local v6 = nil
	local resolveMovementDiagnosticContext = runtime._options.ResolveMovementDiagnosticContext

	if resolveMovementDiagnosticContext ~= nil then
		local success2, result2 = pcall(resolveMovementDiagnosticContext, data.ServerTime)

		if success2 and typeof(result2) == "table" then
			v6 = result2
		end
	end

	local classify = CorrectionDiagnostics.classify
	local v7

	if data3 ~= nil then
		v7 = data3.PostState
	end

	local v8 = classify(metrics, v7, data.State, v6)
	local v10 = string.format(
		"issue=OwnerCorrection suspectedCause=%s status=%s statusReason=%s clientServerTime=%.6f pingMs=%.2f",
		v8,
		runtime._status,
		tostring(runtime._reason),
		Workspace:GetServerTimeNow(),
		v5 * 1000
	)
	local mapping = runtime._mapping
	local v11 = mapping == nil and "mapping=nil"
		or string.format(
			"mapping generation=%u actor=%u simulationHz=%d topologyEpoch=%u topologyFingerprint=%u playerCollisions=%s",
			mapping.Generation,
			mapping.ActorId,
			mapping.SimulationHz,
			mapping.TopologyEpoch,
			mapping.TopologyFingerprint,
			(tostring(mapping.PlayerCollisionsEnabled))
		)
	local formatMovementLockContext = CorrectionDiagnostics.formatMovementLockContext(v6, data.ServerTime)
	local v12 = string.format(
		"anchor sequence=%u ackCommand=%u predictedAckTick=%s authorityTick=%u tailTick=%u newestCommand=%s commandLead=%d ring=%d ownerReceived=%d ownerApplied=%d topologyRevision=%u moverRevision=%u flags=0x%02X",
		data.Sequence,
		data.LastProcessedCommand,
		data3 == nil and "nil" or tostring(data3.ServerTick),
		data.ServerTick,
		data2.TailServerTick,
		p4 == nil and "nil" or tostring(p4),
		p5,
		predictionRing == nil and 0 or predictionRing:count(),
		self._ownerReceived,
		self._ownerApplied,
		data.Topology.DestructibleRevision,
		data.Topology.MoverRevision,
		data.Flags
	)
	local v13 = string.format(
		"commandTransport packets=%d recoveryPackets=%d budgetDeferrals=%d tokens=%.3f/%.3f rate=%.3f recoveryAck=%s",
		counters.PacketsSent,
		counters.RecoveryPacketsSent,
		counters.BudgetDeferrals,
		v2,
		v4,
		v3,
		lastRecoveryAcknowledgedCommand == nil and "nil" or tostring(lastRecoveryAcknowledgedCommand)
	)
	local v14 = string.format(
		"reconcile count=%d mode=%s barrier=%s replay=%d retiredAckedPredictions=%d ackAdvance=%d tickAdvance=%d heldTicks=%d synthInput=%s playerContact=%s comparedAtAck=%s tailCompared=%s tailTickDelta=%d workMs=%.3f elapsedMs=%.3f slices=%d maxSliceMs=%.3f",
		self._reconciliationCount,
		metrics.ReconciliationMode,
		metrics.ReplayBarrier,
		metrics.ReplayCount,
		metrics.DroppedCommandCount,
		metrics.AcknowledgedCommandDelta,
		metrics.ServerTickDelta,
		metrics.ServerHeldTickCount,
		tostring(metrics.SynthesizedInput),
		tostring(metrics.PlayerContactCorrection),
		tostring(metrics.ComparedAtAck),
		tostring(metrics.TailCompared),
		metrics.TailServerTickDelta,
		metrics.ReconciliationWorkSeconds * 1000,
		metrics.ReconciliationElapsedSeconds * 1000,
		metrics.ReconciliationSliceCount,
		metrics.ReconciliationMaximumSliceSeconds * 1000
	)
	local v15 = string.format(
		"ackError fields=%s mask=0x%X count=%d position=%.8f horizontal=%.8f vertical=%+.8f velocity=%.8f verticalVelocity=%+.8f yawDeg=%.6f verticalLookDeg=%.6f duck=%.8f stamina=%.8f supportAnchor=%.8f supportVelocity=%.8f supportKindMismatch=%d supportSourceMismatch=%d supportCanonicalMismatch=%s topologyRevisionDelta=%d",
		State.mismatchLabel(metrics.CanonicalStateMismatchMask),
		metrics.CanonicalStateMismatchMask,
		metrics.CanonicalStateMismatchCount,
		metrics.Position,
		metrics.HorizontalPosition,
		p2,
		metrics.Velocity,
		p3,
		math.deg(metrics.LookYaw),
		math.deg(metrics.VerticalLook),
		metrics.DuckAmount,
		metrics.Stamina,
		metrics.SupportAnchor,
		metrics.SupportVelocity,
		metrics.SupportKindMismatch,
		metrics.SupportSourceMismatch,
		tostring(metrics.CanonicalSupportMismatch),
		metrics.TopologyRevisionDelta
	)
	local v16 = string.format(
		"tailError position=%.8f horizontal=%.8f vertical=%+.8f velocity=%.8f verticalVelocity=%+.8f supportAnchor=%.8f supportVelocity=%.8f supportKindMismatch=%d supportSourceMismatch=%d groundMismatch=%s stanceMismatch=%s",
		metrics.TailPosition,
		metrics.TailHorizontalPosition,
		metrics.TailVerticalPosition,
		metrics.TailVelocity,
		metrics.TailVerticalVelocity,
		metrics.TailSupportAnchor,
		metrics.TailSupportVelocity,
		metrics.TailSupportKindMismatch,
		metrics.TailSupportSourceMismatch,
		tostring(metrics.TailGroundMismatch),
		(tostring(metrics.TailStanceMismatch))
	)
	local v17 = command == nil and "ackCommandInput=nil"
		or string.format(
			"ackCommandInput number=%u move=(%+.6f,%+.6f) yaw=%+.8f verticalLook=%+.8f buttons=0x%02X weaponRequest=%s weapon=%s predictedBaseSpeed=%s weaponProfile=%s/%s",
			command.CommandNumber,
			command.Move.X,
			command.Move.Y,
			command.LookYaw,
			command.VerticalLook,
			command.Buttons,
			tostring(command.WeaponSelectRequestId),
			tostring(command.WeaponSelectIdentifier),
			tostring(command.PredictedBaseMoveSpeed),
			tostring(command.PredictedWeaponMoveSpeed),
			(tostring(command.PredictedWeaponScopedMoveSpeed))
		)
	local v18

	if data3 ~= nil then
		v18 = data3.PostState
	end

	local v19 = stateLabel("predictedAtAck", v18)
	local postSupport

	if data3 ~= nil then
		postSupport = data3.PostSupport
	end

	local v20

	if postSupport == nil then
		v20 = "predictedSupportAtAck=nil"
	else
		v20 = string.format(
			"%s kind=%d source=%u anchor=%s velocity=%s",
			"predictedSupportAtAck",
			postSupport.Kind,
			postSupport.SourceId,
			vectorLabel(postSupport.Anchor), -- inferred equivalent call
			vectorLabel(postSupport.Velocity)
		)
	end

	local v21 = stateLabel("authoritativeAtAck", data.State)
	local support = data.Support
	local v22

	if support == nil then
		v22 = "authoritativeSupportAtAck=nil"
	else
		v22 = string.format(
			"%s kind=%d source=%u anchor=%s velocity=%s",
			"authoritativeSupportAtAck",
			support.Kind,
			support.SourceId,
			vectorLabel(support.Anchor), -- inferred equivalent call
			vectorLabel(support.Velocity)
		)
	end

	local v23 = stateLabel("reconciledTail", data2.State)
	local support2 = data2.Support
	local v24

	if support2 == nil then
		v24 = "reconciledTailSupport=nil"
	else
		v24 = string.format(
			"%s kind=%d source=%u anchor=%s velocity=%s",
			"reconciledTailSupport",
			support2.Kind,
			support2.SourceId,
			vectorLabel(support2.Anchor), -- inferred equivalent call
			vectorLabel(support2.Velocity)
		)
	end

	local v9 = {
		v10,
		v11,
		formatMovementLockContext,
		v12,
		v13,
		v14,
		v15,
		v16,
		v17,
		v19,
		v20,
		v21,
		v22,
		v23,
		v24,
		v == nil and "remoteClock=nil" or string.format(
			"remoteClock mode=%s driftTicks=%+.6f hardRebases=%d latestObservedTick=%s",
			v.Mode,
			v.DriftTicks,
			v.HardRebases,
			(tostring(v.LatestObservedTick))
		)
	}
	self:reportIssue("OwnerCorrection", table.concat(v9, "\n"), snapshotIdentity(data)) -- inferred equivalent call
end

function class:_printOwnerTrace(data, data2, data3, p: number, flag: boolean, p2: number, p3: number, p4: number?, p5: number)
	local metrics = data2.Metrics

	if
		metrics.ReconciliationMode ~= "Reuse"
		and not metrics.PlayerContactCorrection
		and (materialAckCorrection(metrics) or metrics.TailCompared and (metrics.TailPosition >= 0.01 or metrics.TailVelocity >= 0.1 or metrics.TailSupportAnchor >= 0.01 or metrics.TailSupportVelocity >= 0.1 or metrics.TailSupportKindMismatch > 0 or metrics.TailSupportSourceMismatch > 0 or metrics.TailGroundMismatch or metrics.TailStanceMismatch))
	then
		output(string.format(
			"[MovementV2.Client] CORRECTION mode=%s barrier=%s seq=%u ack=%u tick=%u ackFields=%s ackPos=%.8f ackVel=%.8f tailPos=%.8f tailY=%+.8f tailVel=%.8f tailVy=%+.8f tailTickDelta=%d replay=%d workMs=%.3f elapsedMs=%.3f slices=%d maxSliceMs=%.3f held=%d synth=%s groundTail=%s stanceTail=%s supportTail=%d/%d",
			metrics.ReconciliationMode,
			metrics.ReplayBarrier,
			data.Sequence,
			data.LastProcessedCommand,
			data.ServerTick,
			State.mismatchLabel(metrics.CanonicalStateMismatchMask),
			metrics.Position,
			metrics.Velocity,
			metrics.TailPosition,
			metrics.TailVerticalPosition,
			metrics.TailVelocity,
			metrics.TailVerticalVelocity,
			metrics.TailServerTickDelta,
			metrics.ReplayCount,
			metrics.ReconciliationWorkSeconds * 1000,
			metrics.ReconciliationElapsedSeconds * 1000,
			metrics.ReconciliationSliceCount,
			metrics.ReconciliationMaximumSliceSeconds * 1000,
			metrics.ServerHeldTickCount,
			tostring(metrics.SynthesizedInput),
			tostring(metrics.TailGroundMismatch),
			tostring(metrics.TailStanceMismatch),
			metrics.TailSupportKindMismatch,
			metrics.TailSupportSourceMismatch
		))
	end

	local v = p - self._lastSummaryAt >= 1
	local v2 = flag and p - self._lastAnomalyAt >= 0.25

	if not (v or v2) then
		return
	end

	if v then
		self._lastSummaryAt = p
	end

	if v2 then
		self._lastAnomalyAt = p
	end

	local predictionRing = self._runtime._predictionRing
	local v3 = self._replayTotal / math.max(self._ownerApplied, 1)
	local reconciliationMode = metrics.ReconciliationMode
	local replayBarrier = metrics.ReplayBarrier
	local sequence = data.Sequence
	local lastProcessedCommand = data.LastProcessedCommand
	local v4 = data3 == nil and "nil" or tostring(data3.ServerTick)
	local serverTick = data.ServerTick
	local acknowledgedCommandDelta = metrics.AcknowledgedCommandDelta
	local serverTickDelta = metrics.ServerTickDelta
	local serverHeldTickCount = metrics.ServerHeldTickCount
	local synthesizedInput = tostring(metrics.SynthesizedInput)
	local v5 = p4 == nil and "nil" or tostring(p4)
	local reconciliationCount = self._reconciliationCount
	local replayCount = data2.ReplayCount
	local v6 = metrics.ReconciliationWorkSeconds * 1000
	local v7 = metrics.ReconciliationElapsedSeconds * 1000
	local reconciliationSliceCount = metrics.ReconciliationSliceCount
	local v8 = metrics.ReconciliationMaximumSliceSeconds * 1000
	local replayMax = self._replayMax
	local v9 = predictionRing == nil and 0 or predictionRing:count()
	local ownerReceived = self._ownerReceived
	local ownerApplied = self._ownerApplied
	local tailServerTick = data2.TailServerTick
	local tailServerTickDelta = metrics.TailServerTickDelta
	local mismatchLabel = State.mismatchLabel(metrics.CanonicalStateMismatchMask)
	local canonicalStateMismatchMask = metrics.CanonicalStateMismatchMask
	local canonicalStateMismatchCount = metrics.CanonicalStateMismatchCount
	local position = metrics.Position
	local velocity = metrics.Velocity
	local tailPosition = metrics.TailPosition
	local tailVerticalPosition = metrics.TailVerticalPosition
	local tailVelocity = metrics.TailVelocity
	local tailVerticalVelocity = metrics.TailVerticalVelocity
	local v10 = data3 == nil and "nil" or tostring(data3.PostState.OnGround)
	local onGround = tostring(data.State.OnGround)
	local v11

	if data3 ~= nil then
		v11 = data3.PostSupport
	end

	output(string.format(
		"[MovementV2.Client] owner mode=%s barrier=%s seq=%u ack=%u ackTick=%s/%u ackAdvance=%d tickAdvance=%d held=%d synth=%s newest=%s lead=%d reconcileCount=%d replay=%d workMs=%.3f elapsedMs=%.3f slices=%d maxSliceMs=%.3f avgReplay=%.1f maxReplay=%d ring=%d recv/applied=%d/%d tailTick=%u tailTickDelta=%d fields=%s mismatch=0x%X/%d posErr=%.8f yErr=%+.8f velErr=%.8f vyErr=%+.8f tailPos=%.8f tailY=%+.8f tailVel=%.8f tailVy=%+.8f ground=%s/%s support=%s/%s stance=%s/%s jumpHull=%s/%s",
		reconciliationMode,
		replayBarrier,
		sequence,
		lastProcessedCommand,
		v4,
		serverTick,
		acknowledgedCommandDelta,
		serverTickDelta,
		serverHeldTickCount,
		synthesizedInput,
		v5,
		p5,
		reconciliationCount,
		replayCount,
		v6,
		v7,
		reconciliationSliceCount,
		v8,
		v3,
		replayMax,
		v9,
		ownerReceived,
		ownerApplied,
		tailServerTick,
		tailServerTickDelta,
		mismatchLabel,
		canonicalStateMismatchMask,
		canonicalStateMismatchCount,
		position,
		p2,
		velocity,
		p3,
		tailPosition,
		tailVerticalPosition,
		tailVelocity,
		tailVerticalVelocity,
		v10,
		onGround,
		supportIdentityLabel(v11), -- inferred equivalent call
		supportIdentityLabel(data.Support), -- inferred equivalent call
		data3 == nil and "nil" or data3.PostState.Stance,
		data.State.Stance,
		data3 == nil and "nil" or tostring(data3.PostState.JumpHullActive),
		(tostring(data.State.JumpHullActive))
	))
end

function class:recordOwnerApplied(data, data2, p)
	local runtime = self._runtime
	local metrics = data2.Metrics
	self:_recordReplayWindow(data2)
	self._ownerApplied += 1
	self._replayTotal += data2.ReplayCount
	self._replayMax = math.max(self._replayMax, data2.ReplayCount)
	local v = metrics.ReconciliationMode == "Replay" or metrics.ReconciliationMode == "Reanchor"

	if v then
		self._reconciliationCount += 1
	end

	local reportingEnabled = self:reportingEnabled()
	local v2 = DiagnosticProtocol.OwnerTraceEnabled and DiagnosticProtocol.shouldOutputForPlayer(Players.LocalPlayer)

	if not (reportingEnabled or v2) then
		return
	end

	local now = os.clock()
	local v3 = p == nil and 0 or p.PostState.Position.Y - data.State.Position.Y
	local v4 = p == nil and 0 or p.PostState.Velocity.Y - data.State.Velocity.Y
	local predictionRing = runtime._predictionRing
	local v5

	if predictionRing ~= nil then
		v5 = predictionRing:newestCommandNumber()
	end

	local v6 = v5 == nil and 0 or math.max(Serial.deltaUInt32(v5, data.LastProcessedCommand), 0)
	local v7 = metrics.ComparedAtAck and (metrics.CanonicalStateMismatchCount > 0 or metrics.CanonicalSupportMismatch)
	local synthesizedInput

	if metrics.ReconciliationMode == "Initial" then
		synthesizedInput = false
	elseif metrics.ReconciliationMode == "Reanchor" then
		synthesizedInput = true
	else
		synthesizedInput = metrics.SynthesizedInput or v7 or presentationSnapCorrection(metrics) -- inferred equivalent call

		if not synthesizedInput then
			if metrics.ReconciliationMode == "Reuse" then
				synthesizedInput = false
			else
				synthesizedInput = materialAckCorrection(metrics) or materialTailCorrection(metrics) -- inferred equivalent call
			end
		end
	end

	if reportingEnabled and v and not synthesizedInput then
		self:reportIssue(
			"Reconciliation",
			string.format(
				"issue=Reconciliation count=%d mode=%s barrier=%s generation=%u sequence=%u ackCommand=%u authorityTick=%u tailTick=%u replay=%d retiredAckedPredictions=%d heldTicks=%d workMs=%.3f elapsedMs=%.3f slices=%d maxSliceMs=%.3f ackPos=%.8f ackVel=%.8f tailPos=%.8f tailVel=%.8f",
				self._reconciliationCount,
				metrics.ReconciliationMode,
				metrics.ReplayBarrier,
				data.Generation,
				data.Sequence,
				data.LastProcessedCommand,
				data.ServerTick,
				data2.TailServerTick,
				metrics.ReplayCount,
				metrics.DroppedCommandCount,
				metrics.ServerHeldTickCount,
				metrics.ReconciliationWorkSeconds * 1000,
				metrics.ReconciliationElapsedSeconds * 1000,
				metrics.ReconciliationSliceCount,
				metrics.ReconciliationMaximumSliceSeconds * 1000,
				metrics.Position,
				metrics.Velocity,
				metrics.TailPosition,
				metrics.TailVelocity
			),
			snapshotIdentity(data) -- inferred equivalent call
		)
	end

	if reportingEnabled and synthesizedInput then
		self:_reportOwnerCorrection(data, data2, p, now, v3, v4, v5, v6)
	end

	if not v2 then
		return
	end

	local v8 = math.max(1, (math.ceil(0.0625 * (runtime._config or Config.Default).SimulationHz)))
	local v9

	if p == nil then
		v9 = false
	else
		v9 = p.PostState.OnGround ~= data.State.OnGround
	end

	local v10 = p ~= nil
		and (p.PostSupport.Kind ~= data.Support.Kind or p.PostSupport.SourceId ~= data.Support.SourceId)
	self:_printOwnerTrace(
		data,
		data2,
		p,
		now,
		v8 <= data2.ReplayCount or metrics.ReconciliationMode == "Reanchor" or metrics.ServerHeldTickCount > 0 or math.abs(v3) >= 0.01 or math.abs(v4) >= 0.1 or (v9 or v10),
		v3,
		v4,
		v5,
		v6
	)
end

function class:_traceAirStrafe(data, p: number, p2: number, data2, data3)
	local airStrafePreviousYaw = self._airStrafePreviousYaw
	self._airStrafePreviousYaw = data.LookYaw

	if self._airStrafeLineCount >= 320 or data2.OnGround and data3.OnGround then
		return
	end

	local runtime = self._runtime
	local v = assert(runtime._config)
	local movementConfig = RuntimeSettings.getMovementConfig(v.SimulationHz)
	local v2

	if movementConfig.BunnyHopAirAccelerate > 0 then
		v2 = movementConfig.BunnyHopAirSpeedCap > movementConfig.PositionSnapEpsilon
	else
		v2 = false
	end

	if not self._airStrafeHeaderPrinted then
		self._airStrafeHeaderPrinted = true
		output(string.format(
			"[MovementV2.AirStrafe] BEGIN version=1 generation=%u gamemode=%s profile=%s simulationHz=%u airAccelerate=%.6f airSpeedCap=%.6f bunnyHopAirAccelerate=%.6f bunnyHopAirSpeedCap=%.6f",
			assert(runtime._mapping).Generation,
			tostring(Workspace:GetAttribute("ServerGamemode")),
			v2 and "relaxed" or "source",
			v.SimulationHz,
			movementConfig.AirAccelerate,
			movementConfig.AirSpeedCap,
			movementConfig.BunnyHopAirAccelerate,
			movementConfig.BunnyHopAirSpeedCap
		))
	end

	local v3 = ProvenMath.moveVectorToWorld(data.Move, data.LookYaw)
	local v4 = not (v3.Magnitude > 1e-6) and createVector(0, 0, 0) or v3.Unit
	local vector = Vector3.new(data2.Velocity.X, 0, data2.Velocity.Z)
	local vector2 = Vector3.new(data3.Velocity.X, 0, data3.Velocity.Z)
	local vector3 = vector2 - vector
	local dot = vector:Dot(v4)
	local bunnyHopAirSpeedCap

	if v2 then
		bunnyHopAirSpeedCap = movementConfig.BunnyHopAirSpeedCap
	else
		bunnyHopAirSpeedCap = movementConfig.AirSpeedCap
	end

	local v5 = bunnyHopAirSpeedCap - dot
	local v6

	if v2 then
		v6 = movementConfig.BunnyHopAirAccelerate * bunnyHopAirSpeedCap * v.StepSeconds
	else
		v6 = movementConfig.AirAccelerate * data2.BaseMoveSpeed * data2.VelocityModifier * v.StepSeconds * data2.GroundSurfaceFriction
	end

	local v7 = math.min(v6, (math.max(v5, 0)))
	local v8 = airStrafePreviousYaw == nil and 0
		or math.atan2(math.sin(data.LookYaw - airStrafePreviousYaw), (math.cos(data.LookYaw - airStrafePreviousYaw)))
	local v9 = data2.OnGround and not data3.OnGround and "takeoff"
		or (data2.OnGround or not data3.OnGround) and "air"
		or "landing"
	self._airStrafeLineCount += 1
	output(string.format(
		"[MovementV2.AirStrafe] cmd=%u tick=%u phase=%s alpha=%.4f buttons=%u move=(%+.4f,%+.4f) yawDeg=%+.3f yawDeltaDeg=%+.3f wish=(%+.5f,%+.5f) wishVsVelocityDeg=%+.3f velocityTurnDeg=%+.3f speed=%.6f->%.6f speedDelta=%+.6f directionalSpeed=%+.6f room=%+.6f fullWishImpulse=%.6f expectedImpulse=%.6f appliedAlongWish=%+.6f baseSpeed=%.6f velocityModifier=%.6f stamina=%.6f surfaceFriction=%.6f wallNormal=%.6f",
		data.CommandNumber,
		p,
		v9,
		p2,
		data.Buttons,
		data.Move.X,
		data.Move.Y,
		math.deg(data.LookYaw),
		math.deg(v8),
		v4.X,
		v4.Z,
		math.deg(signedHorizontalAngle(vector, v4)), -- inferred equivalent call
		math.deg(signedHorizontalAngle(vector, vector2)), -- inferred equivalent call
		vector.Magnitude,
		vector2.Magnitude,
		vector2.Magnitude - vector.Magnitude,
		dot,
		v5,
		v6,
		v7,
		vector3:Dot(v4),
		data2.BaseMoveSpeed,
		data2.VelocityModifier,
		data2.Stamina,
		data2.GroundSurfaceFriction,
		data3.WallNormal.Magnitude
	))

	if self._airStrafeLineCount == 320 then
		output(`[MovementV2.AirStrafe] COMPLETE reason=lineLimit lines={320}`)
	end
end

function class:recordPredictedStep(p, p2: number, p3: number, p4, data, p5, data2)
	if not DiagnosticProtocol.shouldOutputForPlayer(Players.LocalPlayer) then
		return
	end

	if DiagnosticProtocol.AirStrafeTraceEnabled then
		self:_traceAirStrafe(p, p2, p3, p4, data)
	end

	if DiagnosticProtocol.OwnerTraceEnabled and (data2.Jumped or data2.Landed or data2.LeftGround) then
		output(string.format(
			"[MovementV2.Client] transition cmd=%u tick=%u jumped=%s landed=%s leftGround=%s y=%.5f vy=%.5f onGround=%s stance=%s jumpHull=%s support=%s",
			p.CommandNumber,
			p2,
			tostring(data2.Jumped),
			tostring(data2.Landed),
			tostring(data2.LeftGround),
			data.Position.Y,
			data.Velocity.Y,
			tostring(data.OnGround),
			data.Stance,
			tostring(data.JumpHullActive),
			supportIdentityLabel(p5) -- inferred equivalent call
		))
	end
end

function class:emitNetcodeSummary()
	local now = os.clock()

	if now - self._summaryAt < frozen.NetcodeSummary then
		return
	end

	if self:reportingEnabled() then
		local runtime = self._runtime
		local window = self._window
		local v = math.max(now - self._summaryAt, 1e-6)
		self._summaryAt = now
		local v2 = {}

		for k, barrierCount in window.BarrierCounts do
			table.insert(v2, string.format("%s=%d", k, barrierCount))
		end

		table.sort(v2)
		self:recordStatusChange(runtime._status)
		local v3 = {}

		for k, statusDwellSecond in window.StatusDwellSeconds do
			if statusDwellSecond >= 0.001 then
				table.insert(v3, string.format("%s=%.0fms", k, statusDwellSecond * 1000))
			end
		end

		table.sort(v3)
		local commandClock = runtime._commandClock
		local v4

		if commandClock ~= nil then
			v4 = commandClock:diagnostics()
		end

		local remoteClock = runtime._remoteClock
		local v5

		if remoteClock ~= nil then
			v5 = remoteClock:diagnostics()
		end

		local config = runtime._config
		local predictionRing = runtime._predictionRing
		local commandStream = runtime._commandStream
		local lastAcceptedOwnerSnapshot = runtime._lastAcceptedOwnerSnapshot
		local v6

		if commandStream ~= nil then
			v6 = commandStream:lastSampledCommandNumber()
		end

		local counters = runtime._uplink:counters()
		local v7 = math.max(window.DepthSamples, 1)
		local v8 = math.max(window.Frames, 1)
		self:reportIssue("NetcodeSummary", table.concat({
			string.format(
				"issue=NetcodeSummary windowSeconds=%.2f status=%s statusReason=%s ping=%.0fms",
				v,
				runtime._status,
				tostring(runtime._reason),
				Players.LocalPlayer:GetNetworkPing() * 1000
			),
			string.format(
				"reservoir meanDepth=%.2f worstDepth=%s negativeSamples=%d/%d stalledFlag=%d longestStalledRun=%d clockRate=%.4f clockWorst=%s clockTarget=%s clockError=%s",
				window.DepthSum / v7,
				tostring(window.WorstDepth),
				window.StallSamples,
				window.DepthSamples,
				window.StalledFlagSamples,
				window.LongestStalledRun,
				v4 == nil and 1 or v4.Rate,
				v4 == nil and "nil" or tostring(v4.WorstDepth),
				v4 == nil and "nil" or tostring(v4.TargetDepth),
				v4 == nil and "nil" or tostring(v4.ErrorTicks)
			),
			string.format(
				"pacing frames=%d commandsPerSecond=%.1f stepsPerFrame=%.2f maxStepsInFrame=%d discardedMs=%.2f ceilingBreaks=%d accumulatorMs=%.2f",
				window.Frames,
				window.StepsDrained / v,
				window.StepsDrained / v8,
				window.MaxStepsInFrame,
				window.DiscardedSeconds * 1000,
				window.CeilingBreaks,
				runtime._accumulatorSeconds * 1000
			),
			string.format(
				"reconcile ownerRecv=%d ownerApplied=%d replayEvents=%.2f/s replayCommands=%.2f/s corrections=%.2f/s maxCorrection=%.5f ring=%d/%d lead=%s",
				self._ownerReceived,
				self._ownerApplied,
				window.ReplayEvents / v,
				window.ReplayCommands / v,
				window.CorrectionCount / v,
				window.MaxCorrection,
				predictionRing == nil and 0 or predictionRing:count(),
				predictionRing == nil and 0 or predictionRing:capacity(),
				(v6 == nil or lastAcceptedOwnerSnapshot == nil) and "nil" or tostring(Serial.deltaUInt32(
					v6,
					lastAcceptedOwnerSnapshot.LastProcessedCommand
				))
			),
			string.format(
				"remote framesSeen=%d seqGaps=%d rxLoss=%.2f%% baselineRejects=%d otherRejects=%d actorSamples=%d stale=%.2f%% missing=%.2f%% blindFrames=%d longestBlindMs=%.1f clock=%s drift=%.2f rebases=%d delayMs=%.1f minMarginMs=%.1f rate=%.3f extrapFrames=%d holdFrames=%d",
				window.RemoteFramesSeen,
				window.RemoteSequenceGaps,
				100 * (window.RemoteSequenceGaps / math.max(1, window.RemoteFramesSeen + window.RemoteSequenceGaps)),
				window.RemoteBaselineRejects,
				window.RemoteOtherRejects,
				window.RemoteActorSamples,
				100 * (window.RemoteStaleSamples / math.max(1, window.RemoteActorSamples)),
				100 * (window.RemoteMissingSamples / math.max(1, window.RemoteActorSamples)),
				window.RemoteBlindFrames,
				window.RemoteLongestBlindSeconds * 1000,
				v5 == nil and "nil" or v5.Mode,
				v5 == nil and 0 or v5.DriftTicks,
				v5 == nil and 0 or v5.HardRebases,
				v5 == nil and 0 or v5.DelayMs,
				v5 == nil and 0 or v5.WindowMinMarginMs or 0,
				v5 == nil and 1 or v5.Rate,
				v5 == nil and 0 or v5.ExtrapolatingFrames,
				v5 == nil and 0 or v5.HoldingFrames
			),
			string.format(
				"uplink commandPackets=%.1f/s recoveryPackets=%.1f/s budgetDeferrals=%d",
				(counters.PacketsSent - window.CommandPacketsBase) / v,
				(counters.RecoveryPacketsSent - window.RecoveryPacketsBase) / v,
				counters.BudgetDeferrals - window.SendDeferralsBase
			),
			string.format(
				"recovery resyncRequests=%d mappingRequests=%d dwell=%s",
				window.ResyncRequests,
				window.MappingRequests,
				#v3 == 0 and "none" or table.concat(v3, " ")
			),
			"barriers " .. (#v2 == 0 and "none" or table.concat(v2, " ")),
			string.format(
				"policy simulationHz=%s bufferTarget=%s catchUpBank=%s maxFrameTicks=%s accumulatorTicks=%s",
				config == nil and "nil" or tostring(config.SimulationHz),
				config == nil and "nil" or tostring(config.CommandBufferTargetTicks),
				config == nil and "nil" or tostring(config.CommandCatchUpBankTicks),
				config == nil and "nil" or tostring(config.MaxPredictionFrameTicks),
				config == nil and "nil" or tostring(config.PredictionAccumulatorTicks)
			)
		}, "\n"))
		self:_resetWindow()
	else
		self._summaryAt = now
		self:_resetWindow()
	end
end

function class:connectOutput(p)
	if not DiagnosticProtocol.shouldOutputForPlayer(Players.LocalPlayer) then
		return {}
	end

	local _output = self._output
	return {
		p.Diagnostics.OnClientEvent:Connect(function(p2)
			local decodeDelivery = DiagnosticProtocol.decodeDelivery(p2)

			if decodeDelivery ~= nil then
				_output:queue(decodeDelivery)
			end
		end),
		RunService.Heartbeat:Connect(function()
			_output:drain()
		end)
	}
end

function class:clearOutput()
	self._output:clear()
end

return table.freeze(class)