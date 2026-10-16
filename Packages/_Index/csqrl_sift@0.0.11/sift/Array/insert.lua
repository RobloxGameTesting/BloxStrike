local function insert(list, p: number, ...)
	local count = #list

	if p < 1 then
		p += count + 1
	end

	if count < p then
		if count + 1 < p then
			return list
		end

		p = count + 1
		count += 1
	end

	local result = {}

	for i = 1, count do
		if i == p then
			for _, v in ipairs({ ... }) do
				table.insert(result, v)
			end
		end

		table.insert(result, list[i])
	end

	return result
end

return insert