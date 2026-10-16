local Selection = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)
Selection.Changed = Signal.new()
Selection.Order = table.freeze({
	"All",
	"CasualDefusal",
	"CasualHostage",
	"Deathmatch",
	"CompetitiveDefusal",
	"CompetitiveHostage"
})
Selection.Names = table.freeze({
	All = "All Gamemodes",
	CasualDefusal = "Bomb Defusal - Casual",
	CasualHostage = "Hostage Rescue - Casual",
	Deathmatch = "Deathmatch",
	CompetitiveDefusal = "Bomb Defusal - Competitive",
	CompetitiveHostage = "Hostage Rescue - Competitive"
})
Selection.Headings = table.freeze({
	All = "LIFETIME STATS",
	CasualDefusal = "CASUAL DEFUSAL STATS",
	CasualHostage = "CASUAL HOSTAGE STATS",
	Deathmatch = "DEATHMATCH STATS",
	CompetitiveDefusal = "COMPETITIVE DEFUSAL STATS",
	CompetitiveHostage = "COMPETITIVE HOSTAGE STATS"
})

function Selection.HasRounds(p: string)
	return p ~= "Deathmatch"
end

local v = "All"

function Selection.Get()
	return v
end

function Selection.Set(p: string)
	if v == p or Selection.Names[p] == nil then
		return
	end

	v = p
	Selection.Changed:Fire(p)
end

return Selection