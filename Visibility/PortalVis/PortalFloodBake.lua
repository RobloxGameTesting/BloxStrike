--!native
require(script.Parent:WaitForChild("Winding"))
local Brush = require(script.Parent:WaitForChild("Brush"))
local BSP = require(script.Parent:WaitForChild("BSP"))
local Portals = require(script.Parent:WaitForChild("Portals"))
local Vis = require(script.Parent:WaitForChild("Vis"))
local v = {
	DEFAULTS = table.freeze({
		pad = 3,
		padDown = 0,
		padUp = 1,
		band = 13,
		domainPad = 3,
		ground = true
	})
}
local v2 = {
	{ 1, 3, 4 },
	{ 1, 4, 2 },
	{ 2, 4, 6 },
	{ 2, 6, 5 },
	{ 1, 5, 6 },
	{ 1, 6, 3 },
	{ 1, 2, 5 },
	{ 3, 6, 4 }
}
local v3 = {
	{ 1, 3, 4 },
	{ 1, 4, 2 },
	{ 3, 4, 5 },
	{ 1, 3, 5 },
	{ 1, 5, 2 },
	{ 2, 5, 4 }
}

local function world(cframe, p, p2, p3) -- 11 equivalent calls inferred from this helper
	local pointToWorldSpace = cframe:PointToWorldSpace((Vector3.new(p, p2, p3)))
	return { pointToWorldSpace.X, pointToWorldSpace.Y, pointToWorldSpace.Z }
end

local function boxPlanes(p, p2, p3, p4, p5, p6)
	return {
		{ 1, 0, 0, p4 },
		{
			-1,
			0,
			0,
			-p
		},
		{ 0, 1, 0, p5 },
		{
			0,
			-1,
			0,
			-p2
		},
		{ 0, 0, 1, p6 },
		{
			0,
			0,
			-1,
			-p3
		}
	}
end

function v.planesForPart(instance)
	local cframe = instance.CFrame
	local v4 = instance.Size * 0.5
	local x = v4.X
	local y = v4.Y
	local z = v4.Z
	local v5 = nil

	if instance:IsA("WedgePart") or instance:IsA("Part") and instance.Shape == Enum.PartType.Wedge then
		v5 = "Wedge"
	elseif instance:IsA("CornerWedgePart") or instance:IsA("Part") and instance.Shape == Enum.PartType.CornerWedge then
		v5 = "CornerWedge"
	elseif instance:IsA("Part") then
		local shape = instance.Shape

		if shape == Enum.PartType.Block then
			v5 = "Block"
		elseif shape == Enum.PartType.Cylinder then
			v5 = "Cylinder"
		elseif shape == Enum.PartType.Ball then
			v5 = "Ball"
		else
			v5 = v5
		end
	end

	if v5 == "Block" then
		local position = cframe.Position
		local rightVector = cframe.RightVector
		local upVector = cframe.UpVector
		local lookVector = cframe.LookVector

		local function plane(p, p2, p3, p4) -- 6 equivalent calls inferred from this helper
			return {
				p,
				p2,
				p3,
				p * position.X + p2 * position.Y + p3 * position.Z + p4
			}
		end

		local v6 = plane(rightVector.X, rightVector.Y, rightVector.Z, x) -- inferred equivalent call
		local v7 = plane(-rightVector.X, -rightVector.Y, -rightVector.Z, x) -- inferred equivalent call
		local v8 = plane(upVector.X, upVector.Y, upVector.Z, y) -- inferred equivalent call
		local v9 = plane(-upVector.X, -upVector.Y, -upVector.Z, y) -- inferred equivalent call
		local v10 = plane(-lookVector.X, -lookVector.Y, -lookVector.Z, z) -- inferred equivalent call
		return "Block", {
			v6,
			v7,
			v8,
			v9,
			v10,
			plane(lookVector.X, lookVector.Y, lookVector.Z, z) -- inferred equivalent call
		}
	elseif v5 == "Wedge" then
		local v6 = world(cframe, -x, -y, -z) -- inferred equivalent call
		local v7 = world(cframe, -x, -y, z) -- inferred equivalent call
		local v8 = world(cframe, x, -y, -z) -- inferred equivalent call
		local v9 = world(cframe, x, -y, z) -- inferred equivalent call
		local v10 = world(cframe, -x, y, z) -- inferred equivalent call
		local pointToWorldSpace = cframe:PointToWorldSpace((Vector3.new(x, y, z)))
		local v11 = {
			v6,
			v7,
			v8,
			v9,
			v10,
			{ pointToWorldSpace.X, pointToWorldSpace.Y, pointToWorldSpace.Z }
		}
		return "Wedge", Brush.planesFromMesh(v11, v2)
	elseif v5 == "CornerWedge" then
		local v6 = world(cframe, -x, -y, -z) -- inferred equivalent call
		local v7 = world(cframe, -x, -y, z) -- inferred equivalent call
		local v8 = world(cframe, x, -y, -z) -- inferred equivalent call
		local v9 = world(cframe, x, -y, z) -- inferred equivalent call
		local pointToWorldSpace = cframe:PointToWorldSpace((Vector3.new(x, y, -z)))
		local v10 = {
			v6,
			v7,
			v8,
			v9,
			{ pointToWorldSpace.X, pointToWorldSpace.Y, pointToWorldSpace.Z }
		}
		return "CornerWedge", Brush.planesFromMesh(v10, v3)
	else
		if v5 ~= "Cylinder" then
			return v5, nil
		end

		local v6 = math.min(y, z)
		local v7 = {}
		local v8 = {}

		for i = 0, 11 do
			local v9 = i / 12 * 3.141592653589793 * 2
			local v10 = math.cos(v9) * v6
			local v11 = math.sin(v9) * v6
			local v12 = i * 2 + 1
			v7[v12] = world(cframe, -x, v10, v11) -- inferred equivalent call
			local v13 = i * 2 + 2
			v7[v13] = world(cframe, x, v10, v11) -- inferred equivalent call
		end

		for i = 0, 11 do
			local v9 = (i + 1) % 12
			v8[#v8 + 1] = { i * 2 + 1, v9 * 2 + 1, v9 * 2 + 2 }
		end

		v8[#v8 + 1] = { 1, 3, 5 }
		v8[#v8 + 1] = { 2, 6, 4 }
		return v5, Brush.planesFromMesh(v7, v8)
	end
end

function v.buildGraph(items, p, p2)
	local v4 = {}

	for k, v5 in v.DEFAULTS do
		if p2 ~= nil and p2[k] ~= nil then
			v5 = p2[k]
		end

		v4[k] = v5
	end

	local yield

	if p2 ~= nil then
		yield = p2.yield
	end

	local lastTime = os.clock()
	local v5 = {}
	local stats = { brushes = 0, unsupported = 0, degenerate = 0, groundBrushes = 0 }

	for k, item in items do
		if yield ~= nil and k % 8 == 0 then
			yield()
		end

		local _, v6 = v.planesForPart(item)

		if v6 == nil then
			stats.unsupported += 1
		else
			local v7 = Brush.fromPlanes(v6, #v5 + 1, item.Name)

			if v7 == nil then
				stats.degenerate += 1
			else
				v5[#v5 + 1] = v7
			end
		end
	end

	stats.brushes = #v5

	if #v5 == 0 then
		return nil, "NoBrushes"
	end

	local pad = v4.pad
	local v6 = {}
	local v7 = 1e999
	local v8 = 1e999
	local v9 = 1e999
	local v10 = -1e999
	local v11 = -1e999
	local v12 = -1e999

	for k, region in p.regions do
		v6[k] = {
			cluster = region.cluster,
			minX = region.minimum.X - pad,
			minY = region.minimum.Y - v4.padDown,
			minZ = region.minimum.Z - pad,
			maxX = region.maximum.X + pad,
			maxY = math.min(region.maximum.Y, region.minimum.Y + v4.band) + v4.padUp,
			maxZ = region.maximum.Z + pad
		}
		local domainPad = v4.domainPad
		v7 = math.min(v7, region.minimum.X - domainPad)
		v8 = math.min(v8, region.minimum.Y - 2)
		v9 = math.min(v9, region.minimum.Z - domainPad)
		v10 = math.max(v10, region.maximum.X + domainPad)
		v11 = math.max(v11, region.maximum.Y + 2)
		v12 = math.max(v12, region.maximum.Z + domainPad)
	end

	local v13 = boxPlanes(v7, v8, v9, v10, v11, v12)

	if v4.ground then
		for _, region in p.regions do
			local v14 = region.minimum.Y + 0.25 - 0.5
			v5[#v5 + 1] = Brush.fromPlanes(
				boxPlanes(region.minimum.X, v8 - 1, region.minimum.Z, region.maximum.X, v14, region.maximum.Z),
				#v5 + 1,
				"ground"
			)
			stats.groundBrushes += 1

			if not (region.maximum.Y - region.minimum.Y < 95) then
				continue
			end

			v5[#v5 + 1] = Brush.fromPlanes(
				boxPlanes(
					region.minimum.X,
					region.maximum.Y + 0.25,
					region.minimum.Z,
					region.maximum.X,
					v11 + 1,
					region.maximum.Z
				),
				#v5 + 1,
				"ceiling"
			)
			stats.groundBrushes += 1
		end
	end

	local clipped = {}

	for k, v14 in v5 do
		for _, v15 in v13 do
			if v14 == nil then
				break
			else
				local parts
				parts, v14 = Brush.split(v14, v15[1], v15[2], v15[3], v15[4])
			end
		end

		if v14 ~= nil then
			clipped[#clipped + 1] = v14
		end

		if yield ~= nil and k % 2 == 0 then
			yield()
		end
	end

	stats.clipped = #clipped
	local root, leaves, bsp = BSP.build(clipped, v13, yield)
	stats.bsp = bsp
	local v14, portals = Portals.build(root, leaves, v7, v8, v9, v10, v11, v12, yield)
	stats.portals = portals
	local state = Vis.prepare(v14, leaves, yield)
	stats.directedPortals = #state.portals
	stats.airLeaves = #state.airLeaves
	local count = #p.cells
	local cellHasVolume = table.create(count, false)
	local total = 0
	local volumes = {}

	for _, v15 in v6 do
		local v16 = boxPlanes(v15.minX, v15.minY, v15.minZ, v15.maxX, v15.maxY, v15.maxZ)

		for _, airLeave in state.airLeaves do
			if not BSP.leafTouchesBox(airLeave, v15.minX, v15.minY, v15.minZ, v15.maxX, v15.maxY, v15.maxZ, 0.01) then
				continue
			end

			local clone = table.clone(airLeave.planes)

			for _, v17 in v16 do
				clone[#clone + 1] = v17
			end

			local v17 = Brush.fromPlanes(clone, 0, "volume")

			if v17 == nil then
				continue
			end

			local faces = {}

			for _, side in v17.sides do
				faces[#faces + 1] = {
					w = side.w,
					nx = side.nx,
					ny = side.ny,
					nz = side.nz,
					d = side.d
				}
			end

			total += #faces
			volumes[#volumes + 1] = { cell = v15.cluster, leaf = airLeave.airIndex, faces = faces }
			cellHasVolume[v15.cluster] = true
		end

		if yield ~= nil then
			yield()
		end
	end

	stats.volumes = #volumes
	stats.faces = total
	stats.buildSeconds = os.clock() - lastTime
	return {
		state = state,
		volumes = volumes,
		cellCount = count,
		cellHasVolume = cellHasVolume,
		clipped = clipped,
		root = root,
		leaves = leaves,
		domain = { v7, v8, v9, v10, v11, v12 },
		stats = stats
	}
end

local function writeWinding(buf, offset, list)
	buffer.writeu32(buf, offset, #list)
	local v4 = offset + 4

	for i = 1, #list do
		buffer.writef64(buf, v4, list[i])
		v4 += 8
	end

	return v4
end

local function readWinding(buf, offset)
	local v4 = buffer.readu32(buf, offset)
	local v5 = offset + 4
	local result = table.create(v4)

	for i = 1, v4 do
		result[i] = buffer.readf64(buf, v5)
		v5 += 8
	end

	return result, v5
end

function v.encodeGraph(p, callback)
	local total = 8

	for _, portal in p.portals do
		total += #portal.w * 8 + 92
	end

	for _, airLeave in p.airLeaves do
		total += #airLeave.planes * 32 + 4
	end

	local buf = buffer.create(total)
	buffer.writeu32(buf, 0, #p.airLeaves)
	buffer.writeu32(buf, 4, #p.portals)
	local v4 = 8

	for k, portal in p.portals do
		if callback ~= nil and k % 256 == 0 then
			callback()
		end

		buffer.writeu32(buf, v4, portal.from)
		buffer.writeu32(buf, v4 + 4, portal.leaf)
		local v5 = v4 + 8

		for _, value in {
			portal.nx,
			portal.ny,
			portal.nz,
			portal.d,
			portal.minX,
			portal.minY,
			portal.minZ,
			portal.maxX,
			portal.maxY,
			portal.maxZ
		} do
			buffer.writef64(buf, v5, value)
			v5 += 8
		end

		local w = portal.w
		buffer.writeu32(buf, v5, #w)
		v4 = v5 + 4

		for i = 1, #w do
			buffer.writef64(buf, v4, w[i])
			v4 += 8
		end
	end

	for _, airLeave in p.airLeaves do
		buffer.writeu32(buf, v4, #airLeave.planes)
		v4 += 4

		for _, plane in airLeave.planes do
			buffer.writef64(buf, v4, plane[1])
			local v5 = v4 + 8
			buffer.writef64(buf, v5, plane[2])
			local v6 = v5 + 8
			buffer.writef64(buf, v6, plane[3])
			local v7 = v6 + 8
			buffer.writef64(buf, v7, plane[4])
			v4 = v7 + 8
		end
	end

	return buf
end

function v.decodeGraph(buf, callback)
	local v4 = buffer.readu32(buf, 0)
	local v5 = buffer.readu32(buf, 4)
	local portals = table.create(v5)
	local leafPortals = table.create(v4)
	local v6 = 8

	for i = 1, v4 do
		leafPortals[i] = {}
	end

	for i = 1, v5 do
		if callback ~= nil and i % 256 == 0 then
			callback()
		end

		local from = buffer.readu32(buf, v6)
		local leaf = buffer.readu32(buf, v6 + 4)
		local v7 = v6 + 8
		local v8 = table.create(10)

		for j = 1, 10 do
			v8[j] = buffer.readf64(buf, v7)
			v7 += 8
		end

		local v9 = buffer.readu32(buf, v7)
		v6 = v7 + 4
		local v10 = table.create(v9)

		for j = 1, v9 do
			v10[j] = buffer.readf64(buf, v6)
			v6 += 8
		end

		local v11 = {
			id = i,
			from = from,
			leaf = leaf,
			nx = v8[1],
			ny = v8[2],
			nz = v8[3],
			d = v8[4],
			minX = v8[5],
			minY = v8[6],
			minZ = v8[7],
			maxX = v8[8],
			maxY = v8[9],
			maxZ = v8[10],
			w = v10,
			done = false
		}
		portals[i] = v11
		local v12 = leafPortals[from]
		v12[#v12 + 1] = v11
	end

	local airLeaves = table.create(v4)

	for i = 1, v4 do
		local v7 = buffer.readu32(buf, v6)
		v6 += 4
		local planes = table.create(v7)

		for j = 1, v7 do
			planes[j] = {
				buffer.readf64(buf, v6),
				buffer.readf64(buf, v6 + 8),
				buffer.readf64(buf, v6 + 16),
				(buffer.readf64(buf, v6 + 24))
			}
			v6 += 32
		end

		airLeaves[i] = { airIndex = i, planes = planes, air = true, leaf = true }
	end

	return {
		portals = portals,
		leafPortals = leafPortals,
		airLeaves = airLeaves,
		leafWords = (v4 + 31) // 32
	}
end

function v.encodeFronts(p, value, value2)
	local v4 = (#p.portals + 31) // 32
	local v5 = value2 - value + 1
	local buf = buffer.create(8 + v5 * v4 * 4)
	buffer.writeu32(buf, 0, value)
	buffer.writeu32(buf, 4, value2)
	local total = 8

	for i = value, value2 do
		buffer.copy(buf, total, p.portals[i].front)
		total += v4 * 4
	end

	return buf
end

function v:applyFronts(p)
	local portalWords = (#self.portals + 31) // 32
	self.portalWords = portalWords
	local v4 = buffer.readu32(p, 0)
	local v5 = buffer.readu32(p, 4)
	local total = 8

	for i = v4, v5 do
		local buf = buffer.create(portalWords * 4)
		buffer.copy(buf, 0, p, total, portalWords * 4)
		self.portals[i].front = buf
		total += portalWords * 4
	end

	return v4, v5
end

function v.encodeMightsee(p, callback)
	local v4 = p.leafWords * 4
	local buf = buffer.create(#p.portals * (v4 + 4))
	local total = 0

	for k, portal in p.portals do
		if callback ~= nil and k % 512 == 0 then
			callback()
		end

		buffer.writeu32(buf, total, portal.numMightsee or 0)
		buffer.copy(buf, total + 4, portal.mightsee)
		total += 4 + v4
	end

	return buf
end

function v.decodeMightsee(p, p2, callback)
	local v4 = p.leafWords * 4
	local total = 0

	for k, portal in p.portals do
		if callback ~= nil and k % 512 == 0 then
			callback()
		end

		portal.numMightsee = buffer.readu32(p2, total)
		local buf = buffer.create(v4)
		buffer.copy(buf, 0, p2, total + 4, v4)
		portal.mightsee = buf
		total += 4 + v4
	end
end

function v.encodeVolumes(list, callback)
	local total = 4

	for _, v4 in list do
		total += 12

		for _, face in v4.faces do
			total += #face.w * 8 + 36
		end
	end

	local buf = buffer.create(total)
	buffer.writeu32(buf, 0, #list)
	local v4 = 4

	for k, v5 in list do
		if callback ~= nil and k % 128 == 0 then
			callback()
		end

		buffer.writeu32(buf, v4, v5.cell)
		buffer.writeu32(buf, v4 + 4, v5.leaf)
		buffer.writeu32(buf, v4 + 8, #v5.faces)
		v4 += 12

		for _, face in v5.faces do
			buffer.writef64(buf, v4, face.nx)
			buffer.writef64(buf, v4 + 8, face.ny)
			buffer.writef64(buf, v4 + 16, face.nz)
			buffer.writef64(buf, v4 + 24, face.d)
			local v6 = v4 + 32
			local w = face.w
			buffer.writeu32(buf, v6, #w)
			v4 = v6 + 4

			for i = 1, #w do
				buffer.writef64(buf, v4, w[i])
				v4 += 8
			end
		end
	end

	return buf
end

function v.decodeVolumes(buf, callback)
	local v4 = buffer.readu32(buf, 0)
	local result = table.create(v4)
	local v5 = 4

	for i = 1, v4 do
		if callback ~= nil and i % 128 == 0 then
			callback()
		end

		local cell = buffer.readu32(buf, v5)
		local leaf = buffer.readu32(buf, v5 + 4)
		local v6 = buffer.readu32(buf, v5 + 8)
		v5 += 12
		local faces = table.create(v6)

		for j = 1, v6 do
			local nx = buffer.readf64(buf, v5)
			local ny = buffer.readf64(buf, v5 + 8)
			local nz = buffer.readf64(buf, v5 + 16)
			local v7 = buffer.readf64(buf, v5 + 24)
			local v8 = v5 + 32
			local v9 = buffer.readu32(buf, v8)
			v5 = v8 + 4
			local v10 = table.create(v9)

			for k = 1, v9 do
				v10[k] = buffer.readf64(buf, v5)
				v5 += 8
			end

			faces[j] = {
				w = v10,
				nx = nx,
				ny = ny,
				nz = nz,
				d = v7
			}
		end

		result[i] = { cell = cell, leaf = leaf, faces = faces }
	end

	return result
end

function v.encodeRow(p, items)
	local v4 = {}

	for k in items do
		v4[#v4 + 1] = k
	end

	table.sort(v4)
	return p .. ":" .. table.concat(v4, " ")
end

function v.decodeRow(value)
	local v4, v5 = string.match(value, "^(%d+):(.*)$")
	local result = {}

	for k in string.gmatch(v5 or "", "%d+") do
		result[tonumber(k)] = true
	end

	return tonumber(v4), result
end

local function regionGap(p, p2)
	local v4 = math.max(p2.minimum.X - p.maximum.X, p.minimum.X - p2.maximum.X, 0)
	local v5 = math.max(p2.minimum.Y - p.maximum.Y, p.minimum.Y - p2.maximum.Y, 0)
	local v6 = math.max(p2.minimum.Z - p.maximum.Z, p.minimum.Z - p2.maximum.Z, 0)
	return (math.sqrt(v4 * v4 + v5 * v5 + v6 * v6))
end

function v.applyVisibility(p, data, list, list2, callback)
	local count = #p.cells
	local rowStride = data.getRowStride(count)
	local visibilityBuffer = data.newVisibilityBuffer(count)
	local result = {
		pairs = 0,
		visible = 0,
		near = 0,
		failOpen = 0,
		floodOnly = 0,
		sampledOnly = 0
	}

	for i = 1, count do
		if callback ~= nil then
			callback()
		end

		data.setVisible(visibilityBuffer, rowStride, i, i)

		for j = i + 1, count do
			result.pairs += 1
			local v4 = data.isVisible(p, i, j) or data.isVisible(p, j, i)
			local v5

			if list[i] == nil or list[i][j] ~= true then
				if list[j] == nil then
					v5 = false
				else
					v5 = list[j][i] == true
				end
			else
				v5 = true
			end

			local v6 = v4 or v5

			if not v6 then
				local v7 = 1e999

				for _, v8 in p.cells[i].regions or {} do
					for _, v9 in p.cells[j].regions or {} do
						v7 = math.min(v7, (regionGap(v8, v9)))
					end
				end

				if v7 <= p.nearDistance then
					result.near += 1
					v6 = true
				elseif not (list2[i] and list2[j]) then
					result.failOpen += 1
					v6 = true
				end
			end

			if v5 and not v4 then
				result.floodOnly += 1
			elseif v4 and not v5 then
				result.sampledOnly += 1
			end

			if not v6 then
				continue
			end

			data.setVisible(visibilityBuffer, rowStride, i, j)
			data.setVisible(visibilityBuffer, rowStride, j, i)
			result.visible += 1
		end
	end

	return buffer.tostring(visibilityBuffer), result
end

return table.freeze(v)