return table.freeze({
	Kill = {
		Competitive = 300,
		Casual = 150,
		Deathmatch = 0,
		WeaponBonuses = {
			Knife = 1200,
			MP9 = 300,
			["MAC-10"] = 300,
			["MP5-SD"] = 300,
			["UMP-45"] = 300,
			["PP-Bizon"] = 300,
			MP7 = 300,
			Nova = 600,
			["Sawed-Off"] = 600,
			["MAG-7"] = 600,
			P90 = 0,
			XM1014 = 0,
			AWP = -200,
			["Zeus x27"] = -200,
			["HE Grenade"] = 0,
			Molotov = 0,
			Incendiary = 0,
			["Incendiary Grenade"] = 0
		},
		WeaponBonusesCompetitive = {
			Knife = 1200,
			MP9 = 300,
			["MAC-10"] = 300,
			["MP5-SD"] = 300,
			["UMP-45"] = 300,
			["PP-Bizon"] = 300,
			MP7 = 300,
			Nova = 600,
			["Sawed-Off"] = 600,
			["MAG-7"] = 600,
			XM1014 = 600,
			P90 = 0,
			AWP = -200,
			["CZ75-Auto"] = -200,
			["Zeus x27"] = -300,
			["HE Grenade"] = 0,
			Molotov = 0,
			Incendiary = 0,
			["Incendiary Grenade"] = 0
		}
	},
	Assist = { Competitive = 0, Casual = 50, Deathmatch = 0 },
	BombPlant = { Competitive = 300, Casual = 300, Deathmatch = 0 },
	BombDefuse = { Competitive = 300, Casual = 300, Deathmatch = 0 },
	BombPlantedButDefused = { Competitive = 600, Casual = 600, Deathmatch = 0 },
	RoundWin = {
		Competitive = {
			Elimination = 3250,
			BombObjective = 3500,
			BombExplode = 3500,
			BombDefuse = 3250,
			HostageRescue = 3500,
			TimeExpiration = 3250
		},
		Casual = {
			Elimination = 3250,
			BombObjective = 3500,
			HostageRescue = 3500,
			TimeExpiration = 3250
		},
		Deathmatch = { Elimination = 0, BombObjective = 0, TimeExpiration = 0 }
	},
	RoundLoss = {
		Competitive = {
			[0] = 1400,
			[1] = 1900,
			[2] = 2400,
			[3] = 2900,
			[4] = 3400
		},
		Casual = {
			[0] = 1400,
			[1] = 1900,
			[2] = 2400,
			[3] = 2900,
			[4] = 3400
		},
		Deathmatch = {
			[0] = 0,
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 0
		}
	},
	BombPlantLossBonus = { Competitive = 600, Casual = 0, Deathmatch = 0 },
	CTTeamKillBonus = { Competitive = 50, Casual = 50, Deathmatch = 0 },
	HostageShotPenalty = { Competitive = -300, Deathmatch = 0, Casual = -300 },
	HostageInteraction = { Competitive = 150, Casual = 0, Deathmatch = 0 },
	HostageTeamInteraction = { Competitive = 500, Casual = 0, Deathmatch = 0 },
	HostageRescueBonus = { Competitive = 1000, Casual = 0, Deathmatch = 0 },
	TeamKillPenalty = { Competitive = -300, Casual = 0, Deathmatch = 0 },
	MinimumRoundIncome = { Competitive = 1400, Casual = 1400, Deathmatch = 0 },
	SpecialRules = {
		TerroristTimeoutPenalty = true,
		CasualKillRewardHalved = true,
		MaxMoney = 16000
	}
})