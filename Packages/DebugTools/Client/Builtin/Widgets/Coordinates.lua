local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local parent = script.Parent.Parent.Parent
local Constants = require(parent.Parent.Shared.Constants)

if not Constants.DEFAULT_WIDGETS_ENABLED then
	return nil
end

local Widget = require(parent.Widget)
Widget.new("Coordinates", function(parent2)
	local frame = Instance.new("Frame")
	frame.Name = "Content"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -8)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.AutomaticSize = Enum.AutomaticSize.XY
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 4)
	uiPadding.PaddingLeft = UDim.new(0, 4)
	uiPadding.PaddingRight = UDim.new(0, 4)
	uiPadding.PaddingTop = UDim.new(0, 4)
	uiPadding.Parent = frame
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = frame
	local textBox = Instance.new("TextBox")
	textBox.Name = "CoordinatesTextBox"
	textBox.AutoLocalize = false
	textBox.Size = UDim2.fromOffset(0, 14)
	textBox.BackgroundTransparency = 1
	textBox.FontFace = Font.new(
		"rbxasset://fonts/families/SourceSansPro.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textBox.Text = "X: 0.00 Y: 0.00 Z: 0.00"
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.TextSize = 14
	textBox.TextTransparency = 0.33
	textBox.AutomaticSize = Enum.AutomaticSize.X
	textBox.LayoutOrder = 3
	textBox.Visible = false
	textBox.TextEditable = false
	textBox.ClearTextOnFocus = false
	textBox.Parent = frame
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "CoordinatesLabel"
	textLabel.AutoLocalize = false
	textLabel.Size = UDim2.fromOffset(0, 14)
	textLabel.BackgroundTransparency = 1
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/SourceSansPro.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.Text = "X: 0.00 Y: 0.00 Z: 0.00"
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 14
	textLabel.TextTransparency = 0.33
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.LayoutOrder = 3
	textLabel.Parent = frame
	frame.Parent = parent2
	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not Players.LocalPlayer.Character then
			textLabel.Text = "No character"
			return
		end

		local primaryPart = Players.LocalPlayer.Character.PrimaryPart

		if not primaryPart then
			textLabel.Text = "No character"
			return
		end

		if UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt) then
			textBox.Visible = true
			textLabel.Visible = false
		else
			textBox.Visible = false
			textLabel.Visible = true
		end

		local position = primaryPart.Position
		textBox.Text = `{string.format("%.3f", position.X)}, {string.format("%.3f", position.Y)}, {string.format("%.3f", position.Z)}`
		textLabel.Text = `X: {string.format("%.3f", position.X)} Y: {string.format("%.3f", position.Y)} Z: {string.format("%.3f", position.Z)}`
	end)
	return function()
		frame:Destroy()
		frame = nil
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end)
return nil