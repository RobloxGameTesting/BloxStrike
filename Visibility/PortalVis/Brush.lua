--!native
local Winding = require(script.Parent:WaitForChild("Winding"))
local Brush = {}

local function makeSide(nx, ny, nz, p, baseForPlane, used) -- 1 equivalent call inferred from this helper
	return {
		nx = nx,
		ny = ny,
		nz = nz,
		d = p,
		w = baseForPlane,
		used = used,
		key = Winding.planeKey(nx, ny, nz, p)
	}
end

local function finish(p)
	local minX = 1e999
	local minY = 1e999
	local minZ = 1e999
	local maxX = -1e999
	local maxY = -1e999
	local maxZ = -1e999
	local keys = {}

	for _, side in p.sides do
		local bounds, v, v2, v3, v4, v5 = Winding.bounds(side.w)

		if bounds < minX then
			minX = bounds
		end

		if v < minY then
			minY = v
		end

		if v2 < minZ then
			minZ = v2
		end

		if maxX < v3 then
			maxX = v3
		end

		if maxY < v4 then
			maxY = v4
		end

		if maxZ < v5 then
			maxZ = v5
		end

		keys[side.key] = true
	end

	p.minX = minX
	p.minY = minY
	p.minZ = minZ
	p.maxX = maxX
	p.maxY = maxY
	p.maxZ = maxZ
	p.keys = keys
	return p
end

function Brush.fromPlanes(items, id, name, p)
	local sides = {}

	for k, item in items do
		local baseForPlane = Winding.baseForPlane(item[1], item[2], item[3], item[4])

		for k2, item2 in items do
			if k2 ~= k and baseForPlane ~= nil then
				baseForPlane = Winding.clip(baseForPlane, -item2[1], -item2[2], -item2[3], -item2[4], 0.02)
			end
		end

		if baseForPlane == nil then
			continue
		end

		for i = 1, #baseForPlane do
			if math.abs(baseForPlane[i]) > 50000 then
				return nil
			end
		end

		local v = #sides + 1
		sides[v] = makeSide(item[1], item[2], item[3], item[4], baseForPlane, p ~= nil and p[k] == true) -- inferred equivalent call
	end

	if #sides < 4 then
		return nil
	end

	return (finish({ id = id, name = name, sides = sides }))
end

function Brush.planesFromMesh(list, items)
	local total = 0
	local total2 = 0
	local total3 = 0

	for _, v in list do
		total += v[1]
		total2 += v[2]
		total3 += v[3]
	end

	local v = total / #list
	local v2 = total2 / #list
	local v3 = total3 / #list
	local v4 = {}
	local result = {}

	for _, item in items do
		local v5 = list[item[1]]
		local v6 = list[item[2]]
		local v7 = list[item[3]]
		local planeFromPoints, v8, v9, v10 = Winding.planeFromPoints(
			v5[1],
			v5[2],
			v5[3],
			v6[1],
			v6[2],
			v6[3],
			v7[1],
			v7[2],
			v7[3]
		)

		if planeFromPoints == nil then
			continue
		end

		if planeFromPoints * v + v8 * v2 + v9 * v3 - v10 > 0 then
			planeFromPoints = -planeFromPoints
			v8 = -v8
			v9 = -v9
			v10 = -v10
		end

		local v11 = string.format("%.5f,%.5f,%.5f,%.3f", planeFromPoints, v8, v9, v10)

		if v4[v11] then
			continue
		end

		v4[v11] = true
		result[#result + 1] = { planeFromPoints, v8, v9, v10 }
	end

	return result
end

function Brush.range(p, p2, p3, p4, p5)
	local v = 1e999
	local v2 = -1e999

	for _, side in p.sides do
		local range, v3 = Winding.range(side.w, p2, p3, p4, p5)

		if range < v then
			v = range
		end

		if v2 < v3 then
			v2 = v3
		end
	end

	return v, v2
end

function Brush.boxRange(data, p, p2, p3, p4)
	local v

	if p > 0 then
		v = data.minX
	else
		v = data.maxX
	end

	local v2 = v * p
	local v3

	if p2 > 0 then
		v3 = data.minY
	else
		v3 = data.maxY
	end

	local v4 = v2 + v3 * p2
	local v5

	if p3 > 0 then
		v5 = data.minZ
	else
		v5 = data.maxZ
	end

	local v6 = v4 + v5 * p3 - p4
	local v7

	if p > 0 then
		v7 = data.maxX
	else
		v7 = data.minX
	end

	local v8 = v7 * p
	local v9

	if p2 > 0 then
		v9 = data.maxY
	else
		v9 = data.minY
	end

	local v10 = v8 + v9 * p2
	local v11

	if p3 > 0 then
		v11 = data.maxZ
	else
		v11 = data.minZ
	end

	return v6, v10 + v11 * p3 - p4
end

function Brush.classify(p, p2, p3, p4, p5)
	local boxRange, v = Brush.boxRange(p, p2, p3, p4, p5)

	if v <= 0.05 then
		return "back"
	end

	if boxRange >= -0.05 then
		return "front"
	end

	local range, v2 = Brush.range(p, p2, p3, p4, p5)

	if v2 <= 0.05 then
		return "back"
	end

	if range >= -0.05 then
		return "front"
	end

	return "cross"
end

function Brush.split(data, p, p2, p3, p4)
	local range, v = Brush.range(data, p, p2, p3, p4)

	if v < 0.05 then
		return nil, data
	end

	if range > -0.05 then
		return data, nil
	end

	local v2 = {}
	local v3 = {}

	for k, side in data.sides do
		v2[k] = { side.nx, side.ny, side.nz, side.d }
		v3[k] = side.used
	end

	local count = #v2
	v2[count + 1] = {
		-p,
		-p2,
		-p3,
		-p4
	}
	v3[count + 1] = true
	local v4 = Brush.fromPlanes(v2, data.id, data.name, v3)
	v2[count + 1] = { p, p2, p3, p4 }
	local v5 = Brush.fromPlanes(v2, data.id, data.name, v3)

	local function thin(data2) -- 2 equivalent calls inferred from this helper
		return data2 == nil
			or data2.maxX - data2.minX < 0.05
			or data2.maxY - data2.minY < 0.05
			or data2.maxZ - data2.minZ < 0.05
	end

	if thin(v4) then -- inferred equivalent call
		v4 = nil
	end

	if thin(v5) then -- inferred equivalent call
		v5 = nil
	end

	return v4, v5
end

function Brush.markUsed(p, p2)
	for _, side in p.sides do
		if side.key == p2 then
			side.used = true
		end
	end
end

return Brush