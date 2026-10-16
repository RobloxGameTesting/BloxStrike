return table.freeze({
	MissionId = "Get 15 Assists",
	DisplayName = "Get 15 Assists In Bomb Defusal Or Hostage Rescue",
	Target = 15,
	Type = "daily",
	Gamemodes = { "Bomb Defusal", "Hostage Rescue" },
	Category = "assists",
	Rewards = {
		{ type = "Credits", amount = 26 }
	}
})