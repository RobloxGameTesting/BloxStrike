local createVector = vector.create
local Enums = require(script.Parent.Parent.Enums)
local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
local Config = require(script.Parent.Config)
local DeterminismTrace = require(script.Parent.DeterminismTrace)
local v = {
	DefaultIterations = 4,
	DefaultContactEpsilon = 0.002,
	DefaultSeparationSkin = 0.0005,
	newScratch = function()
		return {
			HalfSizes = {},
			PairA = {},
			PairB = {},
			Deltas = {},
			Counts = {},
			Contacts = {},
			SupportTopById = {},
			SupportLowerById = {},
			SupportAnchorById = {},
			BodiesById = {},
			SupportsById = {}
		}
	end
}

local function isFiniteNumber(value)
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

local function isFiniteVector3(data) -- 3 equivalent calls inferred from this helper
	local v2

	if typeof(data) == "Vector3" then
		local x = data.X

		if typeof(x) == "number" and x == x and x > -1e999 then
			v2 = x < 1e999
		else
			v2 = false
		end

		if v2 then
			local y = data.Y

			if typeof(y) == "number" and y == y and y > -1e999 then
				v2 = y < 1e999
			else
				v2 = false
			end

			if v2 then
				local z = data.Z

				if typeof(z) == "number" and z == z and z > -1e999 then
					return z < 1e999
				else
					return false
				end
			end
		end
	else
		return false
	end

	return v2
end

local function traceFor(data, id: number) -- 7 equivalent calls inferred from this helper
	if data.TraceBodyId == id then
		return data.TraceRecorder
	end

	local traceRecordersById = data.TraceRecordersById

	if traceRecordersById == nil then
		return nil
	end

	return traceRecordersById[id]
end

local function traceBody(data, p: string, data2, p2: number?, p3: number?)
	local v2 = traceFor(data, data2.Id) -- inferred equivalent call

	if v2 == nil then
		return
	end

	DeterminismTrace.vector(
		v2,
		p,
		data2.Position,
		data2.WorldVelocity,
		p2,
		p3,
		nil,
		"ReplicatedStorage.MovementV2.Simulation.PlayerContacts",
		debug.info(2, "l")
	)
end

local function halfSize(item, config) -- 1 equivalent call inferred from this helper
	local v2

	if item.Stance == "Ducking" then
		v2 = config.PlayerSizeDucking
	else
		v2 = config.PlayerSizeStanding
	end

	return v2 * 0.5
end

function v.toWorldVelocity(vector: Vector3, p)
	if p.Kind == Enums.SupportKind.None then
		return vector
	end

	return vector + p.Velocity
end

function v.carryDelta(vector: Vector3, vector2: Vector3, p: number, p2: number)
	return vector / math.max(1, p2) - vector2 * p
end

function v.fromWorldVelocity(vector: Vector3, p)
	if p.Kind == Enums.SupportKind.None then
		return vector
	end

	return vector - p.Velocity
end

local function validateBodies(items)
	local id = 0
	local count = 0

	for _, item in items do
		assert(Serial.isUInt32(item.Id) and item.Id > 0, "player contact body ID must be a non-zero u32")
		assert(id < item.Id, "player contact bodies must be strictly sorted by ID")
		local startPosition = item.StartPosition
		assert(isFiniteVector3(startPosition), "invalid player contact start position") -- inferred equivalent call
		local position = item.Position
		assert(isFiniteVector3(position), "invalid player contact position") -- inferred equivalent call
		local worldVelocity = item.WorldVelocity
		assert(isFiniteVector3(worldVelocity), "invalid player contact velocity") -- inferred equivalent call
		assert(item.Stance == "Standing" or item.Stance == "Ducking", "invalid player contact stance")
		assert(typeof(item.OwnsMotion) == "boolean", "invalid player contact motion ownership")

		if item.OwnsMotion then
			count += 1
		end

		id = item.Id
	end

	assert(count <= 1, "player contact solve may write only one moving body")
end

local function axisComponent(vector: Vector3, p: number) -- 5 equivalent calls inferred from this helper
	if p == 1 then
		return vector.X
	elseif p == 2 then
		return vector.Y
	end

	return vector.Z
end

local function axisVector(p: number) -- 3 equivalent calls inferred from this helper
	if p == 1 then
		return createVector(1, 0, 0)
	elseif p == 2 then
		return createVector(0, 1, 0)
	end

	return createVector(0, 0, 1)
end

local function axisPriority(p: number) -- 2 equivalent calls inferred from this helper
	if p == 2 then
		return 1
	elseif p == 1 then
		return 2
	end

	return 3
end

local function sweptPair(p, p2, vector: Vector3, p3: number)
	if
		math.min(p.StartPosition.X, p.Position.X) > math.max(p2.StartPosition.X, p2.Position.X) + vector.X
		or math.min(p2.StartPosition.X, p2.Position.X) > math.max(p.StartPosition.X, p.Position.X) + vector.X
		or math.min(p.StartPosition.Y, p.Position.Y) > math.max(p2.StartPosition.Y, p2.Position.Y) + vector.Y
		or math.min(p2.StartPosition.Y, p2.Position.Y) > math.max(p.StartPosition.Y, p.Position.Y) + vector.Y
		or math.min(p.StartPosition.Z, p.Position.Z) > math.max(p2.StartPosition.Z, p2.Position.Z) + vector.Z
		or math.min(p2.StartPosition.Z, p2.Position.Z) > math.max(p.StartPosition.Z, p.Position.Z) + vector.Z
	then
		return nil, nil
	end

	local v2 = p.StartPosition - p2.StartPosition

	if math.abs(v2.X) < vector.X and math.abs(v2.Y) < vector.Y and math.abs(v2.Z) < vector.Z then
		return nil, nil
	end

	local v3 = p.Position - p.StartPosition - (p2.Position - p2.StartPosition)
	local v4 = 0
	local v5 = 0
	local v6 = 1
	local v7 = 0
	local v8 = 1
	local v9 = createVector(0, 0, 0)

	for i = 1, 3 do
		local v10 = axisComponent(v2, i) -- inferred equivalent call
		local v11 = axisComponent(v3, i) -- inferred equivalent call
		local v12 = axisComponent(vector, i) -- inferred equivalent call
		local v13 = math.max(v12 - p3, 0)

		if math.abs(v11) <= 1e-9 then
			if v10 < -v12 or v12 < v10 or (v10 <= -v13 or v13 <= v10) then
				return nil, nil
			end
		else
			local v14 = (-v12 - v10) / v11
			local v15 = (v12 - v10) / v11
			local v16 = math.min(v14, v15)
			local v17 = math.max(v14, v15)

			if v4 + 1e-9 < v16 or math.abs(v16 - v4) <= 1e-9 and (v5 == 0 or axisPriority(i) < axisPriority(v5)) then -- inferred equivalent call
				v4 = math.max(v16, 0)
				v9 = axisVector(i) * (v11 > 0 and -1 or 1) -- inferred equivalent call
				v5 = i
			end

			v6 = math.min(v6, v17)
			local v18 = (-v13 - v10) / v11
			local v19 = (v13 - v10) / v11
			v7 = math.max(v7, (math.min(v18, v19)))
			v8 = math.min(v8, (math.max(v18, v19)))

			if v6 < v4 or v8 <= v7 then
				return nil, nil
			end
		end
	end

	local v10 = math.max(v7, 0)
	local v11 = math.min(v8, 1)

	if v11 <= v10 or v11 <= 0 or v10 >= 1 or v4 >= 1 or v9 == createVector(0, 0, 0) then
		return nil, nil
	end

	return v4, v9
end

local function overlapContact(p, p2, vector: Vector3, contactEpsilon: number)
	local v2 = p.Position - p2.Position
	local v3 = vector.X - math.abs(v2.X)
	local v4 = vector.Y - math.abs(v2.Y)
	local v5 = vector.Z - math.abs(v2.Z)

	if v3 < -contactEpsilon or v4 < -contactEpsilon or v5 < -contactEpsilon then
		return nil, nil
	end

	local v6

	if v3 < v4 - contactEpsilon then
		v4 = v3
		v6 = 1
	else
		v6 = 2
	end

	if v5 < v4 - contactEpsilon then
		v4 = v5
		v6 = 3
	end

	if v6 == 2 and (v3 <= 0 or v5 <= 0) then
		if v3 <= v5 then
			v4 = v3
			v6 = 1
		else
			v4 = v5
			v6 = 3
		end
	end

	local v7 = axisComponent(v2, v6) -- inferred equivalent call
	local v8

	if v7 > 0 then
		v8 = 1
	elseif v7 < 0 then
		v8 = -1
	elseif p.Id < p2.Id then
		v8 = -1
	else
		v8 = 1
	end

	return axisVector(v6) * v8, v4 -- inferred equivalent call
end

local function accumulateMoverCorrection(p, data, vector: Vector3, p2: number, vectorsById, counts)
	if p2 <= 0 then
		return
	end

	if p.OwnsMotion then
		data = p
	elseif not data.OwnsMotion then
		data = nil
	end

	if data == nil then
		return
	end

	if data ~= p then
		vector = -vector
	end

	local v2 = math.max(-(data.Position - data.StartPosition):Dot(vector), 0)

	if v2 <= 1e-9 then
		return
	end

	local v3 = vector * math.min(p2, v2)
	local v4 = vectorsById[data.Id] or createVector(0, 0, 0)
	local id = data.Id
	local x

	if math.abs(v3.X) > math.abs(v4.X) then
		x = v3.X
	else
		x = v4.X
	end

	local y

	if math.abs(v3.Y) > math.abs(v4.Y) then
		y = v3.Y
	else
		y = v4.Y
	end

	local v5

	if math.abs(v3.Z) > math.abs(v4.Z) then
		v5 = v3.Z
	else
		v5 = v4.Z
	end

	vectorsById[id] = Vector3.new(x, y, v5)
	counts[data.Id] = (counts[data.Id] or 0) + 1
end

local function applyCorrections(items, deltas, counts, canOccupy, data, p: string)
	local count = 0

	for _, item in items do
		local v2 = deltas[item.Id]

		if v2 == nil then
			continue
		end

		local v3 = counts[item.Id] or 1
		local position = item.Position + v2
		local v4 = canOccupy == nil or canOccupy(item, position)
		assert(typeof(v4) == "boolean", "player contact CanOccupy must return a boolean")

		if v4 then
			item.Position = position
		else
			for i = 1, 3 do
				local v5 = axisComponent(v2, i) -- inferred equivalent call

				if v5 == 0 then
					continue
				end

				local position2 = item.Position + axisVector(i) * v5 -- inferred equivalent call
				local v6 = assert(canOccupy)(item, position2)
				assert(typeof(v6) == "boolean", "player contact CanOccupy must return a boolean")

				if v6 then
					item.Position = position2
				else
					count += 1
				end
			end
		end

		local v5 = v4 and 1 or 0
		local v6 = traceFor(data, item.Id) -- inferred equivalent call

		if v6 ~= nil then
			DeterminismTrace.vector(
				v6,
				p,
				item.Position,
				item.WorldVelocity,
				v5,
				v3,
				nil,
				"ReplicatedStorage.MovementV2.Simulation.PlayerContacts",
				debug.info(2, "l")
			)
		end
	end

	return count
end

local function removeInwardVelocity(state, state2, vector: Vector3, data)
	local dot = state.WorldVelocity:Dot(vector)

	if state.OwnsMotion and dot < 0 then
		state.WorldVelocity -= vector * dot
		local id = state2.Id
		local v2 = traceFor(data, state.Id) -- inferred equivalent call

		if v2 ~= nil then
			DeterminismTrace.vector(
				v2,
				"playerContacts.velocityClip",
				state.Position,
				state.WorldVelocity,
				dot,
				id,
				nil,
				"ReplicatedStorage.MovementV2.Simulation.PlayerContacts",
				debug.info(2, "l")
			)
		end
	end

	local dot2 = state2.WorldVelocity:Dot(vector)

	if state2.OwnsMotion and dot2 > 0 then
		state2.WorldVelocity -= vector * dot2
		local id = state.Id
		local v2 = traceFor(data, state2.Id) -- inferred equivalent call

		if v2 == nil then
			return
		else
			DeterminismTrace.vector(
				v2,
				"playerContacts.velocityClip",
				state2.Position,
				state2.WorldVelocity,
				dot2,
				id,
				nil,
				"ReplicatedStorage.MovementV2.Simulation.PlayerContacts",
				debug.info(2, "l")
			)
		end
	end
end

function v.solve(items, options)
	validateBodies(items)
	local v2 = options or {}
	local config = v2.Config or Config.Default
	local iterations = v2.Iterations or v.DefaultIterations
	local contactEpsilon = v2.ContactEpsilon or v.DefaultContactEpsilon
	local separationSkin = v2.SeparationSkin or v.DefaultSeparationSkin
	local scratch = v2.Scratch or v.newScratch()
	local v3 = iterations % 1 == 0 and iterations >= 1 and iterations <= 8
	assert(v3, "invalid player contact iteration count")
	local v4

	if typeof(contactEpsilon) == "number" and contactEpsilon == contactEpsilon and contactEpsilon > -1e999 then
		v4 = contactEpsilon < 1e999
	else
		v4 = false
	end

	if v4 then
		if contactEpsilon >= 0 then
			v4 = contactEpsilon <= 0.1
		else
			v4 = false
		end
	end

	assert(v4, "invalid player contact epsilon")
	local v5

	if typeof(separationSkin) == "number" and separationSkin == separationSkin and separationSkin > -1e999 then
		v5 = separationSkin < 1e999
	else
		v5 = false
	end

	if v5 then
		if separationSkin >= 0 then
			v5 = separationSkin <= 0.1
		else
			v5 = false
		end
	end

	assert(v5, "invalid player separation skin")
	local halfSizes = scratch.HalfSizes
	table.clear(halfSizes)
	local v6 = nil

	for _, item in items do
		local id = item.Id
		halfSizes[id] = halfSize(item, config) -- inferred equivalent call

		if item.OwnsMotion then
			v6 = item
		end

		local v7 = item.OwnsMotion and 1 or 0
		local v8 = traceFor(v2, item.Id) -- inferred equivalent call

		if v8 ~= nil then
			DeterminismTrace.vector(
				v8,
				"playerContacts.input",
				item.Position,
				item.WorldVelocity,
				v7,
				0,
				nil,
				"ReplicatedStorage.MovementV2.Simulation.PlayerContacts",
				debug.info(2, "l")
			)
		end
	end

	local pairA = scratch.PairA
	local pairB = scratch.PairB
	table.clear(pairA)
	table.clear(pairB)

	if v6 ~= nil then
		for _, item in items do
			if item == v6 then
				continue
			end

			local v7 = #pairA + 1
			local v8

			if item.Id < v6.Id then
				v8 = item
			else
				v8 = v6
			end

			pairA[v7] = v8

			if item.Id < v6.Id then
				item = v6
			end

			pairB[v7] = item
		end
	end

	local deltas = scratch.Deltas
	local counts = scratch.Counts
	table.clear(deltas)
	table.clear(counts)
	local count = 0

	for k, v7 in pairA do
		local v8 = pairB[k]
		local v9, v10 = sweptPair(v7, v8, halfSizes[v7.Id] + halfSizes[v8.Id], math.max(separationSkin, 1e-7))

		if not (v9 ~= nil and v10 ~= nil) then
			continue
		end

		local v11 = -(v7.Position - v7.StartPosition - (v8.Position - v8.StartPosition)):Dot(v10) * (1 - v9)

		if not (v11 > 0) then
			continue
		end

		accumulateMoverCorrection(v7, v8, v10, v11 + separationSkin, deltas, counts)
		count += 1
	end

	local unresolvedCount = 0 + applyCorrections(
		items,
		deltas,
		counts,
		v2.CanOccupy,
		v2,
		"playerContacts.sweptCorrection"
	)

	for _ = 1, iterations do
		table.clear(deltas)
		table.clear(counts)

		for k, v7 in pairA do
			local v8 = pairB[k]
			local v9, v10 = overlapContact(v7, v8, halfSizes[v7.Id] + halfSizes[v8.Id], contactEpsilon)

			if v9 ~= nil and v10 ~= nil and v10 > 0 then
				accumulateMoverCorrection(v7, v8, v9, v10 + separationSkin, deltas, counts)
			end
		end

		if next(deltas) == nil then
			break
		else
			unresolvedCount += applyCorrections(
				items,
				deltas,
				counts,
				v2.CanOccupy,
				v2,
				"playerContacts.overlapCorrection"
			)
		end
	end

	local collectContacts = v2.CollectContacts ~= false
	local contacts = scratch.Contacts
	local supportTopById = scratch.SupportTopById
	local supportLowerById = scratch.SupportLowerById
	local supportAnchorById = scratch.SupportAnchorById
	table.clear(contacts)
	table.clear(supportTopById)
	table.clear(supportLowerById)
	table.clear(supportAnchorById)

	for k, v7 in pairA do
		local v8 = pairB[k]
		local normal, v9 = overlapContact(v7, v8, halfSizes[v7.Id] + halfSizes[v8.Id], contactEpsilon)

		if not (normal ~= nil and v9 ~= nil) then
			continue
		end

		if collectContacts then
			contacts[#contacts + 1] = {
				A = v7.Id,
				B = v8.Id,
				Normal = normal,
				Penetration = math.max(v9, 0)
			}
		end

		removeInwardVelocity(v7, v8, normal, v2)

		if math.abs(normal.Y) <= 0.5 then
			continue
		end

		local v10

		if normal.Y > 0 then
			v10 = v7
		else
			v10 = v8
		end

		if normal.Y > 0 then
			v7 = v8
		end

		local v11 = v7.Position.Y + halfSizes[v7.Id].Y

		if
			v10.Position.Y - halfSizes[v10.Id].Y < v11 - contactEpsilon - separationSkin
			or v10.WorldVelocity.Y - v7.WorldVelocity.Y > config.GroundClearVelocity
		then
			continue
		end

		local v12 = supportTopById[v10.Id]

		if not (v12 == nil or v12 < v11 or v11 == v12 and v7.Id < (supportLowerById[v10.Id] or 1e999)) then
			continue
		end

		supportTopById[v10.Id] = v11
		supportLowerById[v10.Id] = v7.Id
		supportAnchorById[v10.Id] = v10.Position - v7.Position
	end

	local bodiesById = scratch.BodiesById
	table.clear(bodiesById)

	for _, item in items do
		bodiesById[item.Id] = item
	end

	local supportsById = scratch.SupportsById
	table.clear(supportsById)

	for k, sourceId in supportLowerById do
		local worldVelocity = assert(bodiesById[sourceId]).WorldVelocity
		supportsById[k] = {
			Kind = Enums.SupportKind.Player,
			SourceId = sourceId,
			Anchor = assert(supportAnchorById[k]),
			Velocity = Vector3.new(worldVelocity.X, 0, worldVelocity.Z)
		}
		local v7 = assert(bodiesById[k])
		local v8 = traceFor(v2, v7.Id) -- inferred equivalent call

		if v8 ~= nil then
			DeterminismTrace.vector(
				v8,
				"playerContacts.support",
				v7.Position,
				v7.WorldVelocity,
				0,
				sourceId,
				nil,
				"ReplicatedStorage.MovementV2.Simulation.PlayerContacts",
				debug.info(2, "l")
			)
		end
	end

	for _, item in items do
		local v7 = supportLowerById[item.Id] or 0
		local v8 = traceFor(v2, item.Id) -- inferred equivalent call

		if v8 ~= nil then
			DeterminismTrace.vector(
				v8,
				"playerContacts.final",
				item.Position,
				item.WorldVelocity,
				unresolvedCount,
				v7,
				nil,
				"ReplicatedStorage.MovementV2.Simulation.PlayerContacts",
				debug.info(2, "l")
			)
		end
	end

	return {
		Contacts = contacts,
		SupportsById = supportsById,
		UnresolvedCount = unresolvedCount,
		SweptContactCount = count
	}
end

return table.freeze(v)