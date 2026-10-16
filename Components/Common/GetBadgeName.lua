local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
return function(player, p)
	if not player:IsA("Player") then
		return ""
	end

	local v, v2 = DataController.Get(player, "Loadout", "Inventory")

	if not (v and v2) then
		return ""
	end

	local v3 = v[p]

	if not (v3 and v3.Equipped) then
		return ""
	end

	local equippedBadge = v3.Equipped["Equipped Badge"]

	if not equippedBadge or equippedBadge == "" then
		return ""
	end

	local v4 = nil

	for _, v5 in ipairs(v2) do
		if v5._id ~= equippedBadge then
			continue
		end

		v4 = v5
		break
	end

	if not v4 then
		return ""
	end

	if Skins.GetSkinInformation(v4.Name, v4.Skin) then
		return GetSkinDisplayName.GetSkinDisplayName(v4.Skin)
	end

	return ""
end