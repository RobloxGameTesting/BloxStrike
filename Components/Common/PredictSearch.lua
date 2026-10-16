local function distanceWithin(value: string, item: string, p: number)
	if p < math.abs(#value - #item) then
		return p + 1
	end

	local v = {}
	local v2 = {}

	for i = 0, #item do
		v[i] = i
	end

	for i = 1, #value do
		v2[0] = i
		local v3 = i

		for j = 1, #item do
			local v4 = string.byte(value, i) == string.byte(item, j) and 0 or 1
			v2[j] = math.min(v[j] + 1, v2[j - 1] + 1, v[j - 1] + v4)
			v3 = math.min(v3, v2[j])
		end

		if p < v3 then
			return p + 1
		end

		v, v2 = v2, v
	end

	return v[#item]
end

return function(items, list: string, p: number)
	if list == "" then
		return nil
	end

	local v = 1e999
	local v2 = 1e999
	local v3 = nil

	for _, item in items do
		local v4 = 1e999
		local v5 = 1e999
		local v6 = string.find(item, list, 1, true)

		if v6 == 1 then
			v5 = #item
			v4 = 1
		elseif v6 then
			v5 = v6
			v4 = 2
		elseif v >= 3 and p <= #list then
			local v7 = distanceWithin(list, item, 3)

			if v7 <= 3 then
				v5 = v7
				v4 = 3
			end
		end

		if not (v4 < v or v4 == v and v5 < v2) then
			continue
		end

		v3 = item
		v2 = v5
		v = v4
	end

	return v3
end