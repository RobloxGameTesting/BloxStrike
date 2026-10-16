local function intersection(...)
	local v = select("#", ...)
	local v2 = select(1, ...)
	local result = {}

	for k, _ in pairs(v2) do
		local flag = true

		for i = 2, v do
			if select(i, ...)[k] == true then
				continue
			end

			flag = false
			break
		end

		if flag then
			result[k] = true
		end
	end

	return result
end

return intersection