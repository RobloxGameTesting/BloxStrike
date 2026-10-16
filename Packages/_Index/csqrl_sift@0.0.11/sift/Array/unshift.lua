local function unshift(list, ...)
	local result = { ... }

	for _, v in ipairs(list) do
		table.insert(result, v)
	end

	return result
end

return unshift