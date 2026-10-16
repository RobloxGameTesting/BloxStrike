local Melee = {}
Melee.__index = Melee
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local HapticsController = require(ReplicatedStorage.Controllers.HapticsController)
local SoundController = require(ReplicatedStorage.Controllers.SoundController)
local InputController = require(ReplicatedStorage.Controllers.InputController)
local GetRayIgnore = require(ReplicatedStorage.Components.Common.GetRayIgnore)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local GetCharacterVelocity = require(ReplicatedStorage.Components.Common.GetCharacterVelocity)
local ReplicateCharacterAction = require(ReplicatedStorage.Components.Common.ReplicateCharacterAction)
local WeaponTimings = require(ReplicatedStorage.Components.Common.WeaponTimings)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local CreateBloodSplatter = require(ReplicatedStorage.Components.Common.VFXLibary.CreateBloodSplatter)
local CreateMarker = require(ReplicatedStorage.Components.Common.VFXLibary.CreateMarker)
local CreateImpact = require(ReplicatedStorage.Components.Common.VFXLibary.CreateImpact)
local BreakGlass = require(ReplicatedStorage.Components.Common.VFXLibary.BreakGlass)
local WeaponComponent = require(ReplicatedStorage.Classes.WeaponComponent)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local function isPlayer(instance)
	return CharacterResolver.isPlayerCharacter(instance and instance:FindFirstAncestorOfClass("Model") or nil)
end

local function cancelThreadField(p, p2: string) -- 9 equivalent calls inferred from this helper
	local v = p[p2]

	if v then
		task.cancel(v)
		p[p2] = nil
	end
end

local function isCurrentEquipped(p: string)
	return HttpService:JSONDecode(LocalPlayer:GetAttribute("CurrentEquipped") or "[]").Identifier == p
end

local function isBackStab(p, model)
	local rootPart = CharacterResolver.getRootPart(p)
	local rootPart2 = CharacterResolver.getRootPart(model)

	if rootPart and rootPart2 then
		return math.deg((math.acos((rootPart2.CFrame.LookVector:Dot((rootPart.Position - rootPart2.Position).Unit))))) > 100
	end
end

local function getBotVictimKey(instance)
	local model = instance:FindFirstAncestorOfClass("Model")

	while model ~= nil and model:GetAttribute("Bot") ~= true do
		model = model:FindFirstAncestorOfClass("Model")
	end

	local combatants = ReplicatedStorage:FindFirstChild("Combatants")
	local child

	if not (model == nil or combatants == nil) then
		child = combatants:FindFirstChild((tostring(model:GetAttribute("CombatantId"))))
	end

	local userId

	if child ~= nil then
		userId = child:GetAttribute("UserId")
	end

	if typeof(userId) == "number" then
		return userId
	end

	return nil
end

local function scheduleInspectEnd(object, length: number) -- 2 equivalent calls inferred from this helper
	object.InspectDelayThread = task.delay(length, function()
		if not object.IsDestroyed then
			object.InspectDelayThread = nil
			object.IsInspecting = false
		end
	end)
end

local function resetActionState(p) -- 3 equivalent calls inferred from this helper
	p.IsInspectFadingOut = false
	p.IsInspecting = false
	p.IsShooting = false
	p.IsFireHeld = false
end

function Melee:stopAllAnimations()
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

function Melee:reload()
	if self.IsInspecting or self.IsInspectFadingOut then
		self:cancelInspect(0.25)
	end
end

function Melee:shoot(flag: boolean?)
	local playerCharacter = CharacterResolver.getPlayerCharacter(self.Player)

	if
		tick() - self.WeaponEquippedTick <= WeaponTimings.MELEE_EQUIP_LOCKOUT
		or not (playerCharacter and CharacterResolver.isAliveCharacter(playerCharacter))
	then
		return
	end

	if not self.Properties.FireRate or self.IsShooting then
		return
	end

	if self.IsInspecting or self.IsInspectFadingOut then
		self:cancelInspect(0.25)
	end

	self:stopAllAnimations()
	self.IsInspecting = false
	self.IsInspectFadingOut = false
	self.IsShooting = true
	Router.broadcastRouter(
		"UpdatePlayerNoiseCone",
		"Melee",
		playerCharacter.PrimaryPart.Position,
		SoundController.GetMeleeRange(self.Name),
		nil
	)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = GetRayIgnore()
	raycastParams.IgnoreWater = true
	local v = CurrentCamera.CFrame.LookVector * self.Properties.Range
	local position = CurrentCamera.CFrame.Position
	local raycastResult = workspace:Raycast(position, v, raycastParams)
		or workspace:Spherecast(position, 1.5, v, raycastParams)
	local formatted = `Swing{math.random(1, 2)}`
	local meleeAttack = flag and "Heavy Swing" or formatted

	if raycastResult then
		local instance = raycastResult.Instance
		local playerFromInstance = CharacterResolver.getPlayerFromInstance(instance)
		local v2

		if playerFromInstance == nil then
			v2 = getBotVictimKey(instance)
		end

		local position2 = raycastResult.Position
		local material = raycastResult.Material
		local normal = raycastResult.Normal
		local isPlayerCharacter = CharacterResolver.isPlayerCharacter
		local instanceModel

		if instance then
			instanceModel = instance:FindFirstAncestorOfClass("Model") or nil
		end

		if isPlayerCharacter(instanceModel) then
			local impactMaterial = CharacterResolver.getImpactMaterial(instance, "Blood Splatter")
			CreateImpact(instance, impactMaterial, position2, normal, false, true, true)

			if impactMaterial == "Blood Splatter" then
				CreateBloodSplatter(position2, CurrentCamera.CFrame.LookVector)
			end

			meleeAttack = flag
				and isBackStab(CharacterResolver.getLocalCharacter(), instance:FindFirstAncestorOfClass("Model"))
				and "BackStab"
				or meleeAttack
		else
			local parent = instance.Parent
			CreateImpact(instance, material.Name, position2, normal, false, true, true)

			if parent and parent:HasTag("BreakableGlass") then
				BreakGlass(instance, position2, v.Unit)
			elseif not instance:HasTag("BreakableGlass") then
				CreateMarker(instance, "Melee", position2, normal)
			end
		end

		local send = Remotes.Melee.MeleeAttack.Send
		local v3 = {
			Direction = CurrentCamera.CFrame.LookVector * self.Properties.Range,
			Material = raycastResult.Material.Name,
			Distance = raycastResult.Distance,
			Instance = 0,
			VictimUserId = 0,
			HitPartName = 0,
			Position = 0,
			Normal = 0,
			MeleeAttack = 0,
			Identifier = 0
		}
		local instance2

		if playerFromInstance == nil and v2 == nil then
			instance2 = instance
		end

		v3.Instance = instance2
		local victimUserId

		if playerFromInstance == nil then
			victimUserId = v2
		else
			victimUserId = playerFromInstance.UserId
		end

		v3.VictimUserId = victimUserId
		local hitPartName

		if not (playerFromInstance == nil and v2 == nil) then
			hitPartName = instance.Name
		end

		v3.HitPartName = hitPartName
		v3.Position = raycastResult.Position
		v3.Normal = raycastResult.Normal
		v3.MeleeAttack = meleeAttack
		v3.Identifier = self.Identifier
		send(v3)
	end

	ReplicateCharacterAction(meleeAttack)
	self.Viewmodel.Animation:play(meleeAttack)
	local v2 = (meleeAttack == "Swing1" or meleeAttack == "Swing") and "Swing" or meleeAttack
	HapticsController.vibrate(Enum.VibrationMotor.Small, 1.15, 0.2)
	self.CharacterAnimator:play(v2)
	task.delay(self.Properties.FireRate * (flag and 2.05 or 1), function()
		if not self.IsDestroyed then
			self.IsShooting = false
			local identifier = self.Identifier

			if HttpService:JSONDecode(LocalPlayer:GetAttribute("CurrentEquipped") or "[]").Identifier ~= identifier then
				return
			end

			local v3 = InputController.isActionPressed("Fire", {
					Enum.UserInputType.MouseButton1,
					Enum.KeyCode.ButtonR2
				})
				or self.IsFireHeld
			local actionPressed = InputController.isActionPressed("Secondary Fire", {
				Enum.UserInputType.MouseButton2,
				Enum.KeyCode.ButtonL2
			})

			if v3 or actionPressed then
				self:shoot(actionPressed)
			end
		end
	end)
end

function Melee:cancelInspect(value: number?, value2: number?)
	if not (self.IsInspecting or self.IsInspectFadingOut) then
		return
	end

	cancelThreadField(self, "InspectDelayThread") -- inferred equivalent call
	local v = value or 1.2
	self.IsInspectFadingOut = true
	self.IsInspecting = false
	self.Viewmodel.Animation:markInspectCancel()
	cancelThreadField(self, "CancelDelayThread") -- inferred equivalent call
	cancelThreadField(self, "FadeCompleteThread") -- inferred equivalent call
	self.CancelDelayThread = task.delay(value2 or 0.3, function()
		if self.IsDestroyed or not self.IsInspectFadingOut then
			return
		end

		self.Viewmodel.Animation:crossfadeTo("Idle", v)
		self.FadeCompleteThread = task.delay(v, function()
			if not self.IsDestroyed then
				self.FadeCompleteThread = nil
				self.IsInspectFadingOut = false
			end
		end)
	end)
end

function Melee:inspect()
	if self.IsShooting or self.IsInspecting and not self.IsInspectFadingOut then
		return
	end

	local isInspectFadingOut = self.IsInspectFadingOut == true

	if isInspectFadingOut then
		self.IsInspectFadingOut = false
		cancelThreadField(self, "CancelDelayThread") -- inferred equivalent call
		cancelThreadField(self, "FadeCompleteThread") -- inferred equivalent call
		self.Viewmodel.Animation:cancelCrossfade()
	end

	self.IsInspecting = true
	self.IsShooting = false
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
		local v = self.Viewmodel.Animation:play(inspectVariant)
		ReplicateCharacterAction("Inspect")
		scheduleInspectEnd(self, v.Length) -- inferred equivalent call
	end
end

function Melee:drop()
	if
		workspace:GetAttribute("Gamemode") == "Deathmatch"
		or GameState.GetState() == "Warmup"
		or workspace:GetAttribute("VIPKnifeDropEnabled") ~= true
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

function Melee:equip()
	self.Viewmodel.Animation:stopAnimations()
	self.CharacterAnimator:stopAnimations()
	self.CharacterAnimator:play("Idle")
	self.CharacterAnimator:play("Equip")
	self.WeaponEquippedTick = tick()
	self.Viewmodel:equip(false)
	resetActionState(self) -- inferred equivalent call
end

function Melee:unequip()
	self.CharacterAnimator:stopAnimations()
	self.Viewmodel:unequip()
	resetActionState(self) -- inferred equivalent call
end

function Melee.new(p, p2: string, p3: string, p4: number, p5: string, p6: string, p7: number, p8, p9, p10: string?, p11, p12, _)
	local self = setmetatable(WeaponComponent.new(p, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12), Melee)
	resetActionState(self) -- inferred equivalent call
	self.AlternativeSwitchTick = 0
	self.WeaponEquippedTick = 0
	return self
end

function Melee:destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true
	cancelThreadField(self, "InspectDelayThread") -- inferred equivalent call
	cancelThreadField(self, "CancelDelayThread") -- inferred equivalent call
	cancelThreadField(self, "FadeCompleteThread") -- inferred equivalent call

	if self.Janitor then
		self.Janitor:Destroy()
		self.Janitor = nil
	end

	self.IsInspectFadingOut = nil
	self.IsInspecting = nil
	self.IsShooting = nil
	self.IsFireHeld = nil
	self.AlternativeSwitchTick = nil
	self.WeaponEquippedTick = nil
	WeaponComponent.destroy(self)
end

return Melee