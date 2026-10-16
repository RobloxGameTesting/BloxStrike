local createVector = vector.create
local EndScreenController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local LevelsIcon = require(ReplicatedStorage.Database.Custom.GameStats.LevelsIcon)
local Sound = require(ReplicatedStorage.Classes.Sound)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GetRankTitle = require(ReplicatedStorage.Components.Common.GetRankTitle)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local ClientCharacterPresentation = require(ReplicatedStorage.Components.Common.ClientCharacterPresentation)
local IsPlayingTeam = require(ReplicatedStorage.Components.Common.IsPlayingTeam)
local AttachGlovesToCharacter = require(ReplicatedStorage.Database.Components.Common.AttachGlovesToCharacter)
local Halftime = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Halftime)
local v = { 3, 2, 4, 1, 5 }
local v2 = { "st", "nd", "rd" }
local c0_2 = CFrame.new(-0.251, 0.806, -0.406) * CFrame.Angles(0, -1.5707963267948966, 1.5707963267948966)
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CurrentCamera = workspace.CurrentCamera
local Characters = ReplicatedStorage.Assets.Characters
local v3 = {
	{ Entrance = "rbxassetid://100747011940776", Idle = "rbxassetid://100747011940776" },
	{ Entrance = "rbxassetid://103701913618746", Idle = "rbxassetid://100955283476946" },
	{ Entrance = "rbxassetid://91396952135880", Idle = "rbxassetid://120200138438261" },
	{ Entrance = "rbxassetid://136102955582599", Idle = "rbxassetid://74544097369437" },
	{ Entrance = "rbxassetid://71439100344953", Idle = "rbxassetid://122693948164334" }
}
local v4 = {
	CT = { Character = "IDF", Weapon = "M4A1-S", Glove = "CT Glove" },
	T = { Character = "Anarchist", Weapon = "AK-47", Glove = "T Glove" }
}
local v5 = { ["Counter-Terrorists"] = "CT", Terrorists = "T" }
local maid = Janitor.new()
local flag = false
local locked = false
local count = 0
local returnToMenu = true
local overlayMode = "EndScreen"
local v6 = nil
local v7 = nil
local v8 = {
	RoundWonCT = true,
	RoundWonT = true,
	RoundLost = true,
	PlayerMVPCT = true,
	PlayerMVPT = true,
	MissionCompleted = true
}
local v9 = { MobileButtons = true }

local function getOrdinalPlacementText(p: number) -- 1 equivalent call inferred from this helper
	local v10 = p % 100
	return `{p}{v10 >= 11 and v10 <= 13 and "th" or v2[p % 10] or "th"}`
end

local function collectPlayingPlayers(items)
	local result = {}

	for k, item in pairs(items) do
		if IsPlayingTeam(item.Team) then
			table.insert(result, { userId = k, data = item })
		end
	end

	return result
end

local function sortPlayersByADR(p)
	local v10 = collectPlayingPlayers(p)
	table.sort(v10, function(a, b)
		if (a.data.ADR or 0) ~= (b.data.ADR or 0) then
			return (a.data.ADR or 0) > (b.data.ADR or 0)
		end

		if (a.data.Score or 0) == (b.data.Score or 0) then
			return (tonumber(a.userId) or 1e999) < (tonumber(b.userId) or 1e999)
		end

		return (a.data.Score or 0) > (b.data.Score or 0)
	end)
	return v10
end

local function rankFFAPlayers(p)
	local v10 = collectPlayingPlayers(p)
	table.sort(v10, function(a, b)
		if (a.data.Score or 0) ~= (b.data.Score or 0) then
			return (a.data.Score or 0) > (b.data.Score or 0)
		end

		if (a.data.Kills or 0) ~= (b.data.Kills or 0) then
			return (a.data.Kills or 0) > (b.data.Kills or 0)
		end

		if (a.data.Assists or 0) == (b.data.Assists or 0) then
			return (tonumber(a.userId) or 1e999) < (tonumber(b.userId) or 1e999)
		end

		return (a.data.Assists or 0) > (b.data.Assists or 0)
	end)
	return v10
end

local function cleanupDebris()
	local debris = workspace:FindFirstChild("Debris")

	if debris then
		for _, child in debris:GetChildren() do
			child:Destroy()
		end
	end

	for _, v10 in Players:GetPlayers() do
		ClientCharacterPresentation.Release(v10, v10.Character)
	end
end

local function getMiddleFrame() -- 2 equivalent calls inferred from this helper
	local mainGui = PlayerGui:FindFirstChild("MainGui")
	local gameplay = mainGui and mainGui:FindFirstChild("Gameplay")
	return gameplay and gameplay:FindFirstChild("Middle")
end

local function getEndScreenFrame() -- 7 equivalent calls inferred from this helper
	local middleFrame = getMiddleFrame() -- inferred equivalent call
	return middleFrame and middleFrame:FindFirstChild("EndScreen")
end

local function getEndScreenModel()
	local tutorialEndScreenScene = workspace:FindFirstChild("TutorialEndScreenScene")
	local endScreen = tutorialEndScreenScene and tutorialEndScreenScene:FindFirstChild("EndScreen")
	return endScreen or workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("EndScreen")
end

local function isPanel(child) -- 4 equivalent calls inferred from this helper
	return child:IsA("Frame") or child:IsA("CanvasGroup")
end

local function setChildVisible(instance, childName: string, visible: boolean) -- 12 equivalent calls inferred from this helper
	local child = instance:FindFirstChild(childName)

	if child then
		child.Visible = visible
	end
end

local function getTransparencyProperty(instance)
	if instance:IsA("TextLabel") or instance:IsA("TextButton") then
		return "TextTransparency"
	end

	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		return "ImageTransparency"
	end

	if instance:IsA("Frame") then
		return "BackgroundTransparency"
	end

	if instance:IsA("UIStroke") then
		return "Transparency"
	end

	return nil
end

local function setElementTransparency(descendant, p: number) -- 2 equivalent calls inferred from this helper
	local transparencyProperty = getTransparencyProperty(descendant)

	if transparencyProperty then
		descendant[transparencyProperty] = p
	end
end

local function tweenElementTransparency(descendant, p: number)
	local transparencyProperty = getTransparencyProperty(descendant)

	if transparencyProperty then
		TweenService:Create(descendant, TweenInfo.new(0.5), { [transparencyProperty] = p }):Play()
	end
end

local function shouldSkipFade(instance)
	if instance:GetAttribute("SkipFade") then
		return true
	end

	local parent = instance.Parent

	while parent and parent:IsA("GuiObject") do
		if parent:GetAttribute("SkipFade") then
			return true
		else
			parent = parent.Parent
		end
	end

	return false
end

local function fadeFrame(folder, backgroundTransparency: number)
	local v10

	if not shouldSkipFade(folder) then
		v10 = TweenService:Create(folder, TweenInfo.new(0.5), {
			BackgroundTransparency = backgroundTransparency
		})
	end

	for _, descendant in folder:GetDescendants() do
		if not shouldSkipFade(descendant) then
			tweenElementTransparency(descendant, backgroundTransparency)
		end
	end

	if v10 then
		v10:Play()
	end

	return v10
end

local function fadeInFrame(folder)
	if not shouldSkipFade(folder) then
		folder.BackgroundTransparency = 1
	end

	for _, descendant in folder:GetDescendants() do
		if not shouldSkipFade(descendant) then
			setElementTransparency(descendant, 1) -- inferred equivalent call
		end
	end

	folder.Visible = true
	return (fadeFrame(folder, 0))
end

local function getBarTweenInfo(flag2: boolean?) -- 3 equivalent calls inferred from this helper
	return TweenInfo.new(flag2 and 0.375 or 0.75, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

local function playInterfaceSound(name: string, playbackSpeed: number?) -- 1 equivalent call inferred from this helper
	local v10 = Sound.new("Interface"):play({ Parent = CurrentCamera, Name = name })

	if v10 and playbackSpeed then
		v10.PlaybackSpeed = playbackSpeed
	end
end

local function createBarSize(p: number, barHeight: UDim) -- 9 equivalent calls inferred from this helper
	return UDim2.new(p, 0, barHeight.Scale, barHeight.Offset)
end

local function setChildText(instance, childName: string, text: string) -- 10 equivalent calls inferred from this helper
	local child = instance:FindFirstChild(childName)

	if child then
		child.Text = text
	end
end

local function storeFrameTransparency(folder)
	local transparenciesByUiStroke = {}

	for _, uiStroke in folder:GetDescendants() do
		if uiStroke:IsA("UIStroke") then
			transparenciesByUiStroke[uiStroke] = uiStroke.Transparency
		end
	end

	return {
		BackgroundTransparency = folder.BackgroundTransparency,
		Strokes = transparenciesByUiStroke
	}
end

local function restoreFrameTransparency(p, p2) -- 2 equivalent calls inferred from this helper
	p.BackgroundTransparency = p2.BackgroundTransparency

	for k, stroke in pairs(p2.Strokes) do
		if k and k.Parent then
			k.Transparency = stroke
		end
	end
end

local function setRankDisplay(instance, p: number) -- 2 equivalent calls inferred from this helper
	setChildText(instance, "TextLabel", `[{GetRankTitle(p)} Rank {p}]`) -- inferred equivalent call
	local rank = instance:FindFirstChild("Rank")

	if rank then
		rank.Image = LevelsIcon[tostring(p)] or ""
	end
end

local function populateLevelFrame(xpEarned: number)
	local endScreenFrame = getEndScreenFrame() -- inferred equivalent call

	if not endScreenFrame then
		return nil
	end

	local level = endScreenFrame:FindFirstChild("Level")

	if not level then
		return nil
	end

	local v10 = v7 or DataController.Get(LocalPlayer, "Level")

	if not v10 then
		return nil
	end

	local level2 = v10.Level or 1
	local experience = v10.Experience or 0
	local nextExperienceRequirement = v10.NextExperienceRequirement or 1000
	setRankDisplay(level, level2) -- inferred equivalent call
	local levelBar = level:FindFirstChild("LevelBar")

	if not levelBar then
		return nil
	end

	local current = levelBar:FindFirstChild("Current")
	local earned = levelBar:FindFirstChild("Earned")

	if not (current and earned) then
		return nil
	end

	local currentInfo = level:FindFirstChild("CurrentInfo", true)
	local earnedInfo = level:FindFirstChild("EarnedInfo", true)

	if not (currentInfo and earnedInfo) then
		return nil
	end

	for _, v11 in { current, earned, currentInfo, earnedInfo } do
		v11:SetAttribute("SkipFade", true)
	end

	setChildText(currentInfo, "Amount", `{experience}xp`) -- inferred equivalent call
	setChildText(earnedInfo, "Amount", `+{xpEarned}xp`) -- inferred equivalent call
	return {
		currentXP = experience,
		xpEarned = xpEarned,
		nextLevelXP = math.max(nextExperienceRequirement, 1),
		currentLevel = level2,
		barHeight = current.Size.Y,
		levelBar = levelBar,
		levelFrame = level,
		currentBar = current,
		earnedBar = earned,
		currentInfo = currentInfo,
		earnedInfo = earnedInfo,
		currentInfoTransparency = storeFrameTransparency(currentInfo),
		earnedInfoTransparency = storeFrameTransparency(earnedInfo)
	}
end

local function calcInfoXOffset(p, data, p2: number) -- 6 equivalent calls inferred from this helper
	local v10 = p.AbsolutePosition.X + p2 * p.AbsoluteSize.X
	local parent = data.Parent
	local x = parent and parent.AbsolutePosition.X or 0
	local v11 = data.AnchorPoint.X * data.AbsoluteSize.X
	return v10 - x + v11
end

local function tweenInfoToBarEnd(data, levelBar, p: number, barTweenInfo)
	local position = data.Position
	return TweenService:Create(data, barTweenInfo, {
		Position = UDim2.new(0, calcInfoXOffset(levelBar, data, p), position.Y.Scale, position.Y.Offset) -- inferred equivalent call
	})
end

local function wouldOverlap(p, data, p2: number) -- 1 equivalent call inferred from this helper
	local v10 = p.AbsolutePosition.X + p.AbsoluteSize.X
	local x = data.Parent.AbsolutePosition.X
	local v11 = data.AnchorPoint.X * data.AbsoluteSize.X
	return x + p2 - v11 < v10 + 5
end

local function calcInfoTopAlignedYOffset(data, y: number) -- 2 equivalent calls inferred from this helper
	local parent = data.Parent
	local y2 = parent and parent.AbsolutePosition.Y or 0
	local v10 = data.AnchorPoint.Y * data.AbsoluteSize.Y
	return y - y2 + v10
end

local function getAdjustedEarnedPosition(p, data, p2: number) -- 2 equivalent calls inferred from this helper
	local y = p.AbsolutePosition.Y

	if wouldOverlap(p, data, p2) then -- inferred equivalent call
		y = y + p.AbsoluteSize.Y + -2
	end

	return UDim2.new(0, p2, 0, calcInfoTopAlignedYOffset(data, y)) -- inferred equivalent call
end

local function playBarTween(p, udim: UDim2, p2, object, flag2: boolean, playbackSpeed: number?)
	local tween = TweenService:Create(p, p2, { Size = udim })

	if flag2 then
		playInterfaceSound("XP Bar Fill", playbackSpeed) -- inferred equivalent call
	end

	tween:Play()
	object:Play()
	tween.Completed:Wait()
end

local function tweenInfoToBarEndWithOverlapCheck(earnedInfo, currentInfo, levelBar, p: number, barTweenInfo)
	local adjustedEarnedPosition = getAdjustedEarnedPosition( -- inferred equivalent call
		currentInfo,
		earnedInfo,
		calcInfoXOffset(levelBar, earnedInfo, p) -- inferred equivalent call
	)
	return TweenService:Create(earnedInfo, barTweenInfo, { Position = adjustedEarnedPosition })
end

local function animateLevelBar(data)
	if not flag then
		return
	end

	local v10 = math.clamp(data.currentXP / data.nextLevelXP, 0, 1)
	local v11 = data.currentXP + data.xpEarned
	local v12 = math.clamp(v11 / data.nextLevelXP, 0, 1)
	local v13 = data.nextLevelXP <= v11
	data.currentBar.Visible = false
	data.earnedBar.Visible = false
	data.currentBar.Size = createBarSize(0, data.barHeight) -- inferred equivalent call
	data.earnedBar.Size = createBarSize(0, data.barHeight) -- inferred equivalent call
	data.currentInfo.Visible = false
	data.earnedInfo.Visible = false
	restoreFrameTransparency(data.currentInfo, data.currentInfoTransparency) -- inferred equivalent call
	restoreFrameTransparency(data.earnedInfo, data.earnedInfoTransparency) -- inferred equivalent call
	local v14 = calcInfoXOffset(data.levelBar, data.currentInfo, 0) -- inferred equivalent call
	local v15 = calcInfoXOffset(data.levelBar, data.earnedInfo, 0) -- inferred equivalent call
	local position = data.currentInfo.Position
	local position2 = data.earnedInfo.Position
	data.currentInfo.Position = UDim2.new(0, v14, position.Y.Scale, position.Y.Offset)
	data.earnedInfo.Position = UDim2.new(0, v15, position2.Y.Scale, position2.Y.Offset)
	task.wait(0.5)

	if not flag then
		return
	end

	data.currentBar.Visible = true
	data.currentInfo.Visible = true

	if v10 > 0 then
		local barTweenInfo = getBarTweenInfo(false) -- inferred equivalent call
		local v16 = tweenInfoToBarEnd(data.currentInfo, data.levelBar, v10, barTweenInfo)
		playBarTween(data.currentBar, createBarSize(v10, data.barHeight), barTweenInfo, v16, true) -- inferred equivalent call

		if not flag then
			return
		end
	end

	if data.xpEarned <= 0 then
		return
	end

	task.wait(0.6)

	if not flag then
		return
	end

	data.earnedBar.Size = createBarSize(v10, data.barHeight) -- inferred equivalent call
	data.earnedBar.Visible = true
	data.earnedInfo.Visible = true
	local v16 = calcInfoXOffset(data.levelBar, data.earnedInfo, v10) -- inferred equivalent call
	local adjustedEarnedPosition = getAdjustedEarnedPosition(data.currentInfo, data.earnedInfo, v16) -- inferred equivalent call
	data.earnedInfo.Position = adjustedEarnedPosition

	if v13 then
		local barTweenInfo = getBarTweenInfo(true) -- inferred equivalent call
		local v17 = tweenInfoToBarEndWithOverlapCheck(data.earnedInfo, data.currentInfo, data.levelBar, 1, barTweenInfo)
		playBarTween(data.earnedBar, createBarSize(1, data.barHeight), barTweenInfo, v17, true, 1.15) -- inferred equivalent call

		if not flag then
			return
		end

		Sound.new("Interface"):play({ Parent = CurrentCamera, Name = "Level Up" })
		local v18 = math.clamp((v11 - data.nextLevelXP) / data.nextLevelXP, 0, 1)
		setRankDisplay(data.levelFrame, data.currentLevel + 1) -- inferred equivalent call
		data.currentBar.Size = createBarSize(0, data.barHeight) -- inferred equivalent call
		data.earnedBar.Size = createBarSize(0, data.barHeight) -- inferred equivalent call
		data.currentInfo.Visible = false
		local v19 = calcInfoXOffset(data.levelBar, data.earnedInfo, 0) -- inferred equivalent call
		local v20 = calcInfoTopAlignedYOffset(data.earnedInfo, data.currentInfo.AbsolutePosition.Y) -- inferred equivalent call
		data.earnedInfo.Position = UDim2.new(0, v19, 0, v20)
		local v21 = tweenInfoToBarEnd(data.earnedInfo, data.levelBar, v18, barTweenInfo)
		local earnedBar = data.earnedBar
		local barSize = createBarSize(v18, data.barHeight) -- inferred equivalent call
		local tween = TweenService:Create(earnedBar, barTweenInfo, { Size = barSize })
		tween:Play()
		v21:Play()
		tween.Completed:Wait()
	else
		local barTweenInfo = getBarTweenInfo(false) -- inferred equivalent call
		local v17 = tweenInfoToBarEndWithOverlapCheck(
			data.earnedInfo,
			data.currentInfo,
			data.levelBar,
			v12,
			barTweenInfo
		)
		playBarTween(data.earnedBar, createBarSize(v12, data.barHeight), barTweenInfo, v17, true, 1.15) -- inferred equivalent call
	end
end

local function scaleUDim2(size: UDim2, p: number) -- 1 equivalent call inferred from this helper
	return UDim2.new(size.X.Scale * p, size.X.Offset * p, size.Y.Scale * p, size.Y.Offset * p)
end

local function getItemIcon(inventoryItem)
	local v10 = not inventoryItem.Type and "" or string.lower(inventoryItem.Type)
	local name = inventoryItem.Name

	if v10 == "credits" then
		return "rbxassetid://115958498634807"
	end

	if v10 == "case" or v10 == "sticker capsule" or v10 == "charm pack" or v10 == "charm capsule" then
		local case = Cases.GetCaseByName(name)

		if case and case.imageAssetId then
			return case.imageAssetId
		end
	end

	local v11 = inventoryItem.Skin and name and Skins.GetSkinInformation(name, inventoryItem.Skin)

	if not v11 then
		return "rbxassetid://18822070027"
	end

	if v11.wearImages and v11.wearImages[1] then
		return v11.wearImages[1].assetId
	end

	if v11.charmImages and v11.charmImages[1] then
		return v11.charmImages[1].assetId
	end

	if v11.imageAssetId then
		return v11.imageAssetId
	end

	return "rbxassetid://18822070027"
end

local function clearDropItems(instance)
	for _, frame in instance:GetChildren() do
		if frame:IsA("Frame") and frame.Name ~= "ItemTemplate" then
			frame:Destroy()
		end
	end
end

local function displayDrops(levelRewards)
	if not flag or not levelRewards or #levelRewards == 0 then
		return
	end

	local endScreenFrame = getEndScreenFrame() -- inferred equivalent call

	if not endScreenFrame then
		return
	end

	local drops = endScreenFrame:FindFirstChild("Drops")
	local dropsContainer = drops and drops:FindFirstChild("Container")
	local itemTemplate = dropsContainer and dropsContainer:FindFirstChild("ItemTemplate")

	if not itemTemplate then
		return
	end

	dropsContainer:SetAttribute("SkipFade", true)
	itemTemplate.Visible = false
	clearDropItems(dropsContainer)
	drops.Visible = false
	task.wait(0.8)

	if not flag then
		return
	end

	local v10 = {}

	for i, v11 in ipairs(levelRewards) do
		local reward = v11.reward
		local v12 = reward.type == "credits"
		local inventoryItem = reward.inventoryItem

		if not (v12 or inventoryItem) then
			continue
		end

		local clone = itemTemplate:Clone()
		clone.Name = "Drop_" .. i
		clone.Visible = false
		clone.Parent = dropsContainer
		local content = clone:FindFirstChild("Content")

		if content then
			local icon = content:FindFirstChild("Icon")

			if icon then
				icon.Image = v12 and "rbxassetid://115958498634807" or getItemIcon(inventoryItem)
			end

			local amount = content:FindFirstChild("amount") or content:FindFirstChild("Amount")

			if amount then
				if v12 and reward.amount then
					amount.Visible = true
					amount.Text = `x{reward.amount}`
				else
					amount.Visible = false
				end
			end

			local rarityFrame = content:FindFirstChild("RarityFrame")
			local uiGradient = rarityFrame and rarityFrame:FindFirstChild("UIGradient")

			if uiGradient then
				local v13 = v12 and "Rare" or inventoryItem and inventoryItem.Rarity
				local v14 = v13 and Rarities[v13]

				if v14 and v14.ColorSequence then
					uiGradient.Color = v14.ColorSequence
				end
			end

			local size = content.Size
			content.Size = scaleUDim2(size, 1.25) -- inferred equivalent call
			local player = clone:FindFirstChild("Player", true)

			if player and v11.userId > 0 then
				player.Image = `rbxthumb://type=AvatarHeadShot&id={v11.userId}&w=150&h=150`
			end

			table.insert(v10, { item = clone, content = content, originalSize = size })
		else
			clone:Destroy()
		end
	end

	if #v10 == 0 then
		return
	end

	fadeInFrame(drops)
	task.wait(0.5)

	if not flag then
		return
	end

	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	for i, v11 in ipairs(v10) do
		local v12 = v11
		task.delay((i - 1) * 0.35, function()
			if not flag then
				return
			end

			v12.item.Visible = true
			local tween = TweenService:Create(v12.content, tweenInfo, { Size = v12.originalSize })
			maid:Add(tween, "Cancel")
			tween:Play()
		end)
	end
end

local function recordPanelVisibility(instance, visibilityByName)
	if instance then
		for _, child in instance:GetChildren() do
			if isPanel(child) then -- inferred equivalent call
				visibilityByName[child.Name] = child.Visible
			end
		end
	end
end

local function applyPanelVisibility(instance, p, p2)
	for _, child in instance:GetChildren() do
		if not isPanel(child) then -- inferred equivalent call
			continue
		end

		local visible = p[child.Name]

		if visible == nil or p2 and p2[child.Name] then
			continue
		end

		child.Visible = visible
	end
end

local function captureVisibilitySnapshot(mainGui)
	local gameplay = mainGui:FindFirstChild("Gameplay")
	local menu = mainGui:FindFirstChild("Menu")
	local middle

	if gameplay then
		middle = gameplay:FindFirstChild("Middle") or nil
	end

	local gameplayVisible

	if gameplay then
		gameplayVisible = gameplay.Visible or false
	else
		gameplayVisible = false
	end

	local v10 = {
		GameplayVisible = gameplayVisible,
		MenuVisible = menu and menu.Visible or false,
		GameplayChildren = {},
		MiddleChildren = {}
	}
	recordPanelVisibility(gameplay, v10.GameplayChildren)
	recordPanelVisibility(middle, v10.MiddleChildren)
	v6 = v10
end

local function restoreVisibilitySnapshot(mainGui, flag2: boolean?)
	if not v6 then
		return
	end

	local v10 = v6
	v6 = nil
	local gameplay = mainGui:FindFirstChild("Gameplay")
	local menu = mainGui:FindFirstChild("Menu")
	local middle

	if gameplay then
		middle = gameplay:FindFirstChild("Middle") or nil
	end

	if menu then
		menu.Visible = v10.MenuVisible
	end

	if gameplay then
		gameplay.Visible = v10.GameplayVisible
		applyPanelVisibility(gameplay, v10.GameplayChildren)
	end

	if middle then
		applyPanelVisibility(middle, v10.MiddleChildren, v9)

		if flag2 then
			for childName in pairs(v8) do
				local child = middle:FindFirstChild(childName)

				if child and isPanel(child) then -- inferred equivalent call
					child.Visible = false
				end
			end
		end
	end
end

local function enforceEndScreenVisibility(instance)
	local visible = overlayMode == "Halftime"

	if instance:FindFirstChild("Menu") then
		MenuState.HideMenu()
	end

	local gameplay = instance:FindFirstChild("Gameplay")

	if not gameplay then
		return
	end

	local middle = gameplay:FindFirstChild("Middle")
	local endScreen

	if middle then
		endScreen = middle:FindFirstChild("EndScreen") or nil
	end

	local halftime

	if middle then
		halftime = middle:FindFirstChild("Halftime") or nil
	end

	gameplay.Visible = true

	for _, child in gameplay:GetChildren() do
		if child:IsA("Frame") or child:IsA("CanvasGroup") then
			child.Visible = child == middle
		end
	end

	if not middle then
		return
	end

	middle.Visible = true

	for _, child in middle:GetChildren() do
		if not (child:IsA("Frame") or child:IsA("CanvasGroup")) then
			continue
		end

		if child == endScreen then
			child.Visible = not visible
		elseif child == halftime then
			child.Visible = visible
		else
			child.Visible = false
		end
	end

	if endScreen then
		endScreen.Visible = not visible
	end

	if halftime then
		halftime.Visible = visible
	end
end

local v10 = {
	Victory = {
		Background = Color3.fromRGB(11, 97, 31),
		Glow = Color3.fromRGB(46, 158, 78),
		Pattern = Color3.fromRGB(134, 255, 78),
		Stroke = Color3.fromRGB(48, 127, 48)
	},
	Defeat = {
		Background = Color3.fromRGB(83, 9, 9),
		Glow = Color3.fromRGB(158, 14, 14),
		Pattern = Color3.fromRGB(255, 53, 53),
		Stroke = Color3.fromRGB(127, 48, 48)
	}
}

local function hidePanels(instance) -- 2 equivalent calls inferred from this helper
	for _, child in instance:GetChildren() do
		if isPanel(child) then -- inferred equivalent call
			child.Visible = false
		end
	end
end

local function setupResultFrame(folder, visible: boolean, data, scoreTextOverride: string, text: string)
	if not folder then
		return
	end

	folder.BackgroundTransparency = 0

	for _, descendant in folder:GetDescendants() do
		setElementTransparency(descendant, 0) -- inferred equivalent call
	end

	folder.Visible = visible
	local score = folder:FindFirstChild("Score")

	if score then
		score.BackgroundColor3 = data.Background
		local glow = score:FindFirstChild("Glow")

		if glow and glow:IsA("ImageLabel") then
			glow.ImageColor3 = data.Glow
		end

		local pattern = score:FindFirstChild("Pattern")

		if pattern and pattern:IsA("ImageLabel") then
			pattern.ImageColor3 = data.Pattern
		end

		local uiStroke = score:FindFirstChildOfClass("UIStroke")

		if uiStroke then
			uiStroke.Color = data.Stroke
		end

		setChildText(score, "TextLabel", scoreTextOverride) -- inferred equivalent call
	end

	setChildText(folder, "TextLabel", text) -- inferred equivalent call
end

local function bindVisibilityLock(mainGui) -- 2 equivalent calls inferred from this helper
	maid:Add(RunServiceController.BindToRenderStep("EndScreenController.VisibilityLock", function()
		enforceEndScreenVisibility(mainGui)
	end), "Disconnect", "EndScreenVisibilityLock")
end

local function showEndScreenUI(data)
	local isDraw = data.isDraw
	local didWin = data.didWin
	local mainGui = PlayerGui:FindFirstChild("MainGui")

	if not mainGui then
		return
	end

	captureVisibilitySnapshot(mainGui)
	CameraController.setForceLockOverride("EndScreen", true)
	CameraController.setPerspective(false, true)
	local menu = mainGui:FindFirstChild("Menu")

	if menu then
		menu.Visible = false
		CameraController.setForceLockOverride("Menu", false)
	end

	local gameplay = mainGui:FindFirstChild("Gameplay")

	if not gameplay then
		return
	end

	gameplay.Visible = true
	hidePanels(gameplay) -- inferred equivalent call
	local middle = gameplay:FindFirstChild("Middle")

	if not middle then
		return
	end

	hidePanels(middle) -- inferred equivalent call
	middle.Visible = true
	local endScreen = middle:FindFirstChild("EndScreen")

	if data.overlayMode == "Halftime" then
		if endScreen then
			endScreen.Visible = false
		end

		if middle:FindFirstChild("Halftime") and IsPlayingTeam(data.halftimeTeam) then
			Halftime.Show(data.halftimeTeam)
		else
			Halftime.Hide()
		end

		bindVisibilityLock(mainGui) -- inferred equivalent call
	else
		Halftime.Hide()

		if not endScreen then
			return
		end

		setChildVisible(endScreen, "MapVote", false) -- inferred equivalent call
		setChildVisible(endScreen, "Top", false) -- inferred equivalent call
		endScreen.Visible = true
		local tScore = data.tScore
		local ctScore = data.ctScore

		if isDraw or data.winningTeam == "Counter-Terrorists" then
			tScore = data.ctScore
			ctScore = data.tScore
		end

		local scoreTextOverride = data.scoreTextOverride or `<b>{tScore}</b> - {ctScore}`
		setupResultFrame(
			endScreen:FindFirstChild("Victory"),
			isDraw or didWin,
			v10.Victory,
			scoreTextOverride,
			isDraw and "Draw" or "Victory"
		)
		setupResultFrame(
			endScreen:FindFirstChild("Defeat"),
			not (isDraw or didWin),
			v10.Defeat,
			scoreTextOverride,
			isDraw and "Draw" or "Defeat"
		)
		setChildVisible(endScreen, "MVP", data.showAccolades) -- inferred equivalent call
		setChildVisible(endScreen, "Close", data.returnToMenu) -- inferred equivalent call
		setChildVisible(endScreen, "Level", false) -- inferred equivalent call
		setChildVisible(endScreen, "Drops", false) -- inferred equivalent call
		bindVisibilityLock(mainGui) -- inferred equivalent call
	end
end

local function clearSkipFade(instance) -- 4 equivalent calls inferred from this helper
	if instance then
		instance:SetAttribute("SkipFade", nil)
	end
end

local function hideMvpSlots(mvp)
	for i = 1, 5 do
		setChildVisible(mvp, tostring(i), false) -- inferred equivalent call
	end
end

local function hideEndScreenUI()
	local endScreenFrame = getEndScreenFrame() -- inferred equivalent call

	if not endScreenFrame then
		return
	end

	endScreenFrame.Visible = false
	Halftime.Hide()
	setChildVisible(endScreenFrame, "Victory", false) -- inferred equivalent call
	setChildVisible(endScreenFrame, "Defeat", false) -- inferred equivalent call
	local level = endScreenFrame:FindFirstChild("Level")

	if level then
		level.Visible = false
		local levelBar = level:FindFirstChild("LevelBar")

		if levelBar then
			clearSkipFade(levelBar:FindFirstChild("Current")) -- inferred equivalent call
			clearSkipFade(levelBar:FindFirstChild("Earned")) -- inferred equivalent call
		end

		clearSkipFade(level:FindFirstChild("CurrentInfo", true)) -- inferred equivalent call
		clearSkipFade(level:FindFirstChild("EarnedInfo", true)) -- inferred equivalent call
	end

	local mvp = endScreenFrame:FindFirstChild("MVP")

	if mvp then
		mvp.Visible = false
		hideMvpSlots(mvp)
	end

	local drops = endScreenFrame:FindFirstChild("Drops")

	if drops then
		drops.Visible = false
		local container = drops:FindFirstChild("Container")

		if container then
			container:SetAttribute("SkipFade", nil)
			clearDropItems(container)
		end
	end

	setChildVisible(endScreenFrame, "MapVote", true) -- inferred equivalent call
	setChildVisible(endScreenFrame, "Top", true) -- inferred equivalent call
end

local function getTeamLoadout(p: string)
	local loadout = DataController.Get(LocalPlayer, "Loadout")

	if type(loadout) ~= "table" then
		return nil
	end

	local v11 = loadout[p == "CT" and "Counter-Terrorists" or "Terrorists"]

	if type(v11) == "table" then
		return v11
	end

	return nil
end

local function getEquippedGloveId(p: string)
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	local v11

	if type(loadout) == "table" then
		v11 = loadout[p == "CT" and "Counter-Terrorists" or "Terrorists"]

		if type(v11) ~= "table" then
			v11 = nil
		end
	end

	local equippedGloves = v11 and v11.Equipped and v11.Equipped["Equipped Gloves"]

	if type(equippedGloves) == "string" and equippedGloves ~= "" then
		return equippedGloves
	end

	return nil
end

local function findInventoryItem(equippedGloves: string)
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if type(inventory) ~= "table" then
		return nil
	end

	for _, v11 in ipairs(inventory) do
		if v11 and v11._id == equippedGloves then
			return v11
		end
	end

	return nil
end

local function attachGlovesToCharacter(clone, p: string, gloves)
	local name = nil
	local skin = nil
	local float = nil

	if gloves then
		name = gloves.Name
		skin = gloves.Skin
		float = gloves.Float
	else
		local loadout = DataController.Get(LocalPlayer, "Loadout")
		local v11

		if type(loadout) == "table" then
			v11 = loadout[p == "CT" and "Counter-Terrorists" or "Terrorists"]

			if type(v11) ~= "table" then
				v11 = nil
			end
		end

		local equippedGloves = v11 and v11.Equipped and v11.Equipped["Equipped Gloves"]

		if type(equippedGloves) ~= "string" or equippedGloves == "" then
			equippedGloves = nil
		end

		if equippedGloves then
			local inventoryItem = findInventoryItem(equippedGloves)

			if inventoryItem then
				name = inventoryItem.Name
				skin = inventoryItem.Skin
				float = inventoryItem.Float
			end
		end
	end

	local v11 = name or v4[p].Glove
	local v12

	if skin and skin ~= "" and float ~= nil then
		v12 = Skins.GetGloves(v11, skin, float) or nil
	end

	local children

	if v12 then
		children = v12:GetChildren()
	else
		local child = ReplicatedStorage.Assets.Weapons:FindFirstChild(v11)

		if not child then
			return
		end

		children = child:GetChildren()
	end

	local characterArmor = clone:FindFirstChild("CharacterArmor") or Instance.new("Folder")
	characterArmor.Name = "CharacterArmor"
	characterArmor.Parent = clone
	AttachGlovesToCharacter(children, clone, characterArmor)
end

local function getEquippedWeaponFromLoadout(p: string, weapon: string)
	local loadout = DataController.Get(LocalPlayer, "Loadout")
	local v11

	if type(loadout) == "table" then
		v11 = loadout[p == "CT" and "Counter-Terrorists" or "Terrorists"]

		if type(v11) ~= "table" then
			v11 = nil
		end
	end

	local rifles = v11 and v11.Loadout and v11.Loadout.Rifles

	if not rifles or type(rifles.Options) ~= "table" then
		return nil
	end

	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if type(inventory) ~= "table" then
		return nil
	end

	for _, option in ipairs(rifles.Options) do
		if not (type(option) == "string" and option ~= "") then
			continue
		end

		for _, v12 in ipairs(inventory) do
			if v12 and v12._id == option and v12.Name == weapon then
				return {
					Skin = v12.Skin,
					Float = v12.Float,
					StatTrack = v12.StatTrack,
					NameTag = v12.NameTag
				}
			end
		end
	end

	return nil
end

local function attachWeaponToCharacter(clone, p: string, weapon)
	local weapon2 = v4[p].Weapon
	local v11 = nil

	if not weapon or not weapon.Skin or weapon.Skin == "" then
		weapon = getEquippedWeaponFromLoadout(p, weapon2)
	end

	if weapon and weapon.Skin and weapon.Skin ~= "" then
		v11 = Skins.GetCharacterModel(weapon2, weapon.Skin, weapon.Float, weapon.StatTrack, weapon.NameTag)
	end

	local folder = v11 or Skins.GetBaseWeaponModel(weapon2, "Character")

	if not folder then
		return
	end

	folder.Name = weapon2
	local rightHand = clone:FindFirstChild("RightHand")

	if not rightHand then
		folder:Destroy()
		return
	end

	if not folder.PrimaryPart then
		local weapon3 = folder:FindFirstChild("Weapon")
		local insert = weapon3 and weapon3:FindFirstChild("Insert")

		if insert then
			folder.PrimaryPart = insert
		else
			folder:Destroy()
			return
		end
	end

	for _, part in folder:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Anchored = false
		part.Massless = true
	end

	folder.Parent = clone
	local motor6D = Instance.new("Motor6D")
	motor6D.Name = "WeaponAttachment"
	motor6D.Part0 = rightHand
	motor6D.Part1 = folder.PrimaryPart
	motor6D.Parent = rightHand

	if weapon2 == "AK-47" then
		motor6D.C0 = c0_2
		return
	end

	local properties = folder:FindFirstChild("Properties")

	if properties then
		local c0 = properties:FindFirstChild("C0")
		local c1 = properties:FindFirstChild("C1")

		if c0 then
			motor6D.C0 = c0.Value
		end

		if c1 then
			motor6D.C1 = c1.Value
		end
	end
end

local function calculateHSP(value: number?, value2: number?)
	local v11 = value or 0

	if v11 <= 0 then
		return "0%"
	end

	return `{math.floor((value2 or 0) / v11 * 100)}%`
end

local function getEquippedBadgeIcon(playerByUserId, team: string)
	local v11, v12 = DataController.Get(playerByUserId, "Loadout", "Inventory")
	local v13 = v11 and v12 and v11[team]
	local equippedBadge = v13 and v13.Equipped and v13.Equipped["Equipped Badge"]

	if not equippedBadge or equippedBadge == "" then
		return ""
	end

	for _, v14 in ipairs(v12) do
		if v14._id ~= equippedBadge then
			continue
		end

		local skinInformation = Skins.GetSkinInformation(v14.Name, v14.Skin)
		return skinInformation and skinInformation.imageAssetId or ""
	end

	return ""
end

local function populateMVPFrame(list)
	local endScreenFrame = getEndScreenFrame() -- inferred equivalent call

	if not endScreenFrame then
		return
	end

	local mvp = endScreenFrame:FindFirstChild("MVP")

	if not mvp then
		return
	end

	hideMvpSlots(mvp)

	for i, v11 in ipairs(list) do
		local child = mvp:FindFirstChild((tostring(v[i])))

		if not child then
			continue
		end

		local data = v11.data
		local userId = v11.userId
		local v12 = tonumber(userId)
		local playerByUserId

		if v12 then
			playerByUserId = Players:GetPlayerByUserId(v12)
		end

		setChildText(child, "Username", data.Name or playerByUserId and playerByUserId.Name or `Player_{userId}`) -- inferred equivalent call
		setChildText(child, "KDA", `{data.Kills or 0}-{data.Deaths or 0}-{data.Assists or 0}`) -- inferred equivalent call
		local kills = data.Kills or 0
		local headshots = data.Headshots or 0
		setChildText(child, "HSP", kills <= 0 and "0%" or `{math.floor(headshots / kills * 100)}%`) -- inferred equivalent call
		setChildText(child, "APR", tostring((math.floor(data.ADR or 0)))) -- inferred equivalent call
		local score = child:FindFirstChild("Score")

		if not score then
			for _, label in child:GetChildren() do
				if not (label:IsA("TextLabel") and label.Name == "NameScore" and label.Text ~= "SCORE") then
					continue
				end

				score = label
				break
			end
		end

		if score then
			score.Text = tostring(data.Score or 0)
		end

		setChildText(child, "Category", data.Accolade or "Participant") -- inferred equivalent call
		local player = child:FindFirstChild("Player")
		local avatar = player and player:FindFirstChild("Avatar")

		if avatar then
			avatar.Image = `rbxthumb://type=AvatarHeadShot&id={data.AvatarUserId or userId}&w=150&h=150`
		end

		local pin = child:FindFirstChild("Pin")

		if pin then
			local image = not (playerByUserId and data.Team) and "" or getEquippedBadgeIcon(playerByUserId, data.Team)

			if image ~= "" then
				pin.Image = image
			end

			pin.Visible = image ~= ""
		end

		child.Visible = true
	end
end

local function positionCharacterOnGround(clone, rootPart, child)
	clone:PivotTo(child.CFrame)
	local boundingBox, v11 = clone:GetBoundingBox()
	local v12 = rootPart.Position.Y - (boundingBox.Position.Y - v11.Y / 2)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { clone, child }
	raycastParams.RespectCanCollide = true
	local v13 = rootPart.Position + createVector(0, 16, 0)
	local raycastResult = workspace:Raycast(v13, createVector(-0, -128, -0), raycastParams)

	if not raycastResult then
		return false
	end

	local v14 = raycastResult.Position.Y + v12 - rootPart.Position.Y
	clone:PivotTo(clone:GetPivot() + Vector3.new(0, v14, 0))
	return true
end

local function playPodiumAnimation(animator, animationId: string, looped: boolean, priority)
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local track = animator:LoadAnimation(animation)
	track.Looped = looped
	track.Priority = priority
	track:Play()
	maid:Add(animation)
	maid:Add(track)
end

local function spawnEndScreenCharacters(list, flag2: boolean)
	local tutorialEndScreenScene = workspace:FindFirstChild("TutorialEndScreenScene")
	local endScreen = tutorialEndScreenScene and tutorialEndScreenScene:FindFirstChild("EndScreen")
		or workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("EndScreen")

	if not endScreen then
		return {}
	end

	local v11 = {}

	for i = 1, math.min(5, #list) do
		table.insert(v11, list[i])
	end

	if flag2 then
		populateMVPFrame(v11)
	end

	local clones = {}

	for i, v12 in ipairs(v11) do
		local v13 = v[i]
		local child = endScreen:FindFirstChild((tostring(v13)))

		if not child then
			continue
		end

		local v14 = v5[v12.data.Team]

		if not v14 then
			continue
		end

		local child2 = Characters:FindFirstChild(v4[v14].Character)

		if not child2 then
			continue
		end

		local clone = child2:Clone()
		clone.Name = "EndScreenCharacter_" .. v12.userId
		local rootPart = CharacterResolver.getRootPart(clone)

		if rootPart then
			rootPart.Anchored = true

			if not positionCharacterOnGround(clone, rootPart, child) then
				warn(`[EndScreen] No ground found below position {v13}; using the position marker height`)
			end

			clone.Parent = endScreen
			attachGlovesToCharacter(clone, v14, v12.data.Gloves)
			attachWeaponToCharacter(clone, v14, v12.data.Weapon)
			local animator = CharacterResolver.getOrCreateAnimator(clone)
			local v15 = v3[v13]

			if animator and v15 then
				playPodiumAnimation(animator, v15.Entrance, false, Enum.AnimationPriority.Action)
				playPodiumAnimation(animator, v15.Idle, true, Enum.AnimationPriority.Idle)
			end

			maid:Add(clone, "Destroy")
			table.insert(clones, clone)
		else
			warn(`[EndScreen] Character template {child2.Name} is missing a HumanoidRootPart`)
			clone:Destroy()
		end
	end

	return clones
end

local function animateCamera()
	local tutorialEndScreenScene = workspace:FindFirstChild("TutorialEndScreenScene")
	local endScreen = tutorialEndScreenScene and tutorialEndScreenScene:FindFirstChild("EndScreen")
		or workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("EndScreen")

	if not endScreen then
		return nil
	end

	local start = endScreen:FindFirstChild("Start")
	local firstChild = endScreen:FindFirstChild("End")

	if not (start and firstChild) then
		warn("[EndScreen] Missing Start or End part!")
		return nil
	end

	CurrentCamera.CameraType = Enum.CameraType.Scriptable
	CurrentCamera.CFrame = start.CFrame
	CurrentCamera.Focus = start.CFrame
	CurrentCamera.FieldOfView = 60
	CameraController.setMouseEnabled(true)
	maid:Add(CurrentCamera:GetPropertyChangedSignal("CameraType"):Connect(function()
		if CurrentCamera.CameraType ~= Enum.CameraType.Scriptable then
			CurrentCamera.CameraType = Enum.CameraType.Scriptable
		end
	end))
	local tween = TweenService:Create(CurrentCamera, TweenInfo.new(14, Enum.EasingStyle.Linear), {
		CFrame = firstChild.CFrame
	})
	tween:Play()
	return tween
end

local function closeAllActiveScenes()
	MenuState.SetBlurEnabled(false)

	if MenuState.IsCaseSceneActive() then
		Router.broadcastRouter("CaseSceneCloseForGameEnd")
	end

	if MenuState.IsInspectActive() then
		Router.broadcastRouter("WeaponInspectCloseForGameEnd")
	end

	if MenuState.IsTradeUpActive() then
		return
	end

	local mainGui = PlayerGui:FindFirstChild("MainGui")
	local menu = mainGui and mainGui:FindFirstChild("Menu")

	if menu then
		if menu.Visible then
			MenuState.HideMenu()
			CameraController.setForceLockOverride("Menu", false)
		end

		menu.BackgroundTransparency = 1
	end

	local middleFrame = getMiddleFrame() -- inferred equivalent call

	if not middleFrame then
		return
	end

	local buyMenu = middleFrame:FindFirstChild("BuyMenu")

	if buyMenu and buyMenu.Visible then
		local BuyMenu = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.BuyMenu)
		BuyMenu.closeFrame()
	end

	local teamSelection = middleFrame:FindFirstChild("TeamSelection")

	if teamSelection and teamSelection.Visible then
		local TeamSelection = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.TeamSelection)
		TeamSelection.closeFrame()
	end
end

function EndScreenController.IsActive()
	return flag
end

local function cacheLevelData(level) -- 1 equivalent call inferred from this helper
	if level then
		v7 = {
			Level = level.Level,
			Experience = level.Experience,
			NextExperienceRequirement = level.NextExperienceRequirement
		}
	end
end

local function showMainMenuAfterEndScreen()
	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
	local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
	MenuSceneController.ShowMenuScene()
	Top.ResetToMainMenu()
	local mainGui = PlayerGui:FindFirstChild("MainGui")

	if not mainGui then
		return
	end

	CameraController.setForceLockOverride("Menu", true)
	CameraController.setPerspective(true, true)
	mainGui.Menu.Visible = true
	mainGui.Gameplay.Visible = false
	mainGui.Gameplay.Bottom.Visible = false
end

function EndScreenController.ExitMapVoteToMenu()
	if locked then
		return
	end

	MenuState.SetWantsMainMenu(true)

	if flag then
		EndScreenController._finishSequence(true)
		return
	end

	CameraController.setForceLockOverride("EndScreen", false)
	hideEndScreenUI()
	CameraController.SetEnabled(true)
	showMainMenuAfterEndScreen()
	v6 = nil
	returnToMenu = true
end

function EndScreenController._runSequence(data)
	count += 1
	local v11 = count
	returnToMenu = data.returnToMenu
	overlayMode = data.overlayMode
	locked = data.locked
	cleanupDebris()
	showEndScreenUI(data)
	local endScreenFrame = getEndScreenFrame() -- inferred equivalent call
	local close = endScreenFrame and endScreenFrame:FindFirstChild("Close")

	if close then
		close.Visible = not data.locked
	end

	local success, result = pcall(spawnEndScreenCharacters, data.displayPlayers, data.showAccolades)

	if not success then
		warn(`[EndScreen] Podium failed: {result}`)
	end

	local v12 = animateCamera()

	if v12 then
		maid:Add(v12, "Cancel")
	end

	if data.showProgression then
		task.delay(4, function()
			if v11 ~= count then
				return
			end

			local endScreenFrame2 = getEndScreenFrame() -- inferred equivalent call

			if not endScreenFrame2 then
				return
			end

			local victory = endScreenFrame2:FindFirstChild("Victory")
			local defeat = endScreenFrame2:FindFirstChild("Defeat")
			local level = endScreenFrame2:FindFirstChild("Level")
			local v13 = populateLevelFrame(data.xpEarned)
			local v14 = data.isDraw and victory or data.didWin and victory or defeat

			if v14 and v14.Visible then
				fadeFrame(v14, 1)
			end

			task.delay(0.5, function()
				if v11 ~= count then
					return
				end

				if victory then
					victory.Visible = false
				end

				if defeat then
					defeat.Visible = false
				end

				if level then
					fadeInFrame(level)
					task.spawn(function()
						if v13 then
							animateLevelBar(v13)
						end

						displayDrops(data.levelRewards)
					end)
				end
			end)
		end)
	end

	if data.locked then
		return
	end

	local sequenceDuration = data.sequenceDuration or data.showProgression and 14 or 4
	task.delay(sequenceDuration, function()
		if v11 ~= count then
			return
		end

		EndScreenController._finishSequence(data.returnToMenu)
	end)
end

function EndScreenController._finishSequence(flag2: boolean?)
	if locked then
		return
	end

	if flag2 == nil then
		flag2 = returnToMenu
	end

	if typeof(flag2) ~= "boolean" then
		flag2 = flag2 and true or returnToMenu
	end

	count += 1
	overlayMode = "EndScreen"
	flag = false
	CameraController.setForceLockOverride("EndScreen", false)
	maid:Cleanup()
	hideEndScreenUI()
	CameraController.SetEnabled(true)
	local mainGui = PlayerGui:FindFirstChild("MainGui")

	if flag2 or not (mainGui and v6) then
		showMainMenuAfterEndScreen()
		v6 = nil
		returnToMenu = true
	else
		restoreVisibilitySnapshot(mainGui, true)
		MenuState.HideMenu()
		mainGui.Gameplay.Visible = true
		CameraController.setPerspective(true, false)
	end

	cacheLevelData(DataController.Get(LocalPlayer, "Level")) -- inferred equivalent call
end

function EndScreenController.Begin(data)
	if locked then
		return
	end

	local overlayMode2 = data.Halftime == true and "Halftime" or "EndScreen"

	if flag then
		warn("[EndScreen] Interrupting active sequence for new end screen")
		local success, result = pcall(EndScreenController._finishSequence, false)

		if not success then
			warn("[EndScreen] _finishSequence error during interrupt: " .. tostring(result))
		end

		flag = false
	end

	if
		MenuState.IsTradeUpActive()
		or MenuState.IsCaseSceneActive() and Router.broadcastRouter("IsCaseSceneRolling") == true
	then
		return
	end

	local v11 = workspace:GetAttribute("Gamemode") == "Deathmatch"
	local v12

	if data.Players then
		v12 = data.Players[tostring(LocalPlayer.UserId)] or nil
	end

	if not v12 then
		warn(("[EndScreen] Local player missing from payload (userId=%s, teamAttr=%s, winningTeam=%s)"):format(
			tostring(LocalPlayer.UserId),
			tostring(LocalPlayer:GetAttribute("Team")),
			(tostring(data.WinningTeam))
		))

		if not IsPlayingTeam(LocalPlayer:GetAttribute("Team")) or v11 then
			return
		end
	end

	local team = v12 and v12.Team or LocalPlayer:GetAttribute("Team")
	local isDraw = data.WinningTeam == "Draw"
	local scoreTextOverride = nil
	local displayPlayers, didWin

	if v11 then
		if not (v12 and IsPlayingTeam(v12.Team)) then
			warn(("[EndScreen] Begin skipped for Deathmatch: invalid team data (team=%s)"):format((tostring(v12 and v12.Team))))
			return
		end

		displayPlayers = collectPlayingPlayers(data.Players)
		table.sort(displayPlayers, function(a, b)
			if (a.data.Score or 0) ~= (b.data.Score or 0) then
				return (a.data.Score or 0) > (b.data.Score or 0)
			end

			if (a.data.Kills or 0) ~= (b.data.Kills or 0) then
				return (a.data.Kills or 0) > (b.data.Kills or 0)
			end

			if (a.data.Assists or 0) == (b.data.Assists or 0) then
				return (tonumber(a.userId) or 1e999) < (tonumber(b.userId) or 1e999)
			end

			return (a.data.Assists or 0) > (b.data.Assists or 0)
		end)

		if #displayPlayers == 0 then
			warn("[EndScreen] Begin skipped for Deathmatch: no eligible ranked players")
			return
		end

		local v13 = nil

		for i, v14 in ipairs(displayPlayers) do
			if v14.userId ~= tostring(LocalPlayer.UserId) then
				continue
			end

			v13 = i
			break
		end

		if not v13 then
			warn(("[EndScreen] Begin skipped for Deathmatch: local player missing from ranked list (userId=%s)"):format((tostring(LocalPlayer.UserId))))
			return
		end

		didWin = v13 == 1
		scoreTextOverride = `You placed {getOrdinalPlacementText(v13)}` -- inferred equivalent call
	else
		if not IsPlayingTeam(team) then
			warn(("[EndScreen] Begin skipped: invalid team (team=%s, teamAttr=%s, winningTeam=%s)"):format(
				tostring(team),
				tostring(LocalPlayer:GetAttribute("Team")),
				(tostring(data.WinningTeam))
			))
			return
		end

		didWin = not isDraw and data.WinningTeam == team
		local players = {}

		for k, player in pairs(data.Players) do
			if player.Team == team then
				players[k] = player
			end
		end

		displayPlayers = collectPlayingPlayers(players)
		table.sort(displayPlayers, function(a, b)
			if (a.data.ADR or 0) ~= (b.data.ADR or 0) then
				return (a.data.ADR or 0) > (b.data.ADR or 0)
			end

			if (a.data.Score or 0) == (b.data.Score or 0) then
				return (tonumber(a.userId) or 1e999) < (tonumber(b.userId) or 1e999)
			end

			return (a.data.Score or 0) > (b.data.Score or 0)
		end)
	end

	closeAllActiveScenes()
	SpectateController.Stop(false, true)
	CameraController.SetEnabled(false)
	flag = true
	local v13 = {}

	for k in pairs(data.Players) do
		local v14 = tonumber(k)

		if v14 then
			table.insert(v13, v14)
		end
	end

	table.sort(v13)
	local levelRewards2 = {}

	for _, userId in ipairs(v13) do
		local player = data.Players[tostring(userId)]
		local levelRewards = player and player.LevelRewards

		if not levelRewards then
			continue
		end

		for _, levelReward in ipairs(levelRewards) do
			table.insert(levelRewards2, { userId = userId, reward = levelReward })
		end
	end

	EndScreenController._runSequence({
		displayPlayers = displayPlayers,
		didWin = didWin,
		isDraw = isDraw,
		winningTeam = data.WinningTeam,
		xpEarned = v12 and v12.ExperienceEarned or 0,
		levelRewards = levelRewards2,
		ctScore = data.CTScore or 0,
		tScore = data.TScore or 0,
		scoreTextOverride = scoreTextOverride,
		showAccolades = data.ShowAccolades ~= false,
		showProgression = data.ShowProgression ~= false,
		sequenceDuration = data.SequenceDuration,
		returnToMenu = data.ReturnToMenu ~= false,
		overlayMode = overlayMode2,
		halftimeTeam = team,
		locked = data.Locked == true
	})
end

function EndScreenController.Initialize()
	local endScreenFrame = getEndScreenFrame() -- inferred equivalent call

	if endScreenFrame then
		setChildVisible(endScreenFrame, "Drops", false) -- inferred equivalent call
		local close = endScreenFrame:FindFirstChild("Close")

		if close then
			ActivateButton(close)
			CloseButtonRegistry.Add(endScreenFrame, close, function()
				if flag then
					MenuState.SetWantsMainMenu(true)
					EndScreenController._finishSequence(true)
				elseif GameState.GetState() == "Map Voting" then
					EndScreenController.ExitMapVoteToMenu()
				end
			end)
		end
	end

	DataController.CreateListener(LocalPlayer, "Level", function(data)
		if v7 == nil and data then
			v7 = {
				Level = data.Level,
				Experience = data.Experience,
				NextExperienceRequirement = data.NextExperienceRequirement
			}
		end
	end)
	Remotes.Match.EndScreen.Listen(function(p)
		EndScreenController.Begin(p)
	end)
end

return EndScreenController