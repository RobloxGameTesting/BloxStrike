local parent = script.Parent.Parent
local None = require(parent.None)

local function merge(...)
	local result = {}

	for i = 1, select("#", ...) do
		local v = select(i, ...)

		if type(v) ~= "table" then
			continue
		end

		for k, v2 in pairs(v) do
			if v2 == None then
				v2 = nil
			end

			result[k] = v2
		end
	end

	return result
end

return merge