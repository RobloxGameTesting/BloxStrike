local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local LocalPlayer = Players.LocalPlayer
local BuyMenu = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.BuyMenu)

local function onInput(p, _)
	if LocalPlayer:GetAttribute("IsPlayerChatting") or p ~= Enum.UserInputState.Begin then
		return
	end

	if CharacterResolver.isAliveCharacter(CharacterResolver.getLocalCharacter()) then
		BuyMenu.toggleFrame()
	end
end

return table.freeze({
	Name = "Buy Menu",
	Group = "Gameplay",
	Category = "Weapon Keys",
	Callback = onInput
})