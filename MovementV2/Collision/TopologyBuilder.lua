require(script.Parent.Catalog)
require(script.Parent.Geometry)
local HullBake = require(script.Parent.HullBake)
local Schema = require(script.Parent.Schema)
local SpatialGrid = require(script.Parent.SpatialGrid)
local TopologyConfig = require(script.Parent.TopologyConfig)
local WalkmeshBake = require(script.Parent.WalkmeshBake)
require(script.Parent.Parent.Simulation.Config)

local function buildStanceRecords(p, vector: Vector3, resolved, mergedSourceGroups, callback)
	local v = 0
	local result = {}
	local v2 = {}
	local count = 0
	local sourceId = 0
	local count2 = 0
	local total = 0

	for _, item in mergedSourceGroups do
		local v3
		v3, v = HullBake.BuildMerged(item, vector, resolved, v)
		result[#result + 1] = v3

		for _, v4 in item do
			v2[v4.SourceId] = true
			count += 1
		end

		if callback ~= nil then
			callback()
		end
	end

	for _, source in p.Sources do
		assert(sourceId < source.SourceId, "catalog sources must be strictly ordered by SourceId")
		sourceId = source.SourceId

		if v2[source.SourceId] then
			continue
		end

		if source.Kind == Schema.SourceKind.Barrier or source.Kind == Schema.SourceKind.Destructible then
			count += 1
			local v3
			v3, v = HullBake.Build(source, vector, resolved, v)
			result[#result + 1] = v3

			if callback ~= nil then
				callback()
			end
		elseif source.Kind == Schema.SourceKind.Walkmesh then
			count2 += 1
			local v3, v4 = WalkmeshBake.Build(source, vector, resolved)
			total += v4

			for _, v5 in v3 do
				result[#result + 1] = v5
			end
		else
			error(string.format("catalog source %d has unsupported kind %s", source.SourceId, (tostring(source.Kind))))
		end
	end

	table.freeze(result)
	return result, count, count2, total
end

local function assertPairedRecords(stanceRecords, stanceRecords2)
	assert(#stanceRecords == #stanceRecords2, "standing/ducking collision record counts must match")

	for k, v in stanceRecords do
		local v2 = stanceRecords2[k]
		local v3 = v.RecordType == v2.RecordType
			and v.SourceId == v2.SourceId
			and v.Kind == v2.Kind
			and v.DestructibleIndex == v2.DestructibleIndex
			and v.ElementId == v2.ElementId
		assert(v3, "standing/ducking collision record order must match")
	end
end

return table.freeze({
	LargeSourceCount = 4000,
	createFrameYielder = function(p: number)
		local lastTime = os.clock()
		return function()
			if p <= os.clock() - lastTime then
				task.wait()
				lastTime = os.clock()
			end
		end
	end,
	Build = function(p, p2, p3, callback)
		local v = p.Manifest.Epoch >= 1 and p.Manifest.Epoch <= 65535
		assert(v, "collision epoch must fit non-zero u16")
		assert(p.Manifest.SourceCount == #p.Sources, "catalog source count changed after validation")
		assert(p.Manifest.SourceCount > 0, "MovementV2 map has no Barrier, Destructible, or Walkmesh sources")
		local resolved = TopologyConfig.Resolve(p2, p3)
		local mergedSourceGroups = HullBake.FindMergedSourceGroups(p.Sources)
		local stanceRecords, hullSourceCount, walkmeshSourceCount, skippedWalkmeshTriangleCount = buildStanceRecords(
			p,
			resolved.StandingHalfSize,
			resolved,
			mergedSourceGroups,
			callback
		)
		local stanceRecords2, v2, v3, v4 = buildStanceRecords(
			p,
			resolved.DuckingHalfSize,
			resolved,
			mergedSourceGroups,
			callback
		)
		local v5 = hullSourceCount == v2 and walkmeshSourceCount == v3 and skippedWalkmeshTriangleCount == v4
		assert(v5)
		local v6 = #stanceRecords > 0 and #stanceRecords2 > 0
		assert(v6, "MovementV2 map produced no usable Barrier, Destructible, or Walkmesh collision records")
		assertPairedRecords(stanceRecords, stanceRecords2)
		local hasClimbable = false

		for _, stanceRecord in stanceRecords do
			if not (stanceRecord.RecordType == "Hull" and stanceRecord.Climbable) then
				continue
			end

			hasClimbable = true
			break
		end

		local grid = SpatialGrid.Build(stanceRecords, resolved.CellSize, resolved.MaxCellsPerRecord, stanceRecords2)
		table.freeze(grid)
		local frozen = table.freeze({ Records = stanceRecords, Grid = grid })
		local frozen2 = table.freeze({ Records = stanceRecords2, Grid = grid })
		local frozen3 = table.freeze({
			HullSourceCount = hullSourceCount,
			WalkmeshSourceCount = walkmeshSourceCount,
			StandingRecordCount = #stanceRecords,
			DuckingRecordCount = #stanceRecords2,
			SkippedWalkmeshTriangleCount = skippedWalkmeshTriangleCount
		})
		return (table.freeze({
			Epoch = p.Manifest.Epoch,
			Fingerprint = p.Manifest.Fingerprint,
			SourceCount = p.Manifest.SourceCount,
			DestructibleCount = p.Manifest.DestructibleCount,
			HasClimbable = hasClimbable,
			Config = resolved,
			Standing = frozen,
			Ducking = frozen2,
			Stats = frozen3
		}))
	end
})