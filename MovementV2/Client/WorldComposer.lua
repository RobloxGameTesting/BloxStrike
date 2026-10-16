require(script.Parent.Parent.Types)
require(script.Parent.Parent.Simulation.Types)
require(script.Parent.Parent.Collision.TopologyBuilder)
require(script.Parent.Parent.Collision.DestructibleFrame)
local World = require(script.Parent.Parent.Collision.World)
require(script.Parent.RemoteBuffer)
require(script.Parent.Parent.Simulation.PlayerContacts)
local Serial = require(script.Parent.Parent.Serial)
local frozen = table.freeze({ Start = 0, Finish = 1 })
return table.freeze({
	compose = function(self, serverTick: number, p: number?, moverRevision: number?, contactState, flag: boolean?, _, p2)
		local mapping = self._mapping
		local topology = self._topology
		local timeline = self._timeline
		local config = self._config

		if mapping == nil or topology == nil or timeline == nil or config == nil then
			return nil, "CollisionContextUnavailable"
		end

		local v, v2

		if flag then
			v, v2 = timeline:predict(serverTick, p)
		else
			v, v2 = timeline:resolve(serverTick, p)
		end

		if v == nil then
			return nil, v2
		end

		local cachedStaticWorld = self._cachedStaticWorld

		if cachedStaticWorld == nil or self._cachedStaticFrame ~= v then
			cachedStaticWorld = World.new(topology, v)
			self._cachedStaticFrame = v
			self._cachedStaticWorld = cachedStaticWorld
		end

		local v3 = p2 or self._collisionComposer
		local v4 = {
			Mapping = mapping,
			ServerTick = serverTick,
			PreviousServerTick = Serial.addUInt32(serverTick, -1),
			StepSeconds = config.StepSeconds,
			Interval = frozen,
			Topology = topology,
			Destructibles = v,
			StaticWorld = cachedStaticWorld,
			MoverRevision = moverRevision,
			Speculative = flag == true,
			ContactState = contactState
		}
		local v5 = nil
		local composed

		if v3 == nil then
			if moverRevision ~= nil and moverRevision ~= 0 then
				return nil, "MoverComposerUnavailable"
			end

			composed = {
				Query = cachedStaticWorld,
				CanOccupyAtEnd = function(p3, p4, p5)
					return cachedStaticWorld:CanMove(p4, p5, p3.Stance, nil, 1, 1)
				end
			}
		else
			composed, v5 = v3:Compose(v4)
		end

		if composed == nil then
			return nil, v5 or "CollisionComposerUnavailable"
		end

		local query = composed.Query

		if
			query == nil
			or type(query.Sweep) ~= "function"
			or type(query.IsClear) ~= "function"
			or type(query.CanMove) ~= "function"
			or type(query.FindGround) ~= "function"
		then
			return nil, "ComposedCollisionQueryInvalid"
		end

		if type(composed.CanOccupyAtEnd) == "function" then
			return { ServerTick = serverTick, Destructibles = v, Composed = composed }, nil
		end

		return nil, "CollisionComposerMissingEndOccupancy"
	end
})