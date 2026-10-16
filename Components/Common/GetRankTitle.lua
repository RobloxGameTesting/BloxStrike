local frozen = table.freeze({
	table.freeze({ maxLevel = 5, title = "Recruit" }),
	table.freeze({ maxLevel = 10, title = "Private" }),
	table.freeze({ maxLevel = 15, title = "Corporal" }),
	table.freeze({ maxLevel = 20, title = "Sergeant" }),
	table.freeze({ maxLevel = 25, title = "Master Sergeant" }),
	table.freeze({ maxLevel = 30, title = "Lieutenant" }),
	table.freeze({ maxLevel = 35, title = "Captain" }),
	table.freeze({ maxLevel = 40, title = "Global Elite" })
})
return function(p: number)
	for _, v in ipairs(frozen) do
		if p <= v.maxLevel then
			return v.title
		end
	end

	return "Global Elite"
end