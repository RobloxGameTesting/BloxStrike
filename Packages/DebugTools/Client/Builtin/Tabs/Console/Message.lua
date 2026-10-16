local parent = script.Parent.Parent.Parent.Parent
local Style = require(parent.Style)
local v = {
	INFO = Style.COLOR_WHITE,
	ERROR = Color3.fromRGB(255, 81, 70),
	WARNING = Color3.fromRGB(243, 173, 82)
}
local v2 = { internal = {}, prototype = {}, interface = {} }

function v2.internal:createMessageFrame(flag: boolean)
	local COLOR_GREEN = flag and Style.COLOR_GREEN or Style.COLOR_BLUE
	local v3 = self.ContentType == "WARNING" or self.ContentType == "ERROR"
	local textButton = Instance.new("TextButton")
	textButton.Name = "Console Message"
	textButton.AutoLocalize = false
	textButton.Size = UDim2.new(1, 0, 0, 12)
	textButton.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		v3 and Enum.FontWeight.Bold or Enum.FontWeight.Regular
	)
	textButton.BackgroundColor3 = COLOR_GREEN
	textButton.BackgroundTransparency = 0.8
	textButton.Text = self.ContentShort
	textButton.TextSize = 12
	textButton.TextTruncate = Enum.TextTruncate.AtEnd
	textButton.TextXAlignment = Enum.TextXAlignment.Left
	textButton.TextColor3 = v[self.ContentType]
	textButton.BorderSizePixel = 0
	textButton.AutomaticSize = Enum.AutomaticSize.Y
	self.MessageTextButton = textButton
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "UIStroke"
	uiStroke.Transparency = 0.6
	uiStroke.Parent = textButton
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "More"
	textLabel.AutoLocalize = false
	textLabel.AnchorPoint = Vector2.new(1, 0)
	textLabel.Position = UDim2.fromScale(1, 0)
	textLabel.Size = UDim2.fromOffset(0, 12)
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/Inconsolata.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.Text = "..."
	textLabel.TextColor3 = Style.COLOR_WHITE
	textLabel.TextSize = 14
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.Visible = false
	textLabel.Parent = textButton
	self.MoreLabel = textLabel
	local textLabel2 = Instance.new("TextLabel")
	textLabel2.Name = "TextLabel"
	textLabel2.AutoLocalize = false
	textLabel2.AnchorPoint = Vector2.new(1, 0)
	textLabel2.Position = UDim2.new(1, -24, 0, 0)
	textLabel2.Size = UDim2.fromScale(0, 1)
	textLabel2.FontFace = Style.FONT_BOLD
	textLabel2.Text = "x1"
	textLabel2.TextColor3 = Style.COLOR_WHITE
	textLabel2.TextSize = 12
	textLabel2.AutomaticSize = Enum.AutomaticSize.X
	textLabel2.BackgroundColor3 = Style.COLOR_BLACK
	textLabel2.BackgroundTransparency = 0.25
	textLabel2.BorderSizePixel = 0
	textLabel2.Visible = false
	textLabel2.Parent = textButton
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingLeft = UDim.new(0, 2)
	uiPadding.PaddingRight = UDim.new(0, 2)
	uiPadding.Parent = textLabel2
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.BackgroundColor3 = COLOR_GREEN
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.new(0, 4, 1, 0)
	frame.Parent = textButton
	self.CountLabel = textLabel2
end

function v2.prototype.SetParent(p, parent2)
	p.MessageTextButton.Parent = parent2
end

function v2.prototype:Destroy()
	self.MessageTextButton:Destroy()
	self.MessageTextButton = nil
	self._TextButtonActivatedConnection:Disconnect()
	self._TextButtonActivatedConnection = nil
end

function v2.prototype:Concatenate(p: string)
	self.Content ..= p
	local v3 = string.find(self.Content, "\n") or 0
	self.ContentShort = v3 > 0 and string.sub(self.Content, 0, v3 - 1) or self.Content
	self.CanExpand = v3 > 0
	self.MoreLabel.Visible = v3 ~= nil
	self.MessageTextButton.Text = self.Expanded and self.Content or self.ContentShort
end

function v2.prototype:IncreaseCount(value: number?)
	self.Amount += value or 1
	self.CountLabel.Visible = true
	self.CountLabel.Text = `x{self.Amount}`
end

function v2.prototype:ChangeType(contentType: string)
	self.ContentType = contentType
	self.MessageTextButton.BackgroundColor3 = v[self.ContentType] or Style.PRIMARY_DARK
end

function v2.prototype:Expand()
	if not self.CanExpand then
		return
	end

	self.Expanded = not self.Expanded
	self.MessageTextButton.Text = self.Expanded and self.Content or self.ContentShort
end

function v2.interface.new(content: string, contentType: string, flag: boolean?, p: number?)
	local serverSide = flag or false
	local v3 = string.find(content, "\n")
	local contentShort

	if v3 then
		contentShort = string.sub(content, 0, v3 - 1) or content
	else
		contentShort = content
	end

	local object = setmetatable({
		Content = content,
		ContentShort = contentShort,
		ContentType = contentType,
		ServerSide = serverSide,
		CanExpand = v3 ~= nil,
		Expanded = false,
		Amount = 1,
		Timestamp = p or os.clock()
	}, { __index = v2.prototype })
	v2.internal.createMessageFrame(object, serverSide)
	object.MoreLabel.Visible = object.CanExpand
	object._TextButtonActivatedConnection = object.MessageTextButton.Activated:Connect(function()
		object:Expand()
	end)
	return object
end

return v2.interface