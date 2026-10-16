local parent = script.Parent.Parent
local Shared = parent.Parent.Shared
local Signal = require(Shared.Signal)
local Style = require(parent.Style)
local v = { prototype = {}, interface = {} }

function v.prototype.Focus(p)
	p.TabButton.TextColor3 = Style.TAB_FOCUSED_TEXT
	p.TabButton.BackgroundColor3 = Style.TAB_FOCUSED_BACKGROUND
end

function v.prototype.Unfocus(p)
	p.TabButton.TextColor3 = Style.TAB_NORMAL_TEXT
	p.TabButton.BackgroundColor3 = Style.TAB_NORMAL_BACKGROUND
end

function v.prototype:Destroy()
	self.TabActivated:Destroy()
	self.TabButton:Destroy()
	self.ButtonActivatedConnection:Disconnect()
end

function v.interface.new(p: string, parent2)
	local textButton = Instance.new("TextButton")
	textButton.Name = p
	textButton.AutoLocalize = false
	textButton.Size = UDim2.fromScale(0, 1)
	textButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textButton.Text = p
	textButton.TextColor3 = Style.TAB_NORMAL_TEXT
	textButton.TextSize = 14
	textButton.AutomaticSize = Enum.AutomaticSize.X
	textButton.BackgroundColor3 = Style.TAB_NORMAL_BACKGROUND
	textButton.BorderSizePixel = 0
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)
	uiPadding.Parent = textButton
	textButton.Parent = parent2
	local tabActivated = Signal.new()
	return (setmetatable({
		Module = p,
		TabActivated = tabActivated,
		TabButton = textButton,
		ButtonActivatedConnection = textButton.Activated:Connect(function()
			tabActivated:Fire()
		end)
	}, { __index = v.prototype }))
end

return v.interface