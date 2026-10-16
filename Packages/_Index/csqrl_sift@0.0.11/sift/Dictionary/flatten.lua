require(script.Parent.Parent.Types)
local function flatten(item, value: number?)
	local v = type(value) ~= "number" and 1e999 or value
	local result = {}

	for k, item2 in pairs(item) do
		if type(item2) == "table" and v > 0 then
			local v2 = flatten(item2, v - 1)

			for k2, v3 in pairs(result) do
				v2[k2] = v3
			end

			result = v2
		else
			result[k] = item2
		end
	end

	return result
end

return flatten