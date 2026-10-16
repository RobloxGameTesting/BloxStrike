local isSubset = require(script.Parent.isSubset)

local function isSuperset(p, p2)
	return isSubset(p2, p)
end

return isSuperset