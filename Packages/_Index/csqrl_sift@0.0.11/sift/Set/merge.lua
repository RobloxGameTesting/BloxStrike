local function merge(...)
	local result = {}

	for i = 1, select("#", ...) do
		local v = select(i, ...)

		if type(v) ~= "table" then
			continue
		end

		for k, _ in pairs(v) do
			result[k] = true
		end
	end

	return result
end

return merge