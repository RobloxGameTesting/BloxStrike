local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Router = require(ReplicatedStorage.Database.Security.Router)
local GuiShown = require(script.Parent.GuiShown)
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local color = Color3.fromRGB(255, 196, 77)
local tweenInfo2 = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
local tweenInfo3 = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local tweenInfo4 = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfo5 = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local tweenInfo6 = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local v = {
	{ 4, 0.85 },
	{ 8, 0.94 }
}

local function multiplyUDim2(size: UDim2, p: number) -- 4 equivalent calls inferred from this helper
	return UDim2.new(size.X.Scale * p, size.X.Offset, size.Y.Scale * p, size.Y.Offset)
end

local function createGlowStroke(parent, thickness: number, transparency: number)
	local frame = Instance.new("Frame")
	frame.Name = "Glow"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.ZIndex = 3
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "GlowStroke"
	uiStroke.Color = color
	uiStroke.Thickness = thickness
	uiStroke.Transparency = transparency
	uiStroke.Parent = frame
	frame.Parent = parent
	return uiStroke
end

local function createGlowInstances(instance)
	local glowStroke = createGlowStroke(instance, 1.5, 0.3)
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 190)),
		ColorSequenceKeypoint.new(1, color)
	})
	uiGradient.Parent = glowStroke
	local tween = TweenService:Create(uiGradient, tweenInfo2, { Rotation = 360 })
	local result = {}

	for _, v2 in ipairs(v) do
		table.insert(result, (createGlowStroke(instance, v2[1], v2[2])))
	end

	return glowStroke, result, tween
end

local function createShineSweep(parent)
	local frame = Instance.new("Frame")
	frame.Name = "Shine"
	frame.Active = false
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.ZIndex = 150
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Rotation = 20
	uiGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.6, 1),
		NumberSequenceKeypoint.new(1, 1)
	})
	uiGradient.Offset = Vector2.new(-1, 0)
	uiGradient.Parent = frame
	frame.Parent = parent
	return uiGradient
end

local function setupCardEffects(instance, data)
	local glowInstances, v2, v3 = createGlowInstances(instance)
	local v4 = {}

	for i, v5 in ipairs(v2) do
		local v6 = v[i][2]
		table.insert(v4, TweenService:Create(v5, tweenInfo3, {
			Transparency = v6 - 0.08
		}))
	end

	local v5 = { TweenService:Create(glowInstances, tweenInfo4, {
			Transparency = 0,
			Thickness = 2
		}) }
	local v6 = { TweenService:Create(glowInstances, tweenInfo4, {
			Transparency = 0.3,
			Thickness = 1.5
		}) }

	for i, v7 in ipairs(v2) do
		local transparency = v[i][2]
		table.insert(v5, TweenService:Create(v7, tweenInfo4, { Transparency = 1 }))
		table.insert(v6, TweenService:Create(v7, tweenInfo4, { Transparency = transparency }))
	end

	local v7 = false
	data.MouseEnter:Connect(function()
		v7 = true

		for i, v8 in ipairs(v4) do
			v8:Cancel()
			v5[i + 1]:Play()
		end

		v5[1]:Play()
	end)
	data.MouseLeave:Connect(function()
		v7 = false

		for _, v8 in ipairs(v6) do
			v8:Play()
		end
	end)
	local v8 = false
	v6[1].Completed:Connect(function()
		if v8 and not v7 then
			for _, v9 in ipairs(v4) do
				v9:Play()
			end
		end
	end)
	local discount = instance:FindFirstChild("Discount")
	local discount2 = discount and discount:FindFirstChild("Discount")
	local v9

	if discount2 then
		v9 = TweenService:Create(discount2, tweenInfo5, {
			Rotation = discount2.Rotation + 4
		})
	else
		v9 = nil
	end

	GuiShown.Observe(instance, function(flag: boolean)
		v8 = flag
		local v10 = v7 and {} or table.clone(v4)
		table.insert(v10, v3)

		if v9 then
			table.insert(v10, v9)
		end

		for _, v11 in v10 do
			if v8 then
				v11:Play()
			else
				v11:Pause()
			end
		end
	end)
	local shineSweep = createShineSweep(instance)
	task.spawn(function()
		local tween = TweenService:Create(shineSweep, tweenInfo6, { Offset = Vector2.new(1, 0) })

		while instance.Parent do
			if v8 then
				tween:Play()
				tween.Completed:Wait()
				shineSweep.Offset = Vector2.new(-1, 0)
			end

			task.wait(2.5)
		end
	end)
end

return function(parent, data)
	setupCardEffects(parent, data)
	local size = parent.Size
	local tween = TweenService:Create(parent, tweenInfo, { Size = multiplyUDim2(size, 0.9) }) -- inferred equivalent call
	local tween2 = TweenService:Create(parent, tweenInfo, { Size = multiplyUDim2(size, 0.95) }) -- inferred equivalent call
	local tween3 = TweenService:Create(parent, tweenInfo, { Size = multiplyUDim2(size, 0.95) }) -- inferred equivalent call
	local tween4 = TweenService:Create(parent, tweenInfo, { Size = multiplyUDim2(size, 1) }) -- inferred equivalent call
	data.MouseEnter:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
		tween3:Play()
	end)
	data.MouseLeave:Connect(function()
		tween4:Play()
	end)
	data.MouseButton1Down:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		tween:Play()
	end)
	data.MouseButton1Up:Connect(function()
		tween2:Play()
	end)
end