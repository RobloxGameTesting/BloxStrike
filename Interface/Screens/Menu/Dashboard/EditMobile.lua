local EditMobile = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Mobile = require(ReplicatedStorage.Database.Custom.GameStats.UI.Mobile)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local ApplyMobileButtonLayout = require(ReplicatedStorage.Components.Common.ApplyMobileButtonLayout)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local v = {
	["Counter-Terrorists"] = { Primary = "M4A4", Secondary = "USP-S", Melee = "CT Knife" },
	Terrorists = { Primary = "AK-47", Secondary = "Glock-18", Melee = "T Knife" }
}
local v2 = { Primary = "Rifles", Secondary = "Pistols" }
local v3 = {
	Bomb = "C4",
	Grenade1 = "HE Grenade",
	Grenade2 = "Flashbang",
	Grenade3 = "Smoke Grenade",
	Grenade4 = "Molotov"
}
local MAX_TRANSPARENCY = Mobile.MAX_TRANSPARENCY

local function TransparencyToSlider(transparency: number) -- 1 equivalent call inferred from this helper
	return (math.clamp(transparency / MAX_TRANSPARENCY, 0, 1))
end

local function SliderToTransparency(value: number) -- 1 equivalent call inferred from this helper
	return math.clamp(value, 0, 1) * MAX_TRANSPARENCY
end

local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(40, 40, 40)
local color3 = Color3.fromRGB(255, 255, 255)
local color4 = Color3.fromRGB(255, 200, 0)
local v4 = {
	{ Name = "TopLeft", Anchor = Vector2.new(0, 0), Cursor = "rbxasset://SystemCursors/SizeNWSE" },
	{ Name = "TopRight", Anchor = Vector2.new(1, 0), Cursor = "rbxasset://SystemCursors/SizeNESW" },
	{
		Name = "BottomLeft",
		Anchor = Vector2.new(0, 1),
		Cursor = "rbxasset://SystemCursors/SizeNESW"
	},
	{
		Name = "BottomRight",
		Anchor = Vector2.new(1, 1),
		Cursor = "rbxasset://SystemCursors/SizeNWSE"
	},
	{ Name = "Top", Anchor = Vector2.new(0.5, 0), Cursor = "rbxasset://SystemCursors/SizeNS" },
	{ Name = "Bottom", Anchor = Vector2.new(0.5, 1), Cursor = "rbxasset://SystemCursors/SizeNS" },
	{ Name = "Left", Anchor = Vector2.new(0, 0.5), Cursor = "rbxasset://SystemCursors/SizeEW" },
	{ Name = "Right", Anchor = Vector2.new(1, 0.5), Cursor = "rbxasset://SystemCursors/SizeEW" }
}
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local LocalPlayer = Players.LocalPlayer
local v5 = nil
local v6 = nil
local v7 = nil
local v8 = false
local v9 = false
local defaultLayout = Mobile.GetDefaultLayout()
local defaultLayout2 = Mobile.GetDefaultLayout()
local flag = false
local v10 = {}
local v11 = {}
local v12 = {}
local v13 = {}
local v14 = nil
local v15 = nil
local v16 = nil
local v17 = nil
local v18 = nil
local v19 = nil
local v20 = nil

local function IsTouchInputType(p) -- 8 equivalent calls inferred from this helper
	return p == Enum.UserInputType.Touch
end

local function IsPointerPress(input) -- 4 equivalent calls inferred from this helper
	if IsTouchInputType(input.UserInputType) or input.UserInputType == Enum.UserInputType.MouseButton1 then -- inferred equivalent call
		return input.UserInputState == Enum.UserInputState.Begin
	else
		return false
	end
end

local function IsPointerMove(p)
	return IsTouchInputType(p.UserInputType) and true or p.UserInputType == Enum.UserInputType.MouseMovement -- inferred equivalent call
end

local function IsPointerRelease(input) -- 1 equivalent call inferred from this helper
	return IsTouchInputType(input.UserInputType) and true or input.UserInputType == Enum.UserInputType.MouseButton1 -- inferred equivalent call
end

local function IsSamePointer(p, input) -- 4 equivalent calls inferred from this helper
	if p == input then
		return true
	end

	local userInputType = p.UserInputType
	local userInputType2 = input.UserInputType
	local v21 = userInputType == Enum.UserInputType.MouseMovement or userInputType == Enum.UserInputType.MouseButton1
	local v22 = userInputType2 == Enum.UserInputType.MouseMovement or userInputType2 == Enum.UserInputType.MouseButton1
	return v21 and v22
end

local v21 = nil
local v22 = nil
local v23 = nil

local function RefreshMouseCursor() -- 3 equivalent calls inferred from this helper
	local mouseIcon = v22 or v23 or v21 or ""

	if UserInputService.MouseIcon ~= mouseIcon then
		UserInputService.MouseIcon = mouseIcon
	end
end

local function SetHoveredCursor(cursor: string?) -- 7 equivalent calls inferred from this helper
	v21 = cursor
	RefreshMouseCursor() -- inferred equivalent call
end

local function SetActiveResizeCursor(cursor: string?) -- 4 equivalent calls inferred from this helper
	v22 = cursor
	RefreshMouseCursor() -- inferred equivalent call
end

local function SetActiveDragCursor(p: string?) -- 1 equivalent call inferred from this helper
	v23 = p
	RefreshMouseCursor() -- inferred equivalent call
end

local function IsMobilePlatform() -- 2 equivalent calls inferred from this helper
	local userPlatform = GetUserPlatform()
	return table.find(userPlatform, "Mobile") ~= nil and #userPlatform <= 1
end

local function CanUseVIPMenu()
	if RunService:IsStudio() then
		return true
	end

	return workspace:GetAttribute("IsVIPServer") == true and LocalPlayer:GetAttribute("CanUseVIPMenu") == true
end

local function ShouldShowMobileHUDEditor(p) -- 2 equivalent calls inferred from this helper
	return IsMobilePlatform() -- inferred equivalent call
		or UserInputService.PreferredInput == Enum.PreferredInput.Touch
		or IsTouchInputType(p or UserInputService:GetLastInputType()) -- inferred equivalent call
end

local function CopyPositionAndSize(p)
	return {
		Position = { X = p.Position.X, Y = p.Position.Y },
		Size = { X = p.Size.X, Y = p.Size.Y }
	}
end

local function DeepCopyLayout(p)
	local result = {}

	for _, v24 in ipairs(Mobile.GetButtonNames()) do
		local v25 = p[v24] or Mobile.GetDefaultButtonLayout(v24)
		local copyPositionAndSize = CopyPositionAndSize(v25)
		copyPositionAndSize.Transparency = v25.Transparency
		copyPositionAndSize.Enabled = v25.Enabled
		result[v24] = copyPositionAndSize
	end

	return result
end

local function GetInputGuiPosition(p) -- 8 equivalent calls inferred from this helper
	local guiInset = GuiService:GetGuiInset()
	return Vector2.new(p.Position.X - guiInset.X, p.Position.Y - guiInset.Y)
end

local function GetInputScreenPosition(p) -- 5 equivalent calls inferred from this helper
	return Vector2.new(p.Position.X, p.Position.Y)
end

local function SetChildFrameVisible(instance, childName: string, visible: boolean) -- 2 equivalent calls inferred from this helper
	if not instance then
		return
	end

	local frame = instance:FindFirstChild(childName)

	if frame and frame:IsA("Frame") then
		frame.Visible = visible
	end
end

local function PlayUIClick() -- 6 equivalent calls inferred from this helper
	Router.broadcastRouter("RunInterfaceSound", "UI Click")
end

local function GetEditMobileEntryButton()
	local holder = v6 and v6:FindFirstChild("Holder")
	local editMobile = holder and holder:IsA("Frame") and holder:FindFirstChild("EditMobile")

	if editMobile and editMobile:IsA("Frame") then
		return (editMobile:FindFirstChild("EditMobile"))
	end

	return nil
end

local function GetEditMobileFrame()
	local v24 = v7

	if v24 and v24.Parent then
		return v24
	end

	local v25 = v6

	if not v25 then
		return nil
	end

	local editMobile = v25:FindFirstChild("EditMobile")

	if editMobile then
		v25 = editMobile
	elseif v25.Name ~= "EditMobile" then
		v25 = editMobile
	end

	v7 = v25
	return v25
end

local function GetMenuTopFrame() -- 3 equivalent calls inferred from this helper
	local menu = v5 and v5:FindFirstChild("Menu")
	local top = menu and menu:IsA("Frame") and menu:FindFirstChild("Top")

	if top and top:IsA("Frame") then
		return top
	end

	return nil
end

local function GetEditorButtonsFrame() -- 10 equivalent calls inferred from this helper
	local v24 = v7

	if not (v24 and v24.Parent) then
		v24 = v6

		if v24 then
			local editMobile = v24:FindFirstChild("EditMobile")

			if editMobile then
				v24 = editMobile
			elseif v24.Name ~= "EditMobile" then
				v24 = editMobile
			end

			v7 = v24
		else
			v24 = nil
		end
	end

	if v24 then
		return (v24:FindFirstChild("MobileButtons"))
	end

	return nil
end

local function GetGameplayMobileButtonsFrame()
	if not v5 then
		return nil
	end

	local parent = v5.Parent
	local mobileControlsGui = parent and parent:FindFirstChild("MobileControlsGui")
	local mobileButtons = mobileControlsGui and mobileControlsGui:FindFirstChild("MobileButtons")

	if mobileButtons and mobileButtons:IsA("Frame") then
		return mobileButtons
	end

	local gameplay = v5:FindFirstChild("Gameplay")
	local middle = gameplay and gameplay:FindFirstChild("Middle")
	local mobileButtons2 = middle and middle:FindFirstChild("MobileButtons")

	if mobileButtons2 and mobileButtons2:IsA("Frame") then
		return mobileButtons2
	end

	return nil
end

local function ApplyEditorButtonLayout(childName: string)
	local editorButtonsFrame = GetEditorButtonsFrame() -- inferred equivalent call

	if not editorButtonsFrame then
		return
	end

	local guiObject = editorButtonsFrame:FindFirstChild(childName)
	local v24 = defaultLayout2[childName]

	if not (guiObject and guiObject:IsA("GuiObject") and v24) then
		return
	end

	local clone

	if v24.Enabled then
		clone = v24
	else
		clone = table.clone(v24)
		clone.Transparency = math.max(v24.Transparency, 0.75)
	end

	ApplyMobileButtonLayout(guiObject, clone)
end

local function ApplyEditorLayout() -- 3 equivalent calls inferred from this helper
	for _, v24 in ipairs(Mobile.GetButtonNames()) do
		ApplyEditorButtonLayout(v24)
	end
end

local function GetConfigureRefs()
	local frame = v15

	if not frame then
		return nil
	end

	local button = frame:FindFirstChild("Button", true)
	local enabled = frame:FindFirstChild("Enabled")

	if enabled then
		local header = enabled:FindFirstChild("Header")

		if header then
			button = header:FindFirstChild("Button") or button
		end
	end

	local transparency = frame:FindFirstChild("Transparency")
	local slider = transparency and transparency:FindFirstChild("Slider", true)

	if slider and not slider:IsA("GuiButton") then
		slider = slider:FindFirstChild("Slider")
	end

	if not (button and button:IsA("GuiButton") and slider and slider:IsA("GuiButton")) then
		return nil
	end

	local button2 = slider:FindFirstChild("Button")
	local bar = slider:FindFirstChild("Bar")

	if not (button2 and button2:IsA("GuiObject") and bar and bar:IsA("GuiObject")) then
		return nil
	end

	local amount = transparency and transparency:FindFirstChild("Amount", true)
	local title = amount and amount:FindFirstChild("Title")
	local v24 = {
		Frame = frame,
		EnabledButton = button,
		EnabledCheck = button:FindFirstChildWhichIsA("ImageLabel"),
		SliderTrack = slider,
		SliderKnob = button2,
		SliderBar = bar,
		ValueBox = 0
	}

	if not (title and title:IsA("TextBox")) then
		title = nil
	end

	v24.ValueBox = title
	return v24
end

local function GetSelectedButtonLayout()
	local v24 = v14

	if v24 then
		return v24, defaultLayout2[v24]
	end

	return nil, nil
end

local function RefreshConfigurePanel()
	local configureRefs = GetConfigureRefs()

	if not configureRefs then
		return
	end

	local v24 = v14
	local v25

	if v24 then
		v25 = defaultLayout2[v24]
	else
		v24 = nil
	end

	if not (v8 and v24 and v25) then
		configureRefs.Frame.Visible = false
		return
	end

	configureRefs.Frame.Visible = true

	if configureRefs.EnabledCheck then
		configureRefs.EnabledCheck.Visible = v25.Enabled
	end

	local transparencyToSlider = TransparencyToSlider(v25.Transparency) -- inferred equivalent call
	configureRefs.SliderBar.Size = UDim2.new(
		transparencyToSlider,
		0,
		configureRefs.SliderBar.Size.Y.Scale,
		configureRefs.SliderBar.Size.Y.Offset
	)
	configureRefs.SliderKnob.Position = UDim2.new(
		transparencyToSlider,
		0,
		configureRefs.SliderKnob.Position.Y.Scale,
		configureRefs.SliderKnob.Position.Y.Offset
	)

	if configureRefs.ValueBox and not configureRefs.ValueBox:IsFocused() then
		configureRefs.ValueBox.Text = string.format("%d%%", (math.round(transparencyToSlider * 100)))
	end
end

local function SetSelectedButtonTransparency(value: number)
	local v24 = v14
	local v25

	if v24 then
		v25 = defaultLayout2[v24]
	else
		v24 = nil
	end

	if not (v24 and v25) then
		return
	end

	local transparency = SliderToTransparency(math.round(math.clamp(value, 0, 1) / 0.01) * 0.01) -- inferred equivalent call

	if v25.Transparency == transparency then
		return
	end

	v25.Transparency = transparency
	ApplyEditorButtonLayout(v24)
	RefreshConfigurePanel()
end

local function SetSelectedButtonEnabled(enabled: boolean)
	local v24 = v14
	local v25

	if v24 then
		v25 = defaultLayout2[v24]
	else
		v24 = nil
	end

	if not (v24 and v25) then
		return
	end

	v25.Enabled = enabled
	ApplyEditorButtonLayout(v24)
	RefreshConfigurePanel()
end

local fn
local fn2

local function CreateSelectionHandle(frame, data)
	local frame2 = Instance.new("Frame")
	frame2.Name = data.Name
	frame2.BackgroundTransparency = 1
	frame2.BorderSizePixel = 0
	frame2.AnchorPoint = Vector2.new(0.5, 0.5)
	frame2.Position = UDim2.fromScale(data.Anchor.X, data.Anchor.Y)
	frame2.Size = UDim2.fromOffset(17, 17)
	frame2.ZIndex = frame.ZIndex + 2
	frame2.Active = true
	local frame3 = Instance.new("Frame")
	frame3.Name = "Square"
	frame3.AnchorPoint = Vector2.new(0.5, 0.5)
	frame3.Position = UDim2.fromScale(0.5, 0.5)
	frame3.Size = UDim2.fromOffset(7, 7)
	frame3.BackgroundColor3 = color
	frame3.BorderSizePixel = 0
	frame3.ZIndex = frame2.ZIndex
	frame3.Parent = frame2
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 1
	uiStroke.Color = color2
	uiStroke.Parent = frame3
	frame2.MouseEnter:Connect(function()
		if v8 then
			SetHoveredCursor(data.Cursor) -- inferred equivalent call
		end
	end)
	frame2.MouseLeave:Connect(function()
		if v21 == data.Cursor then
			SetHoveredCursor(nil) -- inferred equivalent call
		end
	end)
	frame2.InputBegan:Connect(function(input)
		if not (v8 and v14 and IsPointerPress(input)) then -- inferred equivalent call
			return
		end

		if v18 or v20 then
			return
		end

		fn(v14, data.Anchor, input)
		SetActiveResizeCursor(data.Cursor) -- inferred equivalent call
	end)
	frame2.Parent = frame
end

local function GetOrCreateSelectionOutline()
	if v16 and v16.Parent then
		return v16
	end

	local parent = GetEditorButtonsFrame() -- inferred equivalent call

	if not parent then
		return nil
	end

	local frame = Instance.new("Frame")
	frame.Name = "Selection"
	frame.AnchorPoint = Vector2.new(0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ZIndex = 50
	frame.Visible = false
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "Stroke"
	uiStroke.Thickness = 2
	uiStroke.Color = color3
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.LineJoinMode = Enum.LineJoinMode.Miter
	uiStroke.Parent = frame

	for _, v24 in ipairs(v4) do
		CreateSelectionHandle(frame, v24)
	end

	frame.Active = true
	frame.MouseEnter:Connect(function()
		if v8 and v14 then
			SetHoveredCursor("rbxasset://SystemCursors/SizeAll") -- inferred equivalent call
		end
	end)
	frame.MouseLeave:Connect(function()
		if v21 == "rbxasset://SystemCursors/SizeAll" then
			SetHoveredCursor(nil) -- inferred equivalent call
		end
	end)
	frame.InputBegan:Connect(function(input)
		if v8 and v14 and IsPointerPress(input) then -- inferred equivalent call
			fn2(v14, input)
		end
	end)
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "SizeLabel"
	textLabel.AnchorPoint = Vector2.new(1, 0)
	textLabel.Position = UDim2.new(1, 0, 1, 7)
	textLabel.AutomaticSize = Enum.AutomaticSize.XY
	textLabel.Size = UDim2.fromOffset(0, 0)
	textLabel.BackgroundColor3 = color4
	textLabel.BorderSizePixel = 0
	textLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Font = Enum.Font.GothamMedium
	textLabel.TextSize = 12
	textLabel.Text = ""
	textLabel.ZIndex = frame.ZIndex + 1
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingLeft = UDim.new(0, 6)
	uiPadding.PaddingRight = UDim.new(0, 6)
	uiPadding.PaddingTop = UDim.new(0, 2)
	uiPadding.PaddingBottom = UDim.new(0, 2)
	uiPadding.Parent = textLabel
	textLabel.Parent = frame
	frame.Parent = parent
	v16 = frame
	return frame
end

local function UpdateSelectionOutline()
	local selectionOutline = GetOrCreateSelectionOutline()
	local editorButtonsFrame = GetEditorButtonsFrame() -- inferred equivalent call
	local v24 = v14

	if not (selectionOutline and editorButtonsFrame) then
		return
	end

	local guiObject = v24 and editorButtonsFrame:FindFirstChild(v24)

	if not (v8 and guiObject and guiObject:IsA("GuiObject")) then
		selectionOutline.Visible = false
		return
	end

	local v25 = guiObject.AbsolutePosition - editorButtonsFrame.AbsolutePosition
	selectionOutline.Position = UDim2.fromOffset(v25.X - 4, v25.Y - 4)
	selectionOutline.Size = UDim2.fromOffset(guiObject.AbsoluteSize.X + 8, guiObject.AbsoluteSize.Y + 8)
	local sizeLabel = selectionOutline:FindFirstChild("SizeLabel")

	if sizeLabel then
		local v26 = v24 and defaultLayout2[v24]

		if v26 then
			local formatted = `%.{3}f x %.{3}f`
			sizeLabel.Text = string.format(formatted, v26.Size.X, v26.Size.Y)
		else
			sizeLabel.Text = ""
		end
	end

	selectionOutline.Visible = true
end

local renderSteppedConnection = nil

local function SelectEditorButton(p: string?) -- 3 equivalent calls inferred from this helper
	v14 = p
	RefreshConfigurePanel()

	if renderSteppedConnection then
		renderSteppedConnection:Disconnect()
		renderSteppedConnection = nil
	end

	if p and v8 then
		if GetOrCreateSelectionOutline() then
			UpdateSelectionOutline()
			renderSteppedConnection = RunService.RenderStepped:Connect(UpdateSelectionOutline)
		end
	else
		v18 = nil
		SetActiveResizeCursor(nil) -- inferred equivalent call

		if v16 then
			v16.Visible = false
		end
	end
end

local function SetupConfigurePanel(instance)
	local configure = instance:FindFirstChild("Configure")

	if not (configure and configure:IsA("Frame")) then
		warn("[MobileHUDEditor] EditMobile.Configure frame not found; transparency / enabled editing unavailable")
		return
	end

	v15 = configure
	configure.Visible = false
	local configureRefs = GetConfigureRefs()

	if not configureRefs then
		warn("[MobileHUDEditor] EditMobile.Configure is missing its Enabled button or slider parts")
		return
	end

	ActivateButton(configureRefs.EnabledButton)
	configureRefs.EnabledButton.MouseButton1Click:Connect(function()
		local v24 = v14
		local v25

		if v24 then
			v25 = defaultLayout2[v24]
		end

		if v25 then
			PlayUIClick() -- inferred equivalent call
			local enabled = not v25.Enabled
			local v26 = v14
			local v27

			if v26 then
				v27 = defaultLayout2[v26]
			else
				v26 = nil
			end

			if v26 then
				if not v27 then
					return
				end

				v27.Enabled = enabled
				ApplyEditorButtonLayout(v26)
				RefreshConfigurePanel()
			end
		end
	end)
	local sliderTrack = configureRefs.SliderTrack
	local sliderKnob = configureRefs.SliderKnob
	sliderTrack.AutoButtonColor = false

	if sliderKnob:IsA("GuiButton") then
		sliderKnob.AutoButtonColor = false
	end

	local function IsPointerInput(p) -- 1 equivalent call inferred from this helper
		return p.UserInputType == Enum.UserInputType.MouseButton1 or IsTouchInputType(p.UserInputType) -- inferred equivalent call
	end

	local function SetFromScreenX(x: number) -- 2 equivalent calls inferred from this helper
		local v24 = math.max(sliderTrack.AbsoluteSize.X, 1)
		SetSelectedButtonTransparency(math.clamp((x - sliderTrack.AbsolutePosition.X) / v24, 0, 1))
	end

	local function BeginSliderDrag(p)
		if not IsPointerInput(p) or v17 then -- inferred equivalent call
			return
		end

		v17 = p
		SetFromScreenX(GetInputGuiPosition(p).X) -- inferred equivalent call
	end

	sliderTrack.InputBegan:Connect(BeginSliderDrag)
	sliderKnob.InputBegan:Connect(BeginSliderDrag)
	UserInputService.InputChanged:Connect(function(input)
		local v24 = v17

		if not v24 then
			return
		end

		if
			input == v24
			or v24.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseMovement
		then
			SetFromScreenX(GetInputGuiPosition(input).X) -- inferred equivalent call
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		local v24 = v17

		if not v24 then
			return
		end

		if
			input == v24
			or v24.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseButton1
		then
			v17 = nil
		end
	end)
	local valueBox = configureRefs.ValueBox

	if valueBox then
		valueBox.FocusLost:Connect(function()
			local v24 = tonumber((string.gsub(valueBox.Text, "[^%d%.]", "")))

			if v24 then
				SetSelectedButtonTransparency(v24 / 100)
			end

			RefreshConfigurePanel()
		end)
	end
end

local function HideDashboardPanels()
	local v24 = v6
	local v25 = v7

	if not (v25 and v25.Parent) then
		v25 = v6

		if v25 then
			local editMobile = v25:FindFirstChild("EditMobile")

			if editMobile then
				v25 = editMobile
			elseif v25.Name ~= "EditMobile" then
				v25 = editMobile
			end

			v7 = v25
		else
			v25 = nil
		end
	end

	if not v24 then
		return
	end

	for _, guiObject in ipairs(v24:GetChildren()) do
		if not (guiObject ~= v25 and guiObject:IsA("GuiObject") and guiObject.Visible) then
			continue
		end

		v10[guiObject] = true
		guiObject.Visible = false
	end
end

local function RestoreDashboardPanels() -- 1 equivalent call inferred from this helper
	for k in pairs(v10) do
		if k.Parent then
			k.Visible = true
		end
	end

	table.clear(v10)
end

local function SetDashboardEditorVisibility(visible: boolean)
	local v24 = v7

	if not (v24 and v24.Parent) then
		v24 = v6

		if v24 then
			local editMobile = v24:FindFirstChild("EditMobile")

			if editMobile then
				v24 = editMobile
			elseif v24.Name ~= "EditMobile" then
				v24 = editMobile
			end

			v7 = v24
		else
			v24 = nil
		end
	end

	if v24 then
		v24.Visible = visible
		SetChildFrameVisible(v24, "Action", visible) -- inferred equivalent call
		SetChildFrameVisible(v24, "MobileButtons", visible) -- inferred equivalent call
	end

	local menuTopFrame = GetMenuTopFrame() -- inferred equivalent call

	if menuTopFrame then
		if visible then
			menuTopFrame.Visible = false
		elseif not (MenuState.IsInspectActive() or MenuState.IsCaseSceneActive()) then
			menuTopFrame.Visible = true
		end
	end

	if visible then
		HideDashboardPanels()
		return
	end

	RestoreDashboardPanels() -- inferred equivalent call
end

local function EnforceEditorVisibilityLock()
	if not v8 then
		return
	end

	local menuTopFrame = GetMenuTopFrame() -- inferred equivalent call

	if menuTopFrame and menuTopFrame.Visible then
		menuTopFrame.Visible = false
	end

	for k in pairs(v10) do
		if k.Visible then
			k.Visible = false
		end
	end
end

local function ConnectEditorVisibilityGuards()
	if flag then
		return
	end

	local v24 = v6
	local menuTopFrame = GetMenuTopFrame() -- inferred equivalent call

	if not (v24 or menuTopFrame) then
		return
	end

	flag = true

	if menuTopFrame then
		menuTopFrame:GetPropertyChangedSignal("Visible"):Connect(EnforceEditorVisibilityLock)
	end

	if v24 then
		local v25 = v7

		if not (v25 and v25.Parent) then
			v25 = v6

			if v25 then
				local editMobile = v25:FindFirstChild("EditMobile")

				if editMobile then
					v25 = editMobile
				elseif v25.Name ~= "EditMobile" then
					v25 = editMobile
				end

				v7 = v25
			else
				v25 = nil
			end
		end

		for _, guiObject in ipairs(v24:GetChildren()) do
			if guiObject ~= v25 and guiObject:IsA("GuiObject") then
				guiObject:GetPropertyChangedSignal("Visible"):Connect(EnforceEditorVisibilityLock)
			end
		end
	end
end

local function ClearEditorInteractionState()
	v11 = {}
	v12 = {}
	v13 = {}
	v19 = nil
	v20 = nil
	v18 = nil
	SetActiveResizeCursor(nil) -- inferred equivalent call
	SetActiveDragCursor(nil) -- inferred equivalent call
	SetHoveredCursor(nil) -- inferred equivalent call
end

local function RemoveTouchFromButton(input) -- 1 equivalent call inferred from this helper
	local v24 = v11[input]

	if not v24 then
		return nil
	end

	v11[input] = nil
	local v25 = v12[v24]

	if v25 then
		v25[input] = nil

		if next(v25) == nil then
			v12[v24] = nil
		end
	end

	return v24
end

local function GetButtonTouches(p: string)
	local v24 = v12[p]

	if not v24 then
		return {}
	end

	local result = {}

	for k in pairs(v24) do
		table.insert(result, k)
	end

	return result
end

local function UpdateEditorButtonLayout(buttonName: string, data)
	local v24 = defaultLayout2[buttonName] or Mobile.GetDefaultButtonLayout(buttonName)
	local v25 = defaultLayout2
	local clampButtonLayout = Mobile.ClampButtonLayout
	local v26 = { Position = data.Position, Size = data.Size, Transparency = 0, Enabled = 0 }
	local transparency

	if data.Transparency == nil then
		transparency = v24.Transparency
	else
		transparency = data.Transparency
	end

	v26.Transparency = transparency
	local enabled

	if data.Enabled == nil then
		enabled = v24.Enabled
	else
		enabled = data.Enabled
	end

	v26.Enabled = enabled
	v25[buttonName] = clampButtonLayout(v26)
	ApplyEditorButtonLayout(buttonName)
end

local function StartEditorDrag(buttonName: string, input)
	local v24 = defaultLayout2[buttonName]

	if not v24 then
		return
	end

	v20 = nil

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		v23 = "rbxasset://SystemCursors/SizeAll"
		local mouseIcon = v22 or v23 or v21 or ""

		if UserInputService.MouseIcon ~= mouseIcon then
			UserInputService.MouseIcon = mouseIcon
		end
	end

	v19 = {
		buttonName = buttonName,
		input = input,
		startPosition = GetInputGuiPosition(input), -- inferred equivalent call
		startLayout = CopyPositionAndSize(v24)
	}
end

local function StartEditorPinch(buttonName: string, input, scaleInput)
	local v24 = defaultLayout2[buttonName]

	if not v24 then
		return
	end

	local editorButtonsFrame = GetEditorButtonsFrame() -- inferred equivalent call

	if not editorButtonsFrame then
		return
	end

	local absoluteSize = editorButtonsFrame.AbsoluteSize

	if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
		return
	end

	local inputScreenPosition = GetInputScreenPosition(input) -- inferred equivalent call
	local absolutePosition = editorButtonsFrame.AbsolutePosition
	local lastDistance = math.max((GetInputScreenPosition(scaleInput) - inputScreenPosition).Magnitude, 1) -- inferred equivalent call
	local vector = Vector2.new(
		(inputScreenPosition.X - absolutePosition.X) / absoluteSize.X,
		(inputScreenPosition.Y - absolutePosition.Y) / absoluteSize.Y
	)
	local v25 = not (v24.Size.X > 0) and 0.5 or (vector.X - v24.Position.X) / v24.Size.X
	local v26 = not (v24.Size.Y > 0) and 0.5 or (vector.Y - v24.Position.Y) / v24.Size.Y
	v19 = nil
	v20 = {
		buttonName = buttonName,
		anchorInput = input,
		scaleInput = scaleInput,
		anchorLocalScale = Vector2.new(math.clamp(v25, 0, 1), (math.clamp(v26, 0, 1))),
		lastDistance = lastDistance,
		lastLayout = CopyPositionAndSize(v24)
	}
end

fn = function(buttonName: string, anchor: Vector2, input)
	local v24 = defaultLayout2[buttonName]

	if not v24 then
		return
	end

	v19 = nil
	v20 = nil
	v18 = {
		buttonName = buttonName,
		input = input,
		handleAnchor = anchor,
		startPosition = GetInputGuiPosition(input), -- inferred equivalent call
		startLayout = {
			Position = { X = v24.Position.X, Y = v24.Position.Y },
			Size = { X = v24.Size.X, Y = v24.Size.Y },
			Transparency = v24.Transparency,
			Enabled = v24.Enabled
		}
	}
end

local function UpdateResizeFromInput(input)
	local v24 = v18

	if v24 and IsSamePointer(input, v24.input) then -- inferred equivalent call
		local editorButtonsFrame = GetEditorButtonsFrame() -- inferred equivalent call

		if not editorButtonsFrame then
			return
		end

		local absoluteSize = editorButtonsFrame.AbsoluteSize

		if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
			return
		end

		local v25 = GetInputGuiPosition(input) - v24.startPosition -- inferred equivalent call
		local vector = Vector2.new(v25.X / absoluteSize.X, v25.Y / absoluteSize.Y)
		local startLayout = v24.startLayout
		local handleAnchor = v24.handleAnchor
		local guiObject = editorButtonsFrame:FindFirstChild(v24.buttonName)
		local anchorPoint

		if guiObject and guiObject:IsA("GuiObject") then
			anchorPoint = guiObject.AnchorPoint
		else
			anchorPoint = Vector2.new(0.5, 0.5)
		end

		local function resolveSize(p: number, p2: number, p3: number) -- 2 equivalent calls inferred from this helper
			if p >= 1 then
				return (math.clamp(p2 + p3, Mobile.MIN_SIZE, Mobile.MAX_SIZE))
			end

			if p <= 0 then
				return (math.clamp(p2 - p3, Mobile.MIN_SIZE, Mobile.MAX_SIZE))
			end

			return p2
		end

		local function resolvePosition(p: number, p2: number, p3: number, p4: number, size: number) -- 2 equivalent calls inferred from this helper
			if p >= 1 then
				return p3 + p2 * (size - p4)
			end

			if p <= 0 then
				return p3 + (1 - p2) * (p4 - size)
			end

			return p3
		end

		local size = resolveSize(handleAnchor.X, startLayout.Size.X, vector.X) -- inferred equivalent call
		local size2 = resolveSize(handleAnchor.Y, startLayout.Size.Y, vector.Y) -- inferred equivalent call
		local v26

		if guiObject == nil then
			v26 = false
		else
			v26 = guiObject:FindFirstChildWhichIsA("UIAspectRatioConstraint", true) ~= nil
		end

		if v26 and startLayout.Size.X > 0 and startLayout.Size.Y > 0 then
			local v27 = startLayout.Size.Y / startLayout.Size.X
			local v28 = handleAnchor.X ~= 0.5
			local v29 = handleAnchor.Y ~= 0.5

			if v28 and (not v29 or math.abs(v25.X) >= math.abs(v25.Y)) then
				size2 = math.clamp(size * v27, Mobile.MIN_SIZE, Mobile.MAX_SIZE)
				size = size2 / v27
			else
				size = math.clamp(size2 / v27, Mobile.MIN_SIZE, Mobile.MAX_SIZE)
				size2 = size * v27
			end
		end

		local position = resolvePosition( -- inferred equivalent call
			handleAnchor.X,
			anchorPoint.X,
			startLayout.Position.X,
			startLayout.Size.X,
			size
		)
		local position2 = resolvePosition( -- inferred equivalent call
			handleAnchor.Y,
			anchorPoint.Y,
			startLayout.Position.Y,
			startLayout.Size.Y,
			size2
		)
		UpdateEditorButtonLayout(v24.buttonName, {
			Position = { X = position, Y = position2 },
			Size = { X = size, Y = size2 }
		})
	end
end

local function TryStartEditorPinchWithSecondTouch(input) -- 1 equivalent call inferred from this helper
	local v24 = v19

	if not v24 or v20 or v24.input == input then
		return
	end

	StartEditorPinch(v24.buttonName, v24.input, input)
end

local function RefreshEditorInteraction(buttonName: string)
	if v20 and v20.buttonName == buttonName then
		return
	end

	local buttonTouches = GetButtonTouches(buttonName)

	if #buttonTouches > 0 then
		local v24 = buttonTouches[1]
		local v25 = v19

		if v25 and v25.buttonName == buttonName then
			for _, v26 in ipairs(buttonTouches) do
				if v26 ~= v25.input then
					continue
				end

				v24 = v26
				break
			end
		end

		StartEditorDrag(buttonName, v24)
	else
		if v19 and v19.buttonName == buttonName then
			v19 = nil
			v23 = nil
			local mouseIcon = v22 or v23 or v21 or ""

			if UserInputService.MouseIcon ~= mouseIcon then
				UserInputService.MouseIcon = mouseIcon
			end
		end

		if v20 and v20.buttonName == buttonName then
			v20 = nil
		end
	end
end

local function UpdateDragFromInput(input)
	local v24 = v19

	if v24 and IsSamePointer(input, v24.input) then -- inferred equivalent call
		local editorButtonsFrame = GetEditorButtonsFrame() -- inferred equivalent call
		local v25 = defaultLayout2[v24.buttonName]

		if not (editorButtonsFrame and v25) then
			return
		end

		local absoluteSize = editorButtonsFrame.AbsoluteSize

		if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
			return
		end

		local v26 = GetInputGuiPosition(input) - v24.startPosition -- inferred equivalent call
		local v27 = v26.X / absoluteSize.X
		local v28 = v26.Y / absoluteSize.Y
		UpdateEditorButtonLayout(v24.buttonName, {
			Position = {
				X = v24.startLayout.Position.X + v27,
				Y = v24.startLayout.Position.Y + v28
			},
			Size = { X = v25.Size.X, Y = v25.Size.Y }
		})
	end
end

local function UpdatePinchFromInput(input)
	local v24 = v20

	if not v24 or input ~= v24.scaleInput and input ~= v24.anchorInput then
		return
	end

	local inputScreenPosition = GetInputScreenPosition(v24.anchorInput) -- inferred equivalent call
	local inputScreenPosition2 = GetInputScreenPosition(v24.scaleInput) -- inferred equivalent call
	local lastDistance = math.max((inputScreenPosition2 - inputScreenPosition).Magnitude, 1)
	local v25 = lastDistance / math.max(v24.lastDistance, 1)
	local v26 = v24.lastLayout.Size.X * v25
	local v27 = v24.lastLayout.Size.Y * v25
	local editorButtonsFrame = GetEditorButtonsFrame() -- inferred equivalent call

	if not editorButtonsFrame then
		return
	end

	local absoluteSize = editorButtonsFrame.AbsoluteSize

	if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
		return
	end

	local absolutePosition = editorButtonsFrame.AbsolutePosition
	local vector = Vector2.new(
		(inputScreenPosition.X - absolutePosition.X) / absoluteSize.X,
		(inputScreenPosition.Y - absolutePosition.Y) / absoluteSize.Y
	)
	local v28 = vector.X - v24.anchorLocalScale.X * v26
	local v29 = vector.Y - v24.anchorLocalScale.Y * v27

	if v28 ~= v28 or v29 ~= v29 then
		local v30 = (inputScreenPosition + inputScreenPosition2) * 0.5
		local vector2 = Vector2.new(
			(v30.X - absolutePosition.X) / absoluteSize.X,
			(v30.Y - absolutePosition.Y) / absoluteSize.Y
		)
		v28 = vector2.X - v26 / 2
		v29 = vector2.Y - v27 / 2
	end

	UpdateEditorButtonLayout(v24.buttonName, {
		Position = { X = v28, Y = v29 },
		Size = { X = v26, Y = v27 }
	})
	local v30 = defaultLayout2[v24.buttonName]

	if v30 then
		v24.lastLayout = CopyPositionAndSize(v30)
	end

	v24.lastDistance = lastDistance
end

local function LoadEditorStateFromProfile() -- 1 equivalent call inferred from this helper
	local mobileButtons = DataController.Get(LocalPlayer, "MobileButtons")
	defaultLayout = Mobile.SanitizeLayout(mobileButtons)
	defaultLayout2 = DeepCopyLayout(defaultLayout)
	ApplyEditorLayout() -- inferred equivalent call
end

local function ConnectEditorButtonGesture(state)
	local name = state.Name
	state.Active = true
	state.MouseEnter:Connect(function()
		if v8 then
			SetHoveredCursor("rbxasset://SystemCursors/SizeAll") -- inferred equivalent call
		end
	end)
	state.MouseLeave:Connect(function()
		if v21 == "rbxasset://SystemCursors/SizeAll" then
			SetHoveredCursor(nil) -- inferred equivalent call
		end
	end)
	state.InputBegan:Connect(function(input)
		if v8 and IsPointerPress(input) then -- inferred equivalent call
			fn2(name, input)
		end
	end)
end

fn2 = function(buttonName2: string, input)
	if v11[input] or v18 then
		return
	end

	local buttonName = v20 and v20.buttonName or v19 and v19.buttonName

	if buttonName and buttonName ~= buttonName2 then
		return
	end

	v11[input] = buttonName2
	v12[buttonName2] = v12[buttonName2] or {}
	v12[buttonName2][input] = true
	v13[input] = GetInputGuiPosition(input) -- inferred equivalent call

	if v14 ~= buttonName2 then
		SelectEditorButton(buttonName2)
	end

	RefreshEditorInteraction(buttonName2)
end

local function IsPointInsideGuiObject(data, point: Vector2)
	if not (data and data.Visible) then
		return false
	end

	local absolutePosition = data.AbsolutePosition
	local v24 = absolutePosition + data.AbsoluteSize
	return point.X >= absolutePosition.X and point.X <= v24.X and point.Y >= absolutePosition.Y and point.Y <= v24.Y
end

local function TryDeselectFromEmptyTouch(p)
	if not (v8 and v14) or v11[p] or v18 and v18.input == p then
		return
	end

	local v24 = v20

	if v24 and (v24.anchorInput == p or v24.scaleInput == p) then
		return
	end

	local inputScreenPosition = GetInputScreenPosition(p) -- inferred equivalent call
	local v25 = v15
	local v26

	if v25 and v25.Visible then
		local absolutePosition = v25.AbsolutePosition
		local v27 = absolutePosition + v25.AbsoluteSize

		if
			inputScreenPosition.X >= absolutePosition.X
			and inputScreenPosition.X <= v27.X
			and inputScreenPosition.Y >= absolutePosition.Y
		then
			v26 = inputScreenPosition.Y <= v27.Y
		else
			v26 = false
		end
	else
		v26 = false
	end

	if v26 then
		return
	end

	local v27 = v7

	if not (v27 and v27.Parent) then
		v27 = v6

		if v27 then
			local editMobile = v27:FindFirstChild("EditMobile")

			if editMobile then
				v27 = editMobile
			elseif v27.Name ~= "EditMobile" then
				v27 = editMobile
			end

			v7 = v27
		else
			v27 = nil
		end
	end

	local action = v27 and v27:FindFirstChild("Action")

	if action and action:IsA("GuiObject") then
		local v28

		if action and action.Visible then
			local absolutePosition = action.AbsolutePosition
			local v29 = absolutePosition + action.AbsoluteSize

			if
				inputScreenPosition.X >= absolutePosition.X
				and inputScreenPosition.X <= v29.X
				and inputScreenPosition.Y >= absolutePosition.Y
			then
				v28 = inputScreenPosition.Y <= v29.Y
			else
				v28 = false
			end
		else
			v28 = false
		end

		if v28 then
			return
		end
	end

	SelectEditorButton(nil) -- inferred equivalent call
end

local function FindEquippedLoadoutItem(menuCharacterTeam: string, k: string, p: string)
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	local inventory = DataController.Get(LocalPlayer, "Inventory")
	local v24

	if typeof(loadout) == "table" then
		v24 = loadout[menuCharacterTeam]
	else
		v24 = false
	end

	if typeof(v24) ~= "table" or typeof(inventory) ~= "table" then
		return nil
	end

	local function findInventoryItem(value, p2: string?)
		if typeof(value) ~= "string" or value == "" then
			return nil
		end

		for _, v25 in ipairs(inventory) do
			if typeof(v25) == "table" and v25._id == value and (p2 == nil or v25.Name == p2) then
				return v25
			end
		end

		return nil
	end

	if k == "Melee" then
		local equipped = v24.Equipped
		return typeof(equipped) == "table" and findInventoryItem(equipped["Equipped Melee"], nil) or nil
	end

	local v25 = v2[k]
	local v26

	if typeof(v24.Loadout) == "table" then
		v26 = v25 and v24.Loadout[v25]
	else
		v26 = false
	end

	if typeof(v26) ~= "table" or typeof(v26.Options) ~= "table" then
		return nil
	end

	for _, option in ipairs(v26.Options) do
		local inventoryItem = findInventoryItem(option, p)

		if inventoryItem then
			return inventoryItem
		end
	end

	return nil
end

local function GetLoadoutPreviewIcon(name: string, p)
	if p then
		name = p.Name or name
	end

	local v24 = (not p or typeof(p.Skin) ~= "string") and "Stock" or p.Skin or "Stock"
	local skinInformation = Skins.GetSkinInformation(name, v24)

	if skinInformation then
		if skinInformation.wearImages and skinInformation.wearImages[1] then
			return skinInformation.wearImages[1].assetId
		end

		if skinInformation.imageAssetId then
			return skinInformation.imageAssetId
		end
	end

	local weaponProperties = GetWeaponProperties(name)
	return weaponProperties and weaponProperties.Icon or nil
end

local function SetEditorSlotIcon(instance, childName: string, value: string?) -- 2 equivalent calls inferred from this helper
	local child = instance:FindFirstChild(childName)
	local weaponImage = child and child:FindFirstChild("WeaponImage")

	if weaponImage and weaponImage:IsA("ImageLabel") then
		weaponImage.Image = value or ""
		weaponImage.Visible = value ~= nil
	end
end

local function ApplyEditorLoadoutPreview()
	local editorButtonsFrame = GetEditorButtonsFrame() -- inferred equivalent call

	if not editorButtonsFrame then
		return
	end

	for k, v24 in pairs(v3) do
		local skinInformation = Skins.GetSkinInformation(v24, "Stock")
		local assetId, v25

		if skinInformation then
			if skinInformation.wearImages and skinInformation.wearImages[1] then
				assetId = skinInformation.wearImages[1].assetId
			elseif skinInformation.imageAssetId then
				assetId = skinInformation.imageAssetId
			else
				v25 = GetWeaponProperties(v24)
				assetId = v25 and v25.Icon or nil
			end
		else
			v25 = GetWeaponProperties(v24)
			assetId = v25 and v25.Icon or nil
		end

		SetEditorSlotIcon(editorButtonsFrame, k, assetId) -- inferred equivalent call
	end

	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
	local menuCharacterTeam = MenuSceneController.GetMenuCharacterTeam()

	if not (menuCharacterTeam and v[menuCharacterTeam]) then
		local team = LocalPlayer:GetAttribute("Team")
		menuCharacterTeam = (typeof(team) ~= "string" or not v[team]) and "Counter-Terrorists" or team
	end

	local v24 = v[menuCharacterTeam]

	for k, v25 in pairs(v24) do
		local v26

		if DataController.IsDataLoaded(LocalPlayer) then
			v26 = FindEquippedLoadoutItem(menuCharacterTeam, k, v25)
		end

		SetEditorSlotIcon(editorButtonsFrame, k, GetLoadoutPreviewIcon(v25, v26)) -- inferred equivalent call
	end
end

local function ConvertGuiButtonToFrame(instance)
	local frame = Instance.new("Frame")
	frame.Name = instance.Name
	frame.AnchorPoint = instance.AnchorPoint
	frame.Position = instance.Position
	frame.Size = instance.Size
	frame.SizeConstraint = instance.SizeConstraint
	frame.Rotation = instance.Rotation
	frame.ZIndex = instance.ZIndex
	frame.LayoutOrder = instance.LayoutOrder
	frame.Visible = instance.Visible
	frame.BackgroundColor3 = instance.BackgroundColor3
	frame.BackgroundTransparency = instance.BackgroundTransparency
	frame.BorderSizePixel = instance.BorderSizePixel
	frame.ClipsDescendants = instance.ClipsDescendants

	for _, child in ipairs(instance:GetChildren()) do
		child.Parent = frame
	end

	return frame
end

local function ConvertTreeButtonsToFrames(folder)
	for _, button in ipairs(folder:GetDescendants()) do
		if not button:IsA("GuiButton") then
			continue
		end

		local convertGuiButtonToFrame = ConvertGuiButtonToFrame(button)
		convertGuiButtonToFrame.Parent = button.Parent
		button:Destroy()
	end

	if not folder:IsA("GuiButton") then
		return folder
	end

	local convertGuiButtonToFrame = ConvertGuiButtonToFrame(folder)
	folder:Destroy()
	return convertGuiButtonToFrame
end

local function PopulateEditorButtons()
	local parent = GetEditorButtonsFrame() -- inferred equivalent call
	local gameplayMobileButtonsFrame = GetGameplayMobileButtonsFrame()

	if not (parent and gameplayMobileButtonsFrame) then
		return
	end

	for _, guiObject in ipairs(parent:GetChildren()) do
		if not (guiObject:IsA("GuiObject") and Mobile.IsKnownButton(guiObject.Name)) then
			continue
		end

		guiObject:Destroy()
	end

	for _, childName in ipairs(Mobile.GetButtonNames()) do
		local guiObject = gameplayMobileButtonsFrame:FindFirstChild(childName)

		if not (guiObject and guiObject:IsA("GuiObject")) then
			continue
		end

		if childName == "VIP" then
			local v24

			if RunService:IsStudio() then
				v24 = true
			elseif workspace:GetAttribute("IsVIPServer") == true then
				v24 = LocalPlayer:GetAttribute("CanUseVIPMenu") == true
			else
				v24 = false
			end

			if not v24 then
				continue
			end
		end

		local clone = guiObject:Clone()
		clone.Visible = true
		local toggled = clone:FindFirstChild("Toggled")

		if toggled and toggled:IsA("GuiObject") then
			toggled.Visible = false
		end

		local equipped = clone:FindFirstChild("Equipped")

		if equipped and equipped:IsA("GuiObject") then
			equipped.Visible = false
		end

		local use = clone:FindFirstChild("Use")

		if use and use:IsA("GuiObject") then
			use.Visible = true
		end

		local defuse = clone:FindFirstChild("Defuse")

		if defuse and defuse:IsA("GuiObject") then
			defuse.Visible = false
		end

		local convertTreeButtonsToFrames = ConvertTreeButtonsToFrames(clone)
		convertTreeButtonsToFrames.Parent = parent
		ConnectEditorButtonGesture(convertTreeButtonsToFrames)
	end

	ApplyEditorLoadoutPreview()
end

local function SetEditorMode(flag2: boolean) -- 1 equivalent call inferred from this helper
	v8 = flag2
	SetDashboardEditorVisibility(flag2)

	if flag2 then
		RefreshConfigurePanel()
	else
		ClearEditorInteractionState()
		SelectEditorButton(nil) -- inferred equivalent call
	end
end

local function EnterMobileHUDEditor()
	if
		not IsMobilePlatform() -- inferred equivalent call
		and UserInputService.PreferredInput ~= Enum.PreferredInput.Touch
		and not IsTouchInputType(UserInputService:GetLastInputType()) -- inferred equivalent call
		or (v8 or v9)
	then
		return
	end

	v9 = true
	local v24 = pcall(function()
		DataController.WaitForDataLoaded(LocalPlayer)
	end)
	v9 = false

	if not v24 then
		Router.broadcastRouter("CreateMenuNotification", "Error", "Profile data is still loading. Please try again.")
		return
	end

	ClearEditorInteractionState()
	local editorButtonsFrame = GetEditorButtonsFrame() -- inferred equivalent call
	local v25 = false

	if editorButtonsFrame then
		for _, childName in ipairs(Mobile.GetButtonNames()) do
			if not editorButtonsFrame:FindFirstChild(childName) then
				continue
			end

			v25 = true
			break
		end
	end

	if not (editorButtonsFrame and v25) then
		PopulateEditorButtons()
	end

	LoadEditorStateFromProfile() -- inferred equivalent call
	ApplyEditorLoadoutPreview()
	SetEditorMode(true) -- inferred equivalent call
end

local function ExitMobileHUDEditor(flag2: boolean) -- 2 equivalent calls inferred from this helper
	if not v8 then
		return
	end

	if not flag2 then
		defaultLayout2 = DeepCopyLayout(defaultLayout)
		ApplyEditorLayout() -- inferred equivalent call
	end

	v8 = false
	SetDashboardEditorVisibility(false)
	ClearEditorInteractionState()
	SelectEditorButton(nil) -- inferred equivalent call
end

local function UpdateEditMobileButtonVisibility(p)
	local editMobileEntryButton = GetEditMobileEntryButton()
	local parent = editMobileEntryButton and editMobileEntryButton.Parent
	local visible = ShouldShowMobileHUDEditor(p) -- inferred equivalent call

	if editMobileEntryButton then
		editMobileEntryButton.Visible = visible
	end

	if parent and parent:IsA("GuiObject") then
		parent.Visible = visible
	end

	if not (visible or v8 or MenuState.IsInspectActive() or MenuState.IsCaseSceneActive()) then
		SetDashboardEditorVisibility(false)
	end
end

local function ResetEditorToDefaults() -- 1 equivalent call inferred from this helper
	defaultLayout2 = Mobile.GetDefaultLayout()
	ApplyEditorLayout() -- inferred equivalent call
	RefreshConfigurePanel()
end

local function ApplyLayoutToGameplayButtons(p)
	local gameplayMobileButtonsFrame = GetGameplayMobileButtonsFrame()

	if not gameplayMobileButtonsFrame then
		return
	end

	for _, childName in ipairs(Mobile.GetButtonNames()) do
		local guiObject = gameplayMobileButtonsFrame:FindFirstChild(childName)
		local v24 = p[childName]

		if guiObject and guiObject:IsA("GuiObject") and v24 then
			ApplyMobileButtonLayout(guiObject, v24)
		end
	end
end

local function CommitEditorChanges()
	local layout = Mobile.SanitizeLayout(defaultLayout2)
	defaultLayout2 = DeepCopyLayout(layout)
	defaultLayout = DeepCopyLayout(layout)
	ApplyLayoutToGameplayButtons(layout)
	Remotes.Player.UpdateMobileButtons.Send({ Layout = layout })
end

local function HasEditorLayoutChanges() -- 1 equivalent call inferred from this helper
	local v24 = Mobile.SanitizeLayout(defaultLayout2)
	local v25 = Mobile.SanitizeLayout(defaultLayout)
	return not Mobile.AreLayoutsEqual(v24, v25)
end

local function ConnectActionButton(action, childName: string, onMouseButton1Click) -- 3 equivalent calls inferred from this helper
	local button = action:FindFirstChild(childName)

	if button and button:IsA("GuiButton") then
		ActivateButton(button)
		button.MouseButton1Click:Connect(onMouseButton1Click)
	end
end

local function HandleConfirmPressed()
	if not v8 then
		return
	end

	PlayUIClick() -- inferred equivalent call

	if HasEditorLayoutChanges() then -- inferred equivalent call
		CommitEditorChanges()
	end

	ExitMobileHUDEditor(true) -- inferred equivalent call
end

local function HandleResetPressed()
	if not v8 then
		return
	end

	PlayUIClick() -- inferred equivalent call
	ResetEditorToDefaults() -- inferred equivalent call
end

local function HandleBackPressed()
	if not v8 then
		return
	end

	PlayUIClick() -- inferred equivalent call
	ExitMobileHUDEditor(false) -- inferred equivalent call
end

local function SetupEditMobileEntryButton()
	local editMobileEntryButton = GetEditMobileEntryButton()

	if not editMobileEntryButton then
		return
	end

	ActivateButton(editMobileEntryButton)
	editMobileEntryButton.MouseButton1Click:Connect(function()
		PlayUIClick() -- inferred equivalent call
		EnterMobileHUDEditor()
	end)
end

local function SetupEditorControls()
	local v24 = v7

	if not (v24 and v24.Parent) then
		v24 = v6

		if v24 then
			local editMobile = v24:FindFirstChild("EditMobile")

			if editMobile then
				v24 = editMobile
			elseif v24.Name ~= "EditMobile" then
				v24 = editMobile
			end

			v7 = v24
		else
			v24 = nil
		end
	end

	if not v24 then
		return
	end

	local action = v24:FindFirstChild("Action")

	if action and action:IsA("Frame") then
		ConnectActionButton(action, "Confirm", HandleConfirmPressed) -- inferred equivalent call
		ConnectActionButton(action, "Reset", HandleResetPressed) -- inferred equivalent call
		ConnectActionButton(action, "Back", HandleBackPressed) -- inferred equivalent call
	end

	SetupConfigurePanel(v24)
	PopulateEditorButtons()
end

local function ConnectGlobalInputHandlers()
	UserInputService.LastInputTypeChanged:Connect(function(p)
		UpdateEditMobileButtonVisibility(p)
	end)
	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
	MenuSceneController.MenuCharacterChanged:Connect(function()
		ApplyEditorLoadoutPreview()
	end)
	DataController.CreateListener(LocalPlayer, "Loadout", function()
		ApplyEditorLoadoutPreview()
	end)
	Skins.OnItemStockSchemasUpdated:Connect(function()
		ApplyEditorLoadoutPreview()
	end)
	UserInputService.InputBegan:Connect(function(input)
		if not (v8 and IsPointerPress(input)) then -- inferred equivalent call
			return
		end

		if IsTouchInputType(input.UserInputType) then -- inferred equivalent call
			TryStartEditorPinchWithSecondTouch(input) -- inferred equivalent call
		end

		task.defer(TryDeselectFromEmptyTouch, input)
	end)
	UserInputService.InputChanged:Connect(function(input)
		if
			not v8
			or not IsTouchInputType(input.UserInputType) and input.UserInputType ~= Enum.UserInputType.MouseMovement -- inferred equivalent call
		then
			return
		end

		if v18 then
			UpdateResizeFromInput(input)
		elseif v20 then
			UpdatePinchFromInput(input)
		elseif v19 then
			UpdateDragFromInput(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if not IsPointerRelease(input) then -- inferred equivalent call
			return
		end

		local v24 = v18

		if v24 and IsSamePointer(input, v24.input) then -- inferred equivalent call
			v18 = nil
			SetActiveResizeCursor(nil) -- inferred equivalent call
			return
		end

		local v25 = false
		local anchorInput = nil
		local v26 = v20
		local buttonName

		if v26 and (input == v26.anchorInput or input == v26.scaleInput) then
			buttonName = v26.buttonName

			if input == v26.scaleInput then
				anchorInput = v26.anchorInput
				v25 = true
			end

			v20 = nil
		end

		local removeTouchFromButton = RemoveTouchFromButton(input) -- inferred equivalent call
		local v27 = v13[input]
		v13[input] = nil

		if removeTouchFromButton and not buttonName and v27 and (GetInputGuiPosition(input) - v27).Magnitude <= 12 then -- inferred equivalent call
			SelectEditorButton(removeTouchFromButton)
		end

		local v28 = v19

		if v28 and IsSamePointer(input, v28.input) then -- inferred equivalent call
			v19 = nil
			v23 = nil
			local mouseIcon = v22 or v23 or v21 or ""

			if UserInputService.MouseIcon ~= mouseIcon then
				UserInputService.MouseIcon = mouseIcon
			end
		end

		local buttonName2 = removeTouchFromButton or buttonName

		if v25 and anchorInput and buttonName2 and v11[anchorInput] == buttonName2 then
			StartEditorDrag(buttonName2, anchorInput)
		end

		if buttonName2 then
			RefreshEditorInteraction(buttonName2)
		end
	end)
end

function EditMobile.Initialize(p, instance)
	v5 = p
	local editMobile = instance:FindFirstChild("EditMobile")
	local parent

	if instance.Name == "EditMobile" then
		parent = instance.Parent

		if parent then
			if parent:IsA("Frame") then
				editMobile = instance
			else
				editMobile = instance
				parent = editMobile
				editMobile = parent
			end
		else
			editMobile = instance
			parent = editMobile
			editMobile = parent
		end
	else
		parent = instance
	end

	v6 = parent
	v7 = editMobile
	ConnectEditorVisibilityGuards()
	SetDashboardEditorVisibility(false)
	UpdateEditMobileButtonVisibility(UserInputService:GetLastInputType())
	local editMobileEntryButton = GetEditMobileEntryButton()

	if editMobileEntryButton then
		ActivateButton(editMobileEntryButton)
		editMobileEntryButton.MouseButton1Click:Connect(function()
			PlayUIClick() -- inferred equivalent call
			EnterMobileHUDEditor()
		end)
	end

	SetupEditorControls()
	ConnectGlobalInputHandlers()
end

function EditMobile.ShouldShowEntryButton(p)
	return ShouldShowMobileHUDEditor(p) -- inferred equivalent call
end

function EditMobile.Open()
	EnterMobileHUDEditor()
end

return EditMobile