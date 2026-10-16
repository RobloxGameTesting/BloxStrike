local createVector = vector.create
local StaticOcclusionCodec = require(script.Parent.StaticOcclusionCodec)
local PVSCodec = require(script.Parent.PVSCodec)
local frozen = table.freeze({
	{ 1, 3, 4 },
	{ 1, 4, 2 },
	{ 5, 6, 8 },
	{ 5, 8, 7 },
	{ 1, 5, 7 },
	{ 1, 7, 3 },
	{ 2, 4, 8 },
	{ 2, 8, 6 },
	{ 1, 2, 6 },
	{ 1, 6, 5 },
	{ 3, 7, 8 },
	{ 3, 8, 4 }
})

local function isExactBlock(part) -- 1 equivalent call inferred from this helper
	return part:IsA("Part") and part.Shape == Enum.PartType.Block
end

local function canonicalAxis(vector: Vector3) -- 3 equivalent calls inferred from this helper
	local x = vector.X
	local y = vector.Y
	local z = vector.Z
	local v = math.abs(x)
	local v2 = math.abs(y)
	local v3 = math.abs(z)
	local v4

	if v2 <= v and v3 <= v then
		v4 = x < 0 and -1 or 1
	elseif v3 <= v2 then
		v4 = y < 0 and -1 or 1
	else
		v4 = z < 0 and -1 or 1
	end

	return vector * v4
end

local function axisKey(vector: Vector3) -- 3 equivalent calls inferred from this helper
	return `{string.format("%.9g", vector.X)},{string.format("%.9g", vector.Y)},{string.format("%.9g", vector.Z)}`
end

local function verticesForBlock(part)
	local v = part.Size * 0.5
	local result = table.create(8)
	local count = 0

	for _, v2 in { -v.X, v.X } do
		for _, v3 in { -v.Y, v.Y } do
			for _, v4 in { -v.Z, v.Z } do
				count += 1
				result[count] = part.CFrame:PointToWorldSpace((Vector3.new(v2, v3, v4)))
			end
		end
	end

	return result
end

local function triangleItem(triangle)
	return {
		triangle = triangle,
		minimum = triangle.a:Min(triangle.b):Min(triangle.c),
		maximum = triangle.a:Max(triangle.b):Max(triangle.c),
		centroid = (triangle.a + triangle.b + triangle.c) / 3
	}
end

local frozen2 = table.freeze({
	{ 1, 3, 4 },
	{ 1, 4, 2 },
	{ 2, 4, 6 },
	{ 2, 6, 5 },
	{ 1, 5, 6 },
	{ 1, 6, 3 },
	{ 1, 2, 5 },
	{ 3, 6, 4 }
})
local frozen3 = table.freeze({
	{ 1, 3, 4 },
	{ 1, 4, 2 },
	{ 3, 4, 5 },
	{ 1, 3, 5 },
	{ 1, 5, 2 },
	{ 2, 5, 4 }
})

local function verticesForWedge(instance)
	local v = instance.Size * 0.5
	local cframe = instance.CFrame
	return {
		cframe:PointToWorldSpace((Vector3.new(-v.X, -v.Y, -v.Z))),
		cframe:PointToWorldSpace((Vector3.new(-v.X, -v.Y, v.Z))),
		cframe:PointToWorldSpace((Vector3.new(v.X, -v.Y, -v.Z))),
		cframe:PointToWorldSpace((Vector3.new(v.X, -v.Y, v.Z))),
		cframe:PointToWorldSpace((Vector3.new(-v.X, v.Y, v.Z))),
		cframe:PointToWorldSpace((Vector3.new(v.X, v.Y, v.Z)))
	}
end

local function verticesForCornerWedge(instance)
	local v = instance.Size * 0.5
	local cframe = instance.CFrame
	return {
		cframe:PointToWorldSpace((Vector3.new(-v.X, -v.Y, -v.Z))),
		cframe:PointToWorldSpace((Vector3.new(-v.X, -v.Y, v.Z))),
		cframe:PointToWorldSpace((Vector3.new(v.X, -v.Y, -v.Z))),
		cframe:PointToWorldSpace((Vector3.new(v.X, -v.Y, v.Z))),
		cframe:PointToWorldSpace((Vector3.new(v.X, v.Y, -v.Z)))
	}
end

local function cylinderTriangles(part, k: number, list)
	local v = part.Size * 0.5
	local v2 = math.min(v.Y, v.Z)
	local cframe = part.CFrame
	local v3 = table.create(24)

	for i = 0, 11 do
		local v4 = i / 12 * 3.141592653589793 * 2
		local v5 = math.cos(v4) * v2
		local v6 = math.sin(v4) * v2
		v3[i * 2 + 1] = cframe:PointToWorldSpace((Vector3.new(-v.X, v5, v6)))
		v3[i * 2 + 2] = cframe:PointToWorldSpace((Vector3.new(v.X, v5, v6)))
	end

	local function push(vector: Vector3, vector2: Vector3, vector3: Vector3) -- 4 equivalent calls inferred from this helper
		list[#list + 1] = triangleItem({ a = vector, b = vector2, c = vector3, primitive = k })
	end

	for i = 0, 11 do
		local v4 = (i + 1) % 12
		local v5 = v3[i * 2 + 1]
		local v6 = v3[i * 2 + 2]
		local v7 = v3[v4 * 2 + 1]
		local v8 = v3[v4 * 2 + 2]
		push(v5, v7, v8) -- inferred equivalent call
		push(v5, v8, v6) -- inferred equivalent call
	end

	for i = 1, 10 do
		push(v3[1], v3[i * 2 + 1], v3[(i + 1) * 2 + 1]) -- inferred equivalent call
		push(v3[2], v3[(i + 1) * 2 + 2], v3[i * 2 + 2]) -- inferred equivalent call
	end
end

local function meshForPart(part)
	if part:IsA("WedgePart") or part:IsA("Part") and part.Shape == Enum.PartType.Wedge then
		return verticesForWedge(part), frozen2
	end

	if part:IsA("CornerWedgePart") or part:IsA("Part") and part.Shape == Enum.PartType.CornerWedge then
		return verticesForCornerWedge(part), frozen3
	end

	return nil, nil
end

local function isCylinder(part) -- 1 equivalent call inferred from this helper
	return part:IsA("Part") and part.Shape == Enum.PartType.Cylinder
end

local function unionBounds(list, value: number?, p: number?)
	local minimum = createVector(1e999, 1e999, 1e999)
	local maximum = createVector(-1e999, -1e999, -1e999)

	for i = value or 1, p or #list do
		minimum = minimum:Min(list[i].minimum)
		maximum = maximum:Max(list[i].maximum)
	end

	return { minimum = minimum, maximum = maximum }
end

local function centroidAxis(list)
	local v = createVector(1e999, 1e999, 1e999)
	local v2 = createVector(-1e999, -1e999, -1e999)

	for _, item in list do
		v = v:Min(item.centroid)
		v2 = v2:Max(item.centroid)
	end

	local v3 = v2 - v

	if v3.X >= v3.Y and v3.X >= v3.Z then
		return "X"
	end

	if v3.Y >= v3.Z then
		return "Y"
	end

	return "Z"
end

local function buildBVH(p)
	local v = {}
	local v2 = {}
	local triangles = {}

	local function makeLeaf(list)
		local v3 = #v2 + 1
		local firstTriangle = #triangles + 1

		for _, v4 in list do
			triangles[#triangles + 1] = v4.triangle
		end

		v2[v3] = {
			firstTriangle = firstTriangle,
			triangleCount = #list
		}
		return -v3
	end

	local function buildNode(list)
		local v3 = #v + 1
		v[v3] = { children = {} }
		local v4 = centroidAxis(list)
		table.sort(list, function(a, b)
			local v5 = a.centroid[v4]
			local v6 = b.centroid[v4]

			if v5 == v6 then
				return a.triangle.primitive < b.triangle.primitive
			end

			return v5 < v6
		end)
		local v5 = math.min(8, (math.max(1, (math.ceil(#list / 8)))))
		local total = 1

		for i = 1, v5 do
			local v6 = math.ceil((#list - total + 1) / (v5 - i + 1))
			local v7 = table.create(v6)

			for j = total, total + v6 - 1 do
				v7[#v7 + 1] = list[j]
			end

			total += v6
			local reference

			if #v7 <= 8 then
				reference = makeLeaf(v7)
			else
				reference = buildNode(v7)
			end

			local v8 = unionBounds(v7)
			v[v3].children[i] = {
				minimum = v8.minimum,
				maximum = v8.maximum,
				reference = reference
			}
		end

		return v3
	end

	return v, v2, triangles, (buildNode(p))
end

local function planeForBlock(part, k: number)
	local size = part.Size
	local v = { part.CFrame.RightVector, part.CFrame.UpVector, part.CFrame.ZVector }
	local v2 = { size.X, size.Y, size.Z }
	local v3 = 1
	local v4 = v2[2] < v2[v3] and 2 or v3
	local v5 = v2[3] < v2[v4] and 3 or v4
	local v6 = v5 == 1 and 2 or 1
	local v7 = v5 == 3 and 2 or 3
	local v8 = v6 == v7 and 3 or v7
	local normal = canonicalAxis(v[v5]) -- inferred equivalent call
	local v9 = canonicalAxis(v[v6]) -- inferred equivalent call
	local v10 = canonicalAxis(v[v8]) -- inferred equivalent call
	local dot = part.Position:Dot(normal)
	local dot2 = part.Position:Dot(v9)
	local dot3 = part.Position:Dot(v10)
	local v11 = v2[v6] * 0.5
	local v12 = v2[v8] * 0.5
	return `{axisKey(normal)}|{axisKey(v9)}|{axisKey(v10)}|{string.format("%.9g", dot)}`, {
		origin = normal * dot,
		u = v9,
		v = v10,
		normal = normal,
		rectangles = {}
	}, {
		minimumU = dot2 - v11,
		maximumU = dot2 + v11,
		minimumV = dot3 - v12,
		maximumV = dot3 + v12,
		primitive = k
	} -- inferred equivalent call
end

local function representativePosition(p) -- 2 equivalent calls inferred from this helper
	return (Vector3.new(
		(p.minimum.X + p.maximum.X) * 0.5,
		math.min(p.minimum.Y + 3, (p.minimum.Y + p.maximum.Y) * 0.5),
		(p.minimum.Z + p.maximum.Z) * 0.5
	))
end

local function buildCertificates(list, rectangles, p, p2)
	if p == nil or #list == 0 then
		return {}, {}
	end

	local v = table.create(#p.cells)

	for i = 1, #p.cells do
		v[i] = {}
	end

	for _, region in p.regions do
		v[region.cluster][#v[region.cluster] + 1] = region
	end

	local v2 = p2 == nil and 0 or math.max(math.floor(p2.yieldEveryPairs or 0), 0)

	local function addSegmentCandidates(vector: Vector3, vector2: Vector3, p3)
		for k, v3 in list do
			local dot = (vector - v3.origin):Dot(v3.normal)
			local dot2 = (vector2 - v3.origin):Dot(v3.normal)

			if dot * dot2 >= -1e-6 then
				continue
			end

			local v4 = -dot / (dot2 - dot)

			if v4 <= 0 or v4 >= 1 then
				continue
			end

			local vector3 = vector:Lerp(vector2, v4) - v3.origin
			local dot3 = vector3:Dot(v3.u)
			local dot4 = vector3:Dot(v3.v)

			for i = v3.firstRectangle, v3.firstRectangle + v3.rectangleCount - 1 do
				local v5 = rectangles[i]

				if not (v5.minimumU <= dot3 and dot3 <= v5.maximumU and v5.minimumV <= dot4 and dot4 <= v5.maximumV) then
					continue
				end

				local v6 = math.min(dot3 - v5.minimumU, v5.maximumU - dot3, dot4 - v5.minimumV, v5.maximumV - dot4)
				p3[k] = math.max(p3[k] or -1e999, v6)
				break
			end
		end
	end

	local count = 0
	local result = {}
	local pairEntries = {}

	for i = 1, #p.cells do
		for j = i + 1, #p.cells do
			if PVSCodec.isVisible(p, i, j) then
				continue
			end

			count += 1
			local v3 = {}

			for _, v4 in v[i] do
				for _, v5 in v[j] do
					addSegmentCandidates(representativePosition(v4), representativePosition(v5), v3) -- inferred equivalent call
				end
			end

			local v4 = {}

			for k, score in v3 do
				v4[#v4 + 1] = { plane = k, score = score }
			end

			table.sort(v4, function(a, b)
				if a.score == b.score then
					return a.plane < b.plane
				end

				return a.score > b.score
			end)
			local planes = {}

			for k = 1, math.min(#v4, 8) do
				planes[k] = v4[k].plane
			end

			if #planes > 0 then
				local firstCandidate = #result + 1

				for _, v5 in planes do
					result[#result + 1] = v5
				end

				pairEntries[#pairEntries + 1] = {
					pairKey = bit32.bor(bit32.lshift(i, 16), j),
					firstCandidate = firstCandidate,
					candidateCount = #planes
				}
			end

			if not (v2 > 0 and count % v2 == 0) then
				continue
			end

			if p2 and p2.onCertificateProgress then
				p2.onCertificateProgress(count, #pairEntries)
			end

			task.wait()
		end
	end

	return pairEntries, result
end

return table.freeze({
	build = function(p, p2, p3)
		local v = {}
		local v2 = {}
		local count = 0
		local minimum = createVector(1e999, 1e999, 1e999)
		local maximum = createVector(-1e999, -1e999, -1e999)

		local function includeBounds(vector: Vector3) -- 7 equivalent calls inferred from this helper
			minimum = minimum:Min(vector)
			maximum = maximum:Max(vector)
		end

		for k, part in p.parts do
			if isExactBlock(part) then -- inferred equivalent call
				count += 1
				local v3 = verticesForBlock(part)

				for _, v4 in v3 do
					includeBounds(v4) -- inferred equivalent call
				end

				for _, v4 in frozen do
					v[#v + 1] = triangleItem({
						a = v3[v4[1]],
						b = v3[v4[2]],
						c = v3[v4[3]],
						primitive = k
					})
				end

				local v4, v5, v6 = planeForBlock(part, k)
				local v7 = v2[v4]

				if v7 == nil then
					v2[v4] = v5
					v7 = v5
				end

				v7.rectangles[#v7.rectangles + 1] = v6
			else
				local v3, v4 = meshForPart(part)

				if v3 == nil or v4 == nil then
					if isCylinder(part) then -- inferred equivalent call
						count += 1
						local v5 = #v + 1
						cylinderTriangles(part, k, v)

						for i = v5, #v do
							includeBounds(v[i].minimum) -- inferred equivalent call
							includeBounds(v[i].maximum) -- inferred equivalent call
						end
					end
				else
					count += 1

					for _, v5 in v3 do
						includeBounds(v5) -- inferred equivalent call
					end

					for _, v5 in v4 do
						v[#v + 1] = triangleItem({
							a = v3[v5[1]],
							b = v3[v5[2]],
							c = v3[v5[3]],
							primitive = k
						})
					end
				end
			end
		end

		local count2 = 0
		local walkMesh

		if p3 ~= nil then
			walkMesh = p3.walkMesh
		end

		if walkMesh ~= nil then
			local primitive = #p.parts + 1
			local vertices = walkMesh.Vertices

			for _, triangle in walkMesh.Triangles do
				local v3 = vertices[triangle.A]
				local v4 = vertices[triangle.B]
				local v5 = vertices[triangle.C]

				if not (v3 ~= nil and v4 ~= nil and v5 ~= nil) then
					continue
				end

				includeBounds(v3) -- inferred equivalent call
				includeBounds(v4) -- inferred equivalent call
				includeBounds(v5) -- inferred equivalent call
				v[#v + 1] = triangleItem({ a = v3, b = v4, c = v5, primitive = primitive })
				count2 += 1
			end
		end

		local v3 = {
			inputPrimitives = #p.parts,
			trianglePrimitives = count,
			omittedPrimitives = #p.parts - count,
			triangles = #v,
			walkMeshTriangles = count2,
			nodes = 0,
			leaves = 0,
			planes = 0,
			rectangles = 0,
			encodedBytes = 0,
			certificates = 0,
			candidates = 0
		}

		if #v == 0 then
			return nil, v3, "NoExactBlockPrimitives"
		end

		local bvh, leaves, triangles, rootNode = buildBVH(v)
		local v4 = {}

		for k in v2 do
			v4[#v4 + 1] = k
		end

		table.sort(v4)
		local rectangles = {}
		local planes = {}

		for _, v5 in v4 do
			local v6 = v2[v5]
			table.sort(v6.rectangles, function(a, b)
				if a.minimumU ~= b.minimumU then
					return a.minimumU < b.minimumU
				end

				if a.minimumV == b.minimumV then
					return a.primitive < b.primitive
				end

				return a.minimumV < b.minimumV
			end)
			local firstRectangle = #rectangles + 1

			for _, rectangle in v6.rectangles do
				rectangles[#rectangles + 1] = rectangle
			end

			planes[#planes + 1] = {
				origin = v6.origin,
				u = v6.u,
				v = v6.v,
				normal = v6.normal,
				firstRectangle = firstRectangle,
				rectangleCount = #v6.rectangles
			}
		end

		local worldBounds = { minimum = minimum, maximum = maximum }
		local certificates, candidates = buildCertificates(planes, rectangles, p2, p3)
		local encoded = StaticOcclusionCodec.encode({
			fingerprint = p.fingerprint,
			worldBounds = worldBounds,
			rootNode = rootNode,
			nodes = bvh,
			leaves = leaves,
			triangles = triangles,
			planes = planes,
			rectangles = rectangles,
			certificates = certificates,
			candidates = candidates
		})
		v3.triangles = #triangles
		v3.nodes = #bvh
		v3.leaves = #leaves
		v3.planes = #planes
		v3.rectangles = #rectangles
		v3.encodedBytes = #encoded
		v3.certificates = #certificates
		v3.candidates = #candidates
		return encoded, v3, nil
	end
})