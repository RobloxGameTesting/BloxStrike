local success, service = pcall(game.GetService, game, "EncodingService")

if not success then
	service = nil
end

local BufferCodec = {}
local Zstd = Enum.CompressionAlgorithm.Zstd
local RunService = game:GetService("RunService")
local isServer = RunService:IsServer()
local v = isServer and 33554432 or 268435456

local function ensureCapacity(state, p: number)
	local v2 = state.offset + p
	local v3 = buffer.len(state.buf)

	if v2 <= v3 then
		return
	end

	local v4 = math.max(v3 * 2, v2)
	local buf = buffer.create(v4)
	buffer.copy(buf, 0, state.buf, 0, state.offset)
	state.buf = buf
end

local function writeU8(state, value: number) -- 13 equivalent calls inferred from this helper
	ensureCapacity(state, 1)
	buffer.writeu8(state.buf, state.offset, value)
	state.offset += 1
end

local function writeU32(state, value: number) -- 5 equivalent calls inferred from this helper
	ensureCapacity(state, 4)
	buffer.writeu32(state.buf, state.offset, value)
	state.offset += 4
end

local function writeF64(state, cframe: number) -- 1 equivalent call inferred from this helper
	ensureCapacity(state, 8)
	buffer.writef64(state.buf, state.offset, cframe)
	state.offset += 8
end

local function writeF32(state, value: number) -- 20 equivalent calls inferred from this helper
	ensureCapacity(state, 4)
	buffer.writef32(state.buf, state.offset, value)
	state.offset += 4
end

local function writeBytes(state, str: string) -- 3 equivalent calls inferred from this helper
	local count = #str
	writeU32(state, count) -- inferred equivalent call

	if count == 0 then
		return
	end

	ensureCapacity(state, count)
	buffer.writestring(state.buf, state.offset, str, count)
	state.offset += count
end

local function isArray(cframe)
	local count = 0

	for k in pairs(cframe) do
		if typeof(k) ~= "number" or k < 1 or k % 1 ~= 0 then
			return false
		end

		count += 1
	end

	return count == #cframe
end

local function internInstance(p, p2)
	local v2 = p.instanceIndex[p2]

	if v2 then
		return v2
	end

	local v3 = #p.instances + 1
	p.instances[v3] = p2
	p.instanceIndex[p2] = v3
	return v3
end

local function fn(state, cframe)
	local typeName = typeof(cframe)

	if cframe == nil then
		writeU8(state, 0) -- inferred equivalent call
	elseif typeName == "boolean" then
		ensureCapacity(state, 1)
		buffer.writeu8(state.buf, state.offset, cframe and 2 or 1)
		state.offset += 1
	elseif typeName == "number" then
		writeU8(state, 3) -- inferred equivalent call
		writeF64(state, cframe) -- inferred equivalent call
	elseif typeName == "string" then
		writeU8(state, 4) -- inferred equivalent call
		writeBytes(state, cframe) -- inferred equivalent call
	elseif typeName == "Vector3" then
		writeU8(state, 7) -- inferred equivalent call
		writeF32(state, cframe.X) -- inferred equivalent call
		writeF32(state, cframe.Y) -- inferred equivalent call
		writeF32(state, cframe.Z) -- inferred equivalent call
	elseif typeName == "Vector2" then
		writeU8(state, 8) -- inferred equivalent call
		writeF32(state, cframe.X) -- inferred equivalent call
		writeF32(state, cframe.Y) -- inferred equivalent call
	elseif typeName == "CFrame" then
		writeU8(state, 9) -- inferred equivalent call
		local components, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12 = cframe:GetComponents()
		writeF32(state, components) -- inferred equivalent call
		writeF32(state, v2) -- inferred equivalent call
		writeF32(state, v3) -- inferred equivalent call
		writeF32(state, v4) -- inferred equivalent call
		writeF32(state, v5) -- inferred equivalent call
		writeF32(state, v6) -- inferred equivalent call
		writeF32(state, v7) -- inferred equivalent call
		writeF32(state, v8) -- inferred equivalent call
		writeF32(state, v9) -- inferred equivalent call
		writeF32(state, v10) -- inferred equivalent call
		writeF32(state, v11) -- inferred equivalent call
		writeF32(state, v12) -- inferred equivalent call
	elseif typeName == "Color3" then
		writeU8(state, 10) -- inferred equivalent call
		writeF32(state, cframe.R) -- inferred equivalent call
		writeF32(state, cframe.G) -- inferred equivalent call
		writeF32(state, cframe.B) -- inferred equivalent call
	elseif typeName == "EnumItem" then
		writeU8(state, 11) -- inferred equivalent call
		writeBytes(state, cframe.EnumType.Name) -- inferred equivalent call
		writeBytes(state, cframe.Name) -- inferred equivalent call
	elseif typeName == "Instance" then
		writeU8(state, 12) -- inferred equivalent call
		local v2 = state.instanceIndex[cframe]

		if not v2 then
			v2 = #state.instances + 1
			state.instances[v2] = cframe
			state.instanceIndex[cframe] = v2
		end

		writeU32(state, v2) -- inferred equivalent call
	elseif typeName == "buffer" then
		writeU8(state, 13) -- inferred equivalent call
		local v2 = buffer.len(cframe)
		writeU32(state, v2) -- inferred equivalent call
		ensureCapacity(state, v2)
		buffer.copy(state.buf, state.offset, cframe, 0, v2)
		state.offset += v2
	else
		if typeName == "table" and not state.visited[cframe] then
			state.visited[cframe] = true

			if isArray(cframe) then
				writeU8(state, 5) -- inferred equivalent call
				writeU32(state, #cframe) -- inferred equivalent call

				for i = 1, #cframe do
					fn(state, cframe[i])
				end

				return
			else
				local v2 = {}

				for k, v3 in pairs(cframe) do
					table.insert(v2, k)
					table.insert(v2, v3)
				end

				writeU8(state, 6) -- inferred equivalent call
				writeU32(state, #v2 // 2) -- inferred equivalent call

				for i = 1, #v2, 2 do
					fn(state, v2[i])
					fn(state, v2[i + 1])
				end

				return
			end
		end

		writeU8(state, 0) -- inferred equivalent call
	end
end

local function finishWriter(p) -- 1 equivalent call inferred from this helper
	local buf = buffer.create(p.offset)

	if p.offset > 0 then
		buffer.copy(buf, 0, p.buf, 0, p.offset)
	end

	return buf
end

local function compress(buf: buffer)
	local success2, result = pcall(function()
		if not service then
			error("EncodingService unavailable")
		end

		return service:CompressBuffer(buf, Zstd, 1)
	end)

	if success2 and typeof(result) == "buffer" then
		local buf2 = buffer.create(1 + buffer.len(result))
		buffer.writeu8(buf2, 0, 1)
		buffer.copy(buf2, 1, result)
		return buf2
	else
		local buf2 = buffer.create(1 + buffer.len(buf))
		buffer.writeu8(buf2, 0, 0)
		buffer.copy(buf2, 1, buf)
		return buf2
	end
end

local function sliceBuffer(source: buffer, sourceOffset: number, size: number) -- 1 equivalent call inferred from this helper
	local buf = buffer.create(size)

	if size > 0 then
		buffer.copy(buf, 0, source, sourceOffset, size)
	end

	return buf
end

local function decompress(buf: buffer)
	if buffer.len(buf) < 1 then
		return nil
	end

	local v2 = buffer.readu8(buf, 0)
	local buf2 = sliceBuffer(buf, 1, buffer.len(buf) - 1) -- inferred equivalent call

	if v2 == 0 then
		return buf2
	end

	if not (v2 == 1 and service) then
		return nil
	end

	local success2, result = pcall(function()
		return service:GetDecompressedBufferSize(buf2, Zstd)
	end)

	if success2 and typeof(result) == "number" and not (v < result) then
		local success3, result2 = pcall(function()
			return service:DecompressBuffer(buf2, Zstd)
		end)

		if success3 and typeof(result2) == "buffer" then
			return result2
		end

		return nil
	else
		if not isServer and success2 and typeof(result) == "number" then
			warn(`[BufferCodec] Dropped {result} byte packet (cap {v})`)
		end

		return nil
	end
end

local function remaining(state) -- 6 equivalent calls inferred from this helper
	return state.length - state.offset
end

local function readU8(state) -- 1 equivalent call inferred from this helper
	if remaining(state) < 1 then -- inferred equivalent call
		error("truncated u8")
	end

	local v2 = buffer.readu8(state.buf, state.offset)
	state.offset += 1
	return v2
end

local function readU32(state) -- 5 equivalent calls inferred from this helper
	if remaining(state) < 4 then -- inferred equivalent call
		error("truncated u32")
	end

	local v2 = buffer.readu32(state.buf, state.offset)
	state.offset += 4
	return v2
end

local function readF64(state) -- 1 equivalent call inferred from this helper
	if remaining(state) < 8 then -- inferred equivalent call
		error("truncated f64")
	end

	local v2 = buffer.readf64(state.buf, state.offset)
	state.offset += 8
	return v2
end

local function readF32(state) -- 20 equivalent calls inferred from this helper
	if remaining(state) < 4 then -- inferred equivalent call
		error("truncated f32")
	end

	local v2 = buffer.readf32(state.buf, state.offset)
	state.offset += 4
	return v2
end

local function readBytes(state)
	local u32 = readU32(state) -- inferred equivalent call

	if u32 < 0 or remaining(state) < u32 then -- inferred equivalent call
		error("truncated string")
	end

	if u32 == 0 then
		return ""
	end

	local v2 = buffer.readstring(state.buf, state.offset, u32)
	state.offset += u32
	return v2
end

local function fn2(state)
	local u8 = readU8(state) -- inferred equivalent call

	if u8 == 0 then
		return nil
	elseif u8 == 1 then
		return false
	elseif u8 == 2 then
		return true
	end

	if u8 == 3 then
		return readF64(state) -- inferred equivalent call
	else
		if u8 == 4 then
			return (readBytes(state))
		end

		if u8 == 7 then
			return (Vector3.new(readF32(state), readF32(state), readF32(state))) -- inferred equivalent call
		elseif u8 == 8 then
			return Vector2.new(readF32(state), readF32(state)) -- inferred equivalent call
		elseif u8 == 9 then
			return CFrame.new(
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state), -- inferred equivalent call
				readF32(state) -- inferred equivalent call
			)
		elseif u8 == 10 then
			return Color3.new(readF32(state), readF32(state), readF32(state)) -- inferred equivalent call
		elseif u8 == 11 then
			local v2 = readBytes(state)
			local v3 = readBytes(state)
			local v4 = Enum[v2]

			if typeof(v4) ~= "Enum" then
				return nil
			end

			local success2, result = pcall(function()
				return v4[v3]
			end)

			if success2 then
				return result
			end

			return nil
		elseif u8 == 12 then
			return state.instances[readU32(state)] -- inferred equivalent call
		elseif u8 == 13 then
			local u32 = readU32(state) -- inferred equivalent call

			if remaining(state) < u32 then -- inferred equivalent call
				error("truncated nested buffer")
			end

			local buf = buffer.create(u32)

			if u32 > 0 then
				buffer.copy(buf, 0, state.buf, state.offset, u32)
			end

			state.offset += u32
			return buf
		elseif u8 == 5 then
			local u32 = readU32(state) -- inferred equivalent call
			local result = table.create(u32)

			for i = 1, u32 do
				result[i] = fn2(state)
			end

			return result
		else
			if u8 ~= 6 then
				error("unknown type tag")
				return
			end

			local u32 = readU32(state) -- inferred equivalent call
			local result = {}

			for _ = 1, u32 do
				result[fn2(state)] = fn2(state)
			end

			return result
		end
	end
end

function BufferCodec.Encode(p)
	local v2 = {
		buf = buffer.create(256),
		offset = 0,
		instances = {},
		instanceIndex = {},
		visited = {}
	}
	fn(v2, p)
	return compress(finishWriter(v2)), v2.instances -- inferred equivalent call
end

function BufferCodec.Decode(p, p2)
	if typeof(p) ~= "buffer" then
		return false, nil
	end

	local buf = decompress(p)

	if not buf then
		return false, nil
	end

	local v2 = {
		buf = buf,
		offset = 0,
		length = buffer.len(buf),
		instances = typeof(p2) ~= "table" and {} or p2
	}
	local success2, result = pcall(fn2, v2)

	if success2 then
		return true, result
	end

	return false, nil
end

return BufferCodec