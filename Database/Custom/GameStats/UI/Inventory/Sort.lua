local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local Buttons = require(ReplicatedStorage.Database.Custom.GameStats.UI.Inventory.Buttons)
local v = {
	Forbidden = 7,
	Special = 6,
	Red = 5,
	Pink = 4,
	Purple = 3,
	Blue = 2,
	Stock = 1
}
local v2 = {
	["Sticker Capsule"] = 14,
	["Charm Capsule"] = 13,
	["Music Kit"] = 8,
	Graffiti = 11,
	Grenade = 16,
	Sticker = 10,
	["Zeus x27"] = 3,
	Charm = 9,
	Melee = 1,
	Glove = 2,
	Badge = 7,
	Case = 12,
	C4 = 15
}
local v3 = {
	Melee = 1,
	Glove = 2,
	Case = 3,
	["Charm Capsule"] = 4,
	["Sticker Capsule"] = 4
}
local v4 = {
	Miscellaneous = 18,
	Equipment = 17,
	Pistol = 3,
	Rifle = 6,
	Heavy = 5,
	SMG = 4
}
local v5 = { Pistols = 1, ["Mid Tier"] = 2, Rifles = 3 }
local v6 = {
	["Equipped Melee"] = 1,
	["Equipped Gloves"] = 2,
	["Equipped Badge"] = 3,
	["Equipped Music Kit"] = 4,
	["Equipped Graffiti"] = 5,
	["Equipped Zeus x27"] = 6
}

local function IsStockSkin(p) -- 2 equivalent calls inferred from this helper
	return (p.Skin == "Stock" or p.MetaData and p.MetaData.Origin == "Stock") and true or false
end

local function IsBadge(p) -- 2 equivalent calls inferred from this helper
	return p.Name == "Badge"
end

local function IsCharm(p) -- 2 equivalent calls inferred from this helper
	return p.Name == "Charm"
end

local function GetItemIdentity(data)
	if data.Type == "Case" then
		return data.Skin or ""
	end

	return (data.Name or "") .. "|" .. (data.Skin or "")
end

local function GetCollectionNameForItem(data, callback)
	if Buttons.IsCapsule(data) then
		return "Capsules"
	end

	if data.Type == "Case" then
		if not data.Skin then
			return nil
		end

		local case = Cases.GetCaseByName(data.Skin)

		if not case then
			return nil
		end

		local v7 = callback and callback()

		if not v7 then
			return nil
		end

		for _, v8 in ipairs(v7) do
			if not v8.cases then
				continue
			end

			for _, cas in ipairs(v8.cases) do
				if cas == case.name then
					return v8.name
				end
			end
		end

		return nil
	elseif data.Name and data.Skin then
		local skinInformation = Skins.GetSkinInformation(data.Name, data.Skin)
		return skinInformation and skinInformation.collection or nil
	else
		return nil
	end
end

local function BuildEquippedPriorityMap(p)
	local v7 = {}

	local function record(p2, p3: number) -- 2 equivalent calls inferred from this helper
		local v8 = v7[p2]

		if not v8 or p3 < v8 then
			v7[p2] = p3
		end
	end

	local loadout = DataController.Get(p, "Loadout")

	if not loadout then
		return v7
	end

	for _, v8 in ipairs({ "Counter-Terrorists", "Terrorists" }) do
		local v9 = loadout[v8]

		if not (v9 and v9.Loadout) then
			continue
		end

		for k, v10 in pairs(v5) do
			if not (v10 and v9.Loadout[k] and v9.Loadout[k].Options) then
				continue
			end

			for i, option in ipairs(v9.Loadout[k].Options) do
				record(option, v10 * 1000 + i) -- inferred equivalent call
			end
		end

		if not v9.Equipped then
			continue
		end

		for k, v10 in pairs(v9.Equipped) do
			record(v10, v6[k] or 99) -- inferred equivalent call
		end
	end

	return v7
end

local function MemoizePerItem(callback) -- 5 equivalent calls inferred from this helper
	local v7 = {}
	return function(p)
		local v8 = v7[p]

		if v8 == nil then
			v8 = callback(p)
			v7[p] = v8
		end

		return v8
	end
end

local function GetMetaDataNumber(p, p2: string) -- 1 equivalent call inferred from this helper
	local metaData = p.MetaData
	return metaData and tonumber(metaData[p2]) or 0
end

local function GetCreatedAt(p) -- 1 equivalent call inferred from this helper
	local metaData = p.MetaData
	return metaData and tonumber(metaData.CreatedAt) or 0
end

local function GetSerial(p) -- 2 equivalent calls inferred from this helper
	local serial = tonumber(p.Serial)

	if serial == nil or serial <= 0 then
		return nil
	end

	return serial
end

local function GetNewestSortTimestamp(p) -- 2 equivalent calls inferred from this helper
	local metaDataNumber = GetMetaDataNumber(p, "LastTradeAt") -- inferred equivalent call
	local metaData = p.MetaData
	local createdAt = metaData and tonumber(metaData.CreatedAt) or 0

	if metaDataNumber > 0 then
		createdAt = metaDataNumber or createdAt
	end

	return createdAt
end

local function GetRarityRank(p)
	local v7 = p.Name and p.Skin and Skins.GetSkinInformation(p.Name, p.Skin) or nil
	return v7 and v[v7.rarity] or 0
end

local function GetTypeSortPriority(p)
	local effectiveItemType = Buttons.GetEffectiveItemType(p)
	local v7 = v2[effectiveItemType]

	if v7 then
		return v7
	end

	if effectiveItemType == "Weapon" and p.Name then
		local success, result = pcall(GetWeaponProperties, p.Name)

		if success and result and result.Type then
			return v4[result.Type] or 99
		end
	end

	return 99
end

local function StockLast(fn) -- 8 equivalent calls inferred from this helper
	return function(p, p2)
		local stockSkin = IsStockSkin(p) -- inferred equivalent call
		local stockSkin2 = IsStockSkin(p2) -- inferred equivalent call

		if stockSkin == stockSkin2 then
			return fn(p, p2)
		end

		return stockSkin2, true
	end
end

return {
	GetSortComparisonFunction = function(p: string, p2, callback)
		local memoizePerItem = MemoizePerItem(GetItemIdentity) -- inferred equivalent call
		local memoizePerItem2 = MemoizePerItem(GetRarityRank) -- inferred equivalent call

		local function CompareIdentityThenNewest(p3, p4) -- 6 equivalent calls inferred from this helper
			local v7 = memoizePerItem(p3)
			local v8 = memoizePerItem(p4)

			if v7 ~= v8 then
				return v7 < v8
			end

			local metaData = p3.MetaData
			local createdAt = metaData and tonumber(metaData.CreatedAt) or 0
			return GetCreatedAt(p4) < createdAt -- inferred equivalent call
		end

		if p == "Alphabetical" then
			local function fn(p3, p4)
				local v7 = memoizePerItem(p3)
				local v8 = memoizePerItem(p4)

				if v7 ~= v8 then
					return v7 < v8
				end

				local metaData = p3.MetaData
				local createdAt = metaData and tonumber(metaData.CreatedAt) or 0
				local metaData2 = p4.MetaData
				local createdAt2 = metaData2 and tonumber(metaData2.CreatedAt) or 0

				if createdAt == createdAt2 then
					return (p3._id or "") < (p4._id or "")
				end

				return createdAt2 < createdAt
			end

			return StockLast(fn) -- inferred equivalent call
		end

		if p == "Collection" then
			local function fn(p3)
				return GetCollectionNameForItem(p3, callback) or ""
			end

			local memoizePerItem3 = MemoizePerItem(fn) -- inferred equivalent call

			local function fn2(p3)
				return v3[Buttons.GetEffectiveItemType(p3)] or 4
			end

			local memoizePerItem4 = MemoizePerItem(fn2) -- inferred equivalent call

			local function fn3(p3, p4)
				local v7 = memoizePerItem3(p3)
				local v8 = memoizePerItem3(p4)

				if v7 ~= v8 then
					return v7 < v8
				end

				local v9 = memoizePerItem4(p3)
				local v10 = memoizePerItem4(p4)

				if v9 ~= v10 then
					return v9 < v10
				end

				local v11 = memoizePerItem2(p3)
				local v12 = memoizePerItem2(p4)

				if v11 ~= v12 then
					return v12 < v11
				end

				return CompareIdentityThenNewest(p3, p4) -- inferred equivalent call
			end

			return StockLast(fn3) -- inferred equivalent call
		elseif p == "Equipped" then
			local equippedPriorityMap = BuildEquippedPriorityMap(p2)

			local function fn(p3, p4)
				local v7

				if p3._id then
					v7 = equippedPriorityMap[p3._id] or nil
				end

				local v8

				if p4._id then
					v8 = equippedPriorityMap[p4._id] or nil
				end

				if (v7 ~= nil) ~= (v8 ~= nil) then
					return v7 ~= nil
				end

				if v7 and v8 and v7 ~= v8 then
					return v7 < v8
				end

				return CompareIdentityThenNewest(p3, p4) -- inferred equivalent call
			end

			return StockLast(fn) -- inferred equivalent call
		else
			if p == "Newest" then
				local function fn(p3, p4)
					local newestSortTimestamp = GetNewestSortTimestamp(p3) -- inferred equivalent call
					local newestSortTimestamp2 = GetNewestSortTimestamp(p4) -- inferred equivalent call

					if newestSortTimestamp ~= newestSortTimestamp2 then
						return newestSortTimestamp2 < newestSortTimestamp
					end

					local v7 = memoizePerItem(p3)
					local v8 = memoizePerItem(p4)

					if v7 == v8 then
						return (p3._id or "") < (p4._id or "")
					end

					return v7 < v8
				end

				return StockLast(fn) -- inferred equivalent call
			elseif p == "Quality" then
				local function fn(p3, p4)
					local v7 = memoizePerItem2(p3)
					local v8 = memoizePerItem2(p4)

					if v7 ~= v8 then
						return v8 < v7
					end

					return CompareIdentityThenNewest(p3, p4) -- inferred equivalent call
				end

				return StockLast(fn) -- inferred equivalent call
			end

			if p == "Type" then
				local memoizePerItem3 = MemoizePerItem(GetTypeSortPriority) -- inferred equivalent call

				local function fn(p3, p4)
					local v7 = memoizePerItem3(p3)
					local v8 = memoizePerItem3(p4)

					if v7 ~= v8 then
						return v7 < v8
					end

					return CompareIdentityThenNewest(p3, p4) -- inferred equivalent call
				end

				return StockLast(fn) -- inferred equivalent call
			else
				if p == "Float" then
					local function fn(p3, p4)
						local badge = IsBadge(p3) -- inferred equivalent call
						local badge2 = IsBadge(p4) -- inferred equivalent call

						if badge ~= badge2 then
							return badge2, true
						end

						local charm = IsCharm(p3) -- inferred equivalent call
						local charm2 = IsCharm(p4) -- inferred equivalent call

						if charm ~= charm2 then
							return charm2, true
						end

						local float = p3.Float
						local float2 = p4.Float

						if float ~= nil and float2 ~= nil and float ~= float2 then
							return float < float2
						end

						if float ~= nil and float2 == nil then
							return true
						end

						if float == nil and float2 ~= nil then
							return false
						end

						return CompareIdentityThenNewest(p3, p4) -- inferred equivalent call
					end

					return StockLast(fn) -- inferred equivalent call
				end

				if p ~= "Serial" then
					return nil
				end

				local function fn(p3, p4)
					local serial = GetSerial(p3) -- inferred equivalent call
					local serial2 = GetSerial(p4) -- inferred equivalent call

					if serial == nil or serial2 == nil then
						if serial ~= nil then
							return true, true
						end

						if serial2 ~= nil then
							return false, true
						end
					elseif serial ~= serial2 then
						return serial < serial2
					end

					return CompareIdentityThenNewest(p3, p4) -- inferred equivalent call
				end

				return StockLast(fn) -- inferred equivalent call
			end
		end
	end
}