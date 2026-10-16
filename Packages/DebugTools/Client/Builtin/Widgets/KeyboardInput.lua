local UserInputService = game:GetService("UserInputService")
local parent = script.Parent.Parent.Parent
local Constants = require(parent.Parent.Shared.Constants)

if not Constants.DEFAULT_WIDGETS_ENABLED then
	return nil
end

local Widget = require(parent.Widget)
local v = {
	[Enum.KeyCode.One] = "1",
	[Enum.KeyCode.Two] = "2",
	[Enum.KeyCode.Three] = "3",
	[Enum.KeyCode.Four] = "4",
	[Enum.KeyCode.Five] = "5",
	[Enum.KeyCode.Six] = "6",
	[Enum.KeyCode.Seven] = "7",
	[Enum.KeyCode.Eight] = "8",
	[Enum.KeyCode.Nine] = "9",
	[Enum.KeyCode.Zero] = "0",
	[Enum.KeyCode.Backspace] = "<-",
	[Enum.KeyCode.BackSlash] = "|",
	[Enum.KeyCode.Slash] = "/",
	[Enum.KeyCode.Comma] = ".",
	[Enum.KeyCode.Period] = ",",
	[Enum.KeyCode.Quote] = "'",
	[Enum.KeyCode.Semicolon] = ";",
	[Enum.KeyCode.RightBracket] = "]",
	[Enum.KeyCode.LeftBracket] = "[",
	[Enum.KeyCode.Backquote] = "`",
	[Enum.KeyCode.Minus] = "-",
	[Enum.KeyCode.Equals] = "=",
	[Enum.KeyCode.LeftShift] = "LS",
	[Enum.KeyCode.LeftAlt] = "LA",
	[Enum.KeyCode.LeftControl] = "LC",
	[Enum.KeyCode.RightShift] = "RS",
	[Enum.KeyCode.RightAlt] = "RA",
	[Enum.KeyCode.RightControl] = "RC",
	[Enum.KeyCode.Space] = "⬆️"
}

local function createKeyVisual(keyCode)
	local frame = Instance.new("Frame")
	frame.Name = "Key"
	frame.Size = UDim2.fromOffset(32, 32)
	frame.BackgroundColor3 = Color3.fromRGB(49, 47, 40)
	frame.BorderSizePixel = 0
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = frame
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "KeyLabel"
	textLabel.AutoLocalize = false
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/SourceSansPro.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.Text = v[keyCode] or tostring(keyCode.Name)
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 24
	textLabel.BackgroundTransparency = 1
	textLabel.LayoutOrder = 1
	textLabel.Parent = frame
	return frame
end

Widget.new("Keyboard Input", function(parent2)
	local frame = Instance.new("Frame")
	frame.Name = "MinimalContent"
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Position = UDim2.new(0, 8, 1, -88)
	frame.Size = UDim2.fromOffset(48, 48)
	frame.AutomaticSize = Enum.AutomaticSize.X
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	local frame2 = Instance.new("Frame")
	frame2.Name = "Content"
	frame2.Size = UDim2.fromOffset(48, 48)
	frame2.AutomaticSize = Enum.AutomaticSize.XY
	frame2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame2.BackgroundTransparency = 0.5
	frame2.Visible = false
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.Parent = frame2
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = frame2
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 2)
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = frame2
	frame2.Parent = frame
	frame.Parent = parent2
	local v2 = 0
	local inputBeganConnection = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Unknown then
			return
		end

		local keyVisual = createKeyVisual(input.KeyCode)
		keyVisual.Parent = frame2
		v2 += 1
		frame2.Visible = true
		task.delay(1.7, function()
			keyVisual:Destroy()
			v2 -= 1

			if v2 <= 0 and frame2 then
				frame2.Visible = false
			end
		end)
	end)
	return function()
		frame:Destroy()
		frame = nil
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end
end)
return nil