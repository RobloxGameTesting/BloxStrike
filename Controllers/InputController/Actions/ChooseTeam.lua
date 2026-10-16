local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsPlayingTeam = require(ReplicatedStorage.Components.Common.IsPlayingTeam)
local LocalPlayer = Players.LocalPlayer
local TeamSelection = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.TeamSelection)

local function onInput(p, _)
	if LocalPlayer:GetAttribute("IsPlayerChatting") or p ~= Enum.UserInputState.Begin then
		return
	end

	local isSpectating = LocalPlayer:GetAttribute("IsSpectating")

	if not IsPlayingTeam(LocalPlayer:GetAttribute("Team")) and isSpectating ~= true then
		return
	end

	if isSpectating then
		TeamSelection.openFrame()
	elseif CharacterResolver.getLocalCharacter() then
		TeamSelection.ToggleTeamSelection()
	end
end

return table.freeze({
	Name = "Choose Team",
	Group = "Default",
	Category = "UI Keys",
	Callback = onInput
})