local copy = require(script.Parent.copy)

local function shuffle(list)
	local random = Random.new(os.time() * #list)
	local result = copy(list)

	for i = #result, 1, -1 do
		local integer = random:NextInteger(1, i)
		local v = result[i]
		result[i] = result[integer]
		result[integer] = v
	end

	return result
end

return shuffle