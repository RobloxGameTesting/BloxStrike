local color = Color3.fromRGB(219, 159, 47)
local color2 = Color3.fromRGB(43, 172, 43)
local color3 = Color3.fromRGB(182, 45, 45)
local color4 = Color3.new(0, 0, 0)
local color5 = Color3.new(1, 1, 1)
local color6 = Color3.fromRGB(255, 200, 0)
local color7 = Color3.fromRGB(255, 255, 255)
local numberSequence = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.5, 0),
	NumberSequenceKeypoint.new(0.501, 1),
	NumberSequenceKeypoint.new(1, 1)
})

local function formatTime(p: number) -- 1 equivalent call inferred from this helper
	local v = math.floor(p / 60)
	local v2 = p % 60
	local v3 = math.floor(v2)
	local v4 = math.floor((v2 - v3) * 1000)
	return string.format("%02d:%02d.%03d", v, v3, v4)
end

local function getBackgroundColor(value: number) -- 1 equivalent call inferred from this helper
	local v = math.clamp(value, 0, 1)

	if v <= 0.5 then
		return color3:Lerp(color, v * 2)
	end

	return color:Lerp(color2, (v - 0.5) * 2)
end

local function applyHighContrastText(p) -- 2 equivalent calls inferred from this helper
	p.TextStrokeColor3 = color4
	p.TextColor3 = color5
	p.TextStrokeTransparency = 0
end

local function animateIcon(frame, p: number, childName: string, point: Vector2)
	if not (frame and frame.ProgressBar) then
		return
	end

	local child = frame.ProgressBar:FindFirstChild(childName)

	if not child then
		return
	end

	local v = p * 0.5 + 0.5
	local v2 = math.sin(tick() * v * 3.141592653589793 * 2)
	local v3 = v2 * 0.05 + 1
	local udim = UDim2.new(point.X * v3, 0, point.Y * v3, 0)
	local lerped = color6:Lerp(color7, (v2 + 1) / 2)
	child.Size = udim
	child.ImageColor3 = lerped
end

local RadialProgress = {}

function RadialProgress:Initialize(p: string)
	if not (self.Frame and self.Frame.ProgressBar) then
		warn(`{p}: Frame or ProgressBar not found`)
		return
	end

	local progressBar = self.Frame.ProgressBar
	local leftGradient = progressBar:FindFirstChild("LeftGradient")
	local rightGradient = progressBar:FindFirstChild("RightGradient")
	local progressBarImage = leftGradient:FindFirstChild("ProgressBarImage")
	local progressBarImage2 = rightGradient:FindFirstChild("ProgressBarImage")
	local uiGradient = progressBarImage:FindFirstChild("UIGradient")
	local uiGradient2 = progressBarImage2:FindFirstChild("UIGradient")
	self.LeftProgressImage = progressBarImage
	self.RightProgressImage = progressBarImage2
	self.LeftGradient = uiGradient
	self.RightGradient = uiGradient2
	progressBarImage.ImageColor3 = color3
	progressBarImage2.ImageColor3 = color3
	progressBarImage.ImageTransparency = 0
	progressBarImage2.ImageTransparency = 0
	leftGradient.Visible = true
	rightGradient.Visible = true
	progressBarImage.Visible = true
	progressBarImage2.Visible = true
	uiGradient.Transparency = numberSequence
	uiGradient2.Transparency = numberSequence
	uiGradient.Rotation = 0
	uiGradient2.Rotation = 0
end

function RadialProgress.Update(data, value: number, p: string, point: Vector2)
	if not (data.Frame and data.Frame.ProgressBar and (data.LeftGradient and data.RightGradient)) then
		return
	end

	if not (data.LeftProgressImage and data.RightProgressImage) then
		return
	end

	local v = math.clamp(value, 0, 1)
	local backgroundColor = getBackgroundColor(v) -- inferred equivalent call
	data.LeftProgressImage.ImageColor3 = backgroundColor
	data.RightProgressImage.ImageColor3 = backgroundColor
	local v2 = v * 180
	data.RightGradient.Rotation = 360 - v2
	data.LeftGradient.Rotation = v2 + 180
	animateIcon(data.Frame, v, p, point)

	if data.Frame.UIGradient then
		local lerped = backgroundColor:Lerp(color4, 0.3)
		data.Frame.UIGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, backgroundColor),
			ColorSequenceKeypoint.new(1, lerped)
		})
	end

	local lerped = backgroundColor:Lerp(color4, 0.2)

	if data.Frame.Frame1 then
		data.Frame.Frame1.BackgroundColor3 = lerped
	end

	if data.Frame.Frame2 then
		data.Frame.Frame2.BackgroundColor3 = lerped
	end
end

function RadialProgress.SetTimer(p, p2: number)
	if not (p and p.Timer) then
		return
	end

	local timer = p.Timer
	timer.Text = formatTime(p2) -- inferred equivalent call
	applyHighContrastText(p.Timer) -- inferred equivalent call
end

function RadialProgress.SetTitle(p, text: string)
	if not (p and p.Title) then
		return
	end

	p.Title.Text = text
	applyHighContrastText(p.Title) -- inferred equivalent call
end

return RadialProgress