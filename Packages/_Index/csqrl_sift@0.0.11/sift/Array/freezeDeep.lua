local function freezeDeep(list)
	local result = {}

	for i = 1, #list do
		local v = list[i]

		if type(v) == "table" then
			table.insert(result, freezeDeep(v))
		else
			table.insert(result, v)
		end
	end

	table.freeze(result)
	return result
end

return freezeDeep