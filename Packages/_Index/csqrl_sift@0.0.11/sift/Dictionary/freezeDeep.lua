require(script.Parent.Parent.Types)
local function freezeDeep(item)
	local result = {}

	for k, item2 in pairs(item) do
		if type(item2) == "table" then
			result[k] = freezeDeep(item2)
		else
			result[k] = item2
		end
	end

	table.freeze(result)
	return result
end

return freezeDeep