local copy = require(script.Parent.copy)

local function removeKeys(p, ...)
	local result = copy(p)

	for _, v in ipairs({ ... }) do
		result[v] = nil
	end

	return result
end

return removeKeys