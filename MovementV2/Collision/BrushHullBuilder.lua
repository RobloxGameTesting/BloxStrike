local createVector = vector.create
local CollectionService = game:GetService("CollectionService")
local QuickHull = require(script.Parent.QuickHull)
local HullPoints = require(script.Parent.HullPoints)
local CanonicalGeometry = require(script.Parent.CanonicalGeometry)
local object = setmetatable({}, { __mode = "k" })
local object2 = setmetatable({}, { __mode = "k" })
local v = {
	Get = function(p)
		local v = object[p]

		if v ~= nil then
			return v
		end

		local published, v2 = CanonicalGeometry.ReadPublished(p)
		assert(published ~= nil, v2)
		local v3 = { CFrame = published.CFrame, Size = published.Size }
		object[p] = v3
		return v3
	end
}

function v.GetCFrame(p)
	return v.Get(p).CFrame
end

local v2 = {
	createVector(0.5, 0.5, 0.5),
	createVector(0.5, 0.5, -0.5),
	createVector(-0.5, 0.5, 0.5),
	createVector(-0.5, 0.5, -0.5),
	createVector(0.5, -0.5, 0.5),
	createVector(0.5, -0.5, -0.5),
	createVector(-0.5, -0.5, 0.5),
	createVector(-0.5, -0.5, -0.5)
}
local v3 = {
	createVector(0.5, -0.5, -0.5),
	createVector(-0.5, -0.5, -0.5),
	createVector(0.5, -0.5, 0.5),
	createVector(-0.5, -0.5, 0.5),
	createVector(0.5, 0.5, 0.5),
	createVector(-0.5, 0.5, 0.5)
}
local v4 = {
	createVector(0.5, 0.5, -0.5),
	createVector(0.5, -0.5, 0.5),
	createVector(-0.5, -0.5, 0.5),
	createVector(0.5, -0.5, -0.5),
	createVector(-0.5, -0.5, -0.5)
}

local function quantizeVectorKey(vector: Vector3) -- 1 equivalent call inferred from this helper
	return string.format(
		"%d|%d|%d",
		math.round(vector.X * 10000),
		math.round(vector.Y * 10000),
		(math.round(vector.Z * 10000))
	)
end

local function findShapeForInstance(instance)
	if instance:IsA("WedgePart") then
		return Enum.PartType.Wedge
	end

	if instance:IsA("CornerWedgePart") then
		return Enum.PartType.CornerWedge
	end

	if instance:IsA("Part") then
		return instance.Shape
	end

	return Enum.PartType.Block
end

local function isClimbableInstance(instance)
	return instance:GetAttribute("Climbable") == true or CollectionService:HasTag(instance, "Ladder")
end

local function getSurfaceFriction(_)
	return 1
end

local function isMergeEligibleShape(p)
	return p == Enum.PartType.Block or p == Enum.PartType.Wedge or p == Enum.PartType.CornerWedge
end

local function getCylinderCollisionRadius(vector: Vector3) -- 1 equivalent call inferred from this helper
	return math.min(vector.Y, vector.Z) * 0.5
end

local function generateLocalPointsForPrimitive(instance, vector: Vector3)
	local v5 = HullPoints.Read(instance)

	if v5 ~= nil then
		return v5
	end

	local shapeForInstance = findShapeForInstance(instance)

	if shapeForInstance == Enum.PartType.Wedge then
		local result = {}

		for _, v6 in ipairs(v3) do
			table.insert(result, v6 * vector)
		end

		return result
	elseif shapeForInstance == Enum.PartType.CornerWedge then
		local result = {}

		for _, v6 in ipairs(v4) do
			table.insert(result, v6 * vector)
		end

		return result
	elseif shapeForInstance == Enum.PartType.Cylinder then
		local v6 = vector.X * 0.5
		local cylinderCollisionRadius = getCylinderCollisionRadius(vector) -- inferred equivalent call
		local v7 = instance:GetAttribute("PreciseMovementCylinder") == true and 32 or 12
		local vectors = {}

		for i = 0, v7 - 1 do
			local v8 = i / v7 * 3.141592653589793 * 2
			local v9 = math.cos(v8) * cylinderCollisionRadius
			local v10 = math.sin(v8) * cylinderCollisionRadius
			table.insert(vectors, (Vector3.new(-v6, v9, v10)))
			table.insert(vectors, (Vector3.new(v6, v9, v10)))
		end

		return vectors
	elseif shapeForInstance == Enum.PartType.Ball then
		local v6 = math.min(vector.X, vector.Y, vector.Z) * 0.5
		local vectors = {
			Vector3.new(v6, 0, 0),
			Vector3.new(-v6, 0, 0),
			Vector3.new(0, v6, 0),
			Vector3.new(0, -v6, 0),
			Vector3.new(0, 0, v6),
			(Vector3.new(0, 0, -v6))
		}

		for i = 1, 8 do
			local v7 = i / 9 * 3.141592653589793
			local v8 = math.sin(v7) * v6
			local v9 = math.cos(v7) * v6

			for j = 0, 15 do
				local v10 = j / 16 * 3.141592653589793 * 2
				local v11 = math.cos(v10) * v8
				local v12 = math.sin(v10) * v8
				table.insert(vectors, (Vector3.new(v9, v11, v12)))
				table.insert(vectors, (Vector3.new(-v9, v11, v12)))
			end
		end

		return vectors
	else
		local result = {}

		for _, v6 in ipairs(v2) do
			table.insert(result, v6 * vector)
		end

		return result
	end
end

local function addUniquePoint(list, p, vector: Vector3)
	local v5 = math.round(vector.Y * 10000)
	local v6 = math.round(vector.Z * 10000)

	if math.abs(v5) >= 67108864 or math.abs(v6) >= 67108864 then
		local v7 = quantizeVectorKey(vector) -- inferred equivalent call

		if p[v7] then
			return
		end

		p[v7] = true
		table.insert(list, vector)
	else
		local v7 = math.round(vector.X * 10000)
		local v8 = p[v7]

		if v8 == nil then
			v8 = {}
			p[v7] = v8
		end

		local v9 = v5 * 134217728 + v6

		if v8[v9] then
			return
		end

		v8[v9] = true
		table.insert(list, vector)
	end
end

local function buildExpandedPoints(p, cframe: CFrame, size: Vector3, vector: Vector3)
	local v5 = generateLocalPointsForPrimitive(p, size)
	local v6 = {}
	local v7 = {}

	for _, v8 in ipairs(v5) do
		local pointToWorldSpace = cframe:PointToWorldSpace(v8)

		for _, v9 in ipairs(v2) do
			addUniquePoint(v6, v7, pointToWorldSpace + v9 * vector)
		end
	end

	return v6
end

local function buildExpandedPointsForInstances(list, vector: Vector3)
	local v5 = {}
	local v6 = {}

	for _, v7 in ipairs(list) do
		local v8 = v.Get(v7)
		local v9 = generateLocalPointsForPrimitive(v7, v8.Size)

		for _, v10 in ipairs(v9) do
			local pointToWorldSpace = v8.CFrame:PointToWorldSpace(v10)

			for _, v11 in ipairs(v2) do
				addUniquePoint(v5, v6, pointToWorldSpace + v11 * vector)
			end
		end
	end

	return v5
end

local function buildWorldPointsForInstances(list)
	local v5 = {}
	local v6 = {}

	for _, v7 in ipairs(list) do
		local v8 = v.Get(v7)
		local v9 = generateLocalPointsForPrimitive(v7, v8.Size)

		for _, v10 in ipairs(v9) do
			addUniquePoint(v5, v6, v8.CFrame:PointToWorldSpace(v10))
		end
	end

	return v5
end

local function buildWorldPointsFromLocalPoints(cframe: CFrame, list)
	local result = table.create(#list)

	for i, v5 in ipairs(list) do
		result[i] = cframe:PointToWorldSpace(v5)
	end

	return result
end

local function findPointBounds(list)
	local vector = createVector(1e999, 1e999, 1e999)
	local vector2 = createVector(-1e999, -1e999, -1e999)

	for _, v5 in ipairs(list) do
		vector = Vector3.new(math.min(vector.X, v5.X), math.min(vector.Y, v5.Y), (math.min(vector.Z, v5.Z)))
		vector2 = Vector3.new(math.max(vector2.X, v5.X), math.max(vector2.Y, v5.Y), (math.max(vector2.Z, v5.Z)))
	end

	return vector, vector2
end

local function buildWorldAabb(cframe: CFrame, size: Vector3)
	local vector = createVector(1e999, 1e999, 1e999)
	local vector2 = createVector(-1e999, -1e999, -1e999)

	for _, v5 in ipairs(v2) do
		local pointToWorldSpace = cframe:PointToWorldSpace(v5 * size)
		vector = Vector3.new(
			math.min(vector.X, pointToWorldSpace.X),
			math.min(vector.Y, pointToWorldSpace.Y),
			(math.min(vector.Z, pointToWorldSpace.Z))
		)
		vector2 = Vector3.new(
			math.max(vector2.X, pointToWorldSpace.X),
			math.max(vector2.Y, pointToWorldSpace.Y),
			(math.max(vector2.Z, pointToWorldSpace.Z))
		)
	end

	return vector, vector2
end

local function buildWorldAabbCornerPoints(vector: Vector3, vector2: Vector3)
	return {
		Vector3.new(vector.X, vector.Y, vector.Z),
		Vector3.new(vector.X, vector.Y, vector2.Z),
		Vector3.new(vector.X, vector2.Y, vector.Z),
		Vector3.new(vector.X, vector2.Y, vector2.Z),
		Vector3.new(vector2.X, vector.Y, vector.Z),
		Vector3.new(vector2.X, vector.Y, vector2.Z),
		Vector3.new(vector2.X, vector2.Y, vector.Z),
		(Vector3.new(vector2.X, vector2.Y, vector2.Z))
	}
end

local function planeMatches(p, vector: Vector3, p2: number) -- 1 equivalent call inferred from this helper
	return (p.n - vector).Magnitude <= 0.001 and math.abs(p.ed - p2) <= 0.001
end

local function addPlane(list, unit: Vector3, ed: number, planeNum: number, minkowskiPlaneKind: string?)
	for _, v5 in ipairs(list) do
		if planeMatches(v5, unit, ed) then -- inferred equivalent call
			return false
		end
	end

	table.insert(list, {
		n = unit,
		ed = ed,
		planeNum = planeNum,
		minkowskiPlaneKind = minkowskiPlaneKind
	})
	return true
end

local function buildAabbPlanes(p, count: number)
	local pointBounds, v5 = findPointBounds(p)
	local v6 = {}

	local function pushPlane(vector: Vector3, ed: number)
		count += 1
		table.insert(v6, { n = vector, ed = ed, planeNum = count })
	end

	local x = v5.X
	count += 1
	table.insert(v6, { n = createVector(1, 0, 0), ed = x, planeNum = count })
	local ed = -pointBounds.X
	count += 1
	table.insert(v6, { n = createVector(-1, -0, -0), ed = ed, planeNum = count })
	local y = v5.Y
	count += 1
	table.insert(v6, { n = createVector(0, 1, 0), ed = y, planeNum = count })
	local ed2 = -pointBounds.Y
	count += 1
	table.insert(v6, { n = createVector(-0, -1, -0), ed = ed2, planeNum = count })
	local z = v5.Z
	count += 1
	table.insert(v6, { n = createVector(0, 0, 1), ed = z, planeNum = count })
	local ed3 = -pointBounds.Z
	count += 1
	table.insert(v6, { n = createVector(-0, -0, -1), ed = ed3, planeNum = count })
	return v6, count
end

local function buildPlanesForPoints(expandedPoints, planeNum: number)
	assert(#expandedPoints >= 4, "A convex movement hull requires at least four points")
	local hull = QuickHull.GenerateHull(expandedPoints)
	assert(#hull > 0, "QuickHull returned no triangles")
	local v5 = {}

	for _, v6 in ipairs(hull) do
		local cross = (v6[1] - v6[2]):Cross(v6[1] - v6[3])

		if not (cross.Magnitude > 0.001) then
			continue
		end

		local unit = cross.Unit

		if not addPlane(v5, unit, v6[1]:Dot(unit), planeNum + 1) then
			continue
		end

		planeNum += 1
		v5[#v5].planeNum = planeNum
	end

	assert(#v5 > 0, "QuickHull returned no usable planes")
	return v5, planeNum
end

local function isAxisAlignedBlockPart(part, shapeForInstance, cframe: CFrame)
	if shapeForInstance ~= Enum.PartType.Block or not part:IsA("Part") then
		return false
	end

	for _, v5 in ipairs({ cframe.RightVector, cframe.UpVector, cframe.LookVector }) do
		if math.max(math.abs(v5.X), math.abs(v5.Y), (math.abs(v5.Z))) < 0.999999 then
			return false
		end
	end

	return true
end

local function rawHullRecord(buildMode: string, sourceShape: string, instance, surfaceFriction: number, hull, points, vector: Vector3, vector2: Vector3) -- 5 equivalent calls inferred from this helper
	return {
		buildMode = buildMode,
		sourceShape = sourceShape,
		sourceCFrame = instance.CFrame,
		sourceSize = instance.Size,
		surfaceFriction = surfaceFriction,
		hull = hull,
		points = points,
		aabbMin = vector,
		aabbMax = vector2
	}
end

local function buildAxisAlignedBlockHullRecord(_, instance, vector: Vector3, p: number)
	local worldAabb, v5 = buildWorldAabb(instance.CFrame, instance.Size)
	local v6 = vector * 0.5
	local aabbMin = worldAabb - v6
	local aabbMax = v5 + v6
	local aabbPlanes, v7 = buildAabbPlanes({ aabbMin, aabbMax }, p)
	local worldAabbCornerPoints = buildWorldAabbCornerPoints(aabbMin, aabbMax)
	return
		rawHullRecord( -- inferred equivalent call
			"primitiveAabbPlanes",
			Enum.PartType.Block.Name,
			instance,
			1,
			aabbPlanes,
			worldAabbCornerPoints,
			aabbMin,
			aabbMax
		),
		v7
end

local v5 = { createVector(1, 0, 0), createVector(0, 1, 0), createVector(0, 0, 1) }

local function buildOrientedBlockPlanes(cframe: CFrame, size: Vector3, vector: Vector3, count: number)
	local position = cframe.Position
	local v6 = size * 0.5
	local v7 = {
		{ direction = cframe.RightVector, halfSpan = v6.X },
		{ direction = cframe.UpVector, halfSpan = v6.Y },
		{ direction = cframe.LookVector, halfSpan = v6.Z }
	}
	local v8 = {}

	local function pushPlane(vector2: Vector3, p: number)
		if vector2.Magnitude <= p then
			return
		end

		local unit = vector2.Unit
		local v9 = unit:Dot(position) + math.abs(unit.X) * vector.X + math.abs(unit.Y) * vector.Y + math.abs(unit.Z) * vector.Z

		for _, v10 in ipairs(v7) do
			v9 += math.abs((unit:Dot(v10.direction))) * v10.halfSpan
		end

		if addPlane(v8, unit, v9, count + 1) then
			count += 1
		end
	end

	for _, v9 in ipairs(v7) do
		pushPlane(v9.direction, 0.001)
		pushPlane(-v9.direction, 0.001)
	end

	for _, v9 in ipairs(v5) do
		pushPlane(v9, 0.001)
		pushPlane(-v9, 0.001)
	end

	for _, v9 in ipairs(v7) do
		for _, v10 in ipairs(v5) do
			local cross = v9.direction:Cross(v10)
			pushPlane(cross, 0.02)
			pushPlane(-cross, 0.02)
		end
	end

	return v8, count
end

local function buildLocalFaceNormals(list)
	local hull = QuickHull.GenerateHull(list)
	local units = {}

	for _, v6 in ipairs(hull) do
		local cross = (v6[1] - v6[2]):Cross(v6[1] - v6[3])

		if not (cross.Magnitude > 0.001) then
			continue
		end

		local unit = cross.Unit
		local flag = true

		for _, v7 in ipairs(units) do
			if not ((v7 - unit).Magnitude <= 0.001) then
				continue
			end

			flag = false
			break
		end

		if flag then
			table.insert(units, unit)
		end
	end

	return units
end

local function getLocalFaceNormals(p: string, p2, list)
	local v6 = object2[p2]

	if v6 == nil then
		v6 = {}
		object2[p2] = v6
	end

	local v7 = v6[p]

	if v7 ~= nil and #v7.Points == #list then
		local flag = true

		for i, v8 in ipairs(list) do
			if v7.Points[i] == v8 then
				continue
			end

			flag = false
			break
		end

		if flag then
			return v7.Normals
		end
	end

	local localFaceNormals = buildLocalFaceNormals(list)
	v6[p] = { Points = table.clone(list), Normals = localFaceNormals }
	return localFaceNormals
end

local function buildLocalHullMinkowskiPlanes(cframe: CFrame, _, list, vector: Vector3, count: number, list2)
	local v6 = {}

	local function pushPlane(vector2: Vector3, p: number, minkowskiPlaneKind: string)
		if vector2.Magnitude <= p then
			return
		end

		local unit = vector2.Unit
		local v7 = -1e999

		for _, vector3 in ipairs(list) do
			v7 = math.max(v7, vector3:Dot(unit))
		end

		if addPlane(
			v6,
			unit,
			v7 + (math.abs(unit.X) * vector.X + math.abs(unit.Y) * vector.Y + math.abs(unit.Z) * vector.Z),
			count + 1,
			minkowskiPlaneKind
		) then
			count += 1
		end
	end

	for _, v7 in ipairs(list2) do
		pushPlane(cframe:VectorToWorldSpace(v7), 0.001, "sourceFace")
	end

	for _, v7 in ipairs(v5) do
		pushPlane(v7, 0.001, "playerAxis")
		pushPlane(-v7, 0.001, "playerAxis")
	end

	for i = 1, #list2 do
		for j = i + 1, #list2 do
			local cross = list2[i]:Cross(list2[j])

			if not (cross.Magnitude > 0.02) then
				continue
			end

			local vector2 = cframe:VectorToWorldSpace(cross.Unit)

			for _, v7 in ipairs(v5) do
				local cross2 = vector2:Cross(v7)
				pushPlane(cross2, 0.02, "edgeBevel")
				pushPlane(-cross2, 0.02, "edgeBevel")
			end
		end
	end

	return v6, count
end

local function buildLocalPrimitiveHullRecord(p, instance, shapeForInstance, vector: Vector3, p2: number, flag: boolean?)
	local v6 = generateLocalPointsForPrimitive(p, instance.Size)
	local worldPointsFromLocalPoints = buildWorldPointsFromLocalPoints(instance.CFrame, v6)
	local localHullMinkowskiPlanes, v7 = buildLocalHullMinkowskiPlanes(
		instance.CFrame,
		v6,
		worldPointsFromLocalPoints,
		vector * 0.5,
		p2,
		getLocalFaceNormals("Primitive", p, v6)
	)
	local expandedPoints = buildExpandedPoints(p, instance.CFrame, instance.Size, vector)
	local pointBounds, aabbMax = findPointBounds(expandedPoints)
	return
		rawHullRecord( -- inferred equivalent call
			flag and "authoredHullPlanes" or shapeForInstance == Enum.PartType.Cylinder and "polygonCylinderLocalHullPlanes" or "primitiveLocalHullPlanes",
			flag and "Hull" or shapeForInstance.Name,
			instance,
			1,
			localHullMinkowskiPlanes,
			expandedPoints,
			pointBounds,
			aabbMax
		),
		v7
end

local function buildOrientedBlockHullRecord(p, instance, vector: Vector3, p2: number)
	local orientedBlockPlanes, v6 = buildOrientedBlockPlanes(instance.CFrame, instance.Size, vector * 0.5, p2)
	local expandedPoints = buildExpandedPoints(p, instance.CFrame, instance.Size, vector)
	local pointBounds, aabbMax = findPointBounds(expandedPoints)
	return
		rawHullRecord( -- inferred equivalent call
			"primitiveBlockPlanes",
			Enum.PartType.Block.Name,
			instance,
			1,
			orientedBlockPlanes,
			expandedPoints,
			pointBounds,
			aabbMax
		),
		v6
end

local BrushHullBuilder = {
	BuildHullRecord = function(p, vector: Vector3, p2: number)
		local shapeForInstance = findShapeForInstance(p)
		local v6 = v.Get(p)

		if HullPoints.Read(p) ~= nil then
			return buildLocalPrimitiveHullRecord(p, v6, shapeForInstance, vector, p2, true)
		end

		if isAxisAlignedBlockPart(p, shapeForInstance, v6.CFrame) then
			return buildAxisAlignedBlockHullRecord(p, v6, vector, p2)
		end

		if shapeForInstance == Enum.PartType.Block then
			return buildOrientedBlockHullRecord(p, v6, vector, p2)
		end

		if
			shapeForInstance == Enum.PartType.Cylinder
			or shapeForInstance == Enum.PartType.Wedge
			or shapeForInstance == Enum.PartType.CornerWedge
		then
			return buildLocalPrimitiveHullRecord(p, v6, shapeForInstance, vector, p2)
		end

		local expandedPoints = buildExpandedPoints(p, v6.CFrame, v6.Size, vector)
		local planesForPoints, v7 = buildPlanesForPoints(expandedPoints, p2)
		local pointBounds, aabbMax = findPointBounds(expandedPoints)
		return
			rawHullRecord( -- inferred equivalent call
				"primitiveQuickHull",
				shapeForInstance.Name,
				v6,
				1,
				planesForPoints,
				expandedPoints,
				pointBounds,
				aabbMax
			),
			v7
	end,
	BuildMergedHullRecord = function(list, vector: Vector3, p: number)
		assert(#list >= 2, "A merged movement hull requires at least two parts")
		local v6 = list[1]
		local v7 = v.Get(v6)
		local cframe = v7.CFrame
		local worldPointsForInstances = buildWorldPointsForInstances(list)
		local v8 = table.create(#worldPointsForInstances)

		for i, worldPointsForInstance in ipairs(worldPointsForInstances) do
			v8[i] = cframe:PointToObjectSpace(worldPointsForInstance)
		end

		local localHullMinkowskiPlanes, v9 = buildLocalHullMinkowskiPlanes(
			cframe,
			v8,
			worldPointsForInstances,
			vector * 0.5,
			p,
			getLocalFaceNormals("Merged", v6, v8)
		)
		local expandedPointsForInstances = buildExpandedPointsForInstances(list, vector)
		local pointBounds, aabbMax = findPointBounds(expandedPointsForInstances)
		return
			rawHullRecord( -- inferred equivalent call
				"mergedLocalHullPlanes",
				"Merged",
				v7,
				1,
				localHullMinkowskiPlanes,
				expandedPointsForInstances,
				pointBounds,
				aabbMax
			),
			v9
	end
}

local function aabbsTouch(minPoint: Vector3, maxPoint: Vector3, minPoint2: Vector3, maxPoint2: Vector3)
	return minPoint.X <= maxPoint2.X + 0.05
		and maxPoint.X + 0.05 >= minPoint2.X
		and minPoint.Y <= maxPoint2.Y + 0.05
		and maxPoint.Y + 0.05 >= minPoint2.Y
		and minPoint.Z <= maxPoint2.Z + 0.05
		and maxPoint.Z + 0.05 >= minPoint2.Z
end

local function hasCompatibleOrientation(p, p2)
	local cframe = v.GetCFrame(p)
	local cframe2 = v.GetCFrame(p2)
	return cframe.RightVector:Dot(cframe2.RightVector) >= 0.999
		and cframe.UpVector:Dot(cframe2.UpVector) >= 0.999
		and cframe.LookVector:Dot(cframe2.LookVector) >= 0.999
end

local function componentContainsRampShape(list)
	for _, v6 in ipairs(list) do
		local shapeForInstance = findShapeForInstance(v6)

		if shapeForInstance == Enum.PartType.Wedge or shapeForInstance == Enum.PartType.CornerWedge then
			return true
		end
	end

	return false
end

local function componentIsNarrowStrip(list)
	local cframe = v.GetCFrame(list[1])
	local v6 = 1e999
	local v7 = -1e999
	local v8 = 1e999
	local v9 = -1e999
	local total = 0
	local total2 = 0

	for _, v10 in ipairs(list) do
		local v11 = v.Get(v10)
		local pointToObjectSpace = cframe:PointToObjectSpace(v11.CFrame.Position)
		v6 = math.min(v6, pointToObjectSpace.X)
		v7 = math.max(v7, pointToObjectSpace.X)
		v8 = math.min(v8, pointToObjectSpace.Z)
		v9 = math.max(v9, pointToObjectSpace.Z)
		total += v11.Size.X
		total2 += v11.Size.Z
	end

	local v10 = total / math.max(#list, 1)
	local v11 = total2 / math.max(#list, 1)
	local v12 = math.max(0.05, v10 * 0.6)
	local v13 = math.max(0.05, v11 * 0.6)
	return v7 - v6 <= v12 or v9 - v8 <= v13
end

local function getExplicitConvexGroupId(instance)
	local movementConvexGroup = instance:GetAttribute("MovementConvexGroup")

	if typeof(movementConvexGroup) == "string" and movementConvexGroup ~= "" then
		return movementConvexGroup
	end

	if typeof(movementConvexGroup) == "number" then
		return (tostring(movementConvexGroup))
	end

	return nil
end

function BrushHullBuilder.FindMergedPartGroups(list)
	local v6 = #list <= 512
	local v7 = {}
	local v8 = {}
	local v9 = {}
	local result = {}
	local v10 = {}

	for _, v11 in ipairs(list) do
		local shapeForInstance = findShapeForInstance(v11)

		if not ((shapeForInstance == Enum.PartType.Block or shapeForInstance == Enum.PartType.Wedge or shapeForInstance == Enum.PartType.CornerWedge) and v11:GetAttribute("Climbable") ~= true) then
			continue
		end

		if
			CollectionService:HasTag(v11, "Ladder")
			or v11:GetAttribute("DisableMovementSeamMerge") == true
			or HullPoints.Read(v11) ~= nil
		then
			continue
		end

		local v12 = v.Get(v11)
		local worldAabb, maxPoint = buildWorldAabb(v12.CFrame, v12.Size)
		v7[v11] = { minPoint = worldAabb, maxPoint = maxPoint }
		local movementConvexGroup = v11:GetAttribute("MovementConvexGroup")

		if typeof(movementConvexGroup) ~= "string" or movementConvexGroup == "" then
			if typeof(movementConvexGroup) == "number" then
				movementConvexGroup = tostring(movementConvexGroup)
			else
				movementConvexGroup = nil
			end
		end

		if movementConvexGroup == nil then
			local parent = v11.Parent

			if parent ~= nil and v6 then
				local v13 = v8[parent]

				if v13 == nil then
					v13 = {}
					v8[parent] = v13
				end

				v13[#v13 + 1] = v11
			end
		else
			local v13 = v9[movementConvexGroup]

			if v13 == nil then
				v13 = {}
				v9[movementConvexGroup] = v13
			end

			v13[#v13 + 1] = v11
		end
	end

	for _, list2 in pairs(v9) do
		if not (#list2 >= 2) then
			continue
		end

		result[#result + 1] = list2

		for _, v11 in ipairs(list2) do
			v10[v11] = true
		end
	end

	for _, list2 in pairs(v8) do
		local v11 = {}

		for _, v12 in ipairs(list2) do
			if v11[v12] or v10[v12] then
				continue
			end

			v11[v12] = true
			local v13 = { v12 }
			local v14 = {}

			while #v13 > 0 do
				local v15 = v13[#v13]
				v13[#v13] = nil
				v14[#v14 + 1] = v15
				local v16 = v7[v15]

				if v16 == nil then
					continue
				end

				for _, v17 in ipairs(list2) do
					if v11[v17] or v10[v17] or v17 == v15 then
						continue
					end

					local v18 = v7[v17]

					if not (v18 ~= nil and hasCompatibleOrientation(v15, v17) and aabbsTouch(
						v16.minPoint,
						v16.maxPoint,
						v18.minPoint,
						v18.maxPoint
					)) then
						continue
					end

					v11[v17] = true
					v13[#v13 + 1] = v17
				end
			end

			if not (#v14 >= 2 and #v14 <= 8 and componentContainsRampShape(v14) and componentIsNarrowStrip(v14)) then
				continue
			end

			result[#result + 1] = v14

			for _, v15 in ipairs(v14) do
				v10[v15] = true
			end
		end
	end

	return result
end

return BrushHullBuilder