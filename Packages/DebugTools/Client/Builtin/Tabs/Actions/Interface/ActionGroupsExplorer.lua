local ActionGroupButton = require(script.Parent.ActionGroupButton)
return function(parent, object, p, callback)
	local frame = Instance.new("Frame")
	frame.Name = "Actions Explorer"
	frame.BackgroundColor3 = Color3.fromRGB(172, 195, 245)
	frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(0.25, 1)
	local frame2 = Instance.new("Frame")
	frame2.Name = "Gradient"
	frame2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame2.BackgroundTransparency = 0.8
	frame2.BorderSizePixel = 0
	frame2.Position = UDim2.fromScale(1, 0)
	frame2.Size = UDim2.fromScale(0.05, 1)
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Name = "UIGradient"
	uiGradient.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	uiGradient.Parent = frame2
	frame2.Parent = frame
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "ScrollingFrame"
	scrollingFrame.CanvasSize = UDim2.new()
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.Size = UDim2.fromScale(1, 1)
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 2)
	uiListLayout.Parent = scrollingFrame
	scrollingFrame.Parent = frame
	frame.Parent = parent
	local v = {}
	object:Observe(function(items)
		for _, item in items do
			if v[item] then
				continue
			end

			local v2 = item
			v[item] = ActionGroupButton(item, scrollingFrame, p, function()
				callback(v2)
			end)
		end
	end)
	return function()
		frame:Destroy()
		frame = nil

		for _, v2 in v do
			v2()
		end

		v = nil
	end
end