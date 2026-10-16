--!native
local Winding = require(script.Parent:WaitForChild("Winding"))
local Brush = require(script.Parent:WaitForChild("Brush"))

local function selectSplit(items)
	local v = {}
	local v2 = -1e999
	local v3 = nil

	for _, item in items do
		for _, side in item.sides do
			if side.used or v[side.key] then
				continue
			end

			v[side.key] = true
			local nx = side.nx
			local ny = side.ny
			local nz = side.nz
			local d = side.d
			local count = 0
			local count2 = 0
			local count3 = 0
			local count4 = 0

			for _, item2 in items do
				local classify = Brush.classify(item2, nx, ny, nz, d)

				if classify == "front" then
					count4 += 1
				elseif classify == "back" then
					count2 += 1
				else
					count += 1
				end

				if item2.keys[side.key] then
					count3 += 1
				end
			end

			local v4 = count3 * 5 - count * 5 - math.abs(count4 - count2)

			if Winding.isAxial(nx, ny, nz) then
				v4 += 5
			end

			if not (v2 < v4) then
				continue
			end

			v3 = side
			v2 = v4
		end
	end

	return v3
end

local BSP = {}

function BSP.build(p, p2, callback)
	local v = {}
	local v2 = {
		nodes = 0,
		airLeaves = 0,
		solidLeaves = 0,
		maxDepth = 0,
		splitBrushes = 0
	}

	local function makeLeaf(planes, air, brushes) -- 1 equivalent call inferred from this helper
		local v3 = {
			leaf = true,
			air = air,
			planes = planes,
			index = #v + 1,
			portals = nil,
			brushes = brushes
		}
		v[#v + 1] = v3

		if air then
			v2.airLeaves += 1
			return v3
		else
			v2.solidLeaves += 1
			return v3
		end
	end

	local function build(brushes, clone, maxDepth)
		if v2.maxDepth < maxDepth then
			v2.maxDepth = maxDepth
		end

		if #brushes == 0 then
			return makeLeaf(clone, true, brushes) -- inferred equivalent call
		else
			local v3 = selectSplit(brushes)

			if v3 == nil then
				local v4 = {
					leaf = true,
					air = false,
					planes = clone,
					index = #v + 1,
					portals = nil,
					brushes = brushes
				}
				v[#v + 1] = v4
				v2.solidLeaves += 1
				return v4
			else
				local nx = v3.nx
				local ny = v3.ny
				local nz = v3.nz
				local d = v3.d
				local key = v3.key
				local v4 = {}
				local v5 = {}

				for _, v6 in brushes do
					local classify = Brush.classify(v6, nx, ny, nz, d)

					if classify == "front" then
						Brush.markUsed(v6, key)
						v5[#v5 + 1] = v6
					elseif classify == "back" then
						Brush.markUsed(v6, key)
						v4[#v4 + 1] = v6
					else
						local parts, v7 = Brush.split(v6, nx, ny, nz, d)
						v2.splitBrushes += 1

						if parts ~= nil then
							Brush.markUsed(parts, key)
							v5[#v5 + 1] = parts
						end

						if v7 ~= nil then
							Brush.markUsed(v7, key)
							v4[#v4 + 1] = v7
						end
					end
				end

				v2.nodes += 1

				if callback ~= nil and v2.nodes % 4 == 0 then
					callback()
				end

				local clone2 = table.clone(clone)
				clone2[#clone2 + 1] = {
					-nx,
					-ny,
					-nz,
					-d
				}
				local clone3 = table.clone(clone)
				clone3[#clone3 + 1] = { nx, ny, nz, d }
				local parent = {
					plane = { nx, ny, nz, d },
					portals = nil
				}
				parent.front = build(v5, clone2, maxDepth + 1)
				parent.back = build(v4, clone3, maxDepth + 1)
				parent.front.parent = parent
				parent.back.parent = parent
				return parent
			end
		end
	end

	return build(p, table.clone(p2), 0), v, v2
end

function BSP.leafTouchesBox(p, p2, p3, p4, p5, p6, p7, p8)
	for _, plane in p.planes do
		local v = plane[1]
		local v2 = plane[2]
		local v3 = plane[3]
		local v4 = plane[4]
		local v5

		if v > 0 then
			v5 = p2
		else
			v5 = p5
		end

		local v6 = v5 * v
		local v7

		if v2 > 0 then
			v7 = p3
		else
			v7 = p6
		end

		local v8 = v6 + v7 * v2
		local v9

		if v3 > 0 then
			v9 = p4
		else
			v9 = p7
		end

		if p8 < v8 + v9 * v3 - v4 then
			return false
		end
	end

	return true
end

return BSP