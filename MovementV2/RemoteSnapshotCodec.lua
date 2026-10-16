--!native
local createVector = vector.create
local Enums = require(script.Parent.Enums)
local RemoteActorIdentity = require(script.Parent.RemoteActorIdentity)
local Quantization = require(script.Parent.Quantization)
local Serial = require(script.Parent.Serial)
require(script.Parent.Types)
local v = {}
local buf = buffer.create(4)
v.Version = 6
v.HeaderSize = 29
v.MaxRecordsPerPacket = 22
v.MaxWireSize = 975

local function vectorWithin(data, p: number) -- 5 equivalent calls inferred from this helper
	local finiteVector3 = Quantization.isFiniteVector3(data)

	if finiteVector3 then
		if math.abs(data.X) <= p and math.abs(data.Y) <= p then
			finiteVector3 = math.abs(data.Z) <= p
		else
			finiteVector3 = false
		end
	end

	return finiteVector3
end

local function validateSupport(supportKind, supportSourceId) -- 2 equivalent calls inferred from this helper
	return typeof(supportKind) == "number"
		and supportKind % 1 == 0
		and Enums.SupportKind.None <= supportKind
		and supportKind <= Enums.SupportKind.Max
		and Serial.isUInt32(supportSourceId)
		and (supportKind == Enums.SupportKind.None) == (supportSourceId == 0)
end

local function canonicalFloat32(value: number) -- 3 equivalent calls inferred from this helper
	buffer.writef32(buf, 0, value)
	return (buffer.readf32(buf, 0))
end

local function canonicalVector3(position: Vector3) -- 1 equivalent call inferred from this helper
	local v2 = canonicalFloat32(position.X) -- inferred equivalent call
	local v3 = canonicalFloat32(position.Y) -- inferred equivalent call
	local z = position.Z
	return (Vector3.new(v2, v3, canonicalFloat32(z))) -- inferred equivalent call
end

local function quantizeVelocity(p: number) -- 6 equivalent calls inferred from this helper
	return (math.clamp(math.round(p * 8), -32767, 32767))
end

local function canonicalVelocity(velocity: Vector3) -- 1 equivalent call inferred from this helper
	return (Vector3.new(
		quantizeVelocity(velocity.X) / 8, -- inferred equivalent call
		quantizeVelocity(velocity.Y) / 8, -- inferred equivalent call
		quantizeVelocity(velocity.Z) / 8 -- inferred equivalent call
	))
end

function v.validateActor(data)
	if typeof(data) ~= "table" then
		return false, "ActorNotTable"
	end

	if type(data.UserId) ~= "number" or data.UserId % 1 ~= 0 or data.UserId < 0 or data.UserId > 9007199254740991 then
		return false, "InvalidActorUserId"
	end

	if not Serial.isNonZeroUInt16(data.Generation) then
		return false, "InvalidActorGeneration"
	end

	if not Serial.isUInt32(data.ActorId) or data.ActorId == 0 then
		return false, "InvalidActorId"
	end

	if not vectorWithin(data.Position, 1000000) then -- inferred equivalent call
		return false, "InvalidActorPosition"
	end

	if not vectorWithin(data.Velocity, 100000) then -- inferred equivalent call
		return false, "InvalidActorVelocity"
	end

	if not Quantization.isFinite(data.LookYaw) then
		return false, "InvalidActorLookYaw"
	end

	if not Quantization.isFinite(data.VerticalLook) or data.VerticalLook < -1 or data.VerticalLook > 1 then
		return false, "InvalidActorVerticalLook"
	end

	if data.MovementMode ~= "Walking" and data.MovementMode ~= "Ladder" then
		return false, "InvalidActorMovementMode"
	end

	if data.Stance ~= "Standing" and data.Stance ~= "Ducking" then
		return false, "InvalidActorStance"
	end

	if typeof(data.OnGround) ~= "boolean" then
		return false, "InvalidActorOnGround"
	end

	if not Quantization.isFinite(data.DuckAmount) or data.DuckAmount < 0 or data.DuckAmount > 1 then
		return false, "InvalidActorDuckAmount"
	end

	if not validateSupport(data.SupportKind, data.SupportSourceId) then -- inferred equivalent call
		return false, "InvalidActorSupport"
	end

	if data.OnGround == (data.SupportKind ~= Enums.SupportKind.None) then
		return true, nil
	end

	return false, "ActorGroundSupportMismatch"
end

function v.canonicalizeActor(data)
	local v2, v3 = v.validateActor(data)

	if not v2 then
		return nil, v3
	end

	return {
		UserId = data.UserId,
		ActorId = data.ActorId,
		Generation = data.Generation,
		Position = canonicalVector3(data.Position), -- inferred equivalent call
		Velocity = canonicalVelocity(data.Velocity), -- inferred equivalent call
		LookYaw = Quantization.dequantizeYaw(Quantization.quantizeYaw(data.LookYaw)),
		VerticalLook = Quantization.dequantizeSignedUnit(Quantization.quantizeSignedUnit(data.VerticalLook)),
		MovementMode = data.MovementMode,
		Stance = data.Stance,
		OnGround = data.OnGround,
		DuckAmount = Quantization.dequantizeUnitByte(Quantization.quantizeUnitByte(data.DuckAmount)),
		SupportKind = data.SupportKind,
		SupportSourceId = data.SupportSourceId
	}, nil
end

local function optionalPresent(p)
	return p ~= nil
end

function v.validateDelta(data)
	if typeof(data) ~= "table" then
		return false, "RemoteDeltaNotTable"
	end

	if not Serial.isUInt32(data.ActorId) or data.ActorId == 0 then
		return false, "InvalidRemoteDeltaActorId"
	end

	local fieldMask = data.FieldMask

	if
		type(fieldMask) ~= "number"
		or fieldMask % 1 ~= 0
		or fieldMask == 0
		or bit32.band(fieldMask, 4294967168) ~= 0
	then
		return false, "InvalidRemoteDeltaFieldMask"
	end

	local v2 = bit32.band(fieldMask, 1) ~= 0
	local v3 = data.PositionDelta ~= nil
	local v4 = data.AbsolutePosition ~= nil

	if v2 ~= (v3 or v4) or v3 and v4 then
		return false, "InvalidRemoteDeltaPositionPresence"
	end

	if v3 and not vectorWithin(data.PositionDelta, 32767 / 512) then -- inferred equivalent call
		return false, "InvalidRemoteDeltaPosition"
	end

	if v4 and not vectorWithin(data.AbsolutePosition, 1000000) then -- inferred equivalent call
		return false, "InvalidRemoteDeltaAbsolutePosition"
	end

	local v5 = bit32.band(fieldMask, 2) ~= 0

	if v5 ~= (data.Velocity ~= nil) then
		return false, "InvalidRemoteDeltaVelocityPresence"
	end

	if v5 and not vectorWithin(data.Velocity, 100000) then -- inferred equivalent call
		return false, "InvalidRemoteDeltaVelocity"
	end

	local v6 = bit32.band(fieldMask, 4) ~= 0

	if v6 ~= (data.LookYaw ~= nil) then
		return false, "InvalidRemoteDeltaLookYawPresence"
	end

	if v6 and not Quantization.isFinite(data.LookYaw) then
		return false, "InvalidRemoteDeltaLookYaw"
	end

	local v7 = bit32.band(fieldMask, 8) ~= 0

	if v7 ~= (data.VerticalLook ~= nil) then
		return false, "InvalidRemoteDeltaVerticalLookPresence"
	end

	if v7 and (not Quantization.isFinite(data.VerticalLook) or data.VerticalLook < -1 or data.VerticalLook > 1) then
		return false, "InvalidRemoteDeltaVerticalLook"
	end

	local v8 = bit32.band(fieldMask, 16) ~= 0

	if v8 ~= (data.MovementMode ~= nil and data.Stance ~= nil and data.OnGround ~= nil) then
		return false, "InvalidRemoteDeltaMovementPresence"
	end

	if v8 then
		if data.MovementMode ~= "Walking" and data.MovementMode ~= "Ladder" then
			return false, "InvalidRemoteDeltaMovementMode"
		end

		if data.Stance ~= "Standing" and data.Stance ~= "Ducking" then
			return false, "InvalidRemoteDeltaStance"
		end

		if typeof(data.OnGround) ~= "boolean" then
			return false, "InvalidRemoteDeltaOnGround"
		end
	elseif data.MovementMode ~= nil or data.Stance ~= nil or data.OnGround ~= nil then
		return false, "InvalidRemoteDeltaMovementPresence"
	end

	local v9 = bit32.band(fieldMask, 32) ~= 0

	if v9 ~= (data.DuckAmount ~= nil) then
		return false, "InvalidRemoteDeltaDuckPresence"
	end

	if v9 and (not Quantization.isFinite(data.DuckAmount) or data.DuckAmount < 0 or data.DuckAmount > 1) then
		return false, "InvalidRemoteDeltaDuckAmount"
	end

	local v10 = bit32.band(fieldMask, 64) ~= 0

	if v10 ~= (data.SupportKind ~= nil and data.SupportSourceId ~= nil) then
		return false, "InvalidRemoteDeltaSupportPresence"
	end

	if v10 and not validateSupport(data.SupportKind, data.SupportSourceId) then -- inferred equivalent call
		return false, "InvalidRemoteDeltaSupport"
	end

	if v10 or data.SupportKind == nil and data.SupportSourceId == nil then
		return true, nil
	end

	return false, "InvalidRemoteDeltaSupportPresence"
end

local function quantizedPositionDelta(position: Vector3, position2: Vector3)
	local vector = position - position2
	local v2 = math.round(vector.X * 512)
	local v3 = math.round(vector.Y * 512)
	local v4 = math.round(vector.Z * 512)

	if math.abs(v2) <= 32767 and math.abs(v3) <= 32767 and math.abs(v4) <= 32767 then
		return Vector3.new(v2 / 512, v3 / 512, v4 / 512), nil
	end

	return nil, position
end

function v.deltaFromCanonicalBaseline(data, data2)
	if data.UserId ~= data2.UserId or data.ActorId ~= data2.ActorId or data.Generation ~= data2.Generation then
		return nil, "RemoteDeltaIdentityMismatch"
	end

	local v2 = {
		ActorId = data.ActorId,
		FieldMask = 0,
		PositionDelta = nil,
		AbsolutePosition = nil,
		Velocity = nil,
		LookYaw = nil,
		VerticalLook = nil,
		MovementMode = nil,
		Stance = nil,
		OnGround = nil,
		DuckAmount = nil,
		SupportKind = nil,
		SupportSourceId = nil
	}

	if data.Position ~= data2.Position then
		local vector, absolutePosition = quantizedPositionDelta(data.Position, data2.Position)

		if absolutePosition ~= nil or vector ~= createVector(0, 0, 0) then
			v2.FieldMask = bit32.bor(v2.FieldMask, 1)
			v2.PositionDelta = vector
			v2.AbsolutePosition = absolutePosition
		end
	end

	if data.Velocity ~= data2.Velocity then
		v2.FieldMask = bit32.bor(v2.FieldMask, 2)
		v2.Velocity = data.Velocity
	end

	if data.LookYaw ~= data2.LookYaw then
		v2.FieldMask = bit32.bor(v2.FieldMask, 4)
		v2.LookYaw = data.LookYaw
	end

	if data.VerticalLook ~= data2.VerticalLook then
		v2.FieldMask = bit32.bor(v2.FieldMask, 8)
		v2.VerticalLook = data.VerticalLook
	end

	if data.MovementMode ~= data2.MovementMode or data.Stance ~= data2.Stance or data.OnGround ~= data2.OnGround then
		v2.FieldMask = bit32.bor(v2.FieldMask, 16)
		v2.MovementMode = data.MovementMode
		v2.Stance = data.Stance
		v2.OnGround = data.OnGround
	end

	if data.DuckAmount ~= data2.DuckAmount then
		v2.FieldMask = bit32.bor(v2.FieldMask, 32)
		v2.DuckAmount = data.DuckAmount
	end

	if data.SupportKind ~= data2.SupportKind or data.SupportSourceId ~= data2.SupportSourceId then
		v2.FieldMask = bit32.bor(v2.FieldMask, 64)
		v2.SupportKind = data.SupportKind
		v2.SupportSourceId = data.SupportSourceId
	end

	if v2.FieldMask == 0 then
		return nil, nil
	end

	local v3, v4 = v.validateDelta(v2)

	if v3 then
		return v2, nil
	end

	return nil, v4
end

function v.applyDeltaToCanonicalBaseline(data, data2, flag: boolean?)
	if not flag then
		local v2, v3 = v.validateDelta(data2)

		if not v2 then
			return nil, v3
		end
	end

	if data2.ActorId ~= data.ActorId then
		return nil, "RemoteDeltaIdentityMismatch"
	end

	local v2 = {
		UserId = data.UserId,
		ActorId = data.ActorId,
		Generation = data.Generation,
		Position = data.Position,
		Velocity = data.Velocity,
		LookYaw = data.LookYaw,
		VerticalLook = data.VerticalLook,
		MovementMode = data.MovementMode,
		Stance = data.Stance,
		OnGround = data.OnGround,
		DuckAmount = data.DuckAmount,
		SupportKind = data.SupportKind,
		SupportSourceId = data.SupportSourceId
	}

	if bit32.band(data2.FieldMask, 1) ~= 0 then
		local position

		if data2.AbsolutePosition == nil then
			position = data.Position + assert(data2.PositionDelta)
		else
			position = data2.AbsolutePosition
		end

		v2.Position = position
	end

	if bit32.band(data2.FieldMask, 2) ~= 0 then
		v2.Velocity = assert(data2.Velocity)
	end

	if bit32.band(data2.FieldMask, 4) ~= 0 then
		v2.LookYaw = assert(data2.LookYaw)
	end

	if bit32.band(data2.FieldMask, 8) ~= 0 then
		v2.VerticalLook = assert(data2.VerticalLook)
	end

	if bit32.band(data2.FieldMask, 16) ~= 0 then
		v2.MovementMode = assert(data2.MovementMode)
		v2.Stance = assert(data2.Stance)
		v2.OnGround = data2.OnGround == true
	end

	if bit32.band(data2.FieldMask, 32) ~= 0 then
		v2.DuckAmount = assert(data2.DuckAmount)
	end

	if bit32.band(data2.FieldMask, 64) ~= 0 then
		v2.SupportKind = assert(data2.SupportKind)
		v2.SupportSourceId = assert(data2.SupportSourceId)
	end

	local v3, v4 = v.validateActor(v2)

	if v3 then
		return v2, nil
	end

	return nil, v4
end

function v.validate(data)
	if typeof(data) ~= "table" then
		return false, "RemoteSnapshotNotTable"
	end

	if not Serial.isUInt32(data.Sequence) then
		return false, "InvalidRemoteSequence"
	end

	if data.Kind ~= "Baseline" and data.Kind ~= "Delta" then
		return false, "InvalidRemoteSnapshotKind"
	end

	if not Serial.isUInt32(data.BaselineSequence) then
		return false, "InvalidRemoteBaselineSequence"
	end

	if data.Kind == "Baseline" and data.BaselineSequence ~= data.Sequence then
		return false, "RemoteBaselineIdentityMismatch"
	end

	if data.Kind == "Delta" and Serial.deltaUInt32(data.Sequence, data.BaselineSequence) <= 0 then
		return false, "RemoteDeltaBaselineOrder"
	end

	if not Serial.isUInt32(data.ServerTick) then
		return false, "InvalidRemoteServerTick"
	end

	if
		typeof(data.Topology) ~= "table"
		or not (Serial.isNonZeroUInt16(data.Topology.Epoch) and Serial.isUInt32(data.Topology.Fingerprint) and Serial.isUInt32(data.Topology.DestructibleRevision))
	then
		return false, "InvalidRemoteTopology"
	end

	if
		type(data.ChunkIndex) ~= "number"
		or data.ChunkIndex % 1 ~= 0
		or type(data.ChunkCount) ~= "number"
		or data.ChunkCount % 1 ~= 0
		or data.ChunkCount < 1
		or data.ChunkCount > 255
		or data.ChunkIndex < 0
		or data.ChunkIndex >= data.ChunkCount
	then
		return false, "InvalidRemoteChunk"
	end

	if type(data.Actors) ~= "table" or type(data.Deltas) ~= "table" or type(data.RemovedActorIds) ~= "table" then
		return false, "InvalidRemoteRecords"
	end

	local v2 = #data.Actors + #data.Deltas + #data.RemovedActorIds

	if v2 > 22 then
		return false, "InvalidRemoteActorCount"
	end

	if v2 == 0 and (data.ChunkIndex ~= 0 or data.ChunkCount ~= 1) then
		return false, "InvalidEmptyRemoteFrame"
	end

	if data.Kind == "Baseline" and (#data.Deltas > 0 or #data.RemovedActorIds > 0) then
		return false, "RemoteBaselineHasDeltaRecords"
	end

	local v3 = nil
	local v4 = {}

	for k, actor in data.Actors do
		if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or #data.Actors < k then
			return false, "RemoteActorsNotDenseArray"
		end

		local v5, v6 = v.validateActor(actor)

		if not v5 then
			return false, v6
		end

		if v3 ~= nil and not RemoteActorIdentity.wireLess(v3, actor) then
			return false, "RemoteActorsNotStrictlySorted"
		end

		if v4[actor.ActorId] then
			return false, "DuplicateActorId"
		end

		v4[actor.ActorId] = true
		v3 = actor
	end

	local actorId = 0

	for k, delta in data.Deltas do
		if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or #data.Deltas < k then
			return false, "RemoteDeltasNotDenseArray"
		end

		local v5, v6 = v.validateDelta(delta)

		if not v5 then
			return false, v6
		end

		if delta.ActorId <= actorId then
			return false, "RemoteDeltasNotStrictlySorted"
		end

		if v4[delta.ActorId] then
			return false, "DuplicateActorId"
		end

		v4[delta.ActorId] = true
		actorId = delta.ActorId
	end

	local v5 = 0

	for k, removedActorId in data.RemovedActorIds do
		if
			type(k) ~= "number"
			or k % 1 ~= 0
			or k < 1
			or #data.RemovedActorIds < k
			or not Serial.isUInt32(removedActorId)
			or removedActorId == 0
			or removedActorId <= v5
		then
			return false, "InvalidRemovedRemoteActorId"
		end

		if v4[removedActorId] then
			return false, "RemoteActorAlsoRemoved"
		end

		v4[removedActorId] = true
		v5 = removedActorId
	end

	return true, nil
end

local function writeVector3(buf2: buffer, offset: number, vector: Vector3) -- 2 equivalent calls inferred from this helper
	buffer.writef32(buf2, offset, vector.X)
	buffer.writef32(buf2, offset + 4, vector.Y)
	buffer.writef32(buf2, offset + 8, vector.Z)
	return offset + 12
end

local function readVector3(buf2: buffer, offset: number) -- 1 equivalent call inferred from this helper
	return
		Vector3.new(buffer.readf32(buf2, offset), buffer.readf32(buf2, offset + 4), (buffer.readf32(buf2, offset + 8))),
		offset + 12
end

local function writeVelocity(buf2: buffer, offset: number, vector: Vector3) -- 2 equivalent calls inferred from this helper
	buffer.writei16(buf2, offset, quantizeVelocity(vector.X)) -- inferred equivalent call
	buffer.writei16(buf2, offset + 2, quantizeVelocity(vector.Y)) -- inferred equivalent call
	buffer.writei16(buf2, offset + 4, quantizeVelocity(vector.Z)) -- inferred equivalent call
	return offset + 6
end

local function readVelocity(buf2: buffer, offset: number) -- 1 equivalent call inferred from this helper
	return
		Vector3.new(
			buffer.readi16(buf2, offset) / 8,
			buffer.readi16(buf2, offset + 2) / 8,
			buffer.readi16(buf2, offset + 4) / 8
		),
		offset + 6
end

local function actorFlags(data) -- 1 equivalent call inferred from this helper
	local v2 = 0

	if data.OnGround then
		v2 = bit32.bor(v2, 1)
	end

	if data.MovementMode == "Ladder" then
		v2 = bit32.bor(v2, 2)
	end

	if data.Stance == "Ducking" then
		v2 = bit32.bor(v2, 4)
	end

	return (bit32.bor(v2, (bit32.lshift(data.SupportKind, 3))))
end

local function unsignedVarintSize(p: number) -- 6 equivalent calls inferred from this helper
	local v2 = 1

	while p >= 128 do
		p = math.floor(p / 128)
		v2 += 1
	end

	return v2
end

local function writeUnsignedVarint(buf2: buffer, count: number, p: number)
	repeat
		local v2 = p % 128
		p = math.floor(p / 128)

		if p > 0 then
			v2 += 128
		end

		buffer.writeu8(buf2, count, v2)
		count += 1
	until p == 0

	return count
end

local function readUnsignedVarint(buf2: buffer, count: number, p: number, p2: number)
	local total = 0
	local v2 = 1

	for i = 1, p do
		if buffer.len(buf2) <= count then
			return nil, count, "RemoteActorVarintTruncated"
		end

		local v3 = buffer.readu8(buf2, count)
		count += 1
		local v4 = bit32.band(v3, 127)

		if math.floor((p2 - total) / v2) < v4 then
			return nil, count, "RemoteActorVarintOverflow"
		end

		total += v4 * v2

		if v3 < 128 then
			if unsignedVarintSize(total) == i then -- inferred equivalent call
				return total, count, nil
			end

			return nil, count, "RemoteActorVarintNonCanonical"
		else
			v2 *= 128
		end
	end

	return nil, count, "RemoteActorVarintTooLong"
end

local function fullActorWireSize(actor) -- 1 equivalent call inferred from this helper
	return unsignedVarintSize(actor.UserId) + unsignedVarintSize(actor.ActorId) + unsignedVarintSize(actor.Generation) + 23 + (actor.SupportKind == Enums.SupportKind.None and 0 or 4) -- inferred equivalent call
end

local function deltaActorWireSize(delta)
	local v2 = unsignedVarintSize(delta.ActorId) + 1 -- inferred equivalent call

	if bit32.band(delta.FieldMask, 1) ~= 0 then
		v2 += delta.AbsolutePosition == nil and 6 or 14
	end

	if bit32.band(delta.FieldMask, 2) ~= 0 then
		v2 += 6
	end

	if bit32.band(delta.FieldMask, 4) ~= 0 then
		v2 += 2
	end

	if bit32.band(delta.FieldMask, 8) ~= 0 then
		v2 += 1
	end

	if bit32.band(delta.FieldMask, 16) ~= 0 then
		v2 += 1
	end

	if bit32.band(delta.FieldMask, 32) ~= 0 then
		v2 += 1
	end

	if bit32.band(delta.FieldMask, 64) ~= 0 then
		return v2 + ((delta.SupportKind == Enums.SupportKind.None and 0 or 4) + 1)
	end

	return v2
end

local function writeFullActor(buf2: buffer, p: number, actor)
	local v2 = writeVelocity( -- inferred equivalent call
		buf2,
		writeVector3( -- inferred equivalent call
			buf2,
			writeUnsignedVarint(
				buf2,
				writeUnsignedVarint(buf2, writeUnsignedVarint(buf2, p, actor.UserId), actor.ActorId),
				actor.Generation
			),
			actor.Position
		),
		actor.Velocity
	)
	buffer.writeu16(buf2, v2, (Quantization.quantizeYaw(actor.LookYaw)))
	local v3 = v2 + 2
	buffer.writei8(buf2, v3, (Quantization.quantizeSignedUnit(actor.VerticalLook)))
	local v4 = v3 + 1
	buffer.writeu8(buf2, v4, actorFlags(actor)) -- inferred equivalent call
	local v5 = v4 + 1
	buffer.writeu8(buf2, v5, (Quantization.quantizeUnitByte(actor.DuckAmount)))
	local v6 = v5 + 1

	if actor.SupportKind ~= Enums.SupportKind.None then
		buffer.writeu32(buf2, v6, actor.SupportSourceId)
		return v6 + 4
	end

	return v6
end

local function writeDeltaActor(buf2: buffer, p: number, delta)
	local v2 = writeUnsignedVarint(buf2, p, delta.ActorId)
	buffer.writeu8(buf2, v2, delta.FieldMask)
	local v3 = v2 + 1

	if bit32.band(delta.FieldMask, 1) ~= 0 then
		if delta.AbsolutePosition == nil then
			local v4 = assert(delta.PositionDelta)
			buffer.writei16(buf2, v3, (math.round(v4.X * 512)))
			buffer.writei16(buf2, v3 + 2, (math.round(v4.Y * 512)))
			buffer.writei16(buf2, v3 + 4, (math.round(v4.Z * 512)))
			v3 += 6
		else
			buffer.writei16(buf2, v3, -32768)
			v3 = writeVector3(buf2, v3 + 2, delta.AbsolutePosition) -- inferred equivalent call
		end
	end

	if bit32.band(delta.FieldMask, 2) ~= 0 then
		v3 = writeVelocity(buf2, v3, assert(delta.Velocity)) -- inferred equivalent call
	end

	if bit32.band(delta.FieldMask, 4) ~= 0 then
		buffer.writeu16(buf2, v3, (Quantization.quantizeYaw(assert(delta.LookYaw))))
		v3 += 2
	end

	if bit32.band(delta.FieldMask, 8) ~= 0 then
		buffer.writei8(buf2, v3, (Quantization.quantizeSignedUnit(assert(delta.VerticalLook))))
		v3 += 1
	end

	if bit32.band(delta.FieldMask, 16) ~= 0 then
		local v4 = 0

		if delta.OnGround == true then
			v4 = bit32.bor(v4, 1)
		end

		if delta.MovementMode == "Ladder" then
			v4 = bit32.bor(v4, 2)
		end

		if delta.Stance == "Ducking" then
			v4 = bit32.bor(v4, 4)
		end

		buffer.writeu8(buf2, v3, v4)
		v3 += 1
	end

	if bit32.band(delta.FieldMask, 32) ~= 0 then
		buffer.writeu8(buf2, v3, (Quantization.quantizeUnitByte(assert(delta.DuckAmount))))
		v3 += 1
	end

	if bit32.band(delta.FieldMask, 64) == 0 then
		return v3
	end

	local v4 = assert(delta.SupportKind)
	buffer.writeu8(buf2, v3, v4)
	v3 += 1

	if v4 ~= Enums.SupportKind.None then
		buffer.writeu32(buf2, v3, (assert(delta.SupportSourceId)))
		return v3 + 4
	end

	return v3
end

local function encodeValidated(data)
	local total = 29

	for _, actor in data.Actors do
		total += fullActorWireSize(actor) -- inferred equivalent call
	end

	for _, delta in data.Deltas do
		total += deltaActorWireSize(delta)
	end

	for _, removedActorId in data.RemovedActorIds do
		total += unsignedVarintSize(removedActorId) -- inferred equivalent call
	end

	local buf2 = buffer.create(total)
	local v2 = 0
	buffer.writeu8(buf2, v2, 6)
	local v3 = v2 + 1
	buffer.writeu8(buf2, v3, data.Kind == "Baseline" and 0 or 1)
	local v4 = v3 + 1
	buffer.writeu32(buf2, v4, data.Sequence)
	local v5 = v4 + 4
	buffer.writeu32(buf2, v5, data.BaselineSequence)
	local v6 = v5 + 4
	buffer.writeu32(buf2, v6, data.ServerTick)
	local v7 = v6 + 4
	buffer.writeu16(buf2, v7, data.Topology.Epoch)
	local v8 = v7 + 2
	buffer.writeu32(buf2, v8, data.Topology.Fingerprint)
	local v9 = v8 + 4
	buffer.writeu32(buf2, v9, data.Topology.DestructibleRevision)
	local v10 = v9 + 4
	buffer.writeu8(buf2, v10, data.ChunkIndex)
	local v11 = v10 + 1
	buffer.writeu8(buf2, v11, data.ChunkCount)
	local v12 = v11 + 1
	buffer.writeu8(buf2, v12, #data.Actors)
	local v13 = v12 + 1
	buffer.writeu8(buf2, v13, #data.Deltas)
	local v14 = v13 + 1
	buffer.writeu8(buf2, v14, #data.RemovedActorIds)
	local v15 = v14 + 1
	assert(v15 == 29, "MovementV2 remote header size drift")

	for _, actor in data.Actors do
		v15 = writeFullActor(buf2, v15, actor)
	end

	for _, delta in data.Deltas do
		v15 = writeDeltaActor(buf2, v15, delta)
	end

	for _, removedActorId in data.RemovedActorIds do
		v15 = writeUnsignedVarint(buf2, v15, removedActorId)
	end

	assert(v15 == buffer.len(buf2), "MovementV2 remote payload size drift")
	return buf2
end

function v.encodeValidated(p)
	return (encodeValidated(p))
end

function v.encode(p)
	local v2, v3 = v.validate(p)

	if v2 then
		return encodeValidated(p), nil
	end

	return nil, v3
end

local function readFullActor(buf2: buffer, p: number)
	local userId, v2, v3 = readUnsignedVarint(buf2, p, 8, 9007199254740991)

	if userId == nil then
		return nil, v2, v3
	end

	local actorId, v4, v5 = readUnsignedVarint(buf2, v2, 5, Serial.UInt32Max)

	if actorId == nil then
		return nil, v4, v5
	end

	local generation, v6, v7 = readUnsignedVarint(buf2, v4, 3, Serial.UInt16Max)

	if generation == nil then
		return nil, v6, v7
	end

	if buffer.len(buf2) - v6 < 23 then
		return nil, v6, "RemotePayloadSize"
	end

	local position, v8 = readVector3(buf2, v6) -- inferred equivalent call
	local velocity, v9 = readVelocity(buf2, v8) -- inferred equivalent call
	local dequantizeYaw = Quantization.dequantizeYaw((buffer.readu16(buf2, v9)))
	local v10 = v9 + 2
	local dequantizeSignedUnit = Quantization.dequantizeSignedUnit((buffer.readi8(buf2, v10)))
	local v11 = v10 + 1
	local v12 = buffer.readu8(buf2, v11)
	local v13 = v11 + 1

	if bit32.band(v12, 4294967232) ~= 0 then
		return nil, v13, "InvalidRemoteActorFlags"
	end

	local dequantizeUnitByte = Quantization.dequantizeUnitByte((buffer.readu8(buf2, v13)))
	local v14 = v13 + 1
	local supportKind = bit32.band(v12, 56) / 8

	if Enums.SupportKind.Max < supportKind then
		return nil, v14, "InvalidActorSupport"
	end

	local supportSourceId

	if supportKind == Enums.SupportKind.None then
		supportSourceId = 0
		return {
			UserId = userId,
			ActorId = actorId,
			Generation = generation,
			Position = position,
			Velocity = velocity,
			LookYaw = dequantizeYaw,
			VerticalLook = dequantizeSignedUnit,
			MovementMode = bit32.band(v12, 2) == 0 and "Walking" or "Ladder",
			Stance = bit32.band(v12, 4) == 0 and "Standing" or "Ducking",
			OnGround = bit32.band(v12, 1) ~= 0,
			DuckAmount = dequantizeUnitByte,
			SupportKind = supportKind,
			SupportSourceId = supportSourceId
		}, v14, nil
	end

	if buffer.len(buf2) - v14 < 4 then
		return nil, v14, "RemotePayloadSize"
	end

	supportSourceId = buffer.readu32(buf2, v14)
	v14 += 4
	return {
		UserId = userId,
		ActorId = actorId,
		Generation = generation,
		Position = position,
		Velocity = velocity,
		LookYaw = dequantizeYaw,
		VerticalLook = dequantizeSignedUnit,
		MovementMode = bit32.band(v12, 2) == 0 and "Walking" or "Ladder",
		Stance = bit32.band(v12, 4) == 0 and "Standing" or "Ducking",
		OnGround = bit32.band(v12, 1) ~= 0,
		DuckAmount = dequantizeUnitByte,
		SupportKind = supportKind,
		SupportSourceId = supportSourceId
	}, v14, nil
end

local function readDeltaActor(buf2: buffer, p: number)
	local actorId, v2, v3 = readUnsignedVarint(buf2, p, 5, Serial.UInt32Max)

	if actorId == nil then
		return nil, v2, v3
	end

	if buffer.len(buf2) <= v2 then
		return nil, v2, "RemotePayloadSize"
	end

	local fieldMask = buffer.readu8(buf2, v2)
	local v4 = v2 + 1

	if fieldMask == 0 or bit32.band(fieldMask, 4294967168) ~= 0 then
		return nil, v4, "InvalidRemoteDeltaFieldMask"
	end

	local v5 = {
		ActorId = actorId,
		FieldMask = fieldMask,
		PositionDelta = nil,
		AbsolutePosition = nil,
		Velocity = nil,
		LookYaw = nil,
		VerticalLook = nil,
		MovementMode = nil,
		Stance = nil,
		OnGround = nil,
		DuckAmount = nil,
		SupportKind = nil,
		SupportSourceId = nil
	}

	if bit32.band(fieldMask, 1) ~= 0 then
		if buffer.len(buf2) - v4 < 2 then
			return nil, v4, "RemotePayloadSize"
		end

		local v6 = buffer.readi16(buf2, v4)

		if v6 == -32768 then
			if buffer.len(buf2) - v4 < 14 then
				return nil, v4, "RemotePayloadSize"
			end

			local v7 = v4 + 2
			local vector = Vector3.new(
				buffer.readf32(buf2, v7),
				buffer.readf32(buf2, v7 + 4),
				(buffer.readf32(buf2, v7 + 8))
			)
			v4 = v7 + 12
			v5.AbsolutePosition = vector
		else
			if buffer.len(buf2) - v4 < 6 then
				return nil, v4, "RemotePayloadSize"
			end

			v5.PositionDelta = Vector3.new(
				v6 / 512,
				buffer.readi16(buf2, v4 + 2) / 512,
				buffer.readi16(buf2, v4 + 4) / 512
			)
			v4 += 6
		end
	end

	if bit32.band(fieldMask, 2) ~= 0 then
		if buffer.len(buf2) - v4 < 6 then
			return nil, v4, "RemotePayloadSize"
		end

		local vector = Vector3.new(
			buffer.readi16(buf2, v4) / 8,
			buffer.readi16(buf2, v4 + 2) / 8,
			buffer.readi16(buf2, v4 + 4) / 8
		)
		v4 += 6
		v5.Velocity = vector
	end

	if bit32.band(fieldMask, 4) ~= 0 then
		if buffer.len(buf2) - v4 < 2 then
			return nil, v4, "RemotePayloadSize"
		end

		v5.LookYaw = Quantization.dequantizeYaw((buffer.readu16(buf2, v4)))
		v4 += 2
	end

	if bit32.band(fieldMask, 8) ~= 0 then
		if buffer.len(buf2) <= v4 then
			return nil, v4, "RemotePayloadSize"
		end

		v5.VerticalLook = Quantization.dequantizeSignedUnit((buffer.readi8(buf2, v4)))
		v4 += 1
	end

	if bit32.band(fieldMask, 16) ~= 0 then
		if buffer.len(buf2) <= v4 then
			return nil, v4, "RemotePayloadSize"
		end

		local v6 = buffer.readu8(buf2, v4)
		v4 += 1

		if bit32.band(v6, 4294967288) ~= 0 then
			return nil, v4, "InvalidRemoteDeltaMovementFlags"
		end

		v5.MovementMode = bit32.band(v6, 2) == 0 and "Walking" or "Ladder"
		v5.Stance = bit32.band(v6, 4) == 0 and "Standing" or "Ducking"
		v5.OnGround = bit32.band(v6, 1) ~= 0
	end

	if bit32.band(fieldMask, 32) ~= 0 then
		if buffer.len(buf2) <= v4 then
			return nil, v4, "RemotePayloadSize"
		end

		v5.DuckAmount = Quantization.dequantizeUnitByte((buffer.readu8(buf2, v4)))
		v4 += 1
	end

	if bit32.band(fieldMask, 64) ~= 0 then
		if buffer.len(buf2) <= v4 then
			return nil, v4, "RemotePayloadSize"
		end

		local supportKind = buffer.readu8(buf2, v4)
		v4 += 1

		if Enums.SupportKind.Max < supportKind then
			return nil, v4, "InvalidRemoteDeltaSupport"
		end

		local supportSourceId

		if supportKind == Enums.SupportKind.None then
			supportSourceId = 0
		else
			if buffer.len(buf2) - v4 < 4 then
				return nil, v4, "RemotePayloadSize"
			end

			supportSourceId = buffer.readu32(buf2, v4)
			v4 += 4
		end

		v5.SupportKind = supportKind
		v5.SupportSourceId = supportSourceId
	end

	local v6, v7 = v.validateDelta(v5)

	if v6 then
		return v5, v4, nil
	end

	return nil, v4, v7
end

function v.decode(buf2)
	if typeof(buf2) ~= "buffer" then
		return nil, "RemotePayloadNotBuffer"
	end

	if buffer.len(buf2) < 29 or buffer.len(buf2) > v.MaxWireSize then
		return nil, "RemotePayloadSize"
	end

	local v2 = 0

	if buffer.readu8(buf2, v2) ~= 6 then
		return nil, "RemoteVersion"
	end

	local v3 = v2 + 1
	local v4 = buffer.readu8(buf2, v3)
	local v5 = v3 + 1

	if v4 > 1 then
		return nil, "InvalidRemoteSnapshotKind"
	end

	local sequence = buffer.readu32(buf2, v5)
	local v6 = v5 + 4
	local baselineSequence = buffer.readu32(buf2, v6)
	local v7 = v6 + 4
	local serverTick = buffer.readu32(buf2, v7)
	local v8 = v7 + 4
	local epoch = buffer.readu16(buf2, v8)
	local v9 = v8 + 2
	local fingerprint = buffer.readu32(buf2, v9)
	local v10 = v9 + 4
	local destructibleRevision = buffer.readu32(buf2, v10)
	local v11 = v10 + 4
	local chunkIndex = buffer.readu8(buf2, v11)
	local v12 = v11 + 1
	local chunkCount = buffer.readu8(buf2, v12)
	local v13 = v12 + 1
	local v14 = buffer.readu8(buf2, v13)
	local v15 = v13 + 1
	local v16 = buffer.readu8(buf2, v15)
	local v17 = v15 + 1
	local v18 = buffer.readu8(buf2, v17)
	local v19 = v17 + 1

	if v14 + v16 + v18 > 22 then
		return nil, "InvalidRemoteActorCount"
	end

	local v20 = v14 * 26 + 29 + v16 * 3 + v18
	local v21 = v14 * 43 + 29 + v16 * 36 + v18 * 5

	if buffer.len(buf2) < v20 or v21 < buffer.len(buf2) then
		return nil, "RemotePayloadSize"
	end

	local actors = table.create(v14)

	for i = 1, v14 do
		local v22, v23
		v22, v19, v23 = readFullActor(buf2, v19)

		if v22 == nil then
			return nil, v23
		else
			actors[i] = v22
		end
	end

	local deltas = table.create(v16)

	for i = 1, v16 do
		local v22, v23
		v22, v19, v23 = readDeltaActor(buf2, v19)

		if v22 == nil then
			return nil, v23
		else
			deltas[i] = v22
		end
	end

	local removedActorIds = table.create(v18)

	for i = 1, v18 do
		local v22, v23
		v22, v19, v23 = readUnsignedVarint(buf2, v19, 5, Serial.UInt32Max)

		if v22 == nil then
			return nil, v23
		else
			removedActorIds[i] = v22
		end
	end

	if v19 ~= buffer.len(buf2) then
		return nil, "RemotePayloadSize"
	end

	local v22 = {
		Kind = v4 == 0 and "Baseline" or "Delta",
		Sequence = sequence,
		BaselineSequence = baselineSequence,
		ServerTick = serverTick,
		Topology = {
			Epoch = epoch,
			Fingerprint = fingerprint,
			DestructibleRevision = destructibleRevision
		},
		ChunkIndex = chunkIndex,
		ChunkCount = chunkCount,
		Actors = actors,
		Deltas = deltas,
		RemovedActorIds = removedActorIds
	}
	local v23, v24 = v.validate(v22)

	if v23 then
		return v22, nil
	end

	return nil, v24
end

return table.freeze(v)