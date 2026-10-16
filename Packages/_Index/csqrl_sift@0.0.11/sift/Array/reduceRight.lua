local function reduceRight(list, callback, p)
	local count = #list

	if p == nil then
		p = list[count]
		count -= 1
	end

	for i = count, 1, -1 do
		p = callback(p, list[i], i, list)
	end

	return p
end

return reduceRight