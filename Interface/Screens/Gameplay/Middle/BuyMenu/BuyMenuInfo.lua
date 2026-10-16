local frozen = table.freeze({
	Color3.fromRGB(72, 193, 66),
	Color3.fromRGB(227, 202, 14),
	Color3.fromRGB(193, 144, 66),
	(Color3.fromRGB(208, 62, 65))
})

local function row(stars: number, info: string, tip: string) -- 36 equivalent calls inferred from this helper
	return { Stars = stars, Info = info, Tip = tip }
end

local function getStarColor(p: number)
	return frozen[p]
end

return table.freeze({
	StarColorsByTier = frozen,
	Weapons = table.freeze({
		["AK-47"] = row(4, "The classic, accurate, and deadly workhorse", "Consider in full buy rounds"), -- inferred equivalent call
		AUG = row(3, "An optional scope for exceptional accuracy", "Consider in full buy rounds"), -- inferred equivalent call
		AWP = row(3, "Devastating power for the confident sniper", "Consider in full buy rounds"), -- inferred equivalent call
		["Decoy Grenade"] = row(3, "Mimics a weapon firing sound", "Throw early to confuse the enemy"), -- inferred equivalent call
		["Defuse Kit"] = row(1, "Cut your defusing time in half", "Don't be a loser, buy a defuser!"), -- inferred equivalent call
		["Desert Eagle"] = row(4, "A lethal headshot at any range", "Consider in eco rounds"), -- inferred equivalent call
		["Dual Berettas"] = row( -- inferred equivalent call
			2,
			"Two rapid-fire pistols for the price of one",
			"Consider in the first round of the half"
		),
		FAMAS = row(3, "Cheap but effective against armored enemies", "Consider in force buy rounds"), -- inferred equivalent call
		["Five-SeveN"] = row(2, "Power, speed, and precision for a price", "Consider in eco rounds"), -- inferred equivalent call
		Flashbang = row(4, "Blinds/deafens nearby players", "Throw prior to an attack"), -- inferred equivalent call
		["Galil AR"] = row(3, "Cheap but effective against armored enemies", "Consider in force buy rounds"), -- inferred equivalent call
		["Glock-18"] = row(2, "Deadly up close, just a nuisance at range", "Consider in the first round of the half"), -- inferred equivalent call
		["HE Grenade"] = row(3, "Deal damage or clear smoke grenades", "Use with discretion"), -- inferred equivalent call
		["Incendiary Grenade"] = row(3, "Stifles enemy attacks with fire", "Throw at the first sign of trouble"), -- inferred equivalent call
		Kevlar = row(1, "Protects everything but your head", "Consider in the first round of each half"), -- inferred equivalent call
		["Kevlar + Helmet"] = row( -- inferred equivalent call
			1,
			"Survive all but the most lethal bullets",
			"Consider in full buy and force buy rounds"
		),
		["M4A1-S"] = row(3, "Precise, silent, tracer-free", "Consider in full buy rounds"), -- inferred equivalent call
		M4A4 = row(3, "Good accuracy, with ammo to spare", "Consider in full buy rounds"), -- inferred equivalent call
		["MAC-10"] = row( -- inferred equivalent call
			1,
			"A run and gun tool for breaching bombsites",
			"Consider in the first three rounds of the half"
		),
		["MAG-7"] = row(2, "Take the enemy by surprise, reload, repeat!", "Consider in force buy rounds"), -- inferred equivalent call
		MP9 = row(1, "A burst of damage to deny an enemy rush", "Consider in the first three rounds of the half"), -- inferred equivalent call
		Molotov = row(3, "Clears out hiding spots with fire", "Throw before attacking a bombsite"), -- inferred equivalent call
		Negev = row(4, "Pin-point suppressive fire to buy some time", "Consider in force buy rounds"), -- inferred equivalent call
		Nova = row(2, "Versatile shotgun for close quarter combat", "Consider in force buy rounds"), -- inferred equivalent call
		P250 = row(1, "A popular, if modest, damage upgrade", "Consider in eco rounds"), -- inferred equivalent call
		P90 = row(1, "An endless bullet hose bested only by rifles", "Consider in full buy rounds"), -- inferred equivalent call
		["R8 Revolver"] = row(4, "Deals massive damage after a short delay", "Consider in eco rounds"), -- inferred equivalent call
		["Rescue Kit"] = row(1, "Cut rescue time when freeing hostages", "Buy on Hostage Rescue as Counter-Terrorist"), -- inferred equivalent call
		["SG 553"] = row(3, "A lethal weapon made deadlier with a scope", "Consider in full buy rounds"), -- inferred equivalent call
		["SSG 08"] = row(4, "Light and powerful long-distance damage dealer", "Consider in force buy rounds"), -- inferred equivalent call
		["Sawed-Off"] = row(2, "High powered shotgun for close engagements", "Consider in force buy rounds"), -- inferred equivalent call
		["Smoke Grenade"] = row(3, "Creates a large smoke cloud", "Throw to cut off enemy line of sight"), -- inferred equivalent call
		["Tec-9"] = row(3, "Highly mobile, effective at range and up close", "Consider in eco rounds"), -- inferred equivalent call
		["USP-S"] = row(2, "Precise, silent, and (somewhat) deadly", "Consider in the first round of the half"), -- inferred equivalent call
		XM1014 = row(1, "A full-auto rapid-fire monster", "Consider in force buy rounds"), -- inferred equivalent call
		["Zeus x27"] = row(4, "A rechargeable one shot kill at short range", "Attempt at your own risk") -- inferred equivalent call
	}),
	GetStarColor = getStarColor
})