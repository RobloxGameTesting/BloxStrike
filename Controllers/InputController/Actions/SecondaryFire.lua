local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Parent.Types)
local GamepadTrigger = require(script.Parent.Parent.GamepadTrigger)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local InspectController = require(ReplicatedStorage.Controllers.InspectController)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local _ = { ToggleScope = true }
local frozen = table.freeze({ [Enum.KeyCode.ButtonL2] = true })
local v = false

local function onInput(p, p2)
	if
		SpectateController.IsSpectatingNow()
		and p == Enum.UserInputState.Begin
		and not SpectateController.IsControllerPress(p2)
	then
		SpectateController.RequestSwitch(1)
	elseif
		SpectateController.IsLocalPlayerDead()
		or CaseSceneController.IsActive()
		or BlackMarketSceneController.IsActive()
		or InspectController.IsActive()
	then
		if p == Enum.UserInputState.End then
			v = false
		end
	else
		local currentEquipped = InventoryController.getCurrentEquipped()

		if
			not (CharacterResolver.getLocalCharacter() and currentEquipped)
			or currentEquipped.Properties.Slot == "Grenade" and GameState.GetState() == "Buy Period"
		then
			return
		end

		if p == Enum.UserInputState.Begin then
			if currentEquipped.Properties.ShootingOptions == "Revolver" then
				local trigger = GamepadTrigger.isTrigger(p2, frozen)

				if trigger and v then
					return
				end

				if trigger then
					v = true
				end

				currentEquipped:startRevolverSecondaryFire(GamepadTrigger.getInputBinding(p2))
			elseif currentEquipped.Properties.Class == "Grenade" then
				if GameState.GetState() ~= "Buy Period" then
					currentEquipped:StartThrow()
				end
			elseif currentEquipped.Properties.HasScope then
				currentEquipped:scope(true)
			elseif currentEquipped.Properties.HasSuppressor then
				if currentEquipped.IsSuppressed then
					currentEquipped:removeSuppressor()
				else
					currentEquipped:addSuppressor()
				end
			elseif currentEquipped.Properties.ShootingOptions == "Burst" then
				currentEquipped:updateFireMode()
			elseif currentEquipped.Properties.Type == "Equipment" and GameState.GetState() ~= "Buy Period" then
				currentEquipped:shoot(true)
			end
		elseif currentEquipped.Properties.ShootingOptions == "Revolver" and p == Enum.UserInputState.End then
			if GamepadTrigger.isStillPressed(p2, frozen) then
				return
			end

			v = false
			currentEquipped:stopRevolverSecondaryFire()
		else
			local _hasScope = currentEquipped.Properties.HasScope

			if currentEquipped.Properties.Slot == "Grenade" and p == Enum.UserInputState.End then
				v = false

				if GameState.GetState() == "Buy Period" then
					return
				end

				if currentEquipped.ThrowStarted and not currentEquipped.ThrowFinished then
					currentEquipped:Throw("Near")
				end
			elseif p == Enum.UserInputState.End then
				v = false
			end
		end
	end
end

return table.freeze({
	Name = "Secondary Fire",
	Group = "Default",
	Category = "Weapon Keys",
	Callback = onInput
})