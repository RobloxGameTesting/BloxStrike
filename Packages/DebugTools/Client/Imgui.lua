local RunService = game:GetService("RunService")
local v = {
	private = {
		WidgetDefinitions = {},
		Instances = {},
		ProcessedInstance = nil,
		CurrentConfig = table.freeze({
			Font = Font.new("rbxasset://fonts/families/Inconsolata.json"),
			Transparency = { Window = 0.15 },
			Sizes = {
				TextSize = 12,
				FrameCornerRadius = 4,
				ItemPadding = Vector2.new(4, 4),
				FramePadding = Vector2.new(5, 3)
			},
			Colors = {
				WindowBackground = Color3.fromRGB(26, 26, 33),
				Text = Color3.new(1, 1, 1),
				TextDisabled = Color3.new(0.5, 0.5, 0.5),
				Button = Color3.fromRGB(98, 114, 164),
				ButtonHovered = Color3.new(0.19, 0.2, 0.25),
				ButtonActive = Color3.new(0.16, 0.16, 0.21),
				Checkbox = Color3.fromRGB(255, 184, 108)
			}
		})
	},
	public = {}
}

function v.private.GetLineUniqueID()
	local processedInstance = v.private.ProcessedInstance

	if not processedInstance then
		error("Tried to get line unique id but instance is not running!")
	end

	local v2 = 4
	local v3 = debug.info(v2, "l")
	local v4 = {}

	while v3 ~= -1 and v3 ~= nil do
		table.insert(v4, v3)
		v2 += 1
		v3 = debug.info(v2, "l")
	end

	local joined = table.concat(v4)

	if processedInstance.FrameData.WidgetIDs[joined] then
		processedInstance.FrameData.WidgetIDs[joined] += 1
	else
		processedInstance.FrameData.WidgetIDs[joined] = 1
	end

	return joined .. "/" .. processedInstance.FrameData.WidgetIDs[joined]
end

function v.private.GetStackParent()
	if not v.private.ProcessedInstance then
		error("Tried to get stack parent but no instance is active")
	end

	local count = #v.private.ProcessedInstance.FrameData.Stack

	if count == 0 then
		return v.private.ProcessedInstance.Parent
	end

	return v.private.ProcessedInstance.FrameData.Stack[count].TopInstance
end

function v.private.ProcessFrame()
	for _, instance in v.private.Instances do
		v.private.ProcessedInstance = instance
		instance.Tick += 1
		instance.FrameData.CurrentWidget = nil
		instance.FrameData.PreviousWidget = nil
		instance.FrameData.WidgetIndex = 0
		instance.FrameData.Stack = {}
		instance.FrameData.WidgetIDs = {}
		v.public:BeginVertical()
		instance.TickLoop()
		v.public:End()

		for _, widget in instance.Widgets do
			if not (widget.LastUpdateTick < instance.Tick) then
				continue
			end

			v.private.DestroyWidget(widget)
			instance.Widgets[widget.ID] = nil
		end
	end

	v.private.ProcessedInstance = nil
end

function v.private:DestroyImguiInstance()
	table.remove(v.private.Instances, table.find(v.private.Instances, self))

	for _, widget in self.Widgets do
		v.private.DestroyWidget(widget)
	end

	self.Widgets = nil
end

function v.private.DestroyWidget(data)
	local widgetDefinition = v.private.WidgetDefinitions[data.Definition]

	if widgetDefinition.Deconstruct then
		widgetDefinition.Deconstruct(data)
	end

	data.TopInstance:Destroy()

	if data.ChildrenInstance then
		data.ChildrenInstance:Destroy()
	end
end

function v.private.CreateWidgetFromDefinition(definition: string, ...)
	local processedInstance = v.private.ProcessedInstance

	if not processedInstance then
		error("Tried to create widget but no instance is active")
	end

	processedInstance.FrameData.WidgetIndex += 1
	local widgetDefinition = v.private.WidgetDefinitions[definition]
	local lineUniqueID = v.private.GetLineUniqueID()
	local widget = processedInstance.Widgets[lineUniqueID]

	if widget then
		local args = { ... }

		for k, arg in widget.Args do
			if args[k] == arg then
				continue
			end

			widget.Args = args
			widgetDefinition.Update(widget, ...)
			break
		end
	else
		local stackParent = v.private.GetStackParent()

		if not stackParent then
			error("No stack parent")
		end

		widget = {
			ID = lineUniqueID,
			Definition = definition,
			LastUpdateTick = processedInstance.Tick,
			Args = { ... }
		}
		local topInstance, childrenInstance = widgetDefinition.Construct(widget, stackParent, ...)
		widget.TopInstance = topInstance

		if childrenInstance then
			widget.ChildrenInstance = childrenInstance
		end

		if widgetDefinition.Events then
			for k, event in widgetDefinition.Events do
				if event.Setup then
					event.Setup(widget)
				end

				local v2 = event

				widget[k] = function()
					return v2.Evaluate(widget)
				end
			end
		end

		processedInstance.Widgets[lineUniqueID] = widget
	end

	if widget and widget.ChildrenInstance then
		table.insert(processedInstance.FrameData.Stack, widget)
	end

	if v.private.ProcessedInstance then
		widget.LastUpdateTick = v.private.ProcessedInstance.Tick
		widget.TopInstance.LayoutOrder = processedInstance.FrameData.WidgetIndex
	end

	return widget
end

function v.public:End()
	local processedInstance = v.private.ProcessedInstance

	if not processedInstance then
		error("No active instance")
	end

	local count = #processedInstance.FrameData.Stack

	if count <= 1 then
		return
	end

	table.remove(processedInstance.FrameData.Stack, count)
end

function v.public:Connect(parent, tickLoop)
	local v2 = {
		Parent = parent,
		Tick = 0,
		FrameData = { Stack = {}, WidgetIDs = {}, WidgetIndex = 0 },
		Widgets = {},
		TickLoop = tickLoop
	}
	table.insert(v.private.Instances, v2)
	return function()
		v.private.DestroyImguiInstance(v2)
	end
end

function v.public.NewWidgetDefinition(_, p: string, p2)
	if v.public[p] then
		error("Couldn't use identifier as already something else is using it")
	end

	v.private.WidgetDefinitions[p] = p2

	v.public[p] = function(_, ...)
		return v.private.CreateWidgetFromDefinition(p, ...)
	end
end

function v.public.GetTick()
	return v.private.ProcessedInstance and v.private.ProcessedInstance.Tick or 0
end

function v.public.applyFrameStyle(parent)
	local currentConfig = v.private.CurrentConfig

	if currentConfig.Sizes.FramePadding.X > 0 or currentConfig.Sizes.FramePadding.Y > 0 then
		local uiPadding = Instance.new("UIPadding")
		uiPadding.PaddingLeft = UDim.new(0, currentConfig.Sizes.FramePadding.X)
		uiPadding.PaddingRight = UDim.new(0, currentConfig.Sizes.FramePadding.X)
		uiPadding.PaddingTop = UDim.new(0, currentConfig.Sizes.FramePadding.Y)
		uiPadding.PaddingBottom = UDim.new(0, currentConfig.Sizes.FramePadding.Y)
		uiPadding.Parent = parent
	end

	if currentConfig.Sizes.FrameCornerRadius > 0 then
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0, currentConfig.Sizes.FrameCornerRadius)
		uiCorner.Parent = parent
	end
end

function v.public.GetConfig(_)
	return v.private.CurrentConfig
end

function v.public:applyTextStyle()
	self.FontFace = v.private.CurrentConfig.Font
	self.TextSize = v.private.CurrentConfig.Sizes.TextSize
	self.TextColor3 = v.private.CurrentConfig.Colors.Text
	self.AutoLocalize = false
end

function v.public:applyMouseDownStyle(callback)
	return self.MouseButton1Down:Connect(function()
		self.BackgroundColor3 = v.private.CurrentConfig.Colors.ButtonActive
		callback()
	end)
end

function v.public:applyMouseUpStyle(callback)
	return self.MouseButton1Up:Connect(function()
		self.BackgroundColor3 = v.private.CurrentConfig.Colors.ButtonHovered
		callback()
	end)
end

function v.public:applyMouseHoverStyle(callback)
	return self.MouseEnter:Connect(function()
		self.BackgroundColor3 = v.private.CurrentConfig.Colors.ButtonHovered
		callback()
	end)
end

function v.public:applyMouseHoverEndStyle(callback)
	return self.MouseLeave:Connect(function()
		self.BackgroundColor3 = v.private.CurrentConfig.Colors.Button
		callback()
	end)
end

RunService.Heartbeat:Connect(v.private.ProcessFrame)
return v.public