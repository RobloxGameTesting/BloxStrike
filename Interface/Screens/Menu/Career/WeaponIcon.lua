local WeaponIcon = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local GetResolvedSkinInformation = require(ReplicatedStorage.Components.Common.GetResolvedSkinInformation)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Signal = require(ReplicatedStorage.Packages.Signal)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local frozen = table.freeze({ "Counter-Terrorists", "Terrorists" })
local frozen2 = table.freeze({ "Vanilla", "Stock" })
WeaponIcon.Changed = Signal.new()
local v = {}
local v2 = {}

local function GetPlainIcon(p: string) -- 1 equivalent call inferred from this helper
	local v3 = v[p]

	if v3 then
		return v3
	end

	local success, result = pcall(GetWeaponProperties, p)
	local v4 = (not success or typeof(result) ~= "table") and "" or tostring(result.Icon or result.ReverseIcon or "")

	if v4 ~= "" then
		v[p] = v4
	end

	return v4
end

local function GetStockIcon(p: string)
	local v3 = v2[p]

	if v3 then
		return v3
	end

	local allSkinsForWeapon = Skins.GetAllSkinsForWeapon(p)

	if not allSkinsForWeapon then
		return ""
	end

	for _, v4 in ipairs(frozen2) do
		for _, v5 in ipairs(allSkinsForWeapon) do
			if v5.skin ~= v4 then
				continue
			end

			local v6 = Skins.GetWearImageForFloat(v5, 0) or v5.imageAssetId or ""

			if v6 == "" then
				continue
			end

			v2[p] = v6
			return v6
		end
	end

	return ""
end

local function CollectEquippedIdentifiers(p, p2: string?)
	local result = {}

	if typeof(p) ~= "table" then
		return result
	end

	local function collect(items, p3: number)
		if typeof(items) ~= "table" or p3 > 6 then
			return
		end

		for _, item in pairs(items) do
			if typeof(item) == "string" then
				result[item] = true
			elseif typeof(item) == "table" then
				collect(item, p3 + 1)
			end
		end
	end

	if p2 then
		collect(p[p2], 0)
		return result
	end

	for _, v3 in ipairs(frozen) do
		collect(p[v3], 0)
	end

	return result
end

local function GetSkinIcon(data)
	if typeof(data) ~= "table" or typeof(data.Skin) ~= "string" or data.Skin == "" then
		return ""
	end

	local resolvedSkinInformation = GetResolvedSkinInformation(data.Name, data.Skin)

	if not resolvedSkinInformation then
		return ""
	end

	local v3 = typeof(data.Float) ~= "number" and 0.9999 or data.Float
	return Skins.GetWearImageForFloat(resolvedSkinInformation, v3) or resolvedSkinInformation.imageAssetId or ""
end

function WeaponIcon.Get(p: string, p2: string?)
	if p == nil or p == "" then
		return ""
	end

	local v3, v4 = DataController.Get(LocalPlayer, "Inventory", "Loadout")

	if typeof(v3) == "table" and typeof(v4) == "table" then
		local collectEquippedIdentifiers = CollectEquippedIdentifiers(v4, p2)

		for _, v5 in ipairs(v3) do
			if not (typeof(v5) == "table" and v5.Name == p and collectEquippedIdentifiers[v5._id]) then
				continue
			end

			local skinIcon = GetSkinIcon(v5)

			if skinIcon ~= "" then
				return skinIcon
			end
		end
	end

	local stockIcon = GetStockIcon(p)

	if stockIcon ~= "" then
		return stockIcon
	end

	return GetPlainIcon(p) -- inferred equivalent call
end

local flag = false
Skins.ObserveItemStockSchemas(function()
	table.clear(v2)

	if flag then
		WeaponIcon.Changed:Fire()
	end
end)
flag = true
return WeaponIcon