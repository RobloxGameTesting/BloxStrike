local CanonicalGeometry = require(script.Parent.CanonicalGeometry)
local Schema = require(script.Parent.Schema)
local v = {}

local function isFinite(p: number) -- 3 equivalent calls inferred from this helper
	return p == p and p > -1e999 and p < 1e999
end

function v.Decode(str)
	if typeof(str) ~= "string" then
		return nil, "walkmesh payload must be a string"
	end

	local count = #Schema.WalkmeshHeader

	if #str < count + 8 or string.sub(str, 1, count) ~= Schema.WalkmeshHeader then
		return nil, "walkmesh payload is missing the MLWALK1 header"
	end

	local buf = buffer.fromstring(str)
	local vertexCount = buffer.readu32(buf, count)

	if vertexCount == 0 or Schema.MaxWalkmeshVertices < vertexCount then
		return nil, string.format("walkmesh vertex count must be in [1, %d]", Schema.MaxWalkmeshVertices)
	end

	local v2 = count + 4
	local v3 = v2 + vertexCount * 12

	if v3 + 4 > #str then
		return nil, "walkmesh payload ends inside its vertex array"
	end

	local triangleCount = buffer.readu32(buf, v3)

	if triangleCount == 0 or Schema.MaxWalkmeshTriangles < triangleCount then
		return nil, string.format("walkmesh triangle count must be in [1, %d]", Schema.MaxWalkmeshTriangles)
	end

	local v4 = v3 + 4
	local v5 = v4 + triangleCount * 13

	if v5 ~= #str then
		return nil, string.format("walkmesh payload has %d bytes; expected exactly %d", #str, v5)
	end

	local vectors = table.create(vertexCount)

	for i = 1, vertexCount do
		local v6 = buffer.readf32(buf, v2)
		local v7 = buffer.readf32(buf, v2 + 4)
		local v8 = buffer.readf32(buf, v2 + 8)
		v2 += 12

		if not isFinite(v6) then -- inferred equivalent call
			return nil, string.format("walkmesh vertex %d contains a non-finite component", i)
		end

		if isFinite(v7) and isFinite(v8) then -- inferred equivalent call
			vectors[i] = Vector3.new(v6, v7, v8)
			continue
		end

		return nil, string.format("walkmesh vertex %d contains a non-finite component", i)
	end

	local values = table.create(triangleCount)

	for i = 1, triangleCount do
		local v6 = buffer.readu32(buf, v4)
		local v7 = buffer.readu32(buf, v4 + 4)
		local v8 = buffer.readu32(buf, v4 + 8)
		local flags = buffer.readu8(buf, v4 + 12)
		v4 += 13

		if v6 < 1 or vertexCount < v6 or v7 < 1 or vertexCount < v7 or v8 < 1 or vertexCount < v8 then
			return nil, string.format("walkmesh triangle %d references a vertex outside [1, %d]", i, vertexCount)
		end

		if v6 == v7 or v7 == v8 or v6 == v8 then
			return nil, string.format("walkmesh triangle %d repeats a vertex index", i)
		end

		local v9 = vectors[v6]
		local v10 = vectors[v7]
		local v11 = vectors[v8]

		if (v10 - v9):Cross(v11 - v9).Magnitude <= 1e-8 then
			return nil, string.format("walkmesh triangle %d is degenerate", i)
		else
			values[i] = table.freeze({ A = v6, B = v7, C = v8, Flags = flags })
		end
	end

	table.freeze(vectors)
	table.freeze(values)
	return table.freeze({
		Vertices = vectors,
		Triangles = values,
		VertexCount = vertexCount,
		TriangleCount = triangleCount,
		Fingerprint = CanonicalGeometry.Crc32(str)
	}), nil
end

function v.ReadPublished(instance)
	local attribute = instance:GetAttribute(Schema.Attributes.WalkmeshData)
	local decoded, v2 = v.Decode(attribute)

	if decoded == nil then
		return
			nil,
			string.format(
				"%s has invalid %s: %s",
				instance:GetFullName(),
				Schema.Attributes.WalkmeshData,
				v2 or "unknown error"
			)
	end

	return decoded, nil
end

return table.freeze(v)