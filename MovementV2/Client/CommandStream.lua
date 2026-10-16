local CommandCodec = require(script.Parent.Parent.CommandCodec)
local Config = require(script.Parent.Parent.Config)
local Mapping = require(script.Parent.Parent.Mapping)
local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
local class = {}
class.__index = class

local function slotIndex(data, p: number) -- 2 equivalent calls inferred from this helper
	local lastSampledCommandNumber = data._lastSampledCommandNumber

	if lastSampledCommandNumber == nil then
		return 1
	end

	return (data._lastSampledSlotIndex - 1 + Serial.deltaUInt32(p, lastSampledCommandNumber)) % data._capacity + 1
end

local function packetCadenceRate(simulationHz: number) -- 1 equivalent call inferred from this helper
	local v = 1 / Config.PolicySeconds.CommandPacketPeriod
	local v2 = v % 1 == 0 and v > 0
	assert(v2, "command packet period must resolve to an integer rate")
	return (math.min(simulationHz, v))
end

function class.new(p)
	local self = setmetatable({ _slots = {} }, class)
	self:reset(p)
	return self
end

function class:reset(p)
	local v, v2 = Mapping.validate(p)
	assert(v, v2 or "invalid command mapping")
	local derive = Config.derive(p.SimulationHz)
	self._mapping = Mapping.clone(p)
	self._config = derive
	self._capacity = math.max(derive.CommandHistoryTicks, derive.MaxCommandsPerPacket)
	table.clear(self._slots)
	self._lastSampledCommandNumber = nil
	self._lastSampledSlotIndex = 1
	self._lastPacketedCommandNumber = Serial.UInt32Max
	self._packetCadenceRateHz = packetCadenceRate(derive.SimulationHz) -- inferred equivalent call
	self._packetCadencePhase = 0
	self._packetCadenceDue = false
end

function class:reconfigure(p)
	local v, v2 = Mapping.validate(p)
	assert(v, v2 or "invalid command mapping")
	assert(p.Generation == self._mapping.Generation, "cannot reconfigure a different command generation")
	assert(p.SimulationHz == self._mapping.SimulationHz, "cannot reconfigure the command simulation rate")
	self._mapping = Mapping.clone(p)
end

function class:lastSampledCommandNumber()
	return self._lastSampledCommandNumber
end

function class:pendingNewCommandCount()
	local lastSampledCommandNumber = self._lastSampledCommandNumber

	if lastSampledCommandNumber == nil then
		return 0
	end

	return (math.max(Serial.deltaUInt32(lastSampledCommandNumber, self._lastPacketedCommandNumber), 0))
end

function class:hasPacketDue(flag: boolean?)
	if self:pendingNewCommandCount() > 0 then
		return flag == true or self._packetCadenceDue
	end

	return flag == true and self._lastSampledCommandNumber ~= nil
end

function class:getCommand(p: number)
	if not Serial.isUInt32(p) then
		return nil
	end

	local slot = self._slots[slotIndex(self, p)] -- inferred equivalent call

	if slot == nil or slot.CommandNumber ~= p then
		return nil
	end

	return slot
end

function class:sample(data)
	local lastSampledCommandNumber = self._lastSampledCommandNumber == nil and 0
		or Serial.addUInt32(self._lastSampledCommandNumber, 1)
	local canonicalizeCommand, v = CommandCodec.canonicalizeCommand(lastSampledCommandNumber, data)

	if canonicalizeCommand == nil then
		return nil, v
	end

	canonicalizeCommand.PredictedBaseMoveSpeed = data.PredictedBaseMoveSpeed
	canonicalizeCommand.PredictedWeaponMoveSpeed = data.PredictedWeaponMoveSpeed
	canonicalizeCommand.PredictedWeaponScopedMoveSpeed = data.PredictedWeaponScopedMoveSpeed
	local frozen = table.freeze(canonicalizeCommand)

	if Serial.deltaUInt32(lastSampledCommandNumber, self._lastPacketedCommandNumber) > self._capacity then
		return nil, "UnsentHistoryOverflow"
	end

	local lastSampledSlotIndex = slotIndex(self, lastSampledCommandNumber) -- inferred equivalent call
	self._slots[lastSampledSlotIndex] = frozen
	self._lastSampledCommandNumber = lastSampledCommandNumber
	self._lastSampledSlotIndex = lastSampledSlotIndex
	self._packetCadencePhase += self._packetCadenceRateHz

	if self._packetCadencePhase >= self._config.SimulationHz then
		self._packetCadencePhase -= self._config.SimulationHz
		self._packetCadenceDue = true
	end

	if frozen.WeaponSelectRequestId ~= nil then
		self._packetCadenceDue = true
	end

	return frozen, nil
end

function class:takePacket(flag: boolean?, p: number?)
	local pendingNewCommandCount = self:pendingNewCommandCount()
	local v

	if pendingNewCommandCount == 0 and flag == true then
		v = self._lastSampledCommandNumber ~= nil
	else
		v = false
	end

	if pendingNewCommandCount == 0 and not v or not (flag or self._packetCadenceDue) then
		return nil, nil
	end

	local v2 = p or self._config.MaxNewCommandsPerPacket

	if type(v2) ~= "number" or v2 % 1 ~= 0 or v2 < 1 or self._config.MaxNewCommandsPerPacket < v2 then
		return nil, "InvalidMaximumNewCommands"
	end

	local v3 = v and 1 or math.min(pendingNewCommandCount, v2)
	local v4

	if v then
		v4 = assert(self._lastSampledCommandNumber)
	else
		v4 = Serial.addUInt32(self._lastPacketedCommandNumber, 1)
	end

	local targetRedundantCommandCount = self._config.TargetRedundantCommandCount

	while
		targetRedundantCommandCount > 0
		and self:getCommand((Serial.addUInt32(v4, -targetRedundantCommandCount))) == nil
	do
		targetRedundantCommandCount -= 1
	end

	local commands = table.create(targetRedundantCommandCount + v3)

	for i = -targetRedundantCommandCount, v3 - 1 do
		local command = self:getCommand((Serial.addUInt32(v4, i)))

		if command == nil then
			return nil, "CommandHistoryGap"
		else
			table.insert(commands, command)
		end
	end

	local packet, v5 = CommandCodec.makePacket(self._mapping.Generation, commands, v3, self._config)

	if packet == nil then
		return nil, v5
	end

	if not v then
		self._lastPacketedCommandNumber = Serial.addUInt32(v4, v3 - 1)
	end

	if self:pendingNewCommandCount() == 0 then
		self._packetCadenceDue = false
	end

	return packet, nil
end

function class:buildRecoveryPacketsAfter(p: number, value: number?)
	if not Serial.isUInt32(p) then
		return nil, "InvalidAcknowledgedCommand"
	end

	if value ~= nil and (type(value) ~= "number" or value % 1 ~= 0 or value < 1 or value == 1e999) then
		return nil, "InvalidMaximumPackets"
	end

	local lastSampledCommandNumber = self._lastSampledCommandNumber

	if lastSampledCommandNumber == nil then
		return table.freeze({}), nil
	end

	local deltaUInt32 = Serial.deltaUInt32(lastSampledCommandNumber, p)

	if deltaUInt32 <= 0 then
		return table.freeze({}), nil
	end

	if self._capacity < deltaUInt32 then
		return nil, "CommandHistoryGap"
	end

	local v = math.max(1, self._config.TargetRedundantCommandCount)
	local v2 = value or math.ceil(deltaUInt32 / v)
	local packets = table.create((math.min(v2, (math.ceil(deltaUInt32 / v)))))
	local v3 = Serial.addUInt32(p, 1)
	local total = 0

	while total < deltaUInt32 and #packets < v2 do
		local v4 = math.min(v, deltaUInt32 - total)
		local v5 = math.min(self._config.TargetRedundantCommandCount, total)
		local v6 = Serial.addUInt32(v3, -v5)
		local commands = table.create(v5 + v4)

		for i = 0, v5 + v4 - 1 do
			local command = self:getCommand((Serial.addUInt32(v6, i)))

			if command == nil then
				return nil, "CommandHistoryGap"
			else
				table.insert(commands, command)
			end
		end

		local packet, v7 = CommandCodec.makePacket(self._mapping.Generation, commands, v4, self._config)

		if packet == nil then
			return nil, v7
		end

		table.insert(packets, packet)
		total += v4
		v3 = Serial.addUInt32(v3, v4)
	end

	return table.freeze(packets), nil
end

return table.freeze(class)