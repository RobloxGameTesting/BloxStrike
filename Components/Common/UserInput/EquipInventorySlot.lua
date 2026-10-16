local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)

local function isZeusInventorySpace(p)
	return p.Name == "Zeus x27"
end

local function getSpaceNumber(list, p: string) -- 2 equivalent calls inferred from this helper
	for i, v in ipairs(list) do
		if v.Identifier == p then
			return i
		end
	end

	return 0
end

local function getPreferredSpaceOrder(p: number, list, callback)
	local result = {}

	if p == 3 then
		for i, v in ipairs(list) do
			if v.Name ~= "Zeus x27" then
				table.insert(result, i)
			end
		end

		for i, v in ipairs(list) do
			if v.Name == "Zeus x27" then
				table.insert(result, i)
			end
		end
	else
		for i = 1, #list do
			if not callback or callback(list[i]) then
				table.insert(result, i)
			end
		end
	end

	return result
end

local function getPreferredSpaceNumber(p: number, list, p2: string?, callback)
	local preferredSpaceOrder = getPreferredSpaceOrder(p, list, callback)
	local v = preferredSpaceOrder[1]

	if not v then
		return 0
	end

	if not p2 then
		return v
	end

	local index = table.find(preferredSpaceOrder, getSpaceNumber(list, p2)) -- inferred equivalent call

	if index then
		return preferredSpaceOrder[index + 1] or v
	end

	return v
end

return function(p: number, callback)
	local currentEquipped = InventoryController.getCurrentEquipped()
	local inventorySlot = InventoryController.getInventorySlot(p)

	if not inventorySlot then
		return
	end

	local identifier

	if currentEquipped and (currentEquipped.Slot or 1) == p then
		identifier = currentEquipped.Identifier
	end

	local items = inventorySlot._items
	local preferredSpaceOrder = getPreferredSpaceOrder(p, items, callback)
	local v = preferredSpaceOrder[1]
	local v2

	if v then
		if identifier then
			local index = table.find(preferredSpaceOrder, getSpaceNumber(items, identifier)) -- inferred equivalent call

			if index then
				v2 = preferredSpaceOrder[index + 1]

				if not v2 then
					v2 = v
				end
			else
				v2 = v
			end
		else
			v2 = v
		end
	else
		v2 = 0
	end

	if v2 > 0 then
		InventoryController.equip(p, v2)
	end
end