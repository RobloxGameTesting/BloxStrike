--!native
local createVector = vector.create
local OcclusionMath = require(script.Parent.OcclusionMath)
local SilhouetteCoverage = require(script.Parent.SilhouetteCoverage)
require(script.Parent.StaticOcclusionRuntime)
local VisibilityCycleCodec = require(script.Parent.VisibilityCycleCodec)
local class = {}
class.__index = class
local PRIMITIVE_SIZE = VisibilityCycleCodec.PRIMITIVE_SIZE
local VECTOR_SIZE = VisibilityCycleCodec.VECTOR_SIZE
local RESULT_HIDDEN = VisibilityCycleCodec.RESULT_HIDDEN
local RESULT_VISIBLE = VisibilityCycleCodec.RESULT_VISIBLE
local RESULT_UNRESOLVED = VisibilityCycleCodec.RESULT_UNRESOLVED
local RESULT_SKIPPED = VisibilityCycleCodec.RESULT_SKIPPED
local PAIR_SKIP = VisibilityCycleCodec.PAIR_SKIP
local PAIR_PROOF = VisibilityCycleCodec.PAIR_PROOF
local FLAG_DYNAMIC_CERTIFICATES = VisibilityCycleCodec.FLAG_DYNAMIC_CERTIFICATES
local ACTOR_FLAG_EXTRAPOLATED = VisibilityCycleCodec.ACTOR_FLAG_EXTRAPOLATED
local ACTOR_FLAG_HULL_TAIL = VisibilityCycleCodec.ACTOR_FLAG_HULL_TAIL
local readVector = VisibilityCycleCodec.readVector

function class.new(static, buf: buffer?, value: number?, options)
	local v = options or {}
	return (setmetatable({
		Static = static,
		Primitives = buf,
		PrimitiveCount = buf == nil and 0 or buffer.len(buf) // PRIMITIVE_SIZE,
		NonBlockPrimitiveCount = value or 0,
		Cache = {},
		Cycle = 0,
		SearchBudgetPerCycle = v.SearchBudgetPerCycle or 12,
		SearchPlanes = v.SearchPlanes or 8,
		SearchRetryCycles = v.SearchRetryCycles or 30,
		SearchBudget = 0,
		FaceTestBudgetPerCycle = v.FaceTestBudgetPerCycle or 192,
		FaceRetryCycles = v.FaceRetryCycles or 8,
		FaceTestBudget = 0,
		OriginScratch = table.create(VisibilityCycleCodec.MAX_ORIGINS),
		PointScratch = table.create(VisibilityCycleCodec.MAX_TARGET_POINTS),
		BodyScratch = table.create(VisibilityCycleCodec.MAX_TARGET_POINTS * 2),
		SeedScratch = table.create(192),
		ProvenScratch = table.create(VisibilityCycleCodec.MAX_ORIGINS),
		Coverage = SilhouetteCoverage.new(),
		Stats = {
			PartialProofs = 0,
			Pairs = 0,
			Hidden = 0,
			Visible = 0,
			Unresolved = 0,
			Skipped = 0,
			CertificateHits = 0,
			CertificateSearches = 0,
			CertificateFound = 0,
			Segments = 0,
			BlockerHits = 0,
			BVHQueries = 0,
			BVHHits = 0,
			FallbackRays = 0,
			ClearReplays = 0,
			DynamicHits = 0,
			DynamicFound = 0,
			PoseReplays = 0
		},
		Stack = {}
	}, class))
end

local function primitiveIsBlock(primitives: buffer, blocker: number) -- 1 equivalent call inferred from this helper
	return buffer.readu8(primitives, (blocker - 1) * PRIMITIVE_SIZE) == VisibilityCycleCodec.PRIMITIVE_KIND_BLOCK
end

local function primitiveBlocksSegment(primitives: buffer, blocker: number, vector: Vector3, vector2: Vector3)
	local v = (blocker - 1) * PRIMITIVE_SIZE
	local v2 = vector.X - buffer.readf32(primitives, v + 4)
	local v3 = vector.Y - buffer.readf32(primitives, v + 8)
	local v4 = vector.Z - buffer.readf32(primitives, v + 12)
	local v5 = buffer.readf32(primitives, v + 16)
	local v6 = buffer.readf32(primitives, v + 20)
	local v7 = buffer.readf32(primitives, v + 24)
	local v8 = buffer.readf32(primitives, v + 28)
	local v9 = buffer.readf32(primitives, v + 32)
	local v10 = buffer.readf32(primitives, v + 36)
	local v11 = buffer.readf32(primitives, v + 40)
	local v12 = buffer.readf32(primitives, v + 44)
	local v13 = buffer.readf32(primitives, v + 48)
	local v14 = buffer.readf32(primitives, v + 52) + 0.02
	local v15 = buffer.readf32(primitives, v + 56) + 0.02
	local v16 = buffer.readf32(primitives, v + 60) + 0.02
	local v17 = v5 * v2 + v8 * v3 + v11 * v4
	local v18 = v6 * v2 + v9 * v3 + v12 * v4
	local v19 = v7 * v2 + v10 * v3 + v13 * v4
	local v20 = v5 * vector2.X + v8 * vector2.Y + v11 * vector2.Z
	local v21 = v6 * vector2.X + v9 * vector2.Y + v12 * vector2.Z
	local v22 = v7 * vector2.X + v10 * vector2.Y + v13 * vector2.Z
	local v23 = 0
	local v24 = 1

	if math.abs(v20) <= 1e-8 then
		if v14 < math.abs(v17) then
			return false
		end
	else
		local v25 = (-v14 - v17) / v20
		local v26 = (v14 - v17) / v20

		if v26 < v25 then
			v26, v25 = v25, v26
		end

		v23 = math.max(v23, v25)
		v24 = math.min(v24, v26)

		if v24 < v23 then
			return false
		end
	end

	if math.abs(v21) <= 1e-8 then
		if v15 < math.abs(v18) then
			return false
		end
	else
		local v25 = (-v15 - v18) / v21
		local v26 = (v15 - v18) / v21

		if v26 < v25 then
			v26, v25 = v25, v26
		end

		v23 = math.max(v23, v25)
		v24 = math.min(v24, v26)

		if v24 < v23 then
			return false
		end
	end

	if math.abs(v22) <= 1e-8 then
		return math.abs(v19) <= v16
	end

	local v25 = (-v16 - v19) / v22
	local v26 = (v16 - v19) / v22

	if v26 < v25 then
		v26, v25 = v25, v26
	end

	return math.max(v23, v25) <= math.min(v24, v26)
end

local function rememberRecent(list, p: number, p2: number, p3: number)
	for i = p, 1, -1 do
		if list[i] ~= p2 then
			continue
		end

		if i < p then
			table.remove(list, i)
			list[p] = p2
		end

		return p
	end

	if p3 <= p then
		table.remove(list, 1)
		list[p] = p2
		return p
	else
		list[p + 1] = p2
		return p + 1
	end
end

local function segmentBlocked(data, state, vector: Vector3, vector2: Vector3, callback)
	local stats = data.Stats
	stats.Segments += 1
	local vector3 = vector2 - vector
	local primitives = data.Primitives

	if primitives ~= nil then
		local blockers = state.Blockers

		for i = state.BlockerCount, 1, -1 do
			local blocker = blockers[i]

			if not primitiveBlocksSegment(primitives, blocker, vector, vector3) then
				continue
			end

			stats.BlockerHits += 1

			if i < state.BlockerCount then
				table.remove(blockers, i)
				blockers[state.BlockerCount] = blocker
			end

			return true, true
		end
	end

	local static = data.Static
	local v

	if static == nil then
		v = false
	else
		local triangles = state.Triangles

		for i = state.TriangleCount, 1, -1 do
			local triangle = triangles[i]

			if not static:TriangleBlocksSegment(triangle, vector, vector2) then
				continue
			end

			stats.BlockerHits += 1

			if i < state.TriangleCount then
				table.remove(triangles, i)
				triangles[state.TriangleCount] = triangle
			end

			return true, true
		end

		v = true
		stats.BVHQueries += 1
		local segmentBlocked2, v2, v3, v4 = static:SegmentBlocked(vector, vector2, nil, data.Deadline, state.NodeHint)

		if v4 == false then
			return false, false
		end

		if segmentBlocked2 then
			state.NodeHint = static.LastHitNode
			stats.BVHHits += 1

			if
				primitives == nil
				or v2 == nil
				or not (v2 >= 1 and v2 <= data.PrimitiveCount)
				or buffer.readu8(primitives, (v2 - 1) * PRIMITIVE_SIZE) ~= VisibilityCycleCodec.PRIMITIVE_KIND_BLOCK
			then
				if v3 ~= nil then
					state.TriangleCount = rememberRecent(state.Triangles, state.TriangleCount, v3, 8)
				end
			else
				state.BlockerCount = rememberRecent(state.Blockers, state.BlockerCount, v2, 8)
			end

			return true, true
		end
	end

	if callback == nil or not (data.NonBlockPrimitiveCount > 0) and v then
		return false, v
	end

	stats.FallbackRays += 1
	local v2 = callback(vector, vector2)

	if v2 == nil then
		return false, v
	end

	return v2, true
end

local function pairCache(state, actorId: number, actorId2: number)
	local v = state.Cache[actorId]

	if v == nil then
		v = {}
		state.Cache[actorId] = v
	end

	local v2 = v[actorId2]

	if v2 == nil then
		v2 = {
			SampleHints = {},
			OriginProofRetry = {},
			OriginProofs = {},
			ProofCandidates = {},
			Blockers = {},
			BlockerCount = 0,
			Triangles = {},
			TriangleCount = 0,
			SearchAfterCycle = 0,
			FaceSearchAfterCycle = 0,
			FaceFirst = false,
			HiddenAt = -1e999,
			CoverageTriangles = {}
		}
		v[actorId2] = v2
	end

	return v2
end

local function pruneCache(state, p)
	for k, v in state.Cache do
		if p[k] then
			for k2 in v do
				if not p[k2] then
					v[k2] = nil
				end
			end
		else
			state.Cache[k] = nil
		end
	end
end

local function primitiveFace(primitives: buffer, p: number, p2: number, p3: number)
	local v = (p - 1) * PRIMITIVE_SIZE
	local vector = Vector3.new(
		buffer.readf32(primitives, v + 4),
		buffer.readf32(primitives, v + 8),
		(buffer.readf32(primitives, v + 12))
	)
	local vector2 = Vector3.new(
		buffer.readf32(primitives, v + 16),
		buffer.readf32(primitives, v + 28),
		(buffer.readf32(primitives, v + 40))
	)
	local vector3 = Vector3.new(
		buffer.readf32(primitives, v + 20),
		buffer.readf32(primitives, v + 32),
		(buffer.readf32(primitives, v + 44))
	)
	local vector4 = Vector3.new(
		buffer.readf32(primitives, v + 24),
		buffer.readf32(primitives, v + 36),
		(buffer.readf32(primitives, v + 48))
	)
	local v2 = buffer.readf32(primitives, v + 52)
	local v3 = buffer.readf32(primitives, v + 56)
	local v4 = buffer.readf32(primitives, v + 60)

	if p2 == 0 then
		return vector + vector2 * (p3 * v2), vector3, vector4, vector2 * p3, v3, v4
	elseif p2 == 1 then
		return vector + vector3 * (p3 * v3), vector4, vector2, vector3 * p3, v4, v2
	end

	return vector + vector4 * (p3 * v4), vector2, vector3, vector4 * p3, v2, v3
end

local function coverageBody(state, data)
	local targetPoints = data.TargetPoints
	local targetPointCount = data.TargetPointCount
	local vector = nil

	if bit32.band(data.Flags, ACTOR_FLAG_HULL_TAIL) ~= 0 then
		local v = bit32.band(data.Flags, ACTOR_FLAG_EXTRAPOLATED) ~= 0
		local v2 = v and 16 or 8

		if v2 < targetPointCount then
			targetPointCount -= v2

			if v then
				vector = targetPoints[targetPointCount + 9] - targetPoints[targetPointCount + 1]
			end
		end
	end

	local bodyScratch = state.BodyScratch
	table.clear(bodyScratch)

	for i = 1, targetPointCount do
		bodyScratch[i] = targetPoints[i]
	end

	if vector ~= nil then
		for i = 1, targetPointCount do
			bodyScratch[targetPointCount + i] = targetPoints[i] + vector
		end
	end

	return bodyScratch, #bodyScratch
end

local function beginSeeds(state, state2) -- 2 equivalent calls inferred from this helper
	local seedScratch = state.SeedScratch
	table.clear(seedScratch)

	for i = 1, state2.TriangleCount do
		seedScratch[i] = state2.Triangles[i]
	end

	return seedScratch
end

local function appendSeeds(list, items)
	for _, item in items do
		if #list >= 192 then
			break
		else
			list[#list + 1] = item
		end
	end
end

local function coverageBlocks(object, p, vector: Vector3, vector2: Vector3, p2: number)
	if p == nil then
		return 0
	end

	return object:FirstBlockingTriangle(p, p2, vector, vector2)
end

local function proofRange(data)
	local targetPointCount = data.TargetPointCount

	if bit32.band(data.Flags, ACTOR_FLAG_HULL_TAIL) == 0 then
		return data.TargetPointsOffset, targetPointCount
	end

	local selected = bit32.band(data.Flags, ACTOR_FLAG_EXTRAPOLATED) == 0 and 8 or 16

	if selected < targetPointCount then
		return data.TargetPointsOffset + (targetPointCount - selected) * VECTOR_SIZE, selected
	end

	return data.TargetPointsOffset, targetPointCount
end

local function faceCovers(data, buf: buffer, p, data2, p2: number, p3: number, p4: number)
	local primitives = data.Primitives
	local static = data.Static

	if primitives == nil or static == nil or p2 < 1 or data.PrimitiveCount < p2 then
		return false
	end

	local vector, v, v2, v3, v4, v5 = primitiveFace(primitives, p2, p3, p4)
	local targetPointCount = data2.TargetPointCount
	local targetPointsOffset

	if bit32.band(data2.Flags, ACTOR_FLAG_HULL_TAIL) == 0 then
		targetPointsOffset = data2.TargetPointsOffset
	else
		local v6 = bit32.band(data2.Flags, ACTOR_FLAG_EXTRAPOLATED) == 0 and 8 or 16

		if v6 < targetPointCount then
			targetPointsOffset = data2.TargetPointsOffset + (targetPointCount - v6) * VECTOR_SIZE
			targetPointCount = v6
		else
			targetPointsOffset = data2.TargetPointsOffset
		end
	end

	return static:ProveRectangleBuffer(
		buf,
		vector,
		v,
		v2,
		v3,
		v4,
		v5,
		p.OriginsOffset,
		p.OriginCount,
		targetPointsOffset,
		targetPointCount
	)
end

local function cachedFaceCovers(p, buf: buffer, p2, p3, data) -- 2 equivalent calls inferred from this helper
	return faceCovers(p, buf, p2, p3, data.FacePrimitive, data.FaceAxis, data.FaceSign)
end

local function searchBlockFace(state, buf: buffer, data, data2, state2, p: number?, faceAxis: number?, faceSign: number?)
	local primitives = state.Primitives

	if primitives == nil then
		return false
	end

	local v = readVector(buf, data.OriginsOffset)
	local blockers = state2.Blockers
	local count = 0

	for i = state2.BlockerCount, 1, -1 do
		local blocker = blockers[i]

		if not primitiveIsBlock(primitives, blocker) then -- inferred equivalent call
			continue
		end

		local v2 = (blocker - 1) * PRIMITIVE_SIZE
		local v3 = v.X - buffer.readf32(primitives, v2 + 4)
		local v4 = v.Y - buffer.readf32(primitives, v2 + 8)
		local v5 = v.Z - buffer.readf32(primitives, v2 + 12)

		for j = 0, 2 do
			local v6 = v2 + 16 + j * 4
			local v7 = buffer.readf32(primitives, v6) * v3 + buffer.readf32(primitives, v6 + 12) * v4 + buffer.readf32(primitives, v6 + 24) * v5
			local v8 = buffer.readf32(primitives, v2 + 52 + j * 4)
			local faceSign2 = v8 < v7 and 1 or v7 < -v8 and -1 or 0

			if not (faceSign2 ~= 0 and (blocker ~= p or j ~= faceAxis or faceSign2 ~= faceSign)) then
				continue
			end

			if count >= 12 or state.FaceTestBudget <= 0 then
				return false
			end

			count += 1
			state.FaceTestBudget -= 1

			if not faceCovers(state, buf, data, data2, blocker, j, faceSign2) then
				continue
			end

			state2.FacePrimitive = blocker
			state2.FaceAxis = j
			state2.FaceSign = faceSign2
			return true
		end
	end

	return false
end

local function samplePacketBlocks(sampleHint, origin: Vector3, targetPoint: Vector3)
	local vector = targetPoint - origin

	if vector:Dot(vector) <= 1e-7 then
		return false
	end

	local vector2 = sampleHint[2]
	local vector3 = sampleHint[3]
	local cross = vector:Cross(vector3)
	local dot = vector2:Dot(cross)

	if math.abs(dot) <= 1e-7 then
		return false
	end

	local v = 1 / dot
	local vector4 = origin - sampleHint[1]
	local v2 = vector4:Dot(cross) * v

	if v2 < -1e-7 or v2 > 1.0000001 then
		return false
	end

	local cross2 = vector4:Cross(vector2)
	local v3 = vector:Dot(cross2) * v

	if v3 < -1e-7 or v2 + v3 > 1.0000001 then
		return false
	end

	local v4 = vector3:Dot(cross2) * v
	return v4 >= 1e-7 and v4 <= 0.9999999
end

local function evaluatePair(state, buf: buffer, captureHeader, data, data2, p: number, state2, callback, flag: boolean, flag2: boolean, hiddenViewerPose: string, hiddenTargetPose: string, p2: number)
	local count = 0
	local static

	if flag then
		static = state.Static
	end

	if data.OriginCount == 0 or data2.TargetPointCount == 0 then
		return RESULT_UNRESOLVED
	end

	local proofs

	if static ~= nil then
		proofs = static.Proofs
	end

	local originBounds = data.OriginBounds
	local targetBounds = data2.TargetBounds
	local proofPlane = state2.ProofPlane
	local preferredPlane = state2.PreferredPlane
	local facePrimitive = state2.FacePrimitive
	local v = nil
	local v2

	if flag2 then
		if static == nil then
			v2 = false
		else
			v2 = facePrimitive ~= nil
		end
	else
		v2 = flag2
	end

	local v3

	if p == PAIR_PROOF and static ~= nil then
		v3 = preferredPlane ~= nil
	else
		v3 = false
	end

	if v2 and state2.FaceFirst then
		if cachedFaceCovers(state, buf, data, data2, state2) then -- inferred equivalent call
			state.Stats.CertificateHits += 1
			state.Stats.DynamicHits += 1
			return RESULT_HIDDEN
		else
			v = facePrimitive
			v2 = false
		end
	end

	if v3 then
		local targetPointCount = data2.TargetPointCount
		local targetPointsOffset

		if bit32.band(data2.Flags, ACTOR_FLAG_HULL_TAIL) == 0 then
			targetPointsOffset = data2.TargetPointsOffset
		else
			local v4 = bit32.band(data2.Flags, ACTOR_FLAG_EXTRAPOLATED) == 0 and 8 or 16

			if v4 < targetPointCount then
				targetPointsOffset = data2.TargetPointsOffset + (targetPointCount - v4) * VECTOR_SIZE
				targetPointCount = v4
			else
				targetPointsOffset = data2.TargetPointsOffset
			end
		end

		if static:ProvePlaneBuffer(
			buf,
			preferredPlane,
			data.OriginsOffset,
			data.OriginCount,
			targetPointsOffset,
			targetPointCount,
			nil
		) then
			state.Stats.CertificateHits += 1
			state2.FaceFirst = false
			return RESULT_HIDDEN
		end
	end

	if v2 then
		if cachedFaceCovers(state, buf, data, data2, state2) then -- inferred equivalent call
			state.Stats.CertificateHits += 1
			state.Stats.DynamicHits += 1
			state2.FaceFirst = true
			return RESULT_HIDDEN
		else
			v = facePrimitive
		end
	end

	if not flag then
		return RESULT_UNRESOLVED
	end

	if
		state2.HiddenViewerPose == hiddenViewerPose
		and state2.HiddenTargetPose == hiddenTargetPose
		and captureHeader.CaptureTime - state2.HiddenAt <= 0.25
	then
		state.Stats.PoseReplays += 1
		return RESULT_HIDDEN
	else
		state2.HiddenViewerPose = nil

		if
			static == nil
			or state.PrimitiveCount ~= 0
			or state2.ClearOrigin ~= nil
			or not (captureHeader.CaptureTime - state2.HiddenAt <= 0.5)
		then
			local clearOrigin = state2.ClearOrigin
			local clearPoint = state2.ClearPoint

			if clearOrigin ~= nil and clearPoint ~= nil and clearOrigin < data.OriginCount then
				local clearOriginWorld2 = readVector(buf, data.OriginsOffset + clearOrigin * VECTOR_SIZE)
				local position

				if clearPoint < 0 then
					position = data2.Position
				elseif clearPoint < data2.TargetPointCount then
					position = readVector(buf, data2.TargetPointsOffset + clearPoint * VECTOR_SIZE)
				end

				if position ~= nil then
					local flag3, v4 = segmentBlocked(state, state2, clearOriginWorld2, position, callback)

					if not v4 then
						return RESULT_UNRESOLVED
					end

					if not flag3 then
						state.Stats.ClearReplays += 1
						state2.ClearOriginWorld = clearOriginWorld2
						state2.ClearPointWorld = position
						state2.ClearTargetRoot = data2.Position
						return RESULT_VISIBLE
					end
				end

				local clearOriginWorld = state2.ClearOriginWorld
				local clearPointWorld = state2.ClearPointWorld
				local clearTargetRoot = state2.ClearTargetRoot

				if
					clearOriginWorld ~= nil
					and clearPointWorld ~= nil
					and clearTargetRoot ~= nil
					and (clearOriginWorld2 - clearOriginWorld).Magnitude <= 0.5
					and (data2.Position - clearTargetRoot).Magnitude <= 0.35
				then
					local flag3, v4 = segmentBlocked(state, state2, clearOriginWorld, clearPointWorld, callback)

					if not v4 then
						return RESULT_UNRESOLVED
					end

					if not flag3 then
						state.Stats.ClearReplays += 1
						return RESULT_VISIBLE
					end
				end

				state2.ClearOrigin = nil
				state2.ClearPoint = nil
				state2.ClearOriginWorld = nil
				state2.ClearPointWorld = nil
				state2.ClearTargetRoot = nil
			end

			if state.Cycle < (state2.CoverageRetryAfter or 0) then
				return RESULT_VISIBLE
			end

			if
				proofs == nil
				or originBounds == nil
				or targetBounds == nil
				or proofPlane == nil
				or not proofs:Covers(proofPlane, originBounds, targetBounds, p2)
			then
				local origin = data.Origins[1]
				local flag3, v4 = segmentBlocked(state, state2, origin, data2.Position, callback)

				if not v4 then
					return RESULT_UNRESOLVED
				end

				if flag3 then
					if
						proofs ~= nil
						and originBounds ~= nil
						and targetBounds ~= nil
						and state.Cycle >= (state2.ProofSearchAfter or 0)
					then
						state2.ProofSearchAfter = state.Cycle + 4
						state.Stats.CertificateSearches += 1
						table.clear(state2.ProofCandidates)
						local search = proofs:Search(
							originBounds,
							targetBounds,
							state2.Triangles,
							state2.TriangleCount,
							proofPlane,
							p2,
							state2.ProofCandidates
						)

						if search ~= nil then
							state2.ProofPlane = search
							state.Stats.CertificateFound += 1
							return RESULT_HIDDEN
						end
					end

					local originCount = data.OriginCount
					local targetPointCount = data2.TargetPointCount
					local origins = data.Origins
					local targetPoints = data2.TargetPoints
					local provenScratch = state.ProvenScratch
					table.clear(provenScratch)
					local count2 = 0

					for i = 0, originCount - 1 do
						if p2 <= os.clock() then
							state.Stats.Segments += count
							state.Stats.BlockerHits += count
							return RESULT_UNRESOLVED
						else
							local origin2 = origins[i + 1]

							if
								proofs ~= nil
								and targetBounds ~= nil
								and state.Cycle >= (state2.OriginProofRetry[i + 1] or 0)
							then
								local coversOrigin = proofs:CoversOrigin(
									origin2,
									targetBounds,
									state2.ProofCandidates,
									state2.OriginProofs[i + 1],
									p2
								)

								if coversOrigin == nil then
									state2.OriginProofRetry[i + 1] = state.Cycle + 8
								else
									state2.OriginProofs[i + 1] = coversOrigin
									state.Stats.PartialProofs += 1
									provenScratch[i + 1] = true
									continue
								end
							end

							for j = 0, targetPointCount - 1 do
								if count2 >= 32 then
									if p2 <= os.clock() then
										state.Stats.Segments += count
										state.Stats.BlockerHits += count
										return RESULT_UNRESOLVED
									else
										count2 = 0
									end
								end

								count2 += 1
								local targetPoint = targetPoints[j + 1]
								local v5 = i * VisibilityCycleCodec.MAX_TARGET_POINTS + j + 1
								local sampleHint = state2.SampleHints[v5]
								local v6, v7

								if
									sampleHint
									and static
									and state.PrimitiveCount == 0
									and samplePacketBlocks(sampleHint, origin2, targetPoint)
								then
									count += 1
									v6 = true
									v7 = true
								else
									v7, v6 = segmentBlocked(state, state2, origin2, targetPoint, callback)

									if
										v7
										and static ~= nil
										and state.PrimitiveCount == 0
										and state2.TriangleCount > 0
									then
										state2.SampleHints[v5] = static:SamplePacket(state2.Triangles[state2.TriangleCount])
									else
										state2.SampleHints[v5] = nil
									end
								end

								if v6 then
									if not v7 then
										state2.ClearOrigin = i
										state2.ClearPoint = j
										state2.ClearOriginWorld = origin2
										state2.ClearPointWorld = targetPoint
										state2.ClearTargetRoot = data2.Position
										state.Stats.Segments += count
										state.Stats.BlockerHits += count
										return RESULT_VISIBLE
									end
								else
									state.Stats.Segments += count
									state.Stats.BlockerHits += count
									return RESULT_UNRESOLVED
								end
							end
						end
					end

					if static ~= nil and state.PrimitiveCount == 0 then
						local v5, v6 = coverageBody(state, data2)
						local coverage = state.Coverage
						local seedScratch = beginSeeds(state, state2) -- inferred equivalent call

						for i = 0, originCount - 1 do
							if provenScratch[i + 1] then
								continue
							end

							local originCovered, v7 = coverage:OriginCovered(
								static,
								origins[i + 1],
								v5,
								v6,
								state2.CoverageTriangles[i + 1],
								p2,
								seedScratch
							)

							if originCovered == true then
								state2.CoverageTriangles[i + 1] = v7

								for _, v8 in v7 do
									if #seedScratch >= 192 then
										break
									else
										seedScratch[#seedScratch + 1] = v8
									end
								end
							else
								state2.CoverageTriangles[i + 1] = nil
								state.Stats.Segments += count
								state.Stats.BlockerHits += count

								if originCovered == nil and p2 <= os.clock() then
									return RESULT_UNRESOLVED
								end

								state2.CoverageRetryAfter = state.Cycle + 4
								return RESULT_VISIBLE
							end
						end
					end

					if
						p == PAIR_PROOF
						and static ~= nil
						and static.Data.certificateCount > 0
						and state.SearchBudget > 0
						and state.Cycle >= state2.SearchAfterCycle
						and data.CellCount > 0
						and data2.CellCount > 0
					then
						state.SearchBudget -= 1
						state.Stats.CertificateSearches += 1
						state2.SearchAfterCycle = state.Cycle + state.SearchRetryCycles
						local targetPointCount2 = data2.TargetPointCount
						local targetPointsOffset

						if bit32.band(data2.Flags, ACTOR_FLAG_HULL_TAIL) == 0 then
							targetPointsOffset = data2.TargetPointsOffset
						else
							local v5 = bit32.band(data2.Flags, ACTOR_FLAG_EXTRAPOLATED) == 0 and 8 or 16

							if v5 < targetPointCount2 then
								targetPointsOffset = data2.TargetPointsOffset + (targetPointCount2 - v5) * VECTOR_SIZE
								targetPointCount2 = v5
							else
								targetPointsOffset = data2.TargetPointsOffset
							end
						end

						local proveProjectedOccludedForCellBuffer, preferredPlane2 = static:ProveProjectedOccludedForCellBuffer(
							buf,
							data.CellsOffset,
							data.CellCount,
							data2.CellsOffset,
							data2.CellCount,
							data.OriginsOffset,
							data.OriginCount,
							targetPointsOffset,
							targetPointCount2,
							preferredPlane,
							nil,
							state.SearchPlanes
						)

						if proveProjectedOccludedForCellBuffer and preferredPlane2 ~= nil then
							state2.PreferredPlane = preferredPlane2
							state.Stats.CertificateFound += 1
							state.Stats.Segments += count
							state.Stats.BlockerHits += count
							return RESULT_HIDDEN
						end
					end

					if
						flag2
						and static ~= nil
						and state.FaceTestBudget > 0
						and state.Cycle >= state2.FaceSearchAfterCycle
					then
						if searchBlockFace(state, buf, data, data2, state2, v, state2.FaceAxis, state2.FaceSign) then
							state.Stats.DynamicFound += 1
							state2.FaceFirst = true
						else
							state2.FaceSearchAfterCycle = state.Cycle + state.FaceRetryCycles
						end
					end

					state2.HiddenViewerPose = hiddenViewerPose
					state2.HiddenTargetPose = hiddenTargetPose
					state2.HiddenAt = captureHeader.CaptureTime
					state.Stats.Segments += count
					state.Stats.BlockerHits += count
					return RESULT_HIDDEN
				else
					state2.ClearOrigin = 0
					state2.ClearPoint = -1
					state2.ClearOriginWorld = origin
					state2.ClearPointWorld = data2.Position
					state2.ClearTargetRoot = data2.Position
					return RESULT_VISIBLE
				end
			else
				state.Stats.CertificateHits += 1
				return RESULT_HIDDEN
			end
		else
			local origins = data.Origins
			local v4, v5 = coverageBody(state, data2)
			local seedScratch = beginSeeds(state, state2) -- inferred equivalent call

			for i = 1, data.OriginCount do
				local originCovered, v6 = state.Coverage:OriginCovered(
					static,
					origins[i],
					v4,
					v5,
					state2.CoverageTriangles[i],
					p2,
					seedScratch
				)

				if originCovered == true then
					state2.CoverageTriangles[i] = v6

					for _, v7 in v6 do
						if #seedScratch >= 192 then
							break
						else
							seedScratch[#seedScratch + 1] = v7
						end
					end
				else
					state2.CoverageTriangles[i] = nil
					state2.HiddenAt = -1e999

					if originCovered == nil and p2 <= os.clock() then
						return RESULT_UNRESOLVED
					end

					state2.CoverageRetryAfter = state.Cycle + 4
					return RESULT_VISIBLE
				end
			end

			local targetPoints = data2.TargetPoints

			for i = 1, data.OriginCount do
				local coverageTriangle = state2.CoverageTriangles[i]
				local v6 = 1

				for j = 1, data2.TargetPointCount do
					local origin = origins[i]
					local targetPoint = targetPoints[j]
					local v7 = coverageTriangle == nil and 0
						or static:FirstBlockingTriangle(coverageTriangle, v6, origin, targetPoint)

					if v7 == 0 then
						local flag3, v8 = segmentBlocked(state, state2, origins[i], targetPoints[j], callback)

						if not v8 then
							return RESULT_UNRESOLVED
						end

						if not flag3 then
							state2.HiddenAt = -1e999
							return RESULT_VISIBLE
						end
					else
						v6 = v7
					end
				end
			end

			state2.HiddenViewerPose = hiddenViewerPose
			state2.HiddenTargetPose = hiddenTargetPose
			state2.HiddenAt = captureHeader.CaptureTime
			return RESULT_HIDDEN
		end
	end
end

function class.FaceCertified(p, buf: buffer, p2: number, p3: number)
	local v = p.Cache[p2]
	local v2

	if v ~= nil then
		v2 = v[p3]
	end

	if v2 == nil or v2.FacePrimitive == nil then
		return false
	end

	local v3 = nil
	local v4 = nil

	for i = 1, VisibilityCycleCodec.readCaptureHeader(buf).ActorCount do
		local actor = VisibilityCycleCodec.readActor(buf, i)

		if actor.ActorId == p2 then
			v3 = actor
		elseif actor.ActorId == p3 then
			v4 = actor
		end
	end

	if v3 == nil or v4 == nil then
		return false
	end

	return cachedFaceCovers(p, buf, v3, v4, v2)
end

function class:Solve(buf: buffer, p: number, p2: number, callback, p3: number?)
	local now = os.clock()
	local captureHeader = VisibilityCycleCodec.readCaptureHeader(buf)
	local actorCount = captureHeader.ActorCount
	local deadline = now + math.max(captureHeader.CycleBudgetSeconds, 0.0005)
	self.Deadline = deadline
	local result = VisibilityCycleCodec.createResult(
		actorCount,
		p,
		captureHeader.Sequence,
		captureHeader.CaptureTime,
		captureHeader.Generation,
		0
	)
	local stats = self.Stats

	for k in stats do
		stats[k] = 0
	end

	self.Cycle += 1
	self.SearchBudget = self.SearchBudgetPerCycle
	self.FaceTestBudget = self.FaceTestBudgetPerCycle
	local actors = table.create(actorCount)
	local v = table.create(actorCount)
	local v2 = {}

	for i = 1, actorCount do
		local actor = VisibilityCycleCodec.readActor(buf, i)

		local function decodePoints(p4: number, p5: number, vector: Vector3?)
			local result2 = table.create(p5)
			local v3 = vector or createVector(1e999, 1e999, 1e999)
			local v4 = vector or createVector(-1e999, -1e999, -1e999)
			local v5 = true

			for j = 0, p5 - 1 do
				local v6 = readVector(buf, p4 + j * VECTOR_SIZE)
				result2[j + 1] = v6

				if not OcclusionMath.isFiniteVector(v6) then
					v5 = false
				end

				v3 = v3:Min(v6)
				v4 = v4:Max(v6)
			end

			if v5 and OcclusionMath.isFiniteVector(v3) and OcclusionMath.isFiniteVector(v4) then
				return result2, { v3.X, v3.Y, v3.Z, v4.X, v4.Y, v4.Z }
			end

			return result2, nil
		end

		local origins, originBounds = decodePoints(actor.OriginsOffset, actor.OriginCount, nil)
		actor.Origins = origins
		actor.OriginBounds = originBounds
		local targetPoints, targetBounds = decodePoints(
			actor.TargetPointsOffset,
			actor.TargetPointCount,
			actor.Position
		)
		actor.TargetPoints = targetPoints
		actor.TargetBounds = targetBounds
		actors[i] = actor
		v2[actor.ActorId] = true
		v[i] = buffer.readstring(buf, actor.OriginsOffset, actor.OriginCount * VECTOR_SIZE) .. buffer.readstring(
			buf,
			actor.TargetPointsOffset,
			actor.TargetPointCount * VECTOR_SIZE
		)
	end

	if self.Cycle % 64 == 0 then
		pruneCache(self, v2)
	end

	local v3 = bit32.band(captureHeader.Flags, VisibilityCycleCodec.FLAG_STATIC) ~= 0
	local v4 = bit32.band(captureHeader.Flags, FLAG_DYNAMIC_CERTIFICATES) ~= 0
	local pairKindOffset = captureHeader.PairKindOffset
	local resultRowsOffset = VisibilityCycleCodec.resultRowsOffset()
	local resultMatrixOffset = VisibilityCycleCodec.resultMatrixOffset(actorCount)
	local v5 = not (actorCount > 0) and 0 or captureHeader.Sequence % actorCount
	local v6 = false

	for i = 0, actorCount - 1 do
		local v7 = (i + v5) % actorCount + 1
		local v8 = actors[v7]

		if v8.ActorId % p2 ~= p - 1 then
			continue
		end

		buffer.writeu8(result, resultRowsOffset + v7 - 1, 1)
		local v9 = resultMatrixOffset + (v7 - 1) * actorCount

		for j = 1, actorCount do
			local v10 = buffer.readu8(buf, pairKindOffset + (v7 - 1) * actorCount + (j - 1))

			if v10 == PAIR_SKIP or j == v7 then
				stats.Skipped += 1
				buffer.writeu8(result, v9 + j - 1, RESULT_SKIPPED)
			else
				stats.Pairs += 1

				if v6 or deadline <= os.clock() then
					stats.Unresolved += 1
					buffer.writeu8(result, v9 + j - 1, RESULT_UNRESOLVED)
					v6 = true
				else
					local v11 = actors[j]
					local v12 = evaluatePair(
						self,
						buf,
						captureHeader,
						v8,
						v11,
						v10,
						pairCache(self, v8.ActorId, v11.ActorId),
						callback,
						v3,
						v4,
						v[v7],
						v[j],
						deadline
					)

					if v12 == RESULT_HIDDEN then
						stats.Hidden += 1
					elseif v12 == RESULT_VISIBLE then
						stats.Visible += 1
					else
						stats.Unresolved += 1
						v6 = deadline <= os.clock() or v6
					end

					buffer.writeu8(result, v9 + j - 1, v12)
				end
			end
		end
	end

	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_PAIRS, stats.Pairs)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_HIDDEN, stats.Hidden)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_VISIBLE, stats.Visible)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_UNRESOLVED, stats.Unresolved)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_SKIPPED, stats.Skipped)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_CERTIFICATE_HITS, stats.CertificateHits)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_CLEAR_REPLAYS, stats.ClearReplays)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_DYNAMIC_HITS, stats.DynamicHits)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_DYNAMIC_FOUND, stats.DynamicFound)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_POSE_REPLAYS, stats.PoseReplays)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_CERTIFICATE_SEARCHES, stats.CertificateSearches)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_CERTIFICATE_FOUND, stats.CertificateFound)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_SEGMENTS, stats.Segments)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_BLOCKER_HITS, stats.BlockerHits)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_BVH_QUERIES, stats.BVHQueries)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_BVH_HITS, stats.BVHHits)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_FALLBACK_RAYS, stats.FallbackRays)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_DEADLINE, v6 and 1 or 0)
	VisibilityCycleCodec.writeStat(result, VisibilityCycleCodec.STAT_MICROSECONDS, ((p3 or os.clock()) - now) * 1000000)
	return result
end

return table.freeze(class)