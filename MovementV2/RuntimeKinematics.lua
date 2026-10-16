local createVector = vector.create
local v = {}
local object = setmetatable({}, { __mode = "k" })

function v.write(p, velocity: Vector3, onGround: boolean, position: Vector3?)
	if p == nil then
		return
	end

	local v2 = object[p]

	if v2 == nil then
		object[p] = { Velocity = velocity, OnGround = onGround, Position = position }
		return
	end

	v2.Velocity = velocity
	v2.OnGround = onGround
	v2.Position = position
end

function v.clear(p)
	if p ~= nil then
		object[p] = nil
	end
end

function v.read(p)
	if p == nil then
		return nil
	end

	return object[p]
end

function v.getVelocity(p, instance)
	local v2 = v.read(p)

	if v2 ~= nil then
		return v2.Velocity, true
	end

	if instance == nil then
		return createVector(0, 0, 0), false
	end

	return instance.AssemblyLinearVelocity, false
end

function v.getPosition(p, p2)
	local v2 = v.read(p)

	if v2 ~= nil and v2.Position ~= nil then
		return v2.Position, true
	end

	if p2 == nil then
		return createVector(0, 0, 0), false
	end

	return p2.Position, false
end

function v.isOnGround(p)
	local v2 = v.read(p)

	if v2 == nil then
		return false, false
	end

	return v2.OnGround, true
end

function v.resolve(p, p2)
	local velocity, v2 = v.getVelocity(p, p2)
	local onGround, v3 = v.isOnGround(p)
	local vector = Vector3.new(velocity.X, 0, velocity.Z)
	return velocity, vector, vector.Magnitude, velocity.Y, onGround, v2 or v3
end

return table.freeze(v)