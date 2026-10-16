local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local Sift = require(ReplicatedStorage.Packages.Sift)
local v = {
	LayoutOrder = 0,
	Search = {
		"Badge",
		"Zeus x27",
		"C4",
		"Graffiti",
		"Charm",
		"Charm Capsule",
		"Sticker",
		"Sticker Capsule",
		"Music Kit",
		"Weapon",
		"Glove",
		"Melee",
		"Case",
		"Package"
	}
}

local function IsCapsule(data) -- 1 equivalent call inferred from this helper
	if data.Type ~= "Case" or not data.Name then
		return false
	end

	local v2 = string.find(data.Skin, "Sticker") ~= nil
	return string.find(data.Skin, "Charm") ~= nil or v2
end

return (Sift.Dictionary.freezeDeep({
	GetEffectiveItemType = function(data)
		if not IsCapsule(data) then -- inferred equivalent call
			return data.Type or ""
		end

		if string.find(data.Name, "Charm") then
			return "Charm Capsule"
		end

		return "Sticker Capsule"
	end,
	IsCapsule = IsCapsule,
	Everything = { Default = v },
	Equipment = {
		["All Equipment"] = v,
		Melee = {
			Search = { "Melee" },
			LayoutOrder = 1
		},
		Pistols = {
			Search = { "Weapon:Pistol" },
			LayoutOrder = 2
		},
		["Mid-Tier"] = {
			Search = { "Weapon:Heavy", "Weapon:SMG" },
			LayoutOrder = 3
		},
		Rifles = {
			Search = { "Weapon:Rifle" },
			LayoutOrder = 4
		},
		Misc = {
			Search = { "Zeus x27", "C4" },
			LayoutOrder = 5
		},
		Gloves = {
			Search = { "Glove" },
			LayoutOrder = 6
		},
		["Music Kits"] = {
			Search = { "Music Kit" },
			LayoutOrder = 7
		}
	},
	["Graphic Art"] = {
		["All Graphic Art"] = {
			Search = { "Badge", "Graffiti", "Charm", "Sticker" },
			LayoutOrder = 0
		},
		Badges = {
			Search = { "Badge" },
			LayoutOrder = 1
		},
		Stickers = {
			Search = { "Sticker" },
			LayoutOrder = 2
		},
		Graffiti = {
			Search = { "Graffiti" },
			LayoutOrder = 3
		},
		Charms = {
			Search = { "Charm" },
			LayoutOrder = 4
		}
	},
	Display = {
		All = {
			Search = { "Case", "Package", "Charm Capsule", "Sticker Capsule" },
			LayoutOrder = 0
		},
		Cases = {
			Search = { "Case" },
			LayoutOrder = 1
		},
		Packages = {
			Search = { "Package" },
			LayoutOrder = 2
		},
		Capsules = {
			Search = { "Charm Capsule", "Sticker Capsule" },
			LayoutOrder = 3
		}
	}
}))