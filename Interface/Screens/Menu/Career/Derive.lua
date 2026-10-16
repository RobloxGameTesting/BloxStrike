local Derive = {}
require(script.Parent.Types)
Derive.AccuracyCeiling = 0.4

function Derive.Divide(p: number, p2: number)
	if p2 <= 0 then
		return 0
	end

	return p / p2
end

function Derive.KillDeath(p)
	if p.Deaths > 0 then
		return p.Kills / p.Deaths
	end

	return p.Kills
end

function Derive.AverageDamage(p)
	return Derive.Divide(p.DamageDealt, p.RoundsPlayed)
end

function Derive.CombatScore(p)
	return Derive.Divide(p.CombatScore, p.RoundsPlayed)
end

function Derive.Kast(p)
	return Derive.Divide(p.KastRounds, p.RoundsPlayed)
end

function Derive.DamageDelta(data)
	return Derive.Divide(data.DamageDealt - data.DamageTaken, data.RoundsPlayed)
end

function Derive.EconomyRating(p: number, p2: number)
	return Derive.Divide(p, p2) * 1000
end

function Derive.ZoneShare(p: number, p2: number)
	return Derive.Divide(p, p2)
end

function Derive.HeatWeight(p: number, p2: number)
	return (math.clamp(Derive.Divide(p, p2) / Derive.AccuracyCeiling, 0, 1))
end

function Derive.FavouriteWeapon(p, p2: string)
	local sideWeaponKill = p.SideWeaponKills[p2]

	if not sideWeaponKill then
		return nil, 0
	end

	local v = 0
	local v2 = nil

	for k, v3 in pairs(sideWeaponKill) do
		if not (v < v3 or v3 == v and v2 and k < v2) then
			continue
		end

		v2 = k
		v = v3
	end

	if v <= 0 then
		return nil, 0
	end

	return v2, v
end

return Derive