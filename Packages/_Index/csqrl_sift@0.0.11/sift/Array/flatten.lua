local function flatten(list, value: number?)
	local v = type(value) ~= "number" and 1e999 or value
	local result = {}

	for _, v2 in ipairs(list) do
		if type(v2) == "table" and v > 0 then
			local v3 = flatten(v2, v - 1)

			for _, v4 in ipairs(v3) do
				table.insert(result, v4)
			end
		else
			table.insert(result, v2)
		end
	end

	return result
end

return flatten