--!native
local v = {
	MAX_CELLS = 32,
	MAX_ORIGINS = 32,
	MAX_TARGET_POINTS = 64,
	VECTOR_SIZE = 12,
	PAIR_SKIP = 0,
	PAIR_BROAD = 1,
	PAIR_PROOF = 2,
	RESULT_HIDDEN = 0,
	RESULT_VISIBLE = 1,
	RESULT_UNRESOLVED = 2,
	RESULT_SKIPPED = 3,
	RESULT_NOT_OWNED = 255,
	FLAG_STATIC = 2,
	FLAG_DYNAMIC_CERTIFICATES = 4,
	ACTOR_FLAG_EXTRAPOLATED = 1,
	ACTOR_FLAG_HULL_TAIL = 2,
	STAT_PAIRS = 0,
	STAT_HIDDEN = 1,
	STAT_VISIBLE = 2,
	STAT_UNRESOLVED = 3,
	STAT_SKIPPED = 4,
	STAT_CERTIFICATE_HITS = 5,
	STAT_CERTIFICATE_SEARCHES = 6,
	STAT_CERTIFICATE_FOUND = 7,
	STAT_SEGMENTS = 8,
	STAT_BLOCKER_HITS = 9,
	STAT_BVH_QUERIES = 10,
	STAT_BVH_HITS = 11,
	STAT_FALLBACK_RAYS = 12,
	STAT_DEADLINE = 14,
	STAT_MICROSECONDS = 15,
	STAT_CLEAR_REPLAYS = 16,
	STAT_DYNAMIC_HITS = 17,
	STAT_DYNAMIC_FOUND = 18,
	STAT_POSE_REPLAYS = 19
}

local function writeVector(buf: buffer, offset: number, vector: Vector3) -- 4 equivalent calls inferred from this helper
	buffer.writef32(buf, offset, vector.X)
	buffer.writef32(buf, offset + 4, vector.Y)
	buffer.writef32(buf, offset + 8, vector.Z)
end

local function readVector(buf: buffer, offset: number) -- 2 equivalent calls inferred from this helper
	return (Vector3.new(buffer.readf32(buf, offset), buffer.readf32(buf, offset + 4), (buffer.readf32(buf, offset + 8))))
end

v.readVector = readVector

local function checkedCount(p: number, p2: number, p3: string)
	if p < 0 or p2 < p or p ~= math.floor(p) then
		error(`visibility cycle {p3} count {p} exceeds {p2}`)
	end

	return p
end

local function actorRecordSize(actor) -- 2 equivalent calls inferred from this helper
	local count = #actor.Cells

	if count < 0 or count > 32 or count ~= math.floor(count) then
		error(`visibility cycle cell count {count} exceeds {32}`)
	end

	local count2 = #actor.Origins

	if count2 < 0 or count2 > 32 or count2 ~= math.floor(count2) then
		error(`visibility cycle origin count {count2} exceeds {32}`)
	end

	local count3 = #actor.TargetPoints

	if count3 < 0 or count3 > 64 or count3 ~= math.floor(count3) then
		error(`visibility cycle target point count {count3} exceeds {64}`)
	end

	return count * 2 + 40 + count2 * 12 + count3 * 12
end

function v.encodeCapture(data)
	local count = #data.Actors

	if count < 0 or count > 64 or count ~= math.floor(count) then
		error(`visibility cycle actor count {count} exceeds {64}`)
	end

	if buffer.len(data.PairKinds) < count * count then
		error("visibility cycle pair-kind table is too small")
	end

	local total = 0

	for _, actor in data.Actors do
		total += actorRecordSize(actor) -- inferred equivalent call
	end

	local v2 = count * 4
	local v3 = v2 + 48 + total
	local v4 = v3 + count * count
	local buf = buffer.create(v4)
	buffer.writeu32(buf, 0, 843272006)
	buffer.writeu16(buf, 4, 2)
	buffer.writeu8(buf, 6, count)
	local total2 = 0

	if data.StaticEnabled then
		total2 += v.FLAG_STATIC
	end

	if data.DynamicCertificates then
		total2 += v.FLAG_DYNAMIC_CERTIFICATES
	end

	buffer.writeu8(buf, 7, total2)
	buffer.writeu32(buf, 8, data.Sequence)
	buffer.writef64(buf, 12, data.CaptureTime)
	buffer.writeu32(buf, 20, data.Generation)
	buffer.writef32(buf, 28, data.CycleBudgetSeconds)
	buffer.writeu32(buf, 36, 48)
	buffer.writeu32(buf, 40, v3)
	buffer.writeu32(buf, 44, v4)
	local v5 = v2 + 48

	for k, actor in data.Actors do
		buffer.writeu32(buf, (k - 1) * 4 + 48, v5)
		local v6 = actorRecordSize(actor) -- inferred equivalent call
		buffer.writeu32(buf, v5, actor.ActorId)
		buffer.writeu32(buf, v5 + 4, actor.Generation)
		writeVector(buf, v5 + 8, actor.Position) -- inferred equivalent call
		writeVector(buf, v5 + 20, actor.Velocity) -- inferred equivalent call
		buffer.writeu8(buf, v5 + 32, #actor.Cells)
		buffer.writeu8(buf, v5 + 33, #actor.Origins)
		buffer.writeu8(buf, v5 + 34, #actor.TargetPoints)
		buffer.writeu8(
			buf,
			v5 + 35,
			(not actor.Extrapolated and 0 or v.ACTOR_FLAG_EXTRAPOLATED) + (not actor.HullTail and 0 or v.ACTOR_FLAG_HULL_TAIL)
		)
		buffer.writeu32(buf, v5 + 36, v6)
		local v7 = v5 + 40

		for _, value in actor.Cells do
			buffer.writeu16(buf, v7, value)
			v7 += 2
		end

		for _, origin in actor.Origins do
			writeVector(buf, v7, origin) -- inferred equivalent call
			v7 += 12
		end

		for _, targetPoint in actor.TargetPoints do
			writeVector(buf, v7, targetPoint) -- inferred equivalent call
			v7 += 12
		end

		v5 += v6
	end

	if v5 ~= v3 then
		error("visibility cycle capture actor bytes drifted")
	end

	buffer.copy(buf, v3, data.PairKinds, 0, count * count)
	return buf
end

function v.readCaptureHeader(buf: buffer)
	if buffer.len(buf) < 48 or buffer.readu32(buf, 0) ~= 843272006 then
		error("visibility cycle capture magic is invalid")
	end

	if buffer.readu16(buf, 4) ~= 2 then
		error("visibility cycle capture version is unsupported")
	end

	local actorCount = buffer.readu8(buf, 6)
	local pairKindOffset = buffer.readu32(buf, 40)
	local v2 = buffer.readu32(buf, 44)
	local flags = buffer.readu8(buf, 7)

	if
		actorCount > 64
		or pairKindOffset + actorCount * actorCount ~= v2
		or v2 ~= buffer.len(buf)
		or buffer.readu32(buf, 24) ~= 0
		or buffer.readu32(buf, 32) ~= 0
		or bit32.band(flags, (bit32.bnot(v.FLAG_STATIC + v.FLAG_DYNAMIC_CERTIFICATES))) ~= 0
	then
		error("visibility cycle capture layout is invalid")
	end

	return {
		ActorCount = actorCount,
		Flags = flags,
		Sequence = buffer.readu32(buf, 8),
		CaptureTime = buffer.readf64(buf, 12),
		Generation = buffer.readu32(buf, 20),
		CycleBudgetSeconds = buffer.readf32(buf, 28),
		PairKindOffset = pairKindOffset
	}
end

function v.readActor(buf: buffer, p: number)
	local offset = buffer.readu32(buf, (p - 1) * 4 + 48)
	local cellCount = buffer.readu8(buf, offset + 32)
	local originCount = buffer.readu8(buf, offset + 33)
	local targetPointCount = buffer.readu8(buf, offset + 34)
	local v2 = buffer.readu32(buf, offset + 36)

	if v2 ~= cellCount * 2 + 40 + originCount * 12 + targetPointCount * 12 or offset + v2 > buffer.len(buf) then
		error("visibility cycle actor record is invalid")
	end

	local cellsOffset = offset + 40
	local originsOffset = cellsOffset + cellCount * 2
	return {
		Offset = offset,
		ActorId = buffer.readu32(buf, offset),
		Generation = buffer.readu32(buf, offset + 4),
		Position = readVector(buf, offset + 8), -- inferred equivalent call
		Velocity = readVector(buf, offset + 20), -- inferred equivalent call
		CellCount = cellCount,
		OriginCount = originCount,
		TargetPointCount = targetPointCount,
		Flags = buffer.readu8(buf, offset + 35),
		CellsOffset = cellsOffset,
		OriginsOffset = originsOffset,
		TargetPointsOffset = originsOffset + originCount * 12
	}
end

function v.createResult(value: number, value2: number, value3: number, value4: number, value5: number, value6: number)
	if value < 0 or value > 64 or value ~= math.floor(value) then
		error(`visibility cycle result actor count {value} exceeds {64}`)
	end

	local buf = buffer.create(value + 108 + value * value)
	buffer.writeu32(buf, 0, 844255046)
	buffer.writeu16(buf, 4, 2)
	buffer.writeu8(buf, 6, value)
	buffer.writeu8(buf, 7, value2)
	buffer.writeu32(buf, 8, value3)
	buffer.writef64(buf, 12, value4)
	buffer.writeu32(buf, 20, value5)
	buffer.writeu8(buf, 24, value6)
	buffer.fill(buf, value + 108, v.RESULT_NOT_OWNED)
	return buf
end

function v.resultMatrixOffset(p: number)
	return p + 108
end

function v.resultRowsOffset()
	return 108
end

function v.writeStat(buf: buffer, p: number, p2: number)
	buffer.writeu32(buf, p * 4 + 28, (math.clamp(math.floor(p2), 0, 4294967295)))
end

function v.readStat(buf: buffer, p: number)
	return (buffer.readu32(buf, p * 4 + 28))
end

function v.readResultHeader(buf: buffer)
	if buffer.len(buf) < 108 or buffer.readu32(buf, 0) ~= 844255046 then
		error("visibility cycle result magic is invalid")
	end

	if buffer.readu16(buf, 4) ~= 2 then
		error("visibility cycle result version is unsupported")
	end

	local actorCount = buffer.readu8(buf, 6)
	local resultMatrixOffset = v.resultMatrixOffset(actorCount)

	if actorCount > 64 or resultMatrixOffset + actorCount * actorCount ~= buffer.len(buf) then
		error("visibility cycle result layout is invalid")
	end

	return {
		ActorCount = actorCount,
		WorkerIndex = buffer.readu8(buf, 7),
		Sequence = buffer.readu32(buf, 8),
		CaptureTime = buffer.readf64(buf, 12),
		Generation = buffer.readu32(buf, 20),
		Status = buffer.readu8(buf, 24),
		RowsOffset = v.resultRowsOffset(),
		MatrixOffset = resultMatrixOffset
	}
end

v.PRIMITIVE_SIZE = 64
v.PRIMITIVE_KIND_OTHER = 0
v.PRIMITIVE_KIND_BLOCK = 1

function v.virtualPrimitiveCount(items, p: number)
	local v2 = 0

	if items ~= nil then
		for k in items do
			if p < k then
				v2 = math.max(v2, k - p)
			end
		end
	end

	return v2
end

function v.encodePrimitives(list, p, value: number?)
	local v2 = math.max(0, (math.floor(value or 0)))
	local buf = buffer.create((#list + v2) * 64)
	local count = 0

	for k, part in list do
		local v3 = (k - 1) * 64
		local v4 = part:IsA("Part") and part.Shape.Name == "Block"

		if not v4 and (p == nil or not p[k]) then
			count += 1
		end

		local v5

		if v4 then
			v5 = v.PRIMITIVE_KIND_BLOCK
		else
			v5 = v.PRIMITIVE_KIND_OTHER
		end

		buffer.writeu8(buf, v3, v5)

		for k2, value2 in { part.CFrame:GetComponents() } do
			buffer.writef32(buf, v3 + k2 * 4, value2)
		end

		local size = part.Size
		buffer.writef32(buf, v3 + 52, size.X * 0.5)
		buffer.writef32(buf, v3 + 56, size.Y * 0.5)
		buffer.writef32(buf, v3 + 60, size.Z * 0.5)
	end

	for i = #list + 1, #list + v2 do
		local v3 = (i - 1) * 64
		buffer.writeu8(buf, v3, v.PRIMITIVE_KIND_OTHER)
		buffer.writef32(buf, v3 + 4, 0)
		buffer.writef32(buf, v3 + 8, -1000000)
		buffer.writef32(buf, v3 + 12, 0)
		buffer.writef32(buf, v3 + 16, 1)
		buffer.writef32(buf, v3 + 32, 1)
		buffer.writef32(buf, v3 + 48, 1)
	end

	return buf, count
end

return table.freeze(v)