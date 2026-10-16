local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
require(script.Parent.Parent.Types)
local GamepadTrigger = require(script.Parent.Parent.GamepadTrigger)
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local InspectController = require(ReplicatedStorage.Controllers.InspectController)
local HintController = require(ReplicatedStorage.Controllers.HintController)
local Router = require(ReplicatedStorage.Database.Security.Router)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local v = table.find(GetUserPlatform(), "Mobile") and #GetUserPlatform() <= 1
local thread = nil
local identifier = nil
local v2 = false
local flag = false
local v3 = nil
local v4 = false
local frozen = table.freeze({ [Enum.KeyCode.ButtonR2] = true, [Enum.KeyCode.ButtonL2] = true })
RunService:BindToRenderStep("FireAction.SameFrameFire", Enum.RenderPriority.Camera.Value + 2, function()
	if not flag then
		return
	end

	flag = false
	local v5 = v3
	local v6 = v4
	v3 = nil
	v4 = false

	if not v5 then
		return
	end

	task.spawn(function()
		local currentEquipped = InventoryController.getCurrentEquipped()

		if not currentEquipped or currentEquipped.Identifier ~= v5.Identifier then
			v5.IsBurstShooting = false
			return
		end

		if v6 then
			v5:fireBurst()
			return
		end

		debug.profilebegin("FireAction.Shot")
		v5:shoot()

		if v5.Rounds and v5.Rounds <= 0 then
			debug.profilebegin("FireAction.ReloadHint")
			HintController:createHint("Reload")
			debug.profileend()
		end

		debug.profileend()
	end)
end)

local function cancelQueuedShot() -- 2 equivalent calls inferred from this helper
	if thread then
		task.cancel(thread)
		thread = nil
		identifier = nil
	end
end

local function rejectInput(p) -- 3 equivalent calls inferred from this helper
	if p == Enum.UserInputState.End then
		v2 = false
	end
end

local function onInput(p, p2)
	if v and p2.UserInputType == Enum.UserInputType.MouseButton1 or LocalPlayer:GetAttribute("IsPlayerChatting") then
		return
	end

	if
		SpectateController.IsSpectatingNow()
		and p == Enum.UserInputState.Begin
		and not SpectateController.IsControllerPress(p2)
	then
		SpectateController.RequestSwitch(-1)
	elseif
		SpectateController.IsLocalPlayerDead()
		or CaseSceneController.IsActive()
		or BlackMarketSceneController.IsActive()
		or InspectController.IsActive()
	then
		rejectInput(p) -- inferred equivalent call
	else
		local currentEquipped = InventoryController.getCurrentEquipped()

		if currentEquipped and CharacterResolver.getLocalCharacter() and GameState.GetState() ~= "Buy Period" then
			Router.broadcastRouter("Cancel Defuse Bomb")

			if p == Enum.UserInputState.Begin then
				local gamepadInput = GamepadTrigger.isGamepadInput(p2)
				local class = currentEquipped.Properties.Class
				local slot = currentEquipped.Properties.Slot

				if gamepadInput and v2 and class == "Weapon" and not currentEquipped.Properties.Automatic then
					return
				end

				if gamepadInput then
					v2 = true
				end

				if class == "C4" then
					currentEquipped:shoot()
					return
				end

				if slot == "Grenade" then
					currentEquipped:StartThrow()
					return
				end

				if class == "Weapon" then
					if currentEquipped.Properties.ShootingOptions == "Revolver" then
						cancelQueuedShot() -- inferred equivalent call
						currentEquipped:startRevolverCharge(GamepadTrigger.getInputBinding(p2))
						return
					else
						currentEquipped.IsFireHeld = true
						currentEquipped.FireInputBinding = GamepadTrigger.getInputBinding(p2)
					end
				end

				if
					not (currentEquipped.IsBurstShooting or currentEquipped.IsShooting)
					and currentEquipped.Properties.FireRate
					and tick() - currentEquipped.AlternativeSwitchTick > currentEquipped.Properties.FireRate
				then
					cancelQueuedShot() -- inferred equivalent call
					local isBurstShooting = currentEquipped.AlternativeShootingOption == "Burst"
					currentEquipped.IsBurstShooting = isBurstShooting

					if flag then
						currentEquipped.IsBurstShooting = false
						return
					end

					flag = true
					v3 = currentEquipped
					v4 = isBurstShooting
				elseif
					not currentEquipped.Properties.Automatic
					and currentEquipped.AlternativeShootingOption == "Default"
					and currentEquipped.IsShooting
					and identifier ~= currentEquipped.Identifier
				then
					if thread then
						task.cancel(thread)
					end

					local nextShotDue = currentEquipped.NextShotDue
					local v5 = not nextShotDue and 0 or math.max(0, nextShotDue - os.clock())

					if v5 <= 0.15 then
						identifier = currentEquipped.Identifier
						thread = task.delay(v5, function()
							RunService.Heartbeat:Wait()
							RunService.Heartbeat:Wait()
							thread = nil
							identifier = nil
							local currentEquipped2 = InventoryController.getCurrentEquipped()

							if
								not currentEquipped2
								or currentEquipped2.Identifier ~= currentEquipped.Identifier
								or currentEquipped2.Properties.Automatic
								or currentEquipped2.AlternativeShootingOption == "Burst"
							then
								return
							end

							if currentEquipped2.Rounds <= 0 then
								HintController:createHint("Reload")
							else
								currentEquipped2:shoot()
							end
						end)
					end
				end
			elseif p == Enum.UserInputState.End and currentEquipped.Properties.Class == "Weapon" then
				if currentEquipped.Properties.ShootingOptions == "Revolver" then
					if GamepadTrigger.isStillPressed(p2, frozen) then
						return
					end

					v2 = false
					local primary = currentEquipped.Properties.FireModes
						and currentEquipped.Properties.FireModes.Primary

					if not primary or primary.CancelOnRelease ~= false then
						currentEquipped:cancelRevolverCharge(false)
						return
					end

					currentEquipped.IsFireHeld = false
					currentEquipped.FireInputBinding = nil
				else
					v2 = false
					currentEquipped.IsFireHeld = false
					currentEquipped.FireInputBinding = nil
				end
			elseif p == Enum.UserInputState.End and currentEquipped.Properties.Class == "C4" then
				if GamepadTrigger.isStillPressed(p2, frozen) then
					return
				end

				v2 = false
				currentEquipped:cancel()
			elseif currentEquipped.Properties.Slot == "Grenade" and p == Enum.UserInputState.End then
				v2 = false

				if currentEquipped.ThrowStarted and not currentEquipped.ThrowFinished then
					currentEquipped:Throw("Far")
				end
			else
				rejectInput(p) -- inferred equivalent call
			end
		else
			rejectInput(p) -- inferred equivalent call
		end
	end
end

return table.freeze({
	Name = "Fire",
	Group = "Default",
	Category = "Weapon Keys",
	Callback = onInput
})