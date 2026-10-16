local parent = script.Parent.Parent
local Util = require(parent.Util)

local function count(items, truthy)
	local count2 = 0

	if type(truthy) ~= "function" then
		truthy = Util.func.truthy
	end

	for k, item in pairs(items) do
		if truthy(item, k, items) then
			count2 += 1
		end
	end

	return count2
end

return count