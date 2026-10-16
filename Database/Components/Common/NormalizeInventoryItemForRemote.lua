local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Sift = require(ReplicatedStorage.Packages.Sift)
local v = { "_id", "Type", "Name", "Skin", "Rarity", "OriginalOwner" }
local v2 = { "LastTradeAt", "CreatedAt" }
local v3 = { "OriginalOwner", "Owner", "Origin", "GlobalMarketPlaceListingReference" }
return function(p)
	if typeof(p) ~= "table" then
		return p
	end

	local result = Sift.Dictionary.copyDeep(p)

	for _, v4 in v do
		if typeof(result[v4]) == "number" then
			result[v4] = tostring(result[v4])
		end
	end

	local metaData = result.MetaData

	if typeof(metaData) ~= "table" then
		return result
	end

	for _, v4 in v2 do
		if typeof(metaData[v4]) == "string" then
			metaData[v4] = tonumber(metaData[v4])
		end
	end

	if metaData.GlobalMarketPlaceListingReference == false then
		metaData.GlobalMarketPlaceListingReference = nil
	end

	for _, v4 in v3 do
		if typeof(metaData[v4]) == "number" then
			metaData[v4] = tostring(metaData[v4])
		end
	end

	return result
end