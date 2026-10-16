local EndScreen = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local GetTimerFormat = require(ReplicatedStorage.Components.Common.GetTimerFormat)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Observers = require(ReplicatedStorage.Packages.Observers)
local v = nil
local v2 = nil
local v3 = nil
local v4 = nil

local function clearFrame(mapVote, p: string)
	for _, child in ipairs(mapVote:GetChildren()) do
		if child.ClassName == p then
			child:Destroy()
		end
	end
end

local function updateVotingFrame(p)
	local children = v2.MapVote:GetChildren()

	for _, button in ipairs(children) do
		if not button:IsA("ImageButton") then
			continue
		end

		local v5 = p and p[button.Name] or button:GetAttribute("Amount")

		if not v5 then
			continue
		end

		button.Main.Amount.Text = `<font color="rgb(219,199,126)">{v5}</font>/{#Players:GetPlayers()}`
		button:SetAttribute("Amount", v5)
	end
end

local function tweenVoteStroke(p, transparency: number, thickness: number)
	TweenService:Create(p.Main.UIStroke, TweenInfo.new(0.5), { Transparency = transparency }):Play()
	TweenService:Create(p.Main.UIStroke, TweenInfo.new(0.5), { Thickness = thickness }):Play()
end

local function cancelMapVoteBar() -- 1 equivalent call inferred from this helper
	if v4 then
		v4:Cancel()
		v4 = nil
	end
end

local function createVoteButton(i: number, childName)
	local child = ReplicatedStorage.Database.Custom.GameStats.Maps:WaitForChild(childName, 10)

	if not child then
		warn(`Failed to load map module for {childName} - map may not exist or hasn't replicated yet`)
		return
	end

	local module = require(child)

	if not (module and module.Icon) then
		warn(`Map {childName} is missing Icon property`)
		return
	end

	local clone = ReplicatedStorage.Assets.UI.EndScreen.VoteTemplate:Clone()
	clone.Main.Amount.Text = `<font color="rgb(219,199,126)">0</font>/{#Players:GetPlayers()}`
	clone.Main.Icon.Image = module.Icon
	clone.Parent = v2.MapVote
	clone.Main.Selection.Text = childName
	clone:SetAttribute("Amount", 0)
	clone.Title.Visible = i == 1
	clone.Voted.Visible = false
	clone.Name = childName
	clone.Button.MouseButton1Click:Connect(function()
		if v ~= childName then
			Remotes.Map.SubmitMapVote.Send(childName)
			tweenVoteStroke(clone, 0, 5.5)

			if v then
				tweenVoteStroke(v2.MapVote:FindFirstChild(v), 0.75, 1.5)
			end

			v = childName
		end
	end)
	clone.Button.MouseEnter:Connect(function()
		TweenService:Create(clone.Main.Icon.UIScale, TweenInfo.new(0.5), { Scale = 1.1 }):Play()
	end)
	clone.Button.MouseLeave:Connect(function()
		TweenService:Create(clone.Main.Icon.UIScale, TweenInfo.new(0.5), { Scale = 1 }):Play()
	end)
end

function EndScreen.CloseFrame()
	local visible = v2.Visible
	v2.Visible = false
	CameraController.setForceLockOverride("EndScreen", false)

	if visible then
		local team = LocalPlayer:GetAttribute("Team")

		if not (LocalPlayer.Character and team) or team == "Spectators" then
			local TeamSelection = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.TeamSelection)
			TeamSelection.openFrame()
			return
		end
	end

	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)

	if not (MenuSceneController.IsActive() or v3.Menu.Visible) then
		return
	end

	local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
	Top.ResetToMainMenu()

	if not v3.Menu.Visible then
		CameraController.setForceLockOverride("Menu", true)
		v3.Menu.Visible = true
	end

	v3.Gameplay.Visible = false
end

function EndScreen.Initialize(p, p2)
	v2 = p2
	v3 = p
	clearFrame(v2.MapVote, "ImageButton")
	Remotes.Map.StartMapVote.Listen(function(list)
		cancelMapVoteBar() -- inferred equivalent call
		clearFrame(v2.MapVote, "ImageButton")
		v = nil

		for i, v5 in ipairs(list) do
			createVoteButton(i, v5)
		end
	end)
	Remotes.Map.UpdateMapVote.Listen(updateVotingFrame)
	Remotes.Map.EndMapVote.Listen(function(_: string)
		if v4 then
			v4:Cancel()
			v4 = nil
		end

		EndScreen.CloseFrame()
	end)
	Observers.observePlayer(function()
		updateVotingFrame()
		return function()
			updateVotingFrame()
		end
	end)
	Observers.observeAttribute(workspace, "Timer", function(p3)
		v2.Top.Timer.Text = GetTimerFormat(p3)

		if GameState.GetState() == "Map Voting" and not v4 then
			local extra = v2.Top:FindFirstChild("Extra")

			if extra and p3 > 0 then
				extra.Size = UDim2.new(0, 0, extra.Size.Y.Scale, extra.Size.Y.Offset)
				local tween = TweenService:Create(extra, TweenInfo.new(p3 * 1.15, Enum.EasingStyle.Linear), {
					Size = UDim2.new(1, 0, extra.Size.Y.Scale, extra.Size.Y.Offset)
				})
				v4 = tween
				tween:Play()
			end
		end
	end)

	if GameState.GetState() == "Map Voting" then
		local v5 = false

		for _, button in ipairs(v2.MapVote:GetChildren()) do
			if not button:IsA("ImageButton") then
				continue
			end

			v5 = true
			break
		end

		if not v5 then
			Remotes.Map.RequestMapVote.Send()
		end
	end
end

return EndScreen