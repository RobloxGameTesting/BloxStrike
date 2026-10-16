local v = {
	Knife = {
		"CT Knife",
		"T Knife",
		"Butterfly Knife",
		"Flip Knife",
		"Gut Knife",
		"Karambit",
		"M9 Bayonet",
		"Bayonet",
		"Bowie Knife",
		"Falchion Knife",
		"Huntsman Knife",
		"Navaja Knife",
		"Paracord Knife",
		"Shadow Daggers",
		"Skeleton Knife",
		"Stiletto Knife",
		"Survival Knife",
		"Talon Knife",
		"Ursus Knife",
		"Classic Knife",
		"Nomad Knife",
		"Kukri Knife"
	},
	Pistols = {
		"USP-S",
		"P2000",
		"Glock-18",
		"P250",
		"Five-SeveN",
		"Tec-9",
		"CZ75-Auto",
		"Dual Berettas",
		"Desert Eagle",
		"R8 Revolver"
	},
	Shotguns = { "Nova", "MAG-7", "Sawed-Off" },
	SMGs = { "MAC-10", "MP9", "MP5-SD", "UMP-45", "PP-Bizon" },
	ElevenPoint = { "XM1014", "MP7", "P90" },
	AssaultRifles = { "AK-47", "M4A1-S", "M4A4", "AUG", "SG 553", "FAMAS", "Galil AR", "SSG 08" },
	SniperRifles = { "AWP", "SCAR-20", "G3SG1" },
	MachineGuns = { "Negev", "M249" }
}
local deathmatchKill = {}

for _, v2 in ipairs({
	{ "Knife", 20 },
	{ "Pistols", 12 },
	{ "Shotguns", 12 },
	{ "SMGs", 12 },
	{ "ElevenPoint", 11 },
	{ "AssaultRifles", 11 },
	{ "SniperRifles", 10 },
	{ "MachineGuns", 10 }
}) do
	for _, v3 in ipairs(v[v2[1]]) do
		deathmatchKill[v3] = v2[2]
	end
end

deathmatchKill["Zeus x27"] = 12
return table.freeze({
	Kill = { Default = 2, NearObjective = 3 },
	DeathmatchKill = deathmatchKill,
	DeathmatchKillDefault = 11,
	Assist = { Default = 1, Deathmatch = 6 },
	BombPlant = 2,
	BombExplodePlanter = 1,
	BombExplodeAlive = 1,
	BombDefuseWithEnemies = 4,
	BombDefuseNoEnemies = 2,
	BombDefuseAlive = 1,
	HostagePickup = 1,
	HostageRescueFirst = 4,
	HostageRescueSubsequent = 1,
	HostageRescueAlive = 1,
	TeamKill = -2,
	Suicide = -2,
	CasualParticipation = 1,
	ObjectiveProximityDistance = 15
})