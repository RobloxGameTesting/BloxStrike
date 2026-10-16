local v = {
	Attributes = table.freeze({
		CharacterName = "PresentationCharacterName",
		Generation = "PresentationGeneration",
		SpawnPosition = "PresentationSpawnPosition",
		SpawnYaw = "PresentationSpawnYaw",
		BodyColor = "PresentationBodyColor",
		EquippedGloves = "PresentationEquippedGloves",
		Health = "Health",
		MaxHealth = "MaxHealth"
	}),
	OwnedAttribute = "ClientOwnedCharacterPresentation",
	OwnerUserIdAttribute = "PresentationOwnerUserId",
	VisibleAttribute = "ClientCharacterPresentationVisible"
}
return table.freeze(v)