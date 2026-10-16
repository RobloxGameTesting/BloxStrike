local Serial = require(script.Parent.Serial)
local v = { AnchorWireSize = 8 }

local function isUInt8(tickAge) -- 1 equivalent call inferred from this helper
	return type(tickAge) == "number" and tickAge % 1 == 0 and tickAge >= 0 and tickAge <= 255
end

local function isUInt16(value) -- 3 equivalent calls inferred from this helper
	return type(value) == "number" and value % 1 == 0 and value >= 0 and value <= Serial.UInt16Max
end

local function isDenseArray(list, p: number, flag: boolean?)
	if type(list) ~= "table" or p < #list or #list == 0 and flag ~= true then
		return false
	end

	for k in list do
		if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or #list < k then
			return false
		end
	end

	return true
end

function v.validateStreams(items)
	if not isDenseArray(items, 64) then
		return false, "InvalidMoverProgressStreamCount"
	end

	local id = 0
	local total = 0

	for _, item in items do
		if type(item) ~= "table" or not Serial.isUInt32(item.Id) or item.Id == 0 or item.Id <= id then
			return false, "MoverProgressStreamsNotStrictlySorted"
		end

		id = item.Id

		if not isDenseArray(item.Samples, 255) then
			return false, "InvalidMoverProgressSampleCount"
		end

		total += #item.Samples

		if total > 1024 then
			return false, "MoverProgressSampleLimit"
		end

		local tickAge = 256

		for _, sample in item.Samples do
			if type(sample) ~= "table" then
				return false, "InvalidMoverProgressTickAge"
			end

			if not isUInt8(sample.TickAge) then -- inferred equivalent call
				return false, "InvalidMoverProgressTickAge"
			end

			if tickAge <= sample.TickAge then
				return false, "MoverProgressSamplesNotChronological"
			end

			tickAge = sample.TickAge

			if not isUInt16(sample.ProgressQ) then -- inferred equivalent call
				return false, "InvalidMoverProgressValue"
			end

			continue
		end
	end

	return true, nil
end

function v.streamsWireSize(items)
	local v2, v3 = v.validateStreams(items)
	assert(v2, v3)
	local total = 0

	for _, item in items do
		total += #item.Samples * 3 + 5
	end

	return total
end

function v.writeStreamsValidated(buf: buffer, offset: number, items)
	for _, item in items do
		buffer.writeu32(buf, offset, item.Id)
		buffer.writeu8(buf, offset + 4, #item.Samples)
		offset += 5

		for _, sample in item.Samples do
			buffer.writeu8(buf, offset, sample.TickAge)
			buffer.writeu16(buf, offset + 1, sample.ProgressQ)
			offset += 3
		end
	end

	return offset
end

function v.readStreams(buf: buffer, offset: number, p: number)
	if p < 1 or p > 64 then
		return nil, offset, "InvalidMoverProgressStreamCount"
	end

	local result = table.create(p)
	local total = 0

	for i = 1, p do
		if buffer.len(buf) - offset < 5 then
			return nil, offset, "MoverProgressPayloadSize"
		end

		local id = buffer.readu32(buf, offset)
		local v2 = buffer.readu8(buf, offset + 4)
		offset += 5

		if v2 < 1 or v2 > 255 then
			return nil, offset, "InvalidMoverProgressSampleCount"
		end

		total += v2

		if total > 1024 or buffer.len(buf) - offset < v2 * 3 then
			return nil, offset, "MoverProgressPayloadSize"
		end

		local samples = table.create(v2)

		for j = 1, v2 do
			samples[j] = {
				TickAge = buffer.readu8(buf, offset),
				ProgressQ = buffer.readu16(buf, offset + 1)
			}
			offset += 3
		end

		result[i] = { Id = id, Samples = samples }
	end

	local v2, v3 = v.validateStreams(result)

	if v2 then
		return result, offset, nil
	end

	return nil, offset, v3
end

function v.validateAnchors(items, flag: boolean?)
	if not isDenseArray(items, 64, flag) then
		return false, "InvalidMoverProgressAnchorCount"
	end

	local id = 0

	for _, item in items do
		if type(item) ~= "table" or not Serial.isUInt32(item.Id) or item.Id == 0 or item.Id <= id then
			return false, "MoverProgressAnchorsNotStrictlySorted"
		end

		id = item.Id

		if isUInt16(item.PreviousProgressQ) and isUInt16(item.CurrentProgressQ) then -- inferred equivalent call
			continue
		end

		return false, "InvalidMoverProgressAnchorValue"
	end

	return true, nil
end

function v.writeAnchorsValidated(buf: buffer, offset: number, items)
	for _, item in items do
		buffer.writeu32(buf, offset, item.Id)
		buffer.writeu16(buf, offset + 4, item.PreviousProgressQ)
		buffer.writeu16(buf, offset + 6, item.CurrentProgressQ)
		offset += 8
	end

	return offset
end

function v.readAnchors(buf: buffer, offset: number, p: number)
	if p < 0 or p > 64 or buffer.len(buf) - offset < p * 8 then
		return nil, offset, "MoverProgressAnchorPayloadSize"
	end

	local result = table.create(p)

	for i = 1, p do
		result[i] = {
			Id = buffer.readu32(buf, offset),
			PreviousProgressQ = buffer.readu16(buf, offset + 4),
			CurrentProgressQ = buffer.readu16(buf, offset + 6)
		}
		offset += 8
	end

	local v2, v3 = v.validateAnchors(result, true)

	if v2 then
		return result, offset, nil
	end

	return nil, offset, v3
end

return table.freeze(v)