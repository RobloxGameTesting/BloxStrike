local Schema = require(script.Parent.Schema)
local v = {}

local function isUInt32(value) -- 2 equivalent calls inferred from this helper
	return typeof(value) == "number" and value % 1 == 0 and value >= 0 and value <= 4294967295
end

local function validateBits(value: number, value2: string)
	local v2 = math.ceil(value / 8)

	if #value2 ~= v2 then
		return false, string.format("active bitset has %d bytes; expected %d", #value2, v2)
	end

	local v3 = value % 8

	if v3 ~= 0 and v2 > 0 then
		local v4 = string.byte(value2, v2)

		if 2 ^ v3 - 1 < v4 then
			return false, "active bitset has non-zero padding bits"
		end
	end

	return true, nil
end

function v.Validate(value, value2, value3, value4)
	if not isUInt32(value) or value == 0 or Schema.MaxEpoch < value then -- inferred equivalent call
		return false, "epoch must be a non-zero u16"
	end

	if not isUInt32(value2) then -- inferred equivalent call
		return false, "revision must be a u32"
	end

	if typeof(value3) ~= "number" or value3 % 1 ~= 0 or value3 < 0 or Schema.MaxDestructibleCount < value3 then
		return false, string.format("count must be an integer in [0, %d]", Schema.MaxDestructibleCount)
	end

	if typeof(value4) == "string" then
		return validateBits(value3, value4)
	end

	return false, "active bitset must be a string"
end

function v.New(epoch: number, revision: number, count: number, activeBits: string)
	local v2, v3 = v.Validate(epoch, revision, count, activeBits)
	assert(v2, v3)
	return (table.freeze({
		Epoch = epoch,
		Revision = revision,
		Count = count,
		ActiveBits = activeBits
	}))
end

function v.AllActive(p: number, p2: number, p3: number)
	local v2 = p3 % 1 == 0 and p3 >= 0 and p3 <= Schema.MaxDestructibleCount
	assert(v2, "invalid destructible count")
	local v3 = math.floor(p3 / 8)
	local v4 = p3 % 8
	local v5 = string.rep("\255", v3)

	if v4 ~= 0 then
		v5 ..= string.char(2 ^ v4 - 1)
	end

	return v.New(p, p2, p3, v5)
end

function v.IsActive(p, p2: number)
	local v2 = p2 % 1 == 0 and p2 >= 1 and p2 <= p.Count
	assert(v2, "destructible index is outside the frame")
	local v3 = p2 - 1
	local v4 = math.floor(v3 / 8) + 1
	local v5 = v3 % 8
	return bit32.band(string.byte(p.ActiveBits, v4), (bit32.lshift(1, v5))) ~= 0
end

return table.freeze(v)