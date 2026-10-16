local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local InventoryCharmUtils = {
	IsCharmItem = function(p)
		return p.Type == "Charm" or p.Name == "Charm"
	end
}

local function getCharmReference(p) -- 2 equivalent calls inferred from this helper
	local charm = p.Charm

	if typeof(charm) == "table" then
		return charm
	end

	return nil
end

local function getEquippedCharmId(p) -- 2 equivalent calls inferred from this helper
	local charmReference = getCharmReference(p) -- inferred equivalent call

	if charmReference then
		return charmReference._id
	end

	return nil
end

local function isValidCharmItem(p) -- 1 equivalent call inferred from this helper
	return p ~= nil and InventoryCharmUtils.IsCharmItem(p) and p.IsTradeable ~= false
end

function InventoryCharmUtils.GetTradeContext(items)
	local v = { itemsById = {}, attachedCharmIds = {} }

	for _, item in items do
		v.itemsById[item._id] = item
		local equippedCharmId = getEquippedCharmId(item) -- inferred equivalent call

		if equippedCharmId then
			v.attachedCharmIds[equippedCharmId] = true
		end
	end

	return v
end

function InventoryCharmUtils:IsTradeableItem(p)
	if self.IsTradeable == false then
		return false
	end

	if InventoryCharmUtils.IsCharmItem(self) then
		return p.attachedCharmIds[self._id] ~= true
	end

	local equippedCharmId = getEquippedCharmId(self) -- inferred equivalent call

	if not equippedCharmId then
		return true
	end

	return isValidCharmItem(p.itemsById[equippedCharmId]) -- inferred equivalent call
end

function InventoryCharmUtils.ResolveCharmReferences(list, p)
	local v = p or InventoryCharmUtils.GetTradeContext(list)
	local clones = table.create(#list)

	for k, clone in list do
		local charmReference = getCharmReference(clone) -- inferred equivalent call
		local v2

		if charmReference then
			v2 = v.itemsById[charmReference._id]
		end

		if
			charmReference
			and (not charmReference.Skin or charmReference.Skin == "" or not charmReference.Pattern)
			and v2
			and InventoryCharmUtils.IsCharmItem(v2)
		then
			local clone2 = table.clone(charmReference)

			if not clone2.Skin or clone2.Skin == "" then
				clone2.Skin = v2.Skin
			end

			clone2.Pattern = clone2.Pattern or v2.Pattern or 1
			clone = table.clone(clone)
			clone.Charm = clone2
		end

		clones[k] = clone
	end

	return clones
end

return InventoryCharmUtils