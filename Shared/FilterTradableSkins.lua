local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local InventoryCharmUtils = require(ReplicatedStorage.Shared.InventoryCharmUtils)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local frozen = table.freeze({ Stock = true, Default = true })
return function(items)
	local tradeContext = InventoryCharmUtils.GetTradeContext(items)
	local v = {}

	for _, item in items do
		if not (frozen[item.Skin] ~= true and Skins.HasSkinTextures(item.Name, item.Skin) and InventoryCharmUtils.IsTradeableItem(item, tradeContext)) then
			continue
		end

		table.insert(v, item)
	end

	return InventoryCharmUtils.ResolveCharmReferences(v, tradeContext)
end