require(script.Parent.Parent.Types)

local function differenceSymmetric(p, ...)
	local clone = table.clone(p)

	for _, v in { ... } do
		if typeof(v) ~= "table" then
			continue
		end

		for k in v do
			clone[k] = clone[k] == nil
		end
	end

	for k, v in clone do
		clone[k] = v and true or nil
	end

	return clone
end

return differenceSymmetric