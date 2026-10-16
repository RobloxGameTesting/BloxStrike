local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	Droppable = true,
	Team = "Both",
	Type = "Equipment",
	Class = "Grenade",
	Slot = "Grenade",
	ReverseIcon = "rbxassetid://81385239843859",
	Icon = "rbxassetid://81385239843859",
	Cost = 50,
	Range = 60,
	ArmorPenetration = 0.99,
	WalkSpeed = 19.796,
	RagdollMultiplier = 85,
	DamagePerPart = { Torso = 41, Head = 48, Arms = 31, Legs = 28 },
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations["Decoy Grenade"].CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations["Decoy Grenade"].CameraAnimations,
	ShowCrosshair = true
})