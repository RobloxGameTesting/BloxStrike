local CaseScroll = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
require(ReplicatedStorage.Database.Custom.Types)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
require(ReplicatedStorage.Database.Components.Libraries.Cases)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local v = nil
local v2 = nil
local v3 = nil
local count = 0

local function GetRandomCaseItem(p)
	local total = 0

	for _, content in ipairs(p.contents) do
		total += content.weight
	end

	local v4 = math.random() * total
	local total2 = 0

	for _, content in ipairs(p.contents) do
		total2 += content.weight

		if v4 <= total2 then
			return content, content.isSpecial or false
		end
	end

	local content = p.contents[1]
	return content, content.isSpecial or false
end

local function GenerateScrollItemList(p, p2, CASE_SCROLL_WINNING_INDEX: number, isGold: boolean)
	local result = {}

	for i = 1, v3.CASE_SCROLL_ITEM_COUNT do
		if i == CASE_SCROLL_WINNING_INDEX then
			table.insert(result, { item = p2, isGold = isGold })
		else
			local v4, isGold2 = GetRandomCaseItem(p)
			table.insert(result, { item = v4, isGold = isGold2 })
		end
	end

	return result
end

local function GetStoreItemIcon(skinInformation) -- 1 equivalent call inferred from this helper
	if not skinInformation then
		return ""
	end

	if skinInformation.wearImages and skinInformation.wearImages[1] then
		return skinInformation.wearImages[1].assetId
	end

	if skinInformation.charmImages and skinInformation.charmImages[1] then
		return skinInformation.charmImages[1].assetId
	end

	return skinInformation.imageAssetId or ""
end

local function CreateScrollItem(parent, p, layoutOrder: number, size: UDim2)
	local caseScroll = ReplicatedStorage.Assets.UI.Store.CaseScroll
	local goldTemplate

	if p.isGold then
		goldTemplate = caseScroll:FindFirstChild("GoldTemplate")
	else
		goldTemplate = caseScroll:FindFirstChild("ItemTemplate")
	end

	if not goldTemplate then
		warn("[Store] Missing case scroll template")
		return
	end

	local clone = goldTemplate:Clone()
	clone.Name = tostring(layoutOrder)
	clone.LayoutOrder = layoutOrder
	clone.Size = size
	clone.SizeConstraint = Enum.SizeConstraint.RelativeXY
	clone.AutomaticSize = Enum.AutomaticSize.None
	clone.Parent = parent

	if p.isGold then
		clone.Frame.Icon.Image = v3.SPECIAL_CASE_ICONS[string.lower(p.item.skin.skinName)] or v3.DEFAULT_CASE_ICON
	else
		local rarity = Rarities[p.item.rarity]
		local skinInformation = Skins.GetSkinInformation(p.item.skin.weaponName, p.item.skin.skinName)
		local frame = clone:FindFirstChild("Frame")

		if rarity and skinInformation and frame then
			local rarityFrame = frame:FindFirstChild("RarityFrame")
			local uiGradient = rarityFrame and rarityFrame:FindFirstChild("UIGradient")

			if uiGradient then
				uiGradient.Color = rarity.ColorSequence
			end

			local icon = frame:FindFirstChild("Icon")

			if icon then
				icon.Image = GetStoreItemIcon(skinInformation) -- inferred equivalent call
			end

			local rarity2 = frame:FindFirstChild("Rarity")

			if rarity2 then
				rarity2.ImageColor3 = rarity.Color
			end
		end
	end
end

local function PopulateScrollContainer(container, list, udim: UDim2, CASE_SCROLL_ITEM_PADDING: number)
	for _, guiObject in ipairs(container:GetChildren()) do
		if not (guiObject:IsA("Frame") or guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton")) then
			continue
		end

		guiObject:Destroy()
	end

	local uiListLayout = container:FindFirstChildOfClass("UIListLayout")

	if uiListLayout then
		uiListLayout.FillDirection = Enum.FillDirection.Horizontal
		uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
		uiListLayout.Padding = UDim.new(0, CASE_SCROLL_ITEM_PADDING)
	end

	for i, v4 in ipairs(list) do
		CreateScrollItem(container, v4, i, udim)
	end
end

local function ConfigureScrollContainer(container, p: number)
	local v4 = math.max(container.AbsoluteSize.X, 1)
	local v5 = math.max(p / v4, 1)
	container.CanvasSize = UDim2.fromScale(v5, 0)
	container:SetAttribute("ScrollMaxOffset", (math.max(0, p - v4)))
	container:SetAttribute("ScrollViewportWidth", v4)
end

local function CalculateTargetOffset(container, p: number, CASE_SCROLL_WINNING_INDEX: number, p2: number, p3: number) -- 4 equivalent calls inferred from this helper
	local v4 = math.max(container.AbsoluteSize.X, 1)
	local v5 = math.max(0, p - v4)

	if v5 <= 0 then
		return 0
	end

	return (math.clamp((CASE_SCROLL_WINNING_INDEX - 0.5) * p2 - v4 * 0.5 + p3, 0, v5))
end

local function AnimateScroll(container, container2, p: number, p2: number, p3: number, fn)
	local tweenInfo = TweenInfo.new(v3.CASE_SCROLL_DURATION, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tween = TweenService:Create(container, tweenInfo, { CanvasPosition = Vector2.new(p, 0) })
	local tween2 = TweenService:Create(container2, tweenInfo, {
		CanvasPosition = Vector2.new(p2, 0)
	})
	v2.currentTween = tween
	v2.currentZoomTween = tween2
	local v4 = 0
	local connection = nil

	local function stopRender() -- 2 equivalent calls inferred from this helper
		if connection then
			connection:Disconnect()
			connection = nil
			v2.renderConnection = nil
		end
	end

	connection = RunServiceController.BindToRenderStep("UI.Store.CaseOpeningSounds", function()
		if v2.isOpening then
			local x = container.CanvasPosition.X
			local v5 = math.floor(not (p3 > 0) and 0 or x / p3) + 1

			if v4 < v5 and v5 <= v3.CASE_SCROLL_ITEM_COUNT then
				fn(v5)
				v4 = v5
			end

			if tween.PlaybackState == Enum.PlaybackState.Completed and connection then
				connection:Disconnect()
				connection = nil
				v2.renderConnection = nil
			end
		else
			stopRender() -- inferred equivalent call
		end
	end)
	v2.renderConnection = connection
	tween.Completed:Connect(function()
		if tween == v2.currentTween and connection then
			connection:Disconnect()
			connection = nil
			v2.renderConnection = nil
		end
	end)
	local v5 = v3.CASE_SCROLL_DURATION * 0.86
	task.delay(v5, function()
		if not (tween == v2.currentTween and tween.PlaybackState ~= Enum.PlaybackState.Completed) then
			return
		end

		if container.Parent ~= nil and container2.Parent ~= nil then
			tween:Cancel()
			tween2:Cancel()
			container.CanvasPosition = Vector2.new(p, 0)
			container2.CanvasPosition = Vector2.new(p2, 0)
		end

		stopRender() -- inferred equivalent call
	end)
	tween:Play()
	tween2:Play()
	return tween
end

local function FindWinningItem(p, data)
	for _, content in ipairs(p.contents) do
		if content.skin.skinName == data.Skin and content.skin.weaponName == data.Name then
			return content, content.isSpecial or false
		end
	end

	if data.Type == "Melee" or data.Type == "Glove" then
		return {
			skin = { weaponName = data.Name, skinName = data.Skin, type = data.Type },
			isSpecial = true,
			rarity = "Special",
			skinId = "",
			weight = 0
		}, true
	end

	local content = p.contents[1]
	return content, content.isSpecial or false
end

local function ResetProgressBar()
	if v2.progressRightTween then
		v2.progressRightTween:Cancel()
		v2.progressRightTween = nil
	end

	if v2.progressRightProxy then
		v2.progressRightProxy:Destroy()
		v2.progressRightProxy = nil
	end

	if not v then
		return
	end

	local progressBar = v.Menu.OpenCase.Contents:FindFirstChild("ProgressBar")

	if not progressBar then
		return
	end

	for _, childName in { "RightGradient", "LeftGradient" } do
		local child = progressBar:FindFirstChild(childName)
		local uiGradient = child
			and child:FindFirstChild("ProgressBarImage")
			and child.ProgressBarImage:FindFirstChild("UIGradient")

		if not uiGradient then
			continue
		end

		uiGradient.Transparency = NumberSequence.new(1)
		uiGradient.Rotation = 90
	end
end

local function MakeArcTransparency(value: number, p: number, p2: number)
	if value <= 0.001 then
		return NumberSequence.new(p2)
	end

	if value >= 0.999 then
		return NumberSequence.new(p)
	end

	local v4 = math.clamp(value - 0.05, 0, 0.999)
	local v5 = math.clamp(value, v4 + 0.001, 1)
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, p),
		NumberSequenceKeypoint.new(v4, p),
		NumberSequenceKeypoint.new(v5, p2),
		NumberSequenceKeypoint.new(1, p2)
	})
end

local function MakeFillTransparency(p: number)
	return MakeArcTransparency(p, 0, 1)
end

local function MakeEraseTransparency(p: number)
	return MakeArcTransparency(p, 1, 0)
end

local function AnimateProgressBar(CASE_SCROLL_DURATION: number)
	ResetProgressBar()

	if not v then
		return
	end

	local progressBar = v.Menu.OpenCase.Contents:FindFirstChild("ProgressBar")

	if not progressBar then
		return
	end

	local leftGradient = progressBar:FindFirstChild("LeftGradient")
	local rightGradient = progressBar:FindFirstChild("RightGradient")

	if not (leftGradient and rightGradient) then
		return
	end

	local progressBarImage = leftGradient:FindFirstChild("ProgressBarImage")
	local progressBarImage2 = rightGradient:FindFirstChild("ProgressBarImage")

	if not (progressBarImage and progressBarImage2) then
		return
	end

	local uiGradient = progressBarImage:FindFirstChild("UIGradient")
	local uiGradient2 = progressBarImage2:FindFirstChild("UIGradient")

	if not (uiGradient and uiGradient2) then
		return
	end

	leftGradient.ClipsDescendants = true
	rightGradient.ClipsDescendants = true
	uiGradient.Rotation = 90
	uiGradient2.Rotation = -90
	uiGradient.Transparency = NumberSequence.new(1)
	uiGradient2.Transparency = NumberSequence.new(1)
	progressBar.Visible = true
	count += 1
	local v4 = count
	local v5 = CASE_SCROLL_DURATION / v3.PROGRESS_BAR_LOOPS / 4

	local function runPhase(p, callback, duration: number)
		if not v2.isOpening or v4 ~= count then
			return false
		end

		local numberValue = Instance.new("NumberValue")
		numberValue.Value = 0
		local changedConnection = numberValue.Changed:Connect(function(p2)
			p.Transparency = callback(p2)
		end)
		v2.progressRightProxy = numberValue
		local tween = TweenService:Create(numberValue, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Value = 1
		})
		v2.progressRightTween = tween
		tween:Play()
		tween.Completed:Wait()
		changedConnection:Disconnect()
		numberValue:Destroy()
		v2.progressRightProxy = nil
		v2.progressRightTween = nil
		return v2.isOpening and v4 == count
	end

	local v6 = {
		{ uiGradient, MakeFillTransparency },
		{ uiGradient2, MakeFillTransparency },
		{ uiGradient, MakeEraseTransparency },
		{ uiGradient2, MakeEraseTransparency }
	}
	Profiler.spawn("UI.Store.ProgressBarThread", function()
		for _ = 1, v3.PROGRESS_BAR_LOOPS do
			for _, v7 in v6 do
				if not runPhase(v7[1], v7[2], v5) then
					return
				end
			end
		end
	end)
end

local function RunScrollAnimation(p, p2)
	if not v2.isOpening then
		return nil
	end

	local openCase = v.Menu.OpenCase
	local canvasGroup = openCase:FindFirstChild("CanvasGroup")
	local zoom = openCase:FindFirstChild("Zoom")

	if not (canvasGroup and zoom) then
		warn("[Store] Missing CanvasGroup or Zoom group in OpenCase UI")
		return nil
	end

	local container = canvasGroup:FindFirstChild("Container")
	local container2 = zoom:FindFirstChild("Container")

	if not (container and container2) then
		warn("[Store] Missing scroll containers for case opening")
		return nil
	end

	local v4, isGold = FindWinningItem(p, p2)
	local generateScrollItemList = GenerateScrollItemList(p, v4, v3.CASE_SCROLL_WINNING_INDEX, isGold)
	local absoluteSize = v and v.AbsoluteSize or Vector2.new(v3.CASE_SCROLL_ITEM_WIDTH * 5, 1000)
	local v5 = math.max(absoluteSize.X / 5, 1)
	local v6 = math.max(v5 * 0.65, 1)
	local udim = UDim2.fromOffset(v5, v6)
	local udim2 = UDim2.fromOffset(v5, v6 * 1.125)
	local line = openCase:FindFirstChild("Line")

	if line and line:IsA("GuiObject") then
		line.Size = UDim2.new(0.003, 0, 0, v6 * 1.125)
	end

	PopulateScrollContainer(container, generateScrollItemList, udim, v3.CASE_SCROLL_ITEM_PADDING)
	PopulateScrollContainer(container2, generateScrollItemList, udim2, v3.CASE_SCROLL_ITEM_PADDING)
	container.CanvasPosition = Vector2.new(0, 0)
	container2.CanvasPosition = Vector2.new(0, 0)
	local v7 = v5 + v3.CASE_SCROLL_ITEM_PADDING
	local v8 = v3.CASE_SCROLL_ITEM_COUNT * v7
	task.wait()
	ConfigureScrollContainer(container, v8)
	ConfigureScrollContainer(container2, v8)
	local x = absoluteSize.X
	local v9 = math.random(-math.floor(x / 11), (math.floor(x / 22)))
	local calculateTargetOffset = CalculateTargetOffset(container, v8, v3.CASE_SCROLL_WINNING_INDEX, v7, v9) -- inferred equivalent call
	local calculateTargetOffset2 = CalculateTargetOffset(container2, v8, v3.CASE_SCROLL_WINNING_INDEX, v7, v9) -- inferred equivalent call
	container:SetAttribute("_scrollTarget", calculateTargetOffset)
	container2:SetAttribute("_scrollTarget", calculateTargetOffset2)
	local lastTime = tick()
	local currentTween2 = AnimateScroll(
		container,
		container2,
		calculateTargetOffset,
		calculateTargetOffset2,
		v7,
		function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
		end
	)
	AnimateProgressBar(v3.CASE_SCROLL_DURATION)
	v2.viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if not v2.isOpening then
			return
		end

		local calculateTargetOffset3 = CalculateTargetOffset(container, v8, v3.CASE_SCROLL_WINNING_INDEX, v7, v9) -- inferred equivalent call
		local calculateTargetOffset4 = CalculateTargetOffset(container2, v8, v3.CASE_SCROLL_WINNING_INDEX, v7, v9) -- inferred equivalent call

		if v2.currentTween then
			v2.currentTween:Cancel()
		end

		if v2.currentZoomTween then
			v2.currentZoomTween:Cancel()
		end

		local v10 = math.max(0.1, v3.CASE_SCROLL_DURATION - (tick() - lastTime))
		local tweenInfo = TweenInfo.new(v10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		local tween = TweenService:Create(container, tweenInfo, {
			CanvasPosition = Vector2.new(calculateTargetOffset3, 0)
		})
		local tween2 = TweenService:Create(container2, tweenInfo, {
			CanvasPosition = Vector2.new(calculateTargetOffset4, 0)
		})
		v2.currentTween = tween
		v2.currentZoomTween = tween2
		tween:Play()
		tween2:Play()
	end)

	if currentTween2 then
		while v2.isOpening do
			local currentTween = v2.currentTween

			if not currentTween then
				break
			end

			currentTween.Completed:Wait()

			if v2.currentTween == currentTween then
				break
			end
		end
	end

	if v2.viewportConnection then
		v2.viewportConnection:Disconnect()
		v2.viewportConnection = nil
	end

	v2.currentTween = nil
	v2.currentZoomTween = nil
	return v4
end

function CaseScroll.Bind(p, p2, p3)
	v = p
	v2 = p2
	v3 = p3
end

CaseScroll.GetStoreItemIcon = GetStoreItemIcon
CaseScroll.ResetProgressBar = ResetProgressBar
CaseScroll.RunScrollAnimation = RunScrollAnimation
return CaseScroll