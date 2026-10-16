local createVector = vector.create
local Config = require(script.Parent.Parent.Simulation.Config)
local v = {
	MaxSeconds = 0.2,
	MinSpeed = 150 * Config.Default.HammerUnitToStud,
	MaxDistance = 64 * Config.Default.HammerUnitToStud,
	Epsilon = 0.0001,
	ContactMinDistance = Config.Default.MaxBaseMoveSpeed * (1 / 30)
}

local function finiteNonnegative(value) -- 1 equivalent call inferred from this helper
	if typeof(value) == "number" and value == value and not (value < 0) and value ~= 1e999 then
		return value
	end

	return 0
end

function v.clampOffset(vector: Vector3)
	local magnitude = vector.Magnitude

	if magnitude <= v.Epsilon then
		return createVector(0, 0, 0)
	end

	if v.MaxDistance < magnitude then
		return vector.Unit * v.MaxDistance
	end

	return vector
end

function v.remainingOffset(vector: Vector3, value: number)
	local magnitude = vector.Magnitude

	if magnitude <= v.Epsilon then
		return createVector(0, 0, 0)
	end

	local v2 = finiteNonnegative(value) -- inferred equivalent call
	local v3 = math.max(magnitude - math.max(v2 * v.MinSpeed, v2 / v.MaxSeconds * magnitude), 0)

	if v.Epsilon < v3 then
		return vector.Unit * v3
	end

	return createVector(0, 0, 0)
end

function v.isHardSnapCorrection(data)
	local reconciliationMode = data.ReconciliationMode

	if reconciliationMode == "Initial" or reconciliationMode == "Reanchor" and data.TailCompared ~= true then
		return true
	end

	return (typeof(data.TailPosition) ~= "number" and 0 or data.TailPosition) > v.MaxDistance
end

return table.freeze(v)