local EncodingService = game:GetService("EncodingService")

local function base64Encode(value: string)
	local v = table.create(math.ceil(#value / 3) * 4)
	local total = 1

	while total <= #value do
		local v2 = string.byte(value, total) or 0
		local v3 = string.byte(value, total + 1) or 0
		local v4 = string.byte(value, total + 2) or 0
		local v5 = v2 * 65536 + v3 * 256 + v4
		v[#v + 1] = string.sub(
			"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
			math.floor(v5 / 262144) % 64 + 1,
			math.floor(v5 / 262144) % 64 + 1
		)
		v[#v + 1] = string.sub(
			"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
			math.floor(v5 / 4096) % 64 + 1,
			math.floor(v5 / 4096) % 64 + 1
		)
		v[#v + 1] = not (total + 1 <= #value) and "="
			or string.sub(
				"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",
				math.floor(v5 / 64) % 64 + 1,
				math.floor(v5 / 64) % 64 + 1
			)
		v[#v + 1] = not (total + 2 <= #value) and "="
			or string.sub("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", v5 % 64 + 1, v5 % 64 + 1)
		total += 3
	end

	return table.concat(v)
end

local function base64Decode(str: string)
	if #str == 0 or #str % 4 ~= 0 then
		return nil
	end

	local success, result = pcall(function()
		return buffer.tostring(EncodingService:Base64Decode(buffer.fromstring(str)))
	end)

	if success then
		return result
	end

	return nil
end

local function writePayload(parent, list: string, fingerprint: string, name: string, format: string)
	if #list < 1 or #list > 67108864 then
		error(`Static occlusion payload is outside the runtime storage limit (1-{67108864} bytes)`)
	end

	local child = parent:FindFirstChild(name)

	if child then
		child:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder:SetAttribute("Format", format)
	folder:SetAttribute("Encoding", "Base64")
	folder:SetAttribute("Fingerprint", fingerprint)
	folder:SetAttribute("ByteCount", #list)
	local v = base64Encode(list)
	folder:SetAttribute("EncodedByteCount", #v)
	local v2 = math.max(math.ceil(#v / 160000), 1)
	folder:SetAttribute("ChunkCount", v2)

	for i = 1, v2 do
		local stringValue = Instance.new("StringValue")
		stringValue.Name = `Chunk{string.format("%04d", i)}`
		local v3 = (i - 1) * 160000 + 1
		stringValue.Value = string.sub(v, v3, (math.min(v3 + 160000 - 1, #v)))
		stringValue.Parent = folder
	end

	folder.Parent = parent
end

local function readPayload(instance, p: string?, callback, childName: string, p2: string)
	local folder = instance:FindFirstChild(childName)

	if folder == nil or not folder:IsA("Folder") then
		return nil, "MissingPVSStaticOcclusion"
	end

	if folder:GetAttribute("Format") ~= p2 then
		return nil, "UnsupportedPVSStaticOcclusionFormat"
	end

	if folder:GetAttribute("Encoding") ~= "Base64" then
		return nil, "UnsupportedPVSStaticOcclusionEncoding"
	end

	local fingerprint = folder:GetAttribute("Fingerprint")

	if typeof(fingerprint) ~= "string" or #fingerprint == 0 then
		return nil, "MissingPVSStaticOcclusionFingerprint"
	end

	if p ~= nil and fingerprint ~= p then
		return nil, "PVSStaticOcclusionFingerprintMismatch"
	end

	local chunkCount = folder:GetAttribute("ChunkCount")
	local byteCount = folder:GetAttribute("ByteCount")
	local encodedByteCount = folder:GetAttribute("EncodedByteCount")

	if
		typeof(chunkCount) ~= "number"
		or chunkCount < 1
		or chunkCount > 560
		or chunkCount % 1 ~= 0
		or typeof(byteCount) ~= "number"
		or byteCount < 1
		or byteCount > 67108864
		or byteCount % 1 ~= 0
		or typeof(encodedByteCount) ~= "number"
		or encodedByteCount < 1
		or encodedByteCount > 89478488
		or encodedByteCount % 1 ~= 0
	then
		return nil, "InvalidPVSStaticOcclusionManifest"
	end

	local v = table.create(chunkCount)
	local total = 0
	local total2 = 0

	for i = 1, chunkCount do
		if callback then
			callback()
		end

		local stringValue = folder:FindFirstChild(`Chunk{string.format("%04d", i)}`)

		if stringValue == nil or not stringValue:IsA("StringValue") then
			return nil, `MissingPVSStaticOcclusionChunk:{i}`
		end

		local value = stringValue.Value
		local count = #value

		if count == 0 or count > 160000 or count % 4 ~= 0 then
			return nil, `InvalidPVSStaticOcclusionChunk:{i}`
		end

		total += count

		if encodedByteCount < total then
			return nil, "PVSStaticOcclusionByteCountMismatch"
		end

		local result

		if not (#value == 0 or #value % 4 ~= 0) then
			local success
			success, result = pcall(function()
				return buffer.tostring(EncodingService:Base64Decode(buffer.fromstring(value)))
			end)

			if not success then
				result = nil
			end
		end

		if result == nil then
			return nil, `PVSStaticOcclusionBase64DecodeFailed:{i}`
		end

		v[i] = result
		total2 += #result

		if byteCount < total2 then
			return nil, "PVSStaticOcclusionByteCountMismatch"
		end
	end

	if total == encodedByteCount and total2 == byteCount then
		return table.concat(v), nil
	end

	return nil, "PVSStaticOcclusionByteCountMismatch"
end

return table.freeze({
	write = function(parent, p: string, p2: string)
		writePayload(parent, p, p2, "PVSStaticOcclusion", "PVBVH1")
	end,
	read = function(p, p2: string?, callback)
		return readPayload(p, p2, callback, "PVSStaticOcclusion", "PVBVH1")
	end,
	writeProofs = function(parent, list: string, p: string)
		assert(#list <= 8388608, "geometry proof sidecar exceeds 8 MiB")
		writePayload(parent, list, p, "PVSGeometryProofs", "PVSPRF1")
	end,
	readProofs = function(instance, p: string?, callback)
		local pvsGeometryProofs = instance:FindFirstChild("PVSGeometryProofs")

		if pvsGeometryProofs == nil then
			return nil, nil
		end

		local byteCount = pvsGeometryProofs:GetAttribute("ByteCount")

		if typeof(byteCount) == "number" and not (byteCount > 8388608) then
			return readPayload(instance, p, callback, "PVSGeometryProofs", "PVSPRF1")
		end

		return nil, "InvalidGeometryProofSize"
	end,
	FOLDER_NAME = "PVSStaticOcclusion",
	MAX_RAW_BYTES = 67108864
})