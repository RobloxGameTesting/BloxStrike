local copy = require(script.Parent.copy)

local function set(p, p2, p3)
	local v = copy(p)
	v[p2] = p3
	return v
end

return set