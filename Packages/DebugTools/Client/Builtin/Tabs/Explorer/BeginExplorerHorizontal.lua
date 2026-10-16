local Imgui = require(script.Parent.Parent.Parent.Parent.Imgui)
local v = { [Enum.UserInputType.MouseButton1] = true, [Enum.UserInputType.Touch] = true }
Imgui:NewWidgetDefinition("BeginExplorerHorizontal", {
	Events = {
		activated = {
			Setup = function(p)
				p.TopInstance.InputBegan:Connect(function(input)
					if not v[input.UserInputType] then
						return
					end

					p.WasPressed = true
				end)
			end,
			Evaluate = function(p)
				local wasPressed = p.WasPressed
				p.WasPressed = false
				return wasPressed
			end
		}
	},
	Construct = function(p, parent, flag: boolean?, p2)
		local frame = Instance.new("Frame")
		frame.Name = `ExplorerHorizontal ({p.ID})`
		frame.Size = UDim2.fromScale(1, 0)
		frame.AutomaticSize = Enum.AutomaticSize.XY
		frame.BackgroundTransparency = flag and 0.5 or 1
		frame.BorderSizePixel = 0
		frame.Active = true
		frame.BackgroundColor3 = Color3.fromHex("#0b5aaf")
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Name = "UIListLayout"
		uiListLayout.Padding = UDim.new(0, 2)
		uiListLayout.FillDirection = Enum.FillDirection.Horizontal
		uiListLayout.HorizontalAlignment = p2 or Enum.HorizontalAlignment.Left
		uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout.Parent = frame
		p.TopInstance = frame
		p.UIListLayout = uiListLayout
		frame.Parent = parent
		return frame, frame
	end,
	Update = function(p, flag: boolean?, p2)
		p.UIListLayout.HorizontalAlignment = p2 or Enum.HorizontalAlignment.Left
		p.TopInstance.BackgroundTransparency = flag and 0 or 1
	end
})
return nil