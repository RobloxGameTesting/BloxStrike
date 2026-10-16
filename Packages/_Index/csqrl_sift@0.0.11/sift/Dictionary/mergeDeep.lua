local parent = script.Parent.Parent
local None = require(parent.None)
local copyDeep = require(script.Parent.copyDeep)
local function mergeDeep(...)
	local result = {}

	for i = 1, select("#", ...) do
		local v = select(i, ...)

		if type(v) ~= "table" then
			continue
		end

		for k, v2 in pairs(v) do
			if v2 == None then
				result[k] = nil
			elseif type(v2) == "table" then
				if result[k] == nil or type(result[k]) ~= "table" then
					result[k] = copyDeep(v2)
				else
					result[k] = mergeDeep(result[k], v2)
				end
			else
				result[k] = v2
			end
		end
	end

	return result
end

return mergeDeep