local parent = script.Parent.Parent
local toSet = require(parent.Array.toSet)

local function removeValues(items, ...)
	local v = toSet({ ... })
	local result = {}

	for k, item in pairs(items) do
		if not v[item] then
			result[k] = item
		end
	end

	return result
end

return removeValues