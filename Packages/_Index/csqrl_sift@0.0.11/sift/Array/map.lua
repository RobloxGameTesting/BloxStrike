local function map(list, callback)
	local result = {}

	for i, v in ipairs(list) do
		local v2 = callback(v, i, list)

		if v2 ~= nil then
			table.insert(result, v2)
		end
	end

	return result
end

return map