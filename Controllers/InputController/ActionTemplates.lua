local ActionTemplates = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(script.Parent:WaitForChild("Types"))
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local HintController = require(ReplicatedStorage.Controllers.HintController)
local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local InspectController = require(ReplicatedStorage.Controllers.InspectController)
local EquipInventorySlot = require(ReplicatedStorage.Components.Common.UserInput.EquipInventorySlot)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Leaderboard = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Leaderboard)
local LocalPlayer = Players.LocalPlayer
local v = nil

local function action(name: string, group: string, category: string, fn)
	return table.freeze({ Name = name, Group = group, Category = category, Callback = fn })
end

local function weaponKey(name: string, fn)
	return action(name, "Gameplay", "Weapon Keys", function(p, _)
		if LocalPlayer:GetAttribute("IsPlayerChatting") or p ~= Enum.UserInputState.Begin then
			return
		end

		if CaseSceneController.IsActive() or BlackMarketSceneController.IsActive() or InspectController.IsActive() then
			return
		end

		fn()
	end)
end

function ActionTemplates.placeholder(name: string, category: string)
	return action(name, "Gameplay", category, function() end)
end

function ActionTemplates.equipSlot(name: string, p: number, flag: boolean?)
	return weaponKey(name, function()
		if flag then
			HintController:clearHint("Reload")
		end

		EquipInventorySlot(p)
	end)
end

function ActionTemplates.equipGrenade(name: string, p)
	return weaponKey(name, function()
		EquipInventorySlot(4, function(p2)
			return p[p2.Name] == true
		end)
	end)
end

function ActionTemplates.useEquipped(name: string, p: string, callback)
	return weaponKey(name, function()
		local currentEquipped = InventoryController.getCurrentEquipped()

		if currentEquipped then
			callback(currentEquipped)
			HintController:clearHint(p)
		end
	end)
end

function ActionTemplates.cycleWeapons(name: string, callback)
	return action(name, "Gameplay", "Weapon Keys", function(p, p2)
		if LocalPlayer:GetAttribute("IsPlayerChatting") or p ~= Enum.UserInputState.Begin then
			return
		end

		if
			MenuState.GetCurrentScreen()
			or CaseSceneController.IsActive()
			or BlackMarketSceneController.IsActive()
			or InspectController.IsActive()
			or Leaderboard.IsRightClickUnlockActive() and p2.UserInputType == Enum.UserInputType.MouseWheel
		then
			return
		end

		callback()
		HintController:clearHint("Reload")
	end)
end

function ActionTemplates.movement(name: string, p: string, p2: number)
	local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
	local controls = PlayerModule:GetControls()
	return action(name, "Default", "Movement Keys", function(p3, _)
		if
			LocalPlayer:GetAttribute("IsPlayerChatting")
			or not CharacterResolver.isAliveCharacter(CharacterResolver.getPlayerCharacter(LocalPlayer))
		then
			return
		end

		local activeController = controls.activeController

		if activeController and activeController.UpdateMovement then
			activeController[p] = p3 ~= Enum.UserInputState.Begin and 0 or p2
			activeController:UpdateMovement(p3)
		end
	end)
end

function ActionTemplates.chat(name: string, callback)
	return action(name, "Default", "Communication Options", function(p, _)
		if p ~= Enum.UserInputState.Begin then
			return
		end

		if not v then
			local Chat = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Chat)
			v = Chat
		end

		v.OpenChat(callback())
	end)
end

return ActionTemplates