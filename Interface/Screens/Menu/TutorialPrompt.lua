local TutorialPrompt = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local LocalPlayer = Players.LocalPlayer
local v = nil
local v2 = nil
local v3 = false
local v4 = 0

local function isOwed()
	if not Constants.TUTORIAL_TELEPORT_ENABLED or IsTutorialMode() or not DataController.IsDataLoaded(LocalPlayer) then
		return false
	end

	return DataController.Get(LocalPlayer, "TutorialPrompted") ~= true
		and DataController.Get(LocalPlayer, "TutorialCompleted") ~= true
end

local function hidePrompt() -- 1 equivalent call inferred from this helper
	if v then
		v.Visible = false
	end
end

local function tryShowPrompt()
	if v3 or not (v and isOwed()) then
		return
	end

	if not v2.Menu.Visible or MenuState.IsInspectActive() or MenuState.IsCaseSceneActive() then
		return
	end

	local currentScreen = MenuState.GetCurrentScreen()

	if currentScreen ~= nil and currentScreen ~= "Dashboard" then
		return
	end

	v3 = true
	v.Visible = true
	Remotes.Player.MarkTutorialPrompted.Send()
end

function TutorialPrompt.IsPending()
	return v3 or isOwed()
end

function TutorialPrompt.RequestTeleport()
	if not Constants.TUTORIAL_TELEPORT_ENABLED then
		return
	end

	local now = os.clock()

	if now - v4 < 1 then
		return
	end

	v4 = now
	Remotes.Modes.SelectGamemode.Send("Tutorial")
end

function TutorialPrompt.Initialize(p, p2)
	v2 = p
	v = p2
	v.Visible = false
	local join = v:FindFirstChild("Join")

	if join then
		ActivateButton(join, true, v2)
		join.MouseButton1Click:Connect(TutorialPrompt.RequestTeleport)
	end

	local title = v:FindFirstChild("Title")
	local close = title and title:FindFirstChild("Close")

	if close then
		ActivateButton(close, true, v2)
		close.MouseButton1Click:Connect(hidePrompt)
	end
end

function TutorialPrompt.Start()
	DataController.CreateListener(LocalPlayer, "TutorialPrompted", tryShowPrompt)
	DataController.CreateListener(LocalPlayer, "TutorialCompleted", tryShowPrompt)
	v2.Menu:GetPropertyChangedSignal("Visible"):Connect(function()
		if v2.Menu.Visible then
			tryShowPrompt()
			return
		end

		hidePrompt() -- inferred equivalent call
	end)
	MenuState.OnScreenChanged:Connect(function(_, p)
		if p == "Dashboard" then
			tryShowPrompt()
		elseif v then
			v.Visible = false
		end
	end)
	tryShowPrompt()
end

return TutorialPrompt