local parent = script.Parent.Parent
local Style = require(parent.Style)
return function(data, callback)
	local visible = data.Value
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Argument [boolean]"
	textLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textLabel.Text = data.PropertyText or ""
	textLabel.TextColor3 = Style.COLOR_WHITE
	textLabel.TextSize = 12
	textLabel.TextStrokeTransparency = 0.75
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.AutomaticSize = Enum.AutomaticSize.Y
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.LayoutOrder = 1
	textLabel.Size = UDim2.new(1, 0, 0, 16)
	textLabel.AutoLocalize = false
	local textButton = Instance.new("TextButton")
	textButton.Name = "Checkmark Click Detector"
	textButton.AnchorPoint = Vector2.new(1, 0)
	textButton.Position = UDim2.fromScale(1, 0)
	textButton.Size = UDim2.fromScale(0.1, 1)
	textButton.Text = ""
	textButton.TextSize = 12
	textButton.TextWrapped = true
	textButton.AutoButtonColor = false
	textButton.AutomaticSize = Enum.AutomaticSize.Y
	textButton.BackgroundColor3 = Style.BACKGROUND_DARK
	textButton.BorderSizePixel = 0
	textButton.AutoLocalize = false
	textButton.Parent = textLabel
	local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uiAspectRatioConstraint.Parent = textButton
	local frame = Instance.new("Frame")
	frame.Name = "Value [TextBox]"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.75, 0.75)
	frame.BackgroundColor3 = Style.PRIMARY
	frame.BorderSizePixel = 0
	frame.Visible = visible
	frame.Parent = textButton
	textLabel.Parent = data.Parent
	local activatedConnection = textButton.Activated:Connect(function()
		visible = not visible
		frame.Visible = visible
		callback(visible)
	end)
	return function()
		textLabel:Destroy()
		activatedConnection:Disconnect()
	end
end