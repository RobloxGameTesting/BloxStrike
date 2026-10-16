local Weapon = {}
Weapon.__index = Weapon
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local CenterScreenRaycast = require(ReplicatedStorage.Components.Common.CenterScreenRaycast)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local NumberSlots = require(ReplicatedStorage.Database.Custom.GameStats.NumberSlots)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Grenades = require(ReplicatedStorage.Database.Custom.GameStats.Grenades)
local LocalPlayer = Players.LocalPlayer
local v = { ProximityRange = 6, HoverRange = 10 }
local v2 = {}
local v3 = 0
local v4 = nil
local connection = nil
local v5 = {}

local function UpdateHoveredInstance()
	v4 = CenterScreenRaycast.GetInstance(10)
end

local function StopSharedHeartbeatIfIdle() -- 2 equivalent calls inferred from this helper
	if v3 <= 0 and connection then
		connection:Disconnect()
		connection = nil
		v4 = nil
	end
end

local function EnsureSharedHeartbeat() -- 1 equivalent call inferred from this helper
	if connection then
		return
	end

	connection = RunServiceController.BindToHeartbeat("Observers.Game.WeaponDropped.Update", function(p: number)
		if v3 <= 0 then
			StopSharedHeartbeatIfIdle() -- inferred equivalent call
		else
			v4 = CenterScreenRaycast.GetInstance(v.HoverRange)

			for k in pairs(v2) do
				if k.Model.PrimaryPart then
					k:updateState(p)
				end
			end
		end
	end)
end

local function ReserveAutoPickupSlot(numberSlot: number) -- 1 equivalent call inferred from this helper
	local now = os.clock()
	local v6 = v5[numberSlot]

	if v6 and now - v6 < 1 then
		return false
	end

	v5[numberSlot] = now
	task.delay(1, function()
		if v5[numberSlot] == now then
			v5[numberSlot] = nil
		end
	end)
	return true
end

local function HasReachedDuplicateLimit(inventorySlot, weapon: string) -- 1 equivalent call inferred from this helper
	local grenade = Grenades[weapon]

	if not grenade then
		return false
	end

	local count = 0

	if inventorySlot then
		for _, item in ipairs(inventorySlot._items) do
			if item.Name == weapon then
				count += 1
			end
		end
	end

	return grenade <= count
end

function Weapon:autoPickup()
	local weapon = self.Model:GetAttribute("Weapon")

	if not weapon then
		return
	end

	local weaponProperties = GetWeaponProperties(weapon)

	if not weaponProperties then
		return
	end

	local numberSlot = NumberSlots[weaponProperties.Slot]

	if not numberSlot then
		return
	end

	local inventorySlot = InventoryController.getInventorySlot(numberSlot)

	if
		HasReachedDuplicateLimit(inventorySlot, weapon) -- inferred equivalent call
		or not (inventorySlot and #inventorySlot._items < inventorySlot._settings._strict_slot_space and self.Model:GetAttribute("CanPickup"))
	then
		return
	end

	if not self.SentPickupRequest and ReserveAutoPickupSlot(numberSlot) then -- inferred equivalent call
		self.SentPickupRequest = true
		task.delay(1, function()
			self.SentPickupRequest = false
		end)
		local skinInformation = Skins.GetSkinInformation(self.Weapon, self.Skin)
		assert(skinInformation, "Skin data not found for weapon: " .. self.Weapon .. " and skin: " .. self.Skin)
		local rarity = Rarities[skinInformation.rarity]
		local v6 = math.floor(rarity.Color.R * 255)
		local v7 = math.floor(rarity.Color.G * 255)
		local v8 = math.floor(rarity.Color.B * 255)

		if self.Weapon == "C4" and LocalPlayer:GetAttribute("Team") ~= "Terrorists" then
			return
		end

		Router.broadcastRouter(
			"CreateNotification",
			"Item Picked Up",
			`You picked up a <font color = "rgb({v6}, {v7}, {v8})"><b>{self.Weapon:find("Zeus") and "Taser" or self.Weapon} | {self.Skin}</b></font>`,
			2
		)
		Remotes.Inventory.PickupWeapon.Send({ Identity = self.Model.Name, AllowAutoEquip = false })
	end
end

function Weapon:updateState(p: number)
	self.AlphaTime += p
	local v6 = v4 ~= nil and v4:IsDescendantOf(self.Model) and "Hovering"
	local localCharacter = CharacterResolver.getLocalCharacter()
	local primaryPart = localCharacter and localCharacter.PrimaryPart
	local v7 = primaryPart
		and (primaryPart.Position - self.Model.PrimaryPart.Position).Magnitude <= 6
		and (v6 or "Proximity")
		or v6

	if self.Weapon == "C4" then
		local team = LocalPlayer:GetAttribute("Team")

		if self.AlphaTime >= 1 then
			local flashingLight = self.Model.Weapon:FindFirstChild("FlashingLight")
			self.AlphaTime = 0

			if flashingLight then
				flashingLight.Attachment.PointLight.Enabled = not flashingLight.Attachment.PointLight.Enabled
				flashingLight.Attachment.PointLight.Color = Color3.fromRGB(255, 255, 15)
				flashingLight.Attachment.PointLight.Brightness = 5
			end
		end

		if team ~= "Terrorists" then
			v7 = false
		end
	end

	local lastHoveringState = (v7 == "Hovering" or v7 == "Proximity") and v7 or nil

	if self.LastHoveringState ~= lastHoveringState then
		self.LastHoveringState = lastHoveringState
		self.Model:SetAttribute("HoveringState", lastHoveringState)
	end

	local isInteractableTagged = lastHoveringState ~= nil

	if self.IsInteractableTagged ~= isInteractableTagged then
		self.IsInteractableTagged = isInteractableTagged

		if isInteractableTagged then
			self.Model:AddTag("IsHoveringInteractable")
		else
			self.Model:RemoveTag("IsHoveringInteractable")
		end
	end

	if lastHoveringState == "Proximity" then
		local v8 = DataController.Get(LocalPlayer, "Settings.Game.Item.Auto Pickup Dropped Weapons")
		local weaponProperties = GetWeaponProperties(self.Weapon)
		local slot = weaponProperties and weaponProperties.Slot
		local v9 = slot == "Grenade" or slot == "C4"

		if v8 ~= false or v9 then
			self:autoPickup()
		end
	end
end

function Weapon.new(model)
	local self = setmetatable({}, Weapon)
	self.Model = model
	self.AlphaTime = 0
	self.Weapon = self.Model:GetAttribute("Weapon")
	self.Skin = self.Model:GetAttribute("Skin")
	self.SentPickupRequest = false
	self.IsInteractableTagged = false
	v2[self] = true
	v3 += 1
	EnsureSharedHeartbeat() -- inferred equivalent call
	return self
end

function Weapon:destroy()
	if v2[self] then
		v2[self] = nil
		v3 -= 1
		StopSharedHeartbeatIfIdle() -- inferred equivalent call
	end

	if self.IsInteractableTagged then
		self.Model:RemoveTag("IsHoveringInteractable")
		self.IsInteractableTagged = false
	end

	if self.LastHoveringState ~= nil then
		self.Model:SetAttribute("HoveringState", nil)
		self.LastHoveringState = nil
	end
end

return Weapon