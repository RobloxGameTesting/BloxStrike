local function some(list, callback)
	for i, v in ipairs(list) do
		if callback(v, i, list) then
			return true
		end
	end

	return false
end

return some