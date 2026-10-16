local TweenService = game:GetService("TweenService")
local parent = script.Parent.Parent.Parent.Parent.Parent
local Shared = parent.Parent.Shared
local Action = require(Shared.Action)
local Console = require(parent.Builtin.Tabs.Console)
local Style = require(parent.Style)
local ActionArgument = require(script.Parent.ActionArgument)
return function(data, parent2, value: number?)
	local frame = Instance.new("Frame")
	frame.Name = data.RawName
	frame.Size = UDim2.fromScale(1, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundColor3 = Style.BACKGROUND
	frame.BorderSizePixel = 0
	frame.LayoutOrder = value or 0
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Header"
	textLabel.AutoLocalize = false
	textLabel.Size = UDim2.new(1, 0, 0, 16)
	textLabel.FontFace = Style.FONT_BOLD
	textLabel.Text = data.Name
	textLabel.TextColor3 = Style.COLOR_WHITE
	textLabel.TextSize = 16
	textLabel.TextStrokeTransparency = 0.5
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.LayoutOrder = -2
	local textLabel2 = Instance.new("TextLabel")
	textLabel2.Name = "Side"
	textLabel2.AutoLocalize = false
	textLabel2.Size = UDim2.new(1, 0, 0, 14)
	textLabel2.BackgroundTransparency = 1
	textLabel2.BorderSizePixel = 0
	textLabel2.FontFace = Style.FONT
	textLabel2.Text = data.ServerAction and "Server" or "Client"
	textLabel2.TextColor3 = data.ServerAction and Style.COLOR_RED or Style.COLOR_GREEN
	textLabel2.TextSize = 12
	textLabel2.TextXAlignment = Enum.TextXAlignment.Right
	textLabel2.BackgroundColor3 = Style.COLOR_WHITE
	textLabel2.Parent = textLabel
	textLabel.Parent = frame

	if data.Description then
		local textLabel3 = Instance.new("TextLabel")
		textLabel3.Name = "Description"
		textLabel3.AutoLocalize = false
		textLabel3.AutomaticSize = Enum.AutomaticSize.Y
		textLabel3.Position = UDim2.fromOffset(0, 14)
		textLabel3.Size = UDim2.new(1, 0, 0, 12)
		textLabel3.FontFace = Font.new("rbxasset://fonts/families/Inconsolata.json")
		textLabel3.Text = data.Description
		textLabel3.TextColor3 = Style.TAB_NORMAL_TEXT
		textLabel3.TextSize = 12
		textLabel3.TextStrokeTransparency = 0.75
		textLabel3.TextXAlignment = Enum.TextXAlignment.Left
		textLabel3.TextWrapped = true
		textLabel3.BackgroundTransparency = 1
		textLabel3.BorderSizePixel = 0
		textLabel3.LayoutOrder = -1
		textLabel3.Parent = frame
	end

	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 4)
	uiPadding.PaddingLeft = UDim.new(0, 4)
	uiPadding.PaddingRight = UDim.new(0, 4)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.Parent = frame
	local textButton = Instance.new("TextButton")
	textButton.Name = "Execute"
	textButton.AutoLocalize = false
	textButton.AnchorPoint = Vector2.new(1, 0)
	textButton.Position = UDim2.new(1, 0, 0, 30)
	textButton.Size = UDim2.new(1, 0, 0, 14)
	textButton.FontFace = Style.FONT
	textButton.Text = "Execute"
	textButton.TextColor3 = Style.PRIMARY_TEXT
	textButton.TextSize = 12
	textButton.BackgroundColor3 = Style.PRIMARY
	textButton.BorderSizePixel = 0
	textButton.LayoutOrder = 100
	textButton.Parent = frame
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 4)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = frame
	frame.Parent = parent2
	local v = {}
	local v2 = {}

	if data.Arguments then
		for k, argument in data.Arguments do
			v[k] = argument.Default
			argument.Index = k
			local v3 = k
			table.insert(v2, ActionArgument(frame, argument, function(p)
				v[v3] = p
			end))
		end
	end

	local function flashActionFrame(borderColor: Color3)
		frame.BorderColor3 = borderColor
		frame.BorderSizePixel = 3
		TweenService:Create(frame, TweenInfo.new(0.7, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
			BorderColor3 = Style.BACKGROUND,
			BorderSizePixel = 0
		}):Play()
	end

	local activatedConnection = textButton.Activated:Connect(function()
		local v3 = Action:Execute(data.RawName, v)
		local v4 = v3 == nil or v3

		if v4 == true then
			flashActionFrame(Style.COLOR_GREEN)
		elseif not v4 then
			flashActionFrame(Style.COLOR_RED)
		elseif typeof(v4) == "string" then
			flashActionFrame(Style.COLOR_ORANGE)
			Console:AddMessage(`Action '{data.RawName}' outcome: {v4}`, Enum.MessageType.MessageInfo, false)
		end
	end)
	return function()
		frame:Destroy()
		activatedConnection:Disconnect()

		for _, v3 in v2 do
			v3()
		end
	end
end