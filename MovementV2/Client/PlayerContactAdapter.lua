local Enums = require(script.Parent.Parent.Enums)
local DiagnosticProtocol = require(script.Parent.Parent.DiagnosticProtocol)
require(script.Parent.Parent.Types)
local Config = require(script.Parent.Parent.Simulation.Config)
require(script.Parent.Parent.Simulation.DeterminismTrace)
local PlayerContactStep = require(script.Parent.Parent.Simulation.PlayerContactStep)
local PlayerContacts = require(script.Parent.Parent.Simulation.PlayerContacts)
local PlayerHullClearance = require(script.Parent.Parent.Simulation.PlayerHullClearance)
local PlayerLanding = require(script.Parent.Parent.Simulation.PlayerLanding)
require(script.Parent.Parent.Simulation.Types)
require(script.Parent.RemoteBuffer)
local Players = game:GetService("Players")
local scratch = PlayerContacts.newScratch()
local v2 = PlayerContacts.DefaultContactEpsilon + PlayerContacts.DefaultSeparationSkin
local now = -1e999

local function playerContactDebugEnabled() -- 1 equivalent call inferred from this helper
	return DiagnosticProtocol.PlayerContactOutputEnabled
		and DiagnosticProtocol.shouldOutputForPlayer(Players.LocalPlayer)
end

local function compareBodyId(p, p2)
	return p.Id < p2.Id
end

local function vectorLabel(velocity: Vector3) -- 6 equivalent calls inferred from this helper
	return string.format("%.3f/%.3f/%.3f", velocity.X, velocity.Y, velocity.Z)
end

local function reasonCountsLabel(items)
	local v = {}

	for k, item in items do
		v[#v + 1] = `{k}:{item}`
	end

	table.sort(v)

	if #v == 0 then
		return "none"
	end

	return (table.concat(v, ","))
end

local function bodyHalfSize(stance, p) -- 3 equivalent calls inferred from this helper
	local v

	if stance == "Ducking" then
		v = p.PlayerSizeDucking
	else
		v = p.PlayerSizeStanding
	end

	return v * 0.5
end

local function sweptIntervalsOverlap(p: number, p2: number, p3: number, p4: number, p5: number, p6: number, p7: number)
	local v = math.min(p, p2) - p3
	local v3 = math.max(p, p2) + p3
	local v4 = math.min(p4, p5) - p6
	return v <= math.max(p4, p5) + p6 + p7 and v4 <= v3 + p7
end

local function couldContact(data, data2, p, halfSize: Vector3?)
	if not halfSize then
		halfSize = bodyHalfSize(data.Stance, p) -- inferred equivalent call
	end

	local v = bodyHalfSize(data2.Stance, p) -- inferred equivalent call
	local x = data.StartPosition.X
	local x2 = data.Position.X
	local x3 = halfSize.X
	local x4 = data2.StartPosition.X
	local x5 = data2.Position.X
	local x6 = v.X
	local v3 = v2
	local v4 = math.min(x, x2) - x3
	local v5 = math.max(x, x2) + x3
	local v6 = math.min(x4, x5) - x6
	local v7

	if v4 <= math.max(x4, x5) + x6 + v3 then
		v7 = v6 <= v5 + v3
	else
		v7 = false
	end

	if not v7 then
		return v7
	end

	local y = data.StartPosition.Y
	local y2 = data.Position.Y
	local y3 = halfSize.Y
	local y4 = data2.StartPosition.Y
	local y5 = data2.Position.Y
	local y6 = v.Y
	local v8 = v2
	local v9 = math.min(y, y2) - y3
	local v10 = math.max(y, y2) + y3
	local v11 = math.min(y4, y5) - y6

	if v9 <= math.max(y4, y5) + y6 + v8 then
		v7 = v11 <= v10 + v8
	else
		v7 = false
	end

	if not v7 then
		return v7
	end

	local z = data.StartPosition.Z
	local z2 = data.Position.Z
	local z3 = halfSize.Z
	local z4 = data2.StartPosition.Z
	local z5 = data2.Position.Z
	local z6 = v.Z
	local v12 = v2
	local v13 = math.min(z, z2) - z3
	local v14 = math.max(z, z2) + z3
	local v15 = math.min(z4, z5) - z6

	if v13 <= math.max(z4, z5) + z6 + v12 then
		return v15 <= v14 + v12
	else
		return false
	end

	return v7
end

local function contactQueryBounds(data, p, halfSize: Vector3?)
	if not halfSize then
		halfSize = bodyHalfSize(data.Stance, p) -- inferred equivalent call
	end

	local v = p.PlayerSizeStanding * 0.5
	local v3 = p.PlayerSizeDucking * 0.5
	local v4 = halfSize + Vector3.new(math.max(v.X, v3.X), math.max(v.Y, v3.Y), (math.max(v.Z, v3.Z))) + Vector3.new(v2, v2, v2)
	local vector = Vector3.new(
		math.min(data.StartPosition.X, data.Position.X),
		math.min(data.StartPosition.Y, data.Position.Y),
		(math.min(data.StartPosition.Z, data.Position.Z))
	)
	local vector2 = Vector3.new(
		math.max(data.StartPosition.X, data.Position.X),
		math.max(data.StartPosition.Y, data.Position.Y),
		(math.max(data.StartPosition.Z, data.Position.Z))
	)
	return vector - v4, vector2 + v4
end

local function newStanceProbe()
	local v = { ServerTick = 0, Contacts = {} }

	local function probe(vector: Vector3, p)
		local v3 = assert(v.Mapping)
		local v4 = assert(v.RemoteBuffer)
		local v5 = assert(v.Config)
		local bounds, v6 = PlayerHullClearance.bounds(vector, p, v5)
		local actorId = nil

		for _, v7 in v4:queryCollisionActorKeys(bounds, v6) do
			local collisionPose = v4:getCollisionPose(v7, v.ServerTick, 0)

			if not (collisionPose ~= nil and collisionPose.ActorId ~= v3.ActorId and PlayerHullClearance.overlaps(
				vector,
				p,
				collisionPose.Position,
				collisionPose.Stance,
				v5
			)) then
				continue
			end

			v.Contacts[collisionPose.ActorId] = true

			if actorId == nil then
				actorId = collisionPose.ActorId
			else
				actorId = math.min(actorId, collisionPose.ActorId)
			end
		end

		return actorId
	end

	return probe, v
end

local probe, v3 = newStanceProbe()
local probe2, v4 = newStanceProbe()

local function bindProbe(p, mapping, serverTick: number, remoteBuffer, config, contacts) -- 2 equivalent calls inferred from this helper
	p.Mapping = mapping
	p.ServerTick = serverTick
	p.RemoteBuffer = remoteBuffer
	p.Config = config
	p.Contacts = contacts
end

local v = {
	bindStanceProbe = function(mapping, serverTick: number, remoteBuffer, config)
		if not mapping.PlayerCollisionsEnabled then
			return nil, nil
		end

		local contacts = v3.Contacts
		table.clear(contacts)
		bindProbe(v3, mapping, serverTick, remoteBuffer, config, contacts) -- inferred equivalent call
		return probe, contacts
	end,
	resolvePlayerSupportMotion = function(p, data, object, p2: number, p3: number)
		if data.Kind ~= Enums.SupportKind.Player or data.SourceId == 0 then
			return nil
		end

		local collisionPose = object:getCollisionPoseByActorId(data.SourceId, p2, 0)

		if collisionPose == nil then
			return nil
		end

		local v = p.Position - data.Anchor
		local vector = Vector3.new(collisionPose.Velocity.X, 0, collisionPose.Velocity.Z)
		return {
			Kind = Enums.SupportKind.Player,
			SourceId = data.SourceId,
			Delta = collisionPose.Position - v - vector * p3,
			Velocity = collisionPose.Velocity,
			Position = collisionPose.Position,
			Stance = collisionPose.Stance
		}
	end,
	solve = function(p, p2, data, p3, p4, mapping, serverTick: number, remoteBuffer, p5, callback, p6, traceRecorder)
		local v = {
			Id = mapping.ActorId,
			StartPosition = p.Position,
			Position = data.Position,
			WorldVelocity = PlayerContacts.toWorldVelocity(data.Velocity, p3),
			Stance = data.Stance,
			OwnsMotion = true
		}
		local position = data.Position
		local magnitude = (position - p.Position).Magnitude
		local worldVelocity = v.WorldVelocity
		local config = p6 or Config.Default
		local v5 = { v }
		local v6 = playerContactDebugEnabled() and os.clock() - now >= 0.25 -- inferred equivalent call
		local v7 = v6 and {} or nil
		local v8 = v6 and {} or nil

		if v6 then
			now = os.clock()
		end

		local needsStanding = PlayerLanding.needsStanding(data)
		local halfSize = PlayerLanding.queryHalfSize(data, config)
		local v9, v10 = contactQueryBounds(v, config, halfSize)

		for _, v11 in remoteBuffer:queryCollisionActorKeys(v9, v10) do
			local collisionPose, v12 = remoteBuffer:getCollisionPose(v11, serverTick, 0)

			if collisionPose == nil or collisionPose.ActorId == mapping.ActorId then
				if collisionPose == nil and v12 ~= nil and v8 ~= nil then
					v8[v12] = (v8[v12] or 0) + 1
				end
			else
				local v13 = {
					Id = collisionPose.ActorId,
					StartPosition = collisionPose.Position,
					Position = collisionPose.Position,
					WorldVelocity = collisionPose.Velocity,
					Stance = collisionPose.Stance,
					OwnsMotion = false
				}

				if couldContact(v, v13, config, halfSize) then
					v5[#v5 + 1] = v13

					if v7 ~= nil then
						local v14 = #v7 + 1
						v7[v14] = string.format(
							"a%d src=%u raw=%s replicatedVel=%s",
							collisionPose.ActorId,
							collisionPose.SourceServerTick,
							vectorLabel(v13.Position), -- inferred equivalent call
							vectorLabel(collisionPose.Velocity)
						)
					end
				end
			end
		end

		table.sort(v5, compareBodyId)
		local v11, v12

		if needsStanding then
			v11 = {}
			bindProbe(v4, mapping, serverTick, remoteBuffer, config, v11) -- inferred equivalent call
			v12 = probe2
			PlayerLanding.prepare(data, v, v5, p5, config, v12, traceRecorder)
		end

		local solve = PlayerContacts.solve(v5, {
			CanOccupy = callback ~= nil and function(p7, p8)
				return callback(p7, p7.Position, p8)
			end or nil,
			Config = config,
			TraceRecorder = traceRecorder,
			TraceBodyId = mapping.ActorId,
			Scratch = scratch
		})
		local externalDisplacement = math.max(
			(v.Position - position).Magnitude - magnitude - PlayerContacts.DefaultSeparationSkin,
			0
		)
		local contactActorIds = v11 or {}

		for _, contact in solve.Contacts do
			if contact.A == mapping.ActorId then
				contactActorIds[contact.B] = true
			elseif contact.B == mapping.ActorId then
				contactActorIds[contact.A] = true
			end
		end

		local v13 = solve.SupportsById[mapping.ActorId]

		if v13 ~= nil then
			contactActorIds[v13.SourceId] = true
		end

		local v14 = v8 ~= nil and next(v8) ~= nil
		local v15 = solve.SweptContactCount > 0 or next(contactActorIds) ~= nil or (solve.UnresolvedCount > 0 or v14)

		if v6 and v15 then
			print(string.format(
				"[MovementV2.PlayerContact] CLIENT tick=%u actor=%d start=%s provisional=%s final=%s velBefore=%s velAfter=%s external=%.4f bodies=%d swept=%d unresolved=%d latestRemote=%s misses=%s remotes=[%s]",
				serverTick,
				mapping.ActorId,
				vectorLabel(v.StartPosition), -- inferred equivalent call
				vectorLabel(data.Position), -- inferred equivalent call
				vectorLabel(v.Position), -- inferred equivalent call
				vectorLabel(worldVelocity), -- inferred equivalent call
				vectorLabel(v.WorldVelocity), -- inferred equivalent call
				externalDisplacement,
				#v5,
				solve.SweptContactCount,
				solve.UnresolvedCount,
				remoteBuffer:latestServerTick() == nil and "nil" or tostring(remoteBuffer:latestServerTick()),
				reasonCountsLabel(assert(v8)),
				table.concat(assert(v7), "; ")
			))
		end

		local finalize, support, events = PlayerContactStep.finalize(
			p,
			p2,
			data,
			p3,
			p4,
			v,
			v13,
			p5,
			mapping.SimulationHz,
			config,
			traceRecorder,
			v12
		)

		if support.Kind == Enums.SupportKind.Player then
			contactActorIds[support.SourceId] = true
		end

		return {
			State = finalize,
			Support = support,
			Events = events,
			ContactActorIds = contactActorIds,
			UnresolvedCount = solve.UnresolvedCount,
			NearbyPlayer = #v5 > 1,
			ExternalDisplacement = externalDisplacement
		}
	end
}
return table.freeze(v)