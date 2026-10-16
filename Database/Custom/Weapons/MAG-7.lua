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
	Team = "Counter-Terrorists",
	AimingOptions = "None",
	Type = "Heavy",
	MuzzleType = "ShotGun",
	ReverseIcon = "rbxassetid://79977904375648",
	Icon = "rbxassetid://86291171438206",
	Cost = 1300,
	InventoryIconData = { ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1) },
	BulletsPerShot = 8,
	FireRate = 0.88,
	Range = 120,
	RangeModifier = 0.45,
	ArmorPenetration = 0.75,
	Penetration = 0.14,
	Spread = {
		Range = NumberRange.new(7.5, 10),
		JumpShotMinimum = 12,
		PerShot = 2.5,
		RecoverySpeed = 4.25,
		MovementMultiplier = 0.3
	},
	Recoil = {
		Pattern = RecoilPatterns["MAG-7"],
		RecoverySpeed = 6,
		CameraScale = 1,
		Damper = 1,
		Speed = 26,
		Scale = 1
	},
	WalkSpeed = 18.18,
	RagdollMultiplier = 75,
	DamagePerPart = { Torso = 38, Head = 122, Arms = 25, Legs = 23 },
	ReloadAnimationCount = 1,
	Capacity = 15,
	Rounds = 5,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["MAG-7"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["MAG-7"].CameraAnimations,
	ShowCrosshair = true
})