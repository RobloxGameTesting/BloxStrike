local function every(items, callback)
	for k, item in pairs(items) do
		if not callback(item, k, items) then
			return false
		end
	end

	return true
end

return every