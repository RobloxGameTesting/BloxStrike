local color = Color3.fromRGB(125, 206, 243)

local function createHighlight(parent)
	local frame = Instance.new("Frame")
	frame.Name = "Selected"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BorderSizePixel = 0
	frame.ZIndex = -2
	frame.ClipsDescendants = true
	frame.Visible = false
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Rotation = -90
	uiGradient.Color = ColorSequence.new(Color3.fromRGB(195, 195, 195), Color3.fromRGB(53, 53, 53))
	uiGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.34375),
		NumberSequenceKeypoint.new(0.0857143, 0.46875),
		NumberSequenceKeypoint.new(0.32, 0.7),
		NumberSequenceKeypoint.new(0.704762, 0.88125),
		NumberSequenceKeypoint.new(1, 1)
	})
	uiGradient.Parent = frame
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Pattern"
	imageLabel.BackgroundColor3 = Color3.new(1, 1, 1)
	imageLabel.BackgroundTransparency = 1
	imageLabel.BorderSizePixel = 0
	imageLabel.Image = "rbxassetid://102274428506900"
	imageLabel.ImageTransparency = 0.21
	imageLabel.ScaleType = Enum.ScaleType.Fit
	imageLabel.Size = UDim2.fromScale(1.69762695, 3.10517287)
	imageLabel.Position = UDim2.fromScale(-0.348813593, -0.50142777)
	imageLabel.ZIndex = 0
	imageLabel.Parent = frame
	local uiGradient2 = Instance.new("UIGradient")
	uiGradient2.Rotation = -90
	uiGradient2.Transparency = NumberSequence.new(0, 1)
	uiGradient2.Parent = imageLabel
	frame.Parent = parent
	return frame
end

return function(instance, visible: boolean)
	if instance:GetAttribute("UnselectedColor") == nil then
		instance:SetAttribute("UnselectedColor", instance.BackgroundColor3)
	end

	local selected = instance:FindFirstChild("Selected")

	if not (selected and selected:IsA("GuiObject")) then
		selected = createHighlight(instance)
	end

	selected.Visible = visible
	local backgroundColor

	if visible then
		backgroundColor = color
	else
		backgroundColor = instance:GetAttribute("UnselectedColor")
	end

	instance.BackgroundColor3 = backgroundColor
end