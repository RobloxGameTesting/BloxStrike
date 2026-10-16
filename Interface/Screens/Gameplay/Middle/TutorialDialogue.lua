local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Tutorial = require(ReplicatedStorage.Database.Audio.Tutorial)
local Tips = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Tips)
local Router = require(ReplicatedStorage.Database.Security.Router)
local v = nil
local v2 = nil
local v3 = nil
local v4 = "Hidden"
local v5 = nil
local v6 = nil
local v7 = nil
local v8 = nil
local Left = Enum.TextXAlignment.Left
local color = Color3.fromRGB(238, 238, 238)
local tweens = {}
local v9 = false
local flag = false
local count = 0
local count2 = 0
local count3 = 0
local count4 = 0
local v10 = nil
local v11 = nil
local v12 = false
local count5 = 0
local v13 = false
local v14 = 0
local v15 = 0
local v16 = 0
local v17 = {}
local v18 = nil
local v19 = nil
local v20 = nil
local v21 = nil
local v22 = false
local udim = UDim2.fromScale(0.5, 0.85)
local udim2 = UDim2.fromScale(0, 0.03)
local color2 = Color3.fromRGB(255, 200, 70)
local v23 = nil

local function isDialogueName(name: string) -- 1 equivalent call inferred from this helper
	return name == "TutorialDialogue"
end

local function findMiddle(instance) -- 7 equivalent calls inferred from this helper
	local gameplay = instance and instance:FindFirstChild("Gameplay")

	if gameplay then
		return (gameplay:FindFirstChild("Middle"))
	end

	return nil
end

local function findDialogueFrame(guiObject)
	if guiObject and guiObject:IsA("GuiObject") and isDialogueName(guiObject.Name) then -- inferred equivalent call
		return guiObject
	end

	local middle = findMiddle(v) -- inferred equivalent call

	if middle then
		local tutorialDialogue = middle:FindFirstChild("TutorialDialogue")

		if tutorialDialogue and tutorialDialogue:IsA("GuiObject") then
			return tutorialDialogue
		end

		if guiObject and guiObject:IsA("GuiObject") then
			return guiObject
		end

		return nil
	elseif guiObject and guiObject:IsA("GuiObject") then
		return guiObject
	else
		return nil
	end
end

local function findTextLabel(dialogueFrame) -- 1 equivalent call inferred from this helper
	local objective = dialogueFrame:FindFirstChild("Objective")

	if not objective then
		return nil
	end

	if objective:IsA("TextLabel") then
		return objective
	end

	if objective:IsA("GuiObject") then
		return objective:FindFirstChildWhichIsA("TextLabel", true)
	end

	return nil
end

local function findTabLabel(dialogueFrame)
	for _, frame in dialogueFrame:GetChildren() do
		if not (frame:IsA("Frame") and frame.Name ~= "Main") then
			continue
		end

		local textLabel = frame:FindFirstChildWhichIsA("TextLabel")

		if textLabel then
			return textLabel
		end
	end

	return nil
end

local function bindDialogue(p)
	local dialogueFrame = findDialogueFrame(p)

	if not dialogueFrame then
		return false
	end

	if v2 == dialogueFrame then
		return v3 ~= nil
	end

	v2 = dialogueFrame
	v3 = findTextLabel(dialogueFrame) -- inferred equivalent call
	v5 = findTabLabel(dialogueFrame)

	for _, image in dialogueFrame:GetChildren() do
		if image:IsA("ImageLabel") then
			image:Destroy()
		end
	end

	local v24 = v3

	if v24 then
		Left = v24.TextXAlignment
		color = v24.TextColor3
	end

	local tutorialSkipHint = dialogueFrame:FindFirstChild("TutorialSkipHint")

	if tutorialSkipHint then
		tutorialSkipHint:Destroy()
	end

	local frame = Instance.new("Frame")
	frame.Name = "TutorialSkipHint"
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.Position = UDim2.new(1, 0, 0, -3)
	frame.Size = UDim2.fromScale(0.5, 0.3)
	frame.BackgroundTransparency = 1
	frame.Visible = false
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.FillDirection = Enum.FillDirection.Horizontal
	uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	uiListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	uiListLayout.Padding = UDim.new(0, 6)
	uiListLayout.Parent = frame
	local middle = findMiddle(v) -- inferred equivalent call
	local tips = middle and middle:FindFirstChild("Tips")
	local tipsFrame = tips and tips:FindFirstChildWhichIsA("Frame")
	local keybind = tipsFrame and tipsFrame:FindFirstChild("Keybind")
	local title = tipsFrame and tipsFrame:FindFirstChild("Title")
	local parent

	if keybind and keybind:IsA("ImageButton") then
		parent = keybind:Clone()
	else
		parent = Instance.new("ImageButton")
		parent.AutoButtonColor = false
		parent.Image = ""
		parent.BackgroundColor3 = Color3.new(1, 1, 1)
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(0.15, 0)
		uiCorner.Parent = parent
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Bind"
		textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		textLabel.Position = UDim2.fromScale(0.5, 0.5)
		textLabel.Size = UDim2.fromScale(0.9, 0.7)
		textLabel.BackgroundTransparency = 1
		textLabel.TextScaled = true
		textLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.ExtraBold)
		textLabel.TextColor3 = Color3.new(0, 0, 0)
		textLabel.Parent = parent
		local imageLabel = Instance.new("ImageLabel")
		imageLabel.Name = "Bind"
		imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		imageLabel.Position = UDim2.fromScale(0.5, 0.5)
		imageLabel.Size = UDim2.fromScale(0.9, 0.7)
		imageLabel.BackgroundTransparency = 1
		imageLabel.ScaleType = Enum.ScaleType.Fit
		imageLabel.Visible = false
		imageLabel.Parent = parent
	end

	parent.Name = "Keybind"
	parent.Active = false
	parent.AnchorPoint = Vector2.zero
	parent.Position = UDim2.new()
	parent.Size = UDim2.fromScale(1, 1)
	parent.SizeConstraint = Enum.SizeConstraint.RelativeYY
	parent.LayoutOrder = 1
	parent.Visible = true
	parent.Parent = frame
	local v25

	if title and title:IsA("TextLabel") then
		v25 = title:Clone()
	else
		v25 = Instance.new("TextLabel")
		v25.BackgroundTransparency = 1
		v25.TextColor3 = Color3.new(1, 1, 1)
		v25.TextStrokeTransparency = 0.4
		v25.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
	end

	v25.Name = "Label"
	v25.AnchorPoint = Vector2.zero
	v25.Position = UDim2.new()
	v25.AutomaticSize = Enum.AutomaticSize.X
	v25.Size = UDim2.fromScale(0, 1)
	v25.TextScaled = false
	v25.TextSize = 18
	v25.TextXAlignment = Enum.TextXAlignment.Left
	v25.LayoutOrder = 2
	v25.Parent = frame
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		v25.TextSize = math.max(math.floor(frame.AbsoluteSize.Y * 0.72), 8)
	end)
	frame.Parent = dialogueFrame
	v6 = frame
	v7 = parent
	v8 = v25
	return v3 ~= nil
end

local v24 = false
local fn

local function onSkipAction(_: string, p)
	if p == Enum.UserInputState.Begin then
		fn()
	end

	return Enum.ContextActionResult.Sink
end

local function refreshSkipHint()
	local v25 = v7
	local v26 = v8

	if not (v25 and v26) then
		return
	end

	local v27 = UserInputService.PreferredInput == Enum.PreferredInput.Touch
	local v28

	if Tips.IsGamepadPreferred() then
		v28 = Enum.KeyCode.DPadUp
	else
		v28 = Enum.KeyCode.E
	end

	v25.Visible = not v27 and Tips.ApplyBindingToKeybind(v25, v28)
	v26.Text = v27 and "Tap here to skip" or "Skip"
end

local function updateSkipHint()
	local v25 = v6

	if not v25 then
		return
	end

	local visible

	if v4 == "Commander" then
		visible = v13 and LocalPlayer:GetAttribute("TutorialStep") ~= "DefuseB"
	else
		visible = false
	end

	v25.Visible = visible

	if visible then
		refreshSkipHint()
	end

	if visible and not v24 then
		v24 = true
		ContextActionService:BindActionAtPriority(
			"TutorialSkipDialogue",
			onSkipAction,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.E,
			Enum.KeyCode.DPadUp
		)
	elseif not visible and v24 then
		v24 = false
		ContextActionService:UnbindAction("TutorialSkipDialogue")
	end
end

local function setMode(p: string) -- 3 equivalent calls inferred from this helper
	v4 = p

	for _, v25 in tweens do
		v25:Cancel()
	end

	table.clear(tweens)

	if p == "Hidden" then
		updateSkipHint()
		return
	end

	local v25 = p == "Objective"

	if v5 then
		v5.Text = v25 and "OBJECTIVE" or "COMMANDER"
	end

	local v26 = v3

	if v26 then
		local textXAlignment

		if v25 then
			textXAlignment = Enum.TextXAlignment.Center
		else
			textXAlignment = Left
		end

		v26.TextXAlignment = textXAlignment
		v26.TextColor3 = color
	end

	updateSkipHint()
end

local function stopDialogueAudio() -- 3 equivalent calls inferred from this helper
	local v25 = v20
	v20 = nil

	if v25 then
		v25:Stop()
		v25:Destroy()
	end
end

local function createVoiceSound(soundId: string, playbackRegion: NumberRange?)
	local sound = Instance.new("Sound")
	sound.Name = "TutorialDialogueVoice"
	sound.SoundId = soundId
	sound.Volume = (tonumber(DataController.Get(LocalPlayer, "Settings.Audio.Audio.Master Volume")) or 100) / 100
	sound.Looped = false
	local gameplay = SoundService:FindFirstChild("Gameplay")

	if gameplay and gameplay:IsA("SoundGroup") then
		sound.SoundGroup = gameplay
	end

	if playbackRegion then
		sound.PlaybackRegionsEnabled = true
		sound.PlaybackRegion = playbackRegion
	end

	sound.Parent = SoundService
	return sound
end

local function isTrailingOff(data)
	local timeLength = data.TimeLength

	if timeLength <= 0 then
		return false
	end

	if data.PlaybackRegionsEnabled then
		timeLength = math.min(data.PlaybackRegion.Max, timeLength)
	end

	return timeLength - data.TimePosition <= 0.8 and data.PlaybackLoudness <= 6
end

local flag2 = false

local function preloadVoices()
	if flag2 then
		return
	end

	flag2 = true
	local folder = Instance.new("Folder")
	folder.Name = "TutorialVoicePreload"
	local v25 = {}
	local v26 = {}

	for _, v27 in Tutorial do
		local audioId

		if typeof(v27) == "table" then
			audioId = v27.audioId
		end

		if typeof(audioId) ~= "string" or v25[audioId] then
			continue
		end

		v25[audioId] = true
		local sound = Instance.new("Sound")
		sound.SoundId = audioId
		sound.Parent = folder
		table.insert(v26, sound)
	end

	folder.Parent = SoundService
	task.spawn(function()
		pcall(ContentProvider.PreloadAsync, ContentProvider, v26)
	end)
end

local function waitForVoiceSound(voiceSound)
	local v25 = os.clock() + 2

	while not voiceSound.IsLoaded and os.clock() < v25 do
		task.wait(0.05)
	end
end

local function resolveCommanderLine(p: string)
	local v25 = Tutorial[p]

	if typeof(v25) ~= "table" or typeof(v25.text) ~= "string" then
		return { p }, nil, nil
	end

	local audioId = v25.audioId

	if typeof(audioId) ~= "string" then
		audioId = nil
	end

	local region = v25.region
	local numberRange

	if typeof(region) == "table" then
		numberRange = NumberRange.new(region[1], region[2])
	end

	local pages = v25.pages

	if typeof(pages) == "table" and #pages > 0 then
		return table.clone(pages), audioId, numberRange
	end

	return { v25.text }, audioId, numberRange
end

local function reportCommanderIdle() -- 2 equivalent calls inferred from this helper
	if v14 <= v15 then
		return
	end

	v15 = v14
	Remotes.Tutorial.ClientEvent.Send(`CommanderIdle:{v14}`)
end

local function isMenuOpen() -- 1 equivalent call inferred from this helper
	local menu = v and v:FindFirstChild("Menu")
	return menu ~= nil and menu:IsA("GuiObject") and menu.Visible
end

local function isGameplayVisible() -- 1 equivalent call inferred from this helper
	local gameplay = v and v:FindFirstChild("Gameplay")
	return gameplay ~= nil and gameplay:IsA("GuiObject") and gameplay.Visible
end

local function hasPlayingTeam() -- 1 equivalent call inferred from this helper
	local team = LocalPlayer:GetAttribute("Team")
	return team == "Terrorists" or team == "Counter-Terrorists"
end

local function shouldShowDialogue()
	if not IsTutorialMode() or workspace:GetAttribute("TutorialActive") ~= true or isMenuOpen() then -- inferred equivalent call
		return false
	end

	if not isGameplayVisible() then -- inferred equivalent call
		return false
	end

	local state = GameState.GetState()

	if state == "Game Ending" or state == "Map Voting" then
		return false
	end

	return hasPlayingTeam() -- inferred equivalent call
end

local function liftNotifications(flag3: boolean)
	local middle = findMiddle(v) -- inferred equivalent call
	local notification = middle and middle:FindFirstChild("Notification")

	if not (notification and notification:IsA("GuiObject")) then
		return
	end

	local position = v23 or notification.Position
	v23 = position
	notification.Position = position
	local v25 = v2

	if not (flag3 and v25) then
		return
	end

	local y = v25.AbsolutePosition.Y
	local parent = v5 and v5.Parent

	if parent and parent:IsA("GuiObject") then
		y = math.min(y, parent.AbsolutePosition.Y)
	end

	local v26 = notification.AbsolutePosition.Y + notification.AbsoluteSize.Y + 6 - y

	if v26 > 0 then
		notification.Position = position - UDim2.fromOffset(0, v26)
	end
end

local function hideBox() -- 6 equivalent calls inferred from this helper
	setMode("Hidden") -- inferred equivalent call

	if v2 then
		v2.Visible = false
	end

	local middle = findMiddle(v) -- inferred equivalent call
	local notification = middle and middle:FindFirstChild("Notification")

	if notification then
		if not notification:IsA("GuiObject") then
			return
		end

		local position = v23 or notification.Position
		v23 = position
		notification.Position = position
	end
end

local function clearObjective() -- 1 equivalent call inferred from this helper
	count4 += 1
	count5 += 1
	v12 = false
	v10 = nil
	v11 = nil

	if v4 == "Objective" then
		hideBox() -- inferred equivalent call
	end
end

local function hideDialogue()
	count3 += 1

	if v13 or #v17 > 0 then
		local v25 = {}

		if v18 then
			table.insert(v25, v18)
		end

		table.move(v17, 1, #v17, #v25 + 1, v25)

		if #v25 > 0 then
			v19 = v25
		end
	end

	stopDialogueAudio() -- inferred equivalent call
	v18 = nil
	v13 = false
	v9 = false
	flag = false
	count += 1
	table.clear(v17)
	count4 += 1
	count5 += 1
	v12 = false
	v10 = nil
	v11 = nil

	if v4 == "Objective" then
		setMode("Hidden") -- inferred equivalent call

		if v2 then
			v2.Visible = false
		end

		local middle = findMiddle(v) -- inferred equivalent call
		local notification = middle and middle:FindFirstChild("Notification")

		if notification and notification:IsA("GuiObject") then
			local position = v23 or notification.Position
			v23 = position
			notification.Position = position
		end
	end

	hideBox() -- inferred equivalent call
end

local function findBuyMenu() -- 2 equivalent calls inferred from this helper
	local middle = findMiddle(v) -- inferred equivalent call
	local buyMenu = middle and middle:FindFirstChild("BuyMenu")

	if buyMenu and buyMenu:IsA("GuiObject") then
		return buyMenu
	end

	return nil
end

local function restPosition() -- 2 equivalent calls inferred from this helper
	local buyMenu = findBuyMenu() -- inferred equivalent call

	if buyMenu and buyMenu.Visible then
		return udim + udim2
	end

	return udim
end

local function showDialogue() -- 3 equivalent calls inferred from this helper
	if not shouldShowDialogue() then
		hideDialogue()
	elseif v2 then
		v2.Position = restPosition() -- inferred equivalent call
		v2.Visible = true
		liftNotifications(true)
	end
end

local TutorialDialogue = {
	IsDialogueName = isDialogueName,
	IsActive = function()
		return v13
	end
}

local function utf8Len(list: string)
	local success, result = pcall(utf8.len, list)

	if success and typeof(result) == "number" then
		return result
	end

	return #list
end

local fn2
local fn3
local fn4

local function returnToObjective()
	if v12 or flag then
		return
	end

	if v10 and shouldShowDialogue() then
		fn3(false)
		return
	end

	hideBox() -- inferred equivalent call
end

local function finishCommander(p: number)
	v18 = nil
	v13 = false
	updateSkipHint()
	reportCommanderIdle() -- inferred equivalent call
	local tutorialCommanderId = LocalPlayer:GetAttribute("TutorialCommanderId")

	if v12 and (typeof(tutorialCommanderId) ~= "number" or tutorialCommanderId == v14) then
		fn4()
		return
	end

	v9 = true
	count2 += 1
	local v25 = count2
	task.wait(0.25)

	if v25 == count2 then
		v9 = false
	end

	if p == count3 and not (v13 or v12) then
		if flag then
			return
		end

		if v10 and shouldShowDialogue() then
			fn3(false)
			return
		end

		hideBox() -- inferred equivalent call
	end
end

local function playTypewriter(text: string, commanderLine)
	if not bindDialogue(v2) then
		return
	end

	local v25 = v3

	if not (v2 and v25) then
		return
	end

	count3 += 1
	local v26 = count3
	v13 = true
	v9 = false
	flag = false
	count += 1
	count4 += 1
	setMode("Commander")
	showDialogue() -- inferred equivalent call
	v25.Text = text
	v25.MaxVisibleGraphemes = 0
	local success, result = pcall(utf8.len, text)

	for i = 1, (not success or typeof(result) ~= "number") and #text or result do
		if v26 ~= count3 then
			return
		end

		v25.MaxVisibleGraphemes = i
		task.wait(0.035)
	end

	if v26 ~= count3 then
		return
	end

	v25.MaxVisibleGraphemes = -1

	if commanderLine and #commanderLine > 0 then
		local v27 = table.remove(commanderLine, 1)
		task.wait(1.25)

		if v26 ~= count3 or typeof(v27) ~= "string" then
			return
		end

		playTypewriter(v27, commanderLine)
	else
		local v27 = nil

		while v26 == count3 do
			local v28 = v20

			if not (v28 and v28.IsPlaying) then
				break
			end

			local timeLength = v28.TimeLength
			local v29

			if timeLength <= 0 then
				v29 = false
			else
				if v28.PlaybackRegionsEnabled then
					timeLength = math.min(v28.PlaybackRegion.Max, timeLength)
				end

				if timeLength - v28.TimePosition <= 0.8 then
					v29 = v28.PlaybackLoudness <= 6
				else
					v29 = false
				end
			end

			if v29 then
				v27 = v27 or os.clock()

				if os.clock() - v27 >= 0.2 then
					break
				end
			else
				v27 = nil
			end

			task.wait(0.03)
		end

		if v26 ~= count3 then
			return
		end

		if #v17 > 0 then
			fn2()
		else
			finishCommander(v26)
		end
	end
end

fn2 = function()
	local v25 = table.remove(v17, 1)

	if typeof(v25) ~= "string" or v25 == "" then
		return
	end

	v18 = v25
	local commanderLine, soundId, playbackRegion = resolveCommanderLine(v25)
	local v26 = table.remove(commanderLine, 1)

	if typeof(v26) ~= "string" then
		return
	end

	count3 += 1
	local v27 = count3
	v13 = true
	stopDialogueAudio() -- inferred equivalent call

	if v21 and not v22 then
		v21:Stop()
	end

	local v28 = os.clock() + 6

	while v21 and v21.IsPlaying and os.clock() < v28 do
		task.wait(0.05)
	end

	if v27 ~= count3 then
		return
	end

	if typeof(soundId) ~= "string" or soundId == "" then
		playTypewriter(v26, commanderLine)
		return
	end

	local voiceSound = createVoiceSound(soundId, playbackRegion)
	waitForVoiceSound(voiceSound)

	if v27 ~= count3 then
		voiceSound:Destroy()
		return
	end

	v20 = voiceSound
	voiceSound:Play()
	voiceSound.Ended:Once(function()
		if v20 == voiceSound then
			v20 = nil
			voiceSound:Destroy()
		end
	end)
	playTypewriter(v26, commanderLine)
end

fn = function()
	if not (v13 and shouldShowDialogue()) then
		return
	end

	stopDialogueAudio() -- inferred equivalent call
	count3 += 1

	if #v17 > 0 then
		task.spawn(fn2)
		return
	end

	v18 = nil
	v13 = false
	v9 = false
	reportCommanderIdle() -- inferred equivalent call

	if not v12 then
		if flag then
			return
		end

		if v10 and shouldShowDialogue() then
			fn3(false)
			return
		end

		hideBox() -- inferred equivalent call
	end
end

local function flashObjective()
	local v25 = v3

	if not v25 then
		return
	end

	local tweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	v25.TextColor3 = color2
	local tween = TweenService:Create(v25, tweenInfo, { TextColor3 = color })
	table.insert(tweens, tween)
	tween:Play()
end

local function typeObjective(text: string)
	local v25 = v3

	if not v25 then
		return
	end

	count4 += 1
	local v26 = count4
	v25.Text = text
	v25.MaxVisibleGraphemes = 0
	flashObjective()
	local success, result = pcall(utf8.len, text)

	for i = 1, (not success or typeof(result) ~= "number") and #text or result do
		if v26 ~= count4 or v4 ~= "Objective" then
			return
		end

		v25.MaxVisibleGraphemes = i
		task.wait(0.0175)
	end

	if v26 == count4 and v4 == "Objective" then
		v25.MaxVisibleGraphemes = -1
	end
end

fn3 = function(flag3: boolean)
	local text = v10
	local v25 = v3

	if not text or not v25 or v12 or v13 or v9 or flag then
		return
	end

	if not shouldShowDialogue() then
		return
	end

	setMode("Objective")
	showDialogue() -- inferred equivalent call

	if flag3 then
		task.spawn(typeObjective, text)
		return
	end

	count4 += 1
	v25.Text = text
	v25.MaxVisibleGraphemes = -1
end

local function isCommanderBusy() -- 1 equivalent call inferred from this helper
	local tutorialCommanderId = LocalPlayer:GetAttribute("TutorialCommanderId")
	local v25 = v13 or v9 or flag

	if v25 then
		return v25
	end

	if #v17 > 0 then
		return true
	elseif typeof(tutorialCommanderId) == "number" then
		return tutorialCommanderId ~= v14
	else
		return false
	end
end

local function showTip(text: string)
	local v25 = v3

	if not v25 or v13 or not shouldShowDialogue() then
		return
	end

	count += 1
	local v26 = count
	flag = true
	count4 += 1
	setMode("Commander")
	showDialogue() -- inferred equivalent call
	v25.Text = text
	v25.MaxVisibleGraphemes = 0
	local lastTime = os.clock()
	local success, result = pcall(utf8.len, text)

	for i = 1, (not success or typeof(result) ~= "number") and #text or result do
		if v26 ~= count then
			return
		end

		v25.MaxVisibleGraphemes = i
		task.wait(0.035)
	end

	if v26 ~= count then
		return
	end

	v25.MaxVisibleGraphemes = -1
	task.wait((math.max(4 - (os.clock() - lastTime), 0)))

	if v26 == count then
		flag = false

		if not v12 then
			if flag then
				return
			end

			if v10 and shouldShowDialogue() then
				fn3(false)
				return
			end

			hideBox() -- inferred equivalent call
		end
	end
end

local function holdObjective()
	v12 = true
	count5 += 1
	local v25 = count5
	count4 += 1

	if v4 == "Objective" then
		setMode("Hidden") -- inferred equivalent call

		if v2 then
			v2.Visible = false
		end

		local middle = findMiddle(v) -- inferred equivalent call
		local notification = middle and middle:FindFirstChild("Notification")

		if notification and notification:IsA("GuiObject") then
			local position = v23 or notification.Position
			v23 = position
			notification.Position = position
		end
	end

	local lastTime = os.clock()
	task.spawn(function()
		task.wait(0.3)

		while v25 == count5 do
			if isCommanderBusy() and not (os.clock() - lastTime > 45) then -- inferred equivalent call
				task.wait(0.1)
			else
				v12 = false
				fn3(true)
				break
			end
		end
	end)
end

local function syncObjective()
	if not shouldShowDialogue() then
		hideDialogue()
		return
	end

	if not bindDialogue(v2) then
		return
	end

	local tutorialObjective = LocalPlayer:GetAttribute("TutorialObjective")
	local tutorialStep = LocalPlayer:GetAttribute("TutorialStep")

	if typeof(tutorialObjective) == "string" and tutorialObjective ~= "" then
		local v25 = typeof(tutorialStep) ~= "string" and "" or tutorialStep

		if tutorialObjective == v10 then
			if v4 == "Hidden" then
				fn3(false)
			end
		else
			local v26 = v25 ~= v11
			local v27 = v10
			local v28 = string.gsub(tutorialObjective, "%d", "") ~= string.gsub(v27 or "", "%d", "")
			v10 = tutorialObjective
			v11 = v25

			if v26 then
				holdObjective()
				return
			end

			if v12 or v4 == "Commander" then
				return
			end

			fn3(v28)
		end
	else
		clearObjective() -- inferred equivalent call
	end
end

fn4 = function()
	local tutorialObjective = LocalPlayer:GetAttribute("TutorialObjective")
	local tutorialStep = LocalPlayer:GetAttribute("TutorialStep")

	if typeof(tutorialObjective) ~= "string" or tutorialObjective == "" or v13 or #v17 > 0 or flag then
		return
	end

	v10 = tutorialObjective
	v11 = typeof(tutorialStep) ~= "string" and "" or tutorialStep
	v9 = false
	count2 += 1
	v12 = false
	count5 += 1
	fn3(true)
end

local flag3 = false
local fn5

local function scheduleCommanderRetry()
	if flag3 then
		return
	end

	local tutorialCommanderId = LocalPlayer:GetAttribute("TutorialCommanderId")

	if typeof(tutorialCommanderId) ~= "number" or tutorialCommanderId == v14 then
		return
	end

	flag3 = true
	task.spawn(function()
		local v25 = os.clock() + 30

		while os.clock() < v25 do
			task.wait(0.25)
			local tutorialCommanderId2 = LocalPlayer:GetAttribute("TutorialCommanderId")

			if typeof(tutorialCommanderId2) ~= "number" or tutorialCommanderId2 == v14 then
				break
			end

			if not shouldShowDialogue() then
				continue
			end

			flag3 = false
			fn5()
			return
		end

		flag3 = false
	end)
end

fn5 = function()
	if shouldShowDialogue() then
		local tutorialCommander = LocalPlayer:GetAttribute("TutorialCommander")
		local tutorialCommanderId = LocalPlayer:GetAttribute("TutorialCommanderId")
		local v25

		if
			typeof(tutorialCommander) == "string"
			and tutorialCommander ~= ""
			and typeof(tutorialCommanderId) == "number"
		then
			v25 = tutorialCommanderId ~= v14
		else
			v25 = false
		end

		if v25 then
			v19 = nil
			v14 = tutorialCommanderId
			table.clear(v17)

			for _, v26 in string.split(tutorialCommander, "\n") do
				if v26 ~= "" then
					table.insert(v17, v26)
				end
			end

			if not v13 then
				task.spawn(fn2)
			end
		else
			local v26 = v19

			if v26 and not v13 then
				v19 = nil
				table.move(v26, 1, #v26, #v17 + 1, v17)
				task.spawn(fn2)
			end
		end
	else
		hideDialogue()
		scheduleCommanderRetry()
	end
end

local function syncCommanderVoice()
	local tutorialCommanderVoice = LocalPlayer:GetAttribute("TutorialCommanderVoice")
	local tutorialCommanderVoiceId = LocalPlayer:GetAttribute("TutorialCommanderVoiceId")

	if
		typeof(tutorialCommanderVoice) ~= "string"
		or tutorialCommanderVoice == ""
		or (typeof(tutorialCommanderVoiceId) ~= "number" or tutorialCommanderVoiceId == v16)
	then
		return
	end

	if not shouldShowDialogue() then
		return
	end

	v16 = tutorialCommanderVoiceId
	local tutorialCommanderVoiceStep = LocalPlayer:GetAttribute("TutorialCommanderVoiceStep")
	local tutorialCommanderVoicePriority = LocalPlayer:GetAttribute("TutorialCommanderVoicePriority") == true

	if v13 or #v17 > 0 then
		if not tutorialCommanderVoicePriority then
			return
		end

		local v25 = os.clock() + 30

		while v13 or #v17 > 0 do
			if v16 ~= tutorialCommanderVoiceId or v25 <= os.clock() then
				return
			end

			task.wait(0.05)
		end

		if not shouldShowDialogue() then
			return
		end
	end

	if
		typeof(tutorialCommanderVoiceStep) == "string"
		and LocalPlayer:GetAttribute("TutorialStep") ~= tutorialCommanderVoiceStep
		or not tutorialCommanderVoicePriority and v21 and v22
	then
		return
	end

	local commanderLine, soundId, playbackRegion = resolveCommanderLine(tutorialCommanderVoice)

	if not soundId then
		return
	end

	if tutorialCommanderVoicePriority then
		local joined = table.concat(commanderLine, " ")
		local tutorialObjective = LocalPlayer:GetAttribute("TutorialObjective")

		local function bare(value: string) -- 2 equivalent calls inferred from this helper
			return (string.gsub(string.lower(value), "[^%w]", ""))
		end

		if typeof(tutorialObjective) == "string" and bare(tutorialObjective) == bare(joined) then -- inferred equivalent call
			fn4()
		else
			task.spawn(showTip, joined)
		end
	end

	local v25 = v21
	v21 = nil
	v22 = false

	if v25 then
		v25:Stop()
		v25:Destroy()
	end

	local voiceSound = createVoiceSound(soundId, playbackRegion)
	voiceSound:Play()
	v21 = voiceSound
	v22 = tutorialCommanderVoicePriority

	local function release()
		if v21 == voiceSound then
			v21 = nil
			v22 = false
			voiceSound:Destroy()
		end
	end

	voiceSound.Ended:Once(release)
	voiceSound.Stopped:Once(release)

	if tutorialCommanderVoicePriority then
		task.delay(15, function()
			if v21 == voiceSound then
				v22 = false
			end
		end)
	end
end

local function syncDialogue() -- 3 equivalent calls inferred from this helper
	if IsTutorialMode() then
		preloadVoices()
	end

	fn5()
	syncObjective()
	task.spawn(syncCommanderVoice)
end

function TutorialDialogue.Initialize(p, p2)
	v = p
	bindDialogue(p2)

	if v2 then
		v2.Visible = false
		setMode("Commander")
		v4 = "Hidden"
	end

	if v3 then
		v3.Text = ""
		v3.MaxVisibleGraphemes = 0
	end

	local tutorialObjective = v2 and v2.Parent and v2.Parent:FindFirstChild("TutorialObjective")

	if tutorialObjective then
		tutorialObjective:Destroy()
	end
end

function TutorialDialogue.Start()
	bindDialogue(v2)

	if not (v2 and v3) then
		return
	end

	LocalPlayer:GetAttributeChangedSignal("TutorialObjective"):Connect(syncObjective)
	LocalPlayer:GetAttributeChangedSignal("TutorialStep"):Connect(syncObjective)
	LocalPlayer:GetAttributeChangedSignal("TutorialStep"):Connect(updateSkipHint)
	LocalPlayer:GetAttributeChangedSignal("TutorialCommander"):Connect(fn5)
	LocalPlayer:GetAttributeChangedSignal("TutorialCommanderId"):Connect(fn5)
	LocalPlayer:GetAttributeChangedSignal("TutorialCommanderVoice"):Connect(syncCommanderVoice)
	LocalPlayer:GetAttributeChangedSignal("TutorialCommanderVoiceId"):Connect(syncCommanderVoice)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(syncDialogue)
	local team = LocalPlayer:GetAttribute("Team")
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(function()
		local team2 = LocalPlayer:GetAttribute("Team")

		if IsTutorialMode() and team == "Terrorists" and team2 == "Counter-Terrorists" then
			Router.broadcastRouter(
				"CreateNotification",
				"Team Changed",
				"You are now a Counter-Terrorist. The players in this room are your teammates",
				6
			)
		end

		team = team2
	end)
	workspace:GetAttributeChangedSignal("ServerGamemode"):Connect(syncDialogue)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(syncDialogue)
	workspace:GetAttributeChangedSignal("TutorialActive"):Connect(syncDialogue)
	GameState.ListenToState(function()
		if IsTutorialMode() then
			preloadVoices()
		end

		fn5()
		syncObjective()
		task.spawn(syncCommanderVoice)
	end)
	local menu = v and v:FindFirstChild("Menu")

	if menu and menu:IsA("GuiObject") then
		menu:GetPropertyChangedSignal("Visible"):Connect(function()
			if menu.Visible then
				hideDialogue()
				return
			end

			syncDialogue() -- inferred equivalent call
		end)
	end

	local buyMenu = findBuyMenu() -- inferred equivalent call

	if buyMenu then
		buyMenu:GetPropertyChangedSignal("Visible"):Connect(function()
			if v2 and v2.Visible then
				v2.Position = restPosition() -- inferred equivalent call
				liftNotifications(true)
			end
		end)
	end

	local gameplay = v and v:FindFirstChild("Gameplay")

	if gameplay and gameplay:IsA("GuiObject") then
		gameplay:GetPropertyChangedSignal("Visible"):Connect(function()
			if not gameplay.Visible then
				hideDialogue()
				return
			end

			syncDialogue() -- inferred equivalent call
		end)
	end

	v2.InputBegan:Connect(function(input)
		if not (input.UserInputType == Enum.UserInputType.Touch and LocalPlayer:GetAttribute("TutorialStep") ~= "DefuseB") then
			return
		end

		fn()
	end)
	UserInputService.LastInputTypeChanged:Connect(updateSkipHint)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updateSkipHint)
	syncDialogue() -- inferred equivalent call
end

return TutorialDialogue