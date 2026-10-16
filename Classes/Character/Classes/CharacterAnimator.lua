local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local characterAnimations = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("CharacterAnimations")
local CharacterAnimator = {}
CharacterAnimator.__index = CharacterAnimator
local v = {
	["Add Suppressor"] = "AddSuppressor",
	["Remove Suppressor"] = "RemoveSuppressor",
	["Switch Fire Mode"] = "Switch"
}
local v2 = {
	FR = "ForwardRight",
	FL = "ForwardLeft",
	F = "Forward",
	BR = "BackwardRight",
	BL = "BackwardLeft",
	B = "Backward",
	R = "Right",
	L = "Left"
}
local v3 = nil

local function getMovementAnimationNames()
	if v3 then
		return v3
	end

	local result = { CharacterIdle = true }

	for _, childName in ipairs({ "Crouch", "Movement" }) do
		local folder = characterAnimations:FindFirstChild(childName)

		if not folder then
			continue
		end

		for _, animation in ipairs(folder:GetDescendants()) do
			if animation:IsA("Animation") then
				result[animation.Name] = true
			end
		end
	end

	v3 = result
	return result
end

function CharacterAnimator:play(p: string, ...)
	local animation = self.Animations[p]

	if animation then
		animation:Play(...)
	end

	return animation
end

function CharacterAnimator:stop(p: string, ...)
	local animation = self.Animations[p]

	if animation and animation.IsPlaying then
		animation:Stop(...)
	end
end

function CharacterAnimator:stopAnimations(value: number?)
	for _, animation in pairs(self.Animations) do
		if animation.IsPlaying then
			animation:Stop(value or 0)
		end
	end

	self.CurrentMovementAnimation = nil
	self.LastMovementAnimationSpeed = nil
	self.IsJumping = false
end

function CharacterAnimator.freezeAnimations(p)
	for _, animation in pairs(p.Animations) do
		if animation.IsPlaying then
			animation:AdjustSpeed(0)
		end
	end
end

function CharacterAnimator.adjustAnimationSpeed(p, p2: string, p3: number)
	local animation = p.Animations[p2]

	if animation then
		animation:AdjustSpeed(animation.Length / p3)
	end
end

function CharacterAnimator:unregister(p: string)
	local animation = self.Animations[p]

	if not animation then
		return
	end

	if animation.IsPlaying then
		animation:Stop()
	end

	self.Animations[p] = nil
	self.WeaponAnimationNames[p] = nil
	animation:Destroy()
end

function CharacterAnimator:register(p: string, p2)
	local animator = self.Animator

	if not animator then
		return
	end

	self:unregister(p)
	local success, result = pcall(animator.LoadAnimation, animator, p2)

	if success then
		self.Animations[p] = result
	end
end

local function stopActionAnimations(object)
	for k in pairs(object.WeaponAnimationNames) do
		if k ~= "Idle" then
			object:stop(k, 0.2)
		end
	end
end

function CharacterAnimator:setWeapon(weaponName: string?, weaponIdentifier: string?, flag: boolean?)
	if self.WeaponName == weaponName and self.WeaponIdentifier == weaponIdentifier then
		local idle = self.Animations.Idle

		if idle and not idle.IsPlaying then
			idle:Play()
		end
	else
		for k in pairs(self.WeaponAnimationNames) do
			self:unregister(k)
		end

		self.WeaponName = weaponName
		self.WeaponIdentifier = weaponIdentifier

		if not weaponName then
			return
		end

		local weaponProperties = GetWeaponProperties(weaponName)
		local characterAnimations2 = weaponProperties and weaponProperties.CharacterAnimations

		if not characterAnimations2 then
			return
		end

		for _, animation in ipairs(characterAnimations2:GetChildren()) do
			if not animation:IsA("Animation") then
				continue
			end

			self:register(animation.Name, animation)
			self.WeaponAnimationNames[animation.Name] = true
		end

		if self.Animations.Idle then
			self:play("Idle")
		end

		if flag and self.Animations.Equip then
			self:play("Equip", 0.2)
		end
	end
end

local function resolveActionAnimationName(object, p: string)
	local v4 = p == "NoSuppressorShoot" and "Shoot" or p
	local v5 = v[v4]

	if v5 then
		return v5
	end

	if v4 == "Swing1" or v4 == "Swing2" then
		if object.Animations[v4] then
			return v4
		end

		return "Swing"
	else
		if v4 ~= "Shoot" or not object.WeaponName then
			return v4
		end

		local weaponProperties = GetWeaponProperties(object.WeaponName)
		local v6

		if object.Player then
			v6 = object.Player:GetAttribute("ScopeIncrement")
		end

		if weaponProperties and weaponProperties.AimingOptions == "AutomaticScope" and (v6 or 0) > 0 then
			return "AimShoot"
		end

		return v4
	end
end

function CharacterAnimator:playAction(value: string)
	if typeof(value) ~= "string" or value == "" then
		return
	end

	if value == "Cancel Plant" or value == "CancelThrow" or value == "RevolverChargeCancel" then
		stopActionAnimations(self)
		return
	end

	local v4 = (value == "RevolverChargeStart" or value == "RevolverChargeRelease") and "Shoot" or value

	if v4 == "StartThrow" then
		stopActionAnimations(self)

		if self.Animations.StartThrow then
			self:play("StartThrow", 0.2)
		end

		if self.Animations.ThrowIdle then
			self:play("ThrowIdle")
		end
	else
		if v4 == "Throw" then
			self:stop("StartThrow", 0.2)
			self:stop("ThrowIdle", 0.2)
		end

		local actionAnimationName = resolveActionAnimationName(self, v4)

		if actionAnimationName and self.Animations[actionAnimationName] then
			stopActionAnimations(self)
			self:play(actionAnimationName, 0.2)
		end
	end
end

local function stopMovementAnimations(object)
	local movementAnimationNames = getMovementAnimationNames()

	for k, animation in pairs(object.Animations) do
		if k ~= "Jump" and movementAnimationNames[k] and animation.IsPlaying then
			object:stop(k, 0.2)
		end
	end
end

local function getMovementAnimationFromVelocity(object, vector: Vector3)
	local rootPart = object.RootPart

	if not rootPart then
		return nil
	end

	local v4 = vector * createVector(1, 0, 1)

	if v4.Magnitude < 0.1 then
		return nil
	end

	local cframe = rootPart.CFrame
	local unit = v4.Unit
	local dot = cframe.RightVector:Dot(unit)
	local dot2 = cframe.LookVector:Dot(unit)
	return v2[table.concat({
		dot2 > 0.3 and "F" or "",
		dot2 < -0.3 and "B" or "",
		dot < -0.3 and "L" or "",
		dot > 0.3 and "R" or ""
	})]
end

local function enterJumpState(object) -- 2 equivalent calls inferred from this helper
	local jump = object.Animations.Jump

	if jump ~= nil then
		if not jump.Looped then
			jump.Looped = true
		end

		if not jump.IsPlaying then
			object:play("Jump", 0.2)
		end
	end

	object.IsJumping = true
	object.CurrentMovementAnimation = nil
	object.LastMovementAnimationSpeed = nil
	stopMovementAnimations(object)
end

function CharacterAnimator.noteJumpEvent(object)
	if object.IsDestroyed then
		return
	end

	enterJumpState(object) -- inferred equivalent call
end

function CharacterAnimator:updateLocomotion(vector: Vector3, flag: boolean, flag2: boolean, flag3: boolean)
	if flag3 or flag then
		if self.IsJumping then
			self:stop("Jump", 0.2)
			self.IsJumping = false
		end

		local magnitude = (vector * createVector(1, 0, 1)).Magnitude
		local movementAnimationFromVelocity = getMovementAnimationFromVelocity(self, vector)
		local crouchIdle = self.Animations.CrouchIdle
		local currentMovementAnimation

		if flag2 then
			if magnitude > 0.1 and movementAnimationFromVelocity then
				currentMovementAnimation = `Crouch{movementAnimationFromVelocity}`

				if crouchIdle and crouchIdle.IsPlaying then
					self:stop("CrouchIdle", 0.2)
				end
			else
				self.LastMovementAnimationSpeed = nil

				if crouchIdle and not crouchIdle.IsPlaying then
					self.CurrentMovementAnimation = nil
					stopMovementAnimations(self)
					self:play("CrouchIdle", 0.2)
				end

				return
			end
		else
			if crouchIdle and crouchIdle.IsPlaying then
				self:stop("CrouchIdle", 0.2)
			end

			currentMovementAnimation = movementAnimationFromVelocity or "CharacterIdle"
		end

		local v4

		if currentMovementAnimation then
			v4 = self.Animations[currentMovementAnimation]
		end

		local v5 = self.CurrentMovementAnimation ~= currentMovementAnimation

		if v4 and currentMovementAnimation ~= "CharacterIdle" then
			local lastMovementAnimationSpeed2 = magnitude / (flag2 and 12 or 16)
			local lastMovementAnimationSpeed = self.LastMovementAnimationSpeed

			if
				v5
				or lastMovementAnimationSpeed == nil
				or math.abs(lastMovementAnimationSpeed2 - lastMovementAnimationSpeed) >= 0.03
			then
				v4:AdjustSpeed(lastMovementAnimationSpeed2)
				self.LastMovementAnimationSpeed = lastMovementAnimationSpeed2
			end
		else
			self.LastMovementAnimationSpeed = nil
		end

		if v5 then
			self.CurrentMovementAnimation = currentMovementAnimation
			stopMovementAnimations(self)
		end

		if v4 and not v4.IsPlaying then
			v4:Play(0.15)
		end
	else
		enterJumpState(self) -- inferred equivalent call
	end
end

function CharacterAnimator.new(character, p)
	local object = setmetatable({}, CharacterAnimator)
	object.Janitor = Janitor.new()
	object.Character = character
	object.RootPart = assert(
		CharacterResolver.getRootPart(character),
		`{character:GetFullName()} has no HumanoidRootPart`
	)
	object.Animator = assert(CharacterResolver.getAnimator(character), `{character:GetFullName()} has no Animator`)
	object.Animations = {}
	object.WeaponAnimationNames = {}
	object.IsJumping = false
	object.IsDestroyed = false

	if not (p and p.SkipBaseAnimations) then
		for _, animation in ipairs(characterAnimations:GetDescendants()) do
			if animation:IsA("Animation") then
				object:register(animation.Name, animation)
			end
		end
	end

	return object
end

function CharacterAnimator:destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true

	for _, animation in pairs(self.Animations) do
		if animation.IsPlaying then
			animation:Stop()
		end

		animation:Destroy()
	end

	table.clear(self.Animations)
	table.clear(self.WeaponAnimationNames)
	self.Janitor:Destroy()
	self.Animator = nil
	self.RootPart = nil
	self.Player = nil
end

return CharacterAnimator