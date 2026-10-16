local Skins = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
require(script:WaitForChild("Types"))
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local v = nil
local Signal = require(ReplicatedStorage.Packages.Signal)
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Weapons = Assets:WaitForChild("Weapons")
local skins = Assets:WaitForChild("Skins")
local onItemStockSchemasUpdated = Signal.new()
Skins.OnItemStockSchemasUpdated = onItemStockSchemasUpdated
local v2 = {}
local v3 = {}
local v4 = {
	{ max = 0.07, wear = "Factory New" },
	{ max = 0.15, wear = "Minimal Wear" },
	{ max = 0.38, wear = "Field-Tested" },
	{ max = 0.45, wear = "Well-Worn" },
	{ max = 1, wear = "Battle-Scarred" }
}
local v5 = {
	["Factory New"] = "Mint Condition",
	["Minimal Wear"] = "Near-Mint",
	["Field-Tested"] = "Standard-Grade",
	["Well-Worn"] = "Combat-Worn",
	["Battle-Scarred"] = "War-Torn"
}

local function GetDataController()
	if not v then
		local success, result = pcall(function()
			return require(ReplicatedStorage.Controllers.DataController)
		end)

		if success then
			v = result
		end
	end

	return v
end

local function ResolveCharmFromId(id: string)
	if not v then
		local success, result = pcall(function()
			return require(ReplicatedStorage.Controllers.DataController)
		end)

		if success then
			v = result
		end
	end

	local v6 = v

	if not v6 then
		return nil
	end

	local localPlayer = Players.LocalPlayer

	if not localPlayer then
		return nil
	end

	local inventory = v6.Get(localPlayer, "Inventory")

	if not inventory or typeof(inventory) ~= "table" then
		return nil
	end

	for _, v7 in ipairs(inventory) do
		if v7._id == id and v7.Type == "Charm" then
			return { Skin = v7.Skin, Pattern = v7.Pattern }
		end
	end

	return nil
end

local function ValidateInputs(value: string, value2: string) -- 7 equivalent calls inferred from this helper
	return typeof(value) == "string" and typeof(value2) == "string" and value ~= "" and value2 ~= ""
end

local function Weld(primaryPart, part) -- 3 equivalent calls inferred from this helper
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = primaryPart
	weldConstraint.Part1 = part
	weldConstraint.Parent = primaryPart
end

local function UpdateAvailableSkins(avaiableSkins: string) -- 1 equivalent call inferred from this helper
	v2 = HttpService:JSONDecode(avaiableSkins)

	if #onItemStockSchemasUpdated:GetConnections() > 0 then
		onItemStockSchemasUpdated:Fire(v2)
	end
end

local function CreateSyntheticStockSchema(name: string)
	local weaponProperties = GetWeaponProperties(name)

	if weaponProperties then
		return {
			paintId = "stock",
			type = weaponProperties.Class,
			name = name,
			skin = "Stock",
			rarity = "Stock",
			floatRange = { min = 0, max = 0.07 },
			floatChances = {
				{ wear = "Factory New", chance = 100 }
			},
			charmImages = {},
			wearImages = {},
			supportsStatTrak = false,
			statTrakChance = 0,
			isEnabled = true,
			isMarketplaceVisible = false,
			collection = nil,
			description = "Standard issue finish.",
			caseRarity = "Stock",
			imageAssetId = weaponProperties.Icon or weaponProperties.ReverseIcon
		}
	end

	return nil
end

local function GetSyntheticStockSchema(name: string) -- 1 equivalent call inferred from this helper
	local selected = v3[name] or CreateSyntheticStockSchema(name)
	v3[name] = selected
	return selected
end

local function GetKillTrackValue(value, p: string)
	local v6 = value or 0
	assert(typeof(v6) == "number", "KillCount must be a number")
	local success, result = pcall(GetWeaponProperties, p)

	if success and result then
		if result.Class == "Melee" then
			return (tostring((math.clamp(math.floor(v6), 0, 9999))))
		end

		return string.format("%06d", (math.clamp(math.floor(v6), 0, 999999)))
	else
		return nil
	end
end

local function GetWeaponFolder(childName: string) -- 6 equivalent calls inferred from this helper
	local folder = Weapons:FindFirstChild(childName)

	if folder and folder:IsA("Folder") then
		return folder
	end

	return nil
end

local function GetSkinTextureFolder(childName: string, childName2: string, childName3: string?)
	local child = skins:FindFirstChild(childName)

	if not child then
		return nil
	end

	if childName3 and childName == "Smoke Grenade" then
		local folder = child:FindFirstChild(childName3)

		if folder and folder:IsA("Folder") then
			return folder
		end
	end

	local folder = child:FindFirstChild(childName2)

	if folder and folder:IsA("Folder") then
		return folder
	end

	return nil
end

local function GetSkinVariantFolder(p: string, value: string, p2: string?, childName: string) -- 2 equivalent calls inferred from this helper
	local skinTextureFolder = GetSkinTextureFolder(p, value, p2)
	return skinTextureFolder and skinTextureFolder:FindFirstChild(childName)
end

local function GetWearFromFloat(p, value: number)
	local v6 = math.max(p.floatRange.min, p.floatRange.max - 1e-12)
	local v7 = math.clamp(math.clamp(value, p.floatRange.min, v6), 0, 1)

	for _, v8 in ipairs(v4) do
		if v7 < v8.max then
			return v8.wear, v5[v8.wear]
		end
	end

	return "Battle-Scarred", "War-Torn"
end

local function GetWearTextureFolder(folder, p, p2: number)
	if not (folder and folder:IsA("Folder")) then
		return nil
	end

	local wearFromFloat = GetWearFromFloat(p, p2)
	local folder2 = wearFromFloat and folder:FindFirstChild(wearFromFloat)

	if folder2 and folder2:IsA("Folder") then
		return folder2
	end

	for _, v6 in ipairs(v4) do
		local folder3 = folder:FindFirstChild(v6.wear)

		if folder3 and folder3:IsA("Folder") then
			return folder3
		end
	end

	return nil
end

local function ApplySkinTextures(folder, instance)
	if not instance then
		return
	end

	for _, surfaceAppearance in ipairs(instance:GetChildren()) do
		if not surfaceAppearance:IsA("SurfaceAppearance") then
			continue
		end

		for _, part in ipairs(folder:GetDescendants()) do
			if not (part:IsA("MeshPart") and part.Name == surfaceAppearance.Name) then
				continue
			end

			local surfaceAppearance2 = part:FindFirstChildOfClass("SurfaceAppearance")

			if surfaceAppearance2 then
				surfaceAppearance2:Destroy()
			end

			local clone = surfaceAppearance:Clone()
			clone.Parent = part
		end
	end
end

local function ForEachWeaponPart(instance, callback, ...)
	local weapon = instance:FindFirstChild("Weapon")

	if weapon then
		callback(instance, weapon, ...)
		return
	end

	local weaponL = instance:FindFirstChild("WeaponL")
	local weaponR = instance:FindFirstChild("WeaponR")

	if weaponL then
		callback(instance, weaponL, ...)
	end

	if weaponR then
		callback(instance, weaponR, ...)
	end
end

local function AttachStatTrakToWeapon(parent, instance, p, p2: string, flag: boolean)
	local success, result = pcall(GetWeaponProperties, p2)
	local v6 = success and result and result.Class == "Melee" and "KillTrackKnife" or "KillTrak"
	local clone = Assets.Other[v6]:Clone()
	local primaryPart = instance.PrimaryPart
	local killTrack = primaryPart and instance:FindFirstChild("KillTrack", true)

	if not killTrack then
		clone:Destroy()
		return
	end

	Weld(clone.PrimaryPart, primaryPart) -- inferred equivalent call
	clone:PivotTo(killTrack.WorldCFrame)
	local surfaceGui = clone.Screen.SurfaceGui
	surfaceGui.TextLabel.Text = GetKillTrackValue(p, p2)

	if flag then
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		surfaceGui.CanvasSize = Vector2.new(100, 25)
		surfaceGui.TextLabel.TextSize = 29
		surfaceGui.TextLabel.Size = UDim2.fromScale(1, 1)
	end

	clone.Parent = parent
end

local function AttachNameTagToWeapon(parent, instance, p, flag: boolean)
	local clone = Assets.Other.NamePlate:Clone()
	local primaryPart = instance.PrimaryPart
	local nametag = primaryPart and primaryPart:FindFirstChild("Nametag")

	if not nametag then
		clone:Destroy()
		return
	end

	Weld(clone.PrimaryPart, primaryPart) -- inferred equivalent call
	clone:PivotTo(nametag.WorldCFrame)
	local surfaceGui = clone.Screen.SurfaceGui
	surfaceGui.TextLabel.Text = tostring(p)

	if flag then
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		surfaceGui.CanvasSize = Vector2.new(100, 8)
		surfaceGui.TextLabel.TextSize = 8.98
		surfaceGui.TextLabel.Size = UDim2.fromScale(0.95, 1)
		surfaceGui.TextLabel.Position = UDim2.fromOffset(5, 0)
	end

	clone.Parent = parent
end

local function FindCharmModels(childName: string, p: number)
	local charms = Assets:FindFirstChild("Charms")
	local charmBase = charms and charms:FindFirstChild("CharmBase")

	if not (charmBase and charmBase:IsA("Model")) then
		return nil, nil
	end

	local child = charms:FindFirstChild(childName)
	local model = child and child:FindFirstChild((tostring(p)))

	if model and model:IsA("Model") then
		return charmBase, model
	end

	return charmBase, nil
end

local function MountSpecificCharm(clone, instance)
	local clone2 = instance:Clone()
	clone2.Parent = clone
	local part = clone:FindFirstChild("Part")

	if part and part:IsA("BasePart") then
		clone2:PivotTo(part.CFrame)
		part:Destroy()
	end

	local hingeConstraint = clone:FindFirstChild("HingeConstraint", true)
	local attachment = hingeConstraint and clone2.PrimaryPart and clone2.PrimaryPart:FindFirstChild("Attachment")

	if attachment then
		hingeConstraint.Attachment1 = attachment
	end
end

local function AttachCharmToWeapon(parent, skin: string, pattern: number, position: string, flag: boolean)
	local v6, v7 = FindCharmModels(skin, pattern)

	if v6 then
		if v7 then
			local child = parent:FindFirstChild("Charm" .. position, true)

			if child then
				local parent2 = child.Parent

				if not (parent2 and parent2:IsA("BasePart")) then
					return
				end

				local clone = v6:Clone()
				clone.Parent = parent
				clone:PivotTo(child.WorldCFrame)

				if clone.PrimaryPart then
					Weld(clone.PrimaryPart, parent2) -- inferred equivalent call
				end

				MountSpecificCharm(clone, v7)
			elseif not flag then
				print("Charm attachment not found for weapon:", parent.Name, position)
			end
		elseif not flag then
			warn("Specific charm not found for weapon:", parent.Name, skin, pattern)
		end
	elseif not flag then
		warn("Charm base not found for weapon:", parent.Name)
	end
end

local function AttachCharm(instance, data, flag: boolean)
	if not (typeof(data) == "table" and (data._id and data.Position)) then
		return
	end

	local position = data.Position
	local skin, pattern

	if data.Skin and data.Pattern then
		skin = data.Skin
		pattern = data.Pattern
	else
		local charmFromId = ResolveCharmFromId(data._id)

		if not charmFromId then
			return
		end

		skin = charmFromId.Skin
		pattern = charmFromId.Pattern
	end

	if not (skin and pattern) then
		return
	end

	if instance:FindFirstChild("Weapon") then
		AttachCharmToWeapon(instance, skin, pattern, position, flag)
		return
	end

	local weaponL = instance:FindFirstChild("WeaponL")
	local weaponR = instance:FindFirstChild("WeaponR")

	if weaponL then
		AttachCharmToWeapon(instance, skin, pattern, position, flag)
	end

	if flag and weaponR then
		AttachCharmToWeapon(instance, skin, pattern, position, flag)
	end
end

local function WaitForSkinInformation(p: string, p2: string) -- 5 equivalent calls inferred from this helper
	local skinInformation = Skins.GetSkinInformation(p, p2)

	if not skinInformation and next(v2) == nil then
		onItemStockSchemasUpdated:Wait()
		skinInformation = Skins.GetSkinInformation(p, p2)
	end

	return skinInformation
end

local function DecorateModel(clone, p, p2, p3: number?, p4: string, p5, p6, p7, flag: boolean)
	ApplySkinTextures(clone, GetWearTextureFolder(p, p2, p3 or p2.floatRange.max))

	if p5 then
		ForEachWeaponPart(clone, AttachStatTrakToWeapon, p5, p4, flag)
	end

	if p6 then
		ForEachWeaponPart(clone, AttachNameTagToWeapon, p6, flag)
	end

	if p7 then
		AttachCharm(clone, p7, flag)
	end

	return clone
end

function Skins.GetCharmModel(name: string, p: number)
	local v6, v7 = FindCharmModels(name, p)

	if not v6 then
		warn(`Skins.GetCharmModel: Charm base not found for charm "{name}" with pattern "{p}"`)
		return nil
	end

	if not v7 then
		warn(`Skins.GetCharmModel: Specific charm not found for charm "{name}" with pattern "{p}"`)
		return nil
	end

	local clone = v6:Clone()
	clone.Name = name
	MountSpecificCharm(clone, v7)
	return clone
end

function Skins.GetBadgeModel(childName: string)
	local badges = Assets:FindFirstChild("Badges")

	if not badges then
		warn(`Skins.GetBadgeModel: Badges folder not found for badge "{childName}"`)
		return nil
	end

	local model = badges:FindFirstChild(childName)

	if model and model:IsA("Model") then
		return model:Clone()
	end

	warn(`Skins.GetBadgeModel: Badge model not found for "{childName}"`)
	return nil
end

function Skins.GetWearNameForFloat(p, p2: number)
	return GetWearFromFloat(p, p2)
end

function Skins.GetAbbreviatedWearName(value: string)
	return string.gsub(value, "[^A-Z]", "")
end

function Skins.ObserveItemStockSchemas(callback)
	local connection = onItemStockSchemasUpdated:Connect(callback)

	if next(v2) ~= nil then
		callback(v2)
	end

	return function()
		if connection.Connected then
			connection:Disconnect()
		end
	end
end

Skins.GetKillTrackValue = GetKillTrackValue

function Skins.GetMagazine(childName: string, childName2: string, p: number?)
	if not ValidateInputs(childName, childName2) then -- inferred equivalent call
		return nil
	end

	local waitForSkinInformation = WaitForSkinInformation(childName, childName2) -- inferred equivalent call

	if not waitForSkinInformation then
		return nil
	end

	local weaponFolder = GetWeaponFolder(childName) -- inferred equivalent call
	local character = weaponFolder and weaponFolder:FindFirstChild("Character")

	if not (character and character:IsA("Model")) then
		return nil
	end

	local parts = {}

	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part:HasTag("CharacterMagazine") then
			table.insert(parts, part)
		end
	end

	if #parts == 0 then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = "Magazine"

	for _, v6 in ipairs(parts) do
		local clone = v6:Clone()
		clone.Parent = model

		if not model.PrimaryPart then
			model.PrimaryPart = clone
		end
	end

	local child = skins:FindFirstChild(childName)
	local folder

	if child then
		folder = child:FindFirstChild(childName2)

		if not (folder and folder:IsA("Folder")) then
			folder = nil
		end
	end

	local character2 = folder and folder:FindFirstChild("Character")
	ApplySkinTextures(
		model,
		GetWearTextureFolder(character2, waitForSkinInformation, p or waitForSkinInformation.floatRange.min)
	)
	return model
end

function Skins.GetGloves(name: string, childName: string, p: number?)
	if not ValidateInputs(name, childName) then -- inferred equivalent call
		return nil
	end

	local waitForSkinInformation = WaitForSkinInformation(name, childName) -- inferred equivalent call

	if not waitForSkinInformation then
		return nil
	end

	local weaponFolder = GetWeaponFolder(name) -- inferred equivalent call

	if not weaponFolder then
		return nil
	end

	local model = Instance.new("Model")
	model.Name = name

	for _, part in ipairs(weaponFolder:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		local clone = part:Clone()
		clone.Parent = model
	end

	local child = skins:FindFirstChild(name)
	local folder

	if child then
		folder = child:FindFirstChild(childName)

		if not (folder and folder:IsA("Folder")) then
			folder = nil
		end
	end

	local camera = folder and folder:FindFirstChild("Camera")
	ApplySkinTextures(
		model,
		GetWearTextureFolder(camera, waitForSkinInformation, p or waitForSkinInformation.floatRange.min)
	)
	return model
end

function Skins.GetCharacterModel(p: string, value: string, p2: number?, p3, p4, p5, _, p6: string?)
	if not ValidateInputs(p, value) then -- inferred equivalent call
		return nil
	end

	local waitForSkinInformation = WaitForSkinInformation(p, value) -- inferred equivalent call

	if not waitForSkinInformation then
		warn(`SkinHandler.GetCharacterModel: Skin "{value}" not found for weapon "{p}"`)
		return nil
	end

	local weaponFolder = GetWeaponFolder(p) -- inferred equivalent call
	local character = weaponFolder and weaponFolder:FindFirstChild("Character")

	if not (character and character:IsA("Model")) then
		warn(`SkinHandler.GetCharacterModel: Base character model not found for weapon "{p}"`)
		return nil
	end

	return (DecorateModel(
		character:Clone(),
		GetSkinVariantFolder(p, value, p6, "Character"), -- inferred equivalent call
		waitForSkinInformation,
		p2,
		p,
		p3,
		p4,
		p5,
		false
	))
end

function Skins.GetWorldModel(childName: string, childName2: string, p: number?, p2, p3, p4, _)
	if not ValidateInputs(childName, childName2) then -- inferred equivalent call
		return nil
	end

	local waitForSkinInformation = WaitForSkinInformation(childName, childName2) -- inferred equivalent call

	if not waitForSkinInformation then
		return nil
	end

	local weaponFolder = GetWeaponFolder(childName) -- inferred equivalent call
	local other = weaponFolder and weaponFolder:FindFirstChild("Other")
	local world = other and other:FindFirstChild("World")

	if not (world and world:IsA("Model")) then
		return nil
	end

	local clone = world:Clone()
	local child = skins:FindFirstChild(childName)
	local folder

	if child then
		folder = child:FindFirstChild(childName2)

		if not (folder and folder:IsA("Folder")) then
			folder = nil
		end
	end

	local character = folder and folder:FindFirstChild("Character")
	return (DecorateModel(clone, character, waitForSkinInformation, p, childName, p2, p3, p4, false))
end

function Skins.GetCameraModel(p: string, value: string, p2: number?, p3, p4, p5, _, p6: string?)
	if not ValidateInputs(p, value) then -- inferred equivalent call
		return nil
	end

	local waitForSkinInformation = WaitForSkinInformation(p, value) -- inferred equivalent call

	if not waitForSkinInformation then
		return nil
	end

	local weaponFolder = GetWeaponFolder(p) -- inferred equivalent call
	local camera = weaponFolder and weaponFolder:FindFirstChild("Camera")

	if not (camera and camera:IsA("Model")) then
		return nil
	end

	return (DecorateModel(
		camera:Clone(),
		GetSkinVariantFolder(p, value, p6, "Camera"), -- inferred equivalent call
		waitForSkinInformation,
		p2,
		p,
		p3,
		p4,
		p5,
		true
	))
end

function Skins.GetSkinInformation(name: string, value: string)
	if not ValidateInputs(name, value) then -- inferred equivalent call
		return nil
	end

	local v6 = v2[name]

	if v6 and v6[value] then
		return v6[value]
	end

	if value ~= "Stock" then
		return nil
	end

	return GetSyntheticStockSchema(name) -- inferred equivalent call
end

function Skins.IsSkinAvailable(childName: string, childName2: string)
	local skinInformation = Skins.GetSkinInformation(childName, childName2)

	if not skinInformation then
		return false
	end

	if
		skinInformation.type ~= "Weapon"
		and skinInformation.type ~= "Melee"
		and skinInformation.type ~= "Glove"
		and skinInformation.type ~= "Zeus x27"
	then
		return true
	end

	local folder = skins:FindFirstChild(childName)

	if not (folder and folder:IsA("Folder")) then
		return false
	end

	local child = skins:FindFirstChild(childName)
	local folder2

	if child then
		folder2 = child:FindFirstChild(childName2)

		if not (folder2 and folder2:IsA("Folder")) then
			folder2 = nil
		end
	end

	return folder2 ~= nil
end

function Skins.HasSkinTextures(childName: string, childName2: string)
	if not ValidateInputs(childName, childName2) then -- inferred equivalent call
		return false
	end

	local folder = skins:FindFirstChild(childName)

	if not (folder and folder:IsA("Folder")) then
		return true
	end

	local child = skins:FindFirstChild(childName)
	local folder2

	if child then
		folder2 = child:FindFirstChild(childName2)

		if not (folder2 and folder2:IsA("Folder")) then
			folder2 = nil
		end
	end

	return folder2 ~= nil
end

function Skins.GetAllSkinsForWeapon(value: string)
	if typeof(value) ~= "string" or value == "" then
		return nil
	end

	local v6 = v2[value]

	if not v6 then
		return nil
	end

	local result = {}

	for _, v7 in pairs(v6) do
		table.insert(result, v7)
	end

	return result
end

function Skins.GetWearImageForFloat(p, p2: number)
	local wearFromFloat = GetWearFromFloat(p, p2)

	if not wearFromFloat then
		return nil
	end

	for _, wearImage in ipairs(p.wearImages) do
		if wearImage.wear == wearFromFloat then
			return wearImage.assetId
		end
	end

	return nil
end

local function getCharmImageForPattern(p, p2: number?)
	for _, v6 in p.charmImages or {} do
		if v6.pattern == p2 then
			return v6.assetId
		end
	end

	return nil
end

function Skins.GetItemIconImage(p, data)
	local assetId

	if data.Type == "Charm" or data.Name == "Charm" then
		local pattern = data.Pattern or 1
		local flag = true

		for _, v6 in p.charmImages or {} do
			if v6.pattern ~= pattern then
				continue
			end

			assetId = v6.assetId
			flag = false
			break
		end

		if flag then
			assetId = nil
		end
	else
		assetId = Skins.GetWearImageForFloat(p, data.Float or 0)
	end

	return assetId or p.imageAssetId or ""
end

function Skins.GetBaseWeaponModel(value: string, childName: string)
	if typeof(value) ~= "string" or value == "" then
		return nil
	end

	local weaponFolder = GetWeaponFolder(value) -- inferred equivalent call

	if not weaponFolder then
		return nil
	end

	local model = weaponFolder:FindFirstChild(childName)

	if model and model:IsA("Model") then
		return (model:Clone())
	end

	return nil
end

local function SyncAvailableSkins() -- 1 equivalent call inferred from this helper
	local avaiableSkins = ReplicatedStorage:GetAttribute("AvaiableSkins")

	if avaiableSkins then
		UpdateAvailableSkins(avaiableSkins) -- inferred equivalent call
	end
end

SyncAvailableSkins() -- inferred equivalent call
ReplicatedStorage:GetAttributeChangedSignal("AvaiableSkins"):Connect(SyncAvailableSkins)
return Skins