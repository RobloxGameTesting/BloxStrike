require(script.Parent.Types)
local v = {
	DefaultSimulationHz = 60,
	MinSimulationHz = 20,
	MaxSimulationHz = 240,
	CommandClockMaxSlewRatio = 0.1,
	MaxCommandsPerTick = 2,
	DoorCollisionDebugEnabled = false,
	PolicySeconds = table.freeze({
		CommandHistory = 2.5,
		MaxPendingCommandLead = 2.5,
		CommandLeadResync = 1,
		CommandBuffer = 0.05,
		SynthesizedInputHold = 0.05,
		SynthesizedInputDecay = 0.1,
		PredictionReplay = 2.5,
		OwnerSnapshotPeriod = 1 / 24,
		CommandPacketPeriod = 1 / 60,
		RemoteSnapshotPeriod = 1 / 60,
		RemoteBaselinePeriod = 0.125,
		RemoteHistory = 0.25,
		RenderInterpolation = 0.03125,
		MaxRemoteExtrapolation = 0.1,
		TargetRedundantHistory = 0.05,
		MaxNewCommandSpan = 0.1,
		MaxPredictionFrame = 0.1,
		CommandCatchUpBank = 0.25,
		CommandBufferTarget = 0.004,
		CommandClockWindow = 1
	})
}

local function isFinite(value)
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

local function horizonTicks(p: number, p2: number) -- 12 equivalent calls inferred from this helper
	return (math.max(1, (math.ceil(p * p2))))
end

local function targetTicks(commandBufferTarget: number, p: number) -- 1 equivalent call inferred from this helper
	return (math.max(0, commandBufferTarget * p))
end

local function cadenceTicks(p: number, p2: number)
	return (math.max(1, (math.floor(p * p2))))
end

function v.derive(p: number?)
	local simulationHz = p or v.DefaultSimulationHz
	local v2

	if typeof(simulationHz) == "number" and simulationHz == simulationHz and simulationHz > -1e999 then
		v2 = simulationHz < 1e999
	else
		v2 = false
	end

	if v2 then
		if simulationHz % 1 == 0 and v.MinSimulationHz <= simulationHz then
			v2 = simulationHz <= v.MaxSimulationHz
		else
			v2 = false
		end
	end

	assert(v2, "MovementV2 simulation Hz must be an integer from 20 through 240")
	local policySeconds = v.PolicySeconds
	local targetRedundantCommandCount = horizonTicks(policySeconds.TargetRedundantHistory, simulationHz) -- inferred equivalent call
	local maxNewCommandsPerPacket = horizonTicks(policySeconds.MaxNewCommandSpan, simulationHz) -- inferred equivalent call
	local commandHistoryTicks = horizonTicks(policySeconds.CommandHistory, simulationHz) -- inferred equivalent call
	local maxPendingCommandLeadTicks = horizonTicks(policySeconds.MaxPendingCommandLead, simulationHz) -- inferred equivalent call
	local commandLeadResyncTicks = horizonTicks(policySeconds.CommandLeadResync, simulationHz) -- inferred equivalent call
	local commandBufferTicks = horizonTicks(policySeconds.CommandBuffer, simulationHz) -- inferred equivalent call
	local synthesizedInputHoldTicks = horizonTicks(policySeconds.SynthesizedInputHold, simulationHz) -- inferred equivalent call
	local synthesizedInputDecayTicks = horizonTicks(policySeconds.SynthesizedInputDecay, simulationHz) -- inferred equivalent call
	local predictionReplayTicks = horizonTicks(policySeconds.PredictionReplay, simulationHz) -- inferred equivalent call
	local maxPredictionFrameTicks = horizonTicks(policySeconds.MaxPredictionFrame, simulationHz) -- inferred equivalent call
	local commandCatchUpBankTicks = horizonTicks(policySeconds.CommandCatchUpBank, simulationHz) -- inferred equivalent call
	local commandBufferTargetTicks = targetTicks(policySeconds.CommandBufferTarget, simulationHz) -- inferred equivalent call
	local commandClockWindowTicks = horizonTicks(policySeconds.CommandClockWindow, simulationHz) -- inferred equivalent call
	assert(maxPendingCommandLeadTicks <= commandHistoryTicks, "command history must cover the accepted serial lead")
	assert(maxPendingCommandLeadTicks <= predictionReplayTicks, "prediction replay must cover the accepted serial lead")
	assert(commandLeadResyncTicks <= maxPendingCommandLeadTicks, "accepted serial lead must cover command resync")
	assert(commandBufferTicks < commandLeadResyncTicks, "command resync must exceed the startup jitter buffer")
	assert(commandBufferTicks <= maxPendingCommandLeadTicks, "accepted serial lead must cover the command buffer")
	assert(
		synthesizedInputHoldTicks + synthesizedInputDecayTicks <= predictionReplayTicks,
		"input-loss recovery must fit inside prediction replay retention"
	)
	assert(v.MaxCommandsPerTick <= commandCatchUpBankTicks, "catch-up bank must cover at least one full catch-up tick")
	assert(
		commandCatchUpBankTicks <= maxPendingCommandLeadTicks,
		"catch-up bank must stay inside the accepted serial lead"
	)
	assert(
		commandBufferTargetTicks <= commandBufferTicks,
		"steady-state buffer target must not exceed the startup jitter reservoir"
	)
	local predictionAccumulatorTicks = maxPredictionFrameTicks + 1
	return (table.freeze({
		SimulationHz = simulationHz,
		StepSeconds = 1 / simulationHz,
		CommandHistoryTicks = commandHistoryTicks,
		MaxPendingCommandLeadTicks = maxPendingCommandLeadTicks,
		CommandLeadResyncTicks = commandLeadResyncTicks,
		CommandBufferTicks = commandBufferTicks,
		SynthesizedInputHoldTicks = synthesizedInputHoldTicks,
		SynthesizedInputDecayTicks = synthesizedInputDecayTicks,
		PredictionReplayTicks = predictionReplayTicks,
		OwnerSnapshotEveryTicks = math.max(1, (math.floor(policySeconds.OwnerSnapshotPeriod * simulationHz))),
		CommandPacketEveryTicks = math.max(1, (math.floor(policySeconds.CommandPacketPeriod * simulationHz))),
		RemoteSnapshotEveryTicks = math.max(1, (math.floor(policySeconds.RemoteSnapshotPeriod * simulationHz))),
		RemoteBaselineTicks = math.max(1, (math.ceil(policySeconds.RemoteBaselinePeriod * simulationHz))),
		RemoteHistoryTicks = math.max(1, (math.ceil(policySeconds.RemoteHistory * simulationHz))),
		RenderInterpolationTicks = math.max(1, (math.ceil(policySeconds.RenderInterpolation * simulationHz))),
		MaxRemoteExtrapolationTicks = math.max(1, (math.ceil(policySeconds.MaxRemoteExtrapolation * simulationHz))),
		TargetRedundantCommandCount = targetRedundantCommandCount,
		MaxNewCommandsPerPacket = maxNewCommandsPerPacket,
		MaxCommandsPerPacket = targetRedundantCommandCount + maxNewCommandsPerPacket,
		MaxPredictionFrameTicks = maxPredictionFrameTicks,
		PredictionAccumulatorTicks = predictionAccumulatorTicks,
		CommandCatchUpBankTicks = commandCatchUpBankTicks,
		CommandBufferTargetTicks = commandBufferTargetTicks,
		CommandClockWindowTicks = commandClockWindowTicks
	}))
end

v.Default = v.derive(v.DefaultSimulationHz)
assert(
	v.Default.RenderInterpolationTicks == 2,
	"default remote interpolation must remain at the authored wall-time delay"
)
assert(
	v.Default.TargetRedundantCommandCount / v.Default.SimulationHz >= v.PolicySeconds.TargetRedundantHistory,
	"default redundancy must cover the authored loss horizon"
)
assert(
	v.Default.PredictionAccumulatorTicks > v.Default.MaxPredictionFrameTicks,
	"prediction accumulator must carry a whole admitted frame plus its remainder"
)
return table.freeze(v)