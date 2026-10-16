local Config = require(script.Parent.Config)
local v = {}
local buf = buffer.create(4)
v.MinimumPredictableTicks = 2
v.NetworkSafetyTicks = 2
v.RecoverySeconds = 0.2
v.RecoveryPerSecond = 1 / v.RecoverySeconds

local function isFinite(value) -- 4 equivalent calls inferred from this helper
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

function v.isValidModifier(value)
	local v2

	if typeof(value) == "number" and value == value and value > -1e999 then
		v2 = value < 1e999
	else
		v2 = false
	end

	if v2 then
		if value >= 0 then
			return value <= 1
		else
			return false
		end
	end

	return v2
end

local function canonicalModifier(value: number) -- 2 equivalent calls inferred from this helper
	buffer.writef32(buf, 0, value)
	return (buffer.readf32(buf, 0))
end

function v.predictableDelayTicks(value, value2, value3: number, max: number)
	assert(isFinite(value3) and value3 > 0, "damage-tag step must be finite and positive") -- inferred equivalent call
	local v2 = max % 1 == 0 and v.MinimumPredictableTicks <= max
	assert(v2, "invalid damage-tag horizon")
	local v3 = not isFinite(value) and 0 or math.max(value, 0) -- inferred equivalent call
	return (math.clamp(
		(not isFinite(value2) and 0 or math.max(math.floor(value2), 0)) + math.ceil(v3 / value3 * (1 + Config.CommandClockMaxSlewRatio)) + v.NetworkSafetyTicks, -- inferred equivalent call
		v.MinimumPredictableTicks,
		max
	))
end

function v.apply(p: number, p2: number)
	assert(v.isValidModifier(p), "invalid current velocity modifier")
	assert(v.isValidModifier(p2), "invalid incoming velocity modifier")
	return canonicalModifier(math.min(p, p2)) -- inferred equivalent call
end

function v.recover(p: number, value: number)
	assert(v.isValidModifier(p), "invalid current velocity modifier")
	assert(isFinite(value) and value > 0, "damage-tag delta must be finite and positive") -- inferred equivalent call
	return canonicalModifier(math.min(p + v.RecoveryPerSecond * value, 1)) -- inferred equivalent call
end

return table.freeze(v)