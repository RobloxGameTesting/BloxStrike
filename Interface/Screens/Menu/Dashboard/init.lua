local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local FormatDuration = require(ReplicatedStorage.Components.Common.FormatDuration)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local AnimateDashboardCard = require(ReplicatedStorage.Components.Common.InterfaceAnimations.AnimateDashboardCard)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Store = require(ReplicatedStorage.Interface.Screens.Menu.Store)
local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
local TutorialPrompt = require(ReplicatedStorage.Interface.Screens.Menu.TutorialPrompt)
local LocalPlayer = Players.LocalPlayer
local starterPack = nil
local currentBundle = nil
local v = nil
local EditMobile = require(script:WaitForChild("EditMobile"))
local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(201, 201, 201)
local color3 = Color3.fromRGB(50, 46, 46)
local color4 = Color3.fromRGB(50, 46, 46)
local v2 = nil

local function SetupNewsSection(news) -- 1 equivalent call inferred from this helper
	news.Visible = false
end

local function SetupFeaturedSection(featured)
	local container = featured.Container
	local v3 = {
		{ Frame = container.CurrentBundle, Destination = "Bundle" },
		{ Frame = container.StarterPack, Destination = "StarterPack" }
	}
	currentBundle = container.CurrentBundle
	starterPack = container.StarterPack
	local v4 = 1

	for i, v5 in ipairs(v3) do
		if not v5.Frame.Visible then
			continue
		end

		v4 = i
		break
	end

	local buttons = container.Bottom.Buttons
	local left = buttons.Left
	local right = buttons.Right

	local function IsPageAvailable(p: number) -- 3 equivalent calls inferred from this helper
		if v3[p].Destination == "StarterPack" then
			return not DataController.IsDataLoaded(LocalPlayer) or Store.IsStarterPackShown()
		end

		return true
	end

	local function FindAvailablePage(total: number, p: number)
		while total >= 1 and total <= #v3 do
			if IsPageAvailable(total) then -- inferred equivalent call
				return total
			else
				total += p
			end
		end

		return nil
	end

	local function UpdateFeaturedPage()
		if
			v3[v4].Destination == "StarterPack"
			and DataController.IsDataLoaded(LocalPlayer)
			and not Store.IsStarterPackShown()
		then
			v4 = FindAvailablePage(v4 + 1, 1) or FindAvailablePage(v4 - 1, -1) or v4
		end

		for i, v5 in ipairs(v3) do
			v5.Frame.Visible = IsPageAvailable(i) and i == v4 -- inferred equivalent call
		end

		left.ImageColor3 = FindAvailablePage(v4 - 1, -1) and color or color4
		right.ImageColor3 = FindAvailablePage(v4 + 1, 1) and color or color4

		for i = 1, #v3 do
			local frame = buttons:FindFirstChild((tostring(i)))

			if not (frame and frame:IsA("Frame")) then
				continue
			end

			frame.Visible = IsPageAvailable(i) -- inferred equivalent call
			frame.BackgroundColor3 = i == v4 and color2 or color3
		end
	end

	for k, v5 in { [left] = -1, [right] = 1 } do
		local v6 = v5
		k.MouseButton1Click:Connect(function()
			local availablePage = FindAvailablePage(v4 + v6, v6)

			if not availablePage then
				return
			end

			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			v4 = availablePage
			UpdateFeaturedPage()
		end)
	end

	for _, v5 in ipairs(v3) do
		local view = v5.Frame.Interact.View
		ActivateButton(view)
		local v6 = v5
		view.MouseButton1Click:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			Top.openFrame("Store")

			if MenuState.GetCurrentScreen() ~= "Store" then
				return
			end

			if v6.Destination == "StarterPack" then
				Store.OpenBundleSection()
			else
				Store.OpenFeaturedBundleSection()
			end
		end)
	end

	v = UpdateFeaturedPage
	UpdateFeaturedPage()
end

local function SetupToggleCollapse(guiObject, button, flag: boolean?)
	local textLabel = button:FindFirstChildOfClass("TextLabel")
	local v3 = false
	local scale = guiObject.Size.X.Scale
	local position = guiObject.Position
	local backgroundTransparency = guiObject.BackgroundTransparency
	local v4

	if flag then
		v4 = position.X.Scale - scale - 0.04
	else
		v4 = position.X.Scale + scale + 0.04
	end

	local udim = UDim2.new(v4, position.X.Offset, position.Y.Scale, position.Y.Offset)
	local v5 = flag and "<" or ">"
	local v6 = flag and ">" or "<"

	local function SetVisibleState(flag2: boolean)
		for _, child in guiObject:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = flag2
			elseif child:IsA("UIStroke") or child:IsA("UIGradient") or child:IsA("UIShadow") then
				child.Enabled = flag2
			end
		end

		guiObject.BackgroundTransparency = not flag2 and 1 or backgroundTransparency
	end

	local function UpdateCollapseState()
		if textLabel then
			local v7 = textLabel
			local text

			if v3 then
				text = v6
			else
				text = v5
			end

			v7.Text = text
		end

		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local position2

		if v3 then
			position2 = udim
		else
			position2 = position
		end

		local v7 = TweenService:Create(guiObject, tweenInfo, { Position = position2 })

		if v3 then
			v7.Completed:Once(function()
				SetVisibleState(false)
			end)
		else
			SetVisibleState(true)
		end

		v7:Play()
	end

	UpdateCollapseState()
	ActivateButton(button)
	button.Activated:Connect(function()
		v3 = not v3
		UpdateCollapseState()
	end)
end

local function SetupToggleCollapses(instance, flag: boolean?)
	for _, button in instance:QueryDescendants("#ToggleCollapsed") do
		if not button:IsA("GuiButton") then
			continue
		end

		local guiObject = button:FindFirstAncestorWhichIsA("GuiObject")

		if guiObject then
			SetupToggleCollapse(guiObject, button, flag)
		end
	end
end

local function SetupLeftDashboard(left) -- 1 equivalent call inferred from this helper
	SetupNewsSection(left:WaitForChild("News")) -- inferred equivalent call
	SetupFeaturedSection(left:WaitForChild("Featured"))
	SetupToggleCollapses(left, true)
end

local function SetupTutorialCard(tutorial)
	local button = tutorial:FindFirstChild("Button")

	if button then
		AnimateDashboardCard(tutorial, button)
		button.MouseButton1Click:Connect(TutorialPrompt.RequestTeleport)
	end

	local function updateVisibility() -- 1 equivalent call inferred from this helper
		tutorial.Visible = Constants.TUTORIAL_TELEPORT_ENABLED
			and not IsTutorialMode()
			and DataController.Get(LocalPlayer, "TutorialCompleted") ~= true
	end

	DataController.CreateListener(LocalPlayer, "TutorialCompleted", updateVisibility)
	workspace:GetAttributeChangedSignal("ServerGamemode"):Connect(updateVisibility)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(updateVisibility)
	updateVisibility() -- inferred equivalent call
end

local function UpdateStarterPackTimer()
	if not DataController.IsDataLoaded(LocalPlayer) then
		return
	end

	local v3

	if Store.IsStarterPackAvailable() then
		v3 = math.max(0, Store.GetStarterPackRemainingSeconds())

		if v3 <= 0 then
			v3 = Store.GetStarterPackWindowSeconds()
		end
	else
		v3 = 0
	end

	local text = FormatDuration(v3, "Never")

	if v then
		v()
	end

	if starterPack then
		starterPack.Extra.Title.Top.Timer.Text = text
	end
end

local function UpdateCurrentBundleTimer() -- 1 equivalent call inferred from this helper
	if currentBundle then
		currentBundle.Extra.Title.Top.Timer.Text = Store.GetFeaturedConsoleTimerText()
	end
end

local function SetupDashboardHeartbeat() -- 1 equivalent call inferred from this helper
	local v3 = 1
	RunServiceController.BindToHeartbeat("UI.Dashboard.NewsAndTimers", function(p: number)
		if not v2.Visible then
			v3 = 1
			return
		end

		v3 += p

		if v3 < 1 then
			return
		end

		v3 %= 1
		Profiler.mark("UI.Dashboard.Heartbeat")
		UpdateStarterPackTimer()
		UpdateCurrentBundleTimer() -- inferred equivalent call
	end)
end

local Dashboard = {}

function Dashboard.Initialize(p, p2)
	Profiler.mark("UI.Dashboard.Initialize")
	v2 = p2
	EditMobile.Initialize(p, v2)
	SetupLeftDashboard(v2.Left) -- inferred equivalent call
	local tutorial = v2:FindFirstChild("Tutorial")

	if tutorial and tutorial:IsA("Frame") then
		SetupTutorialCard(tutorial)
	end
end

function Dashboard.Start()
	debug.setmemorycategory("UI.Dashboard.Start")
	Profiler.mark("UI.Dashboard.Start")
	SetupDashboardHeartbeat() -- inferred equivalent call
end

return Dashboard