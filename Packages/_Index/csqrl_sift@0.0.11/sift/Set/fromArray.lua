local function fromArray(list)
	local result = table.create(#list)

	for _, v in ipairs(list) do
		result[v] = true
	end

	return result
end

return fromArray