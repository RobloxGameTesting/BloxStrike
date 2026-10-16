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
	Team = "Counter-Terrorists",
	AimingOptions = "AutomaticScope",
	Type = "Rifle",
	MuzzleType = "Rifle",
	ReverseIcon = "rbxassetid://125463512677698",
	Icon = "rbxassetid://119885531832389",
	Cost = 3300,
	InventoryIconData = {
		Position = UDim2.fromScale(0.5, 0.45),
		ScaleType = Enum.ScaleType.Crop,
		Size = UDim2.fromScale(1, 1)
	},
	BulletsPerShot = 1,
	FireRate = 0.1,
	Range = 1200,
	RangeModifier = 0.98,
	ArmorPenetration = 0.9,
	Penetration = 0.65,
	Spread = {
		Range = NumberRange.new(0.05, 2),
		PerShot = 0.7,
		RecoverySpeed = 5.5,
		MovementMultiplier = 1.4
	},
	Recoil = {
		Pattern = RecoilPatterns.AUG,
		RecoverySpeed = 7,
		CameraScale = 0.5,
		Damper = 1,
		Speed = 25,
		Scale = 1.7
	},
	WalkSpeed = 17.776,
	RagdollMultiplier = 45,
	DamagePerPart = { Torso = 36, Head = 101, Arms = 30, Legs = 19 },
	ReloadAnimationCount = 1,
	Capacity = 90,
	Rounds = 30,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations.AUG.CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations.AUG.CameraAnimations,
	ShowCrosshair = true
})