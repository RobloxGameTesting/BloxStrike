local Inventory = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
require(ReplicatedStorage.Database.Custom.Types)
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local EquipInventorySlot = require(ReplicatedStorage.Components.Common.UserInput.EquipInventorySlot)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local GetResolvedSkinInformation = require(ReplicatedStorage.Components.Common.GetResolvedSkinInformation)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local v = nil
local v2 = 0
local v3 = nil
local attributeChangedConnection = nil
local tweens = {}
local thread = nil
local visible = table.find(GetUserPlatform(), "Console") and #GetUserPlatform() <= 1
local v4 = {
	{ type = "Primary", space = 1 },
	{ type = "Secondary", space = 1 },
	{ type = "Melee", space = 2 },
	{ type = "Grenade", space = 4 },
	{ type = "C4", space = 1 }
}
local v5 = utf8.char(9733) .. " "
local color = Color3.new(1, 1, 1)
local v6 = {}
local v7 = {}
local v8 = nil

local function getWeaponFrames() -- 2 equivalent calls inferred from this helper
	if v8 then
		return { v8.Primary, v8.Secondary, v8.Melee }
	end

	return nil
end

local function isZeusWeapon(p) -- 10 equivalent calls inferred from this helper
	return p ~= nil and p.Name == "Zeus x27"
end

local function shouldDisplaySkinSuffix(p: string) -- 1 equivalent call inferred from this helper
	return p ~= "Vanilla" and p ~= "Stock"
end

local function getInventoryItemDisplayName(data, p: string)
	local v9

	if p == "Melee" then
		v9 = isZeusWeapon(data) and "" or v5 or "" -- inferred equivalent call
	else
		v9 = ""
	end

	local v10 = GetSkinDisplayName.GetNameTag(data.NameTag) ~= nil
	local v11 = v9 .. GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag)

	if data.Skin and not v10 then
		local skinDisplayName = GetSkinDisplayName(data.Skin)
		v11 ..= shouldDisplaySkinSuffix(skinDisplayName) and " | " .. skinDisplayName or "" -- inferred equivalent call
	end

	local v12 = not v10 and (data.Name == "T Knife" or data.Name == "CT Knife") and "Knife" or v11
	local originalOwner = data.OriginalOwner

	if originalOwner and originalOwner ~= "" and originalOwner ~= LocalPlayer.Name then
		return `{originalOwner}'s "{v12}"`
	end

	if v10 then
		return `"{v12}"`
	end

	return v12
end

local function getWeaponColor(p)
	if not p or DataController.Get(LocalPlayer, "Settings.Game.HUD.Glow Weapon with Rarity Color") ~= true then
		return GetPreferenceColor()
	end

	local resolvedSkinInformation = GetResolvedSkinInformation(p.Name, p.Skin)
	local v9 = resolvedSkinInformation and resolvedSkinInformation.rarity and Rarities[resolvedSkinInformation.rarity]

	if v9 then
		return v9.Color
	end

	return (GetPreferenceColor())
end

local function getLabelFromContainer(instance, className: string)
	if not instance then
		return nil
	end

	if instance:IsA(className) then
		return instance
	end

	return instance:FindFirstChildWhichIsA(className, true)
end

local function getImageLabelFromContainer(p) -- 2 equivalent calls inferred from this helper
	return getLabelFromContainer(p, "ImageLabel")
end

local function getTextLabelFromContainer(weaponName) -- 1 equivalent call inferred from this helper
	return getLabelFromContainer(weaponName, "TextLabel")
end

local function getMeleeImageLabels(instance)
	local weapon = instance:FindFirstChild("Weapon")
	local melee

	if weapon then
		melee = weapon:FindFirstChild("Melee") or nil
	end

	melee = getImageLabelFromContainer(melee) -- inferred equivalent call
	local zeus = instance:FindFirstChild("Zeus")

	if not zeus then
		if weapon then
			zeus = weapon:FindFirstChild("Zeus") or nil
		else
			zeus = nil
		end
	end

	zeus = getImageLabelFromContainer(zeus) -- inferred equivalent call

	if not melee and weapon and weapon:IsA("Frame") then
		melee = weapon:FindFirstChildOfClass("ImageLabel")
	end

	return melee, zeus
end

local function getMeleeWeaponNameLabels(instance)
	local weapon = instance:FindFirstChild("Weapon")
	local weaponName

	if weapon then
		weaponName = weapon:FindFirstChild("WeaponName") or nil
	end

	weaponName = getTextLabelFromContainer(weaponName) -- inferred equivalent call
	local zeus = instance:FindFirstChild("Zeus") or weapon and weapon:FindFirstChild("Zeus") or nil

	if not zeus then
		return weaponName, nil
	end

	if zeus:IsA("TextLabel") then
		return weaponName, zeus
	end

	return weaponName, (zeus:FindFirstChildWhichIsA("TextLabel", true))
end

local function getFrameWeaponImageLabel(p, p2)
	if not p then
		return nil
	end

	if p.Name ~= "Melee" then
		return p.Weapon:FindFirstChildOfClass("ImageLabel")
	end

	local meleeImageLabels, v9 = getMeleeImageLabels(p)

	if isZeusWeapon(p2) then -- inferred equivalent call
		meleeImageLabels = v9 or meleeImageLabels
	end

	return meleeImageLabels
end

local function getFrameWeaponNameLabel(p, p2)
	if not p then
		return nil
	end

	if p.Name ~= "Melee" then
		return (p.Weapon:FindFirstChild("WeaponName"))
	end

	local meleeWeaponNameLabels, v9 = getMeleeWeaponNameLabels(p)

	if isZeusWeapon(p2) then -- inferred equivalent call
		meleeWeaponNameLabels = v9 or meleeWeaponNameLabels
	end

	return meleeWeaponNameLabels
end

local function clearFrameWeaponNameLabels(p) -- 3 equivalent calls inferred from this helper
	if not p then
		return
	end

	if p.Name == "Melee" then
		local meleeWeaponNameLabels, v9 = getMeleeWeaponNameLabels(p)

		if meleeWeaponNameLabels then
			meleeWeaponNameLabels.Visible = false
			meleeWeaponNameLabels.Text = ""
		end

		if v9 then
			v9.Visible = false
			v9.Text = ""
		end
	else
		local weaponName = p.Weapon:FindFirstChild("WeaponName")

		if weaponName then
			weaponName.Visible = false
			weaponName.Text = ""
		end
	end
end

local function getVisibleWeaponImageLabel(p)
	if not p then
		return nil
	end

	if p.Name ~= "Melee" then
		return p.Weapon:FindFirstChildOfClass("ImageLabel")
	end

	local meleeImageLabels, v9 = getMeleeImageLabels(p)

	if v9 and v9.Visible then
		return v9
	end

	if meleeImageLabels and meleeImageLabels.Visible then
		return meleeImageLabels
	end

	return p.Weapon:FindFirstChildOfClass("ImageLabel")
end

local function updateMeleeInventoryFrame(melee, p, currentEquipped)
	local meleeImageLabels, v9 = getMeleeImageLabels(melee)
	local meleeWeaponNameLabels, v10 = getMeleeWeaponNameLabels(melee)
	melee:SetAttribute("Slot", 3)
	melee.Keybind.Text = "3"
	local v11 = {}
	local v12 = nil
	local v13 = nil

	for _, item in ipairs(p._items) do
		table.insert(v11, `${item.Name}<{item.Identifier}>`)

		if isZeusWeapon(item) then -- inferred equivalent call
			v13 = item
		else
			v12 = item
		end
	end

	if meleeImageLabels then
		meleeImageLabels.Visible = v12 ~= nil
	end

	if v12 and meleeImageLabels then
		meleeImageLabels.Image = v12.Properties.Icon
		meleeImageLabels.ImageColor3 = getWeaponColor(v12)
	end

	if v9 then
		v9.Visible = v13 ~= nil
	end

	if v13 and v9 then
		v9.Image = v13.Properties.Icon
		v9.ImageColor3 = getWeaponColor(v13)
	end

	local v14

	if currentEquipped and currentEquipped.Properties.Slot == "Melee" then
		v14 = currentEquipped
	else
		v14 = v12 or v13
	end

	if v14 then
		local weaponName

		if melee then
			if melee.Name == "Melee" then
				local v15
				weaponName, v15 = getMeleeWeaponNameLabels(melee)

				if isZeusWeapon(v14) then -- inferred equivalent call
					weaponName = v15 or weaponName
				end
			else
				weaponName = melee.Weapon:FindFirstChild("WeaponName")
			end
		end

		local visible2

		if currentEquipped == nil then
			visible2 = false
		else
			visible2 = currentEquipped.Properties.Slot == "Melee"
		end

		if meleeWeaponNameLabels and meleeWeaponNameLabels ~= weaponName then
			meleeWeaponNameLabels.Visible = false
		end

		if v10 and v10 ~= weaponName then
			v10.Visible = false
		end

		if weaponName then
			weaponName.TextColor3 = getWeaponColor(v14)
			GetSkinDisplayName.ApplyNameLabel(weaponName, getInventoryItemDisplayName(v14, "Melee"), v14.NameTag)
			weaponName.Visible = visible2
		end
	else
		melee.Equip.Visible = false
		clearFrameWeaponNameLabels(melee) -- inferred equivalent call

		if meleeImageLabels then
			meleeImageLabels.Visible = false
		end

		if v9 then
			v9.Visible = false
		end
	end
end

local function getObjectiveKitAttributeName() -- 6 equivalent calls inferred from this helper
	local gamemode = workspace:GetAttribute("Gamemode")

	if gamemode == "Bomb Defusal" then
		return "HasDefuseKit"
	elseif gamemode == "Hostage Rescue" then
		return "HasRescueKit"
	end

	return nil
end

local function shouldShowObjectiveKitIcon(instance)
	if not instance or instance:GetAttribute("Team") ~= "Counter-Terrorists" then
		return false
	end

	local objectiveKitAttributeName = getObjectiveKitAttributeName() -- inferred equivalent call
	return objectiveKitAttributeName ~= nil and instance:GetAttribute(objectiveKitAttributeName) == true
end

local function updateObjectiveKitIcon(instance) -- 6 equivalent calls inferred from this helper
	local defuseKit = v8.Grenade.DefuseKit
	local visible2

	if instance and instance:GetAttribute("Team") == "Counter-Terrorists" then
		local objectiveKitAttributeName = getObjectiveKitAttributeName() -- inferred equivalent call

		if objectiveKitAttributeName == nil then
			visible2 = false
		else
			visible2 = instance:GetAttribute(objectiveKitAttributeName) == true
		end
	else
		visible2 = false
	end

	defuseKit.Visible = visible2
end

local function resetFadeTimer()
	if thread then
		task.cancel(thread)
		thread = nil
	end

	for _, v9 in tweens do
		v9:Cancel()
	end

	table.clear(tweens)
	local weaponFrames = getWeaponFrames() -- inferred equivalent call

	if not weaponFrames then
		return
	end

	for _, frame in ipairs(weaponFrames) do
		if not frame:IsA("Frame") then
			continue
		end

		local equip = frame:FindFirstChild("Equip")

		if equip and equip:IsA("Frame") then
			equip.BackgroundTransparency = 0.225
		end

		for _, image in frame:QueryDescendants("ImageLabel, TextLabel") do
			if image:IsA("ImageLabel") then
				image.ImageTransparency = 0.225
			else
				image.TextTransparency = 0.225
			end
		end
	end
end

local function startFade()
	local v9 = DataController.Get(LocalPlayer, "Settings.Game.Item.Always Show Inventory") ~= false
	resetFadeTimer()

	if v9 then
		return
	end

	local weaponFrames = getWeaponFrames() -- inferred equivalent call

	if not weaponFrames then
		return
	end

	for _, frame in ipairs(weaponFrames) do
		if not frame:IsA("Frame") then
			continue
		end

		local equip = frame:FindFirstChild("Equip")

		if equip and equip:IsA("Frame") then
			local tween = TweenService:Create(
				equip,
				TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }
			)
			tweens[frame.Name .. "_Equip"] = tween
			tween:Play()
		end

		for _, image in frame:QueryDescendants("ImageLabel", "TextLabel") do
			local v10 = image:IsA("ImageLabel") and { ImageTransparency = 1 } or {
				TextTransparency = 1
			}
			local tween = TweenService:Create(
				image,
				TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
				v10
			)
			tweens[frame.Name .. "_" .. image:GetFullName()] = tween
			tween:Play()
		end
	end

	thread = task.delay(5, function()
		thread = nil
	end)
end

local function playPickupFlash(instance, imageColor: Color3)
	local defaultSize = instance:GetAttribute("DefaultSize")

	if not defaultSize then
		return
	end

	local udim = UDim2.new(
		defaultSize.X.Scale * 1.1,
		defaultSize.X.Offset * 1.1,
		defaultSize.Y.Scale * 1.1,
		defaultSize.Y.Offset * 1.1
	)

	for _ = 1, 6 do
		local tween = TweenService:Create(
			instance,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ ImageColor3 = color, Size = udim }
		)
		tween:Play()
		tween.Completed:Wait()
		local tween2 = TweenService:Create(
			instance,
			TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{ ImageColor3 = imageColor, Size = defaultSize }
		)
		tween2:Play()
		tween2.Completed:Wait()
	end
end

local function startPickupFlash(p: string, instance, imageColor: Color3)
	if v6[p] then
		task.cancel(v6[p])
		v6[p] = nil
	end

	local defaultSize = instance:GetAttribute("DefaultSize")

	if defaultSize then
		instance.ImageColor3 = imageColor
		instance.Size = defaultSize
	end

	v6[p] = task.spawn(function()
		playPickupFlash(instance, imageColor)
		v6[p] = nil
	end)
end

local function buildInventorySnapshot(items)
	local result = {}

	for _, item in items do
		local strict_type = item._settings._strict_type
		result[strict_type] = {}

		for _, item2 in item._items do
			local identifier = item2.Identifier

			if identifier then
				result[strict_type][identifier] = true
			end
		end
	end

	return result
end

local function detectAndFlashNewItems(items)
	local inventorySnapshot = buildInventorySnapshot(items)

	for _, item in items do
		local strict_type = item._settings._strict_type
		local v9 = v7[strict_type] or {}

		for k, item2 in item._items do
			local identifier = item2.Identifier

			if not identifier or v9[identifier] then
				continue
			end

			if strict_type == "Grenade" then
				local child = v8.Grenade.Grenades:FindFirstChild((tostring(k)))

				if child then
					local grenade = child:FindFirstChild("Grenade")

					if grenade and grenade.Visible then
						startPickupFlash("Grenade_" .. k, grenade, GetPreferenceColor())
					end
				end
			elseif strict_type == "C4" then
				local bomb = v8.Grenade:FindFirstChild("Bomb")

				if bomb and bomb.Visible then
					startPickupFlash("C4", bomb, GetPreferenceColor())
				end
			else
				local child = v8:FindFirstChild(strict_type)

				if child and child:FindFirstChild("Weapon") then
					local imageLabel

					if strict_type == "Melee" then
						if child then
							if child.Name == "Melee" then
								local v10
								imageLabel, v10 = getMeleeImageLabels(child)

								if isZeusWeapon(item2) then -- inferred equivalent call
									imageLabel = v10 or imageLabel
								end
							else
								imageLabel = child.Weapon:FindFirstChildOfClass("ImageLabel")
							end
						end
					elseif child then
						if child.Name == "Melee" then
							local v10
							imageLabel, v10 = getMeleeImageLabels(child)

							if v10 and v10.Visible then
								imageLabel = v10
							elseif not (imageLabel and imageLabel.Visible) then
								imageLabel = child.Weapon:FindFirstChildOfClass("ImageLabel")
							end
						else
							imageLabel = child.Weapon:FindFirstChildOfClass("ImageLabel")
						end
					end

					if imageLabel and imageLabel.Visible then
						startPickupFlash(strict_type .. "_" .. item2.Name, imageLabel, getWeaponColor(item2))
					end
				end
			end
		end
	end

	v7 = inventorySnapshot
end

local function updateCurrentEquipped(p: number, p2)
	if v then
		if v.Name == "Grenade" then
			local child = v:WaitForChild("Grenades"):FindFirstChild((tostring(v2)))

			if child then
				local grenade = child:FindFirstChild("Grenade")
				TweenService:Create(grenade, TweenInfo.new(0.1), {
					Size = grenade:GetAttribute("DefaultSize")
				}):Play()
			end
		else
			local imageLabel = v3

			if not imageLabel then
				local v9 = v

				if v9 then
					if v9.Name == "Melee" then
						local v10
						imageLabel, v10 = getMeleeImageLabels(v9)

						if v10 and v10.Visible then
							imageLabel = v10
						elseif not (imageLabel and imageLabel.Visible) then
							imageLabel = v9.Weapon:FindFirstChildOfClass("ImageLabel")
						end
					else
						imageLabel = v9.Weapon:FindFirstChildOfClass("ImageLabel")
					end
				else
					imageLabel = nil
				end
			end

			clearFrameWeaponNameLabels(v) -- inferred equivalent call
			v.Equip.Visible = false

			if imageLabel then
				TweenService:Create(imageLabel, TweenInfo.new(0.1), {
					Size = imageLabel:GetAttribute("DefaultSize")
				}):Play()
			end
		end
	end

	local child = v8:FindFirstChild((tostring(p2.Properties.Slot)))
	v = child
	v3 = nil

	if child then
		if child.Name == "Grenade" then
			local child2 = child.Grenades:FindFirstChild((tostring(p)))
			v2 = p

			if child2 then
				local grenade = child2:FindFirstChild("Grenade")
				grenade.ImageColor3 = GetPreferenceColor()
				TweenService:Create(grenade, TweenInfo.new(0.1), {
					Size = grenade:GetAttribute("DefaultSize") + UDim2.fromScale(0.1, 0.1)
				}):Play()
			end
		else
			local imageLabel

			if child then
				if child.Name == "Melee" then
					local v9
					imageLabel, v9 = getMeleeImageLabels(child)

					if isZeusWeapon(p2) then -- inferred equivalent call
						imageLabel = v9 or imageLabel
					end
				else
					imageLabel = child.Weapon:FindFirstChildOfClass("ImageLabel")
				end
			end

			local weaponName

			if child then
				if child.Name == "Melee" then
					local v9
					weaponName, v9 = getMeleeWeaponNameLabels(child)

					if isZeusWeapon(p2) then -- inferred equivalent call
						weaponName = v9 or weaponName
					end
				else
					weaponName = child.Weapon:FindFirstChild("WeaponName")
				end
			end

			v3 = imageLabel

			if imageLabel then
				imageLabel.ImageColor3 = getWeaponColor(p2)
			end

			clearFrameWeaponNameLabels(child) -- inferred equivalent call

			if weaponName then
				weaponName.TextColor3 = getWeaponColor(p2)
				GetSkinDisplayName.ApplyNameLabel(weaponName, getInventoryItemDisplayName(p2, child.Name), p2.NameTag)
				weaponName.Visible = true
			end

			child.Equip.Visible = true

			if imageLabel then
				TweenService:Create(imageLabel, TweenInfo.new(0.1), {
					Size = imageLabel:GetAttribute("DefaultSize") + UDim2.fromScale(0.1, 0.1)
				}):Play()
			end
		end
	end

	if not visible then
		return
	end

	local cycleWeaponsIcons = child and child:FindFirstChild("CycleWeaponsIcons")

	if cycleWeaponsIcons then
		cycleWeaponsIcons.Visible = visible
	end
end

local function convertInventoryDataToServerLoadout(inventory)
	if not inventory or #inventory == 0 then
		return nil
	end

	local result = {}

	for i = 1, 5 do
		local v9 = inventory[i]
		local settings

		if v9 then
			settings = v9._settings
		end

		local strict_slot_space

		if settings then
			strict_slot_space = settings._strict_slot_space
		else
			strict_slot_space = v4[i].space
		end

		local strict_type

		if settings then
			strict_type = settings._strict_type
		else
			strict_type = v4[i].type
		end

		result[i] = {
			_items = {},
			_settings = { _strict_slot_space = strict_slot_space, _strict_type = strict_type }
		}

		if not v9 then
			continue
		end

		for _, item in ipairs(v9._items) do
			table.insert(result[i]._items, item)
		end
	end

	return result
end

local function updateInventoryFrame(list, p)
	local imageColor = GetPreferenceColor()
	v8.Grenade.DefuseKit.ImageColor3 = imageColor
	v8.Grenade.Bomb.ImageColor3 = imageColor
	updateObjectiveKitIcon(p or LocalPlayer) -- inferred equivalent call

	if workspace:GetAttribute("Gamemode") == "Hostage Rescue" then
		v8.Grenade.Bomb.Visible = false
	end

	local currentEquipped = InventoryController.getCurrentEquipped()

	for _, v9 in ipairs(list) do
		if v9._settings._strict_type == "Melee" then
			updateMeleeInventoryFrame(v8.Melee, v9, currentEquipped)
		elseif v9._settings._strict_slot_space == 1 then
			local child = v8:FindFirstChild(v9._settings._strict_type)

			if child then
				local item = v9._items[1]

				if item then
					local weapon = child:FindFirstChild("Weapon")
					child:SetAttribute("Slot", item.Slot)
					child.Keybind.Text = item.Slot

					if weapon then
						local child2 = child.Weapon:FindFirstChild(item.Properties.Class)
						child.Weapon.WeaponName.TextColor3 = getWeaponColor(item)
						GetSkinDisplayName.ApplyNameLabel(
							child.Weapon.WeaponName,
							getInventoryItemDisplayName(item, v9._settings._strict_type),
							item.NameTag
						)
						local visible2 = currentEquipped
							and currentEquipped.Properties.Slot == v9._settings._strict_type
						child.Weapon.WeaponName.Visible = visible2

						if child2 then
							for _, image in child.Weapon:GetChildren() do
								if image:IsA("ImageLabel") then
									image.Visible = image == child2
								end
							end

							child2.Image = item.Properties.Icon
							child2.ImageColor3 = getWeaponColor(item)
						end
					end
				else
					child.Equip.Visible = false
					child.Weapon.WeaponName.Text = ""
					child.Weapon.WeaponName.Visible = false

					for _, image in child.Weapon:GetChildren() do
						if image:IsA("ImageLabel") then
							image.Visible = false
						end
					end
				end
			elseif v9._settings._strict_type == "C4" then
				v8.Grenade.Bomb.Visible = v9._items[1]
			end
		elseif v9._settings._strict_type == "Grenade" then
			for i = 1, 4 do
				local child = v8.Grenade.Grenades:FindFirstChild((tostring(i)))

				if not child then
					continue
				end

				local item = v9._items[i]

				if item then
					child.Grenade.ImageColor3 = imageColor
					child.Grenade.Visible = true
					child.Dot.Visible = false

					if item.Properties and item.Properties.Icon then
						child.Grenade.Image = item.Properties.Icon
					end
				else
					child.Grenade.Visible = false
					child.Dot.Visible = true
				end
			end
		end
	end

	for _, frame in v8:GetChildren() do
		if not frame:IsA("Frame") then
			continue
		end

		local visible2 = frame.Name == "Grenade"

		for _, v9 in list do
			if not (#v9._items > 0 and v9._settings._strict_type == frame.Name) then
				continue
			end

			visible2 = true
			break
		end

		frame.Visible = visible2
	end
end

local function updateBotInventoryFrame(instance)
	local v9 = {}

	for k, v10 in v4 do
		v9[k] = {
			_items = {},
			_settings = { _strict_slot_space = v10.space, _strict_type = v10.type }
		}
	end

	local botGrenades = instance:GetAttribute("BotGrenades")
	local success, result = pcall(
		HttpService.JSONDecode,
		HttpService,
		type(botGrenades) ~= "string" and "[]" or botGrenades
	)

	for k, name in (not success or type(result) ~= "table") and {} or result do
		local properties

		if type(name) == "string" then
			properties = GetWeaponProperties(name)
		end

		if properties and #v9[4]._items < v4[4].space then
			table.insert(v9[4]._items, {
				Name = name,
				Skin = "Stock",
				Float = 0,
				Identifier = `{name}:{k}`,
				Properties = properties,
				Slot = 4
			})
		end
	end

	local currentEquipped = instance:GetAttribute("CurrentEquipped")
	local success2, result2 = pcall(
		HttpService.JSONDecode,
		HttpService,
		type(currentEquipped) ~= "string" and "" or currentEquipped
	)

	if success2 then
		if type(result2) == "table" then
			success2 = type(result2.Name) == "string"
		else
			success2 = false
		end
	end

	local properties

	if success2 then
		properties = GetWeaponProperties(result2.Name)
	end

	local v10 = nil
	local v11 = 1

	if properties then
		for k, v12 in v4 do
			if v12.type == properties.Slot and v12.type == "Grenade" then
				for k2, item in v9[k]._items do
					if item.Name ~= result2.Name then
						continue
					end

					v11 = k2
					v10 = item
					break
				end

				break
			elseif v12.type == properties.Slot then
				v10 = {
					Name = result2.Name,
					Skin = result2.Skin,
					Float = result2.Float,
					Identifier = result2.Identifier or result2.Name,
					Properties = properties,
					Slot = k
				}
				table.insert(v9[k]._items, v10)
				break
			end
		end
	end

	updateInventoryFrame(v9, instance)

	if v10 then
		updateCurrentEquipped(v11, v10)
	end
end

local function disconnectBotInventory() -- 2 equivalent calls inferred from this helper
	if attributeChangedConnection then
		attributeChangedConnection:Disconnect()
		attributeChangedConnection = nil
	end
end

local function refreshSpectatedInventory(instance)
	disconnectBotInventory() -- inferred equivalent call

	if not Participants.IsBot(instance) then
		Remotes.Inventory.RequestSpectatedPlayerInventory.Send(instance)
		return
	end

	attributeChangedConnection = instance.AttributeChanged:Connect(function(p: string)
		if SpectateController.GetPlayer() ~= instance then
			return
		end

		if p == "CurrentEquipped" or p == "BotGrenades" then
			updateBotInventoryFrame(instance)
		elseif p == "HasDefuseKit" or p == "HasRescueKit" or p == "Team" then
			updateObjectiveKitIcon(instance) -- inferred equivalent call
		end
	end)
	updateBotInventoryFrame(instance)
end

local function restoreLocalEquipped(currentInventory)
	local currentEquipped = InventoryController.getCurrentEquipped()

	if not (currentInventory and currentEquipped and currentEquipped.Identifier) then
		return
	end

	for i = 1, 5 do
		local v9 = currentInventory[i]

		if not (v9 and v9._items) then
			continue
		end

		for j, item in ipairs(v9._items) do
			if item.Identifier ~= currentEquipped.Identifier then
				continue
			end

			updateCurrentEquipped(j, item)
			return
		end
	end
end

function Inventory.Initialize(_, p)
	v8 = p
	local v9 = table.find(GetUserPlatform(), "Mobile") ~= nil
	v8.Visible = not v9
	v8.Active = false

	for _, v10 in v8:QueryDescendants("GuiObject") do
		v10.Active = false
	end

	for _, v10 in v8:QueryDescendants("ImageLabel, ImageButton") do
		if v10.Parent.Name == "Weapon" or v10.Name == "Grenade" or v10.Name == "Bomb" then
			v10:SetAttribute("DefaultSize", v10.Size)
		end
	end

	for _, frame in v8:GetChildren() do
		if not (frame:IsA("Frame") and frame:FindFirstChild("Button")) then
			continue
		end

		local v10 = frame
		frame.Button.MouseButton1Click:Connect(function()
			local slot = v10:GetAttribute("Slot")

			if slot then
				EquipInventorySlot(slot)
			end
		end)
	end

	for _, frame in v8.Grenade.Grenades:GetChildren() do
		if not frame:IsA("Frame") then
			continue
		end

		local v10 = frame
		frame:FindFirstChild("Button").MouseButton1Click:Connect(function()
			InventoryController.equip(4, (tonumber(v10.Name)))
		end)
	end

	local bomb = v8.Grenade.Bomb

	if bomb:IsA("ImageButton") then
		bomb.MouseButton1Click:Connect(function()
			if bomb.Visible then
				InventoryController.equip(5, 1)
			end
		end)
	end
end

local function getSpectatedPlayer() -- 4 equivalent calls inferred from this helper
	if LocalPlayer:GetAttribute("IsSpectating") == true then
		return SpectateController.GetPlayer()
	end

	return nil
end

function Inventory.Start()
	InventoryController.OnInventoryChanged:Connect(function(p)
		if not LocalPlayer:GetAttribute("IsSpectating") then
			updateInventoryFrame(p)
			detectAndFlashNewItems(p)
		end
	end)
	InventoryController.OnInventoryItemEquipped:Connect(function(p: number, p2)
		updateCurrentEquipped(p, p2)

		if DataController.Get(LocalPlayer, "Settings.Game.Item.Always Show Inventory") == false then
			local slot = p2.Properties.Slot

			if slot == "Primary" or slot == "Secondary" or slot == "Melee" or slot == "Grenade" then
				startFade()
			end
		end
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Glow Weapon with Rarity Color", function()
		local currentInventory = InventoryController.getCurrentInventory()

		if currentInventory then
			updateInventoryFrame(currentInventory)
		end

		local currentEquipped = InventoryController.getCurrentEquipped()

		if currentEquipped then
			local child = v8:FindFirstChild((tostring(currentEquipped.Properties.Slot)))

			if child and child.Name ~= "Grenade" then
				local weaponColor = getWeaponColor(currentEquipped)
				local imageLabel

				if child then
					if child.Name == "Melee" then
						local v9
						imageLabel, v9 = getMeleeImageLabels(child)

						if isZeusWeapon(currentEquipped) then -- inferred equivalent call
							imageLabel = v9 or imageLabel
						end
					else
						imageLabel = child.Weapon:FindFirstChildOfClass("ImageLabel")
					end
				end

				if imageLabel then
					imageLabel.ImageColor3 = weaponColor
				end

				local weaponName

				if child then
					if child.Name == "Melee" then
						local v9
						weaponName, v9 = getMeleeWeaponNameLabels(child)

						if isZeusWeapon(currentEquipped) then -- inferred equivalent call
							weaponName = v9 or weaponName
						end
					else
						weaponName = child.Weapon:FindFirstChild("WeaponName")
					end
				end

				if weaponName then
					weaponName.TextColor3 = weaponColor
				end
			end
		end
	end)

	local function rebuildInventoryVisuals() -- 1 equivalent call inferred from this helper
		if LocalPlayer:GetAttribute("IsSpectating") == true then
			local player = SpectateController.GetPlayer()

			if player then
				refreshSpectatedInventory(player)
			end
		else
			local currentInventory = InventoryController.getCurrentInventory()

			if currentInventory then
				updateInventoryFrame(currentInventory)
			end
		end
	end

	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", rebuildInventoryVisuals)

	local function updateLocalObjectiveKitIcon() -- 1 equivalent call inferred from this helper
		if not LocalPlayer:GetAttribute("IsSpectating") then
			local v9 = LocalPlayer
			local defuseKit = v8.Grenade.DefuseKit
			local visible2

			if v9 and v9:GetAttribute("Team") == "Counter-Terrorists" then
				local objectiveKitAttributeName = getObjectiveKitAttributeName() -- inferred equivalent call

				if objectiveKitAttributeName == nil then
					visible2 = false
				else
					visible2 = v9:GetAttribute(objectiveKitAttributeName) == true
				end
			else
				visible2 = false
			end

			defuseKit.Visible = visible2
		end
	end

	LocalPlayer:GetAttributeChangedSignal("HasDefuseKit"):Connect(updateLocalObjectiveKitIcon)
	LocalPlayer:GetAttributeChangedSignal("HasRescueKit"):Connect(updateLocalObjectiveKitIcon)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(function()
		updateLocalObjectiveKitIcon() -- inferred equivalent call
		rebuildInventoryVisuals() -- inferred equivalent call
	end)
	Remotes.Inventory.SpectatedPlayerInventory.Listen(function(data)
		if LocalPlayer:GetAttribute("IsSpectating") ~= true then
			return
		end

		local player = SpectateController.GetPlayer()

		if not player or data.Player ~= player then
			return
		end

		local v9 = convertInventoryDataToServerLoadout(data.Inventory)

		if not v9 then
			return
		end

		updateInventoryFrame(v9, player)
		local equippedSlot = data.EquippedSlot or 0
		local equippedSlotSpace = data.EquippedSlotSpace or 0

		if equippedSlot > 0 and equippedSlotSpace > 0 then
			local v10 = v9[equippedSlot]

			if v10 and v10._items and v10._items[equippedSlotSpace] then
				updateCurrentEquipped(equippedSlotSpace, v10._items[equippedSlotSpace])
			end
		end
	end)
	SpectateController.ListenToSpectate:Connect(function(instance)
		if instance then
			refreshSpectatedInventory(instance)
			updateObjectiveKitIcon(instance) -- inferred equivalent call
		else
			disconnectBotInventory() -- inferred equivalent call
			local currentInventory = InventoryController.getCurrentInventory()

			if currentInventory then
				updateInventoryFrame(currentInventory)
			end

			restoreLocalEquipped(currentInventory)
			local v9 = LocalPlayer
			local defuseKit = v8.Grenade.DefuseKit
			local visible2

			if v9 and v9:GetAttribute("Team") == "Counter-Terrorists" then
				local objectiveKitAttributeName = getObjectiveKitAttributeName() -- inferred equivalent call

				if objectiveKitAttributeName == nil then
					visible2 = false
				else
					visible2 = v9:GetAttribute(objectiveKitAttributeName) == true
				end
			else
				visible2 = false
			end

			defuseKit.Visible = visible2
		end
	end)

	local function updateSpectatedObjectiveKit()
		local spectatedPlayer = getSpectatedPlayer() -- inferred equivalent call

		if spectatedPlayer then
			local defuseKit = v8.Grenade.DefuseKit
			local visible2

			if spectatedPlayer and spectatedPlayer:GetAttribute("Team") == "Counter-Terrorists" then
				local objectiveKitAttributeName = getObjectiveKitAttributeName() -- inferred equivalent call

				if objectiveKitAttributeName == nil then
					visible2 = false
				else
					visible2 = spectatedPlayer:GetAttribute(objectiveKitAttributeName) == true
				end
			else
				visible2 = false
			end

			defuseKit.Visible = visible2
		end
	end

	local function connectObjectiveKitSignals(object)
		if object == LocalPlayer then
			return
		end

		object:GetAttributeChangedSignal("HasDefuseKit"):Connect(updateSpectatedObjectiveKit)
		object:GetAttributeChangedSignal("HasRescueKit"):Connect(updateSpectatedObjectiveKit)
		object:GetAttributeChangedSignal("Team"):Connect(updateSpectatedObjectiveKit)
	end

	for _, v9 in ipairs(Players:GetPlayers()) do
		connectObjectiveKitSignals(v9)
	end

	Players.PlayerAdded:Connect(connectObjectiveKitSignals)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(function()
		if LocalPlayer:GetAttribute("IsSpectating") then
			local spectatedPlayer = getSpectatedPlayer() -- inferred equivalent call

			if spectatedPlayer then
				updateObjectiveKitIcon(spectatedPlayer) -- inferred equivalent call
			end
		else
			local v9 = LocalPlayer
			local defuseKit = v8.Grenade.DefuseKit
			local visible2

			if v9 and v9:GetAttribute("Team") == "Counter-Terrorists" then
				local objectiveKitAttributeName = getObjectiveKitAttributeName() -- inferred equivalent call

				if objectiveKitAttributeName == nil then
					visible2 = false
				else
					visible2 = v9:GetAttribute(objectiveKitAttributeName) == true
				end
			else
				visible2 = false
			end

			defuseKit.Visible = visible2
		end
	end)

	if LocalPlayer:GetAttribute("IsSpectating") then
		local spectatedPlayer = getSpectatedPlayer() -- inferred equivalent call

		if spectatedPlayer then
			updateObjectiveKitIcon(spectatedPlayer) -- inferred equivalent call
		end
	else
		updateObjectiveKitIcon(LocalPlayer) -- inferred equivalent call
	end

	local function requestSpectatedInventoryUpdate()
		local spectatedPlayer = getSpectatedPlayer() -- inferred equivalent call

		if spectatedPlayer then
			refreshSpectatedInventory(spectatedPlayer)
		end
	end

	Remotes.Inventory.NewInventoryItem.Listen(requestSpectatedInventoryUpdate)
	Remotes.Inventory.RemoveInventoryItem.Listen(requestSpectatedInventoryUpdate)
	DataController.CreateListener(LocalPlayer, "Settings.Game.Item.Always Show Inventory", startFade)
	task.wait(0.1)

	if DataController.Get(LocalPlayer, "Settings.Game.Item.Always Show Inventory") == false then
		startFade()
	end
end

return Inventory