local function Symbol(p: string)
	local v = newproxy(true)

	getmetatable(v).__tostring = function()
		return p
	end

	return v
end

return Symbol