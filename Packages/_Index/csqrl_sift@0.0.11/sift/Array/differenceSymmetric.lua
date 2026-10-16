require(script.Parent.Parent.Types)
local toSet = require(script.Parent.toSet)
local toArray = require(script.Parent.Parent.Set.toArray)
local differenceSymmetric = require(script.Parent.Parent.Set.differenceSymmetric)

local function differenceSymmetric2(p, ...)
	local v = toSet(p)
	local v2 = {}

	for _, v3 in { ... } do
		if typeof(v3) == "table" then
			table.insert(v2, toSet(v3))
		end
	end

	return toArray((differenceSymmetric(v, unpack(v2))))
end

return differenceSymmetric2