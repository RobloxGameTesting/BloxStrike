local createVector = vector.create
local C4 = {}
C4.__index = C4
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local WeaponComponent = require(ReplicatedStorage.Classes.WeaponComponent)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local GetCharacterVelocity = require(ReplicatedStorage.Components.Common.GetCharacterVelocity)
local ReplicateCharacterAction = require(ReplicatedStorage.Components.Common.ReplicateCharacterAction)
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local CurrentCamera = workspace.CurrentCamera
local Debris = workspace:WaitForChild("Debris")
local v = nil
local now = -1e999
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function PlayerCanPlantC4()
	local localCharacter = CharacterResolver.getLocalCharacter()
	raycastParams.FilterDescendantsInstances = { localCharacter, CurrentCamera, Debris }

	if not (CharacterResolver.isAliveCharacter(localCharacter) and RuntimeKinematics.isOnGround(localCharacter)) then
		return false
	end

	local primaryPart = localCharacter.PrimaryPart

	if not primaryPart then
		return false
	end

	local filterDescendantsInstances = { CurrentCamera, Debris }

	for _, v2 in ipairs(Players:GetPlayers()) do
		if v2.Character then
			table.insert(filterDescendantsInstances, v2.Character)
		end
	end

	local map = workspace:FindFirstChild("Map")
	local barriers

	if map then
		barriers = map:FindFirstChild("Barriers")
	end

	if barriers then
		table.insert(filterDescendantsInstances, barriers)
	end

	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	local raycastResult = workspace:Raycast(primaryPart.Position, createVector(-0, -5, -0), raycastParams)

	if raycastResult and raycastResult.Instance:HasTag("PlantArea") and raycastResult.Instance:GetAttribute("Site") then
		return true
	end

	return false
end

local function GetHoldToPlantMessage() -- 1 equivalent call inferred from this helper
	if UserInputService.PreferredInput == Enum.PreferredInput.Touch then
		return "Keep holding the <b>Shoot</b> button until the bomb is planted"
	end

	local Tips = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Tips)
	local actionKeyText = Tips.GetActionKeyText("Fire")

	if actionKeyText then
		return `Keep holding <b>{actionKeyText}</b> until the bomb is planted`
	end

	return "Keep holding the fire button until the bomb is planted"
end

local function NotifyPlantCancelled(p: string?)
	local v2 = nil
	local v3

	if p == nil and IsTutorialMode() then
		v3 = GetHoldToPlantMessage() -- inferred equivalent call
	else
		v3 = p == "LeftPlantArea"
			and CharacterResolver.isAliveCharacter(CharacterResolver.getLocalCharacter())
			and "Stay on the ground inside the bombsite until the bomb is planted"
			or v2
	end

	if not v3 or os.clock() - now < 2 then
		return
	end

	now = os.clock()
	Router.broadcastRouter("CreateNotification", "Plant Cancelled", v3, 3)
end

local function NotifyPlantOffSite()
	local localCharacter = CharacterResolver.getLocalCharacter()

	if not (IsTutorialMode() and CharacterResolver.isAliveCharacter(localCharacter)) or os.clock() - now < 2 then
		return
	end

	now = os.clock()
	local v2 = RuntimeKinematics.isOnGround(localCharacter) and "Plant the bomb at the bombsite"
		or "Stand on the ground inside the bombsite to plant the bomb"
	Router.broadcastRouter("CreateNotification", "Can't Plant Here", v2, 3)
end

function C4:stopAllAnimations()
	if not (self.CharacterAnimator and self.Viewmodel and self.Viewmodel.Animation) then
		return
	end

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

	self.Viewmodel.Animation:stopSounds()
end

function C4.reload(_) end

function C4:shoot()
	if self.IsPlanting then
		return
	end

	local now2 = tick()

	if now2 - self.PlantStartedTick < 0.5 then
		return
	end

	self.Janitor:Remove("BombAnimationEnded")

	if not PlayerCanPlantC4() then
		NotifyPlantOffSite()
		return
	end

	self.IsInspecting = false
	self.IsPlanting = true
	self.PlantStartedTick = now2
	self:stopAllAnimations()
	ReplicateCharacterAction("Use")
	local v2 = self.Viewmodel.Animation:play("Use")
	self.CharacterAnimator:play("Use")
	Remotes.C4.Start.Send(self.Identifier)
	Router.broadcastRouter("Plant Bomb")
	self.Janitor:Add(v2.Ended:Connect(function()
		if self.IsPlanting then
			if PlayerCanPlantC4() then
				Remotes.C4.Planted.Send(self.Identifier)
				self.IsPlanting = false
			end

			Router.broadcastRouter("Cancel Bomb Plant")
		end
	end), "Disconnect", "BombAnimationEnded")
end

function C4:cancel(p: string?)
	if not self.IsPlanting then
		return
	end

	self.Viewmodel.Model.Weapon.Interactive.SurfaceGui.TextLabel.Text = "*******"
	self.IsPlanting = false
	self:stopAllAnimations()
	ReplicateCharacterAction("Cancel Plant")
	Remotes.C4.Cancel.Send(self.Identifier)
	Router.broadcastRouter("Cancel Bomb Plant")
	self.Janitor:Remove("BombAnimationEnded")
	NotifyPlantCancelled(p)
end

function C4:inspect()
	if self.IsInspecting or self.IsPlanting then
		return
	end

	self.IsInspecting = true
	self:stopAllAnimations()
	local v2 = self.Viewmodel.Animation:play("Inspect")
	ReplicateCharacterAction("Inspect")
	task.delay(v2.Length, function()
		self.IsInspecting = false
	end)
end

function C4:drop()
	if
		workspace:GetAttribute("Gamemode") == "Deathmatch"
		or GameState.GetState() == "Warmup"
		or IsTutorialMode()
		or self.IsPlanting
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

function C4:equip()
	self.Viewmodel.Animation:stopAnimations()
	self.CharacterAnimator:stopAnimations()
	self.CharacterAnimator:play("Idle")
	self.CharacterAnimator:play("Equip")
	self.Viewmodel:equip(false)
	v = self
end

function C4:unequip()
	if self.IsPlanting then
		self:cancel("Unequipped")
	end

	self.CharacterAnimator:stopAnimations()
	self.Viewmodel:unequip()

	if v and v == self then
		v = nil
	end
end

function C4.new(p, p2: string, p3: string, p4: number, p5: string, p6: string, p7: number, p8, p9, p10: string?, p11, p12, _)
	local object = setmetatable(WeaponComponent.new(p, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12), C4)
	object.IsInspecting = false
	object.IsPlanting = false
	object.PlantStartedTick = 0
	object.Janitor:Add(RunServiceController.BindToHeartbeat(`Components.C4.{p2}.PlantValidation`, function(_: number)
		if object.IsPlanting and not PlayerCanPlantC4() then
			object:cancel("LeftPlantArea")
		end
	end))
	return object
end

function C4:destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true

	if self.IsPlanting then
		self:cancel("Destroyed")
	end

	if v and v == self then
		v = nil
	end

	if self.Janitor then
		self.Janitor:Destroy()
		self.Janitor = nil
	end

	self.PlantStartedTick = nil
	self.IsInspecting = nil
	self.IsPlanting = nil
	WeaponComponent.destroy(self)
end

Remotes.C4.ForceCancel.Listen(function()
	if v and v.IsPlanting then
		v:cancel("Server")
	end
end)
return C4