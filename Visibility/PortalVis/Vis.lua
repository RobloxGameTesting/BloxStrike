--!native
local Winding = require(script.Parent:WaitForChild("Winding"))

local function bsSet(buf, p) -- 5 equivalent calls inferred from this helper
	local v = (p - 1) // 32 * 4
	buffer.writeu32(buf, v, (bit32.bor(buffer.readu32(buf, v), (bit32.lshift(1, (p - 1) % 32)))))
end

local function bsTest(buf, p) -- 4 equivalent calls inferred from this helper
	return bit32.band(buffer.readu32(buf, (p - 1) // 32 * 4), (bit32.lshift(1, (p - 1) % 32))) ~= 0
end

local Vis = {
	bsSet = bsSet,
	bsTest = bsTest,
	bsCount = function(buf)
		local count = 0

		for i = 0, buffer.len(buf) - 4, 4 do
			local v = buffer.readu32(buf, i)

			while v ~= 0 do
				v = bit32.band(v, v - 1)
				count += 1
			end
		end

		return count
	end,
	prepare = function(items, items2, callback)
		local airLeaves = {}

		for _, item in items2 do
			if not item.air then
				continue
			end

			airLeaves[#airLeaves + 1] = item
			item.airIndex = #airLeaves
		end

		local leafPortals = {}
		local portals = {}

		for i = 1, #airLeaves do
			leafPortals[i] = {}
		end

		local function add(p, p2, nx, ny, nz, p3, w)
			local bounds, minY, minZ, maxX, maxY, maxZ = Winding.bounds(w)
			local v = {
				id = #portals + 1,
				from = p.airIndex,
				leaf = p2.airIndex,
				nx = nx,
				ny = ny,
				nz = nz,
				d = p3,
				w = w,
				minX = bounds,
				minY = minY,
				minZ = minZ,
				maxX = maxX,
				maxY = maxY,
				maxZ = maxZ,
				done = false
			}
			portals[v.id] = v
			local v2 = leafPortals[p.airIndex]
			v2[#v2 + 1] = v
		end

		for k, item in items do
			if callback ~= nil and k % 32 == 0 then
				callback()
			end

			local plane = item.plane
			add(item.front, item.back, -plane[1], -plane[2], -plane[3], -plane[4], item.w)
			add(item.back, item.front, plane[1], plane[2], plane[3], plane[4], item.w)
		end

		return {
			portals = portals,
			leafPortals = leafPortals,
			airLeaves = airLeaves,
			leafWords = (#airLeaves + 31) // 32
		}
	end
}

local function boxRange(portal, nx, ny, nz, d)
	local v

	if nx > 0 then
		v = portal.minX
	else
		v = portal.maxX
	end

	local v2 = v * nx
	local v3

	if ny > 0 then
		v3 = portal.minY
	else
		v3 = portal.maxY
	end

	local v4 = v2 + v3 * ny
	local v5

	if nz > 0 then
		v5 = portal.minZ
	else
		v5 = portal.maxZ
	end

	local v6 = v4 + v5 * nz - d
	local v7

	if nx > 0 then
		v7 = portal.maxX
	else
		v7 = portal.minX
	end

	local v8 = v7 * nx
	local v9

	if ny > 0 then
		v9 = portal.maxY
	else
		v9 = portal.minY
	end

	local v10 = v8 + v9 * ny
	local v11

	if nz > 0 then
		v11 = portal.maxZ
	else
		v11 = portal.minZ
	end

	return v6, v10 + v11 * nz - d
end

function Vis:basePortalVis(callback, value, p, callback2)
	local portals = self.portals
	local count = #portals
	local portalWords = (count + 31) // 32
	self.portalWords = portalWords

	for i = value or 1, p or count do
		local portal = portals[i]

		if callback2 ~= nil then
			callback2()
		end

		local buf = buffer.create(portalWords * 4)
		local nx = portal.nx
		local ny = portal.ny
		local nz = portal.nz
		local d = portal.d

		for k, portal2 in portals do
			if k == i then
				continue
			end

			local _, v = boxRange(portal2, nx, ny, nz, d)

			if v <= 0.05 then
				continue
			end

			local _, v2 = Winding.range(portal2.w, nx, ny, nz, d)

			if
				v2 <= 0.05
				or boxRange(portal, portal2.nx, portal2.ny, portal2.nz, portal2.d) >= -0.05
				or Winding.range(portal.w, portal2.nx, portal2.ny, portal2.nz, portal2.d) >= -0.05
			then
				continue
			end

			bsSet(buf, k) -- inferred equivalent call
		end

		portal.front = buf

		if callback ~= nil and i % 1000 == 0 then
			callback(i, count)
		end
	end
end

function Vis.simpleFlood(data, callback)
	local leafWords = data.leafWords
	local leafPortals = data.leafPortals
	local total = 0

	for k, portal in data.portals do
		if callback ~= nil and k % 8 == 0 then
			callback()
		end

		local buf = buffer.create(leafWords * 4)
		local leafs = { portal.leaf }
		local count = 0

		while #leafs > 0 do
			local v = table.remove(leafs)

			if bit32.band(buffer.readu32(buf, (v - 1) // 32 * 4), (bit32.lshift(1, (v - 1) % 32))) ~= 0 then
				continue
			end

			bsSet(buf, v) -- inferred equivalent call
			count += 1

			for _, v2 in leafPortals[v] do
				if not bsTest(portal.front, v2.id) then -- inferred equivalent call
					continue
				end

				local leaf = v2.leaf

				if bit32.band(buffer.readu32(buf, (leaf - 1) // 32 * 4), (bit32.lshift(1, (leaf - 1) % 32))) ~= 0 then
					continue
				end

				leafs[#leafs + 1] = v2.leaf
			end
		end

		portal.mightsee = buf
		portal.numMightsee = count
		total += count
	end

	return total / #data.portals
end

local function clipToSeparators(list, list2, p, p2)
	local v = #list // 3
	local v2 = #list2 // 3

	for i = 1, v do
		local v3 = i % v + 1
		local v4 = list[i * 3 - 2]
		local v5 = list[i * 3 - 1]
		local v6 = list[i * 3]
		local v7 = list[v3 * 3 - 2] - v4
		local v8 = list[v3 * 3 - 1] - v5
		local v9 = list[v3 * 3] - v6

		for j = 1, v2 do
			local v10 = list2[j * 3 - 2]
			local v11 = list2[j * 3 - 1]
			local v12 = list2[j * 3]
			local v13 = v10 - v4
			local v14 = v11 - v5
			local v15 = v12 - v6
			local v16 = v8 * v15 - v9 * v14
			local v17 = v9 * v13 - v7 * v15
			local v18 = v7 * v14 - v8 * v13
			local v19 = math.sqrt(v16 * v16 + v17 * v17 + v18 * v18)

			if v19 < 0.05 then
				continue
			end

			local v20 = v16 / v19
			local v21 = v17 / v19
			local v22 = v18 / v19
			local v23 = v10 * v20 + v11 * v21 + v12 * v22
			local flag = nil

			for k = 1, v do
				if not (k ~= i and k ~= v3) then
					continue
				end

				local v24 = list[k * 3 - 2] * v20 + list[k * 3 - 1] * v21 + list[k * 3] * v22 - v23

				if v24 < -0.05 then
					flag = false
					break
				end

				if not (v24 > 0.05) then
					continue
				end

				flag = true
				break
			end

			if flag == nil then
				continue
			end

			if flag then
				v20 = -v20
				v21 = -v21
				v22 = -v22
				v23 = -v23
			end

			local v24 = true
			local count = 0

			for k = 1, v2 do
				if k == j then
					continue
				end

				local v25 = list2[k * 3 - 2] * v20 + list2[k * 3 - 1] * v21 + list2[k * 3] * v22 - v23

				if v25 < -0.05 then
					v24 = false
					break
				elseif v25 > 0.05 then
					count += 1
				end
			end

			if not (v24 and count ~= 0) then
				continue
			end

			if p2 then
				v20 = -v20
				v21 = -v21
				v22 = -v22
				v23 = -v23
			end

			p = Winding.clip(p, v20, v21, v22, v23, 0.05)

			if p == nil then
				return nil
			end
		end
	end

	return p
end

function Vis.portalFlow(p, state, value)
	local leafWords = p.leafWords
	local leafPortals = p.leafPortals
	local buf = buffer.create(leafWords * 4)
	local v = {
		portal = state,
		source = state.w,
		pass = nil,
		nx = state.nx,
		ny = state.ny,
		nz = state.nz,
		d = state.d,
		mightsee = state.mightsee
	}
	local v2 = { portalTests = 0, portalPasses = 0, budgeted = false }
	local v3 = value or 1e999
	local function flow(leaf, data)
		bsSet(buf, leaf) -- inferred equivalent call

		if v3 < v2.portalPasses then
			v2.budgeted = true
			return
		end

		for _, portal in leafPortals[leaf] do
			if v2.budgeted then
				break
			end

			if not bsTest(data.mightsee, portal.leaf) then -- inferred equivalent call
				continue
			end

			local leafvis

			if portal.done then
				leafvis = portal.leafvis
			else
				leafvis = portal.mightsee
			end

			local buf2 = buffer.create(leafWords * 4)
			local v4 = false

			for i = 0, leafWords * 4 - 4, 4 do
				local v5 = bit32.band(buffer.readu32(data.mightsee, i), (buffer.readu32(leafvis, i)))
				buffer.writeu32(buf2, i, v5)

				if bit32.band(v5, (bit32.bnot((buffer.readu32(buf, i))))) == 0 then
					continue
				end

				v4 = true
			end

			if not v4 then
				continue
			end

			if
				portal.nx * data.nx + portal.ny * data.ny + portal.nz * data.nz < -0.9999
				and math.abs(portal.d + data.d) < 0.05
			then
				continue
			end

			v2.portalTests += 1
			local clip = Winding.clip(portal.w, v.nx, v.ny, v.nz, v.d, 0.05)

			if clip == nil then
				continue
			end

			local v5 = {
				portal = portal,
				nx = portal.nx,
				ny = portal.ny,
				nz = portal.nz,
				d = portal.d,
				mightsee = buf2
			}

			if data.pass == nil then
				v5.source = data.source
				v5.pass = clip
				v2.portalPasses += 1
				flow(portal.leaf, v5)
			else
				local clip2 = Winding.clip(clip, data.nx, data.ny, data.nz, data.d, 0.05)

				if clip2 ~= nil then
					local clip3 = Winding.clip(data.source, -portal.nx, -portal.ny, -portal.nz, -portal.d, 0.05)

					if clip3 ~= nil then
						local v6 = clipToSeparators(clip3, data.pass, clip2, false)

						if v6 ~= nil then
							local pass = clipToSeparators(data.pass, clip3, v6, true)

							if pass ~= nil then
								v5.source = clip3
								v5.pass = pass
								v2.portalPasses += 1
								flow(portal.leaf, v5)
							end
						end
					end
				end
			end
		end
	end

	flow(state.leaf, v)

	if v2.budgeted then
		buf = buffer.create(leafWords * 4)
		buffer.copy(buf, 0, state.mightsee)
	end

	state.leafvis = buf
	state.done = true
	return v2
end

function Vis.floodCells(data, items, data2, callback)
	local leafWords = data.leafWords
	local leafPortals = data.leafPortals
	local v = {}
	local v2 = {}
	local cells = {}

	for i = 1, #data.airLeaves do
		v[i] = {}
	end

	for _, item in items do
		local v3 = v[item.leaf]
		v3[#v3 + 1] = item

		if v2[item.cell] == nil then
			v2[item.cell] = {}
			cells[#cells + 1] = item.cell
		end

		local v4 = v2[item.cell]
		v4[#v4 + 1] = item
	end

	table.sort(cells)
	local shardIndex = data2.shardIndex or 1
	local shardCount = data2.shardCount or 1
	local budget = data2.budget or 1e999
	local yieldEvery = data2.yieldEvery or 0
	local yield = data2.yield
	local v3

	if data2.cells ~= nil then
		v3 = {}

		for _, cell in data2.cells do
			v3[cell] = true
		end
	end

	local function coplanar(nx, ny, nz, d, p, p2, p3, p4) -- 2 equivalent calls inferred from this helper
		return nx * p + ny * p2 + nz * p3 > 0.9999 and math.abs(d - p4) < 0.05
	end

	local result = { floods = 0, passes = 0, budgeted = 0, interior = 0 }
	local result2 = {}

	for k, v4 in cells do
		if v3 == nil then
			if (k - 1) % shardCount ~= shardIndex - 1 then
				continue
			end
		elseif not v3[v4] then
			continue
		end

		local v5 = { [v4] = true }
		local buf = buffer.create(leafWords * 4)
		local v6 = {}

		for i = 1, #data.airLeaves do
			local count = 0

			for _, v7 in v[i] do
				if v7.cell ~= v4 then
					count += 1
				end
			end

			v6[i] = count

			if count > 0 then
				bsSet(buf, i) -- inferred equivalent call
			end
		end

		local function mark(p)
			if v5[p.cell] then
				return
			end

			v5[p.cell] = true

			for i = 1, #data.airLeaves do
				local v7 = v6[i]

				if not (v7 > 0) then
					continue
				end

				local count = 0

				for _, v8 in v[i] do
					if v8.cell == p.cell then
						count += 1
					end
				end

				if not (count > 0) then
					continue
				end

				v6[i] = v7 - count

				if v7 - count ~= 0 then
					continue
				end

				local v8 = (i - 1) // 32 * 4
				buffer.writeu32(
					buf,
					v8,
					(bit32.band(buffer.readu32(buf, v8), (bit32.bnot((bit32.lshift(1, (i - 1) % 32))))))
				)
			end
		end

		local function reachable(p, data3, data4)
			for _, face in p.faces do
				local w = face.w
				local _, v7 = Winding.range(w, data4.nx, data4.ny, data4.nz, data4.d)

				if v7 <= 0.05 then
					continue
				end

				if data3.pass == nil then
					return true
				end

				local clip = Winding.clip(w, data4.nx, data4.ny, data4.nz, data4.d, 0.05)

				if clip == nil then
					continue
				end

				local clip2 = Winding.clip(clip, data3.nx, data3.ny, data3.nz, data3.d, 0.05)

				if clip2 == nil then
					continue
				end

				local v8 = clipToSeparators(data3.source, data3.pass, clip2, false)

				if v8 ~= nil and clipToSeparators(data3.pass, data3.source, v8, true) ~= nil then
					return true
				end
			end

			return false
		end

		local function floodFace(leaf, data3)
			local buf2 = buffer.create(leafWords * 4)
			local v7 = { passes = 0, budgeted = false }
			local function flow(p, data4)
				bsSet(buf2, p) -- inferred equivalent call

				for _, v8 in v[p] do
					if v5[v8.cell] or not reachable(v8, data4, data3) then
						continue
					end

					mark(v8)
				end

				if budget < v7.passes then
					v7.budgeted = true
					return
				end

				for _, portal in leafPortals[p] do
					if v7.budgeted then
						break
					end

					if not bsTest(data4.mightsee, portal.leaf) then -- inferred equivalent call
						continue
					end

					local leafvis

					if portal.done then
						leafvis = portal.leafvis
					else
						leafvis = portal.mightsee
					end

					local buf3 = buffer.create(leafWords * 4)
					local v8 = false

					for i = 0, leafWords * 4 - 4, 4 do
						local v9 = bit32.band(buffer.readu32(data4.mightsee, i), (buffer.readu32(leafvis, i)))
						buffer.writeu32(buf3, i, v9)

						if bit32.band(v9, (bit32.bor(bit32.bnot((buffer.readu32(buf2, i))), (buffer.readu32(buf, i))))) == 0 then
							continue
						end

						v8 = true
					end

					if not v8 then
						continue
					end

					if
						portal.nx * data4.nx + portal.ny * data4.ny + portal.nz * data4.nz < -0.9999
						and math.abs(portal.d + data4.d) < 0.05
					then
						continue
					end

					local clip = Winding.clip(portal.w, data3.nx, data3.ny, data3.nz, data3.d, 0.05)

					if clip == nil then
						continue
					end

					local v9 = {
						portal = portal,
						nx = portal.nx,
						ny = portal.ny,
						nz = portal.nz,
						d = portal.d,
						mightsee = buf3
					}

					if data4.pass == nil then
						v9.source = data4.source
						v9.pass = clip
						v7.passes += 1
						flow(portal.leaf, v9)
					else
						local clip2 = Winding.clip(clip, data4.nx, data4.ny, data4.nz, data4.d, 0.05)

						if clip2 ~= nil then
							local clip3 = Winding.clip(
								data4.source,
								-portal.nx,
								-portal.ny,
								-portal.nz,
								-portal.d,
								0.05
							)

							if clip3 ~= nil then
								local v10 = clipToSeparators(clip3, data4.pass, clip2, false)

								if v10 ~= nil then
									local pass = clipToSeparators(data4.pass, clip3, v10, true)

									if pass ~= nil then
										v9.source = clip3
										v9.pass = pass
										v7.passes += 1

										if yieldEvery > 0 and v7.passes % yieldEvery == 0 and yield ~= nil then
											yield()
										end

										flow(portal.leaf, v9)
									end
								end
							end
						end
					end
				end
			end

			flow(leaf, data3)
			result.floods += 1
			result.passes += v7.passes

			if v7.budgeted then
				result.budgeted += 1

				for i = 1, #data.airLeaves do
					if not bsTest(data3.mightsee, i) then -- inferred equivalent call
						continue
					end

					for _, v8 in v[i] do
						if not v5[v8.cell] then
							mark(v8)
						end
					end
				end
			end
		end

		local v7 = v4

		local function interiorFace(face, p)
			for _, v8 in v2[v7] do
				if v8 == p then
					continue
				end

				for _, face2 in v8.faces do
					if
						not (face.nx * face2.nx + face.ny * face2.ny + face.nz * face2.nz > -0.9999)
						and not (math.abs(face.d + face2.d) > 0.01)
						and Winding.contains(face2.w, face2.nx, face2.ny, face2.nz, face.w, 0.01)
					then
						return true
					end
				end
			end

			return false
		end

		for _, v8 in v2[v4] do
			for _, v9 in v[v8.leaf] do
				if not v5[v9.cell] then
					mark(v9)
				end
			end

			local airLeave = data.airLeaves[v8.leaf]

			for _, face in v8.faces do
				if interiorFace(face, v8) then
					result.interior += 1
				else
					local v9 = {}

					for _, v10 in leafPortals[v8.leaf] do
						if not coplanar(face.nx, face.ny, face.nz, face.d, v10.nx, v10.ny, v10.nz, v10.d) then -- inferred equivalent call
							continue
						end

						v9[#v9 + 1] = v10
					end

					local v10 = false

					for _, plane in airLeave.planes do
						if not coplanar(face.nx, face.ny, face.nz, face.d, plane[1], plane[2], plane[3], plane[4]) then -- inferred equivalent call
							continue
						end

						v10 = true
						break
					end

					if not v10 or #v9 ~= 0 then
						if #v9 > 0 then
							for _, v11 in v9 do
								floodFace(v11.leaf, {
									source = face.w,
									pass = nil,
									nx = face.nx,
									ny = face.ny,
									nz = face.nz,
									d = face.d,
									mightsee = v11.mightsee
								})
							end
						else
							local buf2 = buffer.create(leafWords * 4)

							for _, v11 in leafPortals[v8.leaf] do
								local _, v12 = Winding.range(v11.w, face.nx, face.ny, face.nz, face.d)

								if not (v12 > 0.05) then
									continue
								end

								for i = 0, leafWords * 4 - 4, 4 do
									buffer.writeu32(
										buf2,
										i,
										(bit32.bor(buffer.readu32(buf2, i), (buffer.readu32(v11.mightsee, i))))
									)
								end
							end

							floodFace(v8.leaf, {
								source = face.w,
								pass = nil,
								nx = face.nx,
								ny = face.ny,
								nz = face.nz,
								d = face.d,
								mightsee = buf2
							})
						end
					end
				end
			end
		end

		result2[v4] = v5

		if callback ~= nil then
			callback(v4, #cells, result)
		end
	end

	return result2, result
end

function Vis.floodOrder(p)
	local clone = table.clone(p.portals)
	table.sort(clone, function(a, b)
		if a.numMightsee == b.numMightsee then
			return a.id < b.id
		end

		return a.numMightsee < b.numMightsee
	end)
	return clone
end

return Vis