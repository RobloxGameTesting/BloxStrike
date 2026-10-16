local createVector = vector.create
require(script.Parent.Parent.ProvenTypes)
local ProvenMath = require(script.Parent.Parent.ProvenMath)
local Trace = require(script.Parent.Trace)
local TraceRules = require(script.Parent.TraceRules)
local line = Trace.line
local vector = Trace.vector
local magnitudeSq = ProvenMath.magnitudeSq
local isPointTestBlocked = TraceRules.isPointTestBlocked
local getTraceClipNormal = TraceRules.getTraceClipNormal
local getWallConstraintNormal = TraceRules.getWallConstraintNormal
local isDynamicWallContactRecord = TraceRules.isDynamicWallContactRecord
local isFloorSupportTrace = TraceRules.isFloorSupportTrace
local v = { ignoreDynamicPlayerAabbs = true }

local function warmStartStaticWallContact(endPos: Vector3, vector2: Vector3, vector3: Vector3?, object, data, p: string)
	if typeof(vector3) ~= "Vector3" or vector3.Magnitude <= 1e-6 then
		return vector2, nil, nil
	end

	local wallConstraintNormal = getWallConstraintNormal(vector3, data)

	if wallConstraintNormal.Magnitude <= 1e-6 or wallConstraintNormal.Y >= data.WalkableFloor then
		return vector2, nil, nil
	end

	local unit = wallConstraintNormal.Unit
	local sweep = object:Sweep(endPos, endPos - unit * 0.005, p)
	local v2 = nil
	local unit2 = nil

	if sweep.startSolid or sweep.allSolid then
		v2 = "probeEmbedded"
	elseif sweep.fraction >= 1 then
		v2 = "wallOutsideRetentionDistance"
	elseif sweep.normal.Y >= data.WalkableFloor then
		v2 = "walkableProbe"
	elseif isDynamicWallContactRecord(sweep.hullRecord) then
		v2 = "dynamicWall"
	elseif
		sweep.hullRecord.surfaceVelocity == nil
		or not (sweep.hullRecord.surfaceVelocity.Magnitude > data.PositionSnapEpsilon)
	then
		unit2 = getWallConstraintNormal(getTraceClipNormal(sweep, data), data)

		if unit2.Magnitude <= 1e-6 then
			v2 = "invalidProbeNormal"
		else
			unit2 = unit2.Unit

			if unit2:Dot(unit) < 0.995 then
				v2 = "wallNormalMismatch"
			end
		end
	else
		v2 = "movingWall"
	end

	local v3

	if unit2 ~= nil then
		v3 = vector2:Dot(unit2)
	end

	if
		(v2 == nil and v3 ~= nil and data.VelocityEpsilon < v3 and "clearlySeparating" or v2) == nil
		and unit2 ~= nil
		and v3 ~= nil
	then
		return ProvenMath.clipVelocity(vector2, unit2, data.Overbounce), unit2, sweep
	end

	return vector2, nil, nil
end

local function constrainVelocityAgainstClipPlanes(vector2: Vector3, traceClipNormals, count: number, data)
	for i = 1, count do
		local v2 = traceClipNormals[i]
		local vector3 = ProvenMath.clipVelocity(vector2, v2, data.Overbounce)
		local flag = true

		for j = 1, count do
			if not (j ~= i and vector3:Dot(traceClipNormals[j]) < 0) then
				continue
			end

			flag = false
			break
		end

		if flag then
			return vector3
		end
	end

	if count ~= 2 then
		return createVector(0, 0, 0)
	end

	local cross = traceClipNormals[1]:Cross(traceClipNormals[2])

	if cross.Magnitude > 0 then
		local unit = cross.Unit
		return unit * vector2:Dot(unit)
	end

	return createVector(0, 0, 0)
end

local function isPlayerEscapePathClear(vector2: Vector3, vector3: Vector3, p: string, object, config)
	if isPointTestBlocked((object:Sweep(vector2, vector3, p, v))) then
		return false
	end

	if
		vector3.Y < vector2.Y - config.PositionSnapEpsilon
		and isPointTestBlocked((object:FloorSupportSweep(vector2, vector3, p, config.WalkableFloor)))
	then
		return false
	end

	return true
end

local function escapeOverlappingBrushes(vector2: Vector3, sourceId: number, unit: Vector3, p: string, object)
	for _ = 1, 6 do
		if unit.Y < 0 then
			return nil
		end

		local v2 = nil

		for i = 1, 32 do
			local v3 = vector2 + unit * (i * 0.02)
			local pointTest = object:PointTest(v3, p)

			if not isPointTestBlocked(pointTest) then
				return v3
			end

			local hullRecord = pointTest.hullRecord

			if
				hullRecord == nil
				or hullRecord.buildMode == "dynamicPlayerAabb"
				or hullRecord.allowsPlayerDepenetration == false
			then
				return nil
			end

			if hullRecord.sourceId == sourceId then
				continue
			end

			sourceId = hullRecord.sourceId

			if pointTest.normal.Magnitude > 1e-6 then
				unit = pointTest.normal.Unit
				v2 = v3
			else
				v2 = v3
				unit = createVector(0, 1, 0)
			end

			break
		end

		if v2 == nil then
			return nil
		else
			vector2 = v2
		end
	end

	return nil
end

return table.freeze({
	WALL_CONTACT_SEPARATION = 0.001,
	WALL_RECOVERY_SEPARATION = 0.02,
	tryPlayerMove = function(endPos: Vector3, vector2: Vector3, p: number, object, data, p2: string, flag: boolean?, p3, p4: string?, vector3: Vector3?)
		local v2 = false
		local v3 = nil
		local traceClipNormals = p3 or table.create(data.MaxClipPlanes)
		table.clear(traceClipNormals)
		local count = 0
		local total = 0
		local v4 = data.PositionSnapEpsilon * data.PositionSnapEpsilon
		local vector4, v5, v6 = warmStartStaticWallContact(endPos, vector2, vector3, object, data, p2)
		vector("proven.tryPlayerMove.warmStart", endPos, vector4, 0, 0, line(1))
		local v7, v8, v9

		if v5 == nil then
			v7 = vector2
			v8 = false
			v6 = nil
		else
			v7 = vector4
			vector2 = v7
			v9 = v6
			v7 = vector2
			vector2 = v7
			v8 = true
		end

		local v10 = 0
		local count2 = 0
		local count3 = 0

		while v10 < 4 do
			v10 += 1

			if magnitudeSq(vector4) <= v4 or p <= 0 then
				break
			end

			local v11 = vector4 * p

			if magnitudeSq(v11) <= v4 then
				break
			end

			local result

			if flag == true then
				result = object:SweepWithFloorSupport(endPos, endPos + v11, p2)
			else
				result = object:Sweep(endPos, endPos + v11, p2)
			end

			if
				flag == true
				and isFloorSupportTrace(result)
				and (result.startSolid or result.allSolid)
				and vector4:Dot(result.normal) > data.PositionSnapEpsilon
			then
				result = object:Sweep(endPos, endPos + v11, p2)
			end

			if
				p4 ~= nil
				and (p4 == "ground" or vector4.Y > data.VelocityEpsilon)
				and result.fraction > 0.0001
				and object.CanonicalizeExpandedBlockCornerTrace ~= nil
			then
				object:CanonicalizeExpandedBlockCornerTrace(result, v11, p2, p4)
			end

			if result.fraction > 0 and result.fraction < 0.0001 then
				result.fraction = 0
			end

			total += result.fraction
			vector(
				"proven.tryPlayerMove.sweepResult",
				result.endPos,
				vector4,
				result.fraction,
				result.hullRecord == nil and 0 or result.hullRecord.sourceId or 0,
				line(1)
			)

			if result.allSolid then
				if not (result.normal.Y < data.WalkableFloor) then
					v3 = result
					return endPos, createVector(0, 0, 0), true, v8, result, v9, v3
				end

				v8 = true
				local traceClipNormal = getTraceClipNormal(result, data)
				local v12 = endPos + traceClipNormal * 0.02
				vector4 = ProvenMath.clipVelocity(vector4, traceClipNormal, data.Overbounce)

				if (count2 >= 1 and "recoveryBudgetExhausted" or magnitudeSq(traceClipNormal) <= v4 and "invalidNormal" or isPointTestBlocked(object:PointTest(v12, p2)) and "queryPositionBlocked" or magnitudeSq(vector4) <= v4 and "recoveredVelocityTooSmall" or vector4:Dot(vector2) <= 0 and "recoveredVelocityReversed" or nil) ~= nil then
					v9 = result
					return endPos, createVector(0, 0, 0), true, true, result, v9, v3
				end

				count2 += 1
				vector("proven.tryPlayerMove.allSolidRecovery", v12, vector4, result.fraction, 0, line(1))
				v7 = vector4
				v9 = result
				endPos = v12
				v2 = true
			else
				if result.fraction > 0 then
					endPos = result.endPos
					table.clear(traceClipNormals)
					v7 = vector4
					count = 0
				end

				vector("proven.tryPlayerMove.positionAdvance", endPos, vector4, result.fraction, 0, line(1))

				if result.fraction >= 1 then
					break
				end

				v2 = true
				p = math.max(0, p - p * result.fraction)

				if result.normal.Y < data.WalkableFloor then
					v9 = result
					v8 = true
				else
					v3 = result
				end

				local traceClipNormal = getTraceClipNormal(result, data)

				if magnitudeSq(traceClipNormal) <= v4 then
					v6 = result
					vector4 = createVector(0, 0, 0)
					break
				else
					if result.fraction == 0 and not result.startSolid and result.normal.Y < data.WalkableFloor then
						endPos += traceClipNormal * 0.001
					end

					if
						result.fraction == 0
						and not result.startSolid
						and vector4:Dot(traceClipNormal) >= -data.VelocityEpsilon
					then
						vector4 = ProvenMath.clipVelocity(vector4, traceClipNormal, data.Overbounce)
						vector("proven.tryPlayerMove.grazingClip", endPos, vector4, result.fraction, 0, line(1))

						if count3 < 2 then
							count3 += 1
							v10 -= 1
						end

						v7 = vector4
					elseif data.MaxClipPlanes <= count then
						v6 = result
						vector4 = createVector(0, 0, 0)
						break
					else
						count += 1
						traceClipNormals[count] = traceClipNormal
						vector4 = constrainVelocityAgainstClipPlanes(v7, traceClipNormals, count, data)
						vector("proven.tryPlayerMove.clipPlanes", endPos, vector4, result.fraction, count, line(1))

						if magnitudeSq(vector4) <= v4 or vector4:Dot(vector2) <= 0 then
							v6 = result
							vector4 = createVector(0, 0, 0)
							break
						end
					end
				end
			end

			v6 = result
		end

		local v11 = total == 0 and createVector(0, 0, 0) or vector4
		vector("proven.tryPlayerMove.final", endPos, v11, total, count, line(1))
		return endPos, v11, v2, v8, v6, v9, v3
	end,
	escapeStartSolid = function(vector2: Vector3, p: string, object)
		local pointTest = object:PointTest(vector2, p)

		if not (pointTest.startSolid or pointTest.allSolid) then
			return nil
		end

		local hullRecord = pointTest.hullRecord

		if hullRecord ~= nil and hullRecord.allowsPlayerDepenetration == false then
			return nil
		end

		local normal = pointTest.normal
		local v2 = not (normal.Magnitude > 1e-6) and createVector(0, 1, 0) or normal.Unit
		local config = object.Config
		local v3

		if hullRecord == nil then
			v3 = false
		else
			v3 = hullRecord.buildMode == "dynamicPlayerAabb"
		end

		local sourceId

		if hullRecord ~= nil then
			sourceId = hullRecord.sourceId
		end

		local v4 = v3 and math.abs(v2.Y) < config.WalkableFloor
		local v5 = 0

		for i = 1, 32 do
			local v6 = i * 0.02
			local v7 = vector2 + v2 * v6
			local pointTest2 = object:PointTest(v7, p)

			if
				not (pointTest2.startSolid or pointTest2.allSolid)
				and (not v3 or isPlayerEscapePathClear(vector2, v7, p, object, config))
			then
				if not v4 then
					return v7
				end

				while v6 - v5 > config.PositionSnapEpsilon do
					local v8 = (v5 + v6) * 0.5
					local v9 = vector2 + v2 * v8
					local pointTest3 = object:PointTest(v9, p)

					if
						not (pointTest3.startSolid or pointTest3.allSolid)
						and isPlayerEscapePathClear(vector2, v9, p, object, config)
					then
						v7 = v9
						v6 = v8
					else
						v5 = v8
					end
				end

				return v7
			else
				v5 = v6
			end
		end

		if v2.Y < 0.9 then
			for i = 1, 32 do
				local v6 = vector2 + Vector3.new(0, i * 0.02, 0)
				local pointTest2 = object:PointTest(v6, p)

				if
					not (pointTest2.startSolid or pointTest2.allSolid)
					and (not v3 or isPlayerEscapePathClear(vector2, v6, p, object, config))
				then
					return v6
				end
			end
		end

		if v3 or sourceId == nil then
			return nil
		end

		return (escapeOverlappingBrushes(vector2, sourceId, v2, p, object))
	end
})