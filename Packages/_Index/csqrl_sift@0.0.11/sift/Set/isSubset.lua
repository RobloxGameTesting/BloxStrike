local function isSubset(items, p)
	for k, item in pairs(items) do
		if p[k] ~= item then
			return false
		end
	end

	return true
end

return isSubset