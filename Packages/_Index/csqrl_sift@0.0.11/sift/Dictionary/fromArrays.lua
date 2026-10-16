local function fromArrays(list, list2)
	local result = {}

	for i = 1, #list do
		result[list[i]] = list2[i]
	end

	return result
end

return fromArrays