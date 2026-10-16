local GameDashboard = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local Votekick = require(ReplicatedStorage.Database.Custom.GameStats.Settings.Votekick)
local LocalPlayer = Players.LocalPlayer
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local TeamSelection = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.TeamSelection)
local v = nil
local v2 = nil

local function ClearFrame(container)
	for _, frame in ipairs(container:GetChildren()) do
		if frame:IsA("Frame") then
			frame:Destroy()
		end
	end
end

local function IsActiveTeamPlayer(instance) -- 1 equivalent call inferred from this helper
	return Votekick.GetActiveTeam(instance:GetAttribute("Team")) ~= nil
end

local function GetActiveTeamPlayerCount()
	local count = 0

	for _, v3 in ipairs(Players:GetPlayers()) do
		if IsActiveTeamPlayer(v3) then -- inferred equivalent call
			count += 1
		end
	end

	return count
end

function GameDashboard.PlayerAdded(player)
	if LocalPlayer == player or Votekick.GetActiveTeam(player:GetAttribute("Team")) == nil then
		return
	end

	if not v2.Menu.VoteKick.Container:FindFirstChild((tostring(player.UserId))) then
		local clone = ReplicatedStorage.Assets.UI.VoteKick.PlayerTemplate:Clone()
		clone.PlayerIcon.Image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=420&h=420`
		clone.PlayerInfo.Username.Text = `@{player.Name}`
		clone.PlayerInfo.Nickname.Text = player.DisplayName
		clone.Parent = v2.Menu.VoteKick.Container
		clone.Name = tostring(player.UserId)
		clone.MouseButton1Click:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			Remotes.VoteKick.CallVote.Send((tostring(player.UserId)))
			v2.Menu.VoteKick.Visible = false
		end)
	end
end

function GameDashboard.RefreshVoteKickEntries()
	ClearFrame(v2.Menu.VoteKick.Container)

	for _, v3 in ipairs(Players:GetPlayers()) do
		GameDashboard.PlayerAdded(v3)
	end
end

function GameDashboard.OpenChooseTeam()
	local isSpectating = LocalPlayer:GetAttribute("IsSpectating")
	local team = LocalPlayer:GetAttribute("Team")

	if team ~= "Counter-Terrorists" and team ~= "Terrorists" and isSpectating ~= true then
		return
	end

	if isSpectating then
		TeamSelection.openFrame()
	elseif LocalPlayer.Character then
		TeamSelection.ToggleTeamSelection()
	end
end

function GameDashboard.Initialize(p, p2)
	v2 = p
	v = p2
	GameDashboard.RefreshVoteKickEntries()
	Players.PlayerAdded:Connect(function(player)
		GameDashboard.PlayerAdded(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local child = v2.Menu.VoteKick.Container:FindFirstChild((tostring(player.UserId)))

		if child then
			child:Destroy()
		end
	end)
end

function GameDashboard.Start()
	ActivateButton(v2.Menu.VoteKick.Buttons.Close)
	CloseButtonRegistry.Add(v2.Menu.VoteKick, v2.Menu.VoteKick.Buttons.Close, function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		v2.Menu.VoteKick.Visible = false
	end)
	ActivateButton(v.ChooseTeam)
	v.ChooseTeam.MouseButton1Click:Connect(function()
		GameDashboard.OpenChooseTeam()
	end)
	ActivateButton(v.VoteKick)
	v.VoteKick.MouseButton1Click:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		local voteKick = v2.Menu:FindFirstChild("VoteKick")

		if not voteKick then
			return
		end

		local activeTeam = Votekick.GetActiveTeam(LocalPlayer:GetAttribute("Team"))

		if LocalPlayer:GetAttribute("IsSpectating") and not activeTeam then
			Router.broadcastRouter(
				"CreateMenuNotification",
				"Error",
				"You cannot vote kick while spectating as a spectator."
			)
			return
		end

		if not activeTeam then
			Router.broadcastRouter("CreateMenuNotification", "Error", "You must be on a team to start a vote kick.")
			return
		end

		local level = DataController.Get(LocalPlayer, "Level")
		local level2

		if typeof(level) == "table" then
			level2 = tonumber(level.Level)
		end

		if not level2 then
			Router.broadcastRouter(
				"CreateMenuNotification",
				"Error",
				"Your data is still loading. Please try again in a moment."
			)
			return
		end

		if level2 < Votekick.MIN_LEVEL then
			Router.broadcastRouter(
				"CreateMenuNotification",
				"Error",
				`You need to be level {Votekick.MIN_LEVEL} to vote kick players.`
			)
			return
		end

		if GetActiveTeamPlayerCount() < Votekick.MINIMUM_ACTIVE_PLAYERS then
			Router.broadcastRouter("CreateMenuNotification", "Error", "Not enough active players to start a vote kick.")
			return
		end

		pcall(function()
			GameDashboard.RefreshVoteKickEntries()
		end)
		voteKick.Visible = true
	end)
end

return GameDashboard