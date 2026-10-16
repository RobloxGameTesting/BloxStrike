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
	Team = "Both",
	AimingOptions = "None",
	Type = "Heavy",
	MuzzleType = "MachineGun",
	ReverseIcon = "rbxassetid://75806785943496",
	Icon = "rbxassetid://134163874921903",
	Cost = 1700,
	InventoryIconData = { ScaleType = Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1) },
	BulletsPerShot = 1,
	FireRate = 0.075,
	Range = 1200,
	RangeModifier = 0.93,
	ArmorPenetration = 0.75,
	Penetration = 0.65,
	Spread = {
		Range = NumberRange.new(0.5, 5.5),
		JumpShotMinimum = 15,
		PerShot = 2.5,
		RecoverySpeed = 4,
		MovementMultiplier = 3
	},
	Recoil = {
		Pattern = RecoilPatterns.Negev,
		RecoverySpeed = 6,
		CameraScale = 0.55,
		Damper = 1,
		Speed = 26,
		Scale = 2.7
	},
	WalkSpeed = 12.12,
	RagdollMultiplier = 65,
	DamagePerPart = { Torso = 36, Head = 115, Arms = 30, Legs = 24 },
	ReloadAnimationCount = 1,
	Capacity = 300,
	Rounds = 150,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations.Negev.CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations.Negev.CameraAnimations,
	ShowCrosshair = true
})