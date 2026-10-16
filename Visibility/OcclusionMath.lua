local v = {}

local function finite(p: number) -- 3 equivalent calls inferred from this helper
	return p == p and p > -1e999 and p < 1e999
end

function v.isFiniteVector(data)
	local v2

	if typeof(data) == "Vector3" then
		local x = data.X

		if x == x and x > -1e999 then
			v2 = x < 1e999
		else
			v2 = false
		end

		if v2 then
			local y = data.Y

			if y == y and y > -1e999 then
				v2 = y < 1e999
			else
				v2 = false
			end

			if v2 then
				local z = data.Z

				if z == z and z > -1e999 then
					return z < 1e999
				else
					return false
				end
			end
		end
	else
		return false
	end

	return v2
end

local function clipAxis(z: number, z2: number, z3: number, z4: number, p: number, p2: number)
	if math.abs(z2) <= 1e-9 then
		if z < z3 or z4 < z then
			return nil, nil
		end

		return p, p2
	else
		local v2 = 1 / z2
		local v3 = (z3 - z) * v2
		local v4 = (z4 - z) * v2

		if v4 < v3 then
			v4, v3 = v3, v4
		end

		local v5 = math.max(p, v3)
		local v6 = math.min(p2, v4)

		if v6 < v5 then
			return nil, nil
		end

		return v5, v6
	end
end

function v.segmentAABBInterval(vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3)
	if
		not v.isFiniteVector(vector)
		or not v.isFiniteVector(vector2)
		or not v.isFiniteVector(vector3)
		or not v.isFiniteVector(vector4)
		or vector3.X > vector4.X
		or vector3.Y > vector4.Y
		or vector3.Z > vector4.Z
	then
		return nil, nil
	end

	local v2 = vector2 - vector
	local x = vector.X
	local x2 = v2.X
	local x3 = vector3.X
	local x4 = vector4.X
	local v3 = 0
	local v4 = 1

	if math.abs(x2) <= 1e-9 then
		if x < x3 or x4 < x then
			v3 = nil
			v4 = nil
		end
	else
		local v5 = 1 / x2
		local v6 = (x3 - x) * v5
		local v7 = (x4 - x) * v5

		if v7 < v6 then
			v7, v6 = v6, v7
		end

		v3 = math.max(v3, v6)
		v4 = math.min(v4, v7)

		if v4 < v3 then
			v3 = nil
			v4 = nil
		end
	end

	if v3 == nil or v4 == nil then
		return nil, nil
	end

	local y = vector.Y
	local y2 = v2.Y
	local y3 = vector3.Y
	local y4 = vector4.Y

	if math.abs(y2) <= 1e-9 then
		if y < y3 or y4 < y then
			v3 = nil
			v4 = nil
		end
	else
		local v5 = 1 / y2
		local v6 = (y3 - y) * v5
		local v7 = (y4 - y) * v5

		if v7 < v6 then
			v7, v6 = v6, v7
		end

		v3 = math.max(v3, v6)
		v4 = math.min(v4, v7)

		if v4 < v3 then
			v3 = nil
			v4 = nil
		end
	end

	if v3 == nil or v4 == nil then
		return nil, nil
	end

	return clipAxis(vector.Z, v2.Z, vector3.Z, vector4.Z, v3, v4)
end

function v.segmentSphereInterval(vector: Vector3, vector2: Vector3, vector3: Vector3, p: number)
	if not (v.isFiniteVector(vector) and v.isFiniteVector(vector2) and v.isFiniteVector(vector3)) then
		return nil, nil
	end

	if not (finite(p) and not (p <= 0)) then -- inferred equivalent call
		return nil, nil
	end

	local vector4 = vector2 - vector
	local dot = vector4:Dot(vector4)

	if dot <= 1e-6 then
		if (vector - vector3).Magnitude <= p then
			return 0, 1
		end

		return nil, nil
	else
		local vector5 = vector - vector3
		local v2 = 2 * vector5:Dot(vector4)
		local v3 = vector5:Dot(vector5) - p * p
		local v4 = v2 * v2 - 4 * dot * v3

		if v4 < 0 then
			return nil, nil
		end

		local v5 = math.sqrt(v4)
		local v6 = (-v2 - v5) / (2 * dot)
		local v7 = (-v2 + v5) / (2 * dot)
		local v8 = math.max(0, (math.min(v6, v7)))
		local v9 = math.min(1, (math.max(v6, v7)))

		if v9 < v8 then
			return nil, nil
		end

		return v8, v9
	end

	return nil, nil
end

local function mergedIntervals(items)
	local result = {}

	for _, item in items do
		local minimum = math.clamp(item.minimum, 0, 1)
		local maximum = math.clamp(item.maximum, 0, 1)

		if not (finite(minimum) and finite(maximum) and minimum < maximum) then -- inferred equivalent call
			continue
		end

		result[#result + 1] = { minimum = minimum, maximum = maximum }
	end

	if #result <= 1 then
		return result
	end

	table.sort(result, function(a, b)
		if a.minimum == b.minimum then
			return a.maximum < b.maximum
		end

		return a.minimum < b.minimum
	end)
	local result2 = { result[1] }

	for i = 2, #result do
		local v2 = result[i]
		local v3 = result2[#result2]

		if v2.minimum <= v3.maximum + 1e-6 then
			v3.maximum = math.max(v3.maximum, v2.maximum)
		else
			result2[#result2 + 1] = v2
		end
	end

	return result2
end

function v.uncoveredUnionLength(p, p2)
	local v2 = mergedIntervals(p)

	if #v2 == 0 then
		return 0
	end

	local v3 = mergedIntervals(p2)

	if #v3 == 0 then
		local total = 0

		for _, v4 in v2 do
			total += v4.maximum - v4.minimum
		end

		return total
	else
		local v4 = 1
		local total = 0

		for _, v5 in v2 do
			local minimum = v5.minimum

			while v4 <= #v3 and v3[v4].maximum <= minimum do
				v4 += 1
			end

			local v6 = v4

			while v6 <= #v3 and v3[v6].minimum < v5.maximum do
				local v7 = v3[v6]

				if minimum < v7.minimum then
					total += math.min(v7.minimum, v5.maximum) - minimum
				end

				minimum = math.max(minimum, v7.maximum)

				if v5.maximum <= minimum then
					break
				else
					v6 += 1
				end
			end

			if minimum < v5.maximum then
				total += v5.maximum - minimum
			end
		end

		return (math.max(total, 0))
	end
end

return table.freeze(v)