local MarketPlacePrices = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
require(ReplicatedStorage.Database.Custom.Types)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local v = false
local v2 = nil
local v3 = {}

local function GetWearNameFromFloat(p: string, p2: string, p3: number) -- 1 equivalent call inferred from this helper
	local skinInformation = Skins.GetSkinInformation(p, p2)
	return skinInformation and Skins.GetWearNameForFloat(skinInformation, p3)
end

local function WaitForMarketPlacePrices()
	while not v do
		ReplicatedStorage:GetAttributeChangedSignal("MarketPlacePrices"):Wait()
	end
end

local function GetItemKey(p: string, p2: string) -- 2 equivalent calls inferred from this helper
	return (("%*\0%*"):format(p, p2))
end

local function UpdateMarketPlacePrices(marketPlacePrices: string)
	v2 = HttpService:JSONDecode(marketPlacePrices)
	table.clear(v3)

	for _, item in v2.items do
		v3[GetItemKey(item.itemName, item.itemSkin)] = item -- inferred equivalent call
	end

	v = true
end

function MarketPlacePrices.IsLoaded()
	return v
end

function MarketPlacePrices.GetItemPrice(p: string, p2: string, p3: number, p4)
	local wearNameFromFloat = GetWearNameFromFloat(p, p2, p3) -- inferred equivalent call
	local marketPlaceItem = MarketPlacePrices.GetMarketPlaceItem(p, p2)

	if marketPlaceItem and wearNameFromFloat then
		return (p4 and marketPlaceItem.statTrack or marketPlaceItem.standard)[wearNameFromFloat]
	end

	return nil
end

function MarketPlacePrices.GetMarketPlaceItem(p: string, p2: string)
	WaitForMarketPlacePrices()
	return v3[GetItemKey(p, p2)] -- inferred equivalent call
end

local function SyncMarketPlacePrices() -- 1 equivalent call inferred from this helper
	local marketPlacePrices = ReplicatedStorage:GetAttribute("MarketPlacePrices")

	if typeof(marketPlacePrices) == "string" then
		UpdateMarketPlacePrices(marketPlacePrices)
	end
end

SyncMarketPlacePrices() -- inferred equivalent call
ReplicatedStorage:GetAttributeChangedSignal("MarketPlacePrices"):Connect(SyncMarketPlacePrices)
return MarketPlacePrices