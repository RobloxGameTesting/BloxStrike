local parent = script.Parent.Parent
local Util = require(parent.Util)

local function filter(items, truthy)
	local result = {}

	if type(truthy) ~= "function" then
		truthy = Util.func.truthy
	end

	for k, item in pairs(items) do
		if truthy(item, k, items) then
			result[k] = item
		end
	end

	return result
end

return filter