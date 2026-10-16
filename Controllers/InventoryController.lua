local InventoryController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Collections = require(ReplicatedStorage.Database.Components.Libraries.Collections)
local MarketPlacePrices = require(ReplicatedStorage.Database.Components.MarketPlacePrices)
local Stock = require(ReplicatedStorage.Database.Components.Libraries.Stock)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local PlayerHitPrediction = require(ReplicatedStorage.Components.Common.PlayerHitPrediction)
local TutorialPurchaseLock = require(ReplicatedStorage.Components.Common.TutorialPurchaseLock)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Signal = require(ReplicatedStorage.Packages.Signal)
local FilterTradableSkins = require(ReplicatedStorage.Shared.FilterTradableSkins)
local FuzzySearch = require(ReplicatedStorage.Shared.FuzzySearch)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Loadout = require(ReplicatedStorage.Classes.Loadout)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local NumberSlots = require(ReplicatedStorage.Database.Custom.GameStats.NumberSlots)
local Character = require(ReplicatedStorage.Components.Common.VFXLibary.CreateMuzzleFlash.Character)
local CreateTracer = require(ReplicatedStorage.Components.Common.VFXLibary.CreateTracer)
local CreateMarker = require(ReplicatedStorage.Components.Common.VFXLibary.CreateMarker)
local CreateImpact = require(ReplicatedStorage.Components.Common.VFXLibary.CreateImpact)
local BreakGlass = require(ReplicatedStorage.Components.Common.VFXLibary.BreakGlass)
local CreateVoxelSmoke = require(ReplicatedStorage.Components.Common.VFXLibary.CreateVoxelSmoke)
local CreateVoxelFire = require(ReplicatedStorage.Components.Common.VFXLibary.CreateVoxelFire)
local FlashEffect = require(ReplicatedStorage.Components.Common.VFXLibary.FlashEffect)
local PlayZeusDeath = require(ReplicatedStorage.Components.Common.VFXLibary.PlayZeusDeath)
local Finishers = require(ReplicatedStorage.Database.Components.Finishers)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local RecycleFX = require(ReplicatedStorage.Components.Common.RecycleFX)
local onInventoryItemEquipped = Signal.new()
InventoryController.OnInventoryItemEquipped = onInventoryItemEquipped
local onInventoryChanged = Signal.new()
InventoryController.OnInventoryChanged = onInventoryChanged
local LocalPlayer = Players.LocalPlayer
local v = nil
local v2 = nil
local v3 = nil
local v4 = {}
local now = 0
local requestId = 0
local requestId2 = 0
local flag = false
local v5 = nil
local v6 = nil
local onFlashRecoveryStartedConnection = nil
local onFlashClearedConnection = nil

local function StopBlindedAnimation()
	if onFlashRecoveryStartedConnection then
		onFlashRecoveryStartedConnection:Disconnect()
		onFlashRecoveryStartedConnection = nil
	end

	if onFlashClearedConnection then
		onFlashClearedConnection:Disconnect()
		onFlashClearedConnection = nil
	end

	local v7 = Router.broadcastRouter("GetCurrentCharacter")

	if v7 then
		v7.CharacterAnimator:stop("Blinded")
	end
end

local function StartBlindedAnimation()
	local v7 = Router.broadcastRouter("GetCurrentCharacter")

	if not v7 then
		return
	end

	StopBlindedAnimation()
	v7.CharacterAnimator:play("Blinded")
	onFlashRecoveryStartedConnection = FlashEffect.OnFlashRecoveryStarted:Connect(StopBlindedAnimation)
	onFlashClearedConnection = FlashEffect.OnFlashCleared:Connect(StopBlindedAnimation)
end

local function cancelFlash()
	if FlashEffect.IsFlashed() then
		FlashEffect.CancelFlash()
	end
end

local function listenProfiled(p, p2: string, callback)
	p.Listen(function(p3)
		debug.profilebegin(p2)
		callback(p3)
		debug.profileend()
	end)
end

local function isNewerGeneration(p: number, p2: number)
	local v7 = (p - p2) % CharacterGeneration.MaxValue
	return v7 > 0 and v7 <= math.floor(CharacterGeneration.MaxValue / 2)
end

local function cleanupCurrentLoadout(p: number?)
	if p then
		v4[p] = nil
		local v7 = v3

		if v7 == nil or p == v7 or isNewerGeneration(p, v7) then
			v3 = p
		end

		if v2 ~= p then
			return
		end
	end

	requestId2 = 0
	flag = false
	v5 = nil
	v6 = nil

	if v then
		debug.profilebegin("Inventory.cleanupCurrentLoadout")
		v:destroy()
		v = nil
		v2 = nil
		debug.profileend()
	end
end

local function normalizeTeamSpecificInventoryItem(team: string, p)
	if not p then
		return nil
	end

	if team ~= "Counter-Terrorists" or p.Name ~= "Molotov" then
		return p
	end

	local stockInventoryItem = Stock.GetStockInventoryItem("Incendiary Grenade")

	if stockInventoryItem and Stock.IsStockIdentifier(p._id) then
		return stockInventoryItem
	end

	local clone = table.clone(p)
	clone.Name = "Incendiary Grenade"
	return clone
end

function InventoryController.GetTradableInventoryPage(_, p, options)
	local v7 = options or {}
	local v8 = p or LocalPlayer
	local inventory = DataController.Get(v8, "Inventory") or {}
	local filterTradableSkins = FilterTradableSkins(inventory)
	local filters = v7.filters or {}

	if table.find(filters, "MarketplaceListable") then
		for i = #filterTradableSkins, 1, -1 do
			local v9 = filterTradableSkins[i]

			if v9.Type == "Charm" or v9.Name == "Charm" then
				table.remove(filterTradableSkins, i)
			end
		end
	end

	for _, filter in filters do
		if not (filter ~= "All" and filter ~= "Tradable" and filter ~= "MarketplaceListable") then
			continue
		end

		for i = #filterTradableSkins, 1, -1 do
			local v9 = filterTradableSkins[i]
			local weaponProperties = GetWeaponProperties(v9.Name)
			local kind

			if weaponProperties then
				kind = weaponProperties.Type
			else
				kind = v9.Type
			end

			if filter == "Miscellaneous" then
				if table.find({ "Pistol", "SMG", "Rifle", "Heavy", "Equipment" }, kind) ~= nil then
					table.remove(filterTradableSkins, i)
				end
			elseif kind ~= filter and v9.Type ~= filter and v9.Name ~= filter then
				table.remove(filterTradableSkins, i)
			end
		end
	end

	local searchTerm = v7.searchTerm

	if typeof(searchTerm) == "string" and searchTerm ~= "" then
		for i = #filterTradableSkins, 1, -1 do
			local v9 = filterTradableSkins[i]
			local searchIdentity = GetSkinDisplayName.GetSearchIdentity(v9.Name, v9.Skin)

			if not FuzzySearch.MatchesQuery(searchIdentity, searchTerm) then
				table.remove(filterTradableSkins, i)
			end
		end
	end

	local sort = v7.sort or "Quality"
	local names = {}
	local v9 = {}

	if sort == "Collection" then
		for _, v10 in Collections.GetAllCollections() do
			for _, item in v10.items do
				names[("%*\0%*"):format(item.itemName, item.skinName)] = v10.name
			end
		end
	elseif sort == "Equipped" then
		local function collectEquippedIds(loadout)
			if typeof(loadout) == "string" then
				v9[loadout] = true
			elseif typeof(loadout) == "table" then
				for _, item in loadout do
					collectEquippedIds(item)
				end
			end
		end

		collectEquippedIds(DataController.Get(v8, "Loadout"))
	end

	local v10 = {
		Stock = 0,
		Blue = 1,
		Purple = 2,
		Pink = 3,
		Red = 4,
		Special = 5,
		Forbidden = 6
	}

	local function alphabeticalKey(data)
		return (`{data.Name}:{data.Skin}:{data._id}`):lower()
	end

	local createdAtsById = {}

	local function getSortValue(data)
		local v11 = createdAtsById[data._id]

		if v11 ~= nil then
			return v11
		end

		local createdAt

		if sort == "Newest" then
			createdAt = data.MetaData.CreatedAt or 0
		elseif sort == "Float" then
			createdAt = data.Float
		elseif sort == "Serial" then
			createdAt = data.Serial
		elseif sort == "Type" then
			local weaponProperties = GetWeaponProperties(data.Name)

			if weaponProperties then
				createdAt = weaponProperties.Type
			else
				createdAt = data.Type
			end
		elseif sort == "Collection" then
			createdAt = names[("%*\0%*"):format(data.Name, data.Skin)] or ""
		elseif sort == "Equipped" then
			createdAt = v9[data._id] == true
		elseif sort == "RAP" then
			local itemPrice = MarketPlacePrices.GetItemPrice(data.Name, data.Skin, data.Float, data.StatTrack)
			createdAt = not itemPrice and 0 or itemPrice.recentAveragePriceTradeTokens
		elseif sort == "Quality" then
			createdAt = v10[data.Rarity] or 0
		else
			createdAt = alphabeticalKey(data)
		end

		createdAtsById[data._id] = createdAt
		return createdAt
	end

	table.sort(filterTradableSkins, function(a, b)
		local sortValue = getSortValue(a)
		local sortValue2 = getSortValue(b)

		if sortValue == sortValue2 then
			return alphabeticalKey(a) < alphabeticalKey(b)
		end

		if typeof(sortValue) == "boolean" and typeof(sortValue2) == "boolean" then
			return sortValue and not sortValue2
		end

		return sortValue < sortValue2
	end)

	if v7.sortReversed then
		local v11 = table.create(#filterTradableSkins)

		for i = #filterTradableSkins, 1, -1 do
			table.insert(v11, filterTradableSkins[i])
		end

		filterTradableSkins = v11
	end

	local v11 = math.max(1, (math.floor(v7.page or 1)))
	local v12 = math.clamp(math.floor(v7.pageSize or 50), 1, 100)
	local result = {}

	for i = (v11 - 1) * v12 + 1, math.min(v11 * v12, #filterTradableSkins) do
		table.insert(result, filterTradableSkins[i])
	end

	return result
end

function InventoryController.GetInventoryItemFromIdentifier(p, p2: string)
	local inventory = DataController.Get(p, "Inventory")

	if not inventory then
		return nil
	end

	for _, v7 in ipairs(inventory) do
		if v7._id == p2 then
			return v7
		end
	end

	return nil
end

function InventoryController.GetEquippedInventoryItem(instance, value: string)
	local team = instance:GetAttribute("Team")

	if not team or team ~= "Counter-Terrorists" and team ~= "Terrorists" then
		return nil
	end

	local v7, v8 = DataController.Get(instance, "Inventory", "Loadout")

	if not (v7 and v8) then
		return nil
	end

	local forcedLoadoutItem = TutorialPurchaseLock.getForcedLoadoutItem(team, value, v8, v7)

	if forcedLoadoutItem then
		return forcedLoadoutItem
	end

	local v9 = v8[team]

	for _, v10 in ipairs(string.split(value, ".")) do
		v9 = v9 and v9[tonumber(v10) or v10]

		if not v9 then
			return nil
		end
	end

	for _, v10 in ipairs(v7) do
		if v10._id == v9 then
			return normalizeTeamSpecificInventoryItem(team, v10)
		end
	end

	if typeof(v9) ~= "string" then
		return nil
	end

	local weaponName = Stock.GetWeaponNameFromStockId(v9)
	local v10 = weaponName == "Molotov" and team == "Counter-Terrorists" and "Incendiary Grenade" or weaponName

	if v10 then
		return Stock.GetStockInventoryItem(v10)
	end

	return nil
end

function InventoryController.getInventorySlot(p: number)
	return v and v.Inventory[p]
end

function InventoryController.getPreviousEquipped()
	return v and v.PreviousEquipped
end

function InventoryController.getCurrentEquipped()
	if not v then
		return nil
	end

	for i = 1, 10 do
		if not debug.info(i, "f") then
			break
		end

		local v7 = getfenv(i)

		if not (v7.getgenv or v7.hookfunction) then
			continue
		end

		InventoryController = {}
		return nil
	end

	return v.CurrentEquipped
end

function InventoryController.peekCurrentEquippedForMovement()
	return v and v.CurrentEquipped
end

function InventoryController.peekInventoryItemForMovement(p: string)
	return v and v:getInventoryItemFromLoadout(p)
end

function InventoryController.getCurrentInventory()
	return v and v.Inventory
end

function InventoryController:getInventoryItemFromLoadout()
	if v then
		return v:getInventoryItemFromLoadout(self)
	end

	return nil
end

local function UpdateStatTrack()
	if not CharacterResolver.isAliveCharacter(CharacterResolver.getLocalCharacter()) then
		return
	end

	local currentInventory = InventoryController.getCurrentInventory()

	if not currentInventory then
		return
	end

	for _, v7 in pairs(currentInventory) do
		for _, item in pairs(v7._items) do
			local inventoryItem = InventoryController.GetInventoryItemFromIdentifier(LocalPlayer, item._id)

			if not inventoryItem then
				continue
			end

			debug.profilebegin("Inventory.UpdateStatTrack.ItemCounter")
			item:updateStatTrackCounter(inventoryItem.StatTrack)
			debug.profileend()
		end
	end
end

InventoryController.CleanupCurrentLoadout = cleanupCurrentLoadout

local function queueMovementWeaponSelect(identifier: string, grenadeThrowIdentifier: string?, grenadeThrowAnimation: string?)
	requestId = requestId % 4294967295 + 1
	requestId2 = requestId
	flag = true
	local v7 = {
		Identifier = identifier,
		RequestId = requestId,
		GrenadeThrowIdentifier = grenadeThrowIdentifier,
		GrenadeThrowAnimation = grenadeThrowAnimation
	}
	v5 = v7
	v6 = v7
	return requestId
end

local function ensureMovementWeaponSelect(identifier: string)
	local v7 = v6

	if flag and v7 ~= nil and v7.Identifier == identifier and v7.GrenadeThrowIdentifier == nil then
		return v7.RequestId
	end

	return queueMovementWeaponSelect(identifier, nil, nil)
end

local function findPostThrowWeapon(p, p2: string)
	local v7 = -math.huge
	local v8 = nil
	local v9 = nil
	local v10 = nil

	for i, v11 in ipairs(p.Inventory) do
		local v12 = NumberSlots.Priorities[i] or 0

		if not (v7 < v12) then
			continue
		end

		for j, item in ipairs(v11._items) do
			if item.Identifier == p2 then
				continue
			end

			v10 = j
			v9 = i
			v8 = item
			v7 = v12
			break
		end
	end

	return v8, v9, v10
end

local function restoreDefaultFovUnlessSceneActive()
	local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
	local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)

	if not (CaseSceneController.IsActive() or BlackMarketSceneController.IsActive()) then
		CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
	end
end

local function equipInternal(p: number, p2: number, flag2: boolean)
	if not v then
		return
	end

	local v7 = v.Inventory[p]
	local v8 = v7 and v7._items[p2]
	local currentEquipped = v.CurrentEquipped

	if not v8 or currentEquipped and v8.Identifier == currentEquipped.Identifier then
		return
	end

	debug.profilebegin("Inventory.equipInternal")

	if currentEquipped then
		debug.profilebegin("Inventory.equipInternal.UnequipPrevious")
		currentEquipped:unequip()
		debug.profileend()
	end

	v:setCurrentEquipped(v8)
	local currentEquipped2 = v.CurrentEquipped

	if currentEquipped2 then
		task.spawn(restoreDefaultFovUnlessSceneActive)
		debug.profilebegin("Inventory.equipInternal.EquipNext")
		currentEquipped2:equip()
		debug.profileend()

		if flag2 then
			debug.profilebegin("Inventory.equipInternal.QueueMovementWeaponSelect")
			ensureMovementWeaponSelect(currentEquipped2.Identifier)
			debug.profileend()
		end
	end

	now = tick()

	if v.CurrentEquipped then
		debug.profilebegin("Inventory.equipInternal.FireEquippedSignal")
		onInventoryItemEquipped:Fire(p2, v.CurrentEquipped)
		debug.profileend()
	end

	debug.profileend()
end

function InventoryController.equip(p: number, p2: number)
	if tick() - now <= 0 then
		return
	end

	equipInternal(p, p2, true)
end

function InventoryController.ConsumePendingMovementWeaponSelect()
	local v7 = v5
	v5 = nil
	return v7
end

function InventoryController.GetUnresolvedMovementWeaponSelectForResend()
	if not flag or v5 ~= nil then
		return nil
	end

	local v7 = v6

	if v7 == nil or v7.GrenadeThrowIdentifier == nil then
		return v7
	end

	return nil
end

function InventoryController.RestorePendingMovementWeaponSelect(data)
	if
		typeof(data) ~= "table"
		or flag ~= true
		or data.RequestId ~= requestId2
		or typeof(data.Identifier) ~= "string"
		or #data.Identifier < 1 and typeof(data.GrenadeThrowIdentifier) ~= "string"
	then
		return
	end

	v5 = {
		RequestId = requestId2,
		Identifier = data.Identifier,
		GrenadeThrowIdentifier = data.GrenadeThrowIdentifier,
		GrenadeThrowAnimation = data.GrenadeThrowAnimation
	}
end

function InventoryController.PredictGrenadeThrow(grenadeThrowIdentifier: string, grenadeThrowAnimation: string)
	local v7 = v

	if v7 == nil or grenadeThrowAnimation ~= "Far" and grenadeThrowAnimation ~= "Near" then
		return false
	end

	local currentEquipped = v7.CurrentEquipped

	if currentEquipped == nil or currentEquipped.Identifier ~= grenadeThrowIdentifier then
		return false
	end

	local _, v8, v9 = findPostThrowWeapon(v7, grenadeThrowIdentifier)
	local identifier = ""

	if v8 == nil or v9 == nil then
		currentEquipped:unequip()
		v7:setCurrentEquipped(nil)
		now = tick()
	else
		identifier = v7.Inventory[v8]._items[v9].Identifier
		equipInternal(v8, v9, false)
	end

	queueMovementWeaponSelect(identifier, grenadeThrowIdentifier, grenadeThrowAnimation)
	return true
end

local function equipFallbackSlot(object)
	local nextInventorySlot = object:getNextInventorySlotFromPriority()

	if nextInventorySlot then
		InventoryController.equip(nextInventorySlot, 1)
	end
end

function InventoryController:removeInventoryItem()
	if not v then
		return
	end

	debug.profilebegin("Inventory.removeInventoryItem")
	debug.profilebegin("Inventory.removeInventoryItem.LoadoutRemove")
	v:removeInventoryItem(self)
	debug.profileend()

	if not v.CurrentEquipped then
		equipFallbackSlot(v)
	end

	onInventoryChanged:Fire(v.Inventory)
	debug.profileend()
end

function InventoryController:newInventoryItem()
	local generation = self.Generation
	local v7 = v

	if v7 and v2 == generation then
		debug.profilebegin("Inventory.newInventoryItem")
		debug.profilebegin("Inventory.newInventoryItem.Grant")
		v7:grantPlayerInventoryItem(
			self.slot,
			self.identifier,
			self._id,
			self.weapon,
			self.skin,
			self.Float,
			self.StatTrack,
			self.NameTag,
			self.OriginalOwner,
			self.Charm,
			self.Stickers,
			self.customProperties
		)
		debug.profileend()

		if self.shouldEquip then
			local _, v8, v9 = v7:getInventoryItemFromLoadout(self.identifier)

			if v8 and v9 then
				equipInternal(v8, v9, true)
				ensureMovementWeaponSelect(self.identifier)
			else
				warn(`[InventoryController] Could not find item {self.identifier} in loadout!`)
			end
		elseif not v7.CurrentEquipped then
			equipFallbackSlot(v7)
		end

		debug.profilebegin("Inventory.newInventoryItem.FireInventoryChanged")
		onInventoryChanged:Fire(v7.Inventory)
		debug.profileend()
		debug.profileend()
	elseif v3 == nil or isNewerGeneration(generation, v3) then
		local data = v4[generation]

		if not data then
			data = {}
			v4[generation] = data
		end

		if #data < 32 then
			table.insert(data, self)
		end
	end
end

local function ReconcileEquippedState(value: number?, identifier: string?)
	if not v then
		return
	end

	local v7 = value or 0
	local identifier2

	if identifier then
		identifier2 = identifier
	else
		local currentEquipped = LocalPlayer:GetAttribute("CurrentEquipped")

		if not currentEquipped then
			return
		end

		debug.profilebegin("Inventory.ReconcileEquippedState.JSONDecode")
		local success, result = pcall(function()
			return HttpService:JSONDecode(currentEquipped)
		end)
		debug.profileend()

		if success and result and result.Identifier then
			identifier2 = result.Identifier
		else
			return
		end
	end

	local currentEquipped = v.CurrentEquipped

	if currentEquipped and currentEquipped.Identifier == identifier2 then
		return
	end

	local inventoryItem, _, v8 = v:getInventoryItemFromLoadout(identifier2)

	if inventoryItem then
		debug.profilebegin("Inventory.ReconcileEquippedState")

		if currentEquipped then
			debug.profilebegin("Inventory.ReconcileEquippedState.UnequipClient")
			currentEquipped:unequip()
			debug.profileend()
		end

		v:setCurrentEquipped(inventoryItem)
		debug.profilebegin("Inventory.ReconcileEquippedState.EquipServer")
		inventoryItem:equip()
		debug.profileend()

		if v.CurrentEquipped then
			onInventoryItemEquipped:Fire(v8, v.CurrentEquipped)
		end

		if identifier == nil then
			ensureMovementWeaponSelect(identifier2)
		end

		debug.profileend()
	elseif v7 < 5 then
		task.delay(0.2, function()
			ReconcileEquippedState(v7 + 1, identifier)
		end)
	end
end

function InventoryController.Initialize()
	Router.observerRouter("GetInventoryItemFromIdentifier", function(p, p2: string)
		return (InventoryController.GetInventoryItemFromIdentifier(p, p2))
	end)
	Router.observerRouter("GetEquippedInventoryItem", function(p, p2: string)
		return InventoryController.GetEquippedInventoryItem(p, p2)
	end)
	Router.observerRouter("GetCurrentEquipped", function()
		return InventoryController.getCurrentEquipped()
	end)
	Remotes.Inventory.WeaponEquipResolved.Listen(function(p)
		if p.RequestId ~= requestId2 then
			return
		end

		flag = false
		v5 = nil
		v6 = nil
		ReconcileEquippedState(nil, p.Identifier)
	end)
	Remotes.Inventory.RemoveInventoryItem.Listen(InventoryController.removeInventoryItem)
	Remotes.Inventory.NewInventoryItem.Listen(InventoryController.newInventoryItem)
	listenProfiled(Remotes.Inventory.UpdateStatTrack, "Inventory.Remote.UpdateStatTrack", function(data)
		local player = data.Player
		local identifier = data.Identifier

		if not (player and identifier) then
			return
		end

		local inventory = DataController.Get(player, "Inventory")

		if inventory then
			for _, v7 in ipairs(inventory) do
				if v7._id ~= identifier then
					continue
				end

				v7.StatTrack = data.StatTrack
				break
			end
		end

		local v7

		if player == LocalPlayer then
			v7 = InventoryController.getCurrentInventory()
		else
			v7 = false
		end

		if not v7 then
			return
		end

		for _, v8 in pairs(v7) do
			for _, item in pairs(v8._items) do
				if item._id ~= identifier then
					continue
				end

				item:updateStatTrackCounter(data.StatTrack)
				return
			end
		end
	end)
	listenProfiled(Remotes.Inventory.RefillAmmo, "Inventory.Remote.RefillAmmo", function(data)
		local v7 = data and data.Identifier and v and v:getInventoryItemFromLoadout(data.Identifier)

		if not v7 then
			return
		end

		v7.CurrentReloadIdentity = nil
		v7.IsReloading = false
		v7.Rounds = data.Rounds
		v7.Capacity = data.Capacity
		v7.RechargeStartTime = nil
	end)
	listenProfiled(Remotes.Inventory.CleanupGameLoadout, "Inventory.Remote.CleanupGameLoadout", function(p)
		cancelFlash()
		cleanupCurrentLoadout(p.Generation)
	end)
	listenProfiled(Remotes.Inventory.CreateGameLoadout, "Inventory.Remote.CreateGameLoadout", function(p)
		if FlashEffect.IsFlashed() then
			debug.profilebegin("Inventory.CreateGameLoadout.CancelFlash")
			FlashEffect.CancelFlash()
			debug.profileend()
		end

		local generation = p.Generation
		local v7 = v3

		if v7 and (v2 == generation or generation == v7 or not isNewerGeneration(generation, v7)) then
			return
		end

		cleanupCurrentLoadout()
		debug.profilebegin("Inventory.CreateGameLoadout.Loadout.new")
		local v8 = Loadout.new(p.Inventory)
		v = v8
		debug.profileend()
		v2 = generation
		v3 = generation
		debug.profilebegin("Inventory.CreateGameLoadout.FireInventoryChanged")
		onInventoryChanged:Fire(v8.Inventory)
		debug.profileend()
		local v9 = v4[generation]
		v4[generation] = nil

		if v9 then
			for _, v10 in v9 do
				InventoryController.newInventoryItem(v10)
			end
		end
	end)
	LocalPlayer:GetAttributeChangedSignal("CurrentEquipped"):Connect(function()
		if flag then
			return
		end

		task.defer(ReconcileEquippedState)
	end)
end

function InventoryController.Start()
	Router.observerRouter("PredictGrenadeThrow", function(p: string, p2: string)
		return InventoryController.PredictGrenadeThrow(p, p2)
	end)
	Remotes.VFX.ReplicateFinisher.Listen(function(p)
		debug.profilebegin("VFX.Remote.ReplicateFinisher")

		if DataController.Get(LocalPlayer, "Settings.Video.Presets.Ragdolls") == false or not p then
			local v7 = p.Victim and Finishers.ResolveVictimCharacter(p)

			if v7 then
				Ragdoll.RetireCorpseLocally(v7)
			end

			debug.profileend()
		else
			debug.profileend()
			Finishers.ExecuteFinisher(p)
		end
	end)
	listenProfiled(Remotes.UI.UIPlayerKilled, "UI.Remote.UIPlayerKilled", function(p)
		if p and p.Weapon == "Zeus x27" then
			PlayZeusDeath(p.Victim)
		end
	end)
	Remotes.VFX.CleanupDebris.Listen(RecycleFX)
	listenProfiled(Remotes.VFX.CreateCharacterMuzzleFlash, "VFX.Remote.CreateCharacterMuzzleFlash", function(data)
		local v7 = DataController.Get(LocalPlayer, "Settings.Video.Presets.Muzzle Flash") ~= false

		if v7 or data.WeaponName == "Zeus x27" then
			Character(data.UserId, data.Generation, data.WeaponName, data.ShootingHand, data.Suppressor, not v7)
		end
	end)
	listenProfiled(Remotes.VFX.CreateImpact, "VFX.Remote.CreateImpact", function(data)
		local v7

		if data.AttackerUserId == nil then
			v7 = false
		else
			v7 = data.AttackerUserId == tostring(LocalPlayer.UserId)
		end

		local v8 = DataController.Get(LocalPlayer, "Settings.Game.Other.Emit Particles When Server Validated") == true

		if v7 then
			if v8 then
				if
					typeof(data.ShotSeq) == "number"
					and typeof(data.VictimUserId) == "number"
					and typeof(data.HitPartName) == "string"
				then
					v8 = PlayerHitPrediction.Consume(data.ShotSeq, data.VictimUserId, data.HitPartName, data.Position)
				else
					v8 = false
				end
			end
		else
			v8 = v7
		end

		if v8 then
			return
		end

		CreateImpact(
			data.Instance,
			data.Material,
			data.Position,
			data.Normal,
			data.Exit,
			data.Ricochet,
			v7,
			data.AttackerUserId,
			data.IsWallbang,
			data.WasHelmetHeadshot,
			data.SuppressVisuals,
			data.SuppressSound
		)
	end)
	listenProfiled(Remotes.VFX.CreateMarker, "VFX.Remote.CreateMarker", function(data)
		CreateMarker(data.Instance, data.Type, data.Position, data.Normal)
	end)
	listenProfiled(Remotes.VFX.CreateTracer, "VFX.Remote.CreateTracer", function(data)
		CreateTracer(data.Distance, data.Origin, data.Target)
	end)
	listenProfiled(Remotes.VFX.BreakGlass, "VFX.Remote.BreakGlass", function(data)
		BreakGlass(data.Instance, data.Position, data.Direction)
	end)
	listenProfiled(Remotes.VFX.CreateVoxelSmoke, "VFX.Remote.CreateVoxelSmoke", CreateVoxelSmoke.Create)
	listenProfiled(Remotes.VFX.DestroyVoxelSmoke, "VFX.Remote.DestroyVoxelSmoke", CreateVoxelSmoke.Destroy)
	listenProfiled(Remotes.VFX.DisruptVoxelSmoke, "VFX.Remote.DisruptVoxelSmoke", function(data)
		CreateVoxelSmoke.Disrupt(data.Position, data.Radius, data.Duration)
	end)
	listenProfiled(Remotes.VFX.CreateVoxelFire, "VFX.Remote.CreateVoxelFire", CreateVoxelFire.Create)
	listenProfiled(Remotes.VFX.DestroyVoxelFire, "VFX.Remote.DestroyVoxelFire", CreateVoxelFire.Destroy)
	listenProfiled(Remotes.VFX.UpdateVoxelFire, "VFX.Remote.UpdateVoxelFire", CreateVoxelFire.Update)
	local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
	listenProfiled(Remotes.VFX.FlashPlayer, "VFX.Remote.FlashPlayer", function(p)
		if FlashEffect.Flash(p) and not p.Duration then
			StartBlindedAnimation()
		end
	end)
	SpectateController.ListenToSpectate:Connect(cancelFlash)
	local GameState = require(ReplicatedStorage.Database.Components.GameState)
	GameState.ListenToState(function(_, p)
		if p == "Buy Period" then
			CreateVoxelSmoke.DestroyAll()
			CreateVoxelFire.DestroyAll()
		end
	end)
	DataController.CreateListener(LocalPlayer, "Inventory", function()
		debug.profilebegin("Inventory.DataListener.Inventory")
		UpdateStatTrack()
		debug.profileend()
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Video.Presets.Ragdolls", function(p)
		Ragdoll.SetEnabled(p ~= false)
	end)
end

return InventoryController