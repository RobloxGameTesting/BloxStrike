return function(instance)
	local uiGridLayout = instance:FindFirstChildOfClass("UIGridLayout")

	if not uiGridLayout then
		return 50
	end

	local x = instance.AbsoluteSize.X
	local y = instance.AbsoluteSize.Y
	local v = uiGridLayout.CellSize.X.Scale * x + uiGridLayout.CellSize.X.Offset
	local v2 = uiGridLayout.CellSize.Y.Scale * y + uiGridLayout.CellSize.Y.Offset
	local v3 = uiGridLayout.CellPadding.X.Scale * x + uiGridLayout.CellPadding.X.Offset
	local v4 = uiGridLayout.CellPadding.Y.Scale * y + uiGridLayout.CellPadding.Y.Offset
	local uiPadding = instance:FindFirstChildOfClass("UIPadding")

	if uiPadding then
		x -= (uiPadding.PaddingLeft.Scale + uiPadding.PaddingRight.Scale) * x + uiPadding.PaddingLeft.Offset + uiPadding.PaddingRight.Offset
		y -= (uiPadding.PaddingTop.Scale + uiPadding.PaddingBottom.Scale) * y + uiPadding.PaddingTop.Offset + uiPadding.PaddingBottom.Offset
	end

	local v5 = not (v + v3 > 0) and 1 or math.max(1, (math.floor((x + v3) / (v + v3))))
	return ((not (v2 + v4 > 0) and 1 or math.max(1, (math.floor((y + v4) / (v2 + v4))))) + 1) * v5
end