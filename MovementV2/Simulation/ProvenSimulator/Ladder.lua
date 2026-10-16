local createVector = vector.create
require(script.Parent.Parent.ProvenTypes)
local ProvenMath = require(script.Parent.Parent.ProvenMath)
local Trace = require(script.Parent.Trace)
local TraceRules = require(script.Parent.TraceRules)
local SlideMove = require(script.Parent.SlideMove)
local line = Trace.line
local vector = Trace.vector
local tryPlayerMove = SlideMove.tryPlayerMove
local getTraceSurfaceVelocity = TraceRules.getTraceSurfaceVelocity
local isWalkableGround = TraceRules.isWalkableGround
local WALL_CONTACT_SEPARATION = SlideMove.WALL_CONTACT_SEPARATION

local function getViewBasis(lookYaw: number, verticalLook: number?)
	local v = typeof(verticalLook) ~= "number" and 0 or math.clamp(verticalLook, -1, 1)
	local vector2 = Vector3.new(-math.sin(lookYaw), 0, -math.cos(lookYaw))
	local v2 = math.sqrt((math.max(0, 1 - v * v)))
	local vector3 = Vector3.new(vector2.X * v2, v, vector2.Z * v2)

	if vector3.Magnitude <= 1e-6 then
		vector3 = vector2
	end

	local vector4 = Vector3.new(math.cos(lookYaw), 0, -math.sin(lookYaw))
	local v3 = vector4.Magnitude <= 1e-6 and createVector(1, 0, 0) or vector4
	return vector3.Unit, v3.Unit
end

local function computeLadderVelocity(data, unit: Vector3, flag: boolean, data2)
	local ladderSpeed = data2.LadderSpeed

	if data.Duck or data.Walk then
		ladderSpeed *= data2.LadderClimbModifier
	end

	local v = math.clamp(-data.MoveVector.Y, -1, 1)
	local v2 = math.clamp(data.MoveVector.X, -1, 1)
	local v3 = v * ladderSpeed
	local v4 = v2 * ladderSpeed

	if math.abs(v3) <= 1e-6 and math.abs(v4) <= 1e-6 then
		return createVector(0, 0, 0)
	end

	local viewBasis, v5 = getViewBasis(data.LookYaw, data.VerticalLook)
	local vector2 = viewBasis * v3 + v5 * v4
	local cross = (createVector(0, 1, 0)):Cross(unit)
	local vector3 = cross.Magnitude <= 1e-6 and createVector(1, 0, 0) or cross.Unit
	local vector4 = unit:Cross(vector3)
	local dot = vector2:Dot(unit)
	local v6 = unit * dot
	local v7 = vector2 - v6
	local dot2 = vector4:Dot(v7)
	local dot3 = vector3:Dot(v7)
	local v8 = vector3 * dot3 + v6

	if v8.Magnitude > 1e-6 and v8.Unit:Dot(unit) < data2.LadderDampenAngle then
		v7 = vector4 * dot2 + vector3 * (data2.LadderDampen * dot3)
	end

	local v9 = (v7 - vector4 * dot) * data2.LadderLateralScale

	if flag and dot > 0 then
		v9 += unit * data2.LadderSpeed
	end

	vector("proven.ladderVelocity", createVector(0, 0, 0), v9, dot, 0, line(1))
	return v9
end

local function isClimbableTrace(p, p2) -- 1 equivalent call inferred from this helper
	local hullRecord = p and p.hullRecord
	return hullRecord ~= nil and hullRecord.climbable == true and p.normal.Y < p2.WalkableFloor
end

local function considerLadderTrace(p, vector2: Vector3, sweep, p2)
	if not isClimbableTrace(sweep, p2) then -- inferred equivalent call
		return p
	end

	if p == nil then
		return sweep
	end

	local magnitude = (p.endPos - vector2).Magnitude
	local magnitude2 = (sweep.endPos - vector2).Magnitude

	if magnitude2 + p2.PositionSnapEpsilon < magnitude then
		return sweep
	end

	if not (math.abs(magnitude2 - magnitude) <= p2.PositionSnapEpsilon) then
		return p
	end

	local v

	if p == nil then
		v = createVector(0, 0, 1)
	else
		local vector3 = Vector3.new(p.normal.X, 0, p.normal.Z)
		v = not (vector3.Magnitude > 1e-6) and createVector(0, 0, 1) or vector3.Unit
	end

	local v2

	if sweep == nil then
		v2 = createVector(0, 0, 1)
	else
		local vector3 = Vector3.new(sweep.normal.X, 0, sweep.normal.Z)
		v2 = not (vector3.Magnitude > 1e-6) and createVector(0, 0, 1) or vector3.Unit
	end

	if v2.Y < v.Y then
		return sweep
	end

	return p
end

local function findLadderTrace(vector2: Vector3, p: string, object, p2, flattened: Vector3?, unit: Vector3?, ladderDetachDistance: number, flag: boolean)
	if not object:HasClimbableNear(vector2, p, ladderDetachDistance + p2.PositionSnapEpsilon) then
		return nil
	end

	local v = nil

	local function traceDirection(unit2: Vector3) -- 5 equivalent calls inferred from this helper
		local sweep = object:Sweep(vector2, vector2 + unit2 * ladderDetachDistance, p)
		v = considerLadderTrace(v, vector2, sweep, p2)
	end

	if typeof(unit) == "Vector3" then
		local vector3 = Vector3.new(unit.X, 0, unit.Z)

		if vector3.Magnitude > 1e-6 then
			local sweep = object:Sweep(vector2, vector2 - vector3.Unit * ladderDetachDistance, p)
			v = considerLadderTrace(v, vector2, sweep, p2)

			if v ~= nil then
				return v
			end
		end
	end

	if typeof(flattened) == "Vector3" then
		local vector3 = Vector3.new(flattened.X, 0, flattened.Z)

		if vector3.Magnitude > 1e-6 then
			traceDirection(vector3.Unit) -- inferred equivalent call
			return v
		end
	end

	if flag then
		return nil
	end

	traceDirection(createVector(1, 0, 0)) -- inferred equivalent call
	traceDirection(createVector(-1, -0, -0)) -- inferred equivalent call
	traceDirection(createVector(0, 0, 1)) -- inferred equivalent call
	traceDirection(createVector(-0, -0, -1)) -- inferred equivalent call
	return v
end

return table.freeze({
	getLadderNormal = function(p, vector2: Vector3?)
		if p ~= nil then
			local vector3 = Vector3.new(p.normal.X, 0, p.normal.Z)

			if vector3.Magnitude > 1e-6 then
				return vector3.Unit
			end
		end

		if typeof(vector2) == "Vector3" then
			local vector3 = Vector3.new(vector2.X, 0, vector2.Z)

			if vector3.Magnitude > 1e-6 then
				return vector3.Unit
			end
		end

		return createVector(0, 0, 1)
	end,
	findLadderTrace = findLadderTrace,
	simulateLadderMove = function(vector2: Vector3, p, p2: number, p3, p4, p5: string, p6, vector3: Vector3?, flag: boolean, p7)
		local vector4, unit

		if p6 == nil then
			if typeof(vector3) == "Vector3" then
				vector4 = Vector3.new(vector3.X, 0, vector3.Z)
				unit = not (vector4.Magnitude > 1e-6) and createVector(0, 0, 1) or vector4.Unit
			else
				unit = createVector(0, 0, 1)
			end
		else
			local vector5 = Vector3.new(p6.normal.X, 0, p6.normal.Z)

			if vector5.Magnitude > 1e-6 then
				unit = vector5.Unit
			elseif typeof(vector3) == "Vector3" then
				vector4 = Vector3.new(vector3.X, 0, vector3.Z)
				unit = not (vector4.Magnitude > 1e-6) and createVector(0, 0, 1) or vector4.Unit
			else
				unit = createVector(0, 0, 1)
			end
		end

		local traceSurfaceVelocity = getTraceSurfaceVelocity(p6)
		local v = computeLadderVelocity(p, unit, flag, p4)
		local v2 = v + traceSurfaceVelocity
		local v3 = v.Y < -p4.PositionSnapEpsilon
		local position, velocity, _, touchedWall, impactTrace = tryPlayerMove(vector2, v2, p2, p3, p4, p5, v3, p7)

		if v3 and isWalkableGround(impactTrace, p4) then
			return {
				position = position,
				velocity = velocity,
				contactTrace = nil,
				impactTrace = impactTrace,
				touchedWall = touchedWall,
				detached = true
			}
		end

		local ladderTrace = findLadderTrace(
			position,
			p5,
			p3,
			p4,
			ProvenMath.flatten(velocity),
			unit,
			p4.LadderDetachDistance,
			false
		)

		if ladderTrace == nil then
			return {
				position = position,
				velocity = velocity,
				contactTrace = nil,
				impactTrace = impactTrace,
				touchedWall = touchedWall,
				detached = true
			}
		end

		local vector5, unit2

		if ladderTrace == nil then
			if typeof(unit) == "Vector3" then
				vector5 = Vector3.new(unit.X, 0, unit.Z)
				unit2 = not (vector5.Magnitude > 1e-6) and createVector(0, 0, 1) or vector5.Unit
			else
				unit2 = createVector(0, 0, 1)
			end
		else
			local vector6 = Vector3.new(ladderTrace.normal.X, 0, ladderTrace.normal.Z)

			if vector6.Magnitude > 1e-6 then
				unit2 = vector6.Unit
			elseif typeof(unit) == "Vector3" then
				vector5 = Vector3.new(unit.X, 0, unit.Z)
				unit2 = not (vector5.Magnitude > 1e-6) and createVector(0, 0, 1) or vector5.Unit
			else
				unit2 = createVector(0, 0, 1)
			end
		end

		local traceSurfaceVelocity2 = getTraceSurfaceVelocity(ladderTrace)
		local vector6 = velocity - traceSurfaceVelocity
		local dot = vector6:Dot(unit2)

		if dot ~= 0 then
			vector6 -= unit2 * dot
		end

		local velocity2 = vector6 + traceSurfaceVelocity2
		return {
			position = ladderTrace.endPos + unit2 * math.max(p4.PositionSnapEpsilon, WALL_CONTACT_SEPARATION),
			velocity = velocity2,
			contactTrace = ladderTrace,
			impactTrace = impactTrace or ladderTrace,
			touchedWall = touchedWall,
			detached = false
		}
	end
})