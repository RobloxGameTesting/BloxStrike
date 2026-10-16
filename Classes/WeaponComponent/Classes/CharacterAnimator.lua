local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterAnimator = require(ReplicatedStorage.Classes.Character.Classes.CharacterAnimator)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local CharacterAnimator2 = {}
CharacterAnimator2.__index = CharacterAnimator2

local function bind(object, p)
	if object._animator then
		object._animator:destroy()
		object._animator = nil
		object.Animations = {}
	end

	if object.IsDestroyed or not p then
		return
	end

	local animator = CharacterAnimator.new(p, { SkipBaseAnimations = true })
	animator.Player = object.Player
	animator.WeaponName = object.Weapon
	local weaponProperties = GetWeaponProperties(object.Weapon)
	local characterAnimations = weaponProperties and weaponProperties.CharacterAnimations

	if characterAnimations then
		for _, animation in ipairs(characterAnimations:GetChildren()) do
			if not animation:IsA("Animation") then
				continue
			end

			animator:register(animation.Name, animation)
			animator.WeaponAnimationNames[animation.Name] = true
		end
	end

	object._animator = animator
	object.Animations = animator.Animations
end

function CharacterAnimator2.getAnimation(p, p2: string)
	return p.Animations[p2]
end

function CharacterAnimator2:play(p: string, ...)
	local animator = self._animator

	if animator then
		return (animator:play(p, ...))
	end

	return nil
end

function CharacterAnimator2:stop(p: string, ...)
	local animator = self._animator

	if animator then
		animator:stop(p, ...)
	end
end

function CharacterAnimator2:stopAnimations(p: number?)
	local animator = self._animator

	if animator then
		animator:stopAnimations(p)
	end
end

function CharacterAnimator2:adjustAnimationSpeed(p: string, p2: number)
	local animator = self._animator

	if animator then
		animator:adjustAnimationSpeed(p, p2)
	end
end

function CharacterAnimator2.new(player, weapon: string, p)
	local object = setmetatable({}, CharacterAnimator2)
	object.Janitor = Janitor.new()
	object.IsDestroyed = false
	object.Player = player
	object.Weapon = weapon
	object.Animations = {}

	if p then
		bind(object, p)
		return object
	end

	object.Janitor:Add(CharacterResolver.observeCharacter(player, function(p2)
		bind(object, p2)
	end))
	return object
end

function CharacterAnimator2:destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true

	if self._animator then
		self._animator:destroy()
		self._animator = nil
	end

	self.Animations = {}
	self.Janitor:Destroy()
end

return CharacterAnimator2