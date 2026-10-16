local function set(list, total: number, p)
	local v = #list
	local result = {}

	if total < 1 then
		total += v
	end

	for i, v2 in ipairs(list) do
		if i == total then
			table.insert(result, p)
		else
			table.insert(result, v2)
		end
	end

	return result
end

return set