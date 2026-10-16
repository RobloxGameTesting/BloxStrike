local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local LocalPlayer = Players.LocalPlayer
local bindPriority = Enum.ContextActionPriority.High.Value + 1
LocalPlayer:GetAttributeChangedSignal("IsPlayerChatting"):Connect(function()
	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		CharacterController.walk(false)
	end
end)

local function onInput(p, _)
	if
		LocalPlayer:GetAttribute("IsPlayerChatting")
		or not CharacterResolver.isAliveCharacter(CharacterResolver.getPlayerCharacter(LocalPlayer))
	then
		return
	end

	if DataController.Get(LocalPlayer, "Settings.Keyboard/Mouse.Keyboard & Mouse Settings.Walk Mode") == "Toggle" then
		if p == Enum.UserInputState.Begin then
			CharacterController.walk(not CharacterController.GetWalkState())
		end
	elseif p == Enum.UserInputState.Begin then
		CharacterController.walk(true)
	elseif p == Enum.UserInputState.End then
		CharacterController.walk(false)
	end
end

return table.freeze({
	Name = "Walk",
	Group = "Default",
	Category = "Movement Keys",
	BindPriority = bindPriority,
	Callback = onInput
})