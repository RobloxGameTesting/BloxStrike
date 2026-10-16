local VIPMenu = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local LocalPlayer = Players.LocalPlayer
local isStudio = RunService:IsStudio()
local Maps = ReplicatedStorage.Database.Custom.GameStats.Maps
local v = {
	{ Name = "DropKnife", Label = "Drop Knife", Key = "KnifeDropEnabled" },
	{ Name = "FreezeTimer", Label = "Freeze Timer", Key = "TimerFrozen" },
	{ Name = "KillTrading", Label = "Kill Trading", Key = "KillTradingEnabled" },
	{ Name = "InfiniteAmmo", Label = "Infinite Ammo", Key = "InfiniteAmmoEnabled" },
	{ Name = "InfiniteCash", Label = "Infinite Cash", Key = "InfiniteCashEnabled" },
	{ Name = "DisableTeamLimit", Label = "Disable Team Limit", Key = "DisableTeamLimitEnabled" },
	{ Name = "FriendlyFire", Label = "Friendly Fire", Key = "FriendlyFireEnabled" },
	{ Name = "PlayerCollisions", Label = "Player Collisions", Key = "PlayerCollisionsEnabled" },
	{
		Name = "CompetitiveMovement",
		Label = "Competitive Movement",
		Key = "CompetitiveMovementEnabled"
	}
}
local v2 = { "Easy", "Normal", "Hard", "Expert" }
local v3 = {
	Easy = Color3.fromRGB(126, 211, 133),
	Normal = Color3.fromRGB(238, 238, 238),
	Hard = Color3.fromRGB(240, 168, 76),
	Expert = Color3.fromRGB(236, 88, 88)
}
local v4 = {
	{
		Name = "TerroristBots",
		Label = "Terrorist Bots",
		Accent = Color3.fromRGB(222, 176, 82),
		Key = "BotTerrorists",
		OtherKey = "BotCounterTerrorists"
	},
	{
		Name = "CounterTerroristBots",
		Label = "CT Bots",
		Accent = Color3.fromRGB(104, 158, 228),
		Key = "BotCounterTerrorists",
		OtherKey = "BotTerrorists"
	}
}
local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(150, 150, 150)
local color3 = Color3.fromRGB(125, 206, 243)
local color4 = Color3.fromRGB(92, 92, 92)
local color5 = Color3.fromRGB(32, 32, 32)
local color6 = Color3.fromRGB(150, 44, 44)
local color7 = Color3.fromRGB(236, 96, 96)
local color8 = Color3.fromRGB(255, 255, 255)
local color9 = Color3.fromRGB(77, 77, 77)
local tweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfo2 = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local tweenInfo3 = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local tweenInfo4 = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local tweenInfo5 = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfo6 = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local v5 = {
	{
		Name = "Competitive",
		Mode = "COMPETITIVE",
		Description = "Classic round-based rules with economy and no respawns.",
		ServerGamemode = "Competitive",
		Image = "rbxassetid://94623163725066"
	},
	{
		Name = "Casual",
		Mode = "CASUAL",
		Description = "Relaxed round-based rules with lighter penalties.",
		ServerGamemode = "Casual",
		Image = "rbxassetid://129151622905807"
	},
	{
		Name = "Deathmatch",
		Mode = "DEATHMATCH",
		Description = "Fast respawn combat focused on eliminations.",
		ServerGamemode = "Deathmatch",
		Image = "rbxassetid://102545840590668"
	},
	{
		Name = "Surf",
		Mode = "SURF",
		Description = "Slide down ramps with CS:GO surf movement.",
		ServerGamemode = "Surf"
	}
}
local v6 = {
	GodMode = { Key = "GodModeEnabledPlayers", Title = "God Mode" },
	ESP = { Key = "ESPEnabledPlayers", Title = "ESP" }
}
local v7 = {}
local data = {}
local v8 = {}
local v9 = false
local serverGamemode = nil
local v10 = {}
local v11 = "Settings"
local v12 = "KickPlayer"
local clonesByName = {}
local clonesByName2 = {}
local v13 = {}
local flag = false
local v14 = nil
local object = setmetatable({}, { __mode = "k" })
local object2 = setmetatable({}, { __mode = "k" })
local maid = Janitor.new()
local maid2 = Janitor.new()
local v15 = Janitor.new()
local v16 = Janitor.new()
local v17 = Janitor.new()
local v18 = nil
local v19 = nil
local backdrop = nil
local backgroundTransparency = 0
local v20 = {}
local scrollingFrame = nil
local selectMap = nil
local selectMode = nil
local voteKick = nil
local container = nil
local title = nil
local sectionTemplate = nil
local toggleTemplate = nil
local inputTemplate = nil
local clickTemplate = nil
local template = nil
local template2 = nil
local template3 = nil

local function canUseVIPMenu() -- 1 equivalent call inferred from this helper
	return isStudio or LocalPlayer:GetAttribute("CanUseVIPMenu") == true
end

local function hasActiveCharacter() -- 2 equivalent calls inferred from this helper
	local character = LocalPlayer.Character
	return character ~= nil and character:IsDescendantOf(workspace)
end

local function isOnPlayingTeam()
	local team = LocalPlayer:GetAttribute("Team")
	return team == "Counter-Terrorists" or team == "Terrorists"
end

local function isInGameplayContext() -- 1 equivalent call inferred from this helper
	local team = LocalPlayer:GetAttribute("Team")
	return team == "Counter-Terrorists" or team == "Terrorists" or LocalPlayer:GetAttribute("IsSpectating") == true
end

local function getMainGuiFromRoot() -- 3 equivalent calls inferred from this helper
	local parent = v18 and v18.Parent
	local parent2 = parent and parent.Parent
	local parent3 = parent2 and parent2.Parent

	if parent3 and parent3:IsA("ScreenGui") then
		return parent3
	end

	return nil
end

local function isMainMenuVisible()
	local mainGuiFromRoot = getMainGuiFromRoot() -- inferred equivalent call

	if not mainGuiFromRoot then
		return false
	end

	local menu = mainGuiFromRoot:FindFirstChild("Menu")
	return menu ~= nil and menu:IsA("GuiObject") and menu.Visible
end

local function isTeamSelectionVisible()
	local mainGuiFromRoot = getMainGuiFromRoot() -- inferred equivalent call

	if not mainGuiFromRoot then
		return false
	end

	local gameplay = mainGuiFromRoot:FindFirstChild("Gameplay")

	if not (gameplay and gameplay:IsA("GuiObject")) then
		return false
	end

	local middle = gameplay:FindFirstChild("Middle")

	if not (middle and middle:IsA("GuiObject")) then
		return false
	end

	local teamSelection = middle:FindFirstChild("TeamSelection")
	return teamSelection ~= nil and teamSelection:IsA("GuiObject") and teamSelection.Visible
end

local function isLocalPlayerSpectating()
	return LocalPlayer:GetAttribute("IsSpectating") == true
end

local function bindPress(maid3, button, onMouseButton1Click)
	if button:IsA("GuiButton") then
		maid3:Add(button.MouseButton1Click:Connect(onMouseButton1Click))
		return
	end

	button.Active = true
	maid3:Add(button.InputBegan:Connect(function(input)
		local userInputType = input.UserInputType

		if userInputType ~= Enum.UserInputType.MouseButton1 and userInputType ~= Enum.UserInputType.Touch then
			return
		end

		onMouseButton1Click()
	end))
end

local function bindHover(maid3, p, fn)
	maid3:Add(p.MouseEnter:Connect(function()
		fn(true)
	end))
	maid3:Add(p.MouseLeave:Connect(function()
		fn(false)
	end))
end

local function tween(p, p2, p3)
	local tween2 = TweenService:Create(p, p2, p3)
	tween2:Play()
	return tween2
end

local function paintButton(p)
	local backgroundColor = object[p]

	if backgroundColor then
		if object2[p] then
			backgroundColor = backgroundColor:Lerp(Color3.new(1, 1, 1), 0.12)
		end

		TweenService:Create(p, tweenInfo, { BackgroundColor3 = backgroundColor }):Play()
	end
end

local function setButtonColor(instance, color10: Color3) -- 1 equivalent call inferred from this helper
	object[instance] = color10
	paintButton(instance)
end

local function bindButtonHover(p, p2) -- 6 equivalent calls inferred from this helper
	object[p2] = object[p2] or p2.BackgroundColor3
	bindHover(p, p2, function(p3)
		object2[p2] = p3 and true or nil
		paintButton(p2)
	end)
end

local function getScale(parent) -- 2 equivalent calls inferred from this helper
	local v21 = parent:FindFirstChildOfClass("UIScale")

	if not v21 then
		v21 = Instance.new("UIScale")
		v21.Parent = parent
	end

	return v21
end

local function popIn(parent, scale: number, p: number?)
	local scale2 = getScale(parent) -- inferred equivalent call
	scale2.Scale = scale
	local v21

	if p then
		v21 = TweenInfo.new(tweenInfo5.Time, tweenInfo5.EasingStyle, tweenInfo5.EasingDirection, 0, false, p)
	else
		v21 = tweenInfo5
	end

	TweenService:Create(scale2, v21, { Scale = 1 }):Play()
end

local function slideIn(instance, udim: UDim2)
	local basePosition = instance:GetAttribute("BasePosition")

	if typeof(basePosition) ~= "UDim2" then
		basePosition = instance.Position
		instance:SetAttribute("BasePosition", basePosition)
	end

	instance.Position = basePosition + udim
	TweenService:Create(instance, tweenInfo4, { Position = basePosition }):Play()
end

local function punchLabel(instance)
	local baseSize = instance:GetAttribute("BaseSize")

	if typeof(baseSize) ~= "UDim2" then
		baseSize = instance.Size
		instance:SetAttribute("BaseSize", baseSize)
	end

	instance.Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset, baseSize.Y.Scale * 1.3, baseSize.Y.Offset)
	TweenService:Create(instance, tweenInfo6, { Size = baseSize }):Play()
end

local function setLabelValue(title2, text: string, textColor: Color3) -- 3 equivalent calls inferred from this helper
	title2.TextColor3 = textColor

	if title2.Text ~= text then
		title2.Text = text
		punchLabel(title2)
	end
end

local function playClick() -- 9 equivalent calls inferred from this helper
	Router.broadcastRouter("RunInterfaceSound", "UI Click")
end

local function clearGenerated(instance, p, p2)
	for _, guiObject in ipairs(instance:GetChildren()) do
		if guiObject == p or p2 and p2[guiObject.Name] or not guiObject:IsA("GuiObject") then
			continue
		end

		guiObject:Destroy()
	end

	p.Visible = false
end

local function getTogglePlayers(p: string)
	local v21 = v7[p]

	if typeof(v21) == "table" then
		return v21
	end

	local v22 = {}
	v7[p] = v22
	return v22
end

local function setLocalTogglePlayer(key: string, userId: number, flag2: boolean) -- 1 equivalent call inferred from this helper
	local v21 = v7[key]

	if typeof(v21) ~= "table" then
		v21 = {}
		v7[key] = v21
	end

	v21[userId] = nil
	v21[tostring(userId)] = flag2 and true or nil
	return v21
end

local function isPlayerToggleEnabled(key: string, userId: number) -- 2 equivalent calls inferred from this helper
	local v21 = v7[key]
	return typeof(v21) == "table" and (v21[tostring(userId)] == true or v21[userId] == true)
end

local function updateVoteKickHeader() -- 1 equivalent call inferred from this helper
	if not title then
		return
	end

	local v21 = v6[v12]
	title.Text = string.upper(not v21 and "Kick Player" or v21.Title)
end

local function updateRootPosition(flag2: boolean)
	local v21 = not voteKick.Visible and 0 or -(voteKick.AbsoluteSize.X + v18.AbsoluteSize.X * 0.02) / 2
	local udim = UDim2.new(0.5, v21, 0.5, 0)

	if flag2 then
		TweenService:Create(v18, tweenInfo4, { Position = udim }):Play()
	else
		v18.Position = udim
	end
end

local function setTabVisual(instance, visible: boolean) -- 2 equivalent calls inferred from this helper
	local v21

	if visible then
		v21 = color4
	else
		v21 = color5
	end

	setButtonColor(instance, v21) -- inferred equivalent call
	local selected = instance:FindFirstChild("Selected")

	if selected and selected:IsA("GuiObject") then
		selected.Visible = visible
	end
end

local function staggerCards(instance)
	local guiObjects = {}

	for _, guiObject in ipairs(instance:GetChildren()) do
		if guiObject:IsA("GuiObject") and guiObject.Visible then
			table.insert(guiObjects, guiObject)
		end
	end

	table.sort(guiObjects, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for i, v21 in ipairs(guiObjects) do
		popIn(v21, 0.9, (i - 1) * 0.035)
	end
end

local function showPanel(p: string, flag2: boolean?)
	v11 = p
	scrollingFrame.Visible = p == "Settings"
	selectMap.Visible = p == "MapSelect"
	selectMode.Visible = p == "ModeSelect"

	for k, v21 in pairs(v20) do
		setTabVisual(v21, k == p) -- inferred equivalent call
	end

	if flag2 then
		local v21

		if p == "Settings" then
			v21 = scrollingFrame
		elseif p == "MapSelect" then
			v21 = selectMap
		else
			v21 = selectMode
		end

		slideIn(v21, UDim2.fromOffset(0, 16))

		if p ~= "Settings" then
			staggerCards(v21)
		end
	end
end

local function showPlayers() -- 1 equivalent call inferred from this helper
	updateVoteKickHeader() -- inferred equivalent call

	if not voteKick.Visible then
		voteKick.Visible = true
		slideIn(voteKick, UDim2.fromOffset(-40, 0))
	end

	updateRootPosition(true)
end

local function hidePlayers(flag2: boolean) -- 3 equivalent calls inferred from this helper
	voteKick.Visible = false
	updateRootPosition(flag2)
end

local function getMapInfo(childName: string)
	if v10[childName] ~= nil then
		return v10[childName]
	end

	local init = Maps:FindFirstChild(childName)

	if init and not init:IsA("ModuleScript") then
		init = init:FindFirstChild("init")
	end

	if not (init and init:IsA("ModuleScript")) then
		return nil
	end

	local success, result = pcall(require, init)

	if not success or typeof(result) ~= "table" then
		result = nil
	end

	v10[childName] = result
	return result
end

local function mapSupportsMode(p: string, p2: string?)
	if not p2 then
		return true
	end

	local mapInfo = getMapInfo(p)
	local gamemode = mapInfo and mapInfo.Gamemode

	if typeof(gamemode) ~= "table" then
		return false
	end

	local v21 = gamemode[p2]
	return v21 ~= nil and v21 ~= false
end

local function loadAvailableMaps()
	v8 = {}

	for _, init in ipairs(Maps:GetChildren()) do
		local name = init.Name

		if not init:IsA("ModuleScript") then
			init = init:FindFirstChild("init")
		end

		if not (init and init:IsA("ModuleScript")) then
			continue
		end

		local success, result = pcall(require, init)

		if not (success and typeof(result) == "table" and result.Hidden ~= true) then
			continue
		end

		v10[name] = result

		if name ~= "Tutorial Range" then
			table.insert(v8, {
				Name = name,
				Icon = typeof(result.Icon) ~= "string" and "" or result.Icon or ""
			})
		end
	end

	table.sort(v8, function(a, b)
		return a.Name < b.Name
	end)
	v9 = true
end

local function getGamemodeIcon(serverGamemode2: string)
	for _, v21 in ipairs(v8) do
		local name = v21.Name
		local v22

		if serverGamemode2 then
			local mapInfo = getMapInfo(name)
			local gamemode = mapInfo and mapInfo.Gamemode

			if typeof(gamemode) == "table" then
				local v23 = gamemode[serverGamemode2]

				if v23 == nil then
					v22 = false
				else
					v22 = v23 ~= false
				end
			else
				v22 = false
			end
		else
			v22 = true
		end

		if v22 and v21.Icon ~= "" then
			return v21.Icon
		end
	end

	return nil
end

local function setSegments(bar, p: number, fn, color10: Color3?)
	local uiListLayout = bar:FindFirstChildOfClass("UIListLayout")
	local v21 = p > 4 and 0.012 or 0.03

	if uiListLayout then
		uiListLayout.Padding = UDim.new(v21, 0)
	end

	local v22 = {}

	for _, frame in ipairs(bar:GetChildren()) do
		if frame:IsA("Frame") then
			table.insert(v22, frame)
		end
	end

	for i = #v22 + 1, p do
		local frame = Instance.new("Frame")
		frame.BorderSizePixel = 0
		frame.BackgroundColor3 = color9
		frame.Parent = bar
		v22[i] = frame
	end

	local v23 = (1 - v21 * (p - 1)) / p

	for i, v24 in ipairs(v22) do
		v24.Name = tostring(i)
		v24.LayoutOrder = i
		v24.Visible = i <= p
		v24.Size = UDim2.fromScale(v23, 1)
		local backgroundColor

		if fn(i) then
			backgroundColor = color10 or color8
		else
			backgroundColor = color9
		end

		if v24.BackgroundColor3 ~= backgroundColor then
			TweenService:Create(v24, tweenInfo, { BackgroundColor3 = backgroundColor }):Play()
		end
	end
end

local function setArrowEnabled(button, enabled: boolean) -- 6 equivalent calls inferred from this helper
	button:SetAttribute("Enabled", enabled)

	if button:IsA("ImageButton") then
		button.ImageTransparency = enabled and 0 or 0.75
	end
end

local function setToggleSelector(data2, enabled: boolean)
	setLabelValue(data2.Title, enabled and "ON" or "OFF", color) -- inferred equivalent call
	setSegments(data2.Bar, 2, function(p)
		return p == (enabled and 2 or 1)
	end)
	setArrowEnabled(data2.Decrease, enabled) -- inferred equivalent call
	setArrowEnabled(data2.Increase, not enabled) -- inferred equivalent call
end

local function isBotAutoFill() -- 1 equivalent call inferred from this helper
	return v7.BotAutoFill ~= false
end

local function areBotsFrozen() -- 1 equivalent call inferred from this helper
	return v7.BotsFrozen == true
end

local function getBotCount(p: string) -- 4 equivalent calls inferred from this helper
	local v21 = v7[p]

	if typeof(v21) == "number" then
		return v21
	end

	return 0
end

local function getBotDifficulty() -- 2 equivalent calls inferred from this helper
	local botDifficulty = v7.BotDifficulty

	if table.find(v2, botDifficulty) then
		return botDifficulty
	end

	return v2[1]
end

local function refreshBotControls()
	local botAutoFill = isBotAutoFill() -- inferred equivalent call

	for _, v21 in ipairs(v4) do
		local v22 = v13[v21.Name]

		if not v22 then
			continue
		end

		local botCount = getBotCount(v21.Key) -- inferred equivalent call
		local title2 = v22.Title
		local text = tostring(botCount)
		local v23

		if botAutoFill then
			v23 = color2
		else
			v23 = color
		end

		setLabelValue(title2, text, v23) -- inferred equivalent call
		local bar = v22.Bar

		local function fn(p)
			return p <= botCount
		end

		local v24

		if botAutoFill then
			v24 = color2
		else
			v24 = v21.Accent
		end

		setSegments(bar, 14, fn, v24)
		setArrowEnabled(v22.Decrease, botCount > 0) -- inferred equivalent call
		setArrowEnabled(v22.Increase, botCount + getBotCount(v21.OtherKey) < 14) -- inferred equivalent call
	end

	local botDifficulty = v13.BotDifficulty

	if botDifficulty then
		local botDifficulty2 = getBotDifficulty() -- inferred equivalent call
		local index = table.find(v2, botDifficulty2)
		setLabelValue(botDifficulty.Title, string.upper(botDifficulty2), v3[botDifficulty2]) -- inferred equivalent call
		setSegments(botDifficulty.Bar, #v2, function(p)
			return p <= index
		end, v3[botDifficulty2])
		setArrowEnabled(botDifficulty.Decrease, index > 1) -- inferred equivalent call
		setArrowEnabled(botDifficulty.Increase, index < #v2) -- inferred equivalent call
	end

	if v13.BotAutoFill then
		setToggleSelector(v13.BotAutoFill, botAutoFill)
	end

	if v13.BotsFrozen then
		setToggleSelector(v13.BotsFrozen, areBotsFrozen()) -- inferred equivalent call
	end
end

local function updateToggleIndicators()
	for _, v21 in ipairs(v) do
		local v22 = v13[v21.Name]

		if v22 then
			setToggleSelector(v22, v7[v21.Key] == true)
		end
	end

	refreshBotControls()
end

local function setCardSelected(instance, flag2: boolean)
	local badge = instance:FindFirstChild("Badge")

	if badge and badge:IsA("GuiObject") then
		local visible = badge.Visible
		badge.Visible = flag2

		if flag2 and not visible then
			popIn(badge, 0.5)
		end
	end

	local highlight = instance:FindFirstChild("Highlight", true)

	if highlight and highlight:IsA("UIStroke") then
		highlight.Enabled = flag2
	end
end

local function bindCardHover(p, clone)
	local image = clone:FindFirstChild("Image", true)

	if image and image:IsA("ImageLabel") then
		local imageColor3 = image.ImageColor3
		bindHover(p, clone, function(p2)
			local v21 = p2 and 1.06 or 1
			local imageColor

			if p2 then
				imageColor = imageColor3:Lerp(Color3.new(1, 1, 1), 0.35)
			else
				imageColor = imageColor3
			end

			TweenService:Create(image, tweenInfo4, {
				ImageColor3 = imageColor,
				Size = UDim2.fromScale(v21, v21)
			}):Play()
		end)
	end
end

local function refreshMaps()
	for _, v21 in ipairs(v8) do
		local v22 = clonesByName[v21.Name]

		if not v22 then
			continue
		end

		local name = v21.Name
		local v23 = serverGamemode
		local visible

		if v23 then
			local mapInfo = getMapInfo(name)
			local gamemode = mapInfo and mapInfo.Gamemode

			if typeof(gamemode) == "table" then
				local v24 = gamemode[v23]

				if v24 == nil then
					visible = false
				else
					visible = v24 ~= false
				end
			else
				visible = false
			end
		else
			visible = true
		end

		v22.Visible = visible
		setCardSelected(v22, v7.NextMap == v21.Name)
	end
end

local function buildMapEntries()
	if not v9 then
		return
	end

	v15:Cleanup()
	table.clear(clonesByName)
	clearGenerated(selectMap, template, nil)

	for i, v21 in ipairs(v8) do
		local clone = template:Clone()
		clone.Name = v21.Name
		clone.LayoutOrder = i
		clone.Visible = true
		local image = clone:FindFirstChild("Image", true)
		image.Image = v21.Icon
		local mapName = clone:WaitForChild("MapName")
		mapName.Text = string.upper(v21.Name)
		bindCardHover(v15, clone)
		local v22 = v21
		bindPress(v15, clone, function()
			playClick() -- inferred equivalent call
			v7.NextMap = v22.Name
			Remotes.VIP.SetSetting.Send({ Key = "NextMap", Value = v22.Name })
			refreshMaps()
		end)
		clone.Parent = selectMap
		clonesByName[v21.Name] = clone
	end

	refreshMaps()
end

local function refreshModeCards()
	local nextGamemode

	if typeof(v7.NextGamemode) == "string" then
		nextGamemode = v7.NextGamemode
	else
		nextGamemode = serverGamemode
	end

	for _, v21 in ipairs(v5) do
		local v22 = clonesByName2[v21.Name]

		if v22 then
			setCardSelected(v22, nextGamemode == v21.ServerGamemode)
		end
	end
end

local function buildModeCards()
	v16:Cleanup()
	table.clear(clonesByName2)
	clearGenerated(selectMode, template2, nil)
	local uiListLayout = selectMode:FindFirstChildOfClass("UIListLayout")
	local v21 = not uiListLayout and 0 or uiListLayout.Padding.Scale
	local count = #v5
	local v22 = (1 - v21 * (count - 1)) / count

	for i, v23 in ipairs(v5) do
		local clone = template2:Clone()
		clone.Name = v23.Name
		clone.LayoutOrder = i
		clone.Size = UDim2.fromScale(v22, 1)
		clone.Visible = true
		local mode = clone:WaitForChild("Mode")
		local description = clone:WaitForChild("Description")
		local image = clone:FindFirstChild("Image", true)
		mode.Text = v23.Mode
		description.Text = v23.Description
		image.Image = v23.Image or getGamemodeIcon(v23.ServerGamemode) or ""
		bindCardHover(v16, clone)
		local v24 = v23
		bindPress(v16, clone, function()
			playClick() -- inferred equivalent call
			serverGamemode = v24.ServerGamemode
			Remotes.VIP.SetSetting.Send({ Key = "NextGamemode", Value = v24.ServerGamemode })
			refreshModeCards()
			showPanel("MapSelect", true)
			refreshMaps()
		end)
		clone.Parent = selectMode
		clonesByName2[v23.Name] = clone
	end

	refreshModeCards()
end

local function renderPlayers()
	v17:Cleanup()
	clearGenerated(container, template3, nil)
	local v21 = v6[v12]
	local layoutOrder = 1

	for _, v22 in ipairs(data) do
		if not (v12 ~= "KickPlayer" or v22.UserId ~= LocalPlayer.UserId) then
			continue
		end

		local clone = template3:Clone()
		clone.Name = tostring(v22.UserId)
		clone.LayoutOrder = layoutOrder
		clone.Visible = true
		layoutOrder += 1
		local left = clone:WaitForChild("Left")
		local avatar = left:WaitForChild("Avatar")
		local name = left:WaitForChild("Name")
		local bomb = avatar:WaitForChild("Bomb")
		local state = clone:WaitForChild("Right"):WaitForChild("State")
		local selected = clone:WaitForChild("Selected")
		avatar.Image = `rbxthumb://type=AvatarHeadShot&id={v22.UserId}&w=150&h=150`
		name.Text = v22.DisplayName
		bomb.Visible = v22.Team == "Terrorists"

		local function setToggleModeVisual(visible: boolean) -- 1 equivalent call inferred from this helper
			selected.Visible = visible
			state.Text = visible and "ON" or "OFF"
			local v23 = state
			local textColor

			if visible then
				textColor = color3
			else
				textColor = color2
			end

			v23.TextColor3 = textColor
		end

		if v21 then
			local playerToggleEnabled = isPlayerToggleEnabled(v21.Key, v22.UserId) -- inferred equivalent call
			selected.Visible = playerToggleEnabled
			state.Text = playerToggleEnabled and "ON" or "OFF"
			local textColor

			if playerToggleEnabled then
				textColor = color3
			else
				textColor = color2
			end

			state.TextColor3 = textColor
		else
			selected.Visible = false
			state.Text = "KICK"
			state.TextColor3 = color7
		end

		bindButtonHover(v17, clone) -- inferred equivalent call
		local v23 = v22
		bindPress(v17, clone, function()
			playClick() -- inferred equivalent call

			if v21 then
				local visible = not isPlayerToggleEnabled(v21.Key, v23.UserId) -- inferred equivalent call
				local v24 = setLocalTogglePlayer(v21.Key, v23.UserId, visible) -- inferred equivalent call
				setToggleModeVisual(visible) -- inferred equivalent call
				Remotes.VIP.SetSetting.Send({ Key = v21.Key, Value = v24 })
			else
				selected.Visible = true
				Remotes.VIP.ExecuteAction.Send({ Action = "KickPlayer", Params = v23.UserId })
				hidePlayers(true) -- inferred equivalent call
			end
		end)
		clone.Parent = container
	end
end

local function renderSettings()
	maid2:Cleanup()
	clearGenerated(scrollingFrame, toggleTemplate, {
		InputTemplate = true,
		ClickTemplate = true,
		SectionTemplate = true
	})
	inputTemplate.Visible = false
	clickTemplate.Visible = false
	sectionTemplate.Visible = false
	table.clear(v13)
	local count = 0

	local function createSection(name: string, text: string, p: number)
		count += 1
		local v21 = math.ceil(p / 2)
		local v22 = v21 * 0.115 + (v21 - 1) * 0.022
		local v23 = v22 + 0.07
		local clone = sectionTemplate:Clone()
		clone.Name = name
		clone.LayoutOrder = count
		clone.Size = UDim2.fromScale(1, v23)
		clone.Visible = true
		local label = clone:WaitForChild("Label")
		label.Text = text
		label.Size = UDim2.fromScale(1, 0.035 / v23)
		local grid = clone:WaitForChild("Grid")
		grid.Position = UDim2.fromScale(0, 0.07 / v23)
		grid.Size = UDim2.fromScale(1, v22 / v23)
		local uiGridLayout = grid:FindFirstChildOfClass("UIGridLayout")
		uiGridLayout.CellSize = UDim2.fromScale(0.492, 0.115 / v22)
		uiGridLayout.CellPadding = UDim2.fromScale(0.016, 0.022 / v22)
		clone.Parent = scrollingFrame
		return grid
	end

	local function createRow(instance, parent, name: string, text: string) -- 3 equivalent calls inferred from this helper
		local clone = instance:Clone()
		clone.Name = name
		clone.LayoutOrder = #parent:GetChildren()
		clone.Visible = true
		local label = clone:WaitForChild("Left"):WaitForChild("Label")
		label.Text = text
		clone.Parent = parent
		return clone
	end

	local function createSelector(parent, name: string, text: string, fn, fn2, callback)
		local row = createRow(toggleTemplate, parent, name, text) -- inferred equivalent call
		local switch = row:WaitForChild("Right"):WaitForChild("Switch")
		local selection = switch:WaitForChild("Selection")
		local v21 = {
			Row = row,
			Title = selection:WaitForChild("Title"),
			Bar = selection:WaitForChild("Frame"),
			Decrease = switch:WaitForChild("Left"),
			Increase = switch:WaitForChild("Right")
		}
		switch.AutoButtonColor = false
		bindButtonHover(maid2, switch) -- inferred equivalent call

		local function step(instance, callback2) -- 2 equivalent calls inferred from this helper
			bindPress(maid2, instance, function()
				if instance:GetAttribute("Enabled") ~= false then
					playClick() -- inferred equivalent call
					callback2()
				end
			end)
		end

		step(v21.Decrease, fn) -- inferred equivalent call
		step(v21.Increase, fn2) -- inferred equivalent call

		if callback then
			local v22 = false

			local function markArrow()
				v22 = true
				task.defer(function()
					v22 = false
				end)
			end

			maid2:Add(v21.Decrease.MouseButton1Down:Connect(markArrow))
			maid2:Add(v21.Increase.MouseButton1Down:Connect(markArrow))
			bindPress(maid2, switch, function()
				if not v22 then
					playClick() -- inferred equivalent call
					callback()
				end
			end)
		end

		v13[name] = v21
		return v21
	end

	local function createToggle(section, name: string, text: string, callback, fn)
		local v21 = nil

		local function set(flag2: boolean) -- 1 equivalent call inferred from this helper
			if flag2 == callback() then
				return
			end

			fn(flag2)
			setToggleSelector(v21, flag2)
		end

		v21 = createSelector(section, name, text, function()
			if callback() == false then
				return
			end

			fn(false)
			setToggleSelector(v21, false)
		end, function()
			if callback() == true then
				return
			end

			fn(true)
			setToggleSelector(v21, true)
		end, function()
			set(not callback()) -- inferred equivalent call
		end)
		setToggleSelector(v21, callback())
	end

	local section = createSection("MatchRules", "MATCH RULES", #v + 1)

	for _, v21 in ipairs(v) do
		local v22 = v21
		local v23 = v21
		createToggle(section, v21.Name, v21.Label, function()
			return v7[v22.Key] == true
		end, function(p)
			v7[v23.Key] = p
			Remotes.VIP.SetSetting.Send({ Key = v23.Key, Value = p })
		end)
	end

	local textBox = createRow(inputTemplate, section, "SetTimer", "Set Timer"):FindFirstChildWhichIsA("TextBox", true) -- inferred equivalent call
	textBox.Text = ""
	maid2:Add(textBox.FocusLost:Connect(function()
		local text = tonumber(textBox.Text)

		if not text then
			textBox.Text = ""
			return
		end

		Remotes.VIP.ExecuteAction.Send({
			Action = "SetTimer",
			Params = math.clamp(math.floor(text), 0, 9999)
		})
		textBox.Text = ""
	end))
	local section2 = createSection("Bots", "BOTS", 5)

	local function changeBotCount(p, p2: number)
		local v21 = getBotCount(p.Key) + p2 -- inferred equivalent call

		if not (v21 < 0) and not (v21 + getBotCount(p.OtherKey) > 14) then -- inferred equivalent call
			v7[p.Key] = v21
			v7.BotAutoFill = false
			refreshBotControls()
			Remotes.VIP.SetSetting.Send({ Key = p.Key, Value = v21 })
		end
	end

	for _, v21 in ipairs(v4) do
		local v22 = v21
		local v23 = v21
		createSelector(section2, v21.Name, v21.Label, function()
			changeBotCount(v22, -1)
		end, function()
			changeBotCount(v23, 1)
		end)
	end

	local function shiftBotDifficulty(p: number)
		local index = table.find(v2, getBotDifficulty()) -- inferred equivalent call
		local botDifficulty = v2[math.clamp(index + p, 1, #v2)]
		v7.BotDifficulty = botDifficulty
		refreshBotControls()
		Remotes.VIP.SetSetting.Send({ Key = "BotDifficulty", Value = botDifficulty })
	end

	createSelector(section2, "BotDifficulty", "Bot Difficulty", function()
		shiftBotDifficulty(-1)
	end, function()
		shiftBotDifficulty(1)
	end)
	createToggle(section2, "BotAutoFill", "Auto Fill Bots", isBotAutoFill, function(botAutoFill)
		v7.BotAutoFill = botAutoFill
		refreshBotControls()
		Remotes.VIP.SetSetting.Send({ Key = "BotAutoFill", Value = botAutoFill })
	end)
	createToggle(section2, "BotsFrozen", "Freeze Bots", areBotsFrozen, function(botsFrozen)
		v7.BotsFrozen = botsFrozen
		Remotes.VIP.SetSetting.Send({ Key = "BotsFrozen", Value = botsFrozen })
	end)

	local function openPlayers(p: string) -- 3 equivalent calls inferred from this helper
		v12 = p

		if v6[p] then
			Remotes.VIP.RequestData.Send("State")
		end

		Remotes.VIP.RequestData.Send("PlayerList")
		renderPlayers()
		showPlayers() -- inferred equivalent call
	end

	local v21 = {
		{
			Name = "GodMode",
			Label = "God Mode",
			Button = "PLAYERS",
			Callback = function()
				openPlayers("GodMode") -- inferred equivalent call
			end
		},
		{
			Name = "ESP",
			Label = "ESP",
			Button = "PLAYERS",
			Callback = function()
				openPlayers("ESP") -- inferred equivalent call
			end
		},
		{
			Name = "KickPlayer",
			Label = "Kick Player",
			Button = "PLAYERS",
			Callback = function()
				openPlayers("KickPlayer") -- inferred equivalent call
			end
		},
		{
			Name = "ResetScore",
			Label = "Reset Score",
			Button = "RESET",
			Callback = function()
				Remotes.VIP.ExecuteAction.Send({ Action = "ResetScore", Params = nil })
			end
		},
		{
			Name = "EndGame",
			Label = "End Current Game",
			Button = "END GAME",
			Danger = true,
			Callback = function()
				Remotes.VIP.ExecuteAction.Send({ Action = "EndGame", Params = nil })
			end
		}
	}
	local section3 = createSection("Actions", "SERVER ACTIONS", #v21)

	for _, v22 in ipairs(v21) do
		local action = createRow(clickTemplate, section3, v22.Name, v22.Label):FindFirstChild("Action", true) -- inferred equivalent call
		local title = action:WaitForChild("Title")
		title.Text = v22.Button

		if v22.Danger then
			action.BackgroundColor3 = color6
		end

		bindButtonHover(maid2, action) -- inferred equivalent call
		local v23 = v22
		bindPress(maid2, action, function()
			playClick() -- inferred equivalent call
			v23.Callback()
		end)
	end

	refreshBotControls()
end

local function setupTabs()
	for k, v21 in pairs(v20) do
		bindButtonHover(maid, v21) -- inferred equivalent call
		local v22 = k
		bindPress(maid, v21, function()
			if v11 == v22 then
				return
			end

			playClick() -- inferred equivalent call

			if v22 == "MapSelect" then
				serverGamemode = nil
				refreshMaps()
			elseif v22 == "ModeSelect" then
				refreshModeCards()
			else
				updateToggleIndicators()
			end

			showPanel(v22, true)
		end)
	end
end

local function setupCloseButtons()
	local close = voteKick:WaitForChild("Header"):FindFirstChild("Close")

	if close and close:IsA("GuiButton") then
		bindButtonHover(maid, close) -- inferred equivalent call
		bindPress(maid, close, function()
			playClick() -- inferred equivalent call
			voteKick.Visible = false
			updateRootPosition(true)
		end)
	end

	local close2 = v18:WaitForChild("Close")

	if close2 and close2:IsA("GuiButton") then
		bindButtonHover(maid, close2) -- inferred equivalent call
		bindPress(maid, close2, function()
			playClick() -- inferred equivalent call
			VIPMenu.closeFrame()
		end)
	end

	CloseButtonRegistry.Add(v18, nil, function()
		if not voteKick.Visible then
			VIPMenu.closeFrame()
			return
		end

		hidePlayers(true) -- inferred equivalent call
	end)
end

function VIPMenu.openFrame()
	if
		canUseVIPMenu() -- inferred equivalent call
		and v18
		and not (EndScreenController.IsActive() or MenuState.IsInspectActive() or MenuState.IsCaseSceneActive())
		and isInGameplayContext() -- inferred equivalent call
	then
		local mainGuiFromRoot = getMainGuiFromRoot() -- inferred equivalent call
		local visible

		if mainGuiFromRoot then
			local menu = mainGuiFromRoot:FindFirstChild("Menu")

			if menu == nil then
				visible = false
			else
				visible = menu:IsA("GuiObject") and menu.Visible
			end
		else
			visible = false
		end

		if not (visible or isTeamSelectionVisible() or flag) then
			CameraController.setForceLockOverride("VIPMenu", true)

			if LocalPlayer:GetAttribute("IsSpectating") ~= true and hasActiveCharacter() then -- inferred equivalent call
				CameraController.setPerspective(true, true)
			end

			if v14 then
				v14:Cancel()
				v14 = nil
			end

			flag = true
			v18.Visible = true
			hidePlayers(false) -- inferred equivalent call
			showPanel(v11, true)
			v19.Scale = 0.94
			TweenService:Create(v19, tweenInfo2, { Scale = 1 }):Play()

			if backdrop then
				backdrop.BackgroundTransparency = 1
				TweenService:Create(backdrop, tweenInfo2, {
					BackgroundTransparency = backgroundTransparency
				}):Play()
			end

			Remotes.VIP.RequestData.Send("State")
			Remotes.VIP.RequestData.Send("PlayerList")
			refreshMaps()
			refreshModeCards()
		end
	end
end

function VIPMenu.closeFrame()
	if not v18 then
		return
	end

	CameraController.setForceLockOverride("VIPMenu", false)

	if LocalPlayer:GetAttribute("IsSpectating") ~= true and hasActiveCharacter() then -- inferred equivalent call
		CameraController.setPerspective(true, false)
	end

	if not flag then
		return
	end

	flag = false
	local tween2 = TweenService:Create(v19, tweenInfo3, { Scale = 0.94 })
	tween2:Play()

	if backdrop then
		TweenService:Create(backdrop, tweenInfo3, { BackgroundTransparency = 1 }):Play()
	end

	v14 = tween2
	tween2.Completed:Connect(function(p)
		if p == Enum.PlaybackState.Completed and v14 == tween2 then
			v14 = nil
			v18.Visible = false
		end
	end)
end

function VIPMenu.toggleFrame()
	if not v18 then
		return
	end

	if flag then
		VIPMenu.closeFrame()
	else
		VIPMenu.openFrame()
	end
end

function VIPMenu.Initialize(_, instance)
	v18 = instance
	v19 = getScale(instance) -- inferred equivalent call
	backdrop = instance:FindFirstChild("Backdrop")

	if backdrop then
		backgroundTransparency = backdrop.BackgroundTransparency
	end

	local frame = instance:WaitForChild("Frame")
	v20 = {
		Settings = frame:WaitForChild("Settings"),
		MapSelect = frame:WaitForChild("MapSelect"),
		ModeSelect = frame:WaitForChild("ModeSelect")
	}
	scrollingFrame = instance:WaitForChild("ScrollingFrame")
	selectMap = instance:WaitForChild("SelectMap")
	selectMode = instance:WaitForChild("SelectMode")
	voteKick = instance:WaitForChild("VoteKick")
	container = voteKick:WaitForChild("Container")
	title = voteKick:WaitForChild("Header"):WaitForChild("Title")
	sectionTemplate = scrollingFrame:WaitForChild("SectionTemplate")
	toggleTemplate = scrollingFrame:WaitForChild("ToggleTemplate")
	inputTemplate = scrollingFrame:WaitForChild("InputTemplate")
	clickTemplate = scrollingFrame:WaitForChild("ClickTemplate")
	template = selectMap:WaitForChild("Template")
	template2 = selectMode:WaitForChild("Template")
	template3 = container:WaitForChild("Template")
	loadAvailableMaps()
	v18.Visible = false
	voteKick.Visible = false
	v11 = "Settings"
	scrollingFrame.Visible = true
	selectMap.Visible = false
	selectMode.Visible = false

	for k, v21 in pairs(v20) do
		setTabVisual(v21, k == "Settings") -- inferred equivalent call
	end

	renderSettings()
	buildModeCards()
	buildMapEntries()
	maid:Add(v18:GetPropertyChangedSignal("Visible"):Connect(function()
		if v18.Visible then
			return
		end

		flag = false
		CameraController.setForceLockOverride("VIPMenu", false)
	end))

	local function applyState(data2) -- 1 equivalent call inferred from this helper
		v7 = data2

		if not v18.Visible then
			return
		end

		updateToggleIndicators()
		refreshMaps()
		refreshModeCards()

		if voteKick.Visible then
			renderPlayers()
		end
	end

	maid:Add(Remotes.VIP.SyncState.Listen(applyState))
	maid:Add(Remotes.VIP.DataResponse.Listen(function(p)
		if p.Type == "State" then
			applyState(p.Data) -- inferred equivalent call
		elseif p.Type == "PlayerList" then
			data = p.Data

			if v18.Visible and voteKick.Visible then
				renderPlayers()
			end
		end
	end))
end

function VIPMenu.Start()
	setupTabs()
	setupCloseButtons()
	updateToggleIndicators()
end

return VIPMenu