local v = {
	Buttons = require(script.Parent.Buttons),
	MovementMode = table.freeze({ Walking = 0, Ladder = 1 }),
	Stance = table.freeze({ Standing = 0, Ducking = 1 }),
	SupportKind = table.freeze({
		None = 0,
		Walkmesh = 1,
		Barrier = 2,
		Destructible = 3,
		Player = 4,
		Mover = 5,
		Max = 5
	}),
	OwnerSnapshotFlags = table.freeze({
		Teleport = 1,
		Discontinuity = 2,
		SynthesizedInput = 4,
		Stalled = 8,
		ValidMask = 15
	})
}
return table.freeze(v)