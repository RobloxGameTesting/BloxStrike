local function pop(list, value: number?)
	local result = {}

	for i = 1, #list - (type(value) ~= "number" and 1 or value) do
		table.insert(result, list[i])
	end

	return result
end

return pop