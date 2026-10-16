local createVector = vector.create
local v = {}

local function quantize(p: number, p2: number) -- 3 equivalent calls inferred from this helper
	return (math.round(p / p2))
end

local function appendOrientedBox(list, vector: Vector3, rightVector: Vector3, vector2: Vector3, lookVector: Vector3, p: number, p2: number, p3: number, p4: number)
	for i = 0, 1 do
		local v2

		if i == 1 then
			v2 = vector2 * p3
		else
			v2 = vector2 * -p2
		end

		for j = -1, 1, 2 do
			list[#list + 1] = vector + v2 + rightVector * (p * j) + lookVector * (p4 * -1)
			list[#list + 1] = vector + v2 + rightVector * (p * j) + lookVector * (p4 * 1)
		end
	end
end

v.appendOrientedBox = appendOrientedBox

function v.orientedBox(vector: Vector3, p: number, p2: number, p3: number, p4: number, p5: number)
	local cframe = CFrame.Angles(0, p, 0)
	local v2 = table.create(8)
	appendOrientedBox(v2, vector, cframe.RightVector, createVector(0, 1, 0), cframe.LookVector, p2, p3, p4, p5)
	return v2
end

function v.orientedPartBox(cframe: CFrame, vector: Vector3, value: number?)
	local v2 = math.max(value or 0, 0)
	local v3 = vector * 0.5 + createVector(1, 1, 1) * v2
	local result = table.create(8)

	for _, v4 in { -1, 1 } do
		for _, v5 in { -1, 1 } do
			for _, v6 in { -1, 1 } do
				result[#result + 1] = cframe:PointToWorldSpace((Vector3.new(v3.X * v4, v3.Y * v5, v3.Z * v6)))
			end
		end
	end

	return result
end

function v.capsuleBox(vector: Vector3, vector2: Vector3, p: number)
	local v2 = vector2 - vector
	local magnitude = v2.Magnitude
	local vector3 = not (magnitude > 0.00001) and createVector(0, 1, 0) or v2 / magnitude
	local unit = vector3:Cross(math.abs((vector3:Dot(createVector(0, 1, 0)))) < 0.9 and createVector(0, 1, 0) or createVector(1, 0, 0)).Unit
	local unit2 = unit:Cross(vector3).Unit
	local v3 = math.max(p, 0)
	local v4 = vector - vector3 * v3
	local v5 = vector2 + vector3 * v3
	local result = table.create(8)

	for _, v6 in { v4, v5 } do
		for _, v7 in { -1, 1 } do
			for _, v8 in { -1, 1 } do
				result[#result + 1] = v6 + unit * (v3 * v7) + unit2 * (v3 * v8)
			end
		end
	end

	return result
end

function v.pointBoxes(list, p: number)
	local v2 = createVector(1, 1, 1) * math.max(p, 0)
	local result = table.create(#list)

	for _, v3 in list do
		local v4 = v3 - v2
		local v5 = v3 + v2
		local vectors = table.create(8)

		for i = 0, 1 do
			for j = 0, 1 do
				for k = 0, 1 do
					local v6 = #vectors + 1
					local x

					if i == 0 then
						x = v4.X
					else
						x = v5.X
					end

					local y

					if j == 0 then
						y = v4.Y
					else
						y = v5.Y
					end

					local v7

					if k == 0 then
						v7 = v4.Z
					else
						v7 = v5.Z
					end

					vectors[v6] = Vector3.new(x, y, v7)
				end
			end
		end

		result[#result + 1] = vectors
	end

	return result
end

function v.animatedCapsuleFallback(vector: Vector3, p: number, value: number, vector2: Vector3, p2: number, p3: number, p4: number, p5: number, value2: number?)
	local v2 = math.max(p5, 0)
	local v3 = math.max(value2 or 0, 0)
	local v4 = vector2.X + p2 + v2
	local v5 = vector2.Z + p2 + v2
	local v6 = { (v.orientedBox(vector, p, v4, vector2.Y + v3 + v2, vector2.Y + p3 + v2, v5)) }

	if p4 <= 0 then
		return v6
	end

	local lookVector = CFrame.Angles(0, p, 0).LookVector
	local v7 = math.clamp(value, -1, 1)
	local v8 = lookVector * math.sqrt((math.max(1 - v7 * v7, 0))) + createVector(0, 1, 0) * v7
	local v9 = math.max(0.65, vector2.X + p2) + v2
	local v10 = math.max(vector2.Y * 0.25, 0.5)
	local v11 = vector + createVector(0, 1, 0) * v10 + lookVector * math.max(vector2.Z * 0.5, 0.25)
	local v12 = v11 + v8 * (vector2.Z + p2 + p4)
	v6[#v6 + 1] = v.capsuleBox(v11, v12, v9)
	return v6
end

function v.fingerprint(list, value: number?)
	local v2 = value or 0.05
	local v3 = (v2 <= 0 or v2 ~= v2) and 0.05 or v2
	local v4 = table.create(#list + 1)
	v4[1] = tostring(#list)

	for k, v5 in list do
		v4[k + 1] = `{quantize(v5.X, v3)},{quantize(v5.Y, v3)},{quantize(v5.Z, v3)}` -- inferred equivalent call
	end

	return table.concat(v4, ";")
end

function v.orientedBodyFallback(vector: Vector3, p: number, vector2: Vector3, p2: number, p3: number, p4: number, value: number?)
	local cframe = CFrame.Angles(0, p, 0)
	local rightVector = cframe.RightVector
	local lookVector = cframe.LookVector
	local v2 = vector2.X + p2
	local v3 = vector2.Z + p2
	local v4 = vector2.Y + math.max(value or 0, 0)
	local v5 = vector2.Y + p3
	local v6 = {}
	appendOrientedBox(v6, vector, rightVector, createVector(0, 1, 0), lookVector, v2, v4, v5, v3)
	v6[#v6 + 1] = vector + lookVector * (v3 + p4) + createVector(0, 1, 0) * math.max(vector2.Y * 0.35, 0.5)
	return v6
end

return table.freeze(v)