local createVector = vector.create
local Enums = require(script.Parent.Parent.Enums)
require(script.Parent.Parent.Types)
require(script.Parent.Config)
require(script.Parent.Types)
local DeterminismTrace = require(script.Parent.DeterminismTrace)
local ProvenMath = require(script.Parent.ProvenMath)
local PlayerContacts = require(script.Parent.PlayerContacts)
local PlayerLanding = require(script.Parent.PlayerLanding)
require(script.Parent.PlayerHullClearance)
local ProvenSimulator = require(script.Parent.ProvenSimulator)

local function cloneSupport(data) -- 3 equivalent calls inferred from this helper
	return {
		Kind = data.Kind,
		SourceId = data.SourceId,
		Anchor = data.Anchor,
		Velocity = data.Velocity
	}
end

local function emptySupport() -- 1 equivalent call inferred from this helper
	return {
		Kind = Enums.SupportKind.None,
		SourceId = 0,
		Anchor = createVector(0, 0, 0),
		Velocity = createVector(0, 0, 0)
	}
end

local function clearGround(state, worldVelocity: Vector3, data) -- 2 equivalent calls inferred from this helper
	state.OnGround = false
	state.GroundNormal = createVector(0, 1, 0)
	state.GroundSurfaceFriction = data.SurfaceFrictionDefault
	state.Velocity = worldVelocity
	return emptySupport() -- inferred equivalent call
end

local function applyGroundVelocity(state, worldVelocity: Vector3, data, groundNormal: Vector3, p: number, data2)
	local support = cloneSupport(data) -- inferred equivalent call
	local v = PlayerContacts.fromWorldVelocity(worldVelocity, support)
	local vector = ProvenMath.clipVelocity(v, groundNormal)

	if math.abs(groundNormal.Y - 1) <= data2.PlaneEpsilon then
		vector = Vector3.new(vector.X, 0, vector.Z)
	end

	state.OnGround = true
	state.MovementMode = "Walking"
	state.GroundNormal = groundNormal
	state.GroundSurfaceFriction = math.max(p, 0)
	state.Velocity = vector
	return support, vector + support.Velocity
end

return table.freeze({
	finalize = function(data, p, state, data2, state2, state3, p2, object, p3: number, data3, p4, p5)
		if PlayerLanding.needsStanding(state) then
			if state3.Stance == "Standing" then
				state.Stance = "Standing"
				state.JumpHullActive = false
			else
				p2 = nil
			end
		end

		local worldVelocity = PlayerContacts.toWorldVelocity(state.Velocity, data2)
		local landed = state2.Landed
		local impactVelocityY = state2.ImpactVelocityY
		local onGround = data.OnGround

		if onGround then
			if p.Kind == Enums.SupportKind.Player then
				onGround = state.OnGround

				if onGround then
					if data2.Kind == Enums.SupportKind.Player then
						onGround = data2.SourceId == p.SourceId
					else
						onGround = false
					end
				end
			else
				onGround = false
			end
		end

		local v = state3.Position ~= state.Position
		local v2 = state3.WorldVelocity ~= worldVelocity
		state.Position = state3.Position
		local worldVelocity2 = state3.WorldVelocity
		DeterminismTrace.checkpoint(p4, "runtime.playerContacts.bodyCommit", state, data2, nil)

		if v or v2 or p2 ~= nil or data2.Kind == Enums.SupportKind.Player then
			local v3

			if state.OnGround then
				v3 = data2
			end

			local v4

			if p2 == nil then
				if onGround and data2.Kind == Enums.SupportKind.Player and data2.SourceId == p.SourceId then
					local v5 = state3.WorldVelocity - worldVelocity
					local clipVelocity = ProvenMath.clipVelocity(state.Velocity + v5, createVector(0, 1, 0))
					local vector = Vector3.new(clipVelocity.X, 0, clipVelocity.Z)
					v4 = cloneSupport(data2) -- inferred equivalent call
					state.OnGround = true
					state.MovementMode = "Walking"
					state.GroundNormal = createVector(0, 1, 0)
					state.GroundSurfaceFriction = data3.SurfaceFrictionDefault
					state.Velocity = vector
					local _ = vector + v4.Velocity
				elseif v or data2.Kind == Enums.SupportKind.Player then
					local ground = object:FindGround(state.Position, state.Stance, data3.GroundProbeDistance, 1, v3)
					local v5

					if ground == nil or not (ground.Normal.Y >= data3.WalkableFloor) then
						v5 = false
					else
						v5 = worldVelocity2.Y - ground.Support.Velocity.Y <= data3.GroundClearVelocity
					end

					if v5 and ground ~= nil and PlayerLanding.needsStanding(state) then
						ground = PlayerLanding.restoreWorldGround(ground, object, data3, p5, p4)

						if ground == nil or not (ground.Normal.Y >= data3.WalkableFloor) then
							v5 = false
						else
							v5 = worldVelocity2.Y - ground.Support.Velocity.Y <= data3.GroundClearVelocity
						end

						if v5 then
							state.Stance = "Standing"
							state.JumpHullActive = false
						end
					end

					if v5 and ground ~= nil then
						state.Position = ground.Position
						local position = ground.Position
						local stance = state.Stance
						state3.Position = position
						state3.Stance = stance
						local _
						v4, _ = applyGroundVelocity(
							state,
							worldVelocity2,
							ground.Support,
							ground.Normal,
							ground.SurfaceFriction,
							data3
						)
					else
						v4 = clearGround(state, worldVelocity2, data3) -- inferred equivalent call
					end
				elseif state.OnGround then
					local _
					v4, _ = applyGroundVelocity(
						state,
						worldVelocity2,
						data2,
						state.GroundNormal,
						state.GroundSurfaceFriction,
						data3
					)
				else
					v4 = clearGround(state, worldVelocity2, data3) -- inferred equivalent call
				end
			elseif onGround and p2.SourceId == p.SourceId then
				local v5 = state3.WorldVelocity - worldVelocity
				local clipVelocity = ProvenMath.clipVelocity(state.Velocity + v5, createVector(0, 1, 0))
				local vector = Vector3.new(clipVelocity.X, 0, clipVelocity.Z)
				v4 = cloneSupport(p2) -- inferred equivalent call
				state.OnGround = true
				state.MovementMode = "Walking"
				state.GroundNormal = createVector(0, 1, 0)
				state.GroundSurfaceFriction = data3.SurfaceFrictionDefault
				state.Velocity = vector
				local _ = vector + v4.Velocity
			else
				local _
				v4, _ = applyGroundVelocity(
					state,
					worldVelocity2,
					p2,
					createVector(0, 1, 0),
					data3.SurfaceFrictionDefault,
					data3
				)
			end

			DeterminismTrace.checkpoint(p4, "runtime.playerContacts.groundFinalize", state, v4, nil)

			if state.OnGround and state.DuckAmount >= 0.999 then
				state.JumpHullActive = false
			end

			local onGround2 = not data.OnGround and state.OnGround
			local leftGround = data.OnGround and not state.OnGround
			local impactVelocityY2

			if onGround2 then
				impactVelocityY2 = impactVelocityY or data.Velocity.Y
			end

			if landed and not onGround2 then
				state.Stamina = ProvenSimulator.finishStamina(data.Stamina, nil, 1 / p3, data3)
			elseif onGround2 and not landed and impactVelocityY2 ~= nil then
				state.Stamina = ProvenSimulator.finishStamina(data.Stamina, impactVelocityY2, 1 / p3, data3)
				state.Velocity = ProvenSimulator.applyLandingVelocity(state.Velocity, data3)
			end

			state2.Landed = onGround2
			state2.LeftGround = leftGround
			state2.ImpactVelocityY = impactVelocityY2
			DeterminismTrace.checkpoint(p4, "runtime.playerContacts.eventsFinalize", state, v4, nil)
			assert(state.OnGround == (v4.Kind ~= Enums.SupportKind.None), "post-contact ground invariant is broken")
			return state, v4, state2
		else
			DeterminismTrace.checkpoint(p4, "runtime.playerContacts.groundFinalize", state, data2, nil)
			DeterminismTrace.checkpoint(p4, "runtime.playerContacts.eventsFinalize", state, data2, nil)
			return state, data2, state2
		end
	end
})