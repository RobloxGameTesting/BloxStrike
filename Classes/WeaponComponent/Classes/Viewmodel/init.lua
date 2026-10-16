local Viewmodel = {}
Viewmodel.__index = Viewmodel
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local camera = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("MuzzleFlashes"):WaitForChild("Camera")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local GetMuzzleFlash = require(ReplicatedStorage.Components.Common.VFXLibary.CreateMuzzleFlash.GetMuzzleFlash)
local AttachGlovesToViewmodel = require(ReplicatedStorage.Database.Components.Common.AttachGlovesToViewmodel)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Sound = require(ReplicatedStorage.Classes.Sound)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local BakedViewmodelMirror = require(ReplicatedStorage.Shared.BakedViewmodelMirror)
local ViewmodelHand = require(ReplicatedStorage.Shared.ViewmodelHand)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Animation = require(script.Classes.Animation)
local Bobble = require(script.Classes.Bobble)
local CurrentCamera = workspace.CurrentCamera
local frozen = table.freeze({})
local v = { "Weapon", "WeaponL", "WeaponR", "CharmBase" }
local cframe = CFrame.new(0, 10000, 0)
local v2 = {}
local count = 0
local v3 = nil
local v4 = {}

local function updateTransparency(folder, flag: boolean)
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local hiddenTransparency = descendant:GetAttribute("HiddenTransparency")

			if flag then
				local transparency = descendant.Transparency
				descendant.Transparency = 1

				if not hiddenTransparency then
					descendant:SetAttribute("HiddenTransparency", transparency)
				end
			elseif hiddenTransparency then
				descendant.Transparency = hiddenTransparency
			end
		elseif descendant:IsA("Texture") then
			if flag then
				if descendant.Transparency < 1 then
					descendant:SetAttribute("HiddenTransparency", descendant.Transparency)
					descendant.Transparency = 1
				end
			else
				local hiddenTransparency = descendant:GetAttribute("HiddenTransparency")

				if hiddenTransparency ~= nil then
					descendant.Transparency = hiddenTransparency
					descendant:SetAttribute("HiddenTransparency", nil)
				end
			end
		end
	end
end

local function setupMuzzleFlashPart(p, properties) -- 3 equivalent calls inferred from this helper
	if not (p and properties.MuzzleType) then
		return
	end

	GetMuzzleFlash(p, camera, properties.MuzzleType, "Motor6D")

	if properties.HasSuppressor then
		GetMuzzleFlash(p, camera, "Suppressor", "Motor6D")
	end
end

local function stripWeaponGeometry(model)
	for _, childName in ipairs(v) do
		local child = model:FindFirstChild(childName)

		if child then
			child:Destroy()
		end
	end
end

local function findWeaponRoot(model) -- 2 equivalent calls inferred from this helper
	return model:FindFirstChild("Weapon") or model:FindFirstChild("WeaponL") or model:FindFirstChild("WeaponR")
end

local function getViewmodelStash() -- 1 equivalent call inferred from this helper
	local v5 = v3

	if v5 and v5.Parent == CurrentCamera then
		return v5
	end

	v5 = Instance.new("Folder")
	v5.Name = "ViewmodelStash"
	v5.Parent = CurrentCamera
	v3 = v5
	return v5
end

local function getCarryOverKey(weaponComponent, p: string, p2: string)
	if weaponComponent.Character or weaponComponent.Player ~= Players.LocalPlayer or p == "C4" then
		return nil
	end

	local charm = weaponComponent.Charm
	local v5

	if type(charm) == "table" then
		v5 = `{charm.Skin}:{charm.Pattern}:{charm.Position}`
	else
		v5 = tostring(charm)
	end

	local viewmodelCameraWeapon = weaponComponent.ViewmodelCameraWeapon or p
	local float = tostring(weaponComponent.Float)
	local v6

	if weaponComponent.StatTrack == nil then
		v6 = false
	else
		v6 = weaponComponent.StatTrack ~= false
	end

	return table.concat({
		viewmodelCameraWeapon,
		p,
		p2,
		float,
		tostring(v6),
		tostring(weaponComponent.NameTag),
		v5,
		(tostring(weaponComponent.ViewmodelHideWeaponGeometry == true))
	}, "|")
end

local function getCharacterKey(character)
	local team = character:GetAttribute("Team")
	local characterName = character:GetAttribute("CharacterName")
		or workspace:GetAttribute(team == "Counter-Terrorists" and "CTCharacter" or "TCharacter")
	local bodyColors = character:FindFirstChild("Body Colors")
	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
	local torsoColor3

	if bodyColors then
		torsoColor3 = bodyColors.TorsoColor3
	elseif torso and torso:IsA("BasePart") then
		torsoColor3 = torso.Color
	end

	return table.concat({
		tostring(team),
		tostring(characterName),
		tostring(character:GetAttribute("EquippedGloves")),
		not torsoColor3 and "" or torsoColor3:ToHex()
	}, "|")
end

local function isLocalPlayerDead() -- 2 equivalent calls inferred from this helper
	return Players.LocalPlayer:GetAttribute("Dead") == true
end

local function flushCarryOver()
	if isLocalPlayerDead() then -- inferred equivalent call
		return
	end

	local now = os.clock()

	for i = #v4, 1, -1 do
		local v5 = v4[i]

		if v5.Viewmodel.IsDestroyed then
			table.remove(v4, i)
		elseif v5.ExpiresAt <= now then
			table.remove(v4, i)
			v5.Viewmodel:destroy()
			task.delay(0, flushCarryOver)
			break
		end
	end
end

Players.LocalPlayer:GetAttributeChangedSignal("Dead"):Connect(function()
	if isLocalPlayerDead() or #v4 == 0 then -- inferred equivalent call
		return
	end

	local v5 = os.clock() + 5

	for _, v6 in v4 do
		v6.ExpiresAt = math.max(v6.ExpiresAt, v5)
	end

	task.delay(5.1, flushCarryOver)
end)

local function weldLooseParts(folder)
	local primaryPart = folder.PrimaryPart

	if not primaryPart then
		return
	end

	local descendants = folder:GetDescendants()
	local v5 = {}

	for _, instance in ipairs(descendants) do
		if not ((instance:IsA("JointInstance") or instance:IsA("WeldConstraint")) and instance.Enabled) then
			continue
		end

		local part0 = instance.Part0
		local part1 = instance.Part1

		if not (part0 and part1) then
			continue
		end

		v5[part0] = v5[part0] or {}
		v5[part1] = v5[part1] or {}
		table.insert(v5[part0], part1)
		table.insert(v5[part1], part0)
	end

	local v6 = { [primaryPart] = true }
	local v7 = { primaryPart }

	while #v7 > 0 do
		for _, v8 in v5[table.remove(v7)] or {} do
			if v6[v8] then
				continue
			end

			v6[v8] = true
			table.insert(v7, v8)
		end
	end

	local charmBase = folder:FindFirstChild("CharmBase")

	for _, part in ipairs(descendants) do
		if not part:IsA("BasePart") or part == primaryPart or charmBase and part:IsDescendantOf(charmBase) then
			continue
		end

		part.Anchored = false

		if v6[part] then
			continue
		end

		local weld = Instance.new("Weld")
		weld.Name = "LooseWeld"
		weld.Part0 = primaryPart
		weld.Part1 = part
		weld.C0 = primaryPart.CFrame:ToObjectSpace(part.CFrame)
		weld.Parent = part
	end
end

local function getChargeGuiObject(model, p: string)
	local interactables = model and model:FindFirstChild("Interactables")
	local charge = interactables and interactables:FindFirstChild("Charge", true)
	local surfaceGui = charge and charge:FindFirstChildOfClass("SurfaceGui")

	if not surfaceGui then
		return nil
	end

	local child = surfaceGui:FindFirstChild(p)

	if child and child:IsA(p) then
		return child
	end

	return surfaceGui:FindFirstChildWhichIsA(p)
end

local function getRechargeChargeAlpha(weaponComponent)
	local properties = weaponComponent and weaponComponent.Properties

	if not properties then
		return nil
	end

	local rechargeTime = properties.RechargeTime
	local rounds = properties.Rounds

	if not rechargeTime or not rounds or rounds <= 0 then
		return nil
	end

	local v5 = math.clamp((tonumber(weaponComponent.Rounds) or rounds) / rounds, 0, 1)

	if v5 >= 1 then
		return 1
	end

	local rechargeStartTime = tonumber(weaponComponent.RechargeStartTime)

	if rechargeStartTime then
		return (math.clamp(
			v5 + math.clamp(math.max(workspace:GetServerTimeNow() - rechargeStartTime, 0) / rechargeTime, 0, 1) / rounds,
			0,
			1
		))
	end

	return v5
end

local color = Color3.fromRGB(125, 20, 20)
local color2 = Color3.fromRGB(255, 235, 140)
local color3 = Color3.fromRGB(40, 223, 213)

local function updateChargeFrame(object, p: number)
	local chargeFillFrame = object.ChargeFillFrame

	if not (chargeFillFrame and chargeFillFrame.Parent) then
		chargeFillFrame = getChargeGuiObject(object.Model, "Frame")
		object.ChargeFillFrame = chargeFillFrame
		local chargeFillBaseSize

		if chargeFillFrame then
			chargeFillBaseSize = chargeFillFrame.Size or nil
		end

		object.ChargeFillBaseSize = chargeFillBaseSize
	end

	local chargeTextLabel = object.ChargeTextLabel

	if not (chargeTextLabel and chargeTextLabel.Parent) then
		chargeTextLabel = getChargeGuiObject(object.Model, "TextLabel")
		object.ChargeTextLabel = chargeTextLabel
	end

	local chargeFillBaseSize = object.ChargeFillBaseSize

	if not (chargeFillFrame and chargeFillBaseSize) then
		return
	end

	local v5 = getRechargeChargeAlpha(object.WeaponComponent) or 1
	local displayedChargeAlpha = object.DisplayedChargeAlpha
	local v6

	if displayedChargeAlpha == nil or v5 < displayedChargeAlpha then
		v6 = v5
	else
		local v7 = math.clamp(p * 3.5, 0, 1)
		v6 = displayedChargeAlpha + (v5 - displayedChargeAlpha) * v7
	end

	if math.abs(v5 - v6) <= 0.001 then
		v6 = v5
	end

	local displayedChargeAlpha2 = v6 >= 0.999 and 1 or v6
	object.DisplayedChargeAlpha = displayedChargeAlpha2
	chargeFillFrame.Size = UDim2.new(
		chargeFillBaseSize.X.Scale,
		chargeFillBaseSize.X.Offset,
		0.8 * displayedChargeAlpha2,
		0
	)
	local v7

	if displayedChargeAlpha2 >= 0.999 then
		v7 = color3
	else
		v7 = color:Lerp(color2, displayedChargeAlpha2)
	end

	chargeFillFrame.BackgroundColor3 = v7

	if chargeTextLabel then
		chargeTextLabel.Text = `{math.round(displayedChargeAlpha2 * 100)}%`
		chargeTextLabel.TextColor3 = v7
	end
end

local v5 = {}
local v6 = {}

local function singleAssemblyRoot(folder)
	local primaryPart = folder.PrimaryPart

	if primaryPart == nil then
		return nil
	end

	for _, part in folder:GetDescendants() do
		if part:IsA("BasePart") and part.AssemblyRootPart ~= primaryPart then
			return nil
		end
	end

	return primaryPart
end

local function pivotModel(pivotPlans, instance, cframe2: CFrame)
	local now = os.clock()
	local v7 = pivotPlans[instance]

	if v7 == nil or v7.CheckAt <= now then
		v7 = {
			Root = singleAssemblyRoot(instance),
			CheckAt = now + 0.5
		}
		pivotPlans[instance] = v7
	end

	local root = v7.Root

	if root == nil or root.Parent == nil or instance.PrimaryPart ~= root then
		instance:PivotTo(cframe2)
		return
	end

	local v8 = v5
	local v9 = v6
	local v10 = cframe2 * root.PivotOffset:Inverse()
	v8[1] = root
	v9[1] = v10
	workspace:BulkMoveTo(v5, v6, Enum.BulkMoveMode.FireCFrameChanged)
end

function Viewmodel.aim(data)
	data.Bobble:setIsAiming(true)

	if data.MuzzlePartWeld then
		local cframe2 = CurrentCamera.CFrame
		local worldPivot = data.Model.WorldPivot
		local cframe3 = data.MuzzlePartWeld.Part0.CFrame

		if data.Mirror then
			worldPivot = data.Mirror:ToNormalPose(data.Model:GetPivot())
			cframe3 = data.Mirror:ToNormalPose(cframe3)
		end

		local v7 = cframe2 + cframe2.UpVector * -0.5 + worldPivot.LookVector * 1 + worldPivot.RightVector * 0.1
		data.MuzzlePartWeld.C0 = cframe3:Inverse() * v7
	end
end

function Viewmodel:unaim()
	self.Bobble:setIsAiming(false)

	if self.OriginalC0 and self.MuzzlePartWeld then
		self.MuzzlePartWeld.C0 = self.OriginalC0
	end
end

function Viewmodel:unhide()
	if self.Hidden then
		updateTransparency(self.Model, false)
		self.Hidden = false
	end
end

function Viewmodel:hide()
	if not self.Hidden then
		updateTransparency(self.Model, true)
		self.Hidden = true
	end
end

function Viewmodel:equip(flag: boolean)
	self.IsEquipped = true

	if not self.Model then
		return
	end

	if self.Mirror then
		self.Mirror:PrepareEquip()
	end

	self.Model.Parent = CurrentCamera

	if self.LargeWeaponModel then
		self.LargeWeaponModel.Parent = CurrentCamera
	end

	self.Animation:stopAnimations()
	self.Animation:play("Idle")
	self:unhide()

	if not flag then
		self.Animation:play(self.Animation:pickVariant("Equip"))
	end
end

function Viewmodel:unequip()
	self.IsEquipped = false
	self.Animation:stopAnimations()
	self.LastViewmodelPosition = nil
	local model = self.Model

	if model and model:IsDescendantOf(workspace) then
		model.Parent = getViewmodelStash() -- inferred equivalent call
		pivotModel(self.PivotPlans, model, cframe)
	end

	if self.LargeWeaponModel then
		self.LargeWeaponModel.Parent = nil
	end
end

function Viewmodel:applyCharmImpulse(vector: Vector3)
	if self.LargeCharmModel and self.LargeCharmModel.PrimaryPart then
		local charmMassCache = self.CharmMassCache

		if self.CharmMassCacheModel ~= self.LargeCharmModel or typeof(charmMassCache) ~= "number" then
			charmMassCache = 0

			for _, part in ipairs(self.LargeCharmModel:GetDescendants()) do
				if part:IsA("BasePart") then
					charmMassCache += part:GetMass()
				end
			end

			self.CharmMassCache = charmMassCache
			self.CharmMassCacheModel = self.LargeCharmModel
		end

		self.LargeCharmModel.PrimaryPart:ApplyImpulse(vector * 10 * charmMassCache)
	end
end

function Viewmodel:render(p: number)
	local stats = self.Model and self.Model:FindFirstChild("Stats")

	if not stats then
		return
	end

	debug.profilebegin("Viewmodel.render.UpdateChargeFrame")
	updateChargeFrame(self, p)
	debug.profileend()
	debug.profilebegin("Viewmodel.render.GetViewmodelSettings")
	local v7 = DataController.Get(self.Player, "Settings.Game.Viewmodel") or frozen
	debug.profileend()

	if self.Bobble or self.Inspecting then
		debug.profilebegin("Viewmodel.render.BobbleNextCFrame")
		local nextCFrame, v8, v9 = self.Bobble:getNextCFrame(p)
		debug.profileend()
		local value = stats.Rotation.Value
		local v10 = CurrentCamera.CFrame * nextCFrame * CFrame.Angles(value.X, value.Y, value.Z) * CFrame.new(stats.Default.Value) * CFrame.new(
			(v7["X Offset"] or 0) / 100,
			(v7["Y Offset"] or 0) / 100,
			(v7["Z Offset"] or 0) / 100
		)
		debug.profilebegin("Viewmodel.render.PivotModel")
		local pivotPlans = self.PivotPlans
		local mirror = self.Mirror

		if mirror then
			mirror:SetLeftHanded(not self.WeaponComponent.Character and ViewmodelHand.IsPlayerLeftHanded(self.Player))
			pivotModel(pivotPlans, self.Model, mirror:GetDisplayPose(CurrentCamera.CFrame, v10))
			mirror:UpdateSurfaces()
		else
			pivotModel(pivotPlans, self.Model, v10)
		end

		debug.profileend()

		if self.LargeWeaponModel and self.SmallWeaponModel then
			local pivot = self.SmallWeaponModel:GetPivot()

			if mirror then
				pivot = mirror:ToNormalPose(pivot)
			end

			debug.profilebegin("Viewmodel.render.PivotLargeWeaponModel")
			pivotModel(pivotPlans, self.LargeWeaponModel, pivot)
			debug.profileend()
			local position = v10.Position

			if self.LastViewmodelPosition then
				self:applyCharmImpulse(-(position - self.LastViewmodelPosition) * 0.2)
			end

			self.LastViewmodelPosition = position
		end

		if self.Bobble.Scope and self.Bobble.IsAiming then
			debug.profilebegin("Viewmodel.render.Scope")
			local cframe2 = CurrentCamera.CFrame
			local v11 = v9.X * -cframe2.LookVector + v9.Y * -cframe2.UpVector
			self.Bobble.Scope:PivotTo(cframe2 + cframe2.LookVector * 0.15 + v8 + v11)

			if self.Bobble.ScopeReticlePart then
				self.Bobble.ScopeReticlePart.CFrame = cframe2 * CFrame.Angles(
					1.5707963267948966,
					1.5707963267948966,
					-1.5707963267948966
				) + cframe2.LookVector * 0.15
			end

			debug.profileend()
		end
	end
end

function Viewmodel:attachSleeves(childName: string)
	local child = ReplicatedStorage.Assets.Sleeves:FindFirstChild(childName)

	if not child then
		return
	end

	for _, child2 in ipairs(child:GetChildren()) do
		local child3 = self.Model:FindFirstChild(child2.Name)

		if not child3 then
			continue
		end

		local clone = child2:Clone()
		clone.CastShadow = false
		clone.CanCollide = false
		clone.CanTouch = false
		clone.Anchored = false
		clone.CanQuery = false
		clone.Name = "Sleeve"
		clone.Size = Vector3.new(child3.Size.X * 1.3, child3.Size.Y * 1.4, child3.Size.Z * 0.79)
		local v7 = child3.Size.Z / 2 - clone.Size.Z / 2
		clone.Parent = child3
		local motor6D = Instance.new("Motor6D", clone)
		motor6D.Part0 = child3
		motor6D.Part1 = clone
		motor6D.C1 = CFrame.new(0, -0.02, -v7)
	end
end

local function resolveInventoryGlove(p, p2: string)
	local v7 = Router.broadcastRouter("GetInventoryItemFromIdentifier", p, p2)

	if v7 then
		return v7.Name, v7.Skin, v7.Float
	end

	return nil, nil, nil
end

function Viewmodel:addAttachments(value)
	debug.profilebegin("Viewmodel.addAttachments")
	local name = nil
	local skin = nil
	local float = nil

	if type(value) == "string" then
		local player = self.Player
		local v7 = Router.broadcastRouter("GetInventoryItemFromIdentifier", player, value)

		if v7 then
			name = v7.Name
			skin = v7.Skin
			float = v7.Float
		end
	elseif type(value) == "table" then
		local skinIdentifier = value.SkinIdentifier

		if type(skinIdentifier) == "string" and skinIdentifier ~= "" then
			local player = self.Player
			local v7 = Router.broadcastRouter("GetInventoryItemFromIdentifier", player, skinIdentifier)

			if v7 then
				name = v7.Name
				skin = v7.Skin
				float = v7.Float
			end
		end

		if not name and type(value.Name) == "string" and type(value.Skin) == "string" then
			name = value.Name
			skin = value.Skin

			if typeof(value.Float) == "number" then
				float = value.Float
			else
				float = nil
			end
		end
	end

	if name and skin then
		debug.profilebegin("Viewmodel.addAttachments.GetGloves")
		local formatted = `{name}|{skin}|{float or ""}`
		local v7 = v2[formatted]

		if not v7 then
			local gloves = Skins.GetGloves(name, skin, float)
			v7 = v2[formatted]

			if v7 then
				if gloves then
					gloves:Destroy()
				end
			elseif gloves then
				if count >= 8 then
					v7 = gloves

					for _, v8 in v2 do
						v8:Destroy()
					end

					table.clear(v2)
					count = 0
				else
					v7 = gloves
				end

				v2[formatted] = v7
				count += 1
			else
				v7 = gloves
			end
		end

		debug.profileend()

		if v7 then
			debug.profilebegin("Viewmodel.addAttachments.AttachGloves")
			AttachGlovesToViewmodel(v7:GetChildren(), self.Model)
			debug.profileend()
		end
	end

	debug.profileend()
end

function Viewmodel:construct(character, player)
	debug.profilebegin("Viewmodel.construct")

	if self.ModelJanitor then
		debug.profilebegin("Viewmodel.construct.DestroyModelJanitor")
		self.ModelJanitor:Destroy()
		debug.profileend()
	end

	self.ModelJanitor = Janitor.new()
	self.Mirror = nil
	self.CharmModel = nil
	self.LargeWeaponModel = nil
	self.SmallWeaponModel = nil
	self.LargeCharmModel = nil
	self.LastViewmodelPosition = nil
	self.ChargeFillFrame = nil
	self.ChargeTextLabel = nil
	self.ChargeFillBaseSize = nil
	self.DisplayedChargeAlpha = nil

	if self.Animation then
		debug.profilebegin("Viewmodel.construct.StopAnimations")
		self.Animation:stopAnimations()
		debug.profileend()
	end

	if self.Model then
		debug.profilebegin("Viewmodel.construct.DestroyPreviousModel")
		self.Model:Destroy()
		debug.profileend()
		self.Model = nil
	end

	local cameraModelWeapon = self.CameraModelWeapon or self.Weapon
	local team = self.Team

	if cameraModelWeapon ~= "Smoke Grenade" or team ~= "Counter-Terrorists" and team ~= "Terrorists" then
		team = nil
	end

	debug.profilebegin("Viewmodel.construct.GetCameraModel")
	self.Model = Skins.GetCameraModel(
		cameraModelWeapon,
		self.Skin,
		self.Float,
		self.StatTrack,
		self.NameTag,
		self.Charm,
		self.Stickers,
		team
	)
	debug.profileend()

	if not self.Model and self.HideWeaponGeometry then
		debug.profilebegin("Viewmodel.construct.GetBaseWeaponModel")
		self.Model = Skins.GetBaseWeaponModel(cameraModelWeapon, "Camera")
		debug.profileend()
	end

	if not self.Model then
		debug.profileend()
		error(`Viewmodel.construct: Failed to get camera model for weapon "{cameraModelWeapon}" with skin "{self.Skin}"`)
	end

	self.Model.Name = cameraModelWeapon

	if self.HideWeaponGeometry then
		debug.profilebegin("Viewmodel.construct.StripWeaponGeometry")
		stripWeaponGeometry(self.Model)
		debug.profileend()
	end

	self.CharacterKey = getCharacterKey(character)
	self.Team = character:GetAttribute("Team") or self.Team
	local characterName = character:GetAttribute("CharacterName")

	if type(characterName) ~= "string" or characterName == "" then
		characterName = workspace:GetAttribute(self.Team == "Counter-Terrorists" and "CTCharacter" or "TCharacter")
	end

	if type(characterName) == "string" and characterName ~= "" then
		self:attachSleeves(characterName)
	end

	local equippedGloves = character:GetAttribute("EquippedGloves")

	if type(equippedGloves) == "string" and equippedGloves ~= "" then
		debug.profilebegin("Viewmodel.construct.DecodeEquippedGloves")
		local success, result = pcall(HttpService.JSONDecode, HttpService, equippedGloves)
		debug.profileend()

		if success and result then
			self:addAttachments(result)
		else
			self:addAttachments(equippedGloves)
		end
	end

	debug.profilebegin("Viewmodel.construct.SetupDescendants")

	for _, part in ipairs(self.Model:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = "Viewmodel"
		part.CanCollide = false
		part.CastShadow = false
		part.CanQuery = true
		part.CanTouch = false

		if part.Name == "HumanoidRootPart" or part.Name == "ViewmodelLight" then
			part.Transparency = 1
		end
	end

	debug.profileend()
	debug.profilebegin("Viewmodel.construct.SetupArmColors")
	local bodyColors = character:FindFirstChild("Body Colors")
	local torsoColor3 = nil

	if bodyColors then
		torsoColor3 = bodyColors.TorsoColor3
	else
		local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")

		if torso and torso:IsA("BasePart") then
			torsoColor3 = torso.Color
		end
	end

	if torsoColor3 then
		for _, childName in ipairs({ "Right Arm", "Left Arm" }) do
			local part = self.Model:FindFirstChild(childName)

			if part and part:IsA("BasePart") then
				part.Color = torsoColor3
			end
		end
	end

	debug.profileend()
	debug.profilebegin("Viewmodel.construct.CacheMuzzleParts")
	local interactables = self.Model:FindFirstChild("Interactables")
	local muzzlePart = interactables
		and (interactables:FindFirstChild("MuzzlePart", true) or interactables:FindFirstChild("MuzzlePartL", true) or interactables:FindFirstChild("MuzzlePartR", true))
	self.MuzzlePart = muzzlePart

	if interactables then
		self.MuzzlePartL = interactables:FindFirstChild("MuzzlePartL", true)
		self.MuzzlePartR = interactables:FindFirstChild("MuzzlePartR", true)

		if self.MuzzlePartL and self.MuzzlePartL:IsA("BasePart") then
			self.MuzzlePartL.Transparency = 1
		end

		if self.MuzzlePartR and self.MuzzlePartR:IsA("BasePart") then
			self.MuzzlePartR.Transparency = 1
		end
	end

	if self.MuzzlePart and self.MuzzlePart:IsA("BasePart") then
		self.MuzzlePart.Transparency = 1
	end

	debug.profileend()
	debug.profilebegin("Viewmodel.construct.ScaleTo")
	self.Model:ScaleTo(0.1)
	debug.profileend()
	debug.profilebegin("Viewmodel.construct.CacheMuzzleWeld")

	if self.MuzzlePart and not self.MuzzlePart:FindFirstChild("WeldConstraint", true) then
		for _, weld in ipairs(self.Model:GetDescendants()) do
			if not (weld:IsA("Weld") and (weld.Part1 == muzzlePart or weld.Part0 == muzzlePart)) then
				continue
			end

			self.MuzzlePartWeld = weld
			self.OriginalC0 = weld.C0
			break
		end
	end

	debug.profileend()
	local properties = player.Properties

	if properties then
		if properties.ShootingOptions == "Dual" then
			setupMuzzleFlashPart(self.MuzzlePartL, properties) -- inferred equivalent call
			setupMuzzleFlashPart(self.MuzzlePartR, properties) -- inferred equivalent call
		else
			setupMuzzleFlashPart(self.MuzzlePart, properties) -- inferred equivalent call
		end
	end

	debug.profilebegin("Viewmodel.construct.FindCharmModel")
	local charmBase = self.Model:FindFirstChild("CharmBase", true)

	if charmBase and charmBase:IsA("Model") then
		local model = charmBase:FindFirstChildOfClass("Model")

		if model and model.PrimaryPart then
			self.CharmModel = model
		end
	end

	debug.profileend()

	if self.CharmModel then
		debug.profilebegin("Viewmodel.construct.SetupCharmPhysics")
		self:setupCharmPhysics()
		debug.profileend()
	end

	debug.profilebegin("Viewmodel.construct.SetModelReferences")

	if self.Animation then
		self.Animation:setModel(self.Model)
	end

	if self.Bobble then
		local bobble = self.Bobble
		bobble.Character = character
		bobble:setModel(self.Model)
	end

	debug.profileend()
	weldLooseParts(self.Model)
	local viewmodelMirrors = ReplicatedStorage:FindFirstChild("ViewmodelMirrors")
	local v7 = self.Player == Players.LocalPlayer and not (player.Character or self.Inspecting)
	local mirror = viewmodelMirrors and BakedViewmodelMirror.new(self.Model, viewmodelMirrors, v7)

	if mirror and self.ModelJanitor then
		self.Mirror = mirror
		self.ModelJanitor:Add(mirror, "Destroy")
	end

	debug.profilebegin("Viewmodel.construct.FinalEquipState")

	if self.IsEquipped then
		self:equip(false)
	else
		self:unequip()
	end

	debug.profileend()
	debug.profileend()
end

function Viewmodel:setupCharmPhysics()
	debug.profilebegin("Viewmodel.setupCharmPhysics")
	local parent = self.CharmModel.Parent

	if not (parent and parent.PrimaryPart) then
		debug.profileend()
		return
	end

	self.CharmModel:PivotTo(parent.PrimaryPart.CFrame * CFrame.new(0, 0, -1))
	local charmModel = self.CharmModel
	local weaponRoot = findWeaponRoot(self.Model) -- inferred equivalent call

	if not weaponRoot then
		debug.profileend()
		return
	end

	debug.profilebegin("Viewmodel.setupCharmPhysics.CloneLargeProxy")
	local model = Instance.new("Model")
	model.Name = self.Model.Name
	local v7 = {}

	for _, childName in ipairs(v) do
		local folder = self.Model:FindFirstChild(childName)

		if not folder then
			continue
		end

		local clone = folder:Clone()
		v7[folder] = clone
		local descendants = clone:GetDescendants()

		for i, descendant in folder:GetDescendants() do
			v7[descendant] = descendants[i]
		end

		clone.Parent = model
	end

	model.WorldPivot = self.Model:GetPivot()
	debug.profileend()
	local weaponRoot2 = findWeaponRoot(model) -- inferred equivalent call

	if weaponRoot2 then
		debug.profilebegin("Viewmodel.setupCharmPhysics.TrimLargeProxy")

		local function relink(descendant, p: string) -- 4 equivalent calls inferred from this helper
			local v8 = descendant[p]

			if v8 == nil or v8:IsDescendantOf(model) then
				return true
			end

			local v9 = v7[v8]

			if not v9 then
				return false
			end

			descendant[p] = v9
			return true
		end

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant.Name == "ViewmodelLight" then
				descendant:Destroy()
			elseif
				descendant:IsA("JointInstance")
				or descendant:IsA("WeldConstraint")
				or descendant:IsA("NoCollisionConstraint")
			then
				if relink(descendant, "Part0") and relink(descendant, "Part1") then -- inferred equivalent call
					continue
				end

				descendant:Destroy()
			elseif descendant:IsA("Constraint") then
				if relink(descendant, "Attachment0") and relink(descendant, "Attachment1") then -- inferred equivalent call
					continue
				end

				descendant:Destroy()
			end
		end

		debug.profileend()
		debug.profilebegin("Viewmodel.setupCharmPhysics.ScaleAndPivotProxy")
		model:ScaleTo(1 / self.Model:GetScale())
		model:PivotTo(weaponRoot.Parent:GetPivot())

		if weaponRoot2.PrimaryPart then
			weaponRoot2.PrimaryPart.Anchored = true
		end

		local boundingBox = model:GetBoundingBox()

		if model.PrimaryPart then
			model.PrimaryPart.PivotOffset = model.PrimaryPart.CFrame:ToObjectSpace(boundingBox)
		else
			model.WorldPivot = boundingBox
		end

		model.PrimaryPart = weaponRoot2.PrimaryPart
		debug.profileend()
		debug.profilebegin("Viewmodel.setupCharmPhysics.ConfigureProxyDescendants")

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 1
				descendant.CanCollide = true
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") or descendant:IsA("Beam") then
				descendant.Transparency = 1
			elseif descendant:IsA("SurfaceGui") or descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end

		debug.profileend()
		debug.profilebegin("Viewmodel.setupCharmPhysics.FindLargeCharm")
		local charmBase = model:FindFirstChild("CharmBase", true)
		local model2

		if charmBase and charmBase:IsA("Model") then
			model2 = charmBase:FindFirstChildOfClass("Model")

			if model2 then
				for _, part in ipairs(model2:GetDescendants()) do
					if not part:IsA("BasePart") then
						continue
					end

					part.CanCollide = true
					part.CollisionGroup = "Charm"
				end
			end
		end

		debug.profileend()
		self.LargeWeaponModel = weaponRoot2.Parent
		self.SmallWeaponModel = weaponRoot
		self.LargeCharmModel = model2

		if model2 and self.ModelJanitor then
			local bindingName = RunServiceController.CreateBindingName("Classes.Viewmodel.CharmSync")
			self.ModelJanitor:Add(RunServiceController.BindToPostSimulation(bindingName, function()
				local largeCharmModel = self.LargeCharmModel

				if not (self.IsEquipped and largeCharmModel and largeCharmModel.PrimaryPart and charmModel.PrimaryPart) then
					return
				end

				local cframe2 = weaponRoot2:GetPivot():ToObjectSpace(largeCharmModel:GetPivot())
				local v8 = CFrame.new(cframe2.Position / 10) * CFrame.fromOrientation(cframe2:ToOrientation())
				charmModel:PivotTo(weaponRoot:GetPivot() * v8)
			end))
		end

		if self.CharmModel.PrimaryPart then
			self.CharmModel.PrimaryPart.Anchored = true
		end

		if not self.ModelJanitor then
			debug.profileend()
			return
		end

		self.ModelJanitor:Add(function()
			model:Destroy()
			self.LargeWeaponModel = nil
			self.SmallWeaponModel = nil
			self.LargeCharmModel = nil
		end)
		debug.profileend()
	else
		model:Destroy()
		debug.profileend()
	end
end

function Viewmodel.new(weaponComponent, weapon: string, skin: string, inspecting: boolean?)
	debug.profilebegin("Viewmodel.new")
	local object = setmetatable({}, Viewmodel)
	object.Janitor = Janitor.new()
	object.ModelJanitor = Janitor.new()
	object.IsDestroyed = false
	object.Inspecting = inspecting
	object.Player = weaponComponent.Player
	object.Team = (weaponComponent.Character or object.Player):GetAttribute("Team")
	object.WeaponComponent = weaponComponent
	object.Weapon = weapon
	object.CameraModelWeapon = weaponComponent.ViewmodelCameraWeapon or weapon
	object.HideWeaponGeometry = weaponComponent.ViewmodelHideWeaponGeometry == true
	object.Skin = skin
	object.StatTrack = weaponComponent.StatTrack
	object.Stickers = weaponComponent.Stickers
	object.NameTag = weaponComponent.NameTag
	object.Float = weaponComponent.Float
	object.Charm = weaponComponent.Charm
	object.Hidden = false
	object.IsEquipped = false
	object.PivotPlans = setmetatable({}, { __mode = "k" })
	local carryOverKey

	if not inspecting then
		carryOverKey = getCarryOverKey(weaponComponent, weapon, skin)
	end

	object.CarryOverKey = carryOverKey
	debug.profilebegin("Viewmodel.new.Sound")
	object.Sound = Sound.new(object.CameraModelWeapon)
	debug.profileend()
	debug.profilebegin("Viewmodel.new.Animation")
	object.Animation = Animation.new(object.Player, object.Sound)
	debug.profileend()
	debug.profilebegin("Viewmodel.new.Bobble")
	object.Bobble = Bobble.new(weaponComponent)
	debug.profileend()
	local character = weaponComponent.Character or object.Player.Character

	if character then
		debug.profilebegin("Viewmodel.new.InitialConstruct")
		local success, result = pcall(object.construct, object, character, weaponComponent)
		debug.profileend()

		if not success then
			debug.profileend()
			error(result, 2)
		end
	end

	if not weaponComponent.Character then
		local v7 = character
		object.Janitor:Add(CharacterResolver.observeCharacter(object.Player, function(p)
			if p and p ~= v7 then
				object:adoptCharacter(p)
			end

			v7 = nil
			return function() end
		end))
	end

	object.Janitor:Add(function()
		if object.ModelJanitor then
			object.ModelJanitor:Destroy()
			object.ModelJanitor = nil
		end
	end)
	debug.profileend()
	return object
end

function Viewmodel:adoptCharacter(character)
	if self.Model and self.CharacterKey == getCharacterKey(character) then
		self.Bobble.Character = character
	elseif self.WeaponComponent then
		self:construct(character, self.WeaponComponent)
	end
end

function Viewmodel:release()
	local carryOverKey = self.CarryOverKey

	if self.IsDestroyed or not (self.Model and carryOverKey) then
		self:destroy()
		return
	end

	if self.Bobble.IsAiming then
		self:unaim()
	end

	self:unequip()
	self.WeaponComponent = nil
	table.insert(v4, {
		Viewmodel = self,
		Key = carryOverKey,
		ExpiresAt = os.clock() + 5
	})
	task.delay(5.1, flushCarryOver)
end

function Viewmodel.claim(weaponComponent, p: string, p2: string)
	local carryOverKey = getCarryOverKey(weaponComponent, p, p2)

	if not carryOverKey then
		return nil
	end

	for k, v7 in v4 do
		local viewmodel = v7.Viewmodel

		if v7.Key ~= carryOverKey or viewmodel.IsDestroyed then
			continue
		end

		table.remove(v4, k)
		viewmodel.WeaponComponent = weaponComponent
		viewmodel.StatTrack = weaponComponent.StatTrack
		local character = viewmodel.Player.Character

		if character and not pcall(viewmodel.adoptCharacter, viewmodel, character) then
			viewmodel:destroy()
			return nil
		else
			return viewmodel
		end
	end

	return nil
end

function Viewmodel:destroy()
	if not self.IsDestroyed then
		debug.profilebegin("Viewmodel.destroy")
		self.IsDestroyed = true

		if self.Animation then
			self.Animation:stopAnimations()
			self.Animation:destroy()
			self.Animation = nil
		end

		if self.Bobble then
			self.Bobble:destroy()
			self.Bobble = nil
		end

		if self.Sound then
			self.Sound:destroy()
			self.Sound = nil
		end

		if self.Model then
			self.Model.Parent = nil
			self.Model:Destroy()
			self.Model = nil
		end

		self.Janitor:Destroy()
		self.Janitor = nil
		self.StatTrack = nil
		self.Stickers = nil
		self.NameTag = nil
		self.Player = nil
		self.Weapon = nil
		self.Float = nil
		self.Charm = nil
		self.Skin = nil
		self.Team = nil
		self.MuzzlePartWeld = nil
		self.MuzzlePartL = nil
		self.MuzzlePartR = nil
		self.MuzzlePart = nil
		self.OriginalC0 = nil
		self.CharmModel = nil
		self.LargeCharmModel = nil
		self.LargeWeaponModel = nil
		debug.profileend()
	end
end

return Viewmodel