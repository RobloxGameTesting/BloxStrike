local function fromEntries(list)
	local result = {}

	for _, v in ipairs(list) do
		result[v[1]] = v[2]
	end

	return result
end

return fromEntries