local parent = script.Parent.Parent
local Util = require(parent.Util)

local function count(list, truthy)
	local count2 = 0

	if type(truthy) ~= "function" then
		truthy = Util.func.truthy
	end

	for i, v in ipairs(list) do
		if truthy(v, i, list) then
			count2 += 1
		end
	end

	return count2
end

return count