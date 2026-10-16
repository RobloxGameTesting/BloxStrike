local toSet = require(script.Parent.toSet)

local function removeValues(list, ...)
	local v = toSet({ ... })
	local result = {}

	for _, v2 in ipairs(list) do
		if not v[v2] then
			table.insert(result, v2)
		end
	end

	return result
end

return removeValues