return function(list, callback)
	local v = {}

	for i = 1, #list do
		if callback(i, list[i]) then
			table.insert(v, i)
		end
	end

	for i = #v, 1, -1 do
		table.remove(list, v[i])
	end

	return list
end