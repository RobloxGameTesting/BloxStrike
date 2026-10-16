local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Router = require(ReplicatedStorage.Database.Security.Router)

local function onInput(p, _)
	if
		LocalPlayer:GetAttribute("IsPlayerChatting")
		or p ~= Enum.UserInputState.Begin
		or SpectateController.IsLocalPlayerDead()
	then
		return
	end

	local currentEquipped = InventoryController.getCurrentEquipped()

	if not currentEquipped then
		return
	end

	local skinInformation = Skins.GetSkinInformation(currentEquipped.Name, currentEquipped.Skin)

	if not skinInformation then
		return
	end

	local rarity = Rarities[skinInformation.rarity]
	local v = math.floor(rarity.Color.R * 255)
	local v2 = math.floor(rarity.Color.G * 255)
	local v3 = math.floor(rarity.Color.B * 255)

	if currentEquipped:drop() then
		Router.broadcastRouter(
			"CreateNotification",
			"Item Dropped",
			`You dropped your <font color = "rgb({v}, {v2}, {v3})"><b>{currentEquipped.Name:find("Zeus") and "Taser" or currentEquipped.Name} | {currentEquipped.Skin}</b></font>`,
			2
		)
	end
end

return table.freeze({
	Name = "Drop Weapon",
	Group = "Gameplay",
	Category = "Weapon Keys",
	Callback = onInput
})