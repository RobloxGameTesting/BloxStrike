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
	ShootingOptions = "Default",
	Team = "Both",
	AimingOptions = "None",
	Type = "Pistol",
	MuzzleType = "Pistol",
	ReverseIcon = "rbxassetid://116440682239559",
	Icon = "rbxassetid://73666032770570",
	Cost = 300,
	InventoryIconData = {
		Position = UDim2.fromScale(0.5, 0.48),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.95, 0.95)
	},
	BulletsPerShot = 1,
	FireRate = 0.15,
	Range = 1200,
	RangeModifier = 0.9,
	ArmorPenetration = 0.64,
	Penetration = 0.14,
	Spread = {
		Range = NumberRange.new(1.5, 14.15),
		PerShot = 3.2,
		RecoverySpeed = 4.5,
		MovementMultiplier = 0.22
	},
	Recoil = {
		Pattern = RecoilPatterns.P250,
		RecoverySpeed = 4,
		CameraScale = 0.4,
		Damper = 1,
		Speed = 23,
		Scale = 0.9
	},
	WalkSpeed = 19.392,
	RagdollMultiplier = 35,
	DamagePerPart = { Torso = 47, Head = 151, Arms = 38, Legs = 28 },
	ReloadAnimationCount = 1,
	Capacity = 26,
	Rounds = 13,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations.P250.CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations.P250.CameraAnimations,
	ShowCrosshair = true
})