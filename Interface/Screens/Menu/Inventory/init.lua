local Inventory = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Collections = require(ReplicatedStorage.Database.Components.Libraries.Collections)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local GetResolvedSkinInformation = require(ReplicatedStorage.Components.Common.GetResolvedSkinInformation)
local ItemEquipment = require(ReplicatedStorage.Components.Common.ItemEquipment)
local CalculateGridRenderCount = require(ReplicatedStorage.Components.Common.CalculateGridRenderCount)
local UpdateStatusFrame = ItemEquipment.UpdateStatusFrame
local IsEquippedOnTeam = ItemEquipment.IsEquippedOnTeam
local ApplyWearAndSerialBadges = require(ReplicatedStorage.Components.Common.ApplyWearAndSerialBadges)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Buttons = require(ReplicatedStorage.Database.Custom.GameStats.UI.Inventory.Buttons)
local Sort = require(ReplicatedStorage.Database.Custom.GameStats.UI.Inventory.Sort)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Grenades = require(ReplicatedStorage.Database.Custom.GameStats.Grenades)
local UseItemFrame = require(script.Parent.UseItemFrame)
local Loadout = require(script.Parent.Loadout)
local Store = require(script.Parent.Store)
local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local v = {}
local v2 = table.find(GetUserPlatform(), "PC") ~= nil
local v3 = nil
local v4 = nil
local v5 = nil
local v6 = nil
local v7 = 0
local v8 = false
local v9 = nil
local v10 = nil
local v11 = false
local flag = false
local now = nil
local v12 = 0
local v13 = nil
local v14 = {}
local information = nil
local v15 = nil
local v16 = nil
local parent2 = nil
local v17 = nil
local v18 = {}
local v19 = {}
local v20 = {}
local v21 = {}
local v22 = {}
local v23 = false
local id = nil
local id2 = nil
local connection = nil
local v24 = false
local v25 = { ["Charm Capsule"] = "Charm Pack", Package = "Package" }
local v26 = {
	Special = "Drop Gold",
	Red = "Drop Red",
	Pink = "Drop Pink",
	Purple = "Drop Purple",
	Blue = "Drop Blue"
}
local v27 = {
	Glove = "Equipped Gloves",
	Badge = "Equipped Badge",
	["Zeus x27"] = "Equipped Zeus x27"
}
local v28 = { Pistol = "Pistols", SMG = "Mid Tier", Heavy = "Mid Tier", Rifle = "Rifles" }
local v29 = {}
local v30 = {}
local v31 = {}
local v32 = nil

local function setReverseSortVisual(reverseSort, flag2: boolean) -- 2 equivalent calls inferred from this helper
	local imageLabel = reverseSort:FindFirstChildOfClass("ImageLabel")

	if imageLabel then
		imageLabel.Rotation = flag2 and 180 or 0
	end
end

local function ClearQuickOpenPending(p: string?)
	if p and v13 ~= p then
		return false
	end

	if v13 then
		Store.ClearPendingOpenCaseRequest(v13)
	end

	flag = false
	v13 = nil
	return true
end

local v34 = { "Charm", "Inspect", "ReplaceCT", "ReplaceT", "Unlock" }

local function GetVisibleInformationFrameButtons()
	local result = {}

	for _, v35 in v34 do
		local v36 = information[v35]

		if v36 and v36.Visible then
			table.insert(result, v36)
		end
	end

	local quickUnlock = information:FindFirstChild("QuickUnlock")

	if quickUnlock and quickUnlock.Visible then
		table.insert(result, quickUnlock)
	end

	return result
end

local function hasAnyInformationFrameButton() -- 1 equivalent call inferred from this helper
	return information ~= nil and #GetVisibleInformationFrameButtons() > 0
end

local function ItemHasCharm(p) -- 3 equivalent calls inferred from this helper
	local charm = p.Charm
	return charm ~= nil and charm ~= false and (type(charm) == "string" or charm == true or type(charm) == "table")
end

local function GetInventoryItemFromIdentifier(list, p: string) -- 3 equivalent calls inferred from this helper
	for _, v35 in ipairs(list) do
		if v35._id == p then
			return v35
		end
	end

	return nil
end

local function IsWeaponEquippedInTeamCategory(name: string, p: string, p2: string)
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not (loadout and inventory) then
		return false, nil
	end

	local v35 = loadout[p]

	if not (v35 and v35.Loadout and v35.Loadout[p2]) then
		return false, nil
	end

	local options = v35.Loadout[p2].Options

	for i, option in ipairs(options) do
		if not (option and option ~= "") then
			continue
		end

		local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(inventory, option) -- inferred equivalent call

		if inventoryItemFromIdentifier and inventoryItemFromIdentifier.Name == name then
			return true, i
		end
	end

	return false, nil
end

local function GetWeaponCategory(name: string) -- 1 equivalent call inferred from this helper
	local success, result = pcall(GetWeaponProperties, name)

	if success and result and result.Type then
		return v28[result.Type]
	end

	return nil
end

local function ReplaceItemOnTeam(data, team: string)
	if data.Type == "Weapon" then
		local name = data.Name
		local weaponCategory = GetWeaponCategory(name) -- inferred equivalent call

		if not weaponCategory then
			return
		end

		local v36, v37 = IsWeaponEquippedInTeamCategory(name, team, weaponCategory)

		if v36 and v37 then
			Remotes.Inventory.EquipLoadoutSkin.Send({
				Type = weaponCategory,
				Slot = v37 - 1,
				Team = team,
				Identifier = data._id
			})
			return
		end

		Top.openFrame("Loadout")
		local v38 = team == "Counter-Terrorists" and "CT" or "T"
		Loadout.SelectTeam(v38)
		Loadout.SortByCategory(nil)
		Loadout.SortByWeapon(name)
		Profiler.defer("UI.Inventory.LoadoutWeaponFilterDeferred", Loadout.SortByWeapon, name)
	elseif data.Type == "Melee" then
		if
			data.Name == "CT Knife" and team == "Terrorists"
			or data.Name == "T Knife" and team == "Counter-Terrorists"
		then
			return
		end

		Remotes.Inventory.EquipSpecialItem.Send({
			Identifier = data._id,
			Path = "Equipped Melee",
			Team = team
		})
	elseif v27[data.Type] then
		Remotes.Inventory.EquipSpecialItem.Send({
			Identifier = data._id,
			Path = v27[data.Type],
			Team = team
		})
	end
end

local function SetDropdownOpen(instance, flag2: boolean) -- 4 equivalent calls inferred from this helper
	if not instance then
		return
	end

	instance.Visible = flag2
	instance.Active = flag2
	local scroll = instance:FindFirstChild("Scroll")

	if scroll and scroll:IsA("GuiObject") then
		scroll.Visible = flag2
		scroll.Active = flag2
	end
end

local function setSortDropdownOpen(flag2: boolean) -- 3 equivalent calls inferred from this helper
	SetDropdownOpen(v15, flag2) -- inferred equivalent call
end

local function BindSortDropdownFocus(dropdownContent, selectedObject, fn, p: string)
	local function getInitialSortOption()
		local button = dropdownContent.Scroll:FindFirstChild(fn())

		if button and button:IsA("GuiButton") and button.Selectable then
			return button
		end

		for _, button2 in ipairs(dropdownContent.Scroll:GetChildren()) do
			if button2:IsA("GuiButton") and button2.Selectable then
				return button2
			end
		end

		return nil
	end

	dropdownContent:GetPropertyChangedSignal("Visible"):Connect(function()
		if GuiService.SelectedObject == nil then
			return
		end

		if dropdownContent.Visible then
			local initialSortOption = getInitialSortOption()

			if initialSortOption then
				Profiler.defer(p, function()
					if dropdownContent.Visible then
						GuiService.SelectedObject = initialSortOption
					end
				end)
			end
		else
			local selectedObject2 = GuiService.SelectedObject

			if selectedObject2 and selectedObject2:IsDescendantOf(dropdownContent.Scroll) then
				GuiService.SelectedObject = selectedObject
			end
		end
	end)
end

local function BindSearchTap(search, title)
	search.MouseButton1Click:Connect(function()
		title:CaptureFocus()
	end)
	search.Activated:Connect(function()
		title:CaptureFocus()
	end)
end

local function IsMouseOverVisibleGui(data, point: Vector2)
	if not (data and data.Visible) then
		return false
	end

	local absolutePosition = data.AbsolutePosition
	local absoluteSize = data.AbsoluteSize
	return point.X >= absolutePosition.X
		and point.X <= absolutePosition.X + absoluteSize.X
		and point.Y >= absolutePosition.Y
		and point.Y <= absolutePosition.Y + absoluteSize.Y
end

local function IsMouseOverBlockingUI()
	local vector = Vector2.new(mouse.X, mouse.Y)

	if v16.Ignore.ItemNotification.Visible then
		return true
	end

	local v35 = v15
	local v36

	if v35 and v35.Visible then
		local absolutePosition = v35.AbsolutePosition
		local absoluteSize = v35.AbsoluteSize

		if
			vector.X >= absolutePosition.X
			and vector.X <= absolutePosition.X + absoluteSize.X
			and vector.Y >= absolutePosition.Y
		then
			v36 = vector.Y <= absolutePosition.Y + absoluteSize.Y
		else
			v36 = false
		end
	else
		v36 = false
	end

	if v36 then
		return v36
	end

	local v37 = information

	if not (v37 and v37.Visible) then
		return false
	end

	local absolutePosition = v37.AbsolutePosition
	local absoluteSize = v37.AbsoluteSize

	if
		vector.X >= absolutePosition.X
		and vector.X <= absolutePosition.X + absoluteSize.X
		and vector.Y >= absolutePosition.Y
	then
		return vector.Y <= absolutePosition.Y + absoluteSize.Y
	else
		return false
	end
end

local function shouldRunInventoryUpdate() -- 2 equivalent calls inferred from this helper
	return v16 ~= nil and v16.Visible
end

local function stopInventoryUpdate() -- 1 equivalent call inferred from this helper
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function updateInventoryHeartbeat(p: number)
	Profiler.mark("UI.Inventory.Heartbeat")

	if v16 and parent2 then
		local v35 = shouldRunInventoryUpdate() -- inferred equivalent call

		if v35 and v2 and v16.Visible then
			Inventory.UpdateHoverFrame(p)
		else
			v16.Ignore.Hover.Visible = false
		end

		if v35 and v16.Ignore.ItemNotification.Visible then
			v16.Ignore.ItemNotification.Holder.Light.Rotation = v16.Ignore.ItemNotification.Holder.Light.Rotation + p * 10
		end

		if not v35 and connection then
			connection:Disconnect()
			connection = nil
		end
	else
		stopInventoryUpdate() -- inferred equivalent call
	end
end

local function syncInventoryUpdate()
	if not (v16 and parent2) then
		return
	end

	local count = 0

	for _, v35 in ipairs(v19) do
		if not v20[v35._id] then
			count += 1
		end
	end

	local alert = parent2.Menu.Top.Bottom.Buttons.Inventory.Alert
	alert.TextLabel.Text = count
	alert.Visible = count > 0
	local count2 = #v19
	local holder = v16.Ignore.ItemNotification.Holder
	holder.Amount.TextLabel.Text = `{v7} / {count2}`
	holder.Right.Visible = v7 < count2
	holder.Left.Visible = v7 > 1

	if not shouldRunInventoryUpdate() then -- inferred equivalent call
		updateInventoryHeartbeat(0)
		return
	end

	if connection then
		return
	end

	connection = RunServiceController.BindToHeartbeat("UI.Inventory.Update", updateInventoryHeartbeat)
	updateInventoryHeartbeat(0)
end

local function CalculateHoverPosition(p)
	local absolutePosition = v16.AbsolutePosition
	local absoluteSize = v16.Ignore.Hover.AbsoluteSize
	local absolutePosition2 = p.AbsolutePosition
	local absoluteSize2 = v16.AbsoluteSize
	local absoluteSize3 = p.AbsoluteSize
	local v35 = absolutePosition2.X - absolutePosition.X
	local v36 = absolutePosition2.Y - absolutePosition.Y
	local v37 = absoluteSize2.X - (v35 + absoluteSize3.X) >= absoluteSize.X + 8
		and (v35 + absoluteSize3.X + 8 + absoluteSize.X / 2) / absoluteSize2.X
		or (v35 - 8 - absoluteSize.X / 2) / absoluteSize2.X
	local v38 = math.max((v36 + absoluteSize3.Y / 2) / absoluteSize2.Y, absoluteSize.Y / 2 / absoluteSize2.Y)
	local v39 = 1 - absoluteSize.Y / 2 / absoluteSize2.Y
	local v40 = math.min(v38, v39)

	if GuiService:GetGuiInset().Y >= absolutePosition.Y + v40 * absoluteSize2.Y - absoluteSize.Y / 2 then
		v40 = math.min(v40 + 30 / absoluteSize2.Y, v39)
	end

	return UDim2.fromScale(v37, v40)
end

local function ReportViewedItems()
	local itemIds = {}

	for k in v21 do
		table.insert(itemIds, k)
	end

	table.clear(v21)

	if #itemIds > 0 then
		Remotes.Player.NewInventoryItemsSeen.Send({ ItemIds = itemIds, Dismissed = false })
	end
end

local function MarkItemViewed(id3: string) -- 1 equivalent call inferred from this helper
	if v20[id3] then
		return
	end

	v20[id3] = true
	v21[id3] = true

	if not v23 then
		v23 = true
		task.delay(2, function()
			v23 = false
			ReportViewedItems()
		end)
	end
end

local function DismissItemNotifications()
	v16.Ignore.ItemNotification.Visible = false
	v7 = 0
	id = nil
	local now2 = os.clock()
	local ids = {}
	local v35 = {}

	for _, v36 in ipairs(v19) do
		table.insert(ids, v36._id)
		v35[v36._id] = true
		v22[v36._id] = now2
	end

	if #ids > 0 then
		table.clear(v21)
		Remotes.Player.NewInventoryItemsSeen.Send({ ItemIds = ids, Dismissed = true })
		local v36 = {}

		for _, v37 in ipairs(v18) do
			if not v35[v37] then
				table.insert(v36, v37)
			end
		end

		v18 = v36
	end

	table.clear(v19)
	table.clear(v20)
	v24 = false
	syncInventoryUpdate()
end

local function FindQueuedItemIndex(id3: string) -- 1 equivalent call inferred from this helper
	for i, v35 in ipairs(v19) do
		if v35._id == id3 then
			return i
		end
	end

	return nil
end

local function RefreshNewInventoryItems()
	local i = v19[v7]
	local v35 = {}
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if type(inventory) == "table" then
		for _, v36 in ipairs(inventory) do
			if v36._id then
				v35[v36._id] = v36
			end
		end
	end

	table.clear(v19)
	local v36 = {}

	for _, v37 in ipairs(v18) do
		v36[v37] = true
		local v38 = v35[v37]

		if v38 then
			table.insert(v19, v38)
		end
	end

	for k in v20 do
		if not v36[k] then
			v20[k] = nil
		end
	end

	local visible

	if v16 == nil then
		visible = false
	else
		visible = v16.Ignore.ItemNotification.Visible
	end

	local visible2 = visible and v16.Visible

	if #v19 == 0 then
		if visible then
			v16.Ignore.ItemNotification.Visible = false
		end

		v7 = 0
		v24 = false
	else
		local v37

		if i then
			local _id = i._id

			for j, v39 in ipairs(v19) do
				if v39._id ~= _id then
					continue
				end

				v37 = j
				break
			end
		else
			v37 = i
		end

		if v37 then
			v7 = v37
		else
			local count = 0

			for _, v38 in ipairs(v19) do
				if not v20[v38._id] then
					break
				end

				count += 1
			end

			v7 = count

			if visible2 then
				Inventory.NextInventoryItem((math.min(count + 1, #v19)))
			elseif visible then
				v16.Ignore.ItemNotification.Visible = false
			end
		end
	end

	local i2 = id
	local v37

	if i2 then
		local v38 = id

		for j, v40 in ipairs(v19) do
			if v40._id ~= v38 then
				continue
			end

			v37 = j
			break
		end
	else
		v37 = i2
	end

	if v37 then
		id = nil

		if v16 and v16.Visible then
			Inventory.NextInventoryItem(v37)
		else
			v7 = v37 - 1
		end
	end

	syncInventoryUpdate()
end

local function InspectInventoryItem(data) -- 3 equivalent calls inferred from this helper
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

local function GetIconImage(data, p, flag2: boolean)
	if not p then
		return ""
	end

	if flag2 then
		return p.imageAssetId or ""
	end

	if data.Type ~= "Charm" then
		return Skins.GetWearImageForFloat(p, data.Float or 0.9999) or p.imageAssetId or ""
	end

	local pattern = data.Pattern

	if pattern and p.charmImages then
		for _, charmImage in ipairs(p.charmImages) do
			if charmImage.pattern == pattern then
				return charmImage.assetId
			end
		end
	end

	return p.imageAssetId or ""
end

local function GetItemDisplayName(data, p, flag2: boolean) -- 2 equivalent calls inferred from this helper
	local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag)
	local v35 = flag2 and p.caseType and v25[p.caseType] or flag2 and p.caseType

	if not v35 then
		if data.StatTrack then
			v35 = "KillTrak™ " .. weaponDisplayName or weaponDisplayName
		else
			v35 = weaponDisplayName
		end
	end

	return (data.Type == "Melee" and "★ " or "") .. v35
end

local function findCharmInventoryItemInList(charm, inventory)
	if not charm or charm == false or not inventory then
		return nil
	end

	local id3 = nil

	if type(charm) == "table" then
		id3 = charm._id
	elseif type(charm) == "string" then
		id3 = charm
	end

	if not id3 then
		return nil
	end

	for _, v35 in ipairs(inventory) do
		if v35._id == id3 and v35.Type == "Charm" then
			return v35
		end
	end

	return nil
end

local function syncItemTemplateCharmIcon(p, p2)
	local charm = p.ItemContent:FindFirstChild("Charm")

	if not (charm and charm:IsA("ImageLabel")) then
		return
	end

	local image = ""

	if p2.Type == "Weapon" and ItemHasCharm(p2) then -- inferred equivalent call
		local inventory = DataController.Get(LocalPlayer, "Inventory")
		local charmInventoryItemInList = findCharmInventoryItemInList(p2.Charm, inventory)
		local v36 = charmInventoryItemInList
			and GetResolvedSkinInformation(charmInventoryItemInList.Name, charmInventoryItemInList.Skin)

		if v36 then
			image = GetIconImage(charmInventoryItemInList, v36, false)
		end
	end

	if image == "" then
		charm.Visible = false
		charm.Image = ""
	else
		charm.Image = image
		charm.Visible = true
	end
end

local function GetCollectionNameForItem(data)
	if data.Type ~= "Case" then
		local resolvedSkinInformation = GetResolvedSkinInformation(data.Name, data.Skin)
		return resolvedSkinInformation and resolvedSkinInformation.collection or nil
	end

	local case = Cases.GetCaseByName(data.Skin)

	if not (case and v9) then
		return nil
	end

	for _, v35 in ipairs(v9) do
		if not v35.cases then
			continue
		end

		for _, cas in ipairs(v35.cases) do
			if cas == case.name then
				return v35.name
			end
		end
	end

	return nil
end

local function GetSortedInventoryData()
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not inventory then
		return {}
	end

	local v35 = v10 or v16.Frame.Right.Top.Filter.Container.Left.Title.Text
	local sortComparisonFunction = Sort.GetSortComparisonFunction(v35, LocalPlayer, function()
		return v9
	end)
	local result = {}

	for _, v36 in inventory do
		local v37 = v36 and Grenades[v36.Name]
		local v38 = v36 and (v36.Type == "Case" or v36.Type == "Package")

		if not (v36 and v36._id and v36.Name and (v38 or v36.Skin)) then
			continue
		end

		if v37 then
			continue
		end

		table.insert(result, v36)
	end

	if not sortComparisonFunction then
		return result
	end

	if v11 then
		table.sort(result, function(a, b)
			local v36, v37 = sortComparisonFunction(a, b)

			if v37 then
				return v36
			end

			return sortComparisonFunction(b, a)
		end)
		return result
	else
		table.sort(result, sortComparisonFunction)
	end

	return result
end

local function IsNotFiltered(p, search)
	if not search or #search == 0 then
		return true
	end

	local effectiveItemType = Buttons.GetEffectiveItemType(p)
	local isCapsule = Buttons.IsCapsule(p)

	for _, v35 in ipairs(search) do
		if effectiveItemType == v35 or p.Type and p.Type == v35 and not isCapsule then
			return true
		end

		local v36

		if p.Name then
			v36 = GetWeaponProperties(p.Name)
		end

		if string.find(v35, ":") then
			local v37 = string.split(v35, ":")
			local v38 = v37[1]
			local v39 = v37[2]

			if v38 == "Weapon" and v36 and v36.Class == "Weapon" and v36.Type == v39 then
				return true
			end
		elseif v36 and v36.Class == v35 then
			return true
		end
	end

	return false
end

local function SetSearchTokens(list, text: string)
	table.clear(list)

	if text ~= "" then
		for _, v35 in ipairs(string.split(string.lower(text), " ")) do
			if v35 ~= "" then
				table.insert(list, v35)
			end
		end
	end
end

local function MatchesSearchQuery(p)
	if #v14 == 0 then
		return true
	end

	local lower = GetSkinDisplayName.GetSearchIdentity(p.Name, p.Skin):lower()

	for _, v35 in ipairs(v14) do
		if string.find(lower, v35, 1, true) == nil then
			return false
		end
	end

	return true
end

local function GetItemCategoryOption(p)
	local v35 = v31[p._id]

	if v35 ~= nil then
		return v35 or nil
	end

	local v36 = nil

	for k, v38 in v30 do
		if not IsNotFiltered(p, v38.Search) then
			continue
		end

		v36 = k
		break
	end

	v31[p._id] = v36 or false
	return v36
end

local function RefreshCategoryFilterRows(p)
	for k, v35 in v30 do
		local v36 = p[k] or 0
		v35.Count.Text = tostring(v36)
		v35.Label.TextTransparency = v36 > 0 and 0 or 0.65
		v35.Count.TextTransparency = v36 > 0 and 0.4 or 0.65
	end

	if v32 then
		v32.Visible = next(v29) ~= nil
	end
end

local function ApplyFilterToSortedData(list)
	local v35 = {}
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if inventory then
		for _, v36 in ipairs(inventory) do
			if not v36.Charm then
				continue
			end

			local id3 = type(v36.Charm) == "table" and v36.Charm._id

			if not id3 then
				if type(v36.Charm) == "string" then
					id3 = v36.Charm
				else
					id3 = false
				end
			end

			if id3 then
				v35[id3] = true
			end
		end
	end

	local v36 = next(v30) ~= nil
	local v37 = next(v29) ~= nil
	local v38 = {}
	local result = {}

	for _, v39 in ipairs(list) do
		if not ((v39.Type ~= "Charm" or not v35[v39._id]) and MatchesSearchQuery(v39)) then
			continue
		end

		if v36 then
			local itemCategoryOption = GetItemCategoryOption(v39)

			if itemCategoryOption then
				v38[itemCategoryOption] = (v38[itemCategoryOption] or 0) + 1

				if not v37 or v29[itemCategoryOption] then
					table.insert(result, v39)
				end
			end
		else
			table.insert(result, v39)
		end
	end

	RefreshCategoryFilterRows(v38)
	return result
end

local function CreateMissingItemTemplates(container, p: number, p2: number)
	for i = p, p2 do
		local v35 = v[i]

		if not v35 or container:FindFirstChild(v35._id) then
			continue
		end

		Inventory.CreateItemTemplate(v35)
	end
end

local function ApplySortedLayoutOrder(container)
	for _, frame in ipairs(container:GetChildren()) do
		if not (frame:IsA("Frame") and frame.Name ~= "UIGridLayout" and frame.Name ~= "UIListLayout" and frame.Name ~= "UIPadding") then
			continue
		end

		for i, v36 in ipairs(v) do
			if v36._id ~= frame.Name then
				continue
			end

			frame.LayoutOrder = i
			break
		end
	end
end

local function RenderInventoryTemplates() -- 1 equivalent call inferred from this helper
	Profiler.mark("UI.Inventory.RenderInventoryTemplates")

	if v16 and v16.Visible then
		local container = v16.Frame.Right.Container
		local v35 = math.min(v12 + 25, #v)
		CreateMissingItemTemplates(container, v12 + 1, v35)
		v12 = v35
		ApplySortedLayoutOrder(container)
	end
end

local function OnScrollPositionChanged()
	if v16 and v16.Visible then
		local y = v16.Frame.Right.Container.CanvasPosition.Y
		local v35 = v16.Frame.Right.Container.AbsoluteCanvasSize.Y - v16.Frame.Right.Container.AbsoluteSize.Y

		if v35 > 0 and v12 < #v and v35 - y < 200 then
			RenderInventoryTemplates() -- inferred equivalent call
		end
	end
end

local function CalculateInitialRenderCount()
	if v16 and v16.Visible then
		return CalculateGridRenderCount(v16.Frame.Right.Container)
	end

	return 50
end

local function RenderInitialTemplates()
	Profiler.mark("UI.Inventory.RenderInitialTemplates")

	if not (v16 and v16.Visible) then
		return
	end

	local container = v16.Frame.Right.Container
	v12 = 0
	local v35 = math.min(
		math.max(not (v16 and v16.Visible) and 50 or CalculateGridRenderCount(v16.Frame.Right.Container), 50),
		#v
	)
	CreateMissingItemTemplates(container, 1, v35)
	ApplySortedLayoutOrder(container)
	v12 = v35
end

local function IsItemTemplate(button) -- 3 equivalent calls inferred from this helper
	local isA = button:IsA("ImageButton")

	if isA then
		if
			button.Name == "UIGridLayout"
			or button.Name == "UIListLayout"
			or button.Name == "UIPadding"
			or button.Name == "Title"
		then
			isA = false
		else
			isA = button.Name ~= "Label"
		end
	end

	return isA
end

local function UpdateInventoryTemplates()
	Profiler.mark("UI.Inventory.UpdateInventoryTemplates")

	if not v16 then
		return
	end

	local container = v16.Frame.Right.Container

	for _, child in ipairs(container:GetChildren()) do
		if IsItemTemplate(child) then -- inferred equivalent call
			child:Destroy()
		end
	end

	v12 = 0

	if v16.Visible then
		RenderInitialTemplates()
	end
end

local function ApplyCurrentSort() -- 3 equivalent calls inferred from this helper
	Profiler.mark("UI.Inventory.ApplyCurrentSort")

	if not (v16 and v16.Visible) then
		return
	end

	v = GetSortedInventoryData()
	v = ApplyFilterToSortedData(v)
	UpdateInventoryTemplates()
end

local function RegisterCategoryFilterRow(parent)
	local v35 = string.gsub(parent.Name, " ", "")
	local v36 = nil
	local search = {}

	for _, button in Buttons do
		if type(button) ~= "table" then
			continue
		end

		for k, v37 in button do
			if string.gsub(k, " ", "") ~= v35 then
				continue
			end

			search = v37.Search
			v36 = k
		end
	end

	if not v36 then
		warn(`[Inventory] Category filter row "{parent.Name}" has no matching option`)
		return
	end

	local info = parent.Info
	local button = parent.Button
	local imageLabel = button.ImageLabel
	imageLabel.Visible = false
	local clone = info:Clone()
	clone.Name = "Count"
	clone.AnchorPoint = Vector2.new(1, 0.5)
	clone.Position = UDim2.fromScale(button.Position.X.Scale - button.Size.X.Scale, info.Position.Y.Scale)
	clone.Size = UDim2.fromScale(0.22, info.Size.Y.Scale)
	clone.TextXAlignment = Enum.TextXAlignment.Right
	clone.Text = ""
	clone.Parent = parent
	local textButton = Instance.new("TextButton")
	textButton.Name = "RowButton"
	textButton.Text = ""
	textButton.BackgroundTransparency = 1
	textButton.Size = UDim2.fromScale(1, 1)
	textButton.ZIndex = button.ZIndex - 1
	textButton.Selectable = false
	textButton.Parent = parent
	v30[v36] = { Check = imageLabel, Label = info, Count = clone, Search = search }

	local function toggle() -- 1 equivalent call inferred from this helper
		local visible = not v29[v36]
		v29[v36] = visible and true or nil
		imageLabel.Visible = visible
		ApplyCurrentSort() -- inferred equivalent call
	end

	ActivateButton(button)
	button.Activated:Connect(toggle)
	textButton.Activated:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		toggle() -- inferred equivalent call
	end)
end

local function ConnectButtonActivation(p, onMouseButton1Click) -- 13 equivalent calls inferred from this helper
	p.MouseButton1Click:Connect(onMouseButton1Click)
	p.Activated:Connect(function(p2)
		if p2 and p2.UserInputType == Enum.UserInputType.Gamepad1 then
			onMouseButton1Click()
		end
	end)
end

local function AnimateSortButton(scroll, child, childName: string, title, fn) -- 1 equivalent call inferred from this helper
	child.Selectable = true

	local function handleSortOptionClick()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")

		if information then
			information.Visible = false
		end

		v10 = childName
		Profiler.mark("UI.Inventory.ApplyCurrentSort")

		if v16 and v16.Visible then
			v = GetSortedInventoryData()
			v = ApplyFilterToSortedData(v)
			UpdateInventoryTemplates()
		end

		title.Text = childName

		for _, button in ipairs(scroll:GetChildren()) do
			if button:IsA("TextButton") then
				button.Frame.BackgroundTransparency = button == child and 0 or 1
			end
		end

		fn()
	end

	ConnectButtonActivation(child, handleSortOptionClick) -- inferred equivalent call
end

function Inventory.CreateItemTemplate(data)
	Profiler.mark("UI.Inventory.CreateItemTemplate")

	if not (data and data._id) then
		return
	end

	local v35 = data.Type == "Case" or data.Type == "Package"
	local v36 = v35 and Cases.GetCaseByName(data.Skin) or GetResolvedSkinInformation(data.Name, data.Skin)

	if not v36 then
		print(`[Inventory] Skipping template creation for item: {data.Name} | {data.Skin} (Type: {data.Type}) - No item information found`)
		return
	end

	local caseRarity = v35 and v36.caseRarity or v36.rarity
	local rarity = Rarities[caseRarity]
	local image = GetIconImage(data, v36, v35)
	local clone = ReplicatedStorage.Assets.UI.Inventory.ItemTemplate:Clone()
	clone.ItemContent.Rarity.BackgroundColor3 = rarity.Color
	clone.Parent = v16.Frame.Right.Container
	clone.ItemContent.Content.Icon.Image = image
	clone.Name = data._id
	local weaponProperties = GetWeaponProperties(data.Name)

	if weaponProperties and weaponProperties.InventoryIconData then
		clone.ItemContent.Content.Icon.ScaleType = weaponProperties.InventoryIconData.ScaleType
			or clone.ItemContent.Content.Icon.ScaleType
			or clone.ItemContent.Content.Icon.Position
		clone.ItemContent.Content.Icon.Size = weaponProperties.InventoryIconData.Size
			or clone.itemTemplate.ItemContent.Content.Icon.Size
	end

	syncItemTemplateCharmIcon(clone, data)
	ApplyWearAndSerialBadges(clone, data, v36)
	GetSkinDisplayName.ApplyNameLabel(clone.Bottom.Footer.WeaponName, GetItemDisplayName(data, v36, v35), data.NameTag) -- inferred equivalent call
	clone.Bottom.Footer.SkinName.Text = GetSkinDisplayName(v35 and v36.skin or data.Skin or "")
	UpdateStatusFrame(clone, data._id)
	clone.Selectable = true

	local function handleItemSelection(flag2: boolean?)
		if not v16.Ignore.ItemNotification.Visible then
			local vector = Vector2.new(mouse.X, mouse.Y)
			local v40

			if v16.Ignore.ItemNotification.Visible then
				v40 = true
			else
				local v41 = v15

				if v41 and v41.Visible then
					local absolutePosition = v41.AbsolutePosition
					local absoluteSize = v41.AbsoluteSize

					if
						vector.X >= absolutePosition.X
						and vector.X <= absolutePosition.X + absoluteSize.X
						and vector.Y >= absolutePosition.Y
					then
						v40 = vector.Y <= absolutePosition.Y + absoluteSize.Y
					else
						v40 = false
					end
				else
					v40 = false
				end

				if not v40 then
					local v42 = information

					if v42 and v42.Visible then
						local absolutePosition = v42.AbsolutePosition
						local absoluteSize = v42.AbsoluteSize

						if
							vector.X >= absolutePosition.X
							and vector.X <= absolutePosition.X + absoluteSize.X
							and vector.Y >= absolutePosition.Y
						then
							v40 = vector.Y <= absolutePosition.Y + absoluteSize.Y
						else
							v40 = false
						end
					else
						v40 = false
					end
				end
			end

			if not v40 then
				local inventory = DataController.Get(LocalPlayer, "Inventory")

				if inventory then
					for _, v42 in ipairs(inventory) do
						if v42._id ~= data._id then
							continue
						end

						data = v42
						break
					end
				end

				local v41 = data.Type == "Case" or data.Type == "Package"
				local v42 = data.Type == "Charm Capsule" or data.Type == "Sticker Capsule"
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				v6 = clone
				v3 = data
				Inventory.SetupInformationFrame(data)

				if not hasAnyInformationFrameButton() then -- inferred equivalent call
					information.Visible = false
					return
				end

				local function positionInformationFrame()
					local parent = information.Parent.Parent
					local absolutePosition = parent.AbsolutePosition
					local absoluteSize = parent.AbsoluteSize
					local x = nil
					local y = nil

					if UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1 or flag2 then
						if clone and clone:IsA("GuiObject") then
							local absolutePosition2 = clone.AbsolutePosition
							local absoluteSize2 = clone.AbsoluteSize
							x = absolutePosition2.X + absoluteSize2.X / 2
							y = absolutePosition2.Y + absoluteSize2.Y / 2
						end
					else
						x = mouse.X
						y = mouse.Y
					end

					local v43, v44

					if x then
						local v45 = (x - absolutePosition.X) / absoluteSize.X
						v43 = (y - absolutePosition.Y) / absoluteSize.Y + information.Size.Y.Scale / 2

						if 1 - v45 >= information.Size.X.Scale + 0.01 then
							v44 = v45 + information.Size.X.Scale / 2 + 0.01
						else
							v44 = v45 - information.Size.X.Scale / 2 - 0.01
						end
					else
						v44 = 0.5
						v43 = 0.5
					end

					information.Position = UDim2.fromScale(v44, v43)
				end

				if v41 or v42 then
					information.Visible = true
					positionInformationFrame()
					v16.Ignore.Hover.Visible = false

					if flag2 then
						Profiler.defer("UI.Inventory.InformationNavigationDeferred", function()
							Inventory.SetupInformationFrameNavigation()
							Inventory.SelectFirstInformationFrameButton()
						end)
					end
				else
					if flag2 then
						information.Visible = true
					else
						information.Visible = not information.Visible
					end

					if information.Visible then
						positionInformationFrame()
						v16.Ignore.Hover.Visible = false
						Profiler.defer("UI.Inventory.InformationNavigationDeferred", function()
							Inventory.SetupInformationFrameNavigation()

							if flag2 then
								Inventory.SelectFirstInformationFrameButton()
							end
						end)
					elseif v5 then
						now = tick()
					end
				end
			end
		end
	end

	clone.MouseButton1Click:Connect(function()
		handleItemSelection(false)
	end)
	clone.Activated:Connect(function(p)
		if p and p.UserInputType == Enum.UserInputType.Gamepad1 then
			handleItemSelection(true)
		end
	end)

	if v2 then
		clone.MouseEnter:Connect(function()
			v4 = data
			v5 = clone
			now = tick()
		end)
		clone.MouseLeave:Connect(function()
			v5 = nil
			v4 = nil
			now = nil
		end)
	end
end

function Inventory.UpdateInventory(list)
	Profiler.mark("UI.Inventory.UpdateInventory")

	if not v16 then
		return
	end

	if not list or type(list) ~= "table" then
		print("UpdateInventory received invalid inventory data:", list)
		return
	end

	if not v16.Visible then
		return
	end

	local container = v16.Frame.Right.Container
	local v35 = {}

	for _, v36 in ipairs(list) do
		if v36 and v36._id then
			v35[v36._id] = true
		end
	end

	if v3 and v3._id and not v35[v3._id] then
		v3 = nil
		v6 = nil
		v4 = nil

		if information then
			information.Visible = false
		end
	end

	for _, child in ipairs(container:GetChildren()) do
		if not IsItemTemplate(child) or v35[child.Name] then -- inferred equivalent call
			continue
		end

		child:Destroy()
	end

	ApplyCurrentSort() -- inferred equivalent call
end

function Inventory.UpdateTemplates(list)
	Profiler.mark("UI.Inventory.UpdateTemplates")

	if not (v16 and v16.Visible) then
		return
	end

	local container = v16.Frame.Right.Container

	if list then
		for _, v35 in ipairs(list) do
			local frame = container:FindFirstChild(v35._id)

			if not (frame and frame:IsA("Frame")) then
				continue
			end

			local resolvedSkinInformation = GetResolvedSkinInformation(v35.Name, v35.Skin)

			if resolvedSkinInformation then
				frame.Main.RarityFrame.UIGradient.Color = Rarities[resolvedSkinInformation.rarity].ColorSequence
				frame.Main.Glow.UIGradient.Color = Rarities[resolvedSkinInformation.rarity].ColorSequence
				frame.Main.Icon.Image = GetIconImage(v35, resolvedSkinInformation, false)
			end

			syncItemTemplateCharmIcon(frame, v35)
			UpdateStatusFrame(frame, v35._id)
		end
	end
end

function Inventory.SetupInformationFrameNavigation()
	if not information then
		return
	end

	local visibleInformationFrameButtons = GetVisibleInformationFrameButtons()
	table.sort(visibleInformationFrameButtons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for i, v36 in ipairs(visibleInformationFrameButtons) do
		v36.NextSelectionUp = visibleInformationFrameButtons[i > 1 and i - 1 or #visibleInformationFrameButtons]
		v36.NextSelectionDown = visibleInformationFrameButtons[i < #visibleInformationFrameButtons and i + 1 or 1]
		v36.NextSelectionLeft = nil
		v36.NextSelectionRight = nil
	end
end

function Inventory.SetupItemNotificationNavigation()
	if not (v16 and v16.Ignore.ItemNotification) then
		return
	end

	local holder = v16.Ignore.ItemNotification.Holder
	local left

	if holder.Left.Visible then
		left = holder.Left
	end

	local right

	if holder.Right.Visible then
		right = holder.Right
	end

	local v35 = {}

	for _, v36 in { holder.ViewLoadout, holder.Continue } do
		if v36 and v36.Visible then
			table.insert(v35, v36)
		end
	end

	table.sort(v35, function(a, b)
		return a.AbsolutePosition.X < b.AbsolutePosition.X
	end)
	local nextSelectionDown = v35[1]
	local nextSelectionDown2 = v35[#v35]

	for i, v38 in ipairs(v35) do
		v38.NextSelectionLeft = v35[i - 1] or left
		v38.NextSelectionRight = v35[i + 1] or right
		v38.NextSelectionUp = right or left
		v38.NextSelectionDown = nil
	end

	if left then
		left.NextSelectionLeft = nil
		left.NextSelectionRight = right or nextSelectionDown
		left.NextSelectionUp = nil
		left.NextSelectionDown = nextSelectionDown
	end

	if right then
		right.NextSelectionLeft = left or nextSelectionDown2
		right.NextSelectionRight = nil
		right.NextSelectionUp = nil
		right.NextSelectionDown = nextSelectionDown2
	end
end

function Inventory.EnsureItemNotificationSelection()
	if not (UserInputService.GamepadEnabled and v16.Ignore.ItemNotification.Visible) then
		return
	end

	local holder = v16.Ignore.ItemNotification.Holder
	local selectedObject = GuiService.SelectedObject

	if
		selectedObject
		and selectedObject:IsDescendantOf(holder)
		and selectedObject:IsA("GuiButton")
		and selectedObject.Visible
	then
		return
	end

	if selectedObject == holder.Left and holder.Right.Visible then
		GuiService.SelectedObject = holder.Right
	elseif selectedObject == holder.Right and holder.Left.Visible then
		GuiService.SelectedObject = holder.Left
	else
		Inventory.SelectFirstItemNotificationButton()
	end
end

function Inventory.SelectFirstItemNotificationButton()
	if not (UserInputService.GamepadEnabled and (v16 and v16.Ignore.ItemNotification and v16.Ignore.ItemNotification.Visible)) then
		return
	end

	local holder = v16.Ignore.ItemNotification.Holder

	if holder.ViewLoadout and holder.ViewLoadout.Visible and holder.ViewLoadout.Selectable then
		GuiService.SelectedObject = holder.ViewLoadout
	elseif holder.Continue and holder.Continue.Visible and holder.Continue.Selectable then
		GuiService.SelectedObject = holder.Continue
	end
end

function Inventory.SelectFirstInformationFrameButton()
	if not (information and information.Visible) then
		return
	end

	Inventory.SetupInformationFrameNavigation()
	local selectedObject = GetVisibleInformationFrameButtons()[1]

	if selectedObject then
		GuiService.SelectedObject = selectedObject
	end
end

function Inventory.SetupInformationFrame(data)
	Profiler.mark("UI.Inventory.SetupInformationFrame")
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if inventory then
		data = GetInventoryItemFromIdentifier(inventory, data._id) or data -- inferred equivalent call
	end

	local v35 = data.Type == "Weapon"
	local v36 = data.Type == "Melee"
	local v37 = data.Type == "Glove"
	local v38 = data.Type == "Badge"
	local v39 = data.Type == "Zeus x27"
	information.Inspect.Visible = v35 or v37 or v36 or v39 or data.Type == "Charm" or v38
	local v40

	if data.Type == "Case" then
		v40 = Cases.GetCaseByName(data.Skin)
	end

	local unlock = information.Unlock
	local visible

	if data.Type == "Package" then
		visible = true
	elseif v40 == nil then
		visible = false
	else
		visible = Cases.HasCaseModel(v40.caseId)
	end

	unlock.Visible = visible
	information.Loadout.Visible = false
	local quickUnlock = information:FindFirstChild("QuickUnlock")

	if quickUnlock then
		quickUnlock.Visible = false
	end

	local unlockDivider = information:FindFirstChild("UnlockDivider")

	if unlockDivider then
		unlockDivider.Visible = false
	end

	local visible2 = v35 or v39 or data.Type == "Charm"

	if not information.Charm then
		warn("[Inventory] InformationFrame.Charm element not found - item type:", data.Type)
	end

	if information.Charm then
		information.Charm.Visible = visible2
		local textLabel = visible2 and information.Charm:FindFirstChildWhichIsA("TextLabel", true)

		if textLabel then
			if data.Type == "Charm" then
				textLabel.Text = "Attach to Weapon"
			else
				textLabel.Text = ItemHasCharm(data) and "Detach Charm" or "Attach Charm" -- inferred equivalent call
			end
		end
	end

	local v43 = false
	local v44 = false

	local function applyTeamRestriction(team: string?) -- 2 equivalent calls inferred from this helper
		v43 = team == "Both" or team == "Counter-Terrorists"
		v44 = team == "Both" or team == "Terrorists"
	end

	if v35 then
		local success, result = pcall(GetWeaponProperties, data.Name)

		if success and result then
			applyTeamRestriction(result.Team) -- inferred equivalent call
		end
	elseif v36 then
		if data.Name == "T Knife" then
			v43 = false
		else
			v43 = true
		end

		if data.Name == "CT Knife" then
			v44 = false
		else
			v44 = true
		end
	elseif v37 then
		local weaponProperties = GetWeaponProperties(data.Name)

		if weaponProperties then
			applyTeamRestriction(weaponProperties.Team) -- inferred equivalent call
		end
	elseif v38 or v39 then
		v43 = true
		v44 = true
	end

	local equippedOnTeam = IsEquippedOnTeam(data._id, "Counter-Terrorists")
	local equippedOnTeam2 = IsEquippedOnTeam(data._id, "Terrorists")
	local v45 = v35 or v36 or v37 or v38 or v39

	if information.ReplaceCT then
		information.ReplaceCT.Visible = v45 and v43 and not equippedOnTeam
	end

	if information.ReplaceT then
		information.ReplaceT.Visible = v45 and v44 and not equippedOnTeam2
	end

	local v46 = {
		{ dividerName = "CharmDivider", action = information.Charm },
		{ dividerName = "InspectDivider", action = information.Inspect },
		{ dividerName = "ReplaceCTDivider", action = information.ReplaceCT },
		{ dividerName = "ReplaceTDivider", action = information.ReplaceT },
		{ dividerName = "LoadoutDivider", action = information.Loadout }
	}
	local v47 = { UnlockDivider = true }

	for _, v48 in ipairs(v46) do
		v47[v48.dividerName] = true
	end

	for _, v48 in ipairs(v46) do
		local child = information:FindFirstChild(v48.dividerName)

		if not (child and v48.action) then
			continue
		end

		local visible3 = false

		if v48.action.Visible then
			for _, guiObject in ipairs(information:GetChildren()) do
				if
					v47[guiObject.Name]
					or guiObject == child
					or guiObject == v48.action
					or not (guiObject:IsA("Frame") or guiObject:IsA("TextButton"))
				then
					continue
				end

				if not (guiObject.LayoutOrder < child.LayoutOrder and guiObject.Visible) then
					continue
				end

				visible3 = true
				break
			end
		end

		child.Visible = visible3
	end
end

function Inventory:ShowNewItemNotification()
	Profiler.mark("UI.Inventory.ShowNewItemNotification")
	local queuedItemIndex = FindQueuedItemIndex(self._id) -- inferred equivalent call

	if queuedItemIndex then
		id = nil

		if v16.Visible then
			id2 = self._id
			Inventory.NextInventoryItem(queuedItemIndex)
		else
			v7 = queuedItemIndex - 1
		end
	else
		id = self._id
	end

	v16.Visible = true
	syncInventoryUpdate()
end

function Inventory.NextInventoryItem(p: number)
	Profiler.mark("UI.Inventory.NextInventoryItem")
	local v35 = v19[p]
	v7 = p

	if v35 then
		MarkItemViewed(v35._id) -- inferred equivalent call
		local v36 = v35.Type == "Case" or v35.Type == "Package"
		local v37 = v36 and Cases.GetCaseByName(v35.Skin) or GetResolvedSkinInformation(v35.Name, v35.Skin)
		local caseRarity = v37 and (v36 and v37.caseRarity or v37.rarity) or v35.Rarity or "Blue"
		local v38 = Rarities[caseRarity] or Rarities.Blue
		local skin

		if v36 and v37 and v37.Skin then
			skin = v37.Skin
		else
			local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(v35.Name, v35.NameTag)

			if v35.StatTrack then
				weaponDisplayName = "KillTrak™ " .. weaponDisplayName or weaponDisplayName
			end

			skin = `{weaponDisplayName} | {v35.Skin}`
		end

		local image = GetIconImage(v35, v37, v36)
		local viewLoadout = v16.Ignore.ItemNotification.Holder.ViewLoadout
		viewLoadout.Visible = v35.Type ~= "Case" and v35.Type ~= "Package"
		v16.Ignore.ItemNotification.Holder.RarityFrame.UIGradient.Color = v38.ColorSequence
		v16.Ignore.ItemNotification.Holder.Background.ImageColor3 = v38.Color
		v16.Ignore.ItemNotification.Holder.IconShadow.Image = image
		v16.Ignore.ItemNotification.Holder.Light.ImageColor3 = v38.Color
		GetSkinDisplayName.ApplyNameLabel(v16.Ignore.ItemNotification.Holder.WeaponName, skin, v35.NameTag)
		v16.Ignore.ItemNotification.Holder.Icon.Image = image
		v16.Ignore.ItemNotification.Visible = true

		if not v24 then
			v24 = true
			Router.broadcastRouter("RunInterfaceSound", "New Item Reveal")
		end

		v16.Ignore.ItemNotification.Holder.Title.TextColor3 = Color3.new(
			v38.Color.R * 0.56,
			v38.Color.G * 0.56,
			v38.Color.B * 0.56
		)
		Profiler.defer("UI.Inventory.ItemNotificationDeferred", function()
			Inventory.SetupItemNotificationNavigation()
			Inventory.EnsureItemNotificationSelection()
		end)
		syncInventoryUpdate()
	end
end

local v35 = {
	Blue = 1,
	Purple = 2,
	Pink = 3,
	Red = 4,
	Special = 5,
	Forbidden = 6,
	Stock = 7
}
local v36 = {
	Blue = "Blue",
	Purple = "Purple",
	Pink = "Pink",
	Red = "Red",
	Special = "★ Special",
	Forbidden = "★ Special"
}

local function ClearHoverCollectionFrames(collection)
	for _, frame in ipairs(collection:GetChildren()) do
		if frame:IsA("Frame") and frame.Name ~= "UIListLayout" then
			frame:Destroy()
		end
	end
end

local function HideHoverCollection() -- 1 equivalent call inferred from this helper
	local collection = v16.Ignore.Hover.Collection

	if collection then
		ClearHoverCollectionFrames(collection)
		collection.Visible = false
	end

	v16.Ignore.Hover.CollectionName.Visible = false
	v16.Ignore.Hover.CollectionSpacer.Visible = false
end

local function ShowHoverCollection(p, collectionName)
	local collection = v16.Ignore.Hover.Collection
	local inventory = DataController.Get(LocalPlayer, "Inventory")
	ClearHoverCollectionFrames(collection)
	local v37 = {}

	if inventory then
		for _, v38 in ipairs(inventory) do
			if v38.Name and v38.Skin then
				v37[v38.Name .. "|" .. v38.Skin] = true
			end
		end
	end

	local v38 = {}

	for _, item in ipairs(p.items) do
		if not (item.itemName and item.skinName) then
			continue
		end

		local resolvedSkinInformation = GetResolvedSkinInformation(item.itemName, item.skinName)

		if resolvedSkinInformation then
			table.insert(v38, {
				item = item,
				rarity = resolvedSkinInformation.rarity,
				rarityOrder = v35[resolvedSkinInformation.rarity] or 99
			})
		end
	end

	table.sort(v38, function(a, b)
		if a.rarityOrder == b.rarityOrder then
			return a.item.itemName < b.item.itemName
		end

		return a.rarityOrder < b.rarityOrder
	end)
	local collectionNameTemplate = ReplicatedStorage.Assets.UI.Inventory.CollectionNameTemplate

	for i, v39 in ipairs(v38) do
		local item = v39.item
		local resolvedSkinInformation = GetResolvedSkinInformation(item.itemName, item.skinName)

		if not (resolvedSkinInformation and collectionNameTemplate) then
			continue
		end

		local clone = collectionNameTemplate:Clone()
		clone.Parent = collection
		clone.LayoutOrder = i
		clone.Visible = true
		local gun = clone.gun
		gun.Text = "[" .. item.itemName .. "] | " .. item.skinName
		local v41 = resolvedSkinInformation.rarity and Rarities[resolvedSkinInformation.rarity]

		if v41 then
			gun.TextColor3 = v41.Color
		end

		gun.Visible = true
		clone.ImageLabel.Visible = v37[item.itemName .. "|" .. item.skinName] == true
	end

	collectionName.Visible = true
	collection.Visible = true
	v16.Ignore.Hover.CollectionSpacer.Visible = true
end

function Inventory.UpdateHoverFrame(_: number)
	local v37 = tick() - (now or 0)
	local vector = Vector2.new(mouse.X, mouse.Y)
	local v38

	if v16.Ignore.ItemNotification.Visible then
		v38 = true
	else
		local v39 = v15

		if v39 and v39.Visible then
			local absolutePosition = v39.AbsolutePosition
			local absoluteSize = v39.AbsoluteSize

			if
				vector.X >= absolutePosition.X
				and vector.X <= absolutePosition.X + absoluteSize.X
				and vector.Y >= absolutePosition.Y
			then
				v38 = vector.Y <= absolutePosition.Y + absoluteSize.Y
			else
				v38 = false
			end
		else
			v38 = false
		end

		if not v38 then
			local v40 = information

			if v40 and v40.Visible then
				local absolutePosition = v40.AbsolutePosition
				local absoluteSize = v40.AbsoluteSize

				if
					vector.X >= absolutePosition.X
					and vector.X <= absolutePosition.X + absoluteSize.X
					and vector.Y >= absolutePosition.Y
				then
					v38 = vector.Y <= absolutePosition.Y + absoluteSize.Y
				else
					v38 = false
				end
			else
				v38 = false
			end
		end
	end

	if not v16.Visible or v38 or information.Visible or not (v5 and v4 and v37 > 0.75) then
		v16.Ignore.Hover.Visible = false
		return
	end

	v16.Ignore.Hover.Position = CalculateHoverPosition(v5)
	local v39 = v4
	local v40 = v39.Type == "Case" or v39.Type == "Package"
	local v41 = v40 and Cases.GetCaseByName(v39.Skin) or GetResolvedSkinInformation(v39.Name, v39.Skin)

	if v41 then
		local itemDisplayName = GetItemDisplayName(v39, v41, v40) -- inferred equivalent call
		local skinDisplayName = GetSkinDisplayName(v40 and v41.skin or v39.Skin)
		local v44 = skinDisplayName == "Vanilla" and "" or " | " .. skinDisplayName
		GetSkinDisplayName.ApplyNameLabel(v16.Ignore.Hover.ItemName.Frame.ItemName, itemDisplayName .. v44, v39.NameTag)
		local collectionNameForItem = GetCollectionNameForItem(v39)
		v16.Ignore.Hover.ItemName.Frame.Collection.Text = collectionNameForItem or ""
		local collectionIcon = v16.Ignore.Hover.ItemName.CollectionIcon
		local v46 = collectionNameForItem and Collections.GetCollectionByName(collectionNameForItem)

		if v46 and v46.imageAssetId then
			collectionIcon.Image = v46.imageAssetId
			collectionIcon.Visible = true
		else
			collectionIcon.Visible = false
		end

		local collectionName = v16.Ignore.Hover.CollectionName

		if collectionNameForItem then
			collectionName.Text = collectionNameForItem .. ":"
			collectionName.Visible = true
		else
			collectionName.Visible = false
		end

		local v47 = collectionNameForItem and not v40 and Collections.GetCollectionByName(collectionNameForItem)

		if v47 and v47.items then
			ShowHoverCollection(v47, collectionName)
		else
			HideHoverCollection() -- inferred equivalent call
		end

		local description

		if v40 or v39.Type ~= "Weapon" and v39.Type ~= "Melee" and v39.Type ~= "Glove" and v39.Type ~= "Zeus x27" then
			description = v41.description
		else
			local resolvedSkinInformation = GetResolvedSkinInformation(
				v39.Type == "Melee" and "T Knife" or v39.Type == "Glove" and "T Glove" or v39.Name,
				"Stock"
			)
			description = resolvedSkinInformation and resolvedSkinInformation.description
		end

		v16.Ignore.Hover.Description.Text = description or ""
		local v48 = v39.Type == "Charm Capsule" or v39.Type == "Sticker Capsule"
		v16.Ignore.Hover.Information.Visible = not (v40 or v48)
		local caseRarity = v40 and v41.caseRarity or v41.rarity
		local v49 = caseRarity and Rarities[caseRarity]

		if v49 then
			v16.Ignore.Hover.Information.Rarity.Label.Text = v36[caseRarity] or caseRarity
			v16.Ignore.Hover.Information.Rarity.Label.TextColor3 = v49.Color
		else
			v16.Ignore.Hover.Information.Rarity.Label.Text = ""
		end

		local exterior = v16.Ignore.Hover.Information.Exterior
		local v50, text

		if not v40 then
			v50, text = Skins.GetWearNameForFloat(v41, v39.Float or v41.floatRange.max)
		end

		if v50 and text then
			exterior.Label.Text = text
			exterior.Visible = true
		else
			exterior.Visible = false
		end

		local team = v16.Ignore.Hover.Information.Team.Team
		local text2 = nil

		if
			v39.Type == "Melee"
			or v39.Type == "Glove"
			or v39.Type == "Badge"
			or v39.Type == "Charm"
			or v39.Type == "Zeus x27"
		then
			text2 = "Both"
		elseif v39.Type == "Weapon" then
			local weaponProperties = GetWeaponProperties(v39.Name)
			local team2 = weaponProperties and weaponProperties.Team

			if team2 then
				text2 = team2 ~= "Counter-Terrorists" and team2 ~= "Terrorists" and "Both" or team2
			end
		end

		if text2 then
			team.CT.Visible = text2 ~= "Terrorists"
			team.T.Visible = text2 ~= "Counter-Terrorists"
			team.Label.Visible = true
			team.Label.Text = text2
		end
	end

	v16.Ignore.Hover.Visible = true
end

function Inventory.Initialize(p, p2)
	Profiler.mark("UI.Inventory.Initialize")
	parent2 = p
	v16 = p2
	information = p2.Ignore.Information
	CloseButtonRegistry.Add(information, nil, function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		information.Visible = false

		if v6 and v6:FindFirstChild("Button") then
			local button = v6:FindFirstChild("Button")

			if button and button:IsA("GuiButton") then
				GuiService.SelectedObject = button
			end
		end
	end)
	Collections.ObserveAvailableCollections(function(p3)
		v9 = p3
	end)
	information.Inspect.Selectable = true

	local function handleInspectClick()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")

		if v3 then
			information.Visible = false
			InspectInventoryItem(v3) -- inferred equivalent call
		end
	end

	ActivateButton(information.Inspect)
	ConnectButtonActivation(information.Inspect, handleInspectClick) -- inferred equivalent call

	if information.Charm then
		information.Charm.Selectable = true

		local function handleCharmClick()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")

			if v3 then
				local itemHasCharm = ItemHasCharm(v3) -- inferred equivalent call
				information.Visible = false

				if itemHasCharm then
					Remotes.Inventory.RemoveWeaponCharm.Send({ WeaponId = v3._id })
				else
					v16.Visible = false
					UseItemFrame.TriggerAction("AttachCharm", v3)
				end
			end
		end

		ConnectButtonActivation(information.Charm, handleCharmClick) -- inferred equivalent call
	end

	UseItemFrame.OnItemSelected:Connect(function(p3, p4)
		local v37 = UseItemFrame.GetActions().Get(p4.ActionType)

		if v37 then
			v37.OnItemSelected(p3, p4)
		end
	end)
	UseItemFrame.OnClosed:Connect(function(_)
		if MenuState.GetCurrentScreen() == "Inventory" then
			v16.Visible = true
		end
	end)
	information.Unlock.Selectable = true

	local function handleUnlockClick()
		if flag then
			return
		end

		Router.broadcastRouter("RunInterfaceSound", "UI Click")

		if v3 then
			local case = Cases.GetCaseByName(v3.Skin)

			if case and Cases.HasCaseModel(case.caseId) then
				Store.OpenCaseContent(case.caseId, "Open", v3._id)
				information.Visible = false
				v16.Visible = false
			end
		end
	end

	ConnectButtonActivation(information.Unlock, handleUnlockClick) -- inferred equivalent call

	local function setupReplaceButton(p3, team: string)
		if not p3 then
			return
		end

		p3.Selectable = true

		local function fn()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")

			if v3 then
				information.Visible = false
				ReplaceItemOnTeam(v3, team)
			end
		end

		ConnectButtonActivation(p3, fn) -- inferred equivalent call
	end

	local replaceT = information.ReplaceT

	if replaceT then
		replaceT.Selectable = true
		local team = "Terrorists"

		local function fn()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")

			if v3 then
				information.Visible = false
				ReplaceItemOnTeam(v3, team)
			end
		end

		ConnectButtonActivation(replaceT, fn) -- inferred equivalent call
	end

	local replaceCT = information.ReplaceCT

	if replaceCT then
		replaceCT.Selectable = true
		local team = "Counter-Terrorists"

		local function fn()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")

			if v3 then
				information.Visible = false
				ReplaceItemOnTeam(v3, team)
			end
		end

		ConnectButtonActivation(replaceCT, fn) -- inferred equivalent call
	end

	local itemNotification = v16.Ignore.ItemNotification

	local function stepItemNotification(p3: number) -- 4 equivalent calls inferred from this helper
		local v37 = v7 + p3

		if v37 >= 1 and v37 <= #v19 then
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			Inventory.NextInventoryItem(v37)
		end
	end

	itemNotification.Holder.Left.Selectable = true
	itemNotification.Holder.Right.Selectable = true
	itemNotification.Holder.Left.MouseButton1Click:Connect(function()
		stepItemNotification(-1) -- inferred equivalent call
	end)
	itemNotification.Holder.Right.MouseButton1Click:Connect(function()
		stepItemNotification(1) -- inferred equivalent call
	end)
	MenuState.RegisterBumperOverride(itemNotification, function(flag2: boolean)
		local v37 = v7 + (flag2 and -1 or 1)

		if v37 >= 1 and v37 <= #v19 then
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			Inventory.NextInventoryItem(v37)
		end

		return true
	end, itemNotification)
	UserInputService.InputBegan:Connect(function(input, gameProcessed: boolean)
		if
			gameProcessed
			or LocalPlayer:GetAttribute("IsPlayerChatting")
			or UserInputService:GetFocusedTextBox()
			or not (v16 and v16.Ignore.ItemNotification and v16.Ignore.ItemNotification.Visible)
		then
			return
		end

		if input.KeyCode == Enum.KeyCode.Left then
			stepItemNotification(-1) -- inferred equivalent call
		else
			if input.KeyCode ~= Enum.KeyCode.Right then
				return
			end

			stepItemNotification(1) -- inferred equivalent call
		end
	end)
	v16.Ignore.ItemNotification.Holder.Continue.Selectable = true
	v16.Ignore.ItemNotification.Holder.ViewLoadout.Selectable = true

	local function handleContinueClick() -- 1 equivalent call inferred from this helper
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		DismissItemNotifications()
	end

	local continue = v16.Ignore.ItemNotification.Holder.Continue
	continue.MouseButton1Click:Connect(handleContinueClick)
	continue.Activated:Connect(function(p3)
		if p3 and p3.UserInputType == Enum.UserInputType.Gamepad1 then
			handleContinueClick()
		end
	end)

	local function handleViewLoadoutClick()
		local v37 = v19[v7]
		handleContinueClick() -- inferred equivalent call

		if v37 and (v37.Type == "Melee" or v37.Type == "Glove" or v37.Type == "Weapon" or v37.Type == "Zeus x27") then
			v16.Visible = false
			Loadout.ViewInLoadout(v37._id)
		end
	end

	ConnectButtonActivation(v16.Ignore.ItemNotification.Holder.ViewLoadout, handleViewLoadoutClick) -- inferred equivalent call
	local filter = v16.Frame.Right.Top.Filter
	local dropdownContent = filter.DropdownContent
	v15 = dropdownContent
	filter.Active = true
	filter.Selectable = true
	setSortDropdownOpen(false) -- inferred equivalent call

	local function handleSortButtonClick()
		setSortDropdownOpen(not dropdownContent.Visible) -- inferred equivalent call
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
	end

	filter.Activated:Connect(handleSortButtonClick)
	BindSortDropdownFocus(dropdownContent, filter, function()
		return v10 or filter.Container.Left.Title.Text
	end, "UI.Inventory.SortFocusDeferred")
	local reverseSort = v16.Frame.Right.Top.ReverseSort

	local function handleReverseSortButtonClick()
		v11 = not v11
		setReverseSortVisual(reverseSort, v11) -- inferred equivalent call
		Profiler.mark("UI.Inventory.ApplyCurrentSort")

		if v16 and v16.Visible then
			v = GetSortedInventoryData()
			v = ApplyFilterToSortedData(v)
			UpdateInventoryTemplates()
		end

		Router.broadcastRouter("RunInterfaceSound", "UI Click")
	end

	reverseSort.Selectable = true
	reverseSort.Activated:Connect(handleReverseSortButtonClick)

	for _, childName in {
		"Alphabetical",
		"Collection",
		"Equipped",
		"Newest",
		"Quality",
		"Type",
		"Float",
		"Serial"
	} do
		local child = dropdownContent.Scroll:FindFirstChild(childName)

		if not child then
			continue
		end

		local scroll = dropdownContent.Scroll
		local title = filter.Container.Left.Title

		local function fn()
			SetDropdownOpen(v15, false) -- inferred equivalent call
		end

		AnimateSortButton(scroll, child, childName, title, fn) -- inferred equivalent call
	end

	local title = v16.Frame.Right.Top.Search.Container.Container.Title
	BindSearchTap(v16.Frame.Right.Top.Search, title)
	local tradeUp = v16.Frame.Right.Top.TradeUp
	local tradeUp2 = v16.Frame.TradeUp
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local container = tradeUp2.TradeContainer.Container
	local itemTemplate = container.ItemTemplate
	local exchange = tradeUp2.TradeContainer.Exchange
	local itemTemplate2 = exchange.ItemTemplate
	local addTemplate = exchange.AddTemplate
	itemTemplate.Visible = false
	itemTemplate2.Visible = false
	addTemplate.Visible = false
	local v37 = { Blue = "Purple", Purple = "Pink", Pink = "Red" }
	local v38 = { Blue = true, Purple = true, Pink = true }
	local v39 = {
		"Alphabetical",
		"Collection",
		"Equipped",
		"Newest",
		"Quality",
		"Type",
		"Float",
		"Serial"
	}

	for _, folder in { itemTemplate, itemTemplate2, addTemplate } do
		for _, guiObject in ipairs(folder:GetDescendants()) do
			if not guiObject:IsA("GuiObject") then
				continue
			end

			guiObject.Active = false

			if not guiObject:IsA("GuiButton") then
				continue
			end

			guiObject.Interactable = false
			guiObject.Selectable = false
		end

		if folder:FindFirstChildOfClass("UIScale") then
			continue
		end

		local uiScale = Instance.new("UIScale")
		uiScale.Parent = folder
	end

	for _, v40 in { itemTemplate, itemTemplate2 } do
		local context = v40:FindFirstChild("Context")

		if context and context:IsA("GuiObject") then
			context.Visible = false
		end
	end

	for _, v40 in { container, exchange } do
		local uiGridLayout = v40:FindFirstChildOfClass("UIGridLayout")

		if uiGridLayout then
			uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
		end
	end

	local v40 = nil

	for _, child in ipairs(tradeUp2.Warning:GetChildren()) do
		if child.Name ~= "WarningForTradeUp" then
			continue
		end

		local container2 = child:FindFirstChild("Container")
		local left = container2 and container2:FindFirstChild("Left")
		local title2 = left and left:FindFirstChild("Title")

		if not (title2 and title2:IsA("TextLabel") and string.find(title2.Text, "Selected For Exchange", 1, true)) then
			continue
		end

		v40 = title2
		break
	end

	local v42 = "Newest"
	local v43 = false
	local v44 = {}
	local ids = {}
	local v45 = nil
	local selectTradeUpItem
	local deselectTradeUpItem
	local v46 = {}
	local flag2 = true
	DataController.CreateListener(LocalPlayer, "Inventory", function()
		flag2 = true
	end)

	local function getTradeUpSearchable(p3) -- 1 equivalent call inferred from this helper
		local v47 = string.lower((p3.Name or "") .. " " .. (p3.Skin or ""))

		if string.find(v47, "zeus", 1, true) then
			return v47 .. " taser"
		end

		return v47
	end

	local function tradeUpMatchesSearch(searchable: string)
		if #v44 == 0 then
			return true
		end

		for _, v47 in ipairs(v44) do
			if string.find(searchable, v47, 1, true) == nil then
				return false
			end
		end

		return true
	end

	local v47 = {}
	Collections.ObserveAvailableCollections(function()
		table.clear(v47)
		flag2 = true
	end)

	local function collectionHasNextTier(collection: string?, rarity: string)
		if not collection or collection == "" then
			return false
		end

		local v48 = v37[rarity]

		if not (v48 and v9) then
			return false
		end

		local v49 = collection .. "|" .. v48
		local v50 = v47[v49]

		if v50 ~= nil then
			return v50
		end

		local v51 = false

		for _, v53 in ipairs(v9) do
			if v53.name ~= collection then
				continue
			end

			for _, v55 in ipairs(v53.items or {}) do
				local resolvedSkinInformation = GetResolvedSkinInformation(v55.itemName, v55.skinName)

				if not (resolvedSkinInformation and resolvedSkinInformation.rarity == v48) then
					continue
				end

				v51 = true
				break
			end

			break
		end

		v47[v49] = v51
		return v51
	end

	local v48 = {}

	local function getEligibleTradeUpInfo(data)
		if data.Type ~= "Weapon" and data.Type ~= "Zeus x27" then
			return nil
		end

		local v49 = (data.Name or "") .. "|" .. (data.Skin or "")
		local v50 = v48[v49]

		if v50 == nil then
			v50 = GetResolvedSkinInformation(data.Name, data.Skin)

			if v50 then
				v48[v49] = v50
			end
		end

		if not v50 then
			return nil
		end

		local rarity = v50.rarity

		if rarity and v38[rarity] and collectionHasNextTier(v50.collection, rarity) then
			return v50
		end

		return nil
	end

	local function getTradeUpKey(p3, p4) -- 2 equivalent calls inferred from this helper
		return tostring(p4.rarity) .. "|" .. (p3.StatTrack and "ST" or "N")
	end

	local function isTradeUpSelected(p3: string)
		return table.find(ids, p3) ~= nil
	end

	local function updateTradeUpWarning() -- 3 equivalent calls inferred from this helper
		if v40 then
			v40.Text = `{#ids}/{10} Selected For Exchange`
		end
	end

	local function clearRenderedItems(container2, itemTemplate3)
		for _, guiObject in ipairs(container2:GetChildren()) do
			if guiObject:IsA("GuiObject") and guiObject ~= itemTemplate3 then
				guiObject:Destroy()
			end
		end
	end

	local function buildTradeUpFrame(itemTemplate3, parent, data, p3, fn)
		local rarity = Rarities[p3.rarity]
		local clone = itemTemplate3:Clone()
		clone.Name = data._id
		clone.Parent = parent
		clone.Visible = true
		clone.Selectable = true
		clone.ItemContent.Rarity.BackgroundColor3 = rarity.Color
		clone.ItemContent.Content.Icon.Image = GetIconImage(data, p3, false)
		local weaponProperties = GetWeaponProperties(data.Name)

		if weaponProperties and weaponProperties.InventoryIconData then
			clone.ItemContent.Content.Icon.ScaleType = weaponProperties.InventoryIconData.ScaleType
				or clone.ItemContent.Content.Icon.ScaleType
			clone.ItemContent.Content.Icon.Size = weaponProperties.InventoryIconData.Size
				or clone.ItemContent.Content.Icon.Size
		end

		syncItemTemplateCharmIcon(clone, data)
		local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag)

		if data.StatTrack then
			weaponDisplayName = "KillTrak™ " .. weaponDisplayName or weaponDisplayName
		end

		GetSkinDisplayName.ApplyNameLabel(clone.Bottom.Footer.WeaponName, weaponDisplayName, data.NameTag)
		clone.Bottom.Footer.SkinName.Text = GetSkinDisplayName(data.Skin or "")
		local context = clone:FindFirstChild("Context")
		local inspect = clone.ItemContent:FindFirstChild("Inspect")

		if inspect then
			inspect.Visible = true
			inspect.Active = true
			inspect.Interactable = true
			inspect.MouseButton1Click:Connect(function()
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				InspectInventoryItem(data) -- inferred equivalent call
			end)
		end

		local uiScale = clone:FindFirstChildOfClass("UIScale")
		clone.MouseEnter:Connect(function()
			if context then
				context.Visible = true
			end

			Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
			TweenService:Create(uiScale, tweenInfo, { Scale = 0.95 }):Play()

			if v2 then
				v4 = data
				v5 = clone
				now = tick()
			end
		end)
		clone.MouseLeave:Connect(function()
			if context then
				context.Visible = false
			end

			TweenService:Create(uiScale, tweenInfo, { Scale = 1 }):Play()

			if v2 and v5 == clone then
				v5 = nil
				v4 = nil
				now = nil
			end
		end)
		clone.SelectionGained:Connect(function()
			if context then
				context.Visible = true
			end
		end)
		clone.SelectionLost:Connect(function()
			if context then
				context.Visible = false
			end
		end)
		clone.MouseButton1Down:Connect(function()
			TweenService:Create(uiScale, tweenInfo, { Scale = 0.9 }):Play()
		end)
		clone.MouseButton1Up:Connect(function()
			TweenService:Create(uiScale, tweenInfo, { Scale = 0.95 }):Play()
		end)
		clone.MouseButton1Click:Connect(function()
			fn()
		end)
		clone.Activated:Connect(function(p4)
			if p4 and p4.UserInputType == Enum.UserInputType.Gamepad1 then
				fn()
			end
		end)
		return clone
	end

	local v49 = {}
	local v50 = 0
	local count = 0
	local count2 = 0

	local function renderNextTradeUpBatch(p3: number)
		local v51 = v50 + 1
		local v52 = math.min(v50 + p3, #v49)

		for i = v51, v52 do
			local v53 = v49[i]
			local tradeUpFrame = buildTradeUpFrame(itemTemplate, container, v53.item, v53.info, function()
				selectTradeUpItem(v53.item, v53.info)
			end)
			count += 1
			tradeUpFrame.LayoutOrder = count
		end

		v50 = v52
	end

	local function rebuildTradeUpPool()
		flag2 = false
		table.clear(v46)
		local inventory = DataController.Get(LocalPlayer, "Inventory")

		if not inventory then
			return
		end

		for _, v51 in ipairs(inventory) do
			if not (v51 and v51._id) then
				continue
			end

			local eligibleTradeUpInfo = getEligibleTradeUpInfo(v51)

			if not eligibleTradeUpInfo then
				continue
			end

			local v53 = {
				item = v51,
				info = eligibleTradeUpInfo,
				key = getTradeUpKey(v51, eligibleTradeUpInfo), -- inferred equivalent call
				searchable = getTradeUpSearchable(v51) -- inferred equivalent call
			}
			table.insert(v46, v53)
		end

		local sortComparisonFunction = Sort.GetSortComparisonFunction(v42, LocalPlayer, function()
			return v9
		end)

		if sortComparisonFunction then
			table.sort(v46, function(a, b)
				if not v43 then
					return sortComparisonFunction(a.item, b.item)
				end

				local v51, v52 = sortComparisonFunction(a.item, b.item)

				if v52 then
					return v51
				end

				return sortComparisonFunction(b.item, a.item)
			end)
		end
	end

	local function renderTradeUpContainer()
		count2 += 1
		local v51 = count2
		clearRenderedItems(container, itemTemplate)
		table.clear(v49)
		v50 = 0
		count = 0

		if flag2 then
			rebuildTradeUpPool()
		end

		for _, v52 in ipairs(v46) do
			local _id = v52.item._id

			if not (table.find(ids, _id) == nil and (v45 == nil or v52.key == v45) and tradeUpMatchesSearch(v52.searchable)) then
				continue
			end

			table.insert(v49, v52)
		end

		renderNextTradeUpBatch(25)

		if #v49 > 25 then
			task.defer(function()
				if v51 == count2 and tradeUp2.Visible then
					renderNextTradeUpBatch(25)
				end
			end)
		end
	end

	container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		if not tradeUp2.Visible or v50 >= #v49 then
			return
		end

		local v51 = container.AbsoluteCanvasSize.Y - container.AbsoluteSize.Y

		if v51 > 0 and v51 - container.CanvasPosition.Y < 200 then
			renderNextTradeUpBatch(25)
		end
	end)
	local clones = {}
	local v51 = {}

	for i = 1, 10 do
		local clone = addTemplate:Clone()
		clone.Name = `AddSlot{i}`
		clone.Visible = true
		clone.LayoutOrder = i + 100
		clone.Active = false
		clone.Interactable = false
		clone.Selectable = false
		clone.Parent = exchange
		clones[i] = clone
		v51[clone] = true
	end

	local function updateExchangePlaceholders() -- 3 equivalent calls inferred from this helper
		local v52 = #ids

		for i, v53 in ipairs(clones) do
			v53.Visible = v52 < i
		end
	end

	local function appendExchangeFrame(p3, p4, layoutOrder: number) -- 2 equivalent calls inferred from this helper
		local _id = p3._id
		local tradeUpFrame = buildTradeUpFrame(itemTemplate2, exchange, p3, p4, function()
			deselectTradeUpItem(_id)
		end)
		tradeUpFrame.LayoutOrder = layoutOrder
	end

	local function renderTradeUpExchange()
		for _, guiObject in ipairs(exchange:GetChildren()) do
			if
				not guiObject:IsA("GuiObject")
				or guiObject == itemTemplate2
				or guiObject == addTemplate
				or v51[guiObject]
			then
				continue
			end

			guiObject:Destroy()
		end

		local inventory = DataController.Get(LocalPlayer, "Inventory")

		if inventory and #ids > 0 then
			local v52 = {}

			for _, v53 in ipairs(inventory) do
				if v53 and v53._id then
					v52[v53._id] = v53
				end
			end

			local count3 = 0

			for _, v53 in ipairs(ids) do
				local v54 = v52[v53]
				local v55 = v54 and getEligibleTradeUpInfo(v54)

				if not v55 then
					continue
				end

				count3 += 1
				appendExchangeFrame(v54, v55, count3) -- inferred equivalent call
			end
		end

		updateExchangePlaceholders() -- inferred equivalent call
	end

	local function renderTradeUp()
		renderTradeUpContainer()
		renderTradeUpExchange()
		updateTradeUpWarning() -- inferred equivalent call
	end

	selectTradeUpItem = function(item, info)
		Router.broadcastRouter("RunInterfaceSound", "UI Click")

		if not (#ids >= 10) then
			local _id = item._id

			if table.find(ids, _id) == nil then
				local tradeUpKey = getTradeUpKey(item, info) -- inferred equivalent call

				if v45 and tradeUpKey ~= v45 then
					return
				end

				local v52 = #ids == 0

				if v52 then
					v45 = tradeUpKey
				end

				table.insert(ids, item._id)

				if v52 then
					renderTradeUpContainer()
				else
					for i, v53 in ipairs(v49) do
						if v53.item._id ~= item._id then
							continue
						end

						table.remove(v49, i)

						if not (i <= v50) then
							break
						end

						v50 -= 1
						local child = container:FindFirstChild(item._id)

						if not child then
							break
						end

						child:Destroy()
						break
					end

					if v50 < 50 and v50 < #v49 then
						renderNextTradeUpBatch(50 - v50)
					end
				end

				appendExchangeFrame(item, info, #ids) -- inferred equivalent call
				updateExchangePlaceholders() -- inferred equivalent call
				updateTradeUpWarning() -- inferred equivalent call
			end
		end
	end

	deselectTradeUpItem = function(id3: string)
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		local index = table.find(ids, id3)

		if not index then
			return
		end

		table.remove(ids, index)

		if #ids == 0 then
			v45 = nil
		end

		renderTradeUpContainer()
		local child = exchange:FindFirstChild(id3)

		if child and not v51[child] then
			child:Destroy()
		end

		for i, childName in ipairs(ids) do
			local child2 = exchange:FindFirstChild(childName)

			if child2 then
				child2.LayoutOrder = i
			end
		end

		updateExchangePlaceholders() -- inferred equivalent call
		updateTradeUpWarning() -- inferred equivalent call
	end

	local function clearTradeUpSelection() -- 4 equivalent calls inferred from this helper
		table.clear(ids)
		v45 = nil
	end

	local flag3 = false
	local v52 = false
	local v53 = nil
	local count3 = 0
	local inventoryItem = nil
	local flag4 = false
	local flag5 = false
	local v54 = false
	local title2 = tradeUp2.Options.Proceed.Container.Title
	local text = title2.Text
	local position = tradeUp2.Options.Cancel.Position
	local position2 = tradeUp2.Options.Proceed.Position
	local udim = UDim2.new(0.405, 0, position.Y.Scale, position.Y.Offset)
	local udim2 = UDim2.new(0.595, 0, position2.Y.Scale, position2.Y.Offset)
	local udim3 = UDim2.new(0.5, 0, position2.Y.Scale, position2.Y.Offset)
	local frame = tradeUp2.TradeContainer.Contract.Frame
	local position3 = frame.Position
	local udim4 = UDim2.new(position3.X.Scale, position3.X.Offset, 1.5, 0)
	local tweenInfo2 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local color = Color3.fromRGB(49, 75, 114)
	local frame2 = Instance.new("Frame")
	frame2.Name = "DrawingCanvas"
	frame2.BackgroundTransparency = 1
	frame2.AnchorPoint = Vector2.new(frame.AnchorPoint.X, 0)
	frame2.Position = UDim2.new(position3.X.Scale, position3.X.Offset, 0, 0)
	frame2.Size = UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 1, 0)
	frame2.ClipsDescendants = true
	frame2.ZIndex = 10
	frame2.Active = true
	frame2.Parent = tradeUp2.TradeContainer.Contract
	local count4 = 0
	local v55 = false
	local v56 = nil

	local function clearContractDrawing() -- 3 equivalent calls inferred from this helper
		v55 = false
		v56 = nil
		count4 = 0

		for _, child in ipairs(frame2:GetChildren()) do
			child:Destroy()
		end
	end

	local function toContractCanvasPoint(position4: Vector3)
		local absolutePosition = frame2.AbsolutePosition
		local absoluteSize = frame2.AbsoluteSize
		return Vector2.new(
			math.clamp(position4.X - absolutePosition.X, 0, absoluteSize.X),
			(math.clamp(position4.Y - absolutePosition.Y, 0, absoluteSize.Y))
		)
	end

	local function createContractInkFrame() -- 2 equivalent calls inferred from this helper
		local frame3 = Instance.new("Frame")
		frame3.BackgroundColor3 = color
		frame3.BorderSizePixel = 0
		frame3.AnchorPoint = Vector2.new(0.5, 0.5)
		frame3.SizeConstraint = Enum.SizeConstraint.RelativeYY
		frame3.ZIndex = 10
		return frame3
	end

	local function addContractDrawPoint(point: Vector2)
		if count4 >= 2500 then
			return
		end

		local v57 = v56

		if v57 and (point - v57).Magnitude < 2 then
			return
		end

		count4 += 1
		local contractInkFrame = createContractInkFrame() -- inferred equivalent call
		contractInkFrame.Position = UDim2.fromOffset(point.X, point.Y)
		contractInkFrame.Size = UDim2.fromScale(0.01, 0.01)
		contractInkFrame.Parent = frame2

		if v57 then
			local v58 = point - v57
			local midpoint = (point + v57) / 2
			local contractInkFrame2 = createContractInkFrame() -- inferred equivalent call
			contractInkFrame2.Position = UDim2.fromOffset(midpoint.X, midpoint.Y)
			contractInkFrame2.Size = UDim2.new(0, v58.Magnitude, 0.01, 0)
			contractInkFrame2.Rotation = math.deg((math.atan(v58.Y / v58.X)))
			contractInkFrame2.Parent = frame2
		end

		v56 = point
	end

	frame2.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			v55 = true
			v56 = nil
			addContractDrawPoint(toContractCanvasPoint(input.Position))
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not v55 then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			addContractDrawPoint(toContractCanvasPoint(input.Position))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			v55 = false
			v56 = nil
		end
	end)
	local v57 = {
		"Jan",
		"Feb",
		"Mar",
		"Apr",
		"May",
		"Jun",
		"Jul",
		"Aug",
		"Sep",
		"Oct",
		"Nov",
		"Dec"
	}
	local v58 = {
		{ maxLevel = 5, title = "Recruit" },
		{ maxLevel = 10, title = "Private" },
		{ maxLevel = 15, title = "Corporal" },
		{ maxLevel = 20, title = "Sergeant" },
		{ maxLevel = 25, title = "Master Sergeant" },
		{ maxLevel = 30, title = "Lieutenant" },
		{ maxLevel = 35, title = "Captain" },
		{ maxLevel = 40, title = "Global Elite" }
	}
	local count5 = 0

	local function playRandomTypingSound() -- 3 equivalent calls inferred from this helper
		Router.broadcastRouter("RunInterfaceSound", `TradeUp Type {math.random(1, 3)}`)
	end

	local function getContractDate() -- 1 equivalent call inferred from this helper
		local v59 = os.date("*t")
		return string.format("%s %d, %d", v57[v59.month], v59.day, v59.year)
	end

	local function getPlayerRankTitle()
		local level = DataController.Get(LocalPlayer, "Level")
		local level2 = type(level) == "table" and tonumber(level.Level) or 1

		for _, v59 in ipairs(v58) do
			if level2 <= v59.maxLevel then
				return v59.title
			end
		end

		return "Global Elite"
	end

	local function runContractTypewriter()
		count5 += 1
		local v59 = count5
		local frame3 = tradeUp2.TradeContainer.Contract.Frame
		local _1 = frame3:FindFirstChild("1")
		local _2 = frame3:FindFirstChild("2")

		if not (_1 and _2) then
			return
		end

		local v64 = {
			{ label = _1:FindFirstChild("ID"), text = tostring(LocalPlayer.UserId) },
			{ label = _1:FindFirstChild("Name"), text = LocalPlayer.Name },
			{ label = _1:FindFirstChild("Number"), text = tostring(10) },
			{ label = _2:FindFirstChild("Date"), text = getContractDate() }, -- inferred equivalent call
			{ label = _2:FindFirstChild("Rank"), text = getPlayerRankTitle() }
		}
		local v65 = 0
		local v66 = {}

		for _, v67 in ipairs(v64) do
			if not (v67.label and v67.label:IsA("TextLabel")) then
				continue
			end

			v67.label.Text = ""
			local v68 = #v67.text
			v65 = math.max(v65, v68)
			table.insert(v66, v67)
		end

		task.spawn(function()
			task.wait(0.2)

			if v59 ~= count5 then
				return
			end

			for i = 1, v65 do
				task.wait(0.12)

				if v59 ~= count5 then
					break
				end

				for _, v67 in ipairs(v66) do
					if i <= #v67.text then
						v67.label.Text = string.sub(v67.text, 1, i)
					end
				end

				playRandomTypingSound() -- inferred equivalent call
			end
		end)
	end

	local count6 = 0

	local function getTradeUpItemName(data)
		if not data then
			return ""
		end

		local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag)
		local skin = data.Skin or ""

		if skin == "" then
			return weaponDisplayName
		end

		return `{weaponDisplayName} | {skin}`
	end

	local function utf8Prefix(value: string, i: number) -- 2 equivalent calls inferred from this helper
		local v59 = utf8.offset(value, i + 1)

		if v59 then
			return (string.sub(value, 1, v59 - 1))
		end

		return value
	end

	local function getContractSlotLabel(i: number)
		local frame3 = tradeUp2.TradeContainer.Contract.Frame
		local v59 = tostring(i)
		local label = frame3:FindFirstChild("3") and frame3["3"]:FindFirstChild(v59)
			or frame3:FindFirstChild("4") and frame3["4"]:FindFirstChild(v59)

		if label and label:IsA("TextLabel") then
			return label
		end

		return nil
	end

	local function getContractReceivedLabel() -- 2 equivalent calls inferred from this helper
		local _2 = tradeUp2.TradeContainer.Contract.Frame:FindFirstChild("2")
		local received = _2 and _2:FindFirstChild("Received")

		if received and received:IsA("TextLabel") then
			return received
		end

		return nil
	end

	local function clearContractSlots()
		for i = 1, 10 do
			local contractSlotLabel = getContractSlotLabel(i)

			if contractSlotLabel then
				contractSlotLabel.Text = ""
			end
		end

		local contractReceivedLabel = getContractReceivedLabel() -- inferred equivalent call

		if contractReceivedLabel then
			contractReceivedLabel.Text = ""
		end
	end

	local function clearContractHeaderFields()
		local frame3 = tradeUp2.TradeContainer.Contract.Frame

		for _, v59 in {
			{ "1", "ID", "Name", "Number" },
			{ "2", "Date", "Rank" }
		} do
			local child = frame3:FindFirstChild(v59[1])

			for i = 2, #v59 do
				local label = child and child:FindFirstChild(v59[i])

				if label and label:IsA("TextLabel") then
					label.Text = ""
				end
			end
		end
	end

	local setTradeUpVisible

	local function finishTradeUpReveal(inventoryItem2)
		setTradeUpVisible(false)

		if not inventoryItem2 then
			return
		end

		local resolvedSkinInformation = GetResolvedSkinInformation(inventoryItem2.Name, inventoryItem2.Skin)
		local rarity = resolvedSkinInformation and resolvedSkinInformation.rarity or inventoryItem2.Rarity or "Blue"
		Router.broadcastRouter("RunStoreSound", v26[rarity] or "Drop Blue")

		local function showNotification() -- 2 equivalent calls inferred from this helper
			v24 = false
			Inventory.ShowNewItemNotification(inventoryItem2)
		end

		local onInspectStateChangedConnection = nil
		onInspectStateChangedConnection = MenuState.OnInspectStateChanged:Connect(function(flag6: boolean)
			if flag6 then
				return
			end

			onInspectStateChangedConnection:Disconnect()
			onInspectStateChangedConnection = nil
			showNotification() -- inferred equivalent call
		end)
		InspectInventoryItem(inventoryItem2) -- inferred equivalent call

		if onInspectStateChangedConnection and not Router.broadcastRouter("IsInspectActive") then
			onInspectStateChangedConnection:Disconnect()
			onInspectStateChangedConnection = nil
			showNotification() -- inferred equivalent call
		end
	end

	local function runContractConfirmReveal(list) -- 1 equivalent call inferred from this helper
		count6 += 1
		local v59 = count6
		clearContractSlots()
		task.spawn(function()
			for i = 1, 10 do
				local contractSlotLabel = getContractSlotLabel(i)
				local v60 = list[i] or ""

				if not contractSlotLabel then
					continue
				end

				for j = 1, utf8.len(v60) or #v60 do
					task.wait(0.06)

					if v59 ~= count6 then
						return
					end

					contractSlotLabel.Text = utf8Prefix(v60, j) -- inferred equivalent call
					playRandomTypingSound() -- inferred equivalent call
				end
			end

			while v59 == count6 and inventoryItem == nil do
				task.wait(0.05)
			end

			if v59 ~= count6 then
				return
			end

			local contractReceivedLabel = getContractReceivedLabel() -- inferred equivalent call
			local v60 = inventoryItem
			local v61

			if v60 then
				v61 = GetSkinDisplayName.GetWeaponDisplayName(v60.Name, v60.NameTag)
				local skin = v60.Skin or ""

				if skin ~= "" then
					v61 = `{v61} | {skin}`
				end
			else
				v61 = ""
			end

			if contractReceivedLabel then
				for i = 1, utf8.len(v61) or #v61 do
					task.wait(0.06)

					if v59 ~= count6 then
						return
					end

					contractReceivedLabel.Text = utf8Prefix(v61, i) -- inferred equivalent call
					playRandomTypingSound() -- inferred equivalent call
				end
			end

			task.wait(0.1)

			if v59 ~= count6 then
				return
			end

			local approved = tradeUp2.TradeContainer.Contract:FindFirstChild("Approved")

			if approved and approved:IsA("ImageLabel") then
				approved.Size = UDim2.fromScale(0.65, 0.65)
				approved.ImageTransparency = 0.85
				approved.Visible = true
				Router.broadcastRouter("RunInterfaceSound", "TradeUp Approved")

				local function stampStep(duration: number, p3) -- 2 equivalent calls inferred from this helper
					return TweenService:Create(approved, TweenInfo.new(duration, Enum.EasingStyle.Linear), p3)
				end

				local v62 = stampStep(0.2, { -- inferred equivalent call
					Size = UDim2.fromScale(0.35, 0.35),
					ImageTransparency = 0
				})
				local v64 = {
					v62,
					stampStep(0.03, { Size = UDim2.fromScale(0.365, 0.365) }), -- inferred equivalent call
					stampStep(0.03, { Size = UDim2.fromScale(0.35, 0.35) })
				}

				for _, v65 in ipairs(v64) do
					v65:Play()
					v65.Completed:Wait()

					if v59 ~= count6 then
						return
					end
				end
			end

			task.wait(1.25)

			if v59 ~= count6 then
				return
			end

			finishTradeUpReveal(inventoryItem)
		end)
	end

	local function skipContractReveal() -- 1 equivalent call inferred from this helper
		count6 += 1
		local v59 = count6
		task.spawn(function()
			while v59 == count6 and inventoryItem == nil do
				task.wait(0.05)
			end

			if v59 ~= count6 then
				return
			end

			finishTradeUpReveal(inventoryItem)
		end)
	end

	local function setTradeUpItemSelectionState()
		flag3 = false
		flag4 = false
		flag5 = false
		v54 = false
		count5 += 1
		count6 += 1
		tradeUp2.Options.Clear.Visible = true
		tradeUp2.Options.Proceed.Visible = true
		tradeUp2.Options.Cancel.Visible = false
		title2.Text = text
		tradeUp2.Options.Cancel.Position = position
		tradeUp2.Options.Proceed.Position = position2
		tradeUp2.Top.Visible = true

		if v52 and parent2 and parent2.Menu then
			parent2.Menu.Top.Visible = true
		end

		v52 = false
		tradeUp2.TradeContainer.Container.Visible = true
		tradeUp2.TradeContainer.Exchange.Visible = true
		tradeUp2.TradeContainer.Contract.Visible = false
		clearContractDrawing() -- inferred equivalent call

		for _, guiObject in ipairs(tradeUp2.Warning:GetChildren()) do
			if guiObject:IsA("GuiObject") then
				guiObject.Visible = guiObject.Name ~= "WarningForContract"
			end
		end
	end

	local function setTradeUpContractState()
		flag3 = true
		tradeUp2.Options.Clear.Visible = false
		tradeUp2.Options.Proceed.Visible = true
		tradeUp2.Options.Cancel.Visible = true
		title2.Text = "CONFIRM"
		tradeUp2.Options.Cancel.Position = udim
		tradeUp2.Options.Proceed.Position = udim2
		tradeUp2.Top.Visible = false

		if parent2 and parent2.Menu then
			parent2.Menu.Top.Visible = false
			v52 = true
		end

		for _, guiObject in ipairs(tradeUp2.Warning:GetChildren()) do
			if guiObject:IsA("GuiObject") then
				guiObject.Visible = false
			end
		end

		clearContractDrawing() -- inferred equivalent call
		clearContractHeaderFields()
		clearContractSlots()
		local approved = tradeUp2.TradeContainer.Contract:FindFirstChild("Approved")

		if approved and approved:IsA("ImageLabel") then
			approved.Visible = false
		end

		tradeUp2.TradeContainer.Container.Visible = false
		tradeUp2.TradeContainer.Exchange.Visible = false
		count5 += 1
		local v59 = count5
		frame.Position = udim4

		if not tradeUp2.TradeContainer.Contract.Visible then
			tradeUp2.TradeContainer.Contract.Visible = true
		end

		task.delay(0.18, function()
			if v59 ~= count5 then
				return
			end

			local tween = TweenService:Create(frame, tweenInfo2, { Position = position3 })
			tween.Completed:Connect(function()
				if v59 ~= count5 then
					return
				end

				runContractTypewriter()
			end)
			Router.broadcastRouter("RunInterfaceSound", "TradeUp Contract Slide")
			tween:Play()
		end)
	end

	setTradeUpVisible = function(visible: boolean)
		v16.Frame.Categories.Visible = not visible
		v16.Frame.Right.Visible = not visible
		tradeUp2.Visible = visible
		v5 = nil
		v4 = nil
		now = nil
		v16.Ignore.Hover.Visible = false

		if visible then
			MenuState.EnterTradeUp()

			if information then
				information.Visible = false
			end

			if v16.Ignore.ItemNotification.Visible then
				DismissItemNotifications()
			end

			setTradeUpItemSelectionState()
			clearTradeUpSelection() -- inferred equivalent call
			renderTradeUp()
		else
			MenuState.ExitTradeUp()
			flag3 = false
			flag4 = false
			flag5 = false
			v54 = false
			count5 += 1
			count6 += 1
			clearContractDrawing() -- inferred equivalent call
			tradeUp2.Options.Cancel.Position = position
			tradeUp2.Options.Proceed.Position = position2
			title2.Text = text

			if v52 and parent2 and parent2.Menu then
				parent2.Menu.Top.Visible = true
			end

			v52 = false
		end
	end

	local clear = tradeUp2.Options.Clear
	local proceed = tradeUp2.Options.Proceed
	local cancel = tradeUp2.Options.Cancel
	ActivateButton(clear)
	clear.Selectable = true

	local function fn()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		clearTradeUpSelection() -- inferred equivalent call
		renderTradeUp()
	end

	ConnectButtonActivation(clear, fn) -- inferred equivalent call
	ActivateButton(proceed)
	proceed.Selectable = true

	local function handleTradeUpProceedClick()
		if flag5 then
			if flag3 and not v54 then
				v54 = true
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				skipContractReveal() -- inferred equivalent call
			end
		else
			Router.broadcastRouter("RunInterfaceSound", "UI Click")

			if flag3 then
				if v53 or flag4 or #ids ~= 10 then
					return
				end

				flag5 = true
				v54 = false
				tradeUp2.Options.Cancel.Visible = false
				tradeUp2.Options.Proceed.Position = udim3
				title2.Text = "SKIP"
				local inventory = DataController.Get(LocalPlayer, "Inventory") or {}
				local v59 = {}

				for _, v60 in ipairs(inventory) do
					if v60 and v60._id then
						v59[v60._id] = v60
					end
				end

				local v60 = {}

				for _, v61 in ipairs(ids) do
					local v62 = v59[v61]
					local v63

					if v62 then
						v63 = GetSkinDisplayName.GetWeaponDisplayName(v62.Name, v62.NameTag)
						local skin = v62.Skin or ""

						if skin ~= "" then
							v63 = `{v63} | {skin}`
						end
					else
						v63 = ""
					end

					table.insert(v60, v63)
				end

				inventoryItem = nil
				flag4 = false
				count3 += 1
				local formatted = `TradeUp_{count3}`
				v53 = formatted
				Remotes.Store.TradeUpItems.Send({
					ItemIds = table.clone(ids),
					RequestId = formatted
				})
				runContractConfirmReveal(v60) -- inferred equivalent call
			elseif #ids == 10 then
				setTradeUpContractState()
			end
		end
	end

	ConnectButtonActivation(proceed, handleTradeUpProceedClick) -- inferred equivalent call
	ActivateButton(cancel)
	cancel.Selectable = true

	local function handleTradeUpCancelClick()
		if flag5 then
			return
		end

		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		count6 += 1

		if flag4 then
			clearTradeUpSelection() -- inferred equivalent call
		end

		setTradeUpItemSelectionState()
		renderTradeUp()
	end

	ConnectButtonActivation(cancel, handleTradeUpCancelClick) -- inferred equivalent call
	Remotes.Store.TradeUpCompleted.Listen(function(data)
		local v59

		if data and typeof(data.RequestId) == "string" then
			v59 = data.RequestId
		end

		if not v53 or v59 ~= v53 then
			return
		end

		v53 = nil
		DataController.ApplyInventoryDelta(LocalPlayer, { data.InventoryItem }, data.DeletedItemIds)
		flag4 = true
		inventoryItem = data.InventoryItem
	end)
	Remotes.Store.TradeUpDenied.Listen(function(p3)
		local requestId

		if p3 and typeof(p3.RequestId) == "string" then
			requestId = p3.RequestId
		end

		if requestId and v53 and requestId ~= v53 then
			return
		end

		v53 = nil
		count6 += 1
		flag5 = false
		v54 = false

		if tradeUp2.Visible then
			setTradeUpVisible(false)
		end
	end)
	ActivateButton(tradeUp)
	tradeUp.Selectable = true

	local function fn2()
		setTradeUpVisible(true)
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
	end

	ConnectButtonActivation(tradeUp, fn2) -- inferred equivalent call

	local function setupTradeUpTopBar()
		local top = v16.Frame.TradeUp.Top
		local weapon = top.Weapon
		local click = weapon.Click
		local dropdownContent2 = weapon.DropdownContent
		local title3 = weapon.Container.Left.Title

		local function setDropdownOpen(flag6: boolean) -- 2 equivalent calls inferred from this helper
			SetDropdownOpen(dropdownContent2, flag6) -- inferred equivalent call
		end

		weapon.Active = false
		click.Selectable = true
		SetDropdownOpen(dropdownContent2, false) -- inferred equivalent call
		click.Activated:Connect(function()
			setDropdownOpen(not dropdownContent2.Visible) -- inferred equivalent call
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
		end)
		BindSortDropdownFocus(dropdownContent2, click, function()
			return v42 or click.Frame.TextLabel.Text
		end, "UI.Inventory.TradeUpSortFocusDeferred")
		local reverseSort2 = weapon.Container.Left.ReverseSort
		reverseSort2.Selectable = true
		reverseSort2.Activated:Connect(function()
			v43 = not v43
			setReverseSortVisual(reverseSort2, v43) -- inferred equivalent call
			flag2 = true
			renderTradeUpContainer()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
		end)

		for _, childName in v39 do
			local button = dropdownContent2.Scroll:FindFirstChild(childName)

			if not (button and button:IsA("TextButton")) then
				continue
			end

			button.Selectable = true
			local text2 = childName

			local function handleSortOptionClick()
				Router.broadcastRouter("RunInterfaceSound", "UI Click")
				v42 = text2
				flag2 = true
				title3.Text = text2

				for _, button2 in ipairs(dropdownContent2.Scroll:GetChildren()) do
					if button2:IsA("TextButton") then
						button2.Frame.BackgroundTransparency = button2 == button and 0 or 1
					end
				end

				renderTradeUpContainer()
				setDropdownOpen(false) -- inferred equivalent call
			end

			ConnectButtonActivation(button, handleSortOptionClick) -- inferred equivalent call
		end

		local title4 = top.Search.Container.Title
		BindSearchTap(top.Search, title4)
		title4:GetPropertyChangedSignal("Text"):Connect(function()
			if not tradeUp2.Visible then
				return
			end

			SetSearchTokens(v44, title4.Text)
			renderTradeUpContainer()
		end)
		return { setDropdownOpen = setDropdownOpen, searchTextBox = title4 }
	end

	v17 = setupTradeUpTopBar()
	v16.Frame.TradeUp.Top.TradeUp.Visible = false
	setTradeUpVisible(false)
	clearContractSlots()
	clearContractHeaderFields()
	task.spawn(function()
		local v59 = {}
		local images = {}

		for _, guiObject in ipairs(tradeUp2.TradeContainer.Contract:GetDescendants()) do
			if
				not (guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton"))
				or guiObject.Image == ""
				or v59[guiObject.Image]
			then
				continue
			end

			v59[guiObject.Image] = true
			table.insert(images, guiObject.Image)
		end

		if #images == 0 then
			return
		end

		ContentProvider:PreloadAsync(images)
		local frame3 = Instance.new("Frame")
		frame3.Name = "TradeUpContractImageWarmup"
		frame3.BackgroundTransparency = 1
		frame3.Size = UDim2.fromOffset(1, 1)
		frame3.Position = UDim2.fromOffset(0, 0)

		for _, image in ipairs(images) do
			local imageLabel = Instance.new("ImageLabel")
			imageLabel.BackgroundTransparency = 1
			imageLabel.ImageTransparency = 0.99
			imageLabel.Size = UDim2.fromOffset(1, 1)
			imageLabel.Image = image
			imageLabel.Parent = frame3
		end

		frame3.Parent = parent2
		task.wait(0.5)
		frame3:Destroy()
	end)

	if parent2 and parent2.Menu then
		parent2.Menu.Top:GetPropertyChangedSignal("Visible"):Connect(function()
			if flag3 and parent2.Menu.Top.Visible then
				parent2.Menu.Top.Visible = false
			end
		end)
	end

	Router.observerRouter("ResetInventoryToGrid", function()
		setTradeUpVisible(false)
	end)
	title:GetPropertyChangedSignal("Text"):Connect(function()
		if not v16.Visible then
			return
		end

		SetSearchTokens(v14, title.Text)
		ApplyCurrentSort() -- inferred equivalent call
	end)

	local function handleInventoryClosed()
		setSortDropdownOpen(false) -- inferred equivalent call
		setTradeUpVisible(false)
		table.clear(v14)
		title.Text = ""
		table.clear(v44)
		clearTradeUpSelection() -- inferred equivalent call

		if v17 then
			v17.setDropdownOpen(false)
			v17.searchTextBox.Text = ""
		end

		UpdateInventoryTemplates()
	end

	v16:GetPropertyChangedSignal("Visible"):Connect(function()
		syncInventoryUpdate()

		if v16.Visible then
			Profiler.mark("UI.Inventory.ApplyCurrentSort")

			if v16 and v16.Visible then
				v = GetSortedInventoryData()
				v = ApplyFilterToSortedData(v)
				UpdateInventoryTemplates()
			end

			local v59 = id2
			id2 = nil
			local v60 = v19[v7]
			local visible

			if v59 == nil or v60 == nil or v60._id ~= v59 then
				visible = false
			else
				visible = v16.Ignore.ItemNotification.Visible
			end

			local count7 = #v19

			if not visible and count7 > 0 and v7 < count7 then
				Inventory.NextInventoryItem(v7 + 1)
			end
		else
			id2 = nil
			ReportViewedItems()

			if not MenuState.IsInspectActive() then
				handleInventoryClosed()
			end
		end
	end)
	MenuState.OnInspectStateChanged:Connect(function(flag6: boolean)
		if flag6 then
			return
		end

		task.defer(function()
			if not v16.Visible then
				handleInventoryClosed()
			end
		end)
	end)

	if parent2 and parent2.Menu then
		parent2.Menu:GetPropertyChangedSignal("Visible"):Connect(function()
			if not parent2.Menu.Visible and v16.Visible then
				v16.Visible = false
				handleInventoryClosed()
				syncInventoryUpdate()
			end
		end)
	end

	v16.Frame.Right.Container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		OnScrollPositionChanged()
	end)
	v16.Frame.Right.Container:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		Profiler.defer("UI.Inventory.ScrollDeferred", OnScrollPositionChanged)
	end)
end

function Inventory.Start()
	debug.setmemorycategory("UI.Inventory.Start")
	Profiler.mark("UI.Inventory.Start.Begin")
	DataController.WaitForDataLoaded(LocalPlayer)
	Profiler.mark("UI.Inventory.Start.DataLoaded")
	Profiler.mark("UI.Inventory.Start.InitialCategory")
	local inputBeganConnection = nil

	local function setupGamepadNavigation() -- 1 equivalent call inferred from this helper
		Profiler.mark("UI.Inventory.SetupGamepadNavigation")

		if inputBeganConnection then
			inputBeganConnection:Disconnect()
		end

		inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed: boolean)
			if input.UserInputType ~= Enum.UserInputType.Gamepad1 or (not v16 or not v16.Visible or gameProcessed) then
				return
			end

			local keyCode = input.KeyCode
			local selectedObject = GuiService.SelectedObject
			local visible = v16 and v16.Ignore.ItemNotification and v16.Ignore.ItemNotification.Visible

			if keyCode == Enum.KeyCode.ButtonB then
				if visible then
					Router.broadcastRouter("RunInterfaceSound", "UI Click")
					DismissItemNotifications()
					CloseButtonRegistry.MarkUsed()
					return
				elseif information and information.Visible then
					information.Visible = false
					Router.broadcastRouter("RunInterfaceSound", "UI Click")
					CloseButtonRegistry.MarkUsed()
					return
				elseif v16 and v16.Tabs.Inventory.Sort.Button.Options.Visible then
					v16.Tabs.Inventory.Sort.Button.Options.Visible = false
					Router.broadcastRouter("RunInterfaceSound", "UI Click")
					CloseButtonRegistry.MarkUsed()
					return
				end
			end

			local v37 = keyCode == Enum.KeyCode.DPadUp
			local nextSelectionUp

			if v37 or keyCode == Enum.KeyCode.DPadDown then
				nextSelectionUp = selectedObject
					and selectedObject:IsA("GuiButton")
					and (v37 and selectedObject.NextSelectionUp or selectedObject.NextSelectionDown)
			else
				nextSelectionUp = false
			end

			if visible then
				local holder = v16.Ignore.ItemNotification.Holder

				if nextSelectionUp and nextSelectionUp:IsDescendantOf(holder) and nextSelectionUp.Visible then
					GuiService.SelectedObject = nextSelectionUp
				end
			else
				local v38 = information
					and information.Visible
					and selectedObject
					and selectedObject:IsDescendantOf(information)

				if nextSelectionUp and (not v38 or nextSelectionUp:IsDescendantOf(information)) then
					GuiService.SelectedObject = nextSelectionUp
				end
			end
		end)
	end

	local changedConnection = nil

	local function setupSelectionProtection() -- 1 equivalent call inferred from this helper
		Profiler.mark("UI.Inventory.SetupSelectionProtection")

		if changedConnection then
			changedConnection:Disconnect()
		end

		changedConnection = GuiService.Changed:Connect(function(p)
			if p ~= "SelectedObject" then
				return
			end

			local itemNotification = v16 and v16.Ignore.ItemNotification

			if itemNotification and itemNotification.Visible then
				local holder = itemNotification.Holder
				local selectedObject = GuiService.SelectedObject

				if
					selectedObject
					and selectedObject ~= holder.Continue
					and selectedObject ~= holder.ViewLoadout
					and not (selectedObject:IsDescendantOf(holder) and selectedObject:IsA("GuiButton"))
				then
					Profiler.defer(
						"UI.Inventory.SelectionProtectionDeferred",
						Inventory.SelectFirstItemNotificationButton
					)
				end
			else
				if not (information and information.Visible) then
					return
				end

				local selectedObject = GuiService.SelectedObject

				if selectedObject and not selectedObject:IsDescendantOf(information) then
					Profiler.defer(
						"UI.Inventory.SelectionProtectionDeferred",
						Inventory.SelectFirstInformationFrameButton
					)
				end
			end
		end)
	end

	if v16 then
		v16:GetPropertyChangedSignal("Visible"):Connect(function()
			if v16.Visible then
				setupGamepadNavigation() -- inferred equivalent call
				setupSelectionProtection() -- inferred equivalent call

				if UserInputService.GamepadEnabled then
					Profiler.defer("UI.Inventory.AutoSelectDeferred", function()
						local count = 0

						while count < 5 do
							task.wait(0.1)
							count += 1

							if GuiService.SelectedObject or not (v16 and v16.Visible) then
								break
							end

							if not v16.Frame.Right.Container then
								continue
							end

							for _, frame in ipairs(v16.Frame.Right.Container:GetChildren()) do
								if not (frame:IsA("Frame") and frame.Name ~= "UIGridLayout" and frame.Name ~= "UIListLayout" and frame.Name ~= "UIPadding") then
									continue
								end

								local button = frame:FindFirstChild("Button")

								if not (button and button:IsA("GuiButton") and button.Selectable and button.Visible) then
									continue
								end

								GuiService.SelectedObject = button
								return
							end
						end
					end)
				end
			else
				if inputBeganConnection then
					inputBeganConnection:Disconnect()
					inputBeganConnection = nil
				end

				if changedConnection then
					changedConnection:Disconnect()
					changedConnection = nil
				end
			end
		end)
	end

	syncInventoryUpdate()
	Skins.OnItemStockSchemasUpdated:Connect(function(_)
		Profiler.mark("UI.Inventory.ItemStockSchemasUpdated")
		local inventory = DataController.Get(LocalPlayer, "Inventory")
		Inventory.UpdateTemplates(inventory)
	end)
	DataController.CreateListener(LocalPlayer, "New Inventory Items", function(list)
		Profiler.mark("UI.Inventory.NewInventoryItemsChanged")

		if type(list) ~= "table" then
			return
		end

		local now2 = os.clock()

		for k, v37 in v22 do
			if now2 - v37 >= 10 then
				v22[k] = nil
			end
		end

		local v37 = {}

		for _, v38 in ipairs(list) do
			if not v22[v38] then
				table.insert(v37, v38)
			end
		end

		v18 = v37
		RefreshNewInventoryItems()
	end)
	Remotes.Store.CaseOpenDenied.Listen(function(data)
		local requestId

		if data and typeof(data.RequestId) == "string" then
			requestId = data.RequestId
		end

		local v37 = requestId and v13 == requestId

		if v37 and (not requestId or v13 == requestId) then
			if v13 then
				Store.ClearPendingOpenCaseRequest(v13)
			end

			flag = false
			v13 = nil
		end

		if v37 and data and data.Reason == "RateLimited" then
			local v38 = (tonumber(data.RetryAfterMs) or 0) / 1000
			local v39 = not (v38 > 0) and "Quick open is rate limited. Please wait a moment and try again."
				or string.format("Quick open is rate limited. Wait %.1fs and try again.", v38)
			Router.broadcastRouter("CreateMenuNotification", "Error", v39)
		end
	end)
	DataController.CreateListener(LocalPlayer, "Inventory", function(list)
		Profiler.mark("UI.Inventory.InventoryChanged")
		Inventory.UpdateInventory(list)
		RefreshNewInventoryItems()

		if not v8 then
			v16.Frame.Right.Top.Filter.Container.Left.Title.Text = "Newest"
			v10 = "Newest"
			v8 = true
		end

		Profiler.mark("UI.Inventory.ApplyCurrentSort")

		if v16 and v16.Visible then
			v = GetSortedInventoryData()
			v = ApplyFilterToSortedData(v)
			UpdateInventoryTemplates()
		end

		if information and information.Visible and v3 and v3._id and type(list) == "table" then
			local inventoryItemFromIdentifier = GetInventoryItemFromIdentifier(list, v3._id) -- inferred equivalent call

			if inventoryItemFromIdentifier then
				v3 = inventoryItemFromIdentifier
				Inventory.SetupInformationFrame(inventoryItemFromIdentifier)
			end
		end
	end)
	DataController.CreateListener(LocalPlayer, "Loadout", function()
		Profiler.mark("UI.Inventory.LoadoutChanged")

		if v16 and v16.Visible then
			local container = v16.Frame.Right.Container

			for _, child in ipairs(container:GetChildren()) do
				if IsItemTemplate(child) then -- inferred equivalent call
					UpdateStatusFrame(child, child.Name)
				end
			end
		end
	end)
	MenuState.OnInspectStateChanged:Connect(function(flag2: boolean)
		if not flag2 then
			Profiler.defer("UI.Inventory.InspectClosedDeferred", function()
				local count = #v19

				if v16.Visible and count > 0 and v7 < count then
					Inventory.NextInventoryItem(v7 + 1)
				end
			end)
		end
	end)
	Router.observerRouter("QuickOpenResolved", function(value)
		if typeof(value) == "string" then
			if value and v13 ~= value then
				return
			end

			if v13 then
				Store.ClearPendingOpenCaseRequest(v13)
			end

			flag = false
			v13 = nil
		end
	end)
	Router.observerRouter("ShowNewItemNotification", Inventory.ShowNewItemNotification)

	for _, v37 in CollectionService:GetTagged("CategoryFilter") do
		if v37:IsDescendantOf(v16) then
			RegisterCategoryFilterRow(v37)
		end
	end

	local reset = v16.Frame.Right.Top:FindFirstChild("Reset")

	if reset and reset:IsA("GuiButton") then
		v32 = reset
		reset.Visible = false
		ActivateButton(reset)
		reset.Activated:Connect(function()
			table.clear(v29)

			for _, v37 in v30 do
				v37.Check.Visible = false
			end

			Profiler.mark("UI.Inventory.ApplyCurrentSort")

			if not (v16 and v16.Visible) then
				return
			end

			v = GetSortedInventoryData()
			v = ApplyFilterToSortedData(v)
			UpdateInventoryTemplates()
		end)
	end

	for _, v37 in CollectionService:GetTagged("CategoryButtons") do
		local v38 = v37
		v37.Activated:Connect(function()
			v38.Parent[`{v38.Name}Filter`].Visible = not v38.Parent[`{v38.Name}Filter`].Visible
			v38.Icon.Rotation = v38.Parent[`{v38.Name}Filter`].Visible and 180 or 0
		end)
	end
end

return Inventory