local function add(items, ...)
	local result = {}

	for k, _ in pairs(items) do
		result[k] = true
	end

	for _, v in ipairs({ ... }) do
		result[v] = true
	end

	return result
end

return add