local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RecoilPatterns = require(ReplicatedStorage.Database.Components.Common.RecoilPatterns)
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	HasSuppressor = true,
	Automatic = false,
	Droppable = true,
	HasScope = false,
	Slot = "Secondary",
	WallbangMultiplier = 0.4,
	Class = "Weapon",
	ShootingOptions = "Default",
	Team = "Counter-Terrorists",
	AimingOptions = "None",
	Type = "Pistol",
	MuzzleType = "Pistol",
	ReverseIcon = "rbxassetid://93152953016540",
	Icon = "rbxassetid://131658947857971",
	Cost = 200,
	InventoryIconData = { ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(0.95, 0.95) },
	BulletsPerShot = 1,
	FireRate = 0.17,
	Range = 1200,
	RangeModifier = 0.91,
	ArmorPenetration = 0.505,
	Penetration = 0.14,
	Spread = {
		Range = NumberRange.new(0.5, 5),
		PerShot = 1.3,
		RecoverySpeed = 3,
		MovementMultiplier = 0.2
	},
	Recoil = {
		Pattern = RecoilPatterns["USP-S"],
		RecoverySpeed = 3.5,
		CameraScale = 0.5,
		Damper = 1,
		Speed = 25,
		Scale = 1
	},
	WalkSpeed = 19.392,
	RagdollMultiplier = 40,
	DamagePerPart = { Torso = 43, Head = 140, Arms = 34, Legs = 26 },
	ReloadAnimationCount = 1,
	Capacity = 24,
	Rounds = 12,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["USP-S"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["USP-S"].CameraAnimations,
	ShowCrosshair = true
})