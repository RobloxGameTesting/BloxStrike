local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Other = ReplicatedStorage.Assets.Other
local character = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("MuzzleFlashes"):WaitForChild("Character")
require(ReplicatedStorage.Database.Custom.Types)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local GetMuzzleFlash = require(ReplicatedStorage.Components.Common.VFXLibary.CreateMuzzleFlash.GetMuzzleFlash)
local ThirdPersonWeaponStash = require(ReplicatedStorage.Components.Common.ThirdPersonWeaponStash)
local DebugFlags = require(ReplicatedStorage.Shared.DebugFlags)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Attachments = require(ReplicatedStorage.Database.Custom.GameStats.Character.Attachments)
local v = { "PrimaryAttachment", "SecondaryAttachment", "MeleeAttachment" }
local v2 = {
	MuzzlePartL = 1,
	MuzzlePartR = 1,
	MuzzlePart = 1,
	RootPart = 1,
	Hitbox = 1,
	Insert = 1,
	move = 1
}
local v3 = CFrame.new(0, -0.4, 0.24) * CFrame.Angles(0, 3.141592653589793, 0)
local cframe2 = CFrame.new(0, 0.2, 0.8) * CFrame.Angles(1.5707963267948966, 0.20943951023931956, 0.17453292519943295)
local v4 = {}
local v5 = {}

local function dlog(p, value: string, ...)
	if not DebugFlags.IsEnabled("ThirdPersonWeaponModels") then
		return
	end

	local v6 = not p and "[ThirdPersonWeaponModels] " or "[ThirdPersonWeaponModels] " .. p.Name .. " - "
	warn(v6 .. value:format(...))
end

local function destroyInstance(instance) -- 16 equivalent calls inferred from this helper
	if instance then
		instance:Destroy()
	end
end

local function GetSmokeGrenadeTeam(instance, p: string)
	if p ~= "Smoke Grenade" then
		return nil
	end

	local team = instance:GetAttribute("Team")

	if team == "Counter-Terrorists" or team == "Terrorists" then
		return team
	end

	return nil
end

local function IsWeaponEquippedInHand(weapon: string, skin: string, p) -- 1 equivalent call inferred from this helper
	return weapon == p.Name and skin == p.Skin
end

local function GetCharacterData(p) -- 5 equivalent calls inferred from this helper
	local selected = v4[p] or { Character = nil }
	v4[p] = selected
	return selected
end

local function GetJointPart(name: string, instance) -- 1 equivalent call inferred from this helper
	local v6 = Attachments.WEAPON_JOINT_PARTS[name] or Attachments.DEFAULT_JOINT_PART
	local child = instance:WaitForChild(v6, 10)
	assert(child, `Failed to get joint part: {v6} for weapon: {name}`)
	return child
end

local function GetUpperTorso(instance)
	local humanoidRootPart = instance:FindFirstChild("HumanoidRootPart")
		or instance:WaitForChild("HumanoidRootPart", 10)

	if not (humanoidRootPart and humanoidRootPart:IsA("BasePart")) then
		return nil
	end

	local upperTorso = instance:FindFirstChild("UpperTorso") or instance:WaitForChild("UpperTorso", 10)

	if upperTorso and upperTorso:IsA("BasePart") then
		return upperTorso
	end

	return nil
end

local function SetWeaponProperties(folder)
	for _, part in ipairs(folder:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = "WeaponModel"
		part.CastShadow = false
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Anchored = false
		part.Massless = true
		local transparency = v2[part.Name]

		if transparency then
			part.Transparency = transparency
		end
	end
end

local function SetupMuzzleFlashPart(p, p2) -- 3 equivalent calls inferred from this helper
	if not (p and p2.MuzzleType) then
		return
	end

	GetMuzzleFlash(p, character, p2.MuzzleType, "WeldConstraint")

	if p2.HasSuppressor then
		GetMuzzleFlash(p, character, "Suppressor", "WeldConstraint")
	end
end

local function SetModelVisible(instance, folder, flag: boolean)
	local v6 = flag and instance:GetAttribute("SpectatedFirstPerson") ~= true

	for _, part in ipairs(folder:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Transparency = v2[part.Name] or v6 and 0 or 1
		end
	end
end

local function CreateWeldForWeapon(instance, attachment)
	local parent = attachment.Parent

	if not (parent and parent:IsA("BasePart")) then
		error(`Character attachment parent is not a BasePart: {attachment.Name}`)
	end

	local insert = instance:FindFirstChild("Insert", true) or instance.PrimaryPart

	if not insert then
		error("Weapon model has no PrimaryPart or Insert part")
	end

	local attachment2 = insert:FindFirstChild("WeaponAttachment")

	if not attachment2 then
		attachment2 = Instance.new("Attachment")
		attachment2.Name = "WeaponAttachment"
		attachment2.Parent = insert
	end

	instance:PivotTo(parent.CFrame * attachment.CFrame * attachment2.CFrame:Inverse() * insert.CFrame:Inverse() * instance:GetPivot())

	if not pcall(function()
		local attachmentConstraint = Instance.new("AttachmentConstraint")
		attachmentConstraint.Parent = insert
		attachmentConstraint.Attachment0 = attachment
		attachmentConstraint.Attachment1 = attachment2
	end) then
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Parent = insert
		weldConstraint.Part0 = parent
		weldConstraint.Part1 = insert
	end
end

local function GetPlayerAttachmentsFolder(p)
	local playerCharacter = CharacterResolver.getPlayerCharacter(p)

	if not playerCharacter then
		return nil
	end

	local weaponAttachments = playerCharacter:FindFirstChild("WeaponAttachments")

	if weaponAttachments and weaponAttachments:IsA("Folder") then
		return weaponAttachments
	end

	destroyInstance(weaponAttachments) -- inferred equivalent call
	local folder = Instance.new("Folder")
	folder.Name = "WeaponAttachments"
	folder.Parent = playerCharacter
	return folder
end

local function GetOrCreateCharacterFolder(parent, name: string)
	local v6 = nil

	for _, folder in ipairs(parent:GetChildren()) do
		if folder.Name ~= name then
			continue
		end

		if folder:IsA("Folder") and not v6 then
			v6 = folder
		else
			destroyInstance(folder) -- inferred equivalent call
		end
	end

	if v6 then
		return v6
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function ToModelWithPrimaryPart(defuseKit)
	local clone = defuseKit:Clone()
	local parent

	if clone:IsA("Model") then
		parent = clone
	else
		parent = Instance.new("Model")
		clone.Parent = parent
	end

	local primaryPart = parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart", true)

	if primaryPart then
		if not parent.PrimaryPart then
			parent.PrimaryPart = primaryPart
		end

		return parent
	else
		destroyInstance(parent) -- inferred equivalent call
		return nil
	end
end

local function GetOrCreateTorsoAttachment(instance, name: string, cframe: CFrame)
	local attachment = instance:FindFirstChild(name, true)

	if attachment and attachment:IsA("Attachment") then
		attachment.CFrame = cframe
		return attachment
	end

	local parent = GetUpperTorso(instance)

	if not parent then
		return nil
	end

	local attachment2 = Instance.new("Attachment")
	attachment2.Name = name
	attachment2.CFrame = cframe
	attachment2.Parent = parent
	return attachment2
end

local function AttachHolsterModel(p, instance, attachment, name: string) -- 2 equivalent calls inferred from this helper
	SetWeaponProperties(instance)
	CreateWeldForWeapon(instance, attachment)
	local parent = GetPlayerAttachmentsFolder(p)

	if parent then
		instance.Name = name
		instance.Parent = parent
		return instance
	else
		destroyInstance(instance) -- inferred equivalent call
		return nil
	end
end

local function CreateObjectiveKitHolsterModel(instance, instance2)
	local defuseKit = Other:FindFirstChild("DefuseKit")

	if not defuseKit then
		dlog(instance, "objective kit holster skipped: missing template Assets.Other.DefuseKit")
		return nil
	end

	local bodyBackAttachment = instance2:FindFirstChild("BodyBackAttachment", true)
	local v6

	if bodyBackAttachment and bodyBackAttachment:IsA("Attachment") then
		v6 = bodyBackAttachment.CFrame * v3
	else
		v6 = v3
	end

	local attachment = GetOrCreateTorsoAttachment(instance2, "ObjectiveKitAttachment", v6)

	if not attachment then
		dlog(instance, "objective kit holster skipped: no valid character attachment")
		return nil
	end

	local toModelWithPrimaryPart = ToModelWithPrimaryPart(defuseKit)

	if not toModelWithPrimaryPart then
		dlog(instance, "objective kit holster skipped: template has no BasePart")
		return nil
	end

	return AttachHolsterModel(instance, toModelWithPrimaryPart, attachment, "ObjectiveKitHolster") -- inferred equivalent call
end

local function DestroyObjectiveKitHolsters(instance, p)
	local objectiveKitHolsterModel = p.ObjectiveKitHolsterModel

	if objectiveKitHolsterModel then
		objectiveKitHolsterModel:Destroy()
	end

	p.ObjectiveKitHolsterModel = nil
	local playerCharacter = CharacterResolver.getPlayerCharacter(instance)
	local weaponAttachments

	if playerCharacter then
		weaponAttachments = playerCharacter:FindFirstChild("WeaponAttachments")
	end

	if not weaponAttachments then
		return
	end

	for _, model in ipairs(weaponAttachments:GetChildren()) do
		if model:IsA("Model") and model.Name == "ObjectiveKitHolster" and model then
			model:Destroy()
		end
	end
end

local function UpdateObjectiveKitHolster(instance, p)
	local v6 = v4[instance] or { Character = nil }
	v4[instance] = v6
	local v7

	if instance:GetAttribute("Team") == "Counter-Terrorists" then
		v7 = instance:GetAttribute("HasDefuseKit") == true or instance:GetAttribute("HasRescueKit") == true
	else
		v7 = false
	end

	local objectiveKitHolsterModel = v6.ObjectiveKitHolsterModel

	if v7 and objectiveKitHolsterModel and objectiveKitHolsterModel.Parent then
		return
	end

	DestroyObjectiveKitHolsters(instance, v6)

	if v7 then
		v6.ObjectiveKitHolsterModel = CreateObjectiveKitHolsterModel(instance, p)
	end
end

local function CreateBombHolsterModel(instance, p, data)
	local attachment = GetOrCreateTorsoAttachment(p, "BombAttachment", cframe2)

	if not attachment then
		dlog(instance, "bomb holster skipped: no valid character attachment (missing UpperTorso)")
		return nil
	end

	local characterModel = Skins.GetCharacterModel(
		"C4",
		data.Skin or "",
		data.Float,
		data.StatTrack,
		data.NameTag,
		false,
		data.Stickers
	)

	if not characterModel then
		dlog(instance, "bomb holster skipped: SkinHandler returned nil for C4")
		return nil
	end

	return AttachHolsterModel(instance, characterModel, attachment, "BombHolster") -- inferred equivalent call
end

local function DestroyBombHolster(p) -- 3 equivalent calls inferred from this helper
	destroyInstance(p.BombHolsterModel) -- inferred equivalent call
	p.BombHolsterModel = nil
	p.BombHolsterVisible = nil
end

local function UpdateBombHolster(instance, p, p2)
	local characterData = GetCharacterData(instance) -- inferred equivalent call
	local slot5 = instance:GetAttribute("Slot5")
	local v6

	if slot5 then
		v6 = HttpService:JSONDecode(slot5)
	end

	if v6 and v6.Weapon == "C4" then
		local bombHolsterModel = characterData.BombHolsterModel

		if not (bombHolsterModel and bombHolsterModel.Parent) then
			DestroyBombHolster(characterData) -- inferred equivalent call
			bombHolsterModel = CreateBombHolsterModel(instance, p, v6)
			characterData.BombHolsterModel = bombHolsterModel
		end

		local bombHolsterVisible = not p2 or p2.Name ~= "C4"

		if bombHolsterModel and characterData.BombHolsterVisible ~= bombHolsterVisible then
			SetModelVisible(p, bombHolsterModel, bombHolsterVisible)
			characterData.BombHolsterVisible = bombHolsterVisible
		end
	else
		DestroyBombHolster(characterData) -- inferred equivalent call
	end
end

local function CacheWeaponCharacterModel(instance, instance2, p: number, data, visible: boolean)
	local weapon = data.Weapon
	local skin = data.Skin
	local getCharacterModel = Skins.GetCharacterModel
	local float = data.Float
	local statTrack = data.StatTrack
	local nameTag = data.NameTag
	local stickers = data.Stickers
	local team

	if weapon == "Smoke Grenade" then
		team = instance:GetAttribute("Team")

		if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
			team = nil
		end
	end

	local characterModel = getCharacterModel(weapon, skin, float, statTrack, nameTag, false, stickers, team)

	if not characterModel then
		dlog(instance, "holster skipped: SkinHandler returned nil for slot=%d weapon=%s skin=%s", p, weapon, skin)
		return
	end

	SetWeaponProperties(characterModel)
	local v6 = v[p]
	local child

	if v6 then
		child = instance2:FindFirstChild(v6, true)
	end

	if not child then
		dlog(instance, "missing character attachment for slot=%d weapon=%s (expected %s)", p, weapon, (tostring(v6)))
		error(`Missing character attachment for slot: {p}`)
	end

	CreateWeldForWeapon(characterModel, child)
	local parent = GetPlayerAttachmentsFolder(instance)

	if parent then
		characterModel.Parent = parent
		characterModel.Name = weapon
	end

	local characterData = GetCharacterData(instance) -- inferred equivalent call
	characterData[p] = {
		StatTrack = data.StatTrack,
		Stickers = data.Stickers,
		NameTag = data.NameTag,
		Model = characterModel,
		Float = data.Float,
		Charm = data.Charm,
		Weapon = weapon,
		Skin = skin,
		Visible = visible
	}
	dlog(instance, "cached holster slot=%d weapon=%s skin=%s visible=%s", p, weapon, skin, "unknown")
	SetModelVisible(instance2, characterModel, visible)
end

local function DestroyEquippedModels(p)
	local equippedModels = p.EquippedModels

	if equippedModels then
		for _, equippedModel in pairs(equippedModels) do
			for _, motor in equippedModel.Motors do
				motor:Destroy()
			end

			destroyInstance(equippedModel.Model) -- inferred equivalent call
		end
	end

	p.EquippedModels = nil
	p.ActiveEquipped = nil
end

local function DisconnectCharacter(p) -- 2 equivalent calls inferred from this helper
	local v6 = v5[p]

	if v6 then
		for _, connection in v6 do
			connection:Disconnect()
		end

		v5[p] = nil
	end
end

local function ClearPlayerCache(p)
	DisconnectCharacter(p) -- inferred equivalent call
	local v6 = v4[p]

	if v6 then
		local character2 = v6.Character
		DestroyEquippedModels(v6)
		destroyInstance(v6.ObjectiveKitHolsterModel) -- inferred equivalent call
		v6.ObjectiveKitHolsterModel = nil
		DestroyBombHolster(v6) -- inferred equivalent call

		for k, v7 in pairs(v6) do
			if not (typeof(k) == "number" and typeof(v7) == "table") then
				continue
			end

			destroyInstance(v7.Model) -- inferred equivalent call
			v6[k] = nil
		end

		if character2 then
			for _, childName in { "WeaponModel", "WeaponAttachments" } do
				local folder = character2:FindFirstChild(childName)

				if folder and folder:IsA("Folder") then
					folder:ClearAllChildren()
				end
			end
		end
	end

	dlog(p, "cleared player cache (destroyed holsters)")
	v4[p] = nil
end

local function RefreshHolsterVisibility(p, character2)
	local v6 = v4[p]

	if not v6 or v6.Character ~= character2 then
		return
	end

	for k, v7 in pairs(v6) do
		if not (typeof(k) == "number" and typeof(v7) == "table" and v7.Model and v7.Visible ~= nil) then
			continue
		end

		SetModelVisible(character2, v7.Model, v7.Visible)
	end

	local bombHolsterModel = v6.BombHolsterModel

	if bombHolsterModel and v6.BombHolsterVisible ~= nil then
		SetModelVisible(character2, bombHolsterModel, v6.BombHolsterVisible)
	end
end

local function InitializePlayerCache(p, character2)
	local v6 = v4[p] or { Character = nil }
	v4[p] = v6

	if v6.Character == character2 then
		return
	end

	if v6.Character then
		ClearPlayerCache(p)
		v6 = v4[p] or { Character = nil }
		v4[p] = v6
	end

	v6.Character = character2
	DisconnectCharacter(p) -- inferred equivalent call
	v5[p] = {
		character2:GetAttributeChangedSignal("SpectatedFirstPerson"):Connect(function()
			RefreshHolsterVisibility(p, character2)
		end),
		(character2.AncestryChanged:Connect(function(_, parent)
			local v7 = v4[p]

			if parent or not v7 then
				return
			end

			DestroyEquippedModels(v7)
			v7.ObjectiveKitHolsterModel = nil
			v7.BombHolsterModel = nil

			for k, v8 in pairs(v7) do
				if not (typeof(k) == "number" and typeof(v8) == "table") then
					continue
				end

				v7[k] = nil
			end

			v7.Character = nil
		end))
	}
end

local function UpdateCachedWeapon(p, p2, k: number, p3, p4)
	local weaponProperties = GetWeaponProperties(p3.Weapon)

	if weaponProperties and weaponProperties.ShootingOptions == "Dual" then
		return
	end

	local characterData = GetCharacterData(p) -- inferred equivalent call
	local v6 = characterData[k]
	local weaponEquippedInHand = IsWeaponEquippedInHand(p3.Weapon, p3.Skin, p4) -- inferred equivalent call
	local visible = not weaponEquippedInHand

	if v6 then
		local v7

		if v6.Skin == p3.Skin then
			v7 = v6.Weapon == p3.Weapon
		else
			v7 = false
		end

		if v7 and v6.Model then
			if v6.Visible ~= visible then
				SetModelVisible(p2, v6.Model, visible)
				v6.Visible = visible
			end

			return
		else
			destroyInstance(v6.Model) -- inferred equivalent call
		end
	end

	characterData[k] = nil
	dlog(
		p,
		"holster slot=%d weapon=%s skin=%s equippedInHand=%s",
		k,
		p3.Weapon,
		p3.Skin,
		(tostring(weaponEquippedInHand))
	)
	CacheWeaponCharacterModel(p, p2, k, p3, visible)
end

local function CreateCharacterWeapons(p, playerCharacter, p2, list)
	InitializePlayerCache(p, playerCharacter)
	local characterData = GetCharacterData(p) -- inferred equivalent call

	for i = 1, 3 do
		local v6 = characterData[i]

		if list[i] or not v6 then
			continue
		end

		destroyInstance(v6.Model) -- inferred equivalent call
		characterData[i] = nil
	end

	for k, v6 in pairs(list) do
		if v6 then
			UpdateCachedWeapon(p, playerCharacter, k, v6, p2)
		end
	end

	UpdateObjectiveKitHolster(p, playerCharacter)
	UpdateBombHolster(p, playerCharacter, p2)
end

local function SetupSuppressorState(instance, p, isSuppressed: boolean) -- 3 equivalent calls inferred from this helper
	local silencer = instance:FindFirstChild("Silencer", true)

	if silencer and p.HasSuppressor then
		silencer.Transparency = isSuppressed and 0 or 1
	end
end

local function ResolveWeaponBindPart(instance, childName: string?)
	if childName then
		local part = instance:FindFirstChild(childName, true)

		if part and part:IsA("BasePart") then
			return part
		end
	end

	if instance.PrimaryPart then
		return instance.PrimaryPart
	end

	local insert = instance:FindFirstChild("Insert", true)

	if insert and insert:IsA("BasePart") then
		return insert
	end

	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function CreateMotor6DAttachment(p, instance, value: string?)
	local part = ResolveWeaponBindPart(instance, value)

	if not part then
		warn(`CreateMotor6DAttachment: no bindable part on "{instance.Name}", skipping attachment`)
		return nil
	end

	local identity = CFrame.identity
	local identity2 = CFrame.identity
	local properties = instance:FindFirstChild("Properties")

	if properties then
		for _, v6 in ipairs(value and { "LEFT", "RIGHT" } or { "" }) do
			local child = properties:FindFirstChild("C0" .. v6)

			if child then
				identity = child.Value
			end

			local child2 = properties:FindFirstChild("C1" .. v6)

			if child2 then
				identity2 = child2.Value
			end
		end
	end

	ThirdPersonWeaponStash.PoseForJoint(instance, part, p, identity, identity2)
	local motor6D = Instance.new("Motor6D")
	motor6D.Name = "WeaponAttachment" .. (value or "")
	motor6D.C0 = identity
	motor6D.C1 = identity2
	motor6D.Part0 = p
	motor6D.Part1 = part
	motor6D.Parent = p
	return motor6D
end

local function CreateDualMotor6DAttachments(instance, p)
	local rightHand = instance:FindFirstChild("RightHand")
	local leftHand = instance:FindFirstChild("LeftHand")

	if not (rightHand and leftHand) then
		warn("CreateDualMotor6DAttachments: Could not find RightHand or LeftHand for dual weapon")
		return {}
	end

	local v6 = {}
	local motor6DAttachment = CreateMotor6DAttachment(rightHand, p, "HandleR")

	if motor6DAttachment then
		table.insert(v6, motor6DAttachment)
	end

	local motor6DAttachment2 = CreateMotor6DAttachment(leftHand, p, "HandleL")

	if motor6DAttachment2 then
		table.insert(v6, motor6DAttachment2)
	end

	return v6
end

local function CreateEquippedMotors(instance, p, p2, flag: boolean)
	if flag then
		return (CreateDualMotor6DAttachments(instance, p2))
	end

	local motor6DAttachment = CreateMotor6DAttachment(p, p2, nil)

	if motor6DAttachment then
		return { motor6DAttachment }
	end

	return {}
end

local function GetEquippedModelKey(instance, data)
	local stickers = data.Stickers
	local name = data.Name
	local skin = data.Skin
	local float = tostring(data.Float)
	local statTrack = tostring(data.StatTrack)
	local nameTag = tostring(data.NameTag)
	local v6 = typeof(stickers) ~= "table" and "" or HttpService:JSONEncode(stickers)
	local team

	if data.Name == "Smoke Grenade" then
		team = instance:GetAttribute("Team")

		if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
			team = nil
		end
	end

	return table.concat({ name, skin, float, statTrack, nameTag, v6, (tostring(team)) }, "|")
end

local function ParkActiveEquipped(p) -- 1 equivalent call inferred from this helper
	local activeEquipped = p.ActiveEquipped

	if not activeEquipped then
		return
	end

	p.ActiveEquipped = nil
	ThirdPersonWeaponStash.Park(activeEquipped.Model, activeEquipped.Motors)
end

local function EvictEquippedModels(equippedModels)
	local count = 0
	local lastUsed = 1e999
	local v6 = nil

	for k, item in pairs(equippedModels) do
		count += 1

		if not (item.LastUsed < lastUsed) then
			continue
		end

		lastUsed = item.LastUsed
		v6 = k
	end

	if count > 8 and v6 then
		destroyInstance(equippedModels[v6].Model) -- inferred equivalent call
		equippedModels[v6] = nil
	end
end

local function CreateEquippedWeapon(instance, playerCharacter, data)
	if not playerCharacter.Parent then
		return nil
	end

	local v6 = GetJointPart(data.Name, playerCharacter) -- inferred equivalent call
	local weaponProperties = GetWeaponProperties(data.Name)

	if not weaponProperties then
		return nil
	end

	local characterData = GetCharacterData(instance) -- inferred equivalent call
	ParkActiveEquipped(characterData) -- inferred equivalent call
	local parent = GetOrCreateCharacterFolder(playerCharacter, "WeaponModel")
	parent:ClearAllChildren()
	destroyInstance(v6:FindFirstChild("WeaponAttachment")) -- inferred equivalent call
	destroyInstance(v6:FindFirstChild("WeaponAttachmentHandleR")) -- inferred equivalent call
	local leftHand = playerCharacter:FindFirstChild("LeftHand")
	destroyInstance(leftHand and leftHand:FindFirstChild("WeaponAttachmentHandleL")) -- inferred equivalent call
	local equippedModels = characterData.EquippedModels or {}
	characterData.EquippedModels = equippedModels
	local equippedModelKey = GetEquippedModelKey(instance, data)
	local v7 = weaponProperties.ShootingOptions == "Dual"
	local equippedModel = equippedModels[equippedModelKey]

	if equippedModel then
		equippedModels[equippedModelKey] = nil

		if ThirdPersonWeaponStash.TryUnpark(equippedModel.Model, parent) then
			SetupSuppressorState(equippedModel.Model, weaponProperties, data.IsSuppressed) -- inferred equivalent call
			equippedModel.Motors = CreateEquippedMotors(playerCharacter, v6, equippedModel.Model, v7)

			if #equippedModel.Motors == 0 then
				destroyInstance(equippedModel.Model) -- inferred equivalent call
				return nil
			else
				ThirdPersonWeaponStash.Release(equippedModel.Motors)
				equippedModel.LastUsed = os.clock()
				equippedModels[equippedModelKey] = equippedModel
				characterData.ActiveEquipped = equippedModel
				return v6
			end
		end
	end

	local getCharacterModel = Skins.GetCharacterModel
	local name = data.Name
	local skin = data.Skin
	local float = data.Float
	local statTrack = data.StatTrack
	local nameTag = data.NameTag
	local stickers = data.Stickers
	local team

	if data.Name == "Smoke Grenade" then
		team = instance:GetAttribute("Team")

		if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
			team = nil
		end
	end

	local characterModel = getCharacterModel(name, skin, float, statTrack, nameTag, false, stickers, team)

	if not characterModel then
		dlog(instance, "equipped weapon skipped: SkinHandler returned nil for weapon=%s skin=%s", data.Name, data.Skin)
		return nil
	end

	SetWeaponProperties(characterModel)
	SetupSuppressorState(characterModel, weaponProperties, data.IsSuppressed) -- inferred equivalent call
	local interactables = weaponProperties.MuzzleType and characterModel:FindFirstChild("Interactables")

	if interactables then
		if v7 then
			SetupMuzzleFlashPart(interactables:FindFirstChild("MuzzlePartL"), weaponProperties) -- inferred equivalent call
			SetupMuzzleFlashPart(interactables:FindFirstChild("MuzzlePartR"), weaponProperties) -- inferred equivalent call
		else
			SetupMuzzleFlashPart(interactables:FindFirstChild("MuzzlePart"), weaponProperties) -- inferred equivalent call
		end
	end

	local motors = CreateEquippedMotors(playerCharacter, v6, characterModel, v7)

	if #motors == 0 then
		dlog(instance, "equipped weapon skipped: nothing to joint on weapon=%s", data.Name)
		destroyInstance(characterModel) -- inferred equivalent call
		return nil
	else
		characterModel.Name = "Equipped"
		characterModel.Parent = parent
		local activeEquipped = { Model = characterModel, Motors = motors, LastUsed = os.clock() }
		equippedModels[equippedModelKey] = activeEquipped
		characterData.ActiveEquipped = activeEquipped
		EvictEquippedModels(equippedModels)
		return v6
	end
end

local self = setmetatable({}, {
	__call = function(_, p, p2, p3)
		local playerCharacter = CharacterResolver.getPlayerCharacter(p)

		if not playerCharacter then
			return nil, nil
		end

		InitializePlayerCache(p, playerCharacter)
		local equippedWeapon = CreateEquippedWeapon(p, playerCharacter, p2)
		CreateCharacterWeapons(p, playerCharacter, p2, p3)

		if equippedWeapon then
			return equippedWeapon, ClearPlayerCache
		end

		return nil, nil
	end
})
self.ClearPlayerCache = ClearPlayerCache

function self.RefreshObjectiveKitHolster(p)
	local playerCharacter = CharacterResolver.getPlayerCharacter(p)

	if playerCharacter then
		InitializePlayerCache(p, playerCharacter)
		UpdateObjectiveKitHolster(p, playerCharacter)
	end
end

function self.RefreshBombHolster(instance)
	local playerCharacter = CharacterResolver.getPlayerCharacter(instance)

	if not playerCharacter then
		return
	end

	InitializePlayerCache(instance, playerCharacter)
	local currentEquipped = instance:GetAttribute("CurrentEquipped")
	local v6

	if currentEquipped then
		v6 = HttpService:JSONDecode(currentEquipped)
	end

	UpdateBombHolster(instance, playerCharacter, v6)
end

function self.RefreshSuppressorState(p, p2)
	local playerCharacter = CharacterResolver.getPlayerCharacter(p)
	local weaponModel = playerCharacter and playerCharacter:FindFirstChild("WeaponModel")
	local equipped = weaponModel and weaponModel:FindFirstChild("Equipped")

	if not (equipped and equipped:IsA("Model")) then
		return false
	end

	local weaponProperties = GetWeaponProperties(p2.Name)

	if not weaponProperties then
		return false
	end

	SetupSuppressorState(equipped, weaponProperties, p2.IsSuppressed) -- inferred equivalent call
	return true
end

Players.PlayerRemoving:Connect(ClearPlayerCache)
return self