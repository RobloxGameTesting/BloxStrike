local createVector = vector.create

local function vec3ToArray(vector: Vector3) -- 10 equivalent calls inferred from this helper
	return { vector.X, vector.Y, vector.Z }
end

local function calculateAngle(vector: Vector3, normal: Vector3) -- 2 equivalent calls inferred from this helper
	local magnitude = vector.Magnitude

	if magnitude < 0.001 then
		return 0
	end

	return (math.deg((math.acos((math.clamp(math.abs(((vector / magnitude):Dot(normal))), -1, 1))))))
end

local GrenadeTrajectoryExporter = {}

function GrenadeTrajectoryExporter.startRecording(grenade_type: string, throw_type: string, vector: Vector3, vector2: Vector3, vector3: Vector3, value: string?)
	return {
		grenade_type = grenade_type,
		throw_type = throw_type,
		start_position = vec3ToArray(vector), -- inferred equivalent call
		throw_direction = vec3ToArray(vector2.Unit), -- inferred equivalent call
		player_velocity = vec3ToArray(vector3), -- inferred equivalent call
		player_state = value or "standing",
		map_name = "",
		start_time = tick(),
		points = {},
		bounces = {},
		end_position = nil,
		end_reason = nil
	}
end

function GrenadeTrajectoryExporter.recordPoint(p, data, flag: boolean?)
	local time_ms = math.floor(data.simulationTime * 1000)
	local v = not (#p.points > 0) and -16 or p.points[#p.points].time_ms

	if not flag and time_ms - v < 16 then
		return
	end

	local points = p.points
	local v2 = {
		time_ms = time_ms,
		position = vec3ToArray(data.position), -- inferred equivalent call
		velocity = vec3ToArray(data.velocity), -- inferred equivalent call
		speed = data.velocity.Magnitude
	}
	table.insert(points, v2)
end

function GrenadeTrajectoryExporter.recordBounce(p, data, vector: Vector3, value: string?)
	local normal = data.normal or createVector(0, 1, 0)
	local velocity = data.velocity
	local bounces = p.bounces
	local v = {
		time_ms = math.floor((data.timestamp - (p.start_time or data.timestamp)) * 1000),
		position = vec3ToArray(data.position), -- inferred equivalent call
		velocity_before = vec3ToArray(vector), -- inferred equivalent call
		velocity_after = vec3ToArray(velocity), -- inferred equivalent call
		surface_normal = vec3ToArray(normal), -- inferred equivalent call
		surface_type = value or "world",
		incident_angle = calculateAngle(vector, normal), -- inferred equivalent call
		reflection_angle = calculateAngle(velocity, normal) -- inferred equivalent call
	}
	table.insert(bounces, v)
end

function GrenadeTrajectoryExporter:finishRecording(vector: Vector3, end_reason: string)
	self.end_position = vec3ToArray(vector) -- inferred equivalent call
	self.end_reason = end_reason
end

return GrenadeTrajectoryExporter