local function removeIndices(list, ...)
	local v = #list
	local v2 = {}
	local result = {}

	for _, total in ipairs({ ... }) do
		if total < 1 then
			total += v
		end

		v2[total] = true
	end

	for i, v3 in ipairs(list) do
		if not v2[i] then
			table.insert(result, v3)
		end
	end

	return result
end

return removeIndices