local Grenade = {}
Grenade.__index = Grenade
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
require(ReplicatedStorage.Database.Custom.Types)
local WeaponComponent = require(ReplicatedStorage.Classes.WeaponComponent)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local GetCharacterVelocity = require(ReplicatedStorage.Components.Common.GetCharacterVelocity)
local ReplicateCharacterAction = require(ReplicatedStorage.Components.Common.ReplicateCharacterAction)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local CurrentCamera = workspace.CurrentCamera
local v = { "StartThrow", "ThrowIdle" }

local function isCompetitiveFreezeTime() -- 2 equivalent calls inferred from this helper
	return workspace:GetAttribute("ServerGamemode") == "Competitive" and GameState.GetState() == "Buy Period"
end

local function stopPlayingTracks(object, flag: boolean)
	for k, animation in pairs(object.Animations) do
		if animation.IsPlaying and animation.Name ~= "Idle" and (not flag or animation.Name ~= "Equip") then
			object:stop(k)
		end
	end
end

local function isOnThrowCooldown(object) -- 2 equivalent calls inferred from this helper
	return object.LastThrowTime > 0 and tick() - object.LastThrowTime < 0.7
end

function Grenade:stopAllAnimations()
	if self.CharacterAnimator and self.Viewmodel and self.Viewmodel.Animation then
		stopPlayingTracks(self.CharacterAnimator, false)
		stopPlayingTracks(self.Viewmodel.Animation, false)
	end
end

function Grenade:StartThrow()
	if
		not self.IsDestroyed
		and not (isCompetitiveFreezeTime() or self.EquipTime > 0 and tick() - self.EquipTime < 0.7) -- inferred equivalent call
		and not isOnThrowCooldown(self) -- inferred equivalent call
		and (not self.ThrowStarted or self.ThrowFinished)
	then
		if self.ThrowFinished then
			self.ThrowFinished = false
			self.ThrowStarted = false
			self.Janitor:Remove("ThrowGrenadeFinished")
			self.Janitor:Remove("ThrowGrenadeStoppedFallback")
		end

		local localCharacter = CharacterResolver.getLocalCharacter()

		if localCharacter and localCharacter:GetAttribute("Dead") then
			return
		end

		self.ThrowStarted = true

		if not self.Viewmodel or self.Viewmodel.IsDestroyed or not self.Viewmodel.Model then
			return
		end

		if self.Viewmodel.Model.Parent ~= CurrentCamera then
			if not self.Viewmodel.equip then
				return
			end

			self.Viewmodel:equip(false)
		end

		if self.Viewmodel.Hidden then
			self.Viewmodel:unhide()
		end

		if isOnThrowCooldown(self) then -- inferred equivalent call
			self.ThrowStarted = false
			return
		end

		if self.Viewmodel.IsDestroyed then
			return
		end

		local equip = self.Viewmodel.Animation.Animations.Equip

		if equip and equip.IsPlaying then
			stopPlayingTracks(self.Viewmodel.Animation, true)
			stopPlayingTracks(self.CharacterAnimator, true)
		else
			self:stopAllAnimations()
		end

		self.CharacterAnimator:play("StartThrow")
		self.CharacterAnimator:play("ThrowIdle")
		ReplicateCharacterAction("StartThrow")

		if
			self.Viewmodel
			and not self.Viewmodel.IsDestroyed
			and self.Viewmodel.Model
			and self.Viewmodel.Model.Parent == CurrentCamera
		then
			local v2 = self.Viewmodel.Animation:play("ThrowIdle")
			self.Viewmodel.Animation:play("StartThrow")

			if v2 then
				v2.Looped = true
			end
		end
	end
end

function Grenade:Throw(p: string)
	if self.ThrowFinished then
		return
	end

	if isCompetitiveFreezeTime() then -- inferred equivalent call
		if self.ThrowStarted and not self.ThrowFinished then
			self:Cancel()
		end
	else
		local localCharacter = CharacterResolver.getLocalCharacter()

		if localCharacter and localCharacter:GetAttribute("Dead") then
			return
		end

		if not self.Viewmodel or self.Viewmodel.IsDestroyed or not self.Viewmodel.Model then
			self.ThrowStarted = false
			return
		end

		if self.Viewmodel.Model.Parent ~= CurrentCamera then
			if not self.Viewmodel.equip then
				self.ThrowStarted = false
				return
			end

			self.Viewmodel:equip(false)
			RunService.Heartbeat:Wait()

			if self.Viewmodel.Model.Parent ~= CurrentCamera then
				self.ThrowStarted = false
				return
			end
		end

		if self.Viewmodel.Hidden then
			self.Viewmodel:unhide()
		end

		if not self.Viewmodel.Animation then
			self.ThrowStarted = false
			return
		end

		self.Janitor:Remove("ThrowGrenadeFinished")
		self.Janitor:Remove("ThrowGrenadeStoppedFallback")
		local equip = self.Viewmodel.Animation.Animations.Equip

		if equip and equip.IsPlaying then
			self.Viewmodel.Animation:stop("Equip")
			self.CharacterAnimator:stop("Equip")
			stopPlayingTracks(self.Viewmodel.Animation, false)
			stopPlayingTracks(self.CharacterAnimator, false)
			RunService.Heartbeat:Wait()
		else
			for _, v2 in { self.Viewmodel.Animation, self.CharacterAnimator } do
				for _, v3 in v do
					if v2.Animations[v3] then
						v2:stop(v3)
					end
				end
			end
		end

		if not self.Viewmodel or self.Viewmodel.IsDestroyed or not self.Viewmodel.Animation then
			self.ThrowStarted = false
			return
		end

		local v2 = self.Viewmodel.Animation:play(p)

		if not v2 then
			self.ThrowStarted = false
			return
		end

		local lastTime = tick()

		while v2.Length == 0 and tick() - lastTime < 0.5 do
			RunService.Heartbeat:Wait()
		end

		if self.IsDestroyed or not self.Viewmodel or self.Viewmodel.IsDestroyed then
			self.ThrowStarted = false
			return
		end

		self.CharacterAnimator:play("Throw")
		ReplicateCharacterAction("Throw")
		self.ThrowCompleted = false

		local function completeThrow()
			if self.ThrowCompleted then
				return
			end

			self.ThrowCompleted = true

			if self.IsDestroyed or not self.Identifier then
				return
			end

			self.ThrowFinished = true
			self.ThrowStarted = false
			self.LastThrowTime = tick()

			if Router.broadcastRouter("PredictGrenadeThrow", self.Identifier, p) ~= true then
				self.ThrowFinished = false
				self.ThrowCompleted = false
				warn("[Grenade] Could not queue ordered grenade transition")
			end
		end

		if not v2.IsPlaying then
			self.ThrowStarted = false
			return
		end

		local function fallbackThrow()
			if not self.ThrowCompleted and not self.IsDestroyed and self.ThrowStarted and not self.ThrowFinished then
				completeThrow()
			end
		end

		self.Janitor:Add(v2:GetMarkerReachedSignal("Throw"):Once(completeThrow), "Disconnect", "ThrowGrenadeFinished")
		self.Janitor:Add(v2.Stopped:Once(function()
			task.delay(0.05, function()
				if not (self.ThrowCompleted or self.IsDestroyed) then
					completeThrow()
				end
			end)
		end), "Disconnect", "ThrowGrenadeStoppedFallback")

		if v2.Length > 0 then
			local thread = task.delay(v2.Length * 0.7, fallbackThrow)
			self.Janitor:Add(function()
				task.cancel(thread)
			end, false, "ThrowGrenadeDelayFallback2")
		end

		local thread = task.delay(2, fallbackThrow)
		self.Janitor:Add(function()
			task.cancel(thread)
		end, false, "ThrowGrenadeDelayFallback3")
	end
end

function Grenade:Cancel()
	if self.ThrowFinished then
		return
	end

	self.Janitor:Remove("ThrowGrenadeFinished")
	self.Janitor:Remove("ThrowGrenadeStoppedFallback")
	self.Janitor:Remove("ThrowGrenadeDelayFallback2")
	self.Janitor:Remove("ThrowGrenadeDelayFallback3")
	self.ThrowFinished = false
	self.ThrowStarted = false
	self.ThrowCompleted = false
	self:stopAllAnimations()
	ReplicateCharacterAction("CancelThrow")
end

function Grenade:inspect()
	if self.IsInspecting then
		return
	end

	if self.ThrowStarted and not self.ThrowFinished then
		self:Cancel()
	end

	self.IsInspecting = true
	self:stopAllAnimations()
	local v2 = self.Viewmodel.Animation:play("Inspect")
	ReplicateCharacterAction("Inspect")
	task.delay(v2.Length, function()
		self.IsInspecting = false
	end)
end

function Grenade.reload(_) end

function Grenade:drop()
	if
		workspace:GetAttribute("Gamemode") == "Deathmatch"
		or GameState.GetState() == "Warmup"
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

function Grenade:equip()
	self.EquipTime = tick()
	self.Janitor:Remove("EquipDelayThrow")
	self.Viewmodel.Animation:stopAnimations()
	self.CharacterAnimator:stopAnimations()
	self.ThrowStarted = false
	self.ThrowFinished = false
	self.ThrowCompleted = false
	self.CharacterAnimator:play("Idle")
	self.CharacterAnimator:play("Equip")
	self.Viewmodel:equip(false)
	local thread = task.delay(0.7, function()
		if self.IsDestroyed or GameState.GetState() == "Buy Period" then
			return
		end

		if InputController.isActionPressed("Fire", { Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2 }) then
			self:StartThrow()
		end
	end)
	self.Janitor:Add(function()
		task.cancel(thread)
	end, false, "EquipDelayThrow")
end

function Grenade:unequip()
	self.Janitor:Remove("EquipDelayThrow")
	self.CharacterAnimator:stopAnimations()
	self.Viewmodel:unequip()
	self.IsInspecting = false

	if self.ThrowStarted and not self.ThrowFinished then
		self:Cancel()
	end
end

function Grenade.new(p, p2: string, p3: string, p4: number, p5: string, p6: string, p7: number, p8, p9, p10: string?, p11, p12, _)
	local self = setmetatable(WeaponComponent.new(p, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12), Grenade)
	self.IsInspecting = false
	self.ThrowStarted = false
	self.ThrowFinished = false
	self.ThrowCompleted = false
	self.LastThrowTime = 0
	self.EquipTime = 0
	return self
end

function Grenade:destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true

	if self.Janitor then
		self.Janitor:Destroy()
		self.Janitor = nil
	end

	self.ThrowFinished = nil
	self.ThrowStarted = nil
	self.ThrowCompleted = nil
	self.IsInspecting = nil
	WeaponComponent.destroy(self)
end

return Grenade