local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RecoilPatterns = require(ReplicatedStorage.Database.Components.Common.RecoilPatterns)
require(ReplicatedStorage.Database.Custom.Types)
local WeaponAnimations = ReplicatedStorage.Assets:WaitForChild("WeaponAnimations")
local zeusx27 = WeaponAnimations:FindFirstChild("Zeus x27")
	or WeaponAnimations:FindFirstChild("Zeus X27")
	or WeaponAnimations:FindFirstChild("Zeus")
	or WeaponAnimations:FindFirstChild("Taser")
	or WeaponAnimations:WaitForChild("P250")
return table.freeze({
	HasSuppressor = false,
	Automatic = false,
	Droppable = true,
	HasScope = false,
	Slot = "Melee",
	WallbangMultiplier = 0,
	Class = "Weapon",
	ShootingOptions = "Default",
	Team = "Both",
	AimingOptions = "None",
	Type = "Pistol",
	MuzzleType = "Zeus x27",
	ReverseIcon = "rbxassetid://131579417467777",
	Icon = "rbxassetid://71464446190434",
	Cost = 200,
	InventoryIconData = {
		Position = UDim2.fromScale(0.5, 0.48),
		ScaleType = Enum.ScaleType.Fit,
		Size = UDim2.fromScale(0.95, 0.95)
	},
	BulletsPerShot = 1,
	FireRate = 0.15,
	Range = 13.584,
	RangeModifier = 0.011416,
	RechargeTime = 30,
	ArmorPenetration = 1,
	Penetration = 0.14,
	Spread = {
		Range = NumberRange.new(0.2, 3.5),
		PerShot = 0,
		RecoverySpeed = 10,
		MovementMultiplier = 0.04
	},
	Recoil = {
		Pattern = RecoilPatterns["Zeus x27"] or RecoilPatterns.P250,
		RecoverySpeed = 8,
		CameraScale = 0.2,
		Damper = 1,
		Speed = 20,
		Scale = 0.35
	},
	WalkSpeed = 17.776,
	RagdollMultiplier = 42,
	DamagePerPart = { Torso = 500, Head = 500, Arms = 500, Legs = 500 },
	ReloadAnimationCount = 1,
	Capacity = 0,
	Rounds = 1,
	CharacterAnimations = zeusx27.CharacterAnimations,
	CameraAnimations = zeusx27.CameraAnimations,
	ShowCrosshair = true
})