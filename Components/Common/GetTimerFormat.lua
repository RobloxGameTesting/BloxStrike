local function format(p: number) -- 2 equivalent calls inferred from this helper
	return string.format("%02i", p)
end

return function(p: number)
	return format(math.floor(p / 60)) .. ":" .. format(p % 60) -- inferred equivalent call
end