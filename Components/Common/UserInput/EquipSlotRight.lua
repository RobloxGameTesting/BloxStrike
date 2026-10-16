local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)

local function getSpaceNumber(items, identifier: string) -- 1 equivalent call inferred from this helper
	for i, v in ipairs(items) do
		if v.Identifier == identifier then
			return i
		end
	end

	return 0
end

return function()
	local currentEquipped = InventoryController.getCurrentEquipped()

	if not currentEquipped then
		return
	end

	local slot = currentEquipped.Slot or 1
	local inventorySlot = InventoryController.getInventorySlot(slot)
	local spaceNumber = getSpaceNumber(inventorySlot._items, currentEquipped.Identifier) -- inferred equivalent call

	if spaceNumber < #inventorySlot._items then
		InventoryController.equip(slot, spaceNumber + 1)
		return
	end

	local currentInventory = InventoryController.getCurrentInventory()
	local v = slot

	for i = 1, #currentInventory do
		if not (#currentInventory[i]._items > 0 and v < i) then
			continue
		end

		v = i
		break
	end

	if v == slot then
		for i = 1, #currentInventory do
			if not (#currentInventory[i]._items > 0 and i < v) then
				continue
			end

			v = i
			break
		end
	end

	InventoryController.equip(v, 1)
end