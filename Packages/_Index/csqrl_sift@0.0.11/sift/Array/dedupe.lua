local fromArray = require(script.Parent.Parent.Set.fromArray)
local toArray = require(script.Parent.Parent.Set.toArray)

local function dedupe(p)
	return toArray(fromArray(p))
end

return dedupe