local function map(items, callback)
	local result = {}

	for k, _ in pairs(items) do
		local v = callback(k, items)

		if v ~= nil then
			result[v] = true
		end
	end

	return result
end

return map