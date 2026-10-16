local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
require(script.Parent.RuntimeTypes)

local function newerFeedback(lastOwnerCommandFeedback, data)
	local v

	if data == nil or data.Generation ~= lastOwnerCommandFeedback.Generation then
		return true
	else
		v = Serial.isNewerUInt32(lastOwnerCommandFeedback.Sequence, data.Sequence)

		if v then
			if
				Serial.deltaUInt32(lastOwnerCommandFeedback.ServerTick, data.ServerTick) >= 0
				and Serial.deltaUInt32(lastOwnerCommandFeedback.LastProcessedCommand, data.LastProcessedCommand) >= 0
				and Serial.deltaUInt32(
					lastOwnerCommandFeedback.Topology.DestructibleRevision,
					data.Topology.DestructibleRevision
				) >= 0
			then
				return Serial.deltaUInt32(lastOwnerCommandFeedback.Topology.MoverRevision, data.Topology.MoverRevision) >= 0
			else
				return false
			end
		end
	end

	return v
end

local v = {
	observe = function(self, lastOwnerCommandFeedback, p: number)
		local mapping = self._mapping

		if
			mapping == nil
			or lastOwnerCommandFeedback.Generation ~= mapping.Generation
			or lastOwnerCommandFeedback.Topology.Epoch ~= mapping.TopologyEpoch
			or lastOwnerCommandFeedback.Topology.Fingerprint ~= mapping.TopologyFingerprint
			or not (newerFeedback(lastOwnerCommandFeedback, self._lastAcceptedOwnerSnapshot) and newerFeedback(
				lastOwnerCommandFeedback,
				self._lastOwnerCommandFeedback
			))
		then
			return
		end

		self._lastOwnerCommandFeedback = lastOwnerCommandFeedback
		local commandClock = self._commandClock

		if commandClock ~= nil then
			commandClock:observe(lastOwnerCommandFeedback.BufferDepth, p)
		end

		self._diagnostics:recordOwnerFeedback(lastOwnerCommandFeedback)
	end
}

local function consider(data, data2)
	if
		data2 == nil
		or data2.Generation ~= data.Generation
		or data2.LastProcessedCommand ~= data.LastProcessedCommand
		or data2.Topology.Epoch ~= data.Topology.Epoch
		or data2.Topology.Fingerprint ~= data.Topology.Fingerprint
		or not (Serial.isNewerUInt32(data2.Sequence, data.Sequence) and Serial.deltaUInt32(data2.ServerTick, data.ServerTick) >= 0)
	then
		return data
	end

	return data2
end

function v.choose(p, p2, p3)
	if p == nil then
		return nil
	end

	return (consider(consider(p, p3), p2))
end

return table.freeze(v)