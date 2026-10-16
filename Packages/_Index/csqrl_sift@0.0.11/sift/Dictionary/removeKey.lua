local copy = require(script.Parent.copy)

local function removeKey(p, p2)
	local v = copy(p)
	v[p2] = nil
	return v
end

return removeKey