--!native
local v = {}

local function ensureFinite(p: number, p2: string) -- 11 equivalent calls inferred from this helper
	if p ~= p or p == 1e999 or p == -1e999 then
		error(`PVSData contains non-finite {p2}`)
	end

	return p
end

local function expectedRowStride(p: number) -- 3 equivalent calls inferred from this helper
	return (math.ceil(p / 8))
end

local function cellWorldAABB(p)
	local vector = p.size * 0.5
	local rightVector = p.cframe.RightVector
	local upVector = p.cframe.UpVector
	local lookVector = p.cframe.LookVector
	local vector2 = Vector3.new(
		math.abs(rightVector.X) * vector.X + math.abs(upVector.X) * vector.Y + math.abs(lookVector.X) * vector.Z,
		math.abs(rightVector.Y) * vector.X + math.abs(upVector.Y) * vector.Y + math.abs(lookVector.Y) * vector.Z,
		math.abs(rightVector.Z) * vector.X + math.abs(upVector.Z) * vector.Y + math.abs(lookVector.Z) * vector.Z
	)
	return p.cframe.Position - vector2, p.cframe.Position + vector2
end

local function validateCell(cell, i: number, p)
	if cell.id < 1 or cell.id > 65535 or cell.id % 1 ~= 0 then
		error(`PVSData cluster {i} has an invalid ID`)
	end

	if p[cell.id] then
		error(`PVSData contains duplicate cluster ID {cell.id}`)
	end

	p[cell.id] = true
	local size = cell.size
	ensureFinite(size.X, `cluster {i} size X`) -- inferred equivalent call
	ensureFinite(size.Y, `cluster {i} size Y`) -- inferred equivalent call
	ensureFinite(size.Z, `cluster {i} size Z`) -- inferred equivalent call

	if size.X <= 0 or size.Y <= 0 or size.Z <= 0 then
		error(`PVSData cluster {i} has a non-positive size`)
	end

	local v2 = { cell.cframe:GetComponents() }

	for j, v3 in ipairs(v2) do
		ensureFinite(v3, `cluster {i} CFrame component {j}`) -- inferred equivalent call
	end
end

local function validateRegion(region, i: number, count: number)
	if region.cluster < 1 or count < region.cluster or region.cluster % 1 ~= 0 then
		error(`PVSData region {i} has an invalid cluster`)
	end

	ensureFinite(region.minimum.X, `region {i} minimum X`) -- inferred equivalent call
	ensureFinite(region.minimum.Y, `region {i} minimum Y`) -- inferred equivalent call
	ensureFinite(region.minimum.Z, `region {i} minimum Z`) -- inferred equivalent call
	ensureFinite(region.maximum.X, `region {i} maximum X`) -- inferred equivalent call
	ensureFinite(region.maximum.Y, `region {i} maximum Y`) -- inferred equivalent call
	ensureFinite(region.maximum.Z, `region {i} maximum Z`) -- inferred equivalent call
	local vector = region.maximum - region.minimum

	if vector.X <= 0 or vector.Y <= 0 or vector.Z <= 0 then
		error(`PVSData region {i} has non-positive bounds`)
	end
end

local function attachRegionsToCells(p)
	for _, cell in ipairs(p.cells) do
		cell.regions = {}
	end

	for _, region in ipairs(p.regions) do
		local regions = p.cells[region.cluster].regions
		assert(regions ~= nil)
		regions[#regions + 1] = region
	end
end

local function validateData(data, callback)
	local count = #data.cells

	if count < 1 or count > 8192 then
		error(`PVSData cluster count must be between 1 and {8192}`)
	end

	if #data.regions < 1 or #data.regions > 65535 then
		error(`PVSData region count must be between 1 and {65535}`)
	end

	local v2 = expectedRowStride(count) -- inferred equivalent call

	if data.rowStride ~= v2 then
		error(`PVSData row stride mismatch: expected {v2}, got {data.rowStride}`)
	end

	if #data.visibleBytes ~= count * v2 then
		error(`PVSData visibility byte count mismatch: expected {count * v2}, got {#data.visibleBytes}`)
	end

	local maxDistance = data.maxDistance

	if maxDistance ~= maxDistance or maxDistance == 1e999 or maxDistance == -1e999 then
		error("PVSData contains non-finite maximum distance")
	end

	local nearDistance = data.nearDistance

	if nearDistance ~= nearDistance or nearDistance == 1e999 or nearDistance == -1e999 then
		error("PVSData contains non-finite near distance")
	end

	if data.maxDistance < 0 or data.nearDistance < 0 then
		error("PVSData distances cannot be negative")
	end

	if data.raysPerPair < 1 or data.raysPerPair > 255 or data.raysPerPair % 1 ~= 0 then
		error("PVSData bake quality must be an integer between 1 and 255")
	end

	local v3 = {}

	for i, cell in ipairs(data.cells) do
		validateCell(cell, i, v3)
	end

	local v4 = table.create(count, 0)

	for i, region in ipairs(data.regions) do
		validateRegion(region, i, count)
		local cluster = region.cluster
		v4[cluster] += 1
	end

	for i = 1, count do
		if v4[i] == 0 then
			error(`PVSData cluster {i} has no spatial regions`)
		end
	end

	local buf = buffer.fromstring(data.visibleBytes)
	local v5 = {}
	local v6 = {}

	for i = 1, count do
		v5[i] = math.floor((i - 1) / 8)
		v6[i] = bit32.lshift(1, (i - 1) % 8)
	end

	for i = 1, count do
		if callback and i % 32 == 0 then
			callback()
		end

		local v7 = (i - 1) * v2
		local v8 = v5[i]
		local v9 = v6[i]

		if bit32.band(buffer.readu8(buf, v7 + v8), v9) == 0 then
			error(`PVSData cluster {i} is not visible to itself`)
		end

		for j = i + 1, count do
			if (bit32.band(buffer.readu8(buf, v7 + v5[j]), v6[j]) ~= 0) == (bit32.band(buffer.readu8(buf, (j - 1) * v2 + v8), v9) ~= 0) then
				continue
			end

			error(`PVSData visibility is not mutual for clusters {i} and {j}`)
		end
	end
end

function v.getRowStride(p: number)
	local v2 = p >= 0 and p % 1 == 0
	assert(v2, "cellCount must be a non-negative integer")
	return expectedRowStride(p) -- inferred equivalent call
end

function v.newVisibilityBuffer(p: number)
	local v2 = p >= 1 and p <= 8192 and p % 1 == 0
	assert(v2, "invalid PVS cluster count")
	return buffer.create(p * expectedRowStride(p)) -- inferred equivalent call
end

function v.setVisible(buf: buffer, p: number, p2: number, p3: number)
	local v2 = (p2 - 1) * p + math.floor((p3 - 1) / 8)
	local v3 = bit32.lshift(1, (p3 - 1) % 8)
	buffer.writeu8(buf, v2, (bit32.bor(buffer.readu8(buf, v2), v3)))
end

function v.isVisible(data, p: number, p2: number)
	local count = #data.cells

	if p < 1 or count < p or p2 < 1 or count < p2 then
		return false
	end

	local v2 = (p - 1) * data.rowStride + math.floor((p2 - 1) / 8) + 1
	local v3 = string.byte(data.visibleBytes, v2)
	return v3 ~= nil and bit32.band(v3, (bit32.lshift(1, (p2 - 1) % 8))) ~= 0
end

function v.regionContainsPoint(p, vector: Vector3, value: number?)
	local v2 = math.max(value or 0, 0)

	if
		vector.X >= p.minimum.X - v2
		and vector.X <= p.maximum.X + v2
		and vector.Y >= p.minimum.Y - v2
		and vector.Y <= p.maximum.Y + v2
		and vector.Z >= p.minimum.Z - v2
	then
		return vector.Z <= p.maximum.Z + v2
	else
		return false
	end
end

function v.findCellIndices(p, vector: Vector3, p2: number?)
	local v2 = {}
	local clusters = {}

	for _, region in ipairs(p.regions) do
		if v2[region.cluster] or not v.regionContainsPoint(region, vector, p2) then
			continue
		end

		v2[region.cluster] = true
		clusters[#clusters + 1] = region.cluster
	end

	table.sort(clusters)
	return clusters
end

function v.regionFromCell(p, cluster: number)
	local vector, maximum = cellWorldAABB(p)
	return { cluster = cluster, minimum = vector, maximum = maximum }
end

function v.encode(data)
	validateData(data)
	local count = #data.cells
	local count2 = #data.regions
	local v2 = count * 62 + 22 + count2 * 26 + #data.visibleBytes
	local buf = buffer.create(v2)
	local v3 = 0
	buffer.writestring(buf, v3, "BLXPVS2")
	local v4 = v3 + 7
	buffer.writeu16(buf, v4, count)
	local v5 = v4 + 2
	buffer.writeu16(buf, v5, data.rowStride)
	local v6 = v5 + 2
	buffer.writeu16(buf, v6, count2)
	local v7 = v6 + 2
	buffer.writef32(buf, v7, data.maxDistance)
	local v8 = v7 + 4
	buffer.writef32(buf, v8, data.nearDistance)
	local v9 = v8 + 4
	buffer.writeu8(buf, v9, data.raysPerPair)
	local v10 = v9 + 1

	for _, cell in ipairs(data.cells) do
		buffer.writeu16(buf, v10, cell.id)
		v10 += 2
		local v11 = { cell.cframe:GetComponents() }
		v11[#v11 + 1] = cell.size.X
		v11[#v11 + 1] = cell.size.Y
		v11[#v11 + 1] = cell.size.Z

		for _, value in ipairs(v11) do
			buffer.writef32(buf, v10, value)
			v10 += 4
		end
	end

	for _, region in ipairs(data.regions) do
		buffer.writeu16(buf, v10, region.cluster)
		v10 += 2

		for _, value in ipairs({
			region.minimum.X,
			region.minimum.Y,
			region.minimum.Z,
			region.maximum.X,
			region.maximum.Y,
			region.maximum.Z
		}) do
			buffer.writef32(buf, v10, value)
			v10 += 4
		end
	end

	buffer.writestring(buf, v10, data.visibleBytes)
	return buffer.tostring(buf)
end

function v.isEncoded(value)
	return typeof(value) == "string"
		and #value >= 7
		and (string.sub(value, 1, 7) == "BLXPVS1" or string.sub(value, 1, 7) == "BLXPVS2")
end

function v.decode(str: string, callback)
	if not v.isEncoded(str) then
		error("PVSData does not start with a supported BLXPVS header")
	end

	local v2 = string.sub(str, 1, 7) == "BLXPVS2"
	local buf = buffer.fromstring(str)
	local total = 7
	local count = #str

	local function ensureCanRead(p: number, p2: string) -- 3 equivalent calls inferred from this helper
		if count - total < p then
			error(`PVSData ended while reading {p2}`)
		end
	end

	local function readu16(p: string) -- 2 equivalent calls inferred from this helper
		ensureCanRead(2, p) -- inferred equivalent call
		local v3 = buffer.readu16(buf, total)
		total += 2
		return v3
	end

	local function readu8(p: string)
		ensureCanRead(1, p) -- inferred equivalent call
		local v3 = buffer.readu8(buf, total)
		total += 1
		return v3
	end

	local function readf32(p: string) -- 21 equivalent calls inferred from this helper
		ensureCanRead(4, p) -- inferred equivalent call
		local finite = ensureFinite(buffer.readf32(buf, total), p) -- inferred equivalent call
		total += 4
		return finite
	end

	if count - total < 2 then
		error("PVSData ended while reading cluster count")
	end

	local v3 = buffer.readu16(buf, total)
	total += 2

	if v3 < 1 or v3 > 8192 then
		error(`PVSData has an invalid cluster count: {v3}`)
	end

	if count - total < 2 then
		error("PVSData ended while reading row stride")
	end

	local rowStride = buffer.readu16(buf, total)
	total += 2
	local v4

	if v2 then
		if count - total < 2 then
			error("PVSData ended while reading region count")
		end

		v4 = buffer.readu16(buf, total)
		total += 2
	else
		v4 = v3
	end

	if v4 < 1 or v4 > 65535 then
		error(`PVSData has an invalid region count: {v4}`)
	end

	if count - total < 4 then
		error("PVSData ended while reading maximum distance")
	end

	local maxDistance = buffer.readf32(buf, total)

	if maxDistance ~= maxDistance or maxDistance == 1e999 or maxDistance == -1e999 then
		error("PVSData contains non-finite maximum distance")
	end

	total += 4

	if count - total < 4 then
		error("PVSData ended while reading near distance")
	end

	local nearDistance = buffer.readf32(buf, total)

	if nearDistance ~= nearDistance or nearDistance == 1e999 or nearDistance == -1e999 then
		error("PVSData contains non-finite near distance")
	end

	total += 4

	if count - total < 1 then
		error("PVSData ended while reading bake quality")
	end

	local raysPerPair = buffer.readu8(buf, total)
	total += 1
	local v5 = not v2 and 0 or v4 * 26
	local v6 = (v2 and 22 or 20) + v3 * 62 + v5 + v3 * rowStride

	if count ~= v6 then
		error(`PVSData byte count mismatch: expected {v6}, got {count}`)
	end

	local cells = table.create(v3)

	for i = 1, v3 do
		local id = readu16(`cluster {i} ID`) -- inferred equivalent call
		local finite = readf32(`cluster {i} position X`) -- inferred equivalent call
		local finite2 = readf32(`cluster {i} position Y`) -- inferred equivalent call
		local finite3 = readf32(`cluster {i} position Z`) -- inferred equivalent call
		local finite4 = readf32(`cluster {i} rotation 00`) -- inferred equivalent call
		local finite5 = readf32(`cluster {i} rotation 01`) -- inferred equivalent call
		local finite6 = readf32(`cluster {i} rotation 02`) -- inferred equivalent call
		local finite7 = readf32(`cluster {i} rotation 10`) -- inferred equivalent call
		local finite8 = readf32(`cluster {i} rotation 11`) -- inferred equivalent call
		local finite9 = readf32(`cluster {i} rotation 12`) -- inferred equivalent call
		local finite10 = readf32(`cluster {i} rotation 20`) -- inferred equivalent call
		local finite11 = readf32(`cluster {i} rotation 21`) -- inferred equivalent call
		local finite12 = readf32(`cluster {i} rotation 22`) -- inferred equivalent call
		local finite13 = readf32(`cluster {i} size X`) -- inferred equivalent call
		local finite14 = readf32(`cluster {i} size Y`) -- inferred equivalent call
		local finite15 = readf32(`cluster {i} size Z`) -- inferred equivalent call
		cells[i] = {
			id = id,
			cframe = CFrame.new(
				finite,
				finite2,
				finite3,
				finite4,
				finite5,
				finite6,
				finite7,
				finite8,
				finite9,
				finite10,
				finite11,
				finite12
			),
			size = Vector3.new(finite13, finite14, finite15)
		}
	end

	local regions = table.create(v4)

	if v2 then
		for i = 1, v4 do
			local v7 = { cluster = readu16(`region {i} cluster`), minimum = 0, maximum = 0 } -- inferred equivalent call
			local finite = readf32(`region {i} minimum X`) -- inferred equivalent call
			local finite2 = readf32(`region {i} minimum Y`) -- inferred equivalent call
			local formatted = `region {i} minimum Z`
			v7.minimum = Vector3.new(finite, finite2, readf32(formatted)) -- inferred equivalent call
			local finite3 = readf32(`region {i} maximum X`) -- inferred equivalent call
			local finite4 = readf32(`region {i} maximum Y`) -- inferred equivalent call
			local formatted2 = `region {i} maximum Z`
			v7.maximum = Vector3.new(finite3, finite4, readf32(formatted2)) -- inferred equivalent call
			regions[i] = v7
		end
	else
		for i, v7 in ipairs(cells) do
			regions[i] = v.regionFromCell(v7, i)
		end
	end

	local v7 = v3 * rowStride

	if count - total < v7 then
		error("PVSData ended while reading visibility rows")
	end

	local v8 = {
		cells = cells,
		regions = regions,
		rowStride = rowStride,
		visibleBytes = buffer.readstring(buf, total, v7),
		maxDistance = maxDistance,
		nearDistance = nearDistance,
		raysPerPair = raysPerPair
	}
	validateData(v8, callback)
	attachRegionsToCells(v8)
	return v8
end

return table.freeze(v)