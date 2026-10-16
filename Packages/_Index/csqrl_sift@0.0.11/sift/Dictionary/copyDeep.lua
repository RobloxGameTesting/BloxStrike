local function copyDeep(item)
	local clone = table.clone(item)

	for k, item2 in pairs(item) do
		if type(item2) == "table" then
			clone[k] = copyDeep(item2)
		end
	end

	return clone
end

return copyDeep