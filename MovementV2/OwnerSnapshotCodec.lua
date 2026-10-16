local Enums = require(script.Parent.Enums)
local Quantization = require(script.Parent.Quantization)
local Serial = require(script.Parent.Serial)
local StateCodec = require(script.Parent.StateCodec)
require(script.Parent.Types)
local v = {}
local wireSize = 68 + StateCodec.WireSize
v.Version = 8
v.HeaderSize = 68
v.WireSize = wireSize
local isVector3Within = Quantization.isVector3Within
local writeVector3F32 = Quantization.writeVector3F32
local readVector3F32 = Quantization.readVector3F32

local function validateTopology(topology)
	if typeof(topology) ~= "table" then
		return false, "TopologyNotTable"
	end

	if not Serial.isNonZeroUInt16(topology.Epoch) then
		return false, "InvalidTopologyEpoch"
	end

	if not Serial.isUInt32(topology.Fingerprint) then
		return false, "InvalidTopologyFingerprint"
	end

	if not Serial.isUInt32(topology.DestructibleRevision) then
		return false, "InvalidDestructibleRevision"
	end

	if Serial.isUInt32(topology.MoverRevision) then
		return true, nil
	end

	return false, "InvalidMoverRevision"
end

local function validateSupport(data)
	if typeof(data) ~= "table" then
		return false, "SupportNotTable"
	end

	if
		typeof(data.Kind) ~= "number"
		or data.Kind % 1 ~= 0
		or data.Kind < Enums.SupportKind.None
		or data.Kind > Enums.SupportKind.Max
	then
		return false, "InvalidSupportKind"
	end

	if not Serial.isUInt32(data.SourceId) then
		return false, "InvalidSupportSourceId"
	end

	if (data.Kind == Enums.SupportKind.None) ~= (data.SourceId == 0) then
		return false, "InvalidEmptySupport"
	end

	if not isVector3Within(data.Anchor, 1000000) then
		return false, "InvalidSupportAnchor"
	end

	if not isVector3Within(data.Velocity, 100000) then
		return false, "InvalidSupportVelocity"
	end

	if data.Kind == Enums.SupportKind.None and (data.Anchor.Magnitude > 0 or data.Velocity.Magnitude > 0) then
		return false, "NonCanonicalEmptySupport"
	end

	return true, nil
end

local function validateSnapshot(data, flag: boolean)
	if typeof(data) ~= "table" then
		return false, "SnapshotNotTable"
	end

	if not Serial.isNonZeroUInt16(data.Generation) then
		return false, "InvalidGeneration"
	end

	if not Serial.isUInt32(data.Sequence) then
		return false, "InvalidSnapshotSequence"
	end

	if not Serial.isUInt32(data.ServerTick) then
		return false, "InvalidServerTick"
	end

	if
		typeof(data.ServerTime) ~= "number"
		or data.ServerTime ~= data.ServerTime
		or math.abs(data.ServerTime) == 1e999
	then
		return false, "InvalidServerTime"
	end

	if not Serial.isUInt32(data.LastProcessedCommand) then
		return false, "InvalidLastProcessedCommand"
	end

	if
		typeof(data.Flags) ~= "number"
		or data.Flags % 1 ~= 0
		or data.Flags < 0
		or bit32.band(data.Flags, (bit32.bnot(Enums.OwnerSnapshotFlags.ValidMask))) ~= 0
	then
		return false, "InvalidSnapshotFlags"
	end

	if
		typeof(data.BufferDepth) ~= "number"
		or data.BufferDepth % 1 ~= 0
		or data.BufferDepth < -128
		or data.BufferDepth > 127
	then
		return false, "InvalidBufferDepth"
	end

	if not flag then
		local v2, v3 = StateCodec.validate(data.State)

		if not v2 then
			return false, v3
		end
	end

	local v2, v3 = validateTopology(data.Topology)

	if not v2 then
		return false, v3
	end

	local v4, v5 = validateSupport(data.Support)

	if not v4 then
		return false, v5
	end

	if data.State.OnGround == (data.Support.Kind ~= Enums.SupportKind.None) then
		return true, nil
	end

	return false, "GroundSupportMismatch"
end

function v.validate(p)
	return validateSnapshot(p, false)
end

function v.canonicalizeSupport(data)
	local v2, v3 = validateSupport(data)

	if not v2 then
		return nil, v3
	end

	local buf = buffer.create(24)
	writeVector3F32(buf, writeVector3F32(buf, 0, data.Anchor), data.Velocity)
	local anchor, v4 = readVector3F32(buf, 0)
	local velocity, v5 = readVector3F32(buf, v4)
	assert(v5 == 24, "support canonicalization size drift")
	return { Kind = data.Kind, SourceId = data.SourceId, Anchor = anchor, Velocity = velocity }, nil
end

function v.encode(data)
	local v2, v3 = v.validate(data)

	if not v2 then
		return nil, v3
	end

	local buf = buffer.create(wireSize)
	local v4 = 0
	buffer.writeu8(buf, v4, 8)
	local v5 = v4 + 1
	buffer.writeu8(buf, v5, data.Flags)
	local v6 = v5 + 1
	buffer.writeu16(buf, v6, data.Generation)
	local v7 = v6 + 2
	buffer.writeu32(buf, v7, data.Sequence)
	local v8 = v7 + 4
	buffer.writeu32(buf, v8, data.ServerTick)
	local v9 = v8 + 4
	buffer.writef64(buf, v9, data.ServerTime)
	local v10 = v9 + 8
	buffer.writeu32(buf, v10, data.LastProcessedCommand)
	local v11 = v10 + 4
	buffer.writei8(buf, v11, data.BufferDepth)
	local v12 = v11 + 1
	buffer.writeu16(buf, v12, data.Topology.Epoch)
	local v13 = v12 + 2
	buffer.writeu32(buf, v13, data.Topology.Fingerprint)
	local v14 = v13 + 4
	buffer.writeu32(buf, v14, data.Topology.DestructibleRevision)
	local v15 = v14 + 4
	buffer.writeu32(buf, v15, data.Topology.MoverRevision)
	local v16 = v15 + 4
	buffer.writeu8(buf, v16, data.Support.Kind)
	local v17 = v16 + 1
	buffer.writeu32(buf, v17, data.Support.SourceId)
	local v18 = writeVector3F32(buf, writeVector3F32(buf, v17 + 4, data.Support.Anchor), data.Support.Velocity)
	assert(v18 == 68, "MovementV2 owner snapshot header size drift")
	StateCodec.writeValidated(buf, v18, data.State)
	return buf, nil
end

function v.decode(buf)
	if typeof(buf) ~= "buffer" then
		return nil, "SnapshotPayloadNotBuffer"
	end

	if buffer.len(buf) ~= wireSize then
		return nil, "SnapshotPayloadSize"
	end

	local v2 = 0

	if buffer.readu8(buf, v2) ~= 8 then
		return nil, "SnapshotVersion"
	end

	local v3 = v2 + 1
	local flags = buffer.readu8(buf, v3)
	local v4 = v3 + 1
	local generation = buffer.readu16(buf, v4)
	local v5 = v4 + 2
	local sequence = buffer.readu32(buf, v5)
	local v6 = v5 + 4
	local serverTick = buffer.readu32(buf, v6)
	local v7 = v6 + 4
	local serverTime = buffer.readf64(buf, v7)
	local v8 = v7 + 8
	local lastProcessedCommand = buffer.readu32(buf, v8)
	local v9 = v8 + 4
	local bufferDepth = buffer.readi8(buf, v9)
	local v10 = v9 + 1
	local topology = {
		Epoch = buffer.readu16(buf, v10),
		Fingerprint = buffer.readu32(buf, v10 + 2),
		DestructibleRevision = buffer.readu32(buf, v10 + 6),
		MoverRevision = buffer.readu32(buf, v10 + 10)
	}
	local v11 = v10 + 14
	local kind = buffer.readu8(buf, v11)
	local v12 = v11 + 1
	local sourceId = buffer.readu32(buf, v12)
	local anchor, v13 = readVector3F32(buf, v12 + 4)
	local velocity, v14 = readVector3F32(buf, v13)
	assert(v14 == 68, "MovementV2 owner snapshot header size drift")
	local decodeFrom, v15, v16 = StateCodec.decodeFrom(buf, v14)

	if decodeFrom == nil then
		return nil, v16
	end

	assert(v15 == wireSize, "MovementV2 owner snapshot state size drift")
	local v17 = {
		Generation = generation,
		Sequence = sequence,
		ServerTick = serverTick,
		ServerTime = serverTime,
		LastProcessedCommand = lastProcessedCommand,
		Flags = flags,
		BufferDepth = bufferDepth,
		State = decodeFrom,
		Topology = topology,
		Support = { Kind = kind, SourceId = sourceId, Anchor = anchor, Velocity = velocity }
	}
	local v18, v19 = validateSnapshot(v17, true)

	if v18 then
		return v17, nil
	end

	return nil, v19
end

return table.freeze(v)