local copy = require(script.Parent.copy)

local function freeze(p)
	local v = copy(p)
	table.freeze(v)
	return v
end

return freeze