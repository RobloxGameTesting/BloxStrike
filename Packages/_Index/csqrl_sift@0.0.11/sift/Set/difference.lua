require(script.Parent.Parent.Types)

local function difference(p, ...)
	local clone = table.clone(p)

	for _, v in { ... } do
		if typeof(v) ~= "table" then
			continue
		end

		for k in v do
			clone[k] = nil
		end
	end

	return clone
end

return difference