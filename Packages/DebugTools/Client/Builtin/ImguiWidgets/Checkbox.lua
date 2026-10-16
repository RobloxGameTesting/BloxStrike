local Imgui = require(script.Parent.Parent.Parent.Imgui)
Imgui:NewWidgetDefinition("Checkbox", {
	Events = {
		activated = {
			Evaluate = function(p)
				local pressed = p.Pressed
				p.Pressed = false
				return pressed
			end
		}
	},
	Construct = function(state, parent, text: string, visible: boolean)
		local frame = Instance.new("Frame")
		frame.Name = `Checkbox ({state.ID})`
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Text"
		textLabel.Text = text
		textLabel.AutomaticSize = Enum.AutomaticSize.XY
		textLabel.BackgroundTransparency = 1
		textLabel.BorderSizePixel = 0
		textLabel.LayoutOrder = 1
		Imgui.applyTextStyle(textLabel)
		textLabel.Parent = frame
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Name = "UIListLayout"
		uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uiListLayout.FillDirection = Enum.FillDirection.Horizontal
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout.Parent = frame
		uiListLayout.Padding = UDim.new(0, Imgui:GetConfig().Sizes.ItemPadding.X)
		local textButton = Instance.new("TextButton")
		textButton.Name = "TextButton"
		textButton.AutoLocalize = false
		textButton.Size = UDim2.fromOffset(18, 18)
		textButton.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
		textButton.Text = ""
		textButton.TextSize = 14
		textButton.BackgroundColor3 = Color3.fromRGB(54, 54, 54)
		textButton.BorderSizePixel = 0
		local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		uiAspectRatioConstraint.Name = "UIAspectRatioConstraint"
		uiAspectRatioConstraint.Parent = textButton
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "Status ImageLabel"
		imageLabel.Size = UDim2.fromScale(1, 1)
		imageLabel.Image = "rbxassetid://15225522557"
		imageLabel.ImageColor3 = Imgui:GetConfig().Colors.Checkbox
		imageLabel.Visible = visible
		imageLabel.BackgroundTransparency = 1
		imageLabel.BorderSizePixel = 0
		imageLabel.Parent = textButton
		textButton.Parent = frame
		frame.Parent = parent
		state.CheckboxButton = textButton
		state.TextLabel = textLabel
		state.StatusImageLabel = imageLabel
		state.Status = visible or true
		state.PressConnection = textButton.Activated:Connect(function()
			state.Pressed = true
			state.Status = not state.Status
		end)
		return frame
	end,
	Deconstruct = function(p)
		p.PressConnection:Disconnect()
	end,
	Update = function(state, text: string, flag: boolean)
		state.Status = flag
		state.TextLabel.Text = text
		state.StatusImageLabel.Visible = flag
	end
})
return nil