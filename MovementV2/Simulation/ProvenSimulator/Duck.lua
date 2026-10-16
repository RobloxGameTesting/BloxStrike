require(script.Parent.Parent.ProvenTypes)
local ProvenMath = require(script.Parent.Parent.ProvenMath)
local TraceRules = require(script.Parent.TraceRules)
local GROUND_PROBE_START_BUMP = TraceRules.GROUND_PROBE_START_BUMP
local getTraceNormalY = TraceRules.getTraceNormalY

local function getStandingFloorSupportTrace(vector: Vector3, object, p) -- 4 equivalent calls inferred from this helper
	return object:FloorSupportSweep(vector, vector, "standing", p.WalkableFloor)
end

local function isStandingFloorSupportBlocked(data, p) -- 4 equivalent calls inferred from this helper
	if not (data and (data.startSolid or data.allSolid)) then
		return false
	end

	local floorPenetrationDepth = data.floorPenetrationDepth

	if typeof(floorPenetrationDepth) == "number" then
		return GROUND_PROBE_START_BUMP + p.PositionSnapEpsilon < floorPenetrationDepth
	end

	return true
end

local function isUncrouchSweepHardBlocked(data, p)
	if not data then
		return false
	end

	if data.startSolid or data.allSolid or data.fraction < 1 then
		return getTraceNormalY(data, 1) < p.WalkableFloor
	end

	return false
end

local function isWalkablePointOverlap(pointTest, data) -- 1 equivalent call inferred from this helper
	if pointTest and (pointTest.startSolid or pointTest.allSolid) then
		return getTraceNormalY(pointTest, 0) >= data.WalkableFloor
	end

	return false
end

local function getUncrouchFloorRecoveryDistance(standingFloorSupportTrace, data) -- 1 equivalent call inferred from this helper
	local floorPenetrationDepth = standingFloorSupportTrace and standingFloorSupportTrace.floorPenetrationDepth

	if typeof(floorPenetrationDepth) == "number" and floorPenetrationDepth > 0 then
		return (math.clamp(floorPenetrationDepth + data.PositionSnapEpsilon, data.PositionSnapEpsilon, 0.08))
	end

	return (math.max(GROUND_PROBE_START_BUMP + data.PositionSnapEpsilon, data.PositionSnapEpsilon))
end

local function testUncrouchStandPosition(vector: Vector3, vector2: Vector3, object, data)
	local sweep = object:Sweep(vector, vector2, "crouching")
	local v

	if sweep and (sweep.startSolid or sweep.allSolid or sweep.fraction < 1) then
		v = getTraceNormalY(sweep, 1) < data.WalkableFloor
	else
		v = false
	end

	if v then
		return false, sweep, nil, nil
	end

	local pointTest = object:PointTest(vector2, "standing", true)
	local standingFloorSupportTrace = getStandingFloorSupportTrace(vector2, object, data) -- inferred equivalent call

	if pointTest.startSolid or pointTest.allSolid or isStandingFloorSupportBlocked(standingFloorSupportTrace, data) then -- inferred equivalent call
		return false, sweep, pointTest, standingFloorSupportTrace
	end

	return true, sweep, pointTest, standingFloorSupportTrace
end

local function getUncrouchClearance(position: Vector3, object, data)
	local v = position + Vector3.new(0, (data.PlayerSizeStanding.Y - data.PlayerSizeDucking.Y) * 0.5, 0)
	local sweep = object:Sweep(position, v, "crouching")
	local pointTest = object:PointTest(v, "standing", true)
	local standingFloorSupportTrace = getStandingFloorSupportTrace(v, object, data) -- inferred equivalent call
	local v2

	if sweep and (sweep.startSolid or sweep.allSolid or sweep.fraction < 1) then
		v2 = getTraceNormalY(sweep, 1) < data.WalkableFloor
	else
		v2 = false
	end

	local startSolid = pointTest.startSolid or pointTest.allSolid
	local standingFloorSupportBlocked = isStandingFloorSupportBlocked(standingFloorSupportTrace, data) -- inferred equivalent call

	if v2 or not standingFloorSupportBlocked and not isWalkablePointOverlap(pointTest, data) then -- inferred equivalent call
		return v2 or startSolid or standingFloorSupportBlocked, v, sweep, pointTest, standingFloorSupportTrace
	end

	local v3 = v + Vector3.new(0, getUncrouchFloorRecoveryDistance(standingFloorSupportTrace, data), 0) -- inferred equivalent call
	local v4, v5, v6, v7 = testUncrouchStandPosition(position, v3, object, data)

	if v4 then
		return false, v3, v5, v6, v7
	end

	return v2 or startSolid or standingFloorSupportBlocked, v, sweep, pointTest, standingFloorSupportTrace
end

local function getDuckSpeedFromState(data, data2) -- 1 equivalent call inferred from this helper
	return (math.clamp(data.DuckFatigueLevel / 10, 0, data2.DuckSpeedIdeal))
end

local function setDuckSpeedOnState(state, value: number, data) -- 1 equivalent call inferred from this helper
	state.DuckFatigueLevel = math.clamp(value, 0, data.DuckSpeedIdeal) * 10
end

local function getStance(p) -- 4 equivalent calls inferred from this helper
	if p.DuckAmount >= 0.999 then
		return "crouching"
	end

	return "standing"
end

local function getDuckJumpCenterShift(value: number, data) -- 3 equivalent calls inferred from this helper
	return (data.PlayerSizeStanding.Y - data.PlayerSizeDucking.Y) * data.DuckJumpOriginShiftFraction * math.clamp(value, 0, 1)
end

local function applyDuckJumpCenterShift(state, value: number, object, data)
	local duckJumpCenterShift = getDuckJumpCenterShift(value, data) -- inferred equivalent call
	local v = getDuckJumpCenterShift(state.DuckAmount, data) - duckJumpCenterShift -- inferred equivalent call

	if math.abs(v) <= data.PositionSnapEpsilon or v < 0 and state.Velocity.Y <= data.VelocityEpsilon then
		return
	end

	local position = state.Position
	local v2 = position + Vector3.new(0, v, 0)
	local v3

	if v < 0 then
		v3 = object:SweepWithFloorSupport(position, v2, getStance(state)) -- inferred equivalent call
	else
		v3 = object:Sweep(position, v2, getStance(state)) -- inferred equivalent call
	end

	if v3.startSolid or v3.allSolid then
		return
	end

	state.Position = v3.endPos
end

local function isAirUncrouchBlocked(position: Vector3, value: number, object, data)
	local pointTest = object:PointTest(position, "standing", true)

	if
		pointTest.startSolid
		or pointTest.allSolid
		or isStandingFloorSupportBlocked(getStandingFloorSupportTrace(position, object, data), data) -- inferred equivalent call
	then
		return true
	end

	local v = (data.PlayerSizeStanding.Y - data.PlayerSizeDucking.Y) * data.DuckJumpOriginShiftFraction * 0 - getDuckJumpCenterShift(value, data) -- inferred equivalent call

	if not (math.abs(v) > data.PositionSnapEpsilon) then
		return false
	end

	local v2 = position + Vector3.new(0, v, 0)
	local floorSupportSweep = object:FloorSupportSweep(position, v2, "standing", data.WalkableFloor)

	if floorSupportSweep.startSolid or floorSupportSweep.allSolid or floorSupportSweep.fraction < 1 then
		return true
	end

	local pointTest2 = object:PointTest(v2, "standing", true)

	if
		pointTest2.startSolid
		or pointTest2.allSolid
		or isStandingFloorSupportBlocked(getStandingFloorSupportTrace(v2, object, data), data) -- inferred equivalent call
	then
		return true
	end

	return false
end

return table.freeze({
	getStance = getStance,
	getUncrouchClearance = getUncrouchClearance,
	applyDuckStateForStep = function(self, data, p, p2: number, p3, data2)
		local duckAmount = math.clamp(data.DuckAmount, 0, 1)
		local duckHeld = data.DuckHeld == true
		local v = p.Duck and not duckHeld
		local v2 = not p.Duck and duckHeld
		local v3 = not data.OnGround and data.MovementType ~= "Ladder"
		local v4 = duckAmount >= 0.999
		local v5 = nil
		local v6 = math.max(data2.TimeToDuckMsecs, 1)
		local v7 = math.max(data2.TimeToUnDuckMsecs, 1)
		local duckSpeedFromState = getDuckSpeedFromState(data, data2) -- inferred equivalent call
		local duckFatigueTimerMsecs = math.max(0, data.DuckFatigueTimerMsecs - p2 * 1000)
		local v8

		if duckAmount <= 0 or duckAmount >= 1 then
			v8 = data2.DuckSpeedFastRecoveryRate
		else
			v8 = data2.DuckSpeedRecoveryRate
		end

		local approach = ProvenMath.approach(data2.DuckSpeedIdeal, duckSpeedFromState, p2 * v8)

		if v or v2 then
			approach = math.max(0, approach - data2.DuckSpamPenalty)
		end

		local duck = p.Duck == true

		if duck and approach < data2.DuckSpamMinSpeed then
			duck = false
		end

		if duck and duckAmount <= 0.75 and duckFatigueTimerMsecs > 0 then
			duck = false
		end

		self.DuckAmount = duckAmount
		self.IsDucking = false

		if duck then
			if v3 then
				self.DuckAmount = 1
			elseif duckAmount < 1 then
				self.DuckAmount = math.min(1, duckAmount + p2 * approach * data2.DuckSpeedDuckMultiplier)
			end

			if self.DuckAmount >= 0.999 then
				self.DuckAmount = 1
				self.IsDucking = false
			elseif duckAmount < self.DuckAmount then
				self.IsDucking = true
			end
		else
			local v9 = false

			if duckAmount > 0 then
				if v4 and v3 then
					if isAirUncrouchBlocked(self.Position, duckAmount, p3, data2) then
						self.DuckAmount = 1
						self.IsDucking = false
						v9 = true
					end
				elseif v4 then
					local uncrouchClearance, v10 = getUncrouchClearance(self.Position, p3, data2)

					if uncrouchClearance then
						self.DuckAmount = 1
						self.IsDucking = false
						v9 = true
					else
						v5 = v10
					end
				end

				if not v9 then
					if v3 then
						self.DuckAmount = 0
					else
						self.DuckAmount = math.max(
							0,
							duckAmount - p2 * math.max(data2.DuckSpeedUnduckMinimum, approach)
						)
					end

					self.IsDucking = self.DuckAmount > 0
				end
			end
		end

		if duckAmount < 1 and self.DuckAmount >= 1 then
			duckFatigueTimerMsecs = math.max(duckFatigueTimerMsecs, data2.TimeBetweenDucksMsecs)
		end

		self.DuckFatigueTimerMsecs = duckFatigueTimerMsecs
		setDuckSpeedOnState(self, approach, data2) -- inferred equivalent call
		local duckTimeMsecs

		if duck then
			duckTimeMsecs = (1 - self.DuckAmount) * v6
		else
			duckTimeMsecs = self.DuckAmount * v7
		end

		self.DuckTimeMsecs = duckTimeMsecs
		local stance = getStance(data) -- inferred equivalent call
		local stance2 = getStance(self) -- inferred equivalent call

		if v3 then
			applyDuckJumpCenterShift(self, duckAmount, p3, data2)
		end

		if data.OnGround and stance ~= stance2 then
			local v9 = (data2.PlayerSizeStanding.Y - data2.PlayerSizeDucking.Y) * 0.5

			if stance2 == "crouching" then
				self.Position -= Vector3.new(0, v9, 0)
			else
				self.Position = assert(v5, "grounded uncrouch requires clearance")
			end
		end
	end
})