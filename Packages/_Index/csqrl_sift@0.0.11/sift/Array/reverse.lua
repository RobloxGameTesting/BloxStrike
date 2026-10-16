local function reverse(list)
	local result = {}

	for i = #list, 1, -1 do
		table.insert(result, list[i])
	end

	return result
end

return reverse