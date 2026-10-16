local frozen = table.freeze({
	Rifle = "RIFLE",
	SMG = "SMG",
	Pistol = "PISTOL",
	Shotgun = "HEAVY",
	Sniper = "SNIPER",
	Melee = "MELEE",
	Special = "SPECIAL"
})
local frozen2 = table.freeze({
	Rifle = table.freeze({ "AK-47", "M4A4", "M4A1-S", "AUG", "SG 553", "FAMAS", "Galil AR" }),
	SMG = table.freeze({ "MP9", "MAC-10", "P90" }),
	Pistol = table.freeze({
		"Glock-18",
		"USP-S",
		"P250",
		"Five-SeveN",
		"Tec-9",
		"Dual Berettas",
		"Desert Eagle",
		"R8 Revolver"
	}),
	Shotgun = table.freeze({ "Nova", "XM1014", "MAG-7", "Sawed-Off", "Negev" }),
	Sniper = table.freeze({ "AWP", "SSG 08" }),
	Melee = table.freeze({
		"CT Knife",
		"T Knife",
		"Karambit",
		"M9 Bayonet",
		"Butterfly Knife",
		"Flip Knife",
		"Gut Knife",
		"Skeleton Knife",
		"Stiletto Knife",
		"LightSaber"
	}),
	Special = table.freeze({ "HE Grenade", "Molotov", "Incendiary Grenade", "Zeus x27" })
})
local v = {}
local result = {}
local v2 = { ["Zeus x27"] = true }
local v3 = {}

for _, v4 in ipairs({ "Rifle", "SMG", "Pistol", "Shotgun", "Sniper", "Melee", "Special" }) do
	for _, v5 in ipairs(frozen2[v4]) do
		v[v5] = v4
		table.insert(result, v5)
	end
end

for _, v4 in ipairs({ "Melee", "Special" }) do
	for _, v5 in ipairs(frozen2[v4]) do
		v2[v5] = true
	end
end

table.freeze(v)
table.freeze(result)
table.freeze(v2)

function v3.GetWeapons()
	return result
end

function v3.GetCategory(p: string)
	return v[p] or "Special"
end

function v3.GetLabel(p: string)
	return frozen[v3.GetCategory(p)] or "SPECIAL"
end

function v3.CountsTowardsAccuracy(p: string?)
	return p ~= nil and p ~= "" and not v2[p]
end

return table.freeze(v3)