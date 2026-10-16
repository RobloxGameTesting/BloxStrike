--!native
local Winding = {
	count = function(list)
		return #list // 3
	end,
	baseForPlane = function(p, p2, p3, p4)
		local v = math.abs(p)
		local v2 = math.abs(p2)
		local v3 = math.abs(p3)
		local v4, v5, v6

		if v <= v3 and v2 <= v3 then
			v4 = 1
			v5 = 0
			v6 = 0
		else
			v4 = 0
			v5 = 0
			v6 = 1
		end

		local v7 = v4 * p + v5 * p2 + v6 * p3
		local v8 = v4 - p * v7
		local v9 = v5 - p2 * v7
		local v10 = v6 - p3 * v7
		local v11 = math.sqrt(v8 * v8 + v9 * v9 + v10 * v10)
		local v12 = v8 / v11
		local v13 = v9 / v11
		local v14 = v10 / v11
		local v15 = p * p4
		local v16 = p2 * p4
		local v17 = p3 * p4
		local v18 = v13 * p3 - v14 * p2
		local v19 = v14 * p - v12 * p3
		local v20 = v12 * p2 - v13 * p
		local v21 = v12 * 100000
		local v22 = v13 * 100000
		local v23 = v14 * 100000
		local v24 = v18 * 100000
		local v25 = v19 * 100000
		local v26 = v20 * 100000
		return {
			v15 - v24 + v21,
			v16 - v25 + v22,
			v17 - v26 + v23,
			v15 + v24 + v21,
			v16 + v25 + v22,
			v17 + v26 + v23,
			v15 + v24 - v21,
			v16 + v25 - v22,
			v17 + v26 - v23,
			v15 - v24 - v21,
			v16 - v25 - v22,
			v17 - v26 - v23
		}
	end,
	clip = function(list, p, p2, p3, p4, p5)
		local v = #list // 3
		local v2 = table.create(v)
		local v3 = table.create(v)
		local count = 0
		local count2 = 0

		for i = 1, v do
			local v4 = i * 3
			local v5 = list[v4 - 2] * p + list[v4 - 1] * p2 + list[v4] * p3 - p4
			v2[i] = v5

			if p5 < v5 then
				v3[i] = 1
				count += 1
			elseif v5 < -p5 then
				v3[i] = -1
				count2 += 1
			else
				v3[i] = 0
			end
		end

		if count == 0 then
			return nil
		end

		if count2 == 0 then
			return list
		end

		local total = 0
		local result = {}

		for i = 1, v do
			local v4 = i * 3
			local v5 = list[v4 - 2]
			local v6 = list[v4 - 1]
			local v7 = list[v4]
			local v8 = v3[i]

			if v8 == 0 then
				local v9 = total + 1
				local v10 = total + 2
				local v11 = total + 3
				result[v9] = v5
				result[v10] = v6
				result[v11] = v7
				total += 3
			else
				if v8 == 1 then
					local v9 = total + 1
					local v10 = total + 2
					local v11 = total + 3
					result[v9] = v5
					result[v10] = v6
					result[v11] = v7
					total += 3
				end

				local v9 = i % v + 1
				local v10 = v3[v9]

				if v10 ~= 0 and v10 ~= v8 then
					local v11 = v9 * 3
					local v12 = list[v11 - 2]
					local v13 = list[v11 - 1]
					local v14 = list[v11]
					local v15 = v2[i] / (v2[i] - v2[v9])
					local v16

					if p == 1 then
						v16 = p4
					elseif p == -1 then
						v16 = -p4
					else
						v16 = v5 + v15 * (v12 - v5)
					end

					local v17

					if p2 == 1 then
						v17 = p4
					elseif p2 == -1 then
						v17 = -p4
					else
						v17 = v6 + v15 * (v13 - v6)
					end

					local v18

					if p3 == 1 then
						v18 = p4
					elseif p3 == -1 then
						v18 = -p4
					else
						v18 = v7 + v15 * (v14 - v7)
					end

					local v19 = total + 1
					local v20 = total + 2
					local v21 = total + 3
					result[v19] = v16
					result[v20] = v17
					result[v21] = v18
					total += 3
				end
			end
		end

		if total < 9 then
			return nil
		end

		return result
	end,
	split = function(list, p, p2, p3, p4, p5)
		local v = #list // 3
		local v2 = table.create(v)
		local v3 = table.create(v)
		local count = 0
		local count2 = 0

		for i = 1, v do
			local v4 = i * 3
			local v5 = list[v4 - 2] * p + list[v4 - 1] * p2 + list[v4] * p3 - p4
			v2[i] = v5

			if p5 < v5 then
				v3[i] = 1
				count += 1
			elseif v5 < -p5 then
				v3[i] = -1
				count2 += 1
			else
				v3[i] = 0
			end
		end

		if count == 0 then
			return nil, list
		end

		if count2 == 0 then
			return list, nil
		end

		local result = {}
		local result2 = {}

		for i = 1, v do
			local v4 = i * 3
			local v5 = list[v4 - 2]
			local v6 = list[v4 - 1]
			local v7 = list[v4]
			local v8 = v3[i]

			if v8 == 0 then
				local v9 = #result2 + 1
				local v10 = #result2 + 2
				local v11 = #result2 + 3
				result2[v9] = v5
				result2[v10] = v6
				result2[v11] = v7
				local v12 = #result + 1
				local v13 = #result + 2
				local v14 = #result + 3
				result[v12] = v5
				result[v13] = v6
				result[v14] = v7
			else
				if v8 == 1 then
					local v9 = #result2 + 1
					local v10 = #result2 + 2
					local v11 = #result2 + 3
					result2[v9] = v5
					result2[v10] = v6
					result2[v11] = v7
				else
					local v9 = #result + 1
					local v10 = #result + 2
					local v11 = #result + 3
					result[v9] = v5
					result[v10] = v6
					result[v11] = v7
				end

				local v9 = i % v + 1
				local v10 = v3[v9]

				if v10 ~= 0 and v10 ~= v8 then
					local v11 = v9 * 3
					local v12 = list[v11 - 2]
					local v13 = list[v11 - 1]
					local v14 = list[v11]
					local v15 = v2[i] / (v2[i] - v2[v9])
					local v16

					if p == 1 then
						v16 = p4
					elseif p == -1 then
						v16 = -p4
					else
						v16 = v5 + v15 * (v12 - v5)
					end

					local v17

					if p2 == 1 then
						v17 = p4
					elseif p2 == -1 then
						v17 = -p4
					else
						v17 = v6 + v15 * (v13 - v6)
					end

					local v18

					if p3 == 1 then
						v18 = p4
					elseif p3 == -1 then
						v18 = -p4
					else
						v18 = v7 + v15 * (v14 - v7)
					end

					local v19 = #result2 + 1
					local v20 = #result2 + 2
					local v21 = #result2 + 3
					result2[v19] = v16
					result2[v20] = v17
					result2[v21] = v18
					local v22 = #result + 1
					local v23 = #result + 2
					local v24 = #result + 3
					result[v22] = v16
					result[v23] = v17
					result[v24] = v18
				end
			end
		end

		if not (#result2 >= 9) then
			result2 = nil
		end

		if #result >= 9 then
			return result2, result
		end

		return result2, nil
	end,
	area = function(list)
		local v = #list // 3

		if v < 3 then
			return 0
		end

		local v2 = list[1]
		local v3 = list[2]
		local v4 = list[3]
		local total = 0
		local total2 = 0
		local total3 = 0

		for i = 2, v - 1 do
			local v5 = list[i * 3 - 2] - v2
			local v6 = list[i * 3 - 1] - v3
			local v7 = list[i * 3] - v4
			local v8 = list[i * 3 + 1] - v2
			local v9 = list[i * 3 + 2] - v3
			local v10 = list[i * 3 + 3] - v4
			total += v6 * v10 - v7 * v9
			total2 += v7 * v8 - v5 * v10
			total3 += v5 * v9 - v6 * v8
		end

		return math.sqrt(total * total + total2 * total2 + total3 * total3) * 0.5
	end
}

function Winding.contains(list, p, p2, p3, list2, p4)
	local v = #list // 3

	for i = 1, v do
		local v2 = i % v + 1
		local v3 = list[i * 3 - 2]
		local v4 = list[i * 3 - 1]
		local v5 = list[i * 3]
		local v6 = list[v2 * 3 - 2] - v3
		local v7 = list[v2 * 3 - 1] - v4
		local v8 = list[v2 * 3] - v5
		local v9 = p2 * v8 - p3 * v7
		local v10 = p3 * v6 - p * v8
		local v11 = p * v7 - p2 * v6
		local v12 = math.sqrt(v9 * v9 + v10 * v10 + v11 * v11)

		if v12 < 1e-9 then
			continue
		end

		local v13 = v9 / v12
		local v14 = v10 / v12
		local v15 = v11 / v12
		local v16 = v13 * v3 + v14 * v4 + v15 * v5
		local center, v17, v18 = Winding.center(list)

		if v13 * center + v14 * v17 + v15 * v18 - v16 < 0 then
			v13 = -v13
			v14 = -v14
			v15 = -v15
			v16 = -v16
		end

		for j = 1, #list2, 3 do
			if v13 * list2[j] + v14 * list2[j + 1] + v15 * list2[j + 2] - v16 < -p4 then
				return false
			end
		end
	end

	return true
end

function Winding.reverse(list)
	local v = #list // 3
	local result = table.create(#list)

	for i = 1, v do
		local v2 = v + 1 - i
		local v3 = i * 3 - 2
		local v4 = i * 3 - 1
		local v5 = i * 3
		local v6 = list[v2 * 3 - 2]
		local v7 = list[v2 * 3 - 1]
		local v8 = list[v2 * 3]
		result[v3] = v6
		result[v4] = v7
		result[v5] = v8
	end

	return result
end

function Winding.range(list, p, p2, p3, p4)
	local v = 1e999
	local v2 = -1e999

	for i = 1, #list, 3 do
		local v3 = list[i] * p + list[i + 1] * p2 + list[i + 2] * p3 - p4

		if v3 < v then
			v = v3
		end

		if v2 < v3 then
			v2 = v3
		end
	end

	return v, v2
end

function Winding.center(list)
	local v = #list // 3
	local total = 0
	local total2 = 0
	local total3 = 0

	for i = 1, #list, 3 do
		total += list[i]
		total2 += list[i + 1]
		total3 += list[i + 2]
	end

	return total / v, total2 / v, total3 / v
end

function Winding.bounds(list)
	local v = 1e999
	local v2 = 1e999
	local v3 = 1e999
	local v4 = -1e999
	local v5 = -1e999
	local v6 = -1e999

	for i = 1, #list, 3 do
		local v7 = list[i]
		local v8 = list[i + 1]
		local v9 = list[i + 2]

		if v7 < v then
			v = v7
		end

		if v8 < v2 then
			v2 = v8
		end

		if v9 < v3 then
			v3 = v9
		end

		if v4 < v7 then
			v4 = v7
		end

		if v5 < v8 then
			v5 = v8
		end

		if v6 < v9 then
			v6 = v9
		end
	end

	return v, v2, v3, v4, v5, v6
end

function Winding.planeFromPoints(p, p2, p3, p4, p5, p6, p7, p8, p9)
	local v = p4 - p
	local v2 = p5 - p2
	local v3 = p6 - p3
	local v4 = p7 - p
	local v5 = p8 - p2
	local v6 = p9 - p3
	local v7 = v2 * v6 - v3 * v5
	local v8 = v3 * v4 - v * v6
	local v9 = v * v5 - v2 * v4
	local v10 = math.sqrt(v7 * v7 + v8 * v8 + v9 * v9)

	if v10 < 1e-6 then
		return nil
	end

	local v11 = v7 / v10
	local v12 = v8 / v10
	local v13 = v9 / v10
	return v11, v12, v13, v11 * p + v12 * p2 + v13 * p3
end

function Winding.planeKey(p, p2, p3, p4)
	local v

	if p < -1e-6 then
		v = true
	elseif math.abs(p) <= 1e-6 then
		if p2 < -1e-6 then
			v = true
		elseif math.abs(p2) <= 1e-6 then
			v = p3 < 0
		else
			v = false
		end
	else
		v = false
	end

	if not v then
		return string.format("%.4f,%.4f,%.4f,%.2f", p, p2, p3, p4)
	end

	p = -p
	p2 = -p2
	p3 = -p3
	p4 = -p4
	return string.format("%.4f,%.4f,%.4f,%.2f", p, p2, p3, p4)
end

function Winding.isAxial(p, p2, p3)
	return math.abs(p) > 0.9999 or math.abs(p2) > 0.9999 or math.abs(p3) > 0.9999
end

return Winding