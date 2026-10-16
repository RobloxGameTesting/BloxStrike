local parent = script.Parent.Parent.Parent.Parent.Parent
local Style = require(parent.Style)
return function(p: string, parent2, object, callback)
	local textButton = Instance.new("TextButton")
	textButton.Name = `Action Group ({p})`
	textButton.AutoLocalize = false
	textButton.Size = UDim2.new(1, 0, 0, 18)
	textButton.FontFace = Style.FONT_BOLD
	textButton.Text = ` {p}`
	textButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	textButton.TextSize = 12
	textButton.TextStrokeTransparency = 0
	textButton.TextXAlignment = Enum.TextXAlignment.Left
	textButton.BackgroundColor3 = Style.PRIMARY_DARK
	textButton.BorderSizePixel = 0
	textButton.Parent = parent2
	local activatedConnection = textButton.Activated:Connect(function()
		callback()
	end)
	local connection = object:Observe(function(p2: string)
		textButton.BackgroundColor3 = p == p2 and Style.PRIMARY_TEXT or Style.PRIMARY_DARK
	end)
	return function()
		connection:Disconnect()
		connection = nil
		activatedConnection:Disconnect()
		activatedConnection = nil
		textButton:Destroy()
		textButton = nil
	end
end