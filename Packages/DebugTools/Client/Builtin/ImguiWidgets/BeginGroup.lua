local Imgui = require(script.Parent.Parent.Parent.Imgui)
Imgui:NewWidgetDefinition("BeginGroup", {
	Construct = function(p, parent, size: UDim2, p2)
		local frame = Instance.new("Frame")
		frame.Name = `Group ({p.ID})`
		frame.Size = size
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Name = "UIListLayout"
		uiListLayout.Padding = UDim.new(0, 2)
		uiListLayout.FillDirection = Enum.FillDirection.Horizontal
		uiListLayout.HorizontalAlignment = p2 or Enum.HorizontalAlignment.Left
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout.Parent = frame
		p.UIListLayout = uiListLayout
		frame.Parent = parent
		return frame, frame
	end,
	Update = function(p, size: UDim2, p2)
		p.TopInstance.Size = size
		p.UIListLayout.HorizontalAlignment = p2 or Enum.HorizontalAlignment.Left
	end
})
return nil