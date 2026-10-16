local copy = require(script.Parent.copy)

local function update(p, p2, callback, callback2)
	local v = copy(p)

	if v[p2] then
		if callback then
			v[p2] = callback(v[p2], p2)
			return v
		end
	elseif typeof(callback2) == "function" then
		v[p2] = callback2(p2)
	end

	return v
end

return update