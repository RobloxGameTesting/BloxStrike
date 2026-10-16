local parent = script.Parent.Parent.Parent.Parent
local Widget = require(parent.Widget)
local color = Color3.fromRGB(183, 241, 77)
local color2 = Color3.fromRGB(132, 156, 137)
local color3 = Color3.fromRGB(241, 77, 77)
local color4 = Color3.fromRGB(147, 115, 137)

local function createWidgetButton(name: string, scrollingFrame)
	local isVisible = Widget:IsVisible(name)
	local textButton = Instance.new("TextButton")
	textButton.Name = name
	textButton.AutoLocalize = false
	textButton.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textButton.Text = ` {name}`
	textButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	textButton.TextSize = 12
	textButton.TextStrokeTransparency = 0
	textButton.TextXAlignment = Enum.TextXAlignment.Left
	textButton.BackgroundColor3 = isVisible and color2 or color4
	textButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textButton.BorderSizePixel = 0
	textButton.Size = UDim2.new(1, 0, 0, 18)
	local activatedConnection = textButton.Activated:Connect(function()
		Widget:SwitchVisibility(name)
	end)
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.BackgroundColor3 = isVisible and color or color3
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.new(1, -12, 0.5, 0)
	frame.Size = UDim2.new(0, 100, 0.3, 0)
	local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uiAspectRatioConstraint.Parent = frame
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = frame
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "UIStroke"
	uiStroke.Color = Color3.fromRGB(81, 88, 104)
	uiStroke.Parent = frame
	frame.Parent = textButton
	textButton.Parent = scrollingFrame
	local widgetMountedConnection = Widget.WidgetMounted:Connect(function(p: string)
		if p ~= name then
			return
		end

		frame.BackgroundColor3 = Color3.fromRGB(183, 241, 77)
		textButton.BackgroundColor3 = Color3.fromRGB(132, 156, 137)
	end)
	local widgetUnmountedConnection = Widget.WidgetUnmounted:Connect(function(p: string)
		if p ~= name then
			return
		end

		frame.BackgroundColor3 = Color3.fromRGB(241, 77, 77)
		textButton.BackgroundColor3 = Color3.fromRGB(147, 115, 137)
	end)
	return function()
		activatedConnection:Disconnect()
		activatedConnection = nil
		widgetMountedConnection:Disconnect()
		widgetMountedConnection = nil
		widgetUnmountedConnection:Disconnect()
		widgetUnmountedConnection = nil
		textButton:Destroy()
		textButton = nil
	end
end

return function(parent2)
	local frame = Instance.new("Frame")
	frame.Name = "Widgets List"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.BackgroundColor3 = Color3.fromRGB(172, 195, 245)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(1, 0)
	frame.Size = UDim2.fromScale(0.25, 1)
	local frame2 = Instance.new("Frame")
	frame2.Name = "Gradient"
	frame2.AnchorPoint = Vector2.new(1, 0)
	frame2.Size = UDim2.fromScale(0.05, 1)
	frame2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame2.BackgroundTransparency = 0.8
	frame2.BorderSizePixel = 0
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Name = "UIGradient"
	uiGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	uiGradient.Parent = frame2
	frame2.Parent = frame
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "ScrollingFrame"
	scrollingFrame.Size = UDim2.fromScale(1, 1)
	scrollingFrame.CanvasSize = UDim2.new()
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 2)
	uiListLayout.SortOrder = Enum.SortOrder.Name
	uiListLayout.Parent = scrollingFrame
	scrollingFrame.Parent = frame
	frame.Parent = parent2
	local v = {}

	for k in Widget:GetAll() do
		table.insert(v, (createWidgetButton(k, scrollingFrame)))
	end

	local widgetAddedConnection = Widget.WidgetAdded:Connect(function(name)
		table.insert(v, (createWidgetButton(name, scrollingFrame)))
	end)
	return function()
		for _, v2 in v do
			v2()
		end

		widgetAddedConnection:Disconnect()
		widgetAddedConnection = nil
		frame:Destroy()
		frame = nil
	end
end