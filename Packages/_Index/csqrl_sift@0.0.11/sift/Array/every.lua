local function every(list, callback)
	for i, v in ipairs(list) do
		if not callback(v, i, list) then
			return false
		end
	end

	return true
end

return every