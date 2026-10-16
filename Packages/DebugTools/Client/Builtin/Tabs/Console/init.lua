local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local parent = script.Parent.Parent.Parent
local Shared = parent.Parent.Shared
local Tab = require(parent.Tab)
local Style = require(parent.Style)
local Networking = require(parent.Networking)
local Signal = require(Shared.Signal)
local Message = require(script.Message)
local OutputModal = require(script.OutputModal)
local v = {
	[Enum.MessageType.MessageError] = "ERROR",
	[Enum.MessageType.MessageWarning] = "WARNING",
	[Enum.MessageType.MessageOutput] = "INFO",
	Default = "INFO"
}
table.freeze(v)
local v2 = {
	internal = {
		Messages = {},
		LatestMessage = nil,
		ParsingMessageStack = false,
		BreakpointNumber = 0,
		Interface = { ConsoleFrame = nil, MessagesScrollingFrame = nil }
	},
	interface = { MessageAdded = Signal.new() }
}

function v2.internal.mergeLatestExactMessages()
	local messages = v2.internal.Messages
	local count = #messages

	if count < 2 then
		return
	end

	local message = messages[count - 1]
	local message2 = messages[count]
	local v3 = message2.Content == message.Content

	if message2.ContentType == message.ContentType and v3 then
		message:IncreaseCount()
		message2:Destroy()
		table.remove(messages, table.find(messages, message2))
		v2.internal.LatestMessage = message
	end
end

function v2.internal.createModuleInterface()
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = script
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "Messages"
	scrollingFrame.Size = UDim2.new(1, 0, 1, -20)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.BackgroundColor3 = Style.COLOR_BLACK
	scrollingFrame.BackgroundTransparency = 0.5
	scrollingFrame.TopImage = scrollingFrame.MidImage
	scrollingFrame.BottomImage = scrollingFrame.MidImage
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	scrollingFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.Parent = frame
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 1)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = scrollingFrame
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.Parent = scrollingFrame
	local uiPadding2 = Instance.new("UIPadding")
	uiPadding2.Name = "UIPadding"
	uiPadding2.PaddingBottom = UDim.new(0, 8)
	uiPadding2.PaddingLeft = UDim.new(0, 8)
	uiPadding2.PaddingRight = UDim.new(0, 8)
	uiPadding2.PaddingTop = UDim.new(0, 10)
	uiPadding2.Parent = frame
	local frame2 = Instance.new("Frame")
	frame2.Name = "Bottom Buttons"
	frame2.AnchorPoint = Vector2.new(0, 1)
	frame2.Position = UDim2.new(0, 0, 1, 0)
	frame2.Size = UDim2.new(1, 0, 0, 12)
	frame2.BackgroundTransparency = 1
	frame2.BorderSizePixel = 0
	frame2.Parent = frame
	local uiListLayout2 = Instance.new("UIListLayout")
	uiListLayout2.Name = "UIListLayout"
	uiListLayout2.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout2.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout2.HorizontalAlignment = Enum.HorizontalAlignment.Right
	uiListLayout2.Padding = UDim.new(0, 8)
	uiListLayout2.Parent = frame2
	local textButton = Instance.new("TextButton")
	textButton.Size = UDim2.fromOffset(0, 12)
	textButton.AutoLocalize = false
	textButton.BackgroundColor3 = Style.COLOR_RED
	textButton.AutomaticSize = Enum.AutomaticSize.X
	textButton.BorderSizePixel = 0
	textButton.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textButton.Text = "Clear"
	textButton.TextSize = 12
	textButton.LayoutOrder = 3
	textButton.Parent = frame2
	local uiPadding3 = Instance.new("UIPadding")
	uiPadding3.Name = "UIPadding"
	uiPadding3.PaddingLeft = UDim.new(0, 8)
	uiPadding3.PaddingRight = UDim.new(0, 8)
	uiPadding3.Parent = textButton
	textButton.Activated:Connect(function()
		v2.interface:ClearOutput()
	end)
	local textButton2 = Instance.new("TextButton")
	textButton2.AutoLocalize = false
	textButton2.Size = UDim2.fromOffset(0, 12)
	textButton2.BackgroundColor3 = Style.TAB_FOCUSED_BACKGROUND
	textButton2.AutomaticSize = Enum.AutomaticSize.X
	textButton2.BorderSizePixel = 0
	textButton2.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textButton2.Text = "Breakpoint (1)"
	textButton2.TextSize = 12
	textButton2.LayoutOrder = 1
	textButton2.Parent = frame2
	local uiPadding4 = Instance.new("UIPadding")
	uiPadding4.Name = "UIPadding"
	uiPadding4.PaddingLeft = UDim.new(0, 8)
	uiPadding4.PaddingRight = UDim.new(0, 8)
	uiPadding4.Parent = textButton2
	textButton2.Activated:Connect(function()
		v2.internal.BreakpointNumber += 1
		textButton2.Text = `Breakpoint ({v2.internal.BreakpointNumber + 1})`
		v2.interface:AddMessage(`Breakpoint {v2.internal.BreakpointNumber}`, Enum.MessageType.MessageInfo, false)
	end)
	local textButton3 = Instance.new("TextButton")
	textButton3.AutoLocalize = false
	textButton3.Size = UDim2.fromOffset(0, 12)
	textButton3.BackgroundColor3 = Style.TAB_FOCUSED_BACKGROUND
	textButton3.AutomaticSize = Enum.AutomaticSize.X
	textButton3.BorderSizePixel = 0
	textButton3.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
	textButton3.Text = "Output Log"
	textButton3.TextSize = 12
	textButton3.LayoutOrder = 2
	textButton3.Parent = frame2
	local uiPadding5 = Instance.new("UIPadding")
	uiPadding5.Name = "UIPadding"
	uiPadding5.PaddingLeft = UDim.new(0, 8)
	uiPadding5.PaddingRight = UDim.new(0, 8)
	uiPadding5.Parent = textButton3
	textButton3.Activated:Connect(function()
		local v3 = OutputModal.new(v2.interface:GetOutputLog())
		v3:ParentTo(frame)
		v3.CloseActivated:Connect(function()
			v3:Destroy()
			v3 = nil
		end)
	end)
	v2.internal.Interface.ConsoleFrame = frame
	v2.internal.Interface.MessagesScrollingFrame = scrollingFrame
end

function v2.interface:GetOutputLog()
	local v3 = os.date("*t")
	local formatted = `{string.format("%02d", v3.hour)}:{string.format("%02d", v3.min)}:{string.format("%02d", v3.sec)}/{string.format("%02d", v3.day)}.{string.format("%02d", v3.month)}.{v3.year}`
	local formatted2 = `p{game.PlaceId}_v{game.PlaceVersion}_{os.time()}\nGenerated at [{formatted}] by {Players.LocalPlayer.Name}@{Players.LocalPlayer.DisplayName}\n`

	for _, message in v2.internal.Messages do
		local v4 = tostring((math.floor((message.Timestamp - math.floor(message.Timestamp)) * 1000)))
		formatted2 ..= `{not (message.Amount > 1) and "" or `[x{message.Amount}]` or ""}[{message.ServerSide and "SERVER" or "CLIENT"}][{os.date("%X", message.Timestamp)}.{v4}][{message.ContentType}] {message.Content}\n`
	end

	return formatted2
end

function v2.internal:Init()
	v2.internal.createModuleInterface()

	for _, v3 in LogService:GetLogHistory() do
		v2.interface:AddMessage(v3.message, v3.messageType, false, v3.timestamp)
	end

	LogService.MessageOut:Connect(function(p: string, p2)
		v2.interface:AddMessage(p, p2, false)
	end)
	Networking:SubscribeToTopic("console_messages", function(p, p2: string, p3: number)
		v2.interface:AddMessage(p2, p, true, p3)
	end)
end

function v2.internal:MountInterface(parent2)
	if not v2.internal.Interface.ConsoleFrame then
		return
	end

	v2.internal.Interface.ConsoleFrame.Parent = parent2
end

function v2.internal:UnmountInterface()
	if not v2.internal.Interface.ConsoleFrame then
		return
	end

	v2.internal.Interface.ConsoleFrame.Parent = script
end

function v2.interface:AddMessage(p: string, p2, flag: boolean, p3: number?)
	if v2.internal.LatestMessage and p2 == Enum.MessageType.MessageInfo then
		if p == "Stack Begin" then
			v2.internal.ParsingMessageStack = true

			if v2.internal.LatestMessage.ContentType == "INFO" then
				v2.internal.LatestMessage:ChangeType("ERROR")
			end

			return
		else
			if p == "Stack End" then
				v2.internal.ParsingMessageStack = false
				return
			end

			if v2.internal.ParsingMessageStack then
				v2.internal.LatestMessage:Concatenate(`\n  ╠ {p}`)
				v2.internal.mergeLatestExactMessages()
				return
			end
		end
	end

	local v3 = v[p2] or v.Default
	local latestMessage = Message.new(p, v3, flag, p3)
	latestMessage:SetParent(v2.internal.Interface.MessagesScrollingFrame)
	table.insert(v2.internal.Messages, latestMessage)

	if #v2.internal.Messages > 400 then
		v2.internal.Messages[1]:Destroy()
		table.remove(v2.internal.Messages, 1)
	end

	v2.internal.LatestMessage = latestMessage
	v2.internal.mergeLatestExactMessages()
	v2.interface.MessageAdded:Fire(p, v3)
end

function v2.interface:ClearOutput()
	for _, message in v2.internal.Messages do
		message:Destroy()
	end

	v2.internal.Messages = {}
	v2.internal.ParsingMessageStack = false
end

v2.internal:Init()
Tab.new("Console", function(p)
	v2.internal:MountInterface(p)
	return function()
		v2.internal:UnmountInterface()
	end
end)
return v2.interface