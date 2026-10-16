local function withKeys(p, ...)
	local result = {}

	for _, v in ipairs({ ... }) do
		result[v] = p[v]
	end

	return result
end

return withKeys