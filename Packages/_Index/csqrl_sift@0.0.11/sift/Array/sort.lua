local copy = require(script.Parent.copy)

local function sort(p, callback)
	local v = copy(p)
	table.sort(v, callback)
	return v
end

return sort