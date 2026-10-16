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
	Team = "Terrorists",
	AimingOptions = "None",
	Type = "Heavy",
	MuzzleType = "ShotGun",
	ReverseIcon = "rbxassetid://102157038423883",
	Icon = "rbxassetid://117478678996500",
	Cost = 1100,
	InventoryIconData = { ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1) },
	BulletsPerShot = 8,
	FireRate = 0.8,
	Range = 120,
	RangeModifier = 0.5,
	ArmorPenetration = 0.7,
	Penetration = 0.14,
	Spread = {
		Range = NumberRange.new(11.5, 11.5),
		JumpShotMinimum = 15,
		PerShot = 5,
		RecoverySpeed = 4.25,
		MovementMultiplier = 0.3
	},
	Recoil = {
		Pattern = RecoilPatterns["Sawed-Off"],
		RecoverySpeed = 6,
		CameraScale = 1,
		Damper = 1,
		Speed = 26,
		Scale = 1
	},
	WalkSpeed = 16.968,
	RagdollMultiplier = 75,
	DamagePerPart = { Torso = 42, Head = 125, Arms = 32, Legs = 25 },
	ReloadAnimationCount = 7,
	Capacity = 32,
	Rounds = 7,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["Sawed-Off"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["Sawed-Off"].CameraAnimations,
	ShowCrosshair = true
})