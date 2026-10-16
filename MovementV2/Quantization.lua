local createVector = vector.create
local v = {
	isFinite = function(value)
		return typeof(value) == "number" and value - value == 0
	end,
	isFiniteVector2 = function(p)
		if typeof(p) ~= "Vector2" then
			return false
		end

		local x = p.X
		local y = p.Y
		return x - x == 0 and y - y == 0
	end,
	isFiniteVector3 = function(data)
		if typeof(data) ~= "Vector3" then
			return false
		end

		local x = data.X
		local y = data.Y
		local z = data.Z
		return x - x == 0 and y - y == 0 and z - z == 0
	end
}

function v.isVector3Within(data, p: number)
	local finiteVector3 = v.isFiniteVector3(data)

	if finiteVector3 then
		if math.abs(data.X) <= p and math.abs(data.Y) <= p then
			finiteVector3 = math.abs(data.Z) <= p
		else
			finiteVector3 = false
		end
	end

	return finiteVector3
end

function v.writeVector3F32(buf: buffer, offset: number, vector: Vector3)
	buffer.writef32(buf, offset, vector.X)
	buffer.writef32(buf, offset + 4, vector.Y)
	buffer.writef32(buf, offset + 8, vector.Z)
	return offset + 12
end

function v.readVector3F32(buf: buffer, offset: number)
	return
		Vector3.new(buffer.readf32(buf, offset), buffer.readf32(buf, offset + 4), (buffer.readf32(buf, offset + 8))),
		offset + 12
end

function v.canonicalMove(point: Vector2)
	return Vector2.new(math.clamp(point.X, -1, 1), (math.clamp(point.Y, -1, 1)))
end

function v.quantizeSignedUnit(value: number)
	return (math.clamp(math.round(math.clamp(value, -1, 1) * 127), -127, 127))
end

function v.dequantizeSignedUnit(p: number)
	return (math.clamp(p / 127, -1, 1))
end

function v.quantizeYaw(p: number)
	return math.round(p % 6.283185307179586 / 6.283185307179586 * 65536) % 65536
end

function v.dequantizeYaw(p: number)
	local v2 = p / 65536 * 6.283185307179586

	if v2 >= 3.141592653589793 then
		return v2 - 6.283185307179586
	end

	return v2
end

function v.quantizeUnitByte(value: number)
	return (math.clamp(math.round(math.clamp(value, 0, 1) * 255), 0, 255))
end

function v.dequantizeUnitByte(p: number)
	return (math.clamp(p / 255, 0, 1))
end

function v.quantizeNormal(vector: Vector3)
	local v2 = not (vector.Magnitude > 1e-8) and createVector(0, 0, 0) or vector.Unit
	return math.round(v2.X * 32767), math.round(v2.Y * 32767), (math.round(v2.Z * 32767))
end

function v.dequantizeNormal(p: number, p2: number, p3: number)
	local vector = Vector3.new(p / 32767, p2 / 32767, p3 / 32767)

	if vector.Magnitude > 1e-8 then
		return vector.Unit
	end

	return createVector(0, 0, 0)
end

return table.freeze(v)