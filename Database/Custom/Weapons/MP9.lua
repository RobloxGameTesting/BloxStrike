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
	Team = "Counter-Terrorists",
	AimingOptions = "None",
	Type = "SMG",
	MuzzleType = "SMG",
	ReverseIcon = "rbxassetid://98859371551950",
	Icon = "rbxassetid://135384625641866",
	Cost = 1250,
	InventoryIconData = {
		Position = UDim2.fromScale(0.5, 0.48),
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1)
	},
	BulletsPerShot = 1,
	FireRate = 0.07,
	Range = 1200,
	RangeModifier = 0.87,
	ArmorPenetration = 0.575,
	Penetration = 0,
	Spread = {
		Range = NumberRange.new(0.25, 2.25),
		JumpShotMinimum = 10,
		PerShot = 0.32,
		RecoverySpeed = 4.25,
		MovementMultiplier = 0.5
	},
	Recoil = {
		Pattern = RecoilPatterns.MP9,
		RecoverySpeed = 6,
		CameraScale = 0.55,
		Damper = 1,
		Speed = 26,
		Scale = 2.3
	},
	WalkSpeed = 19.392,
	RagdollMultiplier = 55,
	DamagePerPart = { Torso = 32, Head = 104, Arms = 26, Legs = 19 },
	ReloadAnimationCount = 1,
	Capacity = 120,
	Rounds = 30,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations.MP9.CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations.MP9.CameraAnimations,
	ShowCrosshair = true
})