local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RecoilPatterns = require(ReplicatedStorage.Database.Components.Common.RecoilPatterns)
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	HasSuppressor = false,
	Automatic = false,
	Droppable = true,
	HasScope = false,
	Slot = "Primary",
	WallbangMultiplier = 0.5,
	Class = "Weapon",
	ShootingOptions = "Default",
	Team = "Both",
	AimingOptions = "None",
	Type = "Heavy",
	MuzzleType = "ShotGun",
	ReverseIcon = "rbxassetid://84241192314676",
	Icon = "rbxassetid://127273982496076",
	Cost = 1050,
	InventoryIconData = { ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1) },
	BulletsPerShot = 9,
	FireRate = 0.88,
	Range = 120,
	RangeModifier = 0.7,
	ArmorPenetration = 0.5,
	Penetration = 0,
	Spread = {
		Range = NumberRange.new(8, 8),
		JumpShotMinimum = 15,
		PerShot = 4,
		RecoverySpeed = 4.25,
		MovementMultiplier = 0.3
	},
	Recoil = {
		Pattern = RecoilPatterns.Nova,
		RecoverySpeed = 6,
		CameraScale = 1,
		Damper = 1,
		Speed = 26,
		Scale = 1
	},
	WalkSpeed = 17.776,
	RagdollMultiplier = 75,
	DamagePerPart = { Torso = 34, Head = 106, Arms = 28, Legs = 20 },
	ReloadAnimationCount = 8,
	Capacity = 32,
	Rounds = 8,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations.Nova.CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations.Nova.CameraAnimations,
	ShowCrosshair = true
})