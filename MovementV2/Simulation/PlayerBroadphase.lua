local Quantization = require(script.Parent.Parent.Quantization)
local Serial = require(script.Parent.Parent.Serial)
local class = {}
class.__index = class
class.DefaultCellSize = 8

local function cellCoordinate(p: number, cellSize: number) -- 6 equivalent calls inferred from this helper
	return (math.floor(p / cellSize))
end

local function removeFromCell(p, p2: number, p3: number, p4: number) -- 2 equivalent calls inferred from this helper
	local cell = p._cells[p3]

	if cell == nil then
		return
	end

	local v = cell[p4]

	if v == nil then
		return
	end

	v[p2] = nil

	if next(v) == nil then
		cell[p4] = nil

		if next(cell) == nil then
			p._cells[p3] = nil
		end
	end
end

function class.new(p: number?)
	local cellSize = p or class.DefaultCellSize
	local v = type(cellSize) == "number" and cellSize == cellSize and cellSize > 0 and cellSize < 1e999
	assert(v, "invalid player broadphase cell size")
	return (setmetatable({
		_cellSize = cellSize,
		_cells = {},
		_cellXById = {},
		_cellZById = {},
		_queryScratch = {}
	}, class))
end

function class:clear()
	table.clear(self._cells)
	table.clear(self._cellXById)
	table.clear(self._cellZById)
	table.clear(self._queryScratch)
end

function class:remove(p: number)
	local v = self._cellXById[p]
	local v2 = self._cellZById[p]

	if v == nil or v2 == nil then
		return
	end

	removeFromCell(self, p, v, v2) -- inferred equivalent call
	self._cellXById[p] = nil
	self._cellZById[p] = nil
end

function class:upsert(p: number, vector: Vector3)
	assert(Serial.isUInt32(p) and p > 0, "player broadphase ID must be a non-zero u32")
	assert(Quantization.isFiniteVector3(vector), "invalid player broadphase position")
	local v = cellCoordinate(vector.X, self._cellSize) -- inferred equivalent call
	local v2 = cellCoordinate(vector.Z, self._cellSize) -- inferred equivalent call
	local v3 = self._cellXById[p]
	local v4 = self._cellZById[p]

	if v3 == v and v4 == v2 then
		return
	end

	if v3 ~= nil and v4 ~= nil then
		removeFromCell(self, p, v3, v4) -- inferred equivalent call
	end

	local cell = self._cells[v]

	if cell == nil then
		cell = {}
		self._cells[v] = cell
	end

	local v5 = cell[v2]

	if v5 == nil then
		v5 = {}
		cell[v2] = v5
	end

	v5[p] = true
	self._cellXById[p] = v
	self._cellZById[p] = v2
end

function class:query(vector: Vector3, vector2: Vector3, p)
	assert(Quantization.isFiniteVector3(vector) and Quantization.isFiniteVector3(vector2), "invalid query bounds")
	local v = vector.X <= vector2.X and vector.Z <= vector2.Z
	assert(v, "inverted player broadphase bounds")
	local result = p or self._queryScratch
	table.clear(result)
	local v2 = cellCoordinate(vector.X, self._cellSize) -- inferred equivalent call
	local v3 = cellCoordinate(vector2.X, self._cellSize) -- inferred equivalent call
	local v4 = cellCoordinate(vector.Z, self._cellSize) -- inferred equivalent call
	local v5 = cellCoordinate(vector2.Z, self._cellSize) -- inferred equivalent call

	for i = v2, v3 do
		local cell = self._cells[i]

		if cell == nil then
			continue
		end

		for j = v4, v5 do
			local v6 = cell[j]

			if v6 == nil then
				continue
			end

			for k in v6 do
				result[#result + 1] = k
			end
		end
	end

	table.sort(result)
	return result
end

return table.freeze(class)