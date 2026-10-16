local Imgui = require(script.Parent.Parent.Parent.Imgui)
Imgui:NewWidgetDefinition("BeginHorizontal", {
	Construct = function(p, parent, p2)
		local frame = Instance.new("Frame")
		frame.Name = `Horizontal ({p.ID})`
		frame.Size = UDim2.fromScale(1, 0)
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Name = "UIListLayout"
		uiListLayout.Padding = UDim.new(0, 2)
		uiListLayout.FillDirection = Enum.FillDirection.Horizontal
		uiListLayout.HorizontalAlignment = p2 or Enum.HorizontalAlignment.Left
		uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout.Parent = frame
		p.UIListLayout = uiListLayout
		frame.Parent = parent
		return frame, frame
	end,
	Update = function(p, p2)
		p.UIListLayout.HorizontalAlignment = p2 or Enum.HorizontalAlignment.Left
	end
})
return nil