local CommandCodec = require(script.Parent.Parent.CommandCodec)
local Config = require(script.Parent.Parent.Config)
local Enums = require(script.Parent.Parent.Enums)
local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
require(script.Parent.Parent.Transport)
require(script.Parent.CommandStream)
local class = {}
class.__index = class

local function sendBudget(p) -- 2 equivalent calls inferred from this helper
	local v = 1 / Config.PolicySeconds.CommandPacketPeriod
	local v2 = math.min(p.SimulationHz, v) * 1.375
	return v2, (math.max(8, v2 * 0.25))
end

function class.new(host)
	return (setmetatable({
		_host = host,
		_tokens = 0,
		_lastRefillAt = 0,
		_counters = { PacketsSent = 0, RecoveryPacketsSent = 0, BudgetDeferrals = 0 },
		_lastRecoverySentAt = 0,
		_acknowledgementAdvancedAt = 0
	}, class))
end

function class:resetGeneration()
	self._tokens = 0
	self._lastRefillAt = 0
	self._lastRecoverySentAt = 0
	self._lastRecoveryAcknowledgedCommand = nil
	self._observedAcknowledgedCommand = nil
	self._acknowledgementAdvancedAt = 0
end

function class:resetCounters()
	local counters = self._counters
	counters.PacketsSent = 0
	counters.RecoveryPacketsSent = 0
	counters.BudgetDeferrals = 0
end

function class:fillBudget(p)
	if p == nil then
		self._tokens = 0
		self._lastRefillAt = 0
	else
		local v = 1 / Config.PolicySeconds.CommandPacketPeriod
		self._tokens = math.max(8, math.min(p.SimulationHz, v) * 1.375 * 0.25)
		self._lastRefillAt = os.clock()
	end
end

function class:counters()
	return self._counters
end

function class:lastRecoveryAcknowledgedCommand()
	return self._lastRecoveryAcknowledgedCommand
end

function class:onOwnerApplied(p: number)
	local lastRecoveryAcknowledgedCommand = self._lastRecoveryAcknowledgedCommand

	if lastRecoveryAcknowledgedCommand ~= nil and Serial.deltaUInt32(p, lastRecoveryAcknowledgedCommand) > 0 then
		self._lastRecoveryAcknowledgedCommand = nil
	end
end

function class:_refill(p, p2: number?)
	local v, tokens = sendBudget(p) -- inferred equivalent call
	local lastRefillAt2 = p2 or os.clock()
	local lastRefillAt = self._lastRefillAt

	if lastRefillAt <= 0 then
		self._tokens = tokens
		self._lastRefillAt = lastRefillAt2
		return self._tokens, v, tokens
	else
		local v2 = lastRefillAt2 - lastRefillAt

		if v2 > 0 then
			self._tokens = math.min(tokens, self._tokens + v2 * v)
			self._lastRefillAt = lastRefillAt2
		elseif v2 < 0 then
			self._lastRefillAt = lastRefillAt2
		end

		return self._tokens, v, tokens
	end
end

function class:peekBudget(p, p2: number)
	if p == nil then
		return 0, 0, 0
	end

	local v, v2 = sendBudget(p) -- inferred equivalent call

	if self._lastRefillAt <= 0 then
		return v2, v, v2
	end

	local v3 = math.max(p2 - self._lastRefillAt, 0)
	return math.min(v2, self._tokens + v3 * v), v, v2
end

function class:_tryConsumeToken(p)
	local refill = self:_refill(p)

	if refill < 1 then
		return false
	end

	self._tokens = refill - 1
	return true
end

function class:_refundToken(p)
	local _, _, v = self:_refill(p)
	self._tokens = math.min(v, self._tokens + 1)
end

function class:sendDue(object, p, p2, flag: boolean?)
	if object == nil or p == nil or p2 == nil or not object:hasPacketDue(flag) then
		return
	end

	local counters = self._counters
	local v = math.max(1, p.TargetRedundantCommandCount)
	local pendingNewCommandCount = object:pendingNewCommandCount()
	local v2

	if flag == true then
		v2 = pendingNewCommandCount == 0
	else
		v2 = false
	end

	for _ = 1, math.ceil(math.max(pendingNewCommandCount, 1) / v) + 1 do
		if not object:hasPacketDue(flag) then
			return
		end

		if not self:_tryConsumeToken(p) then
			counters.BudgetDeferrals += 1
			return
		end

		local pendingNewCommandCount2 = object:pendingNewCommandCount()
		local v3, v4 = object:takePacket(flag, v)

		if v3 == nil then
			self:_refundToken(p)

			if v4 ~= nil then
				self._host.Warn(`could not form command packet: {v4}`)
			end

			return
		else
			local encoded, v5 = CommandCodec.encode(v3, p)

			if encoded == nil then
				self:_refundToken(p)
				self._host.Warn(`could not encode command packet: {v5}`)
				return
			else
				p2.Commands:FireServer(encoded)
				counters.PacketsSent += 1
				self._host.OnPacketSent(buffer.len(encoded), false)
				local pendingNewCommandCount3 = object:pendingNewCommandCount()

				if v2 or pendingNewCommandCount3 == 0 then
					return
				end

				if pendingNewCommandCount2 <= pendingNewCommandCount3 then
					self._host.Warn("command packet drain made no forward progress")
					return
				end
			end
		end
	end

	self._host.Warn("command packet drain exceeded its monotonic bound")
end

function class:sendRecovery(object, p, p2, p3: number, value: number?)
	if object == nil or p == nil or p2 == nil then
		return
	end

	local lastSampledCommandNumber = object:lastSampledCommandNumber()

	if lastSampledCommandNumber == nil or Serial.deltaUInt32(lastSampledCommandNumber, p3) <= 0 then
		return
	end

	if Serial.deltaUInt32(lastSampledCommandNumber, p3) > math.max(p.CommandHistoryTicks, p.MaxCommandsPerPacket) then
		return
	end

	local counters = self._counters
	local v = math.floor((self:_refill(p)))

	if v < 1 then
		counters.BudgetDeferrals += 1
		return
	end

	local recoveryPacketsAfter, v2 = object:buildRecoveryPacketsAfter(p3, (math.min(value or 5, v)))

	if recoveryPacketsAfter == nil then
		self._host.Warn(`could not form command recovery: {v2 or "Unknown"}`)
		return
	end

	for i = 1, #recoveryPacketsAfter do
		if not self:_tryConsumeToken(p) then
			counters.BudgetDeferrals += 1
			break
		end

		local v3 = recoveryPacketsAfter[i]
		local encoded, v4 = CommandCodec.encode(v3, p)

		if encoded == nil then
			self:_refundToken(p)
			self._host.Warn(`could not encode command recovery: {v4 or "Unknown"}`)
			break
		else
			p2.Commands:FireServer(encoded)
			counters.PacketsSent += 1
			counters.RecoveryPacketsSent += 1
			self._host.OnPacketSent(buffer.len(encoded), true)
		end
	end
end

function class:recoverStalled(p, object, p2, p3, p4: number, flag: boolean)
	if p == nil or p2 == nil or object == nil then
		return
	end

	local now = os.clock()
	local lastProcessedCommand = p.LastProcessedCommand

	if self._observedAcknowledgedCommand ~= lastProcessedCommand then
		self._observedAcknowledgedCommand = lastProcessedCommand
		self._acknowledgementAdvancedAt = now
	end

	local lastSampledCommandNumber = object:lastSampledCommandNumber()

	if
		lastSampledCommandNumber == nil
		or Serial.deltaUInt32(lastSampledCommandNumber, lastProcessedCommand) <= p2.TargetRedundantCommandCount
	then
		return
	end

	local v

	if bit32.band(p.Flags, Enums.OwnerSnapshotFlags.Stalled) == 0 then
		v = false
	else
		v = now - self._acknowledgementAdvancedAt >= p2.TargetRedundantCommandCount * p2.StepSeconds
	end

	local v2

	if p4 > 0 then
		v2 = now - p4 >= 0.2
	else
		v2 = false
	end

	local v3

	if lastProcessedCommand == Serial.UInt32Max then
		v3 = object:getCommand(0) ~= nil
	else
		v3 = false
	end

	if not (v or v2 or v3) or now - self._lastRecoverySentAt < 0.25 or flag then
		return
	end

	local recoveryPacketsSent = self._counters.RecoveryPacketsSent
	self:sendRecovery(object, p2, p3, lastProcessedCommand, (v or v2) and 5 or 1)

	if recoveryPacketsSent < self._counters.RecoveryPacketsSent then
		self._lastRecoverySentAt = now
		self._lastRecoveryAcknowledgedCommand = lastProcessedCommand
	end
end

return table.freeze(class)