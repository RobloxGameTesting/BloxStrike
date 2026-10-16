local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
return table.freeze({
	Droppable = true,
	Slot = "C4",
	Class = "C4",
	Team = "Terrorists",
	Type = "Miscellaneous",
	ReverseIcon = "rbxassetid://109858795365969",
	Icon = "rbxassetid://109858795365969",
	Range = 1200,
	WalkSpeed = 20.2,
	CharacterAnimations = ReplicatedStorage.Assets.WeaponAnimations.C4.CharacterAnimations,
	CameraAnimations = ReplicatedStorage.Assets.WeaponAnimations.C4.CameraAnimations,
	RagdollMultiplier = 35,
	ShowCrosshair = false
})