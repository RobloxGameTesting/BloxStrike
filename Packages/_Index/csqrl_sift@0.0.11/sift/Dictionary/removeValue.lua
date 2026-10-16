local function removeValue(items, p)
	local result = {}

	for k, item in pairs(items) do
		if item ~= p then
			result[k] = item
		end
	end

	return result
end

return removeValue