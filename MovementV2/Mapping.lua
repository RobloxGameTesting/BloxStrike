local Config = require(script.Parent.Config)
local Serial = require(script.Parent.Serial)
require(script.Parent.Types)
local v = {
	Version = 2,
	WireSize = 16,
	clone = function(data)
		return {
			Generation = data.Generation,
			ActorId = data.ActorId,
			SimulationHz = data.SimulationHz,
			TopologyEpoch = data.TopologyEpoch,
			TopologyFingerprint = data.TopologyFingerprint,
			PlayerCollisionsEnabled = data.PlayerCollisionsEnabled
		}
	end,
	validate = function(data)
		if typeof(data) ~= "table" then
			return false, "MappingNotTable"
		end

		if not Serial.isNonZeroUInt16(data.Generation) then
			return false, "InvalidGeneration"
		end

		if not Serial.isUInt32(data.ActorId) or data.ActorId == 0 then
			return false, "InvalidActorId"
		end

		if
			typeof(data.SimulationHz) ~= "number"
			or data.SimulationHz % 1 ~= 0
			or data.SimulationHz < Config.MinSimulationHz
			or data.SimulationHz > Config.MaxSimulationHz
		then
			return false, "InvalidSimulationHz"
		end

		if not Serial.isNonZeroUInt16(data.TopologyEpoch) then
			return false, "InvalidTopologyEpoch"
		end

		if not Serial.isUInt32(data.TopologyFingerprint) then
			return false, "InvalidTopologyFingerprint"
		end

		if typeof(data.PlayerCollisionsEnabled) == "boolean" then
			return true, nil
		end

		return false, "InvalidPlayerCollisionsEnabled"
	end
}

function v.encode(data)
	local v2, v3 = v.validate(data)

	if not v2 then
		return nil, v3
	end

	local buf = buffer.create(16)
	buffer.writeu8(buf, 0, 2)
	buffer.writeu16(buf, 1, data.Generation)
	buffer.writeu32(buf, 3, data.ActorId)
	buffer.writeu16(buf, 7, data.SimulationHz)
	buffer.writeu16(buf, 9, data.TopologyEpoch)
	buffer.writeu32(buf, 11, data.TopologyFingerprint)
	buffer.writeu8(buf, 15, data.PlayerCollisionsEnabled and 1 or 0)
	return buf, nil
end

function v.decode(buf)
	if typeof(buf) ~= "buffer" then
		return nil, "MappingPayloadNotBuffer"
	end

	if buffer.len(buf) ~= 16 then
		return nil, "MappingPayloadSize"
	end

	if buffer.readu8(buf, 0) ~= 2 then
		return nil, "MappingVersion"
	end

	local v2 = buffer.readu8(buf, 15)

	if v2 > 1 then
		return nil, "InvalidPlayerCollisionsEnabled"
	end

	local v3 = {
		Generation = buffer.readu16(buf, 1),
		ActorId = buffer.readu32(buf, 3),
		SimulationHz = buffer.readu16(buf, 7),
		TopologyEpoch = buffer.readu16(buf, 9),
		TopologyFingerprint = buffer.readu32(buf, 11),
		PlayerCollisionsEnabled = v2 == 1
	}
	local v4, v5 = v.validate(v3)

	if v4 then
		return v3, nil
	end

	return nil, v5
end

return table.freeze(v)