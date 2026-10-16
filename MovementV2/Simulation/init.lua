local createVector = vector.create
local Buttons = require(script.Parent.Buttons)
local Serial = require(script.Parent.Serial)
local DamageTag = require(script.Parent.DamageTag)
local Enums = require(script.Parent.Enums)
require(script.Parent.Types)
local Config = require(script.Config)
local DeterminismTrace = require(script.DeterminismTrace)
local PlayerContacts = require(script.PlayerContacts)
require(script.PlayerHullClearance)
local PlayerSupportQuery = require(script.PlayerSupportQuery)
local ProvenCollisionAdapter = require(script.ProvenCollisionAdapter)
local ProvenSimulator = require(script.ProvenSimulator)
local Solver = require(script.Solver)
local State = require(script.State)
local Types = require(script.Types)

local function activeSupportVelocity(support, data)
	if support.Kind == 0 or support.SourceId == 0 then
		return createVector(0, 0, 0)
	end

	local velocity

	if data == nil or data.Kind ~= support.Kind or data.SourceId ~= support.SourceId then
		velocity = support.Velocity
	else
		velocity = data.Velocity
	end

	if support.Kind == Enums.SupportKind.Player then
		return (Vector3.new(velocity.X, 0, velocity.Z))
	end

	return velocity
end

local function applySupportCarry(clone, support, data, p, p2, p3: number)
	if
		not clone.OnGround
		or support.Kind == 0
		or support.SourceId == 0
		or data == nil
		or data.Kind ~= support.Kind
		or data.SourceId ~= support.SourceId
		or data.Delta.Magnitude <= p2.PlaneEpsilon
	then
		return false, false, createVector(0, 0, 0)
	end

	local delta = data.Delta

	if support.Kind == Enums.SupportKind.Mover then
		local velocity = data.Velocity
		delta -= Vector3.new(velocity.X, 0, velocity.Z) * p3
	end

	local slideDisplacement = Solver.slideDisplacement(clone.Position, delta, clone.Stance, p, support, 1, 1, p2)
	clone.Position = slideDisplacement.Position
	return slideDisplacement.Blocked, slideDisplacement.StartSolid, slideDisplacement.WallNormal
end

local v = {
	Kind = Enums.SupportKind.Mover,
	SourceId = 0,
	Anchor = createVector(0, 0, 0),
	Velocity = createVector(0, 0, 0)
}

local function applyMoverPush(clone, support, p, p2)
	local findMoverPush = p.FindMoverPush
	local penetratesMover = p.PenetratesMover

	if findMoverPush == nil or penetratesMover == nil then
		return nil
	end

	local sourceId = 0
	local v2 = nil

	while true do
		local v3
		sourceId, v3 = findMoverPush(p, clone.Position, clone.Stance, sourceId, 0.01)

		if sourceId == nil then
			break
		end

		if not (support.Kind ~= Enums.SupportKind.Mover or support.SourceId ~= sourceId) then
			continue
		end

		v.SourceId = sourceId
		local slideDisplacement = Solver.slideDisplacement(clone.Position, v3, clone.Stance, p, v, 1, 1, p2)

		if penetratesMover(p, sourceId, slideDisplacement.Position, clone.Stance) then
			v2 = v2 or sourceId
		else
			clone.Position = slideDisplacement.Position
		end
	end

	return v2
end

local v2 = {}
local v3 = {}
local v4 = {}

local function toProvenState(data, vector: Vector3, p, list)
	local velocity

	if data.OnGround then
		velocity = data.Velocity + vector
	else
		velocity = data.Velocity
	end

	local v5 = list or {}

	if list then
		table.clear(list)
	end

	v5.Position = data.Position
	v5.Velocity = velocity
	v5.OnGround = data.OnGround
	v5.GroundSupportIsDynamicPlayer = data.OnGround and p.Kind == Enums.SupportKind.Player
	v5.GroundNormal = data.GroundNormal
	v5.GroundSurfaceFriction = data.GroundSurfaceFriction
	v5.WallNormal = data.WallNormal
	v5.DuckAmount = data.DuckAmount
	v5.DuckTimeMsecs = data.DuckTimeMsecs
	v5.IsDucking = data.IsDucking
	v5.DuckHeld = Buttons.has(data.PreviousButtons, Buttons.Duck)
	v5.DuckFatigueLevel = data.DuckSpeed * 10
	v5.DuckFatigueTimerMsecs = data.DuckCooldownSeconds * 1000
	v5.MovementType = data.MovementMode
	v5.Stamina = data.Stamina
	v5.LastJumpTick = data.LastJumpCommandNumber == 4294967295 and -1024 or data.LastJumpCommandNumber
	v5.JumpHeld = Buttons.has(data.PreviousButtons, Buttons.Jump)
	v5.JumpBufferTicksRemaining = data.JumpBufferTicksRemaining
	v5.JumpHullActive = data.JumpHullActive
	v5.StuckStepTicks = data.StuckStepTicks
	return v5
end

local function toProvenInput(data, p: number, p2: number, list)
	local selected = list or {}

	if list then
		table.clear(list)
	end

	selected.Tick = data.CommandNumber
	selected.MoveVector = data.Move
	selected.LookYaw = data.LookYaw
	selected.VerticalLook = data.VerticalLook
	selected.Jump = Buttons.has(data.Buttons, Buttons.Jump)
	selected.Duck = Buttons.has(data.Buttons, Buttons.Duck)
	selected.Walk = Buttons.has(data.Buttons, Buttons.Walk)
	selected.BaseMoveSpeed = p * p2
	return selected
end

local function outputStance(p)
	if p.DuckAmount >= 0.999 or p.JumpHullActive == true then
		return "Ducking"
	end

	return "Standing"
end

return table.freeze({
	step = function(data, p, data2, p2: number, p3, data3, p4, p5, p6)
		local v5 = p2 == p2 and p2 > 0 and p2 < 1e999
		assert(v5, "MovementV2 simulation step must be finite and positive")
		assert((p.Kind == 0) == (p.SourceId == 0), "MovementV2 support identity is not canonical")
		assert(data.OnGround == (p.Kind ~= 0), "MovementV2 state/support ground invariant is broken")
		local v6 = p4 or Config.Default
		DeterminismTrace.checkpoint(p5, "simulation.input", data, p, data2)
		local support = State.cloneSupport(p)
		local v7

		if
			support.Kind == Enums.SupportKind.Player
			and data3 ~= nil
			and data3.Kind == support.Kind
			and data3.SourceId == support.SourceId
			and data3.Position ~= nil
			and data3.Stance ~= nil
		then
			v7 = PlayerSupportQuery.new(p3, support, data3, v6)
		else
			v7 = p3
		end

		local v8 = p5 == nil
		local clone

		if v8 then
			clone = State.cloneInto(v2, data)
		else
			clone = State.clone(data)
		end

		local blocked, startSolid, wallNormal = applySupportCarry(clone, support, data3, v7, v6, p2)
		DeterminismTrace.checkpoint(p5, "simulation.supportCarry", clone, support, data3)
		local blockedByMoverId = applyMoverPush(clone, support, p3, v6)
		DeterminismTrace.checkpoint(p5, "simulation.moverPush", clone, support, nil)
		local v9 = activeSupportVelocity(support, data3)
		local velocity

		if data.OnGround then
			velocity = data.Velocity + v9
		else
			velocity = data.Velocity
		end

		local acquire = ProvenCollisionAdapter.acquire
		local v10

		if data.OnGround then
			v10 = v9
		end

		local v11 = acquire(v7, v6, support, p5, v10, p6)
		local v12

		if v8 then
			v12 = v3
		end

		local v13 = toProvenState(clone, v9, support, v12)
		local baseMoveSpeed = data.BaseMoveSpeed
		local velocityModifier = data.VelocityModifier
		local v14

		if v8 then
			v14 = v4
		end

		local v15 = toProvenInput(data2, baseMoveSpeed, velocityModifier, v14)
		DeterminismTrace.checkpoint(p5, "simulation.provenInput", v13, support, data2)
		local v16, v17 = ProvenSimulator.step(v13, v15, p2, v11, v6, p5)
		DeterminismTrace.checkpoint(p5, "simulation.provenOutput", v16, nil, nil)
		local stance = (v16.DuckAmount >= 0.999 or v16.JumpHullActive == true) and "Ducking" or "Standing"
		local noneSupport = State.noneSupport()
		local onGround = v16.OnGround
		local velocity2 = v16.Velocity
		local groundNormal = v16.GroundNormal
		local groundSurfaceFriction = v16.GroundSurfaceFriction

		if onGround then
			local groundTrace = v11:ResolveGroundTrace(v17, v16.Position)

			if groundTrace == nil then
				groundTrace = v7:FindGround(
					v16.Position,
					stance,
					math.max(v6.GroundProbeDistance, v6.MaxStepHeight),
					1,
					support
				)
			end

			if groundTrace == nil then
				groundSurfaceFriction = v6.SurfaceFrictionDefault
				onGround = false
			else
				noneSupport = State.cloneSupport(groundTrace.Support)
				local v18 = v16.Velocity - groundTrace.Support.Velocity
				velocity2 = Vector3.new(v18.X, 0, v18.Z)
				groundNormal = groundTrace.Normal
				groundSurfaceFriction = groundTrace.SurfaceFriction
			end
		end

		local v18 = {
			Position = v16.Position,
			Velocity = velocity2,
			LookYaw = data2.LookYaw,
			VerticalLook = data2.VerticalLook,
			BaseMoveSpeed = data.BaseMoveSpeed,
			WeaponMoveSpeed = data.WeaponMoveSpeed,
			WeaponScopedMoveSpeed = data.WeaponScopedMoveSpeed,
			VelocityModifier = DamageTag.recover(data.VelocityModifier, p2),
			MovementTick = Serial.addUInt32(data.MovementTick, 1),
			MovementMode = v16.MovementType,
			Stance = stance,
			OnGround = onGround,
			GroundNormal = not onGround and createVector(0, 1, 0) or groundNormal,
			WallNormal = 0,
			GroundSurfaceFriction = 0,
			DuckAmount = 0,
			DuckTimeMsecs = 0,
			IsDucking = 0,
			DuckSpeed = 0,
			DuckCooldownSeconds = 0,
			Stamina = 0,
			LastJumpCommandNumber = 0,
			PreviousButtons = 0,
			JumpBufferTicksRemaining = 0,
			JumpHullActive = 0,
			StuckStepTicks = 0
		}

		if not (wallNormal.Magnitude > 0) then
			wallNormal = v16.WallNormal
		end

		v18.WallNormal = wallNormal
		v18.GroundSurfaceFriction = groundSurfaceFriction
		v18.DuckAmount = v16.DuckAmount
		v18.DuckTimeMsecs = v16.DuckTimeMsecs
		v18.IsDucking = v16.IsDucking
		v18.DuckSpeed = v16.DuckFatigueLevel / 10
		v18.DuckCooldownSeconds = v16.DuckFatigueTimerMsecs / 1000
		v18.Stamina = v16.Stamina
		v18.LastJumpCommandNumber = v16.LastJumpTick < 0 and 4294967295 or v16.LastJumpTick
		v18.PreviousButtons = data2.Buttons
		v18.JumpBufferTicksRemaining = v16.JumpBufferTicksRemaining
		v18.JumpHullActive = v16.JumpHullActive
		v18.StuckStepTicks = v16.StuckStepTicks
		DeterminismTrace.checkpoint(p5, "simulation.outputConversion", v18, noneSupport, nil)
		local onGround2 = not data.OnGround and v18.OnGround
		local leftGround = data.OnGround and not v18.OnGround
		local v19 = {
			Jumped = leftGround and Buttons.has(data2.Buttons, Buttons.Jump) and v16.Velocity.Y > v6.VelocityEpsilon,
			Landed = onGround2,
			LeftGround = leftGround,
			ImpactVelocityY = 0,
			Blocked = 0,
			StartSolid = 0,
			BlockedByMoverId = 0
		}
		local impactVelocityY

		if onGround2 then
			impactVelocityY = velocity.Y
		end

		v19.ImpactVelocityY = impactVelocityY
		v19.Blocked = blocked
		v19.StartSolid = startSolid
		v19.BlockedByMoverId = blockedByMoverId
		return v18, noneSupport, v19
	end,
	Config = Config,
	DeterminismTrace = DeterminismTrace,
	PlayerContacts = PlayerContacts,
	Solver = Solver,
	State = State,
	Types = Types
})