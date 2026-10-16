--!native
local class = {}
class.__index = class

local function validBounds(list)
	if #list ~= 6 then
		return false
	end

	for i = 1, 6 do
		if list[i] ~= list[i] or math.abs(list[i]) == 1e999 then
			return false
		end
	end

	return list[1] <= list[4] and list[2] <= list[5] and list[3] <= list[6]
end

local function checksum(buf: buffer, p: number, callback)
	local v = 5381

	for i = p, buffer.len(buf) - 1 do
		if callback and i % 4096 == 0 then
			callback()
		end

		v = (v * 33 + buffer.readu8(buf, i)) % 4294967296
	end

	return v
end

local function triangle(data, p: number)
	local v = p >= 1 and p <= data.triangleCount
	assert(v, "invalid proof triangle")
	local result = {}

	for i = 0, 2 do
		local v2 = buffer.readu32(data.buffer, data.triangleOffset + (p - 1) * 12 + i * 4)
		local v3 = data.vertexOffset + (v2 - 1) * 12
		result[i + 1] = {
			buffer.readf32(data.buffer, v3),
			buffer.readf32(data.buffer, v3 + 4),
			(buffer.readf32(data.buffer, v3 + 8))
		}
	end

	return result
end

local function half(list)
	for i = 1, 3 do
		if not (list[1][i] == list[2][i] and list[1][i] == list[3][i]) then
			continue
		end

		local v = i % 3 + 1
		local v2 = (i + 1) % 3 + 1
		local u0 = 1e999
		local u1 = -1e999
		local v3 = 1e999
		local v4 = -1e999

		for _, v5 in list do
			u0 = math.min(u0, v5[v])
			u1 = math.max(u1, v5[v])
			v3 = math.min(v3, v5[v2])
			v4 = math.max(v4, v5[v2])
		end

		if u1 <= u0 or v4 <= v3 then
			continue
		end

		local v5 = 0

		for _, v6 in list do
			if v6[v] ~= u0 and v6[v] ~= u1 or v6[v2] ~= v3 and v6[v2] ~= v4 then
				return nil, nil
			end

			v5 = bit32.bor(v5, (bit32.lshift(1, (v6[v] == u1 and 1 or 0) + (v6[v2] == v4 and 2 or 0))))
		end

		for j = 0, 3 do
			if v5 == 15 - bit32.lshift(1, j) then
				return {
					axis = i,
					d = list[1][i],
					u0 = u0,
					u1 = u1,
					v0 = v3,
					v1 = v4
				}, j
			end
		end
	end

	return nil, nil
end

local function same(data, data2) -- 1 equivalent call inferred from this helper
	return data.axis == data2.axis
		and data.d == data2.d
		and data.u0 == data2.u0
		and data.u1 == data2.u1
		and data.v0 == data2.v0
		and data.v1 == data2.v1
end

local function join(data, data2)
	local v = data.axis == data2.axis and data.d == data2.d
	assert(v, "noncoplanar proof merge")
	local v2

	if data.v0 == data2.v0 and data.v1 == data2.v1 and data.u1 >= data2.u0 then
		v2 = data2.u1 >= data.u0
	else
		v2 = false
	end

	local v3 = data.u0 == data2.u0 and data.u1 == data2.u1 and data.v1 >= data2.v0 and data2.v1 >= data.v0
	assert(v2 or v3, "proof merge crosses a gap or nonrectangular union")
	return {
		axis = data.axis,
		d = data.d,
		u0 = math.min(data.u0, data2.u0),
		u1 = math.max(data.u1, data2.u1),
		v0 = math.min(data.v0, data2.v0),
		v1 = math.max(data.v1, data2.v1)
	}
end

function class.new(str: string, data, callback)
	assert(data.version == 3, "proofs require indexed exact geometry")
	local buf = buffer.fromstring(str)
	local v = buffer.len(buf) >= 40 and buffer.len(buf) <= 8388608 and buffer.readstring(buf, 0, 8) == "PVSPRF1\0"
	assert(v, "invalid proof header")
	assert(buffer.readu32(buf, 8) == 1, "unsupported proof version")
	local v2 = buffer.readu32(buf, 12) == buffer.readu32(data.buffer, 40)
		and buffer.readu32(buf, 16) == data.triangleCount
	assert(v2, "proof geometry mismatch")
	local v3 = buffer.readu32(buf, 20)
	local v4 = buffer.readu32(buf, 24)
	local v5 = buffer.readu32(buf, 28)
	local patchCount = buffer.readu32(buf, 32)
	local v6 = v3 >= 1 and v3 <= 512 and v4 >= 1 and v4 + v5 <= 400000 and patchCount <= v4
	assert(v6, "proof limits")
	assert(buffer.len(buf) == v3 + 40 + (v4 + v5) * 8 + patchCount * 4, "proof length mismatch")
	assert(buffer.readstring(buf, 40, v3) == data.fingerprint, "proof fingerprint mismatch")
	assert(checksum(buf, 40, callback) == buffer.readu32(buf, 36), "proof checksum mismatch")
	local v7 = table.create(v4 + v5)
	local v8 = v3 + 40

	for i = 1, v4 do
		if callback and i % 128 == 0 then
			callback()
		end

		local v9, v10 = half(triangle(data, buffer.readu32(buf, v8)))
		local v11, v12 = half(triangle(data, buffer.readu32(buf, v8 + 4)))

		if v9 then
			if v11 then
				if v10 then
					if v12 then
						v12 = same(v9, v11) and bit32.bxor(v10, v12) == 3 -- inferred equivalent call
					end
				else
					v12 = v10
				end
			else
				v12 = v11
			end
		else
			v12 = v9
		end

		assert(v12, "invalid rectangle triangle witnesses")
		v7[i] = v9
		v8 += 8
	end

	for i = v4 + 1, v4 + v5 do
		if callback and i % 512 == 0 then
			callback()
		end

		local v9 = buffer.readu32(buf, v8)
		local v10 = buffer.readu32(buf, v8 + 4)
		local v11 = v9 >= 1 and v9 < i and v10 >= 1 and v10 < i and v9 ~= v10
		assert(v11, "invalid proof DAG reference")
		v7[i] = join(v7[v9], v7[v10])
		v8 += 8
	end

	local v9 = {}
	local byAxis = { {}, {}, {} }
	local planes = {}
	local sorted = { {}, {}, {} }

	for _ = 1, patchCount do
		local v10 = buffer.readu32(buf, v8)
		v8 += 4
		local v11 = v10 >= 1 and v10 <= #v7 and not v9[v10]
		assert(v11, "invalid proof root")
		v9[v10] = true
		local v12 = v7[v10]
		local v13 = byAxis[v12.axis][v12.d]

		if not v13 then
			v13 = {
				axis = v12.axis,
				d = v12.d,
				rects = {},
				id = #planes + 1,
				u0 = v12.u0,
				u1 = v12.u1,
				v0 = v12.v0,
				v1 = v12.v1
			}
			planes[#planes + 1] = v13
			byAxis[v12.axis][v12.d] = v13
			table.insert(sorted[v12.axis], v13)
		end

		v13.rects[#v13.rects + 1] = v12
		v13.u0 = math.min(v13.u0, v12.u0)
		v13.u1 = math.max(v13.u1, v12.u1)
		v13.v0 = math.min(v13.v0, v12.v0)
		v13.v1 = math.max(v13.v1, v12.v1)
	end

	for _, v10 in planes do
		table.sort(v10.rects, function(a, b)
			return (a.u1 - a.u0) * (a.v1 - a.v0) > (b.u1 - b.u0) * (b.v1 - b.v0)
		end)
	end

	for _, list in sorted do
		table.sort(list, function(a, b)
			return a.d < b.d
		end)
	end

	return (setmetatable({
		Data = data,
		Planes = planes,
		ByAxis = byAxis,
		Sorted = sorted,
		PatchCount = patchCount,
		Tests = 0,
		Hits = 0,
		HintIds = {},
		Hints = {}
	}, class))
end

local function footprint(plane, p, p2)
	local axis = plane.axis
	local d = plane.d
	local v, v2, v3, v4, v5, v6, v7, v8

	if p[axis + 3] < d - 0.02 then
		local v9 = p2[axis]

		if d + 0.02 < v9 then
			v = math.abs(p[axis] - d)
			v2 = math.abs(p[axis + 3] - d)
			v3 = math.abs(p2[axis] - d)
			v4 = math.abs(p2[axis + 3] - d)
			v5 = math.min(v, v2) / (math.min(v, v2) + math.max(v3, v4))
			v6 = math.max(v, v2) / (math.max(v, v2) + math.min(v3, v4))
			v7 = axis % 3 + 1
			v8 = (axis + 1) % 3 + 1
			return
				math.min(p[v7] + (p2[v7] - p[v7]) * v5, p[v7] + (p2[v7] - p[v7]) * v6) - 0.02,
				math.max(p[v7 + 3] + (p2[v7 + 3] - p[v7 + 3]) * v5, p[v7 + 3] + (p2[v7 + 3] - p[v7 + 3]) * v6) + 0.02,
				math.min(p[v8] + (p2[v8] - p[v8]) * v5, p[v8] + (p2[v8] - p[v8]) * v6) - 0.02,
				math.max(p[v8 + 3] + (p2[v8 + 3] - p[v8 + 3]) * v5, p[v8 + 3] + (p2[v8 + 3] - p[v8 + 3]) * v6) + 0.02
		end
	end

	if not (p2[axis + 3] < d - 0.02) then
		return nil, nil, nil, nil
	end

	local v9 = p[axis]

	if not (d + 0.02 < v9) then
		return nil, nil, nil, nil
	end

	v = math.abs(p[axis] - d)
	v2 = math.abs(p[axis + 3] - d)
	v3 = math.abs(p2[axis] - d)
	v4 = math.abs(p2[axis + 3] - d)
	v5 = math.min(v, v2) / (math.min(v, v2) + math.max(v3, v4))
	v6 = math.max(v, v2) / (math.max(v, v2) + math.min(v3, v4))
	v7 = axis % 3 + 1
	v8 = (axis + 1) % 3 + 1
	return
		math.min(p[v7] + (p2[v7] - p[v7]) * v5, p[v7] + (p2[v7] - p[v7]) * v6) - 0.02,
		math.max(p[v7 + 3] + (p2[v7 + 3] - p[v7 + 3]) * v5, p[v7 + 3] + (p2[v7 + 3] - p[v7 + 3]) * v6) + 0.02,
		math.min(p[v8] + (p2[v8] - p[v8]) * v5, p[v8] + (p2[v8] - p[v8]) * v6) - 0.02,
		math.max(p[v8 + 3] + (p2[v8 + 3] - p[v8 + 3]) * v5, p[v8 + 3] + (p2[v8 + 3] - p[v8 + 3]) * v6) + 0.02
end

function class:Covers(p: number, p2, p3, p4: number?)
	if not (validBounds(p2) and validBounds(p3)) then
		return false
	end

	local plane = self.Planes[p]

	if not plane then
		return false
	end

	self.Tests += 1
	local v, v2, v3, v4 = footprint(plane, p2, p3)

	if
		v == nil
		or v2 == nil
		or v3 == nil
		or v4 == nil
		or v < plane.u0
		or plane.u1 < v2
		or v3 < plane.v0
		or plane.v1 < v4
	then
		return false
	end

	local v5 = {
		{ v, v2, v3, v4 }
	}

	for k, rect in plane.rects do
		if p4 and k % 16 == 1 and p4 <= os.clock() or k > 128 then
			return false
		end

		if rect.u1 < v or v2 < rect.u0 or rect.v1 < v3 or v4 < rect.v0 then
			continue
		end

		if rect.u0 <= v and v2 <= rect.u1 and rect.v0 <= v3 and v4 <= rect.v1 then
			self.Hits += 1
			return true
		end

		local v6 = {}

		for _, v7 in v5 do
			local v8 = math.max(v7[1], rect.u0)
			local v9 = math.min(v7[2], rect.u1)
			local v10 = math.max(v7[3], rect.v0)
			local v11 = math.min(v7[4], rect.v1)

			if v9 <= v8 or v11 <= v10 then
				v6[#v6 + 1] = v7
			else
				if v7[1] < v8 then
					v6[#v6 + 1] = { v7[1], v8, v7[3], v7[4] }
				end

				if v9 < v7[2] then
					v6[#v6 + 1] = { v9, v7[2], v7[3], v7[4] }
				end

				if v7[3] < v10 then
					v6[#v6 + 1] = { v8, v9, v7[3], v10 }
				end

				if v11 < v7[4] then
					v6[#v6 + 1] = { v8, v9, v11, v7[4] }
				end
			end

			if #v6 > 32 then
				return false
			end
		end

		if #v6 == 0 then
			self.Hits += 1
			return true
		else
			v5 = v6
		end
	end

	return false
end

function class:PlaneForTriangle(p: number)
	local v = (p - 1) % 2048 + 1

	if self.HintIds[v] == p then
		if self.Hints[v] == 0 then
			return nil
		end

		return self.Hints[v]
	else
		local v2 = triangle(self.Data, p)
		local id = nil

		for i = 1, 3 do
			if not (v2[1][i] == v2[2][i] and v2[1][i] == v2[3][i]) then
				continue
			end

			local v3 = self.ByAxis[i][v2[1][i]]

			if not v3 then
				continue
			end

			id = v3.id
			break
		end

		self.HintIds[v] = p
		self.Hints[v] = id or 0
		return id
	end
end

function class:Search(list, list2, list3, p: number, p2: number?, p3: number?, list4)
	local v = {}

	if p2 then
		v[p2] = true

		if list4 then
			list4[#list4 + 1] = p2
		end
	end

	local count = 0

	local function test(p4: number)
		if p3 and p3 <= os.clock() or v[p4] then
			return false
		end

		v[p4] = true

		if list4 then
			list4[#list4 + 1] = p4
		end

		count += 1
		return self:Covers(p4, list, list2, p3)
	end

	for i = p, 1, -1 do
		local planeForTriangle = self:PlaneForTriangle(list3[i])

		if not planeForTriangle then
			continue
		end

		local v2

		if p3 and p3 <= os.clock() or v[planeForTriangle] then
			v2 = false
		else
			v[planeForTriangle] = true

			if list4 then
				list4[#list4 + 1] = planeForTriangle
			end

			count += 1
			v2 = self:Covers(planeForTriangle, list, list2, p3)
		end

		if v2 then
			return planeForTriangle
		end
	end

	for i = 1, 3 do
		local v2 = math.min(list[i + 3], list2[i + 3]) + 0.02
		local v3 = math.max(list[i], list2[i]) - 0.02

		if v3 <= v2 then
			continue
		end

		local v4 = self.Sorted[i]
		local v5 = #v4 + 1
		local v6 = (v2 + v3) * 0.5
		local v7 = 1

		while v7 < v5 do
			local v8 = (v7 + v5) // 2

			if v4[v8].d < v6 then
				v7 = v8 + 1
			else
				v5 = v8
			end
		end

		local v8 = v7 - 1

		for j = 1, 16 do
			if count >= 24 then
				return nil
			end

			local v9

			if j % 2 == 1 then
				v9 = v7
			else
				v9 = v8
			end

			if j % 2 == 1 then
				v7 += 1
			else
				v8 -= 1
			end

			local v10 = v4[v9]

			if not (v10 and v2 < v10.d and v10.d < v3) then
				continue
			end

			local id = v10.id
			local v11

			if p3 and p3 <= os.clock() or v[id] then
				v11 = false
			else
				v[id] = true

				if list4 then
					list4[#list4 + 1] = id
				end

				count += 1
				v11 = self:Covers(id, list, list2, p3)
			end

			if v11 then
				return v10.id
			end
		end
	end

	return nil
end

function class:CoversOrigin(vector: Vector3, p, list, p2: number?, p3: number)
	local v = { vector.X, vector.Y, vector.Z, vector.X, vector.Y, vector.Z }

	if p2 and self:Covers(p2, v, p, p3) then
		return p2
	end

	for i = 1, math.min(#list, 8) do
		local v2 = list[i]

		if v2 ~= p2 and self:Covers(v2, v, p, p3) then
			return v2
		end
	end

	return nil
end

return table.freeze(class)