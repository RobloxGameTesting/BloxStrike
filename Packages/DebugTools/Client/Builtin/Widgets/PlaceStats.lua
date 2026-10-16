local RunService = game:GetService("RunService")
local parent = script.Parent.Parent.Parent
local Constants = require(parent.Parent.Shared.Constants)

if not Constants.DEFAULT_WIDGETS_ENABLED then
	return nil
end

local Style = require(parent.Style)
local Widget = require(parent.Widget)
local Performance = require(parent.Builtin.Tabs.Performance)
Widget.new("Place Stats", function(parent2)
	local frame = Instance.new("Frame")
	frame.Name = "Content"
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Position = UDim2.new(0, 8, 1, -8)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.AutomaticSize = Enum.AutomaticSize.XY
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "FPSLabel"
	textLabel.AutoLocalize = false
	textLabel.Size = UDim2.fromOffset(0, 24)
	textLabel.FontFace = Font.new(
		"rbxasset://fonts/families/SourceSansPro.json",
		Enum.FontWeight.Bold,
		Enum.FontStyle.Normal
	)
	textLabel.Text = "FPS: 0"
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = 24
	textLabel.TextTransparency = 0.33
	textLabel.AutomaticSize = Enum.AutomaticSize.X
	textLabel.BackgroundTransparency = 1
	textLabel.LayoutOrder = 1
	textLabel.Parent = frame
	local uiPadding = Instance.new("UIPadding")
	uiPadding.Name = "UIPadding"
	uiPadding.PaddingBottom = UDim.new(0, 8)
	uiPadding.PaddingLeft = UDim.new(0, 8)
	uiPadding.PaddingRight = UDim.new(0, 8)
	uiPadding.PaddingTop = UDim.new(0, 8)
	uiPadding.Parent = frame
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = frame
	local textLabel2 = Instance.new("TextLabel")
	textLabel2.Name = "FPSCapLabel"
	textLabel2.AutoLocalize = false
	textLabel2.Size = UDim2.fromOffset(0, 14)
	textLabel2.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	textLabel2.Text = "FPS Cap: 0"
	textLabel2.TextColor3 = Style.COLOR_RED
	textLabel2.TextSize = 14
	textLabel2.TextTransparency = 0.33
	textLabel2.AutomaticSize = Enum.AutomaticSize.X
	textLabel2.BackgroundTransparency = 1
	textLabel2.LayoutOrder = 2
	textLabel2.Parent = frame
	local textLabel3 = Instance.new("TextLabel")
	textLabel3.Name = "PhysicsFPSLabel"
	textLabel3.AutoLocalize = false
	textLabel3.Size = UDim2.fromOffset(0, 14)
	textLabel3.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	textLabel3.Text = "Physics FPS: 0"
	textLabel3.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel3.TextSize = 14
	textLabel3.TextTransparency = 0.33
	textLabel3.AutomaticSize = Enum.AutomaticSize.X
	textLabel3.BackgroundTransparency = 1
	textLabel3.LayoutOrder = 3
	textLabel3.Parent = frame
	local textLabel4 = Instance.new("TextLabel")
	textLabel4.Name = "PlaceVersionLabel"
	textLabel4.AutoLocalize = false
	textLabel4.Size = UDim2.fromOffset(0, 14)
	textLabel4.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json")
	textLabel4.Text = `Version: {game.PlaceVersion}`
	textLabel4.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel4.TextSize = 14
	textLabel4.TextTransparency = 0.33
	textLabel4.AutomaticSize = Enum.AutomaticSize.X
	textLabel4.BackgroundTransparency = 1
	textLabel4.LayoutOrder = 4
	textLabel4.Parent = frame
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.Name = "UIListLayout"
	uiListLayout.Padding = UDim.new(0, 2)
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Parent = frame
	frame.Parent = parent2
	local nows = {}
	local lastTime = os.clock()
	local heartbeatConnection = RunService.Heartbeat:Connect(function()
		local now = os.clock()

		for i = #nows, 1, -1 do
			local v = nows
			local v2 = i + 1
			local v3 = nows[i]
			local v4

			if now - 1 <= v3 then
				v4 = nows[i] or nil
			end

			v[v2] = v4
		end

		nows[1] = now
		local v = math.floor(os.clock() - lastTime >= 1 and #nows or #nows / (os.clock() - lastTime))
		local fpsCap = Performance:GetFPSCap()
		textLabel2.Visible = fpsCap > 0
		textLabel2.Text = `FPS Cap: {fpsCap}`
		textLabel.Text = `FPS: {v}`
		textLabel3.Text = `Physics FPS: {math.floor((workspace:GetRealPhysicsFPS()))}`
	end)
	return function()
		frame:Destroy()
		frame = nil
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end
end)
return nil