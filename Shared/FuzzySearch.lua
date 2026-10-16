return {
	MatchesQuery = function(value: string, value2: string)
		if value2 == "" then
			return true
		end

		local v = value:lower():gsub("[^%w]", "")
		local v2 = value2:lower():gsub("[^%w]", "")
		local v3 = 1
		local v4 = 1

		while v3 <= #v and v4 <= #v2 do
			if v:sub(v3, v3) == v2:sub(v4, v4) then
				v4 += 1
			end

			v3 += 1
		end

		return #v2 < v4
	end
}