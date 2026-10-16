local createVector = vector.create
require(script.Parent.Parent.ProvenTypes)
local ProvenMath = require(script.Parent.Parent.ProvenMath)
local Trace = require(script.Parent.Trace)
local TraceRules = require(script.Parent.TraceRules)
local SlideMove = require(script.Parent.SlideMove)
local line = Trace.line
local vector = Trace.vector
local clampHorizontal = ProvenMath.clampHorizontal
local horizontalMagnitudeSq = ProvenMath.horizontalMagnitudeSq
local tryPlayerMove = SlideMove.tryPlayerMove
local GROUND_PROBE_START_BUMP = TraceRules.GROUND_PROBE_START_BUMP
local isPointTestBlocked = TraceRules.isPointTestBlocked
local getTraceSurfaceVelocity = TraceRules.getTraceSurfaceVelocity
local getImpactWallConstraintNormal = TraceRules.getImpactWallConstraintNormal
local isDynamicWallContactRecord = TraceRules.isDynamicWallContactRecord
local isFloorSupportTrace = TraceRules.isFloorSupportTrace
local getResolvedSupportPosition = TraceRules.getResolvedSupportPosition
local isWalkableGround = TraceRules.isWalkableGround
local getTraceGroundNormal = TraceRules.getTraceGroundNormal
local getTraceMinkowskiPlaneKind = TraceRules.getTraceMinkowskiPlaneKind
local isRampPrimitiveHullRecord = TraceRules.isRampPrimitiveHullRecord
local supportTraceMatchesPosition = TraceRules.supportTraceMatchesPosition
local v = {}
local v2 = {}
local v3 = {}
local v4 = {}

local function getClearWalkableSupportFallback(vector2: Vector3, p: number, p2: string, object, p3, flag: boolean?)
	local walkableSupportSweep = object:WalkableSupportSweep(
		vector2 + Vector3.new(0, GROUND_PROBE_START_BUMP, 0),
		vector2 - Vector3.new(0, p, 0),
		p2,
		p3.WalkableFloor,
		flag
	)

	if
		not isWalkableGround(walkableSupportSweep, p3)
		or isPointTestBlocked(object:PointTest(getResolvedSupportPosition(walkableSupportSweep, vector2), p2))
	then
		return nil
	end

	return walkableSupportSweep
end

local function groundProbeWithRetry(vector2: Vector3, p: number, p2: string, object, p3, flag: boolean?, flag2: boolean?)
	local supportSweep = object:SupportSweep(
		vector2 + Vector3.new(0, GROUND_PROBE_START_BUMP, 0),
		vector2 - Vector3.new(0, p, 0),
		p2,
		p3.WalkableFloor,
		flag2
	)

	if supportSweep.startSolid and flag ~= false then
		local v5 = math.max(GROUND_PROBE_START_BUMP, p, p3.MaxStepHeight)
		local endPos = object:Sweep(vector2, vector2 + Vector3.new(0, v5, 0), p2).endPos
		local supportSweep2 = object:SupportSweep(
			endPos,
			endPos - Vector3.new(0, p + v5, 0),
			p2,
			p3.WalkableFloor,
			flag2
		)

		if not (supportSweep2.startSolid and supportSweep2.allSolid) then
			supportSweep = supportSweep2
		end
	end

	if not isWalkableGround(supportSweep, p3) and supportSweep.normal.Y < p3.WalkableFloor then
		local clearWalkableSupportFallback = getClearWalkableSupportFallback(vector2, p, p2, object, p3, flag2)

		if clearWalkableSupportFallback ~= nil then
			supportSweep = clearWalkableSupportFallback
		end
	end

	return supportSweep
end

local function getHorizontalDistanceSq(vector2: Vector3, position: Vector3) -- 1 equivalent call inferred from this helper
	local v5 = position.X - vector2.X
	local v6 = position.Z - vector2.Z
	return v5 * v5 + v6 * v6
end

local function getForwardMoveProgress(vector2: Vector3, position: Vector3, vector3: Vector3?) -- 1 equivalent call inferred from this helper
	if vector3 == nil then
		return 0
	end

	local v5 = position.X - vector2.X
	local v6 = position.Z - vector2.Z
	return v5 * vector3.X + v6 * vector3.Z
end

local function makeGroundMoveChoice(p, vector2: Vector3, position: Vector3, velocity: Vector3, collided: boolean, touchedWall: boolean, impactTrace, groundDriveDirection: Vector3?) -- 2 equivalent calls inferred from this helper
	p.position = position
	p.velocity = velocity
	p.collided = collided
	p.touchedWall = touchedWall
	p.impactTrace = impactTrace
	p.horizontalDistanceSq = getHorizontalDistanceSq(vector2, position) -- inferred equivalent call
	p.forwardProgress = getForwardMoveProgress(vector2, position, groundDriveDirection) -- inferred equivalent call
	return p
end

local function resolveGroundDriveDirection(vector2: Vector3?, vector3: Vector3, positionSnapEpsilon: number)
	local v5 = positionSnapEpsilon * positionSnapEpsilon

	if vector2 ~= nil then
		local x = vector2.X
		local z = vector2.Z
		local v6 = x * x + z * z

		if v5 < v6 then
			local v7 = 1 / math.sqrt(v6)
			return (Vector3.new(x * v7, 0, z * v7))
		end
	end

	local x = vector3.X
	local z = vector3.Z
	local v6 = x * x + z * z

	if v5 < v6 then
		local v7 = 1 / math.sqrt(v6)
		return (Vector3.new(x * v7, 0, z * v7))
	else
		return nil
	end
end

local function getStaticWallConstraintNormal(p, vector2: Vector3, data)
	if p == nil or (p.normal.Y >= data.WalkableFloor or isDynamicWallContactRecord(p.hullRecord)) then
		return nil
	end

	local surfaceVelocity = p.hullRecord.surfaceVelocity

	if surfaceVelocity ~= nil and surfaceVelocity.Magnitude > data.PositionSnapEpsilon then
		return nil
	end

	local impactWallConstraintNormal = getImpactWallConstraintNormal(p, data)

	if
		impactWallConstraintNormal.Magnitude <= data.PositionSnapEpsilon
		or math.abs(impactWallConstraintNormal.Y) > data.PositionSnapEpsilon
		or vector2:Dot(impactWallConstraintNormal) >= -data.VelocityEpsilon
	then
		return nil
	end

	return impactWallConstraintNormal.Unit
end

local function getRampAdjacentWallNormal(p, p2, vector2: Vector3, data) -- 3 equivalent calls inferred from this helper
	if p2 == nil or p == nil or p.hullRecord == p2.hullRecord then
		return nil
	end

	return (getStaticWallConstraintNormal(p, vector2, data))
end

local function tryWalkableRampSupportMove(p, vector2: Vector3, vector3: Vector3, p2: number, object, data, p3: string, p4, p5, groundDriveDirection: Vector3?)
	local traceGroundNormal = getTraceGroundNormal(p4)

	if traceGroundNormal == nil then
		return nil, nil, false
	end

	local walkableGround = isWalkableGround(p4, data)
	local flag = false
	local flag2 = false
	local unit = nil
	local hullRecord = p4.hullRecord

	if walkableGround then
		if traceGroundNormal.Y >= 1 - data.PositionSnapEpsilon then
			return nil, nil, false
		end
	elseif isRampPrimitiveHullRecord(hullRecord) and getTraceMinkowskiPlaneKind(p4) == "playerAxis" then
		local vector4 = Vector3.new(traceGroundNormal.X, 0, traceGroundNormal.Z)

		if vector4.Magnitude <= data.PositionSnapEpsilon then
			return nil, nil, false
		end

		unit = vector4.Unit

		if Vector3.new(vector3.X, 0, vector3.Z):Dot(unit) >= -data.PositionSnapEpsilon then
			return nil, nil, false
		else
			flag = true
		end
	elseif p4 == p5 and getStaticWallConstraintNormal(p5, vector3, data) ~= nil then
		flag2 = true
	else
		return nil, nil, false
	end

	local v5 = nil
	local v6

	if walkableGround then
		v6 = getRampAdjacentWallNormal(p5, p4, vector3, data) -- inferred equivalent call
	elseif flag2 then
		v6 = getStaticWallConstraintNormal(p5, vector3, data)
	end

	local velocity

	if v6 == nil then
		velocity = vector3
	else
		velocity = ProvenMath.clipVelocity(vector3, v6, data.Overbounce)
		v5 = p5
	end

	local v7 = Vector3.new(velocity.X, 0, velocity.Z) * p2

	if horizontalMagnitudeSq(v7) <= data.PositionSnapEpsilon * data.PositionSnapEpsilon then
		return nil, nil, false
	end

	local v8 = data.MaxStepHeight + data.PositionSnapEpsilon
	local v9 = vector2 + v7
	local v10 = v9 + Vector3.new(0, v8, 0)
	local supportSweep = object:SupportSweep(v10, v9, p3, data.WalkableFloor)

	if not isWalkableGround(supportSweep, data) and walkableGround and v6 == nil then
		local rampAdjacentWallNormal = getRampAdjacentWallNormal(supportSweep, p4, vector3, data) -- inferred equivalent call

		if rampAdjacentWallNormal ~= nil then
			velocity = ProvenMath.clipVelocity(vector3, rampAdjacentWallNormal, data.Overbounce)
			v9 = vector2 + Vector3.new(velocity.X, 0, velocity.Z) * p2
			v10 = v9 + Vector3.new(0, v8, 0)
			v5 = supportSweep
			v6 = rampAdjacentWallNormal
		end
	end

	if not isWalkableGround(supportSweep, data) and v6 ~= nil then
		supportSweep = object:WalkableSupportSweep(v10, v9, p3, data.WalkableFloor)
	end

	if not isWalkableGround(supportSweep, data) then
		return nil, supportSweep, false
	end

	local traceGroundNormal2 = getTraceGroundNormal(supportSweep)

	if traceGroundNormal2 == nil then
		return nil, supportSweep, false
	end

	local position, v11, v12, collided, touchedWall, v13, v14, _, _, _

	-- [DEDUP] synthesized from 2 duplicated terminal regions
	local function deduplicatedTail()
		local v15, v16, forwardProgress

		if groundDriveDirection == nil then
			forwardProgress = 0
		else
			v15 = position.X - vector2.X
			v16 = position.Z - vector2.Z
			forwardProgress = v15 * groundDriveDirection.X + v16 * groundDriveDirection.Z
		end

		p.forwardProgress = forwardProgress
		return p, supportSweep, flag
	end

	if flag2 then
		local hullRecord2 = supportSweep.hullRecord
		local surfaceVelocity

		if hullRecord2 ~= nil then
			surfaceVelocity = hullRecord2.surfaceVelocity
		end

		if
			traceGroundNormal2.Y >= 1 - data.PositionSnapEpsilon
			or hullRecord2 == nil
			or isDynamicWallContactRecord(hullRecord2)
			or surfaceVelocity ~= nil and surfaceVelocity.Magnitude > data.PositionSnapEpsilon
		then
			return nil, supportSweep, false
		end

		if getRampAdjacentWallNormal(v5, supportSweep, vector3, data) == nil then -- inferred equivalent call
			return nil, supportSweep, false
		end

		position = getResolvedSupportPosition(supportSweep, v10)
		v11 = position.Y - vector2.Y

		if v11 < -data.PositionSnapEpsilon or v8 < v11 then
			return nil, supportSweep, false
		end

		v12 = object:PointTest(position, p3)

		if isPointTestBlocked(v12) then
			return nil, supportSweep, false
		end

		collided = v5 ~= nil
		touchedWall = v5 ~= nil
		p.position = position
		p.velocity = velocity
		p.collided = collided
		p.touchedWall = touchedWall
		p.impactTrace = v5 or supportSweep
		v13 = position.X - vector2.X
		v14 = position.Z - vector2.Z
		p.horizontalDistanceSq = v13 * v13 + v14 * v14
		return deduplicatedTail()
	else
		if flag then
			local hullRecord2 = supportSweep.hullRecord
			local vector4 = Vector3.new(traceGroundNormal2.X, 0, traceGroundNormal2.Z)

			if
				hullRecord2 ~= hullRecord
				or getTraceMinkowskiPlaneKind(supportSweep) ~= "sourceFace"
				or vector4.Magnitude <= data.PositionSnapEpsilon
				or unit == nil
				or unit:Dot(vector4.Unit) < 0.5
			then
				return nil, supportSweep, false
			end
		elseif traceGroundNormal:Dot(traceGroundNormal2.Unit) < 0.98 then
			return nil, supportSweep, false
		end

		position = getResolvedSupportPosition(supportSweep, v10)
		v11 = position.Y - vector2.Y

		if v11 < -data.PositionSnapEpsilon or v8 < v11 then
			return nil, supportSweep, false
		end

		v12 = object:PointTest(position, p3)

		if isPointTestBlocked(v12) then
			return nil, supportSweep, false
		end

		collided = v5 ~= nil
		touchedWall = v5 ~= nil
		p.position = position
		p.velocity = velocity
		p.collided = collided
		p.touchedWall = touchedWall
		p.impactTrace = v5 or supportSweep
		v13 = position.X - vector2.X
		v14 = position.Z - vector2.Z
		p.horizontalDistanceSq = v13 * v13 + v14 * v14
		return deduplicatedTail()
	end
end

local function stayOnGround(position: Vector3, p: string, object, data)
	local v5 = groundProbeWithRetry(position, data.MaxStepHeight, p, object, data, true)

	if isWalkableGround(v5, data) then
		local resolvedSupportPosition = getResolvedSupportPosition(v5, position)

		if math.abs(position.Y - resolvedSupportPosition.Y) > data.PositionSnapEpsilon then
			return resolvedSupportPosition, v5
		end

		return position, v5
	else
		if not (v5 and v5.normal.Y < data.WalkableFloor) then
			return position, nil
		end

		local vector2 = Vector3.new(0, data.MaxStepHeight, 0)
		local floorSupportSweep = object:FloorSupportSweep(
			position + Vector3.new(0, GROUND_PROBE_START_BUMP, 0),
			position - vector2,
			p,
			data.WalkableFloor
		)

		if not isWalkableGround(floorSupportSweep, data) then
			return position, nil
		end

		local resolvedSupportPosition = getResolvedSupportPosition(floorSupportSweep, position)

		if not isPointTestBlocked(object:PointTest(resolvedSupportPosition, p)) then
			return resolvedSupportPosition, floorSupportSweep
		end

		if not isPointTestBlocked(object:PointTest(position, p)) then
			floorSupportSweep.endPos = position
			return position, floorSupportSweep
		end

		return position, nil
	end
end

local function stepMove(vector2: Vector3, vector3: Vector3, p: number, object, data, p2: string, vector4: Vector3?, p3)
	local vector5 = Vector3.new(vector3.X, 0, vector3.Z)
	local v5 = horizontalMagnitudeSq(vector5)
	local groundDriveDirection = resolveGroundDriveDirection(vector4, vector5, data.PositionSnapEpsilon)
	local position, velocity, collided, touchedWall, impactTrace, v6, v7 = tryPlayerMove(
		vector2,
		vector3,
		p,
		object,
		data,
		p2,
		false,
		p3,
		"ground"
	)
	local groundMoveChoice = makeGroundMoveChoice( -- inferred equivalent call
		v,
		vector2,
		position,
		velocity,
		collided,
		touchedWall,
		impactTrace,
		groundDriveDirection
	)
	local v8 = v4
	v8.choice = groundMoveChoice
	v8.direct = groundMoveChoice
	v8.step = nil
	v8.supportTrace = nil
	v8.stepVerticalDelta = 0
	v8.usedStep = false
	local choice = nil
	local supportTrace = nil

	if collided then
		local choice2, supportTrace2 = tryWalkableRampSupportMove(
			v2,
			vector2,
			vector3,
			p,
			object,
			data,
			p2,
			v7 or impactTrace,
			v6,
			groundDriveDirection
		)

		if choice2 ~= nil then
			v8.choice = choice2
			v8.supportTrace = supportTrace2

			if not choice2.touchedWall then
				return v8
			end

			supportTrace = supportTrace2
			choice = choice2
		end
	end

	if not collided or v5 <= data.PositionSnapEpsilon * data.PositionSnapEpsilon then
		return v8
	end

	local vector6 = Vector3.new(0, data.MaxStepHeight + data.PositionSnapEpsilon, 0)
	local v9 = true
	local sweep = object:Sweep(vector2, vector2 + vector6, p2)
	local endPos

	if sweep.startSolid or sweep.allSolid then
		endPos = vector2
	else
		endPos = sweep.endPos
	end

	local v10 = nil
	local stepVerticalDelta = 0
	local v11 = data.PositionSnapEpsilon * data.PositionSnapEpsilon
	local v12, v13, collided2, touchedWall2, impactTrace2 = tryPlayerMove(
		endPos,
		vector5,
		p,
		object,
		data,
		p2,
		false,
		p3
	)
	local supportSweep = object:SupportSweep(v12, v12 - vector6, p2, data.WalkableFloor)
	local supportTrace2

	if isWalkableGround(supportSweep, data) or not (supportSweep.normal.Y < data.WalkableFloor) then
		supportTrace2 = supportSweep
	else
		supportTrace2 = object:WalkableSupportSweep(v12, v12 - vector6, p2, data.WalkableFloor)

		if not isWalkableGround(supportTrace2, data) then
			supportTrace2 = supportSweep
		end
	end

	if isWalkableGround(supportTrace2, data) then
		local resolvedSupportPosition = getResolvedSupportPosition(supportTrace2, v12)
		stepVerticalDelta = resolvedSupportPosition.Y - vector2.Y

		if not (data.MaxStepHeight + data.PositionSnapEpsilon < stepVerticalDelta) then
			if not isFloorSupportTrace(supportTrace2) then
				local floorSupportSweep = object:FloorSupportSweep(v12, v12 - vector6, p2, data.WalkableFloor)

				if isWalkableGround(floorSupportSweep, data) then
					local resolvedSupportPosition2 = getResolvedSupportPosition(floorSupportSweep, v12)
					local v14 = resolvedSupportPosition2.Y - vector2.Y
					local v15 = resolvedSupportPosition2.Y - resolvedSupportPosition.Y

					if resolvedSupportPosition2.Y + data.PositionSnapEpsilon < resolvedSupportPosition.Y then
						v9 = not isPointTestBlocked(object:PointTest(resolvedSupportPosition2, p2))
					end

					if
						v9
						and v14 ~= nil
						and v15 ~= nil
						and v15 >= -0.02
						and v14 <= data.MaxStepHeight + data.PositionSnapEpsilon
					then
						supportTrace2 = floorSupportSweep
						stepVerticalDelta = v14
						resolvedSupportPosition = resolvedSupportPosition2
					end
				end
			end

			if not isPointTestBlocked(object:PointTest(resolvedSupportPosition, p2)) then
				v10 = v3
				makeGroundMoveChoice( -- inferred equivalent call
					v10,
					vector2,
					resolvedSupportPosition,
					Vector3.new(v13.X, vector3.Y, v13.Z),
					collided2,
					touchedWall2,
					impactTrace2,
					groundDriveDirection
				)
			end
		end
	end

	if v10 ~= nil then
		v8.step = v10
		v8.stepVerticalDelta = stepVerticalDelta
		local v14 = choice or groundMoveChoice
		local v15

		if choice == nil then
			v15 = v10.horizontalDistanceSq + v11 >= v14.horizontalDistanceSq
		else
			v15 = v10.forwardProgress > v14.forwardProgress + data.PositionSnapEpsilon
		end

		local v16 = choice ~= nil
			and math.abs(v10.forwardProgress - v14.forwardProgress) <= data.PositionSnapEpsilon
			and v10.horizontalDistanceSq + v11 >= v14.horizontalDistanceSq

		if v15 or v16 then
			v8.choice = v10
			v8.usedStep = true
			v8.supportTrace = supportTrace2
		end
	end

	if choice ~= nil and not v8.usedStep then
		v8.choice = choice
		v8.supportTrace = supportTrace
	end

	return v8
end

return table.freeze({
	groundProbeWithRetry = groundProbeWithRetry,
	walkMove = function(vector2: Vector3, vector3: Vector3, vector4: Vector3, p: number, p2: number, p3: number, p4, data, p5: string, vector5: Vector3, p6: number, p7: number, p8)
		local v5 = vector3 - vector5
		local v6 = ProvenMath.applyFriction(v5, p3, data.Friction, data.StopSpeed, p6)
		vector("proven.walkMove.friction", vector2, v6, p, 0, line(1))

		if data.PositionSnapEpsilon < p then
			v6 = ProvenMath.accelerate(v6, vector4, p, data.GroundAccelerate, p3, p6, p7)
			vector("proven.walkMove.accelerate", vector2, v6, p, 0, line(1))
		end

		local v7 = clampHorizontal(v6, p2)
		vector("proven.walkMove.speedClamp", vector2, v7, p2, 0, line(1))
		local v8 = v7 + vector5

		if not (data.PositionSnapEpsilon < p) then
			vector4 = nil
		end

		local v9 = stepMove(vector2, v8, p3, p4, data, p5, vector4, p8)
		local position = v9.choice.position
		vector(
			"proven.walkMove.stepChoice",
			v9.choice.position,
			v9.choice.velocity,
			v9.stepVerticalDelta,
			v9.usedStep and 1 or 0,
			line(1)
		)
		local supportTrace = v9.supportTrace

		if
			supportTrace == nil
			or supportTrace.startSolid
			or supportTrace.allSolid
			or not supportTraceMatchesPosition(supportTrace, position, data)
		then
			position, supportTrace = stayOnGround(position, p5, p4, data)
		end

		local velocity = v9.choice.velocity
		vector("proven.walkMove.stayOnGround", position, velocity, 0, 0, line(1))
		return
			position,
			velocity,
			velocity - vector5,
			v8,
			v9,
			supportTrace or v9.supportTrace,
			v9.choice.collided,
			v9.choice.touchedWall,
			v9.choice.impactTrace
	end,
	getGroundSupportVelocity = function(vector2: Vector3, p: string, object, p2)
		local getRetainedGroundSurfaceVelocity = object.GetRetainedGroundSurfaceVelocity

		if getRetainedGroundSurfaceVelocity ~= nil then
			local retainedGroundSurfaceVelocity = getRetainedGroundSurfaceVelocity(object)

			if typeof(retainedGroundSurfaceVelocity) == "Vector3" then
				return retainedGroundSurfaceVelocity, nil
			end
		end

		local v5 = math.max(p2.GroundProbeDistance, p2.MaxStepHeight)

		if object:HasUniformGroundSurfaces(vector2, p, v5) then
			return createVector(0, 0, 0), nil
		end

		local v6 = groundProbeWithRetry(vector2, v5, p, object, p2, true)

		if isWalkableGround(v6, p2) then
			return getTraceSurfaceVelocity(v6), v6
		end

		return createVector(0, 0, 0), nil
	end
})