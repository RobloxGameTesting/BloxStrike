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
	ReverseIcon = "rbxassetid://135022102978537",
	Icon = "rbxassetid://115344320193773",
	Cost = 2000,
	InventoryIconData = { ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1) },
	BulletsPerShot = 6,
	FireRate = 0.35,
	Range = 120,
	RangeModifier = 0.7,
	ArmorPenetration = 0.8,
	Penetration = 0.14,
	Spread = {
		Range = NumberRange.new(8, 12),
		JumpShotMinimum = 12,
		PerShot = 0.85,
		RecoverySpeed = 4.25,
		MovementMultiplier = 0.3
	},
	Recoil = {
		Pattern = RecoilPatterns.XM1014,
		RecoverySpeed = 6,
		CameraScale = 1,
		Damper = 1,
		Speed = 26,
		Scale = 1
	},
	WalkSpeed = 17.372,
	RagdollMultiplier = 75,
	DamagePerPart = { Torso = 26, Head = 82, Arms = 22, Legs = 17 },
	ReloadAnimationCount = 7,
	Capacity = 32,
	Rounds = 7,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations.XM1014.CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations.XM1014.CameraAnimations,
	ShowCrosshair = true
})