local Shared = script.Parent.Parent.Parent.Parent.Parent.Shared
local Signal = require(Shared.Signal)
local v = { internal = {}, prototype = {}, interface = {} }

function v.internal:createModalInterface(text: string)
	local frame = Instance.new("Frame")
	frame.Name = "Output Modal"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(79, 88, 105)
	frame.BackgroundTransparency = 0.1
	frame.BorderColor3 = Color3.fromRGB(79, 88, 105)
	frame.BorderSizePixel = 10
	frame.ZIndex = 10
	local textButton = Instance.new("TextButton")
	textButton.AutoLocalize = false
	textButton.Position = UDim2.fromOffset(-8, -8)
	textButton.Size = UDim2.new(1, 16, 1, 16)
	textButton.BackgroundTransparency = 1
	textButton.Text = ""
	textButton.ZIndex = -1
	textButton.Parent = frame
	local textLabel = Instance.new("TextLabel")
	textLabel.AutoLocalize = false
	textLabel.Name = "TextLabel"
	textLabel.AnchorPoint = Vector2.new(0, 1)
	textLabel.Position = UDim2.fromScale(0, 1)
	textLabel.Size = UDim2.new(1, 0, 0, 12)
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.Text = "Copy the above message and paste it into a file."
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 12
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.BackgroundTransparency = 1
	textLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.BorderSizePixel = 0
	textLabel.Parent = frame
	local textBox = Instance.new("TextBox")
	textBox.AutoLocalize = false
	textBox.Name = "TextBox"
	textBox.Position = UDim2.fromOffset(0, 16)
	textBox.Size = UDim2.new(1, 0, 1, -30)
	textBox.ClearTextOnFocus = false
	textBox.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textBox.Text = text
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.TextSize = 12
	textBox.TextTruncate = Enum.TextTruncate.AtEnd
	textBox.TextWrapped = true
	textBox.TextXAlignment = Enum.TextXAlignment.Left
	textBox.TextYAlignment = Enum.TextYAlignment.Top
	textBox.Active = false
	textBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	textBox.BackgroundTransparency = 0.5
	textBox.BorderSizePixel = 0
	textBox.TextEditable = false
	textBox.ZIndex = 10
	textBox.Parent = frame
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.Parent = frame
	local textButton2 = Instance.new("TextButton")
	textButton2.AutoLocalize = false
	textButton2.Name = "Close Button"
	textButton2.AnchorPoint = Vector2.new(1, 0)
	textButton2.Position = UDim2.new(1, 8, 0, -8)
	textButton2.Size = UDim2.fromOffset(32, 16)
	textButton2.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textButton2.Text = "X"
	textButton2.TextColor3 = Color3.fromRGB(0, 0, 0)
	textButton2.TextSize = 16
	textButton2.BackgroundColor3 = Color3.fromRGB(255, 81, 70)
	textButton2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	textButton2.BorderSizePixel = 0
	textButton2.Parent = frame
	self.CloseButtonActivatedConnection = textButton2.Activated:Connect(function()
		self.CloseActivated:Fire()
	end)
	return frame
end

function v.prototype.ParentTo(p, parent)
	p.ModalFrame.Parent = parent
end

function v.prototype:Destroy()
	self.ModalFrame:Destroy()
	self.ModalFrame = nil
	self.CloseActivated:Destroy()
	self.CloseActivated = nil
	self.CloseButtonActivatedConnection:Disconnect()
	self.CloseButtonActivatedConnection = nil
end

function v.interface.new(p: string)
	local self = setmetatable({ ModalFrame = nil, CloseActivated = Signal.new() }, {
		__index = v.prototype
	})
	self.ModalFrame = v.internal.createModalInterface(self, p)
	return self
end

return v.interface