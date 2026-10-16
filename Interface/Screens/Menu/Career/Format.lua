local Format = {
	Number = function(p: number)
		return (tostring((math.max(math.floor(p), 0))):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
	end,
	Ratio = function(p: number, p2: number)
		if p2 <= 0 then
			return string.format("%.2f", p)
		end

		return string.format("%.2f", p / p2)
	end,
	Percent = function(p: number, p2: number, value: number?)
		if p2 <= 0 then
			if (value or 0) > 0 then
				return (string.format(`%.{value}f%%`, 0))
			end

			return "0%"
		else
			local v = p / p2 * 100

			if (value or 0) > 0 then
				return string.format(`%.{value}f%%`, v)
			end

			return string.format("%d%%", (math.floor(v + 0.5)))
		end
	end,
	Decimal = function(p: number, p2: number)
		return string.format(`%.{p2}f`, p)
	end,
	Signed = function(p: number, p2: number)
		local v = string.format(`%.{p2}f`, (math.abs(p)))

		if p > 0 then
			return `+{v}`
		end

		if p < 0 then
			return `-{v}`
		end

		return v
	end
}

function Format.Money(p: number)
	return `${Format.Number(p)}`
end

function Format.Share(p: number, value: number?)
	if (value or 0) > 0 then
		return string.format(`%.{value}f%%`, p * 100)
	end

	return string.format("%d%%", (math.floor(p * 100 + 0.5)))
end

function Format.TimePlayed(p: number)
	local v = math.max(math.floor(p / 60), 0)
	local v2 = math.floor(v / 60)
	local v3 = v % 60

	if v2 <= 0 then
		return `{v3}M`
	end

	if v2 < 10 and v3 > 0 then
		return `{v2}HR {v3}M`
	end

	return `{Format.Number(v2)}HR`
end

function Format.Duration(p: number)
	local v = math.max(math.floor(p), 0)
	return string.format("%02d:%02d", math.floor(v / 60), v % 60)
end

function Format.DateTime(p: number)
	local success, result = pcall(function()
		return DateTime.fromUnixTimestamp(p):FormatLocalTime("MM/DD/YY , h:mm a", "en-us")
	end)

	if success and typeof(result) == "string" and result ~= "" then
		return string.upper(result)
	end

	return string.upper(os.date("%m/%d/%y , %I:%M %p", p))
end

function Format.MatchScore(p: string, p2: number, p3: number)
	local v = p == "Counter-Terrorists"
	local v2

	if v then
		v2 = p2
	else
		v2 = p3
	end

	if v then
		p2 = p3
	end

	return `<font color="{v and "rgb(165,183,212)" or "rgb(219,199,126)"}">{v2}</font> - <font color="{v and "rgb(219,199,126)" or "rgb(165,183,212)"}">{p2}</font>`
end

return Format