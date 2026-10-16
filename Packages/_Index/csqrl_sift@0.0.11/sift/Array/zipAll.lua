local parent = script.Parent.Parent
local reduce = require(script.Parent.reduce)
local None = require(parent.None)

local function zipAll(...)
	local v = { ... }
	local result = {}

	if select("#", ...) == 0 then
		return result
	end

	for i = 1, reduce(v, function(p, list)
		return (math.max(p, #list))
	end, #v[1]) do
		local v2 = {}

		for _, v3 in ipairs(v) do
			local v4 = v3[i]

			if v4 == nil then
				v4 = None
			end

			table.insert(v2, v4)
		end

		table.insert(result, v2)
	end

	return result
end

return zipAll