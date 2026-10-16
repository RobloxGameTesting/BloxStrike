local CareerData = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Types)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local frozen = table.freeze({
	"CasualDefusal",
	"CasualHostage",
	"Deathmatch",
	"CompetitiveDefusal",
	"CompetitiveHostage"
})
local frozen2 = table.freeze({ "Counter-Terrorists", "Terrorists" })
CareerData.Buckets = frozen
CareerData.EconomyTiers = table.freeze({ "Pistol", "Eco", "Semi", "Full" })
local frozen3 = table.freeze({
	"MatchesPlayed",
	"MatchesWon",
	"MatchesLost",
	"MatchesTied",
	"SecondsPlayed",
	"RoundsPlayed",
	"RoundsWon",
	"RoundsSurvived",
	"Kills",
	"Deaths",
	"Assists",
	"HeadshotKills",
	"DamageDealt",
	"DamageTaken",
	"CombatScore",
	"KastRounds",
	"Clutches",
	"FlawlessRounds",
	"AceRounds",
	"RoundMVPs",
	"FirstBloods",
	"Plants",
	"Defuses",
	"Rescues",
	"OvertimeWins"
})
local frozen4 = table.freeze({ "ShotsFired", "ShotsHit", "HeadHits", "BodyHits", "LegHits" })
local frozen5 = table.freeze({ "Kills", "Deaths", "RoundsPlayed", "RoundsWon" })
local frozen6 = table.freeze({
	"RoundsPlayed",
	"RoundsWon",
	"Kills",
	"Deaths",
	"DamageDealt",
	"KastRounds"
})
local frozen7 = table.freeze({
	"Kills",
	"Damage",
	"Matches",
	"RoundsPlayed",
	"RoundsWon",
	"RankedRoundsPlayed",
	"RankedRoundsWon",
	"CrouchKills",
	"JumpKills",
	"BlindKills",
	"CrouchDamage",
	"JumpDamage",
	"BlindDamage",
	"Assists",
	"DeadAssists",
	"ShotsFired",
	"ShotsHit",
	"HeadshotHits",
	"Reloads",
	"Inspects"
})
local frozen8 = table.freeze({
	"UserId",
	"AvatarUserId",
	"Kills",
	"Deaths",
	"Assists",
	"MVPs",
	"Score",
	"Money",
	"BadgeFloat",
	"CombatScore",
	"RoundsPlayed",
	"DamageDealt",
	"MoneySpent",
	"FirstBloods",
	"Plants",
	"Defuses",
	"Rescues"
})
CareerData.Changed = Signal.new()
CareerData.MatchLoaded = Signal.new()
local v = nil
local v2 = {}
local v3 = 0
local now = 0
local flag = false

local function ToNumber(value) -- 18 equivalent calls inferred from this helper
	return typeof(value) == "number" and value or 0
end

local function ToText(value, p: string) -- 27 equivalent calls inferred from this helper
	return typeof(value) == "string" and value or p
end

local function ReadNumbers(p, list)
	local v4 = typeof(p) == "table" and p or {}
	local result = {}

	for _, v5 in ipairs(list) do
		result[v5] = ToNumber(v4[v5]) -- inferred equivalent call
	end

	return result
end

local function AddNumbers(p, p2, frozen9)
	for _, v4 in ipairs(frozen9) do
		p[v4] += ToNumber(p2[v4]) -- inferred equivalent call
	end
end

local function ReadBucket(p)
	local v4 = typeof(p) == "table" and p or {}
	local readNumbers = ReadNumbers(v4, frozen3)
	readNumbers.Accuracy = ReadNumbers(v4.Accuracy, frozen4)
	readNumbers.Sides = {}
	readNumbers.SideWeaponKills = {}
	readNumbers.Weapons = {}
	readNumbers.Economy = {}

	for _, v5 in ipairs(frozen2) do
		local sides = readNumbers.Sides
		local v6

		if typeof(v4.Sides) == "table" then
			v6 = v4.Sides[v5]
		else
			v6 = false
		end

		sides[v5] = ReadNumbers(v6, frozen5)
		local v7 = {}
		local v8

		if typeof(v4.SideWeaponKills) == "table" then
			v8 = v4.SideWeaponKills[v5]
		else
			v8 = false
		end

		if typeof(v8) == "table" then
			for k, v9 in pairs(v8) do
				if typeof(k) == "string" then
					v7[k] = ToNumber(v9) -- inferred equivalent call
				end
			end
		end

		readNumbers.SideWeaponKills[v5] = v7
	end

	for _, economyTier in ipairs(CareerData.EconomyTiers) do
		local economy = readNumbers.Economy
		local v5

		if typeof(v4.Economy) == "table" then
			v5 = v4.Economy[economyTier]
		else
			v5 = false
		end

		economy[economyTier] = ReadNumbers(v5, frozen6)
	end

	if typeof(v4.Weapons) ~= "table" then
		return readNumbers
	end

	for k, weapon in pairs(v4.Weapons) do
		if not (typeof(k) == "string" and typeof(weapon) == "table") then
			continue
		end

		readNumbers.Weapons[k] = ReadNumbers(weapon, frozen7)
	end

	return readNumbers
end

local function AddBucket(data, bucket)
	AddNumbers(data, bucket, frozen3)
	AddNumbers(data.Accuracy, bucket.Accuracy, frozen4)

	for _, v4 in ipairs(frozen2) do
		AddNumbers(data.Sides[v4], bucket.Sides[v4], frozen5)

		for k, v5 in pairs(bucket.SideWeaponKills[v4]) do
			data.SideWeaponKills[v4][k] = (data.SideWeaponKills[v4][k] or 0) + v5
		end
	end

	for _, economyTier in ipairs(CareerData.EconomyTiers) do
		AddNumbers(data.Economy[economyTier], bucket.Economy[economyTier], frozen6)
	end

	for k, weapon in pairs(bucket.Weapons) do
		local weapon2 = data.Weapons[k]

		if weapon2 then
			AddNumbers(weapon2, weapon, frozen7)
		else
			data.Weapons[k] = ReadNumbers(weapon, frozen7)
		end
	end
end

local function ReadMatchPlayer(player)
	local v4 = typeof(player) == "table" and player or {}
	local readNumbers = ReadNumbers(v4, frozen8)
	readNumbers.Username = ToText(v4.Username, "") -- inferred equivalent call
	readNumbers.DisplayName = ToText(v4.DisplayName, readNumbers.Username) -- inferred equivalent call
	readNumbers.Team = ToText(v4.Team, "") -- inferred equivalent call
	readNumbers.BadgeSkin = ToText(v4.BadgeSkin, "") -- inferred equivalent call
	readNumbers.Disconnected = v4.Disconnected == true
	return readNumbers
end

local function ReadMatch(match)
	local v4 = typeof(match) == "table" and match or {}
	local players = {}

	if typeof(v4.Players) == "table" then
		for _, player in ipairs(v4.Players) do
			table.insert(players, (ReadMatchPlayer(player)))
		end
	end

	return {
		MatchId = ToText(v4.MatchId, ""), -- inferred equivalent call
		CompletedAt = ToNumber(v4.CompletedAt), -- inferred equivalent call
		Map = ToText(v4.Map, ""), -- inferred equivalent call
		Gamemode = ToText(v4.Gamemode, ""), -- inferred equivalent call
		ServerGamemode = ToText(v4.ServerGamemode, ""), -- inferred equivalent call
		Bucket = ToText(v4.Bucket, ""), -- inferred equivalent call
		Duration = ToNumber(v4.Duration), -- inferred equivalent call
		Team = ToText(v4.Team, ""), -- inferred equivalent call
		Result = ToText(v4.Result, "Draw"), -- inferred equivalent call
		CTScore = ToNumber(v4.CTScore), -- inferred equivalent call
		TScore = ToNumber(v4.TScore), -- inferred equivalent call
		RoundCount = ToNumber(v4.RoundCount), -- inferred equivalent call
		Players = players
	}
end

local function ReadCareerData(p)
	local v4 = typeof(p) == "table" and p or {}
	local buckets = {}

	for _, v5 in ipairs(frozen) do
		local v6

		if typeof(v4.Buckets) == "table" then
			v6 = v4.Buckets[v5]
		else
			v6 = false
		end

		buckets[v5] = ReadBucket(v6)
	end

	local matches = {}

	if typeof(v4.Matches) == "table" then
		for _, match in ipairs(v4.Matches) do
			table.insert(matches, (ReadMatch(match)))
		end
	end

	return { SchemaVersion = ToNumber(v4.SchemaVersion), Buckets = buckets, Matches = matches } -- inferred equivalent call
end

local function ReadHitZones(p) -- 2 equivalent calls inferred from this helper
	return (ReadNumbers(p, { "Head", "Body", "Legs" }))
end

local function ReadMatchDetails(p)
	local v4 = typeof(p) == "table" and p or {}
	local rounds = {}

	if typeof(v4.Rounds) == "table" then
		for _, round in ipairs(v4.Rounds) do
			if typeof(round) ~= "table" then
				continue
			end

			local players = {}

			if typeof(round.Players) == "table" then
				for _, player in ipairs(round.Players) do
					local readNumbers = ReadNumbers(player, {
						"UserId",
						"Kills",
						"Assists",
						"Deaths",
						"CombatScore",
						"MoneySpent"
					})
					readNumbers.Equip = ToText(player.Equip, "") -- inferred equivalent call
					readNumbers.Armor = ToText(player.Armor, "No Armor") -- inferred equivalent call
					readNumbers.Survived = player.Survived == true
					table.insert(players, readNumbers)
				end
			end

			local events = {}

			if typeof(round.Events) == "table" then
				for _, event in ipairs(round.Events) do
					local readNumbers = ReadNumbers(event, {
						"Time",
						"Killer",
						"Victim",
						"Distance"
					})
					readNumbers.Weapon = ToText(event.Weapon, "") -- inferred equivalent call
					readNumbers.Headshot = event.Headshot == true
					table.insert(events, readNumbers)
				end
			end

			local v5 = {
				Round = ToNumber(round.Round), -- inferred equivalent call
				Winner = ToText(round.Winner, ""), -- inferred equivalent call
				WinType = ToText(round.WinType, "Elimination"), -- inferred equivalent call
				Players = players,
				Events = events
			}
			table.insert(rounds, v5)
		end
	end

	local duels = {}

	if typeof(v4.Duels) == "table" then
		for _, duel in ipairs(v4.Duels) do
			if typeof(duel) ~= "table" then
				continue
			end

			local fights = {}

			if typeof(duel.Fights) == "table" then
				for _, fight in ipairs(duel.Fights) do
					local v5 = {
						Round = ToNumber(fight.Round), -- inferred equivalent call
						RoundWon = fight.RoundWon == true,
						Outcome = ToText(fight.Outcome, "None"), -- inferred equivalent call
						YourWeapon = ToText(fight.YourWeapon, ""), -- inferred equivalent call
						YourArmor = ToText(fight.YourArmor, "No Armor"), -- inferred equivalent call
						EnemyWeapon = ToText(fight.EnemyWeapon, ""), -- inferred equivalent call
						EnemyArmor = ToText(fight.EnemyArmor, "No Armor"), -- inferred equivalent call
						Distance = ToNumber(fight.Distance), -- inferred equivalent call
						DamageDealt = ReadHitZones(fight.DamageDealt), -- inferred equivalent call
						DamageTaken = ReadHitZones(fight.DamageTaken) -- inferred equivalent call
					}
					table.insert(fights, v5)
				end
			end

			local v5 = {
				UserId = ToNumber(duel.UserId), -- inferred equivalent call
				AvatarUserId = ToNumber(duel.AvatarUserId), -- inferred equivalent call
				Username = ToText(duel.Username, ""), -- inferred equivalent call
				DisplayName = ToText(duel.DisplayName, ToText(duel.Username, "")), -- inferred equivalent call
				Team = ToText(duel.Team, ""), -- inferred equivalent call
				BadgeSkin = ToText(duel.BadgeSkin, ""), -- inferred equivalent call
				BadgeFloat = ToNumber(duel.BadgeFloat), -- inferred equivalent call
				Kills = ToNumber(duel.Kills), -- inferred equivalent call
				Deaths = ToNumber(duel.Deaths), -- inferred equivalent call
				Assists = ToNumber(duel.Assists), -- inferred equivalent call
				Fights = fights
			}
			table.insert(duels, v5)
		end
	end

	return { MatchId = ToText(v4.MatchId, ""), Rounds = rounds, Duels = duels } -- inferred equivalent call
end

local function Deliver(p)
	v = ReadCareerData(p)
	CareerData.Changed:Fire(v)
end

local function DeliverMatch(p)
	local readMatchDetails = ReadMatchDetails(p)

	if readMatchDetails.MatchId == "" then
		return
	end

	v2[readMatchDetails.MatchId] = readMatchDetails
	CareerData.MatchLoaded:Fire(readMatchDetails)
end

function CareerData.Get()
	return v
end

function CareerData.IsLoaded()
	return v ~= nil
end

function CareerData.GetBucket(p: string)
	local v4 = v

	if not v4 then
		return (ReadBucket(nil))
	end

	if p ~= "All" then
		return v4.Buckets[p] or ReadBucket(nil)
	end

	local readBucket = ReadBucket(nil)

	for _, v5 in ipairs(frozen) do
		local bucket = v4.Buckets[v5]

		if bucket then
			AddBucket(readBucket, bucket)
		end
	end

	return readBucket
end

function CareerData.GetMatch(p: string)
	local v4 = v

	if not v4 then
		return nil
	end

	for _, match in ipairs(v4.Matches) do
		if match.MatchId == p then
			return match
		end
	end

	return nil
end

function CareerData.GetMatchDetails(p: string)
	return v2[p]
end

function CareerData.Request()
	local now2 = os.clock()

	if now2 - v3 < 2 then
		return
	end

	v3 = now2
	Remotes.Career.RequestStatistics.Send()
end

function CareerData.RequestMatchDetails(p: string)
	if p == "" or v2[p] then
		return
	end

	local now2 = os.clock()

	if now2 - now < 0.5 then
		task.delay(0.5, function()
			if not v2[p] then
				now = os.clock()
				Remotes.Career.RequestMatchDetails.Send(p)
			end
		end)
		return
	end

	now = now2
	Remotes.Career.RequestMatchDetails.Send(p)
end

function CareerData.Listen()
	if flag then
		return
	end

	flag = true
	Remotes.Career.Statistics.Listen(Deliver)
	Remotes.Career.MatchDetails.Listen(function(p)
		local readMatchDetails = ReadMatchDetails(p)

		if readMatchDetails.MatchId == "" then
			return
		end

		v2[readMatchDetails.MatchId] = readMatchDetails
		CareerData.MatchLoaded:Fire(readMatchDetails)
	end)
end

return CareerData