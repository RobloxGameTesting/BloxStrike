local function keys(items)
	local result = {}

	for k in pairs(items) do
		table.insert(result, k)
	end

	return result
end

return keys