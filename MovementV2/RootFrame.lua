local Config = require(script.Parent.Simulation.Config)
require(script.Parent.Types)
local v = { DefaultRootHeightFromFeet = 3 }

local function halfHeight(p, p2) -- 2 equivalent calls inferred from this helper
	local v2

	if p == "Ducking" then
		v2 = p2.PlayerSizeDucking.Y
	else
		v2 = p2.PlayerSizeStanding.Y
	end

	return v2 * 0.5
end

function v.visualStance(value: number?)
	if (value or 0) >= 0.999 then
		return "Ducking"
	end

	return "Standing"
end

function v.getDuckRootVerticalOffset(value: number?, flag: boolean?, p)
	if flag ~= false then
		return 0
	end

	local v2 = p or Config.Default
	return (v2.PlayerSizeStanding.Y - v2.PlayerSizeDucking.Y) * (v2.DuckJumpOriginShiftFraction + 0.5) * math.clamp(value or 0, 0, 1)
end

function v.rootToSimulationPosition(vector: Vector3, p, p2: number?, p3)
	local v2 = p3 or Config.Default
	local v3 = p2 or v.DefaultRootHeightFromFeet
	return vector + Vector3.new(0, halfHeight(p, v2) - v3, 0) -- inferred equivalent call
end

function v.simulationToRootPosition(vector: Vector3, p, p2: number?, p3)
	local v2 = p3 or Config.Default
	local v3 = p2 or v.DefaultRootHeightFromFeet
	return vector - Vector3.new(0, halfHeight(p, v2) - v3, 0) -- inferred equivalent call
end

function v.simulationToVisualRootPosition(vector: Vector3, p: number?, p2: number?, p3)
	return v.simulationToRootPosition(vector, v.visualStance(p), p2, p3)
end

function v.stateToRootPosition(p, p2: number?, p3)
	return v.simulationToVisualRootPosition(p.Position, p.DuckAmount, p2, p3)
end

function v.cframe(p, p2: number?, p3)
	return CFrame.new(v.stateToRootPosition(p, p2, p3)) * CFrame.Angles(0, p.LookYaw, 0)
end

return table.freeze(v)