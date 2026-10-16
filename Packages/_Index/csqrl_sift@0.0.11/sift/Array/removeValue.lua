local function removeValue(list, p)
	local result = {}

	for _, v in ipairs(list) do
		if v ~= p then
			table.insert(result, v)
		end
	end

	return result
end

return removeValue