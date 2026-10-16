local frozen = table.freeze({
	"Shoot",
	"NoSuppressorShoot",
	"ShootRight",
	"ShootLeft",
	"SlamFire",
	"Reload",
	"Inspect",
	"Switch Fire Mode",
	"Add Suppressor",
	"Remove Suppressor",
	"RevolverChargeStart",
	"RevolverChargeCancel",
	"RevolverChargeRelease",
	"Use",
	"Cancel Plant",
	"StartThrow",
	"Throw",
	"CancelThrow",
	"Swing1",
	"Swing2",
	"Heavy Swing",
	"BackStab",
	"ReloadStart",
	"ReloadEnd"
})
local v = {}

for i, v2 in ipairs(frozen) do
	v[v2] = i
end

return table.freeze({
	Names = frozen,
	ToId = function(value: string?)
		if typeof(value) == "string" then
			return v[value]
		end

		return nil
	end,
	ToName = function(value: number?)
		if typeof(value) == "number" then
			return frozen[value]
		end

		return nil
	end
})