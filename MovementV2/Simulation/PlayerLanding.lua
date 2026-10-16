require(script.Parent.Parent.Types)
require(script.Parent.Config)
require(script.Parent.DeterminismTrace)
local PlayerContacts = require(script.Parent.PlayerContacts)
require(script.Parent.PlayerHullClearance)
local ProvenCollisionAdapter = require(script.Parent.ProvenCollisionAdapter)
local ProvenSimulator = require(script.Parent.ProvenSimulator)
require(script.Parent.Types)
local v = {
	needsStanding = function(p)
		return p.JumpHullActive and p.DuckAmount < 0.999
	end
}

function v.queryHalfSize(p, data)
	if v.needsStanding(p) then
		return data.PlayerSizeStanding * 0.5 + Vector3.new(0, data.GroundProbeDistance + data.PositionSnapEpsilon, 0)
	end

	local v2

	if p.Stance == "Ducking" then
		v2 = data.PlayerSizeDucking
	else
		v2 = data.PlayerSizeStanding
	end

	return v2 * 0.5
end

function v.prepare(p, state, items, object, data, p2, p3)
	if not v.needsStanding(p) or p.OnGround or state.WorldVelocity.Y > data.VelocityEpsilon then
		return false
	end

	local v2 = data.PlayerSizeDucking * 0.5
	local v3 = data.PlayerSizeStanding * 0.5
	local defaultContactEpsilon = PlayerContacts.DefaultContactEpsilon
	local defaultSeparationSkin = PlayerContacts.DefaultSeparationSkin
	local v4 = state.StartPosition.Y - v2.Y
	local v5 = state.Position.Y - v3.Y
	local v6 = -1e999
	local v7 = nil

	for _, item in items do
		if item.Id == state.Id then
			continue
		end

		local v8

		if item.Stance == "Ducking" then
			v8 = data.PlayerSizeDucking
		else
			v8 = data.PlayerSizeStanding
		end

		local v9 = v8 * 0.5
		local v10 = item.Position.Y + v9.Y
		local v11 = state.Position - item.Position

		if not (v10 - defaultContactEpsilon - defaultSeparationSkin <= v4 and v5 <= v10 + data.GroundProbeDistance + data.PositionSnapEpsilon and math.abs(v11.X) < v3.X + v9.X - defaultContactEpsilon) then
			continue
		end

		if not (math.abs(v11.Z) < v3.Z + v9.Z - defaultContactEpsilon and (v6 < v10 or v10 == v6 and v7 ~= nil and item.Id < v7.Id)) then
			continue
		end

		v7 = item
		v6 = v10
	end

	if v7 == nil then
		return false
	end

	local vector = Vector3.new(state.Position.X, v6 + v2.Y + defaultSeparationSkin, state.Position.Z)

	if not object:CanMove(state.Position, vector, "Ducking", nil, 1, 1) then
		return false
	end

	local v8 = ProvenCollisionAdapter.new(object, data, nil, p3, nil, p2)
	local v9, position = ProvenSimulator.checkStandingClearance(vector, v8, data)

	if v9 then
		return false
	end

	state.Position = position
	state.Stance = "Standing"
	return true
end

function v.restoreWorldGround(p, object, p2, p3, p4)
	local v2 = ProvenCollisionAdapter.new(object, p2, p.Support, p4, nil, p3)
	local v3, v4 = ProvenSimulator.checkStandingClearance(p.Position, v2, p2)

	if v3 then
		return nil
	end

	local ground = object:FindGround(v4, "Standing", p2.GroundProbeDistance, 1, p.Support)

	if ground == nil then
		return nil
	end

	local pointTest = v2:PointTest(ground.Position, "standing", true)

	if pointTest.startSolid or pointTest.allSolid then
		return nil
	end

	return ground
end

return table.freeze(v)