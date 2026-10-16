return table.freeze({
	sample = function(flag: boolean, flag2: boolean, flag3: boolean)
		if flag then
			return true, false, false
		end

		if flag3 then
			return false, flag2, false
		end

		if flag2 then
			return true, false, true
		end

		return false, false, false
	end
})