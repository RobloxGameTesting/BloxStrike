--!native
local Geometry = require(script.Parent.Geometry)
local class = {}
class.__index = class

local function cellRange(vector: Vector3, vector2: Vector3, p: number) -- 2 equivalent calls inferred from this helper
	return math.floor(vector.X / p), math.floor(vector2.X / p), math.floor(vector.Z / p), (math.floor(vector2.Z / p))
end

function class.Build(list, cellSize: number, p: number, list2)
	assert(cellSize > 0, "spatial-grid cell size must be positive")
	local v = p >= 1 and p % 1 == 0
	assert(v, "invalid oversized-record threshold")
	assert(list2 == nil or #list2 == #list, "paired spatial-grid records must have equal counts")
	local oversized = {}
	local cells = {}

	for k, v2 in list do
		local aabbMin = v2.AabbMin
		local aabbMax = v2.AabbMax
		local v3

		if list2 ~= nil then
			v3 = list2[k]
		end

		if v3 ~= nil then
			aabbMin = Geometry.Min(aabbMin, v3.AabbMin)
			aabbMax = Geometry.Max(aabbMax, v3.AabbMax)
		end

		local v4, v5, v6, v7 = cellRange(aabbMin, aabbMax, cellSize) -- inferred equivalent call

		if p < (v5 - v4 + 1) * (v7 - v6 + 1) then
			oversized[#oversized + 1] = k
		else
			for i = v4, v5 do
				local v8 = cells[i]

				if v8 == nil then
					v8 = {}
					cells[i] = v8
				end

				for j = v6, v7 do
					local v9 = v8[j]

					if v9 == nil then
						v9 = {}
						v8[j] = v9
					end

					v9[#v9 + 1] = k
				end
			end
		end
	end

	for _, list3 in cells do
		for _, list4 in list3 do
			table.freeze(list4)
		end

		table.freeze(list3)
	end

	table.freeze(cells)
	table.freeze(oversized)
	return (setmetatable({ CellSize = cellSize, Cells = cells, Oversized = oversized }, class))
end

function class.QueryInto(data, vector: Vector3, vector2: Vector3, p, list, p2, p3: number, options, _)
	local v = p3 % 1 == 0 and p3 > 0
	assert(v, "spatial-grid query stamp must be a positive integer")
	local v2, v3, v4, v5 = cellRange(vector, vector2, data.CellSize) -- inferred equivalent call
	table.clear(list)
	local v6 = options or {}
	table.clear(v6)

	if #data.Oversized > 0 then
		v6[#v6 + 1] = data.Oversized
	end

	for i = v2, v3 do
		local cell = data.Cells[i]

		if cell == nil then
			continue
		end

		for j = v4, v5 do
			local v7 = cell[j]

			if v7 ~= nil then
				v6[#v6 + 1] = v7
			end
		end
	end

	local count = #v6
	local x = vector.X
	local y = vector.Y
	local z = vector.Z
	local x2 = vector2.X
	local y2 = vector2.Y
	local z2 = vector2.Z
	local count2 = 0

	if count == 1 then
		for _, v7 in v6[1] do
			local v8 = p[v7]
			local aabbMin = v8.AabbMin
			local aabbMax = v8.AabbMax

			if not (x <= aabbMax.X and aabbMin.X <= x2 and y <= aabbMax.Y and aabbMin.Y <= y2) then
				continue
			end

			if not (z <= aabbMax.Z and aabbMin.Z <= z2) then
				continue
			end

			count2 += 1
			list[count2] = v7
		end
	elseif count == 2 then
		local v7 = v6[1]
		local v8 = v6[2]
		local v9 = v7[1]
		local v10 = v8[1]
		local v11 = 1
		local v12 = 1

		while v9 ~= nil or v10 ~= nil do
			local v13

			if v10 == nil or v9 ~= nil and v9 < v10 then
				v11 += 1
				v13 = v7[v11]
			elseif v9 == nil or v10 < v9 then
				v12 += 1
				v13 = v9
				v9 = v10
				v10 = v8[v12]
			else
				v11 += 1
				v12 += 1
				v13 = v7[v11]
				v10 = v8[v12]
			end

			local v14 = p[v9]
			local aabbMin = v14.AabbMin
			local aabbMax = v14.AabbMax

			if
				x <= aabbMax.X
				and aabbMin.X <= x2
				and y <= aabbMax.Y
				and aabbMin.Y <= y2
				and z <= aabbMax.Z
				and aabbMin.Z <= z2
			then
				count2 += 1
				list[count2] = v9
			end

			v9 = v13
		end
	else
		for _, v7 in v6 do
			for _, v8 in v7 do
				if p2[v8] == p3 then
					continue
				end

				p2[v8] = p3
				local v9 = p[v8]
				local aabbMin = v9.AabbMin
				local aabbMax = v9.AabbMax

				if not (x <= aabbMax.X and aabbMin.X <= x2 and y <= aabbMax.Y and aabbMin.Y <= y2) then
					continue
				end

				if not (z <= aabbMax.Z and aabbMin.Z <= z2) then
					continue
				end

				count2 += 1
				list[count2] = v8
			end
		end

		table.sort(list)
	end
end

return table.freeze(class)