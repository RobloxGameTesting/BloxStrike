local State = require(script.Parent.Parent.Simulation.State)
local fieldMask = State.fieldMask("BaseMoveSpeed")
local fieldMask2 = State.fieldMask("VelocityModifier")

local function stateMismatchMask(p) -- 2 equivalent calls inferred from this helper
	if typeof(p.CanonicalStateMismatchMask) == "number" then
		return p.CanonicalStateMismatchMask
	end

	return 0
end

local function hasBaseMoveSpeedMismatch(data) -- 1 equivalent call inferred from this helper
	return bit32.band(stateMismatchMask(data), fieldMask) ~= 0 -- inferred equivalent call
end

local function stateNumber(p, p2: string) -- 4 equivalent calls inferred from this helper
	if typeof(p) == "table" and typeof(p[p2]) == "number" then
		return p[p2]
	end

	return nil
end

local function stateFieldLabel(data) -- 1 equivalent call inferred from this helper
	return State.mismatchLabel(stateMismatchMask(data)) -- inferred equivalent call
end

local v = {
	classify = function(data, p, p2, data2)
		if data.SynthesizedInput == true then
			return "PacketLossOrCommandGap: authority synthesized missing input; client and server did not simulate identical commands"
		end

		if (data.ServerHeldTickCount or 0) > 0 then
			return "CommandStarvation: authority held movement while waiting for an unproven command frontier"
		end

		if data.PlayerContactCorrection == true then
			return "RemotePlayerContactPhase: another player's causally-late pose affected collision prediction"
		end

		if data.ReconciliationMode == "Reanchor" then
			return `PredictionHistoryUnavailable: acknowledged command was absent from the client ring (barrier={data.ReplayBarrier})`
		end

		if (data.TopologyRevisionDelta or 0) ~= 0 then
			return `TopologyTimelineMismatch: prediction and authority used destructible revisions {data.TopologyRevisionDelta} apart`
		end

		if hasBaseMoveSpeedMismatch(data) then -- inferred equivalent call
			local v = stateNumber(p, "BaseMoveSpeed") -- inferred equivalent call
			local v2 = stateNumber(p2, "BaseMoveSpeed") -- inferred equivalent call

			if v ~= nil and v2 ~= nil then
				local v3

				if v2 <= 0.00001 then
					v3 = v > 0.00001
				else
					v3 = false
				end

				local v4

				if v <= 0.00001 then
					v4 = v2 > 0.00001
				else
					v4 = false
				end

				if v3 then
					if data2 ~= nil and (data2.LocalPlanting == true or data2.ReplicatedPlanting == true) then
						return "BombPlantPredictionGap: planting lock was active but the acknowledged client prediction retained nonzero BaseMoveSpeed"
					end

					if data2 ~= nil and (data2.LocalDefusing == true or data2.ReplicatedDefusing == true) then
						return "DefusePredictionGap: defuse lock was active but the acknowledged client prediction retained nonzero BaseMoveSpeed"
					end

					if data2 ~= nil and data2.ReplicatedRescuing == true then
						return "HostageRescuePredictionGap: rescue lock was active but the acknowledged client prediction retained nonzero BaseMoveSpeed"
					end

					if
						data2 == nil
						or data2.GameStateAtSnapshot ~= "Buy Period" and data2.CurrentGameState ~= "Buy Period"
					then
						return string.format(
							"MovementLockDivergence: authority BaseMoveSpeed=%.5f while client predicted %.5f; inspect movementLockContext",
							v2,
							v
						)
					end

					return "BuyPeriodPredictionGap: freeze time was active but the acknowledged client prediction retained nonzero BaseMoveSpeed"
				elseif v4 then
					return string.format(
						"MovementUnlockDivergence: client BaseMoveSpeed=%.5f while authority had released to %.5f; inspect movementLockContext",
						v,
						v2
					)
				else
					return string.format(
						"BaseMoveSpeedDivergence: client %.5f authority %.5f; fields=%s",
						v,
						v2,
						stateFieldLabel(data)
					)
				end
			end
		end

		if bit32.band(data.CanonicalStateMismatchMask or 0, fieldMask2) ~= 0 then
			local v = stateNumber(p, "VelocityModifier") -- inferred equivalent call
			local v2 = stateNumber(p2, "VelocityModifier") -- inferred equivalent call

			if v ~= nil and v2 ~= nil then
				return string.format(
					"DamageTagTimelineDivergence: client velocity modifier %.6f authority %.6f; the predictable damage event was missing or late",
					v,
					v2
				)
			end
		end

		if (data.SupportKindMismatch or 0) > 0 or (data.SupportSourceMismatch or 0) > 0 then
			return "SupportDivergence: client and authority selected different ground/support identity"
		end

		if (data.CanonicalStateMismatchCount or 0) > 0 then
			return `DeterministicStateDivergence: identical command anchor differs in {stateFieldLabel(data)}` -- inferred equivalent call
		end

		if data.CanonicalSupportMismatch == true then
			return "SupportDivergence: support anchor or motion differs without an accompanying movement-state mismatch"
		end

		if data.TailCompared ~= true then
			return "UnclassifiedReconciliation: inspect paired state, support, timing, movement-lock context, and trace evidence"
		end

		local v = typeof(data.TailPosition) ~= "number" and 0 or data.TailPosition
		local v2 = typeof(data.TailVelocity) ~= "number" and 0 or data.TailVelocity

		if
			v > 0
			or v2 > 0
			or (data.TailSupportKindMismatch or 0) > 0
			or (data.TailSupportSourceMismatch or 0) > 0
			or data.TailGroundMismatch == true
			or data.TailStanceMismatch == true
		then
			return "ReplayTailDivergence: the authoritative replay changed the live predicted tail"
		end

		return "UnclassifiedReconciliation: inspect paired state, support, timing, movement-lock context, and trace evidence"
	end
}

local function scalarLabel(value)
	if value == nil then
		return "nil"
	end

	if typeof(value) == "number" then
		if value == value and math.abs(value) < 1e999 then
			return (string.format("%.6f", value))
		end

		return "invalid"
	elseif typeof(value) == "boolean" then
		return (tostring(value))
	else
		return string.gsub(tostring(value), "%s+", "_")
	end
end

function v.formatMovementLockContext(data, p: number)
	if data == nil then
		return string.format("movementLockContext snapshotServerTime=%.6f unavailable=true", p)
	end

	return string.format(
		"movementLockContext snapshotServerTime=%.6f gameStateAtSnapshot=%s gameStateNow=%s localPlantingNow=%s replicatedPlantingNow=%s plantLockAt=%s localDefusingNow=%s replicatedDefusingNow=%s replicatedRescuingNow=%s carryingHostageNow=%s",
		p,
		scalarLabel(data.GameStateAtSnapshot),
		scalarLabel(data.CurrentGameState),
		scalarLabel(data.LocalPlanting),
		scalarLabel(data.ReplicatedPlanting),
		scalarLabel(data.BombPlantMovementLockAt),
		scalarLabel(data.LocalDefusing),
		scalarLabel(data.ReplicatedDefusing),
		scalarLabel(data.ReplicatedRescuing),
		scalarLabel(data.CarryingHostage)
	)
end

return table.freeze(v)