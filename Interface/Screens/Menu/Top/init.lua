local Top = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local IsPlayingTeam = require(ReplicatedStorage.Components.Common.IsPlayingTeam)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local TeamSelection = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.TeamSelection)
local CurrentCamera = workspace.CurrentCamera
local blurEffect = Instance.new("BlurEffect", Lighting)
blurEffect.Enabled = false
blurEffect.Name = "Menu"
blurEffect.Size = 20
local v = false
local v2 = false
local flag = false
local flag2 = false
local v3 = false
local v4 = nil
local dashboard = nil
local selectedObject = nil
local v5 = nil
local now = 0
local fn
local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(150, 220, 239)
local color3 = Color3.fromRGB(175, 175, 175)
local v6 = nil
local v7 = nil

local function tweenButton(button, color4: Color3)
	if button:IsA("ImageButton") then
		TweenService:Create(button, TweenInfo.new(0.15), { ImageColor3 = color4 }):Play()
	elseif button:IsA("TextButton") then
		local defaultSize = button:GetAttribute("DefaultSize") or button.Size
		local v8 = color4 == color2 and 1.12 or color4 == color3 and 1.06 or 1
		TweenService:Create(button, TweenInfo.new(0.15), {
			Size = UDim2.new(
				defaultSize.X.Scale * v8,
				defaultSize.X.Offset * v8,
				defaultSize.Y.Scale * v8,
				defaultSize.Y.Offset * v8
			)
		}):Play()
	end
end

local function animateBlackmarketButton(blackmarket, fn2)
	local icon = blackmarket:FindFirstChild("Icon")

	if not icon then
		return
	end

	local position = icon.Position
	local rotation = icon.Rotation
	local v8 = false
	local total = 0
	blackmarket.MouseEnter:Connect(function()
		v8 = true
	end)
	blackmarket.MouseLeave:Connect(function()
		v8 = false
	end)
	RunServiceController.BindToRenderStep("UI.Top.BlackmarketButton", function(p: number)
		if not fn2() then
			return
		end

		if GuiService.ReducedMotionEnabled then
			icon.Position = position
			icon.Rotation = rotation
		else
			total += ((v8 and 1 or 0) - total) * (1 - math.exp(p * -14))
			local v9 = os.clock() * 1.4
			icon.Position = position + UDim2.fromScale(0, math.sin(v9) * 0.035)
			icon.Rotation = rotation + math.cos(v9) * 2 + total * -8
		end
	end)
end

local y = nil

local function fitTopButtonsBesideTabs()
	local buttons = v6.Top.Buttons
	local store = v7.Menu:FindFirstChild("Store")
	local top = store and store:FindFirstChild("Top")
	local categories = top and top:FindFirstChild("Categories")
	local v8 = y

	if not (categories and v8) then
		return
	end

	if categories:IsA("GuiObject") and not categories.Visible then
		buttons.Size = UDim2.new(buttons.Size.X, v8)
		return
	end

	local v9 = -1e999

	for _, guiObject in categories:GetChildren() do
		if guiObject:IsA("GuiObject") and guiObject.Visible then
			v9 = math.max(v9, guiObject.AbsolutePosition.X + guiObject.AbsoluteSize.X)
		end
	end

	local count = 0
	local v10 = 0

	for _, button in buttons:GetChildren() do
		if not (button:IsA("GuiButton") and button.Visible) then
			continue
		end

		count += 1
		v10 = math.max(v10, button.Size.Y.Scale)
	end

	local y2 = buttons.Parent.AbsoluteSize.Y

	if v9 == -1e999 or count == 0 or v10 <= 0 or y2 <= 0 then
		return
	end

	local x = buttons.AbsoluteSize.X
	local uiPadding = buttons:FindFirstChildOfClass("UIPadding")
	local uiListLayout = buttons:FindFirstChildOfClass("UIListLayout")
	local v11 = not uiPadding and 0 or uiPadding.PaddingRight.Scale * x + uiPadding.PaddingRight.Offset
	local v12 = not uiListLayout and 0 or uiListLayout.Padding.Scale * x + uiListLayout.Padding.Offset
	local v13 = buttons.AbsolutePosition.X + x - v11 - (v9 + 8) - v12 * (count - 1)
	local v14 = v10 * math.min(x, v8.Scale * y2 + v8.Offset)
	local v15 = math.clamp(v13 / count / v14, 0, 1)
	buttons.Size = UDim2.new(buttons.Size.X, UDim.new(v8.Scale * v15, v8.Offset * v15))
end

local function setupButton(folder)
	for _, guiObject in ipairs(folder:GetDescendants()) do
		if not guiObject:IsA("GuiObject") or guiObject:IsA("GuiButton") or not guiObject.Active then
			continue
		end

		guiObject.Active = false
	end

	if folder:IsA("ImageButton") then
		folder.ImageColor3 = color
	elseif folder:IsA("TextButton") then
		folder.TextLabel.TextColor3 = color
		folder:SetAttribute("DefaultSize", folder.Size)
	end

	folder.MouseLeave:Connect(function()
		if dashboard ~= folder then
			tweenButton(folder, color)
		end
	end)
	folder.MouseEnter:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Highlight")

		if dashboard ~= folder then
			tweenButton(folder, color3)
		end
	end)
	folder.MouseButton1Click:Connect(function()
		local v8 = dashboard
		dashboard = folder

		if v8 ~= folder then
			tweenButton(folder, color2)

			if v8 then
				local alert = v8:FindFirstChild("Alert")
				tweenButton(v8, color)

				if alert then
					alert.Visible = false
				end
			end
		end
	end)
end

local v8 = {
	Dashboard = true,
	Inventory = true,
	Loadout = true,
	Gamemodes = true,
	Settings = true,
	Store = true,
	Career = true,
	Progression = true,
	GlobalMarketPlace = true,
	GameDashboard = true,
	Blackmarket = true
}

local function toMenuScreen(childName: string) -- 1 equivalent call inferred from this helper
	if v8[childName] then
		return childName
	end

	return nil
end

local function setButtonToggle(p) -- 4 equivalent calls inferred from this helper
	local v9 = dashboard
	dashboard = p
	tweenButton(p, color2)

	if v9 and v9 ~= p then
		tweenButton(v9, color)
	end
end

local function setNavigationVisible(visible: boolean)
	if not v6 then
		return
	end

	for _, childName in ipairs({ "Top", "Bottom" }) do
		local guiObject = v6:FindFirstChild(childName)

		if guiObject and guiObject:IsA("GuiObject") then
			guiObject.Visible = visible
		end
	end
end

local function syncControlLockWithMenuVisibility()
	local visible = v7 and v7.Menu and v7.Menu.Visible
	local visible2 = TeamSelection.isVisible()
	local v9 = visible == true or visible2 == true

	if v9 and not v2 then
		InputController.disableGroup("Gameplay")
		v2 = true
	elseif not v9 and v2 then
		InputController.enableGroup("Gameplay")
		v2 = false
	end

	if UserInputService.TouchEnabled then
		local touchControlsEnabled = not v9

		if GuiService.TouchControlsEnabled ~= touchControlsEnabled then
			GuiService.TouchControlsEnabled = touchControlsEnabled
		end
	end
end

local function syncCameraWithTeamSelection()
	local shouldUseMapCamera = TeamSelection.shouldUseMapCamera()

	if v7.Menu.Visible or not shouldUseMapCamera then
		return
	end

	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)

	if MenuSceneController.ShowTeamSelectScene() then
		return
	end

	if MenuSceneController.IsActive() then
		MenuSceneController.HideMenuScene(true, false)
	end

	local map = workspace:FindFirstChild("Map")

	if map then
		Top.UpdateBackground(map)
	end
end

function Top.UpdateBackground(instance)
	Profiler.mark("UI.Top.UpdateBackground")
	local shouldUseMapCamera = TeamSelection.shouldUseMapCamera()

	if v7.Menu.Visible or not shouldUseMapCamera then
		return
	end

	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)

	if
		MenuSceneController.IsActive()
		or MenuSceneController.IsTeamSelectSceneActive()
		or (MenuState.IsInspectActive() or MenuState.IsCaseSceneActive())
	then
		return
	end

	if LocalPlayer:GetAttribute("IsSpectating") then
		return
	end

	local cameras = instance:FindFirstChild("Cameras")

	if cameras then
		local children = cameras:GetChildren()
		assert(children[1], "Current map doesnt contain any cameras.")
		CurrentCamera.CameraType = Enum.CameraType.Scriptable
		CurrentCamera.CameraSubject = nil
		local replicationFocus = children[math.random(1, #children)]
		LocalPlayer.ReplicationFocus = replicationFocus
		CurrentCamera.CFrame = replicationFocus.CFrame
		CameraController.updateCameraFOV(80)
	end
end

function Top.ToggleMenu()
	Profiler.mark("UI.Top.ToggleMenu")

	if MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() then
		return
	end

	local state = GameState.GetState()

	if not state or state == "Map Voting" or state == "Game Ending" then
		return
	end

	if v7.Menu.Visible then
		MenuState.SetWantsMainMenu(false)
		v3 = false
		CameraController.setForceLockOverride("Menu", false)

		if not LocalPlayer:GetAttribute("IsSpectating") then
			CameraController.setPerspective(true, false)
		end

		MenuState.SetBlurEnabled(false)
		v7.Gameplay.Visible = true
		v7.Gameplay.Top.Visible = true
		local visible = table.find(GetUserPlatform(), "Mobile") == nil
		v7.Gameplay.Middle.SessionStats.Visible = visible
		v7.Gameplay.Middle.Chat.Visible = visible
		MenuState.HideMenu()
	else
		if v7.Gameplay.Middle.TeamSelection.Visible then
			TeamSelection.closeFrame()
		end

		CameraController.setForceLockOverride("Menu", true)

		if not LocalPlayer:GetAttribute("IsSpectating") then
			CameraController.setPerspective(true, true)
		end

		v7.Gameplay.Visible = false
		v7.Menu.Visible = true

		if LocalPlayer.Character then
			Top.openFrame("GameDashboard")
		elseif v4 and not v4.Visible then
			Top.openFrame(v4.Name)
		end

		if v4 and v4.Name ~= "Dashboard" then
			MenuState.SetBlurEnabled(true)
		end
	end
end

function Top.openFrame(childName: string, flag3: boolean?)
	Profiler.mark("UI.Top.OpenFrame")

	if MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() then
		return
	end

	if childName == "Store" and not MenuState.IsStoreEnabled() then
		Router.broadcastRouter("RunInterfaceSound", "UI Store Click")
		return
	end

	if childName == "Store" then
		fn()
	end

	local isSceneScreen = MenuState.IsSceneScreen(childName)
	local v9

	if childName == "Dashboard" or childName == "Play" then
		v9 = false
	else
		v9 = not isSceneScreen
	end

	MenuState.SetBlurEnabled(v9)
	local pattern = v7.Menu:FindFirstChild("Pattern")
	v7.Menu.BackgroundTransparency = v9 and 0.15 or 1

	if pattern then
		pattern.Visible = not (v9 or isSceneScreen)
	end

	setNavigationVisible(not isSceneScreen)

	if childName == "Play" then
		local state = GameState.GetState()
		local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)

		if state and (state ~= "Game Ending" or not EndScreenController.IsActive()) then
			local v10 = nil
			local v11 = v3
			v3 = false
			Router.broadcastRouter("RunInterfaceSound", "UI Play Click")

			if flag3 then
				Top.reportPressedPlay()
				MenuState.SetWantsMainMenu(false)
			end

			CameraController.resetForceLockOverride()
			CameraController.setPerspective(true, false)

			if v4 and v4.Name ~= "Dashboard" then
				v4.Visible = false
				local dashboard2 = v7.Menu:FindFirstChild("Dashboard")

				if dashboard2 then
					dashboard2.Visible = true
					v4 = dashboard2
				end
			end

			v7.Gameplay.Bottom.Visible = false
			v7.Gameplay.Top.Visible = true
			v7.Gameplay.Visible = true
			MenuState.HideMenu()

			if state == "Map Voting" then
				v10 = "EndScreen"
			else
				local team = LocalPlayer:GetAttribute("Team")
				local character = LocalPlayer.Character
				local v12 = v11 and IsPlayingTeam(team)

				if IsTutorialMode() then
					if team ~= "Terrorists" or not character then
						Remotes.TeamSelection.SelectTeam.Send("Terrorists")
					end
				else
					v10 = not v12 and (not character or not team or team == "Spectators") and "TeamSelection" or v10
				end
			end

			if v10 then
				CameraController.setForceLockOverride(v10, true)
				CameraController.setPerspective(true, true)

				for _, child in ipairs(v7.Gameplay.Middle:GetChildren()) do
					if child.Name == "Chat" then
						child.Visible = not table.find(GetUserPlatform(), "Mobile")
					else
						child.Visible = child.Name == "Notification"
							or child.Name == "Votekick" and child:GetAttribute("IsVoteKickActive") == true
							or child.Name == v10
					end
				end
			else
				local visible = table.find(GetUserPlatform(), "Mobile") == nil
				v7.Gameplay.Middle.SessionStats.Visible = visible
				v7.Gameplay.Middle.Chat.Visible = visible
				v7.Gameplay.Middle.TeamSelection.Visible = false
				v7.Gameplay.Middle.Crosshair.Visible = true
				v7.Gameplay.Top.Visible = true
				v7.Gameplay.Bottom.Visible = true
				local radar = v7.Gameplay.Middle:FindFirstChild("Radar")

				if v11 and radar and radar:IsA("GuiObject") and not IsTutorialMode() then
					radar.Visible = true
				end

				if LocalPlayer.Character then
					CameraController.setPerspective(true, false)
				end
			end
		end
	else
		if childName == "Inventory" then
			Router.broadcastRouter("ResetInventoryToGrid")
		end

		local child = v7.Menu:FindFirstChild(childName)

		if child and (child ~= v4 or not child.Visible) then
			child.Visible = true

			if v4 and v4 ~= child then
				v4.Visible = false
			end

			v4 = child
			MenuState.SetScreen(toMenuScreen(childName)) -- inferred equivalent call
		end

		if v then
			Router.broadcastRouter("RunInterfaceSound", `UI {childName} Click`)
		else
			v = childName == "Dashboard"
		end
	end
end

function Top.reportPressedPlay()
	if flag2 then
		return
	end

	flag2 = true
	Remotes.Player.PressedPlay.Send()
end

function Top.CloseTeamSelection()
	v7.Gameplay.Middle.TeamSelection.Visible = false
	v7.Gameplay.Middle.Crosshair.Visible = true
	v7.Gameplay.Top.Visible = true
	v7.Gameplay.Bottom.Visible = true
end

local v9 = {
	"Loadout",
	"Inventory",
	"Gamemodes",
	"Play",
	"Store",
	"GlobalMarketPlace",
	"Progression"
}

local function getControllerCurrentTab()
	local selectedObject2 = GuiService.SelectedObject

	for _, childName in ipairs(v9) do
		local child = v6.Bottom.Buttons:FindFirstChild(childName)

		if child and selectedObject2 and (selectedObject2 == child or selectedObject2:IsDescendantOf(child)) then
			return childName
		end
	end

	local currentScreen = MenuState.GetCurrentScreen()

	if currentScreen and table.find(v9, currentScreen) then
		return currentScreen
	end

	local name = dashboard and dashboard.Name or nil

	if name and table.find(v9, name) then
		return name
	end

	return "Play"
end

local function getTabForBumper(p: string, flag3: boolean) -- 1 equivalent call inferred from this helper
	local index = table.find(v9, p)

	if not index then
		return nil
	end

	local count = #v9

	if flag3 then
		return v9[(index - 2 + count) % count + 1]
	end

	return v9[index % count + 1]
end

local function getTopButton(childName: string)
	if not v6 then
		return nil
	end

	for _, childName2 in ipairs({ "Top", "Bottom" }) do
		local child = v6:FindFirstChild(childName2)
		local buttons = child and child:FindFirstChild("Buttons")
		local button = buttons and buttons:FindFirstChild(childName)

		if button and button:IsA("GuiButton") then
			return button
		end
	end

	return nil
end

local function goToTab(tabForBumper: string, flag3: boolean?)
	local topButton = getTopButton(tabForBumper)

	if not topButton then
		return
	end

	GuiService.SelectedObject = topButton
	MenuState.HoldNavigationSelection(topButton)

	if not flag3 then
		Top.openFrame(tabForBumper)
	end

	setButtonToggle(topButton) -- inferred equivalent call
	Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
end

local function getVisibleUtilityButtons()
	local buttons = {}

	for _, button in ipairs(v6.Top.Buttons:GetChildren()) do
		if button:IsA("GuiButton") and button.Visible then
			table.insert(buttons, button)
		end
	end

	table.sort(buttons, function(a, b)
		return a.AbsolutePosition.X < b.AbsolutePosition.X
	end)
	return buttons
end

local function cycleUtilityButtons(flag3: boolean)
	local visibleUtilityButtons = getVisibleUtilityButtons()
	local count = #visibleUtilityButtons

	if count == 0 then
		return
	end

	local selectedObject2 = GuiService.SelectedObject
	local v10 = 1

	for i, ancestor in ipairs(visibleUtilityButtons) do
		if not (selectedObject2 and (selectedObject2 == ancestor or selectedObject2:IsDescendantOf(ancestor))) then
			continue
		end

		v10 = i
		break
	end

	local visibleUtilityButton = visibleUtilityButtons[(v10 - 1 + (flag3 and -1 or 1)) % count + 1]
	GuiService.SelectedObject = visibleUtilityButton
	MenuState.HoldNavigationSelection(visibleUtilityButton)

	if visibleUtilityButton.Name ~= "Blackmarket" then
		Top.openFrame(visibleUtilityButton.Name)
		setButtonToggle(visibleUtilityButton) -- inferred equivalent call
	end

	Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
end

local v10 = {
	Loadout = function(instance)
		return { (instance:FindFirstChild("Ignore")) }
	end,
	Inventory = function(instance)
		return { (instance:FindFirstChild("Ignore")) }
	end,
	Gamemodes = function(instance)
		local gamemodes = instance:FindFirstChild("Gamemodes")
		return { gamemodes and gamemodes:FindFirstChild("Prompt") }
	end,
	Store = function(instance)
		local children = {}

		for _, childName in { "CaseContent", "Gift", "CreatorCode", "CurrentConfirm" } do
			local child = instance:FindFirstChild(childName)

			if child then
				table.insert(children, child)
			end
		end

		return children
	end,
	Settings = function(folder)
		local descendants = {}

		for _, descendant in folder:GetDescendants() do
			if descendant.Name == "Share" or descendant.Name == "ChangeColor" then
				table.insert(descendants, descendant)
			end
		end

		return descendants
	end
}

local function getPageButtonForBack(selectedObject2)
	if not selectedObject2 then
		return nil
	end

	for childName, v11 in pairs(v10) do
		local guiObject = v7.Menu:FindFirstChild(childName)

		if not (guiObject and guiObject:IsA("GuiObject") and guiObject.Visible and selectedObject2:IsDescendantOf(guiObject)) then
			continue
		end

		for _, ancestor in ipairs(v11(guiObject)) do
			if ancestor and selectedObject2:IsDescendantOf(ancestor) then
				return nil
			end
		end

		return (getTopButton(childName))
	end

	return nil
end

local function autoJoinMatch()
	if flag or not IsTutorialMode() or (MenuState.IsInspectActive() or MenuState.IsCaseSceneActive()) then
		return
	end

	local state = GameState.GetState()

	if state == nil or state == "Game Ending" or state == "Map Voting" or not workspace:FindFirstChild("Map") then
		return
	end

	flag = true
	Top.openFrame("Play", true)
	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)

	if MenuSceneController.IsActive() then
		MenuSceneController.HideMenuScene(true, false)
	end
end

local function getStoreNewAlert() -- 2 equivalent calls inferred from this helper
	local topButton = getTopButton("Store")
	local newAlert = topButton and topButton:FindFirstChild("NewAlert")

	if newAlert and newAlert:IsA("GuiObject") then
		return newAlert
	end

	return nil
end

local function hasUnseenShopVersion() -- 2 equivalent calls inferred from this helper
	if DataController.IsDataLoaded(LocalPlayer) then
		return DataController.Get(LocalPlayer, "LastShopVersionViewed") ~= Constants.SHOP_VERSION
	end

	return false
end

local function updateStoreNewAlert() -- 1 equivalent call inferred from this helper
	local storeNewAlert = getStoreNewAlert() -- inferred equivalent call

	if storeNewAlert then
		storeNewAlert.Visible = hasUnseenShopVersion() -- inferred equivalent call
	end
end

fn = function()
	if not hasUnseenShopVersion() then -- inferred equivalent call
		return
	end

	local storeNewAlert = getStoreNewAlert() -- inferred equivalent call

	if storeNewAlert then
		storeNewAlert.Visible = false
	end

	Remotes.Player.MarkShopVersionViewed.Send()
end

local function shouldPreserveMenuFrame()
	if not v7 then
		return false
	end

	local currentScreen = MenuState.GetCurrentScreen()

	if not (v7.Menu.Visible and currentScreen and MenuState.IsPreservableScreen(currentScreen)) then
		return false
	end

	local child = v7.Menu:FindFirstChild(currentScreen)
	return child ~= nil and child.Visible
end

function Top.ResetToMainMenu()
	Profiler.mark("UI.Top.ResetToMainMenu")

	if MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() or not (v7 and v7:FindFirstChild("Menu")) then
		return
	end

	if shouldPreserveMenuFrame() then
		return
	end

	for _, frame in ipairs(v7.Menu:GetChildren()) do
		if not (frame:IsA("Frame") and frame.Name ~= "Top" and frame.Name ~= "Dashboard" and frame.Name ~= "Rewards") then
			continue
		end

		if not (frame.Name ~= "UpdateLog" and frame.Name ~= "TutorialPrompt") then
			continue
		end

		frame.Visible = false
	end

	local dashboard2 = v7.Menu:FindFirstChild("Dashboard")

	if dashboard2 then
		dashboard2.Visible = true
		v4 = dashboard2
	end

	local top = v7.Menu:FindFirstChild("Top")

	if top then
		top.Visible = true
	end

	setNavigationVisible(true)
	MenuState.SetBlurEnabled(false)
	v7.Menu.BackgroundTransparency = 1
	local pattern = v7.Menu:FindFirstChild("Pattern")

	if pattern then
		pattern.Visible = true
	end

	MenuState.SetScreen("Dashboard")

	if dashboard then
		tweenButton(dashboard, color)
	end

	dashboard = v6.Top.Buttons.Dashboard
	tweenButton(dashboard, color2)
end

function Top.ShowMainMenu()
	if MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() then
		return
	end

	MenuState.SetWantsMainMenu(true)
	CameraController.setForceLockOverride("Menu", true)

	if not LocalPlayer:GetAttribute("IsSpectating") then
		CameraController.setPerspective(true, true)
	end

	v7.Gameplay.Visible = false
	v7.Gameplay.Bottom.Visible = false
	v7.Menu.Visible = true
	Top.ResetToMainMenu()

	local function tryMenuScene() -- 1 equivalent call inferred from this helper
		if v7.Menu.Visible and not v7.Gameplay.Visible then
			local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
			MenuSceneController.ShowMenuScene()
		end
	end

	tryMenuScene() -- inferred equivalent call

	if LocalPlayer.Character then
		task.delay(0.15, tryMenuScene)
		task.delay(0.5, tryMenuScene)
	end
end

function Top.ShowMainMenuOverGameplay()
	if MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() then
		return
	end

	v3 = true
	CameraController.setForceLockOverride("Menu", true)

	if not LocalPlayer:GetAttribute("IsSpectating") then
		CameraController.setPerspective(true, true)
	end

	v7.Gameplay.Visible = false
	v7.Menu.Visible = true
	Top.ResetToMainMenu()
end

function Top.Initialize(p, p2)
	Profiler.mark("UI.Top.Initialize")
	v7 = p
	v6 = p2

	for _, v11 in { v6.Top.Buttons, v6.Bottom.Buttons } do
		for _, button in ipairs(v11:GetChildren()) do
			if not button:IsA("ImageButton") then
				continue
			end

			setupButton(button)
			ActivateButton(button)
			local v12 = button
			button.MouseButton1Click:Connect(function()
				MenuState.HoldNavigationSelection(nil)
				Top.openFrame(v12.Name, v12.Name == "Play")
			end)
		end
	end

	local buttons = v6.Top.Buttons
	y = buttons.Size.Y
	local blackmarket = buttons:FindFirstChild("Blackmarket")

	if blackmarket and blackmarket:IsA("GuiButton") and not Constants.BLACK_MARKET_ENABLED then
		blackmarket.Visible = false
	elseif blackmarket and blackmarket:IsA("GuiButton") then
		animateBlackmarketButton(blackmarket, function()
			return v7.Enabled and v7.Menu.Visible and v6.Visible and blackmarket.Visible
		end)
	end

	local flag3 = false

	local function queueTopButtonsFit() -- 1 equivalent call inferred from this helper
		if flag3 then
			return
		end

		flag3 = true
		task.defer(function()
			flag3 = false
			fitTopButtonsBesideTabs()
		end)
	end

	local store = v7.Menu:FindFirstChild("Store")
	local top = store and store:FindFirstChild("Top")
	local categories = top and top:FindFirstChild("Categories")

	if categories and categories:IsA("GuiObject") then
		categories:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueTopButtonsFit)
		categories:GetPropertyChangedSignal("AbsolutePosition"):Connect(queueTopButtonsFit)
		categories:GetPropertyChangedSignal("Visible"):Connect(queueTopButtonsFit)
	end

	buttons.Parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueTopButtonsFit)
	queueTopButtonsFit() -- inferred equivalent call
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Map" then
			task.delay(0.25, function()
				if v7.Menu.Visible or not TeamSelection.shouldUseMapCamera() then
					return
				end

				Top.UpdateBackground(child)
			end)
		end
	end)
end

function Top.Start()
	debug.setmemorycategory("UI.Top.Start")
	Profiler.mark("UI.Top.Start")
	dashboard = v6.Top.Buttons.Dashboard
	tweenButton(dashboard, color2)
	local pattern = v7.Menu:FindFirstChild("Pattern")
	v7.Menu.BackgroundTransparency = 1

	if pattern then
		pattern.Visible = false
	end

	if v7.Menu.Visible then
		CameraController.setForceLockOverride("Menu", true)
	end

	local function syncMenuAndTeamSelectionState()
		syncControlLockWithMenuVisibility()
		syncCameraWithTeamSelection()
	end

	v7.Menu:GetPropertyChangedSignal("Visible"):Connect(syncControlLockWithMenuVisibility)
	local gameplay = v7:FindFirstChild("Gameplay")
	local middle = gameplay and gameplay:FindFirstChild("Middle")
	local teamSelection = middle and middle:FindFirstChild("TeamSelection")
	local bottom = gameplay and gameplay:FindFirstChild("Bottom")

	if teamSelection and teamSelection:IsA("GuiObject") then
		teamSelection:GetPropertyChangedSignal("Visible"):Connect(syncMenuAndTeamSelectionState)
	end

	if bottom and bottom:IsA("GuiObject") then
		bottom:GetPropertyChangedSignal("Visible"):Connect(syncControlLockWithMenuVisibility)
	end

	syncControlLockWithMenuVisibility()
	local team = LocalPlayer:GetAttribute("Team")
	local v11 = team == "Counter-Terrorists" or team == "Terrorists"

	if not (LocalPlayer.Character or v11 or IsTutorialMode()) then
		if not CameraController.isForceLockOverrideActive() then
			CameraController.setForceLockOverride("Menu", true)
		end

		if not v7.Menu.Visible then
			v7.Menu.Visible = true
		end

		v7.Gameplay.Visible = false
		v7.Gameplay.Bottom.Visible = false
	end

	UserInputService.InputBegan:Connect(function(input, _)
		if not (v7 and v7.Menu.Visible) or (MenuState.IsInspectActive() or MenuState.IsCaseSceneActive()) then
			return
		end

		if LocalPlayer:GetAttribute("IsPlayerChatting") then
			return
		end

		local v12 = input.KeyCode == Enum.KeyCode.ButtonL1
		local v13 = input.KeyCode == Enum.KeyCode.ButtonR1

		if not (v12 or v13) then
			return
		end

		if MenuState.IsSelectionWithin(v6.Top.Buttons) then
			cycleUtilityButtons(v12)
			return
		end

		if MenuState.HandleBumperInput(v12) then
			return
		end

		local tabForBumper = getTabForBumper(getControllerCurrentTab(), v12) -- inferred equivalent call

		if tabForBumper then
			goToTab(tabForBumper, tabForBumper == "Play")
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.ButtonB or not (v7 and v7.Menu.Visible) then
			return
		end

		if
			MenuState.IsInspectActive()
			or MenuState.IsCaseSceneActive()
			or LocalPlayer:GetAttribute("IsPlayerChatting")
		then
			return
		end

		local selectedObject2 = GuiService.SelectedObject

		if selectedObject2 == nil and os.clock() - now < 0.1 then
			selectedObject2 = v5
		end

		local pageButtonForBack = getPageButtonForBack(selectedObject2)

		if not pageButtonForBack then
			return
		end

		task.defer(function()
			if CloseButtonRegistry.IsDoublePressed() then
				return
			end

			GuiService.SelectedObject = pageButtonForBack
			Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
		end)
	end)
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		v5 = selectedObject
		selectedObject = GuiService.SelectedObject
		now = os.clock()
	end)
	UserInputService.InputBegan:Connect(function(input, _)
		if not (v7 and v7.Menu.Visible) or (MenuState.IsInspectActive() or MenuState.IsCaseSceneActive()) then
			return
		end

		if
			LocalPlayer:GetAttribute("IsPlayerChatting")
			or input.UserInputType ~= Enum.UserInputType.Gamepad1
			or input.KeyCode ~= Enum.KeyCode.ButtonA
		then
			return
		end

		local topButton = getTopButton("Play")

		if not topButton then
			return
		end

		local selectedObject2 = GuiService.SelectedObject

		if selectedObject2 ~= topButton and not (selectedObject2 and selectedObject2:IsDescendantOf(topButton)) then
			return
		end

		Top.openFrame("Play", true)
	end)
	Top.openFrame("Dashboard")
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		if not (v7 and v7.Menu.Visible) then
			return
		end

		local selectedObject2 = GuiService.SelectedObject

		if MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() or not (v6 and selectedObject2) then
			return
		end

		local v12 = nil

		for _, v13 in ipairs(v9) do
			local topButton = getTopButton(v13)

			if not (topButton and (selectedObject2 == topButton or selectedObject2:IsDescendantOf(topButton))) then
				continue
			end

			v12 = topButton
			break
		end

		if not v12 then
			local topButton = getTopButton("Dashboard")

			if topButton and (selectedObject2 == topButton or selectedObject2:IsDescendantOf(topButton)) then
				v12 = topButton
			end
		end

		if v12 and dashboard ~= v12 then
			setButtonToggle(v12) -- inferred equivalent call
			Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
		end
	end)
	MenuState.OnScreenChanged:Connect(function(_, childName)
		if not childName then
			return
		end

		local frame = v7.Menu:FindFirstChild(childName)

		if frame and frame:IsA("Frame") then
			v4 = frame
		end

		local button = v6.Bottom.Buttons:FindFirstChild(childName) or v6.Top.Buttons:FindFirstChild(childName)

		if button and button:IsA("GuiButton") and dashboard ~= button then
			setButtonToggle(button) -- inferred equivalent call
		end
	end)
	LocalPlayer.CharacterAdded:Connect(function(_)
		Profiler.defer("UI.Top.CharacterAddedDeferred", function()
			local visible = v7.Menu.Visible
			local visible2 = v7.Gameplay.Middle.TeamSelection.Visible
			local isCaseSceneActive = MenuState.IsCaseSceneActive()
			local isInspectActive = MenuState.IsInspectActive()
			local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)
			local isActive = EndScreenController.IsActive()

			if not (visible or visible2 or isCaseSceneActive or isInspectActive or isActive) then
				CameraController.resetForceLockOverride()
				CameraController.setPerspective(true, false)
			end
		end)
	end)
	Observers.observeAttribute(LocalPlayer, "Team", function(p)
		if not IsPlayingTeam(p) then
			v3 = false
		end

		if p == "Spectators" then
			Top.CloseTeamSelection()
		end
	end)
	GameState.ListenToState(function(p, p2)
		if p2 == "Game Ending" or p2 == "Map Voting" then
			v3 = false
		end

		if MenuState.IsCaseSceneActive() then
			if p2 == "Game Ending" or p2 == "Map Voting" then
				v7.Gameplay.Bottom.Visible = false
				v7.Gameplay.Visible = false
			end
		else
			if MenuState.IsInspectActive() then
				return
			end

			if MenuState.IsTradeUpActive() then
				if p2 == "Game Ending" or p2 == "Map Voting" then
					v7.Gameplay.Bottom.Visible = false
					v7.Gameplay.Visible = false

					if not v7.Menu.Visible then
						CameraController.setForceLockOverride("Menu", true)
						v7.Menu.Visible = true
					end
				end
			else
				if p2 == "Game Ending" or p2 == "Map Voting" then
					if IsTutorialMode() then
						Top.ShowMainMenu()
						return
					end

					local EndScreenController = require(ReplicatedStorage.Controllers.EndScreenController)

					if EndScreenController.IsActive() then
						if MenuState.IsInspectActive() then
							Router.broadcastRouter("WeaponInspectCloseForGameEnd")
						end

						return
					else
						v7.Gameplay.Visible = false
						v7.Gameplay.Bottom.Visible = false

						if MenuState.IsInspectActive() then
							Router.broadcastRouter("WeaponInspectCloseForGameEnd")
						end

						if not shouldPreserveMenuFrame() then
							Top.ResetToMainMenu()
						end

						if not v7.Menu.Visible then
							CameraController.setForceLockOverride("Menu", true)
							v7.Menu.Visible = true
						end
					end
				end

				if p2 == "Map Voting" then
					if LocalPlayer:GetAttribute("FollowGamemode") or LocalPlayer:GetAttribute("IsSpectating") then
						if v7.Menu.Visible and (MenuState.WantsMainMenu() or shouldPreserveMenuFrame()) then
							return
						end

						Top.openFrame("Play")
						return
					elseif not (v7.Menu.Visible or shouldPreserveMenuFrame()) then
						Top.openFrame("Dashboard")
						Top.ToggleMenu()
					end
				end

				if (p == "Game Ending" or p == "Map Voting") and p2 ~= "Game Ending" and p2 ~= "Map Voting" then
					if IsTutorialMode() and v7.Menu.Visible then
						return
					end

					if p == "Map Voting" then
						if v7.Menu.Visible then
							return
						end

						if MenuState.WantsMainMenu() then
							Top.ResetToMainMenu()
							CameraController.setForceLockOverride("Menu", true)
							v7.Gameplay.Visible = false
							v7.Gameplay.Bottom.Visible = false
							v7.Menu.Visible = true
							return
						else
							local team2 = LocalPlayer:GetAttribute("Team")

							if not LocalPlayer.Character or not team2 or team2 == "Spectators" then
								MenuState.HideMenu()
								v7.Gameplay.Visible = true
								v7.Gameplay.Top.Visible = true
								TeamSelection.openFrame()
								return
							end
						end
					elseif v7.Menu.Visible and shouldPreserveMenuFrame() then
						return
					end

					Profiler.defer("UI.Top.StateTransitionDeferred", function()
						if MenuState.IsInspectActive() then
							return
						end

						local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)

						if MenuSceneController.IsActive() and not v7.Menu.Visible then
							if not shouldPreserveMenuFrame() then
								Top.ResetToMainMenu()
							end

							CameraController.setForceLockOverride("Menu", true)
							v7.Gameplay.Visible = false
							v7.Menu.Visible = true
						end
					end)
				end
			end
		end
	end)
	DataController.CreateListener(LocalPlayer, "LastShopVersionViewed", updateStoreNewAlert)
	updateStoreNewAlert() -- inferred equivalent call
	GameState.ListenToState(function()
		Profiler.defer("UI.Top.AutoJoinTutorialDeferred", autoJoinMatch)
	end)
	workspace:GetAttributeChangedSignal("ServerGamemode"):Connect(autoJoinMatch)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(autoJoinMatch)
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Map" then
			autoJoinMatch()
		end
	end)
	Profiler.defer("UI.Top.AutoJoinTutorialDeferred", autoJoinMatch)
	local tutorialActive = workspace:GetAttribute("TutorialActive") == true
	workspace:GetAttributeChangedSignal("TutorialActive"):Connect(function()
		local tutorialActive2 = workspace:GetAttribute("TutorialActive") == true

		if tutorialActive and not tutorialActive2 then
			Top.ShowMainMenu()
		end

		tutorialActive = tutorialActive2
	end)
end

return Top