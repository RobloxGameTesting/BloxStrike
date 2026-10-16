local ReplicatedStorage = game:GetService("ReplicatedStorage")
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Stock = require(ReplicatedStorage.Database.Components.Libraries.Stock)
local frozen = table.freeze({
	BuyWeapons = table.freeze({ "AK-47" }),
	BuyCTWeapons = table.freeze({ "M4A4", "M4A1-S" })
})
local frozen2 = table.freeze({
	GoToRange = true,
	PracticeAK = true,
	KillCTs = true,
	PlantBomb = true,
	WaitExplode = true,
	GoToCTBuy = true,
	KillTs = true,
	DefuseB = true
})
local frozen3 = table.freeze({
	Terrorists = frozen.BuyWeapons,
	["Counter-Terrorists"] = frozen.BuyCTWeapons
})
local TutorialPurchaseLock = {
	getRequiredItems = function(instance)
		if not IsTutorialMode() then
			return nil
		end

		local tutorialStep = instance:GetAttribute("TutorialStep")

		if typeof(tutorialStep) == "string" then
			return frozen[tutorialStep]
		end

		return nil
	end,
	isBuyMenuLocked = function(instance)
		if not IsTutorialMode() then
			return false
		end

		local tutorialStep = instance:GetAttribute("TutorialStep")
		return typeof(tutorialStep) == "string" and frozen2[tutorialStep] == true
	end
}

function TutorialPurchaseLock.isPurchaseAllowed(p, p2: string)
	if TutorialPurchaseLock.isBuyMenuLocked(p) then
		return false
	end

	local requiredItems = TutorialPurchaseLock.getRequiredItems(p)
	return not requiredItems or table.find(requiredItems, p2) ~= nil
end

function TutorialPurchaseLock.isWaitingOnPurchase(p, callback)
	local requiredItems = TutorialPurchaseLock.getRequiredItems(p)

	if not requiredItems then
		return false
	end

	for _, requiredItem in ipairs(requiredItems) do
		if callback(requiredItem) then
			return false
		end
	end

	return true
end

function TutorialPurchaseLock.getForcedLoadoutItem(p: string, p2: string, p3, items)
	if p2 ~= "Loadout.Rifles.Options.1" or not IsTutorialMode() then
		return nil
	end

	local v = frozen3[p]

	if not v then
		return nil
	end

	local v2

	if typeof(p3) == "table" then
		v2 = p3[p]
	end

	local rifles

	if typeof(v2) == "table" and typeof(v2.Loadout) == "table" then
		rifles = v2.Loadout.Rifles
	end

	local options

	if typeof(rifles) == "table" then
		options = rifles.Options
	end

	if typeof(options) ~= "table" then
		return Stock.GetStockInventoryItem(v[1])
	end

	for _, option in options do
		local name

		if typeof(option) == "string" then
			name = Stock.GetWeaponNameFromStockId(option)
		end

		if not name and typeof(items) == "table" then
			for _, item in items do
				if item._id ~= option then
					continue
				end

				name = item.Name
				break
			end
		end

		if name and table.find(v, name) then
			return nil
		end
	end

	return Stock.GetStockInventoryItem(v[1])
end

return TutorialPurchaseLock