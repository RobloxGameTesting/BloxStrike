local function find(list, p, value: number?)
	local v = #list

	if type(value) == "number" then
		if value < 1 then
			value = v + value
		end
	else
		value = 1
	end

	return table.find(list, p, value)
end

return find