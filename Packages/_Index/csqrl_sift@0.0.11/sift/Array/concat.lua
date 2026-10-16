local parent = script.Parent.Parent
local None = require(parent.None)

local function concat(...)
	local result = {}

	for i = 1, select("#", ...) do
		local v = select(i, ...)

		if type(v) ~= "table" then
			continue
		end

		for _, v2 in ipairs(v) do
			if v2 ~= None then
				table.insert(result, v2)
			end
		end
	end

	return result
end

return concat