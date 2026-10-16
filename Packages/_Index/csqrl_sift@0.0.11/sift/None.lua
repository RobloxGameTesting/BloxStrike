local v = newproxy(true)

getmetatable(v).__tostring = function()
	return "Sift.None"
end

return v