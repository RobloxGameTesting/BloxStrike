local Config = require(script.Parent.Parent.Simulation.Config)

local function finitePositive(value) -- 3 equivalent calls inferred from this helper
	return typeof(value) == "number" and value == value and value > 0 and value < 1e999
end

local function integerAtLeast(value, p: number)
	local v

	if typeof(value) == "number" and value == value and value > 0 then
		v = value < 1e999
	else
		v = false
	end

	if v then
		if value % 1 == 0 then
			return p <= value
		else
			return false
		end
	end

	return v
end

local v = {
	Resolve = function(p, options)
		local v = p or Config.Default
		local v2 = options or {}
		local cellSize = v2.CellSize or 8
		local maxCellsPerRecord = v2.MaxCellsPerRecord or 4096
		local maxSweepDistance = v2.MaxSweepDistance or 1000
		assert(finitePositive(cellSize), "collision cell size must be positive") -- inferred equivalent call
		local v3

		if
			typeof(maxCellsPerRecord) == "number"
			and maxCellsPerRecord == maxCellsPerRecord
			and maxCellsPerRecord > 0
		then
			v3 = maxCellsPerRecord < 1e999
		else
			v3 = false
		end

		if v3 then
			if maxCellsPerRecord % 1 == 0 then
				v3 = maxCellsPerRecord >= 1
			else
				v3 = false
			end
		end

		assert(v3, "max cells per collision record must be a positive integer")
		assert(finitePositive(maxSweepDistance), "maximum collision sweep distance must be positive") -- inferred equivalent call
		local v4 = v.PlayerSizeStanding.X > 0 and v.PlayerSizeStanding.Y > 0 and v.PlayerSizeStanding.Z > 0
		assert(v4)
		local v5 = v.PlayerSizeDucking.X > 0 and v.PlayerSizeDucking.Y > 0 and v.PlayerSizeDucking.Z > 0
		assert(v5)
		assert(
			v.PlayerSizeDucking.Y <= v.PlayerSizeStanding.Y,
			"ducking collision height cannot exceed standing height"
		)
		local v6 = v.WalkableFloor > 0 and v.WalkableFloor <= 1
		assert(v6, "walkable-floor normal threshold must be in (0, 1]")
		local groundProbeStartBump = v.GroundProbeStartBump
		assert(
			finitePositive(groundProbeStartBump) and v.GroundProbeStartBump < maxSweepDistance, -- inferred equivalent call
			"ground-probe start bump must be positive and below the maximum sweep distance"
		)
		assert(v.SurfaceFrictionDefault >= 0, "default surface friction cannot be negative")
		return (table.freeze({
			StandingHalfSize = v.PlayerSizeStanding * 0.5,
			DuckingHalfSize = v.PlayerSizeDucking * 0.5,
			CellSize = cellSize,
			MaxCellsPerRecord = maxCellsPerRecord,
			MaxSweepDistance = maxSweepDistance,
			PlaneNormalEpsilon = 0.001,
			PlaneDuplicateDot = 0.9999999,
			ContactEpsilon = 0.0001,
			BroadphasePadding = 0.1,
			HitTieDistance = 0.03125 * v.HammerUnitToStud,
			BrushEpsilon = 0.03125 * v.HammerUnitToStud,
			SupportEdgeOwnershipTolerance = 0.0625 * v.HammerUnitToStud,
			FloorContactEpsilon = 0.02,
			FloorSupportContactEpsilon = 0.001,
			FloorTriangleEdgeSlop = 0.06,
			FloorStartSolidRecoveryDepth = math.max(0.05, v.MaxStepHeight + 0.02),
			WalkmeshBoundsPadding = 0.05,
			GroundProbeStartBump = v.GroundProbeStartBump,
			WalkableFloor = v.WalkableFloor,
			SurfaceFriction = v.SurfaceFrictionDefault
		}))
	end
}
v.Default = v.Resolve()
return table.freeze(v)