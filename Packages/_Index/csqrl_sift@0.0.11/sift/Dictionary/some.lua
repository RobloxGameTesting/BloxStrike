local function some(items, callback)
	for k, item in pairs(items) do
		if callback(item, k, items) then
			return true
		end
	end

	return false
end

return some