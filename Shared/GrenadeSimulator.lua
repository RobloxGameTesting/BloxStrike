local createVector = vector.create
local GrenadeSimulator = {
	Constants = {
		GRENADE_ELASTICITY = 0.4,
		FLOOR_NORMAL_THRESHOLD = 0.7,
		FIXED_TIMESTEP = 0.0078125,
		GRAVITY = createVector(0, -23.833334, 0),
		THROW_UPWARD_BIAS_FAR = 0.06,
		THROW_UPWARD_BIAS_NEAR = 0.04,
		THROW_FORWARD_OFFSET = 1.35,
		THROW_HEIGHT_OFFSET = 2.4,
		MAX_SIMULATION_TIME = 10
	},
	createInitialState = function(total: Vector3, vector: Vector3, p: string, vector2: Vector3, p2: number, timestamp: number)
		local v = ((p == "Far" and 1 or 0) * 0.7 + 0.3) * 57.29166666666667 * p2 * 0.58
		local isJumpThrow = vector2.Y > 5
		local v2 = 1

		if isJumpThrow then
			total += createVector(0, 0, 0)
		end

		local v3 = isJumpThrow and createVector(0, 20, 0) or Vector3.new(0, vector2.Y * 2 * 0.58, 0)
		local v4

		if isJumpThrow then
			v4 = Vector3.new(vector.X * v2, vector.Y, vector.Z * v2).Unit
		else
			v4 = vector
		end

		local v5 = not isJumpThrow and 1 or v2
		local v6 = v4 * v + v3 + (Vector3.new(vector.X * v5, vector.Y, vector.Z * v5).Unit * v * 0.15 + Vector3.new(0, p2 * 6.5 * 0.58, 0))
		local v7 = not isJumpThrow and 50 or (vector.Y - 0.4) * 20 + 62

		if v7 < v6.Magnitude then
			v6 = v6.Unit * v7
		end

		local velocity = v6 + Vector3.new(vector2.X, 0, vector2.Z) * 1.5 * v2
		local v8 = math.floor(timestamp * 1000) % 1000
		return {
			position = total,
			velocity = velocity,
			angularVelocity = Vector3.new(v8 % 11 - 5, math.floor(v8 / 11) % 13 - 6, math.floor(v8 / 143) % 11 - 5),
			timestamp = timestamp,
			simulationTime = 0,
			bounceCount = 0,
			isGrounded = false,
			isAtRest = false,
			hasTouched = false,
			accumulatedTime = 0,
			isJumpThrow = isJumpThrow
		}
	end,
	createConfig = function(radius: number, rangeScale: number, isNearThrow: boolean, fuseTime: number?, minimumFuseTime: number?, flag: boolean?)
		return {
			radius = radius,
			restitution = 0.4,
			maxBounces = 20,
			fuseTime = fuseTime,
			minimumFuseTime = minimumFuseTime,
			explodeOnFloorImpact = flag,
			rangeScale = rangeScale,
			isNearThrow = isNearThrow
		}
	end,
	detectCollision = function(vector: Vector3, vector2: Vector3, p: number, p2)
		local v = vector2 - vector
		local magnitude = v.Magnitude

		if magnitude < 0.001 then
			return nil
		end

		local v2 = p * 0.01
		local v3 = {
			Vector3.new(v2, 0, 0),
			Vector3.new(-v2, 0, 0),
			Vector3.new(0, v2, 0),
			Vector3.new(0, -v2, 0),
			Vector3.new(0, 0, v2),
			(Vector3.new(0, 0, -v2))
		}
		local distance = 1e999
		local raycastResult = workspace:Raycast(vector, v, p2)

		if raycastResult and raycastResult.Distance < distance then
			distance = raycastResult.Distance
		else
			raycastResult = nil
		end

		local v4 = createVector(0, 0, 0)

		for _, v5 in v3 do
			local v6 = vector + v5
			local raycastResult2 = workspace:Raycast(v6, v, p2)

			if not (raycastResult2 and raycastResult2.Distance < distance) then
				continue
			end

			distance = raycastResult2.Distance
			v4 = v5
			raycastResult = raycastResult2
		end

		if not raycastResult then
			return nil
		end

		local position = raycastResult.Position - v4
		local magnitude2 = (position - vector).Magnitude

		if magnitude + v2 + 0.1 < magnitude2 then
			return nil
		end

		local instance = raycastResult.Instance
		local parent = instance.Parent
		local isPlayer

		if parent == nil then
			isPlayer = false
		else
			isPlayer = parent:IsA("Model") and parent:GetAttribute("CharacterType") == "PlayerCustomCharacter"
		end

		local isGlass = parent and parent:HasTag("BreakableGlass") or instance:HasTag("BreakableGlass")
		return {
			hit = true,
			position = position,
			normal = raycastResult.Normal,
			distance = magnitude2,
			instance = instance,
			isPlayer = isPlayer,
			isGlass = isGlass
		}
	end,
	checkGrounded = function(vector: Vector3, p)
		local raycastResult = workspace:Raycast(vector, createVector(0, -0.2, 0), p)

		if raycastResult then
			return true, raycastResult.Normal
		end

		return false, nil
	end
}

local function PhysicsClipVelocity(vector: Vector3, vector2: Vector3, p: number)
	local v = vector:Dot(vector2) * p
	local v2 = vector.X - vector2.X * v
	local v3 = vector.Y - vector2.Y * v
	local v4 = vector.Z - vector2.Z * v
	return (Vector3.new(
		math.abs(v2) < 0.0076388888888888895 and 0 or v2,
		math.abs(v3) < 0.0076388888888888895 and 0 or v3,
		math.abs(v4) < 0.0076388888888888895 and 0 or v4
	))
end

function GrenadeSimulator.integrate(vector: Vector3, vector2: Vector3, p: number, flag: boolean)
	if flag then
		return vector + vector2 * p, vector2
	end

	local v = vector2.Y - p * 23.83333396911621
	local midpoint = (vector2.Y + v) / 2
	local vector3 = Vector3.new(vector2.X * p, midpoint * p, vector2.Z * p)
	local vector4 = Vector3.new(vector2.X, v, vector2.Z)
	return vector + vector3, vector4
end

function GrenadeSimulator.calculateBounce(vector: Vector3, vector2: Vector3, p, flag: boolean)
	local clone = table.clone(p)
	clone.bounceCount = p.bounceCount + 1
	clone.hasTouched = true
	local v = math.clamp((p.isJumpThrow and 0.32 or 0.4) * (flag and 0.3 or 1), 0, 0.9)
	local vector3 = PhysicsClipVelocity(vector, vector2, 2) * v

	if vector2.Y > 0.7 and vector3:Dot(vector3) < 2.3341049382716053 then
		return createVector(0, 0, 0), clone
	end

	return vector3, clone
end

function GrenadeSimulator.shouldStop(vector: Vector3, flag: boolean, flag2: boolean)
	if flag and flag2 then
		return vector:Dot(vector) < 2.3341049382716053
	end

	return false
end

local function newEvent(p: string, data, clone, normal: Vector3, velocity: Vector3) -- 2 equivalent calls inferred from this helper
	return {
		type = p,
		timestamp = data.timestamp + clone.simulationTime,
		position = clone.position,
		normal = normal,
		velocity = velocity,
		bounceCount = clone.bounceCount
	}
end

function GrenadeSimulator.step(data, data2, p, p2: number)
	local clone = table.clone(data)
	clone.simulationTime = data.simulationTime + p2
	local v = nil

	if clone.simulationTime >= 10 then
		clone.isAtRest = true
		local velocity = clone.velocity
		return clone, {
			type = "timeout",
			timestamp = data.timestamp + clone.simulationTime,
			position = clone.position,
			normal = createVector(0, 1, 0),
			velocity = velocity,
			bounceCount = clone.bounceCount
		}
	elseif data2.fuseTime and clone.simulationTime >= data2.fuseTime then
		clone.isAtRest = true
		local velocity = clone.velocity
		return clone, {
			type = "fuse",
			timestamp = data.timestamp + clone.simulationTime,
			position = clone.position,
			normal = createVector(0, 1, 0),
			velocity = velocity,
			bounceCount = clone.bounceCount
		}
	elseif data.bounceCount >= data2.maxBounces then
		clone.isAtRest = true
		clone.velocity = createVector(0, 0, 0)
		return clone, {
			type = "rest",
			timestamp = data.timestamp + clone.simulationTime,
			position = clone.position,
			normal = createVector(0, 1, 0),
			velocity = createVector(0, 0, 0),
			bounceCount = clone.bounceCount
		}
	else
		local position = clone.position
		local integrate, velocity = GrenadeSimulator.integrate(clone.position, clone.velocity, p2, clone.isGrounded)
		local collision = GrenadeSimulator.detectCollision(position, integrate, data2.radius, p)

		if collision then
			local velocity2
			velocity2, clone = GrenadeSimulator.calculateBounce(velocity, collision.normal, clone, collision.isPlayer)
			clone.position = collision.position + collision.normal * 0.05
			clone.velocity = velocity2
			local v2 = collision.normal.Y > 0.7

			if
				data2.explodeOnFloorImpact
				and v2
				and (not data2.minimumFuseTime or clone.simulationTime >= data2.minimumFuseTime)
			then
				clone.isAtRest = true
				return clone, newEvent("floor_impact", data, clone, collision.normal, clone.velocity) -- inferred equivalent call
			else
				v = newEvent("bounce", data, clone, collision.normal, clone.velocity) -- inferred equivalent call
			end
		else
			clone.position = integrate
			clone.velocity = velocity
		end

		local isGrounded, v2 = GrenadeSimulator.checkGrounded(clone.position, p)
		clone.isGrounded = isGrounded

		if
			not GrenadeSimulator.shouldStop(clone.velocity, isGrounded, clone.hasTouched)
			or data2.minimumFuseTime and not (clone.simulationTime >= data2.minimumFuseTime)
			or data2.fuseTime
		then
			return clone, v
		end

		clone.isAtRest = true
		clone.velocity = createVector(0, 0, 0)
		clone.angularVelocity = createVector(0, 0, 0)
		return clone, {
			type = "rest",
			timestamp = data.timestamp + clone.simulationTime,
			position = clone.position,
			normal = v2 or createVector(0, 1, 0),
			velocity = createVector(0, 0, 0),
			bounceCount = clone.bounceCount
		}
	end
end

function GrenadeSimulator.simulate(state, p, p2, p3: number)
	if state.isAtRest then
		if not p.fuseTime then
			return { state = state, events = {} }
		end

		local clone = table.clone(state)
		clone.simulationTime = state.simulationTime + p3

		if not (clone.simulationTime >= p.fuseTime) then
			return { state = clone, events = {} }
		end

		local velocity = clone.velocity
		return {
			state = clone,
			events = {
				{
					type = "fuse",
					timestamp = state.timestamp + clone.simulationTime,
					position = clone.position,
					normal = createVector(0, 1, 0),
					velocity = velocity,
					bounceCount = clone.bounceCount
				}
			}
		}
	else
		local clone = table.clone(state)
		clone.accumulatedTime = state.accumulatedTime + p3

		if clone.accumulatedTime > 0.1 then
			clone.accumulatedTime = 0.1
		end

		local count = 0
		local events = {}

		while clone.accumulatedTime >= 0.0078125 and count < 16 do
			count += 1
			clone.accumulatedTime -= 0.0078125
			local v
			clone, v = GrenadeSimulator.step(clone, p, p2, 0.0078125)

			if v then
				table.insert(events, v)
			end

			if clone.isAtRest then
				break
			end
		end

		return { state = clone, events = events }
	end
end

function GrenadeSimulator.calculateThrowParameters(vector: Vector3, vector2: Vector3, p: string, value: number)
	local v = p == "Near"
	local v2 = (v and 0.04 or 0.06) * math.clamp(value, 0.8, 1.2)
	local v3 = 1.35
	local v4 = 2.4
	local v5

	if v then
		v3 *= 0.55
		v5 = v4 * 0.8
		v2 += 0.08
	else
		v5 = v4 + 0.1
	end

	local unit = (vector2 + Vector3.new(0, v2, 0)).Unit
	local vector3 = Vector3.new(vector2.X, 0, vector2.Z)
	return
		vector + (vector3.Magnitude < 0.01 and createVector(0, 0, -1) or vector3).Unit * v3 + Vector3.new(0, v5, 0),
		unit
end

return GrenadeSimulator