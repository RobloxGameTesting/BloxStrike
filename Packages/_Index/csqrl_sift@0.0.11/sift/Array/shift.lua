local function shift(list, value: number?)
	local v = #list
	local result = {}

	for i = type(value) ~= "number" and 2 or value + 1, v do
		table.insert(result, list[i])
	end

	return result
end

return shift