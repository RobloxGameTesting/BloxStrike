local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RecoilPatterns = require(ReplicatedStorage.Database.Components.Common.RecoilPatterns)
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	HasSuppressor = false,
	Automatic = true,
	Droppable = true,
	HasScope = false,
	Slot = "Primary",
	WallbangMultiplier = 0.6,
	Class = "Weapon",
	ShootingOptions = "Default",
	Team = "Terrorists",
	AimingOptions = "None",
	Type = "SMG",
	MuzzleType = "SMG",
	ReverseIcon = "rbxassetid://74151990961277",
	Icon = "rbxassetid://83671879972945",
	Cost = 1050,
	InventoryIconData = { ScaleType = Enum.ScaleType.Fit, Size = UDim2.fromScale(1, 1) },
	BulletsPerShot = 1,
	FireRate = 0.075,
	Range = 1200,
	RangeModifier = 0.8,
	ArmorPenetration = 0.575,
	Penetration = 0,
	Spread = {
		Range = NumberRange.new(1, 4.5),
		JumpShotMinimum = 40,
		PerShot = 0.35,
		RecoverySpeed = 4.25,
		MovementMultiplier = 0.2
	},
	Recoil = {
		Pattern = RecoilPatterns["MAC-10"],
		RecoverySpeed = 6,
		CameraScale = 0.55,
		Damper = 1,
		Speed = 26,
		Scale = 2
	},
	WalkSpeed = 19.392,
	RagdollMultiplier = 55,
	DamagePerPart = { Torso = 35, Head = 114, Arms = 28, Legs = 21 },
	ReloadAnimationCount = 1,
	Capacity = 100,
	Rounds = 30,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["MAC-10"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["MAC-10"].CameraAnimations,
	ShowCrosshair = true
})