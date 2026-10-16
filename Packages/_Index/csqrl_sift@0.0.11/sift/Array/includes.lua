local find = require(script.Parent.find)

local function includes(p, p2, p3: number?)
	return find(p, p2, p3) ~= nil
end

return includes