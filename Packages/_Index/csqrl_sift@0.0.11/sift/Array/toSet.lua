local parent = script.Parent.Parent
require(parent.Types)

local function toSet(list)
	local result = {}

	for _, v in ipairs(list) do
		result[v] = true
	end

	return result
end

return toSet