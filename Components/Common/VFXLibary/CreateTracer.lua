local createVector = vector.create
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local ObjectPool = require(ReplicatedStorage.Shared.ObjectPool)
local tracers = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Tracers")
local Debris = workspace:WaitForChild("Debris")
local _ = { StudsPerSecond = 1000, FadeInDistance = 50, SpawnDistance = 5, Width = 0.2 }

local function resetTracer(data) -- 1 equivalent call inferred from this helper
	data.TopAttachment.Position = createVector(0, 0, 0)
	data.BottomAttachment.Position = createVector(0, 0, 0)
	data.LeftAttachment.Position = createVector(0, 0, 0)
	data.RightAttachment.Position = createVector(0, 0, 0)
end

local default = tracers:WaitForChild("Default")
local v = ObjectPool.new(default, { InitialSize = 8, MaxRetained = 48, Reset = resetTracer })
local v2 = {}
local connection = nil
local parts = {}
local cframes = {}

local function retireTracer(i: number, p) -- 2 equivalent calls inferred from this helper
	v:Release(p.Part, p.Lease)
	v2[i] = v2[#v2]
	v2[#v2] = nil
end

local function updateTracers(p: number)
	debug.profilebegin("VFX.TracerUpdate")

	for i = #v2, 1, -1 do
		local v3 = v2[i]
		v3.Elapsed += p
		local part = v3.Part

		if v3.Elapsed >= 1 or part.Parent == nil then
			retireTracer(i, v3) -- inferred equivalent call
		else
			local v4 = 5 + 995 * (v3.Elapsed / 1)

			if v3.MaxDistance == nil or not (v3.MaxDistance <= v4) then
				parts[#parts + 1] = part
				cframes[#cframes + 1] = CFrame.new(v3.Origin + v3.Direction * v4)
				local halfWidth = 0.1 * math.min(v4 / 50, 1)

				if v3.HalfWidth ~= halfWidth then
					v3.HalfWidth = halfWidth
					part.TopAttachment.Position = Vector3.new(0, halfWidth, 0)
					part.BottomAttachment.Position = Vector3.new(0, -halfWidth, 0)
					part.LeftAttachment.Position = Vector3.new(-halfWidth, 0, 0)
					part.RightAttachment.Position = Vector3.new(halfWidth, 0, 0)
				end
			else
				retireTracer(i, v3) -- inferred equivalent call
			end
		end
	end

	if #parts > 0 then
		workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		table.clear(parts)
		table.clear(cframes)
	end

	if #v2 == 0 and connection then
		connection:Disconnect()
		connection = nil
	end

	debug.profileend()
end

local function ensureUpdaterBound() -- 1 equivalent call inferred from this helper
	if not connection then
		connection = RunServiceController.BindToHeartbeat("VFX.TracerUpdater", updateTracers)
	end
end

return function(p: number, vector: Vector3, vector2: Vector3, flag: boolean?)
	debug.profilebegin("VFX.Tracer")

	if not vector or flag == true and p <= 5 then
		debug.profileend()
		return
	end

	debug.profilebegin("VFX.Tracer.Acquire")
	local part, lease = v:Acquire()
	part.CollisionGroup = "Debris"
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Anchored = true
	debug.profileend()
	debug.profilebegin("VFX.Tracer.Parent")
	resetTracer(part) -- inferred equivalent call
	part.CFrame = CFrame.new(vector + vector2 * 5)
	part.Parent = Debris
	debug.profileend()
	local maxDistance

	if flag == true then
		maxDistance = math.max(p, 0)
	end

	table.insert(v2, {
		Part = part,
		Lease = lease,
		Origin = vector,
		Direction = vector2,
		Elapsed = 0,
		MaxDistance = maxDistance
	})
	ensureUpdaterBound() -- inferred equivalent call
	debug.profileend()
end