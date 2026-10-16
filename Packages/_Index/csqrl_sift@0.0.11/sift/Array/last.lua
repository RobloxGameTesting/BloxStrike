local at = require(script.Parent.at)

local function last(p)
	return at(p, 0)
end

return last