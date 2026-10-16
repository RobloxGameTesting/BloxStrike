local reduce = require(script.Parent.reduce)

local function zip(...)
	local v = { ... }
	local result = {}

	if select("#", ...) == 0 then
		return result
	end

	for i = 1, reduce(v, function(p, list)
		return (math.min(p, #list))
	end, #v[1]) do
		local v2 = {}

		for _, v3 in ipairs(v) do
			table.insert(v2, v3[i])
		end

		table.insert(result, v2)
	end

	return result
end

return zip