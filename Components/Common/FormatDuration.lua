return function(p: number, value: string?)
	local v = value or "Never"
	local v2 = math.max(0, (math.floor(p)))
	local v3 = math.floor(v2 / 86400)
	local v4

	if v == "Never" then
		v4 = math.floor(v2 / 3600)
	else
		v4 = math.floor(v2 % 86400 / 3600)
	end

	local v5 = math.floor(v2 % 3600 / 60)
	local v6 = v2 % 60

	if v == "Always" or v == "IfNeeded" and v3 > 0 then
		return string.format("%02d:%02d:%02d:%02d", v3, v4, v5, v6)
	end

	return string.format("%02d:%02d:%02d", v4, v5, v6)
end