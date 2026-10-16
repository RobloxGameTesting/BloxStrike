local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local DiagnosticProtocol = require(ReplicatedStorage.MovementV2.DiagnosticProtocol)
local PredictionErrorSmoother = require(ReplicatedStorage.MovementV2.Client.PredictionErrorSmoother)

local function emptyNetworkWindow() -- 5 equivalent calls inferred from this helper
	return {
		DurationSeconds = 0,
		RemoteRxBytes = 0,
		OwnerRxBytes = 0,
		CommandTxBytes = 0,
		RemotePackets = 0,
		OwnerPackets = 0,
		CommandPackets = 0,
		RecoveryPackets = 0,
		FullActorRecords = 0,
		DeltaActorRecords = 0,
		RemovedActorRecords = 0
	}
end

local flag = false
local v = nil
local v2 = emptyNetworkWindow() -- inferred equivalent call
local v3 = emptyNetworkWindow() -- inferred equivalent call
local now = os.clock()
local v4 = 0
local count = 0
local count2 = 0
local count3 = 0
local count4 = 0
local count5 = 0
local v5 = nil
local v6 = 0

local function resetMovementSession(p: number) -- 1 equivalent call inferred from this helper
	v = p
	v2 = emptyNetworkWindow() -- inferred equivalent call
	v3 = emptyNetworkWindow() -- inferred equivalent call
	now = os.clock()
	v4 = 0
	count = 0
	count2 = 0
	count3 = 0
	count4 = 0
	count5 = 0
	v5 = nil
	v6 = 0
end

local function networkWindow(p: number) -- 1 equivalent call inferred from this helper
	local durationSeconds = p - now

	if durationSeconds >= 1 then
		v2.DurationSeconds = durationSeconds
		v3 = v2
		v2 = emptyNetworkWindow() -- inferred equivalent call
		now = p
	end

	return v3
end

local function observeGeneration(p: number) -- 4 equivalent calls inferred from this helper
	if v ~= p then
		resetMovementSession(p) -- inferred equivalent call
	end
end

local function updateNetworkDiagnostics(now2: number)
	local v7 = networkWindow(now2) -- inferred equivalent call
	local v8 = math.max(v7.DurationSeconds, 1)
	local v9 = v7.FullActorRecords + v7.DeltaActorRecords + v7.RemovedActorRecords
	local v10 = not (v9 > 0) and 0 or v7.RemoteRxBytes / v9

	if
		DiagnosticProtocol.shouldOutputForPlayer(LocalPlayer)
		and now2 - v4 >= 5
		and v7.RemotePackets + v7.OwnerPackets + v7.CommandPackets > 0
	then
		v4 = now2
		print(string.format(
			"[MovementV2.Network] player=%s remoteRxKiBps=%.3f ownerRxKiBps=%.3f commandTxKiBps=%.3f packets=%d/%d/%d recovery=%d remoteRecords=%d/%d/%d wireBytesPerRecord=%.2f",
			LocalPlayer.Name,
			v7.RemoteRxBytes / v8 / 1024,
			v7.OwnerRxBytes / v8 / 1024,
			v7.CommandTxBytes / v8 / 1024,
			v7.RemotePackets,
			v7.OwnerPackets,
			v7.CommandPackets,
			v7.RecoveryPackets,
			v7.FullActorRecords,
			v7.DeltaActorRecords,
			v7.RemovedActorRecords,
			v10
		))
	end
end

local NetStatsController = {}

function NetStatsController.ObserveOwnerSnapshot(p: number, _: number, p2)
	observeGeneration(p) -- inferred equivalent call

	if p2 ~= nil and typeof(p2.Bytes) == "number" then
		v2.OwnerRxBytes += math.max(0, p2.Bytes)
		v2.OwnerPackets += 1
	end

	updateNetworkDiagnostics(os.clock())
end

function NetStatsController.ObserveRemoteSnapshot(p: number, _: number, data)
	observeGeneration(p) -- inferred equivalent call

	if data ~= nil and typeof(data.Bytes) == "number" then
		v2.RemoteRxBytes += math.max(0, data.Bytes)
		v2.RemotePackets += 1
		v2.FullActorRecords += data.FullActorCount or 0
		v2.DeltaActorRecords += data.DeltaActorCount or 0
		v2.RemovedActorRecords += data.RemovedActorCount or 0
	end

	updateNetworkDiagnostics(os.clock())
end

function NetStatsController.ObserveCommandPacket(p: number, p2: number, flag2: boolean)
	observeGeneration(p) -- inferred equivalent call
	v2.CommandTxBytes += math.max(0, p2)
	v2.CommandPackets += 1

	if flag2 then
		v2.RecoveryPackets += 1
	end

	updateNetworkDiagnostics(os.clock())
end

function NetStatsController.ObserveReconciliation(data, p)
	local mapping = p.Mapping

	if mapping ~= nil then
		observeGeneration(mapping.Generation) -- inferred equivalent call
	end

	local v7 = data.ReconciliationMode ~= "Reuse"
	local v8

	if v7 then
		if data.ComparedAtAck == true then
			v8 = data.Position >= 0.01
				or data.Velocity >= 0.1
				or data.SupportAnchor >= 0.01
				or data.SupportVelocity >= 0.1
				or data.SupportKindMismatch > 0
				or data.SupportSourceMismatch > 0
		else
			v8 = false
		end
	else
		v8 = v7
	end

	if v7 then
		if data.ComparedAtAck == true then
			v7 = v8
				or data.LookYaw >= 0.004363323129985824
				or data.VerticalLook >= 0.004363323129985824
				or data.DuckAmount >= 0.01
				or data.Stamina >= 0.01
		else
			v7 = false
		end
	end

	local v9

	if data.TailCompared == true then
		v9 = data.TailPosition >= 0.01
			or data.TailVelocity >= 0.1
			or data.TailSupportAnchor >= 0.01
			or data.TailSupportVelocity >= 0.1
			or data.TailSupportKindMismatch > 0
			or data.TailSupportSourceMismatch > 0
			or data.TailGroundMismatch == true
			or data.TailStanceMismatch == true
	else
		v9 = false
	end

	local v10 = v7 or v9

	if v10 then
		count += 1
	end

	local v11

	if data.TailCompared == true then
		v11 = PredictionErrorSmoother.isHardSnapCorrection(data)
	else
		v11 = false
	end

	if v11 then
		count3 += 1
	end

	local v12 = bit32.band(data.CanonicalStateMismatchMask or 0, 4071648) ~= 0
	local v13 = data.ReplayBarrier == "AcceptedWorldChange"
		or data.ReplayBarrier == "MoverRevision"
		or data.ReplayBarrier == "DestructibleRevision"
	local v14 = data.SynthesizedInput == true or (data.ServerHeldTickCount or 0) > 0
	local playerContactCorrection = data.PlayerContactCorrection == true
	local v15 = v7 and not v14 and not playerContactCorrection
		or v9 and not (v13 or v14) and not playerContactCorrection
		or v12
		or data.SupportKindMismatch > 0
		or data.SupportSourceMismatch > 0

	if v15 then
		count2 += 1
	end

	if DiagnosticProtocol.shouldOutputForPlayer(LocalPlayer) and (v10 or v15 or v11) then
		warn(string.format(
			"[MovementV2.LocalCounter] player=%s correction=%s desync=%s snap=%s totals=%d/%d/%d generation=%s tick=%s mode=%s barrier=%s replay=%d held=%d synth=%s contact=%s mismatch=0x%X ackPos=%.8f ackVel=%.8f tailPos=%.8f tailVel=%.8f tailTickDelta=%d tailGround=%s tailStance=%s supportMismatch=%d/%d tailSupportMismatch=%d/%d",
			LocalPlayer.Name,
			tostring(v10),
			tostring(v15),
			tostring(v11),
			count,
			count2,
			count3,
			mapping == nil and "nil" or tostring(mapping.Generation),
			tostring(p.ServerTick),
			tostring(data.ReconciliationMode),
			tostring(data.ReplayBarrier),
			data.ReplayCount or 0,
			data.ServerHeldTickCount or 0,
			tostring(data.SynthesizedInput == true),
			tostring(data.PlayerContactCorrection == true),
			data.CanonicalStateMismatchMask or 0,
			data.Position or 0,
			data.Velocity or 0,
			data.TailPosition or 0,
			data.TailVelocity or 0,
			data.TailServerTickDelta or 0,
			tostring(data.TailGroundMismatch == true),
			tostring(data.TailStanceMismatch == true),
			data.SupportKindMismatch or 0,
			data.SupportSourceMismatch or 0,
			data.TailSupportKindMismatch or 0,
			data.TailSupportSourceMismatch or 0
		))
	end
end

function NetStatsController.ObservePresentation(data)
	if not DiagnosticProtocol.shouldOutputForPlayer(LocalPlayer) then
		return
	end

	local localPlayerContactCritical = data.LocalPlayerContactCritical == true
	local v7 = v5
	v5 = localPlayerContactCritical

	if v7 == nil or v7 == localPlayerContactCritical then
		return
	end

	count5 += 1
	local now2 = os.clock()

	if now2 - v6 >= 0.25 then
		v6 = now2
		print(string.format(
			"[MovementV2.Client] PRESENTATION collisionRoot=%s tick=%s fraction=%.4f status=%s reason=%s modeSwitches=%d",
			localPlayerContactCritical and "exact" or "interpolated",
			data.ServerTick == nil and "nil" or tostring(data.ServerTick),
			data.TickFraction or 0,
			tostring(data.Status),
			tostring(data.Reason),
			count5
		))
	end
end

function NetStatsController.ObservePredictionHitch(data)
	count4 += 1

	if DiagnosticProtocol.shouldOutputForPlayer(LocalPlayer) then
		warn(string.format(
			"[MovementV2.LocalCounter] player=%s hitch=true total=%d tick=%s frameMs=%.3f discardedMs=%.3f backlogBeforeMs=%.3f backlogAfterMs=%.3f drained=%d guaranteed=%d hardCap=%d predictionWorkMs=%.3f ownerAgeMs=%.3f status=%s",
			LocalPlayer.Name,
			count4,
			tostring(data.ServerTick),
			(data.FrameSeconds or 0) * 1000,
			(data.DiscardedSeconds or 0) * 1000,
			(data.BacklogBeforeSeconds or 0) * 1000,
			(data.BacklogAfterSeconds or 0) * 1000,
			data.StepsDrained or 0,
			data.GuaranteedStepBudget or 0,
			data.StepBudget or 0,
			(data.PredictionWorkSeconds or 0) * 1000,
			(data.OwnerSnapshotAgeSeconds or 0) * 1000,
			(tostring(data.Status))
		))
	end
end

function NetStatsController.Initialize()
	if flag then
		return
	end

	flag = true
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local temporaryNetStats

	if playerGui ~= nil then
		temporaryNetStats = playerGui:FindFirstChild("TemporaryNetStats", true)
	end

	if temporaryNetStats ~= nil then
		temporaryNetStats:Destroy()
	end
end

return NetStatsController