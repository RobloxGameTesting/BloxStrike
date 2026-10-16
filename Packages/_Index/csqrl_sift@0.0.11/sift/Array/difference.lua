require(script.Parent.Parent.Types)
local toSet = require(script.Parent.toSet)
local toArray = require(script.Parent.Parent.Set.toArray)
local difference = require(script.Parent.Parent.Set.difference)

local function difference2(p, ...)
	local v = toSet(p)
	local v2 = {}

	for _, v3 in { ... } do
		if typeof(v3) == "table" then
			table.insert(v2, toSet(v3))
		end
	end

	return toArray((difference(v, unpack(v2))))
end

return difference2