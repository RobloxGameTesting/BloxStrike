local SpeedProfile = require(script.Parent.Parent.SpeedProfile)
local v = 0.03125 * SpeedProfile.HammerUnitToStud
local DefaultBaseSpeed = SpeedProfile.DefaultBaseSpeed
local ProvenMath = {}

function ProvenMath.approach(p: number, p2: number, p3: number)
	if p2 < p then
		return (math.min(p2 + p3, p))
	end

	return (math.max(p2 - p3, p))
end

function ProvenMath.flatten(vector: Vector3)
	return (Vector3.new(vector.X, 0, vector.Z))
end

function ProvenMath.clipVelocity(vector: Vector3, vector2: Vector3, value: number?)
	local vector3 = vector - vector2 * (vector:Dot(vector2) * (value or 1))
	local dot = vector3:Dot(vector2)

	if dot <= 0 then
		vector3 -= vector2 * math.min(dot, -v)
	end

	return vector3
end

function ProvenMath.moveVectorToWorld(point: Vector2, p: number)
	local v2 = math.sin(p)
	local v3 = math.cos(p)
	local v4 = -point.Y
	local x = point.X
	local v5 = v3 * x - v2 * v4
	local v6 = -v2 * x - v3 * v4
	local v7 = v5 * v5 + v6 * v6

	if v7 > 1 then
		local v8 = 1 / math.sqrt(v7)
		v5 *= v8
		v6 *= v8
	end

	return (Vector3.new(v5, 0, v6))
end

function ProvenMath.applyFriction(vector: Vector3, p: number, p2: number, p3: number, p4: number)
	local x = vector.X
	local z = vector.Z
	local v2 = x * x + z * z

	if v2 <= 0 then
		return vector
	end

	local v3 = math.sqrt(v2)

	if v3 <= 0 then
		return vector
	end

	local v4 = math.max(v3 - math.max(v3, p3) * p2 * p4 * p, 0)

	if v4 ~= v3 and v3 > 0 then
		local v5 = v4 / v3
		x *= v5
		z *= v5
	end

	return (Vector3.new(x, vector.Y, z))
end

function ProvenMath.accelerate(vector: Vector3, vector2: Vector3, p: number, p2: number, p3: number, p4: number, p5: number)
	local v2 = p - vector:Dot(vector2)

	if v2 <= 0 then
		return vector
	end

	local v3 = math.max(DefaultBaseSpeed, p) * p5
	return vector + vector2 * math.min(p2 * p3 * v3 * p4, v2)
end

function ProvenMath.airAccelerate(vector: Vector3, vector2: Vector3, p: number, p2: number, p3: number, p4: number, p5: number)
	local v2 = math.min(p, p3) - vector:Dot(vector2)

	if v2 <= 0 then
		return vector
	end

	local v3 = p2 * p * p4 * p5

	if v2 < v3 then
		v3 = v2
	end

	return vector + vector2 * v3
end

function ProvenMath.legacyBunnyHopAirAccelerate(vector: Vector3, vector2: Vector3, p: number, p2: number, p3: number, p4: number)
	local v2 = math.min(p, p3)
	local v3 = v2 - vector:Dot(vector2)

	if v3 <= 0 then
		return vector
	end

	return vector + vector2 * math.min(p2 * v2 * p4, v3)
end

function ProvenMath.clampHorizontal(vector: Vector3, p: number)
	local x = vector.X
	local z = vector.Z
	local v2 = x * x + z * z

	if p * p < v2 and v2 > 0 then
		local v3 = p / math.sqrt(v2)
		x *= v3
		z *= v3
	end

	return (Vector3.new(x, vector.Y, z))
end

function ProvenMath.horizontalMagnitude(vector: Vector3)
	return (math.sqrt(vector.X * vector.X + vector.Z * vector.Z))
end

function ProvenMath.magnitudeSq(vector: Vector3)
	return vector.X * vector.X + vector.Y * vector.Y + vector.Z * vector.Z
end

function ProvenMath.horizontalMagnitudeSq(vector: Vector3)
	return vector.X * vector.X + vector.Z * vector.Z
end

return ProvenMath