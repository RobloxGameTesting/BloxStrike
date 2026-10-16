local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RecoilPatterns = require(ReplicatedStorage.Database.Components.Common.RecoilPatterns)
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	HasSuppressor = false,
	Automatic = false,
	Droppable = true,
	HasScope = false,
	Slot = "Secondary",
	WallbangMultiplier = 0.35,
	Class = "Weapon",
	ShootingOptions = "Burst",
	Team = "Terrorists",
	AimingOptions = "None",
	Type = "Pistol",
	MuzzleType = "Pistol",
	ReverseIcon = "rbxassetid://103283372012613",
	Icon = "rbxassetid://101406018897044",
	Cost = 200,
	InventoryIconData = {
		Position = UDim2.fromScale(0.5, 0.48),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.95, 0.95)
	},
	BulletsPerShot = 1,
	FireRate = 0.15,
	Range = 1200,
	RangeModifier = 0.85,
	ArmorPenetration = 0.473,
	Penetration = 0.14,
	Spread = {
		Range = NumberRange.new(1, 6.4),
		PerShot = 1.8,
		RecoverySpeed = 6,
		MovementMultiplier = 0.25
	},
	Recoil = {
		Pattern = RecoilPatterns["Glock-18"],
		RecoverySpeed = 4,
		CameraScale = 0.4,
		Damper = 1,
		Speed = 23,
		Scale = 0.9
	},
	WalkSpeed = 19.392,
	RagdollMultiplier = 35,
	DamagePerPart = { Torso = 37, Head = 118, Arms = 29, Legs = 22 },
	ReloadAnimationCount = 1,
	Capacity = 120,
	Rounds = 20,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["Glock-18"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["Glock-18"].CameraAnimations,
	ShowCrosshair = true
})