local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local ViewmodelHand = require(ReplicatedStorage.Shared.ViewmodelHand)
require(script.Parent.Parent.Types)
return table.freeze({
	Name = "Switch Viewmodel Left/Right Hand",
	Group = "Gameplay",
	Category = "Weapon Keys",
	Callback = function(p)
		if
			p ~= Enum.UserInputState.Begin
			or (Players.LocalPlayer:GetAttribute("IsPlayerChatting") or SpectateController.IsSpectatingNow())
		then
			return
		end

		ViewmodelHand.Toggle()
	end
})