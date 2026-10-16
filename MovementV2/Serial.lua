local v = { UInt16Max = 65535, UInt32Max = 4294967295 }

function v.isUInt16(value)
	return typeof(value) == "number" and value % 1 == 0 and value >= 0 and value <= v.UInt16Max
end

function v.isNonZeroUInt16(p)
	return v.isUInt16(p) and p > 0
end

function v.isUInt32(value)
	return typeof(value) == "number" and value % 1 == 0 and value >= 0 and value <= v.UInt32Max
end

function v.deltaUInt32(p: number, p2: number)
	local v2 = (p - p2) % 4294967296

	if v2 >= 2147483648 then
		return v2 - 4294967296
	end

	return v2
end

function v.deltaUInt16(p: number, p2: number)
	local v2 = (p - p2) % 65536

	if v2 >= 32768 then
		return v2 - 65536
	end

	return v2
end

function v.addUInt32(p: number, p2: number)
	return (p + p2) % 4294967296
end

function v.isNewerUInt32(p: number, p2: number)
	return v.isUInt32(p) and v.isUInt32(p2) and v.deltaUInt32(p, p2) > 0
end

return table.freeze(v)