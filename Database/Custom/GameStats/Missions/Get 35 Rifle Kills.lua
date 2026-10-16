return table.freeze({
	MissionId = "Get 35 Rifle Kills",
	DisplayName = "Get 35 Rifle Kills In Bomb Defusal Or Hostage Rescue",
	Target = 35,
	Type = "daily",
	Gamemodes = { "Bomb Defusal", "Hostage Rescue" },
	Category = "rifle_kills",
	Rewards = {
		{ type = "Credits", amount = 22 }
	}
})