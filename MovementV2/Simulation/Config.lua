local createVector = vector.create
local SpeedProfile = require(script.Parent.Parent.SpeedProfile)
local Config = require(script.Parent.Parent.Config)
local v = {}
local HammerUnitToStud = SpeedProfile.HammerUnitToStud
v.Default = table.freeze({
	HammerUnitToStud = HammerUnitToStud,
	PlayerSizeStanding = createVector(32, 72, 32) * HammerUnitToStud,
	PlayerSizeDucking = createVector(32, 54, 32) * HammerUnitToStud,
	Gravity = 800 * HammerUnitToStud,
	JumpSpeed = 301.993377 * HammerUnitToStud,
	GroundAccelerate = 5.5,
	AirAccelerate = 12,
	AirSpeedCap = 30 * HammerUnitToStud,
	Friction = 5.2,
	StopSpeed = 80 * HammerUnitToStud,
	WalkModifier = SpeedProfile.WalkModifier,
	CrouchModifier = SpeedProfile.CrouchModifier,
	WalkableFloor = 0.7,
	GroundProbeDistance = 2 * HammerUnitToStud,
	GroundProbeStartBump = 0.03,
	GroundClearVelocity = 140 * HammerUnitToStud,
	MaxStepHeight = 18 * HammerUnitToStud,
	MaxBumps = 4,
	MaxClipPlanes = 5,
	PositionSnapEpsilon = 0.001,
	VelocityEpsilon = 0.05,
	PlaneEpsilon = 0.00001,
	MaxVelocity = 3500 * HammerUnitToStud,
	DefaultBaseMoveSpeed = SpeedProfile.DefaultBaseSpeed,
	MaxBaseMoveSpeed = SpeedProfile.TopSpeed,
	SurfaceFrictionDefault = 1,
	LadderAttachDistance = 2 * HammerUnitToStud,
	LadderSpeed = 200 * HammerUnitToStud,
	LadderJumpOffSpeed = 270 * HammerUnitToStud,
	Overbounce = 1,
	BunnyHopInputBufferTicks = 0,
	AutoJumpHull = false,
	AutoBunnyHop = false,
	AutoJumpLedgeAssistHeight = 0,
	AutoJumpLedgeAssistLiftSpeed = 0,
	BunnyHopSpeedCap = 0,
	BunnyHopAirAccelerate = 0,
	BunnyHopAirSpeedCap = 0,
	BunnyHopPenaltyThreshold = 0,
	BunnyHopPenaltyBase = 0,
	BunnyHopPenaltyScale = 0,
	BunnyHopMinVelocityRetain = 1,
	MaxSpeed = SpeedProfile.DefaultBaseSpeed,
	TimeToDuckMsecs = 200,
	TimeToUnDuckMsecs = 200,
	DuckJumpOriginShiftFraction = 0.2,
	DuckSpeedIdeal = 8,
	DuckSpeedRecoveryRate = 3,
	DuckSpeedFastRecoveryRate = 6,
	DuckSpeedDuckMultiplier = 0.8,
	DuckSpeedUnduckMinimum = 1.5,
	DuckSpamPenalty = 2,
	DuckSpamMinSpeed = 1.5,
	TimeBetweenDucksMsecs = 400,
	StaminaMax = 100,
	StaminaMaxPenalty = 80,
	StaminaRecoveryRate = 60,
	StaminaJumpCost = 0.08,
	StaminaLandCost = 0.05,
	LadderDetachDistance = 10 * HammerUnitToStud,
	LadderClimbModifier = 0.34,
	LadderLateralScale = 0.78,
	LadderDampen = 0.2,
	LadderDampenAngle = -0.707
})
local DefaultSimulationHz = Config.DefaultSimulationHz
local values = {}

local function casualDeathmatchProfile(p: number)
	local v2 = values[p]

	if v2 ~= nil then
		return v2
	end

	local clone = table.clone(v.Default)
	clone.BunnyHopInputBufferTicks = math.max(1, (math.floor(p * 0.1 + 0.5)))
	clone.AutoJumpHull = true
	clone.AutoJumpLedgeAssistHeight = clone.HammerUnitToStud * 18
	clone.AutoJumpLedgeAssistLiftSpeed = clone.HammerUnitToStud * 600
	clone.BunnyHopSpeedCap = 24.5
	clone.BunnyHopPenaltyThreshold = 19
	clone.BunnyHopPenaltyBase = 0.1
	clone.BunnyHopPenaltyScale = 0.03
	clone.BunnyHopMinVelocityRetain = 0.4
	local frozen = table.freeze(clone)
	values[p] = frozen
	return frozen
end

local function surfProfile() -- 1 equivalent call inferred from this helper
	local clone = table.clone(v.Default)
	clone.AirAccelerate = 150
	clone.GroundAccelerate = 5
	clone.Friction = 4
	clone.StaminaJumpCost = 0
	clone.StaminaLandCost = 0
	clone.AutoBunnyHop = true
	return table.freeze(clone)
end

v.Competitive = v.Default
v.CasualDeathmatch = casualDeathmatchProfile(DefaultSimulationHz)
v.Surf = surfProfile() -- inferred equivalent call

function v.resolveServerGamemode(p, p2: number?)
	local v2 = p2 or DefaultSimulationHz
	local v3 = type(v2) == "number" and v2 == v2 and v2 > 0 and v2 < 1e999
	assert(v3, "MovementV2 simulation Hz must be finite and positive")

	if p == "Casual" or p == "Deathmatch" then
		return (casualDeathmatchProfile(v2))
	end

	if p == "Surf" then
		return v.Surf
	end

	return v.Competitive
end

return table.freeze(v)