local createVector = vector.create
local Schema = require(script.Parent.Schema)
local v = table.create(256)
local v2 = {}

for i = 0, 255 do
	local v3 = i

	for _ = 1, 8 do
		local v4 = bit32.rshift(v3, 1)

		if bit32.band(v3, 1) == 0 then
			v3 = v4
		else
			v3 = bit32.bxor(v4, 3988292384)
		end
	end

	v[i + 1] = v3
end

table.freeze(v)

local function updateCrc32(p: number, value: string)
	for i = 1, #value do
		local v3 = bit32.band(bit32.bxor(p, (string.byte(value, i))), 255) + 1
		p = bit32.bxor(bit32.rshift(p, 8), v[v3])
	end

	return p
end

local function finishCrc32(p: number) -- 2 equivalent calls inferred from this helper
	return (bit32.bxor(p, 4294967295))
end

local function isFinite(value) -- 7 equivalent calls inferred from this helper
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

local function quantize(value: number, p: number)
	if not isFinite(value) then -- inferred equivalent call
		return nil, "geometry contains a non-finite component"
	end

	local v3 = math.round(value * p)

	if v3 < -2147483648 or v3 > 2147483647 then
		return nil, "geometry component exceeds the signed fixed-point range"
	end

	return v3 == 0 and 0 or v3, nil
end

local function appendQuantized(list, value: number, p: number)
	local finite = isFinite(value) -- inferred equivalent call
	local v3, v4

	if finite then
		local v5 = math.round(value * p)

		if v5 < -2147483648 or v5 > 2147483647 then
			v4 = "geometry component exceeds the signed fixed-point range"
		else
			v3 = v5 == 0 and 0 or v5
		end
	else
		v4 = "geometry contains a non-finite component"
	end

	if v3 == nil then
		return v4
	end

	list[#list + 1] = v3
	return nil
end

local function encodeRaw(cframe: CFrame, vector: Vector3)
	if typeof(cframe) ~= "CFrame" or typeof(vector) ~= "Vector3" then
		return nil, "geometry requires a CFrame and Vector3 size"
	end

	local v3 = { cframe:GetComponents() }

	for _, v4 in ipairs(v3) do
		if not isFinite(v4) then -- inferred equivalent call
			return nil, "geometry CFrame contains a non-finite component"
		end
	end

	if not isFinite(vector.X) then -- inferred equivalent call
		return nil, "geometry size contains a non-finite component"
	end

	if not (isFinite(vector.Y) and isFinite(vector.Z)) then -- inferred equivalent call
		return nil, "geometry size contains a non-finite component"
	end

	if vector.X < 0 or vector.Y < 0 or vector.Z < 0 then
		return nil, "geometry size cannot be negative"
	end

	local position = cframe.Position
	local rightVector = cframe.RightVector
	local upVector = cframe.UpVector
	local v4 = {
		{ position.X, 4096 },
		{ position.Y, 4096 },
		{ position.Z, 4096 },
		{ rightVector.X, 4096 },
		{ rightVector.Y, 4096 },
		{ rightVector.Z, 4096 },
		{ upVector.X, 4096 },
		{ upVector.Y, 4096 },
		{ upVector.Z, 4096 },
		{ vector.X, 4096 },
		{ vector.Y, 4096 },
		{ vector.Z, 4096 }
	}
	local v5 = {}

	for _, v6 in ipairs(v4) do
		local v7 = v6[1]
		local v8 = v6[2]
		local finite = isFinite(v7) -- inferred equivalent call
		local v9, v10

		if finite then
			local v11 = math.round(v7 * v8)

			if v11 < -2147483648 or v11 > 2147483647 then
				v10 = "geometry component exceeds the signed fixed-point range"
			else
				v9 = v11 == 0 and 0 or v11
			end
		else
			v10 = "geometry contains a non-finite component"
		end

		if v9 ~= nil then
			v5[#v5 + 1] = v9
			v10 = nil
		end

		if v10 ~= nil then
			return nil, v10
		end
	end

	local v6 = table.create(13)
	v6[1] = Schema.CanonicalGeometryVersion

	for i, v7 in ipairs(v5) do
		v6[i + 1] = tostring(v7)
	end

	local joined = table.concat(v6, "|")
	local crc32 = v2.Crc32(joined)
	return string.format("%s|%08x", joined, crc32), nil
end

local function parseCanonicalInteger(value: string?)
	if value == nil or string.match(value, "^%-?%d+$") == nil or value == "-0" then
		return nil
	end

	local v3 = tonumber(value)

	if v3 == nil or v3 % 1 ~= 0 or v3 < -2147483648 or v3 > 2147483647 then
		return nil
	end

	if tostring(v3) == value then
		return v3
	end

	return nil
end

function v2.Crc32(value: string)
	assert(typeof(value) == "string", "CRC32 input must be a string")
	return finishCrc32(updateCrc32(4294967295, value)) -- inferred equivalent call
end

function v2.HashStrings(p)
	local clone = table.clone(p)
	table.sort(clone)
	local v3 = 4294967295

	for _, v4 in ipairs(clone) do
		assert(typeof(v4) == "string", "fingerprint entries must be strings")
		local count = #v4
		assert(count <= 4294967295, "fingerprint entry is too large")
		v3 = updateCrc32(
			updateCrc32(
				v3,
				string.char(
					bit32.band(count, 255),
					bit32.band(bit32.rshift(count, 8), 255),
					bit32.band(bit32.rshift(count, 16), 255),
					(bit32.band(bit32.rshift(count, 24), 255))
				)
			),
			v4
		)
	end

	return finishCrc32(v3) -- inferred equivalent call
end

function v2.TryEncode(cframe: CFrame, vector: Vector3)
	return encodeRaw(cframe, vector)
end

function v2.Encode(cframe: CFrame, vector: Vector3)
	local v3, v4 = encodeRaw(cframe, vector)
	assert(v3 ~= nil, v4)
	return v3
end

function v2.Decode(descriptor)
	if typeof(descriptor) ~= "string" then
		return nil, "canonical geometry descriptor must be a string"
	end

	local v3 = string.split(descriptor, "|")

	if #v3 ~= 14 or v3[1] ~= Schema.CanonicalGeometryVersion then
		return nil, "canonical geometry descriptor has an unsupported shape or version"
	end

	local v4 = v3[14]

	if #v4 ~= 8 or string.match(v4, "^%x+$") == nil or v4 ~= string.lower(v4) then
		return nil, "canonical geometry descriptor has an invalid CRC field"
	end

	local v5 = tonumber(v4, 16)
	local v6 = string.sub(descriptor, 1, #descriptor - 9)

	if v5 == nil or v2.Crc32(v6) ~= v5 then
		return nil, "canonical geometry descriptor CRC does not match"
	end

	local v7 = table.create(12)

	for i = 1, 12 do
		local v8 = parseCanonicalInteger(v3[i + 1])

		if v8 == nil then
			return nil, string.format("canonical geometry field %d is not a canonical i32", i)
		else
			v7[i] = v8
		end
	end

	if v7[10] < 0 or v7[11] < 0 or v7[12] < 0 then
		return nil, "canonical geometry size cannot be negative"
	end

	local v8 = Vector3.new(v7[1], v7[2], v7[3]) / 4096
	local vector = Vector3.new(v7[4], v7[5], v7[6]) / 4096
	local vector2 = Vector3.new(v7[7], v7[8], v7[9]) / 4096
	local magnitude = vector.Magnitude
	local magnitude2 = vector2.Magnitude

	if math.abs(magnitude - 1) > 0.01 or math.abs(magnitude2 - 1) > 0.01 then
		return nil, "canonical geometry axes are not unit length"
	end

	if math.abs((vector:Dot(vector2))) > 0.01 then
		return nil, "canonical geometry axes are not orthogonal"
	end

	local unit = vector.Unit
	local v9 = vector2 - unit * vector2:Dot(unit)

	if v9.Magnitude <= 0.5 then
		return nil, "canonical geometry axes are degenerate"
	end

	local unit2 = unit:Cross(v9.Unit).Unit
	local unit3 = unit2:Cross(unit).Unit
	local size = Vector3.new(v7[10], v7[11], v7[12]) / 4096
	return
		table.freeze({
			CFrame = CFrame.fromMatrix(v8, unit, unit3, unit2),
			Size = size,
			Descriptor = descriptor
		}),
		nil
end

function v2.EncodeInstance(instance)
	if instance:IsA("BasePart") then
		return v2.Encode(instance.CFrame, instance.Size)
	end

	if instance:IsA("Model") then
		return v2.Encode(instance:GetPivot(), createVector(0, 0, 0))
	end

	error("canonical geometry can only be encoded for a BasePart or Model", 2)
end

function v2.Publish(instance)
	local encodeInstance = v2.EncodeInstance(instance)
	instance:SetAttribute(Schema.Attributes.CanonicalGeometry, encodeInstance)
	return encodeInstance
end

function v2.ReadPublished(instance)
	local attribute = instance:GetAttribute(Schema.Attributes.CanonicalGeometry)

	if typeof(attribute) ~= "string" then
		return nil, string.format("%s is missing %s", instance:GetFullName(), Schema.Attributes.CanonicalGeometry)
	end

	local decoded, v3 = v2.Decode(attribute)

	if decoded == nil then
		return
			nil,
			string.format("%s has invalid canonical geometry: %s", instance:GetFullName(), v3 or "unknown error")
	end

	return decoded, nil
end

return table.freeze(v2)