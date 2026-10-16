local v = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
require(ReplicatedStorage.Shared.Janitor)
local Router = require(ReplicatedStorage.Database.Security.Router)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local udim = UDim2.fromScale(0.196, 0.621)
local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local tweenInfo2 = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function pickOther(pool, p)
	local index = table.find(pool, p)

	if not index or #pool < 2 then
		return pool[math.random(1, #pool)]
	end

	local v2 = math.random(1, #pool - 1)

	if index <= v2 then
		v2 += 1
	end

	return pool[v2]
end

local function buildSequence(p)
	local result = table.create(42)
	result[5] = p.Winner
	result[4] = pickOther(p.Pool, result[5])
	result[3] = pickOther(p.Pool, result[4])
	result[2] = pickOther(p.Pool, result[3])
	result[1] = pickOther(p.Pool, result[2])

	for i = 6, 42 do
		result[i] = pickOther(p.Pool, result[i - 1])
	end

	return result
end

local function createRoot(parent)
	local frame = Instance.new("Frame")
	frame.Name = "ConsoleItemRoller"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(0.74, 0.36)
	frame.BackgroundTransparency = 1
	frame.ClipsDescendants = true
	frame.ZIndex = 20
	frame.Parent = parent
	return frame
end

local function createTile(parent, p)
	local frame = Instance.new("Frame")
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = udim
	frame.BackgroundTransparency = 1
	frame.Visible = false
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = frame
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Glow"
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Position = UDim2.fromScale(0.5, 0.56)
	imageLabel.Size = UDim2.fromScale(1.19, 1.37)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxassetid://10906540366"
	imageLabel.ImageColor3 = p.Color
	imageLabel.ImageTransparency = 1
	imageLabel.Parent = frame
	local imageLabel2 = Instance.new("ImageLabel")
	imageLabel2.Name = "Icon"
	imageLabel2.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel2.Position = UDim2.fromScale(0.5, 0.5)
	imageLabel2.Size = UDim2.fromScale(1, 1)
	imageLabel2.BackgroundTransparency = 1
	imageLabel2.Image = p.Image
	imageLabel2.ImageTransparency = 1
	imageLabel2.ScaleType = Enum.ScaleType.Fit
	imageLabel2.ZIndex = 2
	imageLabel2.Parent = frame
	frame.Parent = parent
	return { Frame = frame, Scale = uiScale, Icon = imageLabel2, Glow = imageLabel }
end

local function createPointer(parent)
	local frame = Instance.new("Frame")
	frame.Name = "Pointer"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.02)
	frame.Size = UDim2.fromScale(0.32, 0.32)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 5
	local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.Parent = frame
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = frame
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Arrow"
	imageLabel.AnchorPoint = Vector2.new(0.5, 0)
	imageLabel.Position = UDim2.fromScale(0.5, 0.5)
	imageLabel.Size = UDim2.fromScale(0.5, 0.5)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = "rbxassetid://106962999752773"
	imageLabel.ImageTransparency = 1
	imageLabel.Rotation = 90
	imageLabel.Parent = frame
	frame.Parent = parent
	return frame, imageLabel, uiScale
end

local function smoothstep(value: number) -- 2 equivalent calls inferred from this helper
	local v2 = math.clamp(value, 0, 1)
	return v2 * v2 * (3 - v2 * 2)
end

local function layoutTiles(items, p: number, p2: number)
	for k, item in items do
		local v2 = k - p
		local v3 = 0.5 - v2 * (1 / 3)
		local visible

		if v3 > -1 / 3 then
			visible = v3 < 4 / 3
		else
			visible = false
		end

		item.Frame.Visible = visible

		if not visible then
			continue
		end

		item.Frame.Position = UDim2.fromScale(v3, 0.5)
		local v4 = smoothstep(1 - math.abs(v2)) -- inferred equivalent call
		item.Scale.Scale = v4 * 0.51 + 1
		local v5 = smoothstep(math.min(v3, 1 - v3) / 0.15) * p2 -- inferred equivalent call
		local v6 = 1 - (v4 * -0.4 + 0.8)
		item.Icon.ImageTransparency = 1 - v5
		item.Glow.ImageTransparency = 1 - v6 * v5
	end
end

function v.play(parent, p, maid, callback)
	local parent2 = maid:Add((createRoot(parent)))
	local v2 = {}

	for k, v3 in buildSequence(p) do
		v2[k] = createTile(parent2, v3)
	end

	local pointer, v3, v4 = createPointer(parent2)
	local rotation = 0
	local v5 = 0
	local v6 = 39
	local now = os.clock()

	local function swingPointer(p2: number)
		local now2 = os.clock()
		local v7 = math.min(now2 - now, 0.1)
		now = now2

		while v7 > 0 do
			local v8 = math.min(v7, 1 / 240)
			v5 -= (1934.4424626135142 * rotation + 26.389378290154262 * v5) * v8
			rotation += v5 * v8
			v7 -= v8
		end

		local v8 = math.ceil(p2 - 0.5) + 0.5 - p2
		local v9 = nil
		local v10

		if v8 < 0.26 then
			v10 = v8 * 38 / 0.26
		else
			v10 = p2 < v6 and math.round(p2) ~= math.round(v6) and 38 or v9
		end

		v6 = p2

		if v10 and rotation < v10 then
			rotation = v10
			v5 = 0
		end

		pointer.Rotation = rotation
	end

	local function showWinner() -- 4 equivalent calls inferred from this helper
		layoutTiles(v2, 5, 1)
		pointer.Rotation = 0
		v3.ImageTransparency = 0
		v3.ImageColor3 = p.Winner.Color
		return false
	end

	local lastTime = os.clock()

	while callback() do
		local v7 = os.clock() - lastTime
		local v8 = math.min(v7 / 0.25, 1)
		layoutTiles(v2, 39, v8)
		v3.ImageTransparency = 1 - v8

		if v7 >= 0.5 then
			break
		else
			RunService.RenderStepped:Wait()
		end
	end

	if not callback() then
		return showWinner() -- inferred equivalent call
	end

	local v7 = 5 + (math.random() < 0.5 and -1 or 1) * (0.26 + math.random() * 0.18)
	local v8 = 39
	local v9 = math.round(v8)
	local lastTime2 = os.clock()
	local v10 = false
	maid:Add(
		RunServiceController.BindToRenderStep(
			RunServiceController.CreateBindingName("CaseScene.ConsoleItemRoller"),
			function()
				local v11 = math.min((os.clock() - lastTime2) / 5, 1)
				local v12 = 1 - (1 - v11) ^ 5
				v8 = 39 + (v7 - 39) * v12
				layoutTiles(v2, v8, 1)
				swingPointer(v8)
				local v13 = math.round(v8)

				if v13 ~= v9 then
					v9 = v13
					Router.broadcastRouter("RunInterfaceSound", "UI Click")
				end

				v10 = v11 >= 1
			end
		),
		"Disconnect",
		"ConsoleItemRollerScroll"
	)

	while not v10 and callback() do
		RunService.RenderStepped:Wait()
	end

	maid:Remove("ConsoleItemRollerScroll")

	if not callback() then
		return showWinner() -- inferred equivalent call
	end

	local lastTime3 = os.clock()

	while callback() and os.clock() - lastTime3 < 0.3 do
		swingPointer(v8)
		RunService.RenderStepped:Wait()
	end

	if not callback() then
		return showWinner() -- inferred equivalent call
	end

	local v11 = v8
	local lastTime4 = os.clock()

	while callback() do
		local v12 = math.min((os.clock() - lastTime4) / tweenInfo.Time, 1)
		local value = TweenService:GetValue(v12, tweenInfo.EasingStyle, tweenInfo.EasingDirection)
		v8 = v11 + (5 - v11) * value
		layoutTiles(v2, v8, 1)
		swingPointer(v8)

		if v12 >= 1 then
			break
		else
			RunService.RenderStepped:Wait()
		end
	end

	if not callback() then
		return showWinner() -- inferred equivalent call
	end

	v3.ImageColor3 = p.Winner.Color
	v4.Scale = 1.45
	TweenService:Create(pointer, tweenInfo2, { Rotation = 0 }):Play()
	TweenService:Create(v4, tweenInfo2, { Scale = 1 }):Play()
	Router.broadcastRouter("RunStoreSound", p.LandingSound)
	return true
end

return table.freeze(v)