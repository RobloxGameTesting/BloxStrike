local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local GetWeaponProperties = require(script.Parent.GetWeaponProperties)

local function CreateFallbackStockInformation(name: string)
	local success, result = pcall(GetWeaponProperties, name)

	if success and result then
		return {
			paintId = "stock",
			type = result.Class,
			name = name,
			skin = "Stock",
			rarity = "Stock",
			floatRange = { min = 0, max = 0.07 },
			floatChances = {
				{ wear = "Factory New", chance = 100 }
			},
			charmImages = {},
			wearImages = {},
			supportsStatTrak = false,
			statTrakChance = 0,
			isEnabled = true,
			isMarketplaceVisible = false,
			collection = nil,
			description = "Standard issue finish.",
			caseRarity = "Stock",
			imageAssetId = result.Icon or result.ReverseIcon
		}
	end

	return nil
end

return function(name: string, p: string)
	local skinInformation = Skins.GetSkinInformation(name, p)

	if skinInformation or p ~= "Stock" then
		return skinInformation
	end

	return (CreateFallbackStockInformation(name))
end