local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local LocalPlayer = Players.LocalPlayer
local Leaderboard = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Leaderboard)

local function onInput(p, _)
	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		return
	end

	if p == Enum.UserInputState.Begin then
		Leaderboard.openFrame()
	elseif p == Enum.UserInputState.End then
		Leaderboard.closeFrame()
	end
end

return table.freeze({
	Name = "Scoreboard",
	Group = "Default",
	Category = "UI Keys",
	Callback = onInput
})