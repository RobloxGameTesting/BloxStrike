return function(p)
	local rotation = p.Rotation
	local position = p.Position
	local value = rotation.RotationDampen.Value
	local value2 = rotation.RotationSpeed.Value
	local value3 = position.PositionDampen.Value
	local value4 = position.PositionSpeed.Value
	local damper = value3 > 2 and 1 or value3
	local speed = value4 > 2 and 1 or value4
	local speed2 = value2 >= 30 and 25 or value2
	local value5 = rotation.RotationX.Value
	local value6 = rotation.RotationY.Value
	local value7 = rotation.RotationZ.Value
	local damper2 = value >= 5 and 1 or value
	local v = (value5 < 0.1 and 1 or value5) * 0.8
	local v2 = math.abs(value6) < 0.1 and 25 or math.abs(value6)
	return {
		Value = Vector3.new(v, (math.random() * 2 - 1) * v2 * 0.5, value7 < 0.1 and 1 or value7),
		Damper = damper2,
		Speed = speed2
	}, {
		Value = Vector3.new(position.PositionX.Value, position.PositionY.Value, position.PositionZ.Value),
		Damper = damper,
		Speed = speed
	}
end