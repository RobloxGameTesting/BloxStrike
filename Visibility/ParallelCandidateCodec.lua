local v = {
	STATUS_INCONCLUSIVE = 0,
	STATUS_PROVED = 1,
	STATUS_ERROR = 2,
	STATUS_PROVED_FALLBACK = 3,
	PAIR_KIND_PRIMARY = 0,
	PAIR_KIND_FALLBACK = 1
}

local function checkedCount(list, p: string) -- 1 equivalent call inferred from this helper
	local count = #list

	if count > 255 then
		error(`parallel certificate {p} count exceeds {255}`)
	end

	return count
end

local function checkedNumericCount(p: number) -- 11 equivalent calls inferred from this helper
	if p < 0 or p > 255 or p ~= math.floor(p) then
		error("parallel certificate job count is invalid")
	end

	return p
end

local function checkedVolumeCount(items, p: string)
	if items == nil then
		return 0
	end

	local count = checkedCount(items, p) -- inferred equivalent call

	for _, item in items do
		if #item ~= 8 then
			error(`parallel certificate {p} must contain eight box vertices`)
		end
	end

	return count
end

local function jobDataSizeFromCounts(p: number, p2: number, p3: number, p4: number) -- 4 equivalent calls inferred from this helper
	return (p + p2) * 2 + (p3 + p4) * 12
end

local function jobDataSize(data)
	local count = #data.viewerCells

	if count > 255 then
		error(`parallel certificate viewer cell count exceeds {255}`)
	end

	local count2 = #data.targetCells

	if count2 > 255 then
		error(`parallel certificate target cell count exceeds {255}`)
	end

	local count3 = #data.viewerOrigins

	if count3 > 255 then
		error(`parallel certificate viewer origin count exceeds {255}`)
	end

	local count4 = #data.targetPoints

	if count4 > 255 then
		error(`parallel certificate target point count exceeds {255}`)
	end

	return jobDataSizeFromCounts(count, count2, count3, count4) + (checkedVolumeCount( -- inferred equivalent call
		data.fallbackViewerVolumes,
		"fallback viewer volume"
	) + checkedVolumeCount(data.fallbackTargetVolumes, "fallback target volume")) * 8 * 12
end

local function writeVector(buf: buffer, offset: number, vector: Vector3) -- 8 equivalent calls inferred from this helper
	buffer.writef32(buf, offset, vector.X)
	buffer.writef32(buf, offset + 4, vector.Y)
	buffer.writef32(buf, offset + 8, vector.Z)
end

function v.jobSize(p: number, p2: number, p3: number, p4: number, value: number?, value2: number?)
	checkedNumericCount(p) -- inferred equivalent call
	checkedNumericCount(p2) -- inferred equivalent call
	checkedNumericCount(p3) -- inferred equivalent call
	checkedNumericCount(p4) -- inferred equivalent call
	local v2 = checkedNumericCount(value or 0) -- inferred equivalent call
	local v3 = checkedNumericCount(value2 or 0) -- inferred equivalent call
	return jobDataSizeFromCounts(p, p2, p3, p4) + 16 + (v2 + v3) * 8 * 12 -- inferred equivalent call
end

function v.createJobBatch(value: number, value2: number, value3: number, size: number)
	if value3 < 0 or value3 > 65535 or value3 ~= math.floor(value3) then
		error("parallel certificate batch job count is invalid")
	end

	if size < 0 or size ~= math.floor(size) then
		error("parallel certificate batch byte count is invalid")
	end

	local buf = buffer.create(size + 16)
	buffer.writeu32(buf, 0, 826494790)
	buffer.writeu16(buf, 4, 2)
	buffer.writeu16(buf, 6, value3)
	buffer.writeu32(buf, 8, value)
	buffer.writeu32(buf, 12, value2)
	return buf
end

function v.writeJob(buf: buffer, offset: number, value: number, value2: number?, list, list2, list3, list4, options, options2)
	local count = #list

	if count > 255 then
		error(`parallel certificate viewer cell count exceeds {255}`)
	end

	local count2 = #list2

	if count2 > 255 then
		error(`parallel certificate target cell count exceeds {255}`)
	end

	local count3 = #list3

	if count3 > 255 then
		error(`parallel certificate viewer origin count exceeds {255}`)
	end

	local count4 = #list4

	if count4 > 255 then
		error(`parallel certificate target point count exceeds {255}`)
	end

	local v2 = checkedVolumeCount(options, "fallback viewer volume")
	local v3 = checkedVolumeCount(options2, "fallback target volume")
	local v4 = jobDataSizeFromCounts(count, count2, count3, count4) + (v2 + v3) * 8 * 12 -- inferred equivalent call

	if offset < 16 or offset + 16 + v4 > buffer.len(buf) then
		error("parallel certificate job write exceeds its batch")
	end

	buffer.writeu32(buf, offset, value)
	buffer.writeu16(buf, offset + 4, value2 or 0)
	buffer.writeu8(buf, offset + 6, count)
	buffer.writeu8(buf, offset + 7, count2)
	buffer.writeu8(buf, offset + 8, count3)
	buffer.writeu8(buf, offset + 9, count4)
	buffer.writeu16(buf, offset + 10, v4)
	buffer.writeu32(buf, offset + 12, (bit32.bor(v2, (bit32.lshift(v3, 8)))))
	local v5 = offset + 16

	for _, value3 in list do
		buffer.writeu16(buf, v5, value3)
		v5 += 2
	end

	for _, value3 in list2 do
		buffer.writeu16(buf, v5, value3)
		v5 += 2
	end

	for _, v6 in list3 do
		writeVector(buf, v5, v6) -- inferred equivalent call
		v5 += 12
	end

	for _, v6 in list4 do
		writeVector(buf, v5, v6) -- inferred equivalent call
		v5 += 12
	end

	for _, v6 in options or {} do
		for _, v7 in v6 do
			writeVector(buf, v5, v7) -- inferred equivalent call
			v5 += 12
		end
	end

	for _, v6 in options2 or {} do
		for _, v7 in v6 do
			writeVector(buf, v5, v7) -- inferred equivalent call
			v5 += 12
		end
	end

	return v5
end

function v.encodeBatch(p: number, p2: number, list)
	if #list > 65535 then
		error("parallel certificate batch exceeds 65535 jobs")
	end

	local total = 0

	for _, v2 in list do
		total += jobDataSize(v2) + 16
	end

	local jobBatch = v.createJobBatch(p, p2, #list, total)
	local v2 = 16

	for _, v3 in list do
		v2 = v.writeJob(
			jobBatch,
			v2,
			v3.jobId,
			v3.preferredPlane,
			v3.viewerCells,
			v3.targetCells,
			v3.viewerOrigins,
			v3.targetPoints,
			v3.fallbackViewerVolumes,
			v3.fallbackTargetVolumes
		)
	end

	assert(v2 == buffer.len(jobBatch), "parallel certificate encoder size drift")
	return jobBatch
end

function v.readBatchHeader(buf: buffer)
	if buffer.len(buf) < 16 or buffer.readu32(buf, 0) ~= 826494790 then
		error("parallel certificate job magic is invalid")
	end

	if buffer.readu16(buf, 4) ~= 2 then
		error("parallel certificate job version is unsupported")
	end

	return buffer.readu32(buf, 8), buffer.readu32(buf, 12), (buffer.readu16(buf, 6))
end

function v.readJob(buf: buffer, offset: number)
	if offset < 16 or offset + 16 > buffer.len(buf) then
		error("parallel certificate job header is truncated")
	end

	local v2 = buffer.readu32(buf, offset)
	local v3 = buffer.readu16(buf, offset + 4)
	local v4 = buffer.readu8(buf, offset + 6)
	local v5 = buffer.readu8(buf, offset + 7)
	local v6 = buffer.readu8(buf, offset + 8)
	local v7 = buffer.readu8(buf, offset + 9)
	local v8 = buffer.readu16(buf, offset + 10)
	local v9 = buffer.readu32(buf, offset + 12)

	if bit32.band(v9, 4294901760) ~= 0 then
		error("parallel certificate fallback metadata is malformed")
	end

	local v10 = bit32.band(v9, 255)
	local v11 = bit32.band(bit32.rshift(v9, 8), 255)
	local v12 = offset + 16
	local v13 = jobDataSizeFromCounts(v4, v5, v6, v7) + (v10 + v11) * 8 * 12 -- inferred equivalent call

	if v8 ~= v13 or v12 + v13 > buffer.len(buf) then
		error("parallel certificate job payload is malformed")
	end

	local v14 = v12 + v4 * 2
	local v15 = v14 + v5 * 2
	local v16 = v15 + v6 * 12
	local v17 = v16 + v7 * 12
	local v18 = v17 + v10 * 8 * 12
	local v19 = v18 + v11 * 8 * 12

	if v3 == 0 then
		v3 = nil
	end

	return v2, v3, v12, v4, v14, v5, v15, v6, v16, v7, v17, v10, v18, v11, v19
end

local function actorDataSizeFromCounts(p: number, p2: number, p3: number, p4: number, p5: number) -- 3 equivalent calls inferred from this helper
	return p * 2 + (p2 + p3) * 12 + (p4 + p5) * 8 * 12
end

function v.actorRecordSize(p: number, p2: number, p3: number, value: number?, value2: number?)
	checkedNumericCount(p) -- inferred equivalent call
	checkedNumericCount(p2) -- inferred equivalent call
	checkedNumericCount(p3) -- inferred equivalent call
	return actorDataSizeFromCounts(p, p2, p3, checkedNumericCount(value or 0), checkedNumericCount(value2 or 0)) + 12 -- inferred equivalent call
end

function v.createActorBatch(value: number, value2: number, value3: number, value4: number, value5: number)
	if value3 < 0 or value3 > 64 or value3 ~= math.floor(value3) then
		error(`parallel certificate actor count must be between 0 and {64}`)
	end

	if value4 < 0 or value4 > 65535 or value4 ~= math.floor(value4) then
		error("parallel certificate actor-pair count is invalid")
	end

	if value5 < 0 or value5 ~= math.floor(value5) then
		error("parallel certificate actor byte count is invalid")
	end

	local buf = buffer.create(value5 + 24 + value4 * 12)
	buffer.writeu32(buf, 0, 826363718)
	buffer.writeu16(buf, 4, 1)
	buffer.writeu16(buf, 6, value3)
	buffer.writeu16(buf, 8, value4)
	buffer.writeu16(buf, 10, 0)
	buffer.writeu32(buf, 12, value)
	buffer.writeu32(buf, 16, value2)
	buffer.writeu32(buf, 20, value5)
	return buf
end

function v.writeActor(buf: buffer, offset: number, list, list2, list3, options, options2)
	local count = #list

	if count > 255 then
		error(`parallel certificate actor cell count exceeds {255}`)
	end

	local count2 = #list2

	if count2 > 255 then
		error(`parallel certificate actor viewer point count exceeds {255}`)
	end

	local count3 = #list3

	if count3 > 255 then
		error(`parallel certificate actor target point count exceeds {255}`)
	end

	local v2 = checkedVolumeCount(options, "actor fallback viewer volume")
	local v3 = checkedVolumeCount(options2, "actor fallback target volume")
	local v4 = actorDataSizeFromCounts(count, count2, count3, v2, v3) -- inferred equivalent call

	if offset < 24 or offset + 12 + v4 > buffer.len(buf) then
		error("parallel certificate actor write exceeds its batch")
	end

	buffer.writeu8(buf, offset, count)
	buffer.writeu8(buf, offset + 1, count2)
	buffer.writeu8(buf, offset + 2, count3)
	buffer.writeu8(buf, offset + 3, v2)
	buffer.writeu8(buf, offset + 4, v3)
	buffer.writeu8(buf, offset + 5, 0)
	buffer.writeu16(buf, offset + 6, 0)
	buffer.writeu32(buf, offset + 8, v4)
	local v5 = offset + 12

	for _, value in list do
		buffer.writeu16(buf, v5, value)
		v5 += 2
	end

	for _, v6 in list2 do
		writeVector(buf, v5, v6) -- inferred equivalent call
		v5 += 12
	end

	for _, v6 in list3 do
		writeVector(buf, v5, v6) -- inferred equivalent call
		v5 += 12
	end

	for _, v6 in options or {} do
		for _, v7 in v6 do
			writeVector(buf, v5, v7) -- inferred equivalent call
			v5 += 12
		end
	end

	for _, v6 in options2 or {} do
		for _, v7 in v6 do
			writeVector(buf, v5, v7) -- inferred equivalent call
			v5 += 12
		end
	end

	return v5
end

function v.writeActorPair(buf: buffer, offset: number, value: number, p: number, p2: number, value2: number, value3: number?)
	if p < 1 or p > 64 or p2 < 1 or p2 > 64 then
		error("parallel certificate actor-pair index is invalid")
	end

	if value2 ~= v.PAIR_KIND_PRIMARY and value2 ~= v.PAIR_KIND_FALLBACK then
		error("parallel certificate actor-pair kind is invalid")
	end

	if offset < 24 or offset + 12 > buffer.len(buf) then
		error("parallel certificate actor-pair write exceeds its batch")
	end

	buffer.writeu32(buf, offset, value)
	buffer.writeu16(buf, offset + 4, value3 or 0)
	buffer.writeu8(buf, offset + 6, p - 1)
	buffer.writeu8(buf, offset + 7, p2 - 1)
	buffer.writeu8(buf, offset + 8, value2)
	buffer.writeu8(buf, offset + 9, 0)
	buffer.writeu16(buf, offset + 10, 0)
	return offset + 12
end

function v.readActorBatchHeader(buf: buffer)
	if buffer.len(buf) < 24 or buffer.readu32(buf, 0) ~= 826363718 then
		error("parallel certificate actor-batch magic is invalid")
	end

	if buffer.readu16(buf, 4) ~= 1 then
		error("parallel certificate actor-batch version is unsupported")
	end

	local v2 = buffer.readu16(buf, 6)
	local v3 = buffer.readu16(buf, 8)
	local v4 = buffer.readu32(buf, 20)
	local v5 = v4 + 24

	if v2 > 64 or v5 + v3 * 12 ~= buffer.len(buf) then
		error("parallel certificate actor-batch size is invalid")
	end

	return buffer.readu32(buf, 12), buffer.readu32(buf, 16), v2, v3, v4, v5
end

function v.readActor(buf: buffer, offset: number)
	if offset < 24 or offset + 12 > buffer.len(buf) then
		error("parallel certificate actor header is truncated")
	end

	local v2 = buffer.readu8(buf, offset)
	local v3 = buffer.readu8(buf, offset + 1)
	local v4 = buffer.readu8(buf, offset + 2)
	local v5 = buffer.readu8(buf, offset + 3)
	local v6 = buffer.readu8(buf, offset + 4)
	local v7 = buffer.readu32(buf, offset + 8)
	local v8 = actorDataSizeFromCounts(v2, v3, v4, v5, v6) -- inferred equivalent call
	local v9 = offset + 12

	if v7 ~= v8 or v9 + v7 > buffer.len(buf) then
		error("parallel certificate actor payload is malformed")
	end

	local v10 = v9 + v2 * 2
	local v11 = v10 + v3 * 12
	local v12 = v11 + v4 * 12
	local v13 = v12 + v5 * 8 * 12
	return v9, v2, v10, v3, v11, v4, v12, v5, v13, v6, v13 + v6 * 8 * 12
end

function v.readActorPair(buf: buffer, p: number, p2: number)
	local v2 = p + (p2 - 1) * 12

	if p2 < 1 or v2 + 12 > buffer.len(buf) then
		error("parallel certificate actor-pair index is out of range")
	end

	local v3 = buffer.readu16(buf, v2 + 4)
	local v4 = buffer.readu32(buf, v2)
	local v5 = buffer.readu8(buf, v2 + 6) + 1
	local v6 = buffer.readu8(buf, v2 + 7) + 1
	local v7 = buffer.readu8(buf, v2 + 8)

	if v3 == 0 then
		return v4, v5, v6, v7, nil
	end

	return v4, v5, v6, v7, v3
end

function v.createResultBatch(value: number, value2: number, value3: number)
	if value3 < 0 or value3 > 65535 then
		error("parallel certificate result count is invalid")
	end

	local buf = buffer.create(value3 * 12 + 16)
	buffer.writeu32(buf, 0, 827477830)
	buffer.writeu16(buf, 4, 2)
	buffer.writeu16(buf, 6, value3)
	buffer.writeu32(buf, 8, value)
	buffer.writeu32(buf, 12, value2)
	return buf
end

function v.writeResult(buf: buffer, p: number, value: number, value2: number, value3: number?, p2: number)
	local v2 = (p - 1) * 12 + 16

	if p < 1 or v2 + 12 > buffer.len(buf) then
		error("parallel certificate result index is out of range")
	end

	buffer.writeu32(buf, v2, value)
	buffer.writeu16(buf, v2 + 4, value3 or 0)
	buffer.writeu16(buf, v2 + 6, (math.clamp(math.floor(p2), 0, 65535)))
	buffer.writeu8(buf, v2 + 8, value2)
end

function v.readResultHeader(buf: buffer)
	if buffer.len(buf) < 16 or buffer.readu32(buf, 0) ~= 827477830 then
		error("parallel certificate result magic is invalid")
	end

	if buffer.readu16(buf, 4) ~= 2 then
		error("parallel certificate result version is unsupported")
	end

	local v2 = buffer.readu16(buf, 6)

	if buffer.len(buf) ~= v2 * 12 + 16 then
		error("parallel certificate result size is invalid")
	end

	return buffer.readu32(buf, 8), buffer.readu32(buf, 12), v2
end

function v.readResult(buf: buffer, p: number)
	local v2 = (p - 1) * 12 + 16

	if p < 1 or v2 + 12 > buffer.len(buf) then
		error("parallel certificate result index is out of range")
	end

	local v3 = buffer.readu16(buf, v2 + 4)
	local v4 = buffer.readu32(buf, v2)
	local v5 = buffer.readu8(buf, v2 + 8)

	if v3 == 0 then
		v3 = nil
	end

	return v4, v5, v3, (buffer.readu16(buf, v2 + 6))
end

v.HEADER_SIZE = 16
v.JOB_HEADER_SIZE = 16
v.RESULT_SIZE = 12
v.VECTOR_SIZE = 12
v.MAX_ACTORS = 64
v.ACTOR_HEADER_SIZE = 24
v.ACTOR_RECORD_HEADER_SIZE = 12
v.ACTOR_PAIR_SIZE = 12
return table.freeze(v)