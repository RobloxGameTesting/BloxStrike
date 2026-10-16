local function values(items)
	local result = {}

	for _, item in pairs(items) do
		table.insert(result, item)
	end

	return result
end

return values