local DestructibleFrame = require(script.Parent.Collision.DestructibleFrame)
local DamageTag = require(script.Parent.DamageTag)
local ActionLockTimeline = require(script.Parent.ActionLockTimeline)
local Mapping = require(script.Parent.Mapping)
local MoverDescriptorCodec = require(script.Parent.MoverDescriptorCodec)
local MoverProgressCodec = require(script.Parent.MoverProgressCodec)
local OwnerSnapshotCodec = require(script.Parent.OwnerSnapshotCodec)
local Quantization = require(script.Parent.Quantization)
local Serial = require(script.Parent.Serial)
local v = {
	Version = 6,
	Kind = table.freeze({
		Mapping = 1,
		Discontinuity = 2,
		DestructibleBaseline = 3,
		DestructibleDelta = 4,
		BaselineRequest = 5,
		MappingRequest = 6,
		MoverBaseline = 7,
		MoverDelta = 8,
		MoverProgress = 9,
		CommandResyncRequest = 10,
		GenerationUnbound = 11,
		DamageTag = 12,
		GrenadeTransitionRequest = 13,
		ActionLocks = 14
	})
}

local function createPayload(value: number, size: number) -- 14 equivalent calls inferred from this helper
	local buf = buffer.create(size + 2)
	buffer.writeu8(buf, 0, 6)
	buffer.writeu8(buf, 1, value)
	return buf
end

local function copyBody(payload: buffer, encoded: buffer) -- 2 equivalent calls inferred from this helper
	buffer.copy(payload, 2, encoded, 0, buffer.len(encoded))
end

local function readBody(buf: buffer, wireSize: number) -- 2 equivalent calls inferred from this helper
	if buffer.len(buf) ~= wireSize + 2 then
		return nil
	end

	local buf2 = buffer.create(wireSize)
	buffer.copy(buf2, 0, buf, 2, wireSize)
	return buf2
end

function v.encodeActionLocks(value: number, data)
	if not (Serial.isNonZeroUInt16(value) and ActionLockTimeline.validate(data)) then
		return nil, "InvalidActionLocks"
	end

	local payload = createPayload(14, #data.Points * 9 + 9) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	buffer.writeu32(payload, 4, data.Revision)
	buffer.writeu8(payload, 8, data.Initial and 1 or 0)
	buffer.writeu16(payload, 9, #data.Points)

	for k, point in data.Points do
		local v2 = 11 + (k - 1) * 9
		buffer.writef64(payload, v2, point.ServerTime)
		buffer.writeu8(payload, v2 + 8, point.Locked and 1 or 0)
	end

	return payload, nil
end

function v.encodeMapping(p)
	local encoded, v2 = Mapping.encode(p)

	if encoded == nil then
		return nil, v2
	end

	local payload = createPayload(1, Mapping.WireSize) -- inferred equivalent call
	copyBody(payload, encoded) -- inferred equivalent call
	return payload, nil
end

function v.encodeDiscontinuity(p)
	local encoded, v2 = OwnerSnapshotCodec.encode(p)

	if encoded == nil then
		return nil, v2
	end

	local payload = createPayload(2, OwnerSnapshotCodec.WireSize) -- inferred equivalent call
	copyBody(payload, encoded) -- inferred equivalent call
	return payload, nil
end

function v.encodeDestructibleBaseline(data, value)
	local v2, v3 = DestructibleFrame.Validate(data.Epoch, data.Revision, data.Count, data.ActiveBits)

	if not v2 then
		return nil, v3
	end

	if data.Epoch > Serial.UInt16Max or data.Count > Serial.UInt16Max or not Serial.isUInt32(value) then
		return nil, "DestructibleBaselineRange"
	end

	local payload = createPayload(3, #data.ActiveBits + 12) -- inferred equivalent call
	buffer.writeu16(payload, 2, data.Epoch)
	buffer.writeu32(payload, 4, data.Revision)
	buffer.writeu32(payload, 8, value)
	buffer.writeu16(payload, 12, data.Count)

	if #data.ActiveBits > 0 then
		buffer.writestring(payload, 14, data.ActiveBits)
	end

	return payload, nil
end

local function validateDelta(p, p2, list)
	if not Serial.isNonZeroUInt16(p) then
		return false, "InvalidDeltaEpoch"
	end

	if not Serial.isUInt32(p2) or p2 == 0 then
		return false, "InvalidDeltaRevision"
	end

	if type(list) ~= "table" or #list < 1 or #list > 1024 then
		return false, "InvalidDeltaCount"
	end

	local v2 = 0

	for _, v3 in list do
		if not Serial.isNonZeroUInt16(v3) or v3 <= v2 then
			return false, "DeltaIndicesNotStrictlySorted"
		end

		v2 = v3
	end

	return true, nil
end

function v.encodeDestructibleDelta(value, value2, value3, list)
	local v2, v3 = validateDelta(value, value2, list)

	if not v2 then
		return nil, v3
	end

	if not Serial.isUInt32(value3) then
		return nil, "InvalidDeltaServerTick"
	end

	local payload = createPayload(4, #list * 2 + 12) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	buffer.writeu32(payload, 4, value2)
	buffer.writeu32(payload, 8, value3)
	buffer.writeu16(payload, 12, #list)
	local total = 14

	for _, value4 in list do
		buffer.writeu16(payload, total, value4)
		total += 2
	end

	return payload, nil
end

function v.encodeBaselineRequest(value, value2)
	if not (Serial.isNonZeroUInt16(value) and Serial.isUInt32(value2)) then
		return nil, "InvalidBaselineRequest"
	end

	local payload = createPayload(5, 6) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	buffer.writeu32(payload, 4, value2)
	return payload, nil
end

function v.encodeMappingRequest(value)
	if not Serial.isNonZeroUInt16(value) then
		return nil, "InvalidMappingRequest"
	end

	local payload = createPayload(6, 2) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	return payload, nil
end

function v.encodeCommandResyncRequest(value, value2)
	if not (Serial.isNonZeroUInt16(value) and Serial.isUInt32(value2)) then
		return nil, "InvalidCommandResyncRequest"
	end

	local payload = createPayload(10, 6) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	buffer.writeu32(payload, 4, value2)
	return payload, nil
end

function v.encodeGenerationUnbound(value)
	if not Serial.isNonZeroUInt16(value) then
		return nil, "InvalidGenerationUnbound"
	end

	local payload = createPayload(11, 2) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	return payload, nil
end

function v.encodeGrenadeTransitionRequest(value, value2, value3, str, str2, p, p2, p3)
	if
		not Serial.isNonZeroUInt16(value)
		or not Serial.isUInt32(value2)
		or not Serial.isUInt32(value3)
		or value3 == 0
		or type(str) ~= "string"
		or #str > 96
		or type(str2) ~= "string"
		or #str2 < 1
		or #str2 > 96
		or p ~= "Far" and p ~= "Near"
		or not (Quantization.isFinite(p2) and Quantization.isFinite(p3))
	then
		return nil, "InvalidGrenadeTransitionRequest"
	end

	local payload = createPayload(13, #str + 16 + #str2) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	buffer.writeu32(payload, 4, value2)
	buffer.writeu32(payload, 8, value3)
	buffer.writeu8(payload, 12, #str)
	buffer.writeu8(payload, 13, #str2)
	buffer.writeu8(payload, 14, p == "Far" and 1 or 2)
	buffer.writeu16(payload, 15, (Quantization.quantizeYaw(p2)))
	buffer.writei8(payload, 17, (Quantization.quantizeSignedUnit(p3)))
	buffer.writestring(payload, 18, str)
	buffer.writestring(payload, #str + 18, str2)
	return payload, nil
end

function v.encodeDamageTag(value, value2, value3)
	if not (Serial.isNonZeroUInt16(value) and Serial.isUInt32(value2) and DamageTag.isValidModifier(value3)) then
		return nil, "InvalidDamageTag"
	end

	local payload = createPayload(12, 10) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	buffer.writeu32(payload, 4, value2)
	buffer.writef32(payload, 8, value3)
	return payload, nil
end

local function validateMoverHeader(p, p2, p3)
	if Serial.isNonZeroUInt16(p) and Serial.isUInt32(p2) and Serial.isUInt32(p3) then
		return true, nil
	end

	return false, "InvalidMoverControlHeader"
end

local function encodeMoverDescriptors(value: number, value2, value3, value4, list, flag: boolean)
	local v2, v3

	if Serial.isNonZeroUInt16(value2) and Serial.isUInt32(value3) and Serial.isUInt32(value4) then
		v2 = true
	else
		v2 = false
		v3 = "InvalidMoverControlHeader"
	end

	if not v2 then
		return nil, v3
	end

	local v4, v5 = MoverDescriptorCodec.validateList(list, flag)

	if not v4 then
		return nil, v5
	end

	local count = #list
	local payload = createPayload(value, 12 + count * MoverDescriptorCodec.DescriptorWireSize) -- inferred equivalent call
	buffer.writeu16(payload, 2, value2)
	buffer.writeu32(payload, 4, value3)
	buffer.writeu32(payload, 8, value4)
	buffer.writeu16(payload, 12, count)
	assert(MoverDescriptorCodec.writeValidated(payload, 14, list) == buffer.len(payload), "mover control size drift")
	return payload, nil
end

function v.encodeMoverBaseline(value, value2, value3, list, options)
	local v2, v3

	if Serial.isNonZeroUInt16(value) and Serial.isUInt32(value2) and Serial.isUInt32(value3) then
		v2 = true
	else
		v2 = false
		v3 = "InvalidMoverControlHeader"
	end

	if not v2 then
		return nil, v3
	end

	local v4, v5 = MoverDescriptorCodec.validateList(list, true)

	if not v4 then
		return nil, v5
	end

	local v6 = options or {}
	local v7, v8 = MoverProgressCodec.validateAnchors(v6, true)

	if not v7 then
		return nil, v8
	end

	local count = #list
	local payload = createPayload( -- inferred equivalent call
		7,
		13 + count * MoverDescriptorCodec.DescriptorWireSize + #v6 * MoverProgressCodec.AnchorWireSize
	)
	buffer.writeu16(payload, 2, value)
	buffer.writeu32(payload, 4, value2)
	buffer.writeu32(payload, 8, value3)
	buffer.writeu16(payload, 12, count)
	local v9 = MoverDescriptorCodec.writeValidated(payload, 14, list)
	buffer.writeu8(payload, v9, #v6)
	local v10 = v9 + 1
	assert(
		MoverProgressCodec.writeAnchorsValidated(payload, v10, v6) == buffer.len(payload),
		"mover baseline control size drift"
	)
	return payload, nil
end

function v.encodeMoverDelta(p, p2, p3, p4)
	return encodeMoverDescriptors(8, p, p2, p3, p4, false)
end

function v.encodeMoverProgress(value, value2, value3, list)
	local v2, v3

	if Serial.isNonZeroUInt16(value) and Serial.isUInt32(value2) and Serial.isUInt32(value3) then
		v2 = true
	else
		v2 = false
		v3 = "InvalidMoverControlHeader"
	end

	if not v2 then
		return nil, v3
	end

	local v4, v5 = MoverProgressCodec.validateStreams(list)

	if not v4 then
		return nil, v5
	end

	local payload = createPayload(9, 11 + MoverProgressCodec.streamsWireSize(list)) -- inferred equivalent call
	buffer.writeu16(payload, 2, value)
	buffer.writeu32(payload, 4, value2)
	buffer.writeu32(payload, 8, value3)
	buffer.writeu8(payload, 12, #list)
	assert(
		MoverProgressCodec.writeStreamsValidated(payload, 13, list) == buffer.len(payload),
		"mover progress control size drift"
	)
	return payload, nil
end

function v.decodeRequest(buf)
	if typeof(buf) ~= "buffer" then
		return nil, "ControlRequestPayload"
	end

	local v2 = buffer.len(buf)

	if v2 < 2 or buffer.readu8(buf, 0) ~= 6 then
		return nil, "ControlRequestHeader"
	end

	local v3 = buffer.readu8(buf, 1)

	if v3 == 5 then
		if v2 ~= 8 then
			return nil, "BaselineRequestSize"
		end

		local epoch = buffer.readu16(buf, 2)
		local knownRevision = buffer.readu32(buf, 4)

		if Serial.isNonZeroUInt16(epoch) then
			return { Kind = "BaselineRequest", Epoch = epoch, KnownRevision = knownRevision }, nil
		end

		return nil, "InvalidBaselineRequest"
	elseif v3 == 6 then
		if v2 ~= 4 then
			return nil, "MappingRequestSize"
		end

		local generation = buffer.readu16(buf, 2)

		if Serial.isNonZeroUInt16(generation) then
			return { Kind = "MappingRequest", Generation = generation }, nil
		end

		return nil, "InvalidMappingRequest"
	elseif v3 == 10 then
		if v2 ~= 8 then
			return nil, "CommandResyncRequestSize"
		end

		local generation = buffer.readu16(buf, 2)
		local discardThroughCommand = buffer.readu32(buf, 4)

		if Serial.isNonZeroUInt16(generation) then
			return
				{
					Kind = "CommandResyncRequest",
					Generation = generation,
					DiscardThroughCommand = discardThroughCommand
				},
				nil
		end

		return nil, "InvalidCommandResyncRequest"
	else
		if v3 ~= 13 then
			return nil, "ControlRequestKind"
		end

		if v2 < 19 then
			return nil, "GrenadeTransitionRequestSize"
		end

		local generation = buffer.readu16(buf, 2)
		local commandNumber = buffer.readu32(buf, 4)
		local requestId = buffer.readu32(buf, 8)
		local v4 = buffer.readu8(buf, 12)
		local v5 = buffer.readu8(buf, 13)
		local v6 = buffer.readu8(buf, 14)
		local dequantizeYaw = Quantization.dequantizeYaw((buffer.readu16(buf, 15)))
		local dequantizeSignedUnit = Quantization.dequantizeSignedUnit((buffer.readi8(buf, 17)))

		if
			Serial.isNonZeroUInt16(generation)
			and requestId ~= 0
			and not (v4 > 96)
			and not (v5 < 1)
			and not (v5 > 96)
			and (v6 == 1 or v6 == 2)
			and v2 == v4 + 18 + v5
		then
			return {
				Kind = "GrenadeTransitionRequest",
				Generation = generation,
				CommandNumber = commandNumber,
				RequestId = requestId,
				TargetIdentifier = buffer.readstring(buf, 18, v4),
				GrenadeIdentifier = buffer.readstring(buf, v4 + 18, v5),
				Animation = v6 == 1 and "Far" or "Near",
				LookYaw = dequantizeYaw,
				VerticalLook = dequantizeSignedUnit
			}, nil
		end

		return nil, "InvalidGrenadeTransitionRequest"
	end
end

function v.decode(p)
	if typeof(p) ~= "buffer" or buffer.len(p) < 2 then
		return nil, "ControlPayload"
	end

	if buffer.readu8(p, 0) ~= 6 then
		return nil, "ControlVersion"
	end

	local v2 = buffer.readu8(p, 1)

	if v2 == 1 then
		local buf = readBody(p, Mapping.WireSize) -- inferred equivalent call

		if buf == nil then
			return nil, "MappingControlSize"
		end

		local decoded, v3 = Mapping.decode(buf)

		if decoded == nil then
			return nil, v3
		end

		return { Kind = "Mapping", Mapping = decoded }, nil
	elseif v2 == 2 then
		local buf = readBody(p, OwnerSnapshotCodec.WireSize) -- inferred equivalent call

		if buf == nil then
			return nil, "DiscontinuityControlSize"
		end

		local decoded, v3 = OwnerSnapshotCodec.decode(buf)

		if decoded == nil then
			return nil, v3
		end

		return { Kind = "Discontinuity", Snapshot = decoded }, nil
	elseif v2 == 3 then
		if buffer.len(p) < 14 then
			return nil, "BaselineControlSize"
		end

		local v3 = buffer.readu16(p, 2)
		local v4 = buffer.readu32(p, 4)
		local serverTick = buffer.readu32(p, 8)
		local v5 = buffer.readu16(p, 12)
		local v6 = math.ceil(v5 / 8)

		if buffer.len(p) ~= v6 + 14 then
			return nil, "BaselineControlSize"
		end

		local v7 = not (v6 > 0) and "" or buffer.readstring(p, 14, v6)
		local v8, v9 = DestructibleFrame.Validate(v3, v4, v5, v7)

		if v8 then
			return
				{
					Kind = "DestructibleBaseline",
					ServerTick = serverTick,
					Frame = DestructibleFrame.New(v3, v4, v5, v7)
				},
				nil
		end

		return nil, v9
	elseif v2 == 4 then
		if buffer.len(p) < 14 then
			return nil, "DeltaControlSize"
		end

		local epoch = buffer.readu16(p, 2)
		local revision = buffer.readu32(p, 4)
		local serverTick = buffer.readu32(p, 8)
		local v3 = buffer.readu16(p, 12)

		if v3 < 1 or v3 > 1024 or buffer.len(p) ~= v3 * 2 + 14 then
			return nil, "DeltaControlSize"
		end

		local indices = table.create(v3)
		local total = 14

		for i = 1, v3 do
			indices[i] = buffer.readu16(p, total)
			total += 2
		end

		local v4, v5 = validateDelta(epoch, revision, indices)

		if v4 then
			return {
				Kind = "DestructibleDelta",
				Epoch = epoch,
				Revision = revision,
				ServerTick = serverTick,
				Indices = indices
			}, nil
		end

		return nil, v5
	else
		if v2 == 5 or v2 == 6 or v2 == 10 or v2 == 13 then
			return v.decodeRequest(p)
		end

		if v2 == 11 then
			if buffer.len(p) ~= 4 then
				return nil, "GenerationUnboundSize"
			end

			local generation = buffer.readu16(p, 2)

			if Serial.isNonZeroUInt16(generation) then
				return { Kind = "GenerationUnbound", Generation = generation }, nil
			end

			return nil, "InvalidGenerationUnbound"
		elseif v2 == 14 then
			if buffer.len(p) < 11 then
				return nil, "ActionLocksSize"
			end

			local generation = buffer.readu16(p, 2)
			local v3 = buffer.readu8(p, 8)
			local v4 = buffer.readu16(p, 9)

			if not Serial.isNonZeroUInt16(generation) or v3 > 1 or ActionLockTimeline.MaxPoints < v4 then
				return nil, "InvalidActionLocks"
			end

			if buffer.len(p) ~= v4 * 9 + 11 then
				return nil, "ActionLocksSize"
			end

			local points = table.create(v4)

			for i = 1, v4 do
				local v5 = (i - 1) * 9 + 11
				local v6 = buffer.readu8(p, v5 + 8)

				if v6 > 1 then
					return nil, "InvalidActionLocks"
				else
					points[i] = {
						ServerTime = buffer.readf64(p, v5),
						Locked = v6 == 1
					}
				end
			end

			local history = {
				Revision = buffer.readu32(p, 4),
				Initial = v3 == 1,
				Points = points
			}

			if ActionLockTimeline.validate(history) then
				return { Kind = "ActionLocks", Generation = generation, History = history }, nil
			end

			return nil, "InvalidActionLocks"
		elseif v2 == 12 then
			if buffer.len(p) ~= 12 then
				return nil, "DamageTagSize"
			end

			local generation = buffer.readu16(p, 2)
			local applyMovementTick = buffer.readu32(p, 4)
			local velocityModifier = buffer.readf32(p, 8)

			if Serial.isNonZeroUInt16(generation) and DamageTag.isValidModifier(velocityModifier) then
				return
					{
						Kind = "DamageTag",
						Generation = generation,
						ApplyMovementTick = applyMovementTick,
						VelocityModifier = velocityModifier
					},
					nil
			end

			return nil, "InvalidDamageTag"
		elseif v2 == 7 then
			if buffer.len(p) < 15 then
				return nil, "MoverControlSize"
			end

			local epoch = buffer.readu16(p, 2)
			local revision = buffer.readu32(p, 4)
			local serverTick = buffer.readu32(p, 8)
			local v3 = buffer.readu16(p, 12)
			local v4 = v3 * MoverDescriptorCodec.DescriptorWireSize
			local v5 = 14 + v4

			if
				not (Serial.isNonZeroUInt16(epoch) and Serial.isUInt32(revision) and Serial.isUInt32(serverTick))
				or buffer.len(p) <= v5
			then
				return nil, "MoverControlSize"
			end

			local buf = buffer.create(v4)

			if v4 > 0 then
				buffer.copy(buf, 0, p, 14, v4)
			end

			local list, v6, v7 = MoverDescriptorCodec.readList(buf, 0, v3)

			if list == nil then
				return nil, v7
			end

			assert(v6 == v4, "mover baseline descriptor decode size drift")
			local v8 = buffer.readu8(p, v5)
			local v9 = v5 + 1 + v8 * MoverProgressCodec.AnchorWireSize

			if buffer.len(p) ~= v9 then
				return nil, "MoverProgressAnchorPayloadSize"
			end

			local anchors, v10, v11 = MoverProgressCodec.readAnchors(p, v5 + 1, v8)

			if anchors == nil then
				return nil, v11
			end

			assert(v10 == buffer.len(p), "mover baseline control decode size drift")
			return {
				Kind = "MoverBaseline",
				Epoch = epoch,
				Revision = revision,
				ServerTick = serverTick,
				Descriptors = list,
				ProgressAnchors = anchors
			}, nil
		elseif v2 == 8 then
			if buffer.len(p) < 14 then
				return nil, "MoverControlSize"
			end

			local epoch = buffer.readu16(p, 2)
			local revision = buffer.readu32(p, 4)
			local serverTick = buffer.readu32(p, 8)
			local v3 = buffer.readu16(p, 12)

			if
				not (Serial.isNonZeroUInt16(epoch) and Serial.isUInt32(revision) and Serial.isUInt32(serverTick))
				or v3 == 0
				or buffer.len(p) ~= 14 + v3 * MoverDescriptorCodec.DescriptorWireSize
			then
				return nil, "MoverControlSize"
			end

			local list, v4, v5 = MoverDescriptorCodec.readList(p, 14, v3)

			if list == nil then
				return nil, v5
			end

			assert(v4 == buffer.len(p), "mover control decode size drift")
			return {
				Kind = "MoverDelta",
				Epoch = epoch,
				Revision = revision,
				ServerTick = serverTick,
				Descriptors = list
			}, nil
		else
			if v2 ~= 9 then
				return nil, "ControlKind"
			end

			if buffer.len(p) < 21 then
				return nil, "MoverProgressPayloadSize"
			end

			local epoch = buffer.readu16(p, 2)
			local revision = buffer.readu32(p, 4)
			local serverTick = buffer.readu32(p, 8)
			local v3 = buffer.readu8(p, 12)

			if not (Serial.isNonZeroUInt16(epoch) and Serial.isUInt32(revision) and Serial.isUInt32(serverTick)) then
				return nil, "InvalidMoverControlHeader"
			end

			local streams, v4, v5 = MoverProgressCodec.readStreams(p, 13, v3)

			if streams == nil then
				return nil, v5
			end

			if v4 == buffer.len(p) then
				return {
					Kind = "MoverProgress",
					Epoch = epoch,
					Revision = revision,
					ServerTick = serverTick,
					Streams = streams
				}, nil
			end

			return nil, "MoverProgressPayloadSize"
		end
	end
end

return table.freeze(v)