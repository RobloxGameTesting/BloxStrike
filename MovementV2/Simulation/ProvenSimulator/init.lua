local createVector = vector.create
require(script.Parent.ProvenTypes)
local ProvenMath = require(script.Parent.ProvenMath)
require(script.Parent.DeterminismTrace)
local Trace = require(script.Trace)
local TraceRules = require(script.TraceRules)
local Duck = require(script.Duck)
local SlideMove = require(script.SlideMove)
local GroundMove = require(script.GroundMove)
local AirMove = require(script.AirMove)
local Ladder = require(script.Ladder)
local v = {}
local line = Trace.line
local state = Trace.state
local vector = Trace.vector
local clampHorizontal = ProvenMath.clampHorizontal
local horizontalMagnitude = ProvenMath.horizontalMagnitude
local getStance = Duck.getStance
local getUncrouchClearance = Duck.getUncrouchClearance
local tryPlayerMove = SlideMove.tryPlayerMove
local groundProbeWithRetry = GroundMove.groundProbeWithRetry
local getLadderNormal = Ladder.getLadderNormal
local GROUND_PROBE_START_BUMP = TraceRules.GROUND_PROBE_START_BUMP
local WALL_RECOVERY_SEPARATION = SlideMove.WALL_RECOVERY_SEPARATION
local isPointTestBlocked = TraceRules.isPointTestBlocked
local getTraceClipNormal = TraceRules.getTraceClipNormal
local getWallConstraintNormal = TraceRules.getWallConstraintNormal
local getTraceSurfaceVelocity = TraceRules.getTraceSurfaceVelocity
local getTraceSurfaceFriction = TraceRules.getTraceSurfaceFriction
local getImpactWallConstraintNormal = TraceRules.getImpactWallConstraintNormal
local isDynamicPlayerSupportTrace = TraceRules.isDynamicPlayerSupportTrace
local isRecoverableFloorSupportTrace = TraceRules.isRecoverableFloorSupportTrace
local getResolvedSupportPosition = TraceRules.getResolvedSupportPosition
local isWalkableGround = TraceRules.isWalkableGround
local getTraceGroundNormal = TraceRules.getTraceGroundNormal
local getLandingSnapDistance = TraceRules.getLandingSnapDistance
local shouldRejectAirLanding = TraceRules.shouldRejectAirLanding
local supportTraceMatchesPosition = TraceRules.supportTraceMatchesPosition
local v2 = {}
local v3 = {}
local v4 = {}

local function applyBunnyHopLandingPenalty(movedRelativeGroundVelocity: Vector3, config)
	local bunnyHopPenaltyThreshold = config.BunnyHopPenaltyThreshold

	if bunnyHopPenaltyThreshold <= 0 then
		return movedRelativeGroundVelocity
	end

	local v5 = math.sqrt(movedRelativeGroundVelocity.X * movedRelativeGroundVelocity.X + movedRelativeGroundVelocity.Z * movedRelativeGroundVelocity.Z)

	if v5 <= bunnyHopPenaltyThreshold then
		return movedRelativeGroundVelocity
	end

	local v6 = v5 - bunnyHopPenaltyThreshold
	local v7 = config.BunnyHopPenaltyBase + v6 * config.BunnyHopPenaltyScale
	local v8 = math.clamp(math.max(config.BunnyHopMinVelocityRetain, 1 - v7), 0, 1)
	return (Vector3.new(
		movedRelativeGroundVelocity.X * v8,
		movedRelativeGroundVelocity.Y,
		movedRelativeGroundVelocity.Z * v8
	))
end

v.applyLandingVelocity = applyBunnyHopLandingPenalty

local function clampVelocityComponents(vector2: Vector3, maxVelocity: number) -- 2 equivalent calls inferred from this helper
	return (Vector3.new(
		math.clamp(vector2.X, -maxVelocity, maxVelocity),
		math.clamp(vector2.Y, -maxVelocity, maxVelocity),
		(math.clamp(vector2.Z, -maxVelocity, maxVelocity))
	))
end

local function isGroundJumpCommandActive(nextNode, input, config) -- 1 equivalent call inferred from this helper
	local autoBunnyHop = input.Jump and (config.AutoBunnyHop or not nextNode.JumpHeld)
	local v5

	if config.BunnyHopInputBufferTicks > 0 then
		v5 = nextNode.JumpBufferTicksRemaining > 0
	else
		v5 = false
	end

	if autoBunnyHop or v5 then
		return input.Tick - nextNode.LastJumpTick > 1
	end

	return v5
end

local function getStaminaFloor(p) -- 1 equivalent call inferred from this helper
	return (math.max(0, p.StaminaMax - p.StaminaMaxPenalty))
end

local function getStaminaScale(stamina: number, config) -- 2 equivalent calls inferred from this helper
	return (math.clamp(stamina / math.max(config.StaminaMax, 1), 0, 1))
end

local function applyStaminaPenalty(p: number, p2: number, p3: number, p4) -- 2 equivalent calls inferred from this helper
	local v5 = p2 * (math.max(p3, 0) / p4.HammerUnitToStud)
	return (math.max(getStaminaFloor(p4), p - v5)) -- inferred equivalent call
end

function v.finishStamina(p: number, p2: number?, p3: number, data)
	if p2 ~= nil then
		p = applyStaminaPenalty(p, data.StaminaLandCost, -p2, data) -- inferred equivalent call
	end

	return (math.min(data.StaminaMax, p + data.StaminaRecoveryRate * p3))
end

local function createStepState(data, p, list)
	local v5 = list or {}

	if list then
		table.clear(list)
	end

	v5.Position = data.Position
	v5.Velocity = data.Velocity
	v5.OnGround = data.OnGround
	v5.GroundSupportIsDynamicPlayer = data.OnGround and data.GroundSupportIsDynamicPlayer == true
	v5.GroundNormal = data.GroundNormal
	v5.GroundSurfaceFriction = data.GroundSurfaceFriction
	v5.WallNormal = data.WallNormal
	v5.DuckAmount = data.DuckAmount
	v5.DuckTimeMsecs = data.DuckTimeMsecs
	v5.IsDucking = data.IsDucking == true
	v5.DuckHeld = p.Duck == true
	v5.DuckFatigueLevel = data.DuckFatigueLevel
	v5.DuckFatigueTimerMsecs = data.DuckFatigueTimerMsecs
	v5.MovementType = data.MovementType
	v5.Stamina = data.Stamina
	v5.LastJumpTick = data.LastJumpTick
	v5.JumpHeld = data.JumpHeld
	v5.JumpBufferTicksRemaining = data.JumpBufferTicksRemaining
	v5.JumpHullActive = data.JumpHullActive == true
	v5.StuckStepTicks = data.StuckStepTicks
	return v5
end

local function activateJumpHull(state2) -- 2 equivalent calls inferred from this helper
	if not state2.Config.AutoJumpHull then
		return
	end

	state2.Next.JumpHullActive = true
	state2.Stance = "crouching"
end

local function beginStep(state2, input, deltaTime: number, world, config, p)
	local v5 = v3
	table.clear(v5)
	v5.State = state2
	v5.Input = input
	v5.DeltaTime = deltaTime
	v5.World = world
	v5.Config = config
	v5.UsedLadderMove = false
	v5.JumpedFromGround = false
	v5.MovedRelativeGroundVelocity = createVector(0, 0, 0)
	local v6

	if p == nil then
		v6 = v4
	end

	local nextNode = createStepState(state2, input, v6)
	v5.Next = nextNode
	state("proven.createStepState", nextNode, line(1))

	if not config.AutoJumpHull or nextNode.OnGround or nextNode.MovementType == "Ladder" then
		nextNode.JumpHullActive = false
	end

	v5.HadDynamicPlayerSupport = state2.OnGround and state2.GroundSupportIsDynamicPlayer == true
	nextNode.Velocity = clampVelocityComponents(nextNode.Velocity, config.MaxVelocity) -- inferred equivalent call
	state("proven.velocityInputClamp", nextNode, line(1))
	world:BeginStepBounds(
		nextNode.Position,
		nextNode.Velocity,
		math.max(config.MaxSpeed, input.BaseMoveSpeed),
		deltaTime
	)
	return v5
end

local function resolveSpeedAndStance(state2)
	local nextNode = state2.Next
	local input = state2.Input
	local config = state2.Config
	local v5 = math.clamp(nextNode.DuckAmount, 0, 1)
	local v6 = nextNode.OnGround and (v5 > 0 or nextNode.IsDucking)
	local v7, crouchModifier

	if v6 then
		v7 = 1 + (config.CrouchModifier - 1) * v5
		crouchModifier = config.CrouchModifier
	else
		v7 = 1
		crouchModifier = 1
	end

	if input.Walk then
		v7 = math.min(v7, config.WalkModifier)

		if not v6 then
			crouchModifier = config.WalkModifier
		end
	end

	local v8 = 1 * v7
	local staminaScale = getStaminaScale(nextNode.Stamina, config) -- inferred equivalent call
	state2.SpeedModifier = v8 * (staminaScale * staminaScale)
	state2.GroundAccelerationModifier = crouchModifier
	state2.Stance = nextNode.JumpHullActive and "crouching" or getStance(nextNode)
end

local function recoverStartSolid(data)
	local nextNode = data.Next
	local v5 = math.max(1, (math.floor(0.25 / data.DeltaTime + 0.5)))
	local position

	if nextNode.StuckStepTicks > 0 or data.Input.Tick % v5 == 0 then
		position = SlideMove.escapeStartSolid(nextNode.Position, data.Stance, data.World)
	end

	if position ~= nil then
		nextNode.Position = position
	end

	state("proven.startSolidRecovery", nextNode, line(1))
end

local function resolveWish(state2)
	local nextNode = state2.Next
	local state3 = state2.State
	local input = state2.Input
	local config = state2.Config
	local unit = ProvenMath.moveVectorToWorld(input.MoveVector, input.LookYaw)
	local maxSpeed = config.MaxSpeed

	if typeof(input.BaseMoveSpeed) == "number" then
		maxSpeed = math.clamp(input.BaseMoveSpeed, 0, config.MaxBaseMoveSpeed)
	end

	local movementLocked = maxSpeed <= config.PositionSnapEpsilon
	local rawWishDir

	if movementLocked then
		nextNode.Velocity = Vector3.new(0, nextNode.Velocity.Y, 0)
		unit = createVector(0, 0, 0)
		rawWishDir = createVector(0, 0, 0)
	else
		rawWishDir = unit
	end

	state("proven.movementLock", nextNode, line(1))

	if config.BunnyHopInputBufferTicks <= 0 or movementLocked then
		nextNode.JumpBufferTicksRemaining = 0
	else
		nextNode.JumpBufferTicksRemaining = math.max(0, state3.JumpBufferTicksRemaining - 1)

		if input.Jump and not state3.JumpHeld then
			nextNode.JumpBufferTicksRemaining = math.min(config.BunnyHopInputBufferTicks, 255)
		end
	end

	state("proven.jumpBuffer", nextNode, line(1))
	local maxGroundSpeed = maxSpeed * state2.SpeedModifier
	local wishSpeed, rawWishSpeed

	if unit.Magnitude <= 0 then
		wishSpeed = 0
		rawWishSpeed = 0
	else
		unit = unit.Unit
		rawWishSpeed = maxGroundSpeed
		wishSpeed = rawWishSpeed
		rawWishDir = unit
		rawWishSpeed = wishSpeed
		wishSpeed = rawWishSpeed
	end

	state2.MovementLocked = movementLocked
	state2.JumpInputAllowed = not movementLocked
	state2.WishDir = unit
	state2.RawWishDir = rawWishDir
	state2.WishSpeed = wishSpeed
	state2.MaxGroundSpeed = maxGroundSpeed
	state2.RawWishSpeed = rawWishSpeed
	state2.PreMovePosition = nextNode.Position
	state2.RememberedWallNormal = nextNode.WallNormal
	state2.WallConstraintWarmStartNormal = state3.MovementType ~= "Walking" and createVector(0, 0, 0)
		or nextNode.WallNormal
	state2.GroundJumpCommandActive = isGroundJumpCommandActive(nextNode, input, config) -- inferred equivalent call
end

local function moveOnLadder(state2)
	local nextNode = state2.Next
	local input = state2.Input
	local config = state2.Config
	local world = state2.World
	local deltaTime = state2.DeltaTime
	local v5 = nil
	local groundJumpCommandActive = state2.JumpInputAllowed and nextNode.OnGround and state2.GroundJumpCommandActive
	debug.profilebegin("Sim.ladderFind")

	if state2.MovementLocked or state2.State.MovementType ~= "Ladder" then
		if
			not state2.MovementLocked
			and not groundJumpCommandActive
			and state2.RawWishSpeed > config.PositionSnapEpsilon
		then
			v5 = Ladder.findLadderTrace(
				nextNode.Position,
				state2.Stance,
				world,
				config,
				state2.RawWishDir,
				nextNode.WallNormal,
				config.LadderAttachDistance,
				true
			)
		end
	else
		v5 = Ladder.findLadderTrace(
			nextNode.Position,
			state2.Stance,
			world,
			config,
			state2.RawWishDir,
			nextNode.WallNormal,
			config.LadderDetachDistance,
			false
		)
	end

	debug.profileend()
	state("proven.ladderFind", nextNode, line(1))

	if v5 == nil then
		nextNode.MovementType = "Walking"
		return false
	end

	local ladderNormal = getLadderNormal(v5, nextNode.WallNormal)

	if state2.JumpInputAllowed and input.Jump and not nextNode.JumpHeld then
		nextNode.OnGround = false
		nextNode.GroundSupportIsDynamicPlayer = false
		nextNode.GroundSurfaceFriction = config.SurfaceFrictionDefault
		nextNode.MovementType = "Walking"
		nextNode.WallNormal = createVector(0, 0, 0)
		nextNode.Velocity = ladderNormal * config.LadderJumpOffSpeed + getTraceSurfaceVelocity(v5)
		nextNode.LastJumpTick = input.Tick
		nextNode.JumpBufferTicksRemaining = 0
		activateJumpHull(state2) -- inferred equivalent call
		state("proven.ladderJumpOff", nextNode, line(1))
		return false
	else
		local simulateLadderMove = Ladder.simulateLadderMove(
			nextNode.Position,
			input,
			deltaTime,
			world,
			config,
			state2.Stance,
			v5,
			nextNode.WallNormal,
			nextNode.OnGround,
			v2
		)

		if simulateLadderMove.detached then
			state2.UsedLadderMove = true
			nextNode.OnGround = false
			nextNode.GroundSupportIsDynamicPlayer = false
			nextNode.GroundSurfaceFriction = config.SurfaceFrictionDefault
			nextNode.MovementType = "Walking"
			nextNode.JumpHullActive = false
			state2.MovedPosition = simulateLadderMove.position
			state2.MovedVelocity = simulateLadderMove.velocity
			state2.MovedTouchedWall = simulateLadderMove.touchedWall
			state2.MovedImpactTrace = simulateLadderMove.impactTrace
			vector("proven.ladderDetach", simulateLadderMove.position, simulateLadderMove.velocity, 0, 0, line(1))
			return false
		else
			nextNode.Position = simulateLadderMove.position
			nextNode.Velocity = simulateLadderMove.velocity
			nextNode.OnGround = false
			nextNode.GroundSupportIsDynamicPlayer = false
			nextNode.GroundNormal = createVector(0, 1, 0)
			nextNode.GroundSurfaceFriction = config.SurfaceFrictionDefault
			nextNode.WallNormal = getLadderNormal(simulateLadderMove.contactTrace or v5, ladderNormal)
			nextNode.MovementType = "Ladder"
			nextNode.JumpHullActive = false
			nextNode.StuckStepTicks = 0
			nextNode.Stamina = math.min(config.StaminaMax, nextNode.Stamina + config.StaminaRecoveryRate * deltaTime)
			nextNode.JumpHeld = input.Jump
			state("proven.ladderMoveReturn", nextNode, line(1))
			return true
		end
	end
end

local function prevalidatePlayerSupport(data)
	local nextNode = data.Next
	local config = data.Config
	debug.profilebegin("Sim.playerSupportPrevalidation")
	local v5 = groundProbeWithRetry(
		nextNode.Position,
		config.GroundProbeDistance,
		data.Stance,
		data.World,
		config,
		false,
		true
	)
	local walkableGround = isWalkableGround(v5, config)
	debug.profileend()

	if walkableGround then
		nextNode.GroundSupportIsDynamicPlayer = isDynamicPlayerSupportTrace(v5)
	else
		nextNode.OnGround = false
		nextNode.GroundSupportIsDynamicPlayer = false
	end

	state("proven.playerSupportPrevalidation", nextNode, line(1))
end

local function moveOnGround(state2)
	local nextNode = state2.Next
	local input = state2.Input
	local config = state2.Config
	local world = state2.World
	debug.profilebegin("Sim.groundMove")
	local groundSupportVelocity, v5 = GroundMove.getGroundSupportVelocity(
		nextNode.Position,
		state2.Stance,
		world,
		config
	)
	local groundSurfaceFriction

	if v5 == nil then
		groundSurfaceFriction = nextNode.GroundSurfaceFriction
	else
		groundSurfaceFriction = getTraceSurfaceFriction(v5, config)
	end

	nextNode.GroundSurfaceFriction = groundSurfaceFriction

	if state2.MovementLocked then
		nextNode.Velocity = groundSupportVelocity
	end

	state("proven.groundSupportVelocity", nextNode, line(1))
	local v6 = nextNode.Velocity - groundSupportVelocity

	if state2.JumpInputAllowed and state2.GroundJumpCommandActive then
		local staminaScale = getStaminaScale(nextNode.Stamina, config) -- inferred equivalent call
		local v7 = config.JumpSpeed * staminaScale
		nextNode.OnGround = false
		nextNode.GroundSupportIsDynamicPlayer = false
		nextNode.Velocity = Vector3.new(v6.X + groundSupportVelocity.X, v7, v6.Z + groundSupportVelocity.Z)
		nextNode.LastJumpTick = input.Tick
		nextNode.JumpBufferTicksRemaining = 0
		nextNode.Stamina = applyStaminaPenalty(nextNode.Stamina, config.StaminaJumpCost, v7, config) -- inferred equivalent call
		state2.JumpedFromGround = true
		activateJumpHull(state2) -- inferred equivalent call
		state("proven.groundJump", nextNode, line(1))
	else
		nextNode.Velocity = Vector3.new(v6.X, 0, v6.Z) + groundSupportVelocity
		local movedPosition, v7, movedRelativeGroundVelocity, walkPreClipVelocity, groundMoveResult, reusableGroundTrace, _, movedTouchedWall, movedImpactTrace = GroundMove.walkMove(
			nextNode.Position,
			nextNode.Velocity,
			state2.WishDir,
			state2.WishSpeed,
			state2.MaxGroundSpeed,
			state2.DeltaTime,
			world,
			config,
			state2.Stance,
			groundSupportVelocity,
			groundSurfaceFriction,
			state2.GroundAccelerationModifier,
			v2
		)
		state2.GroundMoveResult = groundMoveResult
		state2.MovedPosition = movedPosition
		state2.MovedVelocity = v7
		state2.MovedTouchedWall = movedTouchedWall
		state2.MovedImpactTrace = movedImpactTrace
		state2.MovedRelativeGroundVelocity = movedRelativeGroundVelocity
		state2.ReusableGroundTrace = reusableGroundTrace
		state2.WalkPreClipVelocity = walkPreClipVelocity
		nextNode.Velocity = v7
		state("proven.walkMoveCommit", nextNode, line(1))
	end

	debug.profileend()
end

local function moveInAir(state2)
	local nextNode = state2.Next
	local config = state2.Config
	debug.profilebegin("Sim.airMove")
	local v5

	if config.AutoJumpLedgeAssistHeight > config.PositionSnapEpsilon then
		v5 = config.AutoJumpLedgeAssistLiftSpeed > config.PositionSnapEpsilon
	else
		v5 = false
	end

	local v6 = nextNode.JumpHullActive and getStance(nextNode) == "standing"
	local airMove, movedVelocity, v7, movedTouchedWall, movedImpactTrace = AirMove.airMove(
		nextNode.Position,
		nextNode.Velocity,
		state2.WishDir,
		state2.WishSpeed,
		state2.DeltaTime,
		state2.World,
		config,
		state2.Stance,
		v5,
		v6,
		nextNode.GroundSurfaceFriction,
		state2.WallConstraintWarmStartNormal,
		v2
	)
	state2.MovedPosition = airMove
	state2.MovedVelocity = movedVelocity
	state2.MovedTouchedWall = movedTouchedWall
	state2.MovedImpactTrace = movedImpactTrace
	vector("proven.airMoveResult", airMove, movedVelocity, 0, v7 and 1 or 0, line(1))
	debug.profileend()
end

local function moveOffLadder(data)
	local nextNode = data.Next
	local config = data.Config
	nextNode.Velocity += Vector3.new(0, -config.Gravity * data.DeltaTime * 0.5, 0)
	state("proven.gravityFirstHalf", nextNode, line(1))

	if nextNode.OnGround and data.HadDynamicPlayerSupport then
		prevalidatePlayerSupport(data)
	end

	if nextNode.OnGround then
		moveOnGround(data)
	end

	if not nextNode.OnGround then
		moveInAir(data)
	end
end

local function recoverWedgedGroundMove(data, wallConstraintNormal: Vector3)
	local nextNode = data.Next
	local config = data.Config
	local deltaTime = data.DeltaTime
	local groundMoveResult = data.GroundMoveResult
	local movedImpactTrace = data.MovedImpactTrace
	local v5 = data.WishSpeed > config.PositionSnapEpsilon
	local direct

	if groundMoveResult then
		direct = groundMoveResult.direct
	end

	local step

	if groundMoveResult then
		step = groundMoveResult.step
	end

	local v6

	if direct == nil then
		v6 = false
	else
		v6 = direct.horizontalDistanceSq > 0.0004
	end

	if not v6 and step ~= nil then
		v6 = step.horizontalDistanceSq > 0.0004
	end

	if direct then
		movedImpactTrace = direct.impactTrace
	end

	local startSolid

	if movedImpactTrace == nil or not (movedImpactTrace.normal.Y < config.WalkableFloor) then
		startSolid = false
	else
		startSolid = movedImpactTrace.startSolid
			or movedImpactTrace.allSolid
			or movedImpactTrace.fraction <= config.PositionSnapEpsilon
	end

	local v7

	if direct then
		v7 = direct.touchedWall
	else
		v7 = data.MovedTouchedWall
	end

	local v8 = v7 and startSolid and v5 and not v6

	if v8 then
		if horizontalMagnitude(nextNode.Velocity) <= 0.35 then
			v8 = math.abs(nextNode.Velocity.Y) <= config.VelocityEpsilon
		else
			v8 = false
		end
	end

	local v9 = movedImpactTrace == nil and createVector(0, 0, 0)
		or getWallConstraintNormal(getTraceClipNormal(movedImpactTrace, config), config)
	local v10 = not (v9.Magnitude > 1e-6 and wallConstraintNormal.Magnitude > 1e-6)
		or v9.Unit:Dot(wallConstraintNormal.Unit) >= 0.95
	local walkPreClipVelocity = data.WalkPreClipVelocity

	if v8 and walkPreClipVelocity ~= nil and wallConstraintNormal.Magnitude > 1e-6 and v10 then
		local v11 = walkPreClipVelocity - wallConstraintNormal * walkPreClipVelocity:Dot(wallConstraintNormal)
		local vector2 = Vector3.new(v11.X, 0, v11.Z)
		local magnitude = vector2.Magnitude

		if config.PositionSnapEpsilon < magnitude then
			local v12 = wallConstraintNormal * WALL_RECOVERY_SEPARATION
			local v13 = data.PreMovePosition + v12
			local v14, v15 = tryPlayerMove(v13, vector2, deltaTime, data.World, config, data.Stance, false, v2)
			local v16 = v14.X - v13.X
			local v17 = v14.Z - v13.Z
			local v18 = math.sqrt(v16 * v16 + v17 * v17)
			local v19 = math.max(config.PositionSnapEpsilon, magnitude * deltaTime * 0.5)
			local v20 = horizontalMagnitude(v15)
			local position = v14 - v12
			local v21

			if v19 <= v18 and config.PositionSnapEpsilon < v20 then
				v21 = isPointTestBlocked(data.World:PointTest(position, data.Stance))
			else
				v21 = false
			end

			if v19 <= v18 and config.PositionSnapEpsilon < v20 and not v21 then
				nextNode.Position = position
				nextNode.Velocity = Vector3.new(v15.X, nextNode.Velocity.Y, v15.Z)
				nextNode.WallNormal = data.RememberedWallNormal
				v8 = false
			end
		end
	end

	if not v8 then
		nextNode.StuckStepTicks = 0
		return
	end

	nextNode.Velocity = Vector3.new(0, nextNode.Velocity.Y, 0)
	nextNode.StuckStepTicks = math.min(nextNode.StuckStepTicks + 1, 255)
end

local function commitMove(data)
	local nextNode = data.Next
	local config = data.Config
	debug.profilebegin("Sim.postMove")
	nextNode.Position = data.MovedPosition
	nextNode.Velocity = clampVelocityComponents(data.MovedVelocity, config.MaxVelocity) -- inferred equivalent call
	state("proven.postMoveCommit", nextNode, line(1))

	if config.BunnyHopSpeedCap > 0 and not nextNode.OnGround and nextNode.MovementType == "Walking" then
		nextNode.Velocity = clampHorizontal(nextNode.Velocity, config.BunnyHopSpeedCap)
	end

	local wallConstraintNormal = getWallConstraintNormal(data.RememberedWallNormal, config)

	if data.RawWishSpeed <= config.PositionSnapEpsilon then
		nextNode.WallNormal = createVector(0, 0, 0)
	elseif data.MovedTouchedWall then
		nextNode.WallNormal = getImpactWallConstraintNormal(data.MovedImpactTrace, config)
	else
		nextNode.WallNormal = createVector(0, 0, 0)
	end

	if nextNode.OnGround then
		recoverWedgedGroundMove(data, wallConstraintNormal)
	else
		nextNode.StuckStepTicks = 0
	end

	state("proven.wallRecovery", nextNode, line(1))
	debug.profileend()
end

local function finishRisingTick(data)
	local nextNode = data.Next
	local config = data.Config
	local deltaTime = data.DeltaTime

	if nextNode.OnGround or not (nextNode.Velocity.Y > config.GroundClearVelocity) then
		return false
	end

	if not data.UsedLadderMove then
		nextNode.Velocity += Vector3.new(0, -config.Gravity * deltaTime * 0.5, 0)
	end

	nextNode.GroundSurfaceFriction = config.SurfaceFrictionDefault
	nextNode.GroundSupportIsDynamicPlayer = false
	nextNode.Stamina = math.min(config.StaminaMax, nextNode.Stamina + config.StaminaRecoveryRate * deltaTime)
	nextNode.JumpHeld = data.Input.Jump
	state("proven.risingReturn", nextNode, line(1))
	return true
end

local function traceGroundDecision(data, data2, p: string, p2: number)
	if not Trace.isActive() then
		return
	end

	local hullRecord = data2 and data2.hullRecord
	local sourceId

	if data2 and typeof(data2.SourceId) == "number" then
		sourceId = data2.SourceId
	else
		sourceId = (not hullRecord or typeof(hullRecord.sourceId) ~= "number") and 0 or hullRecord.sourceId
	end

	vector(
		p,
		getResolvedSupportPosition(data2, data.Next.Position),
		getTraceGroundNormal(data2) or createVector(0, 0, 0),
		p2,
		sourceId,
		line(2)
	)
end

local function evaluateGroundTrace(data, data2, p: number)
	local nextNode = data.Next
	local config = data.Config

	if not isWalkableGround(data2, config) then
		traceGroundDecision(data, data2, "proven.groundDecision.noWalkableSupport", -1)
		return false, nil
	end

	if data.PreProbeOnGround then
		traceGroundDecision(data, data2, "proven.groundDecision.retainOwnedSupport", 0)
		return true, nil
	end

	local landingSnapDistance = getLandingSnapDistance(nextNode.Position, data2)
	local recoverableFloorSupportTrace = isRecoverableFloorSupportTrace(data2, config, p)

	if
		(data2.startSolid or data2.allSolid or data2.fraction <= config.PositionSnapEpsilon)
		and not recoverableFloorSupportTrace
	then
		traceGroundDecision(data, data2, "proven.groundDecision.rejectEmbeddedNonFloor", landingSnapDistance)
		return false, "embeddedNonFloor"
	end

	if p < landingSnapDistance then
		traceGroundDecision(data, data2, "proven.groundDecision.rejectSnapDistance", landingSnapDistance)
		return false, "snapDistance"
	end

	if
		data.JumpedFromGround
		or not shouldRejectAirLanding(
			nextNode.Velocity,
			getTraceGroundNormal(data2),
			landingSnapDistance,
			p,
			config.VelocityEpsilon
		)
	then
		traceGroundDecision(data, data2, "proven.groundDecision.acceptAirLanding", landingSnapDistance)
		return true, nil
	end

	traceGroundDecision(data, data2, "proven.groundDecision.rejectMovingAway", landingSnapDistance)
	return false, "movingAwayFromSurface"
end

local function categorizeGround(state2)
	local nextNode = state2.Next
	local state3 = state2.State
	local config = state2.Config
	local world = state2.World
	local deltaTime = state2.DeltaTime
	debug.profilebegin("Sim.groundProbe")
	local onGround = nextNode.OnGround
	state2.PreProbeOnGround = onGround
	local v5 = nextNode.JumpHullActive and getStance(nextNode) == "standing"
	local v6 = v5 and "standing" or state2.Stance
	local v7 = not v5 and 0 or (config.PlayerSizeStanding.Y - config.PlayerSizeDucking.Y) * 0.5
	local groundProbeDistance

	if onGround then
		groundProbeDistance = math.max(config.GroundProbeDistance, config.MaxStepHeight)
	else
		groundProbeDistance = config.GroundProbeDistance
	end

	local v8 = groundProbeDistance + GROUND_PROBE_START_BUMP + config.PositionSnapEpsilon
	local v9 = v8 + v7
	local reusableGroundTrace = state2.ReusableGroundTrace

	if not supportTraceMatchesPosition(reusableGroundTrace, nextNode.Position, config) then
		reusableGroundTrace = groundProbeWithRetry(
			nextNode.Position,
			groundProbeDistance,
			v6,
			world,
			config,
			onGround,
			onGround
		)
	end

	local v10 = evaluateGroundTrace(state2, reusableGroundTrace, v9)
	state("proven.groundProbeEvaluated", nextNode, line(1))
	local resolvedSupportPosition = getResolvedSupportPosition(reusableGroundTrace, nextNode.Position)

	if v5 and v10 and isPointTestBlocked(world:PointTest(resolvedSupportPosition, "standing", true)) then
		v10 = false
	end

	if v5 and not v10 then
		local v11 = groundProbeWithRetry(
			nextNode.Position,
			groundProbeDistance,
			"crouching",
			world,
			config,
			onGround,
			onGround
		)

		if evaluateGroundTrace(state2, v11, v8) then
			resolvedSupportPosition = getResolvedSupportPosition(v11, nextNode.Position)
			local uncrouchClearance, v12 = getUncrouchClearance(resolvedSupportPosition, world, config)
			v10 = true

			if uncrouchClearance then
				nextNode.DuckAmount = 1
				nextNode.IsDucking = false
				nextNode.DuckTimeMsecs = math.max(config.TimeToUnDuckMsecs, 1)
			else
				resolvedSupportPosition = v12
			end

			reusableGroundTrace = v11
		end
	end

	local y = nil

	if v10 then
		local v11 = not onGround and state3.OnGround == false

		if v11 then
			y = state3.Velocity.Y
		end

		local traceSurfaceVelocity = getTraceSurfaceVelocity(reusableGroundTrace)
		local movedRelativeGroundVelocity

		if onGround then
			movedRelativeGroundVelocity = state2.MovedRelativeGroundVelocity
		else
			movedRelativeGroundVelocity = nextNode.Velocity - traceSurfaceVelocity
		end

		if v11 then
			movedRelativeGroundVelocity = applyBunnyHopLandingPenalty(movedRelativeGroundVelocity, config)
		end

		nextNode.OnGround = true
		nextNode.GroundSupportIsDynamicPlayer = isDynamicPlayerSupportTrace(reusableGroundTrace)
		nextNode.GroundNormal = reusableGroundTrace.normal
		nextNode.GroundSurfaceFriction = getTraceSurfaceFriction(reusableGroundTrace, config)
		nextNode.Position = resolvedSupportPosition
		nextNode.Velocity = Vector3.new(movedRelativeGroundVelocity.X, 0, movedRelativeGroundVelocity.Z) + traceSurfaceVelocity
		nextNode.JumpHullActive = false
	else
		nextNode.OnGround = false
		nextNode.GroundSupportIsDynamicPlayer = false
		nextNode.GroundSurfaceFriction = nextNode.Velocity.Y > 0 and 0.25 or config.SurfaceFrictionDefault

		if not state2.UsedLadderMove then
			nextNode.Velocity += Vector3.new(0, -config.Gravity * deltaTime * 0.5, 0)
		end
	end

	state("proven.groundCategorization", nextNode, line(1))
	nextNode.Stamina = v.finishStamina(nextNode.Stamina, y, deltaTime, config)
	nextNode.JumpHeld = state2.Input.Jump
	state("proven.finalState", nextNode, line(1))
	debug.profileend()

	if v10 then
		return reusableGroundTrace
	end

	return nil
end

function v.step(state2, input, deltaTime: number, world, config, p)
	Trace.bind(p)
	local v5 = beginStep(state2, input, deltaTime, world, config, p)
	local nextNode = v5.Next
	debug.profilebegin("Sim.duck")
	Duck.applyDuckStateForStep(nextNode, state2, input, deltaTime, world, config)
	debug.profileend()
	state("proven.duckState", nextNode, line(1))
	resolveSpeedAndStance(v5)
	recoverStartSolid(v5)
	resolveWish(v5)

	if moveOnLadder(v5) then
		Trace.bind(nil)
		return nextNode, nil
	end

	if not v5.UsedLadderMove then
		moveOffLadder(v5)
	end

	commitMove(v5)

	if finishRisingTick(v5) then
		Trace.bind(nil)
		return nextNode, nil
	end

	local v6 = categorizeGround(v5)
	Trace.bind(nil)
	return nextNode, v6
end

function v.checkStandingClearance(vector2: Vector3, p, p2)
	local uncrouchClearance, v5 = getUncrouchClearance(vector2, p, p2)
	return uncrouchClearance, v5
end

return table.freeze(v)