local TeamSelection = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local GetTimerFormat = require(ReplicatedStorage.Components.Common.GetTimerFormat)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local LocalPlayer = Players.LocalPlayer
local colorSequence = ColorSequence.new(Color3.fromRGB(32, 32, 32))
local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(138, 138, 138)
local numberSequence = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.14375),
	NumberSequenceKeypoint.new(0.318, 1),
	NumberSequenceKeypoint.new(1, 1)
})
local numberSequence2 = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.14375),
	NumberSequenceKeypoint.new(0.183193, 1),
	NumberSequenceKeypoint.new(1, 1)
})
local visible = false
local now = 0
local v = nil
local v2 = {}
local v3 = {}
local v4 = nil
local v5 = nil

local function retrieveTeamCount(p, p2, flag: boolean?) -- 3 equivalent calls inferred from this helper
	local count = 0

	for _, v6 in ipairs(Participants.GetAll()) do
		if flag and Participants.IsBot(v6) or v6 == p2 or v6:GetAttribute("Team") ~= p then
			continue
		end

		count += 1
	end

	return count
end

local function isDeathmatchMode()
	return workspace:GetAttribute("ServerGamemode") == "Deathmatch"
		or workspace:GetAttribute("Gamemode") == "Deathmatch"
end

local function areTeamLimitsDisabled() -- 2 equivalent calls inferred from this helper
	return workspace:GetAttribute("VIPDisableTeamLimitEnabled") == true
		or workspace:GetAttribute("ServerGamemode") == "Deathmatch"
		or workspace:GetAttribute("Gamemode") == "Deathmatch"
end

local function teamHasBot(p) -- 2 equivalent calls inferred from this helper
	local count = retrieveTeamCount(p, nil, false) -- inferred equivalent call
	return retrieveTeamCount(p, nil, true) < count
end

local function chooseBalancedTeam(localPlayer) -- 1 equivalent call inferred from this helper
	local v6 = retrieveTeamCount("Counter-Terrorists", localPlayer, true)
	local v7 = retrieveTeamCount("Terrorists", localPlayer, true)

	if v6 == v7 then
		if localPlayer:GetAttribute("Team") == "Terrorists" then
			return "Counter-Terrorists"
		end

		return "Terrorists"
	elseif v6 < v7 then
		return "Counter-Terrorists"
	else
		return "Terrorists"
	end
end

local function isTeamAvailable(localPlayer, p)
	if IsTutorialMode() then
		return p == "Terrorists" or p == "Spectators"
	end

	if areTeamLimitsDisabled() then -- inferred equivalent call
		return p == "Counter-Terrorists" or p == "Terrorists" or p == "Spectators"
	end

	if (p == "Counter-Terrorists" or p == "Terrorists") and teamHasBot(p) then -- inferred equivalent call
		return true
	end

	local v6 = retrieveTeamCount("Counter-Terrorists", localPlayer, true)
	local v7 = retrieveTeamCount("Terrorists", localPlayer, true)

	if p == "Terrorists" and v7 < v6 or p == "Counter-Terrorists" and v6 < v7 then
		return true
	end

	return p == "Spectators" or v6 == v7
end

local function setPlayerTemplateUnhovered(frame, childName: string)
	if not (frame and frame:IsA("Frame")) then
		return
	end

	frame.BackgroundColor3 = childName == "Counter-Terrorists" and Color3.fromRGB(109, 121, 140)
		or Color3.fromRGB(131, 111, 66)
	frame.Player.UIStroke.Color = childName == "Counter-Terrorists" and Color3.fromRGB(50, 56, 65)
		or Color3.fromRGB(94, 85, 54)
	frame.Player.Avatar.ImageColor3 = color2
end

local function updateTeamAvailabilityStyles()
	local v6 = areTeamLimitsDisabled() -- inferred equivalent call
	local count = retrieveTeamCount("Counter-Terrorists", nil, false) -- inferred equivalent call
	local count2 = retrieveTeamCount("Terrorists", nil, false) -- inferred equivalent call
	local v7 = retrieveTeamCount("Counter-Terrorists", nil, true)
	local v8 = retrieveTeamCount("Terrorists", nil, true)

	for _, childName in ipairs({ "Counter-Terrorists", "Terrorists" }) do
		local child = v4:FindFirstChild(childName)

		if not child then
			continue
		end

		if not v2[childName] then
			v2[childName] = {
				TeamTransparency = child.Team.TextTransparency,
				PlayersTransparency = child.Players.TextTransparency,
				UIGradient = child.UIGradient.Color,
				IconOutline = child.Icon.Outline.ImageTransparency,
				IconTeam = child.Icon.Team.ImageTransparency,
				IconTeamIcon = child.Icon.Team.Icon.ImageTransparency
			}
		end

		local v9 = not v6

		if v9 then
			v9 = not teamHasBot(childName) -- inferred equivalent call

			if v9 then
				if childName == "Counter-Terrorists" and v8 < v7 then
					v9 = true
				elseif childName == "Terrorists" then
					if v7 < v8 then
						v9 = true
					else
						v9 = false
					end
				else
					v9 = false
				end
			end
		end

		v3[childName] = v9
		local v10 = childName == "Counter-Terrorists" and count or count2
		local v11 = v2[childName]
		child.Players.Text = `{v10} Player{v10 == 1 and "" or "s"}`
		child.Team.TextTransparency = v9 and 0.5 or v11.TeamTransparency
		child.Players.TextTransparency = v9 and 0.5 or v11.PlayersTransparency
		child.UIGradient.Color = v9 and colorSequence or v11.UIGradient
		child.Icon.Outline.ImageTransparency = v9 and 0.4 or v11.IconOutline
		child.Icon.Team.ImageTransparency = v9 and 0.4 or v11.IconTeam
		child.Icon.Team.Icon.ImageTransparency = v9 and 0.4 or v11.IconTeamIcon

		for _, child2 in ipairs(child.Container:GetChildren()) do
			if v9 then
				setPlayerTemplateUnhovered(child2, childName)
			end
		end
	end
end

local function createButtonAnimation(p)
	p.MouseEnter:Connect(function()
		TweenService:Create(p, TweenInfo.new(0.1), { BackgroundTransparency = 0.85 }):Play()
	end)
	p.MouseLeave:Connect(function()
		TweenService:Create(p, TweenInfo.new(0.1), { BackgroundTransparency = 1 }):Play()
	end)
end

local function isCharacterAlive() -- 2 equivalent calls inferred from this helper
	return CharacterResolver.isAliveCharacter(LocalPlayer.Character)
end

local function getMenuSceneController() -- 5 equivalent calls inferred from this helper
	return require(ReplicatedStorage.Controllers.MenuSceneController)
end

local function createTeamListeners(p, p2)
	p.MouseButton1Click:Connect(function()
		TeamSelection.chooseTeam(p2)
	end)

	if p2 == "Spectators" then
		createButtonAnimation(p)
	else
		TeamSelection.createTeamButtonAnimation(p, p2)
	end
end

local function destroyPlayerTemplate(p) -- 2 equivalent calls inferred from this helper
	local child = v4:FindFirstChild(tostring(p), true)

	if child then
		child:Destroy()
	end
end

function TeamSelection.isVisible()
	if not (v4 and v4.Visible and v5) then
		return false
	end

	local gameplay = v5:FindFirstChild("Gameplay")
	local bottom = gameplay and gameplay:FindFirstChild("Bottom")
	return bottom ~= nil and bottom:IsA("GuiObject") and not bottom.Visible
end

function TeamSelection.shouldUseMapCamera()
	return TeamSelection.isVisible() and not isCharacterAlive() -- inferred equivalent call
end

function TeamSelection.ToggleTeamSelection()
	if EndScreenController.IsActive() then
		return
	end

	if v4.Visible then
		TeamSelection.closeFrame()
	else
		TeamSelection.openFrame()
	end
end

function TeamSelection.openFrame()
	if IsTutorialMode() then
		if v5.Menu.Visible then
			return
		end

		local team = LocalPlayer:GetAttribute("Team")

		if team ~= "Counter-Terrorists" and team ~= "Terrorists" then
			TeamSelection.chooseTeam("Terrorists")
		end
	else
		if
			EndScreenController.IsActive()
			or (MenuState.IsCaseSceneActive() or MenuState.IsInspectActive())
			or v4.Visible
		then
			return
		end

		if v5.Menu.Visible then
			local currentScreen = MenuState.GetCurrentScreen()

			if MenuState.IsPreservableScreen(currentScreen) then
				local child = v5.Menu:FindFirstChild(currentScreen)

				if child and child.Visible then
					return
				end
			end
		end

		local menuSceneController = getMenuSceneController() -- inferred equivalent call

		if menuSceneController.IsActive() then
			menuSceneController.HideMenuScene(true, false, true)
		end

		v = CameraController.getTargetFOV()

		if v5.Menu.Visible then
			CameraController.setForceLockOverride("Menu", false)
			MenuState.SetBlurEnabled(false)
		end

		local buyMenu = v5.Gameplay.Middle:FindFirstChild("BuyMenu")
		visible = buyMenu and buyMenu.Visible or false

		if visible then
			local BuyMenu = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.BuyMenu)
			BuyMenu.closeFrame()
		end

		CameraController.setForceLockOverride("TeamSelection", true)

		if not LocalPlayer:GetAttribute("IsSpectating") then
			CameraController.setPerspective(true, true)
		end

		v5.Gameplay.Bottom.Visible = false
		v5.Gameplay.Top.Visible = true
		v5.Gameplay.Visible = true
		MenuState.HideMenu()
		local index = table.find(GetUserPlatform(), "Mobile")

		for _, child in ipairs(v5.Gameplay.Middle:GetChildren()) do
			if child.Name == "Chat" then
				child.Visible = not index
			elseif child.Name == "MobileButtons" then
				local character = LocalPlayer.Character

				if character and character:IsDescendantOf(workspace) then
					child.Visible = index
				else
					child.Visible = false
				end
			else
				child.Visible = child.Name == "Notification" or child.Name == "TeamSelection"
			end
		end

		updateTeamAvailabilityStyles()
		menuSceneController.ShowTeamSelectScene()
	end
end

function TeamSelection.closeFrame()
	getMenuSceneController().HideTeamSelectScene() -- inferred equivalent call
	CameraController.setForceLockOverride("TeamSelection", false)

	if LocalPlayer.Character then
		CameraController.setForceLockOverride("Menu", false)
	end

	if not LocalPlayer:GetAttribute("IsSpectating") then
		CameraController.setPerspective(true, false)
	end

	local v6 = v
	v = nil

	if v6 and not LocalPlayer:GetAttribute("IsSpectating") then
		CameraController.updateCameraFOV(v6)
	end

	local visible2 = v4.Visible
	v4.Visible = false

	if visible2 or not v5.Menu.Visible then
		MenuState.SetScreen(nil)
	end

	if v5.Menu.Visible then
		v5.Gameplay.Bottom.Visible = false
		v5.Gameplay.Visible = false
		visible = false
		local tutorialDialogue = v5.Gameplay.Middle:FindFirstChild("TutorialDialogue")

		if tutorialDialogue and tutorialDialogue:IsA("GuiObject") then
			tutorialDialogue.Visible = false
		end
	else
		v5.Gameplay.Middle.Crosshair.Visible = true
		v5.Gameplay.Top.Visible = true
		v5.Gameplay.Bottom.Visible = true
		local index = table.find(GetUserPlatform(), "Mobile")
		local character = LocalPlayer.Character
		local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true
		local team = LocalPlayer:GetAttribute("Team")
		local v7 = team == "Counter-Terrorists" or team == "Terrorists"

		for _, child in ipairs(v5.Gameplay.Middle:GetChildren()) do
			local visible3 = character and character:IsDescendantOf(workspace)
			local name = child.Name

			if name == "Chat" then
				child.Visible = not index
			elseif name == "MobileButtons" then
				local visible4

				if index then
					visible4 = visible3 or isSpectating or false
				else
					visible4 = false
				end

				child.Visible = visible4
			elseif name == "Votekick" then
				child.Visible = child:GetAttribute("IsVoteKickActive") == true
			elseif name == "Notification" then
				child.Visible = true
			elseif name == "SessionStats" then
				child.Visible = not index
			elseif name == "Crosshair" then
				child.Visible = visible3
			elseif name == "Radar" then
				local visible4

				if visible3 or v7 or isSpectating then
					visible4 = not IsTutorialMode()
				else
					visible4 = isSpectating
				end

				child.Visible = visible4
			elseif name ~= "TutorialDialogue" and name ~= "TutorialObjective" then
				child.Visible = false
			end
		end

		if visible then
			local BuyMenu = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.BuyMenu)
			visible = false
			BuyMenu.openFrame()
		end
	end
end

function TeamSelection.chooseTeam(p)
	MenuState.SetWantsMainMenu(false)

	if LocalPlayer:GetAttribute("Team") == p then
		if p == "Spectators" and not LocalPlayer:GetAttribute("IsSpectating") then
			Remotes.Spectate.StartSpectating.Send()
		end

		TeamSelection.closeFrame()
	elseif isTeamAvailable(LocalPlayer, p) and tick() - now >= 1 then
		if p == "Spectators" then
			LocalPlayer:SetAttribute("PendingSpectateRequestAt", os.clock())
		end

		Remotes.TeamSelection.SelectTeam.Send(p)
		now = tick()
	end
end

function TeamSelection.createTeamButtonAnimation(p, childName)
	local child = v4:FindFirstChild(childName)

	if child then
		p.MouseEnter:Connect(function()
			if v3[childName] then
				return
			end

			getMenuSceneController().SetTeamSelectHighlight(childName, true) -- inferred equivalent call
			local outline = child.Icon.Outline
			local color3 = childName == "Counter-Terrorists" and Color3.fromRGB(165, 183, 212)

			if not color3 then
				if childName == "Terrorists" then
					color3 = Color3.fromRGB(219, 199, 126)
				else
					color3 = false
				end
			end

			outline.ImageColor3 = color3
			child.Icon.Team.Icon.ImageColor3 = color
			local team = child.Icon.Team
			local color4 = childName == "Counter-Terrorists" and Color3.fromRGB(36, 41, 47)

			if not color4 then
				if childName == "Terrorists" then
					color4 = Color3.fromRGB(89, 79, 50)
				else
					color4 = false
				end
			end

			team.ImageColor3 = color4
			child.UIGradient.Transparency = numberSequence

			for _, frame in ipairs(child.Container:GetChildren()) do
				if not frame:IsA("Frame") then
					continue
				end

				local color5 = childName == "Counter-Terrorists" and Color3.fromRGB(126, 140, 187)

				if not color5 then
					if childName == "Terrorists" then
						color5 = Color3.fromRGB(219, 188, 110)
					else
						color5 = false
					end
				end

				frame.BackgroundColor3 = color5
				local uiStroke = frame.Player.UIStroke
				local color6 = childName == "Counter-Terrorists" and Color3.fromRGB(165, 183, 212)

				if not color6 then
					if childName == "Terrorists" then
						color6 = Color3.fromRGB(219, 199, 126)
					else
						color6 = false
					end
				end

				uiStroke.Color = color6
				frame.Player.Avatar.ImageColor3 = color
			end
		end)
		p.MouseLeave:Connect(function()
			if v3[childName] then
				return
			end

			getMenuSceneController().SetTeamSelectHighlight(childName, false) -- inferred equivalent call
			local outline = child.Icon.Outline
			local color3 = childName == "Counter-Terrorists" and Color3.fromRGB(107, 119, 138)

			if not color3 then
				if childName == "Terrorists" then
					color3 = Color3.fromRGB(127, 115, 73)
				else
					color3 = false
				end
			end

			outline.ImageColor3 = color3
			local icon = child.Icon.Team.Icon
			local color4 = childName == "Counter-Terrorists" and Color3.fromRGB(131, 131, 131)

			if not color4 then
				if childName == "Terrorists" then
					color4 = Color3.fromRGB(182, 182, 182)
				else
					color4 = false
				end
			end

			icon.ImageColor3 = color4
			local team = child.Icon.Team
			local color5 = childName == "Counter-Terrorists" and Color3.fromRGB(20, 24, 27)

			if not color5 then
				if childName == "Terrorists" then
					color5 = Color3.fromRGB(58, 51, 33)
				else
					color5 = false
				end
			end

			team.ImageColor3 = color5
			child.UIGradient.Transparency = numberSequence2

			for _, child2 in ipairs(child.Container:GetChildren()) do
				setPlayerTemplateUnhovered(child2, childName)
			end
		end)
	end
end

function TeamSelection.updatePlayerList(instance, flag: boolean?)
	Profiler.mark("UI.TeamSelection.UpdatePlayerList")
	local team = instance:GetAttribute("Team")
	destroyPlayerTemplate(Participants.Key(instance)) -- inferred equivalent call

	if team == "Counter-Terrorists" or team == "Terrorists" then
		local child = ReplicatedStorage.Assets.UI.TeamSelection:FindFirstChild(team)

		if child and not flag then
			local child2 = v4:WaitForChild(team)
			local _, result = pcall(function()
				return Players:GetUserThumbnailAsync(
					Participants.AvatarUserId(instance),
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size420x420
				)
			end)
			Profiler.scope("UI.TeamSelection.UpdatePlayerList.CloneRow", function()
				local clone = child:Clone()
				clone.Parent = child2.Container
				clone.Team.Text = Participants.DisplayName(instance)
				clone.Player.Avatar.Image = result
				clone.Name = tostring(Participants.Key(instance))
				clone.Visible = true
			end)
		end
	end

	local players = v4["Counter-Terrorists"].Players
	local count = 0

	for _, v6 in ipairs(Participants.GetAll()) do
		if v6 ~= nil and v6:GetAttribute("Team") == "Counter-Terrorists" then
			count += 1
		end
	end

	players.Text = `{count} Player(s)`
	local players2 = v4.Terrorists.Players
	local count2 = 0

	for _, v6 in ipairs(Participants.GetAll()) do
		if v6 ~= nil and v6:GetAttribute("Team") == "Terrorists" then
			count2 += 1
		end
	end

	players2.Text = `{count2} Player(s)`
	updateTeamAvailabilityStyles()
end

function TeamSelection.Initialize(p, p2)
	v4 = p2
	v5 = p
	Observers.observePlayer(function(p3)
		TeamSelection.updatePlayerList(p3)
		local v6 = Observers.observeAttribute(p3, "Team", function()
			TeamSelection.updatePlayerList(p3)

			if LocalPlayer == p3 and v4.Visible then
				TeamSelection.closeFrame()
			end

			return function()
				local userId = p3.UserId
				local child = v4:FindFirstChild(tostring(userId), true)

				if child then
					child:Destroy()
				end
			end
		end)
		return function()
			TeamSelection.updatePlayerList(p3, true)
			v6()
		end
	end)
	local v6 = {}
	Participants.Observe(function(p3)
		if not Participants.IsBot(p3) then
			return
		end

		v6[p3] = Observers.observeAttribute(p3, "Team", function()
			TeamSelection.updatePlayerList(p3)
			return function()
				destroyPlayerTemplate(Participants.Key(p3)) -- inferred equivalent call
			end
		end)
	end, function(p3)
		if not Participants.IsBot(p3) then
			return
		end

		TeamSelection.updatePlayerList(p3, true)
		local v7 = v6[p3]
		v6[p3] = nil

		if v7 then
			v7()
		end
	end)
	Observers.observeAttribute(LocalPlayer, "Team", function()
		if v4.Visible and GameState.GetState() == "Round In Progress" then
			TeamSelection.closeFrame()
		end
	end)
	Observers.observeAttribute(workspace, "Timer", function(p3)
		v4.ProgressBar.Timer.Text = GetTimerFormat(p3)
	end)
	LocalPlayer.CharacterAdded:Connect(function()
		if v4.Visible then
			TeamSelection.closeFrame()
			return
		end

		local radar = v5.Gameplay.Middle:FindFirstChild("Radar")

		if radar and radar:IsA("GuiObject") and v5.Gameplay.Visible and not (v5.Menu.Visible or IsTutorialMode()) then
			radar.Visible = true
		end
	end)

	for _, v7 in ipairs({ "VIPDisableTeamLimitEnabled", "ServerGamemode", "Gamemode" }) do
		Observers.observeAttribute(workspace, v7, updateTeamAvailabilityStyles)
	end
end

function TeamSelection.Start()
	local button = v4["Counter-Terrorists"].Button
	local v6
	v6 = "Counter-Terrorists"
	button.MouseButton1Click:Connect(function()
		TeamSelection.chooseTeam(v6)
	end)
	TeamSelection.createTeamButtonAnimation(button, "Counter-Terrorists")
	local spectate = v4.Bottom.Buttons.Spectate
	local v7
	v7 = "Spectators"
	spectate.MouseButton1Click:Connect(function()
		TeamSelection.chooseTeam(v7)
	end)
	createButtonAnimation(spectate)
	local button2 = v4.Terrorists.Button
	local v8
	v8 = "Terrorists"
	button2.MouseButton1Click:Connect(function()
		TeamSelection.chooseTeam(v8)
	end)
	TeamSelection.createTeamButtonAnimation(button2, "Terrorists")
	createButtonAnimation(v4.Bottom.Buttons.AutoSelect)
	v4.Bottom.Buttons.AutoSelect.MouseButton1Click:Connect(function()
		TeamSelection.chooseTeam(chooseBalancedTeam(LocalPlayer)) -- inferred equivalent call
	end)
	createButtonAnimation(v4.Bottom.Buttons.BackHome)
	v4.Bottom.Buttons.BackHome.MouseButton1Click:Connect(function()
		local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true
		local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)

		if isSpectating or not isCharacterAlive() then -- inferred equivalent call
			local team = LocalPlayer:GetAttribute("Team")

			if team and team ~= "Spectators" then
				Remotes.TeamSelection.SelectTeam.Send("Spectators")
			end

			SpectateController.Stop(true, true)
			MenuState.SetWantsMainMenu(true)
			TeamSelection.closeFrame()
			local menuSceneController = getMenuSceneController() -- inferred equivalent call
			CameraController.setForceLockOverride("Menu", true)
			CameraController.setPerspective(true, true)
			v5.Gameplay.Visible = false
			v5.Gameplay.Bottom.Visible = false
			v5.Menu.Visible = true
			Top.ResetToMainMenu()
			menuSceneController.ShowMenuScene()
		else
			visible = false
			TeamSelection.closeFrame()
			Top.ShowMainMenuOverGameplay()
		end
	end)
end

return TeamSelection