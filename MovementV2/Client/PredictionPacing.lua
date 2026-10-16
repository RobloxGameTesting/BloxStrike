require(script.Parent.Parent.Types)

local function isFinite(value) -- 3 equivalent calls inferred from this helper
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

return table.freeze({
	policyFromConfig = function(data)
		return table.freeze({
			StepSeconds = data.StepSeconds,
			MaxFrameSeconds = data.MaxPredictionFrameTicks * data.StepSeconds,
			MaxAccumulatorSeconds = data.PredictionAccumulatorTicks * data.StepSeconds,
			MaxSteps = data.PredictionAccumulatorTicks,
			WorkCeilingFraction = 0.5,
			MinimumSteps = 2
		})
	end,
	plan = function(value: number, value2: number, data, value3: number?)
		assert(isFinite(value) and value >= 0, "invalid prediction accumulator") -- inferred equivalent call
		assert(isFinite(value2) and value2 >= 0, "invalid frame delta") -- inferred equivalent call
		local v = value3 or 1
		assert(isFinite(v) and v > 0, "invalid command clock rate") -- inferred equivalent call
		local admittedSeconds = math.min(value2, data.MaxFrameSeconds)
		local v2 = math.max(value2 - admittedSeconds, 0)
		local v3 = admittedSeconds * v
		local v4 = value + v3
		local v5 = math.min(v4, data.MaxAccumulatorSeconds)
		local v6 = math.max(v4 - data.MaxAccumulatorSeconds, 0)
		local guaranteedSteps = math.min(data.MaxSteps, (math.max(1, (math.ceil(v3 / data.StepSeconds)))))
		return {
			AdmittedSeconds = admittedSeconds,
			DiscardedSeconds = v2 + v6,
			AccumulatorSeconds = v5,
			BacklogBeforeSeconds = v5,
			GuaranteedSteps = guaranteedSteps,
			MaxSteps = data.MaxSteps,
			WorkCeilingSeconds = admittedSeconds * data.WorkCeilingFraction,
			MinimumSteps = math.min(data.MinimumSteps, guaranteedSteps)
		}
	end
})