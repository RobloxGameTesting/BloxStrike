local function map(items, callback)
	local result = {}

	for k, item in pairs(items) do
		local v, v2 = callback(item, k, items)
		result[v2 or k] = v
	end

	return result
end

return map