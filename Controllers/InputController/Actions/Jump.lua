local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local LocalPlayer = Players.LocalPlayer
local bindPriority = Enum.ContextActionPriority.High.Value + 1

local function onInput(p, p2)
	if p == Enum.UserInputState.Begin then
		if LocalPlayer:GetAttribute("IsPlayerChatting") then
			return
		end

		if p2.UserInputType == Enum.UserInputType.MouseWheel then
			CharacterController.jump()
		else
			CharacterController.jump(true)
		end
	elseif p == Enum.UserInputState.End or p == Enum.UserInputState.Cancel then
		if p2.UserInputType == Enum.UserInputType.MouseWheel then
			return
		else
			CharacterController.jump(false)
		end
	end
end

return table.freeze({
	Name = "Jump",
	Group = "Gameplay",
	Category = "Movement Keys",
	BindPriority = bindPriority,
	Callback = onInput
})