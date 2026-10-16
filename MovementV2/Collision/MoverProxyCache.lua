local createVector = vector.create
local MoverProxyCache = {}
MoverProxyCache.__index = MoverProxyCache
MoverProxyCache.ContactMaxRotationRadiansPerSubdivision = 0.008726646259971648
MoverProxyCache.ContactMaxRotationSubdivisions = 16
MoverProxyCache.ContactMaxRotationRadiansPerTick = MoverProxyCache.ContactMaxRotationRadiansPerSubdivision * MoverProxyCache.ContactMaxRotationSubdivisions
local frozen = table.freeze({ createVector(1, 0, 0), createVector(0, 1, 0), createVector(0, 0, 1) })

local function newContactHull()
	return {
		Center = createVector(0, 0, 0),
		SourceWorldHalf = createVector(0, 0, 0),
		RotationPadding = 0,
		NormalCount = 0,
		Normals = table.create(30, createVector(0, 0, 0)),
		SourceSupports = table.create(30, 0)
	}
end

local function newContactProxy()
	local substeps = table.create(MoverProxyCache.ContactMaxRotationSubdivisions)

	for i = 1, MoverProxyCache.ContactMaxRotationSubdivisions do
		substeps[i] = {
			TimeStart = 0,
			TimeEnd = 0,
			ReferenceCenter = createVector(0, 0, 0),
			Hull = newContactHull()
		}
	end

	return {
		StartHull = newContactHull(),
		EndHull = newContactHull(),
		SubstepCount = 0,
		Substeps = substeps,
		ScratchCount = 0,
		ScratchDirections = table.create(30, createVector(0, 0, 0)),
		PreviousPose = nil,
		Pose = nil,
		Size = nil,
		Config = nil
	}
end

local function directionLess(scratchDirection: Vector3, vector: Vector3) -- 1 equivalent call inferred from this helper
	if scratchDirection.X ~= vector.X then
		return scratchDirection.X < vector.X
	end

	if scratchDirection.Y == vector.Y then
		return scratchDirection.Z < vector.Z
	end

	return scratchDirection.Y < vector.Y
end

local function appendDirection(state, vector: Vector3, p)
	local magnitude = vector.Magnitude

	if magnitude <= p.PlaneNormalEpsilon then
		return
	end

	local v = vector / magnitude

	for i = 1, state.ScratchCount do
		if state.ScratchDirections[i]:Dot(v) >= p.PlaneDuplicateDot then
			return
		end
	end

	local scratchCount = state.ScratchCount + 1
	assert(scratchCount <= 30, "mover contact SAT direction capacity exceeded")
	state.ScratchDirections[scratchCount] = v
	state.ScratchCount = scratchCount
end

local function appendBothDirections(state, vector: Vector3, p) -- 7 equivalent calls inferred from this helper
	appendDirection(state, vector, p)
	appendDirection(state, -vector, p)
end

local function sortScratchDirections(state)
	for i = 2, state.ScratchCount do
		local scratchDirection = state.ScratchDirections[i]
		local v = i

		while v > 1 do
			if not directionLess(scratchDirection, state.ScratchDirections[v - 1]) then -- inferred equivalent call
				break
			end

			state.ScratchDirections[v] = state.ScratchDirections[v - 1]
			v -= 1
		end

		state.ScratchDirections[v] = scratchDirection
	end
end

local function prepareHull(state, state2, p, cframe: CFrame, rotationPadding: number, config)
	state.ScratchCount = 0

	for _, v in frozen do
		appendBothDirections(state, v, config) -- inferred equivalent call
	end

	local rightVector = cframe.RightVector
	local upVector = cframe.UpVector
	local lookVector = cframe.LookVector
	appendBothDirections(state, rightVector, config) -- inferred equivalent call

	for _, v in frozen do
		appendBothDirections(state, rightVector:Cross(v), config) -- inferred equivalent call
	end

	appendBothDirections(state, upVector, config) -- inferred equivalent call

	for _, v in frozen do
		appendBothDirections(state, upVector:Cross(v), config) -- inferred equivalent call
	end

	appendBothDirections(state, lookVector, config) -- inferred equivalent call

	for _, v in frozen do
		appendBothDirections(state, lookVector:Cross(v), config) -- inferred equivalent call
	end

	sortScratchDirections(state)
	local v = p.Size * 0.5

	for i = 1, state.ScratchCount do
		local scratchDirection = state.ScratchDirections[i]
		state2.Normals[i] = scratchDirection
		state2.SourceSupports[i] = math.abs((scratchDirection:Dot(rightVector))) * v.X + math.abs((scratchDirection:Dot(upVector))) * v.Y + math.abs((scratchDirection:Dot(lookVector))) * v.Z
	end

	state2.NormalCount = state.ScratchCount
	state2.Center = cframe.Position
	state2.RotationPadding = rotationPadding
	state2.SourceWorldHalf = Vector3.new(
		math.abs(rightVector.X) * v.X + math.abs(upVector.X) * v.Y + math.abs(lookVector.X) * v.Z,
		math.abs(rightVector.Y) * v.X + math.abs(upVector.Y) * v.Y + math.abs(lookVector.Y) * v.Z,
		math.abs(rightVector.Z) * v.X + math.abs(upVector.Z) * v.Y + math.abs(lookVector.Z) * v.Z
	)
end

local function playerHalfSize(p, p2: string) -- 7 equivalent calls inferred from this helper
	if p2 == "Standing" then
		return p.StandingHalfSize
	elseif p2 == "Ducking" then
		return p.DuckingHalfSize
	end

	error("contact mover body has an invalid stance", 3)
end

function MoverProxyCache.ContactQueryBounds(cframe: CFrame, cframe2: CFrame, vector: Vector3, data)
	local v = math.max(data.StandingHalfSize.Magnitude, data.DuckingHalfSize.Magnitude)
	local v2 = math.max(data.ContactEpsilon, data.BrushEpsilon) + data.BroadphasePadding
	local v3 = (vector * 0.5).Magnitude + v + v2
	local vector2 = Vector3.new(v3, v3, v3)
	local position = cframe.Position
	local position2 = cframe2.Position
	return
		Vector3.new(
			math.min(position.X, position2.X),
			math.min(position.Y, position2.Y),
			(math.min(position.Z, position2.Z))
		) - vector2,
		Vector3.new(
			math.max(position.X, position2.X),
			math.max(position.Y, position2.Y),
			(math.max(position.Z, position2.Z))
		) + vector2
end

local function planeDistance(data, i: number, vector: Vector3)
	local normal = data.Normals[i]
	return data.Center:Dot(normal) + data.SourceSupports[i] + math.abs(normal.X) * vector.X + math.abs(normal.Y) * vector.Y + math.abs(normal.Z) * vector.Z + data.RotationPadding
end

local function containsHull(p, vector: Vector3, vector2: Vector3, p2)
	local v = math.max(p2.ContactEpsilon, p2.BrushEpsilon)

	for i = 1, p.NormalCount do
		if vector:Dot(p.Normals[i]) - planeDistance(p, i, vector2) >= -v then
			return false
		end
	end

	return true
end

local function maximumHullDistance(p, position: Vector3, vector: Vector3)
	local v = -1e999
	local v2 = createVector(0, 1, 0)

	for i = 1, p.NormalCount do
		local normal = p.Normals[i]
		local v3 = position:Dot(normal) - planeDistance(p, i, vector)

		if not (v < v3) then
			continue
		end

		v2 = normal
		v = v3
	end

	return v, v2
end

local function pointSegmentDistanceSquared(position: Vector3, position2: Vector3, position3: Vector3)
	local vector = position3 - position2
	local dot = vector:Dot(vector)

	if dot <= 1e-18 then
		local vector2 = position - position2
		return vector2:Dot(vector2)
	end

	local vector2 = position - (position2 + vector * math.clamp((position - position2):Dot(vector) / dot, 0, 1))
	return vector2:Dot(vector2)
end

local function couldReachAnyBody(data, items, data2)
	local position = data.PreviousCFrame.Position
	local position2 = data.CFrame.Position
	local v = math.max(data2.ContactEpsilon, data2.BrushEpsilon) + data2.BroadphasePadding

	for _, item in items do
		local v2 = data.BoundingRadius + playerHalfSize(data2, item.Stance).Magnitude + v -- inferred equivalent call

		if pointSegmentDistanceSquared(item.Position, position, position2) <= v2 * v2 then
			return true
		end
	end

	return false
end

local function boundsOverlapHull(data, vector: Vector3, vector2: Vector3, vector3: Vector3, broadphasePadding: number)
	local v = data.RotationPadding + broadphasePadding
	local v2 = data.SourceWorldHalf + vector3 + Vector3.new(v, v, v)
	local v3 = data.Center - v2
	local v4 = data.Center + v2

	if
		math.min(vector.X, vector2.X) <= v4.X
		and math.max(vector.X, vector2.X) >= v3.X
		and math.min(vector.Y, vector2.Y) <= v4.Y
		and math.max(vector.Y, vector2.Y) >= v3.Y
		and math.min(vector.Z, vector2.Z) <= v4.Z
	then
		return math.max(vector.Z, vector2.Z) >= v3.Z
	else
		return false
	end
end

local function sweepHull(hull, vector: Vector3, vector2: Vector3, vector3: Vector3, data, flag: boolean?)
	if not boundsOverlapHull(hull, vector, vector2, vector3, data.BroadphasePadding) then
		return nil, createVector(0, 1, 0), false, false, 0
	end

	local vector4 = vector2 - vector
	local magnitude = vector4.Magnitude
	local v = -1e999
	local v2 = -1e999
	local v3 = false
	local v4 = false
	local v5 = -1
	local v6 = false
	local v7 = 1e999
	local v8 = 1
	local v9 = 1e999
	local v10 = createVector(0, 1, 0)
	local v11 = createVector(0, 1, 0)

	for i = 1, hull.NormalCount do
		local normal = hull.Normals[i]
		local v12 = vector:Dot(normal) - planeDistance(hull, i, vector3)
		local v13 = v12 + vector4:Dot(normal)

		if v + data.BrushEpsilon < v12 or math.abs(v12 - v) <= data.BrushEpsilon and i < v9 then
			v11 = normal
			v9 = i
		end

		v = math.max(v, v12)
		v2 = math.max(v2, v13)
		v3 = v3 or v12 > 0
		v4 = v4 or v13 > 0

		if v12 > 0 and v13 > 0 then
			return nil, createVector(0, 1, 0), false, false, 0
		end

		if not (v12 > 0 or v13 > 0) then
			continue
		end

		if v13 < v12 then
			local v14 = math.max(0, (v12 - data.BrushEpsilon) / (v12 - v13))
			local v15 = math.abs(v14 - v5) * magnitude

			if not v6 or data.BrushEpsilon < v15 and v5 < v14 or v15 <= data.BrushEpsilon and i < v7 then
				v10 = normal
				v7 = i
			end

			v5 = math.max(v5, v14)
			v6 = true
		else
			v8 = math.min(v8, (math.min(1, (v12 + data.BrushEpsilon) / (v12 - v13))))
		end
	end

	if v3 then
		if v6 and not (v5 < 0 or v8 <= v5) then
			return math.max(0, v5), v10, false, false, v7
		end

		return nil, createVector(0, 1, 0), false, false, 0
	else
		if (v4 or flag == true) and v < v2 and data.ContactEpsilon < magnitude and vector4.Unit:Dot(v11) > 0.25 then
			return nil, createVector(0, 1, 0), false, false, 0
		end

		local v12 = 0
		local v13 = true
		local v14 = not v4 and v2 < v

		if v9 < 1e999 then
			return v12, v11, true, v14, v9
		end

		return v12, v11, v13, v14, 0
	end
end

local function prepareContactProxy(state, instance, config)
	if
		state.PreviousPose == instance.PreviousCFrame
		and state.Pose == instance.CFrame
		and state.Size == instance.Size
		and state.Config == config
	then
		return
	end

	local rotationAngle = math.abs(instance.RotationAngle)

	if MoverProxyCache.ContactMaxRotationRadiansPerTick + 1e-9 < rotationAngle then
		error(
			string.format(
				"contact mover %d rotates %.4f degrees in one tick; authored maximum is %.4f",
				instance.Id,
				math.deg(rotationAngle),
				(math.deg(MoverProxyCache.ContactMaxRotationRadiansPerTick))
			),
			3
		)
	end

	local substepCount = math.max(
		1,
		(math.ceil(rotationAngle / MoverProxyCache.ContactMaxRotationRadiansPerSubdivision - 1e-12))
	)
	assert(
		substepCount <= MoverProxyCache.ContactMaxRotationSubdivisions,
		"contact mover subdivision capacity exceeded"
	)
	state.SubstepCount = substepCount
	prepareHull(state, state.StartHull, instance, instance.PreviousCFrame, 0, config)
	prepareHull(state, state.EndHull, instance, instance.CFrame, 0, config)

	for i = 1, substepCount do
		local timeStart = (i - 1) / substepCount
		local timeEnd = i / substepCount
		local v = (timeStart + timeEnd) * 0.5
		local lerped = instance.PreviousCFrame:Lerp(instance.CFrame, v)
		local v2 = rotationAngle / substepCount
		local substep = state.Substeps[i]
		substep.TimeStart = timeStart
		substep.TimeEnd = timeEnd
		substep.ReferenceCenter = lerped.Position
		prepareHull(state, substep.Hull, instance, lerped, instance.BoundingRadius * 2 * math.sin(v2 * 0.25), config)
	end

	state.PreviousPose = instance.PreviousCFrame
	state.Pose = instance.CFrame
	state.Size = instance.Size
	state.Config = config
end

function MoverProxyCache.new()
	return (setmetatable({
		_banks = {
			{ EndpointsById = {} },
			{ EndpointsById = {} }
		},
		_contactById = {},
		_endpointScratch = {
			ScratchCount = 0,
			ScratchDirections = table.create(30, createVector(0, 0, 0))
		},
		_activeBank = 0
	}, MoverProxyCache))
end

function MoverProxyCache:BeginComposition()
	self._activeBank = self._activeBank == 1 and 2 or 1
end

function MoverProxyCache:ReserveMover(p: number)
	local v = p % 1 == 0 and p > 0
	assert(v, "mover ID must be a positive integer")

	if self._banks[1].EndpointsById[p] ~= nil then
		assert(self._banks[2].EndpointsById[p] ~= nil, "mover endpoint proxy banks diverged")
		return
	end

	for _, bank in self._banks do
		bank.EndpointsById[p] = {
			Record = nil,
			Hull = newContactHull(),
			Pose = nil,
			Size = nil,
			Config = nil
		}
	end
end

function MoverProxyCache:ReserveContactMover(p: number)
	self:ReserveMover(p)

	if self._contactById[p] == nil then
		self._contactById[p] = newContactProxy()
	end
end

function MoverProxyCache:BindEndpoint(record, config)
	assert(self._activeBank ~= 0, "mover proxy cache composition was not begun")
	local v = self._banks[self._activeBank].EndpointsById[record.Id]

	if v == nil then
		error(string.format("mover %d endpoint proxy was not reserved at registration", record.Id), 2)
	end

	if v.Pose ~= record.CFrame or v.Size ~= record.Size or v.Config ~= config then
		prepareHull(self._endpointScratch, v.Hull, record, record.CFrame, 0, config)
		v.Pose = record.CFrame
		v.Size = record.Size
		v.Config = config
	end

	v.Record = record
	return v
end

function MoverProxyCache.SweepEndpoint(p, vector: Vector3, vector2: Vector3, p2: string, p3)
	return sweepHull(p.Hull, vector, vector2, playerHalfSize(p3, p2), p3, true) -- inferred equivalent call
end

function MoverProxyCache.ContainsEndpoint(p, vector: Vector3, p2: string, p3)
	return (containsHull(p.Hull, vector, playerHalfSize(p3, p2), p3)) -- inferred equivalent call
end

function MoverProxyCache.PenetratesEndpoint(p, vector: Vector3, p2: string, p3)
	local hull = p.Hull
	local v = playerHalfSize(p3, p2) -- inferred equivalent call

	for i = 1, hull.NormalCount do
		if vector:Dot(hull.Normals[i]) - planeDistance(hull, i, v) > 0 then
			return false
		end
	end

	return true
end

function MoverProxyCache.PushExitDistances(p, vector: Vector3, vector2: Vector3, p2: string, p3, p4: number)
	local hull = p.Hull
	local v = playerHalfSize(p3, p2) -- inferred equivalent call
	local v2 = 1e999
	local v3 = 1e999

	for i = 1, hull.NormalCount do
		local normal = hull.Normals[i]
		local v4 = vector:Dot(normal) - planeDistance(hull, i, v)

		if v4 > 0 then
			return nil, 1e999
		end

		local dot = vector2:Dot(normal)

		if p3.PlaneNormalEpsilon < dot then
			v2 = math.min(v2, (p4 - v4) / dot)
		elseif dot < -p3.PlaneNormalEpsilon then
			v3 = math.min(v3, (p4 - v4) / -dot)
		end
	end

	return v2, v3
end

function MoverProxyCache:Retire(p: number)
	for _, bank in self._banks do
		bank.EndpointsById[p] = nil
	end

	self._contactById[p] = nil
end

function MoverProxyCache:Reset()
	for _, bank in self._banks do
		table.clear(bank.EndpointsById)
	end

	table.clear(self._contactById)
	self._endpointScratch.ScratchCount = 0
	self._activeBank = 0
end

function MoverProxyCache:FindEarliestStationaryContact(data, list, data2)
	if #list == 0 then
		return nil, nil, nil
	end

	local v = self._contactById[data.Id]

	if v == nil then
		error(string.format("contact mover %d was not reserved at registration", data.Id), 2)
	end

	if not couldReachAnyBody(data, list, data2) then
		return nil, nil, nil
	end

	prepareContactProxy(v, data, data2)
	local position = data.PreviousCFrame.Position
	local position2 = data.CFrame.Position
	local v2 = math.max(data2.ContactEpsilon, data2.BrushEpsilon) + data2.BroadphasePadding
	local v3 = nil
	local v4 = nil
	local v5 = nil

	for k, v6 in list do
		local v7 = data.BoundingRadius + playerHalfSize(data2, v6.Stance).Magnitude + v2 -- inferred equivalent call
		local v8 = pointSegmentDistanceSquared(v6.Position, position, position2)

		if v7 * v7 < v8 then
			continue
		end

		local id = v6.Id or k
		local v9 = playerHalfSize(data2, v6.Stance) -- inferred equivalent call
		local v10 = math.max(data2.ContactEpsilon, data2.BrushEpsilon)
		local v11, v12 = maximumHullDistance(v.StartHull, v6.Position, v9)

		if v11 <= v10 then
			local v13 = maximumHullDistance(v.EndHull, v6.Position, v9)

			if not (v11 + v10 < v13) then
				return 0, v12, id
			end
		else
			for i = 1, v.SubstepCount do
				local substep = v.Substeps[i]

				if v3 ~= nil and v3 <= substep.TimeStart then
					break
				end

				local lerped = data.PreviousCFrame.Position:Lerp(data.CFrame.Position, substep.TimeStart)
				local lerped2 = data.PreviousCFrame.Position:Lerp(data.CFrame.Position, substep.TimeEnd)
				local v13 = v6.Position - lerped + substep.ReferenceCenter
				local v14 = v6.Position - lerped2 + substep.ReferenceCenter
				local v15, v16 = sweepHull(substep.Hull, v13, v14, v9, data2)

				if v15 == nil then
					continue
				end

				local v17 = substep.TimeStart + (substep.TimeEnd - substep.TimeStart) * v15

				if v3 == nil or v17 < v3 then
					v5 = id
					v4 = v16
					v3 = v17
				end

				if v17 <= 0 then
					return 0, v16, id
				else
					break
				end
			end
		end
	end

	return v3, v4, v5
end

return MoverProxyCache