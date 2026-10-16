local parent = script.Parent.Parent
local Util = require(parent.Util)

local function filter(items, truthy)
	local result = {}

	if type(truthy) ~= "function" then
		truthy = Util.func.truthy
	end

	for k, _ in pairs(items) do
		if truthy(k, items) then
			result[k] = true
		end
	end

	return result
end

return filter