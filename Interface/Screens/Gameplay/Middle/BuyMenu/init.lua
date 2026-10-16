local BuyMenu = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local RemoveFromArray = require(ReplicatedStorage.Database.Components.Common.RemoveFromArray)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local IsInBuyArea = require(ReplicatedStorage.Database.Components.Common.IsInBuyArea)
local GetTimerFormat = require(ReplicatedStorage.Components.Common.GetTimerFormat)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local TutorialPurchaseLock = require(ReplicatedStorage.Components.Common.TutorialPurchaseLock)
local GetCharacterVelocity = require(ReplicatedStorage.Components.Common.GetCharacterVelocity)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Spring = require(ReplicatedStorage.Shared.Spring)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Grenades = require(ReplicatedStorage.Database.Custom.GameStats.Grenades)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local BuyMenuInfo = require(script:WaitForChild("BuyMenuInfo"))
local NumberSlots = require(ReplicatedStorage.Database.Custom.GameStats.NumberSlots)
local color = Color3.fromRGB(149, 149, 149)
local v = { "CompetitivePlayerColor", "Armor", "HasDefuseKit", "HasRescueKit" }
local maid = Janitor.new()
local maid2 = Janitor.new()
local v2 = Spring.new(1, 8, 0)
local identifiers = {}
local flag = false
local v3 = nil
local v4 = nil
local v5 = { ["1"] = "Kevlar", ["2"] = "Kevlar + Helmet" }
local v6 = {
	Kevlar = true,
	["Kevlar + Helmet"] = true,
	["Defuse Kit"] = true,
	["Rescue Kit"] = true
}
local v7 = {
	Terrorists = { "Glock-18" },
	["Counter-Terrorists"] = { "USP-S", "P2000" }
}
local v8 = {
	{ Name = "Yellow", Color = Color3.fromRGB(255, 221, 51) },
	{ Name = "Green", Color = Color3.fromRGB(0, 153, 0) },
	{ Name = "Blue", Color = Color3.fromRGB(0, 102, 204) },
	{ Name = "Purple", Color = Color3.fromRGB(153, 51, 204) },
	{ Name = "Orange", Color = Color3.fromRGB(255, 128, 0) }
}
local v9 = Janitor.new()
local v10 = {}
local v11 = {}
local v12 = nil
local v13 = {}
local v14 = {}
local connection = nil
local color2 = Color3.fromRGB(255, 255, 255)
local v15 = { 1, 2, 3, 4 }
local color3 = Color3.fromRGB(255, 70, 70)
local color4 = Color3.fromRGB(235, 40, 40)

local function CommaNumber(p: number) -- 4 equivalent calls inferred from this helper
	return tostring(p):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function GetInventoryItemFromIdentifier(list, p: string)
	for _, v16 in ipairs(list) do
		if v16._id == p then
			return v16
		end
	end

	return nil
end

local function ResolveTemplateInventoryItem(instance)
	local inventoryItemId = instance:GetAttribute("InventoryItemId")

	if
		not inventoryItemId
		or inventoryItemId == ""
		or inventoryItemId == "__buymenu_zeus_placeholder__"
		or string.sub(inventoryItemId, 1, 10) == "equipment:"
	then
		return nil
	end

	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not inventory or typeof(inventory) ~= "table" then
		return nil
	end

	for _, v16 in ipairs(inventory) do
		if v16._id == inventoryItemId then
			return v16
		end
	end

	return nil
end

local function ResolveTemplateSkinName(p)
	local templateInventoryItem = ResolveTemplateInventoryItem(p)
	local skin = templateInventoryItem and templateInventoryItem.Skin

	if typeof(skin) == "string" and skin ~= "" then
		return skin
	end

	return nil
end

local function ShowWeaponInfoFrame(instance)
	local weapon = instance:GetAttribute("Weapon")

	if not weapon or weapon == "" then
		return
	end

	local weaponInfoFrame = v3.WeaponInfoFrame
	local templateInventoryItem = ResolveTemplateInventoryItem(instance)
	local skin = templateInventoryItem and templateInventoryItem.Skin

	if typeof(skin) ~= "string" or skin == "" then
		skin = nil
	end

	local rarity = nil

	if skin and skin ~= "Stock" then
		local skinInformation = Skins.GetSkinInformation(weapon, skin)

		if skinInformation and skinInformation.rarity then
			rarity = skinInformation.rarity
		end
	end

	local templateInventoryItem2 = ResolveTemplateInventoryItem(instance)
	local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(
		weapon,
		templateInventoryItem2 and templateInventoryItem2.NameTag
	)

	if skin and skin ~= "Stock" and rarity then
		local rarity2 = Rarities[rarity]
		GetSkinDisplayName.ApplyNameLabel(
			weaponInfoFrame.WeaponName,
			`{weaponDisplayName} | {GetSkinDisplayName(skin)}`,
			templateInventoryItem2 and templateInventoryItem2.NameTag
		)
		weaponInfoFrame.WeaponName.TextColor3 = rarity2 and rarity2.Color or color2
	else
		GetSkinDisplayName.ApplyNameLabel(
			weaponInfoFrame.WeaponName,
			weaponDisplayName,
			templateInventoryItem2 and templateInventoryItem2.NameTag
		)
		weaponInfoFrame.WeaponName.TextColor3 = color2
	end

	local weapon2 = BuyMenuInfo.Weapons[weapon]
	local stats = weaponInfoFrame.Stats
	local v16 = not weapon2 and 0 or weapon2.Stars or 0
	stats.Info.Text = not weapon2 and "" or weapon2.Info or ""
	stats.Tip.Text = weapon2 and weapon2.Tip or ""
	local imageColor = v16 >= 1 and BuyMenuInfo.GetStarColor(v16) or color2

	for _, v17 in ipairs(v15) do
		local child = stats.Difficulty:FindFirstChild((tostring(v17)))

		if not child then
			continue
		end

		local visible = v17 <= v16
		child.Visible = visible

		if visible then
			child.ImageColor3 = imageColor
		end
	end

	weaponInfoFrame.Visible = true
end

local function HideWeaponInfoFrame() -- 3 equivalent calls inferred from this helper
	if v3 and v3.WeaponInfoFrame then
		v3.WeaponInfoFrame.Visible = false
	end
end

local function IsObjectiveEquipmentAvailableForPlayer(p: string, team: string?, gamemode) -- 1 equivalent call inferred from this helper
	if team ~= "Counter-Terrorists" then
		return false
	end

	if p == "Defuse Kit" then
		return gamemode == "Bomb Defusal"
	end

	return p ~= "Rescue Kit" or gamemode == "Hostage Rescue"
end

local function IsCompetitiveServerGamemode() -- 2 equivalent calls inferred from this helper
	return workspace:GetAttribute("ServerGamemode") == "Competitive"
end

local function IsEquipmentAvailableForLocalPlayer(p: string)
	if v6[p] and workspace:GetAttribute("ServerGamemode") ~= "Competitive" then
		return false
	end

	if p ~= "Defuse Kit" and p ~= "Rescue Kit" then
		return true
	end

	return IsObjectiveEquipmentAvailableForPlayer( -- inferred equivalent call
		p,
		LocalPlayer:GetAttribute("Team"),
		workspace:GetAttribute("Gamemode")
	)
end

local function GetEquipmentByTemplate(name: string) -- 1 equivalent call inferred from this helper
	local v16 = v5[name]

	if v16 then
		if IsEquipmentAvailableForLocalPlayer(v16) then
			return v16
		end

		return nil
	else
		if name ~= "3" then
			return nil
		end

		local v17

		if v6["Defuse Kit"] and workspace:GetAttribute("ServerGamemode") ~= "Competitive" then
			v17 = false
		else
			local team = LocalPlayer:GetAttribute("Team")
			local gamemode = workspace:GetAttribute("Gamemode")

			if team == "Counter-Terrorists" then
				v17 = gamemode == "Bomb Defusal"
			else
				v17 = false
			end
		end

		if v17 then
			return "Defuse Kit"
		end

		local v18

		if v6["Rescue Kit"] and workspace:GetAttribute("ServerGamemode") ~= "Competitive" then
			v18 = false
		else
			local team = LocalPlayer:GetAttribute("Team")
			local gamemode = workspace:GetAttribute("Gamemode")

			if team == "Counter-Terrorists" then
				v18 = gamemode == "Hostage Rescue"
			else
				v18 = false
			end
		end

		if v18 then
			return "Rescue Kit"
		end

		return nil
	end
end

local function GetPlayerArmorState(instance)
	local armor = instance:GetAttribute("Armor")

	if typeof(armor) == "string" and armor ~= "" then
		local success, result = pcall(function()
			return HttpService:JSONDecode(armor)
		end)

		if success and typeof(result) == "table" then
			return {
				Type = tostring(result.Type or ""),
				Health = tonumber(result.Health) or 0
			}
		end
	end

	return { Type = "", Health = 0 }
end

local function GetDisplayCost(p: string, p2)
	local gamemode = workspace:GetAttribute("Gamemode")

	if
		gamemode == "Deathmatch"
		or gamemode == "Tutorial"
		or GameState.GetState() == "Warmup"
		or workspace:GetAttribute("VIPInfiniteCashEnabled") == true
	then
		return 0
	end

	local cost = p2.Cost

	if p == "Molotov" and LocalPlayer:GetAttribute("Team") == "Counter-Terrorists" then
		return 500
	end

	if p == "Kevlar + Helmet" then
		local playerArmorState = GetPlayerArmorState(LocalPlayer)
		cost = playerArmorState.Type == "Kevlar" and playerArmorState.Health >= 100 and 350 or cost
	end

	return cost
end

local function IsEquipmentOwnedBy(instance, p: string)
	if p == "Defuse Kit" then
		return instance:GetAttribute("HasDefuseKit") == true
	elseif p == "Rescue Kit" then
		return instance:GetAttribute("HasRescueKit") == true
	end

	local playerArmorState = GetPlayerArmorState(instance)
	return (p == "Kevlar" or p == "Kevlar + Helmet") and playerArmorState.Health > 0 and playerArmorState.Type == p
end

local function IsEquipmentOwned(p: string) -- 4 equivalent calls inferred from this helper
	return (IsEquipmentOwnedBy(LocalPlayer, p))
end

local function IsEquipmentPurchaseBlockedForLocalPlayer(p: string)
	if not IsEquipmentAvailableForLocalPlayer(p) then
		return true
	end

	if p == "Defuse Kit" or p == "Rescue Kit" then
		return IsEquipmentOwned(p) -- inferred equivalent call
	end

	local playerArmorState = GetPlayerArmorState(LocalPlayer)
	local v16

	if playerArmorState.Type == "Kevlar + Helmet" then
		v16 = playerArmorState.Health > 0
	else
		v16 = false
	end

	local v17 = v16 and playerArmorState.Health >= 100

	if p == "Kevlar" then
		return playerArmorState.Type == "Kevlar" and playerArmorState.Health >= 100 or v17
	else
		return p == "Kevlar + Helmet" and v16
	end
end

local function IsStarterPistolForLocalPlayer(p: string) -- 1 equivalent call inferred from this helper
	local v16 = v7[LocalPlayer:GetAttribute("Team")]

	if v16 then
		return table.find(v16, p) ~= nil
	end

	return false
end

local function HideTemplate(instance) -- 2 equivalent calls inferred from this helper
	instance:SetAttribute("IsEquipment", nil)
	instance:SetAttribute("Weapon", nil)
	instance.Visible = false
end

local fn

local function setupBuyMenuTemplates()
	Profiler.mark("UI.BuyMenu.SetupBuyMenuTemplates")
	fn()

	for _, button in ipairs(v3.Menu.Container:GetDescendants()) do
		if not button:IsA("TextButton") then
			continue
		end

		if button.Parent.Name == "Equipment" then
			if button.Name == "4" then
				local v16 = Router.broadcastRouter(
					"GetEquippedInventoryItem",
					LocalPlayer,
					"Equipped.Equipped Zeus x27"
				)
				local v17 = not (v16 and v16.Name) and {
						Name = "Zeus x27",
						_id = "__buymenu_zeus_placeholder__"
					}
					or v16
				BuyMenu.createTemplate(button, v17, false, "Equipped.Equipped Zeus x27")
			else
				local name = GetEquipmentByTemplate(button.Name) -- inferred equivalent call

				if name then
					BuyMenu.createTemplate(button, { Name = name, _id = `equipment:{name}` }, true, nil)
				else
					HideTemplate(button) -- inferred equivalent call
				end
			end
		else
			BuyMenu.setupTemplate(button, `Loadout.{button.Parent.Name}.Options.{tonumber(button.Name)}`)
		end
	end
end

local function GetInventoryItemProperties(childName: string) -- 4 equivalent calls inferred from this helper
	local v16 = ReplicatedStorage.Database.Custom.Weapons:FindFirstChild(childName)
		or ReplicatedStorage.Database.Custom.GameStats.Equipment:FindFirstChild(childName)

	if v16 then
		return require(v16)
	end

	return nil
end

local function QueryInventoryItem(list, p: string)
	for _, v16 in ipairs(list) do
		for _, item in ipairs(v16._items) do
			if item.Name == p then
				return item
			end
		end
	end

	return false
end

local function QueryRoundPurchasedInventoryItem(list, p: string)
	for _, v16 in ipairs(list) do
		for _, item in ipairs(v16._items) do
			if item.Name == p and table.find(identifiers, item.Identifier) then
				return item
			end
		end
	end

	return false
end

local function QueryInventoryItemPurchasedThisRound(currentInventory, name: string) -- 1 equivalent call inferred from this helper
	return QueryRoundPurchasedInventoryItem(currentInventory, name) or QueryInventoryItem(currentInventory, name)
end

local function IsUnrefundableStarterPistol(p: string, p2) -- 3 equivalent calls inferred from this helper
	return not not IsStarterPistolForLocalPlayer(p) and (not p2 or not QueryRoundPurchasedInventoryItem(p2, p)) -- inferred equivalent call
end

local function GetInventoryItemCount(list, p: string)
	local count = 0

	for _, v16 in ipairs(list) do
		for _, item in ipairs(v16._items) do
			if item.Name == p then
				count += 1
			end
		end
	end

	return count
end

local function IsTutorialItemAllowed(p: string) -- 2 equivalent calls inferred from this helper
	return TutorialPurchaseLock.isPurchaseAllowed(LocalPlayer, p)
end

local v16 = {}

local function IsTutorialPulseWanted(p: string, p2)
	local requiredItems = TutorialPurchaseLock.getRequiredItems(LocalPlayer)

	if requiredItems and table.find(requiredItems, p) then
		return not (p2 and GetInventoryItemCount(p2, p) > 0)
	end

	return false
end

local function StopTutorialPulse(p, color5: Color3?)
	local v17 = v16[p]

	if not v17 then
		return
	end

	v16[p] = nil
	local background = p.Parent and p.Parent:FindFirstChild("Background")
	local tutorialRequiredOutline = background and background:FindFirstChild("TutorialRequiredOutline")

	if tutorialRequiredOutline then
		tutorialRequiredOutline:Destroy()
	end

	v17.Color:Cancel()
	v17.Swell:Cancel()
	v17.Scale.Scale = 1
	p.ImageColor3 = color5 or v17.RestingColor
end

fn = function()
	for k in v16 do
		StopTutorialPulse(k)
	end
end

local function SyncTutorialPulse(p, color5: Color3?, flag2: boolean)
	local icon = p.Icon
	local v17 = v16[icon]

	if not flag2 then
		StopTutorialPulse(icon, color5)
		return
	end

	if v17 then
		if not color5 or color5 == v17.RestingColor then
			return
		end

		StopTutorialPulse(icon, color5)
	end

	local scale = icon:FindFirstChild("TutorialPulse")

	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = "TutorialPulse"
		scale.Parent = icon
	end

	scale.Scale = 1
	local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local v18 = {
		Color = TweenService:Create(icon, tweenInfo, { ImageColor3 = color3 }),
		Swell = TweenService:Create(scale, tweenInfo, { Scale = 1.1 }),
		Scale = scale,
		RestingColor = color5 or icon.ImageColor3
	}
	v16[icon] = v18
	v18.Color:Play()
	v18.Swell:Play()
	local background = p.Background

	if background and not background:FindFirstChild("TutorialRequiredOutline") then
		local uiStroke = Instance.new("UIStroke")
		uiStroke.Name = "TutorialRequiredOutline"
		uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		uiStroke.Color = color4
		uiStroke.Thickness = 2
		uiStroke.Parent = background
	end
end

local function IsTutorialPurchasePending() -- 2 equivalent calls inferred from this helper
	local currentInventory = InventoryController.getCurrentInventory()
	return TutorialPurchaseLock.isWaitingOnPurchase(LocalPlayer, function(p: string)
		if currentInventory then
			return GetInventoryItemCount(currentInventory, p) > 0
		end

		return false
	end)
end

local function ResetTemplateTeammateIndicators(instance) -- 2 equivalent calls inferred from this helper
	local teammates = instance.Teammates
	teammates.Visible = false

	for _, v17 in ipairs(v8) do
		local teammate = teammates[v17.Name]

		if teammate then
			teammate.Visible = false
		end
	end
end

local function GetCompetitiveTeammateIndicator(instance, instance2)
	local competitivePlayerColor = instance2:GetAttribute("CompetitivePlayerColor")

	if not competitivePlayerColor then
		return nil
	end

	local teammates = instance.Teammates

	for _, v17 in ipairs(v8) do
		if competitivePlayerColor == v17.Color then
			return teammates[v17.Name]
		end
	end

	return nil
end

local function ClearCompetitiveTeammateInventoryCache() -- 2 equivalent calls inferred from this helper
	table.clear(v13)
	table.clear(v14)
end

local function RequestCompetitiveTeammateInventory(instance)
	if instance == LocalPlayer or not instance:IsDescendantOf(Players) or v14[instance] then
		return
	end

	local team = LocalPlayer:GetAttribute("Team")

	if not IsCompetitiveServerGamemode() or instance:GetAttribute("Team") ~= team then -- inferred equivalent call
		return
	end

	v14[instance] = true
	Remotes.Inventory.RequestSpectatedPlayerInventory.Send(instance)
	task.delay(0.15, function()
		v14[instance] = nil
	end)
end

local function RequestCompetitiveTeammateInventories()
	if workspace:GetAttribute("ServerGamemode") ~= "Competitive" then
		return
	end

	local team = LocalPlayer:GetAttribute("Team")

	if not team or team ~= "Counter-Terrorists" and team ~= "Terrorists" then
		return
	end

	for _, v17 in ipairs(Players:GetPlayers()) do
		if v17 ~= LocalPlayer and v17:GetAttribute("Team") == team then
			RequestCompetitiveTeammateInventory(v17)
		end
	end
end

local function PlayerHasTemplateItem(p, weapon: string, isEquipment: boolean)
	if isEquipment then
		return (IsEquipmentOwnedBy(p, weapon))
	end

	local v17

	if p == LocalPlayer then
		v17 = InventoryController.getCurrentInventory()
	else
		v17 = v13[p]
	end

	if not v17 then
		return false
	end

	for _, v18 in ipairs(v17) do
		for _, item in ipairs(v18._items) do
			if item.Name == weapon then
				return true
			end
		end
	end

	return false
end

local function UpdateTemplateTeammateIndicators(instance)
	ResetTemplateTeammateIndicators(instance) -- inferred equivalent call

	if not (instance.Visible and IsCompetitiveServerGamemode()) then -- inferred equivalent call
		return
	end

	local team = LocalPlayer:GetAttribute("Team")

	if not team or team ~= "Counter-Terrorists" and team ~= "Terrorists" then
		return
	end

	local weapon = instance:GetAttribute("Weapon")

	if not weapon then
		return
	end

	local isEquipment = instance:GetAttribute("IsEquipment") == true
	local visible = false

	for _, v17 in ipairs(Players:GetPlayers()) do
		if v17:GetAttribute("Team") ~= team then
			continue
		end

		if v17 ~= LocalPlayer and not (isEquipment or v13[v17]) then
			RequestCompetitiveTeammateInventory(v17)
		end

		if not PlayerHasTemplateItem(v17, weapon, isEquipment) then
			continue
		end

		local competitiveTeammateIndicator = GetCompetitiveTeammateIndicator(instance, v17)

		if not competitiveTeammateIndicator then
			continue
		end

		competitiveTeammateIndicator.Visible = true
		visible = true
	end

	instance.Teammates.Visible = visible
end

local function UpdateAllTeammateIndicators()
	Profiler.mark("UI.BuyMenu.UpdateAllTeammateIndicators")

	if not v3 then
		return
	end

	for _, button in ipairs(v3.Menu.Container:GetDescendants()) do
		if button:IsA("TextButton") then
			UpdateTemplateTeammateIndicators(button)
		end
	end
end

local function CanCarryDuplicate(p, p2: string) -- 2 equivalent calls inferred from this helper
	local inventoryItemCount = GetInventoryItemCount(p, p2)
	local grenade = Grenades[p2]

	if grenade then
		return inventoryItemCount < grenade
	end

	return inventoryItemCount == 0
end

local function WaitForAttribute(localPlayer, attributeName: string)
	local attribute = localPlayer:GetAttribute(attributeName)

	while not attribute do
		attribute = localPlayer:GetAttribute(attributeName)
		task.wait()
	end

	return attribute
end

local function UpdateBuyMenuTimerText()
	local state = GameState.GetState()
	local buyTimerRemaining

	if state == "Buy Period" or state == "Round In Progress" then
		buyTimerRemaining = workspace:GetAttribute("BuyTimerRemaining")
	end

	if typeof(buyTimerRemaining) ~= "number" then
		buyTimerRemaining = workspace:GetAttribute("Timer")
	end

	local v17 = typeof(buyTimerRemaining) ~= "number" and 0 or math.max(0, (math.floor(buyTimerRemaining)))
	v3.Menu.TopFrame.Timer.Text = GetTimerFormat(v17)
end

local function ApplyTemplateColor(instance, color5: Color3) -- 2 equivalent calls inferred from this helper
	instance.ItemName.TextColor3 = color5
	instance.Keybind.TextColor3 = color5
	instance.Icon.ImageColor3 = color5
	instance.Cost.TextColor3 = color5
end

local function TweenTemplateIcon(instance, p: number)
	TweenService:Create(instance.Icon, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(p, p)
	}):Play()
end

local function IsTemplateItemOwned(name: string, flag2: boolean) -- 2 equivalent calls inferred from this helper
	local currentInventory = InventoryController.getCurrentInventory()
	return flag2 and IsEquipmentOwned(name) or currentInventory and QueryInventoryItem(currentInventory, name) -- inferred equivalent call
end

function BuyMenu.purchase(childName: string, value: string?, flag2: boolean)
	local inventoryItemProperties = GetInventoryItemProperties(childName) -- inferred equivalent call

	if not inventoryItemProperties then
		return
	end

	local money = LocalPlayer:GetAttribute("Money")
	local displayCost = GetDisplayCost(childName, inventoryItemProperties)
	local gamemode = workspace:GetAttribute("Gamemode")

	if
		flag2 and IsEquipmentPurchaseBlockedForLocalPlayer(childName)
		or not IsTutorialItemAllowed(childName) -- inferred equivalent call
		or not IsInBuyArea(LocalPlayer)
	then
		return
	end

	local v17 = (gamemode == "Deathmatch" or gamemode == "Tutorial" or GameState.GetState() == "Warmup") and 0
		or displayCost
	local v18 = not flag2 and Grenades[childName] ~= nil and InventoryController.getCurrentInventory()

	if v18 then
		local v19 = v18[NumberSlots.Grenade]

		if v19 and #v19._items >= v19._settings._strict_slot_space then
			return
		end
	end

	if
		not flag2
		and LocalPlayer:GetAttribute("BuyMenu")
		and (gamemode == "Hostage Rescue" or gamemode == "Bomb Defusal")
	then
		local currentInventory = InventoryController.getCurrentInventory()
		local numberSlot = NumberSlots[inventoryItemProperties.Slot]
		local v19 = currentInventory and currentInventory[numberSlot]
		local v20 = v19 and v19._items[1]

		if v20 and table.find(identifiers, v20.Identifier) then
			local inventoryItemProperties2 = GetInventoryItemProperties(v20.Name) -- inferred equivalent call

			if inventoryItemProperties2 then
				local cost = inventoryItemProperties2.Cost
				v17 = displayCost - (v20.Name == "Molotov" and LocalPlayer:GetAttribute("Team") == "Counter-Terrorists" and 500 or cost)
			end
		end
	end

	if money and v17 <= money then
		Router.broadcastRouter("RunInterfaceSound", "Successful Buy Menu Purchase")
		Remotes.Inventory.BuyMenuPurchase.Send({
			Equipment = flag2,
			Name = childName,
			Path = value or ""
		})
	end
end

function BuyMenu:createTemplate(data, isEquipment: boolean, p: string?)
	local inventoryItemProperties = GetInventoryItemProperties(data.Name) -- inferred equivalent call

	if not inventoryItemProperties then
		self.Visible = false
		return
	end

	local gamemode = workspace:GetAttribute("Gamemode")
	local displayCost = GetDisplayCost(data.Name, inventoryItemProperties)
	local reverseIcon = inventoryItemProperties.ReverseIcon or inventoryItemProperties.Icon
	self.Icon.Image = reverseIcon
	self.Cost.Text = "$" .. CommaNumber(displayCost) -- inferred equivalent call
	self.Keybind.Text = tostring((tonumber(self.Name)))
	local cost = self.Cost
	cost.Visible = gamemode ~= "Deathmatch" and gamemode ~= "Tutorial"
	self.LayoutOrder = tonumber(self.Name)
	GetSkinDisplayName.ApplyNameLabel(
		self.ItemName,
		GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag),
		data.NameTag
	)
	ResetTemplateTeammateIndicators(self) -- inferred equivalent call
	self.Visible = true
	local money = tonumber(LocalPlayer:GetAttribute("Money")) or 0
	local v17 = isEquipment and IsEquipmentPurchaseBlockedForLocalPlayer(data.Name)
	ApplyTemplateColor(self, (money < displayCost or v17) and color or GetPreferenceColor()) -- inferred equivalent call
	self:SetAttribute("Weapon", data.Name)
	self:SetAttribute("IsEquipment", isEquipment)
	self:SetAttribute("InventoryItemId", data._id)
	local currentInventory = InventoryController.getCurrentInventory()
	local visible = false
	local v18 = false

	if isEquipment then
		visible = IsEquipmentOwned(data.Name) -- inferred equivalent call
	elseif currentInventory then
		visible = GetInventoryItemCount(currentInventory, data.Name) > 0
		v18 = CanCarryDuplicate(currentInventory, data.Name) -- inferred equivalent call
	end

	local v19 = self.Return
	local visible2

	if visible then
		if GameState.GetState() == "Warmup" or gamemode == "Deathmatch" or gamemode == "Tutorial" then
			visible2 = false
		elseif isEquipment then
			visible2 = isEquipment
		else
			visible2 = not IsUnrefundableStarterPistol(data.Name, currentInventory) -- inferred equivalent call
		end
	else
		visible2 = visible
	end

	v19.Visible = visible2
	self.Hover.Visible = visible
	self.Hover.UIStroke.Transparency = visible and not v18 and 0 or 1
	maid:Add(self.MouseEnter:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Highlight")

		if not IsTemplateItemOwned(data.Name, isEquipment) then -- inferred equivalent call
			self.Hover.UIStroke.Transparency = 1
			self.Hover.Visible = true
			TweenService:Create(
				self.Hover.UIStroke,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Transparency = 0.8 }
			):Play()
		end

		TweenTemplateIcon(self, 0.7)
		ShowWeaponInfoFrame(self)
	end))
	maid:Add(self.MouseLeave:Connect(function()
		if not IsTemplateItemOwned(data.Name, isEquipment) then -- inferred equivalent call
			self.Hover.UIStroke.Transparency = 1
			self.Hover.Visible = false
		end

		TweenTemplateIcon(self, 0.75)
		HideWeaponInfoFrame() -- inferred equivalent call
	end))
	maid:Add(self.MouseButton1Down:Connect(function()
		TweenTemplateIcon(self, 0.65)
	end))
	maid:Add(self.MouseButton1Up:Connect(function()
		TweenTemplateIcon(self, 0.7)
	end))
	maid:Add(self.MouseButton1Click:Connect(function()
		BuyMenu.purchase(data.Name, p, isEquipment)
	end))
	maid:Add(self.Return.MouseButton1Click:Connect(function()
		if isEquipment then
			if IsInBuyArea(LocalPlayer) then
				Remotes.Inventory.ReturnBuyMenuPurchase.Send({
					Identifier = data.Name,
					Equipment = true
				})
			end
		else
			local currentInventory2 = InventoryController.getCurrentInventory()

			if not currentInventory2 or IsUnrefundableStarterPistol(data.Name, currentInventory2) then -- inferred equivalent call
				return
			end

			local queryInventoryItemPurchasedThisRound = QueryInventoryItemPurchasedThisRound( -- inferred equivalent call
				currentInventory2,
				data.Name
			)

			if queryInventoryItemPurchasedThisRound and IsInBuyArea(LocalPlayer) then
				Remotes.Inventory.ReturnBuyMenuPurchase.Send({
					Identifier = queryInventoryItemPurchasedThisRound.Identifier,
					Equipment = false
				})
			end
		end
	end))
end

function BuyMenu.setupTemplate(instance, p: string)
	local v17 = Router.broadcastRouter("GetEquippedInventoryItem", LocalPlayer, p)

	if v17 and v17.Name then
		BuyMenu.createTemplate(instance, v17, false, p)
		return
	end

	HideTemplate(instance) -- inferred equivalent call
end

function BuyMenu.updateBuyMenuTemplate(p, instance)
	local isEquipment = instance:GetAttribute("IsEquipment")
	local weapon = instance:GetAttribute("Weapon")

	if weapon then
		local inventoryItemProperties = GetInventoryItemProperties(weapon) -- inferred equivalent call
		local v17 = nil

		if inventoryItemProperties then
			local displayCost = GetDisplayCost(weapon, inventoryItemProperties)
			instance.Cost.Text = "$" .. CommaNumber(displayCost) -- inferred equivalent call
			local money = LocalPlayer:GetAttribute("Money")
			local v18 = isEquipment and IsEquipmentPurchaseBlockedForLocalPlayer(weapon)
			local v19 = not IsTutorialItemAllowed(weapon) -- inferred equivalent call

			if money then
				v17 = (money < displayCost or v18 or v19) and color or GetPreferenceColor()
				ApplyTemplateColor(instance, v17) -- inferred equivalent call
			end
		end

		local requiredItems = TutorialPurchaseLock.getRequiredItems(LocalPlayer)
		local v18

		if requiredItems and table.find(requiredItems, weapon) then
			v18 = not (p and GetInventoryItemCount(p, weapon) > 0)
		else
			v18 = false
		end

		SyncTutorialPulse(instance, v17, v18)

		if instance.Visible then
			local visible = false
			local v19 = false

			if isEquipment then
				visible = IsEquipmentOwned(weapon) -- inferred equivalent call
			elseif p then
				visible = GetInventoryItemCount(p, weapon) > 0
				v19 = CanCarryDuplicate(p, weapon) -- inferred equivalent call
			end

			local gamemode = workspace:GetAttribute("Gamemode")
			local v20 = instance.Return

			if visible then
				if gamemode == "Deathmatch" or gamemode == "Tutorial" or GameState.GetState() == "Warmup" then
					isEquipment = false
				elseif not isEquipment then
					isEquipment = not IsUnrefundableStarterPistol(weapon, p) -- inferred equivalent call
				end
			else
				isEquipment = visible
			end

			v20.Visible = isEquipment
			instance.Hover.Visible = visible

			if visible then
				TweenService:Create(
					instance.Hover.UIStroke,
					TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Transparency = v19 and 1 or 0
					}
				):Play()
			else
				instance.Hover.UIStroke.Transparency = 1
				return
			end
		end

		UpdateTemplateTeammateIndicators(instance)
	else
		local icon = instance.Icon
		local _ = v16[icon]
		StopTutorialPulse(icon, nil)
	end
end

local function getDroppedCategory(p)
	local slot = p.Slot

	if slot == "Grenade" then
		return "Grenades"
	elseif slot == "Secondary" then
		return "Pistols"
	end

	if slot ~= "Primary" then
		return nil
	end

	local kind = p.Type

	if kind == "SMG" or kind == "Heavy" then
		return "Mid Tier"
	end

	return "Rifles"
end

local function getCategoryTemplateCount(child)
	local count = 0

	for _, frame in ipairs(child:GetChildren()) do
		if frame:IsA("Frame") and frame.Name ~= "Template" then
			count += 1
		end
	end

	return count
end

local function setDroppedLabelDimmed(instance, p: string, p2: string, flag2: boolean, p3: number)
	if not instance then
		return
	end

	if flag2 then
		instance:SetAttribute("_OrigColor", instance[p])
		instance:SetAttribute("_OrigTrans", instance[p2])
		instance[p] = Color3.new(1, 1, 1)
		instance[p2] = p3
	else
		local origColor = instance:GetAttribute("_OrigColor")
		local origTrans = instance:GetAttribute("_OrigTrans")

		if origColor then
			instance[p] = origColor
		end

		if origTrans ~= nil then
			instance[p2] = origTrans
		end
	end
end

local function setDroppedTemplatePickedUp(template, flag2: boolean)
	local imageLabel = template:FindFirstChild("ImageLabel")
	local textLabel = template:FindFirstChild("TextLabel")

	if flag2 then
		template:SetAttribute("_OrigBG", template.BackgroundColor3)
		template.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	else
		local origBG = template:GetAttribute("_OrigBG")

		if origBG then
			template.BackgroundColor3 = origBG
		end
	end

	setDroppedLabelDimmed(imageLabel, "ImageColor3", "ImageTransparency", flag2, 0.6)
	setDroppedLabelDimmed(textLabel, "TextColor3", "TextTransparency", flag2, 0.8)
end

local function isWithinPickupRange(instance) -- 1 equivalent call inferred from this helper
	local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local primaryPart = instance and instance.PrimaryPart

	if humanoidRootPart and primaryPart then
		return (humanoidRootPart.Position - primaryPart.Position).Magnitude <= 45
	end

	return false
end

local v17 = { Pistols = 2, ["Mid Tier"] = 1, Rifles = 1, Grenades = 4 }

local function tryPickupDroppedWeapon(closestModelInEntry, p: string)
	if not (isWithinPickupRange(closestModelInEntry) and closestModelInEntry:GetAttribute("CanPickup")) then -- inferred equivalent call
		return
	end

	local v18 = v17[p]

	if not v18 then
		return
	end

	local currentInventory = InventoryController.getCurrentInventory()

	if not currentInventory then
		return
	end

	local v19 = currentInventory[v18]

	if not v19 then
		return
	end

	if p == "Grenades" then
		local weapon = closestModelInEntry:GetAttribute("Weapon")

		if #v19._items >= v19._settings._strict_slot_space then
			return
		end

		if Grenades[weapon] then
			local count = 0

			for _, item in ipairs(v19._items) do
				if item.Name == weapon then
					count += 1
				end
			end

			if Grenades[weapon] <= count then
				return
			end
		end
	elseif #v19._items >= v19._settings._strict_slot_space then
		local currentEquipped = InventoryController.getCurrentEquipped()
		local v20 = false

		if currentEquipped then
			local weaponProperties = GetWeaponProperties(currentEquipped.Name)

			if weaponProperties and NumberSlots[weaponProperties.Slot] == v18 and currentEquipped.drop then
				currentEquipped:drop()
				v20 = true
			end
		end

		if not v20 then
			local item = v19._items[1]

			if item and item.Properties and item.Properties.Droppable then
				if currentEquipped and currentEquipped.Identifier == item.Identifier then
					currentEquipped:unequip()
				end

				Remotes.Inventory.DropWeapon.Send({
					CharacterVelocity = GetCharacterVelocity(CharacterResolver.getLocalCharacter()),
					Direction = workspace.CurrentCamera.CFrame.LookVector,
					Identifier = item.Identifier
				})
			else
				return
			end
		end
	end

	if p ~= "Grenades" then
		v12 = v18
	end

	Remotes.Inventory.PickupWeapon.Send({
		Identity = closestModelInEntry.Name,
		AllowAutoEquip = true
	})
end

local function getDroppedKey(p: string, weapon: string) -- 1 equivalent call inferred from this helper
	return p .. "::" .. weapon
end

local function findClosestModelInEntry(p)
	local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	if not humanoidRootPart then
		return nil
	end

	local v18 = 1e999
	local v19 = nil

	for k in pairs(p.models) do
		if not (k and k.Parent and k.PrimaryPart and k:GetAttribute("CanPickup")) then
			continue
		end

		local magnitude = (humanoidRootPart.Position - k.PrimaryPart.Position).Magnitude

		if not (magnitude <= 45 and magnitude < v18) then
			continue
		end

		v19 = k
		v18 = magnitude
	end

	return v19
end

local function hasAnyModelInRange(p)
	local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	if not humanoidRootPart then
		return false
	end

	for k in pairs(p.models) do
		if
			k
			and k.Parent
			and k.PrimaryPart
			and (humanoidRootPart.Position - k.PrimaryPart.Position).Magnitude <= 45
		then
			return true
		end
	end

	return false
end

local function updateDroppedTemplateRangeStates()
	Profiler.mark("UI.BuyMenu.UpdateDroppedTemplateRangeStates")

	for _, v18 in pairs(v10) do
		if not next(v18.models) then
			continue
		end

		local anyModelInRange = hasAnyModelInRange(v18)
		local outOfRange = v18.template:GetAttribute("_OutOfRange")

		if anyModelInRange or outOfRange then
			if anyModelInRange and outOfRange then
				v18.template:SetAttribute("_OutOfRange", nil)
				local template = v18.template
				local imageLabel = template:FindFirstChild("ImageLabel")
				local textLabel = template:FindFirstChild("TextLabel")
				local origBG = template:GetAttribute("_OrigBG")

				if origBG then
					template.BackgroundColor3 = origBG
				end

				if imageLabel then
					local origColor = imageLabel:GetAttribute("_OrigColor")
					local origTrans = imageLabel:GetAttribute("_OrigTrans")

					if origColor then
						imageLabel.ImageColor3 = origColor
					end

					if origTrans ~= nil then
						imageLabel.ImageTransparency = origTrans
					end
				end

				if textLabel then
					local origColor = textLabel:GetAttribute("_OrigColor")
					local origTrans = textLabel:GetAttribute("_OrigTrans")

					if origColor then
						textLabel.TextColor3 = origColor
					end

					if origTrans ~= nil then
						textLabel.TextTransparency = origTrans
					end
				end
			end
		else
			v18.template:SetAttribute("_OutOfRange", true)
			setDroppedTemplatePickedUp(v18.template, true)
		end
	end
end

local function getModelCount(models) -- 1 equivalent call inferred from this helper
	local count = 0

	for _ in pairs(models) do
		count += 1
	end

	return count
end

local function updateDroppedTemplateLabel(data) -- 2 equivalent calls inferred from this helper
	local textLabel = data.template:FindFirstChild("TextLabel")

	if not textLabel then
		return
	end

	local modelCount = getModelCount(data.models) -- inferred equivalent call

	if modelCount > 1 then
		textLabel.Text = `x{modelCount} {data.weaponName}`
	else
		textLabel.Text = data.weaponName
	end
end

local function onWeaponDropped(instance)
	if workspace:GetAttribute("Gamemode") == "Deathmatch" or IsTutorialMode() then
		return
	end

	local weapon = instance:GetAttribute("Weapon")

	if not (weapon and instance:GetAttribute("DroppedByTeam") == LocalPlayer:GetAttribute("Team")) then
		return
	end

	local weaponProperties = GetWeaponProperties(weapon)

	if not weaponProperties then
		return
	end

	local slot = weaponProperties.Slot
	local category

	if slot == "Grenade" then
		category = "Grenades"
	elseif slot == "Secondary" then
		category = "Pistols"
	elseif slot == "Primary" then
		local kind = weaponProperties.Type
		category = (kind == "SMG" or kind == "Heavy") and "Mid Tier" or "Rifles"
	else
		category = nil
	end

	if not category then
		return
	end

	local droppedKey = getDroppedKey(category, weapon) -- inferred equivalent call
	local v18 = v10[droppedKey]

	if v18 then
		v18.models[instance] = true
		v11[instance] = droppedKey
		v18.template:SetAttribute("_OutOfRange", nil)
		local template = v18.template
		local imageLabel = template:FindFirstChild("ImageLabel")
		local textLabel = template:FindFirstChild("TextLabel")
		local origBG = template:GetAttribute("_OrigBG")

		if origBG then
			template.BackgroundColor3 = origBG
		end

		if imageLabel then
			local origColor = imageLabel:GetAttribute("_OrigColor")
			local origTrans = imageLabel:GetAttribute("_OrigTrans")

			if origColor then
				imageLabel.ImageColor3 = origColor
			end

			if origTrans ~= nil then
				imageLabel.ImageTransparency = origTrans
			end
		end

		if textLabel then
			local origColor = textLabel:GetAttribute("_OrigColor")
			local origTrans = textLabel:GetAttribute("_OrigTrans")

			if origColor then
				textLabel.TextColor3 = origColor
			end

			if origTrans ~= nil then
				textLabel.TextTransparency = origTrans
			end
		end

		updateDroppedTemplateLabel(v18) -- inferred equivalent call
		local imageButton = v18.template:FindFirstChild("ImageButton")

		if imageButton then
			imageButton.Active = true
		end
	else
		local dropped = v3.Menu:FindFirstChild("Dropped")

		if not dropped then
			return
		end

		local container = dropped:FindFirstChild("Container")

		if not container then
			return
		end

		local child = container:FindFirstChild(category)

		if not child or getCategoryTemplateCount(child) >= 4 then
			return
		end

		local template = container:FindFirstChild("Template")

		if not template then
			return
		end

		local clone = template:Clone()
		clone.Name = droppedKey
		clone.Visible = true
		clone.Parent = child
		local reverseIcon = weaponProperties.ReverseIcon or weaponProperties.Icon
		local imageLabel = clone:FindFirstChild("ImageLabel")
		local textLabel = clone:FindFirstChild("TextLabel")
		local imageButton = clone:FindFirstChild("ImageButton")

		if imageLabel then
			imageLabel.Image = reverseIcon
			imageLabel.ImageColor3 = GetPreferenceColor()
		end

		if textLabel then
			textLabel.Text = weapon
			textLabel.TextColor3 = GetPreferenceColor()
		end

		local v19 = {
			template = clone,
			category = category,
			weaponName = weapon,
			models = { [instance] = true }
		}
		v10[droppedKey] = v19
		v11[instance] = droppedKey

		if imageButton then
			v9:Add((imageButton.MouseButton1Click:Connect(function()
				local closestModelInEntry = findClosestModelInEntry(v19)

				if closestModelInEntry then
					Router.broadcastRouter("RunInterfaceSound", "UI Click")
					tryPickupDroppedWeapon(closestModelInEntry, category)
				end
			end)))
		end
	end
end

local function onWeaponDropRemoved(p)
	local v18 = v11[p]

	if not v18 then
		return
	end

	v11[p] = nil
	local v19 = v10[v18]

	if not v19 then
		return
	end

	v19.models[p] = nil

	if next(v19.models) then
		updateDroppedTemplateLabel(v19) -- inferred equivalent call
	else
		v19.template:SetAttribute("_OutOfRange", nil)
		setDroppedTemplatePickedUp(v19.template, true)
		local imageButton = v19.template:FindFirstChild("ImageButton")

		if imageButton then
			imageButton.Active = false
		end
	end
end

local function updateDroppedFrameVisibility() -- 3 equivalent calls inferred from this helper
	local dropped = v3 and v3.Menu and v3.Menu:FindFirstChild("Dropped")

	if not dropped then
		return
	end

	dropped.Visible = workspace:GetAttribute("Gamemode") ~= "Deathmatch" and not IsTutorialMode()
end

local function cleanupAllDroppedEntries()
	for _, v18 in pairs(v10) do
		v18.template:Destroy()
	end

	table.clear(v10)
	table.clear(v11)
	v9:Cleanup()
	local dropped = v3 and v3.Menu and v3.Menu:FindFirstChild("Dropped")

	if not dropped then
		return
	end

	local container = dropped:FindFirstChild("Container")

	if not container then
		return
	end

	for _, frame in ipairs(container:GetChildren()) do
		if not (frame:IsA("Frame") and frame.Name ~= "Template") then
			continue
		end

		for _, frame2 in ipairs(frame:GetChildren()) do
			if frame2:IsA("Frame") then
				frame2:Destroy()
			end
		end
	end
end

local function updateBuyMenuHeartbeat(p: number)
	Profiler.mark("UI.BuyMenu.Heartbeat")
	local commaNumber = CommaNumber(math.round((v2:getPosition()))) -- inferred equivalent call
	v3.Menu.TopFrame.Money.TextColor3 = GetPreferenceColor()
	v3.Menu.TopFrame.Money.Text = "$" .. commaNumber
	v2:update(p)

	if v3.Visible and not IsInBuyArea(LocalPlayer) then
		local gamemode = workspace:GetAttribute("Gamemode")

		if gamemode == "Bomb Defusal" or gamemode == "Hostage Rescue" then
			BuyMenu.closeFrame()
			return
		end
	end

	if v3.Visible and IsTutorialMode() then
		if IsTutorialPurchasePending() then -- inferred equivalent call
			flag = true
		elseif flag then
			flag = false
			BuyMenu.closeFrame()
			return
		end
	end

	updateDroppedTemplateRangeStates()
end

local function startBuyMenuUpdate() -- 1 equivalent call inferred from this helper
	if connection then
		return
	end

	connection = RunServiceController.BindToHeartbeat("UI.BuyMenu.Update", updateBuyMenuHeartbeat)
	updateBuyMenuHeartbeat(0)
end

local function stopBuyMenuUpdate() -- 1 equivalent call inferred from this helper
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function NotifyTutorial(p: string) -- 2 equivalent calls inferred from this helper
	if not IsTutorialMode() then
		return
	end

	Remotes.Tutorial.ClientEvent.Send(p)
end

function BuyMenu.openFrame()
	if EndScreenController.IsActive() then
		return
	end

	local buyMenu = LocalPlayer:GetAttribute("BuyMenu")

	if
		not IsInBuyArea(LocalPlayer)
		or TutorialPurchaseLock.isBuyMenuLocked(LocalPlayer)
		or (not buyMenu or v3.Visible)
	then
		return
	end

	CameraController.setForceLockOverride("BuyMenu", true)
	CameraController.setPerspective(true, true)
	v4.Gameplay.Bottom.Health.Visible = false
	v4.Gameplay.Bottom.Middle.Visible = false
	v4.Gameplay.Bottom.Armor.Visible = false
	v4.Gameplay.Bottom.Money.Visible = false
	v4.Gameplay.Bottom.Ammo.Visible = false
	v3.Visible = true
	startBuyMenuUpdate() -- inferred equivalent call
	HideWeaponInfoFrame() -- inferred equivalent call
	RequestCompetitiveTeammateInventories()
	UpdateAllTeammateIndicators()
	NotifyTutorial("OpenedBuyMenu") -- inferred equivalent call
end

function BuyMenu.closeFrame()
	if not v3.Visible then
		return
	end

	CameraController.setForceLockOverride("BuyMenu", false)
	CameraController.setPerspective(true, false)
	v4.Gameplay.Bottom.Health.Visible = true
	v4.Gameplay.Bottom.Middle.Visible = true
	v4.Gameplay.Bottom.Armor.Visible = GetPlayerArmorState(LocalPlayer).Health > 0
	v4.Gameplay.Bottom.Money.Visible = true
	v4.Gameplay.Bottom.Ammo.Visible = true
	v3.Visible = false
	stopBuyMenuUpdate() -- inferred equivalent call
	HideWeaponInfoFrame() -- inferred equivalent call
	flag = false
	NotifyTutorial("ClosedBuyMenu") -- inferred equivalent call
end

function BuyMenu.toggleFrame()
	if EndScreenController.IsActive() then
		return
	end

	if LocalPlayer:GetAttribute("BuyMenu") and not v3.Visible then
		BuyMenu.openFrame()
	elseif v3.Visible then
		if IsTutorialPurchasePending() then -- inferred equivalent call
			return
		else
			BuyMenu.closeFrame()
		end
	end
end

function BuyMenu.characterAdded(_)
	if not WaitForAttribute(LocalPlayer, "Money") then
		return
	end

	maid:Cleanup()
	setupBuyMenuTemplates()
end

function BuyMenu.Initialize(p, p2)
	v4 = p
	v3 = p2
	UpdateBuyMenuTimerText()

	local function refreshBuyMenuTemplates()
		local currentInventory = InventoryController.getCurrentInventory()

		for _, button in ipairs(v3.Menu.Container:GetDescendants()) do
			if button:IsA("TextButton") then
				BuyMenu.updateBuyMenuTemplate(currentInventory, button)
			end
		end
	end

	local function trackCompetitiveTeammate(instance)
		if instance == LocalPlayer then
			return
		end

		maid2:Add(instance:GetAttributeChangedSignal("Team"):Connect(function()
			if instance:GetAttribute("Team") ~= LocalPlayer:GetAttribute("Team") then
				v13[instance] = nil
			end

			RequestCompetitiveTeammateInventory(instance)
			UpdateAllTeammateIndicators()
		end))

		for _, v18 in ipairs(v) do
			maid2:Add(instance:GetAttributeChangedSignal(v18):Connect(UpdateAllTeammateIndicators))
		end

		for i = 1, 5 do
			maid2:Add(instance:GetAttributeChangedSignal("Slot" .. i):Connect(function()
				RequestCompetitiveTeammateInventory(instance)
				UpdateAllTeammateIndicators()
			end))
		end
	end

	local function setupCompetitiveTeammateObservers()
		Profiler.mark("UI.BuyMenu.SetupCompetitiveTeammateObservers")
		maid2:Cleanup()
		ClearCompetitiveTeammateInventoryCache() -- inferred equivalent call
		maid2:Add(Players.PlayerAdded:Connect(function(player)
			trackCompetitiveTeammate(player)
			RequestCompetitiveTeammateInventory(player)
			UpdateAllTeammateIndicators()
		end))
		maid2:Add(Players.PlayerRemoving:Connect(function(player)
			v13[player] = nil
			v14[player] = nil
			UpdateAllTeammateIndicators()
		end))
		maid2:Add(Remotes.Inventory.SpectatedPlayerInventory.Listen(function(p3)
			if p3.Player == LocalPlayer then
				return
			end

			v13[p3.Player] = p3.Inventory
			v14[p3.Player] = nil
			UpdateAllTeammateIndicators()
		end))

		for _, v18 in ipairs(Players:GetPlayers()) do
			trackCompetitiveTeammate(v18)
		end

		RequestCompetitiveTeammateInventories()
		UpdateAllTeammateIndicators()
	end

	setupCompetitiveTeammateObservers()
	Observers.observeAttribute(LocalPlayer, "Team", function()
		cleanupAllDroppedEntries()
		ClearCompetitiveTeammateInventoryCache() -- inferred equivalent call
		maid:Cleanup()
		setupBuyMenuTemplates()
		refreshBuyMenuTemplates()
	end)
	Observers.observeAttribute(workspace, "Gamemode", function()
		updateDroppedFrameVisibility() -- inferred equivalent call
		cleanupAllDroppedEntries()
		maid:Cleanup()
		setupBuyMenuTemplates()
		refreshBuyMenuTemplates()
	end)
	updateDroppedFrameVisibility() -- inferred equivalent call
	Observers.observeAttribute(workspace, "ServerGamemode", function()
		updateDroppedFrameVisibility() -- inferred equivalent call
		maid:Cleanup()
		setupBuyMenuTemplates()
		refreshBuyMenuTemplates()
	end)
	Remotes.Inventory.NewInventoryItem.Listen(function(p3)
		if p3.isPurchase ~= true then
			return
		end

		table.insert(identifiers, p3.identifier)
		refreshBuyMenuTemplates()
	end)
	Remotes.Inventory.RemoveInventoryItem.Listen(function(p3)
		RemoveFromArray(identifiers, function(_, p4)
			return p4 == p3
		end)
	end)
	Observers.observeAttribute(LocalPlayer, "MinimumNextRoundIncome", function(p3)
		v3.Menu.TopFrame.NextRoundMoney.Text = "Next Round Minimum:  $" .. CommaNumber(p3) -- inferred equivalent call
	end)
	Observers.observeAttribute(LocalPlayer, "Money", function(p3)
		v2:setGoal(p3)
		refreshBuyMenuTemplates()
	end)

	for _, v18 in ipairs({ "Armor", "HasDefuseKit", "HasRescueKit" }) do
		Observers.observeAttribute(LocalPlayer, v18, refreshBuyMenuTemplates)
	end

	Observers.observeAttribute(workspace, "VIPInfiniteCashEnabled", refreshBuyMenuTemplates)
	Observers.observeAttribute(LocalPlayer, "Team", function()
		setupBuyMenuTemplates()
		refreshBuyMenuTemplates()
	end)
	Observers.observeAttribute(LocalPlayer, "TutorialStep", function()
		refreshBuyMenuTemplates()
	end)
	Observers.observeAttribute(LocalPlayer, "BuyMenu", function()
		return function()
			BuyMenu.closeFrame()
		end
	end)
	Observers.observeAttribute(workspace, "Timer", UpdateBuyMenuTimerText)
	Observers.observeAttribute(workspace, "BuyTimerRemaining", UpdateBuyMenuTimerText)
	GameState.ListenToState(function(_, p3)
		if p3 == "Buy Period" then
			table.clear(identifiers)
			cleanupAllDroppedEntries()
		end

		UpdateBuyMenuTimerText()
	end)
	InventoryController.OnInventoryChanged:Connect(function(p3)
		for _, button in ipairs(v3.Menu.Container:GetDescendants()) do
			if button:IsA("TextButton") then
				BuyMenu.updateBuyMenuTemplate(p3, button)
			end
		end
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", function()
		refreshBuyMenuTemplates()

		for _, v18 in pairs(v10) do
			if v18.template:GetAttribute("_OrigBG") then
				continue
			end

			local imageLabel = v18.template:FindFirstChild("ImageLabel")
			local textLabel = v18.template:FindFirstChild("TextLabel")

			if imageLabel then
				imageLabel.ImageColor3 = GetPreferenceColor()
			end

			if textLabel then
				textLabel.TextColor3 = GetPreferenceColor()
			end
		end
	end)
	DataController.CreateListener(LocalPlayer, "Loadout", function()
		if not LocalPlayer.Character then
			return
		end

		maid:Cleanup()
		setupBuyMenuTemplates()
		refreshBuyMenuTemplates()
	end)
	Observers.observeTag("WeaponDropped", function(p3)
		onWeaponDropped(p3)
		return function()
			onWeaponDropRemoved(p3)
		end
	end)
end

function BuyMenu.Start()
	if LocalPlayer.Character then
		BuyMenu.characterAdded(LocalPlayer.Character)
	end

	LocalPlayer.CharacterAdded:Connect(BuyMenu.characterAdded)
	CharacterResolver.observeCharacter(LocalPlayer, function(instance)
		if not instance then
			BuyMenu.closeFrame()
			return nil
		end

		local function closeWhenDead() -- 1 equivalent call inferred from this helper
			if instance:GetAttribute("Dead") == true then
				BuyMenu.closeFrame()
			end
		end

		closeWhenDead() -- inferred equivalent call
		local deadChangedConnection = instance:GetAttributeChangedSignal("Dead"):Connect(closeWhenDead)
		return function()
			deadChangedConnection:Disconnect()
		end
	end)
	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(function()
		if LocalPlayer:GetAttribute("IsSpectating") == true then
			BuyMenu.closeFrame()
		end
	end)
end

return BuyMenu