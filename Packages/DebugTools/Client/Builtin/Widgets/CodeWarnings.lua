local RunService = game:GetService("RunService")
local parent = script.Parent.Parent.Parent
local Constants = require(parent.Parent.Shared.Constants)

if not Constants.DEFAULT_WIDGETS_ENABLED then
	return nil
end

local Console = require(parent.Builtin.Tabs.Console)
local Widget = require(parent.Widget)
local Style = require(parent.Style)
local v = {
	internal = { ContentFrame = nil, OnScreenMessages = {} }
}

function v.internal.createOutputLabel()
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "OutputLabel"
	textLabel.AutoLocalize = false
	textLabel.FontFace = Style.FONT_BOLD
	textLabel.TextColor3 = Color3.fromRGB(255, 81, 70)
	textLabel.TextSize = 14
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextWrapped = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.AutomaticSize = Enum.AutomaticSize.XY
	textLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.BackgroundTransparency = 0.5
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 4)
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.Parent = textLabel
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = textLabel
	local uiSizeConstraint = Instance.new("UISizeConstraint")
	uiSizeConstraint.Name = "UISizeConstraint"
	uiSizeConstraint.MaxSize = Vector2.new(500, 1e999)
	uiSizeConstraint.Parent = textLabel
	return textLabel
end

function v.internal.getLatestMessageData()
	local count = #v.internal.OnScreenMessages

	if count == 0 then
		return
	else
		return v.internal.OnScreenMessages[count]
	end
end

function v.internal.addMessage(text: string, p: string)
	local latestMessageData = v.internal.getLatestMessageData()

	if latestMessageData and latestMessageData.Message == text and latestMessageData.Type == p then
		latestMessageData.Amount += 1
		latestMessageData.Lifetime = 6
		local v2 = not (latestMessageData.Amount < 99) and "99+" or tostring(latestMessageData.Amount) or "99+"
		latestMessageData.TextLabel.Text = `(x{v2}) {latestMessageData.Message}`
	else
		local outputLabel = v.internal.createOutputLabel()
		outputLabel.Text = text

		if p == "WARNING" then
			outputLabel.TextColor3 = Style.COLOR_ORANGE
		elseif p == "ERROR" then
			outputLabel.TextColor3 = Style.COLOR_RED
		end

		outputLabel.Parent = v.internal.ContentFrame
		table.insert(v.internal.OnScreenMessages, {
			Message = text,
			Type = p,
			Amount = 1,
			TextLabel = outputLabel,
			Lifetime = 6
		})
	end
end

RunService.Heartbeat:Connect(function(dt: number)
	for k, onScreenMessage in v.internal.OnScreenMessages do
		onScreenMessage.Lifetime -= dt

		if onScreenMessage.Lifetime > 0 then
			continue
		end

		onScreenMessage.TextLabel:Destroy()
		table.remove(v.internal.OnScreenMessages, k)
	end
end)
Widget.new("Code Warnings", function(parent2)
	local frame = Instance.new("Frame")
	frame.Name = "Content"
	frame.Position = UDim2.new(0, 8, 0, 48)
	frame.Size = UDim2.fromOffset(32, 32)
	frame.BackgroundTransparency = 1
	frame.AutomaticSize = Enum.AutomaticSize.XY
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 4)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = frame
	frame.Parent = parent2
	v.internal.ContentFrame = frame
	local messageAddedConnection = Console.MessageAdded:Connect(function(p: string, p2: string)
		if p2 == "INFO" then
			return
		end

		v.internal.addMessage(p, p2)
	end)
	return function()
		for _, onScreenMessage in v.internal.OnScreenMessages do
			onScreenMessage.TextLabel:Destroy()
		end

		v.internal.OnScreenMessages = {}
		messageAddedConnection:Disconnect()
		frame:Destroy()
	end
end)
return nil