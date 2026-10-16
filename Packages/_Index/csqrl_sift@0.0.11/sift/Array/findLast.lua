local function findLast(list, p, value: number?)
	local count = #list

	if type(value) == "number" then
		if value < 1 then
			value = count + value
		end
	else
		value = count
	end

	for i = value, 1, -1 do
		if list[i] == p then
			return i
		end
	end
end

return findLast