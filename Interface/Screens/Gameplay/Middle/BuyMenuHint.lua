local createVector = vector.create
local BuyMenuHint = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsInBuyArea = require(ReplicatedStorage.Database.Components.Common.IsInBuyArea)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local IsBotLobby = require(ReplicatedStorage.Components.Common.IsBotLobby)
local TutorialPurchaseLock = require(ReplicatedStorage.Components.Common.TutorialPurchaseLock)
local Tips = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Tips)
local HoverBomb = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.HoverBomb)
local Notification = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Notification)
require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Notification.Types)
local udim = UDim2.fromScale(0.225, 0.054)
local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local v

if table.find(GetUserPlatform(), "Mobile") == nil then
	v = false
else
	v = #GetUserPlatform() <= 1
end

local v2 = false
local v3 = false
local v4 = false
local total = 1e999
local v5 = nil
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local parent = nil
local v6 = nil
local connection = nil
local v7 = nil
local v8 = false
local now = 0
local now2 = -1e999

local function IsBuyMenuScreenOpen() -- 1 equivalent call inferred from this helper
	local buyMenu = parent and parent:FindFirstChild("BuyMenu")
	return buyMenu ~= nil and buyMenu:IsA("GuiObject") and buyMenu.Visible
end

local function IsTouchInput() -- 2 equivalent calls inferred from this helper
	return UserInputService.PreferredInput == Enum.PreferredInput.Touch
end

local function DecodeAttribute(attributeName: string)
	local attribute = LocalPlayer:GetAttribute(attributeName)

	if typeof(attribute) ~= "string" then
		return nil
	end

	local success, result = pcall(HttpService.JSONDecode, HttpService, attribute)

	if success and typeof(result) == "table" then
		return result
	end

	return nil
end

local function IsCarryingBomb()
	local slot5 = LocalPlayer:GetAttribute("Slot5")
	local result

	if typeof(slot5) ~= "string" then
		return result ~= nil and result.Weapon == "C4"
	end

	local success
	success, result = pcall(HttpService.JSONDecode, HttpService, slot5)

	if not success or typeof(result) ~= "table" then
		result = nil
	end

	return result ~= nil and result.Weapon == "C4"
end

local function IsBombEquipped() -- 1 equivalent call inferred from this helper
	local currentEquipped = LocalPlayer:GetAttribute("CurrentEquipped")
	local result

	if typeof(currentEquipped) ~= "string" then
		return result ~= nil and result.Name == "C4"
	end

	local success
	success, result = pcall(HttpService.JSONDecode, HttpService, currentEquipped)

	if not success or typeof(result) ~= "table" then
		result = nil
	end

	return result ~= nil and result.Name == "C4"
end

local function CanPromptBomb() -- 1 equivalent call inferred from this helper
	local tutorialMode = IsTutorialMode()

	if not tutorialMode then
		return tutorialMode
	end

	local slot5 = LocalPlayer:GetAttribute("Slot5")
	local result

	if typeof(slot5) == "string" then
		local success
		success, result = pcall(HttpService.JSONDecode, HttpService, slot5)

		if not success or typeof(result) ~= "table" then
			result = nil
		end
	end

	if result == nil then
		tutorialMode = false
	else
		tutorialMode = result.Weapon == "C4"
	end

	if tutorialMode then
		return tutorialMode
	end

	local currentEquipped = LocalPlayer:GetAttribute("CurrentEquipped")
	local result2

	if typeof(currentEquipped) == "string" then
		local success
		success, result2 = pcall(HttpService.JSONDecode, HttpService, currentEquipped)

		if not success or typeof(result2) ~= "table" then
			result2 = nil
		end
	end

	if result2 == nil then
		return false
	else
		return result2.Name == "C4"
	end

	return tutorialMode
end

local function IsOnTutorialStep(p: string) -- 5 equivalent calls inferred from this helper
	return IsTutorialMode() and LocalPlayer:GetAttribute("TutorialStep") == p
end

local function HasShotPracticeRifle() -- 1 equivalent call inferred from this helper
	local tutorialObjective = LocalPlayer:GetAttribute("TutorialObjective")
	return typeof(tutorialObjective) == "string" and string.find(tutorialObjective, "^Reload") ~= nil
end

local function IsStoodOnPlantArea()
	local character = LocalPlayer.Character
	local primaryPart = character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))

	if not (character and primaryPart) then
		return false
	end

	local debrises = { character, workspace.CurrentCamera }
	local debris = workspace:FindFirstChild("Debris")

	if debris then
		table.insert(debrises, debris)
	end

	raycastParams.FilterDescendantsInstances = debrises
	local raycastResult = workspace:Raycast(primaryPart.Position, createVector(-0, -5, -0), raycastParams)
	return raycastResult ~= nil
		and raycastResult.Instance:HasTag("PlantArea")
		and raycastResult.Instance:GetAttribute("Site") ~= nil
end

local v9 = {
	{
		Text = "EQUIP BOMB",
		Action = "Explosives & Traps",
		GamepadAction = "Cycle Weapons Right",
		GamepadText = "CYCLE TO THE BOMB",
		MobileText = "TAP HERE TO EQUIP BOMB",
		OnTap = function()
			InventoryController.equip(5, 1)
		end,
		IsAvailable = function()
			local v9 = v4

			if not v9 then
				return v9
			end

			local slot5 = LocalPlayer:GetAttribute("Slot5")
			local result

			if typeof(slot5) == "string" then
				local success
				success, result = pcall(HttpService.JSONDecode, HttpService, slot5)

				if not success or typeof(result) ~= "table" then
					result = nil
				end
			end

			if result == nil then
				v9 = false
			else
				v9 = result.Weapon == "C4"
			end

			return v9 and not IsBombEquipped() -- inferred equivalent call
		end
	},
	{
		Text = "HOLD TO PLANT BOMB",
		Action = "Fire",
		MobileButton = "Shoot",
		IsAvailable = function()
			local v9 = v4

			if not v9 then
				return v9
			end

			local currentEquipped = LocalPlayer:GetAttribute("CurrentEquipped")
			local result

			if typeof(currentEquipped) ~= "string" then
				return result ~= nil and result.Name == "C4"
			end

			local success
			success, result = pcall(HttpService.JSONDecode, HttpService, currentEquipped)

			if not success or typeof(result) ~= "table" then
				result = nil
			end

			return result ~= nil and result.Name == "C4"
		end
	},
	{
		Text = "HOLD TO DEFUSE BOMB",
		Action = "Use",
		MobileButton = "Interact",
		IsAvailable = function()
			local onTutorialStep = IsOnTutorialStep("DefuseB") -- inferred equivalent call

			if onTutorialStep then
				if LocalPlayer:GetAttribute("IsDefusingBomb") == true then
					return false
				else
					return (HoverBomb.GetHoverState())
				end
			end

			return onTutorialStep
		end
	},
	{
		Text = "LOOK AT THE BOMB",
		IsAvailable = function()
			local onTutorialStep = IsOnTutorialStep("DefuseB") -- inferred equivalent call

			if onTutorialStep then
				if LocalPlayer:GetAttribute("IsDefusingBomb") == true then
					return false
				else
					return (HoverBomb.IsInDefuseRange())
				end
			end

			return onTutorialStep
		end
	},
	{
		Text = "GO TO THE BOMB",
		IsAvailable = function()
			return IsOnTutorialStep("DefuseB") and LocalPlayer:GetAttribute("IsDefusingBomb") ~= true -- inferred equivalent call
		end
	},
	{
		Text = "SHOOT",
		Action = "Fire",
		MobileButton = "Shoot",
		IsAvailable = function()
			local onTutorialStep = IsOnTutorialStep("PracticeAK") -- inferred equivalent call
			return onTutorialStep and not HasShotPracticeRifle() -- inferred equivalent call
		end
	},
	{
		Text = "RELOAD",
		Action = "Reload",
		MobileButton = "Reload",
		IsAvailable = function()
			local onTutorialStep = IsOnTutorialStep("PracticeAK") -- inferred equivalent call

			if not onTutorialStep then
				return onTutorialStep
			end

			local tutorialObjective = LocalPlayer:GetAttribute("TutorialObjective")
			return typeof(tutorialObjective) == "string" and string.find(tutorialObjective, "^Reload") ~= nil
		end
	},
	{
		Text = "BUY MENU",
		Action = "Buy Menu",
		MobileButton = "Shop",
		MobileText = "TAP THE SHOP BUTTON",
		IsAvailable = function()
			local v9 = v3

			if v9 then
				if LocalPlayer:GetAttribute("BuyMenu") == true then
					return not (IsBuyMenuScreenOpen() or TutorialPurchaseLock.isBuyMenuLocked(LocalPlayer)) -- inferred equivalent call
				else
					return false
				end
			end

			return v9
		end
	}
}

local function ResolvePromptBinding(p)
	if not p.Action then
		return nil
	end

	local actionBinding = Tips.ResolveActionBinding(p.Action)

	if not actionBinding and p.GamepadAction and Tips.IsGamepadPreferred() then
		actionBinding = Tips.ResolveActionBinding(p.GamepadAction)
	end

	return actionBinding
end

local v10 = nil
local v11 = nil
local v12 = nil

local function GetPromptParts()
	local v13 = v7

	if not (v13 and v13.Parent) then
		return nil, nil
	end

	if v13 == v10 and v11 and v11.Parent == v13 and (v12 == nil or v12.Parent == v13) then
		return v11, v12
	end

	local textLabel = v13:FindFirstChild("TextLabel")
	local keybind = v13:FindFirstChild("Keybind")

	if not (textLabel and textLabel:IsA("TextLabel")) then
		warn(`[BuyMenuHint]: {v13:GetFullName()} has no TextLabel child; the prompt cannot render`)
		return nil, nil
	end

	v10 = v13
	v11 = textLabel

	if not (keybind and keybind:IsA("ImageButton")) then
		keybind = nil
	end

	v12 = keybind
	return v11, v12
end

local function RefreshPrompt()
	local v13 = v5
	local v14, v15 = GetPromptParts()

	if not (v13 and v14) then
		return
	end

	local touchInput = IsTouchInput() -- inferred equivalent call
	local mobileText

	if touchInput and v13.MobileText then
		mobileText = v13.MobileText
	elseif Tips.IsGamepadPreferred() and v13.GamepadText then
		mobileText = v13.GamepadText
	else
		mobileText = v13.Text
	end

	v14.Text = string.upper(mobileText)

	if v15 then
		local visible

		if v13.Action == nil then
			visible = false
		else
			visible = not touchInput

			if visible then
				local applyBindingToKeybind = Tips.ApplyBindingToKeybind
				local v16

				if v13.Action then
					v16 = Tips.ResolveActionBinding(v13.Action)

					if not v16 and v13.GamepadAction and Tips.IsGamepadPreferred() then
						v16 = Tips.ResolveActionBinding(v13.GamepadAction)
					end
				end

				visible = applyBindingToKeybind(v15, v16)
			end
		end

		v15.Visible = visible
	end

	local tapTarget = v7 and v7:FindFirstChild("TapTarget")

	if tapTarget and tapTarget:IsA("GuiObject") then
		tapTarget.Visible = touchInput and v13.OnTap ~= nil
	end
end

local function HighlightMobileButton(p)
	if not p.MobileButton then
		return
	end

	now2 = os.clock()

	if UserInputService.PreferredInput ~= Enum.PreferredInput.Touch then
		return
	end

	local MobileButtons = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.MobileButtons)
	MobileButtons.HighlightButton(p.MobileButton, 2)
end

local v13 = nil
local v14 = 0
local v15 = 0
local v16 = 0

local function LayoutKeybind()
	local v17 = v7

	if not (v17 and v17.Parent) then
		return
	end

	local v18, v19 = GetPromptParts()

	if not v18 then
		return
	end

	local x = v17.AbsoluteSize.X

	if x <= 0 then
		return
	end

	local x2 = v18.TextBounds.X
	local v20 = not (v19 and v19.Visible) and -1 or v19.AbsoluteSize.X

	if v18 == v13 and x == v14 and x2 == v15 and v20 == v16 then
		return
	end

	v13 = v18
	v14 = x
	v15 = x2
	v16 = v20
	local v21 = x2 / x

	if not v19 or v20 < 0 then
		v18.Position = UDim2.fromScale(0.5, 0.5)
		return
	end

	local v22 = v20 / x
	local v23 = 0.5 - (v22 + 0.02 + v21) / 2
	v19.Position = UDim2.fromScale(v23 + v22 * v19.AnchorPoint.X, 0.5)
	v18.Position = UDim2.fromScale(v23 + v22 + 0.02 + v21 / 2, 0.5)
end

local function FindCommanderBox()
	if not IsTutorialMode() then
		return nil
	end

	local tutorialDialogue = parent and parent:FindFirstChild("TutorialDialogue")

	if tutorialDialogue and tutorialDialogue:IsA("GuiObject") then
		return tutorialDialogue
	end

	return nil
end

local function GetLayoutOrigin() -- 2 equivalent calls inferred from this helper
	local guiBase2d = parent

	if guiBase2d and guiBase2d:IsA("GuiBase2d") then
		return guiBase2d.AbsolutePosition
	end

	return Vector2.zero
end

local function GetTutorialCardSlot()
	local tutorialDialogue

	if IsTutorialMode() then
		tutorialDialogue = parent and parent:FindFirstChild("TutorialDialogue")

		if not (tutorialDialogue and tutorialDialogue:IsA("GuiObject")) then
			tutorialDialogue = nil
		end
	end

	if not tutorialDialogue then
		return UDim2.fromScale(0.5, 0.74)
	end

	local layoutOrigin = GetLayoutOrigin() -- inferred equivalent call
	local y = tutorialDialogue.AbsolutePosition.Y

	for _, guiObject in tutorialDialogue:GetChildren() do
		if guiObject:IsA("GuiObject") and guiObject.Visible then
			y = math.min(y, guiObject.AbsolutePosition.Y)
		end
	end

	local v17 = tutorialDialogue.AbsolutePosition.X + tutorialDialogue.AbsoluteSize.X / 2
	return UDim2.fromOffset(v17 - layoutOrigin.X, y - layoutOrigin.Y - 10)
end

local function LayoutTutorialCard()
	local v17 = v7

	if not (v8 and v17 and v17.Parent and parent) then
		return
	end

	local v18 = (1 - math.clamp((os.clock() - now) / 0.3, 0, 1)) ^ 2 * 12
	v17.AnchorPoint = Vector2.new(0.5, 1)
	v17.Position = GetTutorialCardSlot() + UDim2.fromOffset(0, v18)
	local tutorialDialogue

	if IsTutorialMode() then
		tutorialDialogue = parent and parent:FindFirstChild("TutorialDialogue")

		if not (tutorialDialogue and tutorialDialogue:IsA("GuiObject")) then
			tutorialDialogue = nil
		end
	end

	if tutorialDialogue then
		v17.ZIndex = tutorialDialogue.ZIndex
	end
end

local function CreateKeycap()
	local imageButton = Instance.new("ImageButton")
	imageButton.Name = "Keybind"
	imageButton.AutoButtonColor = false
	imageButton.Active = false
	imageButton.Image = ""
	imageButton.BackgroundColor3 = Color3.new(1, 1, 1)
	imageButton.BackgroundTransparency = 0
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.2, 0)
	uiCorner.Parent = imageButton
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Bind"
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(0.9, 0.7)
	textLabel.BackgroundTransparency = 1
	textLabel.TextScaled = true
	textLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	textLabel.TextColor3 = Color3.fromRGB(20, 20, 20)
	textLabel.ZIndex = 2
	textLabel.Parent = imageButton
	return imageButton
end

local function EnsureKeycapImage(keybind)
	for _, image in keybind:GetChildren() do
		if image.Name == "Bind" and image:IsA("ImageLabel") then
			return
		end
	end

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Bind"
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Position = UDim2.fromScale(0.5, 0.5)
	imageLabel.Size = UDim2.fromScale(0.9, 0.9)
	imageLabel.BackgroundTransparency = 1
	imageLabel.ScaleType = Enum.ScaleType.Fit
	imageLabel.Visible = false
	imageLabel.ZIndex = 3
	imageLabel.Parent = keybind
end

local function CreateTutorialCard()
	local parent2 = parent
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local assetsUi = assets and assets:FindFirstChild("UI")
	local notification = assetsUi and assetsUi:FindFirstChild("Notification")
	local keybind = notification and (notification:FindFirstChild("Keybind") or notification:FindFirstChild("Default"))

	if not (parent2 and keybind and keybind:IsA("GuiObject")) then
		return nil
	end

	local clone = keybind:Clone()
	clone.Name = "TutorialPrompt"
	clone.Size = udim
	clone.LayoutOrder = 0
	local keybind2 = clone:FindFirstChild("Keybind")

	if not (keybind2 and keybind2:IsA("ImageButton")) then
		if v6 then
			keybind2 = v6:Clone()
		else
			keybind2 = CreateKeycap()
		end

		keybind2.Name = "Keybind"
		keybind2.AnchorPoint = Vector2.new(0, 0.5)
		keybind2.Size = UDim2.fromScale(0.7, 0.7)
		keybind2.SizeConstraint = Enum.SizeConstraint.RelativeYY
		keybind2.ZIndex = 3
		keybind2.Parent = clone
	end

	EnsureKeycapImage(keybind2)
	local textLabel = clone:FindFirstChild("TextLabel")

	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.TextWrapped = false
	end

	local textButton = Instance.new("TextButton")
	textButton.Name = "TapTarget"
	textButton.BackgroundTransparency = 1
	textButton.Text = ""
	textButton.Size = UDim2.fromScale(1, 1)
	textButton.ZIndex = 10
	textButton.Visible = false
	textButton.Activated:Connect(function()
		local v17 = v5

		if v17 and v17.OnTap and IsTouchInput() then -- inferred equivalent call
			v17.OnTap()
		end
	end)
	textButton.Parent = clone
	local backgroundColor = GetPreferenceColor()

	for _, childName in { "Left", "Right" } do
		local guiObject = clone:FindFirstChild(childName)

		if guiObject and guiObject:IsA("GuiObject") then
			guiObject.BackgroundColor3 = backgroundColor
		end
	end

	if clone:IsA("CanvasGroup") then
		clone.GroupTransparency = 1
		TweenService:Create(clone, tweenInfo, { GroupTransparency = 0 }):Play()
	end

	now = os.clock()
	clone.Parent = parent2
	return clone
end

local function RemoveTutorialCard(canvasGroup)
	if not canvasGroup:IsA("CanvasGroup") then
		canvasGroup:Destroy()
		return
	end

	local tween = TweenService:Create(canvasGroup, tweenInfo, { GroupTransparency = 1 })
	tween.Completed:Once(function()
		canvasGroup:Destroy()
	end)
	tween:Play()
end

local function ResolvePrompt() -- 1 equivalent call inferred from this helper
	for _, v17 in ipairs(v9) do
		if v17.IsAvailable() then
			return v17
		end
	end

	return nil
end

local function RemoveCard() -- 8 equivalent calls inferred from this helper
	local v17 = v7
	v7 = nil

	if v8 then
		if v17 and v17.Parent then
			RemoveTutorialCard(v17)
		end
	else
		Notification.removeNotification("BuyMenuHint")
	end
end

local function ShowPrompt(p)
	local v17 = p ~= v5
	v5 = p
	v2 = p ~= nil
	local v18 = IsTutorialMode() or IsBotLobby()

	if v7 and v8 ~= v18 then
		RemoveCard() -- inferred equivalent call
	end

	if p then
		if v17 or os.clock() - now2 >= 2 then
			HighlightMobileButton(p)
		end

		if v7 and v7.Parent then
			if v17 then
				RefreshPrompt()
			end
		else
			v8 = v18

			if v8 then
				v7 = CreateTutorialCard()
			else
				v7 = Notification.createNotification("Keybind", "BuyMenuHint", string.upper(p.Text), 0)
			end

			RefreshPrompt()
		end
	elseif v7 or v17 then
		RemoveCard() -- inferred equivalent call
	end
end

local function ShouldRunUpdate()
	if not (LocalPlayer:GetAttribute("IsSpectating") ~= true and CharacterResolver.isAliveCharacter(LocalPlayer.Character)) then
		return false
	end

	if IsTutorialMode() then
		return true
	end

	if v and not IsBotLobby() then
		return false
	end

	return LocalPlayer:GetAttribute("BuyMenu") == true and workspace:GetAttribute("Gamemode") ~= "Deathmatch"
end

local function StopUpdateConnection() -- 2 equivalent calls inferred from this helper
	if connection then
		connection:Disconnect()
		connection = nil
	end

	v3 = false
	v4 = false
	total = 1e999
end

local function SyncUpdateConnection()
	if ShouldRunUpdate() then
		if connection then
			return
		end

		total = 1e999
		connection = RunServiceController.BindToHeartbeat("UI.BuyMenuHint.Update", function(p: number)
			if ShouldRunUpdate() then
				total += p

				if total >= 0.2 then
					total = 0
					v3 = LocalPlayer:GetAttribute("BuyMenu") == true and IsInBuyArea(LocalPlayer)
					v4 = CanPromptBomb() and IsStoodOnPlantArea() -- inferred equivalent call
				end

				ShowPrompt(ResolvePrompt()) -- inferred equivalent call

				if v2 then
					LayoutKeybind()
					LayoutTutorialCard()
				end
			else
				local v17 = v5 ~= nil
				v5 = nil
				v2 = false
				local v18 = IsTutorialMode() or IsBotLobby()

				if v7 and v8 ~= v18 then
					RemoveCard() -- inferred equivalent call
				end

				if v7 or v17 then
					RemoveCard() -- inferred equivalent call
				end

				StopUpdateConnection() -- inferred equivalent call
			end
		end)
	else
		local v17 = v5 ~= nil
		v5 = nil
		v2 = false
		local v18 = IsTutorialMode() or IsBotLobby()

		if v7 and v8 ~= v18 then
			RemoveCard() -- inferred equivalent call
		end

		if v7 or v17 then
			RemoveCard() -- inferred equivalent call
		end

		StopUpdateConnection() -- inferred equivalent call
	end
end

function BuyMenuHint.GetHintState()
	return v2
end

function BuyMenuHint.GetFloatingSlot()
	if not (IsTutorialMode() or IsBotLobby()) then
		return nil
	end

	local v17 = v7

	if not (v8 and v17 and v17.Parent) then
		return GetTutorialCardSlot()
	end

	local layoutOrigin = GetLayoutOrigin() -- inferred equivalent call
	return UDim2.fromOffset(
		v17.AbsolutePosition.X + v17.AbsoluteSize.X / 2 - layoutOrigin.X,
		v17.AbsolutePosition.Y - layoutOrigin.Y - 10
	)
end

function BuyMenuHint.Initialize(_, instance)
	parent = instance.Parent
	local keybind = instance:FindFirstChild("Keybind")

	if not (keybind and keybind:IsA("ImageButton")) then
		keybind = nil
	end

	v6 = keybind
	instance.Visible = false
	local v17 = v5 ~= nil
	v5 = nil
	v2 = false
	local v18 = IsTutorialMode() or IsBotLobby()

	if v7 and v8 ~= v18 then
		RemoveCard() -- inferred equivalent call
	end

	if v7 or v17 then
		RemoveCard() -- inferred equivalent call
	end

	DataController.CreateListener(LocalPlayer, "Settings.Keyboard/Mouse", function(p)
		if p then
			task.defer(RefreshPrompt)
		end
	end)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(RefreshPrompt)
	LocalPlayer:GetAttributeChangedSignal("BuyMenu"):Connect(SyncUpdateConnection)
	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(SyncUpdateConnection)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(SyncUpdateConnection)
	LocalPlayer.CharacterAdded:Connect(SyncUpdateConnection)
	LocalPlayer.CharacterRemoving:Connect(SyncUpdateConnection)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(SyncUpdateConnection)
	LocalPlayer:GetAttributeChangedSignal("Slot5"):Connect(SyncUpdateConnection)
	LocalPlayer:GetAttributeChangedSignal("CurrentEquipped"):Connect(SyncUpdateConnection)
	workspace:GetAttributeChangedSignal("ServerGamemode"):Connect(SyncUpdateConnection)
	workspace:GetAttributeChangedSignal("BotLobby"):Connect(SyncUpdateConnection)
	SyncUpdateConnection()
end

return BuyMenuHint