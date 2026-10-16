--!native
local StaticOcclusionCodec = require(script.Parent.StaticOcclusionCodec)
local class = {}
class.__index = class
local NODE_SIZE = StaticOcclusionCodec.NODE_SIZE
local LEAF_SIZE = StaticOcclusionCodec.LEAF_SIZE
local INDEXED_VERSION = StaticOcclusionCodec.INDEXED_VERSION
local VERTEX_SIZE = StaticOcclusionCodec.VERTEX_SIZE
local PLANE_SIZE = StaticOcclusionCodec.PLANE_SIZE
local RECT_SIZE = StaticOcclusionCodec.RECT_SIZE
local CERTIFICATE_SIZE = StaticOcclusionCodec.CERTIFICATE_SIZE
local CANDIDATE_SIZE = StaticOcclusionCodec.CANDIDATE_SIZE

local function pairKey(p: number, p2: number) -- 3 equivalent calls inferred from this helper
	local v = math.min(p, p2)
	local v2 = math.max(p, p2)
	return (bit32.bor(bit32.lshift(v, 16), v2))
end

local function readVector(buf: buffer, offset: number) -- 23 equivalent calls inferred from this helper
	return (Vector3.new(buffer.readf32(buf, offset), buffer.readf32(buf, offset + 4), (buffer.readf32(buf, offset + 8))))
end

local function readTriangle(data, p: number)
	local buf = data.buffer
	local v = data.triangleOffset + (p - 1) * data.triangleSize

	if data.version == INDEXED_VERSION then
		local v2 = buffer.readu32(buf, v)
		local v3 = buffer.readu32(buf, v + 4)
		local v4 = buffer.readu32(buf, v + 8)
		return
			readVector(buf, data.vertexOffset + (v2 - 1) * VERTEX_SIZE), -- inferred equivalent call
			readVector(buf, data.vertexOffset + (v3 - 1) * VERTEX_SIZE), -- inferred equivalent call
			readVector(buf, data.vertexOffset + (v4 - 1) * VERTEX_SIZE), -- inferred equivalent call
			0
	else
		return readVector(buf, v), readVector(buf, v + 12), readVector(buf, v + 24), (buffer.readu32(buf, v + 36)) -- inferred equivalent call
	end
end

local function segmentIntersectsBounds(vector: Vector3, p: number, p2: number, p3: number, vector2: Vector3, vector3: Vector3, p4: number)
	local v = 0

	if p == 0 then
		if vector.X < vector2.X or vector.X > vector3.X then
			return false
		end
	else
		local v2 = (vector2.X - vector.X) * p
		local v3 = (vector3.X - vector.X) * p
		v = math.max(v, (math.min(v2, v3)))
		p4 = math.min(p4, (math.max(v2, v3)))

		if p4 < v then
			return false
		end
	end

	if p2 == 0 then
		if vector.Y < vector2.Y or vector.Y > vector3.Y then
			return false
		end
	else
		local v2 = (vector2.Y - vector.Y) * p2
		local v3 = (vector3.Y - vector.Y) * p2
		v = math.max(v, (math.min(v2, v3)))
		p4 = math.min(p4, (math.max(v2, v3)))

		if p4 < v then
			return false
		end
	end

	if p3 == 0 then
		if vector.Z < vector2.Z or vector.Z > vector3.Z then
			return false
		end
	else
		local v2 = (vector2.Z - vector.Z) * p3
		local v3 = (vector3.Z - vector.Z) * p3

		if math.max(v, (math.min(v2, v3))) > math.min(p4, (math.max(v2, v3))) then
			return false
		end
	end

	return true
end

local function segmentIntersectsBox(x: number, y: number, z: number, p: number, p2: number, p3: number, buf: buffer, offset: number, p4: number)
	local v = 0
	local v2 = buffer.readf32(buf, offset)
	local v3 = buffer.readf32(buf, offset + 12)

	if p == 0 then
		if x < v2 or v3 < x then
			return false
		end
	else
		local v4 = (v2 - x) * p
		local v5 = (v3 - x) * p
		v = math.max(v, (math.min(v4, v5)))
		p4 = math.min(p4, (math.max(v4, v5)))

		if p4 < v then
			return false
		end
	end

	local v4 = buffer.readf32(buf, offset + 4)
	local v5 = buffer.readf32(buf, offset + 16)

	if p2 == 0 then
		if y < v4 or v5 < y then
			return false
		end
	else
		local v6 = (v4 - y) * p2
		local v7 = (v5 - y) * p2
		v = math.max(v, (math.min(v6, v7)))
		p4 = math.min(p4, (math.max(v6, v7)))

		if p4 < v then
			return false
		end
	end

	local v6 = buffer.readf32(buf, offset + 8)
	local v7 = buffer.readf32(buf, offset + 20)

	if p3 == 0 then
		if z < v6 or v7 < z then
			return false
		end
	else
		local v8 = (v6 - z) * p3
		local v9 = (v7 - z) * p3

		if math.max(v, (math.min(v8, v9))) > math.min(p4, (math.max(v8, v9))) then
			return false
		end
	end

	return true
end

local function segmentEdgesFraction(vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3, vector5: Vector3, value: number?)
	local cross = vector2:Cross(vector5)
	local dot = vector4:Dot(cross)

	if math.abs(dot) <= 1e-7 then
		return nil
	end

	local v = 1 / dot
	local vector6 = vector - vector3
	local v2 = vector6:Dot(cross) * v
	local v3 = value or -1e-7

	if v2 < v3 or 1 - v3 < v2 then
		return nil
	end

	local cross2 = vector6:Cross(vector4)
	local v4 = vector2:Dot(cross2) * v

	if v4 < v3 then
		return nil
	end

	local v5 = v2 + v4

	if 1 - v3 < v5 then
		return nil
	end

	local v6 = vector5:Dot(cross2) * v

	if v6 >= 1e-7 and v6 <= 0.9999999 then
		return v6
	end

	return nil
end

local function segmentTriangleFraction(vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3, vector5: Vector3) -- 1 equivalent call inferred from this helper
	return (segmentEdgesFraction(vector, vector2, vector3, vector4 - vector3, vector5 - vector3))
end

function class.new(p: string, p2: string?, callback)
	local decoded = StaticOcclusionCodec.decode(p, callback)

	if p2 ~= nil and decoded.fingerprint ~= p2 then
		error("PVBVH1 fingerprint does not match the expected visibility geometry")
	end

	return (setmetatable({
		Data = decoded,
		SamplePacketIds = {},
		SamplePackets = {},
		Stack = table.create((math.max(decoded.nodeCount, 8))),
		TriangleCacheIds = table.create(4096, 0),
		TriangleCacheA = table.create(4096),
		TriangleCacheFirstEdge = table.create(4096),
		TriangleCacheSecondEdge = table.create(4096),
		PlaneMarks = buffer.create(math.max(decoded.planeCount, 1) * 4),
		PlaneMarkToken = 0,
		CandidatePlanes = table.create(decoded.planeCount),
		ChildReferences = table.create(8),
		ChildDepths = table.create(8),
		PlaneX = table.create(8),
		PlaneY = table.create(8),
		PlaneZ = table.create(8),
		ViewerProjectionScratch = buffer.create(48960),
		TargetProjectionScratch = buffer.create(48960),
		VolumePairMarks = buffer.create(65025),
		BatchProjectionScratch = buffer.create(48960),
		BatchVolumePairMarks = buffer.create(65025)
	}, class))
end

function class.GetFingerprint(p)
	return p.Data.fingerprint
end

function class:InstallProofs(p: string, callback)
	self.Proofs = nil
	local success, result = pcall(function()
		local ExactOcclusionProofs = require(script.Parent.ExactOcclusionProofs)
		return ExactOcclusionProofs.new(p, self.Data, callback)
	end)

	if not success then
		return false, (tostring(result))
	end

	self.Proofs = result
	return true, nil
end

local function querySegment(state, vector: Vector3, vector2: Vector3, state2, flag: boolean, p: number?, p2: number?)
	local vector3 = vector2 - vector

	if vector3:Dot(vector3) <= 1e-7 then
		return false, nil, nil, nil
	end

	local v = math.abs(vector3.X) <= 1e-7 and 0 or 1 / vector3.X
	local v2 = math.abs(vector3.Y) <= 1e-7 and 0 or 1 / vector3.Y
	local v3 = math.abs(vector3.Z) <= 1e-7 and 0 or 1 / vector3.Z
	local data = state.Data
	local buf = data.buffer
	local stack = state.Stack
	stack[1] = p2 or data.rootNode
	local x = vector.X
	local y = vector.Y
	local z = vector.Z
	local nodeOffset = data.nodeOffset
	local leafOffset = data.leafOffset
	local v4 = 1
	local count = 0
	local v5 = 1
	local v6 = nil
	local v7 = nil

	while v4 > 0 do
		if p and count % 32 == 0 and p <= os.clock() then
			return false, nil, nil, nil, false
		end

		count += 1
		local lastHitNode = stack[v4]
		v4 -= 1

		if state2 then
			state2.nodes += 1
		end

		local v8 = nodeOffset + (lastHitNode - 1) * NODE_SIZE

		for i = 1, 8 do
			local v9 = buffer.readi32(buf, v8 + 192 + (i - 1) * 4)

			if not (v9 ~= 0 and segmentIntersectsBox(x, y, z, v, v2, v3, buf, v8 + (i - 1) * 24, v5)) then
				continue
			end

			if v9 > 0 then
				v4 += 1
				stack[v4] = v9
			else
				local v10 = leafOffset + (-v9 - 1) * LEAF_SIZE
				local v11 = buffer.readu32(buf, v10)

				for j = v11, v11 + buffer.readu16(buf, v10 + 4) - 1 do
					if state2 then
						state2.triangles += 1
					end

					local vector4, v12, v13, v14 = readTriangle(data, j)
					local v15 = segmentTriangleFraction(vector, vector3, vector4, v12, v13) -- inferred equivalent call

					if not (v15 ~= nil and v15 < v5) then
						continue
					end

					if not flag then
						state.LastHitNode = lastHitNode
						return true, v14, j, v15
					end

					v7 = v14
					v6 = j
					v5 = v15
				end
			end
		end
	end

	local v8 = v6 ~= nil

	if v6 == nil then
		return v8, v7, nil, nil
	end

	return v8, v7, v6, v5
end

function class.SegmentBlocked(p, vector: Vector3, vector2: Vector3, p2, p3: number?, p4: number?)
	if p4 and p4 >= 1 and p4 <= p.Data.nodeCount and p4 % 1 == 0 and p4 ~= p.Data.rootNode then
		local flag, v, v2, _, v3 = querySegment(p, vector, vector2, p2, false, p3, p4)

		if v3 == false then
			return false, nil, nil, false
		end

		if flag then
			return true, v, v2, true
		end
	end

	local flag, v, v2, _, v3 = querySegment(p, vector, vector2, p2, false, p3)
	return flag, v, v2, v3 ~= false
end

local function boxMaxAlong(vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3)
	local x

	if vector.X >= 0 then
		x = vector4.X
	else
		x = vector3.X
	end

	local y

	if vector.Y >= 0 then
		y = vector4.Y
	else
		y = vector3.Y
	end

	local v

	if vector.Z >= 0 then
		v = vector4.Z
	else
		v = vector3.Z
	end

	return (x - vector2.X) * vector.X + (y - vector2.Y) * vector.Y + (v - vector2.Z) * vector.Z
end

function class.VisitFrustumTriangles(data, vector: Vector3, list, vector2: Vector3, p: number, p2: number, callback, p3: number, p4: number?)
	local data2 = data.Data
	local buf = data2.buffer
	local stack = data.Stack
	local childReferences = data.ChildReferences
	local childDepths = data.ChildDepths
	stack[1] = data2.rootNode
	local vector3 = -vector2
	local x = vector.X
	local y = vector.Y
	local z = vector.Z
	local x2 = vector2.X
	local y2 = vector2.Y
	local z2 = vector2.Z
	local x3 = vector3.X
	local y3 = vector3.Y
	local z3 = vector3.Z
	local count = #list
	local planeX = data.PlaneX
	local planeY = data.PlaneY
	local planeZ = data.PlaneZ
	local v = 1
	local count2 = 0
	local total = 0

	for i = 1, count do
		local vector4 = list[i]
		local x4 = vector4.X
		local y4 = vector4.Y
		local z4 = vector4.Z
		planeX[i] = x4
		planeY[i] = y4
		planeZ[i] = z4
	end

	local leafOffset = data2.leafOffset
	local nodeOffset = data2.nodeOffset

	while v > 0 do
		if p4 and count2 % 32 == 0 and p4 <= os.clock() then
			return false, false
		end

		count2 += 1
		local v2 = stack[v]
		v -= 1

		if v2 < 0 then
			local v3 = leafOffset + (-v2 - 1) * LEAF_SIZE
			local v4 = buffer.readu32(buf, v3)
			local v5 = buffer.readu16(buf, v3 + 4)
			total += v5

			if p3 < total then
				return false, false
			end

			for i = v4, v4 + v5 - 1 do
				if callback(i) then
					return true, true
				end
			end
		else
			local v3 = nodeOffset + (v2 - 1) * NODE_SIZE
			local count3 = 0

			for i = 1, 8 do
				local v4 = buffer.readi32(buf, v3 + 192 + (i - 1) * 4)

				if v4 == 0 then
					continue
				end

				local v5 = v3 + (i - 1) * 24
				local v6 = buffer.readf32(buf, v5)
				local v7 = buffer.readf32(buf, v5 + 4)
				local v8 = buffer.readf32(buf, v5 + 8)
				local v9 = buffer.readf32(buf, v5 + 12)
				local v10 = buffer.readf32(buf, v5 + 16)
				local v11 = buffer.readf32(buf, v5 + 20)
				local v12

				if x3 >= 0 then
					v12 = v9
				else
					v12 = v6
				end

				local v13 = (v12 - x) * x3
				local v14

				if y3 >= 0 then
					v14 = v10
				else
					v14 = v7
				end

				local v15 = v13 + (v14 - y) * y3
				local v16

				if z3 >= 0 then
					v16 = v11
				else
					v16 = v8
				end

				local v17 = -(v15 + (v16 - z) * z3)

				if p2 < v17 then
					continue
				end

				local v18

				if x2 >= 0 then
					v18 = v9
				else
					v18 = v6
				end

				local v19 = (v18 - x) * x2
				local v20

				if y2 >= 0 then
					v20 = v10
				else
					v20 = v7
				end

				local v21 = v19 + (v20 - y) * y2
				local v22

				if z2 >= 0 then
					v22 = v11
				else
					v22 = v8
				end

				if v21 + (v22 - z) * z2 < p then
					continue
				end

				local v23 = false

				for j = 1, count do
					local v24 = planeX[j]
					local v25 = planeY[j]
					local v26 = planeZ[j]
					local v27

					if v24 >= 0 then
						v27 = v9
					else
						v27 = v6
					end

					local v28 = (v27 - x) * v24
					local v29

					if v25 >= 0 then
						v29 = v10
					else
						v29 = v7
					end

					local v30 = v28 + (v29 - y) * v25
					local v31

					if v26 >= 0 then
						v31 = v11
					else
						v31 = v8
					end

					if not (v30 + (v31 - z) * v26 < 0) then
						continue
					end

					v23 = true
					break
				end

				if v23 then
					continue
				end

				count3 += 1
				local v24 = count3

				while v24 > 1 and childDepths[v24 - 1] < v17 do
					childDepths[v24] = childDepths[v24 - 1]
					childReferences[v24] = childReferences[v24 - 1]
					v24 -= 1
				end

				childDepths[v24] = v17
				childReferences[v24] = v4
			end

			for i = 1, count3 do
				v += 1
				stack[v] = childReferences[i]
			end
		end
	end

	return false, true
end

function class.TriangleVertices(data, p: number)
	local v = (p - 1) % 4096 + 1

	if data.TriangleCacheIds[v] ~= p then
		local vector, v2, v3 = readTriangle(data.Data, p)
		data.TriangleCacheIds[v] = p
		data.TriangleCacheA[v] = vector
		data.TriangleCacheFirstEdge[v] = v2 - vector
		data.TriangleCacheSecondEdge[v] = v3 - vector
	end

	local vector = data.TriangleCacheA[v]
	local vector2 = data.TriangleCacheFirstEdge[v]
	local vector3 = data.TriangleCacheSecondEdge[v]
	return vector, vector + vector2, vector + vector3
end

function class.NearestSegmentHit(p, vector: Vector3, vector2: Vector3)
	local _, _, _, v = querySegment(p, vector, vector2, nil, true)
	return v
end

function class.TriangleBlocksSegment(data, p: number, vector: Vector3, vector2: Vector3)
	local data2 = data.Data

	if p < 1 or data2.triangleCount < p then
		return false
	end

	local vector3 = vector2 - vector

	if vector3:Dot(vector3) <= 1e-7 then
		return false
	end

	local v = (p - 1) % 4096 + 1

	if data.TriangleCacheIds[v] ~= p then
		local vector4, v2, v3 = readTriangle(data2, p)
		data.TriangleCacheIds[v] = p
		data.TriangleCacheA[v] = vector4
		data.TriangleCacheFirstEdge[v] = v2 - vector4
		data.TriangleCacheSecondEdge[v] = v3 - vector4
	end

	return segmentEdgesFraction(
		vector,
		vector3,
		data.TriangleCacheA[v],
		data.TriangleCacheFirstEdge[v],
		data.TriangleCacheSecondEdge[v]
	) ~= nil
end

function class.FirstBlockingTriangle(data, list, p: number, vector: Vector3, vector2: Vector3)
	local count = #list

	if count == 0 then
		return 0
	end

	local v = (p < 1 or count < p) and 1 or p
	local vector3 = vector2 - vector

	if vector3:Dot(vector3) <= 1e-7 then
		return 0
	end

	local data2 = data.Data
	local triangleCount = data2.triangleCount
	local triangleCacheIds = data.TriangleCacheIds
	local triangleCacheA = data.TriangleCacheA
	local triangleCacheFirstEdge = data.TriangleCacheFirstEdge
	local triangleCacheSecondEdge = data.TriangleCacheSecondEdge

	for _ = 1, count do
		local v2 = list[v]

		if v2 >= 1 and v2 <= triangleCount then
			local v3 = (v2 - 1) % 4096 + 1

			if triangleCacheIds[v3] ~= v2 then
				local vector4, v4, v5 = readTriangle(data2, v2)
				triangleCacheIds[v3] = v2
				triangleCacheA[v3] = vector4
				triangleCacheFirstEdge[v3] = v4 - vector4
				triangleCacheSecondEdge[v3] = v5 - vector4
			end

			if segmentEdgesFraction(
				vector,
				vector3,
				triangleCacheA[v3],
				triangleCacheFirstEdge[v3],
				triangleCacheSecondEdge[v3]
			) ~= nil then
				return v
			end
		end

		if v == count then
			v = 1
		else
			v += 1
		end
	end

	return 0
end

function class.ProveTriangleBuffer(p, buf: buffer, p2: number, p3: number, p4: number, p5: number, p6: number)
	if p4 == 0 or p6 < 4 or p2 < 1 or p.Data.triangleCount < p2 then
		return false
	end

	local vector, v, v2 = readTriangle(p.Data, p2)
	local v3 = v - vector
	local v4 = v2 - vector

	for i = 0, p4 - 1 do
		local vector2 = readVector(buf, p3 + i * 12) -- inferred equivalent call

		for j = 0, p6 - 1 do
			if segmentEdgesFraction(vector2, readVector(buf, p5 + j * 12) - vector2, vector, v3, v4, 0.00001) == nil then -- inferred equivalent call
				return false
			end
		end
	end

	return true
end

local function rectangleCoverage(p, p2: number, p3: number, p4: number, p5: number, p6: number, p7: number, p8)
	local v = p4 - 0.01
	local v2 = p5 + 0.01
	local v3 = p6 - 0.01
	local v4 = p7 + 0.01
	local buf = p.buffer

	if p3 == 1 then
		if p8 then
			p8.rectangles += 1
		end

		local v5 = p.rectangleOffset + (p2 - 1) * RECT_SIZE
		local v6 = buffer.readf32(buf, v5) + 0.01
		local v7 = buffer.readf32(buf, v5 + 4) - 0.01
		local v8 = buffer.readf32(buf, v5 + 8) + 0.01
		local v9 = buffer.readf32(buf, v5 + 12) - 0.01
		local v10

		if v6 <= v and v2 <= v7 and v8 <= v3 then
			v10 = v4 <= v9
		else
			v10 = false
		end

		if v10 then
			return v10, 1
		end

		return v10, 0
	else
		local v5 = {}
		local v6 = { v, v2 }

		for i = p2, p2 + p3 - 1 do
			if p8 then
				p8.rectangles += 1
			end

			local v7 = p.rectangleOffset + (i - 1) * RECT_SIZE
			local minimumU = buffer.readf32(buf, v7) + 0.01
			local maximumU = buffer.readf32(buf, v7 + 4) - 0.01
			local minimumV = buffer.readf32(buf, v7 + 8) + 0.01
			local maximumV = buffer.readf32(buf, v7 + 12) - 0.01

			if not (minimumU <= v2 and v <= maximumU and minimumV <= v4 and v3 <= maximumV) then
				continue
			end

			v5[#v5 + 1] = {
				minimumU = minimumU,
				maximumU = maximumU,
				minimumV = minimumV,
				maximumV = maximumV,
				primitive = buffer.readu32(buf, v7 + 16)
			}
			v6[#v6 + 1] = math.max(minimumU, v)
			v6[#v6 + 1] = math.min(maximumU, v2)
		end

		if #v5 == 0 then
			return false, 0
		end

		table.sort(v6)
		local v7 = {}

		for i = 1, #v6 - 1 do
			local v8 = v6[i]
			local v9 = v6[i + 1]

			if v9 - v8 <= 1e-7 then
				continue
			end

			local v10 = (v8 + v9) * 0.5
			local v11 = {}

			for _, v12 in v5 do
				if v12.minimumU <= v10 and v10 <= v12.maximumU then
					v11[#v11 + 1] = v12
				end
			end

			table.sort(v11, function(a, b)
				if a.minimumV == b.minimumV then
					return a.maximumV > b.maximumV
				end

				return a.minimumV < b.minimumV
			end)
			local maximumV = v3

			for _, v12 in v11 do
				local minimumV = v12.minimumV

				if maximumV + 1e-7 < minimumV then
					return false, 0
				end

				if maximumV < v12.maximumV then
					maximumV = v12.maximumV
					v7[v12.primitive] = true
				end

				if v4 <= maximumV then
					break
				end
			end

			if maximumV < v4 then
				return false, 0
			end
		end

		local count = 0

		for _ in v7 do
			count += 1
		end

		return true, count
	end
end

local function planeCovers(data, p: number, items, items2, p2)
	local buf = data.buffer
	local v = data.planeOffset + (p - 1) * PLANE_SIZE
	local vector = readVector(buf, v) -- inferred equivalent call
	local vector2 = readVector(buf, v + 12) -- inferred equivalent call
	local vector3 = readVector(buf, v + 24) -- inferred equivalent call
	local vector4 = readVector(buf, v + 36) -- inferred equivalent call
	local v2 = buffer.readu32(buf, v + 48)
	local v3 = buffer.readu16(buf, v + 52)
	local v4 = 0

	for _, item in items2 do
		local dot = (item - vector):Dot(vector4)

		if math.abs(dot) <= 0.01 then
			return false, 0
		end

		local v5 = dot > 0 and 1 or -1

		if v4 == 0 then
			v4 = v5
		elseif v5 ~= v4 then
			return false, 0
		end
	end

	if v4 == 0 then
		return false, 0
	end

	local v5 = 1e999
	local v6 = -1e999
	local v7 = 1e999
	local v8 = -1e999

	for _, item in items do
		local dot = (item - vector):Dot(vector4)

		if math.abs(dot) <= 0.01 or (dot > 0 and 1 or -1) == v4 then
			return false, 0
		end

		for _, item2 in items2 do
			local v9 = (item2 - vector):Dot(vector4) - dot

			if math.abs(v9) <= 1e-7 then
				return false, 0
			end

			local v10 = -dot / v9

			if v10 <= 0 or v10 >= 1 then
				return false, 0
			end

			local vector5 = item:Lerp(item2, v10) - vector
			local dot2 = vector5:Dot(vector2)
			local dot3 = vector5:Dot(vector3)
			v5 = math.min(v5, dot2)
			v6 = math.max(v6, dot2)
			v7 = math.min(v7, dot3)
			v8 = math.max(v8, dot3)
		end
	end

	return rectangleCoverage(data, v2, v3, v5, v6, v7, v8, p2)
end

local function projectFootprintBuffer(buf: buffer, vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3, p: number, p2: number, p3: number, p4: number, buf2: buffer, buf3: buffer)
	if p2 > 255 or p4 > 255 then
		return false, 0, 0, 0, 0
	end

	local v = 0

	for i = 0, p4 - 1 do
		local vector5 = readVector(buf, p3 + i * 12) - vector -- inferred equivalent call
		local dot = vector5:Dot(vector4)

		if math.abs(dot) <= 0.01 then
			return false, 0, 0, 0, 0
		end

		local v2 = dot > 0 and 1 or -1

		if v == 0 then
			v = v2
		elseif v2 ~= v then
			return false, 0, 0, 0, 0
		end

		local v3 = i * 24
		buffer.writef64(buf3, v3, dot)
		buffer.writef64(buf3, v3 + 8, (vector5:Dot(vector2)))
		buffer.writef64(buf3, v3 + 16, (vector5:Dot(vector3)))
	end

	if v == 0 then
		return false, 0, 0, 0, 0
	end

	for i = 0, p2 - 1 do
		local vector5 = readVector(buf, p + i * 12) - vector -- inferred equivalent call
		local dot = vector5:Dot(vector4)

		if math.abs(dot) <= 0.01 or (dot > 0 and 1 or -1) == v then
			return false, 0, 0, 0, 0
		end

		local v2 = i * 24
		buffer.writef64(buf2, v2, dot)
		buffer.writef64(buf2, v2 + 8, (vector5:Dot(vector2)))
		buffer.writef64(buf2, v2 + 16, (vector5:Dot(vector3)))
	end

	local v2 = 1e999
	local v3 = -1e999
	local v4 = 1e999
	local v5 = -1e999

	for i = 0, p2 - 1 do
		local v6 = i * 24
		local v7 = buffer.readf64(buf2, v6)
		local v8 = buffer.readf64(buf2, v6 + 8)
		local v9 = buffer.readf64(buf2, v6 + 16)

		for j = 0, p4 - 1 do
			local v10 = j * 24
			local v11 = buffer.readf64(buf3, v10) - v7

			if math.abs(v11) <= 1e-7 then
				return false, 0, 0, 0, 0
			end

			local v12 = -v7 / v11

			if v12 <= 0 or v12 >= 1 then
				return false, 0, 0, 0, 0
			end

			local v13 = buffer.readf64(buf3, v10 + 8)
			local v14 = buffer.readf64(buf3, v10 + 16)
			local v15 = v8 + (v13 - v8) * v12
			local v16 = v9 + (v14 - v9) * v12
			v2 = math.min(v2, v15)
			v3 = math.max(v3, v15)
			v4 = math.min(v4, v16)
			v5 = math.max(v5, v16)
		end
	end

	return true, v2, v3, v4, v5
end

local function planeCoversBuffer(data, p: number, buf: buffer, p2: number, p3: number, p4: number, p5: number, viewerProjectionScratch: buffer, targetProjectionScratch: buffer, p6)
	local buf2 = data.buffer
	local v = data.planeOffset + (p - 1) * PLANE_SIZE
	local vector = readVector(buf2, v) -- inferred equivalent call
	local vector2 = readVector(buf2, v + 12) -- inferred equivalent call
	local vector3 = readVector(buf2, v + 24) -- inferred equivalent call
	local vector4 = readVector(buf2, v + 36) -- inferred equivalent call
	local v2 = buffer.readu32(buf2, v + 48)
	local v3 = buffer.readu16(buf2, v + 52)
	local flag, v4, v5, v6, v7 = projectFootprintBuffer(
		buf,
		vector,
		vector2,
		vector3,
		vector4,
		p2,
		p3,
		p4,
		p5,
		viewerProjectionScratch,
		targetProjectionScratch
	)

	if flag then
		return rectangleCoverage(data, v2, v3, v4, v5, v6, v7, p6)
	end

	return false, 0
end

local function projectBufferPoints(data, p: number, buf: buffer, p2: number, p3: number, buf2: buffer, value: number?)
	if p3 > 2040 then
		return false
	end

	local buf3 = data.buffer
	local v = data.planeOffset + (p - 1) * PLANE_SIZE
	local vector = readVector(buf3, v) -- inferred equivalent call
	local vector2 = readVector(buf3, v + 12) -- inferred equivalent call
	local vector3 = readVector(buf3, v + 24) -- inferred equivalent call
	local vector4 = readVector(buf3, v + 36) -- inferred equivalent call
	local v2 = value or 0

	for i = 0, p3 - 1 do
		local vector5 = readVector(buf, p2 + i * 12) - vector -- inferred equivalent call
		local v3 = (v2 + i) * 24
		buffer.writef64(buf2, v3, (vector5:Dot(vector4)))
		buffer.writef64(buf2, v3 + 8, (vector5:Dot(vector2)))
		buffer.writef64(buf2, v3 + 16, (vector5:Dot(vector3)))
	end

	return true
end

local function projectedVolumePairCoverage(data, p: number, buf: buffer, p2: number, p3: number, buf2: buffer, p4: number, p5: number, p6)
	local v = 0

	for i = p4, p4 + p5 - 1 do
		local v2 = buffer.readf64(buf2, i * 24)

		if math.abs(v2) <= 0.01 then
			return false, 0
		end

		local v3 = v2 > 0 and 1 or -1

		if v == 0 then
			v = v3
		elseif v3 ~= v then
			return false, 0
		end
	end

	if v == 0 then
		return false, 0
	end

	for i = p2, p2 + p3 - 1 do
		local v2 = buffer.readf64(buf, i * 24)

		if math.abs(v2) <= 0.01 or (v2 > 0 and 1 or -1) == v then
			return false, 0
		end
	end

	local buf3 = data.buffer
	local v2 = data.planeOffset + (p - 1) * PLANE_SIZE
	local v3 = buffer.readu32(buf3, v2 + 48)
	local v4 = buffer.readu16(buf3, v2 + 52)

	if v4 == 1 then
		local v5 = data.rectangleOffset + (v3 - 1) * RECT_SIZE
		local v6 = buffer.readf32(buf3, v5) + 0.02
		local v7 = buffer.readf32(buf3, v5 + 4) - 0.02
		local v8 = buffer.readf32(buf3, v5 + 8) + 0.02
		local v9 = buffer.readf32(buf3, v5 + 12) - 0.02
		local v10 = p2 * 24
		local v11 = p4 * 24
		local v12 = buffer.readf64(buf, v10)
		local v13 = buffer.readf64(buf2, v11) - v12

		if math.abs(v13) <= 1e-7 then
			return false, 0
		end

		local v14 = -v12 / v13

		if v14 <= 0 or v14 >= 1 then
			return false, 0
		end

		local v15 = buffer.readf64(buf, v10 + 8)
		local v16 = buffer.readf64(buf, v10 + 16)
		local v17 = v15 + (buffer.readf64(buf2, v11 + 8) - v15) * v14
		local v18 = v16 + (buffer.readf64(buf2, v11 + 16) - v16) * v14

		if v17 < v6 or v7 < v17 or v18 < v8 or v9 < v18 then
			return false, 0
		end

		local v19 = 1e999
		local v20 = -1e999
		local v21 = 1e999
		local v22 = -1e999

		for i = p2, p2 + p3 - 1 do
			local v23 = i * 24
			local v24 = buffer.readf64(buf, v23 + 8)
			local v25 = buffer.readf64(buf, v23 + 16)
			v19 = math.min(v19, v24)
			v20 = math.max(v20, v24)
			v21 = math.min(v21, v25)
			v22 = math.max(v22, v25)
		end

		for i = p4, p4 + p5 - 1 do
			local v23 = i * 24
			local v24 = buffer.readf64(buf2, v23 + 8)
			local v25 = buffer.readf64(buf2, v23 + 16)
			v19 = math.min(v19, v24)
			v20 = math.max(v20, v24)
			v21 = math.min(v21, v25)
			v22 = math.max(v22, v25)
		end

		if v6 <= v19 and v20 <= v7 and v8 <= v21 and v22 <= v9 then
			if p6 then
				p6.rectangles += 1
			end

			return true, 1
		end
	end

	local v5 = 1e999
	local v6 = -1e999
	local v7 = 1e999
	local v8 = -1e999

	for i = p2, p2 + p3 - 1 do
		local v9 = i * 24
		local v10 = buffer.readf64(buf, v9)
		local v11 = buffer.readf64(buf, v9 + 8)
		local v12 = buffer.readf64(buf, v9 + 16)

		for j = p4, p4 + p5 - 1 do
			local v13 = j * 24
			local v14 = buffer.readf64(buf2, v13) - v10

			if math.abs(v14) <= 1e-7 then
				return false, 0
			end

			local v15 = -v10 / v14

			if v15 <= 0 or v15 >= 1 then
				return false, 0
			end

			local v16 = buffer.readf64(buf2, v13 + 8)
			local v17 = buffer.readf64(buf2, v13 + 16)
			local v18 = v11 + (v16 - v11) * v15
			local v19 = v12 + (v17 - v12) * v15
			v5 = math.min(v5, v18)
			v6 = math.max(v6, v18)
			v7 = math.min(v7, v19)
			v8 = math.max(v8, v19)
		end
	end

	return rectangleCoverage(data, v3, v4, v5, v6, v7, v8, p6)
end

local function nextPlaneMark(state) -- 3 equivalent calls inferred from this helper
	local planeMarkToken = state.PlaneMarkToken + 1

	if planeMarkToken >= 4294967295 then
		buffer.fill(state.PlaneMarks, 0, 0)
		planeMarkToken = 1
	end

	state.PlaneMarkToken = planeMarkToken
	return planeMarkToken
end

local function markPlane(p, p2: number, value: number) -- 6 equivalent calls inferred from this helper
	local v = (p2 - 1) * 4

	if buffer.readu32(p.PlaneMarks, v) == value then
		return false
	end

	buffer.writeu32(p.PlaneMarks, v, value)
	return true
end

function class.ProveProjectedOccluded(p, list, list2, p2: number?, p3)
	if #list == 0 or #list2 < 4 then
		return false, nil, 0
	end

	local data = p.Data

	if p2 ~= nil and p2 >= 1 and p2 <= data.planeCount then
		if p3 then
			p3.planes += 1
		end

		local flag, v = planeCovers(data, p2, list, list2, p3)

		if flag then
			return true, p2, v
		end
	end

	for i = 1, data.planeCount do
		if i == p2 then
			continue
		end

		if p3 then
			p3.planes += 1
		end

		local flag, v = planeCovers(data, i, list, list2, p3)

		if flag then
			return true, i, v
		end
	end

	return false, nil, 0
end

local function findCertificate(data, p: number)
	local buf = data.buffer
	local certificateCount = data.certificateCount
	local v = 1

	while v <= certificateCount do
		local v2 = math.floor((v + certificateCount) * 0.5)
		local v3 = data.certificateOffset + (v2 - 1) * CERTIFICATE_SIZE
		local v4 = buffer.readu32(buf, v3)

		if v4 == p then
			return buffer.readu32(buf, v3 + 4), (buffer.readu16(buf, v3 + 8))
		end

		if v4 < p then
			v = v2 + 1
		else
			certificateCount = v2 - 1
		end
	end

	return nil, nil
end

local function beginCandidatePlanes(state, p: number?) -- 2 equivalent calls inferred from this helper
	local candidatePlanes = state.CandidatePlanes
	table.clear(candidatePlanes)
	local planeMark = nextPlaneMark(state) -- inferred equivalent call
	local data = state.Data

	if p ~= nil and p >= 1 and p <= data.planeCount then
		markPlane(state, p, planeMark) -- inferred equivalent call
		candidatePlanes[1] = p
	end

	return planeMark, candidatePlanes
end

local function appendCertificatePlanes(p, value: number, list, p2: number, p3: number)
	local data = p.Data
	local v, v2 = findCertificate(data, pairKey(p2, p3)) -- inferred equivalent call

	if v == nil or v2 == nil then
		return
	end

	for i = v, v + v2 - 1 do
		local v3 = buffer.readu16(data.buffer, data.candidateOffset + (i - 1) * CANDIDATE_SIZE)

		if markPlane(p, v3, value) then -- inferred equivalent call
			list[#list + 1] = v3
		end
	end
end

local function candidatePlanesForCells(p, items, items2, p2: number?)
	local v, candidatePlanes = beginCandidatePlanes(p, p2) -- inferred equivalent call

	for _, item in items do
		for _, item2 in items2 do
			appendCertificatePlanes(p, v, candidatePlanes, item, item2)
		end
	end

	return candidatePlanes
end

local function candidatePlanesForCellBuffer(data, buf: buffer, p: number, p2: number, p3: number, p4: number, p5: number?)
	local v, candidatePlanes = beginCandidatePlanes(data, p5) -- inferred equivalent call

	for i = 0, p2 - 1 do
		local v2 = buffer.readu16(buf, p + i * 2)

		for j = 0, p4 - 1 do
			appendCertificatePlanes(data, v, candidatePlanes, v2, buffer.readu16(buf, p3 + j * 2))
		end
	end

	return candidatePlanes
end

function class.ProveProjectedOccludedForCells(state, list, list2, list3, list4, p: number?, p2)
	if #list3 == 0 or #list4 < 4 or #list == 0 or #list2 == 0 then
		return false, nil, 0
	end

	local data = state.Data

	if p ~= nil and p >= 1 and p <= data.planeCount then
		if p2 then
			p2.planes += 1
		end

		local flag, v = planeCovers(data, p, list3, list4, p2)

		if flag then
			return true, p, v
		end
	end

	local planeMark = nextPlaneMark(state) -- inferred equivalent call

	if p ~= nil then
		markPlane(state, p, planeMark) -- inferred equivalent call
	end

	for _, v in list do
		for _, v2 in list2 do
			local v3, v4 = findCertificate(data, pairKey(v, v2)) -- inferred equivalent call

			if not (v3 ~= nil and v4 ~= nil) then
				continue
			end

			for i = v3, v3 + v4 - 1 do
				local v5 = buffer.readu16(data.buffer, data.candidateOffset + (i - 1) * CANDIDATE_SIZE)

				if not markPlane(state, v5, planeMark) then -- inferred equivalent call
					continue
				end

				if p2 then
					p2.planes += 1
				end

				local flag, v6 = planeCovers(data, v5, list3, list4, p2)

				if flag then
					return true, v5, v6
				end
			end
		end
	end

	return false, nil, 0
end

function class.ProveProjectedOccludedForVolumeGroups(p, p2, p3, list, list2, p4: number?, p5)
	if #list == 0 or #list2 == 0 then
		return false, nil, 0
	end

	local v = candidatePlanesForCells(p, p2, p3, p4)

	if #v == 0 then
		return false, nil, 0
	end

	local v2 = nil
	local total = 0

	for _, v3 in list do
		for _, v4 in list2 do
			local v5 = false
			local v6 = 0
			local v7 = nil

			for _, v8 in v do
				if p5 then
					p5.planes += 1
				end

				local flag, v9 = planeCovers(p.Data, v8, v3, v4, p5)

				if not flag then
					continue
				end

				v7 = v8
				v6 = v9
				v5 = true
				break
			end

			if not v5 then
				return false, nil, 0
			end

			if v2 == nil then
				v2 = v7
			end

			total += v6
		end
	end

	return true, v2, total
end

function class.ProveProjectedOccludedForVolumeGroupBuffer(data, buf: buffer, p: number, p2: number, p3: number, p4: number, p5: number, p6: number, p7: number, p8: number, p9: number?, p10)
	if p2 == 0 or p4 == 0 or p6 == 0 or p8 == 0 then
		return false, nil, 0
	end

	local v = candidatePlanesForCellBuffer(data, buf, p, p2, p3, p4, p9)

	if #v == 0 or (p6 > 255 or p8 > 255) then
		return false, nil, 0
	end

	local v2 = p6 * p8
	local volumePairMarks = data.VolumePairMarks
	buffer.fill(volumePairMarks, 0, 0, v2)
	local v3 = nil
	local total = 0

	for _, v4 in v do
		if not (projectBufferPoints(data.Data, v4, buf, p5, p6 * 8, data.ViewerProjectionScratch) and projectBufferPoints(
			data.Data,
			v4,
			buf,
			p7,
			p8 * 8,
			data.TargetProjectionScratch
		)) then
			return false, nil, 0
		end

		if p6 > 1 then
			for i = 0, p8 - 1 do
				local count = 0

				for j = 0, p6 - 1 do
					if buffer.readu8(volumePairMarks, j * p8 + i) == 0 then
						count += 1
					end
				end

				if count == 0 then
					continue
				end

				if p10 then
					p10.planes += 1
				end

				local flag, v5 = projectedVolumePairCoverage(
					data.Data,
					v4,
					data.ViewerProjectionScratch,
					0,
					p6 * 8,
					data.TargetProjectionScratch,
					i * 8,
					8,
					p10
				)

				if not flag then
					continue
				end

				for j = 0, p6 - 1 do
					local v6 = j * p8 + i

					if buffer.readu8(volumePairMarks, v6) ~= 0 then
						continue
					end

					buffer.writeu8(volumePairMarks, v6, 1)
					v2 -= 1
				end

				total += v5 * count
				v3 = v3 or v4
			end

			if v2 == 0 then
				return true, v3, total
			end
		end

		for i = 0, p6 - 1 do
			for j = 0, p8 - 1 do
				local v5 = i * p8 + j

				if buffer.readu8(volumePairMarks, v5) ~= 0 then
					continue
				end

				if p10 then
					p10.planes += 1
				end

				local flag, v6 = projectedVolumePairCoverage(
					data.Data,
					v4,
					data.ViewerProjectionScratch,
					i * 8,
					8,
					data.TargetProjectionScratch,
					j * 8,
					8,
					p10
				)

				if not flag then
					continue
				end

				buffer.writeu8(volumePairMarks, v5, 1)
				v2 -= 1
				total += v6
				v3 = v3 or v4
			end
		end

		if v2 == 0 then
			return true, v3, total
		end
	end

	return false, nil, 0
end

local function ensureBatchScratch(state, p: number, total: number)
	local v = math.max(p, 1) * 24

	if buffer.len(state.BatchProjectionScratch) < v then
		state.BatchProjectionScratch = buffer.create(v)
	end

	if buffer.len(state.BatchVolumePairMarks) < math.max(total, 1) then
		state.BatchVolumePairMarks = buffer.create((math.max(total, 1)))
	end
end

function class.ProveProjectedOccludedActorBatchBuffer(data, buf: buffer, list, list2, p)
	local v = table.create(#list)
	local viewerProjectionIndex = 0

	for k, v2 in list do
		local v3 = {
			CellsOffset = v2.CellsOffset,
			CellCount = v2.CellCount,
			ViewerPointsOffset = v2.ViewerPointsOffset,
			ViewerPointCount = v2.ViewerPointCount,
			TargetPointsOffset = v2.TargetPointsOffset,
			TargetPointCount = v2.TargetPointCount,
			FallbackViewerOffset = v2.FallbackViewerOffset,
			FallbackViewerCount = v2.FallbackViewerCount,
			FallbackTargetOffset = v2.FallbackTargetOffset,
			FallbackTargetCount = v2.FallbackTargetCount,
			ViewerProjectionIndex = viewerProjectionIndex,
			TargetProjectionIndex = 0,
			FallbackViewerProjectionIndex = 0,
			FallbackTargetProjectionIndex = 0
		}
		local targetProjectionIndex = viewerProjectionIndex + v2.ViewerPointCount
		v3.TargetProjectionIndex = targetProjectionIndex
		local fallbackViewerProjectionIndex = targetProjectionIndex + v2.TargetPointCount
		v3.FallbackViewerProjectionIndex = fallbackViewerProjectionIndex
		local fallbackTargetProjectionIndex = fallbackViewerProjectionIndex + v2.FallbackViewerCount * 8
		v3.FallbackTargetProjectionIndex = fallbackTargetProjectionIndex
		viewerProjectionIndex = fallbackTargetProjectionIndex + v2.FallbackTargetCount * 8
		v[k] = v3
	end

	local v2 = table.create(#list2)
	local total = 0
	local v3 = {}
	local v4 = {}
	local v5 = {}

	for k, query in list2 do
		local v6 = v[query.ViewerActor]
		local v7 = v[query.TargetActor]
		local planes = {}
		local remainingPairs = 0

		if v6 ~= nil and v7 ~= nil then
			local v8

			if query.Fallback then
				if v6.FallbackViewerCount > 0 then
					v8 = v7.FallbackTargetCount > 0
				else
					v8 = false
				end
			elseif v6.ViewerPointCount > 0 then
				v8 = v7.TargetPointCount >= 4
			else
				v8 = false
			end

			if v8 and v6.CellCount > 0 and v7.CellCount > 0 then
				local v9 = candidatePlanesForCellBuffer(
					data,
					buf,
					v6.CellsOffset,
					v6.CellCount,
					v7.CellsOffset,
					v7.CellCount,
					query.PreferredPlane
				)

				for _, v10 in v9 do
					planes[#planes + 1] = v10
					local v11 = v3[v10]

					if v11 == nil then
						v11 = {}
						v3[v10] = v11
					end

					v11[#v11 + 1] = k

					if v4[v10] then
						continue
					end

					v4[v10] = true
					v5[#v5 + 1] = v10
				end
			end

			if query.Fallback then
				remainingPairs = v6.FallbackViewerCount * v7.FallbackTargetCount
			end
		end

		v2[k] = {
			Query = query,
			Planes = planes,
			MarkOffset = total,
			RemainingPairs = remainingPairs,
			FirstPlane = nil,
			ProofLeaves = 0,
			Proved = false,
			Tests = 0
		}
		total += remainingPairs
	end

	ensureBatchScratch(data, viewerProjectionIndex, total)
	local batchProjectionScratch = data.BatchProjectionScratch
	local batchVolumePairMarks = data.BatchVolumePairMarks

	if total > 0 then
		buffer.fill(batchVolumePairMarks, 0, 0, total)
	end

	local v6 = table.create(#list, 0)
	local v7 = table.create(#list, 0)
	local v8 = table.create(#list, 0)
	local v9 = table.create(#list, 0)
	local count = 0

	local function ensureProjected(p2: number, p3: number, p4: number, p5: number, p6: number, p7) -- 7 equivalent calls inferred from this helper
		if p7[p2] == p3 then
			return true
		end

		if not projectBufferPoints(data.Data, p3, buf, p4, p5, batchProjectionScratch, p6) then
			return false
		end

		p7[p2] = p3
		count += 1
		return true
	end

	local count2 = 0

	for _, v10 in v2 do
		local query = v10.Query
		local preferredPlane = query.PreferredPlane

		if preferredPlane == nil or (query.Fallback or v10.Proved) or v10.Planes[1] ~= preferredPlane then
			continue
		end

		local v11 = v[query.ViewerActor]
		local v12 = v[query.TargetActor]

		if not (v11 ~= nil and v12 ~= nil and ensureProjected( -- inferred equivalent call
			query.ViewerActor,
			preferredPlane,
			v11.ViewerPointsOffset,
			v11.ViewerPointCount,
			v11.ViewerProjectionIndex,
			v6
		)) then
			continue
		end

		if not ensureProjected( -- inferred equivalent call
			query.TargetActor,
			preferredPlane,
			v12.TargetPointsOffset,
			v12.TargetPointCount,
			v12.TargetProjectionIndex,
			v7
		) then
			continue
		end

		if p then
			p.planes += 1
		end

		count2 += 1
		v10.Tests += 1
		local flag, proofLeaves = projectedVolumePairCoverage(
			data.Data,
			preferredPlane,
			batchProjectionScratch,
			v11.ViewerProjectionIndex,
			v11.ViewerPointCount,
			batchProjectionScratch,
			v12.TargetProjectionIndex,
			v12.TargetPointCount,
			p
		)

		if not flag then
			continue
		end

		v10.Proved = true
		v10.FirstPlane = preferredPlane
		v10.ProofLeaves = proofLeaves
	end

	for _, firstPlane in v5 do
		local v10 = v3[firstPlane]

		if v10 == nil then
			continue
		end

		for _, v11 in v10 do
			local v12 = v2[v11]

			if v12.Proved or v12.Tests >= 24 then
				continue
			end

			local query = v12.Query
			local v13 = v[query.ViewerActor]
			local v14 = v[query.TargetActor]

			if not (v13 ~= nil and v14 ~= nil and (query.PreferredPlane ~= firstPlane or not (v12.Tests > 0) or query.Fallback)) then
				continue
			end

			if p then
				p.planes += 1
			end

			v12.Tests += 1

			if query.Fallback then
				if
					ensureProjected( -- inferred equivalent call
						query.ViewerActor,
						firstPlane,
						v13.ViewerPointsOffset,
						v13.ViewerPointCount,
						v13.ViewerProjectionIndex,
						v6
					)
					and ensureProjected( -- inferred equivalent call
						query.TargetActor,
						firstPlane,
						v14.FallbackTargetOffset,
						v14.FallbackTargetCount * 8,
						v14.FallbackTargetProjectionIndex,
						v9
					)
				then
					local fallbackViewerCount = v13.FallbackViewerCount
					local fallbackTargetCount = v14.FallbackTargetCount

					if fallbackViewerCount > 1 then
						for i = 0, fallbackTargetCount - 1 do
							local count3 = 0

							for j = 0, fallbackViewerCount - 1 do
								if buffer.readu8(batchVolumePairMarks, v12.MarkOffset + j * fallbackTargetCount + i) == 0 then
									count3 += 1
								end
							end

							if count3 == 0 then
								continue
							end

							count2 += 1
							local flag, v15 = projectedVolumePairCoverage(
								data.Data,
								firstPlane,
								batchProjectionScratch,
								v13.ViewerProjectionIndex,
								v13.ViewerPointCount,
								batchProjectionScratch,
								v14.FallbackTargetProjectionIndex + i * 8,
								8,
								p
							)

							if not flag then
								continue
							end

							for j = 0, fallbackViewerCount - 1 do
								local v16 = v12.MarkOffset + j * fallbackTargetCount + i

								if buffer.readu8(batchVolumePairMarks, v16) ~= 0 then
									continue
								end

								buffer.writeu8(batchVolumePairMarks, v16, 1)
								v12.RemainingPairs -= 1
							end

							v12.FirstPlane = v12.FirstPlane or firstPlane
							v12.ProofLeaves += v15 * count3
						end
					end

					if v12.RemainingPairs > 0 then
						if not ensureProjected( -- inferred equivalent call
							query.ViewerActor,
							firstPlane,
							v13.FallbackViewerOffset,
							fallbackViewerCount * 8,
							v13.FallbackViewerProjectionIndex,
							v8
						) then
							continue
						end

						for i = 0, fallbackViewerCount - 1 do
							for j = 0, fallbackTargetCount - 1 do
								local v15 = v12.MarkOffset + i * fallbackTargetCount + j

								if buffer.readu8(batchVolumePairMarks, v15) ~= 0 then
									continue
								end

								count2 += 1
								local flag, v16 = projectedVolumePairCoverage(
									data.Data,
									firstPlane,
									batchProjectionScratch,
									v13.FallbackViewerProjectionIndex + i * 8,
									8,
									batchProjectionScratch,
									v14.FallbackTargetProjectionIndex + j * 8,
									8,
									p
								)

								if not flag then
									continue
								end

								buffer.writeu8(batchVolumePairMarks, v15, 1)
								v12.RemainingPairs -= 1
								v12.FirstPlane = v12.FirstPlane or firstPlane
								v12.ProofLeaves += v16
							end
						end
					end

					if v12.RemainingPairs == 0 then
						v12.Proved = true
					end
				end
			elseif
				ensureProjected( -- inferred equivalent call
					query.ViewerActor,
					firstPlane,
					v13.ViewerPointsOffset,
					v13.ViewerPointCount,
					v13.ViewerProjectionIndex,
					v6
				)
				and ensureProjected( -- inferred equivalent call
					query.TargetActor,
					firstPlane,
					v14.TargetPointsOffset,
					v14.TargetPointCount,
					v14.TargetProjectionIndex,
					v7
				)
			then
				count2 += 1
				local flag, proofLeaves = projectedVolumePairCoverage(
					data.Data,
					firstPlane,
					batchProjectionScratch,
					v13.ViewerProjectionIndex,
					v13.ViewerPointCount,
					batchProjectionScratch,
					v14.TargetProjectionIndex,
					v14.TargetPointCount,
					p
				)

				if flag then
					v12.Proved = true
					v12.FirstPlane = firstPlane
					v12.ProofLeaves = proofLeaves
				end
			end
		end
	end

	local result = table.create(#list2)

	for k, v10 in v2 do
		result[k] = {
			Proved = v10.Proved,
			PlaneIndex = v10.FirstPlane,
			ProofLeaves = not v10.Proved and 0 or v10.ProofLeaves,
			UsedFallback = v10.Proved and v10.Query.Fallback
		}
	end

	return result, count, count2
end

function class.ProvePlaneBuffer(data, buf: buffer, p: number, p2: number, p3: number, p4: number, p5: number, p6)
	local data2 = data.Data

	if p3 == 0 or p5 < 4 or p < 1 or data2.planeCount < p or p ~= math.floor(p) then
		return false, 0
	end

	if p6 then
		p6.planes += 1
	end

	return planeCoversBuffer(
		data2,
		p,
		buf,
		p2,
		p3,
		p4,
		p5,
		data.ViewerProjectionScratch,
		data.TargetProjectionScratch,
		p6
	)
end

function class.ProveRectangleBuffer(p, buf: buffer, vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3, p2: number, p3: number, p4: number, p5: number, p6: number, p7: number)
	if p5 == 0 or p7 < 4 then
		return false
	end

	local v = p2 - 0.02
	local v2 = p3 - 0.02

	if v <= 0 or v2 <= 0 then
		return false
	end

	local flag, v3, v4, v5, v6 = projectFootprintBuffer(
		buf,
		vector,
		vector2,
		vector3,
		vector4,
		p4,
		p5,
		p6,
		p7,
		p.ViewerProjectionScratch,
		p.TargetProjectionScratch
	)

	if flag then
		if -v <= v3 and v4 <= v and -v2 <= v5 then
			flag = v6 <= v2
		else
			flag = false
		end
	end

	return flag
end

function class.ProveProjectedOccludedForCellBuffer(data, buf: buffer, p: number, p2: number, p3: number, p4: number, p5: number, p6: number, p7: number, p8: number, p9: number?, p10, value: number?)
	if p6 == 0 or p8 < 4 or p2 == 0 or p4 == 0 then
		return false, nil, 0
	end

	local data2 = data.Data
	local v = value or 1e999

	if p9 ~= nil and p9 >= 1 and p9 <= data2.planeCount then
		if p10 then
			p10.planes += 1
		end

		v -= 1
		local flag, v2 = planeCoversBuffer(
			data2,
			p9,
			buf,
			p5,
			p6,
			p7,
			p8,
			data.ViewerProjectionScratch,
			data.TargetProjectionScratch,
			p10
		)

		if flag then
			return true, p9, v2
		end
	end

	local planeMark = nextPlaneMark(data) -- inferred equivalent call

	if p9 ~= nil and p9 >= 1 and p9 <= data2.planeCount then
		markPlane(data, p9, planeMark) -- inferred equivalent call
	end

	for i = 0, p2 - 1 do
		local v2 = buffer.readu16(buf, p + i * 2)

		for j = 0, p4 - 1 do
			local v3, v4 = findCertificate(data2, pairKey(v2, buffer.readu16(buf, p3 + j * 2))) -- inferred equivalent call

			if not (v3 ~= nil and v4 ~= nil) then
				continue
			end

			for k = v3, v3 + v4 - 1 do
				local v5 = buffer.readu16(data2.buffer, data2.candidateOffset + (k - 1) * CANDIDATE_SIZE)

				if not markPlane(data, v5, planeMark) then -- inferred equivalent call
					continue
				end

				if v <= 0 then
					return false, nil, 0
				end

				v -= 1

				if p10 then
					p10.planes += 1
				end

				local flag, v6 = planeCoversBuffer(
					data2,
					v5,
					buf,
					p5,
					p6,
					p7,
					p8,
					data.ViewerProjectionScratch,
					data.TargetProjectionScratch,
					p10
				)

				if flag then
					return true, v5, v6
				end
			end
		end
	end

	return false, nil, 0
end

class.PairKey = pairKey

function class.SamplePacket(data, p: number)
	if p < 1 or data.Data.triangleCount < p or p % 1 ~= 0 then
		return nil
	end

	local v = (p - 1) % 4096 + 1

	if data.SamplePacketIds[v] == p then
		return data.SamplePackets[v]
	end

	local vector, v2, v3 = readTriangle(data.Data, p)
	local frozen = table.freeze({ vector, v2 - vector, v3 - vector })
	data.SamplePacketIds[v] = p
	data.SamplePackets[v] = frozen
	return frozen
end

return table.freeze(class)