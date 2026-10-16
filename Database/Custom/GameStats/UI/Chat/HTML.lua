local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	Badges = table.freeze({ Verified = utf8.char(57344) }),
	Roles = table.freeze({
		[255] = "<font color=\"rgb(84, 210, 101)\">[OWNER] </font>",
		[254] = "<font color=\"rgb(84, 210, 101)\">[OWNER] </font>",
		[253] = "<font color=\"rgb(17, 247, 255)\">[DEVELOPER] </font>",
		[252] = "<font color=\"rgb(17, 247, 255)\">[DEVELOPER] </font>",
		[251] = "<font color=\"rgb(0, 0, 255)\">[CONTRACTOR] </font>",
		[6] = "<font color=\"rgb(0, 0, 255)\">[MODERATOR] </font>",
		[5] = "<font color=\"rgb(0, 0, 255)\">[MODERATOR] </font>",
		[4] = "<font color=\"rgb(255, 17, 0)\">[CONTENT CREATOR] </font>",
		[3] = "<font color=\"rgb(128, 0, 128)\">[CONTRIBUTOR] </font>",
		[2] = "<font color=\"rgb(255, 255, 0)\">[TESTER] </font>",
		[1] = "<font color=\"rgb(255, 255, 0)\">[MEMBER] </font>"
	}),
	Money = table.freeze({
		Kill = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">for neutralizing an enemy</font>",
		KillWithWeapon = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">for neutralizing an enemy with the %s</font>",
		Assist = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">for assist</font>",
		BombPlant = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">for planting the bomb</font>",
		BombDefuse = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">for defusing the bomb</font>",
		RoundWin = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">for winning the round</font>",
		RoundLoss = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">round loss bonus</font>",
		BombPlantLossBonus = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">bomb plant bonus</font>",
		RoundWinElimination = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">team income for eliminating the enemy team</font>",
		RoundWinBombDefuse = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">team income for defusing the C4</font>",
		RoundWinBombExplode = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">team income for eliminating the enemy team</font>",
		RoundLossTeam = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">team income for losing</font>",
		BombPlantedButDefused = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">team income for planting the bomb</font>",
		CTTeamKillBonus = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">team bonus</font>",
		HostageInteraction = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">for interacting with a hostage</font>",
		HostageTeamInteraction = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">team hostage bonus</font>",
		HostageRescueBonus = "<font color=\"rgb(85,255,85)\">+$%d</font> <font color=\"rgb(255,255,255)\">for rescuing a hostage</font>",
		HostageShotPenalty = "<font color=\"rgb(255,85,85)\">-$%d</font> <font color=\"rgb(255,255,255)\">penalty for shooting a hostage</font>",
		TeamKillPenalty = "<font color=\"rgb(255,85,85)\">-$%d</font> <font color=\"rgb(255,255,255)\">penalty for team kill</font>"
	}),
	TeamJoinMessages = table.freeze({
		Terrorists = "<font color=\"rgb(223,171,57)\">%s is joining the Terrorists</font>",
		["Counter-Terrorists"] = "<font color=\"rgb(95,153,217)\">%s is joining the Counter-Terrorists</font>",
		Spectators = "<font color=\"rgb(255,255,255)\">%s is joining the Spectators</font>"
	}),
	TeamColors = table.freeze({
		["Counter-Terrorists"] = "<font color=\"rgb(163,198,255)\">%s</font> ",
		Terrorists = "<font color=\"rgb(255,223,148)\">%s</font> ",
		Spectators = "<font color=\"rgb(255,255,255)\">%s</font> "
	}),
	Prefixes = table.freeze({
		["Counter-Terrorists"] = "<font color=\"rgb(255,255,255)\">[CT]</font> ",
		Spectators = "<font color=\"rgb(255,255,255)\">[SPEC]</font> ",
		Terrorists = "<font color=\"rgb(255,255,255)\">[T]</font> ",
		All = "<font color=\"rgb(255,255,255)\">[ALL]</font> "
	}),
	Points = table.freeze({
		Deathmatch = "<font color=\"rgb(163,255,72)\">%d</font> <font color=\"rgb(255,255,255)\">%s for neutralizing an enemy with the %s</font>"
	}),
	Suffixes = table.freeze({ Dead = "<font color=\"rgb(255,64,64)\">*DEAD*</font>" }),
	PlayerLeave = "<font color=\"rgb(198,203,208)\">%s disconnected</font>",
	PlayerBanned = "<font color=\"rgb(165,0,0)\">%s has been banned by BAC.</font>",
	SystemMessage = "<font color=\"rgb(153,204,255)\">%s</font>",
	TeamDamageWarning = "<font color=\"rgb(255,85,85)\">Warning: continuous team damage will cause you to be kicked.</font>",
	TeamDamageAnnouncement = "<font color=\"rgb(255,255,255)\">%s dealt damage to a teammate.</font>",
	GrenadeColors = table.freeze({
		["HE Grenade"] = "rgb(255,85,85)",
		Flashbang = "rgb(255,170,0)",
		["Smoke Grenade"] = "rgb(85,255,85)",
		Molotov = "rgb(255,170,0)",
		["Incendiary Grenade"] = "rgb(255,170,0)",
		["Decoy Grenade"] = "rgb(85,170,255)"
	}),
	DefuseStartAction = "<font color=\"rgb(255,170,0)\">DEFUSING!</font>",
	DefuseStartLocationColor = "rgb(85,255,85)",
	GrenadeDisplayNames = table.freeze({
		["HE Grenade"] = "HE Grenade",
		Flashbang = "Flashbang",
		["Smoke Grenade"] = "Smoke",
		Molotov = "Molotov",
		["Incendiary Grenade"] = "Incendiary",
		["Decoy Grenade"] = "Decoy"
	})
})