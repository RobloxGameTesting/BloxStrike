local createVector = vector.create
local class = {}
class.__index = class

function class.new(vector: Vector3, p: number)
	return (setmetatable({
		point = vector,
		index = p,
		next = nil,
		prev = nil,
		face = nil
	}, class))
end

local class2 = {}
class2.__index = class2

function class2.new()
	return (setmetatable({ head = nil, tail = nil }, class2))
end

function class2:clear()
	self.head = nil
	self.tail = nil
end

function class2:first()
	return self.head
end

function class2:isEmpty()
	return self.head == nil
end

function class2:add(p)
	if self.head then
		self.tail.next = p
	else
		self.head = p
	end

	p.prev = self.tail
	p.next = nil
	self.tail = p
end

function class2:addAll(nextNode)
	if self.head then
		self.tail.next = nextNode
	else
		self.head = nextNode
	end

	nextNode.prev = self.tail

	while nextNode.next do
		nextNode = nextNode.next
	end

	self.tail = nextNode
end

function class2:insertBefore(nextNode, p)
	p.prev = nextNode.prev
	p.next = nextNode

	if p.prev then
		p.prev.next = p
	else
		self.head = p
	end

	nextNode.prev = p
end

function class2:remove(p)
	if p.prev then
		p.prev.next = p.next
	else
		self.head = p.next
	end

	if p.next then
		p.next.prev = p.prev
	else
		self.tail = p.prev
	end
end

function class2:removeChain(p, p2)
	if p.prev then
		p.prev.next = p2.next
	else
		self.head = p2.next
	end

	if p2.next then
		p2.next.prev = p.prev
	else
		self.tail = p.prev
	end
end

local class3 = {}
class3.__index = class3

function class3.new(vertex, face)
	return (setmetatable({
		vertex = vertex,
		face = face,
		next = nil,
		prev = nil,
		opposite = nil
	}, class3))
end

function class3:head()
	return self.vertex
end

function class3:tail()
	if self.prev then
		return self.prev.vertex
	end

	return nil
end

function class3:lengthSquared()
	local tail = self:tail()

	if not tail then
		return -1
	end

	local v = self:head().point - tail.point
	return v.X * v.X + v.Y * v.Y + v.Z * v.Z
end

function class3:setOpposite(opposite)
	self.opposite = opposite
	opposite.opposite = self
end

local class4 = {}
class4.__index = class4

function class4.new()
	return (setmetatable({
		normal = createVector(0, 0, 0),
		centroid = createVector(0, 0, 0),
		offset = 0,
		outside = nil,
		mark = 0,
		edge = nil,
		nVertices = 0,
		area = 0
	}, class4))
end

function class4.createTriangle(p, p2, p3, value: number?)
	local v = class4.new()
	local v2 = class3.new(p, v)
	local v3 = class3.new(p2, v)
	local v4 = class3.new(p3, v)
	v2.next = v3
	v3.prev = v2
	v3.next = v4
	v4.prev = v3
	v4.next = v2
	v2.prev = v4
	v.edge = v2
	v:computeNormalAndCentroid(value or 0)
	return v
end

function class4:getEdge(p: number)
	local edge = self.edge

	while p > 0 do
		edge = edge.next
		p -= 1
	end

	while p < 0 do
		edge = edge.prev
		p += 1
	end

	return edge
end

function class4:computeNormal()
	local edge = self.edge
	local nextNode = edge.next
	local nextNode2 = nextNode.next
	local vector = nextNode:head().point - edge:head().point
	self.nVertices = 2
	self.normal = createVector(0, 0, 0)

	while nextNode2 ~= edge do
		local v = nextNode2:head().point - edge:head().point
		self.normal += vector:Cross(v)
		nextNode2 = nextNode2.next
		self.nVertices += 1
		vector = v
	end

	self.area = self.normal.Magnitude

	if self.area > 0 then
		self.normal /= self.area
	else
		self.normal = createVector(0, 1, 0)
	end
end

function class4:computeNormalMinArea(p: number)
	self:computeNormal()

	if p <= self.area then
		return
	end

	local edge = self.edge
	local v = 0
	local v2 = nil

	repeat
		local lengthSquared = edge:lengthSquared()

		if v < lengthSquared then
			v = lengthSquared
			v2 = edge
		end

		edge = edge.next
	until edge == self.edge

	if not v2 or v <= 0 then
		return
	end

	local tail = v2:tail()

	if not tail then
		return
	end

	local unit = (v2:head().point - tail.point).Unit
	self.normal -= unit * self.normal:Dot(unit)

	if self.normal.Magnitude > 0 then
		self.normal = self.normal.Unit
	else
		self.normal = createVector(0, 1, 0)
	end
end

function class4:computeCentroid()
	self.centroid = createVector(0, 0, 0)
	local edge = self.edge

	repeat
		self.centroid += edge:head().point
		edge = edge.next
	until edge == self.edge

	self.centroid /= self.nVertices
end

function class4:computeNormalAndCentroid(p: number?)
	if p and p > 0 then
		self:computeNormalMinArea(p)
	else
		self:computeNormal()
	end

	self:computeCentroid()
	self.offset = self.normal:Dot(self.centroid)
end

function class4:distanceToPlane(vector: Vector3)
	return self.normal:Dot(vector) - self.offset
end

function class4:connectHalfEdges(prev, object)
	if prev.opposite.face == object.opposite.face then
		local face = object.opposite.face

		if prev == self.edge then
			self.edge = object
		end

		local v = nil
		local opposite

		if face.nVertices == 3 then
			opposite = object.opposite.prev.opposite
			face.mark = 2
			v = face
		else
			opposite = object.opposite.next

			if face.edge == opposite.prev then
				face.edge = opposite
			end

			opposite.prev = opposite.prev.prev
			opposite.prev.next = opposite
		end

		object.prev = prev.prev
		object.prev.next = object
		object:setOpposite(opposite)
		face:computeNormalAndCentroid()
		return v
	else
		prev.next = object
		object.prev = prev
		return nil
	end
end

function class4:mergeAdjacentFaces(data, list)
	local face = data.opposite.face
	table.insert(list, face)
	face.mark = 2
	local prev = data.prev
	local nextNode = data.next
	local prev2 = data.opposite.prev
	local nextNode2 = data.opposite.next

	while prev.opposite.face == face do
		prev = prev.prev
		nextNode2 = nextNode2.next
	end

	while nextNode.opposite.face == face do
		nextNode = nextNode.next
		prev2 = prev2.prev
	end

	local v = nextNode2

	while nextNode2 ~= prev2.next do
		nextNode2.face = self
		nextNode2 = nextNode2.next
	end

	self.edge = nextNode
	local v2 = self:connectHalfEdges(prev2, nextNode)

	if v2 then
		table.insert(list, v2)
	end

	local v3 = self:connectHalfEdges(prev, v)

	if v3 then
		table.insert(list, v3)
	end

	self:computeNormalAndCentroid()
	return list
end

function class4:collectIndices()
	local edge = self.edge
	local indexes = {}

	repeat
		table.insert(indexes, edge:head().index)
		edge = edge.next
	until edge == self.edge

	return indexes
end

local QuickHull = {}
QuickHull.__index = QuickHull
local v = { "X", "Y", "Z" }

local function getAxisValue(point: Vector3, i: number) -- 3 equivalent calls inferred from this helper
	if i == 1 then
		return point.X
	elseif i == 2 then
		return point.Y
	end

	return point.Z
end

local function appendArray(p, list)
	local clone = table.clone(p)

	for _, v2 in ipairs(list) do
		table.insert(clone, v2)
	end

	return clone
end

local function distancePointToLine(point: Vector3, point2: Vector3, point3: Vector3) -- 1 equivalent call inferred from this helper
	local v2 = point3 - point2

	if v2.Magnitude <= 0 then
		error("line points are identical")
	end

	return (point - point2):Cross(v2).Magnitude / v2.Magnitude
end

function QuickHull.new(list)
	assert(#list >= 4, "cannot build a simplex out of < 4 points")
	local self = setmetatable({
		tolerance = -1,
		faces = {},
		newFaces = {},
		claimed = class2.new(),
		unclaimed = class2.new(),
		vertices = {}
	}, QuickHull)

	for i, v2 in ipairs(list) do
		table.insert(self.vertices, class.new(v2, i))
	end

	return self
end

function QuickHull:addVertexToFace(outside, face)
	outside.face = face

	if face.outside then
		self.claimed:insertBefore(face.outside, outside)
	else
		self.claimed:add(outside)
	end

	face.outside = outside
end

function QuickHull:removeVertexFromFace(p, p2)
	if p == p2.outside then
		if p.next and p.next.face == p2 then
			p2.outside = p.next
		else
			p2.outside = nil
		end
	end

	self.claimed:remove(p)
end

function QuickHull:removeAllVerticesFromFace(p)
	if not p.outside then
		return nil
	end

	local outside = p.outside

	while outside.next and outside.next.face == p do
		outside = outside.next
	end

	self.claimed:removeChain(p.outside, outside)
	outside.next = nil
	return p.outside
end

function QuickHull:deleteFaceVertices(p, object)
	local v2 = self:removeAllVerticesFromFace(p)

	if not v2 then
		return
	end

	if not object then
		self.unclaimed:addAll(v2)
		return
	end

	while v2 do
		local nextNode = v2.next

		if object:distanceToPlane(v2.point) > self.tolerance then
			self:addVertexToFace(v2, object)
		else
			self.unclaimed:add(v2)
		end

		v2 = nextNode
	end
end

function QuickHull:resolveUnclaimedPoints(list)
	local first = self.unclaimed:first()

	while first do
		local nextNode = first.next
		local tolerance = self.tolerance
		local v2 = nil

		for _, v3 in ipairs(list) do
			if v3.mark ~= 0 then
				continue
			end

			local distanceToPlane = v3:distanceToPlane(first.point)

			if not (tolerance < distanceToPlane) then
				continue
			end

			if 1000 * self.tolerance < distanceToPlane then
				v2 = v3
				break
			else
				v2 = v3
				tolerance = distanceToPlane
			end
		end

		if v2 then
			self:addVertexToFace(first, v2)
		end

		first = nextNode
	end
end

function QuickHull:computeExtremes()
	local result = { self.vertices[1], self.vertices[1], self.vertices[1] }
	local result2 = { self.vertices[1], self.vertices[1], self.vertices[1] }
	local axisValues = { self.vertices[1].point.X, self.vertices[1].point.Y, self.vertices[1].point.Z }
	local axisValues2 = { self.vertices[1].point.X, self.vertices[1].point.Y, self.vertices[1].point.Z }

	for i = 2, #self.vertices do
		local v2 = self.vertices[i]

		for j, _ in ipairs(v) do
			local axisValue = getAxisValue(v2.point, j) -- inferred equivalent call

			if axisValue < axisValues[j] then
				axisValues[j] = axisValue
				result[j] = v2
			end

			if not (axisValues2[j] < axisValue) then
				continue
			end

			axisValues2[j] = axisValue
			result2[j] = v2
		end
	end

	self.tolerance = (math.max(math.abs(axisValues[1]), (math.abs(axisValues2[1]))) + math.max(
		math.abs(axisValues[2]),
		(math.abs(axisValues2[2]))
	) + math.max(math.abs(axisValues[3]), (math.abs(axisValues2[3])))) * 0.0003
	return result, result2
end

function QuickHull:createInitialSimplex()
	local extremes, v2 = self:computeExtremes()
	local v3 = 0
	local v4 = 1

	for i, _ in ipairs(v) do
		local v5 = getAxisValue(v2[i].point, i) - getAxisValue(extremes[i].point, i) -- inferred equivalent call

		if not (v3 < v5) then
			continue
		end

		v4 = i
		v3 = v5
	end

	local extreme = extremes[v4]
	local v5 = v2[v4]

	if v3 <= self.tolerance then
		return nil
	end

	local v6 = 0
	local v7 = nil

	for _, v8 in ipairs(self.vertices) do
		if not (v8 ~= extreme and v8 ~= v5) then
			continue
		end

		local v9 = distancePointToLine(v8.point, extreme.point, v5.point) -- inferred equivalent call

		if not (v6 < v9) then
			continue
		end

		v7 = v8
		v6 = v9
	end

	if not v7 or v6 <= self.tolerance then
		return nil
	end

	local cross = (extreme.point - v5.point):Cross(v5.point - v7.point)

	if cross.Magnitude <= self.tolerance then
		return nil
	end

	local unit = cross.Unit
	local dot = extreme.point:Dot(unit)
	local v8 = 0
	local v9 = nil

	for _, v10 in ipairs(self.vertices) do
		if not (v10 ~= extreme and v10 ~= v5 and v10 ~= v7) then
			continue
		end

		local v11 = math.abs(unit:Dot(v10.point) - dot)

		if not (v8 < v11) then
			continue
		end

		v9 = v10
		v8 = v11
	end

	if not v9 or v8 <= self.tolerance then
		return nil
	end

	local clone

	if v9.point:Dot(unit) - dot < 0 then
		local v10 = {
			class4.createTriangle(extreme, v5, v7),
			class4.createTriangle(v9, v5, extreme),
			class4.createTriangle(v9, v7, v5),
			class4.createTriangle(v9, extreme, v7)
		}
		clone = table.clone({})

		for _, v11 in ipairs(v10) do
			table.insert(clone, v11)
		end

		for i = 0, 2 do
			local v11 = (i + 1) % 3
			clone[i + 2]:getEdge(2):setOpposite(clone[1]:getEdge(v11))
			clone[i + 2]:getEdge(1):setOpposite(clone[v11 + 2]:getEdge(0))
		end
	else
		local v10 = {
			class4.createTriangle(extreme, v7, v5),
			class4.createTriangle(v9, extreme, v5),
			class4.createTriangle(v9, v5, v7),
			class4.createTriangle(v9, v7, extreme)
		}
		clone = table.clone({})

		for _, v11 in ipairs(v10) do
			table.insert(clone, v11)
		end

		for i = 0, 2 do
			clone[i + 2]:getEdge(2):setOpposite(clone[1]:getEdge((3 - i) % 3))
			clone[i + 2]:getEdge(0):setOpposite(clone[(i + 1) % 3 + 2]:getEdge(1))
		end
	end

	self.faces = clone

	for _, v10 in ipairs(self.vertices) do
		if not (v10 ~= extreme and v10 ~= v5 and v10 ~= v7 and v10 ~= v9) then
			continue
		end

		local tolerance = self.tolerance
		local v11 = nil

		for _, v12 in ipairs(clone) do
			local distanceToPlane = v12:distanceToPlane(v10.point)

			if not (tolerance < distanceToPlane) then
				continue
			end

			v11 = v12
			tolerance = distanceToPlane
		end

		if v11 then
			self:addVertexToFace(v10, v11)
		end
	end

	return true
end

function QuickHull:reindexFaceAndVertices()
	local faces = {}

	for _, face in ipairs(self.faces) do
		if face.mark == 0 then
			table.insert(faces, face)
		end
	end

	self.faces = faces
end

function QuickHull:collectFaces(flag: boolean?)
	local result = {}

	for _, face in ipairs(self.faces) do
		assert(face.mark == 0, "attempt to include a destroyed face in the hull")
		local indices = face:collectIndices()

		if flag then
			table.insert(result, indices)
		else
			for i = 1, #indices - 2 do
				table.insert(result, { indices[1], indices[i + 1], indices[i + 2] })
			end
		end
	end

	return result
end

function QuickHull:nextVertexToAdd()
	if self.claimed:isEmpty() then
		return nil
	end

	local face = self.claimed:first().face
	local outside = face.outside
	local v2 = 0
	local v3 = nil

	while outside and outside.face == face do
		local distanceToPlane = face:distanceToPlane(outside.point)

		if v2 < distanceToPlane then
			v3 = outside
			v2 = distanceToPlane
		end

		outside = outside.next
	end

	return v3
end

function QuickHull:computeHorizon(vector: Vector3, p, object, nexts)
	self:deleteFaceVertices(object)
	object.mark = 2
	local nextNode

	if p then
		nextNode = p.next
	else
		nextNode = object:getEdge(0)
	end

	local v2 = p or nextNode

	repeat
		local opposite = nextNode.opposite
		local face = opposite.face

		if face.mark == 0 then
			if face:distanceToPlane(vector) > self.tolerance then
				self:computeHorizon(vector, opposite, face, nexts)
			else
				table.insert(nexts, nextNode)
			end
		end

		nextNode = nextNode.next
	until nextNode == v2
end

function QuickHull:addAdjoiningFace(p, object)
	local triangle = class4.createTriangle(p, object:tail(), object:head())
	table.insert(self.faces, triangle)
	triangle:getEdge(-1):setOpposite(object.opposite)
	return triangle:getEdge(0)
end

function QuickHull:addNewFaces(p, list)
	self.newFaces = {}
	local v2 = nil
	local v3 = nil

	for _, v4 in ipairs(list) do
		local v5 = self:addAdjoiningFace(p, v4)

		if v2 then
			v5.next:setOpposite(v3)
		else
			v2 = v5
		end

		table.insert(self.newFaces, v5.face)
		v3 = v5
	end

	if v2 and v3 then
		v2.next:setOpposite(v3)
	end
end

function QuickHull:oppositeFaceDistance(p)
	return p.face:distanceToPlane(p.opposite.face.centroid)
end

function QuickHull:doAdjacentMerge(object, p: number)
	local edge = object.edge
	local count = 0
	local v2 = true

	while true do
		if object.nVertices < count then
			error("merge recursion limit exceeded")
		end

		local face = edge.opposite.face
		local v3 = false

		if p == 2 then
			v3 = self:oppositeFaceDistance(edge) > -self.tolerance
				or self:oppositeFaceDistance(edge.opposite) > self.tolerance
		elseif object.area > face.area then
			if self:oppositeFaceDistance(edge) > -self.tolerance then
				v3 = true
			elseif self:oppositeFaceDistance(edge.opposite) > -self.tolerance then
				v2 = false
			end
		elseif self:oppositeFaceDistance(edge.opposite) > -self.tolerance then
			v3 = true
		elseif self:oppositeFaceDistance(edge) > -self.tolerance then
			v2 = false
		end

		if v3 then
			local mergeAdjacentFaces = object:mergeAdjacentFaces(edge, {})

			for _, mergeAdjacentFace in ipairs(mergeAdjacentFaces) do
				self:deleteFaceVertices(mergeAdjacentFace, object)
			end

			return true
		else
			edge = edge.next
			count += 1

			if edge == object.edge then
				if not v2 then
					object.mark = 1
				end

				return false
			end
		end
	end
end

function QuickHull:addVertexToHull(p)
	local v2 = {}
	self.unclaimed:clear()
	self:removeVertexFromFace(p, p.face)
	self:computeHorizon(p.point, nil, p.face, v2)
	self:addNewFaces(p, v2)

	for _, newFace in ipairs(self.newFaces) do
		if newFace.mark == 0 then
			while self:doAdjacentMerge(newFace, 1) do

			end
		end
	end

	for _, newFace in ipairs(self.newFaces) do
		if newFace.mark ~= 1 then
			continue
		end

		newFace.mark = 0

		while self:doAdjacentMerge(newFace, 2) do

		end
	end

	self:resolveUnclaimedPoints(self.newFaces)
end

function QuickHull:build()
	if not self:createInitialSimplex() then
		return false
	end

	local vertexToAdd = self:nextVertexToAdd()

	while vertexToAdd do
		self:addVertexToHull(vertexToAdd)
		vertexToAdd = self:nextVertexToAdd()
	end

	self:reindexFaceAndVertices()
	return true
end

function QuickHull.GenerateHull(p)
	local v2 = QuickHull.new(p)

	if not v2:build() then
		return nil
	end

	local result = {}

	for _, v3 in ipairs(v2:collectFaces(false)) do
		table.insert(result, { v2.vertices[v3[1]].point, v2.vertices[v3[2]].point, v2.vertices[v3[3]].point })
	end

	return result
end

return QuickHull