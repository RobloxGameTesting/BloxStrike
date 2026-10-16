local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local guiInset = GuiService:GetGuiInset()
local parent = script.Parent
local Shared = parent.Parent.Shared
local Tab = require(parent.Tab)
local Style = require(parent.Style)
local Constants = require(Shared.Constants)
local TabFrame = require(script.TabFrame)
local v = {
	internal = { Tabs = {}, ActiveTab = nil, ActiveContentTabFrame = nil },
	private = {
		Dragging = false,
		InterfaceCreated = false,
		InterfaceElements = { Tabs = nil, ContentFrame = nil, ScreenGui = nil },
		Tabs = {}
	},
	interface = {}
}

function v.internal.focusModule(name: string)
	local activeTab = v.internal.ActiveTab

	if activeTab and activeTab.Name == name then
		return
	end

	local tabConstructor = Tab.getTabConstructor(name)

	if not tabConstructor then
		return
	end

	local activeContentTabFrame = v.internal.ActiveContentTabFrame

	if not activeContentTabFrame then
		return
	end

	if activeTab then
		v.internal.Tabs[activeTab.Name]:Unfocus()
		activeTab.Destructor()
		local children = activeContentTabFrame:GetChildren()

		if #children > 0 then
			warn(`Tab '{activeTab.Name}' didn't cleanup unmounted interface properly, there are leftover elements:`)

			for _, v2 in children do
				warn(`  ╠ {v2.Name}({v2.ClassName})`)
				v2:Destroy()
			end
		end
	end

	v.internal.ActiveTab = {
		Name = name,
		Destructor = tabConstructor(activeContentTabFrame)
	}
	v.internal.Tabs[name]:Focus()
end

function v.internal.tabAdded(p: string)
	local v2 = TabFrame.new(p, v.private.InterfaceElements.Tabs, v.private.InterfaceElements.ContentFrame)
	v2.TabActivated:Connect(function()
		v.internal.focusModule(p)
	end)
	v.internal.Tabs[p] = v2

	if not v.internal.ActiveTab then
		v.internal.focusModule(p)
	end
end

function v.private:CreateInterface()
	assert(not self.InterfaceCreated, "Tried to create interface when it was already created!")
	self.InterfaceCreated = true
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromOffset(624, 375)
	frame.BackgroundTransparency = 0.15
	frame.BackgroundColor3 = Style.BACKGROUND
	frame.BorderSizePixel = 0
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "UIStroke"
	uiStroke.Color = Color3.fromRGB(98, 114, 164)
	uiStroke.Parent = frame
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Header"
	textLabel.AutoLocalize = false
	textLabel.Size = UDim2.new(1, 0, 0, 18)
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.Text = "DEBUG TOOLS"
	textLabel.TextColor3 = Style.TEXT
	textLabel.TextSize = 18
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.BackgroundColor3 = Style.COLOR_WHITE
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Parent = frame
	local textLabel2 = Instance.new("TextLabel")
	textLabel2.Name = "Version"
	textLabel2.AutoLocalize = false
	textLabel2.Size = UDim2.new(1, 0, 0, 18)
	textLabel2.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel2.Text = Constants.VERSION
	textLabel2.TextColor3 = Style.TEXT
	textLabel2.TextSize = 10
	textLabel2.TextTransparency = 0.75
	textLabel2.TextXAlignment = Enum.TextXAlignment.Right
	textLabel2.TextYAlignment = Enum.TextYAlignment.Bottom
	textLabel2.BackgroundColor3 = Style.COLOR_WHITE
	textLabel2.BackgroundTransparency = 1
	textLabel2.BorderSizePixel = 0
	textLabel2.Parent = frame
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.Parent = frame
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.CornerRadius = UDim.new(0, 4)
	uiCorner.Parent = frame
	local frame2 = Instance.new("Frame")
	frame2.Name = "Content Frame"
	frame2.Position = UDim2.fromOffset(0, 24)
	frame2.Size = UDim2.new(1, 0, 1, -24)
	frame2.BackgroundTransparency = 1
	frame2.BorderSizePixel = 0
	local frame3 = Instance.new("Frame")
	frame3.Name = "Active Tab Content"
	frame3.AnchorPoint = Vector2.new(0, 1)
	frame3.Position = UDim2.fromScale(0, 1)
	frame3.Size = UDim2.new(1, 0, 1, -16)
	frame3.BackgroundTransparency = 1
	frame3.BorderSizePixel = 0
	frame3.ClipsDescendants = true
	frame3.ZIndex = 2
	frame3.Parent = frame2
	local frame4 = Instance.new("Frame")
	frame4.Name = "Tabs"
	frame4.Size = UDim2.new(1, 0, 0, 16)
	frame4.BackgroundTransparency = 1
	frame4.BorderSizePixel = 0
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.SortOrder = Enum.SortOrder.Name
	uiListLayout.Parent = frame4
	frame4.Parent = frame2
	frame2.Parent = frame
	local textButton = Instance.new("TextButton")
	textButton.Name = "Drag Detector"
	textButton.Position = UDim2.new(0, -8, 0, -8)
	textButton.Size = UDim2.new(1, 16, 0, 30)
	textButton.BorderSizePixel = 0
	textButton.Text = ""
	textButton.BackgroundTransparency = 1
	textButton.Modal = true
	textButton.Parent = frame
	textButton.InputBegan:Connect(function(input)
		if
			self.Dragging
			or input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		local v2 = Vector2.new(frame.AbsolutePosition.X, frame.AbsolutePosition.Y) + guiInset
		self.Dragging = true
		self.DragOffset = v2 - UserInputService:GetMouseLocation()
		self.InputChangedConnection = UserInputService.InputChanged:Connect(function(input2)
			if
				input2.UserInputType ~= Enum.UserInputType.MouseMovement
				and input2.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			local v3 = -(frame.AbsoluteSize * -frame.AnchorPoint)
			local v4 = Vector2.new(input2.Position.X, input2.Position.Y) + self.DragOffset + guiInset + v3
			local vector = Vector2.new(math.max(0, v4.X), (math.max(0, v4.Y)))
			frame.Position = UDim2.fromOffset(vector.X, vector.Y)
		end)
		self.InputEndedConnection = UserInputService.InputEnded:Connect(function(input2)
			if
				input2.UserInputType ~= Enum.UserInputType.MouseButton1
				and input2.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			self.Dragging = false
			self.InputEndedConnection:Disconnect()
			self.InputChangedConnection:Disconnect()
		end)
	end)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "[DEBUG] Main Interface"
	screenGui.DisplayOrder = Constants.DEBUG_TOOL_DISPLAY_ORDER
	screenGui.IgnoreGuiInset = true
	screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	frame.Parent = screenGui
	screenGui.Parent = Players.LocalPlayer.PlayerGui
	self.InterfaceElements.ContentFrame = frame2
	self.InterfaceElements.Tabs = frame4
	self.InterfaceElements.ScreenGui = screenGui
	v.internal.ActiveContentTabFrame = frame3
	screenGui.DescendantAdded:Connect(function(descendant)
		if not (descendant:IsA("TextLabel") or descendant:IsA("TextButton") or descendant:IsA("TextBox")) then
			return
		end

		if descendant.AutoLocalize then
			warn(`A descendant was added to Debug Tools interface that has AutoLocalize enabled, every Instance that inherits GuiBase2d should have it's AutoLocalize property set to false!\n{descendant:GetFullName()}`)
		end

		descendant.AutoLocalize = false
	end)
end

function v.private:ListenToModules()
	for _, v2 in Tab.getAllTabs() do
		v.internal.tabAdded(v2)
	end

	Tab.TabAdded:Connect(function(p)
		v.internal.tabAdded(p)
	end)
end

function v.interface.init()
	v.private:CreateInterface()
	v.private:ListenToModules()
end

function v.interface.switchVisibility()
	local screenGui = v.private.InterfaceElements.ScreenGui

	if not screenGui then
		return
	end

	screenGui.Enabled = not screenGui.Enabled
end

return v.interface