local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local InspectController = require(ReplicatedStorage.Controllers.InspectController)

local function equipFallback()
	local currentInventory = InventoryController.getCurrentInventory()
	local currentEquipped = InventoryController.getCurrentEquipped()

	if not (currentInventory and currentEquipped) then
		return
	end

	local slot = nil
	local v = nil

	for _, v2 in ipairs(currentInventory) do
		for i, item in ipairs(v2._items) do
			if item.Identifier == currentEquipped.Identifier then
				continue
			end

			slot = item.Slot
			v = i
			break
		end
	end

	if slot and v then
		InventoryController.equip(slot, v)
	end
end

local function onInput(p, _)
	if LocalPlayer:GetAttribute("IsPlayerChatting") or p ~= Enum.UserInputState.Begin then
		return
	end

	if CaseSceneController.IsActive() or BlackMarketSceneController.IsActive() or InspectController.IsActive() then
		return
	end

	local previousEquipped = InventoryController.getPreviousEquipped()

	if not previousEquipped then
		equipFallback()
		return
	end

	local _, v, v2 = InventoryController.getInventoryItemFromLoadout(previousEquipped.Identifier)

	if v and v2 then
		InventoryController.equip(v, v2)
	end
end

return table.freeze({
	Name = "Last Weapon Used",
	Group = "Gameplay",
	Category = "Weapon Keys",
	Callback = onInput
})