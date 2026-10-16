return table.freeze({
	MissionId = "Deal 400 Utility Damage",
	DisplayName = "Deal 400 Utility Damage In Bomb Defusal Or Hostage Rescue",
	Target = 400,
	Type = "daily",
	Gamemodes = { "Bomb Defusal", "Hostage Rescue" },
	Category = "utility_damage",
	Rewards = {
		{ type = "Credits", amount = 26 }
	}
})