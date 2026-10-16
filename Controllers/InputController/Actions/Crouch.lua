local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local LocalPlayer = Players.LocalPlayer
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local bindPriority = Enum.ContextActionPriority.High.Value + 1
LocalPlayer:GetAttributeChangedSignal("IsPlayerChatting"):Connect(function()
	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		CharacterController.crouch(false)
	end
end)

local function onInput(p, _)
	if LocalPlayer:GetAttribute("IsPlayerChatting") then
		return
	end

	if p == Enum.UserInputState.Begin then
		CharacterController.crouch(true)
	elseif p == Enum.UserInputState.End then
		CharacterController.crouch(false)
	end
end

return table.freeze({
	Name = "Crouch",
	Group = "Gameplay",
	Category = "Movement Keys",
	BindPriority = bindPriority,
	Callback = onInput
})