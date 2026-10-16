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
	ShootingOptions = "Revolver",
	Team = "Both",
	AimingOptions = "None",
	Type = "Pistol",
	MuzzleType = "Pistol",
	ReverseIcon = "rbxassetid://127392244236728",
	Icon = "rbxassetid://112745953600473",
	Cost = 600,
	BulletsPerShot = 1,
	FireRate = 0.706,
	Range = 1200,
	RangeModifier = 0.98,
	ArmorPenetration = 0.92,
	Penetration = 0.14,
	Spread = {
		Range = NumberRange.new(0.52, 12.5),
		PerShot = 12,
		RecoverySpeed = 3.5,
		MovementMultiplier = 0.56
	},
	FireModes = {
		Primary = {
			InputBehavior = "Charge",
			ChargeTime = 0.2,
			ChargeStartSpread = 0.9,
			CancelOnRelease = true,
			HoldRepeat = true,
			FireRate = 0.43,
			HoldWalkSpeed = 14.544,
			Spread = {
				Range = NumberRange.new(0.52, 12.5),
				PerShot = 12,
				RecoverySpeed = 3.5,
				MovementMultiplier = 0.56
			}
		},
		Secondary = {
			InputBehavior = "Immediate",
			HoldRepeat = true,
			FireRate = 0.4,
			Animation = "SlamFire",
			CharacterAnimation = "SlamFire",
			Spread = {
				Range = NumberRange.new(12, 28),
				PerShot = 12,
				RecoverySpeed = 4.5,
				MovementMultiplier = 0.6
			}
		}
	},
	Recoil = {
		Pattern = RecoilPatterns["R8 Revolver"] or RecoilPatterns["Glock-18"],
		RecoverySpeed = 2.2,
		CameraScale = 0.85,
		Damper = 0.7,
		Speed = 16,
		Scale = 1.8
	},
	WalkSpeed = 17.776,
	RagdollMultiplier = 45,
	DamagePerPart = { Torso = 86, Head = 256, Arms = 69, Legs = 51 },
	ReloadAnimationCount = 1,
	Capacity = 16,
	Rounds = 8,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["R8 Revolver"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["R8 Revolver"].CameraAnimations,
	ShowCrosshair = true
})