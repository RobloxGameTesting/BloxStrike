local DiagnosticProtocol = require(script.Parent.Parent.DiagnosticProtocol)
local Enums = require(script.Parent.Parent.Enums)
local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
require(script.Parent.Parent.Transport)
local DeterminismTrace = require(script.Parent.Parent.Simulation.DeterminismTrace)
local State = require(script.Parent.Parent.Simulation.State)
require(script.Parent.Parent.Simulation.Types)
require(script.Parent.PredictionRing)
require(script.Parent.Reconciler)
local class = {}
class.__index = class
local output = DiagnosticProtocol.output

local function traceKey(p: number, p2: number, p3: number) -- 2 equivalent calls inferred from this helper
	return `{p}:{p2}:{p3}`
end

local function supportLabel(p) -- 2 equivalent calls inferred from this helper
	return `{p.Kind}:{p.SourceId}`
end

local function snapshotIdentity(data) -- 1 equivalent call inferred from this helper
	return {
		Generation = data.Generation,
		Sequence = data.Sequence,
		CommandNumber = data.LastProcessedCommand,
		ServerTick = data.ServerTick
	}
end

local function traceEventSummary(event)
	if event == nil then
		return "none"
	end

	return string.format(
		"line=%d pos=(%.8f,%.8f,%.8f) vel=(%.8f,%.8f,%.8f) flags=0x%02X scalar=%.8f object=%u state=0x%08X aux=0x%08X",
		event.Line,
		event.Position.X,
		event.Position.Y,
		event.Position.Z,
		event.Velocity.X,
		event.Velocity.Y,
		event.Velocity.Z,
		event.Flags,
		event.Scalar,
		event.ObjectId,
		event.StateHash,
		event.AuxHash
	)
end

local function isGroundTraceEvent(label: string)
	local v = string.lower(label)
	return string.find(v, "ground", 1, true) ~= nil
		or string.find(v, "duck", 1, true) ~= nil
		or string.find(v, "support", 1, true) ~= nil
		or label == "simulation.input"
		or label == "simulation.outputConversion"
		or label == "runtime.playerContacts.final"
end

local function printGroundTrace(p: string, buf: buffer)
	local describe = DeterminismTrace.describe(buf)

	if describe == nil then
		output(`[MovementV2.Trace] GROUND_TRACE_{p} malformed`)
		return
	end

	local count = 0

	for _, v in describe do
		if not isGroundTraceEvent(v.Label) then
			continue
		end

		count += 1
		output(string.format(
			"[MovementV2.Trace] GROUND_TRACE_%s event=%d stage=%s source=%s %s",
			p,
			v.Index,
			v.Label,
			v.Source,
			traceEventSummary(v.Event)
		))
	end

	if count == 0 then
		output(`[MovementV2.Trace] GROUND_TRACE_{p} no ground/duck/support events`)
	end
end

function class.new(host)
	return (setmetatable(
		{
			_host = host,
			_pendingComparisons = {},
			_lastRequestAt = -1e999,
			_lastSuspiciousGroundObservedAt = -1e999
		},
		class
	))
end

function class:bind(channels)
	self._channels = channels
end

function class:reset(p)
	local ring

	if DiagnosticProtocol.DeterminismTraceEnabled and p ~= nil then
		ring = DeterminismTrace.Ring.new(p.PredictionReplayTicks)
	end

	self._ring = ring
	table.clear(self._pendingComparisons)
	self._pendingSuspiciousGroundTrace = nil
	self._lastRequestAt = -1e999
	self._lastSuspiciousGroundObservedAt = -1e999
end

function class:begin(p: number, p2: number, p3: number)
	local ring = self._ring

	if ring == nil then
		return nil
	end

	return (ring:begin(p, p2, p3))
end

function class:finish(p)
	local ring = self._ring

	if p ~= nil and ring ~= nil then
		ring:finish(p)
	end
end

function class:_send(p: number, p2: number, p3: number, buf: buffer, reason: string)
	local channels = self._channels

	if channels == nil then
		return false
	end

	local v = traceKey(p, p2, p3) -- inferred equivalent call

	if self._pendingComparisons[v] ~= nil then
		return false
	end

	local now = os.clock()

	if now - self._lastRequestAt < 0.2 then
		return false
	end

	self._pendingComparisons[v] = { Payload = buf, Reason = reason }
	self._lastRequestAt = now
	channels.Trace:FireServer(DeterminismTrace.encodeRequest(p, p2, p3))
	output(string.format("[MovementV2.Trace] REQUEST generation=%u cmd=%u tick=%u reason=%s", p, p2, p3, reason))
	return true
end

function class:_requestMismatchTrace(data, p, data2)
	local ring = self._ring

	if
		ring == nil
		or p == nil
		or p.ServerTick ~= data.ServerTick
		or data.LastProcessedCommand == Serial.UInt32Max
		or data2.ReconciliationMode == "Reuse"
		or data2.PlayerContactCorrection
		or data2.CanonicalStateMismatchCount == 0 and not data2.CanonicalSupportMismatch
	then
		return
	end

	local v = ring:get(data.Generation, data.LastProcessedCommand, data.ServerTick)

	if v ~= nil then
		self:_send(
			data.Generation,
			data.LastProcessedCommand,
			data.ServerTick,
			v,
			`Mismatch:{State.mismatchLabel(data2.CanonicalStateMismatchMask)}`
		)
		return
	end

	local v2 = string.format(
		"[MovementV2.Trace] LOCAL_TRACE_UNAVAILABLE generation=%u cmd=%u tick=%u; prediction history was replaced before the mismatch could be paired",
		data.Generation,
		data.LastProcessedCommand,
		data.ServerTick
	)
	output(v2)
	self._host.Report("TraceComparison", v2, snapshotIdentity(data)) -- inferred equivalent call
end

function class:_requestPendingSuspiciousGroundTrace(p)
	local pendingSuspiciousGroundTrace = self._pendingSuspiciousGroundTrace

	if pendingSuspiciousGroundTrace == nil then
		return
	end

	if p.Generation ~= pendingSuspiciousGroundTrace.Generation then
		self._pendingSuspiciousGroundTrace = nil
		return
	end

	if
		p.LastProcessedCommand == Serial.UInt32Max
		or Serial.deltaUInt32(p.LastProcessedCommand, pendingSuspiciousGroundTrace.CommandNumber) < 0
	then
		return
	end

	if self:_send(
		pendingSuspiciousGroundTrace.Generation,
		pendingSuspiciousGroundTrace.CommandNumber,
		pendingSuspiciousGroundTrace.ServerTick,
		pendingSuspiciousGroundTrace.Payload,
		"SuspiciousCrouchGroundLoss"
	) then
		output(`[MovementV2.Trace] SUSPICIOUS_CONTEXT {pendingSuspiciousGroundTrace.Context}`)
		self._pendingSuspiciousGroundTrace = nil
	end
end

function class:onSnapshotCommitted(p, p2, p3, flag: boolean)
	if self._ring == nil then
		return
	end

	if p3.SynthesizedInput or p3.ServerHeldTickCount > 0 then
		local pendingSuspiciousGroundTrace = self._pendingSuspiciousGroundTrace

		if
			pendingSuspiciousGroundTrace ~= nil
			and pendingSuspiciousGroundTrace.Generation == p.Generation
			and p.LastProcessedCommand ~= Serial.UInt32Max
			and Serial.deltaUInt32(p.LastProcessedCommand, pendingSuspiciousGroundTrace.CommandNumber) >= 0
		then
			self._pendingSuspiciousGroundTrace = nil
		end
	else
		if flag then
			self:_requestMismatchTrace(p, p2, p3)
		end

		self:_requestPendingSuspiciousGroundTrace(p)
	end
end

function class:observePredictedStep(generation: number, data, serverTick: number, data2, p, data3, p2, p3)
	local ring = self._ring

	if ring == nil or not p3.LeftGround or p3.Jumped or not data2.OnGround then
		return
	end

	if
		not (Enums.Buttons.has(data.Buttons, Enums.Buttons.Duck) or Enums.Buttons.has(data2.PreviousButtons, Enums.Buttons.Duck))
		and data2.Stance ~= "Ducking"
		and data3.Stance ~= "Ducking"
		and not (data2.IsDucking or data3.IsDucking or data2.JumpHullActive or data3.JumpHullActive or math.abs(data3.DuckAmount - data2.DuckAmount) > 1e-6)
	then
		return
	end

	local now = os.clock()

	if self._pendingSuspiciousGroundTrace ~= nil or now - self._lastSuspiciousGroundObservedAt < 0.75 then
		return
	end

	local payload = ring:get(generation, data.CommandNumber, serverTick)

	if payload == nil then
		return
	end

	local context = string.format(
		"buttons=0x%02X move=(%.3f,%.3f) prevPos=(%.8f,%.8f,%.8f) nextPos=(%.8f,%.8f,%.8f) prevVel=(%.8f,%.8f,%.8f) nextVel=(%.8f,%.8f,%.8f) stance=%s/%s duck=%.6f/%.6f jumpHull=%s/%s support=%s/%s",
		data.Buttons,
		data.Move.X,
		data.Move.Y,
		data2.Position.X,
		data2.Position.Y,
		data2.Position.Z,
		data3.Position.X,
		data3.Position.Y,
		data3.Position.Z,
		data2.Velocity.X,
		data2.Velocity.Y,
		data2.Velocity.Z,
		data3.Velocity.X,
		data3.Velocity.Y,
		data3.Velocity.Z,
		data2.Stance,
		data3.Stance,
		data2.DuckAmount,
		data3.DuckAmount,
		tostring(data2.JumpHullActive),
		tostring(data3.JumpHullActive),
		supportLabel(p), -- inferred equivalent call
		supportLabel(p2) -- inferred equivalent call
	)
	self._pendingSuspiciousGroundTrace = {
		Generation = generation,
		CommandNumber = data.CommandNumber,
		ServerTick = serverTick,
		Payload = payload,
		Context = context
	}
	self._lastSuspiciousGroundObservedAt = now
	output(string.format(
		"[MovementV2.Trace] SUSPICIOUS_CROUCH_GROUND_LOSS generation=%u cmd=%u tick=%u %s",
		generation,
		data.CommandNumber,
		serverTick,
		context
	))
end

function class:handleServerTrace(p, sequence: number?)
	local identity, commandNumber, serverTick, v = DeterminismTrace.identity(p)

	if identity == nil or commandNumber == nil or serverTick == nil then
		self._host.Warn("rejected malformed authoritative simulation trace")
		return
	end

	local v2 = traceKey(identity, commandNumber, serverTick) -- inferred equivalent call
	local pendingComparison = self._pendingComparisons[v2]

	if pendingComparison == nil then
		return
	end

	self._pendingComparisons[v2] = nil
	local v3 = {
		Generation = identity,
		Sequence = sequence,
		CommandNumber = commandNumber,
		ServerTick = serverTick
	}

	if v then
		local v4 = string.format(
			"[MovementV2.Trace] SERVER_TRACE_UNAVAILABLE generation=%u cmd=%u tick=%u reason=%s; the authority trace aged out or the reported command/tick identity was not committed",
			identity,
			commandNumber,
			serverTick,
			pendingComparison.Reason
		)
		output(v4)
		self._host.Report("TraceComparison", v4, v3)
	else
		if
			pendingComparison.Reason == "SuspiciousCrouchGroundLoss"
			and DiagnosticProtocol.VerboseGroundTraceEnabled
		then
			printGroundTrace("CLIENT", pendingComparison.Payload)
			printGroundTrace("SERVER", p)
		end

		local compare = DeterminismTrace.compare(pendingComparison.Payload, p)

		if compare == nil then
			self._host.Warn("authoritative simulation trace identity changed during comparison")
		elseif compare.Matched then
			local v4 = string.format(
				"[MovementV2.Trace] NO_RECORDED_DIFFERENCE generation=%u cmd=%u tick=%u reason=%s clientEvents=%d serverEvents=%d overflow=%s/%s likelyCause=The fixed movement step matched; inspect command loss, timeline/replay barriers, player contacts, or presentation after this anchor",
				identity,
				commandNumber,
				serverTick,
				pendingComparison.Reason,
				compare.ClientCount,
				compare.ServerCount,
				tostring(compare.ClientOverflow),
				(tostring(compare.ServerOverflow))
			)
			output(v4)
			self._host.Report("TraceComparison", v4, v3)
		else
			local reason = pendingComparison.Reason
			local eventIndex = compare.EventIndex
			local clientCount = compare.ClientCount
			local serverCount = compare.ServerCount
			local classification = compare.Classification
			local label = compare.Label
			local clientSource = compare.ClientSource
			local client = compare.Client
			local v4 = client == nil and "none"
				or string.format(
					"line=%d pos=(%.8f,%.8f,%.8f) vel=(%.8f,%.8f,%.8f) flags=0x%02X scalar=%.8f object=%u state=0x%08X aux=0x%08X",
					client.Line,
					client.Position.X,
					client.Position.Y,
					client.Position.Z,
					client.Velocity.X,
					client.Velocity.Y,
					client.Velocity.Z,
					client.Flags,
					client.Scalar,
					client.ObjectId,
					client.StateHash,
					client.AuxHash
				)
			local serverSource = compare.ServerSource
			local server = compare.Server
			local v5 = string.format(
				"[MovementV2.Trace] FIRST_DIVERGENCE generation=%u cmd=%u tick=%u reason=%s event=%d/%d:%d class=%s stage=%s clientSource=%s client={%s} serverSource=%s server={%s} overflow=%s/%s",
				identity,
				commandNumber,
				serverTick,
				reason,
				eventIndex,
				clientCount,
				serverCount,
				classification,
				label,
				clientSource,
				v4,
				serverSource,
				server == nil and "none" or string.format(
					"line=%d pos=(%.8f,%.8f,%.8f) vel=(%.8f,%.8f,%.8f) flags=0x%02X scalar=%.8f object=%u state=0x%08X aux=0x%08X",
					server.Line,
					server.Position.X,
					server.Position.Y,
					server.Position.Z,
					server.Velocity.X,
					server.Velocity.Y,
					server.Velocity.Z,
					server.Flags,
					server.Scalar,
					server.ObjectId,
					server.StateHash,
					server.AuxHash
				),
				tostring(compare.ClientOverflow),
				(tostring(compare.ServerOverflow))
			)
			output(v5)
			self._host.Report("TraceComparison", v5, v3)
		end
	end
end

return table.freeze(class)