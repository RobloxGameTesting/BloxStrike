local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RecoilPatterns = require(ReplicatedStorage.Database.Components.Common.RecoilPatterns)
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	HasSuppressor = false,
	Automatic = false,
	Droppable = true,
	HasScope = false,
	Slot = "Secondary",
	WallbangMultiplier = 0.8,
	Class = "Weapon",
	ShootingOptions = "Default",
	Team = "Both",
	AimingOptions = "None",
	Type = "Pistol",
	MuzzleType = "Pistol",
	ReverseIcon = "rbxassetid://101910609893699",
	Icon = "rbxassetid://122477921917392",
	Cost = 700,
	BulletsPerShot = 1,
	FireRate = 0.225,
	Range = 1200,
	RangeModifier = 0.81,
	ArmorPenetration = 0.932,
	Penetration = 0.65,
	Spread = {
		Range = NumberRange.new(0.5, 12.5),
		PerShot = 12,
		RecoverySpeed = 7.5,
		MovementMultiplier = 2.2
	},
	Recoil = {
		Pattern = RecoilPatterns["Desert Eagle"],
		RecoverySpeed = 2.5,
		CameraScale = 0.8,
		Damper = 0.7,
		Speed = 18,
		Scale = 1.6
	},
	WalkSpeed = 18.584,
	RagdollMultiplier = 42,
	DamagePerPart = { Torso = 75, Head = 250, Arms = 60, Legs = 45 },
	ReloadAnimationCount = 1,
	Capacity = 35,
	Rounds = 7,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["Desert Eagle"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["Desert Eagle"].CameraAnimations,
	ShowCrosshair = true
})