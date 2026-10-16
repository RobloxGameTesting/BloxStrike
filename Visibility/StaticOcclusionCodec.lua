local createVector = vector.create

local function finite(p: number)
	return p == p and p > -1e999 and p < 1e999
end

local function finiteVector(vector: Vector3) -- 12 equivalent calls inferred from this helper
	local x = vector.X
	local v

	if x == x and x > -1e999 then
		v = x < 1e999
	else
		v = false
	end

	if not v then
		return v
	end

	local y = vector.Y

	if y == y and y > -1e999 then
		v = y < 1e999
	else
		v = false
	end

	if not v then
		return v
	end

	local z = vector.Z

	if z == z and z > -1e999 then
		return z < 1e999
	else
		return false
	end

	return v
end

local function writeVector(buf: buffer, offset: number, vector: Vector3) -- 9 equivalent calls inferred from this helper
	buffer.writef32(buf, offset, vector.X)
	buffer.writef32(buf, offset + 4, vector.Y)
	buffer.writef32(buf, offset + 8, vector.Z)
end

local function readVector(buf: buffer, offset: number) -- 14 equivalent calls inferred from this helper
	return (Vector3.new(buffer.readf32(buf, offset), buffer.readf32(buf, offset + 4), (buffer.readf32(buf, offset + 8))))
end

local function boundsContain(vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3) -- 1 equivalent call inferred from this helper
	return vector3.X >= vector.X - 0.125
		and vector3.Y >= vector.Y - 0.125
		and vector3.Z >= vector.Z - 0.125
		and vector4.X <= vector2.X + 0.125
		and vector4.Y <= vector2.Y + 0.125
		and vector4.Z <= vector2.Z + 0.125
end

local function boundsContainPoint(vector: Vector3, vector2: Vector3, vector3: Vector3)
	return boundsContain(vector, vector2, vector3, vector3) -- inferred equivalent call
end

local function payloadHash(buf: buffer, p: number, callback)
	local v = 5381

	for i = p, buffer.len(buf) - 1, 65536 do
		if callback then
			callback()
		end

		for j = i, math.min(i + 65535, buffer.len(buf) - 1) do
			v = bit32.band(v * 33 + buffer.readu8(buf, j), 4294967295)
		end
	end

	return v
end

local function checkedCount(p: number, p2: string, value: number?)
	if p < 0 or (value or 2000000) < p or p % 1 ~= 0 then
		error(`PVBVH1 has invalid {p2}`)
	end
end

local v = {
	encode = function(data)
		local count = #data.fingerprint

		if count == 0 or count > 65535 then
			error("PVBVH1 fingerprint length is invalid")
		end

		local count2 = #data.nodes

		if count2 < 0 or count2 > 2000000 or count2 % 1 ~= 0 then
			error("PVBVH1 has invalid node count")
		end

		local count3 = #data.leaves

		if count3 < 0 or count3 > 2000000 or count3 % 1 ~= 0 then
			error("PVBVH1 has invalid leaf count")
		end

		local count4 = #data.triangles

		if count4 < 0 or count4 > 2000000 or count4 % 1 ~= 0 then
			error("PVBVH1 has invalid triangle count")
		end

		local count5 = #data.planes

		if count5 < 0 or count5 > 2000000 or count5 % 1 ~= 0 then
			error("PVBVH1 has invalid plane count")
		end

		local count6 = #data.rectangles

		if count6 < 0 or count6 > 2000000 or count6 % 1 ~= 0 then
			error("PVBVH1 has invalid rectangle count")
		end

		local count7 = #data.certificates

		if count7 < 0 or count7 > 2000000 or count7 % 1 ~= 0 then
			error("PVBVH1 has invalid certificate count")
		end

		local count8 = #data.candidates

		if count8 < 0 or count8 > 2000000 or count8 % 1 ~= 0 then
			error("PVBVH1 has invalid candidate count")
		end

		if #data.nodes == 0 or data.rootNode < 1 or data.rootNode > #data.nodes then
			error("PVBVH1 root node is invalid")
		end

		if finiteVector(data.worldBounds.minimum) then -- inferred equivalent call
			if
				not finiteVector(data.worldBounds.maximum) -- inferred equivalent call
				or data.worldBounds.minimum.X > data.worldBounds.maximum.X
				or data.worldBounds.minimum.Y > data.worldBounds.maximum.Y
				or data.worldBounds.minimum.Z > data.worldBounds.maximum.Z
			then
				error("PVBVH1 world bounds are invalid")
			end
		else
			error("PVBVH1 world bounds are invalid")
		end

		local v = count + #data.nodes * 224 + #data.leaves * 8 + #data.triangles * 40 + #data.planes * 56 + #data.rectangles * 20 + #data.certificates * 12 + #data.candidates * 2
		local buf = buffer.create(v + 80)
		buffer.writestring(buf, 0, "PVBVH1\0\0")
		buffer.writeu16(buf, 8, 2)
		buffer.writeu16(buf, 10, 0)
		buffer.writeu32(buf, 12, #data.nodes)
		buffer.writeu32(buf, 16, #data.leaves)
		buffer.writeu32(buf, 20, #data.triangles)
		buffer.writeu32(buf, 24, #data.planes)
		buffer.writeu32(buf, 28, #data.rectangles)
		buffer.writeu16(buf, 32, count)
		buffer.writeu16(buf, 34, 0)
		buffer.writeu32(buf, 36, data.rootNode)
		buffer.writeu32(buf, 40, 0)
		buffer.writeu32(buf, 44, v)
		local minimum = data.worldBounds.minimum
		buffer.writef32(buf, 48, minimum.X)
		buffer.writef32(buf, 52, minimum.Y)
		buffer.writef32(buf, 56, minimum.Z)
		local maximum = data.worldBounds.maximum
		buffer.writef32(buf, 60, maximum.X)
		buffer.writef32(buf, 64, maximum.Y)
		buffer.writef32(buf, 68, maximum.Z)
		buffer.writeu32(buf, 72, #data.certificates)
		buffer.writeu32(buf, 76, #data.candidates)
		local v2 = 80
		buffer.writestring(buf, v2, data.fingerprint)
		local v3 = v2 + count

		for _, node in data.nodes do
			if #node.children > 8 then
				error("PVBVH1 node has more than eight children")
			end

			local v4 = v3

			for i = 1, 8 do
				local v5 = node.children[i]
				local v6 = v4 + (i - 1) * 24

				if v5 == nil then
					buffer.writef32(buf, v6, 0)
					buffer.writef32(buf, v6 + 4, 0)
					buffer.writef32(buf, v6 + 8, 0)
					local v7 = v6 + 12
					buffer.writef32(buf, v7, 0)
					buffer.writef32(buf, v7 + 4, 0)
					buffer.writef32(buf, v7 + 8, 0)
					buffer.writei32(buf, v4 + 192 + (i - 1) * 4, 0)
				else
					if finiteVector(v5.minimum) then -- inferred equivalent call
						if not finiteVector(v5.maximum) then -- inferred equivalent call
							error("PVBVH1 child bounds are not finite")
						end
					else
						error("PVBVH1 child bounds are not finite")
					end

					writeVector(buf, v6, v5.minimum) -- inferred equivalent call
					writeVector(buf, v6 + 12, v5.maximum) -- inferred equivalent call
					buffer.writei32(buf, v4 + 192 + (i - 1) * 4, v5.reference)
				end
			end

			v3 += 224
		end

		for _, leave in data.leaves do
			buffer.writeu32(buf, v3, leave.firstTriangle)
			buffer.writeu16(buf, v3 + 4, leave.triangleCount)
			buffer.writeu16(buf, v3 + 6, 0)
			v3 += 8
		end

		for _, triangle in data.triangles do
			writeVector(buf, v3, triangle.a) -- inferred equivalent call
			writeVector(buf, v3 + 12, triangle.b) -- inferred equivalent call
			writeVector(buf, v3 + 24, triangle.c) -- inferred equivalent call
			buffer.writeu32(buf, v3 + 36, triangle.primitive)
			v3 += 40
		end

		for _, plane in data.planes do
			writeVector(buf, v3, plane.origin) -- inferred equivalent call
			writeVector(buf, v3 + 12, plane.u) -- inferred equivalent call
			writeVector(buf, v3 + 24, plane.v) -- inferred equivalent call
			writeVector(buf, v3 + 36, plane.normal) -- inferred equivalent call
			buffer.writeu32(buf, v3 + 48, plane.firstRectangle)
			buffer.writeu16(buf, v3 + 52, plane.rectangleCount)
			buffer.writeu16(buf, v3 + 54, 0)
			v3 += 56
		end

		for _, rectangle in data.rectangles do
			buffer.writef32(buf, v3, rectangle.minimumU)
			buffer.writef32(buf, v3 + 4, rectangle.maximumU)
			buffer.writef32(buf, v3 + 8, rectangle.minimumV)
			buffer.writef32(buf, v3 + 12, rectangle.maximumV)
			buffer.writeu32(buf, v3 + 16, rectangle.primitive)
			v3 += 20
		end

		for _, certificate in data.certificates do
			buffer.writeu32(buf, v3, certificate.pairKey)
			buffer.writeu32(buf, v3 + 4, certificate.firstCandidate)
			buffer.writeu16(buf, v3 + 8, certificate.candidateCount)
			buffer.writeu16(buf, v3 + 10, 0)
			v3 += 12
		end

		for _, value in data.candidates do
			if value < 1 or #data.planes < value or value > 65535 then
				error("PVBVH1 certificate candidate is invalid")
			end

			buffer.writeu16(buf, v3, value)
			v3 += 2
		end

		assert(v3 == buffer.len(buf), "PVBVH1 encoder size drift")
		buffer.writeu32(buf, 40, (payloadHash(buf, 80)))
		return buffer.tostring(buf)
	end
}

local function readTriangle(data, i: number)
	local buf = data.buffer
	local v2 = data.triangleOffset + (i - 1) * data.triangleSize

	if data.version == 3 then
		local v3 = buffer.readu32(buf, v2)
		local v4 = buffer.readu32(buf, v2 + 4)
		local v5 = buffer.readu32(buf, v2 + 8)
		return
			readVector(buf, data.vertexOffset + (v3 - 1) * 12), -- inferred equivalent call
			readVector(buf, data.vertexOffset + (v4 - 1) * 12), -- inferred equivalent call
			readVector(buf, data.vertexOffset + (v5 - 1) * 12), -- inferred equivalent call
			0
	else
		return readVector(buf, v2), readVector(buf, v2 + 12), readVector(buf, v2 + 24), (buffer.readu32(buf, v2 + 36)) -- inferred equivalent call
	end
end

function v.referencedPrimitives(data)
	local result = {}

	if data.version == 3 then
		if data.triangleCount > 0 then
			result[0] = true
		end

		return result
	else
		local buf = data.buffer

		for i = 1, data.triangleCount do
			result[buffer.readu32(buf, data.triangleOffset + (i - 1) * data.triangleSize + 36)] = true
		end

		return result
	end
end

function v.validateExactGeometry(data)
	if data.planeCount ~= 0 or data.rectangleCount ~= 0 or data.certificateCount ~= 0 or data.candidateCount ~= 0 then
		return false, "ExactPVBVHContainsLegacyRecords"
	end

	if data.version == 3 then
		return true, nil
	end

	local buf = data.buffer

	for i = 1, data.triangleCount do
		if buffer.readu32(buf, data.triangleOffset + (i - 1) * data.triangleSize + 36) ~= 0 then
			return false, "ExactPVBVHHasOwnedPrimitive"
		end
	end

	return true, nil
end

local function validateHierarchy(data, callback)
	local buf = data.buffer
	local buf2 = buffer.create(data.nodeCount)
	local buf3 = buffer.create(data.leafCount)
	local buf4 = buffer.create(data.triangleCount)
	local v2 = table.create(math.min(data.nodeCount, 1024), 0)
	local v3 = table.create(math.min(data.nodeCount, 1024), createVector(0, 0, 0))
	local v4 = table.create(math.min(data.nodeCount, 1024), createVector(0, 0, 0))
	v2[1] = data.rootNode
	v3[1] = data.worldBounds.minimum
	v4[1] = data.worldBounds.maximum
	buffer.writeu8(buf2, data.rootNode - 1, 1)
	local v5 = 1
	local v6 = 1
	local count = 0
	local count2 = 0

	while v5 > 0 do
		if callback then
			callback()
		end

		local v7 = v2[v5]
		local v8 = v3[v5]
		local v9 = v4[v5]
		v5 -= 1
		local v10 = data.nodeOffset + (v7 - 1) * 224
		local count3 = 0

		for i = 1, 8 do
			local v11 = buffer.readi32(buf, v10 + 192 + (i - 1) * 4)

			if v11 == 0 then
				continue
			end

			count3 += 1
			local v12 = v10 + (i - 1) * 24
			local vector = readVector(buf, v12) -- inferred equivalent call
			local vector2 = readVector(buf, v12 + 12) -- inferred equivalent call

			if not boundsContain(v8, v9, vector, vector2) then
				error("PVBVH1 child bounds escape their parent")
			end

			if v11 > 0 then
				if buffer.readu8(buf2, v11 - 1) ~= 0 then
					error("PVBVH1 node graph is cyclic or has multiple parents")
				end

				buffer.writeu8(buf2, v11 - 1, 1)
				v6 += 1
				v5 += 1
				v2[v5] = v11
				v3[v5] = vector
				v4[v5] = vector2
			else
				local v13 = -v11

				if buffer.readu8(buf3, v13 - 1) ~= 0 then
					error("PVBVH1 leaf has multiple parents")
				end

				buffer.writeu8(buf3, v13 - 1, 1)
				count += 1
				local v14 = data.leafOffset + (v13 - 1) * 8
				local v15 = buffer.readu32(buf, v14)

				for j = v15, v15 + buffer.readu16(buf, v14 + 4) - 1 do
					if buffer.readu8(buf4, j - 1) ~= 0 then
						error("PVBVH1 leaf triangle ranges overlap")
					end

					buffer.writeu8(buf4, j - 1, 1)
					count2 += 1
					local v16, v17, v18 = readTriangle(data, j)

					if
						boundsContainPoint(vector, vector2, v16)
						and boundsContainPoint(vector, vector2, v17)
						and boundsContainPoint(vector, vector2, v18)
					then
						continue
					end

					error("PVBVH1 triangle escapes its leaf bounds")
				end
			end
		end

		if count3 == 0 then
			error("PVBVH1 reachable node is empty")
		end
	end

	if v6 ~= data.nodeCount then
		error("PVBVH1 contains unreachable nodes")
	end

	if count ~= data.leafCount then
		error("PVBVH1 contains unreachable leaves")
	end

	if count2 ~= data.triangleCount then
		error("PVBVH1 leaf ranges do not cover every triangle")
	end
end

function v.decode(str: string, callback)
	local buf = buffer.fromstring(str)

	if buffer.len(buf) < 80 or buffer.readstring(buf, 0, 8) ~= "PVBVH1\0\0" then
		error("PVBVH1 magic is invalid")
	end

	local version = buffer.readu16(buf, 8)

	if version ~= 2 and version ~= 3 or buffer.readu16(buf, 10) ~= 0 then
		error("PVBVH1 version or flags are unsupported")
	end

	local v2 = version == 3
	local nodeCount = buffer.readu32(buf, 12)
	local leafCount = buffer.readu32(buf, 16)
	local triangleCount = buffer.readu32(buf, 20)
	local v3 = buffer.readu32(buf, 24)
	local vertexCount = not v2 and 0 or v3
	local planeCount = v2 and 0 or v3
	local rectangleCount = buffer.readu32(buf, 28)
	local certificateCount = buffer.readu32(buf, 72)
	local candidateCount = buffer.readu32(buf, 76)
	local v4 = buffer.readu16(buf, 32)
	local rootNode = buffer.readu32(buf, 36)
	local v5 = buffer.readu32(buf, 40)
	local v6 = buffer.readu32(buf, 44)

	if nodeCount < 0 or nodeCount > 2000000 or nodeCount % 1 ~= 0 then
		error("PVBVH1 has invalid node count")
	end

	if leafCount < 0 or leafCount > 2000000 or leafCount % 1 ~= 0 then
		error("PVBVH1 has invalid leaf count")
	end

	if triangleCount < 0 or triangleCount > 2000000 or triangleCount % 1 ~= 0 then
		error("PVBVH1 has invalid triangle count")
	end

	if vertexCount < 0 or vertexCount > 6000000 or vertexCount % 1 ~= 0 then
		error("PVBVH1 has invalid vertex count")
	end

	if planeCount < 0 or planeCount > 2000000 or planeCount % 1 ~= 0 then
		error("PVBVH1 has invalid plane count")
	end

	if rectangleCount < 0 or rectangleCount > 2000000 or rectangleCount % 1 ~= 0 then
		error("PVBVH1 has invalid rectangle count")
	end

	if certificateCount < 0 or certificateCount > 2000000 or certificateCount % 1 ~= 0 then
		error("PVBVH1 has invalid certificate count")
	end

	if candidateCount < 0 or candidateCount > 2000000 or candidateCount % 1 ~= 0 then
		error("PVBVH1 has invalid candidate count")
	end

	if
		nodeCount == 0
		or rootNode < 1
		or nodeCount < rootNode
		or v4 == 0
		or v2 and (leafCount == 0 or triangleCount == 0 or vertexCount == 0)
	then
		error("PVBVH1 root or fingerprint is invalid")
	end

	if v2 and (rectangleCount ~= 0 or certificateCount ~= 0 or candidateCount ~= 0) then
		error("PVBVH1 v3 is reserved for indexed ExactGeometryV1 payloads")
	end

	local v7 = v4 + nodeCount * 224 + leafCount * 8 + vertexCount * 12 + triangleCount * (v2 and 12 or 40) + planeCount * 56 + rectangleCount * 20 + certificateCount * 12 + candidateCount * 2

	if v6 ~= v7 or buffer.len(buf) ~= v7 + 80 then
		error("PVBVH1 payload size is invalid")
	end

	if payloadHash(buf, 80, callback) ~= v5 then
		error("PVBVH1 payload checksum mismatch")
	end

	local vector2 = Vector3.new(buffer.readf32(buf, 48), buffer.readf32(buf, 52), (buffer.readf32(buf, 56)))
	local vector3 = Vector3.new(buffer.readf32(buf, 60), buffer.readf32(buf, 64), (buffer.readf32(buf, 68)))

	if finiteVector(vector2) then -- inferred equivalent call
		if not finiteVector(vector3) or vector2.X > vector3.X or vector2.Y > vector3.Y or vector2.Z > vector3.Z then -- inferred equivalent call
			error("PVBVH1 world bounds are invalid")
		end
	else
		error("PVBVH1 world bounds are invalid")
	end

	local fingerprint = buffer.readstring(buf, 80, v4)
	local nodeOffset = v4 + 80
	local leafOffset = nodeOffset + nodeCount * 224
	local vertexOffset = leafOffset + leafCount * 8
	local triangleOffset = vertexOffset + vertexCount * 12
	local triangleSize = v2 and 12 or 40
	local planeOffset = triangleOffset + triangleCount * triangleSize
	local rectangleOffset = planeOffset + planeCount * 56
	local certificateOffset = rectangleOffset + rectangleCount * 20
	local candidateOffset = certificateOffset + certificateCount * 12

	for i = 1, nodeCount do
		if callback and i % 1024 == 0 then
			callback()
		end

		local v8 = nodeOffset + (i - 1) * 224

		for j = 1, 8 do
			local v9 = buffer.readi32(buf, v8 + 192 + (j - 1) * 4)

			if nodeCount < v9 or v9 < -leafCount then
				error("PVBVH1 child reference is invalid")
			end

			if v9 == 0 then
				continue
			end

			local v10 = v8 + (j - 1) * 24
			local vector = readVector(buf, v10) -- inferred equivalent call
			local vector4 = readVector(buf, v10 + 12) -- inferred equivalent call

			if
				finiteVector(vector) -- inferred equivalent call
				and finiteVector(vector4) -- inferred equivalent call
				and not (vector.X > vector4.X or vector.Y > vector4.Y or vector.Z > vector4.Z)
			then
				continue
			end

			error("PVBVH1 child bounds are invalid")
		end
	end

	for i = 1, leafCount do
		if callback and i % 8192 == 0 then
			callback()
		end

		local v8 = leafOffset + (i - 1) * 8
		local v9 = buffer.readu32(buf, v8)
		local v10 = buffer.readu16(buf, v8 + 4)

		if v10 == 0 or v9 < 1 or triangleCount < v9 + v10 - 1 then
			error("PVBVH1 leaf triangle range is invalid")
		end
	end

	if v2 then
		for i = 1, vertexCount do
			if callback and i % 8192 == 0 then
				callback()
			end

			if finiteVector(readVector(buf, vertexOffset + (i - 1) * 12)) then -- inferred equivalent call
				continue
			end

			error("PVBVH1 indexed vertex is not finite")
		end

		local buf2 = buffer.create(vertexCount)
		local count = 0

		for i = 1, triangleCount do
			if callback and i % 8192 == 0 then
				callback()
			end

			local v8 = triangleOffset + (i - 1) * 12
			local v9 = buffer.readu32(buf, v8)
			local v10 = buffer.readu32(buf, v8 + 4)
			local v11 = buffer.readu32(buf, v8 + 8)

			if
				v9 < 1
				or vertexCount < v9
				or v10 < 1
				or vertexCount < v10
				or v11 < 1
				or vertexCount < v11
				or v9 == v10
				or v9 == v11
				or v10 == v11
			then
				error("PVBVH1 indexed triangle has invalid vertex indices")
			end

			if buffer.readu8(buf2, v9 - 1) == 0 then
				buffer.writeu8(buf2, v9 - 1, 1)
				count += 1
			end

			if buffer.readu8(buf2, v10 - 1) == 0 then
				buffer.writeu8(buf2, v10 - 1, 1)
				count += 1
			end

			if buffer.readu8(buf2, v11 - 1) ~= 0 then
				continue
			end

			buffer.writeu8(buf2, v11 - 1, 1)
			count += 1
		end

		if count ~= vertexCount then
			error("PVBVH1 indexed vertex table contains unreachable vertices")
		end
	else
		for i = 1, triangleCount do
			if callback and i % 8192 == 0 then
				callback()
			end

			local v8 = triangleOffset + (i - 1) * 40

			if
				finiteVector(readVector(buf, v8)) -- inferred equivalent call
				and finiteVector(readVector(buf, v8 + 12)) -- inferred equivalent call
				and finiteVector(readVector(buf, v8 + 24)) -- inferred equivalent call
			then
				continue
			end

			error("PVBVH1 triangle is not finite")
		end
	end

	for i = 1, planeCount do
		local v8 = planeOffset + (i - 1) * 56
		local v9 = buffer.readu32(buf, v8 + 48)
		local v10 = buffer.readu16(buf, v8 + 52)

		if v10 == 0 or v9 < 1 or rectangleCount < v9 + v10 - 1 then
			error("PVBVH1 plane rectangle range is invalid")
		end
	end

	local v8 = -1

	for i = 1, certificateCount do
		local v9 = certificateOffset + (i - 1) * 12
		local v10 = buffer.readu32(buf, v9)
		local v11 = buffer.readu32(buf, v9 + 4)
		local v12 = buffer.readu16(buf, v9 + 8)

		if v10 <= v8 or v12 == 0 or v11 < 1 or candidateCount < v11 + v12 - 1 then
			error("PVBVH1 certificate range or ordering is invalid")
		end

		v8 = v10
	end

	for i = 1, candidateCount do
		local v9 = buffer.readu16(buf, candidateOffset + (i - 1) * 2)

		if v9 < 1 or planeCount < v9 then
			error("PVBVH1 certificate plane is invalid")
		end
	end

	local v9 = {
		buffer = buf,
		version = version,
		fingerprint = fingerprint,
		rootNode = rootNode,
		nodeCount = nodeCount,
		leafCount = leafCount,
		triangleCount = triangleCount,
		planeCount = planeCount,
		rectangleCount = rectangleCount,
		certificateCount = certificateCount,
		candidateCount = candidateCount,
		vertexCount = vertexCount,
		worldBounds = { minimum = vector2, maximum = vector3 },
		nodeOffset = nodeOffset,
		leafOffset = leafOffset,
		vertexOffset = vertexOffset,
		triangleOffset = triangleOffset,
		triangleSize = triangleSize,
		planeOffset = planeOffset,
		rectangleOffset = rectangleOffset,
		certificateOffset = certificateOffset,
		candidateOffset = candidateOffset
	}
	validateHierarchy(v9, callback)
	return v9
end

v.MAGIC = "PVBVH1\0\0"
v.VERSION = 2
v.INDEXED_VERSION = 3
v.NODE_SIZE = 224
v.LEAF_SIZE = 8
v.TRIANGLE_SIZE = 40
v.VERTEX_SIZE = 12
v.INDEXED_TRIANGLE_SIZE = 12
v.PLANE_SIZE = 56
v.RECT_SIZE = 20
v.CERTIFICATE_SIZE = 12
v.CANDIDATE_SIZE = 2
return table.freeze(v)