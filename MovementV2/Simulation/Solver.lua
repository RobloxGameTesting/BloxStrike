local createVector = vector.create
local Config = require(script.Parent.Config)
local ProvenMath = require(script.Parent.ProvenMath)
require(script.Parent.Types)
local v = {}

local function endpoint(vector: Vector3, vector2: Vector3, value: number) -- 1 equivalent call inferred from this helper
	return vector:Lerp(vector2, (math.clamp(value, 0, 1)))
end

local function normalizedOrUp(normal: Vector3) -- 1 equivalent call inferred from this helper
	local magnitude = normal.Magnitude

	if magnitude > 0 then
		return normal / magnitude
	end

	return createVector(0, 1, 0)
end

local function isWall(vector: Vector3, p: number)
	return math.abs(vector.Y) < p
end

local function validateTimeInterval(total: number, p: number) -- 1 equivalent call inferred from this helper
	local v2 = total == total and p == p and total >= 0 and total <= p and p <= 1
	assert(v2, "movement collision time interval must be normalized and ordered")
end

local function appendPlane(list, vector: Vector3, maxClipPlanes: number)
	for _, vector2 in list do
		if vector2:Dot(vector) > 0.999 then
			return true
		end
	end

	if maxClipPlanes <= #list then
		return false
	end

	table.insert(list, vector)
	return true
end

local function clearsEveryPlane(vector: Vector3, items, p: number) -- 2 equivalent calls inferred from this helper
	for _, item in items do
		if vector:Dot(item) < -p then
			return false
		end
	end

	return true
end

local function resolvePlanes(vector: Vector3, list, planeEpsilon: number)
	for _, v2 in list do
		local clipVelocity = ProvenMath.clipVelocity(vector, v2)

		if clearsEveryPlane(clipVelocity, list, planeEpsilon) then -- inferred equivalent call
			return clipVelocity
		end
	end

	if #list ~= 2 then
		return createVector(0, 0, 0)
	end

	local cross = list[1]:Cross(list[2])
	local magnitude = cross.Magnitude

	if planeEpsilon < magnitude then
		local v2 = cross / magnitude
		local v3 = v2 * vector:Dot(v2)

		if clearsEveryPlane(v3, list, planeEpsilon) then -- inferred equivalent call
			return v3
		end
	end

	return createVector(0, 0, 0)
end

function v.slideMove(vector: Vector3, vector2: Vector3, p: number, p2, object, p3, total: number, p4: number, p5, flag: boolean?)
	validateTimeInterval(total, p4) -- inferred equivalent call
	local v2 = p5 or Config.Default
	local v3 = vector2
	local total2 = 0
	local wallNormal = createVector(0, 0, 0)
	local blocked = false
	local startSolid = false
	local v4 = {}

	for _ = 1, v2.MaxBumps do
		if p <= 0 then
			break
		end

		local v5 = vector + vector2 * p
		local v6

		if flag then
			v6 = object:SweepWithFloorSupport(vector, v5, p2, p3, total, p4)
		else
			v6 = object:Sweep(vector, v5, p2, p3, total, p4)
		end

		if flag and (v6.StartSolid or v6.AllSolid) and vector2:Dot(v6.Normal) > v2.PositionSnapEpsilon then
			v6 = object:Sweep(vector, v5, p2, p3, total, p4)
		end

		startSolid = startSolid or v6.StartSolid

		if v6.AllSolid then
			vector2 = createVector(0, 0, 0)
			blocked = true
			break
		else
			local v7 = math.clamp(v6.Fraction, 0, 1)
			local v8 = v7 > 0 and v7 < 0.0001 and 0 or v7
			total2 += v8
			total += (p4 - total) * v8

			if v8 > 0 then
				vector = endpoint(vector, v5, v8) -- inferred equivalent call
				table.clear(v4)
				v3 = vector2
			end

			if v8 >= 1 then
				break
			end

			blocked = true
			p *= 1 - v8
			local v9 = normalizedOrUp(v6.Normal) -- inferred equivalent call

			if v2.WalkableFloor > math.abs(v9.Y) then
				wallNormal = v9
			end

			if not appendPlane(v4, v9, v2.MaxClipPlanes) then
				vector2 = createVector(0, 0, 0)
				break
			end

			vector2 = resolvePlanes(v3, v4, v2.PlaneEpsilon)

			if vector2:Dot(v3) <= 0 then
				vector2 = createVector(0, 0, 0)
				break
			end
		end
	end

	local v5 = total2 == 0 and createVector(0, 0, 0) or vector2
	return {
		Position = vector,
		Velocity = v5.Magnitude <= v2.VelocityEpsilon and createVector(0, 0, 0) or v5,
		WallNormal = wallNormal,
		Blocked = blocked,
		StartSolid = startSolid,
		TimeFraction = total
	}
end

function v.slideDisplacement(vector: Vector3, vector2: Vector3, p, p2, p3, p4: number, p5: number, p6)
	return v.slideMove(vector, vector2, 1, p, p2, p3, p4, p5, p6)
end

return table.freeze(v)