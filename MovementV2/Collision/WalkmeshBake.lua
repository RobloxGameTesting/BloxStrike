require(script.Parent.Catalog)
local Geometry = require(script.Parent.Geometry)
local Schema = require(script.Parent.Schema)
require(script.Parent.TopologyConfig)

local function triangleBounds(vector: Vector3, vector2: Vector3, vector3: Vector3)
	return Geometry.Min(Geometry.Min(vector, vector2), vector3), Geometry.Max(Geometry.Max(vector, vector2), vector3)
end

return table.freeze({
	Build = function(data, vector: Vector3, data2)
		assert(data.Kind == Schema.SourceKind.Walkmesh, "WalkmeshBake accepts only Walkmesh sources")
		local v = assert(data.Walkmesh, "walkmesh source is missing decoded mesh data")
		local cframe = data.Geometry.CFrame
		local v2 = table.create(v.VertexCount)

		for k, v3 in v.Vertices do
			v2[k] = cframe:PointToWorldSpace(v3)
		end

		local count = 0
		local result = {}

		for k, triangle in v.Triangles do
			local v3 = v2[triangle.A]
			local v4 = v2[triangle.B]
			local v5 = v2[triangle.C]
			local cross = (v4 - v3):Cross(v5 - v3)
			local magnitude = cross.Magnitude

			if magnitude <= data2.PlaneNormalEpsilon then
				count += 1
			else
				local normal = cross / magnitude

				if normal.Y < 0 then
					normal = -normal
					v5, v4 = v4, v5
				end

				local vector2 = Vector3.new(0, vector.Y, 0)
				local vector3 = v3 + vector2
				local v6 = v4 + vector2
				local v7 = v5 + vector2
				local min = Geometry.Min(Geometry.Min(vector3, v6), v7)
				local max = Geometry.Max(Geometry.Max(vector3, v6), v7)
				local expandBounds, aabbMax = Geometry.ExpandBounds(
					min,
					max,
					vector + Vector3.new(
						data2.WalkmeshBoundsPadding,
						data2.WalkmeshBoundsPadding,
						data2.WalkmeshBoundsPadding
					)
				)
				result[#result + 1] = table.freeze({
					RecordType = "Walkmesh",
					SourceId = data.SourceId,
					Kind = data.Kind,
					DestructibleIndex = nil,
					ElementId = k,
					SurfaceFriction = data2.SurfaceFriction,
					A = vector3,
					B = v6,
					C = v7,
					Normal = normal,
					Distance = vector3:Dot(normal),
					AabbMin = expandBounds,
					AabbMax = aabbMax
				})
			end
		end

		table.freeze(result)
		return result, count
	end
})