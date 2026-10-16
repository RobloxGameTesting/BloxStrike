local Config = require(script.Parent.Parent.Config)
require(script.Parent.Parent.Types)
local CommandClockMaxSlewRatio = Config.CommandClockMaxSlewRatio
local class = {}
class.__index = class

local function isFinite(value) -- 3 equivalent calls inferred from this helper
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

function class.new(config, flag: boolean?)
	assert(type(config) == "table", "derived config is required")
	local windowSeconds = config.CommandClockWindowTicks / config.SimulationHz
	local capacity = math.max(4, math.ceil(windowSeconds / (config.OwnerSnapshotEveryTicks / config.SimulationHz)) + 4)
	return (setmetatable({
		_config = config,
		_targetDepth = config.CommandBufferTargetTicks,
		_windowSeconds = windowSeconds,
		_samples = table.create(capacity),
		_head = 0,
		_count = 0,
		_capacity = capacity,
		_rate = 1,
		_errorTicks = 0,
		_enabled = flag ~= false
	}, class))
end

function class:reset()
	self._head = 0
	self._count = 0
	self._rate = 1
	self._worstDepth = nil
	self._bestDepth = nil
	self._errorTicks = 0
	table.clear(self._samples)
end

local function prune(state, p: number)
	local v = p - state._windowSeconds

	while state._count > 0 do
		local sample = state._samples[state._head % state._capacity + 1]

		if sample == nil or v <= sample.AtSeconds then
			break
		end

		state._head = (state._head + 1) % state._capacity
		state._count -= 1
	end
end

local function recompute(state)
	if state._count == 0 then
		state._worstDepth = nil
		state._bestDepth = nil
		state._errorTicks = 0
		state._rate = 1
	else
		local depth = nil
		local depth2 = nil
		local count = 0

		for i = 0, state._count - 1 do
			local sample = state._samples[(state._head + i) % state._capacity + 1]

			if sample == nil then
				continue
			end

			if depth == nil or sample.Depth < depth then
				depth = sample.Depth
			end

			if depth2 == nil or depth2 < sample.Depth then
				depth2 = sample.Depth
			end

			if sample.Depth < state._targetDepth then
				count += 1
			end
		end

		state._worstDepth = depth
		state._bestDepth = depth2

		if depth == nil or depth2 == nil then
			state._errorTicks = 0
			state._rate = 1
		else
			local targetDepth = state._targetDepth
			local errorTicks = 0

			if targetDepth + 0.5 < depth then
				errorTicks = depth - (targetDepth + 0.5)
			elseif depth < targetDepth - 0.5 and count >= 2 then
				errorTicks = depth - targetDepth
			end

			state._errorTicks = errorTicks

			if state._enabled and errorTicks ~= 0 then
				state._rate = math.clamp(
					1 - errorTicks / math.max(1, state._windowSeconds * state._config.SimulationHz),
					1 - CommandClockMaxSlewRatio,
					1 + CommandClockMaxSlewRatio
				)
			else
				state._rate = 1
			end
		end
	end
end

function class:observe(depth: number, atSeconds: number)
	assert(isFinite(depth), "invalid command buffer depth") -- inferred equivalent call
	assert(isFinite(atSeconds) and atSeconds >= 0, "invalid command clock time") -- inferred equivalent call
	prune(self, atSeconds)

	if self._count >= self._capacity then
		self._head = (self._head + 1) % self._capacity
		self._count -= 1
	end

	local v = (self._head + self._count) % self._capacity + 1
	local sample = self._samples[v]

	if sample == nil then
		self._samples[v] = { Depth = depth, AtSeconds = atSeconds }
	else
		sample.Depth = depth
		sample.AtSeconds = atSeconds
	end

	self._count += 1
	recompute(self)
end

function class:rate(value: number)
	assert(isFinite(value) and value >= 0, "invalid command clock time") -- inferred equivalent call
	prune(self, value)
	recompute(self)
	return self._rate
end

function class:diagnostics()
	return table.freeze({
		Rate = self._rate,
		WorstDepth = self._worstDepth,
		BestDepth = self._bestDepth,
		TargetDepth = self._targetDepth,
		ErrorTicks = self._errorTicks,
		SampleCount = self._count
	})
end

return table.freeze(class)