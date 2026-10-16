local function is(list)
	return typeof(list) == "table" and #list > 0 and next(list, #list) == nil
end

return is