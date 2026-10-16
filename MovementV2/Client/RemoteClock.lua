local Config = require(script.Parent.Parent.Config)
local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
local class = {}
class.__index = class

local function isFinite(p: number) -- 3 equivalent calls inferred from this helper
	return p == p and p > -1e999 and p < 1e999
end

function class.new(config, flag: boolean?)
	assert(type(config) == "table", "derived config is required")
	local v = math.max(config.RemoteSnapshotEveryTicks, 1)
	local maxBehindTicks = math.max(v * 2, config.RemoteHistoryTicks - config.RenderInterpolationTicks - v)
	return (setmetatable({
		_config = config,
		_hz = config.SimulationHz,
		_renderOffsetTicks = config.RenderInterpolationTicks,
		_horizonTicks = config.RenderInterpolationTicks + config.MaxRemoteExtrapolationTicks,
		_maxBehindTicks = maxBehindTicks,
		_deepestLagTicks = maxBehindTicks * 0.75,
		_spacingTicks = config.SimulationHz * Config.PolicySeconds.RemoteSnapshotPeriod,
		_spectator = flag == true,
		_bufferTicks = flag and 2 or 0,
		_anchorTick = nil,
		_latestTicks = 0,
		_latestAtSeconds = 0,
		_position = nil,
		_windowKeys = {},
		_windowTimes = {},
		_windowHead = 1,
		_windowTail = 0,
		_sortScratch = {},
		_lateKey = nil,
		_jitterTicks = 0,
		_lateKeyDirty = false,
		_lastMode = "Unanchored",
		_lastErrorTicks = 0,
		_lastMinMarginTicks = nil,
		_lastRate = 1,
		_hardRebases = 0,
		_frames = 0,
		_extrapolatingFrames = 0,
		_holdingFrames = 0
	}, class))
end

function class:setSpectator(spectator: boolean)
	self._spectator = spectator
	self._bufferTicks = spectator and 2 or 0
end

local function targetTicks(p) -- 3 equivalent calls inferred from this helper
	return 0.005 * p._hz + p._bufferTicks
end

local function clearWindow(state) -- 1 equivalent call inferred from this helper
	table.clear(state._windowKeys)
	table.clear(state._windowTimes)
	state._windowHead = 1
	state._windowTail = 0
	state._lateKey = nil
	state._jitterTicks = 0
	state._lateKeyDirty = false
end

local function pushMargin(state, p: number, latestAtSeconds: number) -- 1 equivalent call inferred from this helper
	local windowTail = state._windowTail + 1
	state._windowKeys[windowTail] = p
	state._windowTimes[windowTail] = latestAtSeconds
	state._windowTail = windowTail
	state._lateKeyDirty = true
end

local function lateArrivalKey(object, p: number)
	local windowKeys = object._windowKeys
	local windowTimes = object._windowTimes
	local windowHead = object._windowHead
	local v = p - 1.5

	while windowHead <= object._windowTail and windowTimes[windowHead] < v do
		windowKeys[windowHead] = nil
		windowTimes[windowHead] = nil
		windowHead += 1
		object._lateKeyDirty = true
	end

	if object._windowTail < windowHead then
		object._windowHead = 1
		object._windowTail = 0
		object._lateKey = nil
		return nil
	else
		object._windowHead = windowHead

		if not object._lateKeyDirty then
			return object._lateKey
		end

		local sortScratch = object._sortScratch
		table.clear(sortScratch)
		table.move(windowKeys, windowHead, object._windowTail, 1, sortScratch)
		table.sort(sortScratch)
		local lateKey = sortScratch[math.floor(#sortScratch * 0.05) + 1]
		object._lateKey = lateKey
		object._jitterTicks = sortScratch[math.floor(#sortScratch * 0.5) + 1] - lateKey
		object._lateKeyDirty = false
		return object._lateKey
	end
end

local function settledPosition(data, p: number) -- 2 equivalent calls inferred from this helper
	local v = math.max(p - data._latestAtSeconds, 0) * data._hz
	return (math.min(
		data._latestTicks + data._renderOffsetTicks - data._spacingTicks - targetTicks(data) + v, -- inferred equivalent call
		data._latestTicks + data._horizonTicks
	))
end

function class:observe(anchorTick: number, latestAtSeconds: number)
	assert(Serial.isUInt32(anchorTick), "invalid remote server tick")
	assert(isFinite(latestAtSeconds) and latestAtSeconds >= 0, "invalid observation time") -- inferred equivalent call
	local _anchorTick = self._anchorTick

	if _anchorTick == nil then
		self._anchorTick = anchorTick
		self._latestTicks = 0
		self._latestAtSeconds = latestAtSeconds
		return true
	else
		local deltaUInt32 = Serial.deltaUInt32(anchorTick, _anchorTick)

		if deltaUInt32 <= self._latestTicks then
			return false
		end

		pushMargin(self, self._latestTicks + self._renderOffsetTicks - latestAtSeconds * self._hz, latestAtSeconds) -- inferred equivalent call
		self._latestTicks = deltaUInt32
		self._latestAtSeconds = latestAtSeconds
		return true
	end
end

local function rebase(object, p: number, p2: number)
	local v = assert(object._anchorTick)
	local latestTicks = object._latestTicks
	object._anchorTick = Serial.addUInt32(v, latestTicks)
	object._latestTicks = 0
	clearWindow(object) -- inferred equivalent call
	object._hardRebases += 1
	object._lastMode = "Rebased"
	return math.max(settledPosition(object, p), p2 - latestTicks), latestTicks -- inferred equivalent call
end

function class:advance(value: number?, p: number)
	local v = value == nil or isFinite(value) and value >= 0 -- inferred equivalent call
	assert(v, "invalid remote render delta")
	assert(isFinite(p) and p >= 0, "invalid remote clock time") -- inferred equivalent call

	if self._anchorTick == nil then
		self._lastMode = "Unanchored"
		self._lastErrorTicks = 0
		return nil, 0
	else
		local hz = self._hz
		local position = self._position

		if position == nil then
			self._position = settledPosition(self, p) -- inferred equivalent call
			self._lastMode = "Anchored"
			self._lastErrorTicks = 0
			return self:current()
		else
			self._frames += 1
			local v2 = value or 0
			local v3 = v2 * hz
			local position2 = position + v3
			local v4 = self._latestTicks + self._renderOffsetTicks - position2

			if self._maxBehindTicks < v4 then
				local v5
				position2, v5 = rebase(self, p, position2)
				position -= v5
				self._lastErrorTicks = 0
				self._lastMinMarginTicks = nil
			else
				local v5 = lateArrivalKey(self, p)

				if v5 == nil then
					self._lastMode = "FreeRun"
					self._lastErrorTicks = 0
					self._lastMinMarginTicks = nil
				else
					local lastMinMarginTicks = v5 - (position2 - p * hz)
					local lastErrorTicks = lastMinMarginTicks - targetTicks(self) -- inferred equivalent call
					self._lastMinMarginTicks = lastMinMarginTicks
					self._lastErrorTicks = lastErrorTicks
					local v6

					if self._spectator then
						v6 = self._deepestLagTicks
					else
						v6 = math.min(self._deepestLagTicks, math.clamp(self._jitterTicks, 0, 3) + 4)
					end

					local v7 = lastErrorTicks < 0 and v6 <= v4 and 0 or lastErrorTicks

					if v2 > 0 and v7 ~= 0 then
						local v8 = v7 > 0 and 0.6 or 0.3
						position2 += math.clamp(
							v7 * (1 - math.exp(-v2 / v8)),
							-0.06999999999999995 * v3,
							0.06000000000000005 * v3
						)
					end

					self._lastMode = "Slew"
				end
			end

			local v5 = self._latestTicks + self._horizonTicks

			if v5 < position2 then
				position2 = math.max(v5, position)
				self._lastMode = "Holding"
				self._holdingFrames += 1
			elseif position2 - self._renderOffsetTicks > self._latestTicks then
				if self._lastMode ~= "Rebased" then
					self._lastMode = "Extrapolating"
				end

				self._extrapolatingFrames += 1
			end

			self._lastRate = not (v3 > 0) and 1 or (position2 - position) / v3
			self._position = position2
			return self:current()
		end
	end
end

function class:current()
	local anchorTick = self._anchorTick
	local position = self._position

	if anchorTick == nil or position == nil then
		return nil, 0
	end

	local v = math.floor(position)
	return Serial.addUInt32(anchorTick, v), position - v
end

function class:diagnostics()
	local hz = self._hz
	local position = self._position
	local lastMinMarginTicks = self._lastMinMarginTicks
	local v = {
		Mode = self._lastMode,
		DriftTicks = self._lastErrorTicks,
		HardRebases = self._hardRebases,
		LatestObservedTick = 0,
		DelayMs = 0,
		WindowMinMarginMs = 0,
		TargetMarginMs = 0,
		WindowSamples = 0,
		BufferTicks = 0,
		Rate = 0,
		Frames = 0,
		ExtrapolatingFrames = 0,
		HoldingFrames = 0
	}
	local latestObservedTick

	if self._anchorTick ~= nil then
		latestObservedTick = Serial.addUInt32(self._anchorTick, self._latestTicks)
	end

	v.LatestObservedTick = latestObservedTick
	v.DelayMs = position == nil and 0 or (self._latestTicks + self._renderOffsetTicks - position) * 1000 / hz
	local windowMinMarginMs

	if lastMinMarginTicks ~= nil then
		windowMinMarginMs = lastMinMarginTicks * 1000 / hz
	end

	v.WindowMinMarginMs = windowMinMarginMs
	v.TargetMarginMs = targetTicks(self) * 1000 / hz -- inferred equivalent call
	v.WindowSamples = math.max(self._windowTail - self._windowHead + 1, 0)
	v.BufferTicks = self._bufferTicks
	v.Rate = self._lastRate
	v.Frames = self._frames
	v.ExtrapolatingFrames = self._extrapolatingFrames
	v.HoldingFrames = self._holdingFrames
	return table.freeze(v)
end

return table.freeze(class)