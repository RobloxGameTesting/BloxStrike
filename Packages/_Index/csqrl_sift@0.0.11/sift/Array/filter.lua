local parent = script.Parent.Parent
local Util = require(parent.Util)

local function filter(list, truthy)
	local result = {}

	if type(truthy) ~= "function" then
		truthy = Util.func.truthy
	end

	for i, v in ipairs(list) do
		if truthy(v, i, list) then
			table.insert(result, v)
		end
	end

	return result
end

return filter