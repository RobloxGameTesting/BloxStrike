local Enums = require(script.Parent.Parent.Enums)
local v = {
	ManifestVersion = 1,
	CanonicalGeometryVersion = "MV2G1",
	WalkmeshHeader = "MLWALK1",
	MaxSourceCount = 65535,
	MaxDestructibleCount = 65535,
	MaxEpoch = 65535,
	MaxWalkmeshVertices = 1000000,
	MaxWalkmeshTriangles = 2000000,
	SourceKind = table.freeze({
		Walkmesh = Enums.SupportKind.Walkmesh,
		Barrier = Enums.SupportKind.Barrier,
		Destructible = Enums.SupportKind.Destructible
	})
}
v.SourceKindName = table.freeze({
	[v.SourceKind.Walkmesh] = "Walkmesh",
	[v.SourceKind.Barrier] = "Barrier",
	[v.SourceKind.Destructible] = "Destructible"
})
v.Tags = table.freeze({
	Destructible = "MovementV2Destructible",
	Walkmesh = "CustomWalkMesh",
	UnsupportedFloorGrid = "CustomFloorGrid",
	LadderMetadata = "Ladder"
})
v.Attributes = table.freeze({
	SourceId = "MovementV2SourceId",
	SourceKind = "MovementV2SourceKind",
	DestructibleIndex = "MovementV2DestructibleIndex",
	DestructibleProxy = "MovementV2DestructibleProxy",
	CanonicalGeometry = "MovementV2CanonicalGeometry",
	WalkmeshData = "WalkMeshData",
	Ignore = "IgnoreMovementCollision",
	Climbable = "Climbable",
	PreciseCylinder = "PreciseMovementCylinder",
	ConvexGroup = "MovementConvexGroup",
	DisableSeamMerge = "DisableMovementSeamMerge",
	ManifestVersion = "MovementV2CollisionManifestVersion",
	ManifestEpoch = "MovementV2CollisionEpoch",
	ManifestFingerprint = "MovementV2CollisionFingerprint",
	ManifestSourceCount = "MovementV2CollisionSourceCount",
	ManifestDestructibleCount = "MovementV2CollisionDestructibleCount"
})
v.BarriersNameLower = "barriers"
v.ReplicaContainerName = "MovementV2CollisionCatalogs"

function v.GetSourceKindName(p: number)
	return v.SourceKindName[p]
end

return table.freeze(v)