local UserInputService = game:GetService("UserInputService")
local parent = script.Parent.Parent.Parent
local Tab = require(parent.Tab)
local Widget = require(parent.Widget)
local WidgetVisual = require(script.WidgetVisual)
local WidgetsList = require(script.WidgetsList)
local v = {
	internal = {
		WidgetVisuals = {},
		DraggedWidgetVisual = false,
		ActiveInputEndedConnection = nil,
		ActiveInputChangedConnection = nil,
		CurrentCameraChangedConnection = nil,
		CurrentViewportSizeChangedConnection = nil,
		FakeScreen = {}
	}
}

function v.internal.createWidgetRepresentation(p: string, p2)
	local widgetVisual = WidgetVisual.new(p, p2, v.internal.FakeScreen.ScreenFrame)
	table.insert(v.internal.WidgetVisuals, { WidgetVisual = widgetVisual })
	v.internal.listenToWidgetVisualEvents(widgetVisual)
end

function v.internal.getRegistryWidgetRecord(p)
	for _, widgetVisual in v.internal.WidgetVisuals do
		if widgetVisual.WidgetVisual == p then
			return widgetVisual
		end
	end

	return nil
end

function v.internal.listenToWidgetVisualEvents(draggedWidgetVisual)
	local registryWidgetRecord = v.internal.getRegistryWidgetRecord(draggedWidgetVisual)

	if not registryWidgetRecord then
		return
	end

	registryWidgetRecord.ActivatedConnection = draggedWidgetVisual.Activated:Connect(function(point: Vector2)
		if v.internal.DraggedWidgetVisual then
			return
		end

		v.internal.DraggedWidgetVisual = draggedWidgetVisual
		v.internal.ActiveInputChangedConnection = UserInputService.InputChanged:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			local absoluteSize = v.internal.FakeScreen.ScreenFrame.AbsoluteSize
			local absolutePosition = v.internal.FakeScreen.ScreenFrame.AbsolutePosition
			local v2 = -(draggedWidgetVisual.FrameRepresentation.AbsoluteSize * -draggedWidgetVisual.BoundingInstance.AnchorPoint)
			local v3 = (Vector2.new(input.Position.X, input.Position.Y) - absolutePosition - point + v2) / absoluteSize
			draggedWidgetVisual.BoundingInstance.Position = UDim2.fromScale(v3.X, v3.Y)
		end)
		v.internal.ActiveInputEndedConnection = UserInputService.InputEnded:Connect(function(input)
			if
				input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch
			then
				return
			end

			v.internal.ActiveInputChangedConnection:Disconnect()
			v.internal.ActiveInputChangedConnection = nil
			v.internal.ActiveInputEndedConnection:Disconnect()
			v.internal.ActiveInputEndedConnection = nil
			v.internal.DraggedWidgetVisual = nil
		end)
	end)
end

function v.internal.listenToCurrentCameraViewportChanges()
	if v.internal.CurrentViewportSizeChangedConnection then
		v.internal.CurrentViewportSizeChangedConnection:Disconnect()
	end

	v.internal.CurrentViewportSizeChangedConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		local viewportSize = workspace.CurrentCamera.ViewportSize

		if not v.internal.FakeScreen then
			return
		end

		v.internal.FakeScreen.ScreenFrameAspectRatio.AspectRatio = viewportSize.X / viewportSize.Y
	end)
end

function v.internal.createWidgetInterface(parent2)
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local frame = Instance.new("Frame")
	frame.Name = "Fake Screen"
	frame.Position = UDim2.fromScale(0, 0.5)
	frame.Size = UDim2.fromScale(0.75, 1)
	frame.AnchorPoint = Vector2.new(0, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(79, 88, 105)
	frame.BorderSizePixel = 0
	local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.Name = "UIAspectRatioConstraint"
	uiAspectRatioConstraint.AspectRatio = viewportSize.X / viewportSize.Y
	uiAspectRatioConstraint.Parent = frame
	frame.Parent = parent2
	v.internal.FakeScreen = {
		ScreenFrame = frame,
		ScreenFrameAspectRatio = uiAspectRatioConstraint,
		AbsoluteSizeChangedConnection = frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			for _, widgetVisual in v.internal.WidgetVisuals do
				widgetVisual.WidgetVisual:UpdateRepresentation()
			end
		end)
	}
end

function v.internal:MountInterface(p)
	v.internal.createWidgetInterface(p)
	v.internal.WidgetsListDestructor = WidgetsList(p)

	for k, v2 in Widget:GetAll() do
		if v2.Mounted then
			v.internal.createWidgetRepresentation(k, v2.ScreenGui)
		end
	end

	v.internal.WidgetMountedConnection = Widget.WidgetMounted:Connect(function(p2: string, p3)
		v.internal.createWidgetRepresentation(p2, p3)
	end)
	v.internal.WidgetUnmountedConnection = Widget.WidgetUnmounted:Connect(function(p2: string)
		for k, widgetVisual in v.internal.WidgetVisuals do
			if widgetVisual.WidgetVisual.WidgetName ~= p2 then
				continue
			end

			widgetVisual.WidgetVisual:Destroy()
			widgetVisual.ActivatedConnection:Disconnect()
			widgetVisual.ActivatedConnection = nil
			table.remove(v.internal.WidgetVisuals, k)
		end
	end)
	v.internal.CurrentCameraChangedConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		v.internal.listenToCurrentCameraViewportChanges()
	end)
	v.internal.listenToCurrentCameraViewportChanges()
end

function v.internal:UnmountInterface()
	v.internal.WidgetMountedConnection:Disconnect()
	v.internal.WidgetMountedConnection = nil
	v.internal.WidgetUnmountedConnection:Disconnect()
	v.internal.WidgetUnmountedConnection = nil
	v.internal.CurrentCameraChangedConnection:Disconnect()
	v.internal.CurrentCameraChangedConnection = nil
	v.internal.CurrentViewportSizeChangedConnection:Disconnect()
	v.internal.CurrentViewportSizeChangedConnection = nil
	v.internal.FakeScreen.AbsoluteSizeChangedConnection:Disconnect()
	v.internal.FakeScreen.AbsoluteSizeChangedConnection = nil
	v.internal.FakeScreen.ScreenFrame:Destroy()
	v.internal.FakeScreen = {}
	v.internal.WidgetsListDestructor()
	v.internal.WidgetsListDestructor = nil

	for _, widgetVisual in v.internal.WidgetVisuals do
		widgetVisual.WidgetVisual:Destroy()
	end

	v.internal.WidgetVisuals = {}
end

Tab.new("Widgets", function(p)
	v.internal:MountInterface(p)
	return function()
		v.internal:UnmountInterface()
	end
end)
return nil