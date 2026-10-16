local Imgui = require(script.Parent.Parent.Parent.Parent.Imgui)
local v = {
	string = "#adf195",
	number = "#ffc600",
	Vector3 = "#ffc600",
	CFrame = "#ffc600",
	Instance = "#61a1f1",
	EnumItem = "#61a1f1",
	boolean = "#ff1a1a",
	["nil"] = "#ffc600"
}
Imgui:NewWidgetDefinition("PropertyLabel", {
	Construct = function(p, parent, p2, p3: string)
		local v2 = p2[p3]
		local v3 = tostring(v2)
		local typeName = typeof(v2)

		if typeName == "string" then
			v3 = `"{v3}"`
		end

		if v[typeName] then
			v3 = `<font color="{v[typeName]}">{v3}</font>`
		end

		local frame = Instance.new("Frame")
		frame.Name = `ExplorerHorizontal ({p.ID})`
		frame.Size = UDim2.new(1, 0, 0, 15)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Active = true
		local uiListLayout = Instance.new("UIListLayout")
		uiListLayout.Name = "UIListLayout"
		uiListLayout.Padding = UDim.new(0, 2)
		uiListLayout.FillDirection = Enum.FillDirection.Horizontal
		uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		uiListLayout.Parent = frame
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = `Label ({p.ID})`
		textLabel.Size = UDim2.fromScale(0.35, 1)
		textLabel.Text = `<b>{p3}</b>`
		textLabel.RichText = true
		textLabel.BackgroundTransparency = 1
		textLabel.BorderSizePixel = 0
		textLabel.Parent = frame
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		local textLabel2 = Instance.new("TextLabel")
		textLabel2.Name = `Label ({p.ID})`
		textLabel2.Size = UDim2.fromScale(0.65, 1)
		textLabel2.Position = UDim2.fromScale(0.35, 0)
		textLabel2.Text = `<i>{typeName}</i> [{v3}]`
		textLabel2.RichText = true
		textLabel2.BackgroundTransparency = 1
		textLabel2.BorderSizePixel = 0
		textLabel2.Parent = frame
		textLabel2.TextXAlignment = Enum.TextXAlignment.Left
		Imgui.applyTextStyle(textLabel)
		Imgui.applyTextStyle(textLabel2)
		p.TopInstance = frame
		frame.Parent = parent
		return frame
	end,
	Update = function(_, _, _: string) end
})
return nil