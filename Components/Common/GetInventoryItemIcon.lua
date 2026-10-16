local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local v = {
	["Counter-Terrorists"] = "rbxassetid://120553709154808",
	Terrorists = "rbxassetid://76834532512077"
}
local v2 = { Weapon = true, Melee = true }

local function GetSkinRender(p)
	if typeof(p.Name) ~= "string" then
		return nil
	end

	local v3 = (typeof(p.Skin) ~= "string" or p.Skin == "") and "Stock" or p.Skin
	local skinInformation = Skins.GetSkinInformation(p.Name, v3)

	if not skinInformation then
		return nil
	end

	if skinInformation.wearImages and skinInformation.wearImages[1] then
		return skinInformation.wearImages[1].assetId
	end

	return skinInformation.imageAssetId
end

return function(p, value)
	if not (p and p.Properties) then
		return nil
	end

	local v3 = p.Name == "Smoke Grenade" and typeof(value) == "string" and v[value]

	if v3 then
		return v3
	end

	local v4 = v2[p.Properties.Class] and GetSkinRender(p)
	return v4 or p.Properties.Icon
end