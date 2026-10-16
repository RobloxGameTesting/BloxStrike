local BrushHullBuilder = require(script.Parent.BrushHullBuilder)
require(script.Parent.Catalog)
require(script.Parent.Geometry)
local Schema = require(script.Parent.Schema)
require(script.Parent.TopologyConfig)

local function convertPlane(data, points)
	local flatNormal = nil
	local flatDistance = nil

	if math.abs(data.n.Y) <= 0.0001 and #points > 0 then
		local vector = Vector3.new(data.n.X, 0, data.n.Z)

		if vector.Magnitude > 1e-6 then
			local unit = vector.Unit
			local v = -1e999

			for _, vector2 in points do
				v = math.max(v, vector2:Dot(unit))
			end

			if v ~= -1e999 then
				flatDistance = v
				flatNormal = unit
			end
		end
	end

	return (table.freeze({
		Normal = data.n,
		Distance = data.ed,
		PlaneId = data.planeNum,
		MinkowskiPlaneKind = data.minkowskiPlaneKind,
		FlatNormal = flatNormal,
		FlatDistance = flatDistance
	}))
end

local function convertRecord(data, data2, elementId: number)
	local planes = table.create(#data.hull)

	for k, v in data.hull do
		planes[k] = convertPlane(v, data.points)
	end

	table.freeze(planes)
	local clone = table.clone(data.points)
	table.freeze(clone)
	local ladderPlanes

	if data2.Climbable then
		ladderPlanes = planes
	else
		ladderPlanes = table.freeze({})
	end

	return (table.freeze({
		RecordType = "Hull",
		SourceId = data2.SourceId,
		Kind = data2.Kind,
		DestructibleIndex = data2.DestructibleIndex,
		ElementId = elementId,
		Climbable = data2.Climbable,
		SurfaceFriction = data.surfaceFriction,
		Planes = planes,
		LadderPlanes = ladderPlanes,
		Points = clone,
		BuildMode = data.buildMode,
		SourceShape = data.sourceShape,
		SourceCFrame = data.sourceCFrame,
		SourceSize = data.sourceSize,
		AabbMin = data.aabbMin,
		AabbMax = data.aabbMax
	}))
end

return table.freeze({
	Build = function(p, vector: Vector3, _, value: number?)
		assert(
			p.Kind == Schema.SourceKind.Barrier or p.Kind == Schema.SourceKind.Destructible,
			"HullBake accepts only Barrier or Destructible sources"
		)
		assert(p.Instance:IsA("BasePart"), "brush sources must be BaseParts")
		local hullRecord, v = BrushHullBuilder.BuildHullRecord(p.Instance, vector * 2, value or 0)
		return convertRecord(hullRecord, p, 0), v
	end,
	FindMergedSourceGroups = function(items)
		local v = {}
		local instances = {}

		for _, item in items do
			if
				item.Kind ~= Schema.SourceKind.Barrier
				or not item.Instance:IsA("BasePart")
				or (item.Climbable or item.DisableSeamMerge)
			then
				continue
			end

			v[item.Instance] = item
			instances[#instances + 1] = item.Instance
		end

		local mergedPartGroups = BrushHullBuilder.FindMergedPartGroups(instances)
		local result = {}

		for _, mergedPartGroup in mergedPartGroups do
			local v2 = {}

			for _, v3 in mergedPartGroup do
				local v4 = v[v3]

				if v4 ~= nil then
					v2[#v2 + 1] = v4
				end
			end

			table.sort(v2, function(a, b)
				return a.SourceId < b.SourceId
			end)

			if #v2 >= 2 then
				result[#result + 1] = v2
			end
		end

		table.sort(result, function(a, b)
			return a[1].SourceId < b[1].SourceId
		end)
		return result
	end,
	BuildMerged = function(list, vector: Vector3, _, value: number?)
		assert(#list >= 2, "merged hull requires at least two sources")
		local instances = table.create(#list)

		for k, v in list do
			assert(v.Kind == Schema.SourceKind.Barrier, "destructibles cannot be merged")
			assert(v.Instance:IsA("BasePart"), "merged brush sources must be BaseParts")
			instances[k] = v.Instance
		end

		local mergedHullRecord, v = BrushHullBuilder.BuildMergedHullRecord(instances, vector * 2, value or 0)
		return convertRecord(mergedHullRecord, list[1], 0), v
	end
})