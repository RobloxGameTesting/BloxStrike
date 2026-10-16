local createVector = vector.create
require(script.Parent.Parent.Types)
local Config = require(script.Parent.Config)
local v = {
	CanonicalFields = table.freeze({
		"Position",
		"Velocity",
		"LookYaw",
		"VerticalLook",
		"BaseMoveSpeed",
		"MovementMode",
		"Stance",
		"OnGround",
		"GroundNormal",
		"WallNormal",
		"GroundSurfaceFriction",
		"DuckAmount",
		"DuckTimeMsecs",
		"IsDucking",
		"DuckSpeed",
		"DuckCooldownSeconds",
		"Stamina",
		"LastJumpCommandNumber",
		"PreviousButtons",
		"JumpBufferTicksRemaining",
		"JumpHullActive",
		"StuckStepTicks",
		"WeaponMoveSpeed",
		"WeaponScopedMoveSpeed",
		"VelocityModifier",
		"MovementTick"
	})
}

function v.fieldMask(p: string)
	local index = table.find(v.CanonicalFields, p)
	assert(index ~= nil, `unknown canonical MovementState field {p}`)
	return (bit32.lshift(1, index - 1))
end

function v.canonicalMismatch(p, p2)
	local count = 0
	local v2 = 0

	for k, canonicalField in v.CanonicalFields do
		if p[canonicalField] == p2[canonicalField] then
			continue
		end

		count += 1
		v2 = bit32.bor(v2, (bit32.lshift(1, k - 1)))
	end

	return count, v2
end

function v.mismatchLabel(p: number)
	if p == 0 then
		return "none"
	end

	local canonicalFields = {}

	for k, canonicalField in v.CanonicalFields do
		if bit32.band(p, (bit32.lshift(1, k - 1))) == 0 then
			continue
		end

		canonicalFields[#canonicalFields + 1] = canonicalField
	end

	if #canonicalFields == 0 then
		return (string.format("unknown(0x%X)", p))
	end

	return (table.concat(canonicalFields, ","))
end

function v.new(vector: Vector3, p: number?, value: number?, value2: number?, p2: number?, p3: number?)
	local weaponMoveSpeed = p2 or Config.Default.DefaultBaseMoveSpeed
	return {
		Position = vector,
		Velocity = createVector(0, 0, 0),
		LookYaw = value or 0,
		VerticalLook = value2 or 0,
		BaseMoveSpeed = p or Config.Default.DefaultBaseMoveSpeed,
		WeaponMoveSpeed = weaponMoveSpeed,
		WeaponScopedMoveSpeed = p3 or weaponMoveSpeed,
		VelocityModifier = 1,
		MovementTick = 0,
		MovementMode = "Walking",
		Stance = "Standing",
		OnGround = false,
		GroundNormal = createVector(0, 1, 0),
		WallNormal = createVector(0, 0, 0),
		GroundSurfaceFriction = 1,
		DuckAmount = 0,
		DuckTimeMsecs = 0,
		IsDucking = false,
		DuckSpeed = 8,
		DuckCooldownSeconds = 0,
		Stamina = 100,
		LastJumpCommandNumber = 4294967295,
		PreviousButtons = 0,
		JumpBufferTicksRemaining = 0,
		JumpHullActive = false,
		StuckStepTicks = 0
	}
end

function v.clone(data)
	return {
		Position = data.Position,
		Velocity = data.Velocity,
		LookYaw = data.LookYaw,
		VerticalLook = data.VerticalLook,
		BaseMoveSpeed = data.BaseMoveSpeed,
		WeaponMoveSpeed = data.WeaponMoveSpeed,
		WeaponScopedMoveSpeed = data.WeaponScopedMoveSpeed,
		VelocityModifier = data.VelocityModifier,
		MovementTick = data.MovementTick,
		MovementMode = data.MovementMode,
		Stance = data.Stance,
		OnGround = data.OnGround,
		GroundNormal = data.GroundNormal,
		WallNormal = data.WallNormal,
		GroundSurfaceFriction = data.GroundSurfaceFriction,
		DuckAmount = data.DuckAmount,
		DuckTimeMsecs = data.DuckTimeMsecs,
		IsDucking = data.IsDucking,
		DuckSpeed = data.DuckSpeed,
		DuckCooldownSeconds = data.DuckCooldownSeconds,
		Stamina = data.Stamina,
		LastJumpCommandNumber = data.LastJumpCommandNumber,
		PreviousButtons = data.PreviousButtons,
		JumpBufferTicksRemaining = data.JumpBufferTicksRemaining,
		JumpHullActive = data.JumpHullActive,
		StuckStepTicks = data.StuckStepTicks
	}
end

function v:cloneInto(data)
	table.clear(self)
	self.Position = data.Position
	self.Velocity = data.Velocity
	self.LookYaw = data.LookYaw
	self.VerticalLook = data.VerticalLook
	self.BaseMoveSpeed = data.BaseMoveSpeed
	self.WeaponMoveSpeed = data.WeaponMoveSpeed
	self.WeaponScopedMoveSpeed = data.WeaponScopedMoveSpeed
	self.VelocityModifier = data.VelocityModifier
	self.MovementTick = data.MovementTick
	self.MovementMode = data.MovementMode
	self.Stance = data.Stance
	self.OnGround = data.OnGround
	self.GroundNormal = data.GroundNormal
	self.WallNormal = data.WallNormal
	self.GroundSurfaceFriction = data.GroundSurfaceFriction
	self.DuckAmount = data.DuckAmount
	self.DuckTimeMsecs = data.DuckTimeMsecs
	self.IsDucking = data.IsDucking
	self.DuckSpeed = data.DuckSpeed
	self.DuckCooldownSeconds = data.DuckCooldownSeconds
	self.Stamina = data.Stamina
	self.LastJumpCommandNumber = data.LastJumpCommandNumber
	self.PreviousButtons = data.PreviousButtons
	self.JumpBufferTicksRemaining = data.JumpBufferTicksRemaining
	self.JumpHullActive = data.JumpHullActive
	self.StuckStepTicks = data.StuckStepTicks
	return self
end

function v.noneSupport()
	return {
		Kind = 0,
		SourceId = 0,
		Anchor = createVector(0, 0, 0),
		Velocity = createVector(0, 0, 0)
	}
end

function v.cloneSupport(data)
	return {
		Kind = data.Kind,
		SourceId = data.SourceId,
		Anchor = data.Anchor,
		Velocity = data.Velocity
	}
end

return table.freeze(v)