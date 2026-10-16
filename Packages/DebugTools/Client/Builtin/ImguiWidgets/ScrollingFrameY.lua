local Imgui = require(script.Parent.Parent.Parent.Imgui)
Imgui:NewWidgetDefinition("ScrollingFrameY", {
	Construct = function(p, parent, size: UDim2, p2)
		local scrollingFrame = Instance.new("ScrollingFrame")
		scrollingFrame.Name = `ScrollingFrameY ({p.ID})`
		scrollingFrame.Size = size
		scrollingFrame.BackgroundTransparency = 1
		scrollingFrame.BorderSizePixel = 0
		scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scrollingFrame.CanvasSize = UDim2.fromScale(0, 0)
		scrollingFrame.ScrollBarThickness = 5
		scrollingFrame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		scrollingFrame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		scrollingFrame.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Name = "UIListLayout"
		uiListLayout.Padding = UDim.new(0, 2)
		uiListLayout.FillDirection = Enum.FillDirection.Horizontal
		uiListLayout.HorizontalAlignment = p2 or Enum.HorizontalAlignment.Left
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout.Parent = scrollingFrame
		p.UIListLayout = uiListLayout
		scrollingFrame.Parent = parent
		return scrollingFrame, scrollingFrame
	end,
	Update = function(p, size: UDim2, p2)
		p.TopInstance.Size = size
		p.UIListLayout.HorizontalAlignment = p2 or Enum.HorizontalAlignment.Left
	end
})
return nil