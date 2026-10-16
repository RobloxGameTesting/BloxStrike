local ConsoleBoardAnimator = {}
ConsoleBoardAnimator.__index = ConsoleBoardAnimator
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
require(ReplicatedStorage.Database.Custom.ConsoleTypes)
local ConsoleBoardPlanner = require(script.Parent:WaitForChild("ConsoleBoardPlanner"))
local ConsoleItemRoller = require(script.Parent:WaitForChild("ConsoleItemRoller"))
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Router = require(ReplicatedStorage.Database.Security.Router)
local ROW_COUNT = ConsoleBoardPlanner.ROW_COUNT
local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local tweenInfo2 = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local color = Color3.fromRGB(65, 65, 65)
local color2 = Color3.fromRGB(80, 80, 80)
local tweenInfo3 = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local v = {
	{ 0, 0 },
	{ 0.1, 0.25 },
	{ 0.6, 1 },
	{ 1, 0 }
}
local color3 = Color3.new(1, 1, 1)
local tweenInfo4 = TweenInfo.new(0.2)
local tweenInfo5 = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfo6 = TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfo7 = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfo8 = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfo9 = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfo10 = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
local tweenInfo11 = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfo12 = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function getGridCells(grids)
	local guiObjects = {}

	for _, guiObject in ipairs(grids:GetChildren()) do
		if guiObject:IsA("GuiObject") then
			table.insert(guiObjects, guiObject)
		end
	end

	table.sort(guiObjects, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return guiObjects
end

local function waitFor(p, duration: number) -- 7 equivalent calls inferred from this helper
	task.wait(duration)
	return p.State == "resolving"
end

local function waitWhileCompleted(p, duration: number)
	task.wait(duration)
	return p.State == "completed"
end

local function waitForSound(object, lastResolutionSound)
	while
		object.State == "resolving"
		and lastResolutionSound
		and lastResolutionSound.Parent
		and lastResolutionSound.IsPlaying
	do
		RunService.RenderStepped:Wait()
	end

	return object.State == "resolving"
end

local function playSound(p, p2: string)
	local v2 = Router.broadcastRouter("RunStoreSound", p2)
	assert(v2, `[ConsoleBoardAnimator] Store sound "{p2}" is not registered`)
	p.ActiveSounds[v2] = true
	p.Cleanup:Add(v2, "Destroy", v2)
	v2.Destroying:Once(function()
		p.ActiveSounds[v2] = nil
		p.Cleanup:RemoveNoClean(v2)
	end)
	return v2
end

local function stopSound(p, sound) -- 3 equivalent calls inferred from this helper
	if not (sound and p.ActiveSounds[sound]) then
		return
	end

	p.ActiveSounds[sound] = nil
	sound:Stop()
	p.Cleanup:Remove(sound)
end

local function reelPosition(p, p2: number) -- 6 equivalent calls inferred from this helper
	return UDim2.new(
		p.Position.X.Scale,
		p.Position.X.Offset,
		p.Position.Y.Scale + p.Span.Scale * p2,
		p.Position.Y.Offset + p.Span.Offset * p2
	)
end

local function setArrowRows(list, list2) -- 2 equivalent calls inferred from this helper
	for i = 0, ROW_COUNT - 1 do
		local v2 = list2[i] == true
		local v3 = list[i]
		v3.Visible = true
		v3.ImageTransparency = v2 and 0 or 1
	end
end

local function setArrowVisibility(p, list) -- 3 equivalent calls inferred from this helper
	setArrowRows(p.Arrows, list) -- inferred equivalent call
	setArrowRows(p.RepeatArrows, list) -- inferred equivalent call
end

local function getColumnColor(p, p2: number, arrowColor: Color3, flag: boolean?) -- 1 equivalent call inferred from this helper
	if p.ArrowColor then
		return p.ArrowColor
	end

	if p2 < 1 and flag ~= false then
		return color3
	end

	return arrowColor
end

local function getArrowColor(p, p2: number, arrow, flag: boolean?) -- 1 equivalent call inferred from this helper
	return getColumnColor(p, p2, p.ArrowColors[arrow], flag) -- inferred equivalent call
end

local function setLandingRows(object, p: number, column, list, flag: boolean?)
	for i = 0, ROW_COUNT - 1 do
		local v2 = list[i] == true
		local arrow = column.Arrows[i]
		local repeatArrow = column.RepeatArrows[i]
		local arrowColor = getArrowColor(object, p, arrow, flag) -- inferred equivalent call
		local imageTransparency = v2 and 0.05 or 1
		arrow.ImageColor3 = arrowColor
		arrow.ImageTransparency = imageTransparency
		repeatArrow.ImageColor3 = arrowColor
		repeatArrow.ImageTransparency = imageTransparency
	end
end

local function setReelProgress(p, p2: number) -- 3 equivalent calls inferred from this helper
	p.Container.Position = reelPosition(p, p2) -- inferred equivalent call
	p.RepeatContainer.Position = reelPosition(p, p2 - 1) -- inferred equivalent call
end

local function setPatternProgress(data, p: number)
	local patternSpan = data.PatternSpan
	data.PatternPrimary.Position = UDim2.new(patternSpan.Scale * p, patternSpan.Offset * p, 0, 0)
	data.PatternRepeat.Position = UDim2.new(patternSpan.Scale * (p - 1), patternSpan.Offset * (p - 1), 0, 0)
end

function ConsoleBoardAnimator.new(instance, columnCount: number)
	local consoleLaptop = instance:FindFirstChild("ConsoleLaptop", true)
	local surfaceGui = consoleLaptop.Screen.SurfaceGui
	local main = surfaceGui.BundleMiniGame.Main
	local arrowHolder = main.ArrowHolder
	local _2 = main["2"]
	local gridCells = getGridCells(main.Grids)
	local maid = Janitor.new()
	local v2 = {
		Columns = {},
		Indicators = {},
		Grid = {},
		ArrowColors = {},
		Spinning = {},
		Cleanup = maid,
		ActiveSounds = {},
		AliveRows = ConsoleBoardPlanner.createAllRows(),
		SurvivingRows = {},
		LandedRows = {},
		PlannedRows = {},
		SpinRows = {},
		PulseScaleByArrow = {},
		ScrollingCells = {},
		State = "idle",
		ReelsReady = false,
		SceneReady = false,
		IsSkipped = false,
		IsFullPath = false,
		RolledItem = false,
		ColumnCount = columnCount,
		BoardParts = 0,
		SideLights = 0,
		Background = 0,
		RollerParent = 0
	}
	local positionsByFrame = {
		[main] = main.Position,
		[surfaceGui.BundleMiniGame.Frame] = surfaceGui.BundleMiniGame.Frame.Position
	}
	v2.BoardParts = positionsByFrame
	v2.SideLights = {}
	v2.Background = { Restore = {} }
	v2.RollerParent = surfaceGui.BundleMiniGame
	local object = setmetatable(v2, ConsoleBoardAnimator)

	for _, childName in { "RaritySideLightLeft", "RaritySideLightRight" } do
		local child = consoleLaptop:FindFirstChild(childName)
		local light = child and child:FindFirstChild("Light", true)

		if not light then
			continue
		end

		local uiShadow = light:FindFirstChildOfClass("UIShadow")
		local sideLights = object.SideLights
		local v3 = {
			Frame = light,
			FrameColor = light.BackgroundColor3,
			FrameTransparency = light.BackgroundTransparency,
			Glow = uiShadow,
			GlowColor = 0,
			GlowTransparency = 0
		}
		local glowColor

		if uiShadow then
			glowColor = uiShadow.Color
		end

		v3.GlowColor = glowColor
		local glowTransparency

		if uiShadow then
			glowTransparency = uiShadow.Transparency
		end

		v3.GlowTransparency = glowTransparency
		table.insert(sideLights, v3)
	end

	local background = object.Background

	for _, image in surfaceGui.BundleMiniGame:GetChildren() do
		if not image:IsA("ImageLabel") then
			continue
		end

		if image.Name == "Pattern" then
			background.Pattern = image
		elseif image.Name == "BG" and image.Visible then
			background.Artwork = image
		elseif image.Name == "BG" then
			background.Tintable = image
		else
			continue
		end

		background.Restore[image] = {
			Visible = image.Visible,
			ImageTransparency = image.ImageTransparency,
			ImageColor3 = image.ImageColor3
		}
	end

	for i = 0, columnCount - 1 do
		local parent = arrowHolder[tostring(i + 1)]
		local frame = parent.Frame
		local repeatContainer = maid:Add(frame:Clone())
		repeatContainer.Name = "ReelRepeat"
		repeatContainer.Parent = parent
		local arrows = {}
		local arrows2 = {}

		for j = 0, ROW_COUNT - 1 do
			local arrow = frame[tostring(j + 1)].Arrow
			local arrow2 = repeatContainer[tostring(j + 1)].Arrow
			arrows[j] = arrow
			arrows2[j] = arrow2
			object.ArrowColors[arrow] = arrow.ImageColor3
			arrow.Visible = true
			arrow.ImageTransparency = 1
		end

		object.Columns[i] = {
			Container = frame,
			RepeatContainer = repeatContainer,
			Position = frame.Position,
			Span = frame.Size.Y,
			Arrows = arrows,
			RepeatArrows = arrows2
		}
		repeatContainer.Visible = false
		local v3 = _2[tostring(i + 1)]
		local imageLabel = v3:FindFirstChildWhichIsA("ImageLabel", true)
		local uiShadow = v3:FindFirstChildWhichIsA("UIShadow", true)
		local indicators = object.Indicators
		local v4 = {
			Image = imageLabel,
			ImageColor = imageLabel.ImageColor3,
			ImageTransparency = imageLabel.ImageTransparency,
			Shadow = uiShadow,
			ShadowTransparency = 0,
			ShadowBlurRadius = 0,
			ShadowSpread = 0
		}
		local shadowTransparency

		if uiShadow then
			shadowTransparency = uiShadow.Transparency
		end

		v4.ShadowTransparency = shadowTransparency
		local shadowBlurRadius

		if uiShadow then
			shadowBlurRadius = uiShadow.BlurRadius
		end

		v4.ShadowBlurRadius = shadowBlurRadius
		local shadowSpread

		if uiShadow then
			shadowSpread = uiShadow.Spread
		end

		v4.ShadowSpread = shadowSpread
		indicators[i] = v4
		imageLabel.ImageColor3 = color2

		if uiShadow then
			uiShadow.Transparency = 1
		end

		object.Grid[i] = {}

		for j = 0, ROW_COUNT - 1 do
			local gridCell = gridCells[j * columnCount + i + 1]
			local pattern = gridCell.Pattern
			local connectedGrid = gridCell.ConnectedGrid
			local pattern2 = connectedGrid.ArrowTemplate3.Pattern
			local patternPrimary = maid:Add(pattern2:Clone())
			patternPrimary.Name = "PatternPrimary"
			patternPrimary.AnchorPoint = Vector2.zero
			patternPrimary.Position = UDim2.fromScale(0, 0)
			patternPrimary.Size = pattern2.TileSize
			patternPrimary.Rotation = 0
			patternPrimary.ScaleType = Enum.ScaleType.Stretch
			patternPrimary.Parent = pattern2
			local patternRepeat = maid:Add(patternPrimary:Clone())
			patternRepeat.Name = "PatternRepeat"
			patternRepeat.Position = UDim2.new(-patternPrimary.Size.X.Scale, -patternPrimary.Size.X.Offset, 0, 0)
			patternRepeat.Parent = pattern2
			object.Grid[i][j] = {
				Frame = gridCell,
				Pattern = pattern,
				Connected = connectedGrid,
				PatternMask = pattern2,
				PatternPrimary = patternPrimary,
				PatternRepeat = patternRepeat,
				PatternSpan = patternPrimary.Size.X,
				PatternMaskTransparency = pattern2.ImageTransparency,
				PatternMaskClips = pattern2.ClipsDescendants,
				BackgroundTransparency = gridCell.BackgroundTransparency,
				PatternTransparency = pattern.ImageTransparency,
				ConnectedColor = connectedGrid.GroupColor3
			}
			pattern2.ImageTransparency = 1
			pattern2.ClipsDescendants = true
		end
	end

	return object
end

function ConsoleBoardAnimator:_tween(p, p2, p3)
	local tween = TweenService:Create(p, p3 or tweenInfo4, p2)
	self.Cleanup:Add(tween, "Cancel", tween)
	tween.Completed:Once(function()
		self.Cleanup:RemoveNoClean(tween)
	end)
	tween:Play()
	return tween
end

function ConsoleBoardAnimator:_activateIndicator(p: number)
	local indicator = self.Indicators[p]
	local tween = self:_tween(indicator.Image, {
		ImageColor3 = indicator.ImageColor:Lerp(color3, 0.35)
	}, tweenInfo5)
	local shadow = indicator.Shadow

	if shadow then
		local shadowBlurRadius = indicator.ShadowBlurRadius
		local shadowSpread = indicator.ShadowSpread
		self:_tween(shadow, {
			BlurRadius = UDim.new(shadowBlurRadius.Scale, shadowBlurRadius.Offset + 18),
			Spread = UDim2.new(
				shadowSpread.X.Scale,
				shadowSpread.X.Offset + 8,
				shadowSpread.Y.Scale,
				shadowSpread.Y.Offset + 8
			),
			Transparency = 0.05
		}, tweenInfo5)
	end

	tween.Completed:Once(function(p2)
		if p2 ~= Enum.PlaybackState.Completed or self.State ~= "resolving" then
			return
		end

		self:_tween(indicator.Image, { ImageColor3 = indicator.ImageColor }, tweenInfo7)

		if shadow then
			self:_tween(
				shadow,
				{
					BlurRadius = indicator.ShadowBlurRadius,
					Spread = indicator.ShadowSpread,
					Transparency = indicator.ShadowTransparency
				},
				tweenInfo7
			)
		end
	end)
end

function ConsoleBoardAnimator:_setCell(p: number, p2: number, flag: boolean, flag2: boolean?)
	local arrow = self.Columns[p].Arrows[p2]
	local v2 = self.Grid[p][p2]
	arrow.Visible = true
	local arrowColor

	if flag2 and not flag then
		arrowColor = color
	else
		arrowColor = self.ArrowColors[arrow]

		if self.ArrowColor then
			arrowColor = self.ArrowColor
		elseif p < 1 then
			arrowColor = color3
		end
	end

	self:_tween(arrow, {
		ImageColor3 = arrowColor,
		ImageTransparency = flag and 0.05 or flag2 and 0.2 or 1
	})
	local frame = v2.Frame
	local backgroundTransparency

	if flag then
		backgroundTransparency = v2.BackgroundTransparency
	else
		backgroundTransparency = math.min(1, v2.BackgroundTransparency + 0.2)
	end

	self:_tween(frame, { BackgroundTransparency = backgroundTransparency })
	local pattern = v2.Pattern
	local imageTransparency

	if flag then
		imageTransparency = v2.PatternTransparency
	else
		imageTransparency = math.min(1, v2.PatternTransparency + 0.45)
	end

	self:_tween(pattern, { ImageTransparency = imageTransparency })

	if flag then
		local connected = v2.Connected
		local connectedColor = v2.ConnectedColor

		if self.ArrowColor then
			connectedColor = self.ArrowColor
		elseif p < 1 then
			connectedColor = color3
		end

		connected.GroupColor3 = connectedColor
	end

	self.ScrollingCells[v2] = flag and true or nil
	self:_tween(v2.Connected, {
		GroupTransparency = flag and 0 or 1
	})
end

function ConsoleBoardAnimator:_greyRows(p: number, p2)
	for i = 0, p do
		for k in self.LandedRows[i] do
			if not (not p2 or p2[k]) then
				continue
			end

			local v2 = self.Grid[i][k]
			self:_tween(self.Columns[i].Arrows[k], { ImageColor3 = color, ImageTransparency = 0.2 })
			self.ScrollingCells[v2] = nil
			self:_tween(v2.Connected, { GroupTransparency = 1 })
		end
	end
end

function ConsoleBoardAnimator:_pulseArrow(parent, scale: number, color4: Color3?, p, p2)
	local v2 = self.PulseScaleByArrow[parent]

	if not v2 then
		v2 = self.Cleanup:Add(Instance.new("UIScale"))
		v2.Name = "ConsoleArrowPulse"
		v2.Parent = parent
		self.PulseScaleByArrow[parent] = v2
	end

	if color4 then
		self:_tween(parent, { ImageColor3 = color4 }, tweenInfo5)
	end

	self:_tween(v2, { Scale = scale }, p or tweenInfo6).Completed:Once(function(p3)
		if p3 == Enum.PlaybackState.Completed and self.State == "resolving" then
			self:_tween(v2, { Scale = 1 }, p2 or tweenInfo5)
		end
	end)
end

function ConsoleBoardAnimator:_pulsePaths(p: number, arrowColor: Color3?)
	if arrowColor then
		self.ArrowColor = arrowColor
	end

	local function pulseArrow(p2: number, p3: number)
		local column = self.Columns[p2]
		local v2

		if p2 <= p then
			v2 = self.AliveRows[p3] and self.LandedRows[p2][p3]
		else
			v2 = false
		end

		local v3

		if p < p2 then
			v3 = column.Arrows[p3].ImageTransparency < 1
		else
			v3 = false
		end

		if not (v2 or v3) then
			return true
		end

		self:_pulseArrow(column.Arrows[p3], 1.18, arrowColor)

		if v2 and arrowColor then
			self:_tween(self.Grid[p2][p3].Connected, { GroupColor3 = arrowColor })
		end

		if v3 then
			self:_pulseArrow(column.RepeatArrows[p3], 1.18, arrowColor)
		end

		return waitFor(self, 0.015) -- inferred equivalent call
	end

	local function pulsePath(p2: number)
		if not pulseArrow(p, p2) then
			return false
		end

		for i = self.ColumnCount - 1, 0, -1 do
			if i ~= p and not pulseArrow(i, p2) then
				return false
			end
		end

		return true
	end

	local v2 = ROW_COUNT

	for i = 0, ROW_COUNT - 1 do
		local v3 = i
		Profiler.spawn("CaseScene.ConsoleBoard.RarityPath", function()
			pulsePath(v3)
			v2 -= 1
		end)
	end

	while v2 > 0 and self.State == "resolving" do
		RunService.RenderStepped:Wait()
	end

	return self.State == "resolving" and waitFor(self, 0.3) -- inferred equivalent call
end

function ConsoleBoardAnimator:_startPinkTeaseMelody()
	if not self.TeaseMelody then
		self.TeaseMelody = playSound(self, "Console Pink Tease Melody")
	end
end

function ConsoleBoardAnimator:_stopPinkTeaseMelody()
	local teaseMelody = self.TeaseMelody
	self.TeaseMelody = nil

	if teaseMelody and self.ActiveSounds[teaseMelody] then
		self:_tween(teaseMelody, { PlaybackSpeed = 0.2, Volume = 0 }, tweenInfo3).Completed:Once(function()
			local v2 = self
			local teaseMelody2 = teaseMelody

			if teaseMelody2 then
				if not v2.ActiveSounds[teaseMelody2] then
					return
				end

				v2.ActiveSounds[teaseMelody2] = nil
				teaseMelody2:Stop()
				v2.Cleanup:Remove(teaseMelody2)
			end
		end)
	end
end

function ConsoleBoardAnimator:_celebrateFullPath()
	local lastTime = os.clock()

	local function tweenPathScale(scale: number, tweenInfo13)
		for i = 0, self.ColumnCount - 1 do
			for j = 0, ROW_COUNT - 1 do
				if self.AliveRows[j] and self.LandedRows[i][j] then
					self:_tween(self.PulseScaleByArrow[self.Columns[i].Arrows[j]], { Scale = scale }, tweenInfo13)
				end
			end
		end
	end

	local total = 0

	while total <= 3.43 do
		local v2 = math.exp(total * -0.606) * 0.06 * self.ColumnCount * 0.8
		local tweenInfo13 = TweenInfo.new(v2 * 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		local tweenInfo14 = TweenInfo.new(v2 * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		for i = 0, self.ColumnCount - 1 do
			local v3 = total + 0.1

			while self.State == "resolving" and os.clock() - lastTime < v3 do
				RunService.RenderStepped:Wait()
			end

			if self.State ~= "resolving" then
				return false
			end

			for j = 0, ROW_COUNT - 1 do
				if self.AliveRows[j] and self.LandedRows[i][j] then
					self:_pulseArrow(self.Columns[i].Arrows[j], 1.5, nil, tweenInfo13, tweenInfo14)
				end
			end

			total += math.exp(total * -0.606) * 0.06
		end
	end

	tweenPathScale(1.25, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
	task.wait(0.08)

	if self.State ~= "resolving" then
		return false
	end

	local v2 = math.max(0, 4.2 - (os.clock() - lastTime))
	tweenPathScale(1.8, TweenInfo.new(v2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))

	while self.State == "resolving" and os.clock() - lastTime < 4.2 do
		RunService.RenderStepped:Wait()
	end

	if self.State ~= "resolving" then
		return false
	end

	tweenPathScale(1, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
	return waitFor(self, 0.08) -- inferred equivalent call
end

local function getChasePower(p: number)
	for i = 2, #v do
		local v2 = v[i - 1]
		local v3 = v[i]

		if p <= v3[1] then
			return v2[2] + (v3[2] - v2[2]) * (p - v2[1]) / (v3[1] - v2[1])
		end
	end

	return 0
end

local function createChaseSegments(data, image, color4: Color3)
	local x = image.AbsoluteSize.X
	local y = image.AbsoluteSize.Y
	local v2 = math.min(x, y) / 2
	local v3 = math.max(x, y) - v2 * 2
	local v4 = 2 * (x + y)
	local v5 = v4 / 40
	local clone = image:Clone()
	clone:ClearAllChildren()
	clone.AnchorPoint = Vector2.zero
	clone.Rotation = 0
	clone.ImageColor3 = color4
	clone.ImageTransparency = 1
	local v6 = {}

	local function addSegment(p: number, p2: number, p3: number, p4: number, p5: number)
		local parent = data.Cleanup:Add(Instance.new("Frame"))
		parent.Name = "ConsoleGoldChase"
		parent.BackgroundTransparency = 1
		parent.BorderSizePixel = 0
		parent.ClipsDescendants = true
		parent.Position = UDim2.fromScale(p / x, p2 / y)
		parent.Size = UDim2.fromScale((p3 - p) / x, (p4 - p2) / y)
		local clone2 = clone:Clone()
		clone2.Position = UDim2.fromScale(-p / (p3 - p), -p2 / (p4 - p2))
		clone2.Size = UDim2.fromScale(x / (p3 - p), y / (p4 - p2))
		clone2.Parent = parent
		parent.Parent = image
		table.insert(v6, {
			Image = clone2,
			Position = p5 / v4
		})
	end

	local v7 = math.max(1, (math.round(x / v5)))
	local v8 = math.max(1, (math.round(v3 / v5)))

	for i = 0, v7 - 1 do
		local v9 = x * i / v7
		local v10 = x * (i + 1) / v7
		addSegment(v9, 0, v10, v2, (v9 + v10) / 2)
	end

	for i = 0, v8 - 1 do
		local v9 = v2 + v3 * i / v8
		local v10 = v2 + v3 * (i + 1) / v8
		addSegment(x - v2, v9, x, v10, x + (v9 + v10) / 2)
	end

	for i = 0, v7 - 1 do
		local v9 = x * (v7 - i - 1) / v7
		local v10 = x * (v7 - i) / v7
		addSegment(v9, y - v2, v10, y, x + y + x - (v9 + v10) / 2)
	end

	for i = 0, v8 - 1 do
		local v9 = v2 + v3 * (v8 - i - 1) / v8
		local v10 = v2 + v3 * (v8 - i) / v8
		addSegment(0, v9, v2, v10, 2 * x + y + y - (v9 + v10) / 2)
	end

	clone:Destroy()
	return v6
end

function ConsoleBoardAnimator:_chaseIndicatorsGold()
	local hsv, v2, v3 = self.Indicators[self.ColumnCount - 1].ImageColor:ToHSV()
	local v4 = {}

	for _, indicator in self.Indicators do
		local absoluteSize = indicator.Image.AbsoluteSize

		if not indicator.Image.Visible or (absoluteSize.X <= 0 or absoluteSize.Y <= 0) then
			continue
		end

		local color4 = Color3.fromHSV(
			hsv * (1 + (math.random() * 2 - 1) * 0.1),
			v2 * (1 - math.random() * 0.1),
			v3 * (1 - math.random() * 0.1)
		)
		indicator.Image.ImageTransparency = 1
		table.insert(v4, {
			Offset = math.random(),
			Segments = createChaseSegments(self, indicator.Image, color4)
		})
	end

	local lastTime = os.clock()
	self.Cleanup:Add(
		RunServiceController.BindToRenderStep(
			RunServiceController.CreateBindingName("CaseScene.ConsoleBoard.GoldChase"),
			function()
				local v5 = (os.clock() - lastTime) / 2.1

				for _, v6 in v4 do
					for _, segment in v6.Segments do
						local v7 = (segment.Position - v5 + v6.Offset) % 1
						segment.Image.ImageTransparency = 1 - getChasePower(v7)
					end
				end
			end
		),
		"Disconnect",
		"GoldChase"
	)
end

function ConsoleBoardAnimator:_stopColumn(p: number)
	local v2 = self.Spinning[p]
	stopSound(self, v2 and v2.Sound) -- inferred equivalent call
	self.Spinning[p] = nil
	local column = self.Columns[p]
	column.Container.Position = column.Position
	column.RepeatContainer.Position = reelPosition(column, -1) -- inferred equivalent call
	column.RepeatContainer.Visible = false
end

function ConsoleBoardAnimator:_revealRemainingColumns(p: number)
	for i = p + 1, self.ColumnCount - 1 do
		local v2 = self.Spinning[i]
		stopSound(self, v2 and v2.Sound) -- inferred equivalent call
		self.Spinning[i] = nil
		local column = self.Columns[i]
		local v3 = self.PlannedRows[i] or self.SpinRows[i]
		self.LandedRows[i] = v3
		column.RepeatContainer.Visible = false
		setLandingRows(self, i, column, v3)
		column.Container.Position = reelPosition(column, -0.18) -- inferred equivalent call
		self:_tween(column.Container, { Position = column.Position }, tweenInfo2)

		for j = 0, ROW_COUNT - 1 do
			self:_setCell(i, j, false, v3[j] == true)
		end

		task.wait(0.11)

		if self.State ~= "resolving" then
			return false
		end
	end

	return waitFor(self, tweenInfo2.Time) -- inferred equivalent call
end

function ConsoleBoardAnimator:_landColumn(p)
	local columnIndex = p.columnIndex
	local v2 = self.Spinning[columnIndex]
	local v3 = (os.clock() - v2.StartedAt) % 0.21

	if v3 > 0.01 then
		local v4 = 0.21 - v3
		task.wait(v4)

		if self.State ~= "resolving" then
			return false, {}
		end
	end

	self.Spinning[columnIndex] = nil
	local plannedRow = self.PlannedRows[columnIndex]
	local column = self.Columns[columnIndex]
	local lastTime = os.clock()
	local v4 = false

	while self.State == "resolving" do
		local v5 = math.min((os.clock() - lastTime) / 1.5, 1)
		local v6 = (1 - (1 - v5) ^ 2) * 3

		if not v4 and v6 >= 2 then
			setLandingRows(self, columnIndex, column, plannedRow, false)
			v4 = true
		end

		if v5 == 1 then
			setReelProgress(column, 0) -- inferred equivalent call
			break
		else
			v2.Sound.PlaybackSpeed = math.min(v2.Sound.PlaybackSpeed, (math.max(0.1, 1 - v5)))
			setReelProgress(column, v6 % 1) -- inferred equivalent call
			RunService.RenderStepped:Wait()
		end
	end

	stopSound(self, v2.Sound) -- inferred equivalent call

	if self.State ~= "resolving" then
		return false, {}
	end

	setLandingRows(self, columnIndex, column, plannedRow)
	self:_stopColumn(columnIndex)
	local v5

	if self.ColumnCount == 10 then
		v5 = `Console 10-Column Connect {columnIndex + 1}`
	else
		v5 = `Console Connect {columnIndex + 1}`
	end

	self.LastResolutionSound = playSound(self, p.result == "miss" and "Console Fail" or v5)

	if p.result == "hit" then
		self:_activateIndicator(columnIndex)
	end

	RunService.RenderStepped:Wait()

	if self.State == "resolving" then
		return true, plannedRow
	end

	return false, {}
end

function ConsoleBoardAnimator:_spinColumn(p: number, p2)
	local sound = playSound(self, "Console Reel Spin")
	self.Spinning[p] = { StartedAt = os.clock(), Sound = sound }
	local column = self.Columns[p]
	column.RepeatContainer.Visible = true
	column.Container.Position = column.Position
	column.RepeatContainer.Position = reelPosition(column, -1) -- inferred equivalent call
	setArrowVisibility(column, p2) -- inferred equivalent call
end

function ConsoleBoardAnimator:_stopSpin()
	if self.RenderConnection then
		self.Cleanup:Remove("RenderConnection")
		self.RenderConnection = nil
	end

	local activeSounds = self.ActiveSounds
	self.ActiveSounds = {}

	for k in activeSounds do
		k:Stop()
		self.Cleanup:Remove(k)
	end

	self.TeaseMelody = nil
	table.clear(self.Spinning)

	for _, column in self.Columns do
		column.Container.Position = column.Position
		column.RepeatContainer.Position = reelPosition(column, -1) -- inferred equivalent call
		column.RepeatContainer.Visible = false
	end
end

function ConsoleBoardAnimator:_prepareReels(p)
	local v2 = ConsoleBoardPlanner.prepare(self.SpinRows, self.AliveRows, p, self.ColumnCount)
	self.SpinRows = v2.SpinRows
	self.SurvivingRows = v2.SurvivingRows
	self.PlannedRows = v2.PlannedRows
end

function ConsoleBoardAnimator:_applyStep(p, list)
	local survivingRow = self.SurvivingRows[p.columnIndex]
	local v2 = {}

	for k in self.AliveRows do
		if not survivingRow[k] then
			v2[k] = true
		end
	end

	self.LandedRows[p.columnIndex] = list

	for i = 0, ROW_COUNT - 1 do
		self:_setCell(p.columnIndex, i, survivingRow[i] == true, list[i] == true)
	end

	if p.result ~= "miss" then
		self:_greyRows(p.columnIndex - 1, v2)
	end

	self.AliveRows = survivingRow
end

function ConsoleBoardAnimator:_finish()
	self.State = "completed"
	self:_stopSpin()
	local onComplete = self.OnComplete
	self.OnComplete = nil
	Profiler.defer("CaseScene.ConsoleBoard.Complete", onComplete, self.RolledItem)
end

function ConsoleBoardAnimator:_resolveStep(data)
	local landColumn, v2 = self:_landColumn(data)

	if not landColumn then
		return "cancelled"
	end

	self:_applyStep(data, v2)

	if data.result == "miss" then
		self:_stopPinkTeaseMelody()

		if self:_revealRemainingColumns(data.columnIndex) then
			return "miss"
		end

		return "cancelled"
	else
		if data.kind ~= "rarity" then
			Profiler.spawn("CaseScene.ConsoleBoard.BridgePulse", function()
				self:_pulsePaths(data.columnIndex)
			end)
			return "continue"
		end

		if data.columnIndex == self.ColumnCount - 1 then
			self:_stopPinkTeaseMelody()

			if data.rarity == "Special" then
				self:_chaseIndicatorsGold()
			end
		end

		self:_setRarityAmbience(self.Indicators[data.columnIndex].ImageColor)

		if not self:_pulsePaths(data.columnIndex, self.Indicators[data.columnIndex].ImageColor) then
			return "cancelled"
		end

		if data.columnIndex == self.ColumnCount - 3 then
			self:_startPinkTeaseMelody()
		end

		return "continue"
	end
end

function ConsoleBoardAnimator:_getFinalHoldDuration(p)
	if p.result == "miss" then
		return 1.2
	end

	if self.FinalRarity == "Red" or self.FinalRarity == "Special" then
		return 2
	end

	return 0.8
end

function ConsoleBoardAnimator:_runResolution(list)
	task.wait(0.63)

	if self.State ~= "resolving" then
		return
	end

	for _, v2 in list do
		local step = self:_resolveStep(v2)

		if step == "cancelled" then
			return
		end

		if step == "miss" then
			break
		end
	end

	if self.IsFullPath and not self:_celebrateFullPath() then
		return
	end

	local v2 = list[#list]
	local rollerPlan = self.RollerPlan

	if rollerPlan then
		self.RolledItem = waitFor(self, v2.result == "miss" and 0.35 or self:_getFinalHoldDuration(v2)) -- inferred equivalent call
			and self:_playItemRoller(rollerPlan)

		if self.RolledItem and waitFor(self, 1.4) then -- inferred equivalent call
			self:_finish()
		end
	else
		local finalHoldDuration = self:_getFinalHoldDuration(v2)
		task.wait(finalHoldDuration)

		if self.State ~= "resolving" then
			return
		end

		if waitForSound(self, self.LastResolutionSound) then
			self:_finish()
		end
	end
end

function ConsoleBoardAnimator:_setRarityAmbience(imageColor: Color3)
	for _, sideLight in self.SideLights do
		self:_tween(sideLight.Frame, { BackgroundColor3 = imageColor, BackgroundTransparency = 0 }, tweenInfo8)
		local glow = sideLight.Glow

		if glow then
			self:_tween(glow, { Color = imageColor, Transparency = 0.3 }, tweenInfo8)
		end
	end

	local background = self.Background

	if background.Pattern then
		self:_tween(background.Pattern, { ImageColor3 = imageColor }, tweenInfo9)
	end

	local tintable = background.Tintable

	if not tintable then
		return
	end

	if tintable.Visible then
		self:_tween(tintable, { ImageColor3 = imageColor }, tweenInfo9)
		return
	end

	tintable.ImageColor3 = imageColor
	tintable.ImageTransparency = 1
	tintable.Visible = true
	self:_tween(tintable, { ImageTransparency = background.Restore[tintable].ImageTransparency }, tweenInfo9)

	if background.Artwork then
		self:_tween(background.Artwork, { ImageTransparency = 1 }, tweenInfo9)
	end
end

function ConsoleBoardAnimator:_playItemRoller(p)
	for k, boardPart in self.BoardParts do
		self:_tween(k, {
			Position = boardPart + UDim2.fromScale(0, 1.2)
		}, tweenInfo)
	end

	if waitFor(self, tweenInfo.Time) then -- inferred equivalent call
		return ConsoleItemRoller.play(self.RollerParent, p, self.Cleanup, function()
			return self.State == "resolving"
		end)
	end

	return false
end

function ConsoleBoardAnimator:_tryResolve()
	if self.State ~= "spinning" or not (self.ReelsReady and self.SceneReady and self.Steps and self.OnComplete) then
		return
	end

	self.State = "resolving"

	if self.IsSkipped then
		self:_finish()
		return
	end

	local steps = self.Steps
	self:_prepareReels(steps)

	for i = 0, self.ColumnCount - 1 do
		setArrowVisibility(self.Columns[i], self.SpinRows[i]) -- inferred equivalent call
	end

	Profiler.spawn("CaseScene.ConsoleBoard.Resolve", function()
		self:_runResolution(steps)
	end)
end

function ConsoleBoardAnimator:Start()
	self.State = "spinning"
	self.SpinRows = ConsoleBoardPlanner.createInitialSpinRows(self.ColumnCount)

	for i = 0, self.ColumnCount - 1 do
		setArrowVisibility(self.Columns[i], self.SpinRows[i]) -- inferred equivalent call
	end

	self.RenderConnection = self.Cleanup:Add(
		RunServiceController.BindToRenderStep(
			RunServiceController.CreateBindingName("CaseScene.ConsoleBoard.Render"),
			function()
				for k, v2 in self.Spinning do
					setReelProgress(self.Columns[k], (os.clock() - v2.StartedAt) / 0.21 % 1) -- inferred equivalent call
				end

				local v2 = os.clock() / 2.285714285714286 % 1

				for k in self.ScrollingCells do
					setPatternProgress(k, v2)
				end
			end
		),
		"Disconnect",
		"RenderConnection"
	)
	Profiler.spawn("CaseScene.ConsoleBoard.StartCascade", function()
		task.wait(1)

		for i = 0, self.ColumnCount - 1 do
			if self.State ~= "spinning" or self.IsSkipped then
				return
			end

			self:_spinColumn(i, self.SpinRows[i])

			if i < self.ColumnCount - 1 then
				task.wait(0.12)
			end
		end

		self.ReelsReady = true
		self:_tryResolve()
	end)
end

function ConsoleBoardAnimator:SetSceneReady()
	self.SceneReady = true
	self:_tryResolve()
end

function ConsoleBoardAnimator:Resolve(p, onComplete, rollerPlan, p2)
	self.IsFullPath = p.finalColumnIndex == self.ColumnCount - 1
	self.RollerPlan = rollerPlan
	self.FinalRarity = p.finalRarity or p2
	self.Steps = ConsoleBoardPlanner.getDisplaySteps(p)
	self.OnComplete = onComplete
	self:_tryResolve()
end

function ConsoleBoardAnimator:Skip()
	self.IsSkipped = true
	self.ReelsReady = true
	self:_stopSpin()

	if self.State == "resolving" then
		self:_finish()
	else
		self:_tryResolve()
	end
end

function ConsoleBoardAnimator:PlayReset()
	if self.State ~= "completed" then
		return
	end

	self.Cleanup:Remove("GoldChase")
	local background = self.Background

	for k, v2 in background.Restore do
		if k == background.Tintable and not v2.Visible then
			self:_tween(k, { ImageTransparency = 1 }, tweenInfo10)
		else
			self:_tween(k, {
				ImageTransparency = v2.ImageTransparency,
				ImageColor3 = v2.ImageColor3
			}, tweenInfo10)
		end
	end

	for _, sideLight in self.SideLights do
		self:_tween(
			sideLight.Frame,
			{
				BackgroundColor3 = sideLight.FrameColor,
				BackgroundTransparency = sideLight.FrameTransparency
			},
			tweenInfo10
		)

		if sideLight.Glow then
			self:_tween(
				sideLight.Glow,
				{ Color = sideLight.GlowColor, Transparency = sideLight.GlowTransparency },
				tweenInfo10
			)
		end
	end

	local flag = false

	for k, boardPart in self.BoardParts do
		if k.Position ~= boardPart then
			flag = true
		end
	end

	local function ease(p, items)
		local v2 = nil

		for k, item in items do
			if p[k] == item then
				continue
			end

			v2 = v2 or {}
			v2[k] = item
		end

		if not v2 then
			return
		end

		if not flag then
			self:_tween(p, v2, tweenInfo10)
			return
		end

		for k, v3 in v2 do
			p[k] = v3
		end
	end

	table.clear(self.ScrollingCells)

	for k, column in self.Columns do
		for i = 0, ROW_COUNT - 1 do
			local arrow = column.Arrows[i]
			ease(arrow, { ImageTransparency = 1 })
			ease(column.RepeatArrows[i], { ImageTransparency = 1 })
			local v2 = self.PulseScaleByArrow[arrow]

			if v2 then
				ease(v2, { Scale = 1 })
			end

			local v3 = self.Grid[k][i]
			ease(v3.Frame, { BackgroundTransparency = v3.BackgroundTransparency })
			ease(v3.Pattern, { ImageTransparency = v3.PatternTransparency })
			ease(v3.Connected, { GroupTransparency = 1 })
		end
	end

	for _, indicator in self.Indicators do
		ease(indicator.Image, {
			ImageColor3 = color2,
			ImageTransparency = indicator.ImageTransparency
		})

		if indicator.Shadow then
			ease(indicator.Shadow, { Transparency = 1 })
		end

		for _, child in indicator.Image:GetChildren() do
			local imageLabel

			if child.Name == "ConsoleGoldChase" then
				imageLabel = child:FindFirstChildOfClass("ImageLabel")
			else
				imageLabel = false
			end

			if imageLabel then
				ease(imageLabel, { ImageTransparency = 1 })
			end
		end
	end

	if flag then
		local consoleItemRoller = self.RollerParent:FindFirstChild("ConsoleItemRoller")

		if consoleItemRoller then
			for _, image in consoleItemRoller:GetDescendants() do
				if image:IsA("ImageLabel") and image.ImageTransparency < 1 then
					self:_tween(image, { ImageTransparency = 1 }, tweenInfo12)
				end
			end

			local time = tweenInfo12.Time
			task.wait(time)

			if self.State ~= "completed" then
				return
			end
		end

		for k, boardPart in self.BoardParts do
			self:_tween(k, { Position = boardPart }, tweenInfo11)
		end

		local time = tweenInfo11.Time
		task.wait(time)
	else
		local time = tweenInfo10.Time
		task.wait(time)
	end

	local _ = self.State == "completed"
end

function ConsoleBoardAnimator:Cancel()
	self.State = "cancelled"
	self.OnComplete = nil
	self:_stopSpin()
	self.Cleanup:Cleanup()

	for k, arrowColor in self.ArrowColors do
		k.Visible = true
		k.ImageColor3 = arrowColor
		k.ImageTransparency = 1
	end

	for _, v2 in self.Grid do
		for _, v3 in v2 do
			v3.Frame.BackgroundTransparency = v3.BackgroundTransparency
			v3.Pattern.ImageTransparency = v3.PatternTransparency
			v3.Connected.GroupTransparency = 1
			v3.Connected.GroupColor3 = v3.ConnectedColor
			v3.PatternMask.ImageTransparency = v3.PatternMaskTransparency
			v3.PatternMask.ClipsDescendants = v3.PatternMaskClips
		end
	end

	table.clear(self.ScrollingCells)

	for k, boardPart in self.BoardParts do
		k.Position = boardPart
	end

	for k, v2 in self.Background.Restore do
		k.Visible = v2.Visible
		k.ImageTransparency = v2.ImageTransparency
		k.ImageColor3 = v2.ImageColor3
	end

	for _, sideLight in self.SideLights do
		sideLight.Frame.BackgroundColor3 = sideLight.FrameColor
		sideLight.Frame.BackgroundTransparency = sideLight.FrameTransparency

		if not sideLight.Glow then
			continue
		end

		sideLight.Glow.Color = sideLight.GlowColor
		sideLight.Glow.Transparency = sideLight.GlowTransparency
	end

	for _, indicator in self.Indicators do
		indicator.Image.ImageColor3 = indicator.ImageColor
		indicator.Image.ImageTransparency = indicator.ImageTransparency
		local shadow = indicator.Shadow

		if not shadow then
			continue
		end

		shadow.Transparency = indicator.ShadowTransparency
		shadow.BlurRadius = indicator.ShadowBlurRadius
		shadow.Spread = indicator.ShadowSpread
	end
end

return ConsoleBoardAnimator