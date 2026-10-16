local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
local Config = require(script.Parent.Parent.Config)
local DestructibleFrame = require(script.Parent.Parent.Collision.DestructibleFrame)
local Serial = require(script.Parent.Parent.Serial)
local class = {}
class.__index = class

local function immutableTransition(serverTick: number, frame) -- 2 equivalent calls inferred from this helper
	return (table.freeze({ ServerTick = serverTick, Frame = frame }))
end

local function latestTransition(p) -- 5 equivalent calls inferred from this helper
	return p._transitions[#p._transitions]
end

local function retainedTransition(p, p2: number)
	for i = #p._transitions, 1, -1 do
		local transition = p._transitions[i]

		if Serial.deltaUInt32(p2, transition.ServerTick) >= 0 then
			return transition
		end
	end

	return nil
end

local function requestBaseline(state, p: string) -- 13 equivalent calls inferred from this helper
	state._needsBaseline = true

	if state._requestFired then
		return
	end

	state._requestFired = true
	local v = latestTransition(state) -- inferred equivalent call
	state.BaselineNeeded:Fire(state._expectedEpoch, v == nil and 0 or v.Frame.Revision, p)
end

local function prune(p, p2: number)
	while #p._transitions > 1 do
		local transition = p._transitions[2]

		if Serial.deltaUInt32(p2, transition.ServerTick) < p._retentionTicks then
			break
		else
			table.remove(p._transitions, 1)
		end
	end
end

local function deactivate(frame, items, p: number)
	local v = 0
	local v2 = {}
	local v3 = {}

	for _, item in items do
		if not Serial.isUInt16(item) or item == 0 or frame.Count < item or item <= v then
			return nil, "InvalidDeltaIndices"
		end

		local v4 = item - 1
		local v5 = math.floor(v4 / 8) + 1
		local v6 = bit32.lshift(1, v4 % 8)
		local v7 = v2[v5]

		if v7 == nil then
			v7 = string.byte(frame.ActiveBits, v5)
			v3[#v3 + 1] = v5
		end

		if bit32.band(v7, v6) == 0 then
			return nil, "DeltaDeactivatesInactiveSource"
		end

		v2[v5] = bit32.band(v7, (bit32.bnot(v6)))
		v = item
	end

	local v4 = table.create(#v3 * 2 + 1)
	local v5 = 1

	for _, v6 in v3 do
		if v5 < v6 then
			v4[#v4 + 1] = string.sub(frame.ActiveBits, v5, v6 - 1)
		end

		v4[#v4 + 1] = string.char(v2[v6])
		v5 = v6 + 1
	end

	if v5 <= #frame.ActiveBits then
		v4[#v4 + 1] = string.sub(frame.ActiveBits, v5)
	end

	return DestructibleFrame.New(frame.Epoch, p, frame.Count, table.concat(v4)), nil
end

function class.new(p: number, expectedEpoch: number, expectedCount: number)
	local derive = Config.derive(p)
	assert(Serial.isNonZeroUInt16(expectedEpoch), "destructible timeline epoch must be a non-zero u16")
	local v, v2 = DestructibleFrame.Validate(
		expectedEpoch,
		0,
		expectedCount,
		string.rep("\0", (math.ceil(expectedCount / 8)))
	)
	assert(v, v2)
	return (setmetatable({
		_expectedEpoch = expectedEpoch,
		_expectedCount = expectedCount,
		_retentionTicks = derive.PredictionReplayTicks,
		_transitions = {},
		_needsBaseline = true,
		_requestFired = false,
		BaselineNeeded = Signal.new()
	}, class))
end

function class:fork()
	local clone = table.clone(self)
	clone._transitions = table.clone(self._transitions)
	clone.BaselineNeeded = Signal.new()
	return (setmetatable(clone, class))
end

function class:destroy()
	self.BaselineNeeded:Destroy()
	table.clear(self._transitions)
end

function class:needsBaseline()
	return self._needsBaseline
end

function class:requestBaseline(p: string)
	self._needsBaseline = true

	if self._requestFired then
		return
	end

	self._requestFired = true
	local v = latestTransition(self) -- inferred equivalent call
	self.BaselineNeeded:Fire(self._expectedEpoch, v == nil and 0 or v.Frame.Revision, p)
end

function class.latestRevision(p)
	local v = latestTransition(p) -- inferred equivalent call

	if v == nil then
		return 0
	end

	return v.Frame.Revision
end

function class:consumeBaseline(serverTick: number, data)
	if not Serial.isUInt32(serverTick) then
		return false, "InvalidBaselineServerTick"
	end

	local v, v2 = DestructibleFrame.Validate(data.Epoch, data.Revision, data.Count, data.ActiveBits)

	if not v then
		return false, v2
	end

	if data.Epoch == self._expectedEpoch then
		if data.Count == self._expectedCount then
			local v3 = latestTransition(self) -- inferred equivalent call

			if v3 == nil or v3.Frame.Revision ~= data.Revision or v3.Frame.ActiveBits ~= data.ActiveBits then
				local frame = DestructibleFrame.New(data.Epoch, data.Revision, data.Count, data.ActiveBits)
				table.clear(self._transitions)
				self._transitions[1] = immutableTransition(serverTick, frame) -- inferred equivalent call
				self._needsBaseline = false
				self._requestFired = false
				return true, nil, true
			else
				self._needsBaseline = false
				self._requestFired = false
				return true, nil, false
			end
		else
			requestBaseline(self, "BaselineCountMismatch") -- inferred equivalent call
			return false, "BaselineCountMismatch"
		end
	else
		requestBaseline(self, "BaselineEpochMismatch") -- inferred equivalent call
		return false, "BaselineEpochMismatch"
	end
end

function class:consumeDelta(p: number, p2: number, serverTick: number, list)
	if self._needsBaseline then
		requestBaseline(self, "DeltaWithoutBaseline") -- inferred equivalent call
		return false, "BaselineRequired"
	elseif p == self._expectedEpoch then
		if Serial.isUInt32(p2) and Serial.isUInt32(serverTick) then
			local v = latestTransition(self) -- inferred equivalent call

			if v == nil then
				requestBaseline(self, "DeltaWithoutBaseline") -- inferred equivalent call
				return false, "BaselineRequired"
			elseif p2 == Serial.addUInt32(v.Frame.Revision, 1) then
				if Serial.deltaUInt32(serverTick, v.ServerTick) <= 0 then
					requestBaseline(self, "DeltaTickNotNewer") -- inferred equivalent call
					return false, "DeltaTickNotNewer"
				elseif type(list) == "table" and #list ~= 0 then
					local frame, v2 = deactivate(v.Frame, list, p2)

					if frame == nil then
						requestBaseline(self, v2 or "InvalidDelta") -- inferred equivalent call
						return false, v2
					else
						self._transitions[#self._transitions + 1] = immutableTransition(serverTick, frame) -- inferred equivalent call
						prune(self, serverTick)
						return true, nil
					end
				else
					requestBaseline(self, "InvalidDeltaIndices") -- inferred equivalent call
					return false, "InvalidDeltaIndices"
				end
			else
				requestBaseline(self, "DestructibleRevisionGap") -- inferred equivalent call
				return false, "DestructibleRevisionGap"
			end
		else
			requestBaseline(self, "InvalidDeltaStamp") -- inferred equivalent call
			return false, "InvalidDeltaStamp"
		end
	else
		requestBaseline(self, "DeltaEpochMismatch") -- inferred equivalent call
		return false, "DeltaEpochMismatch"
	end
end

function class:resolve(p: number, p2: number?)
	if not Serial.isUInt32(p) then
		return nil, "InvalidResolveServerTick"
	end

	if p2 ~= nil and not Serial.isUInt32(p2) then
		return nil, "InvalidExpectedRevision"
	end

	if self._needsBaseline then
		requestBaseline(self, "BaselineRequired") -- inferred equivalent call
		return nil, "BaselineRequired"
	else
		local v = retainedTransition(self, p)

		if v == nil then
			requestBaseline(self, "DestructibleFrameOutsideRetention") -- inferred equivalent call
			return nil, "DestructibleFrameOutsideRetention"
		else
			if p2 == nil or v.Frame.Revision == p2 then
				prune(self, p)
				return v.Frame, nil
			end

			requestBaseline(self, "DestructibleRevisionMismatch") -- inferred equivalent call
			return nil, "DestructibleRevisionMismatch"
		end
	end
end

function class:predict(p: number, p2: number?)
	if not Serial.isUInt32(p) then
		return nil, "InvalidResolveServerTick"
	end

	local v = retainedTransition(self, p) or self._transitions[1]

	if v == nil then
		return nil, "DestructibleFrameOutsideRetention"
	end

	if p2 == nil or v.Frame.Revision == p2 then
		return v.Frame, nil
	end

	return nil, "DestructibleRevisionMismatch"
end

function class:peek(p: number, p2: number?)
	if not Serial.isUInt32(p) then
		return nil, "InvalidResolveServerTick"
	end

	if p2 ~= nil and not Serial.isUInt32(p2) then
		return nil, "InvalidExpectedRevision"
	end

	if self._needsBaseline then
		return nil, "BaselineRequired"
	end

	local v = retainedTransition(self, p)

	if v == nil then
		return nil, "DestructibleFrameOutsideRetention"
	end

	if p2 == nil or v.Frame.Revision == p2 then
		return v.Frame, nil
	end

	return nil, "DestructibleRevisionMismatch"
end

return table.freeze(class)