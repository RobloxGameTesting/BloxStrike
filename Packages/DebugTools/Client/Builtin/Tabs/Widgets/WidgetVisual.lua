local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local guiInset = GuiService:GetGuiInset()
local Shared = script.Parent.Parent.Parent.Parent.Parent.Shared
local Signal = require(Shared.Signal)
local v = { internal = {}, prototype = {}, interface = {} }

function v.internal:createWidgetRepresentation(parent)
	local boundingInstance = self.WidgetScreenGui:GetChildren()[1]
	local textButton = Instance.new("TextButton")
	textButton.Name = self.WidgetName
	textButton.AutoLocalize = false
	textButton.Size = UDim2.fromOffset(60, 30)
	textButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	textButton.BackgroundTransparency = 0.5
	textButton.BorderSizePixel = 0
	textButton.Text = ""
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.CornerRadius = UDim.new(0, 4)
	uiCorner.Parent = textButton
	self.FrameRepresentation = textButton
	self.BoundingInstance = boundingInstance
	textButton.Parent = parent
end

function v.internal:observeWidgetChanges()
	local frameRepresentation = self.FrameRepresentation
	self.MouseInteractionConnection = frameRepresentation.MouseButton1Down:Connect(function()
		local v2 = frameRepresentation.AbsolutePosition + guiInset
		local v3 = UserInputService:GetMouseLocation() - v2
		local vector = Vector2.new(math.floor(v3.X), (math.floor(v3.Y)))
		self.Activated:Fire(vector)
	end)
	self.AbsolutePositionChangedConnection = self.BoundingInstance:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		self:UpdateRepresentation()
	end)
	self.AbsoluteSizeChangedConnection = self.BoundingInstance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		self:UpdateRepresentation()
	end)
	self:UpdateRepresentation()
end

function v.prototype:UpdateRepresentation()
	local absoluteSize = self.FrameRepresentation.Parent.AbsoluteSize
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local v2 = self.BoundingInstance.AbsolutePosition + guiInset
	local absoluteSize2 = self.BoundingInstance.AbsoluteSize
	local v3 = v2 / viewportSize
	local v4 = absoluteSize2 / viewportSize
	local v5 = absoluteSize * v3
	local v6 = absoluteSize * v4
	self.FrameRepresentation.Position = UDim2.fromOffset(v5.X, v5.Y)
	self.FrameRepresentation.Size = UDim2.fromOffset(v6.X, v6.Y)
end

function v.prototype:Destroy()
	self.MouseInteractionConnection:Disconnect()
	self.AbsolutePositionChangedConnection:Disconnect()
	self.AbsoluteSizeChangedConnection:Disconnect()
	self.FrameRepresentation:Destroy()
	self.Activated:Destroy()
end

function v.interface.new(widgetName: string, widgetScreenGui, p)
	assert(type(widgetName) == "string", `Expected parameter #1 'widgetName' to be a string, got {type(widgetName)}`)
	local self = setmetatable(
		{ WidgetName = widgetName, WidgetScreenGui = widgetScreenGui, Activated = Signal.new() },
		{ __index = v.prototype }
	)
	v.internal.createWidgetRepresentation(self, p)
	v.internal.observeWidgetChanges(self)
	return self
end

return v.interface