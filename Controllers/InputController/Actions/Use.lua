local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
require(script.Parent.Parent.Types)
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local CenterScreenRaycast = require(ReplicatedStorage.Components.Common.CenterScreenRaycast)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local NumberSlots = require(ReplicatedStorage.Database.Custom.GameStats.NumberSlots)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Grenades = require(ReplicatedStorage.Database.Custom.GameStats.Grenades)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)

local function CountTargetGrenades(list, p: string)
	local count = 0

	for _, v in ipairs(list) do
		if v.Name == p then
			count += 1
		end
	end

	return count
end

local function computePriority(instance, instance2)
	local localCharacter = CharacterResolver.getLocalCharacter()

	if not (localCharacter and localCharacter.PrimaryPart) then
		return false
	end

	if instance:GetAttribute("HoveringState") == "Hovering" then
		return true
	end

	if not (instance2:GetAttribute("HoveringState") ~= "Hovering" and instance:GetAttribute("CanPickup") ~= false) then
		return false
	end

	if instance2:GetAttribute("CanPickup") == false then
		return true
	end

	if instance.PrimaryPart and instance2.PrimaryPart then
		return (localCharacter.PrimaryPart.Position - instance.PrimaryPart.Position).Magnitude < (localCharacter.PrimaryPart.Position - instance2.PrimaryPart.Position).Magnitude
	end

	return false
end

local function GetHoveredBreakableDoor()
	local result = {}
	local model = CenterScreenRaycast.FindTaggedModelInSight("BreakableDoor", 8)

	if not model or not model:IsA("Model") or model:GetAttribute("Destroyed") == true then
		return result
	end

	table.insert(result, model)

	for _, v in CollectionService:GetTagged("BreakableDoor") do
		if not (v ~= model and v:GetAttribute("Destroyed") ~= true) then
			continue
		end

		local breakableDoorHingePivot = model:FindFirstChild("BreakableDoorHingePivot")
		local breakableDoorHingePivot2 = v:FindFirstChild("BreakableDoorHingePivot")

		if
			not breakableDoorHingePivot
			or not breakableDoorHingePivot2
			or (breakableDoorHingePivot.Position - breakableDoorHingePivot2.Position).Magnitude > 20
		then
			continue
		end

		table.insert(result, v)
	end

	return result
end

local function isGrenadeLimitHit(weapon: string)
	local weaponProperties = GetWeaponProperties(weapon)

	if not weaponProperties then
		return false
	end

	local numberSlot = NumberSlots[weaponProperties.Slot]
	local inventorySlot = InventoryController.getInventorySlot(numberSlot)

	if not inventorySlot then
		return false
	end

	local v = #inventorySlot._items >= inventorySlot._settings._strict_slot_space
	local items = inventorySlot._items
	local count = 0
	local v2 = true

	for _, item in ipairs(items) do
		if item.Name == weapon then
			count += 1
		end
	end

	if not (Grenades[weapon] <= count) then
		return v
	end

	return v2
end

local function onUseBegin()
	local v = CollectionService:GetTagged("Bomb")[1]

	if v and v:GetAttribute("CanDefuse") and not (v:GetAttribute("IsGettingDefused") or v:GetAttribute("Defused")) then
		Router.broadcastRouter("Start Defuse Bomb")
		return
	end

	local hoveredBreakableDoor = GetHoveredBreakableDoor()

	if #hoveredBreakableDoor > 0 then
		for _, model in hoveredBreakableDoor do
			if Workspace:GetAttribute("MovementV2DoorDebug") == true then
				print(string.format(
					"[MovementV2.Door] use-send source=Use model=%s clientTime=%.6f",
					model:GetFullName(),
					Workspace:GetServerTimeNow()
				))
			end

			local predictDoorUse = CharacterController.PredictDoorUse(model)
			local send = Remotes.BreakableDoor.Use.Send
			local serverTick

			if predictDoorUse ~= nil then
				serverTick = predictDoorUse.ServerTick
			end

			local targetAngle

			if predictDoorUse ~= nil then
				targetAngle = predictDoorUse.TargetAngle
			end

			local requestId

			if predictDoorUse ~= nil then
				requestId = predictDoorUse.RequestId
			end

			send({
				Model = model,
				ServerTick = serverTick,
				TargetAngle = targetAngle,
				RequestId = requestId
			})
		end
	else
		local tagged = CollectionService:GetTagged("IsHoveringInteractable")

		if #tagged == 0 then
			return
		end

		table.sort(tagged, computePriority)
		local v2 = tagged[1]
		local weapon = v2:GetAttribute("Weapon")
		local skin = v2:GetAttribute("Skin")

		if
			weapon == "C4" and LocalPlayer:GetAttribute("Team") ~= "Terrorists"
			or Grenades[weapon] ~= nil and isGrenadeLimitHit(weapon)
			or not v2:GetAttribute("CanPickup")
		then
			return
		end

		local skinInformation = Skins.GetSkinInformation(weapon, skin)

		if skinInformation then
			local rarity = Rarities[skinInformation.rarity]
			local v3 = math.floor(rarity.Color.R * 255)
			local v4 = math.floor(rarity.Color.G * 255)
			local v5 = math.floor(rarity.Color.B * 255)
			Router.broadcastRouter(
				"CreateNotification",
				"Item Picked Up",
				`You picked up a <font color = "rgb({v3}, {v4}, {v5})"><b>{weapon:find("Zeus") and "Taser" or weapon} | {skin}</b></font>`,
				2
			)
		end

		Remotes.Inventory.PickupWeapon.Send({ Identity = v2.Name, AllowAutoEquip = true })
	end
end

local function onInput(p, _)
	if LocalPlayer:GetAttribute("IsPlayerChatting") or not CharacterResolver.getLocalCharacter() then
		return
	end

	if p == Enum.UserInputState.Begin then
		onUseBegin()
	elseif p == Enum.UserInputState.End then
		if
			CollectionService:GetTagged("Bomb")[1]
			and (LocalPlayer:GetAttribute("IsDefusingBomb") or LocalPlayer:GetAttribute("IsLocallyDefusingBomb"))
		then
			Router.broadcastRouter("Cancel Defuse Bomb")
		elseif LocalPlayer:GetAttribute("IsRescuingHostage") then
			Router.broadcastRouter("Cancel Rescue Hostage")
		end
	end
end

return table.freeze({
	Category = "Weapon Keys",
	Callback = onInput,
	Group = "Gameplay",
	Name = "Use"
})