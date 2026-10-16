local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Sound = require(ReplicatedStorage.Classes.Sound)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
require(ReplicatedStorage.Database.Custom.Types)
local LocalPlayer = Players.LocalPlayer
local v = {}
local flag = false
local v2 = nil

local function formatMVPReason(reason: string?) -- 1 equivalent call inferred from this helper
	if reason and reason ~= "Unknown" then
		return `MVP | {reason}`
	end

	return "MVP"
end

local function arePlayersAliveOnBothTeams()
	local count = 0
	local count2 = 0

	for _, v3 in ipairs(Players:GetPlayers()) do
		local team = v3:GetAttribute("Team")

		if not ((team == "Counter-Terrorists" or team == "Terrorists") and v3:GetAttribute("IsSpectating") ~= true and CharacterResolver.isAlivePlayer(v3)) then
			continue
		end

		if team == "Counter-Terrorists" then
			count2 += 1
		else
			count += 1
		end
	end

	return count2 > 0 and count > 0
end

local function stopMVPMusic()
	local mvp = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MVP")

	if mvp and mvp:IsA("Sound") then
		mvp:Stop()
		mvp:Destroy()
	end

	v2 = nil
end

local function getMVPVolumeMultiplier() -- 2 equivalent calls inferred from this helper
	return (DataController.Get(LocalPlayer, "Settings.Audio.Music.MVP Volume") or 50) / 50
end

local function getMasterVolumeMultiplier() -- 2 equivalent calls inferred from this helper
	return (DataController.Get(LocalPlayer, "Settings.Audio.Audio.Master Volume") or 100) / 100
end

local function updateMVPMusicVolume()
	if not (v2 and v2.Parent) then
		return
	end

	local mvpVolumeMultiplier = getMVPVolumeMultiplier() -- inferred equivalent call
	local masterVolumeMultiplier = getMasterVolumeMultiplier() -- inferred equivalent call
	local baseVolume = v2:GetAttribute("BaseVolume") or v2.Volume
	v2.Volume = baseVolume * mvpVolumeMultiplier * masterVolumeMultiplier
end

local function playMVPMusic()
	if MenuState.GetCurrentScreen() ~= nil then
		return
	end

	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local mvp = playerGui:FindFirstChild("MVP")

	if
		mvp and mvp:IsA("Sound") and mvp.IsPlaying
		or DataController.Get(LocalPlayer, "Settings.Audio.Other.Mute MVP Music when players on both teams are alive") == true
		and arePlayersAliveOnBothTeams()
	then
		return
	end

	local mvpVolumeMultiplier = getMVPVolumeMultiplier() -- inferred equivalent call
	v2 = Sound.new("Round"):play({ Parent = playerGui, Name = "MVP" }, mvpVolumeMultiplier)

	if v2 then
		local masterVolumeMultiplier = getMasterVolumeMultiplier() -- inferred equivalent call
		local volume = v2.Volume

		if mvpVolumeMultiplier > 0 and masterVolumeMultiplier > 0 then
			volume = volume / (mvpVolumeMultiplier * masterVolumeMultiplier) or volume
		end

		v2:SetAttribute("BaseVolume", volume)
		v2.Destroying:Once(function()
			v2 = nil
		end)
	end
end

local function hideAllRoundWonAndMVPFrames()
	for _, v3 in v do
		v3.roundWonFrame.Visible = false

		if v3.playerMVPCTFrame then
			v3.playerMVPCTFrame.Visible = false
		end

		if v3.playerMVPTFrame then
			v3.playerMVPTFrame.Visible = false
		end
	end
end

local function updateMVPFrame(playerMVPCTFrame, text: string, playerName: string)
	local mvp = playerMVPCTFrame:FindFirstChild("MVP")
	local text2 = mvp and mvp:FindFirstChild("Text")

	if text2 then
		text2.Text = text
	end

	local name = playerMVPCTFrame:FindFirstChild("Name")

	if name then
		name.Text = playerName
	end

	local player = playerMVPCTFrame:FindFirstChild("Player")
	local player2 = player and player:FindFirstChild("Player")
	local v3 = player2 and Participants.FromName(playerName)

	if player2 and v3 then
		player2.Image = Participants.HeadshotImage(v3, 420)
	end
end

local function onRoundWinner(p)
	local team = LocalPlayer:GetAttribute("Team")

	for _, v3 in v do
		local roundWonFrame = v3.roundWonFrame
		roundWonFrame.Visible = p == v3.winningTeam and team == p
	end
end

local function onRoundMVP(data)
	if not (data and data.Team and data.PlayerName and data.Reason) then
		return
	end

	local team = data.Team
	local playerName = data.PlayerName
	local reason = data.Reason

	if team ~= "Counter-Terrorists" and team ~= "Terrorists" or not Participants.FromName(playerName) then
		return
	end

	local text = formatMVPReason(reason) -- inferred equivalent call
	local v3 = team == "Counter-Terrorists"

	for _, v4 in v do
		local playerMVPCTFrame

		if v3 then
			playerMVPCTFrame = v4.playerMVPCTFrame
		else
			playerMVPCTFrame = v4.playerMVPTFrame
		end

		local playerMVPTFrame

		if v3 then
			playerMVPTFrame = v4.playerMVPTFrame
		else
			playerMVPTFrame = v4.playerMVPCTFrame
		end

		if not playerMVPCTFrame then
			continue
		end

		updateMVPFrame(playerMVPCTFrame, text, playerName)
		playerMVPCTFrame.Visible = true

		if playerMVPTFrame then
			playerMVPTFrame.Visible = false
		end

		playMVPMusic()
	end
end

local function ensureListenersInitialized()
	if flag then
		return
	end

	flag = true
	DataController.CreateListener(LocalPlayer, "Settings.Audio.Audio.Master Volume", updateMVPMusicVolume)
	DataController.CreateListener(LocalPlayer, "Settings.Audio.Music.MVP Volume", updateMVPMusicVolume)
	GameState.ListenToState(function(p, p2)
		if p == "Intermission" and p2 == "Buy Period" or p2 == "Round In Progress" then
			hideAllRoundWonAndMVPFrames()
			local mvp = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("MVP")

			if mvp and mvp:IsA("Sound") then
				mvp:Stop()
				mvp:Destroy()
			end

			v2 = nil
		end
	end)
	Remotes.UI.RoundWinner.Listen(onRoundWinner)
	Remotes.UI.RoundMVP.Listen(onRoundMVP)
end

return {
	create = function(winningTeam: string)
		return {
			Initialize = function(p, roundWonFrame)
				v[winningTeam] = {
					winningTeam = winningTeam,
					roundWonFrame = roundWonFrame,
					playerMVPCTFrame = p.Gameplay.Middle:FindFirstChild("PlayerMVPCT"),
					playerMVPTFrame = p.Gameplay.Middle:FindFirstChild("PlayerMVPT")
				}
				ensureListenersInitialized()
			end
		}
	end
}