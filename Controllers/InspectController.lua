local InspectController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SceneLighting = require(ReplicatedStorage.Components.Common.SceneLighting)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
require(ReplicatedStorage.Database.Custom.Types)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Viewmodel = require(ReplicatedStorage.Classes.WeaponComponent.Classes.Viewmodel)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Collections = require(ReplicatedStorage.Database.Components.Libraries.Collections)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local ApplyMobileButtonLayout = require(ReplicatedStorage.Components.Common.ApplyMobileButtonLayout)
local Mobile = require(ReplicatedStorage.Database.Custom.GameStats.UI.Mobile)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local userPlatform = GetUserPlatform()
local v = table.find(userPlatform, "Mobile") and #userPlatform <= 1
local CurrentCamera = workspace.CurrentCamera
local inspectScenes = nil
local Lighting = ReplicatedStorage.Assets.Lighting
local PreviewTemplate = ReplicatedStorage.Assets.UI.Inspect:WaitForChild("PreviewTemplate")
local v2 = nil
local v3 = nil
local v4 = nil
local inspectPivot = nil
local v5 = nil
local v6 = nil
local v7 = nil
local v8 = nil
local v9 = false
local v10 = nil
local name = nil
local parent = nil
local models = {}
local maid = Janitor.new()
local v11 = "Weapon"
local flag = false
local v12 = nil
local flag2 = false
local DEFAULT_CAMERA_FOV = Constants.DEFAULT_CAMERA_FOV
local cframe = CFrame.Angles(0, -1.5707963267948966, 0)
local v13 = { "FAMAS", "AK-47", "M4A1-S", "Glock-18", "USP-S" }
local v14 = { Weapon = true, Melee = true, Glove = true }
local v15 = { "HiddenTransparency", "_CaseScenePrevTransparency", "_InspectPrevTransparency" }
local v16 = false
local zero = Vector2.zero
local v17 = 40
local v18 = 40
local v19 = 0
local v20 = 0
local v21 = 0
local v22 = 0
local udim = UDim2.fromScale(0.5, 0.075)
local udim2 = UDim2.fromScale(0.317, 0.054)
local udim3 = UDim2.fromScale(0.243, 0.054)
local udim4 = UDim2.fromScale(0.5, 0.143)
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local v23 = {
	{
		Wear = "Factory New",
		Display = "Mint Condition",
		Min = 0,
		Max = 0.07,
		Color = Color3.fromRGB(0, 255, 127)
	},
	{
		Wear = "Minimal Wear",
		Display = "Near-Mint",
		Min = 0.07,
		Max = 0.15,
		Color = Color3.fromRGB(0, 170, 255)
	},
	{
		Wear = "Field-Tested",
		Display = "Standard-Grade",
		Min = 0.15,
		Max = 0.38,
		Color = Color3.fromRGB(255, 255, 0)
	},
	{
		Wear = "Well-Worn",
		Display = "Combat-Worn",
		Min = 0.38,
		Max = 0.45,
		Color = Color3.fromRGB(255, 85, 0)
	},
	{
		Wear = "Battle-Scarred",
		Display = "War-Torn",
		Min = 0.45,
		Max = 1,
		Color = Color3.fromRGB(255, 0, 0)
	}
}
local v24 = {}
local v25 = nil
local v26 = nil
local v27 = 1
local visible2 = false

local function commaNumber(serial: number) -- 1 equivalent call inferred from this helper
	return tostring(serial):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function applyMapLighting() -- 2 equivalent calls inferred from this helper
	v7 = SceneLighting.RestoreMap(nil, v7)
end

local function applySceneLighting(name2: string) -- 1 equivalent call inferred from this helper
	local v28 = Lighting:FindFirstChild(name2) or Lighting:FindFirstChild("Menu")

	if not v28 then
		return
	end

	v7 = SceneLighting.ApplyScene(name2, v28)
end

local function getInspectScenesFolder() -- 1 equivalent call inferred from this helper
	if inspectScenes then
		return inspectScenes
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")

	if assets then
		inspectScenes = assets:WaitForChild("InspectScenes", 10)
	end

	return inspectScenes
end

local function getRandomInspectScene()
	local inspectScenesFolder = getInspectScenesFolder() -- inferred equivalent call

	if not inspectScenesFolder then
		return nil
	end

	local models2 = {}

	for _, model in ipairs(inspectScenesFolder:GetChildren()) do
		if model:IsA("Model") then
			table.insert(models2, model)
		end
	end

	if #models2 > 0 then
		return models2[math.random(1, #models2)]
	end

	return nil
end

local function activateInspectSceneFlags(folder)
	for _, model in ipairs(folder:GetDescendants()) do
		local csFlag = model:IsA("Model") and model:FindFirstChild("csFlag")

		if not csFlag or not csFlag:IsA("Model") or model:HasTag("Flag") then
			continue
		end

		model:AddTag("Flag")
	end
end

local function pivotInspectWeapon(instance, weaponPart, cframe2: CFrame) -- 4 equivalent calls inferred from this helper
	local v28 = weaponPart.CFrame * cframe2 * cframe

	if inspectPivot then
		v28 *= instance:GetPivot():ToObjectSpace(inspectPivot.WorldCFrame):Inverse()
	end

	instance:PivotTo(v28)
end

local function updateWeaponTransform()
	if not (v10 and parent) then
		return
	end

	local weaponPart = parent:FindFirstChild("WeaponPart")

	if weaponPart then
		local cframe2 = CFrame.Angles(0, math.rad(v20), (math.rad(v19)))
		pivotInspectWeapon(v10, weaponPart, cframe2) -- inferred equivalent call
	end
end

local function isPointerOverButton(position: Vector3)
	for _, button in PlayerGui:GetGuiObjectsAtPosition(position.X, position.Y) do
		if button:IsA("GuiButton") and button.Visible and button.Active then
			return true
		end
	end

	return false
end

local function handleDragInput(point: Vector2) -- 3 equivalent calls inferred from this helper
	v22 += point.X * 0.5
	v21 = math.clamp(v21 + point.Y * 0.5, -80, 80)
end

local function handleFOVInput(p: number) -- 2 equivalent calls inferred from this helper
	if v11 == "Viewmodel" then
		return
	end

	v18 = math.clamp(v18 - p * 2, 20, 70)
end

local function getTouchCount() -- 3 equivalent calls inferred from this helper
	local count = 0

	for _ in pairs(v24) do
		count += 1
	end

	return count
end

local function getPinchDistance()
	local v28 = {}

	for _, v29 in pairs(v24) do
		table.insert(v28, v29)
	end

	if #v28 >= 2 then
		return (v28[1] - v28[2]).Magnitude
	end

	return nil
end

local function getInspectFrame() -- 4 equivalent calls inferred from this helper
	local menuFrame = MenuState.GetMenuFrame()
	return menuFrame and (menuFrame:FindFirstChild("Inspect") or menuFrame:FindFirstChild("InspectFrame"))
end

local function setMenuBackdrop(menuFrame, flag3: boolean, visible: boolean) -- 4 equivalent calls inferred from this helper
	MenuState.SetBlurEnabled(flag3)
	menuFrame.BackgroundTransparency = flag3 and 0.15 or 1
	local pattern = menuFrame:FindFirstChild("Pattern")

	if pattern then
		pattern.Visible = visible
	end
end

local function hideOtherMenuScreens(menuFrame, p: string)
	for _, frame in ipairs(menuFrame:GetChildren()) do
		if not (frame:IsA("Frame") and frame.Name ~= "Top" and frame.Name ~= p and frame.Name ~= "Inspect") then
			continue
		end

		if frame.Name == "InspectFrame" then
			continue
		end

		frame.Visible = false
	end
end

local function hideMenuFrames()
	MenuState.EnterInspect()
	local menuFrame = MenuState.GetMenuFrame()

	if not menuFrame then
		return
	end

	v9 = MenuSceneController.IsActive()

	if v9 then
		MenuSceneController.HideMenuScene(true)
		MenuSceneController.SetMusicVolumeMultiplier(0.5, 0.5)
	end

	setMenuBackdrop(menuFrame, false, false) -- inferred equivalent call
	local top = menuFrame:FindFirstChild("Top")

	if top then
		top.Visible = false
	end

	for _, frame in ipairs(menuFrame:GetChildren()) do
		if frame:IsA("Frame") and frame.Name ~= "Top" then
			frame.Visible = frame.Name == "Inspect" or frame.Name == "InspectFrame"
		end
	end
end

local function getFloatPreviewClosedPosition(floatPreviews, toggleButton)
	local position = floatPreviews.Position
	local v28 = -(floatPreviews.Size.X.Scale * toggleButton.Position.X.Scale)
	local v29 = -(floatPreviews.Size.X.Offset + toggleButton.Position.X.Offset)
	return UDim2.new(v28, v29, position.Y.Scale, position.Y.Offset)
end

local function setFloatPreviewArrowDirection(toggleButton, flag3: boolean) -- 3 equivalent calls inferred from this helper
	local textLabel = toggleButton:FindFirstChild("TextLabel")

	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Rotation = flag3 and 0 or 180
	end
end

local function storeFloatPreviewOpenPosition(floatPreviews)
	local position = floatPreviews.Position
	floatPreviews:SetAttribute("OpenPositionXScale", position.X.Scale)
	floatPreviews:SetAttribute("OpenPositionXOffset", position.X.Offset)
	floatPreviews:SetAttribute("OpenPositionYScale", position.Y.Scale)
	floatPreviews:SetAttribute("OpenPositionYOffset", position.Y.Offset)
end

local function getStoredFloatPreviewOpenPosition(floatPreviews)
	return UDim2.new(
		floatPreviews:GetAttribute("OpenPositionXScale") or floatPreviews.Position.X.Scale,
		floatPreviews:GetAttribute("OpenPositionXOffset") or floatPreviews.Position.X.Offset,
		floatPreviews:GetAttribute("OpenPositionYScale") or floatPreviews.Position.Y.Scale,
		floatPreviews:GetAttribute("OpenPositionYOffset") or floatPreviews.Position.Y.Offset
	)
end

local function bindClickButton(charm, childName: string, onMouseButton1Click) -- 2 equivalent calls inferred from this helper
	local button = charm:FindFirstChild(childName)

	if button and button:IsA("GuiButton") then
		ActivateButton(button)
		button.MouseButton1Click:Connect(onMouseButton1Click)
	end
end

local function initializeInspectButtons()
	local inspectFrame = getInspectFrame() -- inferred equivalent call
	local bottom = inspectFrame and inspectFrame:FindFirstChild("Bottom")

	if not bottom then
		return
	end

	local close = bottom.Container.Buttons:FindFirstChild("Close")

	if close and close:IsA("GuiButton") then
		ActivateButton(close)
		CloseButtonRegistry.Add(inspectFrame, close, function()
			InspectController.HideInspect()
		end)
	end

	local middle = bottom:FindFirstChild("Middle")
	local buttons = middle and middle:FindFirstChild("Buttons")

	if buttons then
		for _, childName in ipairs({ "Viewmodel", "Weapon" }) do
			local button = buttons:FindFirstChild(childName)

			if button and button:IsA("GuiButton") then
				ActivateButton(button)
			end
		end
	end

	local floatPreviews = inspectFrame:FindFirstChild("FloatPreviews")

	if floatPreviews then
		floatPreviews.Visible = false
		local toggleButton = floatPreviews:FindFirstChild("ToggleButton")

		if toggleButton and toggleButton:IsA("GuiButton") then
			ActivateButton(toggleButton)
			storeFloatPreviewOpenPosition(floatPreviews)
			local position = floatPreviews.Position
			local floatPreviewClosedPosition = getFloatPreviewClosedPosition(floatPreviews, toggleButton)
			floatPreviews:SetAttribute("IsOpen", true)
			setFloatPreviewArrowDirection(toggleButton, true) -- inferred equivalent call
			local v28 = nil
			toggleButton.Activated:Connect(function()
				local v29 = floatPreviews:GetAttribute("IsOpen") == false
				floatPreviews:SetAttribute("IsOpen", v29)
				setFloatPreviewArrowDirection(toggleButton, v29) -- inferred equivalent call

				if v28 then
					v28:Cancel()
				end

				local position2

				if v29 then
					position2 = position
				else
					position2 = floatPreviewClosedPosition
				end

				local v30 = TweenService:Create(floatPreviews, tweenInfo, { Position = position2 })
				v28 = v30
				v30:Play()
			end)
		end
	end

	local mobileButtons = inspectFrame:FindFirstChild("MobileButtons")

	if mobileButtons then
		local inspect = mobileButtons:FindFirstChild("Inspect")

		if inspect and inspect:IsA("TextButton") then
			ActivateButton(inspect)
			inspect.MouseButton1Click:Connect(function()
				InspectController.PlayInspectAnimation()
			end)
			local mobileButtons2 = DataController.Get(LocalPlayer, "MobileButtons")
			local inspect2 = Mobile.SanitizeLayout(mobileButtons2).Inspect

			if inspect2 then
				ApplyMobileButtonLayout(inspect, inspect2)
			end
		end

		mobileButtons.Visible = false
	end

	local charm = bottom.Middle:FindFirstChild("Charm")

	if charm then
		local function fn()
			InspectController.CycleCharmPosition()
		end

		bindClickButton(charm, "Next", fn) -- inferred equivalent call

		local function fn2()
			Router.broadcastRouter("ConfirmCharmAttachment")
		end

		bindClickButton(charm, "Confirm", fn2) -- inferred equivalent call
	end
end

local function updateInspectMobileButtonsVisibility() -- 3 equivalent calls inferred from this helper
	local inspectFrame = getInspectFrame() -- inferred equivalent call
	local mobileButtons = inspectFrame and inspectFrame:FindFirstChild("MobileButtons")
	local inspect = mobileButtons and mobileButtons:FindFirstChild("Inspect")

	if not inspect then
		return
	end

	local visible = flag2

	if visible then
		if v11 == "Viewmodel" then
			visible = v
		else
			visible = false
		end
	end

	mobileButtons.Visible = visible
	inspect.Visible = visible
end

local function getItemClass(p) -- 3 equivalent calls inferred from this helper
	if p.Name then
		local success, result = pcall(GetWeaponProperties, p.Name)

		if success and result then
			return result.Class
		end
	end

	return nil
end

local function isGloveInventoryItem(p) -- 6 equivalent calls inferred from this helper
	if p == nil then
		return false
	elseif p.Type == "Glove" then
		return true
	else
		return getItemClass(p) == "Glove" -- inferred equivalent call
	end
end

local v28 = {
	{ Name = "Inspect", Action = "Inspect", Title = "Inspect" },
	{ Name = "Cancel", Action = "Reload", Title = "Cancel" }
}

local function refreshInspectTips()
	local inspectFrame = getInspectFrame() -- inferred equivalent call
	local tips = inspectFrame and inspectFrame:FindFirstChild("Tips")

	if not (tips and tips:IsA("GuiObject")) then
		return
	end

	local Tips = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Tips)

	if not tips:GetAttribute("Mirrored") then
		tips:SetAttribute("Mirrored", true)
		tips.AnchorPoint = Vector2.new(1, tips.AnchorPoint.Y)
		local uiListLayout = tips:FindFirstChildOfClass("UIListLayout")

		if uiListLayout then
			uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
		end

		for _, guiObject in tips:GetChildren() do
			if guiObject:IsA("GuiObject") then
				Tips.MirrorRow(guiObject)
			end
		end
	end

	local v29 = flag2

	if v29 then
		if v11 == "Viewmodel" then
			v29 = UserInputService.PreferredInput ~= Enum.PreferredInput.Touch
		else
			v29 = false
		end
	end

	local visible = false

	for _, v30 in v28 do
		local guiObject = tips:FindFirstChild(v30.Name)

		if not (guiObject and guiObject:IsA("GuiObject")) then
			continue
		end

		local title = guiObject:FindFirstChild("Title")

		if title and title:IsA("TextLabel") then
			title.Text = v30.Title
		end

		local keybind = guiObject:FindFirstChild("Keybind")

		if keybind and keybind:IsA("GuiObject") then
			keybind.Selectable = false
		end

		local v31

		if v30.Name == "Cancel" then
			local v32 = v5

			if v32 == nil then
				v31 = false
			elseif v32.Type == "Glove" then
				v31 = true
			else
				v31 = getItemClass(v32) == "Glove" -- inferred equivalent call
			end
		else
			v31 = false
		end

		local visible3 = not v31

		if v29 then
			if visible3 then
				if keybind == nil then
					visible3 = false
				else
					visible3 = keybind:IsA("GuiButton")
						and Tips.ApplyBindingToKeybind(keybind, Tips.ResolveActionBinding(v30.Action))
				end
			end
		else
			visible3 = v29
		end

		guiObject.Visible = visible3
		visible = visible or visible3
	end

	tips.Visible = visible
end

local function updateCharmFrameVisibility()
	local inspectFrame = getInspectFrame() -- inferred equivalent call
	local bottom = inspectFrame and inspectFrame:FindFirstChild("Bottom")

	if not bottom then
		return
	end

	local charm = bottom.Middle:FindFirstChild("Charm")
	local buttons = bottom.Middle:FindFirstChild("Buttons")

	if charm then
		charm.Visible = Router.broadcastRouter("HasPendingCharmAttachment") or false
		buttons.Visible = not charm.Visible
	end
end

local function supportsViewmodelInspect(p) -- 1 equivalent call inferred from this helper
	return v14[p.Type] == true or v14[getItemClass(p)] == true -- inferred equivalent call
end

local function cleanupGloveViewmodelInspectAnimation() -- 2 equivalent calls inferred from this helper
	if v2 then
		if v2.IsPlaying then
			v2:Stop(0)
		end

		v2:Destroy()
		v2 = nil
	end

	if v3 then
		v3:Destroy()
		v3 = nil
	end
end

local function playGloveViewmodelInspectAnimation()
	if not v2 or v2.IsPlaying then
		return
	end

	if v4 and v4.Animation then
		v4.Animation:stopAnimations()
	end

	v2.TimePosition = 0
	v2:Play(0, 1, 1)
end

local function setupGloveViewmodelInspectAnimation()
	cleanupGloveViewmodelInspectAnimation() -- inferred equivalent call

	if not (v4 and v4.Animation) then
		return
	end

	local animator = v4.Animation.Animator

	if not animator then
		return
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = "rbxassetid://135926544677482"
	local success, result = pcall(function()
		return animator:LoadAnimation(animation)
	end)

	if not (success and result) then
		animation:Destroy()
		return
	end

	v3 = animation
	v2 = result

	if v2 then
		if v2.IsPlaying then
			return
		end

		if v4 and v4.Animation then
			v4.Animation:stopAnimations()
		end

		v2.TimePosition = 0
		v2:Play(0, 1, 1)
	end
end

local function resolveInspectViewmodelSkin(name2: string, skin: string?)
	local v29 = (not skin or skin == "" or not skin) and "Vanilla" or skin

	for _, v30 in ipairs({ v29, "Vanilla", "Default" }) do
		if Skins.GetSkinInformation(name2, v30) then
			return v30
		end
	end

	local allSkinsForWeapon = Skins.GetAllSkinsForWeapon(name2)

	if allSkinsForWeapon and allSkinsForWeapon[1] and allSkinsForWeapon[1].skin then
		return allSkinsForWeapon[1].skin
	end

	return v29
end

local function resolveGloveProxyWeapon()
	for _, v29 in ipairs(v13) do
		local baseWeaponModel = Skins.GetBaseWeaponModel(v29, "Camera")

		if not baseWeaponModel then
			continue
		end

		baseWeaponModel:Destroy()
		return v29
	end

	return "FAMAS"
end

local function clearViewmodelHorizontalOffset(p) -- 1 equivalent call inferred from this helper
	local stats = p.Model:FindFirstChild("Stats")
	local default = stats and stats:FindFirstChild("Default")
	local value = default and default.Value

	if typeof(value) == "Vector3" then
		default.Value = Vector3.new(0.05, value.Y, value.Z)
	end
end

local function cleanupWeaponInspect() -- 4 equivalent calls inferred from this helper
	if v10 then
		v10:Destroy()
		v10 = nil
	end

	inspectPivot = nil
end

local function cleanupViewmodelInspect() -- 4 equivalent calls inferred from this helper
	cleanupGloveViewmodelInspectAnimation() -- inferred equivalent call

	if v4 then
		v4:destroy()
		v4 = nil
	end

	if v6 then
		v6:Destroy()
		v6 = nil
	end

	InputController.enableGroup("Gameplay")
end

local function cleanupInspectMode() -- 2 equivalent calls inferred from this helper
	if v11 == "Weapon" then
		cleanupWeaponInspect() -- inferred equivalent call
	elseif v11 == "Viewmodel" then
		cleanupViewmodelInspect() -- inferred equivalent call
	end
end

local function prepareInspectWeapon(folder, flag3: boolean)
	folder.Name = "InspectWeapon"
	v10 = folder
	inspectPivot = folder:FindFirstChild("InspectPivot", true)
	local charmBase = folder:FindFirstChild("CharmBase", true)

	for _, part in ipairs(folder:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CastShadow = false

		if flag3 then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Anchored = folder.PrimaryPart == part
		elseif charmBase and part:IsDescendantOf(charmBase) then
			part.Anchored = false
		else
			part.CanCollide = part:IsA("MeshPart")
			part.CanQuery = false
			part.CanTouch = false
			part.Anchored = true
		end
	end
end

local function setupWeaponInspect(data)
	if not parent then
		return
	end

	local weaponPart = parent:FindFirstChild("WeaponPart")

	if not weaponPart then
		warn("[InspectController]: Inspect scene missing WeaponPart")
		return
	end

	local v29 = data.Type == "Glove"
	local v30 = data.Type == "Charm"
	local parent2

	if v29 then
		local part = Skins.GetGloves(data.Name, data.Skin, data.Float)

		if part and part:IsA("BasePart") then
			parent2 = Instance.new("Model")
			parent2.Name = data.Name
			part.Parent = parent2
			parent2.PrimaryPart = part
		else
			parent2 = part
		end
	elseif v30 then
		parent2 = Skins.GetCharmModel(data.Skin, data.Pattern or 1)
	elseif data.Type == "Badge" then
		parent2 = Skins.GetBadgeModel(data.Skin)
	else
		parent2 = Skins.GetCharacterModel(
			data.Name,
			data.Skin,
			data.Float,
			data.StatTrack,
			data.NameTag,
			data.Charm,
			data.Stickers
		)
	end

	if not parent2 then
		warn(`[InspectController]: Failed to get model for "{data.Name}"`, data)
		return
	end

	prepareInspectWeapon(parent2, v30)

	if v29 and (data.Name == "T Glove" or data.Name == "CT Glove") then
		local parts = {}

		for _, part in ipairs(parent2:GetChildren()) do
			if part:IsA("BasePart") then
				table.insert(parts, part)
			end
		end

		if #parts >= 2 then
			local rightGlove = parent2:FindFirstChild("RightGlove") or parts[1]

			for _, v31 in ipairs(parts) do
				if v31 ~= rightGlove then
					v31:Destroy()
				end
			end
		end
	end

	parent2.Parent = parent
	pivotInspectWeapon(parent2, weaponPart, CFrame.identity) -- inferred equivalent call
end

local function setupViewmodelInspect(data)
	cleanupViewmodelInspect() -- inferred equivalent call
	local v29 = LocalPlayer:GetAttribute("Team") == "Counter-Terrorists" and "CT" or "T"
	local gloveInventoryItem = isGloveInventoryItem(data) -- inferred equivalent call
	local standaloneCharacter = MenuSceneController.CreateStandaloneCharacter(v29)

	if not standaloneCharacter then
		warn("[InspectController]: Failed to create standalone character for viewmodel")
		return
	end

	if gloveInventoryItem then
		local v30 = { Name = data.Name, Skin = data.Skin, Float = data.Float }

		if data._id and data._id ~= "" then
			v30.SkinIdentifier = data._id
		end

		standaloneCharacter:SetAttribute("EquippedGloves", HttpService:JSONEncode(v30))
	end

	v6 = standaloneCharacter
	local charm = data.Charm
	local charm2 = Router.broadcastRouter("HasPendingCharmAttachment")
		and type(charm) == "table"
		and { _id = charm._id, Position = tostring(v27) }
		or charm
	local v30 = {
		Player = LocalPlayer,
		Character = standaloneCharacter,
		StatTrack = data.StatTrack,
		Stickers = data.Stickers,
		NameTag = data.NameTag,
		Float = data.Float,
		Charm = charm2
	}
	local name2 = data.Name
	local v31

	if gloveInventoryItem then
		name2 = resolveGloveProxyWeapon()
		v31 = "Stock"
	else
		v31 = resolveInspectViewmodelSkin(name2, data.Skin)
	end

	v30.ViewmodelCameraWeapon = name2
	v30.ViewmodelHideWeaponGeometry = gloveInventoryItem
	local success, result = pcall(function()
		return Viewmodel.new(v30, data.Name, v31, true)
	end)

	if success and result then
		v4 = result
		v4:equip(gloveInventoryItem)

		if not v4.Model then
			return
		end

		if v4.Model.Parent ~= CurrentCamera then
			v4.Model.Parent = CurrentCamera
		end

		if v4.Hidden then
			v4:unhide()
		end

		if gloveInventoryItem then
			clearViewmodelHorizontalOffset(v4) -- inferred equivalent call
			setupGloveViewmodelInspectAnimation()
		end

		task.defer(function()
			if not (v4 and v4.Model) then
				return
			end

			for _, descendant in ipairs(v4.Model:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.CastShadow = false

					if
						descendant.Name ~= "HumanoidRootPart"
						and descendant.Name ~= "ViewmodelLight"
						and descendant.Name ~= "MuzzlePart"
						and descendant.Name ~= "MuzzlePartL"
						and descendant.Name ~= "MuzzlePartR"
					then
						local attribute = nil

						for _, attributeName in ipairs(v15) do
							attribute = descendant:GetAttribute(attributeName)

							if attribute == nil then
								continue
							end

							descendant:SetAttribute(attributeName, nil)
							break
						end

						if attribute == nil then
							if
								descendant.Transparency >= 1
								and (descendant.Name == "Right Arm" or descendant.Name == "Left Arm")
							then
								descendant.Transparency = 0
							end
						else
							descendant.Transparency = attribute
						end
					end
				elseif descendant:IsA("SurfaceGui") then
					if descendant:GetAttribute("_InspectPrevSurfaceGuiEnabled") then
						descendant:SetAttribute("_InspectPrevSurfaceGuiEnabled", nil)
					end

					if descendant:GetAttribute("_CaseScenePrevSurfaceGuiEnabled") then
						descendant:SetAttribute("_CaseScenePrevSurfaceGuiEnabled", nil)
					end

					descendant.Enabled = true
				end
			end
		end)
	else
		warn(`[InspectController]: Failed to create viewmodel ({name2} | {v31})`, result)
		cleanupViewmodelInspect() -- inferred equivalent call
	end
end

local function applyInspectMode(p: string)
	local v29 = v5

	if not v29 then
		return
	end

	cleanupInspectMode() -- inferred equivalent call
	v11 = p
	updateInspectMobileButtonsVisibility() -- inferred equivalent call
	refreshInspectTips()

	if p == "Weapon" then
		setupWeaponInspect(v29)
		v18 = 40
		InputController.enableGroup("Gameplay")
	elseif p == "Viewmodel" then
		InputController.disableGroup("Gameplay")
		setupViewmodelInspect(v29)
		v18 = DEFAULT_CAMERA_FOV
		InspectController.PlayInspectAnimation()
	end
end

local function setInspectMode(p: string)
	local v29 = v5

	if not v29 then
		return
	end

	local v30 = isGloveInventoryItem(v29) and p == "Weapon" and "Viewmodel" or p -- inferred equivalent call

	if v11 == v30 then
		return
	end

	if flag then
		v12 = v30
		return
	end

	flag = true

	while v30 do
		local success, result = pcall(applyInspectMode, v30)

		if not success then
			warn(`[InspectController]: Failed to apply inspect mode "{v30}"`, result)
		end

		v30 = v12
		v12 = nil

		if v30 == v11 or not flag2 then
			v30 = nil
		end
	end

	flag = false
end

local function tween(p, p2) -- 6 equivalent calls inferred from this helper
	if p then
		TweenService:Create(p, TweenInfo.new(0.2), p2):Play()
	end
end

local function updateButtonVisuals(p: string, instance, flag3: boolean)
	local hoverFrame = instance:FindFirstChild("HoverFrame")
	local selectFrame = instance:FindFirstChild("SelectFrame")
	local imageLabel = instance:FindFirstChild("ImageLabel")
	local v29

	if v11 == p then
		v29 = p ~= "Info"
	else
		v29 = false
	end

	if v29 then
		tween(hoverFrame, { BackgroundTransparency = 1 }) -- inferred equivalent call
		tween(selectFrame, { -- inferred equivalent call
			BackgroundTransparency = 0,
			BackgroundColor3 = Color3.fromRGB(95, 95, 95)
		})
		tween(imageLabel, { ImageColor3 = Color3.fromRGB(210, 210, 210) }) -- inferred equivalent call
	else
		tween(selectFrame, { BackgroundTransparency = 1 }) -- inferred equivalent call
		tween(imageLabel, { ImageColor3 = Color3.fromRGB(255, 255, 255) }) -- inferred equivalent call
		tween(hoverFrame, { -- inferred equivalent call
			BackgroundTransparency = flag3 and 0 or 1
		})
	end
end

local function refreshAllButtons(items, p: string)
	for k, button in pairs(items) do
		if button and button:IsA("GuiButton") then
			updateButtonVisuals(k, button, k == p)
		end
	end
end

local function formatInfoText(p: string, p2: string)
	return `<b><font color="rgb(175,175,175)">{p}</font></b>: <font color="rgb(255,255,255)">{p2}</font>`
end

local function scaleInfoFrameToFit(information, list)
	local textSize2 = math.clamp(math.floor(CurrentCamera.ViewportSize.Y * 0.025), 8, 32)
	local x = 0

	for _, label in ipairs(list) do
		if not (label and label:IsA("TextLabel") and label.Text ~= "") then
			continue
		end

		label.TextScaled = false
		local textSize = TextService:GetTextSize(
			label.Text:gsub("<[^>]*>", ""),
			textSize2,
			Enum.Font.Gotham,
			Vector2.new(1e999, 1e999)
		)

		if x < textSize.X then
			x = textSize.X
		end

		label.TextSize = textSize2
		label.TextWrapped = false
	end

	if x > 0 then
		information.Size = UDim2.new(0.05, x, information.Size.Y.Scale, information.Size.Y.Offset)
	end
end

local function showInfoFrame(instance, data, p)
	local information = instance:FindFirstChild("Information")

	if not information then
		return
	end

	if p then
		local x = information.Parent.AbsolutePosition.X
		local v29 = p.AbsolutePosition.X + p.AbsoluteSize.X / 2 - x
		information.Position = UDim2.new(
			0,
			v29 + information.AbsoluteSize.X / 2,
			information.Position.Y.Scale,
			information.Position.Y.Offset
		)
	end

	information.Visible = true
	local skinInformation = Skins.GetSkinInformation(data.Name, data.Skin)
	local v29

	if skinInformation then
		local _, v30 = Skins.GetWearNameForFloat(skinInformation, data.Float or 0)
		v29 = v30 or "Mint Condition"
	else
		v29 = "Mint Condition"
	end

	local v30 = data.Type == "Charm"
	local exterior = information:FindFirstChild("Exterior")

	if exterior then
		exterior.Visible = not v30

		if not v30 then
			exterior.RichText = true
			exterior.Text = `<b><font color="rgb(175,175,175)">Exterior</font></b>: <font color="rgb(255,255,255)">{v29}</font>`
		end
	end

	local tradeable = information:FindFirstChild("Tradeable")

	if tradeable then
		tradeable.RichText = true
		tradeable.Text = `<b><font color="rgb(175,175,175)">Tradeable</font></b>: <font color="rgb(255,255,255)">{data.IsTradeable and "Yes" or "No"}</font>`
	end

	local serial = information:FindFirstChild("Serial")

	if serial then
		serial.RichText = true
		local serial2 = data.Serial
		serial.Text = `<b><font color="rgb(175,175,175)">Serial</font></b>: <font color="rgb(255,255,255)">{typeof(serial2) ~= "number" and "N/A" or `#{commaNumber(serial2)}`}</font>` -- inferred equivalent call
	end

	local pattern = information:FindFirstChild("Pattern")

	if pattern then
		if v30 then
			pattern.Visible = true
			pattern.RichText = true
			pattern.Text = `<b><font color="rgb(175,175,175)">Pattern</font></b>: <font color="rgb(255,255,255)">{tostring(data.Pattern or 0)}</font>`
		elseif data.Skin:find("PATTERN") then
			local _, v31 = table.unpack(data.Skin:split("_PATTERN_"))
			pattern.Text = `<b><font color="rgb(175,175,175)">Pattern</font></b>: <font color="rgb(255,255,255)">{v31}</font>`
			pattern.Visible = true
		else
			pattern.Visible = false
		end
	end

	local float = information:FindFirstChild("Float")

	if float then
		float.Visible = not v30

		if not v30 then
			float.RichText = true
			float.Text = `<b><font color="rgb(175,175,175)">Float</font></b>: <font color="rgb(255,255,255)">{string.format("%.14f", data.Float or 0)}</font>`
		end
	end

	task.defer(function()
		local v31 = {}

		if exterior and exterior.Visible then
			table.insert(v31, exterior)
		end

		if tradeable then
			table.insert(v31, tradeable)
		end

		if serial then
			table.insert(v31, serial)
		end

		if pattern and pattern.Visible then
			table.insert(v31, pattern)
		end

		if float and float.Visible then
			table.insert(v31, float)
		end

		scaleInfoFrameToFit(information, v31)
	end)
end

local function hideInfoFrame(instance)
	local information = instance:FindFirstChild("Information")

	if information then
		information.Visible = false
	end
end

local function isStoreOriginInspect()
	if
		MenuState.IsCaseSceneActive()
		or MenuState.GetScreenBeforeCaseScene() == "Store"
		or MenuState.GetCurrentScreen() == "Store"
	then
		return true
	end

	local mainGui = PlayerGui:FindFirstChild("MainGui")
	local menu = mainGui and mainGui:FindFirstChild("Menu")
	local store = menu and menu:FindFirstChild("Store")
	local caseContent = store and store:FindFirstChild("CaseContent")
	return caseContent ~= nil and caseContent:GetAttribute("WasVisibleBeforeInspect") == true
end

local function shouldHideInfoButton() -- 3 equivalent calls inferred from this helper
	return (isStoreOriginInspect())
end

local function tryShowInfoFrame(instance, data) -- 2 equivalent calls inferred from this helper
	if instance and v5 and not shouldHideInfoButton() and v5.Type ~= "Badge" then -- inferred equivalent call
		showInfoFrame(instance, v5, data)
	end
end

local function setupButtonEvents(button, k: string, p, instance)
	maid:Add(button.MouseEnter:Connect(function()
		updateButtonVisuals(k, button, true)

		if k == "Info" then
			tryShowInfoFrame(instance, button) -- inferred equivalent call
		end
	end), "Disconnect", "InspectButton_Enter_" .. k)
	maid:Add(button.MouseLeave:Connect(function()
		updateButtonVisuals(k, button, false)
		local information = k == "Info" and instance and instance:FindFirstChild("Information")

		if information then
			information.Visible = false
		end
	end), "Disconnect", "InspectButton_Leave_" .. k)

	if k == "Info" then
		maid:Add(button.Activated:Connect(function()
			tryShowInfoFrame(instance, button) -- inferred equivalent call
		end), "Disconnect", "InspectButton_Activated_Info")
	else
		maid:Add(button.MouseButton1Click:Connect(function()
			if v11 == k then
				if k == "Viewmodel" then
					InspectController.PlayInspectAnimation()
				end
			else
				setInspectMode(k)
				refreshAllButtons(p, k)
			end
		end), "Disconnect", "InspectButton_Click_" .. k)
	end
end

local function setupInspectButtons(inspect, data)
	local middle = inspect:FindFirstChild("Bottom").Middle
	local buttons = middle and middle:FindFirstChild("Buttons")

	if not buttons then
		return
	end

	local visible = supportsViewmodelInspect(data) -- inferred equivalent call
	local gloveInventoryItem = isGloveInventoryItem(data) -- inferred equivalent call
	local v29 = {
		Info = buttons:FindFirstChild("Info"),
		Viewmodel = buttons:FindFirstChild("Viewmodel"),
		Weapon = buttons:FindFirstChild("Weapon")
	}
	local v30 = shouldHideInfoButton() -- inferred equivalent call
	local v31 = data.Type == "Badge"

	for k, button in pairs(v29) do
		if not (button and button:IsA("GuiButton")) then
			continue
		end

		if k == "Info" then
			button.Visible = not (v30 or v31)
		elseif k == "Weapon" then
			button.Visible = visible and not gloveInventoryItem
		else
			button.Visible = visible
		end

		updateButtonVisuals(k, button, false)
		setupButtonEvents(button, k, v29, inspect)
	end
end

local function getWearPreviewChance(data, wear: string)
	for _, v29 in ipairs(data.floatChances or {}) do
		if v29.wear == wear then
			return v29.chance
		end
	end

	return nil
end

local function formatWearPreviewChance(value: number?) -- 1 equivalent call inferred from this helper
	if value then
		return (string.format("%.2f%%", value))
	end

	return ""
end

local function getWearPreviewFloat(data, p) -- 1 equivalent call inferred from this helper
	local v29 = math.max(data.floatRange.min, p.Min)
	local v30 = math.min(data.floatRange.max, p.Max - 1e-12)

	if v30 < v29 then
		return nil
	end

	return (math.clamp((v29 + v30) / 2, 0, 1))
end

local function refreshActiveInspectItem(clone) -- 2 equivalent calls inferred from this helper
	v5 = clone
	cleanupInspectMode() -- inferred equivalent call

	if v11 == "Weapon" then
		setupWeaponInspect(clone)
	elseif v11 == "Viewmodel" then
		InputController.disableGroup("Gameplay")
		setupViewmodelInspect(clone)
	end
end

local function getStatTrakPreviewChance(data) -- 1 equivalent call inferred from this helper
	if data.type == "Glove" or data.supportsStatTrak == false then
		return 0
	end

	return data.statTrakChance or 0
end

local function setKillTrakBadgeVisible(guiObject, visible: boolean)
	for _, childName in ipairs({ "Bottom", "Middle", "Description", "Statrak" }) do
		guiObject = guiObject and guiObject:FindFirstChild(childName)
	end

	if guiObject and guiObject:IsA("GuiObject") then
		guiObject.Visible = visible
	end
end

local function updateStatTrakToggle(instance, floatPreviews, visible: boolean)
	local killTrak = floatPreviews:FindFirstChild("KillTrak")

	if not killTrak then
		return
	end

	killTrak.Visible = visible
	local button = killTrak:FindFirstChild("Button")

	if not (button and button:IsA("GuiButton")) then
		return
	end

	local checkmarkImage = button:FindFirstChild("CheckmarkImage")

	if checkmarkImage then
		checkmarkImage.Visible = visible2
	end

	maid:Add(button.Activated:Connect(function()
		visible2 = not visible2

		if checkmarkImage then
			checkmarkImage.Visible = visible2
		end

		setKillTrakBadgeVisible(instance, visible2)
		local v29 = v5

		if v29 then
			local clone = table.clone(v29)
			clone.StatTrack = visible2 and 0 or false
			refreshActiveInspectItem(clone) -- inferred equivalent call
		end
	end), "Disconnect", "FloatPreview_StatTrakToggle")
end

local function updateFloatPreviewRow(clone, data, data2, wearPreviewFloat: number, wearPreviewChance: number?)
	clone.Name = data.Wear
	clone.Visible = true
	clone.LayoutOrder = table.find(v23, data) or 0
	clone:SetAttribute("Wear", data.Wear)
	clone:SetAttribute("PreviewFloat", wearPreviewFloat)
	local left = clone:FindFirstChild("Left")
	local label = left and left:FindFirstChild("Label")

	if label and label:IsA("TextLabel") then
		label.Text = data.Display
		label.TextColor3 = data.Color
	end

	local percent = left and left:FindFirstChild("Percent")

	if percent and percent:IsA("TextLabel") then
		percent.Text = formatWearPreviewChance(wearPreviewChance) -- inferred equivalent call
	end

	local bar = clone:FindFirstChild("Bar")
	local current = bar and bar:FindFirstChild("Current")

	if current and current:IsA("Frame") then
		local size = current.Size
		local v29 = math.clamp((wearPreviewChance or 0) / 100, 0, 1)
		current.Size = UDim2.new(v29, 0, size.Y.Scale, size.Y.Offset)
		current.BackgroundColor3 = data.Color
	end

	local icon = clone:FindFirstChild("Icon", true)

	if icon and icon:IsA("ImageLabel") then
		icon.Image = Skins.GetWearImageForFloat(data2, wearPreviewFloat) or data2.imageAssetId or ""
	end

	local rarity = Rarities[data2.rarity]

	if rarity then
		local rarityFrame = clone:FindFirstChild("RarityFrame", true)

		if rarityFrame and rarityFrame:IsA("Frame") then
			rarityFrame.BackgroundColor3 = rarity.Color
		end

		local rarity2 = clone:FindFirstChild("Rarity", true)

		if rarity2 and rarity2:IsA("ImageLabel") then
			rarity2.ImageColor3 = rarity.Color
		end
	end
end

local function updateFloatPreviewFrame(inspect, data, skinInformation)
	local floatPreviews = inspect:FindFirstChild("FloatPreviews")

	if not floatPreviews then
		return
	end

	local container = floatPreviews:FindFirstChild("Container")

	if not container then
		floatPreviews.Visible = false
		return
	end

	for _, frame in ipairs(container:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end

	local visible

	if skinInformation == nil or data.HideWearDetails ~= true then
		visible = false
	else
		visible = data.Type ~= "Charm"
	end

	floatPreviews.Visible = visible

	if not (visible and skinInformation) then
		return
	end

	container.Visible = true
	floatPreviews.Position = getStoredFloatPreviewOpenPosition(floatPreviews)
	floatPreviews:SetAttribute("IsOpen", true)
	local toggleButton = floatPreviews:FindFirstChild("ToggleButton")

	if toggleButton and toggleButton:IsA("GuiButton") then
		setFloatPreviewArrowDirection(toggleButton, true) -- inferred equivalent call
	end

	local v29

	if getStatTrakPreviewChance(skinInformation) > 0 then -- inferred equivalent call
		v29 = isStoreOriginInspect()
	else
		v29 = false
	end

	if not v29 then
		visible2 = false
	end

	updateStatTrakToggle(inspect, floatPreviews, v29)

	for _, v30 in ipairs(v23) do
		local wearPreviewFloat = getWearPreviewFloat(skinInformation, v30) -- inferred equivalent call
		local wearPreviewChance = getWearPreviewChance(skinInformation, v30.Wear)

		if not wearPreviewFloat or not wearPreviewChance or wearPreviewChance <= 0 then
			continue
		end

		local clone = PreviewTemplate:Clone()
		updateFloatPreviewRow(clone, v30, skinInformation, wearPreviewFloat, wearPreviewChance)

		local function selectWearPreview()
			local v31 = v5

			if not v31 then
				return
			end

			local clone2 = table.clone(v31)
			clone2.Float = wearPreviewFloat
			clone2.HideWearDetails = true
			clone2.ShowFullPriceRange = true
			refreshActiveInspectItem(clone2) -- inferred equivalent call
		end

		local inspect2 = clone:FindFirstChild("Inspect")

		if inspect2 and inspect2:IsA("GuiObject") then
			inspect2.Visible = false
		end

		local button = clone:FindFirstChild("Button")

		if button and button:IsA("GuiButton") then
			ActivateButton(button)
			maid:Add(button.Activated:Connect(selectWearPreview), "Disconnect", "FloatPreview_Button_" .. v30.Wear)
		end

		clone.Parent = container
	end
end

local function updateCollectionData(inspect, skinInformation)
	local collection = skinInformation and skinInformation.collection
	local v29 = collection and Collections.GetCollectionByName(collection)
	local visible = v29 ~= nil
	local collection2 = inspect.Top.Frame.Frame.TextInfo:FindFirstChild("Collection")

	if collection2 and collection2:IsA("TextLabel") then
		collection2.Visible = visible
		collection2.Text = collection or ""
	end

	local collectionIcon = inspect.Top.Frame.Frame:FindFirstChild("CollectionIcon")

	if collectionIcon and collectionIcon:IsA("ImageLabel") then
		collectionIcon.Image = v29 and v29.imageAssetId or ""
		collectionIcon.Visible = visible
	end

	local weaponName = inspect:FindFirstChild("WeaponName")

	if weaponName and weaponName:IsA("TextLabel") then
		weaponName.Position = udim
		local size

		if visible then
			size = udim3
		else
			size = udim2
		end

		weaponName.Size = size
		weaponName.TextXAlignment = Enum.TextXAlignment.Center
	end

	local rarity = inspect:FindFirstChild("Rarity")

	if rarity and rarity:IsA("Frame") then
		rarity.Position = udim4
	end
end

local function updateInspectFrameUI(data)
	local mainGui = PlayerGui:FindFirstChild("MainGui")
	local menu = mainGui and mainGui:FindFirstChild("Menu")
	local inspect = menu and (menu:FindFirstChild("Inspect") or menu:FindFirstChild("InspectFrame"))

	if not inspect then
		return
	end

	setupInspectButtons(inspect, data)
	local information = shouldHideInfoButton() and inspect:FindFirstChild("Information") -- inferred equivalent call

	if information then
		information.Visible = false
	end

	local skinInformation = Skins.GetSkinInformation(data.Name, data.Skin)
	updateFloatPreviewFrame(inspect, data, skinInformation)
	local item = inspect.Top.Frame.Frame.TextInfo:FindFirstChild("Item")

	if item and item:IsA("TextLabel") then
		local skinDisplayName = GetSkinDisplayName(data.Skin)
		local v29 = skinInformation and skinInformation.type == "Melee" and "★ " or ""
		GetSkinDisplayName.ApplyNameLabel(
			item,
			v29 .. GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag) .. " | " .. skinDisplayName,
			data.NameTag
		)
	end

	if skinInformation then
		updateCollectionData(inspect, skinInformation)
		local rarity = inspect.Top.Frame:FindFirstChild("Rarity")
		local v29 = rarity and rarity:IsA("Frame") and skinInformation.rarity and Rarities[skinInformation.rarity]

		if v29 then
			rarity.BackgroundColor3 = v29.Color
		end
	end

	local description = inspect.Bottom.Middle:FindFirstChild("Description")

	if description then
		local visible = typeof(data.StatTrack) == "number" or data.StatTrack == true
		description.Statrak.Visible = visible
		description.Description.Text = skinInformation and skinInformation.description or ""
	end
end

local function hideViewmodels()
	models = {}

	for _, model in ipairs(CurrentCamera:GetChildren()) do
		if not (model:IsA("Model") and model.Name ~= "InspectScene" and (not v4 or v4.Model ~= model)) then
			continue
		end

		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") or descendant:IsA("Texture") then
				if descendant.Transparency < 1 then
					descendant:SetAttribute("_InspectPrevTransparency", descendant.Transparency)
					descendant.Transparency = 1
				end
			elseif descendant:IsA("SurfaceGui") and descendant.Enabled then
				descendant:SetAttribute("_InspectPrevSurfaceGuiEnabled", true)
				descendant.Enabled = false
			end
		end

		table.insert(models, model)
	end
end

local function showViewmodels()
	for _, folder in ipairs(models) do
		if not (folder and folder.Parent) then
			continue
		end

		for _, descendant in ipairs(folder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				local inspectPrevTransparency = descendant:GetAttribute("_InspectPrevTransparency")

				if inspectPrevTransparency ~= nil then
					descendant.Transparency = inspectPrevTransparency
					descendant:SetAttribute("_InspectPrevTransparency", nil)
				end
			elseif descendant:IsA("SurfaceGui") then
				if descendant:GetAttribute("_InspectPrevSurfaceGuiEnabled") ~= nil then
					descendant.Enabled = true
					descendant:SetAttribute("_InspectPrevSurfaceGuiEnabled", nil)
				end
			elseif descendant:IsA("Texture") then
				local inspectPrevTransparency = descendant:GetAttribute("_InspectPrevTransparency")

				if inspectPrevTransparency == nil then
					descendant.Transparency = 0.3
				else
					descendant.Transparency = inspectPrevTransparency
					descendant:SetAttribute("_InspectPrevTransparency", nil)
				end
			end
		end
	end

	models = {}
end

local function restoreMenuFrames()
	local menuFrame = MenuState.GetMenuFrame()

	if menuFrame and menuFrame.Visible then
		local inspect = menuFrame:FindFirstChild("Inspect") or menuFrame:FindFirstChild("InspectFrame")

		if inspect and inspect:IsA("GuiObject") then
			local mobileButtons = inspect:FindFirstChild("MobileButtons")
			inspect.Visible = false

			if mobileButtons then
				mobileButtons.Visible = false
			end
		end

		local screenBeforeInspect = MenuState.GetScreenBeforeInspect()
		local v29 = v9
		v9 = false
		MenuState.ExitInspect()

		if v29 then
			MenuSceneController.ShowMenuScene()
			MenuSceneController.SetMusicVolumeMultiplier(1, 0.5)
		end

		local top = menuFrame:FindFirstChild("Top")

		if top then
			top.Visible = true
		end

		if screenBeforeInspect then
			local child = menuFrame:FindFirstChild(screenBeforeInspect)

			if child then
				hideOtherMenuScreens(menuFrame, screenBeforeInspect)
				child.Visible = true

				if
					MenuState.IsCaseSceneActive() and screenBeforeInspect == "Store"
					or MenuState.IsSceneScreen(screenBeforeInspect)
				then
					setMenuBackdrop(menuFrame, false, false) -- inferred equivalent call
				else
					local v30

					if screenBeforeInspect == "Dashboard" then
						v30 = false
					else
						v30 = screenBeforeInspect ~= "Play"
					end

					setMenuBackdrop(menuFrame, v30, not v30) -- inferred equivalent call
				end
			end
		else
			hideOtherMenuScreens(menuFrame, "Dashboard")
			local dashboard = menuFrame:FindFirstChild("Dashboard")

			if dashboard then
				dashboard.Visible = true
			end

			setMenuBackdrop(menuFrame, false, true) -- inferred equivalent call
		end
	else
		v9 = false
		MenuState.ExitInspect()
	end
end

local function abortInspectScene(p: string) -- 2 equivalent calls inferred from this helper
	warn(p)

	if parent then
		parent.Parent = ReplicatedStorage
		parent = nil
	end

	applyMapLighting() -- inferred equivalent call
	restoreMenuFrames()
end

local function resetInspectView(p: number) -- 2 equivalent calls inferred from this helper
	v19 = 0
	v20 = 0
	v21 = 0
	v22 = 0
	v17 = p
	v18 = p
end

function InspectController.ShowInspect(p)
	if flag2 then
		InspectController.HideInspect()
	end

	if Router.broadcastRouter("HasPendingCharmAttachment") then
		v26 = p
		v27 = 1
	else
		v26 = nil
	end

	v5 = p
	visible2 = false
	v11 = isGloveInventoryItem(p) and "Viewmodel" or "Weapon" -- inferred equivalent call
	hideMenuFrames()
	hideViewmodels()
	updateCharmFrameVisibility()
	updateInspectFrameUI(p)

	if v8 then
		if v8.Parent ~= workspace then
			v8.Parent = workspace
		end

		parent = v8
		activateInspectSceneFlags(parent)

		if name then
			applySceneLighting(name) -- inferred equivalent call
		end

		local camPart

		if parent then
			camPart = parent:FindFirstChild("CamPart")
		else
			camPart = nil
		end

		if camPart then
			if parent and parent:FindFirstChild("WeaponPart") then
				if v11 == "Viewmodel" then
					InputController.disableGroup("Gameplay")
					setupViewmodelInspect(p)
				else
					InputController.enableGroup("Gameplay")
					setupWeaponInspect(p)
				end

				resetInspectView(v11 ~= "Viewmodel" and 40 or DEFAULT_CAMERA_FOV) -- inferred equivalent call
				CurrentCamera.CameraType = Enum.CameraType.Scriptable
				CurrentCamera.CFrame = camPart.CFrame
				CurrentCamera.Focus = camPart.CFrame
				CameraController.updateCameraFOV(v11 ~= "Viewmodel" and 40 or DEFAULT_CAMERA_FOV)
				CameraController.setForceLockOverride("Inspect", true)
				maid:Add(RunServiceController.BindToRenderStep("InspectController.CameraUpdate", function(p2)
					local v29 = math.min(1, p2 * 8)
					v17 += (v18 - v17) * v29

					if parent and camPart then
						CurrentCamera.CameraType = Enum.CameraType.Scriptable
						CurrentCamera.CFrame = camPart.CFrame
						CurrentCamera.Focus = camPart.CFrame
						CurrentCamera.FieldOfView = CameraController.clampFOV(v17)
					end

					if v11 == "Weapon" and UserInputService.GamepadEnabled then
						local lastInputType = UserInputService:GetLastInputType()
						local gamepadState = UserInputService:GetGamepadState((lastInputType == Enum.UserInputType.Gamepad1 or lastInputType == Enum.UserInputType.Gamepad2 or lastInputType == Enum.UserInputType.Gamepad3 or lastInputType == Enum.UserInputType.Gamepad4) and lastInputType or Enum.UserInputType.Gamepad1)

						if gamepadState then
							for _, v30 in pairs(gamepadState) do
								if v30.KeyCode == Enum.KeyCode.Thumbstick2 then
									local vector = Vector2.new(v30.Position.X, v30.Position.Y)

									if vector.Magnitude > 0.1 then
										handleDragInput(Vector2.new( -- inferred equivalent call
											vector.X * 0.5 * 60 * p2 * 4.75,
											vector.Y * 0.5 * 60 * p2 * 4.75
										))
									end
								elseif
									(v30.KeyCode == Enum.KeyCode.ButtonR2 or v30.KeyCode == Enum.KeyCode.ButtonL2)
									and v30.Position.Z > 0.1
								then
									local v31

									if v30.KeyCode == Enum.KeyCode.ButtonR2 then
										v31 = -v30.Position.Z
									else
										v31 = v30.Position.Z
									end

									handleFOVInput(v31 * 2 * 30 * p2 * 0.55) -- inferred equivalent call
								end
							end
						end
					end

					if v11 == "Viewmodel" and v4 then
						v4:render(p2)
					elseif v11 == "Weapon" then
						local v30 = math.min(1, p2 * 10)
						v19 += (v21 - v19) * v30
						v20 += (v22 - v20) * v30

						if v10 then
							if not parent then
								return
							end

							local weaponPart = parent:FindFirstChild("WeaponPart")

							if weaponPart then
								local cframe2 = CFrame.Angles(0, math.rad(v20), (math.rad(v19)))
								pivotInspectWeapon(v10, weaponPart, cframe2) -- inferred equivalent call
							end
						end
					end
				end), "Disconnect", "CameraUpdate")
				maid:Add(UserInputService.InputBegan:Connect(function(input, _)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						v16 = true
						zero = Vector2.new(input.Position.X, input.Position.Y)

						if not isPointerOverButton(input.Position) then
							InspectController.PlayInspectAnimation()
						end
					end

					if table.find(InputController.getActionKeybinds("Inspect"), input.KeyCode) then
						if LocalPlayer:GetAttribute("IsPlayerChatting") then
							return
						else
							InspectController.PlayInspectAnimation()
						end
					end

					if table.find(InputController.getActionKeybinds("Reload"), input.KeyCode) then
						if LocalPlayer:GetAttribute("IsPlayerChatting") then
							return
						else
							InspectController.CancelInspectAnimation()
						end
					end

					if input.UserInputType == Enum.UserInputType.Touch then
						v24[input] = Vector2.new(input.Position.X, input.Position.Y)

						if getTouchCount() == 1 then -- inferred equivalent call
							v16 = true
							zero = Vector2.new(input.Position.X, input.Position.Y)
						end

						v25 = getPinchDistance()
					end
				end), "Disconnect", "InputBegan")
				maid:Add(UserInputService.InputChanged:Connect(function(input, _)
					if input.UserInputType == Enum.UserInputType.MouseMovement and v16 then
						local vector = Vector2.new(input.Position.X, input.Position.Y)
						handleDragInput(vector - zero) -- inferred equivalent call
						zero = vector
					end

					if input.UserInputType == Enum.UserInputType.Touch then
						local vector = Vector2.new(input.Position.X, input.Position.Y)
						v24[input] = vector
						local touchCount = getTouchCount() -- inferred equivalent call

						if touchCount == 1 and v16 then
							handleDragInput(vector - zero) -- inferred equivalent call
							zero = vector
						end

						if touchCount >= 2 then
							local pinchDistance = getPinchDistance()

							if pinchDistance and v25 then
								handleFOVInput((pinchDistance - v25) * 0.01) -- inferred equivalent call
							end

							v25 = pinchDistance
						end
					end

					if input.UserInputType == Enum.UserInputType.MouseWheel then
						local z = input.Position.Z

						if v11 == "Viewmodel" then
							return
						else
							v18 = math.clamp(v18 - z * 2, 20, 70)
						end
					end
				end), "Disconnect", "InputChanged")
				maid:Add(UserInputService.InputEnded:Connect(function(input, _)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						v16 = false
					end

					if input.UserInputType == Enum.UserInputType.Touch then
						v24[input] = nil

						if getTouchCount() == 0 then -- inferred equivalent call
							v16 = false
						end

						v25 = getPinchDistance()
					end
				end), "Disconnect", "InputEnded")
				maid:Add(function()
					cleanupWeaponInspect() -- inferred equivalent call

					if parent then
						if parent == v8 then
							parent.Parent = ReplicatedStorage
						else
							parent:Destroy()
						end

						parent = nil
					end

					v16 = false
					v24 = {}
					v25 = nil
					resetInspectView(40) -- inferred equivalent call
				end, true, "InspectCleanup")
				flag2 = true
				updateInspectMobileButtonsVisibility() -- inferred equivalent call
				refreshInspectTips()
			else
				abortInspectScene("[InspectController]: Inspect scene missing WeaponPart") -- inferred equivalent call
			end
		else
			abortInspectScene("[InspectController]: Inspect scene missing CamPart") -- inferred equivalent call
		end
	else
		warn("[InspectController]: No preloaded inspect scene available")
		restoreMenuFrames()
	end
end

function InspectController.HideInspect(flag3: boolean?)
	if not flag2 then
		return
	end

	v12 = nil
	maid:Cleanup()
	cleanupViewmodelInspect() -- inferred equivalent call
	cleanupWeaponInspect() -- inferred equivalent call

	if MenuState.IsCaseSceneActive() then
		CaseSceneController.ApplyCaseSceneLighting()
	else
		applyMapLighting() -- inferred equivalent call
	end

	CurrentCamera.CameraType = Enum.CameraType.Custom
	CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
	CameraController.setForceLockOverride("Inspect", false)

	if flag3 then
		MenuState.ExitInspect()
		v9 = false
	else
		restoreMenuFrames()
	end

	if MenuState.IsCaseSceneActive() then
		models = {}
	else
		showViewmodels()
	end

	v26 = nil
	v27 = 1
	flag2 = false
	updateInspectMobileButtonsVisibility() -- inferred equivalent call
	refreshInspectTips()
end

function InspectController.IsActive()
	return flag2
end

function InspectController.CycleCharmPosition()
	if flag2 and v26 then
		v27 = v27 % 4 + 1
		InspectController.RefreshWeaponWithCharm((tostring(v27)))
	end
end

function InspectController.RefreshWeaponWithCharm(position: string)
	if not (flag2 and parent and v26) then
		return
	end

	local parent2 = parent
	local v29 = v26

	if not parent2:FindFirstChild("WeaponPart") then
		return
	end

	local v30 = v19
	local v31 = v20
	local v32 = v21
	local v37 = v22
	local charm = v29.Charm
	local charm2 = type(charm) == "table" and { _id = charm._id, Position = position } or position

	if v11 == "Weapon" then
		cleanupWeaponInspect() -- inferred equivalent call
		local characterModel = Skins.GetCharacterModel(
			v29.Name,
			v29.Skin,
			v29.Float,
			v29.StatTrack,
			v29.NameTag,
			charm2,
			v29.Stickers
		)

		if not characterModel then
			warn(`[InspectController]: Failed to refresh weapon model for charm position {position}`)
			return
		end

		prepareInspectWeapon(characterModel, false)
		characterModel.Parent = parent2
		v19 = v30
		v20 = v31
		v21 = v32
		v22 = v37
		local weaponPart = v10 and parent and parent:FindFirstChild("WeaponPart")

		if weaponPart then
			local cframe2 = CFrame.Angles(0, math.rad(v20), (math.rad(v19)))
			pivotInspectWeapon(v10, weaponPart, cframe2) -- inferred equivalent call
		end
	end

	if v4 and v6 then
		v4.Charm = charm2
		v4:construct(v6, nil)
	end
end

function InspectController.PlayInspectAnimation()
	if v11 ~= "Viewmodel" or not v4 then
		return
	end

	if isGloveInventoryItem(v5) then -- inferred equivalent call
		if v2 then
			if v2.IsPlaying then
				return
			end

			if v4 and v4.Animation then
				v4.Animation:stopAnimations()
			end

			v2.TimePosition = 0
			v2:Play(0, 1, 1)
		end
	elseif v4.Animation then
		local inspectVariant = v4.Animation:pickInspectVariant()
		v4.Animation:stopAnimations()
		v4.Animation:play("Idle")
		v4.Animation:play(inspectVariant)
	end
end

function InspectController.CancelInspectAnimation()
	if v11 ~= "Viewmodel" or not v4 or isGloveInventoryItem(v5) then -- inferred equivalent call
		return
	end

	if v4.Animation then
		v4.Animation:markInspectCancel()
		v4.Animation:crossfadeTo("Idle", 0.25)
	end
end

function InspectController.Initialize()
	DataController.CreateListener(LocalPlayer, "Settings.Video.Presets.Global Shadows", function()
		SceneLighting.ApplyGlobalShadows(v7)
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Keyboard/Mouse", refreshInspectTips)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshInspectTips)
	local randomInspectScene = getRandomInspectScene()

	if randomInspectScene then
		name = randomInspectScene.Name
		v8 = randomInspectScene
		randomInspectScene.Name = "InspectScene"
		randomInspectScene.Parent = ReplicatedStorage
	else
		warn("[InspectController]: No inspect scene found to preload in ReplicatedStorage.Assets.InspectScenes")
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape and flag2 then
			InspectController.HideInspect()
		end
	end)
	LocalPlayer.CharacterAdded:Connect(function()
		if flag2 then
			InspectController.HideInspect()
		end
	end)
	Router.observerRouter(
		"WeaponInspect",
		function(name2: string, skin: string, float: number?, statTrack, nameTag, charm, stickers, p: string?, pattern: number?, p2: string?, serial: number?, flag3: boolean?, flag4: boolean?, flag5: boolean?)
			local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)

			if EndScreenController.IsActive() then
				return
			end

			local v29 = {
				_id = p2 or "inspect_" .. name2 .. "_" .. skin,
				Name = name2,
				Skin = skin,
				Float = float,
				StatTrack = statTrack,
				NameTag = nameTag,
				Charm = charm,
				Stickers = stickers,
				Type = p,
				Pattern = pattern,
				Serial = serial,
				IsTradeable = flag3,
				HideWearDetails = flag4,
				ShowFullPriceRange = flag5
			}
			InspectController.ShowInspect(v29)
		end
	)
	Router.observerRouter("WeaponInspectClose", function()
		InspectController.HideInspect()
	end)
	Router.observerRouter("WeaponInspectCloseForGameEnd", function()
		InspectController.HideInspect(true)
	end)
	Router.observerRouter("IsInspectActive", function()
		return flag2
	end)
	Router.observerRouter("GetCurrentCharmPosition", function()
		return v27
	end)
end

function InspectController.Start()
	initializeInspectButtons()
end

return InspectController