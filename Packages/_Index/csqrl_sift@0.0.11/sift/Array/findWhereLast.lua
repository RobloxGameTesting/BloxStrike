local function findWhereLast(list, callback, value: number?)
	local count = #list

	if type(value) == "number" then
		if value < 1 then
			value = count + value
		end
	else
		value = count
	end

	for i = value, 1, -1 do
		if callback(list[i], i, list) then
			return i
		end
	end
end

return findWhereLast