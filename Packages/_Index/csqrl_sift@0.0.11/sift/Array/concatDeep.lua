local parent = script.Parent.Parent
local copyDeep = require(script.Parent.copyDeep)
local None = require(parent.None)

local function concatDeep(...)
	local result = {}

	for i = 1, select("#", ...) do
		local v = select(i, ...)

		if type(v) ~= "table" then
			continue
		end

		for _, v2 in ipairs(v) do
			if v2 == None then
				continue
			end

			if type(v2) == "table" then
				table.insert(result, copyDeep(v2))
			else
				table.insert(result, v2)
			end
		end
	end

	return result
end

return concatDeep