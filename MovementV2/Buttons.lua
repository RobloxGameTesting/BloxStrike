local v = { Jump = 1, Duck = 2, Walk = 4, Scoped = 8 }
v.ValidMask = 15

function v.isValid(value)
	return typeof(value) == "number"
		and value % 1 == 0
		and value >= 0
		and value <= 255
		and bit32.band(value, (bit32.bnot(v.ValidMask))) == 0
end

function v.has(p: number, p2: number)
	return bit32.band(p, p2) ~= 0
end

function v.with(p: number, p2: number, flag: boolean)
	if flag then
		return (bit32.bor(p, p2))
	end

	return (bit32.band(p, (bit32.bnot(p2))))
end

return table.freeze(v)