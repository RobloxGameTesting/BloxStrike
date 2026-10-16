local function entries(items)
	local result = {}

	for k, item in pairs(items) do
		table.insert(result, { k, item })
	end

	return result
end

return entries