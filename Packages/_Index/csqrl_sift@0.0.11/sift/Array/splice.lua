local function splice(list, value: number?, value2: number?, ...)
	local count = #list
	local result = {}
	local v = type(value) ~= "number" and 1 or value

	if type(value2) ~= "number" then
		value2 = count
	end

	if v < 1 then
		v += count
	end

	if value2 < 1 then
		value2 += count
	end

	for i = 1, v - 1 do
		table.insert(result, list[i])
	end

	for _, v2 in ipairs({ ... }) do
		table.insert(result, v2)
	end

	for i = value2 + 1, count do
		table.insert(result, list[i])
	end

	return result
end

return splice