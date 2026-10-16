local v = {
	HammerUnitToStud = 0.075,
	DefaultBaseSpeed = 18.75,
	TopSpeed = 19.5,
	WalkModifier = 0.52,
	CrouchModifier = 0.34,
	HostageCarryingSpeed = 15,
	WeaponSpeeds = table.freeze({
		["AK-47"] = 16.125,
		AUG = 16.5,
		AWP = 15,
		["Butterfly Knife"] = 18.75,
		C4 = 18.75,
		["CT Knife"] = 18.75,
		["CZ75-Auto"] = 18,
		["Decoy Grenade"] = 18.375,
		["Desert Eagle"] = 17.25,
		["Dual Berettas"] = 18,
		FAMAS = 16.5,
		["Five-SeveN"] = 18,
		Flashbang = 18.375,
		["Flip Knife"] = 18.75,
		G3SG1 = 16.125,
		["Galil AR"] = 16.125,
		["Glock-18"] = 18,
		["Gut Knife"] = 18.75,
		["HE Grenade"] = 18.375,
		["Incendiary Grenade"] = 18.375,
		Karambit = 18.75,
		LightSaber = 18.75,
		M249 = 14.625,
		["M4A1-S"] = 16.875,
		M4A4 = 16.875,
		["M9 Bayonet"] = 18.75,
		["MAC-10"] = 18,
		["MAG-7"] = 16.875,
		["MP5-SD"] = 17.625,
		MP7 = 16.5,
		MP9 = 18,
		Molotov = 18.375,
		Negev = 11.25,
		Nova = 16.5,
		P2000 = 18,
		P250 = 18,
		P90 = 17.25,
		["PP-Bizon"] = 18,
		["R8 Revolver"] = 16.5,
		["SCAR-20"] = 16.125,
		["SG 553"] = 15.75,
		["SSG 08"] = 17.25,
		["Sawed-Off"] = 15.75,
		["Skeleton Knife"] = 18.75,
		["Smoke Grenade"] = 18.375,
		["Stiletto Knife"] = 18.75,
		["T Knife"] = 18.75,
		["Tec-9"] = 18,
		["UMP-45"] = 17.25,
		["USP-S"] = 18,
		XM1014 = 16.125,
		["Zeus x27"] = 16.5
	}),
	ScopedSpeeds = table.freeze({
		["SSG 08"] = 17.25,
		["SG 553"] = 11.25,
		AWP = 7.5,
		AUG = 11.25,
		["SCAR-20"] = 9,
		G3SG1 = 9,
		["R8 Revolver"] = 13.5
	})
}

function v.resolveWeaponSpeeds(p: string?, value: number?)
	local v2

	if p ~= nil then
		v2 = v.WeaponSpeeds[p]
	end

	local v3 = v2 or v.DefaultBaseSpeed

	if v2 == nil and typeof(value) == "number" and value > 0 then
		v3 = value * (375 / 404)
	end

	local v4 = math.clamp(v3, 0, v.TopSpeed)
	local v5

	if p ~= nil then
		v5 = v.ScopedSpeeds[p]
	end

	return v4, v5 or v4
end

function v.resolveFromWeaponSpeeds(p: number, value: number, flag: boolean?, flag2: boolean?)
	if flag ~= true then
		value = p
	end

	if flag2 == true then
		value = math.min(value, v.HostageCarryingSpeed)
	end

	return (math.clamp(value, 0, v.TopSpeed))
end

function v.resolve(data)
	local weaponSpeeds, v2 = v.resolveWeaponSpeeds(data.WeaponName, data.WeaponWalkSpeed)
	return v.resolveFromWeaponSpeeds(weaponSpeeds, v2, data.IsScoped, data.CarryingHostage)
end

return table.freeze(v)