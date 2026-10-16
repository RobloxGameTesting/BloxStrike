local v = {
	PLUGIN_VERSION = 13,
	EXPORT_VERSION = 1,
	EXPORT_TRANSFORM = "IdentityWorldXYZV1",
	GEOMETRY_VERSION = 1,
	OCCLUDER_MARKER = "PVSOccluder",
	IGNORE_MARKER = "PVSIgnore",
	DYNAMIC_MARKER = "PVSDynamic",
	DYNAMIC_TAGS = table.freeze({
		"BreakableDoor",
		"BreakableGlass",
		"Ceiling Fan",
		"Flag",
		"Flower Pot",
		"Garage",
		"Market Window",
		"Snowman",
		"Television",
		"TugBoat",
		"Vent",
		"VertigoCar",
		"VertigoCrane",
		"VertigoGenerator",
		"Water"
	}),
	STORAGE_FOLDER_NAME = "PVSStaticOcclusion",
	NEGATIVE_AUTHORITY = "ExactGeometryV1",
	MATRIX_POLICY = "SampleVisible_RuntimeProofRequired_v1",
	AUDITED_MATRIX_POLICY = "AuditedHidden_v1",
	MIN_TRUSTED_HOLDOUT_RAYS = 1000000,
	OPAQUE_TRANSPARENCY_LIMIT = 0.01,
	BOUNDS_TOLERANCE = 0.125
}
return table.freeze(v)