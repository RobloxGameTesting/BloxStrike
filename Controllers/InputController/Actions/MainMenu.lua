local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local IsPlayingTeam = require(ReplicatedStorage.Components.Common.IsPlayingTeam)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local LocalPlayer = Players.LocalPlayer
local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)

local function onInput(p, p2)
	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		return
	end

	if p2.KeyCode == Enum.KeyCode.ButtonB then
		if
			p ~= Enum.UserInputState.Begin
			or (CloseButtonRegistry.CloseFrame() or CloseButtonRegistry.IsDoublePressed())
		then
			return
		end
	end

	if IsTutorialMode() then
		return
	end

	if
		(IsPlayingTeam(LocalPlayer:GetAttribute("Team")) or LocalPlayer:GetAttribute("IsSpectating") == true)
		and p == Enum.UserInputState.Begin
	then
		Top.ToggleMenu()
	end
end

return table.freeze({
	Name = "Main Menu",
	Group = "Default",
	Category = "UI Keys",
	Callback = onInput
})