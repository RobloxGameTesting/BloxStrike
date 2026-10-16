local function flip(items)
	local result = {}

	for k, item in pairs(items) do
		result[item] = k
	end

	return result
end

return flip