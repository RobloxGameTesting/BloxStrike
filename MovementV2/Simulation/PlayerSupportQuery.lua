local createVector = vector.create
local Enums = require(script.Parent.Parent.Enums)
require(script.Parent.Parent.Types)
require(script.Parent.Config)
require(script.Parent.Types)
local class = {}
class.__index = class

local function halfSize(p, config) -- 2 equivalent calls inferred from this helper
	local v

	if p == "Ducking" then
		v = config.PlayerSizeDucking
	else
		v = config.PlayerSizeStanding
	end

	return v * 0.5
end

local function playerGround(data, vector: Vector3, p, p2: number)
	local position = data.Motion.Position
	local stance = data.Motion.Stance

	if position == nil or stance == nil then
		return nil
	end

	local v = halfSize(p, data.Config) -- inferred equivalent call
	local v2 = halfSize(stance, data.Config) -- inferred equivalent call
	local positionSnapEpsilon = data.Config.PositionSnapEpsilon
	local v3 = vector - position

	if math.abs(v3.X) >= v.X + v2.X or math.abs(v3.Z) >= v.Z + v2.Z then
		return nil
	end

	local v4 = position.Y + v2.Y
	local v5 = vector.Y - v.Y - v4

	if v5 < -((data.Config.GroundProbeStartBump or 0) + positionSnapEpsilon) or p2 + positionSnapEpsilon < v5 then
		return nil
	end

	local vector2 = Vector3.new(vector.X, v4 + v.Y, vector.Z)
	local velocity = data.Motion.Velocity
	return {
		Position = vector2,
		Normal = createVector(0, 1, 0),
		SurfaceFriction = data.Config.SurfaceFrictionDefault,
		Support = {
			Kind = Enums.SupportKind.Player,
			SourceId = data.Support.SourceId,
			Anchor = vector2 - position,
			Velocity = Vector3.new(velocity.X, 0, velocity.Z)
		}
	}
end

function class.FindPlayerGround(p, vector: Vector3, p2, p3: number)
	return (playerGround(p, vector, p2, p3))
end

function class.new(base, support, motion, config)
	local v = support.Kind == Enums.SupportKind.Player and support.SourceId ~= 0
	assert(v, "player support query requires player ground")
	local v2 = motion.Kind == support.Kind and motion.SourceId == support.SourceId
	assert(v2, "player support motion identity mismatch")
	return (setmetatable({ Base = base, Support = support, Motion = motion, Config = config }, class))
end

function class:Sweep(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return self.Base:Sweep(vector, vector2, p, p2, p3, p4)
end

function class:SweepWithFloorSupport(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return self.Base:SweepWithFloorSupport(vector, vector2, p, p2, p3, p4)
end

function class:SweepDetailed(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return self.Base:SweepDetailed(vector, vector2, p, p2, p3, p4)
end

function class:SweepWithFloorSupportDetailed(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return self.Base:SweepWithFloorSupportDetailed(vector, vector2, p, p2, p3, p4)
end

function class:IsClear(vector: Vector3, p, p2: number)
	return self.Base:IsClear(vector, p, p2)
end

function class:CanMove(vector: Vector3, vector2: Vector3, p, p2, p3: number, p4: number)
	return self.Base:CanMove(vector, vector2, p, p2, p3, p4)
end

function class:FindGround(vector: Vector3, p, p2: number, p3: number, p4)
	local v = playerGround(self, vector, p, p2)

	if v == nil then
		return self.Base:FindGround(vector, p, p2, p3, p4)
	end

	return v
end

function class.FindLadder(p, vector: Vector3, p2, p3: number, p4: number)
	local findLadder = p.Base.FindLadder

	if findLadder == nil then
		return nil
	end

	return (findLadder(p.Base, vector, p2, p3, p4))
end

function class.SetMovementBounds(p, vector: Vector3, vector2: Vector3)
	local setMovementBounds = p.Base.SetMovementBounds

	if setMovementBounds ~= nil then
		setMovementBounds(p.Base, vector, vector2)
	end
end

return table.freeze(class)