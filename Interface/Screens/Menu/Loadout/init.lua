local Loadout = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GamepadService = game:GetService("GamepadService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local GamepadNavigation = require(ReplicatedStorage.Interface.GamepadNavigation)
local Router = require(ReplicatedStorage.Database.Security.Router)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local Collections = require(ReplicatedStorage.Database.Components.Libraries.Collections)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local ItemEquipment = require(ReplicatedStorage.Components.Common.ItemEquipment)
local CalculateGridRenderCount = require(ReplicatedStorage.Components.Common.CalculateGridRenderCount)
local UpdateStatusFrame = ItemEquipment.UpdateStatusFrame
local IsEquippedOnTeam = ItemEquipment.IsEquippedOnTeam
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local UseItemFrame = require(script.Parent.UseItemFrame)
local ItemIcon = require(script.ItemIcon)
local Sort = require(ReplicatedStorage.Database.Custom.GameStats.UI.Inventory.Sort)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local GetResolvedSkinInformation = require(ReplicatedStorage.Components.Common.GetResolvedSkinInformation)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local WeaponCategories = require(ReplicatedStorage.Database.Custom.GameStats.WeaponCategories)
local CommaNumber = require(ReplicatedStorage.Components.Common.CommaNumber)
local team2 = "Counter-Terrorists"
local kind = nil
local v = "Newest"
local v2 = false
local v3 = nil
local v4 = nil
local flag = false
local v5 = nil
local id = nil
local name = nil
local kind2 = nil
local connection = nil
local v6 = nil
local v7 = nil
local connection2 = nil
local v8 = false
local v9 = nil
local id2 = nil
local v10 = false
local flag2 = false
local v11 = false
local v12 = nil
local now = 0
local now2 = 0
local flag3 = false
local count = 0
local id3 = nil
local v13 = nil
local information = nil
local connections = {}
local v14 = {}
local v15 = 0
local flag4 = false
local flag5 = false
local udim = UDim2.fromScale(0.2, 0.2)
local vector = Vector2.new(0, 0)
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local v16 = { Pistol = "Pistols", SMG = "Mid Tier", Heavy = "Mid Tier", Rifle = "Rifles" }
local v17 = {
	["Incendiary Grenade"] = true,
	["Decoy Grenade"] = true,
	["Smoke Grenade"] = true,
	["HE Grenade"] = true,
	Flashbang = true,
	Molotov = true
}
local v18 = {
	Charm = true,
	["Charm Capsule"] = true,
	Sticker = true,
	["Sticker Capsule"] = true,
	Grenade = true,
	Case = true,
	Package = true,
	Booth = true
}
local v19 = {
	Glove = "Equipped Gloves",
	Melee = "Equipped Melee",
	["Zeus x27"] = "Equipped Zeus x27",
	Badge = "Equipped Badge",
	["Music Kit"] = "Equipped Music Kit",
	Graffiti = "Equipped Graffiti"
}
local v20 = {
	["Equipped Gloves"] = "Gloves",
	["Equipped Melee"] = "Melee",
	["Equipped Zeus x27"] = "Zeus",
	["Equipped Badge"] = "Badge",
	["Equipped Music Kit"] = "Music Kit",
	["Equipped Graffiti"] = "Spray"
}
local v21 = { "Melee", "Gloves", "Zeus", "Badge", "Music Kit", "Spray" }
local v22 = { "Badge", "Gloves", "Melee", "Music Kit", "Spray", "Zeus" }
local v23 = {
	Melee = "Melee",
	Gloves = "Glove",
	Badge = "Badge",
	Zeus = "Zeus x27",
	["Music Kit"] = "Music Kit",
	Spray = "Graffiti"
}
local v24 = {
	Weapon = true,
	Melee = true,
	Glove = true,
	["Zeus x27"] = true,
	Badge = true,
	Charm = true
}

local function CanInspectItem(data) -- 2 equivalent calls inferred from this helper
	return data ~= nil and v24[data.Type] == true
end

local v25 = {
	Melee = "Knives",
	Gloves = "Gloves",
	Zeus = "Zeus x27",
	Badge = "Badges",
	["Music Kit"] = "Music Kits",
	Spray = "Sprays"
}
local v26 = { Melee = "Melee", Gloves = "Glove" }
local v27 = { "ButtonCT", "ButtonT" }
local v28 = {
	Terrorists = { "Glock-18" },
	["Counter-Terrorists"] = { "USP-S", "P2000" }
}
local v29 = nil

local function GetTeamFrame(childName: string) -- 8 equivalent calls inferred from this helper
	local frame = v29.Container.Teams:FindFirstChild(childName)
	assert(frame and frame:IsA("Frame"), `[Loadout] Missing {childName} team panel`)
	return frame
end

local function ClearFrame(list, list2)
	for _, child in ipairs(list:GetChildren()) do
		if not table.find(list2, child.Name) then
			child:Destroy()
		end
	end
end

local v30 = { "Charm", "Inspect", "ReplaceCT", "ReplaceT", "Unlock" }

local function GetVisibleInformationFrameButtons()
	local result = {}

	for _, v31 in v30 do
		local v32 = information[v31]

		if v32 and v32.Visible then
			table.insert(result, v32)
		end
	end

	local quickUnlock = information:FindFirstChild("QuickUnlock")

	if quickUnlock and quickUnlock.Visible then
		table.insert(result, quickUnlock)
	end

	return result
end

local function HasAnyInformationFrameButton() -- 1 equivalent call inferred from this helper
	return information ~= nil and #GetVisibleInformationFrameButtons() > 0
end

local function ItemHasCharm(p) -- 2 equivalent calls inferred from this helper
	local charm = p.Charm
	return charm ~= nil and charm ~= false and (type(charm) == "string" or charm == true or type(charm) == "table")
end

local function FindWeaponSlotOnTeam(name2: string, p, p2: string)
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not (loadout and inventory) then
		return nil
	end

	local v31 = loadout[p]

	if not (v31 and v31.Loadout and v31.Loadout[p2]) then
		return nil
	end

	for i, option in ipairs(v31.Loadout[p2].Options) do
		if not (option and option ~= "") then
			continue
		end

		for _, v32 in ipairs(inventory) do
			if v32._id == option and v32.Name == name2 then
				return i
			end
		end
	end

	return nil
end

local function ReplaceItemOnTeam(data, team)
	if data.Type == "Weapon" then
		local success, result = pcall(GetWeaponProperties, data.Name)
		local v31

		if success and result and result.Type then
			v31 = v16[result.Type]
		end

		if not v31 then
			return
		end

		local v32 = FindWeaponSlotOnTeam(data.Name, team, v31) or 1
		Remotes.Inventory.EquipLoadoutSkin.Send({
			Type = v31,
			Slot = v32 - 1,
			Team = team,
			Identifier = data._id
		})
	else
		if
			data.Type == "Melee"
			and (data.Name == "CT Knife" and team == "Terrorists" or data.Name == "T Knife" and team == "Counter-Terrorists")
		then
			return
		end

		local path = v19[data.Type]

		if path then
			Remotes.Inventory.EquipSpecialItem.Send({
				Identifier = data._id,
				Path = path,
				Team = team
			})
		end
	end
end

function Loadout.SetupInformationFrameNavigation()
	if not information then
		return
	end

	local visibleInformationFrameButtons = GetVisibleInformationFrameButtons()
	table.sort(visibleInformationFrameButtons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for i, v31 in ipairs(visibleInformationFrameButtons) do
		v31.NextSelectionUp = visibleInformationFrameButtons[i > 1 and i - 1 or #visibleInformationFrameButtons]
		v31.NextSelectionDown = visibleInformationFrameButtons[i < #visibleInformationFrameButtons and i + 1 or 1]
		v31.NextSelectionLeft = nil
		v31.NextSelectionRight = nil
	end
end

function Loadout.SelectFirstInformationFrameButton()
	if not (information and information.Visible) then
		return
	end

	Loadout.SetupInformationFrameNavigation()
	local selectedObject = GetVisibleInformationFrameButtons()[1]

	if selectedObject then
		GuiService.SelectedObject = selectedObject
	end
end

function Loadout:SetupInformationFrame()
	Profiler.mark("UI.Loadout.SetupInformationFrame")
	local v31 = self.Type == "Weapon"
	local v32 = self.Type == "Melee"
	local v34 = self.Type == "Glove"
	local v35 = self.Type == "Badge"
	local v36 = self.Type == "Zeus x27"
	local inspect = information.Inspect
	inspect.Visible = CanInspectItem(self) -- inferred equivalent call

	if information.Unlock then
		information.Unlock.Visible = self.Type == "Case" or self.Type == "Package"
	end

	if information.Loadout then
		information.Loadout.Visible = false
	end

	local quickUnlock = information:FindFirstChild("QuickUnlock")

	if quickUnlock then
		quickUnlock.Visible = false
	end

	local unlockDivider = information:FindFirstChild("UnlockDivider")

	if unlockDivider then
		unlockDivider.Visible = false
	end

	local visible = v31 or v36 or self.Type == "Charm"

	if information.Charm then
		information.Charm.Visible = visible
		local textLabel = visible and information.Charm:FindFirstChildWhichIsA("TextLabel", true)

		if textLabel then
			if self.Type == "Charm" then
				textLabel.Text = "Attach to Weapon"
			else
				textLabel.Text = ItemHasCharm(self) and "Detach Charm" or "Attach Charm" -- inferred equivalent call
			end
		end
	end

	local v38 = false
	local v39 = false

	local function applyTeamRestriction(team: string?) -- 2 equivalent calls inferred from this helper
		v38 = team == "Both" or team == "Counter-Terrorists"
		v39 = team == "Both" or team == "Terrorists"
	end

	if v31 then
		local success, result = pcall(GetWeaponProperties, self.Name)

		if success and result then
			applyTeamRestriction(result.Team) -- inferred equivalent call
		end
	elseif v32 then
		if self.Name == "T Knife" then
			v38 = false
		else
			v38 = true
		end

		if self.Name == "CT Knife" then
			v39 = false
		else
			v39 = true
		end
	elseif v34 then
		local weaponProperties = GetWeaponProperties(self.Name)

		if weaponProperties then
			applyTeamRestriction(weaponProperties.Team) -- inferred equivalent call
		end
	elseif v35 or v36 then
		v38 = true
		v39 = true
	end

	local equippedOnTeam = IsEquippedOnTeam(self._id, "Counter-Terrorists")
	local equippedOnTeam2 = IsEquippedOnTeam(self._id, "Terrorists")
	local v40 = v31 or v32 or v34 or v35 or v36

	if information.ReplaceCT then
		information.ReplaceCT.Visible = v40 and v38 and not equippedOnTeam
	end

	if information.ReplaceT then
		information.ReplaceT.Visible = v40 and v39 and not equippedOnTeam2
	end

	local v41 = {
		{ dividerName = "CharmDivider", action = information.Charm },
		{ dividerName = "InspectDivider", action = information.Inspect },
		{ dividerName = "ReplaceCTDivider", action = information.ReplaceCT },
		{ dividerName = "ReplaceTDivider", action = information.ReplaceT },
		{ dividerName = "LoadoutDivider", action = information.Loadout }
	}
	local v42 = { UnlockDivider = true }

	for _, v43 in ipairs(v41) do
		v42[v43.dividerName] = true
	end

	for _, v43 in ipairs(v41) do
		local child = information:FindFirstChild(v43.dividerName)

		if not (child and v43.action) then
			continue
		end

		local visible2 = false

		if v43.action.Visible then
			for _, guiObject in ipairs(information:GetChildren()) do
				if
					v42[guiObject.Name]
					or guiObject == child
					or guiObject == v43.action
					or not (guiObject:IsA("Frame") or guiObject:IsA("TextButton"))
				then
					continue
				end

				if not (guiObject.LayoutOrder < child.LayoutOrder and guiObject.Visible) then
					continue
				end

				visible2 = true
				break
			end
		end

		child.Visible = visible2
	end
end

local function PositionInformationFrame(p, flag6: boolean?)
	local parent = information.Parent.Parent
	local absolutePosition = parent.AbsolutePosition
	local absoluteSize = parent.AbsoluteSize
	local x = nil
	local y = nil

	if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 or flag6 then
		if p then
			local absolutePosition2 = p.AbsolutePosition
			local absoluteSize2 = p.AbsoluteSize
			x = absolutePosition2.X + absoluteSize2.X / 2
			y = absolutePosition2.Y + absoluteSize2.Y / 2
		end
	else
		x = mouse.X
		y = mouse.Y
	end

	local v31, v32

	if x and y then
		local v34 = (x - absolutePosition.X) / absoluteSize.X
		v31 = (y - absolutePosition.Y) / absoluteSize.Y + information.Size.Y.Scale / 2

		if 1 - v34 >= information.Size.X.Scale + 0.01 then
			v32 = v34 + information.Size.X.Scale / 2 + 0.01
		else
			v32 = v34 - information.Size.X.Scale / 2 - 0.01
		end
	else
		v32 = 0.5
		v31 = 0.5
	end

	information.Position = UDim2.fromScale(v32, v31)
end

local function ShowContextMenu(p, _: Vector2, p2, flag6: boolean?)
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if inventory then
		for _, v31 in ipairs(inventory) do
			if v31._id ~= p._id then
				continue
			end

			p = v31
			break
		end
	end

	id3 = p._id
	v13 = p2

	if not information then
		return
	end

	Router.broadcastRouter("RunInterfaceSound", "UI Click")
	Loadout.SetupInformationFrame(p)

	if HasAnyInformationFrameButton() then -- inferred equivalent call
		if flag6 then
			information.Visible = true
		else
			information.Visible = not information.Visible
		end

		if information.Visible then
			PositionInformationFrame(p2, flag6)
			Profiler.defer("UI.Loadout.InformationNavigationDeferred", function()
				Loadout.SetupInformationFrameNavigation()

				if flag6 then
					Loadout.SelectFirstInformationFrameButton()
				end
			end)
		else
			id3 = nil
			v13 = nil
		end
	else
		information.Visible = false
		id3 = nil
		v13 = nil
	end
end

local function HideContextMenu() -- 7 equivalent calls inferred from this helper
	if information then
		information.Visible = false
	end

	id3 = nil
	v13 = nil
end

local function GetInventoryItemFromIdentifier(p: string)
	for _, v31 in ipairs(DataController.Get(LocalPlayer, "Inventory") or {}) do
		if v31._id == p then
			return v31
		end
	end

	return nil
end

local function GetCurrentInventoryItem() -- 2 equivalent calls inferred from this helper
	if id3 then
		return (GetInventoryItemFromIdentifier(id3))
	end

	return nil
end

local v31 = nil
Collections.ObserveAvailableCollections(function(p)
	v31 = p
end)

local function IsWeaponValidForTeam(value: string?, p)
	if not value or type(value) ~= "string" or value == "" then
		return false
	end

	local success, result = pcall(GetWeaponProperties, value)

	if success then
		if result == nil or result.Team == nil then
			success = false
		else
			success = result.Team == "Both" or result.Team == p
		end
	end

	return success
end

local function GetSortedLoadoutItemIds()
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not inventory then
		return {}
	end

	local sortComparisonFunction = Sort.GetSortComparisonFunction(v, LocalPlayer, function()
		return v31
	end)
	local v32 = {}
	local v34 = {}

	for _, v35 in ipairs(inventory) do
		if not (v35 and v35._id) then
			continue
		end

		if v32[v35._id] or v18[v35.Type] or v17[v35.Name] or not v35.Name then
			continue
		end

		if type(v35.Name) ~= "string" then
			continue
		end

		local success, result = pcall(GetWeaponProperties, v35.Name)

		if success and result and result.Team then
			local name2 = v35.Name
			local v36 = team2
			local success2

			if name2 and type(name2) == "string" and name2 ~= "" then
				local result2
				success2, result2 = pcall(GetWeaponProperties, name2)

				if success2 then
					if result2 == nil or result2.Team == nil then
						success2 = false
					else
						success2 = result2.Team == "Both" or result2.Team == v36
					end
				end
			else
				success2 = false
			end

			if not success2 then
				continue
			end
		end

		v32[v35._id] = true
		table.insert(v34, v35)
	end

	if kind then
		local v35 = {}

		for _, v36 in ipairs(v34) do
			if not (v36.Type ~= "Case" and v36.Type ~= "Package" and v36.Type ~= "Charm Capsule" and v36.Type ~= "Sticker Capsule") then
				continue
			end

			if not (v36.Name and type(v36.Name) == "string") then
				continue
			end

			local success, result = pcall(GetWeaponProperties, v36.Name)

			if success and result and result.Type == kind then
				table.insert(v35, v36)
			end
		end

		v34 = v35
	end

	if v3 then
		local v35 = v23[v3.sidebarName]
		local v36 = v26[v3.sidebarName]
		local v37 = v3.teamKey == "CT" and "Counter-Terrorists" or "Terrorists"
		local v38 = {}

		for _, v39 in ipairs(v34) do
			if v39.Type ~= v35 then
				continue
			end

			local success, result = pcall(GetWeaponProperties, v39.Name)

			if not (not v36 or not success or not result or not result.Class or result.Class == v36) then
				continue
			end

			local name2 = v39.Name
			local v40 = v37 == "Counter-Terrorists" and "T" or "CT"

			if not (name2 ~= `{v40} Knife` and name2 ~= `{v40} Glove`) then
				continue
			end

			local v41 = not (success and result and result.Team)
			local name3 = v39.Name
			local success2

			if name3 and type(name3) == "string" and name3 ~= "" then
				local result2
				success2, result2 = pcall(GetWeaponProperties, name3)

				if success2 then
					if result2 == nil or result2.Team == nil then
						success2 = false
					else
						success2 = result2.Team == "Both" or result2.Team == v37
					end
				end
			else
				success2 = false
			end

			if v41 or success2 then
				table.insert(v38, v39)
			end
		end

		v34 = v38
	end

	if v4 then
		local v35 = {}

		for _, v36 in ipairs(v34) do
			local v37 = v36.Name == v4.weaponName
			local v38 = v4.skinName == nil or v36.Skin == v4.skinName

			if v37 and v38 then
				table.insert(v35, v36)
			end
		end

		v34 = v35
	end

	if sortComparisonFunction then
		if v2 then
			table.sort(v34, function(a, b)
				local v35, v36 = sortComparisonFunction(a, b)

				if v36 then
					return v35
				end

				return sortComparisonFunction(b, a)
			end)
		else
			table.sort(v34, sortComparisonFunction)
		end
	end

	local ids = table.create(#v34)

	for _, v35 in ipairs(v34) do
		table.insert(ids, v35._id)
	end

	return ids
end

local function CreateMissingItemTemplates(container, p: number, p2: number)
	for i = p, p2 do
		local v32 = v14[i]
		local v34 = v32 and GetInventoryItemFromIdentifier(v32)

		if not v34 or container:FindFirstChild(v32) then
			continue
		end

		Loadout.CreateItemTemplate(v34)
	end
end

local function ApplySortedLayoutOrder(container)
	for _, button in ipairs(container:GetChildren()) do
		if not (button:IsA("ImageButton") and button.Name ~= "UIGridLayout" and button.Name ~= "UIListLayout" and button.Name ~= "UIPadding") then
			continue
		end

		for i, v32 in ipairs(v14) do
			if v32 ~= button.Name then
				continue
			end

			button.LayoutOrder = i
			break
		end
	end
end

local function RenderLoadoutTemplates() -- 2 equivalent calls inferred from this helper
	Profiler.mark("UI.Loadout.RenderLoadoutTemplates")

	if not v29 then
		return
	end

	local container = v29.Container.List.Container
	local v32 = math.min(v15 + 25, #v14)
	CreateMissingItemTemplates(container, v15 + 1, v32)
	v15 = v32
	ApplySortedLayoutOrder(container)
end

local function OnLoadoutScrollPositionChanged()
	if not v29 then
		return
	end

	local container = v29.Container.List.Container
	local y = container.CanvasPosition.Y
	local v32 = container.AbsoluteCanvasSize.Y - container.AbsoluteSize.Y

	if v32 > 0 and v15 < #v14 and v32 - y < 200 then
		RenderLoadoutTemplates() -- inferred equivalent call
	end
end

local function CalculateLoadoutInitialRenderCount()
	if v29 and v29.Visible then
		return CalculateGridRenderCount(v29.Container.List.Container)
	end

	return 50
end

local function RenderInitialLoadoutTemplates()
	Profiler.mark("UI.Loadout.RenderInitialLoadoutTemplates")

	if not (v29 and v29.Visible) then
		return
	end

	local container = v29.Container.List.Container
	v15 = 0
	local v32 = math.min(
		math.max(not (v29 and v29.Visible) and 50 or CalculateGridRenderCount(v29.Container.List.Container), 50),
		#v14
	)
	CreateMissingItemTemplates(container, 1, v32)
	ApplySortedLayoutOrder(container)
	v15 = v32
	flag4 = false
end

local function UpdateLoadoutTemplates()
	Profiler.mark("UI.Loadout.UpdateLoadoutTemplates")

	if not v29 then
		return
	end

	local container = v29.Container.List.Container
	local v32 = {}

	for _, v34 in ipairs(v14) do
		v32[v34] = true
	end

	for _, button in ipairs(container:GetChildren()) do
		if
			not button:IsA("ImageButton")
			or button.Name == "UIGridLayout"
			or button.Name == "UIPadding"
			or v32[button.Name]
		then
			continue
		end

		button:Destroy()
	end

	v15 = 0
	flag4 = true

	if v29.Visible then
		RenderInitialLoadoutTemplates()
	end
end

local function RefreshSortedList() -- 3 equivalent calls inferred from this helper
	if v29 and v29.Visible then
		v14 = GetSortedLoadoutItemIds()
		UpdateLoadoutTemplates()
	else
		flag5 = true
		flag4 = true
	end
end

local function AnimateSortButton(p, flag6: boolean) -- 4 equivalent calls inferred from this helper
	TweenService:Create(p, tweenInfo, {
		BackgroundTransparency = flag6 and 0.85 or 1
	}):Play()
end

local function FadeCategoryLabels(list, flag6: boolean)
	local tweenInfo2 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local textTransparency = flag6 and 0 or 1

	for _, frame in ipairs(list:GetChildren()) do
		if not (frame:IsA("Frame") and frame:FindFirstChild("Price") and frame:FindFirstChild("WeaponName")) then
			continue
		end

		local price = frame:FindFirstChild("Price")
		local weaponName = frame:FindFirstChild("WeaponName")
		TweenService:Create(price, tweenInfo2, { TextTransparency = textTransparency }):Play()
		TweenService:Create(weaponName, tweenInfo2, { TextTransparency = textTransparency }):Play()
	end
end

local function CloseAllDropdowns() -- 2 equivalent calls inferred from this helper
	local dropdownContent = v29.Container.List.Top.Filter.DropdownContent
	local dropdownContent2 = v29.Container.List.Top.Weapon.DropdownContent
	dropdownContent.Visible = false
	dropdownContent2.Visible = false
end

local function UpdateResetButtonVisibility() -- 5 equivalent calls inferred from this helper
	local reset = v29.Container.List.Top:FindFirstChild("Reset")

	if reset then
		local title = v29.Container.List.Top.Weapon.Container.Left.Title
		reset.Visible = kind ~= nil or v3 ~= nil or title.Text ~= "All Weapons"
	end
end

local function CreateDropdownOption(scroll, name2: string, text: string, layoutOrder: number, onMouseButton1Click)
	local sortingTemplate = ReplicatedStorage.Assets.UI.Loadout:FindFirstChild("SortingTemplate")

	if not sortingTemplate then
		return nil
	end

	local clone = sortingTemplate:Clone()
	clone.Name = name2
	clone.LayoutOrder = layoutOrder
	clone.BackgroundTransparency = 1
	clone.Parent = scroll
	local frame = clone:FindFirstChild("Frame")

	if frame then
		local textButton = frame:FindFirstChild("TextButton")

		if textButton then
			textButton.Text = text
		end

		frame.BackgroundTransparency = 1
		frame.Active = false
	end

	clone.MouseEnter:Connect(function()
		AnimateSortButton(clone, true) -- inferred equivalent call
	end)
	clone.MouseLeave:Connect(function()
		AnimateSortButton(clone, false) -- inferred equivalent call
	end)
	clone.MouseButton1Click:Connect(onMouseButton1Click)
	return clone
end

local function ClearDropdownOptions(scroll)
	for _, button in ipairs(scroll:GetChildren()) do
		if button:IsA("TextButton") then
			button:Destroy()
		end
	end
end

local function GetWeaponsInCategory(kind3: string?)
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not inventory then
		return {}
	end

	local v32 = {}

	for _, v34 in ipairs(inventory) do
		if v18[v34.Type] or v17[v34.Name] then
			continue
		end

		local success, result = pcall(GetWeaponProperties, v34.Name)

		if success and result and (not kind3 or result.Type == kind3) then
			v32[v34.Name] = true
		end
	end

	local result = {}

	for k in pairs(v32) do
		table.insert(result, k)
	end

	table.sort(result)
	return result
end

local function GetLoadoutCategoryForWeapon(p: string) -- 3 equivalent calls inferred from this helper
	local success, result = pcall(GetWeaponProperties, p)

	if success and result and result.Type then
		return v16[result.Type]
	end

	return nil
end

local function IsValidStarterPistol(name2: string, p) -- 2 equivalent calls inferred from this helper
	local v32 = v28[p]

	if v32 then
		return table.find(v32, name2) ~= nil
	end

	return false
end

local function IsMouseOverPlayerFrame(vector2: Vector2)
	local teams = v29.Container.Teams
	local guiObjectsAtPosition = PlayerGui:GetGuiObjectsAtPosition(vector2.X, vector2.Y)

	for _, v32 in ipairs(guiObjectsAtPosition) do
		if v32.Name ~= "DragIcon" and (v32 == teams or v32:IsDescendantOf(teams)) then
			return true
		end
	end

	return false
end

local function CreateDragIcon(data)
	local resolvedSkinInformation = GetResolvedSkinInformation(data.Name, data.Skin)

	if not resolvedSkinInformation then
		return nil
	end

	local image = Skins.GetWearImageForFloat(resolvedSkinInformation, data.Float or 0.9999)
		or resolvedSkinInformation.imageAssetId
		or ""
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "DragIcon"
	imageLabel.Size = udim
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = image
	imageLabel.ScaleType = Enum.ScaleType.Fit
	imageLabel.ZIndex = 100
	imageLabel.Active = false
	return imageLabel
end

local function CleanupPendingDrag() -- 6 equivalent calls inferred from this helper
	if connection2 then
		connection2:Disconnect()
		connection2 = nil
	end

	v6 = nil
	v7 = nil
	v8 = false
	v9 = nil
end

local v32 = {
	["Counter-Terrorists"] = Color3.fromHex("5B9BFF"),
	Terrorists = Color3.fromHex("E5B84C")
}
local tweenInfo2 = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local v34 = {}
local tweens = {}

local function AddDropOverlay(guiObject, flag6: boolean)
	if not (guiObject and guiObject:IsA("GuiObject")) then
		return
	end

	local frame = Instance.new("Frame")
	frame.Name = flag6 and "DropHighlight" or "DropDim"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BorderSizePixel = 0
	frame.Active = false
	frame.Selectable = false
	frame.Interactable = false
	frame.ZIndex = 50

	if flag6 then
		local v35 = v32[team2] or v32["Counter-Terrorists"]
		frame.BackgroundColor3 = v35
		frame.BackgroundTransparency = 0.85
		local uiStroke = Instance.new("UIStroke")
		uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		uiStroke.Color = v35
		uiStroke.Thickness = 2
		uiStroke.Parent = frame
		local tween = TweenService:Create(uiStroke, tweenInfo2, { Transparency = 0.6 })
		tween:Play()
		table.insert(tweens, tween)
	else
		frame.BackgroundColor3 = Color3.new(0, 0, 0)
		frame.BackgroundTransparency = 0.45
	end

	frame.Parent = guiObject
	table.insert(v34, frame)
end

local function HideAllMoveFrames()
	for _, v35 in tweens do
		v35:Cancel()
	end

	table.clear(tweens)

	for _, v35 in v34 do
		v35:Destroy()
	end

	table.clear(v34)
end

local function CleanupDrag()
	CleanupPendingDrag() -- inferred equivalent call

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if v5 then
		v5:Destroy()
		v5 = nil
	end

	local v35 = flag
	flag = false
	id = nil
	name = nil
	kind2 = nil
	HideAllMoveFrames()

	if v35 and not flag3 then
		Loadout.RefreshSelectedWeapon()
	end
end

local v35 = nil

local function ShowControllerClickShield()
	if v35 then
		return
	end

	local mainGui = PlayerGui:FindFirstChild("MainGui")
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadoutControllerClickShield"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = (not (mainGui and mainGui:IsA("ScreenGui")) and 0 or mainGui.DisplayOrder) + 1
	local textButton = Instance.new("TextButton")
	textButton.Name = "Sink"
	textButton.Text = ""
	textButton.BackgroundTransparency = 1
	textButton.AutoButtonColor = false
	textButton.Selectable = false
	textButton.Active = true
	textButton.Size = UDim2.fromScale(1, 1)
	textButton.Parent = screenGui
	screenGui.Parent = PlayerGui
	v35 = screenGui
end

local function HideControllerClickShield() -- 13 equivalent calls inferred from this helper
	local v36 = v35

	if not v36 then
		return
	end

	task.delay(0.25, function()
		if v35 == v36 and not flag2 then
			v35 = nil
			v36:Destroy()
		end
	end)
end

local function EnableVirtualCursor(button) -- 1 equivalent call inferred from this helper
	if flag2 then
		return
	end

	flag2 = true
	GuiService.AutoSelectGuiEnabled = false
	GuiService.SelectedObject = nil

	if button then
		GamepadNavigation.ScrollIntoView(button)
	end

	pcall(function()
		GamepadService:EnableGamepadCursor(button)
	end)
	ShowControllerClickShield()
end

local function DisableVirtualCursor()
	if not flag2 then
		return
	end

	flag2 = false
	pcall(function()
		GamepadService:DisableGamepadCursor()
	end)
	GuiService.AutoSelectGuiEnabled = true
	HideControllerClickShield() -- inferred equivalent call
end

local function CleanupControllerHeld(flag6: boolean?)
	local selectedObject = v12
	CleanupDrag()
	id2 = nil
	v12 = nil
	v11 = false

	if flag2 then
		flag2 = false
		pcall(function()
			GamepadService:DisableGamepadCursor()
		end)
		GuiService.AutoSelectGuiEnabled = true
		HideControllerClickShield() -- inferred equivalent call
	end

	HideAllMoveFrames()

	if flag6 and selectedObject and GamepadNavigation.IsUsable(selectedObject) then
		GamepadNavigation.ScrollIntoView(selectedObject)
		GuiService.SelectedObject = selectedObject
	end
end

local function GetSlotIndexInList(p, instance, p2: string)
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	local v36 = loadout and loadout[team2]
	local v37 = v36 and v36.Loadout and v36.Loadout[p2]

	if v37 then
		for i, option in ipairs(v37.Options) do
			if option == p.Name then
				return i
			end
		end
	end

	local count2 = 0

	for _, guiObject in ipairs(instance:GetChildren()) do
		if not guiObject:IsA("GuiObject") then
			continue
		end

		count2 += 1

		if guiObject == p then
			return count2
		end
	end

	return 1
end

local function GetLoadoutSlotInfo(p)
	local parent = p.Parent

	if not (parent and parent:IsA("Frame")) then
		return nil, nil
	end

	local parent2 = parent.Parent
	local parent3

	if parent2 then
		if parent2.Name == "List" then
			parent3 = parent2.Parent
		else
			parent3 = false
		end
	else
		parent3 = parent2
	end

	if not (parent3 and parent3:IsA("Frame")) then
		return nil, nil
	end

	local name2 = parent3.Name

	if name2 == "Mid Tier" or name2 == "Pistols" or name2 == "Rifles" then
		return name2, (GetSlotIndexInList(parent, parent2, name2))
	end

	return nil, nil
end

local function GetInventoryItemFromButton(button) -- 2 equivalent calls inferred from this helper
	if button and button:IsA("ImageButton") then
		return (GetInventoryItemFromIdentifier(button.Name))
	end

	return nil
end

local function GetEquippedItemFromButton(p)
	local parent = p.Parent

	if parent and parent:IsA("Frame") then
		local name2 = parent.Name
		local v36, v37 = GetLoadoutSlotInfo(p)

		if v36 and v37 then
			return GetInventoryItemFromIdentifier(name2), v36, v37
		end
	end

	return nil, nil, nil
end

local v36 = { "Pistols", "Mid Tier", "Rifles" }

local function ShowGunSlotHighlights(fn)
	local guns = GetTeamFrame(team2 == "Counter-Terrorists" and "CT" or "T"):FindFirstChild("Guns") -- inferred equivalent call

	if not guns then
		return
	end

	for _, childName in v36 do
		local child = guns:FindFirstChild(childName)
		local list = child and child:FindFirstChild("List")

		if not (child and list) then
			continue
		end

		local v38 = false

		for _, frame in list:GetChildren() do
			if not (frame:IsA("Frame") and frame:FindFirstChild("Button")) then
				continue
			end

			local v39 = fn(childName, (GetSlotIndexInList(frame, list, childName)))
			AddDropOverlay(frame, v39)
			v38 = v38 or v39
		end

		AddDropOverlay(child:FindFirstChild("Title"), v38)
	end
end

local function GetEquipmentSlotForItem(p)
	local v37 = v19[p.Type]

	if not v37 then
		local success, result = pcall(GetWeaponProperties, p.Name)
		local class = success and result and result.Class
		v37 = class == "Melee" and "Equipped Melee" or class == "Glove" and "Equipped Gloves" or nil
	end

	local v38 = v37 and v20[v37]

	if not v38 then
		return nil
	end

	local equipments = GetTeamFrame(team2 == "Counter-Terrorists" and "CT" or "T"):FindFirstChild("Equipments") -- inferred equivalent call
	local guiObject = equipments and equipments:FindFirstChild(v38)

	if guiObject and guiObject:IsA("GuiObject") then
		return guiObject
	end

	return nil
end

local function ShowMoveFramesForItem(data)
	HideAllMoveFrames()
	local parent = GetEquipmentSlotForItem(data)

	if v19[data.Type] ~= nil or parent ~= nil then
		AddDropOverlay(parent, true)
		AddDropOverlay(GetTeamFrame(team2 == "Counter-Terrorists" and "CT" or "T"):FindFirstChild("Viewport"), true) -- inferred equivalent call
		ShowGunSlotHighlights(function()
			return false
		end)
	else
		local loadoutCategoryForWeapon = GetLoadoutCategoryForWeapon(data.Name) -- inferred equivalent call

		if not loadoutCategoryForWeapon then
			return
		end

		local name2 = data.Name
		local v39 = team2
		local success

		if name2 and type(name2) == "string" and name2 ~= "" then
			local result
			success, result = pcall(GetWeaponProperties, name2)

			if success then
				if result == nil or result.Team == nil then
					success = false
				else
					success = result.Team == "Both" or result.Team == v39
				end
			end
		else
			success = false
		end

		local validStarterPistol = IsValidStarterPistol(data.Name, team2) -- inferred equivalent call
		ShowGunSlotHighlights(function(p: string, p2: number)
			return not not success
				and p == loadoutCategoryForWeapon
				and (p ~= "Pistols" or p2 ~= 1 or not not validStarterPistol)
		end)
	end
end

local fn

local function GetDropTargetCategory(vector2: Vector2)
	local v37 = id2 and GetInventoryItemFromIdentifier(id2)
	local v38 = name or v37 and v37.Name

	if not v38 then
		return nil, nil
	end

	local loadoutCategoryForWeapon = GetLoadoutCategoryForWeapon(v38) -- inferred equivalent call

	if not loadoutCategoryForWeapon then
		return nil, nil
	end

	local teams = v29.Container.Teams
	local guiObjectsAtPosition = PlayerGui:GetGuiObjectsAtPosition(vector2.X, vector2.Y)
	local v40 = nil
	local v41 = false

	for _, v42 in ipairs(guiObjectsAtPosition) do
		if v42.Name == "DragIcon" then
			continue
		end

		v41 = (v42 == teams or v42:IsDescendantOf(teams)) and true or v41

		if v40 then
			continue
		end

		while v42 and v42 ~= teams do
			local parent = v42.Parent

			if parent and parent.Name == "List" then
				local parent2 = parent.Parent

				if not parent2 or parent2.Name ~= loadoutCategoryForWeapon then
					break
				end

				v40 = GetSlotIndexInList(v42, parent, loadoutCategoryForWeapon)
				break
			else
				v42 = parent
			end
		end
	end

	if v41 then
		return loadoutCategoryForWeapon, v40
	end

	return nil, nil
end

local function GetCurrentCategoryOptions(p: string) -- 4 equivalent calls inferred from this helper
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	local v37 = loadout and loadout[team2]

	if v37 and v37.Loadout and v37.Loadout[p] then
		return v37.Loadout[p].Options
	end

	return nil
end

local function IsItemEquippedInCategory(id4: string, p: string)
	local currentCategoryOptions = GetCurrentCategoryOptions(p) -- inferred equivalent call

	for k, v38 in ipairs(currentCategoryOptions or {}) do
		if v38 == id4 then
			return true, k
		end
	end

	return false, nil
end

local function IsWeaponEquippedInCategory(name2: string, p: string)
	local currentCategoryOptions = GetCurrentCategoryOptions(p) -- inferred equivalent call

	if not currentCategoryOptions then
		return false, nil, nil
	end

	for i, v38 in ipairs(currentCategoryOptions) do
		if not (v38 and v38 ~= "") then
			continue
		end

		local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(v38)

		if inventoryItemFromIdentifier and inventoryItemFromIdentifier.Name == name2 then
			return true, i, v38
		end
	end

	return false, nil, nil
end

local function RefreshSelectedWeaponIfIdle() -- 2 equivalent calls inferred from this helper
	if not (flag or id2) then
		Loadout.RefreshSelectedWeapon()
	end
end

local function SendEquipRequest(p, p2) -- 3 equivalent calls inferred from this helper
	if flag3 then
		return false
	end

	flag3 = true
	count += 1
	local v37 = count
	p.Send(p2)
	task.delay(5, function()
		if v37 ~= count or not flag3 then
			return
		end

		flag3 = false
		RefreshSelectedWeaponIfIdle() -- inferred equivalent call
	end)
	return true
end

local function EquipLoadoutSkin(p: string, p2: number, id4: string) -- 2 equivalent calls inferred from this helper
	return SendEquipRequest(Remotes.Inventory.EquipLoadoutSkin, { -- inferred equivalent call
		Type = p,
		Slot = p2 - 1,
		Team = team2,
		Identifier = id4
	})
end

local function SwapLoadoutSkins(p: string, p2: number, p3: number) -- 1 equivalent call inferred from this helper
	return SendEquipRequest(Remotes.Inventory.SwapLoadoutSkins, { -- inferred equivalent call
		Type = p,
		SlotOne = p2 - 1,
		SlotTwo = p3 - 1,
		Team = team2
	})
end

local function EquipSpecialItem(path: string, id4: string) -- 1 equivalent call inferred from this helper
	return SendEquipRequest(Remotes.Inventory.EquipSpecialItem, { -- inferred equivalent call
		Path = path,
		Team = team2,
		Identifier = id4
	})
end

local function GetSpecialItemPathByClass(name2: string) -- 1 equivalent call inferred from this helper
	local success, result = pcall(GetWeaponProperties, name2)
	local class = success and result and result.Class

	if class == "Melee" then
		return "Equipped Melee"
	elseif class == "Glove" then
		return "Equipped Gloves"
	end

	return nil
end

local function fn2()
	if not (v29 and v29.Visible) then
		return
	end

	if id2 then
		local selectedObject = v12
		CleanupDrag()
		id2 = nil
		v12 = nil
		v11 = false

		if flag2 then
			flag2 = false
			pcall(function()
				GamepadService:DisableGamepadCursor()
			end)
			GuiService.AutoSelectGuiEnabled = true
			HideControllerClickShield() -- inferred equivalent call
		end

		HideAllMoveFrames()

		if selectedObject and GamepadNavigation.IsUsable(selectedObject) then
			GamepadNavigation.ScrollIntoView(selectedObject)
			GuiService.SelectedObject = selectedObject
		end

		CloseButtonRegistry.MarkUsed()
	end
end

local function ConnectGamepadPickUp(p) -- 2 equivalent calls inferred from this helper
	p.Activated:Connect(function(p2)
		if
			p2
			and p2.UserInputType == Enum.UserInputType.Gamepad1
			and not id2
			and not flag3
			and os.clock() - now2 > 0.25
		then
			fn(p)
		end
	end)
end

local function ConnectButtonActivation(p, onMouseButton1Click) -- 7 equivalent calls inferred from this helper
	p.MouseButton1Click:Connect(onMouseButton1Click)
	p.Activated:Connect(function(p2)
		if p2 and p2.UserInputType == Enum.UserInputType.Gamepad1 then
			onMouseButton1Click()
		end
	end)
end

function Loadout.HandleSpecialItemDrop()
	if not (id and kind2) then
		return
	end

	local v37 = v19[kind2]

	if not v37 and name then
		v37 = GetSpecialItemPathByClass(name) -- inferred equivalent call
	end

	if not v37 then
		return
	end

	EquipSpecialItem(v37, id) -- inferred equivalent call
end

function Loadout.HandleDrop(p: string, p2: number?)
	if not (id and name) then
		return
	end

	local v37 = name
	local v38 = team2
	local success

	if v37 and type(v37) == "string" and v37 ~= "" then
		local result
		success, result = pcall(GetWeaponProperties, v37)

		if success then
			if result == nil or result.Team == nil then
				success = false
			else
				success = result.Team == "Both" or result.Team == v38
			end
		end
	else
		success = false
	end

	if not (success and GetLoadoutCategoryForWeapon(name) == p) then -- inferred equivalent call
		return
	end

	local currentCategoryOptions = GetCurrentCategoryOptions(p) -- inferred equivalent call

	if not currentCategoryOptions then
		return
	end

	local v40

	if p == "Pistols" then
		v40 = IsValidStarterPistol(name, team2) and 1 or 2 -- inferred equivalent call
	else
		v40 = 1
	end

	local v41, v42 = IsItemEquippedInCategory(id, p)

	if v41 and v42 then
		if p2 and v40 <= p2 and p2 <= #currentCategoryOptions and v42 ~= p2 then
			SwapLoadoutSkins(p, v42, p2) -- inferred equivalent call
		end
	else
		local v43, v44 = IsWeaponEquippedInCategory(name, p)

		if v43 and v44 then
			EquipLoadoutSkin(p, v44, id) -- inferred equivalent call
		else
			if p2 and p2 < v40 then
				return
			end

			if v40 <= #currentCategoryOptions then
				v40 = math.clamp(p2 or v40, v40, #currentCategoryOptions)
			end

			EquipLoadoutSkin(p, v40, id) -- inferred equivalent call
		end
	end
end

local function StartItemDrag(data)
	local dragIcon = CreateDragIcon(data)

	if not dragIcon then
		return false
	end

	flag = true
	v5 = dragIcon
	id = data._id
	name = data.Name
	kind2 = data.Type
	ShowMoveFramesForItem(data)
	Loadout.SetSelectedWeapon(data, true)
	dragIcon.Parent = PlayerGui:FindFirstChild("MainGui") or PlayerGui
	local mouseLocation = UserInputService:GetMouseLocation()
	dragIcon.Position = UDim2.fromOffset(mouseLocation.X + vector.X, mouseLocation.Y + vector.Y)
	connection = RunServiceController.BindToRenderStep("UI.Loadout.DragIcon", function()
		if v5 then
			local mouseLocation2 = UserInputService:GetMouseLocation()
			v5.Position = UDim2.fromOffset(mouseLocation2.X + vector.X, mouseLocation2.Y + vector.Y)
		end
	end)
	return true
end

local function BeginActualDrag(p)
	CleanupPendingDrag() -- inferred equivalent call

	if flag or id2 then
		return
	end

	StartItemDrag(p)
end

function Loadout.OnItemMouseDown(p: string, flag6: boolean?, p2)
	local mouseLocation = UserInputService:GetMouseLocation()

	if id2 or os.clock() - now2 < 0.25 or (flag or v6) then
		return
	end

	v6 = p
	v7 = mouseLocation
	v8 = flag6 or false
	v9 = p2
	connection2 = RunServiceController.BindToRenderStep("UI.Loadout.PendingDrag", function()
		if v6 and v7 then
			if id2 then
				CleanupPendingDrag() -- inferred equivalent call
			elseif (UserInputService:GetMouseLocation() - v7).Magnitude >= 10 then
				local v37 = v6
				CleanupPendingDrag() -- inferred equivalent call
				local v38 = v37 and GetInventoryItemFromIdentifier(v37)

				if v38 then
					CleanupPendingDrag() -- inferred equivalent call

					if not flag then
						if id2 then
							return
						else
							StartItemDrag(v38)
						end
					end
				end
			end
		end
	end)
end

function Loadout.OnItemClick(p)
	v3 = nil
	Loadout.SortByWeapon(p.Name)
end

local function DropDraggedItem()
	local mouseLocation = UserInputService:GetMouseLocation()
	local guiInset = GuiService:GetGuiInset()
	local vector2 = Vector2.new(mouseLocation.X - guiInset.X, mouseLocation.Y - guiInset.Y)
	local v37 = kind2 and v19[kind2]

	if not v37 and name then
		local success, result = pcall(GetWeaponProperties, name)
		v37 = success and result and (result.Class == "Melee" or result.Class == "Glove") and true or v37
	end

	if v37 and IsMouseOverPlayerFrame(vector2) then
		Loadout.HandleSpecialItemDrop()
	elseif not v37 then
		local v38, v39 = GetDropTargetCategory(vector2)

		if v38 then
			Loadout.HandleDrop(v38, v39)
		end
	end
end

function Loadout.EndDrag()
	if v6 and not flag then
		local v37 = v6
		local v38 = v8
		local v39 = v9
		local mouseLocation = UserInputService:GetMouseLocation()
		CleanupPendingDrag() -- inferred equivalent call
		local v40 = v37 and GetInventoryItemFromIdentifier(v37)

		if not v40 then
			return
		end

		if v38 then
			Loadout.OnItemClick(v40)
		else
			ShowContextMenu(v40, mouseLocation, v39, false)
		end
	else
		if not flag then
			return
		end

		DropDraggedItem()
		CleanupDrag()
	end
end

fn = function(button)
	CleanupDrag()
	local inventoryItemFromButton = GetInventoryItemFromButton(button) -- inferred equivalent call

	if not inventoryItemFromButton then
		local parent = button.Parent

		if parent and parent:IsA("Frame") then
			local name2 = parent.Name
			local v38, v39 = GetLoadoutSlotInfo(button)

			if v38 and v39 then
				inventoryItemFromButton = GetInventoryItemFromIdentifier(name2)
			else
				inventoryItemFromButton = nil
			end
		else
			inventoryItemFromButton = nil
		end
	end

	if not inventoryItemFromButton then
		return
	end

	id2 = inventoryItemFromButton._id
	v12 = button
	now = os.clock()
	v11 = false
	EnableVirtualCursor(button) -- inferred equivalent call

	if not StartItemDrag(inventoryItemFromButton) then
		local selectedObject = v12
		CleanupDrag()
		id2 = nil
		v12 = nil
		v11 = false

		if flag2 then
			flag2 = false
			pcall(function()
				GamepadService:DisableGamepadCursor()
			end)
			GuiService.AutoSelectGuiEnabled = true
			HideControllerClickShield() -- inferred equivalent call
		end

		HideAllMoveFrames()

		if selectedObject and GamepadNavigation.IsUsable(selectedObject) then
			GamepadNavigation.ScrollIntoView(selectedObject)
			GuiService.SelectedObject = selectedObject
		end
	end
end

local function fn3()
	now2 = os.clock()

	if flag then
		DropDraggedItem()
	end

	local selectedObject = v12
	CleanupDrag()
	id2 = nil
	v12 = nil
	v11 = false

	if flag2 then
		flag2 = false
		pcall(function()
			GamepadService:DisableGamepadCursor()
		end)
		GuiService.AutoSelectGuiEnabled = true
		HideControllerClickShield() -- inferred equivalent call
	end

	HideAllMoveFrames()

	if selectedObject and GamepadNavigation.IsUsable(selectedObject) then
		GamepadNavigation.ScrollIntoView(selectedObject)
		GuiService.SelectedObject = selectedObject
	end
end

local function InspectInventoryItem(data)
	if not CanInspectItem(data) then -- inferred equivalent call
		return
	end

	Router.broadcastRouter("RunInterfaceSound", "UI Click")
	HideContextMenu() -- inferred equivalent call
	Router.broadcastRouter(
		"WeaponInspect",
		data.Name,
		data.Skin,
		data.Float,
		data.StatTrack,
		data.NameTag,
		data.Charm,
		data.Stickers,
		data.Type,
		data.Pattern,
		data._id,
		data.Serial,
		data.IsTradeable
	)
end

function Loadout:CreateItemTemplate()
	Profiler.mark("UI.Loadout.CreateItemTemplate")
	local _id = self._id
	local resolvedSkinInformation = GetResolvedSkinInformation(self.Name, self.Skin)

	if resolvedSkinInformation then
		local clone = ReplicatedStorage.Assets.UI.Loadout.ItemTemplate:Clone()
		clone.ItemContent.Rarity.BackgroundColor3 = Rarities[resolvedSkinInformation.rarity].Color
		clone.Parent = v29.Container.List.Container
		local image = Skins.GetWearImageForFloat(resolvedSkinInformation, self.Float or 0.9999)
			or resolvedSkinInformation.imageAssetId
			or ""
		clone.ItemContent.Content.Icon.Image = image
		local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(self.Name, self.NameTag)

		if self.StatTrack then
			weaponDisplayName = "KillTrak™ " .. weaponDisplayName or weaponDisplayName
		end

		if self.Type == "Melee" then
			weaponDisplayName = "★ " .. weaponDisplayName
		end

		GetSkinDisplayName.ApplyNameLabel(clone.Bottom.Footer.WeaponName, weaponDisplayName, self.NameTag)
		clone.Bottom.Footer.SkinName.Text = GetSkinDisplayName(self.Skin)
		clone.Name = _id
		local icon = clone.ItemContent.Content.Icon
		local iconDropShadow = ItemIcon.CreateIconDropShadow(
			icon,
			ItemIcon.GetDropShadowImageForItem(self, image),
			clone.ItemContent.Content
		)
		local iconHoverTweens, v39 = ItemIcon.CreateIconHoverTweens(icon, iconDropShadow)
		clone.MouseEnter:Connect(iconHoverTweens)
		clone.MouseLeave:Connect(v39)
		clone.MouseButton1Down:Connect(function()
			Loadout.OnItemMouseDown(_id, false, clone)
		end)
		clone.MouseButton2Click:Connect(function()
			local mouseLocation = UserInputService:GetMouseLocation()
			local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(_id)

			if inventoryItemFromIdentifier then
				ShowContextMenu(inventoryItemFromIdentifier, mouseLocation, clone, false)
			end
		end)
		clone.Selectable = true
		clone.SelectionGained:Connect(iconHoverTweens)
		clone.SelectionLost:Connect(v39)
		ConnectGamepadPickUp(clone) -- inferred equivalent call
		UpdateStatusFrame(clone, _id)
	end
end

function Loadout.CreateLoadoutTemplate(parent, data, p)
	Profiler.mark("UI.Loadout.CreateLoadoutTemplate")
	local _id = data._id
	local resolvedSkinInformation = GetResolvedSkinInformation(data.Name, data.Skin)
	local success, result = pcall(GetWeaponProperties, data.Name)
	local cost = success and result and result.Cost or 0

	if resolvedSkinInformation then
		local v38 = p == "Counter-Terrorists" and "LoadoutTemplateCT" or "LoadoutTemplateT"
		local clone = ReplicatedStorage.Assets.UI.Loadout:FindFirstChild(v38):Clone()
		clone.Rarity.BackgroundColor3 = Rarities[resolvedSkinInformation.rarity].Color
		clone.Parent = parent
		clone.Name = _id
		local image = Skins.GetWearImageForFloat(resolvedSkinInformation, data.Float or 0.9999)
			or resolvedSkinInformation.imageAssetId
			or ""
		clone.Content.Footer.Cost.Text = "$" .. tostring(cost)
		GetSkinDisplayName.ApplyNameLabel(
			clone.Content.Footer.Frame.WeaponName,
			GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag),
			data.NameTag
		)
		local skinName = clone.Content.Footer.Frame.SkinName
		skinName.Text = GetSkinDisplayName(data.Skin)
		local rarity = Rarities[resolvedSkinInformation.rarity]

		if rarity then
			local textColor

			if resolvedSkinInformation.rarity == "Forbidden" then
				textColor = Color3.fromRGB(200, 60, 60)
			else
				textColor = rarity.Color
			end

			skinName.TextColor3 = textColor
		end

		clone.Content.Icon.Image = image
		local icon = clone.Content.Icon
		local iconDropShadow = ItemIcon.CreateIconDropShadow(
			icon,
			ItemIcon.GetDropShadowImageForItem(data, image),
			clone.Content
		)
		local iconHoverTweens, v40 = ItemIcon.CreateIconHoverTweens(icon, iconDropShadow)
		clone.Button.MouseEnter:Connect(iconHoverTweens)
		clone.Button.MouseLeave:Connect(v40)
		clone.Button.MouseButton1Down:Connect(function()
			Loadout.OnItemMouseDown(_id, true, clone)
		end)
		clone.Button.MouseButton2Click:Connect(function()
			local mouseLocation = UserInputService:GetMouseLocation()
			local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(_id)

			if inventoryItemFromIdentifier then
				ShowContextMenu(inventoryItemFromIdentifier, mouseLocation, clone, false)
			end
		end)
		local uiStroke = clone:FindFirstChildOfClass("UIStroke")
		local color = uiStroke and uiStroke.Color
		local color2 = v32[p] or v32["Counter-Terrorists"]

		local function setCardLit(flag6: boolean)
			if flag6 and (flag or id2) then
				return
			end

			if uiStroke and color then
				local v42 = uiStroke
				local color3

				if flag6 then
					color3 = color2
				else
					color3 = color
				end

				v42.Color = color3
			end
		end

		clone.Button.MouseEnter:Connect(function()
			local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(_id)

			if inventoryItemFromIdentifier then
				Loadout.OnLoadoutItemHover(inventoryItemFromIdentifier)
			end

			if not flag then
				if id2 then
					return
				end

				if uiStroke and color then
					uiStroke.Color = color2
				end
			end
		end)
		clone.Button.MouseLeave:Connect(function()
			if uiStroke and color then
				uiStroke.Color = color
			end
		end)
		clone.Button.Selectable = true
		clone.Button.SelectionGained:Connect(function()
			local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(_id)

			if inventoryItemFromIdentifier then
				Loadout.OnLoadoutItemHover(inventoryItemFromIdentifier)
			end

			iconHoverTweens()

			if not flag then
				if id2 then
					return
				end

				if uiStroke and color then
					uiStroke.Color = color2
				end
			end
		end)
		clone.Button.SelectionLost:Connect(function()
			v40()

			if uiStroke and color then
				uiStroke.Color = color
			end
		end)
		ConnectGamepadPickUp(clone.Button) -- inferred equivalent call
		local inspect = clone:FindFirstChild("Inspect")

		if inspect and inspect:IsA("GuiButton") then
			local function fn4()
				if flag or id2 or os.clock() - now2 < 0.25 then
					return
				end

				local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(_id)

				if inventoryItemFromIdentifier then
					InspectInventoryItem(inventoryItemFromIdentifier)
				end
			end

			ConnectButtonActivation(inspect, fn4) -- inferred equivalent call
		end
	end
end

function Loadout.PopulateWeaponDropdown()
	local scroll = v29.Container.List.Top.Weapon.DropdownContent.Scroll

	if not (scroll and (scroll:IsA("Frame") or scroll:IsA("ScrollingFrame"))) then
		return
	end

	ClearDropdownOptions(scroll)
	CreateDropdownOption(scroll, "All", "All Weapons", 0, function()
		Loadout.SortByWeapon(nil)
		scroll.Parent.Visible = false
	end)
	local weaponsInCategory = GetWeaponsInCategory(kind)

	for i, v38 in ipairs(weaponsInCategory) do
		local v39 = v38
		CreateDropdownOption(scroll, v38, v38, i, function()
			Loadout.SortByWeapon(v39)
			scroll.Parent.Visible = false
		end)
	end
end

function Loadout.SortByCategory(value: string?)
	kind = value
	v4 = nil
	v3 = nil
	v29.Container.List.Top.Filter.Container.Left.Title.Text = value or "All Categories"
	Loadout.PopulateWeaponDropdown()
	v29.Container.List.Top.Weapon.Container.Left.Title.Text = "All Weapons"
	UpdateResetButtonVisibility() -- inferred equivalent call
	RefreshSortedList() -- inferred equivalent call
end

function Loadout.SortByWeapon(weaponName: string?, skinName: string?)
	local v37

	if weaponName then
		v37 = { weaponName = weaponName, skinName = skinName } or nil
	end

	v4 = v37
	v3 = nil
	v29.Container.List.Top.Weapon.Container.Left.Title.Text = weaponName or "All Weapons"

	if Sort.GetSortComparisonFunction(v, LocalPlayer, function()
		return v31
	end) then
		RefreshSortedList() -- inferred equivalent call
	end

	UpdateResetButtonVisibility() -- inferred equivalent call
end

function Loadout.SortBySkinMetadata(text: string)
	Profiler.mark("UI.Loadout.SortBySkinMetadata")
	v = text
	v29.Container.List.Top.Filter.Container.Left.Title.Text = text

	if Sort.GetSortComparisonFunction(text, LocalPlayer, function()
		return v31
	end) then
		RefreshSortedList() -- inferred equivalent call
	end
end

function Loadout.UpdateInventoryContainer()
	Profiler.mark("UI.Loadout.UpdateInventoryContainer")

	if not v29 then
		return
	end

	if v29.Visible then
		if id2 and not GetInventoryItemFromIdentifier(id2) then
			local selectedObject = v12
			CleanupDrag()
			id2 = nil
			v12 = nil
			v11 = false

			if flag2 then
				flag2 = false
				pcall(function()
					GamepadService:DisableGamepadCursor()
				end)
				GuiService.AutoSelectGuiEnabled = true
				HideControllerClickShield() -- inferred equivalent call
			end

			HideAllMoveFrames()

			if selectedObject and GamepadNavigation.IsUsable(selectedObject) then
				GamepadNavigation.ScrollIntoView(selectedObject)
				GuiService.SelectedObject = selectedObject
			end
		end

		local inventory = DataController.Get(LocalPlayer, "Inventory")
		local v37 = {}

		for _, v38 in ipairs(inventory) do
			if v38 and v38._id then
				v37[v38._id] = true
			end
		end

		if id3 and not v37[id3] then
			HideContextMenu() -- inferred equivalent call
		end

		local container = v29.Container.List.Container

		for _, button in ipairs(container:GetChildren()) do
			if
				not button:IsA("ImageButton")
				or button.Name == "UIGridLayout"
				or button.Name == "UIPadding"
				or v37[button.Name]
			then
				continue
			end

			button:Destroy()
		end

		Loadout.PopulateWeaponDropdown()
		Loadout.SortBySkinMetadata(v)
	else
		flag5 = true
		flag4 = true
	end
end

function Loadout.UpdateLoadoutContainer(p)
	Profiler.mark("UI.Loadout.UpdateLoadoutContainer")
	local selectedObject2 = v12
	CleanupDrag()
	id2 = nil
	v12 = nil
	v11 = false

	if flag2 then
		flag2 = false
		pcall(function()
			GamepadService:DisableGamepadCursor()
		end)
		GuiService.AutoSelectGuiEnabled = true
		HideControllerClickShield() -- inferred equivalent call
	end

	HideAllMoveFrames()

	if selectedObject2 and GamepadNavigation.IsUsable(selectedObject2) then
		GamepadNavigation.ScrollIntoView(selectedObject2)
		GuiService.SelectedObject = selectedObject2
	end

	local guns = GetTeamFrame(team2 == "Counter-Terrorists" and "CT" or "T"):FindFirstChild("Guns") -- inferred equivalent call
	local selectedObject = GuiService.SelectedObject
	local v39 = nil
	local name2 = nil

	for _, childName in ipairs({ "Mid Tier", "Pistols", "Rifles" }) do
		local list = guns:FindFirstChild(childName).List

		if not (selectedObject and selectedObject:IsDescendantOf(list)) then
			continue
		end

		while selectedObject.Parent and selectedObject.Parent ~= list do
			selectedObject = selectedObject.Parent
		end

		name2 = selectedObject.Name
		v39 = childName
		break
	end

	for _, childName in ipairs({ "Mid Tier", "Pistols", "Rifles" }) do
		local list = guns:FindFirstChild(childName).List
		ClearFrame(list, { "UIListLayout", "Frame" })
		local v41 = p[team2]
		assert(v41, `[Loadout] Failed to get player team loadout for {team2}`)
		local options = v41.Loadout[childName].Options
		local count2 = 0

		for _, option in ipairs(options) do
			local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(option)

			if not inventoryItemFromIdentifier then
				continue
			end

			Loadout.CreateLoadoutTemplate(list, inventoryItemFromIdentifier, team2)

			if list:FindFirstChild(inventoryItemFromIdentifier._id) then
				count2 += 1
			end
		end

		local title = guns:FindFirstChild(childName):FindFirstChild("Title")
		local count3 = title and title:FindFirstChild("Count")

		if count3 and count3:IsA("TextLabel") then
			count3.Text = `{count2} {count2 == 1 and "ITEM" or "ITEMS"}`
		end
	end

	Loadout.RefreshSelectedWeapon()

	if v39 then
		local list = guns:FindFirstChild(v39).List
		task.defer(function()
			if GuiService.SelectedObject ~= nil and GamepadNavigation.IsUsable(GuiService.SelectedObject) then
				return
			end

			local child = name2 and list:FindFirstChild(name2)
			local button = child and child:FindFirstChild("Button")

			if not button then
				for _, frame in list:GetChildren() do
					button = frame:IsA("Frame") and frame:FindFirstChild("Button") or nil

					if button then
						break
					end
				end
			end

			if button and button:IsA("GuiObject") and GamepadNavigation.IsUsable(button) then
				GuiService.SelectedObject = button
			end
		end)
	end
end

function Loadout.UpdateSidebarFrames(p, p2)
	Profiler.mark("UI.Loadout.UpdateSidebarFrames")
	local v37 = p2 or team2
	local equipments = GetTeamFrame(v37 == "Counter-Terrorists" and "CT" or "T"):FindFirstChild("Equipments") -- inferred equivalent call

	if not equipments then
		return
	end

	local v39 = p[v37]

	if not (v39 and v39.Equipped) then
		return
	end

	for k, childName in pairs(v20) do
		local v40 = v39.Equipped[k]
		local child = equipments:FindFirstChild(childName)

		if not child then
			continue
		end

		local v41 = nil
		local v42 = false

		if v40 and v40 ~= "" then
			local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(v40)

			if inventoryItemFromIdentifier then
				local resolvedSkinInformation = GetResolvedSkinInformation(
					inventoryItemFromIdentifier.Name,
					inventoryItemFromIdentifier.Skin
				)

				if resolvedSkinInformation then
					local image = Skins.GetWearImageForFloat(
							resolvedSkinInformation,
							inventoryItemFromIdentifier.Float or 0.9999
						)
						or resolvedSkinInformation.imageAssetId
						or ""
					child.Container.Icon.Image = image
					child.Container.Icon.Visible = true
					child.Rarity.BackgroundColor3 = Rarities[resolvedSkinInformation.rarity].Color
					child.Rarity.Visible = true
					v41 = inventoryItemFromIdentifier
					v42 = true
				else
					v41 = inventoryItemFromIdentifier
				end
			end
		end

		if not v42 then
			child.Container.Icon.Visible = false
			child.Rarity.Visible = false
		end

		child:SetAttribute("EquippedItemId", v41 and v41._id)
		child:SetAttribute("SidebarName", childName)
		child:SetAttribute("TeamKey", v37 == "Counter-Terrorists" and "CT" or "T")
	end
end

local ids = {}
local color = Color3.fromRGB(200, 60, 60)
local v37 = {
	Glove = "Gloves",
	Melee = "Knife",
	Badge = "Badge",
	["Music Kit"] = "Music Kit",
	Graffiti = "Spray",
	["Zeus x27"] = "Zeus"
}
local v38 = {
	RIFLE = "Rifle",
	SNIPER = "Sniper",
	SMG = "SMG",
	PISTOL = "Pistol",
	HEAVY = "Heavy",
	MELEE = "Knife"
}

local function GetCurrentTeamKey() -- 2 equivalent calls inferred from this helper
	if team2 == "Counter-Terrorists" then
		return "CT"
	end

	return "T"
end

local function ComputeWeaponStats(result)
	if type(result) ~= "table" or type(result.Spread) ~= "table" or type(result.DamagePerPart) ~= "table" then
		return nil
	end

	local primary = result.FireModes and result.FireModes.Primary
	local fireRate = primary and primary.FireRate or result.FireRate
	local spread = primary and primary.Spread or result.Spread
	local torso = result.DamagePerPart.Torso

	if type(fireRate) ~= "number" or fireRate <= 0 or type(torso) ~= "number" or type(result.WalkSpeed) ~= "number" then
		return nil
	end

	local bulletsPerShot = result.BulletsPerShot or 1
	local v39 = torso * (not (bulletsPerShot > 1) and 1 or bulletsPerShot * 0.35)
	local v40 = not spread.Range and 0 or spread.Range.Min or 0
	local perShot = spread.PerShot or 0
	local result2 = {
		Damage = math.sqrt((math.clamp(v39 / 143, 0, 1))) * 100,
		FireRate = math.clamp(60 / fireRate / 900, 0, 1) * 100,
		Accuracy = 100 / (1 + v40 * 0.6 + perShot * 0.1),
		Mobility = math.clamp((result.WalkSpeed - 10) / 10.2, 0, 1) * 100
	}

	for k, v41 in result2 do
		result2[k] = math.max(math.round(v41), 4)
	end

	return result2
end

local function PaintWeaponDetails(childName: string, data)
	local viewport = GetTeamFrame(childName):FindFirstChild("Viewport") -- inferred equivalent call
	local details = viewport and viewport:FindFirstChild("Details")

	if not details then
		return
	end

	details.Visible = data ~= nil

	if not data then
		return
	end

	local resolvedSkinInformation = GetResolvedSkinInformation(data.Name, data.Skin)
	local success, result = pcall(GetWeaponProperties, data.Name)

	if not success then
		result = nil
	end

	local v40 = resolvedSkinInformation and Rarities[resolvedSkinInformation.rarity]
	local color2

	if resolvedSkinInformation and resolvedSkinInformation.rarity == "Forbidden" then
		color2 = color
	elseif v40 then
		color2 = v40.Color
	else
		color2 = Rarities.Stock.Color
	end

	details.Render.Image = not resolvedSkinInformation and ""
		or Skins.GetWearImageForFloat(resolvedSkinInformation, data.Float or 0.9999)
		or resolvedSkinInformation.imageAssetId
		or ""
	local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag)

	if data.StatTrack then
		weaponDisplayName = "KillTrak™ " .. weaponDisplayName
	end

	if data.Type == "Melee" then
		weaponDisplayName = "★ " .. weaponDisplayName
	end

	GetSkinDisplayName.ApplyNameLabel(details.WeaponName, weaponDisplayName, data.NameTag)
	details.SkinLine.SkinName.Text = GetSkinDisplayName(data.Skin)
	details.SkinLine.SkinName.TextColor3 = color2
	details.SkinLine.Diamond.BackgroundColor3 = color2
	local class = result and result.Class
	local text = v37[data.Type]
		or class == "Glove" and "Gloves"
		or class == "Melee" and "Knife"
		or v38[WeaponCategories.GetLabel(data.Name)]
		or "Equipment"
	local cost = result and result.Cost
	local meta = details.Meta

	if type(cost) == "number" and cost > 0 then
		text = `{text}  ·  ${CommaNumber(cost)}`
	end

	meta.Text = text
	local v42

	if data.Type == "Weapon" then
		v42 = ComputeWeaponStats(result)
	end

	details.Stats.Visible = v42 ~= nil
	details.Divider.Visible = v42 ~= nil

	if v42 then
		for childName2, v43 in v42 do
			local child = details.Stats:FindFirstChild(childName2)

			if not child then
				continue
			end

			child.Track.Fill.Size = UDim2.fromScale(v43 / 100, 1)
			child.Value.Text = tostring(v43)
		end
	end
end

local function GetDefaultSelectedItem()
	for _, v39 in { "Rifles", "Mid Tier", "Pistols" } do
		local currentCategoryOptions = GetCurrentCategoryOptions(v39) -- inferred equivalent call

		for _, v41 in currentCategoryOptions or {} do
			local v42

			if v41 ~= "" then
				v42 = GetInventoryItemFromIdentifier(v41) or nil
			end

			if v42 then
				return v42
			end
		end
	end

	return nil
end

function Loadout:SetSelectedWeapon(flag6: boolean?)
	if not self or not flag6 and (flag or id2) then
		return
	end

	local currentTeamKey = GetCurrentTeamKey() -- inferred equivalent call

	if not flag6 then
		ids[currentTeamKey] = self._id
	end

	PaintWeaponDetails(currentTeamKey, self)
end

function Loadout.RefreshSelectedWeapon()
	local currentTeamKey = GetCurrentTeamKey() -- inferred equivalent call
	local v40 = ids[currentTeamKey]
	local v41 = v40 and GetInventoryItemFromIdentifier(v40)

	if not (v41 and IsEquippedOnTeam(v40, team2)) then
		v41 = GetDefaultSelectedItem()
		ids[currentTeamKey] = v41 and v41._id
	end

	PaintWeaponDetails(currentTeamKey, v41)
end

function Loadout.OnLoadoutItemHover(p)
	Loadout.SetSelectedWeapon(p)
end

local function SetupSidebarHoverEvents()
	Profiler.mark("UI.Loadout.SetupSidebarHoverEvents")
	local teams = v29.Container.Teams

	for _, childName in ipairs({ "CT", "T" }) do
		local child = teams:FindFirstChild(childName)

		if not child then
			continue
		end

		local equipments = child:FindFirstChild("Equipments")

		if not equipments then
			continue
		end

		for _, childName2 in ipairs(v22) do
			local child2 = equipments:FindFirstChild(childName2)

			if not child2 then
				continue
			end

			local v39 = childName .. "_" .. childName2
			local v40 = v39 .. "_Selection"

			for _, v41 in { v39, v40 } do
				local connection3 = connections[v41]

				if connection3 then
					connection3:Disconnect()
				end
			end

			local function showEquippedItem()
				local equippedItemId = child2:GetAttribute("EquippedItemId")

				if equippedItemId and equippedItemId ~= "" then
					Loadout.SetSelectedWeapon((GetInventoryItemFromIdentifier(equippedItemId)))
				end
			end

			connections[v39] = child2.MouseEnter:Connect(showEquippedItem)
			connections[v40] = child2.SelectionGained:Connect(showEquippedItem)
		end
	end
end

local v39 = { ButtonCT = v32["Counter-Terrorists"], ButtonT = v32.Terrorists }

local function UpdateTeamToggle(p: string)
	for childName, backgroundColor in v39 do
		local guiObject = v29.Teams:FindFirstChild(childName)

		if not (guiObject and guiObject:IsA("GuiObject")) then
			continue
		end

		local visible = childName == `Button{p}`
		local v42 = guiObject:FindFirstChild("InactiveDim")

		if not v42 then
			v42 = Instance.new("Frame")
			v42.Name = "InactiveDim"
			v42.BackgroundColor3 = Color3.new(0, 0, 0)
			v42.BackgroundTransparency = 0.45
			v42.BorderSizePixel = 0
			v42.Size = UDim2.fromScale(1, 1)
			v42.ZIndex = 20
			v42.Interactable = false
			v42.Parent = guiObject
		end

		v42.Visible = not visible
		local v43 = guiObject:FindFirstChild("ActiveBar")

		if not v43 then
			v43 = Instance.new("Frame")
			v43.Name = "ActiveBar"
			v43.BackgroundColor3 = backgroundColor
			v43.BorderSizePixel = 0
			v43.AnchorPoint = Vector2.new(0.5, 1)
			v43.Position = UDim2.fromScale(0.5, 1)
			v43.Size = UDim2.new(1, 0, 0, 3)
			v43.ZIndex = 20
			v43.Interactable = false
			v43.Parent = guiObject
		end

		v43.Visible = visible
	end
end

function Loadout.SelectTeam(p: string)
	Profiler.mark("UI.Loadout.SelectTeam")
	local ct = v29.Container.Teams:FindFirstChild("CT")
	assert(ct and ct:IsA("Frame"), "[Loadout] Missing CT team panel")
	ct.Visible = p == "CT"
	local t = v29.Container.Teams:FindFirstChild("T")
	assert(t and t:IsA("Frame"), "[Loadout] Missing T team panel")
	t.Visible = p == "T"
	team2 = p == "CT" and "Counter-Terrorists" or p == "T" and "Terrorists" or false
	UpdateTeamToggle(p)
	kind = nil
	v4 = nil
	v3 = nil
	v29.Container.List.Top.Filter.Container.Left.Title.Text = "All Categories"
	v29.Container.List.Top.Weapon.Container.Left.Title.Text = "All Weapons"
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	Loadout.UpdateLoadoutContainer(loadout)
	Loadout.UpdateSidebarFrames(loadout)
	Loadout.UpdateInventoryContainer()
	Loadout.PopulateWeaponDropdown()
end

local function RefreshItemStatusFrames()
	if v29 and v29.Visible then
		local container = v29.Container.List.Container

		for _, frame in ipairs(container:GetChildren()) do
			if not (frame:IsA("Frame") and frame.Name ~= "UIGridLayout" and frame.Name ~= "UIListLayout" and frame.Name ~= "UIPadding") then
				continue
			end

			UpdateStatusFrame(frame, frame.Name)
		end
	end
end

function Loadout.Initialize(instance, p)
	Profiler.mark("UI.Loadout.Initialize")
	v29 = p
	v29:GetPropertyChangedSignal("Visible"):Connect(function()
		if v29.Visible then
			if flag5 then
				flag5 = false
				Loadout.SortBySkinMetadata(v)
			end

			if flag4 then
				RenderInitialLoadoutTemplates()
			end
		else
			CleanupDrag()
			CleanupDrag()
			id2 = nil
			v12 = nil
			v11 = false

			if flag2 then
				flag2 = false
				pcall(function()
					GamepadService:DisableGamepadCursor()
				end)
				GuiService.AutoSelectGuiEnabled = true
				HideControllerClickShield() -- inferred equivalent call
			end

			HideAllMoveFrames()
		end
	end)
	local container = v29.Container.List.Container
	container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if not v29 then
			return
		end

		local container2 = v29.Container.List.Container
		local y = container2.CanvasPosition.Y
		local v40 = container2.AbsoluteCanvasSize.Y - container2.AbsoluteSize.Y

		if v40 > 0 and v15 < #v14 and v40 - y < 200 then
			RenderLoadoutTemplates() -- inferred equivalent call
		end
	end)
	container:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		Profiler.defer("UI.Loadout.ScrollDeferred", OnLoadoutScrollPositionChanged)
	end)
	local menu = instance:FindFirstChild("Menu")

	if menu then
		menu:GetPropertyChangedSignal("Visible"):Connect(function()
			if not menu.Visible then
				CleanupDrag()
				CleanupDrag()
				id2 = nil
				v12 = nil
				v11 = false

				if flag2 then
					flag2 = false
					pcall(function()
						GamepadService:DisableGamepadCursor()
					end)
					GuiService.AutoSelectGuiEnabled = true
					HideControllerClickShield() -- inferred equivalent call
				end

				HideAllMoveFrames()
				HideContextMenu() -- inferred equivalent call

				if MenuState.IsInspectActive() then
					Router.broadcastRouter("WeaponInspectClose")
				end
			end
		end)
	end

	information = v29.Ignore.Information

	if information then
		information.Visible = false
		CloseButtonRegistry.Add(information, nil, function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			local v40 = v13
			HideContextMenu() -- inferred equivalent call

			if v40 then
				local button = v40:FindFirstChild("Button")

				if button and button:IsA("GuiButton") then
					GuiService.SelectedObject = button
				end
			end
		end)

		if information.Inspect then
			information.Inspect.Selectable = true

			local function handleInspectClick()
				local v40

				if id3 then
					v40 = GetInventoryItemFromIdentifier(id3)
				end

				if v40 then
					InspectInventoryItem(v40)
				else
					Router.broadcastRouter("RunInterfaceSound", "UI Click")
				end
			end

			ConnectButtonActivation(information.Inspect, handleInspectClick) -- inferred equivalent call
		end

		if information.Charm then
			information.Charm.Selectable = true

			local function handleCharmClick()
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				local currentInventoryItem = GetCurrentInventoryItem() -- inferred equivalent call

				if currentInventoryItem then
					local itemHasCharm = ItemHasCharm(currentInventoryItem) -- inferred equivalent call
					HideContextMenu() -- inferred equivalent call

					if itemHasCharm then
						Remotes.Inventory.RemoveWeaponCharm.Send({
							WeaponId = currentInventoryItem._id
						})
					else
						v29.Visible = false
						UseItemFrame.TriggerAction("AttachCharm", currentInventoryItem)
					end
				end
			end

			ConnectButtonActivation(information.Charm, handleCharmClick) -- inferred equivalent call
		end

		UseItemFrame.OnClosed:Connect(function()
			if MenuState.GetCurrentScreen() == "Loadout" then
				v29.Visible = true
			end
		end)

		if information.Unlock then
			information.Unlock.Selectable = true
			information.Unlock.Visible = false
		end

		local function setupReplaceButton(p2, team)
			if not p2 then
				return
			end

			p2.Selectable = true

			local function fn4()
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				local currentInventoryItem = GetCurrentInventoryItem() -- inferred equivalent call

				if currentInventoryItem then
					if information then
						information.Visible = false
					end

					id3 = nil
					v13 = nil
					ReplaceItemOnTeam(currentInventoryItem, team)
				end
			end

			ConnectButtonActivation(p2, fn4) -- inferred equivalent call
		end

		local replaceT = information.ReplaceT

		if replaceT then
			replaceT.Selectable = true
			local team = "Terrorists"

			local function fn4()
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				local v41

				if id3 then
					v41 = GetInventoryItemFromIdentifier(id3)
				end

				if v41 then
					HideContextMenu() -- inferred equivalent call
					ReplaceItemOnTeam(v41, team)
				end
			end

			ConnectButtonActivation(replaceT, fn4) -- inferred equivalent call
		end

		local replaceCT = information.ReplaceCT

		if replaceCT then
			replaceCT.Selectable = true
			local team = "Counter-Terrorists"

			local function fn4()
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				local v41

				if id3 then
					v41 = GetInventoryItemFromIdentifier(id3)
				end

				if v41 then
					HideContextMenu() -- inferred equivalent call
					ReplaceItemOnTeam(v41, team)
				end
			end

			ConnectButtonActivation(replaceCT, fn4) -- inferred equivalent call
		end
	end

	Profiler.spawn("UI.Loadout.PreloadDropShadows", ItemIcon.PreloadDropShadows)

	for _, v40 in ipairs({ "CT", "T" }) do
		local guns = GetTeamFrame(v40):FindFirstChild("Guns") -- inferred equivalent call

		for _, childName in ipairs({ "Mid Tier", "Pistols", "Rifles" }) do
			local list = guns:FindFirstChild(childName).List

			if not (list and list:IsA("Frame")) then
				continue
			end

			list.MouseEnter:Connect(function()
				FadeCategoryLabels(list, true)
			end)
			list.MouseLeave:Connect(function()
				FadeCategoryLabels(list, false)
			end)
		end
	end

	DataController.CreateListener(LocalPlayer, "Loadout", function(p2)
		Profiler.mark("UI.Loadout.LoadoutChanged")
		flag3 = false
		Loadout.UpdateLoadoutContainer(p2)
		Loadout.UpdateSidebarFrames(p2, "Counter-Terrorists")
		Loadout.UpdateSidebarFrames(p2, "Terrorists")
		SetupSidebarHoverEvents()
		RefreshItemStatusFrames()
	end)
	Remotes.Inventory.LoadoutResponse.Listen(function()
		flag3 = false
		RefreshSelectedWeaponIfIdle() -- inferred equivalent call
	end)
	DataController.CreateListener(LocalPlayer, "Inventory", function()
		Profiler.mark("UI.Loadout.InventoryChanged")
		Loadout.UpdateInventoryContainer()
		RefreshItemStatusFrames()
	end)
	UserInputService.InputEnded:Connect(function(input, _)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			if id2 then
				if input.UserInputType == Enum.UserInputType.MouseButton1 and v11 then
					fn3()
				end
			elseif flag or v6 then
				Loadout.EndDrag()
			end
		end
	end)
	UserInputService.InputBegan:Connect(function(input, _)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if id2 and os.clock() - now > 0.05 then
				v11 = true
			end
		else
			if input.UserInputType ~= Enum.UserInputType.Gamepad1 then
				return
			end

			if input.KeyCode == Enum.KeyCode.ButtonA then
				if id2 and os.clock() - now > 0.05 then
					v11 = true
				end
			elseif input.KeyCode == Enum.KeyCode.ButtonB then
				fn2()
			elseif input.KeyCode == Enum.KeyCode.ButtonX then
				if not v29.Visible or id2 or UserInputService:GetFocusedTextBox() then
					return
				end

				local selectedObject = GuiService.SelectedObject

				if not (selectedObject and selectedObject:IsA("GuiButton") and selectedObject:IsDescendantOf(v29)) then
					return
				end

				local inventoryItemFromButton = GetInventoryItemFromButton(selectedObject) -- inferred equivalent call

				if not inventoryItemFromButton then
					local parent = selectedObject.Parent

					if parent and parent:IsA("Frame") then
						local name2 = parent.Name
						local v41, v42 = GetLoadoutSlotInfo(selectedObject)

						if v41 and v42 then
							inventoryItemFromButton = GetInventoryItemFromIdentifier(name2)
						else
							inventoryItemFromButton = nil
						end
					else
						inventoryItemFromButton = nil
					end
				end

				local equippedItemId = selectedObject:GetAttribute("EquippedItemId")

				if not inventoryItemFromButton and type(equippedItemId) == "string" and equippedItemId ~= "" then
					inventoryItemFromButton = GetInventoryItemFromIdentifier(equippedItemId)
				end

				if inventoryItemFromButton then
					InspectInventoryItem(inventoryItemFromButton)
				end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input, _)
		if input.UserInputType ~= Enum.UserInputType.Gamepad1 then
			return
		end

		if input.KeyCode == Enum.KeyCode.ButtonA and id2 and v11 then
			fn3()
		end
	end)
	UserInputService.LastInputTypeChanged:Connect(function(p2)
		if flag2 and p2 ~= Enum.UserInputType.Keyboard and p2 ~= Enum.UserInputType.Touch then
			return
		end

		local v40 = v10
		v10 = p2 == Enum.UserInputType.Gamepad1

		if v40 and not v10 then
			CleanupDrag()
			id2 = nil
			v12 = nil
			v11 = false

			if flag2 then
				flag2 = false
				pcall(function()
					GamepadService:DisableGamepadCursor()
				end)
				GuiService.AutoSelectGuiEnabled = true
				HideControllerClickShield() -- inferred equivalent call
			end

			HideAllMoveFrames()
		end

		if not v40 and v10 then
			CleanupDrag()
		end
	end)
	v10 = UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1
	local filter = v29.Container.List.Top.Filter
	local scroll = filter.DropdownContent.Scroll
	filter.MouseButton1Click:Connect(function()
		local visible = scroll.Parent.Visible
		CloseAllDropdowns() -- inferred equivalent call
		scroll.Parent.Visible = not visible
	end)

	for _, button in ipairs(scroll:GetChildren()) do
		if not button:IsA("TextButton") then
			continue
		end

		button.BackgroundTransparency = 1
		local v40 = button
		button.MouseEnter:Connect(function()
			AnimateSortButton(v40, true) -- inferred equivalent call
		end)
		local v41 = button
		button.MouseLeave:Connect(function()
			AnimateSortButton(v41, false) -- inferred equivalent call
		end)
		local v42 = button
		button.MouseButton1Click:Connect(function()
			Loadout.SortBySkinMetadata(v42.Name)
			scroll.Parent.Visible = false
		end)
	end

	local reverse = v29.Container.List.Top.Filter.Container.Left.Reverse

	if reverse then
		reverse.Selectable = true

		local function fn4()
			v2 = not v2
			local imageLabel = reverse:FindFirstChildOfClass("ImageLabel")

			if imageLabel then
				imageLabel.Rotation = v2 and 180 or 0
			end

			Loadout.SortBySkinMetadata(v)
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
		end

		ConnectButtonActivation(reverse, fn4) -- inferred equivalent call
	end

	local weapon = v29.Container.List.Top.Weapon
	local scroll2 = weapon.DropdownContent.Scroll

	if scroll2 and (scroll2:IsA("Frame") or scroll2:IsA("ScrollingFrame")) then
		ClearDropdownOptions(scroll2)
		weapon.MouseButton1Click:Connect(function()
			local visible = scroll2.Parent.Visible
			CloseAllDropdowns() -- inferred equivalent call
			scroll2.Parent.Visible = not visible
		end)
	end

	local reset = v29.Container.List.Top.Reset

	if reset then
		reset.Visible = false
		reset.MouseButton1Click:Connect(function()
			kind = nil
			v4 = nil
			v3 = nil
			weapon.Container.Left.Title.Text = "All Weapons"
			reset.Visible = false
			Loadout.PopulateWeaponDropdown()
			local container2 = v29.Container.List.Container

			for _, button in ipairs(container2:GetChildren()) do
				if button:IsA("ImageButton") then
					button.Visible = true
				end
			end

			Loadout.SortBySkinMetadata(v)
		end)
	end
end

function Loadout.ViewInLoadout(p: string)
	local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(p)

	if not inventoryItemFromIdentifier then
		return
	end

	local name2 = inventoryItemFromIdentifier.Name
	local skin = inventoryItemFromIdentifier.Skin
	local success, result = pcall(GetWeaponProperties, name2)

	if success and result and result.Type then
		kind = result.Type
		v29.Container.List.Top.Filter.Container.Left.Title.Text = result.Type
		Loadout.PopulateWeaponDropdown()
	end

	Loadout.SortByWeapon(name2, skin)
	UpdateResetButtonVisibility() -- inferred equivalent call

	if not v29.Visible then
		MenuState.SetScreen("Loadout")
		v29.Visible = true
	end
end

function Loadout.Start()
	debug.setmemorycategory("UI.Loadout.Start")
	Profiler.mark("UI.Loadout.Start.Begin")
	DataController.WaitForDataLoaded(LocalPlayer)
	Profiler.mark("UI.Loadout.Start.DataLoaded")
	Loadout.SelectTeam("CT")
	Profiler.mark("UI.Loadout.Start.InitialTeam")
	local loadout = DataController.Get(LocalPlayer, "Loadout")

	if loadout then
		Loadout.UpdateSidebarFrames(loadout, "Counter-Terrorists")
		Loadout.UpdateSidebarFrames(loadout, "Terrorists")
		SetupSidebarHoverEvents()
	end

	Loadout.PopulateWeaponDropdown()
	Loadout.SortBySkinMetadata("Newest")

	local function ClearFiltersAndShowAll()
		kind = nil
		v4 = nil
		v3 = nil
		v29.Container.List.Top.Filter.Container.Left.Title.Text = "All Categories"
		v29.Container.List.Top.Weapon.Container.Left.Title.Text = "All Weapons"
		local container = v29.Container.List.Container

		for _, button in ipairs(container:GetChildren()) do
			if button:IsA("ImageButton") then
				button.Visible = true
			end
		end

		Loadout.SortBySkinMetadata(v)
		UpdateResetButtonVisibility() -- inferred equivalent call
	end

	local function GetEquipmentSlotTitle(p: string) -- 1 equivalent call inferred from this helper
		return v25[p] or p
	end

	local connections2 = {}

	local function SetupSidebarButtonClicks()
		Profiler.mark("UI.Loadout.SetupSidebarButtonClicks")

		for _, v40 in ipairs({ "CT", "T" }) do
			local equipments = GetTeamFrame(v40):FindFirstChild("Equipments") -- inferred equivalent call

			for _, v41 in ipairs(v21) do
				local equipment = equipments[v41]
				equipment.Selectable = true
				equipment.Active = true
				local teamKey = v40
				local sidebarName = v41

				local function handleSelection()
					if id2 or os.clock() - now2 < 0.25 then
						return
					end

					local v44 = v3

					if v44 then
						if v3.teamKey == teamKey then
							v44 = v3.sidebarName == sidebarName
						else
							v44 = false
						end
					end

					if v44 then
						v3 = nil
						ClearFiltersAndShowAll()
					else
						kind = nil
						v4 = nil
						v29.Container.List.Top.Filter.Container.Left.Title.Text = "All Categories"
						v29.Container.List.Top.Weapon.Container.Left.Title.Text = GetEquipmentSlotTitle(sidebarName) -- inferred equivalent call
						v3 = { teamKey = teamKey, sidebarName = sidebarName }
						Loadout.SortBySkinMetadata(v)
						UpdateResetButtonVisibility() -- inferred equivalent call
					end
				end

				local formatted = `{v40}_{v41}`

				if connections2[formatted] then
					connections2[formatted]:Disconnect()
				end

				connections2[formatted] = equipment.Activated:Connect(handleSelection)
			end
		end
	end

	SetupSidebarButtonClicks()
	ActivateButton(v29.Teams.ButtonCT)
	ActivateButton(v29.Teams.ButtonT)

	local function SwitchToTeam(p: string) -- 1 equivalent call inferred from this helper
		if team2 == (p == "CT" and "Counter-Terrorists" or "Terrorists") then
			return
		end

		Loadout.SelectTeam(p)
		v3 = nil
		ClearFiltersAndShowAll()
		Profiler.defer("UI.Loadout.SidebarButtonsDeferred", SetupSidebarButtonClicks)
	end

	v29.Teams.ButtonCT.MouseButton1Click:Connect(function()
		if team2 == "Counter-Terrorists" then
			return
		end

		Loadout.SelectTeam("CT")
		v3 = nil
		ClearFiltersAndShowAll()
		Profiler.defer("UI.Loadout.SidebarButtonsDeferred", SetupSidebarButtonClicks)
	end)
	v29.Teams.ButtonT.MouseButton1Click:Connect(function()
		if team2 == "Terrorists" then
			return
		end

		Loadout.SelectTeam("T")
		v3 = nil
		ClearFiltersAndShowAll()
		Profiler.defer("UI.Loadout.SidebarButtonsDeferred", SetupSidebarButtonClicks)
	end)
	MenuState.RegisterBumperOverride(v29, function(flag6: boolean)
		if id2 then
			CleanupDrag()
			id2 = nil
			v12 = nil
			v11 = false

			if flag2 then
				flag2 = false
				pcall(function()
					GamepadService:DisableGamepadCursor()
				end)
				GuiService.AutoSelectGuiEnabled = true
				HideControllerClickShield() -- inferred equivalent call
			end

			HideAllMoveFrames()
		end

		local v40 = team2 == "Counter-Terrorists" and "ButtonCT" or "ButtonT"
		local nextBumperTab = MenuState.GetNextBumperTab(v29.Teams, v27, v40, flag6)

		if nextBumperTab and nextBumperTab ~= v40 then
			SwitchToTeam(nextBumperTab == "ButtonCT" and "CT" or "T") -- inferred equivalent call
		end

		local guiObject = v29.Teams:FindFirstChild(nextBumperTab or v40)

		if guiObject and guiObject:IsA("GuiObject") then
			GuiService.SelectedObject = guiObject
		end

		return true
	end, v29, v29.Teams, function()
		return id2 ~= nil
	end)
	CloseButtonRegistry.AddHandler(function()
		return id2 ~= nil and v29.Visible
	end, function()
		local selectedObject = v12
		CleanupDrag()
		id2 = nil
		v12 = nil
		v11 = false

		if flag2 then
			flag2 = false
			pcall(function()
				GamepadService:DisableGamepadCursor()
			end)
			GuiService.AutoSelectGuiEnabled = true
			HideControllerClickShield() -- inferred equivalent call
		end

		HideAllMoveFrames()

		if selectedObject and GamepadNavigation.IsUsable(selectedObject) then
			GamepadNavigation.ScrollIntoView(selectedObject)
			GuiService.SelectedObject = selectedObject
		end
	end)
	GamepadService:GetPropertyChangedSignal("GamepadCursorEnabled"):Connect(function()
		if flag2 and id2 and not GamepadService.GamepadCursorEnabled then
			local selectedObject = v12
			CleanupDrag()
			id2 = nil
			v12 = nil
			v11 = false

			if flag2 then
				flag2 = false
				pcall(function()
					GamepadService:DisableGamepadCursor()
				end)
				GuiService.AutoSelectGuiEnabled = true
				HideControllerClickShield() -- inferred equivalent call
			end

			HideAllMoveFrames()

			if selectedObject and GamepadNavigation.IsUsable(selectedObject) then
				GamepadNavigation.ScrollIntoView(selectedObject)
				GuiService.SelectedObject = selectedObject
			end
		end
	end)
	v29.Teams.ButtonCT.Interactable = true
	v29.Teams.ButtonT.Interactable = true
end

return Loadout