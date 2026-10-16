local createVector = vector.create
local Weapon = {}
Weapon.__index = Weapon
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
require(script:WaitForChild("Types"))
local WeaponComponent = require(ReplicatedStorage.Classes.WeaponComponent)
local Sound = require(ReplicatedStorage.Classes.Sound)
local Camera = require(ReplicatedStorage.Components.Common.VFXLibary.CreateMuzzleFlash.Camera)
local CreateZeusBeam = require(ReplicatedStorage.Components.Common.VFXLibary.CreateZeusBeam)
local CreateBloodSplatter = require(ReplicatedStorage.Components.Common.VFXLibary.CreateBloodSplatter)
local CreateMarker = require(ReplicatedStorage.Components.Common.VFXLibary.CreateMarker)
local CreateImpact = require(ReplicatedStorage.Components.Common.VFXLibary.CreateImpact)
local CreateTracer = require(ReplicatedStorage.Components.Common.VFXLibary.CreateTracer)
local BreakGlass = require(ReplicatedStorage.Components.Common.VFXLibary.BreakGlass)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local GetCharacterVelocity = require(ReplicatedStorage.Components.Common.GetCharacterVelocity)
local PlayerHitPrediction = require(ReplicatedStorage.Components.Common.PlayerHitPrediction)
local ReplicateCharacterAction = require(ReplicatedStorage.Components.Common.ReplicateCharacterAction)
local GetWeaponCameraKick = require(ReplicatedStorage.Components.Common.GetWeaponCameraKick)
local WeaponTimings = require(ReplicatedStorage.Components.Common.WeaponTimings)
local HapticsController = require(ReplicatedStorage.Controllers.HapticsController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local SoundController = require(ReplicatedStorage.Controllers.SoundController)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local HintController = require(ReplicatedStorage.Controllers.HintController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local Bullet = require(script.Classes.Bullet)
local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local other = Sound.new("Other")
local v = { 37, 60 }
local v2 = { Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2 }
local v3 = { Enum.UserInputType.MouseButton2, Enum.KeyCode.ButtonL2 }
local vipInfiniteAmmoEnabled = workspace:GetAttribute("VIPInfiniteAmmoEnabled") == true
workspace:GetAttributeChangedSignal("VIPInfiniteAmmoEnabled"):Connect(function()
	vipInfiniteAmmoEnabled = workspace:GetAttribute("VIPInfiniteAmmoEnabled") == true
end)
local modulesByName = {}

for _, moduleScript in ipairs(ReplicatedStorage.Database.Custom.Weapons:GetChildren()) do
	if not moduleScript:IsA("ModuleScript") then
		continue
	end

	local name = moduleScript.Name
	local module = require(moduleScript)
	modulesByName[name] = module
end

local function botVictimKey(instance)
	local instanceModel = instance and instance:FindFirstAncestorOfClass("Model")
	local combatantId

	if instanceModel and instanceModel:GetAttribute("Bot") == true then
		combatantId = instanceModel:GetAttribute("CombatantId")
	end

	if typeof(combatantId) == "number" then
		return (Participants.BotKey(combatantId))
	end

	return nil
end

local function isPlayer(instance)
	local instanceModel = instance and instance:FindFirstAncestorOfClass("Model")
	return instanceModel ~= nil
		and (CharacterResolver.getPlayerFromCharacter(instanceModel) ~= nil or (instanceModel:GetAttribute("Bot") == true or CharacterResolver.isTutorialDummy(instanceModel)))
end

local function isEquippedLocal(object) -- 3 equivalent calls inferred from this helper
	return not object.IsDestroyed and object.IsEquipped == true
end

local function isJustEquipped(object) -- 6 equivalent calls inferred from this helper
	return tick() - object.WeaponEquippedTick <= WeaponTimings.EQUIP_ACTION_LOCKOUT
end

local function getEquipPulloutDuration(object) -- 2 equivalent calls inferred from this helper
	local animation = object.Viewmodel.Animation:getAnimation("Equip")
	local pulloutSeconds = WeaponTimings.PulloutSeconds
	local v4

	if animation then
		v4 = animation.Length
	end

	return pulloutSeconds(v4)
end

local function isLocalPlayerDefusing() -- 2 equivalent calls inferred from this helper
	return LocalPlayer:GetAttribute("IsDefusingBomb") == true
		or LocalPlayer:GetAttribute("IsLocallyDefusingBomb") == true
end

local function clearFireInputState(p) -- 5 equivalent calls inferred from this helper
	p.IsFireHeld = false
	p.FireInputBinding = nil
	p.IsAlternativeFireHeld = false
	p.AlternativeFireInputBinding = nil
	p.HasPendingChargeRequest = false
end

local function cancelThreadField(p, p2: string) -- 15 equivalent calls inferred from this helper
	local v4 = p[p2]

	if v4 then
		task.cancel(v4)
		p[p2] = nil
	end
end

local function disconnectField(p, p2: string) -- 5 equivalent calls inferred from this helper
	local connection = p[p2]

	if connection and connection.Connected then
		connection:Disconnect()
	end

	p[p2] = nil
end

local function refreshHeldBinding(object, p: string, p2: string) -- 3 equivalent calls inferred from this helper
	local v4 = object[p2]

	if object[p] == true and v4 and not InputController.isBindingPressed(v4) then
		object[p] = false
		object[p2] = nil
	end

	return object[p] == true
end

local function playOtherSound(name: string) -- 5 equivalent calls inferred from this helper
	return other:play({ Parent = LocalPlayer.PlayerGui, Name = name })
end

local function setSniperScoped(object, isSniperScoped: boolean) -- 4 equivalent calls inferred from this helper
	if object.Name == "SSG 08" or object.Name == "AWP" then
		object.IsSniperScoped = isSniperScoped

		if object.Name == "AWP" and object.Player then
			object.Player:SetAttribute("IsSniperScoped", isSniperScoped)
		end
	end
end

local function restoreDefaultFovUnlessSceneActive()
	local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
	local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)

	if not (CaseSceneController.IsActive() or MenuSceneController.IsActive() or BlackMarketSceneController.IsActive()) then
		CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
	end
end

local function getPressedActionBinding(p: string, list)
	local actionKeybinds = InputController.getActionKeybinds(p)

	for _, actionKeybind in ipairs(actionKeybinds) do
		if InputController.isBindingPressed(actionKeybind) then
			return actionKeybind
		end
	end

	if list and #actionKeybinds == 0 then
		for _, v4 in ipairs(list) do
			if InputController.isBindingPressed(v4) then
				return v4
			end
		end
	end

	return nil
end

local function isRevolverWeapon(p) -- 9 equivalent calls inferred from this helper
	return p.Properties.ShootingOptions == "Revolver"
end

local function getRevolverFireMode(p, p2) -- 3 equivalent calls inferred from this helper
	local fireModes = p.Properties.FireModes

	if fireModes then
		return p2 == "Secondary" and fireModes.Secondary or fireModes.Primary
	end

	return nil
end

local function getActiveFireRate(p, p2) -- 3 equivalent calls inferred from this helper
	local revolverFireMode = getRevolverFireMode(p, p2) -- inferred equivalent call
	return revolverFireMode and revolverFireMode.FireRate or p.Properties.FireRate or 0.1
end

local function applyActiveSpreadProfile(p, p2) -- 1 equivalent call inferred from this helper
	if not p.Bullet then
		return
	end

	local revolverFireMode = getRevolverFireMode(p, p2) -- inferred equivalent call
	local spread = revolverFireMode and revolverFireMode.Spread or p.Properties.Spread
	p.Bullet:setSpreadConfig(spread)
end

local function buildActiveRecoilPattern(p, p2)
	local recoil = p.Properties.Recoil

	if not recoil then
		return nil
	end

	local properties = p.Properties

	if isRevolverWeapon(p) and p2 then -- inferred equivalent call
		properties = table.clone(p.Properties)
		properties.FireRate = getActiveFireRate(p, p2) -- inferred equivalent call
	end

	return recoil.Pattern(properties)
end

local function applyActiveRecoilProfile(p, p2)
	local recoil = p.Recoil

	if not recoil then
		return
	end

	local v4 = isRevolverWeapon(p) and p2 or "Default" -- inferred equivalent call
	local activeFireRate = getActiveFireRate(p, p2) -- inferred equivalent call
	local v5 = recoil.Functions[v4]

	if not v5 then
		v5 = buildActiveRecoilPattern(p, p2)

		if not v5 then
			return
		end

		recoil.Functions[v4] = v5
	end

	local activeFireRate2 = recoil.ActiveFireRate

	if activeFireRate2 > 0 and activeFireRate > 0 and activeFireRate2 ~= activeFireRate then
		recoil.Time = recoil.Time / activeFireRate2 * activeFireRate
	end

	recoil.Function = v5
	recoil.ActiveFireRate = activeFireRate
end

local function applyActiveWeaponModeProfiles(p, p2) -- 4 equivalent calls inferred from this helper
	applyActiveSpreadProfile(p, p2) -- inferred equivalent call
	applyActiveRecoilProfile(p, p2)
end

local function applyRevolverRestingWeaponModeProfiles(p) -- 4 equivalent calls inferred from this helper
	if isRevolverWeapon(p) then -- inferred equivalent call
		applyActiveWeaponModeProfiles(p, "Secondary") -- inferred equivalent call
	end
end

local function applyRevolverChargeStartSpread(p, p2)
	if not (p.Bullet and p2 and p2.ChargeStartSpread) then
		return
	end

	local spread = p2.Spread or p.Properties.Spread

	if not spread then
		return
	end

	p.Bullet:setBaseSpreadForConfig(p2.ChargeStartSpread, spread)
end

local function startRechargeTimer(object)
	local rechargeTime = object.Properties.RechargeTime
	local rounds = object.Properties.Rounds

	if not (rechargeTime and rounds) then
		return
	end

	cancelThreadField(object, "RechargeThread") -- inferred equivalent call

	if vipInfiniteAmmoEnabled then
		object.Rounds = rounds
		object.RechargeStartTime = nil
	else
		if rounds <= object.Rounds then
			object.RechargeStartTime = nil
			return
		end

		local serverTimeNow = workspace:GetServerTimeNow()
		local identifier = object.Identifier
		local rechargeStartTime = object.RechargeStartTime or serverTimeNow
		local v4 = math.max(rechargeTime - math.max(serverTimeNow - rechargeStartTime, 0), 0)
		object.RechargeStartTime = rechargeStartTime

		if v4 <= 0 then
			object.Rounds = rounds
			object.RechargeStartTime = nil
		else
			object.RechargeThread = task.delay(v4, function()
				if object.IsDestroyed or object.Identifier ~= identifier then
					return
				end

				object.RechargeThread = nil
				object.Rounds = rounds
				object.RechargeStartTime = nil
			end)
		end
	end
end

local function resolveFireAnimationNames(p, p2: string, p3: string, p4)
	local revolverFireMode = getRevolverFireMode(p, p4) -- inferred equivalent call

	if not revolverFireMode then
		return p2, p3
	end

	local animation = revolverFireMode.Animation

	if animation and p.Viewmodel and p.Viewmodel.Animation then
		if not p.Viewmodel.Animation:getAnimation(animation) then
			animation = p2
		end
	else
		animation = p2
	end

	local characterAnimation = revolverFireMode.CharacterAnimation

	if characterAnimation and p.CharacterAnimator then
		if not p.CharacterAnimator:getAnimation(characterAnimation) then
			characterAnimation = p3
		end
	else
		characterAnimation = p3
	end

	return animation, characterAnimation
end

local function clearRevolverChargeTracking(p) -- 2 equivalent calls inferred from this helper
	cancelThreadField(p, "ChargeThread") -- inferred equivalent call
	disconnectField(p, "ChargeShootConnection") -- inferred equivalent call
end

local function resetRevolverChargeState(p) -- 2 equivalent calls inferred from this helper
	clearRevolverChargeTracking(p) -- inferred equivalent call
	p.HasPendingChargeRequest = false
	p.IsChargeFiring = false
	p.ChargeStartTick = 0
	p.CurrentWalkSpeedOverride = nil
end

local function stopRevolverChargeAnimation(data, flag: boolean?)
	if not (data.Viewmodel and data.Viewmodel.Animation and data.CharacterAnimator) then
		return
	end

	local fireAnimationNames, v4 = resolveFireAnimationNames(data, "Shoot", "Shoot", "Primary")
	data.Viewmodel.Animation:cancelCrossfade()
	data.Viewmodel.Animation:stop(fireAnimationNames)
	data.CharacterAnimator:stop(v4)

	if flag ~= false and data.IsEquipped then
		data.Viewmodel.Animation:play("Idle")
		data.CharacterAnimator:play("Idle")
	end
end

local function completeRevolverChargeShot(object)
	if object.IsDestroyed or not (object.IsEquipped and object.IsChargeFiring) then
		return
	end

	local localCharacter = CharacterResolver.getLocalCharacter()
	local v4 = not localCharacter or localCharacter:GetAttribute("Dead")

	if
		v4
		or GameState.GetState() == "Buy Period"
		or LocalPlayer:GetAttribute("IsDefusingBomb") == true
		or LocalPlayer:GetAttribute("IsLocallyDefusingBomb") == true
	then
		object:cancelRevolverCharge(false, not v4)
		return
	end

	object.CurrentWalkSpeedOverride = nil

	if object.Rounds > 0 then
		object:shoot("Primary")
		return
	end

	resetRevolverChargeState(object) -- inferred equivalent call
	applyRevolverRestingWeaponModeProfiles(object) -- inferred equivalent call
	object:reload()
end

local function scheduleInspectEnd(object, length: number) -- 2 equivalent calls inferred from this helper
	object.InspectDelayThread = task.delay(length, function()
		if not object.IsDestroyed then
			object.InspectDelayThread = nil
			object.IsInspecting = false
		end
	end)
end

local function resetActionState(object) -- 2 equivalent calls inferred from this helper
	clearFireInputState(object) -- inferred equivalent call
	object.IsBurstShooting = false
	object.IsInspectFadingOut = false
	object.IsInspecting = false
	object.IsReloading = false
	object.IsShooting = false
	object.IsAiming = false
	object.IsChargeFiring = false
	object.IsAdjustingSuppressor = false
	object.CurrentWalkSpeedOverride = nil
	object.ChargeStartTick = 0
	object.ChargeThread = nil
	object.ChargeShootConnection = nil
end

local function adjustSuppressor(object, p: string, p2: string, flag: boolean)
	if
		isJustEquipped(object) -- inferred equivalent call
		or object.IsAdjustingSuppressor
		or object.IsShooting
		or object.IsReloading
		or object.IsAiming
	then
		return
	end

	object.IsAdjustingSuppressor = true
	object.IsBurstShooting = false
	object.IsInspecting = false
	object.IsReloading = false
	object.IsShooting = false
	object.IsAiming = false

	if flag then
		object.ScopeStartTick = 0
	end

	object:stopAllAnimations()
	object.Viewmodel.Animation:play(p)
	object.CharacterAnimator:play(p)
	ReplicateCharacterAction(p2)
end

function Weapon.getSpread(p)
	return p.Bullet:getTrueSpread()
end

function Weapon.getCrosshairDisplayState(_)
	return nil
end

function Weapon:getBaseSpread()
	return self.Bullet:getBaseSpread()
end

function Weapon:cancelRevolverCharge(flag: boolean?, flag2: boolean?)
	local isChargeFiring = self.IsChargeFiring
	resetRevolverChargeState(self) -- inferred equivalent call
	applyRevolverRestingWeaponModeProfiles(self) -- inferred equivalent call

	if isChargeFiring then
		stopRevolverChargeAnimation(self, flag2)

		if flag2 ~= false and self.IsEquipped and not self.IsDestroyed then
			ReplicateCharacterAction("RevolverChargeCancel")
		end
	end

	if flag ~= true then
		self.IsFireHeld = false
		self.FireInputBinding = nil
	end
end

function Weapon:startRevolverCharge(fireInputBinding)
	if self.Properties.ShootingOptions ~= "Revolver" then
		return
	end

	local fireModes = self.Properties.FireModes
	local primary

	if fireModes then
		primary = fireModes.Primary
	end

	if not primary or primary.InputBehavior ~= "Charge" then
		return
	end

	self:stopRevolverSecondaryFire()

	if tick() - self.WeaponEquippedTick <= getEquipPulloutDuration(self) then -- inferred equivalent call
		return
	end

	local localCharacter = CharacterResolver.getLocalCharacter()

	if localCharacter and localCharacter:GetAttribute("Dead") then
		return
	end

	if
		GameState.GetState() == "Buy Period"
		or LocalPlayer:GetAttribute("IsDefusingBomb") == true
		or LocalPlayer:GetAttribute("IsLocallyDefusingBomb") == true
	then
		clearFireInputState(self) -- inferred equivalent call
	else
		if self.IsAdjustingSuppressor or self.IsReloading or self.IsChargeFiring then
			return
		end

		if self.IsShooting then
			local v4 = tick() - self.ShootRequestTick
			local fireModes2 = self.Properties.FireModes
			local primary2

			if fireModes2 then
				primary2 = fireModes2.Primary
			end

			if math.max(0, (primary2 and primary2.FireRate or self.Properties.FireRate or 0.1) - v4) <= 0.15 then
				self.IsFireHeld = true
				self.FireInputBinding = fireInputBinding
				self.HasPendingChargeRequest = true
			end
		elseif self.Rounds <= 0 then
			self.IsFireHeld = false
			self.FireInputBinding = nil
			self:reload()
		else
			self.IsFireHeld = true
			self.FireInputBinding = fireInputBinding
			self.HasPendingChargeRequest = false
			self.IsChargeFiring = true
			self.ChargeStartTick = tick()
			self.CurrentWalkSpeedOverride = primary.HoldWalkSpeed or self.Properties.WalkSpeed
			applyActiveWeaponModeProfiles(self, "Primary") -- inferred equivalent call
			local spread = self.Bullet
				and primary
				and primary.ChargeStartSpread
				and (primary.Spread or self.Properties.Spread)

			if spread then
				self.Bullet:setBaseSpreadForConfig(primary.ChargeStartSpread, spread)
			end

			if self.IsInspecting or self.IsInspectFadingOut then
				self:cancelInspect(nil, nil, true)
			end

			clearRevolverChargeTracking(self) -- inferred equivalent call
			self:stopAllAnimations()
			local fireAnimationNames, v4 = resolveFireAnimationNames(self, "Shoot", "Shoot", "Primary")
			local v5 = self.Viewmodel.Animation:play(fireAnimationNames)

			if v5 then
				v5:AdjustSpeed(1)
				self.ChargeShootConnection = v5:GetMarkerReachedSignal("Shoot"):Connect(function()
					completeRevolverChargeShot(self)
				end)
			end

			local v6 = self.CharacterAnimator:play(v4)

			if v6 then
				v6:AdjustSpeed(1)
			end

			Remotes.Sound.ReplicateSound.Send({ Class = self.Name, Name = "Prepare" })
			ReplicateCharacterAction("RevolverChargeStart")

			if not v5 then
				self.ChargeThread = task.delay(primary.ChargeTime or 0, function()
					completeRevolverChargeShot(self)
				end)
			end
		end
	end
end

function Weapon:startRevolverSecondaryFire(alternativeFireInputBinding)
	if self.Properties.ShootingOptions ~= "Revolver" then
		return
	end

	if
		GameState.GetState() == "Buy Period"
		or LocalPlayer:GetAttribute("IsDefusingBomb") == true
		or LocalPlayer:GetAttribute("IsLocallyDefusingBomb") == true
	then
		clearFireInputState(self) -- inferred equivalent call
	else
		self:cancelRevolverCharge(false, false)
		self.IsAlternativeFireHeld = true
		self.AlternativeFireInputBinding = alternativeFireInputBinding
		applyActiveWeaponModeProfiles(self, "Secondary") -- inferred equivalent call

		if self.IsShooting or self.IsReloading or self.IsAdjustingSuppressor then
			return
		end

		if self.Rounds > 0 then
			self:shoot("Secondary")
		else
			self:reload()
		end
	end
end

function Weapon:stopRevolverSecondaryFire()
	self.IsAlternativeFireHeld = false
	self.AlternativeFireInputBinding = nil

	if not self.IsChargeFiring and isRevolverWeapon(self) then -- inferred equivalent call
		applyActiveWeaponModeProfiles(self, "Secondary") -- inferred equivalent call
	end
end

function Weapon:stopAllAnimations()
	if not (self.CharacterAnimator and self.Viewmodel and self.Viewmodel.Animation) then
		return
	end

	self.Viewmodel.Animation:cancelCrossfade()

	for k, animation in pairs(self.CharacterAnimator.Animations) do
		if animation.IsPlaying and animation.Name ~= "Idle" then
			self.CharacterAnimator:stop(k)
		end
	end

	for k, animation in pairs(self.Viewmodel.Animation.Animations) do
		if animation.IsPlaying and animation.Name ~= "Idle" then
			self.Viewmodel.Animation:stop(k)
		end
	end
end

function Weapon.removeSuppressor(p)
	adjustSuppressor(p, "RemoveSuppressor", "Remove Suppressor", true)
end

function Weapon.addSuppressor(p)
	adjustSuppressor(p, "AddSuppressor", "Add Suppressor", false)
end

function Weapon:scope(flag: boolean)
	if not self.Viewmodel or isJustEquipped(self) then -- inferred equivalent call
		return
	end

	local v4 = self.Properties.AimingOptions == "AutomaticScope"

	if self.IsAdjustingSuppressor or self.IsReloading or self.IsShooting and not v4 or self.IsDestroyed then
		return
	end

	if self.Properties.HasScope then
		if not self.IsAiming then
			self:stopAllAnimations()
		end

		self.IsBurstShooting = false
		self.IsInspecting = false
		self.IsReloading = false
		self.IsShooting = false

		if not self.IsAiming then
			self.ScopeStartTick = tick()
		end

		self.IsAiming = true
		setSniperScoped(self, true) -- inferred equivalent call

		if self.Properties.AimingOptions == "SniperScope" then
			if not self.Viewmodel.Hidden then
				self.Viewmodel:hide()
			end

			playOtherSound("Toggle Scope") -- inferred equivalent call
			local currentScopeIncrement

			if flag then
				self.CurrentScopeIncrement += 1

				if self.CurrentScopeIncrement >= 3 then
					self:unscope(nil, nil, "Toggle Scope")
					return
				else
					currentScopeIncrement = self.CurrentScopeIncrement
				end
			else
				currentScopeIncrement = 1
			end

			CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV - v[currentScopeIncrement])
			Remotes.Inventory.UpdateScopeIncrement.Send({
				Increment = currentScopeIncrement,
				SoundName = "Toggle Scope"
			})
		elseif self.Properties.AimingOptions == "AutomaticScope" then
			if self.CurrentScopeIncrement == 1 then
				self:unscope()
				return
			end

			self.CurrentScopeIncrement = 1

			if not self.Viewmodel.Hidden then
				self.Viewmodel:hide()
			end

			self.Viewmodel:aim()
			CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV - 15 * self.CurrentScopeIncrement)
			Remotes.Inventory.UpdateScopeIncrement.Send({
				Increment = self.CurrentScopeIncrement,
				SoundName = "Scope In"
			})
			playOtherSound("Scope In") -- inferred equivalent call
		end
	end
end

function Weapon:unscope(flag: boolean?, flag2: boolean?, p: string?)
	if not flag2 and (isJustEquipped(self) or self.IsAdjustingSuppressor) then -- inferred equivalent call
		return
	end

	if self.Properties.HasScope then
		if self.IsAiming then
			self:stopAllAnimations()
		end

		if self.CurrentScopeIncrement > 0 or self.IsAiming then
			local soundName = p == nil and self.Properties.AimingOptions == "AutomaticScope" and "Scope Out" or p
			Remotes.Inventory.UpdateScopeIncrement.Send({ Increment = 0, SoundName = soundName })
		end

		if not flag then
			self.CurrentScopeIncrement = 0
		end

		self.IsInspecting = false
		self.IsReloading = false
		self.IsAiming = false
		self.ScopeStartTick = 0
		setSniperScoped(self, false) -- inferred equivalent call

		if self.Properties.AimingOptions == "SniperScope" then
			if self.Viewmodel.Hidden then
				self.Viewmodel:unhide()
			end

			restoreDefaultFovUnlessSceneActive()

			if flag then
				self.CurrentScopeIncrement = math.clamp(self.CurrentScopeIncrement - 1, 0, 3)
			end
		elseif self.Properties.AimingOptions == "AutomaticScope" then
			self.CurrentScopeIncrement = 0
			self.Viewmodel:unaim()

			if self.Viewmodel.Hidden then
				self.Viewmodel:unhide()
			end

			CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV - 15 * self.CurrentScopeIncrement)
			playOtherSound("Scope Out") -- inferred equivalent call
		end
	end
end

function Weapon:cancelInspect(value: number?, value2: number?, flag: boolean?)
	if not (self.IsInspecting or self.IsInspectFadingOut) then
		return
	end

	cancelThreadField(self, "InspectDelayThread") -- inferred equivalent call
	cancelThreadField(self, "CancelDelayThread") -- inferred equivalent call
	cancelThreadField(self, "FadeCompleteThread") -- inferred equivalent call

	if flag then
		self.IsInspecting = false
		self.IsInspectFadingOut = false
		self.Viewmodel.Animation:markInspectCancel()
		self.Viewmodel.Animation:cancelCrossfade()
	else
		local v4 = value or 0.25
		self.IsInspectFadingOut = true
		self.IsInspecting = false
		self.Viewmodel.Animation:markInspectCancel()
		self.CancelDelayThread = task.delay(value2 or 0.3, function()
			if self.IsDestroyed or not self.IsInspectFadingOut then
				return
			end

			self.Viewmodel.Animation:crossfadeTo("Idle", v4)
			self.FadeCompleteThread = task.delay(v4, function()
				if not self.IsDestroyed then
					self.FadeCompleteThread = nil
					self.IsInspectFadingOut = false
				end
			end)
		end)
	end
end

function Weapon:inspect()
	if isJustEquipped(self) then -- inferred equivalent call
		return
	end

	if self.IsChargeFiring then
		self:cancelRevolverCharge(false, false)
	end

	self:stopRevolverSecondaryFire()

	if self.IsAdjustingSuppressor or self.IsShooting or self.IsReloading or self.IsAiming then
		return
	end

	if self.IsInspecting and not self.IsInspectFadingOut then
		return
	end

	local isInspectFadingOut = self.IsInspectFadingOut == true

	if isInspectFadingOut then
		self.IsInspectFadingOut = false
		cancelThreadField(self, "CancelDelayThread") -- inferred equivalent call
		cancelThreadField(self, "FadeCompleteThread") -- inferred equivalent call
		self.Viewmodel.Animation:cancelCrossfade()
	end

	self.IsBurstShooting = false
	self.IsInspecting = true
	self.IsReloading = false
	self.IsShooting = false
	self.ScopeStartTick = 0
	self.IsAiming = false
	cancelThreadField(self, "InspectDelayThread") -- inferred equivalent call
	local inspectVariant = self.Viewmodel.Animation:pickInspectVariant()

	if isInspectFadingOut then
		if not self.Viewmodel.Animation:crossfadeRestart(inspectVariant, 0.25) then
			self:stopAllAnimations()
			self.Viewmodel.Animation:play(inspectVariant)
		end

		ReplicateCharacterAction("Inspect")
		local animation = self.Viewmodel.Animation:getAnimation(inspectVariant)

		if animation then
			scheduleInspectEnd(self, animation.Length) -- inferred equivalent call
		end
	else
		self:stopAllAnimations()
		local v4 = self.Viewmodel.Animation:play(inspectVariant)
		ReplicateCharacterAction("Inspect")
		scheduleInspectEnd(self, v4.Length) -- inferred equivalent call
	end
end

function Weapon:fireBurst()
	self.IsBurstShooting = true
	task.spawn(function()
		for _ = 1, WeaponTimings.BURST_SHOT_COUNT do
			if not self.IsEquipped then
				break
			end

			self:shoot()

			if self.Rounds <= 0 then
				HintController:createHint("Reload")
			end

			task.wait(WeaponTimings.BURST_SHOT_INTERVAL)
		end

		task.wait(WeaponTimings.BURST_COOLDOWN)
		self.IsBurstShooting = false
	end)
end

function Weapon:updateFireMode()
	if isJustEquipped(self) then -- inferred equivalent call
		return
	end

	if self.IsShooting or self.IsReloading or self.IsBurstShooting or self.IsChargeFiring then
		return
	end

	playOtherSound("Switch Fire Mode") -- inferred equivalent call
	self:stopAllAnimations()
	self.Viewmodel.Animation:play("Switch")
	self.AlternativeSwitchTick = tick()
	self.AlternativeShootingOption = self.AlternativeShootingOption == "Burst" and "Default" or "Burst"
	ReplicateCharacterAction("Switch Fire Mode")
	local v4 = self.Properties.Automatic and "Switched to automatic" or "Switched to semi-automatic"
	Router.broadcastRouter(
		"CreateNotification",
		"Switched Fire Mode",
		self.AlternativeShootingOption == "Default" and v4 or "Switched to burst-fire mode",
		2.5
	)
end

function Weapon:drop()
	if
		workspace:GetAttribute("Gamemode") == "Deathmatch"
		or GameState.GetState() == "Warmup"
		or IsTutorialMode()
		or not self.Properties.Droppable
	then
		return false
	end

	self:unequip()
	Remotes.Inventory.DropWeapon.Send({
		CharacterVelocity = GetCharacterVelocity(CharacterResolver.getLocalCharacter()),
		Direction = CurrentCamera.CFrame.LookVector,
		Identifier = self.Identifier
	})
	return true
end

function Weapon:reload()
	local v4 = workspace:GetAttribute("Gamemode") == "Deathmatch" or IsTutorialMode()
	local v5 = v4 and self.Properties.ReloadAnimationCount == 1

	if isJustEquipped(self) then -- inferred equivalent call
		return
	end

	if self.IsChargeFiring then
		self:cancelRevolverCharge(false, false)
	end

	self:stopRevolverSecondaryFire()

	if self.IsAdjustingSuppressor or self.IsReloading or self.IsShooting then
		return
	end

	if self.Properties.Rounds == self.Rounds or self.Properties.RechargeTime then
		if self.IsInspecting or self.IsInspectFadingOut then
			self:cancelInspect(0.25)
		end
	elseif self.Capacity <= 0 and not v5 then
		if self.IsInspecting or self.IsInspectFadingOut then
			self:cancelInspect(0.25)
		end

		return playOtherSound("No Ammo")
	else
		if self.IsAiming then
			self:unscope()
		end

		if not (self.Properties.Rounds and self.Properties.ReloadAnimationCount) then
			return
		end

		if self.IsInspecting or self.IsInspectFadingOut then
			self:cancelInspect(nil, nil, true)
		end

		self:stopAllAnimations()
		self.ReloadStartTick = tick()
		self.IsBurstShooting = false
		self.IsInspecting = false
		self.IsReloading = true
		self.IsShooting = false
		self.CurrentWalkSpeedOverride = nil

		if self.Properties.ReloadAnimationCount > 1 then
			local v6 = self.Properties.Rounds / self.Properties.ReloadAnimationCount
			local guid = HttpService:GenerateGUID(false)
			self.CurrentReloadIdentity = guid
			local v7 = self.Viewmodel.Animation:play("ReloadStart")
			ReplicateCharacterAction("ReloadStart")
			task.wait(v7.Length * 0.75)

			for _ = 1, math.ceil((self.Properties.Rounds - self.Rounds) / v6) do
				if not self.IsReloading or self.CurrentReloadIdentity ~= guid then
					return
				end

				if self.Rounds >= self.Properties.Rounds then
					break
				end

				local v8 = self.Viewmodel.Animation:play("ReloadAction")

				if not v8 then
					error(`Client failed to fetch reload animation for {self.Name}.`)
				end

				self.CharacterAnimator:play("Reload")
				ReplicateCharacterAction("Reload")
				v8:GetMarkerReachedSignal("MagOut"):Once(function()
					Remotes.Inventory.CreateMagazine.Send(self.Identifier)
				end)
				v8:GetMarkerReachedSignal("MagIn"):Once(function()
					if not isEquippedLocal(self) or self.CurrentReloadIdentity ~= guid then -- inferred equivalent call
						return
					end

					local v9 = math.min(v6, self.Capacity, self.Properties.Rounds - self.Rounds)

					if v9 > 0 then
						Remotes.Inventory.ReloadWeapon.Send({
							Identifier = self.Identifier,
							Capacity = self.Capacity,
							Rounds = self.Rounds
						})
						self.Rounds += v9

						if not v4 then
							self.Capacity -= v9
						end
					end
				end)
				task.wait(v8.Length)
			end

			if self.IsReloading and self.CurrentReloadIdentity == guid then
				local v8 = self.Viewmodel.Animation:play("ReloadEnd")
				ReplicateCharacterAction("ReloadEnd")
				v8.Ended:Once(function()
					self.IsReloading = false
				end)
			end
		else
			local guid = HttpService:GenerateGUID(false)
			self.CurrentReloadIdentity = guid
			local v6 = self.Viewmodel.Animation:play("Reload")
			assert(v6, `Client failed to fetch reload animation for {self.Name}.`)
			self.CharacterAnimator:play("Reload")
			ReplicateCharacterAction("Reload")
			v6:GetMarkerReachedSignal("MagOut"):Once(function()
				Remotes.Inventory.CreateMagazine.Send(self.Identifier)
			end)
			v6:GetMarkerReachedSignal("MagIn"):Once(function()
				if not isEquippedLocal(self) or self.CurrentReloadIdentity ~= guid then -- inferred equivalent call
					return
				end

				local v7 = math.abs(self.Properties.Rounds - self.Rounds)
				Remotes.Inventory.ReloadWeapon.Send({
					Identifier = self.Identifier,
					Rounds = self.Rounds,
					Capacity = self.Capacity
				})
				HintController:clearHint("Reload")

				if v5 then
					self.Rounds = self.Properties.Rounds
					self.Capacity = self.Properties.Capacity
				elseif self.Capacity - v7 > 0 then
					self.Rounds = self.Properties.Rounds

					if not v4 then
						self.Capacity = math.max(0, self.Capacity - v7)
					end
				elseif self.Capacity - v7 <= 0 then
					self.Rounds += self.Capacity

					if not v4 then
						self.Capacity = 0
					end
				end
			end)
			disconnectField(self, "ReloadTrackFinishedConnection") -- inferred equivalent call
			self.ReloadTrackFinishedConnection = v6:GetPropertyChangedSignal("IsPlaying"):Connect(function()
				if self.IsDestroyed then
					return
				end

				if not v6.IsPlaying and self.WeaponEquippedTick < self.ReloadStartTick then
					self.IsReloading = false
				end

				disconnectField(self, "ReloadTrackFinishedConnection") -- inferred equivalent call
			end)
		end
	end
end

function Weapon:shoot(value)
	local v4 = value or "Primary"
	local activeFireRate = getActiveFireRate(self, v4) -- inferred equivalent call
	local revolverWeapon = isRevolverWeapon(self) -- inferred equivalent call

	if revolverWeapon then
		if v4 == "Primary" then
			revolverWeapon = self.IsChargeFiring
		else
			revolverWeapon = false
		end
	end

	local animation = self.Viewmodel.Animation:getAnimation("Equip")

	if isLocalPlayerDefusing() then -- inferred equivalent call
		clearFireInputState(self) -- inferred equivalent call

		if self.IsChargeFiring then
			self:cancelRevolverCharge(false, false)
		end
	else
		if
			tick() - self.WeaponEquippedTick <= animation.Length * WeaponTimings.EQUIP_PULLOUT_FRACTION
			or CharacterResolver.getLocalCharacter() and CharacterResolver.getLocalCharacter():GetAttribute("Dead")
		then
			return
		end

		if GameState.GetState() == "Buy Period" then
			return
		end

		if pcall(function()
			self.Properties.FireRate += 1e-7
		end) then
			Weapon = {}

			while true do

			end
		else
			local v5, interactables, rounds, v6, v7, chargeThread, chargeShootConnection, v8, v9, v10, position, v11, v12, fireModes, secondary, spread, muzzlePartL, position2, v13, bullets, v14, fireModes2, secondary2, spread2, v15, v16, isAiming, v17, v18, v19, v20, instance, position3, material, normal, exit, instanceModel, v21, v22, v23, userId, v24, parent, pivot, recoil, v25, v26, shootDelayThread, now, nextShotDue, nextShotDue2, shootRequestTick

			if modulesByName and modulesByName[self.Name] then
				local v27 = modulesByName[self.Name]

				if
					self.Properties.FireRate < v27.FireRate
					or self.Properties.BulletsPerShot > v27.BulletsPerShot
					or self.Properties.Range > v27.Range
					or self.Properties.Penetration > v27.Penetration
				then
					Weapon = {}

					while true do

					end

					return
				end
			end

			if
				not self.Properties.FireRate
				or not self.Properties.BulletsPerShot
				or self.IsAdjustingSuppressor
				or self.IsReloading and self.Properties.MuzzleType ~= "ShotGun"
			then
				return
			end

			v5 = CharacterResolver.getPlayerCharacter(self.Player)

			if not (v5 and self.CharacterAnimator) then
				return
			end

			if self.AlternativeShootingOption ~= "Burst" then
				self.ShootRequestTick = tick()
			end

			if self.IsShooting and self.AlternativeShootingOption == "Default" then
				return
			end

			interactables = self.Viewmodel.Model:FindFirstChild("Interactables")

			if not interactables then
				return
			end

			if self.Rounds <= 0 then
				self:reload()
				return
			end

			rounds = self.Properties.Rounds

			if rounds and self.Rounds <= rounds * 0.2 then
				playOtherSound("Low Ammo Fire") -- inferred equivalent call
			end

			v6 = self.IsAiming and self.Properties.AimingOptions == "AutomaticScope" and "AimShoot" or "Shoot"
			v7 = self.Properties.HasSuppressor and not self.IsSuppressed and "NoSuppressorShoot" or "Shoot"
			CameraController.toWeaponFirePosition()

			if not revolverWeapon and (self.IsInspecting or self.IsInspectFadingOut) then
				self:cancelInspect(nil, nil, true)
			end

			if not revolverWeapon then
				self:stopAllAnimations()
			end

			self.CurrentReloadIdentity = nil
			self.IsInspecting = false
			self.IsInspectFadingOut = false
			self.IsReloading = false
			self.IsShooting = true
			chargeThread = self.ChargeThread

			if chargeThread then
				task.cancel(chargeThread)
				self.ChargeThread = nil
			end

			chargeShootConnection = self.ChargeShootConnection

			if chargeShootConnection and chargeShootConnection.Connected then
				chargeShootConnection:Disconnect()
			end

			self.ChargeShootConnection = nil
			self.HasPendingChargeRequest = false
			self.IsChargeFiring = false
			self.ChargeStartTick = 0
			self.CurrentWalkSpeedOverride = nil

			if not vipInfiniteAmmoEnabled then
				self.Rounds -= 1
			end

			self.RechargeStartTime = workspace:GetServerTimeNow()

			if self.Properties.ShootingOptions == "Dual" then
				self.ShootingHand = self.ShootingHand == "Left" and "Right" or "Left"
				v6 = "Shoot" .. self.ShootingHand
				v7 = "Shoot" .. self.ShootingHand
			end

			v8, v9 = resolveFireAnimationNames(self, v7, v6, v4)

			if revolverWeapon then
				v10 = v8
			else
				v10 = self.Viewmodel.Animation:pickVariant(v8)
			end

			if self.Properties.MuzzleType ~= "ShotGun" then
				self.CharacterAnimator:adjustAnimationSpeed(v9, activeFireRate)
			end

			if self.Rounds > 150 then
				return
			end

			startRechargeTimer(self)
			position = v5.PrimaryPart.Position
			v11 = (self.Properties.HasSuppressor and self.IsSuppressed) == true
			v12 = SoundController.GetWeaponShootRange(self.Name, v11)
			Router.broadcastRouter("UpdatePlayerNoiseCone", "Weapon", position, v12, nil)

			if self.Bullet then
				fireModes = self.Properties.FireModes

				if fireModes then
					secondary = v4 == "Secondary" and fireModes.Secondary or fireModes.Primary
				end

				spread = secondary and secondary.Spread or self.Properties.Spread
				self.Bullet:setSpreadConfig(spread)
			end

			applyActiveRecoilProfile(self, v4)
			muzzlePartL = self.Properties.ShootingOptions == "Dual"
				and (self.ShootingHand == "Left" and interactables:FindFirstChild("MuzzlePartL") or interactables:FindFirstChild("MuzzlePartR"))
				or interactables.MuzzlePart
			position2 = muzzlePartL.Position
			debug.profilebegin("Weapon.BuildShootPacket")
			v13 = {}
			bullets = {}

			for _ = 1, self.Properties.BulletsPerShot do
				v14 = self.Bullet:create(self.Properties.AimingOptions, self.IsAiming)

				if not v14 then
					continue
				end

				table.insert(v13, v14)
				table.insert(bullets, { Direction = v14.Direction, Origin = v14.Origin })
			end

			debug.profileend()

			if revolverWeapon and isRevolverWeapon(self) then -- inferred equivalent call
				if self.Bullet then
					fireModes2 = self.Properties.FireModes

					if fireModes2 then
						secondary2 = fireModes2.Secondary or fireModes2.Primary
					end

					spread2 = secondary2 and secondary2.Spread or self.Properties.Spread
					self.Bullet:setSpreadConfig(spread2)
				end

				applyActiveRecoilProfile(self, "Secondary")
			end

			debug.profilebegin("Weapon.SendShootPacket")
			self.ShotSeq += 1
			Remotes.Inventory.ShootWeapon.Send({
				IsSniperScoped = self.IsSniperScoped,
				ShootingHand = self.ShootingHand,
				Identifier = self.Identifier,
				Seq = self.ShotSeq,
				Bullets = bullets,
				ViewTick = Router.broadcastRouter("GetRemoteViewTick")
			})
			debug.profileend()
			debug.profilebegin("Weapon.ShootVFX")
			v15 = DataController.Get(LocalPlayer, "Settings.Video.Presets.First Person Tracers") ~= false
			v16 = DataController.Get(LocalPlayer, "Settings.Video.Presets.Muzzle Flash") ~= false

			if v16 then
				if self.Properties.AimingOptions == "AutomaticScope" then
					isAiming = self.IsAiming
				else
					isAiming = false
				end

				v16 = not isAiming
			end

			v17 = DataController.Get(LocalPlayer, "Settings.Game.Other.Emit Particles When Server Validated") == true
			v18 = self.Properties.MuzzleType == "Zeus x27"

			if v18 then
				CreateZeusBeam(muzzlePartL)
			end

			if v16 and #v13 > 0 then
				Camera(
					muzzlePartL,
					self.Properties.HasSuppressor and self.IsSuppressed and "Suppressor" or self.Properties.MuzzleType
				)
			end

			for _, v27 in ipairs(v13) do
				v19 = false

				if v15 then
					CreateTracer(v27.Distance, position2, v27.Direction)
				end

				v20 = false

				for _, hit in ipairs(v27.Hits) do
					instance = hit.Instance
					position3 = hit.Position
					material = hit.Material
					normal = hit.Normal
					exit = hit.Exit
					instanceModel = instance and instance:FindFirstAncestorOfClass("Model")

					if instanceModel == nil then
						v21 = false
					else
						v21 = CharacterResolver.getPlayerFromCharacter(instanceModel) ~= nil
							or instanceModel:GetAttribute("Bot") == true
							or CharacterResolver.isTutorialDummy(instanceModel)
					end

					if v21 then
						if v17 then
							v22 = CharacterResolver.getPlayerFromInstance(instance)
							v23 = CharacterResolver.getImpactMaterial(instance, "Blood Splatter")
							CreateImpact(instance, v23, position3, normal, exit, false, true, nil, v20, nil, v18)

							if v23 == "Blood Splatter" and not (exit or v18) then
								CreateBloodSplatter(position3, v27.Direction)
							end

							if v22 then
								userId = v22.UserId
							else
								userId = botVictimKey(instance)
							end

							if userId and not exit then
								PlayerHitPrediction.Record(self.ShotSeq, userId, instance.Name, position3)
							end
						end
					else
						v20 = not exit or v20

						if not v18 then
							v24 = not (exit or v19)
							CreateImpact(
								instance,
								material,
								position3,
								normal,
								exit,
								false,
								true,
								nil,
								nil,
								nil,
								nil,
								not v24
							)
							v19 = v24 and true or v19
						end

						parent = instance.Parent

						if parent and parent:HasTag("BreakableGlass") and not exit then
							BreakGlass(instance, position3, v27.Direction)
						elseif not (v18 or instance:HasTag("BreakableGlass") or parent and parent:HasTag("BreakableGlass")) then
							CreateMarker(instance, "Bullet", position3, normal)
						end

						if parent and parent:HasTag("BreakableDoor") and (self.Properties.Penetration or 0) <= 0 then
							break
						end
					end
				end
			end

			debug.profileend()
			debug.profilebegin("Weapon.ShootTail")

			if self.Viewmodel.Model.CameraShake then
				CameraController.weaponKick(GetWeaponCameraKick(self.Viewmodel.Model.CameraShake))
			end

			self.Viewmodel.Bobble:addScopeKick()

			if self.Viewmodel.applyCharmImpulse then
				pivot = self.Viewmodel.Model:GetPivot()

				if self.Viewmodel.Mirror then
					pivot = self.Viewmodel.Mirror:ToNormalPose(pivot)
				end

				self.Viewmodel:applyCharmImpulse(pivot.LookVector * -1 + pivot.UpVector * 0.3)
			end

			if self.Recoil then
				recoil = self.Recoil
				recoil.Time += activeFireRate
			end

			ReplicateCharacterAction(revolverWeapon and "RevolverChargeRelease" or v8)
			v25 = self.IsAiming and self.Properties.AimingOptions == "SniperScope"

			if v25 then
				self:unscope(true)
			end

			debug.profilebegin("Weapon.ShootAnimations")

			if revolverWeapon then
				v26 = self.Viewmodel.Animation:getAnimation(v8)
			else
				v26 = self.Viewmodel.Animation:play(v10)
			end

			if revolverWeapon then
				if not (v26 and v26.IsPlaying) then
					self.Viewmodel.Animation:play(v8)
					self.CharacterAnimator:play(v9)
				end
			else
				self.CharacterAnimator:play(v9)
			end

			debug.profileend()
			debug.profilebegin("Weapon.ShootHaptics")
			HapticsController.vibrate(Enum.VibrationMotor.Small, 1.25, 0.225)
			debug.profileend()
			shootDelayThread = self.ShootDelayThread

			if shootDelayThread then
				task.cancel(shootDelayThread)
				self.ShootDelayThread = nil
			end

			now = os.clock()
			nextShotDue = self.NextShotDue

			if nextShotDue and now - nextShotDue < 0.035 then
				nextShotDue2 = nextShotDue + activeFireRate
			else
				nextShotDue2 = now + activeFireRate
			end

			self.NextShotDue = nextShotDue2
			shootRequestTick = self.ShootRequestTick
			self.ShootDelayThread = task.delay(nextShotDue2 - now, function()
				if self.IsDestroyed then
					return
				end

				self.IsShooting = false
				self.ShootDelayThread = nil

				if not isEquippedLocal(self) then -- inferred equivalent call
					return
				end

				if
					v25
					and self.ShootRequestTick > self.WeaponEquippedTick
					and self.Rounds > 0
					and DataController.Get(LocalPlayer, "Settings.Game.Item.Auto Re-Zoom Sniper Rifle after Shot") == true
				then
					self:scope(true)
				end

				if isRevolverWeapon(self) then -- inferred equivalent call
					local v27 = refreshHeldBinding(self, "IsAlternativeFireHeld", "AlternativeFireInputBinding") -- inferred equivalent call
					local fireModes3 = self.Properties.FireModes
					local secondary3

					if fireModes3 then
						secondary3 = fireModes3.Secondary or fireModes3.Primary
					end

					if v27 and secondary3 and secondary3.HoldRepeat then
						if self.Rounds > 0 then
							self:shoot("Secondary")
						else
							self:reload()
						end
					else
						local v28 = refreshHeldBinding(self, "IsFireHeld", "FireInputBinding") -- inferred equivalent call
						local fireModes4 = self.Properties.FireModes
						local primary

						if fireModes4 then
							primary = fireModes4.Primary
						end

						if v28 and primary and primary.HoldRepeat then
							if self.Rounds > 0 then
								self:startRevolverCharge(self.FireInputBinding)
							else
								self:reload()
							end
						elseif self.HasPendingChargeRequest == true then
							self.HasPendingChargeRequest = false

							if v28 then
								self:startRevolverCharge(self.FireInputBinding)
							end
						end
					end
				else
					local now2 = tick()
					local v27 = math.min(0.15, activeFireRate)
					local v28

					if shootRequestTick < self.ShootRequestTick then
						v28 = now2 - self.ShootRequestTick <= v27
					else
						v28 = false
					end

					local v29 = refreshHeldBinding(self, "IsFireHeld", "FireInputBinding") -- inferred equivalent call

					if
						not (self.Properties.Automatic and v29) and (self.Properties.Automatic or not v28 or v29)
						or self.Properties.ShootingOptions == "Burst" and self.AlternativeShootingOption == "Burst"
					then
						return
					end

					if self.Rounds > 0 then
						self:shoot()
					else
						self:reload()
					end
				end
			end)
			debug.profileend()
		end
	end
end

function Weapon:equip()
	self.IsEquipped = true
	CameraController.resetWeaponRecoil()

	if self.Bullet then
		self.Bullet:setActive(true)
	end

	if self.Viewmodel.Hidden then
		self.Viewmodel:unhide()
	end

	self.Viewmodel.Animation:stopAnimations()
	self.CharacterAnimator:stopAnimations()
	self.CharacterAnimator:play("Idle")
	self.CharacterAnimator:play("Equip")
	self.WeaponEquippedTick = tick()
	self.Viewmodel:equip(false)
	self.Janitor:Remove("EquipDelayFire")
	local thread = task.delay(getEquipPulloutDuration(self), function() -- inferred equivalent call
		if self.IsDestroyed or not self.IsEquipped or GameState.GetState() == "Buy Period" then
			return
		end

		if isLocalPlayerDefusing() then -- inferred equivalent call
			clearFireInputState(self) -- inferred equivalent call
		else
			if
				isRevolverWeapon(self) -- inferred equivalent call
				and (self.IsAlternativeFireHeld or InputController.isActionActive("SecondaryFire"))
			then
				local alternativeFireInputBinding = self.AlternativeFireInputBinding
					or getPressedActionBinding("SecondaryFire", v3)

				if alternativeFireInputBinding or self.IsAlternativeFireHeld then
					self:startRevolverSecondaryFire(alternativeFireInputBinding)
					return
				end
			end

			if not InputController.isActionActive("Fire") then
				return
			end

			local pressedActionBinding = getPressedActionBinding("Fire", v2)

			if pressedActionBinding then
				if isRevolverWeapon(self) then -- inferred equivalent call
					self:startRevolverCharge(pressedActionBinding)
					return
				end

				self.IsFireHeld = true
				self.FireInputBinding = pressedActionBinding
				self:shoot()
			end
		end
	end)
	self.Janitor:Add(function()
		task.cancel(thread)
	end, false, "EquipDelayFire")
	self.CurrentScopeIncrement = 0
	self.ScopeStartTick = 0
	resetActionState(self) -- inferred equivalent call
	applyRevolverRestingWeaponModeProfiles(self) -- inferred equivalent call
	setSniperScoped(self, false) -- inferred equivalent call
end

function Weapon:unequip()
	self.IsEquipped = false
	CameraController.resetWeaponRecoil()

	if self.Bullet then
		self.Bullet:setActive(false)
	end

	self:cancelRevolverCharge(false, false)
	self:stopRevolverSecondaryFire()
	self.Janitor:Remove("EquipDelayFire")
	cancelThreadField(self, "ShootDelayThread") -- inferred equivalent call
	restoreDefaultFovUnlessSceneActive()
	self.CharacterAnimator:stopAnimations()
	self.Viewmodel:unequip()

	if self.IsAiming or self.CurrentScopeIncrement > 0 then
		self:unscope(nil, true)
	end

	if self.Viewmodel.Hidden then
		self.Viewmodel:unhide()
	end

	resetActionState(self) -- inferred equivalent call
	setSniperScoped(self, false) -- inferred equivalent call

	if self.Recoil then
		self.Recoil.Function = self.Recoil.Functions.Default
		self.Recoil.ActiveFireRate = self.Properties.FireRate or 0.1
		self.Recoil.Value = Vector2.zero
		self.Recoil.RecoveryValue = Vector2.zero
		self.Recoil.RecoveryTime = 0
		self.Recoil.RecoveryStartTime = 0
		self.Recoil.Time = 0
	end
end

function Weapon:createSuppressor()
	local model = self.Viewmodel and self.Viewmodel.Model

	if not model then
		return
	end

	local silencer = model:FindFirstChild("Silencer", true)

	if not silencer then
		return
	end

	silencer.Transparency = self.IsSuppressed and 0 or 1
	local identifier = self.Identifier
	local v4 = false
	local animation = self.Viewmodel.Animation:getAnimation("RemoveSuppressor")
	local animation2 = self.Viewmodel.Animation:getAnimation("AddSuppressor")
	self.Janitor:Add(animation:GetMarkerReachedSignal("ScrewOnEnd"):Connect(function()
		if self.IsDestroyed then
			return
		end

		silencer.Transparency = 1
		Remotes.Inventory.UpdateWeaponSuppressor.Send({ Identifier = identifier, State = false })
	end))
	self.Janitor:Add(animation.Ended:Connect(function()
		self.IsAdjustingSuppressor = false

		if not (silencer.Transparency < 1) then
			if not self.IsDestroyed then
				silencer.Transparency = 1
				Remotes.Inventory.UpdateWeaponSuppressor.Send({
					Identifier = identifier,
					State = false
				})
			end

			self.IsSuppressed = false
		end
	end))
	self.Janitor:Add(animation2:GetMarkerReachedSignal("ScrewOnEnd"):Connect(function()
		v4 = true

		if not self.IsDestroyed then
			silencer.Transparency = 0
			Remotes.Inventory.UpdateWeaponSuppressor.Send({ Identifier = identifier, State = true })
		end

		self.IsSuppressed = true
	end))
	self.Janitor:Add(animation2:GetPropertyChangedSignal("IsPlaying"):Connect(function()
		if animation2.IsPlaying then
			v4 = false
			task.delay(1 / 60, function()
				if animation2.IsPlaying then
					silencer.Transparency = 0
				end
			end)
		end
	end))
	self.Janitor:Add(animation2.Ended:Connect(function()
		self.IsAdjustingSuppressor = false

		if not v4 then
			silencer.Transparency = 1
		end
	end))
end

function Weapon:setupRecoil()
	local recoil = self.Properties.Recoil

	if not recoil then
		return
	end

	local recoverySpeed = recoil.RecoverySpeed
	local scale = recoil.Scale
	local damper = recoil.Damper
	local speed = recoil.Speed
	local cameraScale = recoil.CameraScale
	local identifier = self.Identifier
	local pattern = recoil.Pattern(self.Properties)
	self.Recoil = {
		Function = pattern,
		Functions = { Default = pattern },
		Value = Vector2.zero,
		RotationValue = createVector(0, 0, 0),
		ActiveFireRate = self.Properties.FireRate or 0.1,
		Time = 0,
		RecoveryValue = Vector2.zero,
		RecoveryTime = 0,
		RecoveryStartTime = 0
	}
	local recoil2 = self.Recoil
	self.Janitor:Add(
		RunServiceController.BindToStepped(`Components.Weapon.{self.Identifier}.Recoil`, function(_, p: number)
			if self.IsDestroyed or not self.IsEquipped then
				return
			end

			local recoveryValue = recoil2.Function(recoil2.Time)

			if self.IsShooting then
				recoil2.Value = recoveryValue
				recoil2.RecoveryValue = recoveryValue
				recoil2.RecoveryTime = recoil2.Time
				recoil2.RecoveryStartTime = os.clock()
			else
				local v4 = recoil2.RecoveryValue.Magnitude / recoverySpeed

				if recoil2.Value.Magnitude > 0 and v4 > 0 then
					local v5 = os.clock() - recoil2.RecoveryStartTime
					recoil2.Value = recoil2.RecoveryValue:Lerp(Vector2.zero, (math.clamp(v5 / v4, 0, 1)))
				end

				if recoil2.Time > 0 then
					recoil2.Time = math.max(recoil2.Time - recoil2.RecoveryTime * recoverySpeed * p, 0)
				end
			end

			local rotationValue = Vector3.new(recoil2.Value.Y, recoil2.Value.X, 0) * math.rad(scale)
			recoil2.RotationValue = rotationValue

			if not self.IsDestroyed and self.IsEquipped and self.Identifier == identifier then
				CameraController.setWeaponRecoil({
					Value = rotationValue,
					Damper = damper,
					Speed = speed
				}, cameraScale)
			end
		end),
		"Disconnect",
		"RecoilConnection"
	)
end

function Weapon.new(p, p2: string, p3: string, p4: number, p5: string, p6: string, p7: number, p8, p9, p10: string?, p11, p12, options)
	local object = setmetatable(WeaponComponent.new(p, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12), Weapon)
	object.IsEquipped = false
	local v4 = options or {}
	object.Bullet = Bullet.new(object, object.Properties)
	object.Capacity = v4.Capacity or object.Properties.Capacity
	object.Rounds = v4.Rounds or object.Properties.Rounds
	object.RechargeStartTime = v4.RechargeStartTime
	object.AlternativeShootingOption = "Default"
	object.AlternativeSwitchTick = 0
	object.IsBurstShooting = false
	object.ShootingHand = "Right"
	object.HasPendingChargeRequest = false
	object.IsAlternativeFireHeld = false
	object.IsChargeFiring = false
	object.IsAdjustingSuppressor = false
	object.IsInspectFadingOut = false
	object.IsInspecting = false
	object.IsReloading = false
	object.IsShooting = false
	object.IsAiming = false
	object.IsFireHeld = false
	local isSuppressed

	if v4.IsSuppressed == nil then
		isSuppressed = object.Properties.HasSuppressor
	else
		isSuppressed = v4.IsSuppressed
	end

	object.IsSuppressed = isSuppressed
	object.IsSniperScoped = false
	object.CurrentScopeIncrement = 0
	object.WeaponEquippedTick = 0
	object.ChargeStartTick = 0
	object.ShootRequestTick = 0
	object.ShotSeq = 0
	object.ReloadStartTick = 0
	object.ScopeStartTick = 0
	object:setupRecoil()
	applyRevolverRestingWeaponModeProfiles(object) -- inferred equivalent call
	object.Janitor:Add(function()
		object:cancelRevolverCharge(false, false)
		object:stopRevolverSecondaryFire()

		if object.Bullet then
			object.Bullet:destroy()
			object.Bullet = nil
		end

		if object.IsAiming then
			restoreDefaultFovUnlessSceneActive()
		end
	end)

	if object.Properties.HasSuppressor then
		if object.Viewmodel and object.Viewmodel.Model then
			object:createSuppressor()
		else
			local v5 = nil
			v5 = CharacterResolver.observeCharacter(object.Player, function(p13)
				if not p13 then
					return nil
				end

				task.defer(function()
					if object.IsDestroyed or not (object.Viewmodel and object.Viewmodel.Model) then
						return
					end

					if v5 then
						v5()
						v5 = nil
					end

					object:createSuppressor()
				end)
				return nil
			end)
			object.Janitor:Add(function()
				if v5 then
					v5()
					v5 = nil
				end
			end)
		end
	end

	if object.Rounds < (object.Properties.Rounds or object.Rounds) then
		startRechargeTimer(object)
	end

	return object
end

function Weapon:destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true
	disconnectField(self, "ReloadTrackFinishedConnection") -- inferred equivalent call
	cancelThreadField(self, "ShootDelayThread") -- inferred equivalent call
	cancelThreadField(self, "ChargeThread") -- inferred equivalent call
	cancelThreadField(self, "RechargeThread") -- inferred equivalent call
	disconnectField(self, "ChargeShootConnection") -- inferred equivalent call
	cancelThreadField(self, "InspectDelayThread") -- inferred equivalent call
	cancelThreadField(self, "CancelDelayThread") -- inferred equivalent call
	cancelThreadField(self, "FadeCompleteThread") -- inferred equivalent call
	self.Recoil = nil

	if self.Bullet then
		self.Bullet:destroy()
		self.Bullet = nil
	end

	self.Janitor:Destroy()
	self.Janitor = nil
	self.AlternativeShootingOption = nil
	self.AlternativeSwitchTick = nil
	self.CurrentReloadIdentity = nil
	self.CurrentScopeIncrement = nil
	self.WeaponEquippedTick = nil
	self.ChargeStartTick = nil
	self.ShootRequestTick = nil
	self.ReloadStartTick = nil
	self.ShootingHand = nil
	self.CurrentWalkSpeedOverride = nil
	self.HasPendingChargeRequest = nil
	self.IsAlternativeFireHeld = nil
	self.AlternativeFireInputBinding = nil
	self.IsChargeFiring = nil
	self.ChargeThread = nil
	self.ChargeShootConnection = nil
	WeaponComponent.destroy(self)
end

return Weapon