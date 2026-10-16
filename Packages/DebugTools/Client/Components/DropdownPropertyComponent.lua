local parent = script.Parent.Parent
local Style = require(parent.Style)
local DropdownPopup = require(script.Parent.DropdownPopup)
return function(data, callback)
	local value = data.Value
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Dropdown"
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
	textLabel.LayoutOrder = 4
	textLabel.AutoLocalize = false
	local textButton = Instance.new("TextButton")
	textButton.Name = "Dropdown Click Detector"
	textButton.Position = UDim2.fromScale(0.5, 0)
	textButton.Size = UDim2.fromScale(0.5, 1)
	textButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textButton.Text = tostring(value)
	textButton.TextColor3 = Style.COLOR_WHITE
	textButton.TextSize = 12
	textButton.TextWrapped = true
	textButton.AutoButtonColor = false
	textButton.AutomaticSize = Enum.AutomaticSize.Y
	textButton.BackgroundColor3 = Style.BACKGROUND_DARK
	textButton.BorderSizePixel = 0
	textButton.AutoLocalize = false
	textButton.Parent = textLabel
	local v = false
	local activatedConnection = textButton.Activated:Connect(function()
		if v or #data.Options <= 1 then
			return
		end

		v = true
		local clone = table.clone(data.Options)
		table.remove(clone, table.find(clone, value))
		local v2 = DropdownPopup.new(textButton, clone, data.Value)
		v2.EntrySelected:Connect(function(text: string)
			if text == value then
				return
			end

			value = text
			textButton.Text = text
			callback(text)
		end)
		v2.Closed:Connect(function()
			v = false
		end)
	end)
	textLabel.Parent = data.Parent
	return function()
		textLabel:Destroy()
		activatedConnection:Disconnect()
	end
end