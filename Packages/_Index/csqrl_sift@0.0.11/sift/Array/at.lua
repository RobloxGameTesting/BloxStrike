local function at(list, total: number)
	local v = #list

	if total < 1 then
		total += v
	end

	return list[total]
end

return at