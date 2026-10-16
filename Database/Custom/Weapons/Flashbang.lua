local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	Droppable = true,
	Team = "Both",
	Type = "Equipment",
	Class = "Grenade",
	Slot = "Grenade",
	ReverseIcon = "rbxassetid://132038996524430",
	Icon = "rbxassetid://132038996524430",
	Cost = 200,
	Range = 60,
	ArmorPenetration = 0.99,
	WalkSpeed = 19.796,
	RagdollMultiplier = 85,
	DamagePerPart = { Torso = 41, Head = 48, Arms = 31, Legs = 28 },
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations.Flashbang.CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations.Flashbang.CameraAnimations,
	ShowCrosshair = true
})