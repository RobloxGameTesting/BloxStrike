local Loadout = {}
Loadout.__index = Loadout
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
require(script:WaitForChild("Types"))
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local LocalPlayer = Players.LocalPlayer
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local NumberSlots = require(ReplicatedStorage.Database.Custom.GameStats.NumberSlots)
local Grenade = require(ReplicatedStorage.Components.Grenade)
local Weapon = require(ReplicatedStorage.Components.Weapon)
local Melee = require(ReplicatedStorage.Components.Melee)
local C4 = require(ReplicatedStorage.Components.C4)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local v = { Grenade = Grenade, Weapon = Weapon, Melee = Melee, C4 = C4 }

function Loadout:setCurrentEquipped(currentEquipped)
	self.PreviousEquipped = self.CurrentEquipped
	self.CurrentEquipped = currentEquipped
end

function Loadout.getNextInventorySlotFromPriority(p)
	local v2 = -1
	local v3 = nil

	for i, v4 in ipairs(p.Inventory) do
		local v5 = NumberSlots.Priorities[i] or 0

		if not (#v4._items >= 1 and v2 < v5) then
			continue
		end

		v3 = i
		v2 = v5
	end

	return v3
end

function Loadout:getInventoryItemFromLoadout(p: string)
	local v2 = nil
	local v3 = nil
	local v4 = nil

	for i, v5 in ipairs(self.Inventory) do
		for j, item in ipairs(v5._items) do
			if item.Identifier ~= p then
				continue
			end

			v4 = j
			v3 = i
			v2 = item
			break
		end
	end

	return v2, v3, v4
end

function Loadout:removeInventoryItem(p: string)
	local inventoryItem, v2, v3 = self:getInventoryItemFromLoadout(p)
	local v4 = inventoryItem and self.Inventory[v2]

	if not v4 then
		return
	end

	table.remove(v4._items, v3)

	if self.CurrentEquipped == inventoryItem then
		self:setCurrentEquipped(nil)
	end

	inventoryItem:destroy()
end

function Loadout.grantPlayerInventoryItem(p, p2: number, p3: string, p4: string?, p5: string, p6: string, p7: number, p8, p9, p10: string?, p11, p12, p13)
	local v2 = p.Inventory[p2]
	assert(v2, `{p2} does not exist in player inventory`)
	local weaponProperties = GetWeaponProperties(p5)
	assert(weaponProperties, `Client couldn't find weapon properties for "{p5}"`)
	local v3 = v[weaponProperties.Class]
	assert(v3, `Client couldn't find weapon component for "{p5}"`)
	debug.profilebegin("Loadout.grantPlayerInventoryItem")
	debug.profilebegin("Loadout.grantPlayerInventoryItem.Component.new")
	local success, result = pcall(v3.new, LocalPlayer, p3, p4, p2, p5, p6, p7, p8, p9, p10, p11, p12, p13)
	debug.profileend()

	if not success then
		debug.profileend()
		error(result, 2)
	end

	debug.profilebegin("Loadout.grantPlayerInventoryItem.InsertAndCleanup")
	table.insert(v2._items, result)
	p.Janitor:Add(function()
		if result and getmetatable(result) and not result.IsDestroyed then
			result:destroy()
		end
	end)
	debug.profileend()
	debug.profileend()
end

function Loadout.new(inventory)
	debug.profilebegin("Loadout.new")
	local object = setmetatable({}, Loadout)
	object.Janitor = Janitor.new()
	object.IsDestroyed = false
	object.Inventory = inventory
	object.Janitor:Add(RunServiceController.BindToRenderStep(
		"Classes.Loadout.RenderEquippedViewmodel",
		function(p: number)
			if object.IsDestroyed then
				return
			end

			local playerCharacter = CharacterResolver.getPlayerCharacter(LocalPlayer)

			if playerCharacter and playerCharacter:GetAttribute("Dead") then
				return
			end

			if object.CurrentEquipped and object.CurrentEquipped.Viewmodel.IsEquipped then
				debug.profilebegin("Loadout.RenderEquippedViewmodel")
				object.CurrentEquipped.Viewmodel:render(p)
				debug.profileend()
			end
		end
	))
	debug.profileend()
	return object
end

function Loadout:destroy()
	if self.IsDestroyed then
		return
	end

	debug.profilebegin("Loadout.destroy")
	self.IsDestroyed = true

	if self.CurrentEquipped then
		if self.CurrentEquipped.unequip then
			self.CurrentEquipped:unequip()
		end

		if self.CurrentEquipped.destroy and not self.CurrentEquipped.IsDestroyed then
			self.CurrentEquipped:destroy()
		end

		self.CurrentEquipped = nil
	end

	if self.PreviousEquipped then
		if self.PreviousEquipped.destroy and not self.PreviousEquipped.IsDestroyed then
			self.PreviousEquipped:destroy()
		end

		self.PreviousEquipped = nil
	end

	if self.Inventory then
		for _, v2 in ipairs(self.Inventory) do
			if v2._items then
				table.clear(v2._items)
			end
		end
	end

	self.Janitor:Destroy()
	self.Janitor = nil
	self.Inventory = nil
	debug.profileend()
end

return Loadout