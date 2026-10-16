return table.freeze({
	MissionId = "Get 15 Headshots",
	DisplayName = "Get 15 Headshots In Bomb Defusal Or Hostage Rescue",
	Target = 15,
	Type = "daily",
	Gamemodes = { "Bomb Defusal", "Hostage Rescue" },
	Category = "headshots",
	Rewards = {
		{ type = "Credits", amount = 28 }
	}
})