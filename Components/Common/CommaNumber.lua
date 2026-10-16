return function(p: number)
	local v

	if p % 1 == 0 then
		v = tostring(p)
	else
		v = string.format("%.2f", p)
	end

	return v:reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end