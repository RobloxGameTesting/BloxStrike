local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local guiInset = GuiService:GetGuiInset()
local parent = script.Parent.Parent
local Signal = require(parent.Parent.Shared.Signal)
local Constants = require(parent.Parent.Shared.Constants)
local Style = require(parent.Style)
local v = { prototype = {}, interface = {} }

function v.prototype:IsPointInDropdown(point: Vector2)
	local v2 = self.DropdownFrame.AbsolutePosition + guiInset
	local absoluteSize = self.DropdownFrame.AbsoluteSize
	local v3 = point - v2
	return v3.X >= 0 and v3.X <= absoluteSize.X and v3.Y >= 0 and v3.Y <= absoluteSize.Y
end

function v.prototype:Destroy()
	self.Closed:Fire()
	self.Closed:Destroy()
	self.ScreenGui:Destroy()
	self.InputEndedConnection:Disconnect()
	self.EntrySelected:Destroy()

	for _, optionSelectedConnection in self.OptionSelectedConnections do
		optionSelectedConnection:Disconnect()
	end
end

function v.interface.new(parent2, options, p: string)
	local entrySelected = Signal.new()
	local closed = Signal.new()
	local v2 = parent2.AbsolutePosition + guiInset
	local absoluteSize = parent2.AbsoluteSize
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "Dropdown"
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = Constants.DROPDOWN_DISPLAY_ORDER
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local frame = Instance.new("Frame")
	frame.Name = "Frame"
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.Position = UDim2.fromOffset(v2.X, v2.Y + absoluteSize.Y)
	frame.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
	frame.BackgroundTransparency = 1
	frame.Parent = screenGui
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Parent = frame
	local connections = table.create(#options)
	local v3 = nil

	for _, text in options do
		local textButton = Instance.new("TextButton")
		textButton.AutoLocalize = false
		textButton.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
		textButton.BackgroundColor3 = Style.BACKGROUND_DARK
		textButton.BorderSizePixel = 0
		textButton.Text = text
		textButton.TextColor3 = Style.COLOR_WHITE
		textButton.FontFace = Style.FONT
		textButton.TextSize = 12
		textButton.Parent = frame
		local v4 = text
		table.insert(connections, textButton.Activated:Connect(function()
			entrySelected:Fire(v4)
			v3:Destroy()
		end))
	end

	screenGui.Parent = Players.LocalPlayer.PlayerGui
	v3 = setmetatable({
		Value = p,
		Parent = parent2,
		Options = options,
		ScreenGui = screenGui,
		DropdownFrame = frame,
		EntrySelected = entrySelected,
		OptionSelectedConnections = connections,
		Closed = closed
	}, { __index = v.prototype })
	task.defer(function()
		local v4 = true
		v3.InputEndedConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local v5 = Vector2.new(input.Position.X, input.Position.Y) + guiInset

			if not (v4 or v3:IsPointInDropdown(v5)) then
				v3:Destroy()
			end

			v4 = false
		end)
	end)
	return v3
end

return v.interface