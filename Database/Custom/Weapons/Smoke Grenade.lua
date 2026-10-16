local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	Droppable = true,
	Team = "Terrorists",
	Type = "Equipment",
	Class = "Grenade",
	Slot = "Grenade",
	ReverseIcon = "rbxassetid://137305344844339",
	Icon = "rbxassetid://137305344844339",
	Cost = 300,
	Range = 60,
	ArmorPenetration = 0.99,
	WalkSpeed = 19.796,
	RagdollMultiplier = 85,
	DamagePerPart = { Torso = 41, Head = 48, Arms = 31, Legs = 28 },
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["Smoke Grenade"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["Smoke Grenade"].CameraAnimations,
	ShowCrosshair = true
})