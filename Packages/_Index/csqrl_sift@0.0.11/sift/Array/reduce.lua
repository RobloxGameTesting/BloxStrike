local function reduce(list, callback, p)
	local v

	if p == nil then
		p = list[1]
		v = 2
	else
		v = 1
	end

	for i = v, #list do
		p = callback(p, list[i], i, list)
	end

	return p
end

return reduce