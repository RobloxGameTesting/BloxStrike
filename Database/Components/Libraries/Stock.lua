local Stock = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local v = {
	"USP-S",
	"Glock-18",
	"P250",
	"Desert Eagle",
	"Tec-9",
	"CZ75-Auto",
	"Five-SeveN",
	"Dual Berettas",
	"R8 Revolver",
	"MAC-10",
	"MP9",
	"MP7",
	"MP5-SD",
	"UMP-45",
	"P90",
	"PP-Bizon",
	"AK-47",
	"M4A1-S",
	"M4A4",
	"AUG",
	"SG 553",
	"FAMAS",
	"Galil AR",
	"AWP",
	"SSG 08",
	"SCAR-20",
	"G3SG1",
	"XM1014",
	"Nova",
	"MAG-7",
	"Sawed-Off",
	"Negev",
	"M249",
	"CT Knife",
	"T Knife",
	"CT Glove",
	"T Glove",
	"Molotov",
	"Incendiary Grenade",
	"HE Grenade",
	"Flashbang",
	"Smoke Grenade",
	"Decoy Grenade",
	"C4",
	"Zeus x27"
}
local v2 = {
	Weapon = true,
	Melee = true,
	Glove = true,
	Grenade = true,
	C4 = true
}

local function GetInventoryItemType(name: string) -- 1 equivalent call inferred from this helper
	if name == "Zeus x27" or name == "C4" then
		return name
	end

	local child = ReplicatedStorage.Database.Custom.Weapons:FindFirstChild(name)

	if not child then
		return "Weapon"
	end

	local module = require(child)
	local class = module.Class

	if v2[class] then
		return class
	end

	return "Weapon"
end

local function CreateStockItem(name: string)
	return {
		_id = name .. "_Stock",
		Type = GetInventoryItemType(name), -- inferred equivalent call
		Serial = 0,
		Name = name,
		Skin = "Stock",
		Float = 0,
		StatTrack = false,
		IsTradeable = false,
		NameTag = false,
		Charm = false,
		Stickers = {},
		MetaData = {
			LastTradeAt = 0,
			CreatedAt = 0,
			TradeHistory = {},
			OriginalOwner = 0,
			Owner = 0,
			Origin = "Stock"
		}
	}
end

function Stock.IsStockIdentifier(value: string)
	return string.sub(value, -6) == "_Stock"
end

function Stock.GetWeaponNameFromStockId(value: string)
	if Stock.IsStockIdentifier(value) then
		return (string.sub(value, 1, -7))
	end

	return nil
end

function Stock.GetStockInventoryItem(name: string)
	if table.find(v, name) then
		return (CreateStockItem(name))
	end

	return nil
end

function Stock.GenerateStockInventoryItems()
	local result = {}

	for _, v3 in ipairs(v) do
		table.insert(result, (CreateStockItem(v3)))
	end

	return result
end

function Stock.InjectStockItems(stockInventoryItems)
	local stockInventoryItems2 = Stock.GenerateStockInventoryItems()
	local v3 = {}
	local v4 = {}

	for _, v5 in ipairs(stockInventoryItems) do
		v3[v5._id] = true

		if v5.Skin == "Stock" then
			v4[v5.Name] = true
		end
	end

	for _, stockInventoryItem in ipairs(stockInventoryItems2) do
		if not (v3[stockInventoryItem._id] or v4[stockInventoryItem.Name]) then
			table.insert(stockInventoryItems, stockInventoryItem)
		end
	end

	return stockInventoryItems
end

return Stock