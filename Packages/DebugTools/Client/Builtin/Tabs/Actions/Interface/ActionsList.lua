local parent = script.Parent.Parent.Parent.Parent.Parent
local Style = require(parent.Style)
local ActionFrame = require(script.Parent.ActionFrame)
return function(parent2, object, object2)
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "Actions"
	scrollingFrame.AnchorPoint = Vector2.new(1, 0)
	scrollingFrame.Position = UDim2.fromScale(1, 0)
	scrollingFrame.Size = UDim2.fromScale(0.75, 1)
	scrollingFrame.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	scrollingFrame.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
	scrollingFrame.ScrollBarImageColor3 = Style.COLOR_BLACK
	scrollingFrame.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	scrollingFrame.Active = true
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.CanvasSize = UDim2.new()
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.Parent = scrollingFrame
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 8)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = scrollingFrame
	scrollingFrame.Parent = parent2
	local v = {}

	local function refreshActions()
		local v2 = object:Get()
		local v3 = object2:Get()

		if not v2 then
			return
		end

		local rawNames = {}

		for k in v3 do
			table.sort(v3[k], function(a, b)
				return a.Name < b.Name
			end)
		end

		for k, v4 in v3[v2] do
			table.insert(rawNames, v4.RawName)

			if not v[v4.RawName] then
				v[v4.RawName] = ActionFrame(v4, scrollingFrame, k)
			end
		end

		for k, v4 in v do
			if table.find(rawNames, k) then
				continue
			end

			v4()
			v[k] = nil
		end
	end

	local connection = object:Observe(function()
		refreshActions()
	end)
	local connection2 = object2:Observe(function()
		refreshActions()
	end)
	refreshActions()
	return function()
		connection:Disconnect()
		connection = nil
		connection2:Disconnect()
		connection2 = nil
		scrollingFrame:Destroy()
		scrollingFrame = nil

		for _, v2 in v do
			v2()
		end

		v = nil
	end
end