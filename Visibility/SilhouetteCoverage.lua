--!native
local createVector = vector.create
require(script.Parent.StaticOcclusionRuntime)
local class = {}
class.__index = class

local function spanMask(p: number, p2: number) -- 2 equivalent calls inferred from this helper
	return bit32.lshift(1, p2 + 1) - bit32.lshift(1, p)
end

local function projectFrame(state, origin: Vector3, list, p: number)
	local vector2 = createVector(0, 0, 0)

	for i = 1, p do
		vector2 += list[i]
	end

	local vector3 = vector2 / p - origin

	if vector3.Magnitude <= 0.05 then
		return false
	end

	local unit = vector3.Unit
	local cross = unit:Cross(createVector(0, 1, 0))

	if cross.Magnitude < 0.0001 then
		cross = unit:Cross(createVector(1, 0, 0))
	end

	local unit2 = cross.Unit
	local cross2 = unit2:Cross(unit)
	local minNearest = 1e999
	local minX = 1e999
	local v = -1e999
	local minY = 1e999
	local v2 = -1e999

	for i = 1, p do
		local vector4 = list[i] - origin
		local v3 = vector.dot(vector4, unit)

		if v3 - 0.75 <= 0.05 then
			return false
		end

		minNearest = math.min(minNearest, v3 - 0.75)
		local v4 = vector.dot(vector4, unit2) / v3
		local v5 = vector.dot(vector4, cross2) / v3
		local v6 = 0.75 / (v3 - 0.75)
		minX = math.min(minX, v4 - v6)
		v = math.max(v, v4 + v6)
		minY = math.min(minY, v5 - v6)
		v2 = math.max(v2, v5 + v6)
	end

	state.Origin = origin
	state.Forward = unit
	state.Right = unit2
	state.Up = cross2
	state.MinX = minX
	state.MinY = minY
	state.StepX = (v - minX) / 16
	state.StepY = (v2 - minY) / 16
	state.MinNearest = minNearest
	return true
end

local function fillWindow(state)
	local pending = state.Pending
	local rowDepth = state.RowDepth

	for i = 1, 16 do
		pending[i] = 65535
		rowDepth[i] = state.MinNearest
	end

	state.PendingRows = 16
	state.FarDepth = state.MinNearest
end

local function fillSilhouette(state, list, p: number)
	local origin = state.Origin
	local forward = state.Forward
	local right = state.Right
	local up = state.Up
	local minX = state.MinX
	local minY = state.MinY
	local stepX = state.StepX
	local stepY = state.StepY
	local pending = state.Pending
	local rowDepth = state.RowDepth
	pending[1] = 0
	rowDepth[1] = 1e999
	pending[2] = 0
	rowDepth[2] = 1e999
	pending[3] = 0
	rowDepth[3] = 1e999
	pending[4] = 0
	rowDepth[4] = 1e999
	pending[5] = 0
	rowDepth[5] = 1e999
	pending[6] = 0
	rowDepth[6] = 1e999
	pending[7] = 0
	rowDepth[7] = 1e999
	pending[8] = 0
	rowDepth[8] = 1e999
	pending[9] = 0
	rowDepth[9] = 1e999
	pending[10] = 0
	rowDepth[10] = 1e999
	pending[11] = 0
	rowDepth[11] = 1e999
	pending[12] = 0
	rowDepth[12] = 1e999
	pending[13] = 0
	rowDepth[13] = 1e999
	pending[14] = 0
	rowDepth[14] = 1e999
	pending[15] = 0
	rowDepth[15] = 1e999
	pending[16] = 0
	rowDepth[16] = 1e999

	for i = 1, p do
		local vector2 = list[i] - origin
		local v = vector.dot(vector2, forward)
		local v2 = vector.dot(vector2, right) / v
		local v3 = vector.dot(vector2, up) / v
		local v4 = 0.75 / (v - 0.75)
		local v5 = v - 0.75

		for j = math.clamp(math.ceil((v3 - v4 - minY) / stepY - 0.5), 0, 15), math.clamp(
			math.floor((v3 + v4 - minY) / stepY - 0.5),
			0,
			15
		) do
			local v6 = minY + (j + 0.5) * stepY - v3
			local v7 = v4 * v4 - v6 * v6

			if v7 < 0 then
				continue
			end

			local v8 = math.sqrt(v7)
			local v9 = math.max(math.ceil((v2 - v8 - minX) / stepX - 0.5), 0)
			local v10 = math.min(math.floor((v2 + v8 - minX) / stepX - 0.5), 15)

			if not (v9 <= v10) then
				continue
			end

			pending[j + 1] = bit32.bor(pending[j + 1], spanMask(v9, v10)) -- inferred equivalent call
			rowDepth[j + 1] = math.min(rowDepth[j + 1], v5)
		end

		local v6 = math.clamp(math.floor((v2 - minX) / stepX), 0, 15)
		local v7 = math.clamp(math.floor((v3 - minY) / stepY), 0, 15) + 1
		pending[v7] = bit32.bor(pending[v7], (bit32.lshift(1, v6)))
		rowDepth[v7] = math.min(rowDepth[v7], v5)
	end

	local count = 0
	local farDepth = 0

	for i = 1, 16 do
		if pending[i] == 0 then
			continue
		end

		count += 1
		farDepth = math.max(farDepth, rowDepth[i])
	end

	state.PendingRows = count
	state.FarDepth = farDepth
end

local function rasterTriangle(state, triangleVertices: Vector3, vector2: Vector3, vector3: Vector3)
	local origin = state.Origin
	local forward = state.Forward
	local vector4 = triangleVertices - origin
	local vector5 = vector2 - origin
	local vector6 = vector3 - origin
	local v = vector.dot(vector4, forward)
	local v2 = vector.dot(vector5, forward)
	local v3 = vector.dot(vector6, forward)
	local v4 = v >= 0.05
	local v5 = v2 >= 0.05
	local v6 = v3 >= 0.05

	if not (v4 or v5 or v6) then
		return false
	end

	local right = state.Right
	local up = state.Up
	local clipX = state.ClipX
	local clipY = state.ClipY
	local clipW = state.ClipW
	local count = 0

	if v4 then
		count += 1
		clipX[count] = vector.dot(vector4, right) / v
		clipY[count] = vector.dot(vector4, up) / v
		clipW[count] = 1 / v
	end

	if v4 ~= v5 then
		local v7 = (0.05 - v) / (v2 - v)
		local vector7 = vector4 + (vector2 - triangleVertices) * v7
		count += 1
		clipX[count] = vector.dot(vector7, right) / 0.05
		clipY[count] = vector.dot(vector7, up) / 0.05
		clipW[count] = 20
	end

	if v5 then
		count += 1
		clipX[count] = vector.dot(vector5, right) / v2
		clipY[count] = vector.dot(vector5, up) / v2
		clipW[count] = 1 / v2
	end

	if v5 ~= v6 then
		local v7 = (0.05 - v2) / (v3 - v2)
		local vector7 = vector5 + (vector3 - vector2) * v7
		count += 1
		clipX[count] = vector.dot(vector7, right) / 0.05
		clipY[count] = vector.dot(vector7, up) / 0.05
		clipW[count] = 20
	end

	if v6 then
		count += 1
		clipX[count] = vector.dot(vector6, right) / v3
		clipY[count] = vector.dot(vector6, up) / v3
		clipW[count] = 1 / v3
	end

	if v6 ~= v4 then
		local v7 = (0.05 - v3) / (v - v3)
		local vector7 = vector6 + (triangleVertices - vector3) * v7
		count += 1
		clipX[count] = vector.dot(vector7, right) / 0.05
		clipY[count] = vector.dot(vector7, up) / 0.05
		clipW[count] = 20
	end

	local v7 = clipX[1]
	local v8 = clipY[1]
	local v9 = clipW[1]
	local v10 = clipX[2]
	local v11 = clipY[2]
	local v12 = clipX[3]
	local v13 = clipY[3]
	local v14 = count == 4
	local v15, v16

	if v14 then
		v15 = clipX[4]
		v16 = clipY[4]
	else
		v16 = v8
		v15 = v7
	end

	local minX = state.MinX
	local minY = state.MinY
	local stepX = state.StepX
	local stepY = state.StepY
	local v17 = stepX * 0.0001
	local v18 = math.min(v7, v10, v12, v15)
	local v19 = math.max(v7, v10, v12, v15)
	local v20 = math.min(v8, v11, v13, v16)
	local v21 = math.max(v8, v11, v13, v16)
	local v22 = v18 - 2 * v17
	local v23 = v19 + 2 * v17

	if math.floor((v23 - minX) / stepX - 0.5) < 0 or math.ceil((v22 - minX) / stepX - 0.5) > 15 then
		return false
	end

	local v24 = math.max(math.ceil((v20 - minY) / stepY - 0.5), 0)
	local v25 = math.min(math.floor((v21 - minY) / stepY - 0.5), 15)
	local pending = state.Pending
	local rowDepth = state.RowDepth

	while v24 <= v25 and pending[v24 + 1] == 0 do
		v24 += 1
	end

	while v24 <= v25 and pending[v25 + 1] == 0 do
		v25 -= 1
	end

	if v25 < v24 then
		return false
	end

	local v26 = (v10 - v7) * (v13 - v8) - (v12 - v7) * (v11 - v8)
	local v27 = clipW[2]
	local v28 = clipW[3]
	local v29, v30, v31, v32

	if v14 then
		local v33 = (v12 - v7) * (v16 - v8) - (v15 - v7) * (v13 - v8)

		if math.abs(v33) > math.abs(v26) then
			v27 = clipW[3]
			v28 = clipW[4]
			v29 = v16
			v30 = v15
			v31 = v13
			v32 = v12
			v26 = v33
		else
			v29 = v13
			v30 = v12
			v31 = v11
			v32 = v10
		end
	else
		v29 = v13
		v30 = v12
		v31 = v11
		v32 = v10
	end

	if math.abs(v26) < 1e-12 then
		return false
	end

	local v33 = v32 - v7
	local v34 = v31 - v8
	local v35 = v27 - v9
	local v36 = v30 - v7
	local v37 = v29 - v8
	local v38 = v28 - v9
	local v39 = (v35 * v37 - v38 * v34) / v26
	local v40 = (v33 * v38 - v36 * v35) / v26
	local v41 = v9 - v39 * v7 - v40 * v8

	if (v41 + math.max(v39 * v22, v39 * v23) + math.max(v40 * v20, v40 * v21)) * (state.FarDepth - 0.02) < 0.9999999 then
		return false
	end

	local v42

	if v14 then
		v42 = v15
	else
		v42 = v7
	end

	local v43

	if v14 then
		v43 = v16
	else
		v43 = v8
	end

	local v44 = math.min(v8, v11)
	local v45 = math.max(v8, v11)
	local v46 = v10 - v7
	local v47 = v11 - v8
	local v48 = math.min(v11, v13)
	local v49 = math.max(v11, v13)
	local v50 = v12 - v10
	local v51 = v13 - v11
	local v52 = math.min(v13, v43)
	local v53 = math.max(v13, v43)
	local v54 = v42 - v12
	local v55 = v43 - v13
	local v56 = v7 - v15
	local v57 = v8 - v16
	local v58, v59

	if v14 then
		v58 = math.min(v16, v8)
		v59 = math.max(v16, v8)
	else
		v58 = 1e999
		v59 = -1e999
	end

	local v60 = false

	for i = v24, v25 do
		local v61 = pending[i + 1]

		if v61 == 0 then
			continue
		end

		local v62 = minY + (i + 0.5) * stepY
		local v63 = 1e999
		local v64 = -1e999

		if v44 <= v62 and v62 <= v45 then
			if v47 == 0 then
				v63 = math.min(v63, v7, v10)
				v64 = math.max(v64, v7, v10)
			else
				local v65 = v7 + (v62 - v8) / v47 * v46
				v63 = math.min(v63, v65)
				v64 = math.max(v64, v65)
			end
		end

		if v48 <= v62 and v62 <= v49 then
			if v51 == 0 then
				v63 = math.min(v63, v10, v12)
				v64 = math.max(v64, v10, v12)
			else
				local v65 = v10 + (v62 - v11) / v51 * v50
				v63 = math.min(v63, v65)
				v64 = math.max(v64, v65)
			end
		end

		if v52 <= v62 and v62 <= v53 then
			if v55 == 0 then
				v63 = math.min(v63, v12, v42)
				v64 = math.max(v64, v12, v42)
			else
				local v65 = v12 + (v62 - v13) / v55 * v54
				v63 = math.min(v63, v65)
				v64 = math.max(v64, v65)
			end
		end

		if v58 <= v62 and v62 <= v59 then
			if v57 == 0 then
				v63 = math.min(v63, v15, v7)
				v64 = math.max(v64, v15, v7)
			else
				local v65 = v15 + (v62 - v16) / v57 * v56
				v63 = math.min(v63, v65)
				v64 = math.max(v64, v65)
			end
		end

		if v64 < v63 then
			continue
		end

		local v65 = v63 - v17
		local v66 = v64 + v17
		local v67 = 1 / (rowDepth[i + 1] - 0.02)
		local v68 = v40 * v62 + v41

		if math.abs(v39) < 1e-12 then
			if v68 <= v67 then
				continue
			end
		elseif v39 > 0 then
			v65 = math.max(v65, (v67 - v68) / v39)
		else
			v66 = math.min(v66, (v67 - v68) / v39)
		end

		local v69 = math.max(math.ceil((v65 - minX) / stepX - 0.5), 0)
		local v70 = math.min(math.floor((v66 - minX) / stepX - 0.5), 15)

		if v70 < v69 then
			continue
		end

		local v71 = bit32.band(v61, spanMask(v69, v70)) -- inferred equivalent call

		if v71 == 0 then
			continue
		end

		local v72 = v61 - v71
		pending[i + 1] = v72

		if v72 == 0 then
			state.PendingRows -= 1
		end

		v60 = true
	end

	return v60
end

local function sameList(list, list2)
	if #list ~= #list2 then
		return false
	end

	for k, v in list do
		if list2[k] ~= v then
			return false
		end
	end

	return true
end

local function proved(state, list)
	local contributors = state.Contributors

	if list == nil then
		return true, table.clone(contributors)
	end

	local flag

	if #contributors == #list then
		local flag2 = true

		for k, contributor in contributors do
			if list[k] == contributor then
				continue
			end

			flag = false
			flag2 = false
			break
		end

		if flag2 then
			flag = true
		end
	else
		flag = false
	end

	if flag then
		return true, list
	end

	return true, table.clone(contributors)
end

function class.new()
	local object = setmetatable({
		Pending = table.create(16, 0),
		RowDepth = table.create(16, 0),
		PendingRows = 0,
		Contributors = table.create(96),
		Planes = table.create(4),
		ClipX = table.create(4),
		ClipY = table.create(4),
		ClipW = table.create(4),
		Origin = createVector(0, 0, 0),
		Forward = createVector(0, 0, 0),
		Right = createVector(0, 0, 0),
		Up = createVector(0, 0, 0),
		MinX = 0,
		MinY = 0,
		StepX = 0,
		StepY = 0,
		MinNearest = 0,
		FarDepth = 0,
		Marks = {},
		Stamp = 0,
		Static = nil,
		Visit = nil
	}, class)

	function object.Visit(p: number)
		if object.Marks[p] == object.Stamp then
			return false
		end

		object.Marks[p] = object.Stamp
		local triangleVertices, v, v2 = object.Static:TriangleVertices(p)

		if not rasterTriangle(object, triangleVertices, v, v2) then
			return false
		end

		local contributors = object.Contributors

		if #contributors < 96 then
			contributors[#contributors + 1] = p
		end

		return object.PendingRows == 0
	end

	return object
end

function class:OriginCovered(static, vector: Vector3, p, p2: number, list, p3: number?, p4)
	if p2 == 0 or not projectFrame(self, vector, p, p2) then
		return nil, nil
	end

	local contributors = self.Contributors
	table.clear(contributors)

	if list ~= nil and #list > 0 then
		fillWindow(self)
		self.Stamp += 1

		for _, v in list do
			if self.Marks[v] == self.Stamp then
				continue
			end

			self.Marks[v] = self.Stamp
			local triangleVertices, v2, v3 = static:TriangleVertices(v)

			if not rasterTriangle(self, triangleVertices, v2, v3) then
				continue
			end

			contributors[#contributors + 1] = v

			if self.PendingRows == 0 then
				return proved(self, list)
			end
		end

		table.clear(contributors)
	end

	fillSilhouette(self, p, p2)
	self.Stamp += 1

	for i = 1, 2 do
		local v

		if i == 1 then
			v = list
		else
			v = p4
		end

		if v == nil then
			continue
		end

		for _, v2 in v do
			if self.Marks[v2] == self.Stamp then
				continue
			end

			self.Marks[v2] = self.Stamp
			local triangleVertices, v3, v4 = static:TriangleVertices(v2)

			if not rasterTriangle(self, triangleVertices, v3, v4) then
				continue
			end

			if #contributors < 96 then
				contributors[#contributors + 1] = v2
			end

			if self.PendingRows == 0 then
				return proved(self, list)
			end
		end
	end

	local pending = self.Pending
	local rowDepth = self.RowDepth
	local v = 16
	local v2 = 0
	local v3 = 0
	local v4 = -1

	for i = 0, 15 do
		local v5 = pending[i + 1]

		if v5 == 0 then
			continue
		end

		v = math.min(v, i)
		v2 = bit32.bor(v2, v5)
		v3 = math.max(v3, rowDepth[i + 1])
		v4 = i
	end

	local v5 = bit32.countrz(v2)
	local v6 = 31 - bit32.countlz(v2)
	local forward = self.Forward
	local right = self.Right
	local up = self.Up
	local v7 = self.MinX + self.StepX * v5
	local v8 = self.MinX + self.StepX * (v6 + 1)
	local v9 = self.MinY + self.StepY * v
	local v10 = self.MinY + self.StepY * (v4 + 1)
	local planes = self.Planes
	planes[1] = right - forward * v7
	planes[2] = forward * v8 - right
	planes[3] = up - forward * v9
	planes[4] = forward * v10 - up
	self.Static = static
	local v11, v12 = static:VisitFrustumTriangles(vector, planes, forward, 0.05, v3, self.Visit, 20000, p3)
	self.Static = nil

	if v11 then
		return proved(self, nil)
	end

	if v12 then
		return false, nil
	end

	return nil, nil
end

return table.freeze(class)