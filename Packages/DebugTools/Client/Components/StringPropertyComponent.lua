local parent = script.Parent.Parent
local Style = require(parent.Style)
return function(data, callback)
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Argument [string]"
	textLabel.Size = UDim2.new(1, 0, 0, 16)
	textLabel.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textLabel.Text = data.PropertyText
	textLabel.TextColor3 = Style.COLOR_WHITE
	textLabel.TextSize = 12
	textLabel.TextStrokeTransparency = 0.75
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.AutomaticSize = Enum.AutomaticSize.Y
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.LayoutOrder = 1
	textLabel.AutoLocalize = false
	local textBox = Instance.new("TextBox")
	textBox.Name = "Value [TextBox]"
	textBox.Position = UDim2.fromScale(0.5, 0)
	textBox.Size = UDim2.fromScale(0.5, 1)
	textBox.ClearTextOnFocus = false
	textBox.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textBox.PlaceholderText = data.Default or "string"
	textBox.Text = data.Value or ""
	textBox.TextColor3 = Style.COLOR_WHITE
	textBox.TextSize = 12
	textBox.TextWrapped = true
	textBox.AutomaticSize = Enum.AutomaticSize.Y
	textBox.BackgroundColor3 = Style.BACKGROUND_DARK
	textBox.BorderSizePixel = 0
	textBox.AutoLocalize = false
	textBox.Parent = textLabel
	local textChangedConnection = textBox:GetPropertyChangedSignal("Text"):Connect(function()
		callback(textBox.Text)
	end)
	textLabel.Parent = data.Parent
	return function()
		textLabel:Destroy()
		textChangedConnection:Disconnect()
	end
end