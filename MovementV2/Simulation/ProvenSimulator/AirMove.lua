require(script.Parent.Parent.ProvenTypes)
local ProvenMath = require(script.Parent.Parent.ProvenMath)
local Trace = require(script.Parent.Trace)
local TraceRules = require(script.Parent.TraceRules)
local SlideMove = require(script.Parent.SlideMove)
local Duck = require(script.Parent.Duck)
local line = Trace.line
local vector = Trace.vector
local clampHorizontal = ProvenMath.clampHorizontal
local tryPlayerMove = SlideMove.tryPlayerMove
local getUncrouchClearance = Duck.getUncrouchClearance
local GROUND_PROBE_START_BUMP = TraceRules.GROUND_PROBE_START_BUMP
local isPointTestBlocked = TraceRules.isPointTestBlocked
local getTraceClipNormal = TraceRules.getTraceClipNormal
local isDynamicPlayerSupportTrace = TraceRules.isDynamicPlayerSupportTrace
local getResolvedSupportPosition = TraceRules.getResolvedSupportPosition
local isWalkableGround = TraceRules.isWalkableGround

local function tryAirLedgeAssist(vector2: Vector3, vector3: Vector3, p: number, object, data, p2: string, flag: boolean, vector4: Vector3, vector5: Vector3, flag2: boolean, p3, p4)
	local autoJumpLedgeAssistHeight = data.AutoJumpLedgeAssistHeight
	local autoJumpLedgeAssistLiftSpeed = data.AutoJumpLedgeAssistLiftSpeed

	if
		autoJumpLedgeAssistHeight <= data.PositionSnapEpsilon
		or autoJumpLedgeAssistLiftSpeed <= data.PositionSnapEpsilon
		or not flag2
		or p3 == nil
		or p3.normal.Y >= data.WalkableFloor
	then
		return vector4, vector5, false
	end

	if math.abs(vector3.Y) > data.GroundClearVelocity then
		return vector4, vector5, false
	end

	local vector6 = Vector3.new(vector3.X, 0, vector3.Z)

	if vector6.Magnitude <= data.VelocityEpsilon then
		return vector4, vector5, false
	end

	local traceClipNormal = getTraceClipNormal(p3, data)
	local vector7 = Vector3.new(traceClipNormal.X, 0, traceClipNormal.Z)

	if vector7.Magnitude <= data.PositionSnapEpsilon then
		return vector4, vector5, false
	end

	local unit = vector7.Unit

	if vector6:Dot(unit) >= -data.VelocityEpsilon then
		return vector4, vector5, false
	end

	local sweep = object:Sweep(vector2, vector2 + Vector3.new(0, autoJumpLedgeAssistHeight, 0), p2)

	if
		sweep.startSolid
		or sweep.allSolid
		or sweep.fraction < 1 - data.PositionSnapEpsilon
		or isPointTestBlocked(object:PointTest(sweep.endPos, p2))
	then
		return vector4, vector5, false
	end

	local v = tryPlayerMove(sweep.endPos, vector3, p, object, data, p2, false, p4, "risingAir")
	local v2 = -(vector4 - vector2):Dot(unit)

	if -(v - vector2):Dot(unit) <= v2 + data.PositionSnapEpsilon then
		return vector4, vector5, false
	end

	local v3 = vector2 + vector3 * p
	local v4 = v - Vector3.new(
		0,
		autoJumpLedgeAssistHeight + math.abs(vector3.Y * p) + data.GroundProbeDistance + GROUND_PROBE_START_BUMP,
		0
	)
	local supportSweep = object:SupportSweep(v, v4, p2, data.WalkableFloor)

	if not isWalkableGround(supportSweep, data) and supportSweep.normal.Y < data.WalkableFloor then
		supportSweep = object:WalkableSupportSweep(v, v4, p2, data.WalkableFloor)
	end

	if not isWalkableGround(supportSweep, data) or isDynamicPlayerSupportTrace(supportSweep) then
		return vector4, vector5, false
	end

	local resolvedSupportPosition = getResolvedSupportPosition(supportSweep, v)
	local v5 = resolvedSupportPosition.Y - v3.Y

	if
		v5 <= data.PositionSnapEpsilon
		or autoJumpLedgeAssistHeight + data.PositionSnapEpsilon < v5
		or isPointTestBlocked(object:PointTest(resolvedSupportPosition, p2))
	then
		return vector4, vector5, false
	end

	if flag and getUncrouchClearance(resolvedSupportPosition, object, data) then
		return vector4, vector5, false
	end

	local v6 = math.clamp(v5 / autoJumpLedgeAssistHeight, 0, 1) * 0.35 + 0.65
	local sweep2 = object:Sweep(
		vector4,
		vector4 + Vector3.new(0, math.min(v5 + data.PositionSnapEpsilon, autoJumpLedgeAssistLiftSpeed * v6 * p), 0),
		p2
	)

	if
		sweep2.startSolid
		or sweep2.allSolid
		or sweep2.fraction < 1 - data.PositionSnapEpsilon
		or isPointTestBlocked(object:PointTest(sweep2.endPos, p2))
	then
		return vector4, vector5, false
	end

	local vector8 = Vector3.new(vector3.X, 0, vector3.Z)
	return sweep2.endPos, vector8, true
end

return table.freeze({
	airMove = function(vector2: Vector3, vector3: Vector3, vector4: Vector3, p: number, p2: number, p3, data, p4: string, flag: boolean, flag2: boolean, p5: number, vector5: Vector3?, p6)
		if data.PositionSnapEpsilon < p then
			if data.BunnyHopAirAccelerate > 0 and data.BunnyHopAirSpeedCap > data.PositionSnapEpsilon then
				vector3 = ProvenMath.legacyBunnyHopAirAccelerate(
					vector3,
					vector4,
					p,
					data.BunnyHopAirAccelerate,
					data.BunnyHopAirSpeedCap,
					p2
				)
			else
				vector3 = ProvenMath.airAccelerate(vector3, vector4, p, data.AirAccelerate, data.AirSpeedCap, p2, p5)
			end

			vector("proven.airMove.accelerate", vector2, vector3, p, 0, line(1))
		end

		if data.BunnyHopSpeedCap > 0 then
			vector3 = clampHorizontal(vector3, data.BunnyHopSpeedCap)
		end

		local v, v2, v3, v4, v5, v6 = tryPlayerMove(vector2, vector3, p2, p3, data, p4, true, p6, "risingAir", vector5)

		if flag then
			v, v2 = tryAirLedgeAssist(vector2, vector3, p2, p3, data, p4, flag2, v, v2, v4, v6, p6)
		end

		vector("proven.airMove.final", v, v2, 0, v3 and 1 or 0, line(1))
		return v, v2, v3, v4, v5
	end
})