local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RecoilPatterns = require(ReplicatedStorage.Database.Components.Common.RecoilPatterns)
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	HasSuppressor = false,
	Automatic = true,
	Droppable = true,
	HasScope = true,
	Slot = "Primary",
	WallbangMultiplier = 0.7,
	Class = "Weapon",
	ShootingOptions = "Default",
	Team = "Terrorists",
	AimingOptions = "AutomaticScope",
	Type = "Rifle",
	MuzzleType = "Rifle",
	ReverseIcon = "rbxassetid://89786542114704",
	Icon = "rbxassetid://133547075528778",
	Cost = 3000,
	InventoryIconData = { ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1) },
	BulletsPerShot = 1,
	FireRate = 0.1,
	Range = 1200,
	RangeModifier = 0.98,
	ArmorPenetration = 1,
	Penetration = 0.65,
	Spread = {
		Range = NumberRange.new(0.05, 3.25),
		JumpShotMinimum = 0,
		PerShot = 0.32,
		RecoverySpeed = 5.5,
		MovementMultiplier = 1.25
	},
	Recoil = {
		Pattern = RecoilPatterns["SG 553"],
		RecoverySpeed = 7,
		CameraScale = 0.5,
		Damper = 1,
		Speed = 25,
		Scale = 1.7
	},
	WalkSpeed = 16.968,
	RagdollMultiplier = 45,
	DamagePerPart = { Torso = 38, Head = 133, Arms = 30, Legs = 18 },
	ReloadAnimationCount = 1,
	Capacity = 90,
	Rounds = 30,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["SG 553"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["SG 553"].CameraAnimations,
	ShowCrosshair = true
})