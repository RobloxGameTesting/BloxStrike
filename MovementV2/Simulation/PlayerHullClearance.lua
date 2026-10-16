require(script.Parent.Parent.Types)
require(script.Parent.Config)
local PlayerContacts = require(script.Parent.PlayerContacts)

local function halfSize(p, p2) -- 3 equivalent calls inferred from this helper
	local v

	if p == "Ducking" then
		v = p2.PlayerSizeDucking
	else
		v = p2.PlayerSizeStanding
	end

	return v * 0.5
end

return table.freeze({
	bounds = function(vector: Vector3, p, p2)
		local playerSizeStanding = p2.PlayerSizeStanding
		local playerSizeDucking = p2.PlayerSizeDucking
		local v = Vector3.new(
			math.max(playerSizeStanding.X, playerSizeDucking.X),
			math.max(playerSizeStanding.Y, playerSizeDucking.Y),
			(math.max(playerSizeStanding.Z, playerSizeDucking.Z))
		) * 0.5
		local v2 = halfSize(p, p2) + v -- inferred equivalent call
		return vector - v2, vector + v2
	end,
	overlaps = function(vector: Vector3, p, vector2: Vector3, p2, p3)
		local v = halfSize(p, p3) + halfSize(p2, p3) -- inferred equivalent call
		local v2 = vector - vector2
		local defaultContactEpsilon = PlayerContacts.DefaultContactEpsilon
		return math.abs(v2.X) < v.X - defaultContactEpsilon
			and math.abs(v2.Y) < v.Y - defaultContactEpsilon
			and math.abs(v2.Z) < v.Z - defaultContactEpsilon
	end
})