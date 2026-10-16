local MobileButtons = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
require(script:WaitForChild("Types"))
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local MobileAutoShootController = require(ReplicatedStorage.Controllers.MobileAutoShootController)
local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local InspectController = require(ReplicatedStorage.Controllers.InspectController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local HintController = require(ReplicatedStorage.Controllers.HintController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local CanPlayerUseChatService = require(ReplicatedStorage.Database.Components.Common.Roblox.CanPlayerUseChatService)
local CenterScreenRaycast = require(ReplicatedStorage.Components.Common.CenterScreenRaycast)
local IsInBuyArea = require(ReplicatedStorage.Database.Components.Common.IsInBuyArea)
local TutorialPurchaseLock = require(ReplicatedStorage.Components.Common.TutorialPurchaseLock)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local ApplyMobileButtonLayout = require(ReplicatedStorage.Components.Common.ApplyMobileButtonLayout)
local Mobile = require(ReplicatedStorage.Database.Custom.GameStats.UI.Mobile)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Promise = require(ReplicatedStorage.Shared.Promise)
local TeamSelection = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.TeamSelection)
local BuyMenu = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.BuyMenu)
local Leaderboard = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Leaderboard)
local Chat = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Chat)
local HoverBomb = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.HoverBomb)
local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
local ChatModes = require(ReplicatedStorage.Database.Custom.GameStats.UI.Chat.ChatModes)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Buttons = require(script.Buttons)
local Loadout = require(script.Loadout)
local TouchIntent = require(script.TouchIntent)
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local CameraInput = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"):WaitForChild("CameraModule"):WaitForChild("CameraInput"))
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = false
local userPlatform = GetUserPlatform()
local v = table.find(userPlatform, "Mobile") and #userPlatform <= 1
local v2 = nil
local v3 = nil
local v4 = nil
local v5 = nil
local v6 = false
local now = 0
local v7 = false
local v8 = {}
local v9 = {}
local v10 = {}
local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.In)
local BUTTONS_WITH_EXPLICIT_INPUT_ENDED = Buttons.BUTTONS_WITH_EXPLICIT_INPUT_ENDED
local BUTTONS_WITH_EXPLICIT_HANDLERS = Buttons.BUTTONS_WITH_EXPLICIT_HANDLERS
local BUTTONS_EXCLUDED_FROM_CLEARING = Buttons.BUTTONS_EXCLUDED_FROM_CLEARING
local BUTTONS_WITH_CAMERA_DRAG = Buttons.BUTTONS_WITH_CAMERA_DRAG
local SPECTATE_MOBILE_BUTTONS = Buttons.SPECTATE_MOBILE_BUTTONS
local GAMEPLAY_MOBILE_BUTTONS = Buttons.GAMEPLAY_MOBILE_BUTTONS
local v11 = { "EndScreen", "Halftime" }
local v12 = nil
local parent = nil
local v13 = nil

local function GetWeaponDataFromInstance(parent2)
	while parent2 do
		if CollectionService:HasTag(parent2, "WeaponDropped") then
			local weapon = parent2:GetAttribute("Weapon")
			local skin = parent2:GetAttribute("Skin")

			if weapon and skin then
				return weapon, skin, parent2.Name
			else
				break
			end
		else
			parent2 = parent2.Parent
		end
	end

	return nil, nil, nil
end

local function GetPingRaycastResult(...)
	local instances = { CurrentCamera, ... }
	raycastParams.FilterDescendantsInstances = instances
	local raycastResult = workspace:Raycast(
		CurrentCamera.CFrame.Position,
		CurrentCamera.CFrame.LookVector * 1000,
		raycastParams
	)

	while raycastResult and raycastResult.Instance do
		local instance = raycastResult.Instance

		if not instance:IsA("BasePart") or instance.Transparency <= 0.98 then
			break
		end

		table.insert(instances, instance)
		raycastParams.FilterDescendantsInstances = instances
		raycastResult = workspace:Raycast(
			raycastResult.Position,
			CurrentCamera.CFrame.LookVector.Unit * (1000 - raycastResult.Distance),
			raycastParams
		)
	end

	return raycastResult
end

local function ValidateButtonTouch(p, input) -- 4 equivalent calls inferred from this helper
	local v14 = v8[p]
	return v14 ~= nil and (input == nil or input == v14)
end

local function IsNewTouch(p) -- 7 equivalent calls inferred from this helper
	return p.UserInputState == Enum.UserInputState.Begin
end

local function IsPressInput(input) -- 7 equivalent calls inferred from this helper
	return input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
end

local fn

local function TrackButtonTouchStart(p, input)
	if not v8[p] and IsNewTouch(input) then -- inferred equivalent call
		v8[p] = input

		if not BUTTONS_WITH_CAMERA_DRAG[p.Name] then
			TouchIntent.track(input, p, function(p2)
				if fn then
					fn(p, p2)
				end
			end)
		end
	end
end

local function TrackButtonTouchEnd(p, p2) -- 8 equivalent calls inferred from this helper
	if v8[p] == p2 then
		v8[p] = nil
	end
end

local function IsInputInsideButton(p, input) -- 1 equivalent call inferred from this helper
	local position = input.Position
	local absolutePosition = p.AbsolutePosition
	local absoluteSize = p.AbsoluteSize
	return position.X >= absolutePosition.X
		and position.X <= absolutePosition.X + absoluteSize.X
		and position.Y >= absolutePosition.Y
		and position.Y <= absolutePosition.Y + absoluteSize.Y
end

local function SetButtonVisibility(childName: string, flag: boolean) -- 14 equivalent calls inferred from this helper
	local child = v12:FindFirstChild(childName)

	if child then
		child.Visible = flag and not v10[childName]
	end
end

local function CanUseVIPMenu()
	if RunService:IsStudio() then
		return true
	end

	return workspace:GetAttribute("IsVIPServer") == true and LocalPlayer:GetAttribute("CanUseVIPMenu") == true
end

local function SetToggledIndicator(instance, visible: boolean) -- 5 equivalent calls inferred from this helper
	local toggled = instance and instance:FindFirstChild("Toggled")

	if toggled and toggled:IsA("GuiObject") and toggled.Visible ~= visible then
		toggled.Visible = visible
	end
end

local function IsAlternativeActionActive() -- 1 equivalent call inferred from this helper
	if v3 ~= nil then
		return true
	end

	local currentEquipped = InventoryController.getCurrentEquipped()
	local bobble = currentEquipped and currentEquipped.Viewmodel and currentEquipped.Viewmodel.Bobble
	return (bobble and bobble.IsAiming) == true
end

local function UpdateToggledIndicators()
	SetToggledIndicator(v12:FindFirstChild("Crouch"), CharacterController.GetCrouchState() == true) -- inferred equivalent call
	SetToggledIndicator(v12:FindFirstChild("ToggleWalk"), CharacterController.GetWalkState() == true) -- inferred equivalent call
	SetToggledIndicator(v12:FindFirstChild("ToggleScoreboard"), Leaderboard.IsOpen() == true) -- inferred equivalent call
	SetToggledIndicator(v12:FindFirstChild("AlternativeAction"), IsAlternativeActionActive()) -- inferred equivalent call
end

local function UpdateButtonVisibilityForSpectate(isSpectating: boolean)
	if not v12 then
		return
	end

	for _, v14 in ipairs(GAMEPLAY_MOBILE_BUTTONS) do
		SetButtonVisibility(v14, not isSpectating or table.find(SPECTATE_MOBILE_BUTTONS, v14) ~= nil) -- inferred equivalent call
	end

	for _, v14 in ipairs(Loadout.GetSlotButtonNames()) do
		SetButtonVisibility(v14, not isSpectating and Loadout.IsSlotFilled(v14)) -- inferred equivalent call
	end

	local chat = not v7 and v12:FindFirstChild("Chat")

	if chat then
		chat.Visible = false
	end
end

local function IsSiblingFrameVisible(childName: string) -- 2 equivalent calls inferred from this helper
	local v14 = parent or v12 and v12.Parent
	local guiObject = v14 and v14:FindFirstChild(childName)
	return guiObject ~= nil and guiObject:IsA("GuiObject") and guiObject.Visible
end

local function GetDesiredFrameVisibility(p)
	if not v then
		return false
	end

	for _, v14 in ipairs(v11) do
		if IsSiblingFrameVisible(v14) then -- inferred equivalent call
			return false
		end
	end

	local character = LocalPlayer.Character

	if character == p then
		character = nil
	end

	local v14

	if character == nil then
		v14 = false
	else
		v14 = character:IsDescendantOf(workspace)
	end

	if IsSiblingFrameVisible("TeamSelection") and not v14 then -- inferred equivalent call
		return false
	end

	return v14 or LocalPlayer:GetAttribute("IsSpectating") == true
end

local v14 = nil

local function RefreshButtonVisibility(p, flag: boolean?)
	if not v12 then
		return
	end

	local visible2 = GetDesiredFrameVisibility(p)
	local visible = v12.Visible
	v12.Visible = visible2
	local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true

	if visible2 and (flag ~= false or not visible or v14 ~= isSpectating) then
		UpdateButtonVisibilityForSpectate(isSpectating)
	end

	v14 = isSpectating
end

local function GetHoveredHostage() -- 2 equivalent calls inferred from this helper
	return CenterScreenRaycast.GetHoveredHostage()
end

local function GetHoveredBreakableDoor()
	local result = {}
	local model = CenterScreenRaycast.FindTaggedModelInSight("BreakableDoor", 8)

	if not model or not model:IsA("Model") or model:GetAttribute("Destroyed") == true then
		return result
	end

	table.insert(result, model)

	for _, v15 in CollectionService:GetTagged("BreakableDoor") do
		if not (v15 ~= model and v15:GetAttribute("Destroyed") ~= true) then
			continue
		end

		local breakableDoorHingePivot = model:FindFirstChild("BreakableDoorHingePivot")
		local breakableDoorHingePivot2 = v15:FindFirstChild("BreakableDoorHingePivot")

		if
			not breakableDoorHingePivot
			or not breakableDoorHingePivot2
			or (breakableDoorHingePivot.Position - breakableDoorHingePivot2.Position).Magnitude > 20
		then
			continue
		end

		table.insert(result, v15)
	end

	return result
end

local function MultiplyUdim2(udim: UDim2, p: number) -- 2 equivalent calls inferred from this helper
	return UDim2.fromScale(udim.X.Scale * p, udim.Y.Scale * p)
end

local function GetButtonRestingSize(p) -- 3 equivalent calls inferred from this helper
	return v9[p] or p.Size
end

local function SetButtonRestingSize(p, size: UDim2?) -- 3 equivalent calls inferred from this helper
	v9[p] = size or p.Size
end

local function TweenButtonToRestingScale(p, p2: number)
	TweenService:Create(p, tweenInfo, {
		Size = MultiplyUdim2(GetButtonRestingSize(p), p2) -- inferred equivalent call
	}):Play()
end

fn = function(p, p2)
	TrackButtonTouchEnd(p, p2) -- inferred equivalent call
	TweenButtonToRestingScale(p, 1)
end

local function GetCurrentEquipped()
	return Promise.new(function(callback, callback2)
		local currentEquipped = InventoryController.getCurrentEquipped()

		if currentEquipped then
			callback(currentEquipped)
		else
			callback2("Failed to fetch current equipped")
		end
	end):catch(warn)
end

local function SetInteractIcon(visible: boolean, visible2: boolean) -- 3 equivalent calls inferred from this helper
	v12.Interact.Defuse.Visible = visible
	v12.Interact.Use.Visible = visible2
	SetButtonVisibility("Interact", visible or visible2) -- inferred equivalent call
end

local function UpdateInteractButton()
	if not v12 then
		return
	end

	if v12.Shop.Visible then
		SetInteractIcon(false, false) -- inferred equivalent call
	else
		local v15 = CollectionService:GetTagged("Bomb")[1]
		local defused = v15
			and (v15:GetAttribute("Defused") or v15:GetAttribute("Exploding") or v15:GetAttribute("Exploded"))
		local v16 = v6 or LocalPlayer:GetAttribute("IsDefusingBomb") == true
		local v17 = v15
			and not defused
			and HoverBomb.IsDefuseAllowed()
			and (v16 or v15:GetAttribute("CanDefuse") and not v15:GetAttribute("IsGettingDefused"))
		local v18 = #CollectionService:GetTagged("IsHoveringInteractable") > 0
		local v19 = GetHoveredHostage() ~= nil -- inferred equivalent call
		local hoveredBreakableDoor = GetHoveredBreakableDoor()
		local v20

		if hoveredBreakableDoor == nil then
			v20 = false
		else
			v20 = #hoveredBreakableDoor > 0
		end

		if v17 then
			SetInteractIcon(true, false) -- inferred equivalent call
		else
			SetInteractIcon(false, v18 or v19 or v20) -- inferred equivalent call
		end
	end
end

local function HasAlternativeAction(p)
	if not (p and p.Properties) then
		return false
	end

	local properties = p.Properties

	if
		properties.HasScope == true
		or properties.HasSuppressor == true
		or (properties.ShootingOptions == "Burst" or properties.ShootingOptions == "Revolver")
	then
		return true
	end

	local v15 = properties.Type == "Equipment"
	local v16 = properties.Class == "Grenade" or properties.Slot == "Grenade"

	if (v15 or v16) and GameState.GetState() ~= "Buy Period" then
		return true
	end

	return false
end

local function UpdateAlternativeActionButton() -- 1 equivalent call inferred from this helper
	if SpectateController.IsLocalPlayerDead() then
		SetButtonVisibility("AlternativeAction", false) -- inferred equivalent call
	else
		SetButtonVisibility("AlternativeAction", HasAlternativeAction(InventoryController.getCurrentEquipped())) -- inferred equivalent call
	end
end

local function CanDropCurrentEquipped(p)
	if not p or SpectateController.IsLocalPlayerDead() or IsTutorialMode() then
		return false
	end

	local properties = p.Properties

	if not properties then
		return false
	end

	local v15

	if properties.Class == "Melee" then
		v15 = workspace:GetAttribute("VIPKnifeDropEnabled") == true
	else
		v15 = false
	end

	if
		not (properties.Droppable or v15)
		or (GameState.GetState() == "Warmup" or workspace:GetAttribute("Gamemode") == "Deathmatch")
	then
		return false
	end

	return properties.Class ~= "C4" or not p.IsPlanting
end

local function UpdateDropButton() -- 1 equivalent call inferred from this helper
	SetButtonVisibility("Drop", CanDropCurrentEquipped(InventoryController.getCurrentEquipped())) -- inferred equivalent call
end

local function UpdateReloadButton() -- 1 equivalent call inferred from this helper
	if SpectateController.IsLocalPlayerDead() then
		SetButtonVisibility("Reload", false) -- inferred equivalent call
	else
		local currentEquipped = InventoryController.getCurrentEquipped()
		SetButtonVisibility("Reload", currentEquipped ~= nil and currentEquipped.Properties.Class == "Weapon") -- inferred equivalent call
	end
end

local function UpdatePingButton()
	if LocalPlayer:GetAttribute("IsSpectating") == true or SpectateController.IsLocalPlayerDead() then
		SetButtonVisibility("Ping", false) -- inferred equivalent call
	else
		SetButtonVisibility("Ping", workspace:GetAttribute("Gamemode") ~= "Deathmatch") -- inferred equivalent call
	end
end

local function UpdateInspectButton()
	if not v12:FindFirstChild("Inspect") then
		return
	end

	if SpectateController.IsLocalPlayerDead() then
		SetButtonVisibility("Inspect", false) -- inferred equivalent call
	else
		local currentEquipped = InventoryController.getCurrentEquipped()
		local animation = currentEquipped and currentEquipped.Viewmodel and currentEquipped.Viewmodel.Animation
		SetButtonVisibility( -- inferred equivalent call
			"Inspect",
			(animation ~= nil and animation.hasInspectAnimation ~= nil and animation:hasInspectAnimation()) == true
		)
	end
end

local function GetRarityRGB(p) -- 2 equivalent calls inferred from this helper
	return math.floor(p.Color.R * 255), math.floor(p.Color.G * 255), (math.floor(p.Color.B * 255))
end

local function BindPressFeedback(p) -- 1 equivalent call inferred from this helper
	p.InputBegan:Connect(function(input)
		if not IsPressInput(input) then -- inferred equivalent call
			return
		end

		if IsNewTouch(input) then -- inferred equivalent call
			TrackButtonTouchStart(p, input)

			if v8[p] == input then
				TweenButtonToRestingScale(p, 0.9)
			end
		end
	end)
end

local function BindTapButton(p, callback) -- 10 equivalent calls inferred from this helper
	BindPressFeedback(p) -- inferred equivalent call
	p.InputEnded:Connect(function(input)
		if not IsPressInput(input) then -- inferred equivalent call
			return
		end

		TweenButtonToRestingScale(p, 1)

		if ValidateButtonTouch(p, input) then -- inferred equivalent call
			TrackButtonTouchEnd(p, input) -- inferred equivalent call
			callback()
		else
			TrackButtonTouchEnd(p, input) -- inferred equivalent call
		end
	end)
end

function MobileButtons.HighlightButton(childName: string, p: number)
	local button = v12 and v12:FindFirstChild(childName)

	if not button or not button:IsA("TextButton") or v8[button] then
		return
	end

	local size = GetButtonRestingSize(button) -- inferred equivalent call
	local v15 = math.max(1, (math.round(p / 1)))
	button.Size = size
	local tween = TweenService:Create(
		button,
		TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, v15 - 1, true),
		{ Size = MultiplyUdim2(size, 1.2) } -- inferred equivalent call
	)
	tween.Completed:Once(function(p2)
		if p2 == Enum.PlaybackState.Completed then
			button.Size = GetButtonRestingSize(button) -- inferred equivalent call
		end
	end)
	tween:Play()
end

function MobileButtons.setupButton(data)
	Profiler.mark("UI.MobileButtons.SetupButton")
	SetButtonRestingSize(data) -- inferred equivalent call
	data.InputBegan:Connect(function(input)
		if not IsPressInput(input) then -- inferred equivalent call
			return
		end

		if IsNewTouch(input) then -- inferred equivalent call
			if not BUTTONS_WITH_EXPLICIT_HANDLERS[data.Name] then
				TrackButtonTouchStart(data, input)
			end

			if v8[data] == input then
				TweenButtonToRestingScale(data, 0.9)
			end
		end
	end)

	if not BUTTONS_EXCLUDED_FROM_CLEARING[data.Name] then
		data.InputChanged:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			if v8[data] == input and not IsInputInsideButton(data, input) then -- inferred equivalent call
				TrackButtonTouchEnd(data, input) -- inferred equivalent call
				TweenButtonToRestingScale(data, 1)
			end
		end)
	end

	data.InputEnded:Connect(function(input)
		if not IsPressInput(input) then -- inferred equivalent call
			return
		end

		TweenButtonToRestingScale(data, 1)

		if not BUTTONS_WITH_EXPLICIT_INPUT_ENDED[data.Name] then
			TrackButtonTouchEnd(data, input) -- inferred equivalent call
		end
	end)
end

function MobileButtons.Initialize(_, instance)
	Profiler.mark("UI.MobileButtons.Initialize")
	v12 = instance
	parent = instance.Parent
	v5 = nil
	v6 = false
	local screenGui = instance:FindFirstAncestorOfClass("ScreenGui")
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

	if screenGui and playerGui then
		local parent3 = playerGui:FindFirstChild("MobileControlsGui")

		if not (parent3 and parent3:IsA("ScreenGui")) then
			parent3 = Instance.new("ScreenGui")
			parent3.Name = "MobileControlsGui"
			parent3.ResetOnSpawn = false
			parent3.IgnoreGuiInset = screenGui.IgnoreGuiInset
			parent3.ScreenInsets = screenGui.ScreenInsets
			parent3.SafeAreaCompatibility = screenGui.SafeAreaCompatibility
			parent3.ClipToDeviceSafeArea = screenGui.ClipToDeviceSafeArea
			parent3.ZIndexBehavior = screenGui.ZIndexBehavior
			parent3.DisplayOrder = 1000
			parent3.Parent = playerGui
		end

		v13 = parent3
		instance.Parent = parent3
		local guiObject = parent
		local parent2 = guiObject and guiObject.Parent

		local function syncHostVisibility()
			local enabled = screenGui.Enabled
				and (parent2 == nil or not parent2:IsA("GuiObject") or parent2.Visible)
				and (guiObject == nil or (not guiObject:IsA("GuiObject") or guiObject.Visible))

			if parent3.Enabled ~= enabled then
				parent3.Enabled = enabled
			end
		end

		screenGui:GetPropertyChangedSignal("Enabled"):Connect(syncHostVisibility)

		if parent2 and parent2:IsA("GuiObject") then
			parent2:GetPropertyChangedSignal("Visible"):Connect(syncHostVisibility)
		end

		if guiObject and guiObject:IsA("GuiObject") then
			guiObject:GetPropertyChangedSignal("Visible"):Connect(syncHostVisibility)
		end

		local enabled = screenGui.Enabled
			and (parent2 == nil or not parent2:IsA("GuiObject") or parent2.Visible)
			and (guiObject == nil or (not guiObject:IsA("GuiObject") or guiObject.Visible))

		if parent3.Enabled ~= enabled then
			parent3.Enabled = enabled
		end
	end

	for _, button in ipairs(v12:GetChildren()) do
		if button:IsA("TextButton") then
			SetButtonRestingSize(button, button.Size) -- inferred equivalent call
		end

		SetToggledIndicator(button, false) -- inferred equivalent call
	end

	if not v then
		v12.Visible = false
		return
	end

	Loadout.Initialize(v12, function(childName: string, flag: boolean)
		local v15 = flag and LocalPlayer:GetAttribute("IsSpectating") ~= true
		local child = v12:FindFirstChild(childName)

		if child then
			child.Visible = v15 and not v10[childName]
		end
	end)
	local parent2 = parent and parent.Parent
	local top = parent2 and parent2:FindFirstChild("Top")
	local bombDefusal = top and top:FindFirstChild("Bomb Defusal")

	if bombDefusal then
		bombDefusal.Size = UDim2.new(0.6, 0, 0.75, 0)
	end

	v12.Jump.InputBegan:Connect(function(input)
		if not (IsPressInput(input) and input.UserInputState == Enum.UserInputState.Begin) then -- inferred equivalent call
			return
		end

		TrackButtonTouchStart(v12.Jump, input)

		if ValidateButtonTouch(v12.Jump, input) then -- inferred equivalent call
			TouchIntent.onTap(input, CharacterController.jump)
		end
	end)

	local function fn2()
		CharacterController.crouch(not CharacterController.GetCrouchState())
	end

	BindTapButton(v12.Crouch, fn2) -- inferred equivalent call

	local function fn3()
		if not LocalPlayer:GetAttribute("IsPlayerChatting") then
			CharacterController.walk(not CharacterController.GetWalkState())
		end
	end

	BindTapButton(v12.ToggleWalk, fn3) -- inferred equivalent call
	v12.Drop.InputEnded:Connect(function(input)
		if not IsPressInput(input) then -- inferred equivalent call
			return
		end

		local validateButtonTouch = ValidateButtonTouch(v12.Drop, input) -- inferred equivalent call
		TrackButtonTouchEnd(v12.Drop, input) -- inferred equivalent call

		if not validateButtonTouch then
			return
		end

		Promise.new(function(callback, callback2)
			local currentEquipped = InventoryController.getCurrentEquipped()

			if currentEquipped then
				callback(currentEquipped)
			else
				callback2("Failed to fetch current equipped")
			end
		end):catch(warn):andThen(function(object)
			if object and CanDropCurrentEquipped(object) then
				local skinInformation = Skins.GetSkinInformation(object.Name, object.Skin)
				assert(
					skinInformation,
					"Skin data not found for weapon: " .. object.Name .. " and skin: " .. object.Skin
				)
				local rarityRGB, v15, v16 = GetRarityRGB(Rarities[skinInformation.rarity]) -- inferred equivalent call

				if object:drop() then
					Router.broadcastRouter(
						"CreateNotification",
						"Item Dropped",
						`You dropped your <font color = "rgb({rarityRGB}, {v15}, {v16})"><b>{object.Name} | {object.Skin}</b></font>`,
						2
					)
				end
			end
		end)
	end)

	local function fn4()
		Promise.new(function(callback, callback2)
			local currentEquipped = InventoryController.getCurrentEquipped()

			if currentEquipped then
				callback(currentEquipped)
			else
				callback2("Failed to fetch current equipped")
			end
		end):catch(warn):andThen(function(object)
			if object then
				object:reload()
			end
		end)
	end

	BindTapButton(v12.Reload, fn4) -- inferred equivalent call
	v12.Shoot.Active = true
	local flag = false

	local function ProcessEndShoot(p, flag2: boolean?)
		if p ~= v2 or not flag2 and p.UserInputState ~= Enum.UserInputState.End then
			return
		end

		v2 = nil

		if not flag then
			return
		end

		flag = false
		MobileAutoShootController.SetManualFireHeld(false)
		TweenButtonToRestingScale(v12.Shoot, 1)
		Promise.new(function(callback, callback2)
			local currentEquipped = InventoryController.getCurrentEquipped()

			if currentEquipped then
				callback(currentEquipped)
			else
				callback2("Failed to fetch current equipped")
			end
		end):catch(warn):andThen(function(object)
			if not object then
				return
			end

			if object.Properties.Class == "Weapon" then
				if object.Properties.ShootingOptions ~= "Revolver" then
					object.IsFireHeld = false
					return
				end

				local primary = object.Properties.FireModes and object.Properties.FireModes.Primary

				if not primary or primary.CancelOnRelease ~= false then
					object:cancelRevolverCharge(false)
					return
				end

				object.IsFireHeld = false
				object.FireInputBinding = nil
			elseif object.Properties.Class == "Melee" then
				object.IsFireHeld = false
			elseif object.Properties.Class == "C4" then
				object:cancel()
			elseif object.Properties.Slot == "Grenade" then
				object:Throw("Far")
			end
		end)
	end

	v12.Shoot.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1
			or v2
			or not IsNewTouch(input) -- inferred equivalent call
		then
			return
		end

		v2 = input

		if
			LocalPlayer:GetAttribute("IsPlayerChatting")
			or SpectateController.IsLocalPlayerDead()
			or not LocalPlayer.Character
			or GameState.GetState() == "Buy Period"
		then
			return
		end

		Router.broadcastRouter("Cancel Defuse Bomb")
		flag = true
		MobileAutoShootController.SetManualFireHeld(true)
		TweenButtonToRestingScale(v12.Shoot, 0.9)
		Promise.new(function(callback, callback2)
			local currentEquipped = InventoryController.getCurrentEquipped()

			if currentEquipped then
				callback(currentEquipped)
			else
				callback2("Failed to fetch current equipped")
			end
		end):catch(warn):andThen(function(object)
			if not object then
				return
			end

			if object.Properties.Class == "Weapon" then
				if object.Properties.ShootingOptions == "Revolver" then
					object:startRevolverCharge(nil)
				elseif object.AlternativeShootingOption == "Burst" then
					if object.IsBurstShooting then
						return
					end

					object.IsFireHeld = true
					object:fireBurst()
				else
					object.IsFireHeld = true
					object:shoot()
				end
			elseif object.Properties.Class == "Melee" then
				object.IsFireHeld = true
				object:shoot()
			elseif object.Properties.Class == "C4" then
				object:shoot()
			elseif object.Properties.Slot == "Grenade" then
				object:StartThrow()
			end
		end)
	end)
	v12.Shoot.InputEnded:Connect(ProcessEndShoot)
	v12.Shoot.InputChanged:Connect(function(input)
		if input == v2 and input.UserInputType == Enum.UserInputType.Touch then
			CameraInput.addTouchMove(Vector2.new(input.Delta.X, input.Delta.Y))
		end
	end)
	v12.AlternativeAction.Active = true

	local function ProcessEndAlternativeAction(p, flag2: boolean?)
		if p ~= v3 or not flag2 and p.UserInputState ~= Enum.UserInputState.End then
			return
		end

		v3 = nil
		TweenButtonToRestingScale(v12.AlternativeAction, 1)
		Promise.new(function(callback, callback2)
			local currentEquipped = InventoryController.getCurrentEquipped()

			if currentEquipped then
				callback(currentEquipped)
			else
				callback2("Failed to fetch current equipped")
			end
		end):catch(warn):andThen(function(object)
			if not object then
				return
			end

			local properties = object.Properties

			if properties.ShootingOptions == "Revolver" then
				object:stopRevolverSecondaryFire()
				return
			end

			if properties.Slot ~= "Grenade" or GameState.GetState() == "Buy Period" then
				return
			end

			if object.ThrowStarted and not object.ThrowFinished then
				object:Throw("Near")
			end
		end)
	end

	v12.AlternativeAction.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1
			or v3
			or not IsNewTouch(input) -- inferred equivalent call
		then
			return
		end

		v3 = input
		TweenButtonToRestingScale(v12.AlternativeAction, 0.9)
		Promise.new(function(callback, callback2)
			local currentEquipped = InventoryController.getCurrentEquipped()

			if currentEquipped then
				callback(currentEquipped)
			else
				callback2("Failed to fetch current equipped")
			end
		end):catch(warn):andThen(function(object)
			if not object then
				return
			end

			if
				LocalPlayer:GetAttribute("IsPlayerChatting")
				or SpectateController.IsLocalPlayerDead()
				or CaseSceneController.IsActive()
				or BlackMarketSceneController.IsActive()
				or InspectController.IsActive()
			then
				return
			end

			local properties = object.Properties

			if properties.ShootingOptions == "Revolver" then
				object:startRevolverSecondaryFire(nil)
			elseif properties.Class == "Grenade" or properties.Slot == "Grenade" then
				if GameState.GetState() ~= "Buy Period" then
					object:StartThrow()
				end
			elseif properties.HasScope then
				object:scope(true)
			elseif properties.HasSuppressor then
				if object.IsSuppressed then
					object:removeSuppressor()
				else
					object:addSuppressor()
				end
			else
				if properties.ShootingOptions == "Burst" then
					object:updateFireMode()
					return
				end

				if properties.Type ~= "Equipment" then
					return
				end

				if GameState.GetState() ~= "Buy Period" then
					object:shoot(true)
				end
			end
		end)
	end)
	v12.AlternativeAction.InputEnded:Connect(ProcessEndAlternativeAction)
	v12.AlternativeAction.InputChanged:Connect(function(input)
		if input == v3 and input.UserInputType == Enum.UserInputType.Touch then
			CameraInput.addTouchMove(Vector2.new(input.Delta.X, input.Delta.Y))
		end
	end)
	v12.Interact.Active = true
	v5 = nil
	v12.Interact.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1
			or v5
			or not IsNewTouch(input) -- inferred equivalent call
		then
			return
		end

		v5 = input
		TrackButtonTouchStart(v12.Interact, input)
		local v15 = CollectionService:GetTagged("Bomb")[1]

		if
			v15
			and v15:GetAttribute("CanDefuse")
			and not v15:GetAttribute("Defused")
			and HoverBomb.IsDefuseAllowed()
		then
			v6 = true
			Router.broadcastRouter("Start Defuse Bomb")
		else
			local hoveredHostage = GetHoveredHostage() -- inferred equivalent call

			if hoveredHostage then
				local team = LocalPlayer:GetAttribute("Team")

				if
					not LocalPlayer:GetAttribute("IsCarryingHostage")
					and not LocalPlayer:GetAttribute("IsRescuingHostage")
					and team == "Counter-Terrorists"
				then
					local rescuingPlayer = hoveredHostage:GetAttribute("RescuingPlayer")
					local carryingPlayer = hoveredHostage:GetAttribute("CarryingPlayer")

					if (not rescuingPlayer or rescuingPlayer == LocalPlayer.Name) and not carryingPlayer then
						Router.broadcastRouter("Start Rescue Hostage")
						return
					end
				end
			end

			local hoveredBreakableDoor = GetHoveredBreakableDoor()

			if #hoveredBreakableDoor > 0 then
				for _, model in hoveredBreakableDoor do
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

				local v16 = tagged[1]
				local weapon = v16:GetAttribute("Weapon")
				local skin = v16:GetAttribute("Skin")

				if weapon == "C4" and LocalPlayer:GetAttribute("Team") ~= "Terrorists" then
					return
				end

				if v16:GetAttribute("CanPickup") then
					local skinInformation = Skins.GetSkinInformation(weapon, skin)

					if skinInformation then
						local rarityRGB, v17, v18 = GetRarityRGB(Rarities[skinInformation.rarity]) -- inferred equivalent call
						Router.broadcastRouter(
							"CreateNotification",
							"Item Picked Up",
							`You picked up a <font color = "rgb({rarityRGB}, {v17}, {v18})"><b>{weapon:find("Zeus") and "Taser" or weapon} | {skin}</b></font>`,
							2
						)
					end

					Remotes.Inventory.PickupWeapon.Send({
						Identity = v16.Name,
						AllowAutoEquip = true
					})
				end
			end
		end
	end)

	local function ProcessEndInteract(input)
		if input ~= v5 then
			return
		end

		local v15 = v6 or LocalPlayer:GetAttribute("IsDefusingBomb") == true
		v5 = nil
		v6 = false
		TrackButtonTouchEnd(v12.Interact, input) -- inferred equivalent call

		if CollectionService:GetTagged("Bomb")[1] and v15 then
			Router.broadcastRouter("Cancel Defuse Bomb")
		elseif LocalPlayer:GetAttribute("IsRescuingHostage") then
			Router.broadcastRouter("Cancel Rescue Hostage")
		end
	end

	v12.Interact.InputEnded:Connect(ProcessEndInteract)
	v12.Interact.InputChanged:Connect(function(input)
		if input == v5 and input.UserInputType == Enum.UserInputType.Touch then
			CameraInput.addTouchMove(Vector2.new(input.Delta.X, input.Delta.Y))
		end
	end)
	BindTapButton(v12.Shop, BuyMenu.toggleFrame) -- inferred equivalent call

	local function ProcessEndScoreboard(input, flag2: boolean?) -- 2 equivalent calls inferred from this helper
		if input ~= v4 or not flag2 and input.UserInputState ~= Enum.UserInputState.End then
			return
		end

		v4 = nil
		TweenButtonToRestingScale(v12.ToggleScoreboard, 1)
		TrackButtonTouchEnd(v12.ToggleScoreboard, input) -- inferred equivalent call
	end

	v12.ToggleScoreboard.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1
			or v4
			or LocalPlayer:GetAttribute("IsPlayerChatting")
			or not IsNewTouch(input) -- inferred equivalent call
		then
			return
		end

		v4 = input
		TrackButtonTouchStart(v12.ToggleScoreboard, input)
		TweenButtonToRestingScale(v12.ToggleScoreboard, 0.9)
	end)
	v12.ToggleScoreboard.InputEnded:Connect(function(input)
		if input ~= v4 then
			return
		end

		local validateButtonTouch = ValidateButtonTouch(v12.ToggleScoreboard, input) -- inferred equivalent call
		ProcessEndScoreboard(input, true) -- inferred equivalent call

		if not validateButtonTouch then
			return
		end

		if Leaderboard.IsOpen() then
			Leaderboard.closeFrame()
		else
			Leaderboard.openFrame()
		end
	end)

	local function fn5()
		if IsTutorialMode() then
			return
		end

		Chat.CloseChat()
		Top.ToggleMenu()
	end

	BindTapButton(v12.Menu, fn5) -- inferred equivalent call
	local chat = v12.Chat

	local function fn6()
		if not v7 then
			return
		end

		Chat.ToggleChat(ChatModes.Modes.All)
	end

	BindTapButton(chat, fn6) -- inferred equivalent call
	local vip = v12:FindFirstChild("VIP")

	if vip and vip:IsA("TextButton") then
		local function fn7()
			local v15

			if RunService:IsStudio() then
				v15 = true
			elseif workspace:GetAttribute("IsVIPServer") == true then
				v15 = LocalPlayer:GetAttribute("CanUseVIPMenu") == true
			else
				v15 = false
			end

			if v15 and not LocalPlayer:GetAttribute("IsPlayerChatting") then
				local VIPMenu = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.VIPMenu)
				VIPMenu.toggleFrame()
			end
		end

		BindTapButton(vip, fn7) -- inferred equivalent call
	end

	local function fn7()
		if
			LocalPlayer:GetAttribute("IsPlayerChatting")
			or CaseSceneController.IsActive()
			or BlackMarketSceneController.IsActive()
			or InspectController.IsActive()
		then
			return
		end

		local currentEquipped = InventoryController.getCurrentEquipped()

		if currentEquipped then
			currentEquipped:inspect()
			HintController:clearHint("Inspect")
		end
	end

	BindTapButton(v12.Inspect, fn7) -- inferred equivalent call

	local function fn8()
		if LocalPlayer:GetAttribute("IsSpectating") then
			TeamSelection.openFrame()
		elseif LocalPlayer.Character then
			TeamSelection.ToggleTeamSelection()
		end
	end

	BindTapButton(v12.SwapTeam, fn8) -- inferred equivalent call
	local ping = v12.Ping

	local function fn9()
		if
			workspace:GetAttribute("Gamemode") == "Deathmatch"
			or DataController.Get(LocalPlayer, "Settings.Game.HUD.Player Pings") == "Disabled"
			or not CharacterResolver.isAliveCharacter(LocalPlayer.Character)
		then
			return
		end

		local pingRaycastResult = GetPingRaycastResult(LocalPlayer.Character)

		if not pingRaycastResult then
			return
		end

		local weaponName, weaponSkin, weaponIdentity = GetWeaponDataFromInstance(pingRaycastResult.Instance)

		if weaponName and weaponSkin and weaponIdentity then
			Remotes.Ping.CreatePlayerPositionPing.Send({
				Position = pingRaycastResult.Position,
				WeaponIdentity = weaponIdentity,
				WeaponName = weaponName,
				WeaponSkin = weaponSkin,
				IsDanger = false
			})
		else
			Remotes.Ping.CreatePlayerPositionPing.Send({
				IsDanger = tick() - now < 0.5,
				Position = pingRaycastResult.Position
			})
		end

		now = tick()
	end

	BindTapButton(ping, fn9) -- inferred equivalent call

	for _, button in ipairs(v12:GetChildren()) do
		if button:IsA("TextButton") and button.Name ~= "Shoot" and button.Name ~= "AlternativeAction" then
			MobileButtons.setupButton(button)
		end
	end

	RunServiceController.BindToHeartbeat("UI.MobileButtons.UpdateVisibility", function()
		Profiler.mark("UI.MobileButtons.Heartbeat")

		if v12 then
			local visible2 = GetDesiredFrameVisibility(nil)
			local visible = v12.Visible
			v12.Visible = visible2
			local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true

			if visible2 and (not visible or v14 ~= isSpectating) then
				UpdateButtonVisibilityForSpectate(isSpectating)
			end

			v14 = isSpectating
		end

		if not v12.Visible then
			return
		end

		local v15 = LocalPlayer:GetAttribute("IsSpectating") ~= true

		if v15 then
			if LocalPlayer:GetAttribute("BuyMenu") == true then
				v15 = IsInBuyArea(LocalPlayer) and not TutorialPurchaseLock.isBuyMenuLocked(LocalPlayer)
			else
				v15 = false
			end
		end

		SetButtonVisibility("Shop", v15) -- inferred equivalent call
		local menu = IsTutorialMode() and v12:FindFirstChild("Menu")

		if menu then
			menu.Visible = false
		end

		local v16

		if RunService:IsStudio() then
			v16 = true
		elseif workspace:GetAttribute("IsVIPServer") == true then
			v16 = LocalPlayer:GetAttribute("CanUseVIPMenu") == true
		else
			v16 = false
		end

		SetButtonVisibility("VIP", v16 and not IsTutorialMode()) -- inferred equivalent call
		UpdateInteractButton()
		UpdateInspectButton()
		UpdateReloadButton() -- inferred equivalent call
		UpdateDropButton() -- inferred equivalent call
		UpdatePingButton()
		UpdateAlternativeActionButton() -- inferred equivalent call
		UpdateToggledIndicators()
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == v2 or input == v3 or input == v5 then
			CameraInput.addTouchMove(Vector2.new(input.Delta.X, input.Delta.Y))
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if IsPressInput(input) then -- inferred equivalent call
			local function fn10(callback, callback2)
				local currentEquipped = InventoryController.getCurrentEquipped()

				if currentEquipped then
					callback(currentEquipped)
				else
					callback2("Failed to fetch current equipped")
				end
			end

			if input == v2 then
				v2 = nil

				if flag then
					flag = false
					MobileAutoShootController.SetManualFireHeld(false)
					TweenButtonToRestingScale(v12.Shoot, 1)
					Promise.new(fn10):catch(warn):andThen(function(object)
						if not object then
							return
						end

						if object.Properties.Class == "Weapon" then
							if object.Properties.ShootingOptions ~= "Revolver" then
								object.IsFireHeld = false
								return
							end

							local primary = object.Properties.FireModes and object.Properties.FireModes.Primary

							if not primary or primary.CancelOnRelease ~= false then
								object:cancelRevolverCharge(false)
								return
							end

							object.IsFireHeld = false
							object.FireInputBinding = nil
						elseif object.Properties.Class == "Melee" then
							object.IsFireHeld = false
						elseif object.Properties.Class == "C4" then
							object:cancel()
						elseif object.Properties.Slot == "Grenade" then
							object:Throw("Far")
						end
					end)
				end
			end

			if input == v3 then
				v3 = nil
				TweenButtonToRestingScale(v12.AlternativeAction, 1)
				Promise.new(fn10):catch(warn):andThen(function(object)
					if not object then
						return
					end

					local properties = object.Properties

					if properties.ShootingOptions == "Revolver" then
						object:stopRevolverSecondaryFire()
						return
					end

					if properties.Slot ~= "Grenade" or GameState.GetState() == "Buy Period" then
						return
					end

					if object.ThrowStarted and not object.ThrowFinished then
						object:Throw("Near")
					end
				end)
			end

			ProcessEndScoreboard(input, true) -- inferred equivalent call
			ProcessEndInteract(input)

			for k, v15 in pairs(v8) do
				if v15 == input then
					v8[k] = nil
				end
			end
		end
	end)
end

function MobileButtons.Start()
	debug.setmemorycategory("UI.MobileButtons.Start")
	Profiler.mark("UI.MobileButtons.Start")
	v12.Visible = false

	if v then
		task.spawn(function()
			v7 = CanPlayerUseChatService(LocalPlayer)

			if not v12 then
				return
			end

			local visible = GetDesiredFrameVisibility(nil)
			local _visible = v12.Visible
			v12.Visible = visible
			local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true

			if visible then
				UpdateButtonVisibilityForSpectate(isSpectating)
			end

			v14 = isSpectating
		end)
		Loadout.Start()

		if v12 then
			local visible = GetDesiredFrameVisibility(nil)
			local _visible = v12.Visible
			v12.Visible = visible
			local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true

			if visible then
				UpdateButtonVisibilityForSpectate(isSpectating)
			end

			v14 = isSpectating
		end
	end

	LocalPlayer.CharacterAdded:Connect(function()
		if not v12 then
			return
		end

		local visible = GetDesiredFrameVisibility(nil)
		local _visible = v12.Visible
		v12.Visible = visible
		local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true

		if visible then
			UpdateButtonVisibilityForSpectate(isSpectating)
		end

		v14 = isSpectating
	end)
	LocalPlayer.CharacterRemoving:Connect(function(character)
		v3 = nil
		v4 = nil
		Leaderboard.closeFrame()

		if not v12 then
			return
		end

		local visible = GetDesiredFrameVisibility(character)
		local _visible = v12.Visible
		v12.Visible = visible
		local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true

		if visible then
			UpdateButtonVisibilityForSpectate(isSpectating)
		end

		v14 = isSpectating
	end)
	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(RefreshButtonVisibility)
	local v15 = { "TeamSelection", table.unpack(v11) }
	local v16 = parent

	if v16 then
		local function watchSiblingFrame(guiObject) -- 1 equivalent call inferred from this helper
			if guiObject:IsA("GuiObject") and table.find(v15, guiObject.Name) then
				guiObject:GetPropertyChangedSignal("Visible"):Connect(RefreshButtonVisibility)

				if not v12 then
					return
				end

				local visible = GetDesiredFrameVisibility(nil)
				local _visible = v12.Visible
				v12.Visible = visible
				local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true

				if visible then
					UpdateButtonVisibilityForSpectate(isSpectating)
				end

				v14 = isSpectating
			end
		end

		for _, child in v16:GetChildren() do
			watchSiblingFrame(child) -- inferred equivalent call
		end

		v16.ChildAdded:Connect(watchSiblingFrame)
	end

	DataController.CreateListener(LocalPlayer, "MobileButtons", function(p)
		if typeof(p) ~= "table" then
			return
		end

		local v17 = Mobile.SanitizeLayout(p)
		table.clear(v10)

		for childName, v18 in pairs(v17) do
			local guiObject = v12:FindFirstChild(childName)

			if not (guiObject and guiObject:IsA("GuiObject")) then
				continue
			end

			ApplyMobileButtonLayout(guiObject, v18)
			SetButtonRestingSize(guiObject, guiObject.Size) -- inferred equivalent call

			if not v18.Enabled then
				v10[childName] = true
			end
		end

		if not v12 then
			return
		end

		local visible = GetDesiredFrameVisibility(nil)
		local _visible = v12.Visible
		v12.Visible = visible
		local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true

		if visible then
			UpdateButtonVisibilityForSpectate(isSpectating)
		end

		v14 = isSpectating
	end)
end

return MobileButtons