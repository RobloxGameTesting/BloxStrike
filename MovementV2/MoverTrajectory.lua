local Serial = require(script.Parent.Serial)
local RunService = game:GetService("RunService")
local v = {
	Tag = "MovementV2Mover",
	Attributes = table.freeze({
		Id = "MovementV2MoverId",
		Size = "MovementV2MoverSize",
		CollisionOffset = "MovementV2MoverCollisionOffset",
		SurfaceFriction = "MovementV2MoverSurfaceFriction",
		StartPose = "MovementV2MoverStartPose",
		TargetPose = "MovementV2MoverTargetPose",
		EffectiveTick = "MovementV2MoverEffectiveTick",
		StartTick = "MovementV2MoverStartTick",
		DurationTicks = "MovementV2MoverDurationTicks",
		StartServerTime = "MovementV2MoverStartServerTime",
		DurationSeconds = "MovementV2MoverDurationSeconds",
		Moving = "MovementV2MoverMoving",
		Active = "MovementV2MoverActive",
		Revision = "MovementV2MoverRevision",
		Behavior = "MovementV2MoverBehavior"
	})
}
local v2 = {}
local v3 = {}
local v4 = {}
local v5 = false
local bindableEvent = Instance.new("BindableEvent")
local v6 = {}
local v7 = { ServerTick = nil, TickFraction = 0, UpdatedAt = -1e999 }

local function posesMatch(cframe: CFrame, cframe2: CFrame) -- 3 equivalent calls inferred from this helper
	if cframe == cframe2 then
		return true
	end

	if (cframe.Position - cframe2.Position).Magnitude > 0.00001 then
		return false
	end

	local _, v8 = cframe.Rotation:ToObjectSpace(cframe2.Rotation):ToAxisAngle()
	return math.abs(v8) <= 0.00001
end

local function isFiniteNumber(value) -- 8 equivalent calls inferred from this helper
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

local function isFiniteVector3(size) -- 1 equivalent call inferred from this helper
	local v8

	if typeof(size) == "Vector3" then
		local x = size.X

		if typeof(x) == "number" and x == x and x > -1e999 then
			v8 = x < 1e999
		else
			v8 = false
		end

		if v8 then
			local y = size.Y

			if typeof(y) == "number" and y == y and y > -1e999 then
				v8 = y < 1e999
			else
				v8 = false
			end

			if v8 then
				local z = size.Z

				if typeof(z) == "number" and z == z and z > -1e999 then
					return z < 1e999
				else
					return false
				end
			end
		end
	else
		return false
	end

	return v8
end

local function isFiniteCFrame(cframe)
	if typeof(cframe) ~= "CFrame" then
		return false
	end

	for _, v8 in { cframe:GetComponents() } do
		if not isFiniteNumber(v8) then -- inferred equivalent call
			return false
		end
	end

	return true
end

function v.Validate(data)
	if type(data) ~= "table" then
		return false, "mover descriptor must be a table"
	end

	if not Serial.isUInt32(data.Id) or data.Id == 0 then
		return false, "mover id must be a non-zero u32"
	end

	if not isFiniteVector3(data.Size) or data.Size.X <= 0 or data.Size.Y <= 0 or data.Size.Z <= 0 then -- inferred equivalent call
		return false, "mover size must be a finite positive Vector3"
	end

	if not isFiniteCFrame(data.CollisionOffset) then
		return false, "mover collision offset must be a finite CFrame"
	end

	if not isFiniteNumber(data.SurfaceFriction) or data.SurfaceFriction < 0 then -- inferred equivalent call
		return false, "mover surface friction must be finite and nonnegative"
	end

	if not (isFiniteCFrame(data.StartPose) and isFiniteCFrame(data.TargetPose)) then
		return false, "mover trajectory poses must be finite CFrames"
	end

	if not (Serial.isUInt32(data.EffectiveTick) and Serial.isUInt32(data.StartTick)) then
		return false, "mover trajectory start tick must be a u32"
	end

	if data.Moving then
		local deltaUInt32 = Serial.deltaUInt32(data.StartTick, data.EffectiveTick)

		if deltaUInt32 < 0 or deltaUInt32 > 1 then
			return false, "moving descriptor effective tick must equal or immediately precede its start tick"
		end
	elseif data.EffectiveTick ~= data.StartTick then
		return false, "stationary descriptor effective tick must equal its start tick"
	end

	if
		not isFiniteNumber(data.DurationTicks) -- inferred equivalent call
		or data.DurationTicks % 1 ~= 0
		or data.DurationTicks < 0
		or data.DurationTicks >= 2147483648
	then
		return false, "mover trajectory duration ticks are invalid"
	end

	if not isFiniteNumber(data.StartServerTime) or data.StartServerTime < 0 then -- inferred equivalent call
		return false, "mover trajectory start server time is invalid"
	end

	if not isFiniteNumber(data.DurationSeconds) or data.DurationSeconds < 0 then -- inferred equivalent call
		return false, "mover trajectory duration seconds are invalid"
	end

	if typeof(data.Moving) ~= "boolean" then
		return false, "mover trajectory moving flag must be boolean"
	end

	if typeof(data.Active) ~= "boolean" then
		return false, "mover trajectory active flag must be boolean"
	end

	if data.Moving and not data.Active then
		return false, "an inactive mover trajectory cannot be moving"
	end

	if data.Behavior ~= "StopOnBlock" and data.Behavior ~= "Pusher" then
		return false, "mover trajectory behavior is invalid"
	end

	if not Serial.isUInt32(data.Revision) or data.Revision == 0 then
		return false, "mover trajectory revision must be a non-zero u32"
	end

	if data.Moving and (data.DurationTicks < 1 or data.DurationSeconds <= 0) then
		return false, "moving trajectory must have a positive tick and seconds duration"
	end

	return true, nil
end

function v.Read(instance)
	local attributes = v.Attributes

	if RunService:IsClient() and v5 then
		local attribute = instance:GetAttribute(attributes.Id)

		if not Serial.isUInt32(attribute) or attribute == 0 then
			return nil, "mover root identity is unavailable"
		end

		local v8 = v3[attribute] or v2[attribute]

		if v8 == nil then
			v8 = nil
		end

		return v8, "mover is absent from the reliable descriptor baseline"
	else
		local attribute = instance:GetAttribute(attributes.Revision)

		if attribute == nil then
			return nil, "mover trajectory is not committed"
		end

		local v8 = {
			Id = instance:GetAttribute(attributes.Id),
			Size = instance:GetAttribute(attributes.Size),
			CollisionOffset = instance:GetAttribute(attributes.CollisionOffset),
			SurfaceFriction = instance:GetAttribute(attributes.SurfaceFriction),
			StartPose = instance:GetAttribute(attributes.StartPose),
			TargetPose = instance:GetAttribute(attributes.TargetPose),
			EffectiveTick = instance:GetAttribute(attributes.EffectiveTick),
			StartTick = instance:GetAttribute(attributes.StartTick),
			DurationTicks = instance:GetAttribute(attributes.DurationTicks),
			StartServerTime = instance:GetAttribute(attributes.StartServerTime),
			DurationSeconds = instance:GetAttribute(attributes.DurationSeconds),
			Moving = instance:GetAttribute(attributes.Moving),
			Active = instance:GetAttribute(attributes.Active),
			Behavior = instance:GetAttribute(attributes.Behavior),
			Revision = attribute
		}
		local v9, v10 = v.Validate(v8)

		if not v9 then
			v8 = nil
		end

		return v8, v10
	end
end

v.ClientDescriptorChanged = bindableEvent.Event

function v.EvaluateProgress(p, value: number)
	local v8 = type(value) == "number" and value % 1 == 0 and value >= 0 and value <= 65535
	assert(v8, "mover progress must be a u16")
	return p.StartPose:Lerp(p.TargetPose, value / 65535)
end

function v.QuantizeProgress(value: number)
	assert(isFiniteNumber(value), "mover normalized progress must be finite") -- inferred equivalent call
	return (math.floor(math.clamp(value, 0, 1) * 65535))
end

function v.InstallClientBaseline(items, p: number?)
	assert(RunService:IsClient(), "client mover baseline installation is client-only")
	local v8 = {}

	for k in v2 do
		v8[k] = true
	end

	table.clear(v2)
	table.clear(v3)
	table.clear(v4)
	table.clear(v6)

	for _, item in items do
		local v9, v10 = v.Validate(item)
		assert(v9, v10)
		v8[item.Id] = true

		if not (p == nil or Serial.deltaUInt32(p, item.EffectiveTick) >= 0) then
			continue
		end

		local v11 = v2[item.Id]

		if v11 == nil or Serial.deltaUInt32(item.EffectiveTick, v11.EffectiveTick) >= 0 then
			v2[item.Id] = item
		end
	end

	v5 = true

	if p ~= nil then
		for k in v2 do
			v4[k] = p
		end
	end

	for k in v8 do
		bindableEvent:Fire(k)
	end
end

function v.InstallClientSpeculativeDescriptor(p)
	assert(RunService:IsClient(), "speculative mover descriptor installation is client-only")
	assert(v5, "speculative mover descriptor requires a baseline")
	local v8, v9 = v.Validate(p)
	assert(v8, v9)
	assert(v2[p.Id] ~= nil, "speculative mover is absent from the reliable baseline")
	v3[p.Id] = p
	bindableEvent:Fire(p.Id)
end

function v.ClearClientSpeculativeDescriptor(p: number)
	assert(RunService:IsClient(), "speculative mover descriptor clearing is client-only")

	if v3[p] == nil then
		return
	end

	v3[p] = nil
	bindableEvent:Fire(p)
end

function v.InstallClientResolvedPose(descriptor, serverTick: number, previousPose: CFrame, pose: CFrame)
	assert(RunService:IsClient(), "client resolved mover pose installation is client-only")
	assert(v5, "client resolved mover pose requires a baseline")
	assert(Serial.isUInt32(serverTick), "client resolved mover pose tick must be a u32")
	assert(isFiniteCFrame(previousPose) and isFiniteCFrame(pose), "client resolved mover pose must be a finite CFrame")
	local v8 = v6[descriptor.Id]

	if v8 == nil then
		v6[descriptor.Id] = {
			Descriptor = descriptor,
			ServerTick = serverTick,
			PreviousPose = previousPose,
			Pose = pose,
			Discontinuity = 0
		}
		return
	end

	local deltaUInt32 = Serial.deltaUInt32(serverTick, v8.ServerTick)

	if deltaUInt32 < 0 then
		return
	end

	local v9

	if deltaUInt32 == 0 then
		v9 = posesMatch(pose, v8.Pose) -- inferred equivalent call

		if v9 then
			v9 = posesMatch(previousPose, v8.PreviousPose) -- inferred equivalent call
		end
	else
		v9 = posesMatch(previousPose, v8.Pose) -- inferred equivalent call
	end

	v8.Descriptor = descriptor
	v8.ServerTick = serverTick
	v8.PreviousPose = previousPose
	v8.Pose = pose

	if not v9 then
		v8.Discontinuity += 1
		bindableEvent:Fire(descriptor.Id)
	end
end

function v.GetClientPresentation(p: number)
	if RunService:IsClient() then
		return v6[p]
	end

	return nil
end

function v.SetClientPresentationClock(serverTick: number?, value: number)
	v7.ServerTick = serverTick
	v7.TickFraction = math.clamp(value, 0, 1)
	v7.UpdatedAt = os.clock()
end

function v.GetClientPresentationClock()
	if os.clock() - v7.UpdatedAt > 0.25 then
		return nil, 0
	end

	return v7.ServerTick, v7.TickFraction
end

local function installClientResolved(p: number, items, p2)
	assert(RunService:IsClient(), "client mover delta installation is client-only")
	assert(v5, "client mover delta requires a baseline")
	assert(Serial.isUInt32(p), "client mover resolved tick must be a u32")

	for _, item in items do
		local v8, v9 = v.Validate(item)
		assert(v8, v9)

		if Serial.deltaUInt32(p, item.EffectiveTick) < 0 then
			continue
		end

		local v10 = v4[item.Id]

		if not (v10 == nil or not (Serial.deltaUInt32(p, v10) < 0)) then
			continue
		end

		v4[item.Id] = p
		local v11 = v2[item.Id]

		if not (v11 == nil or v11.Revision ~= item.Revision) then
			continue
		end

		v2[item.Id] = item
		local flag = true
		local v12 = v3[item.Id]

		if v12 ~= nil then
			if Serial.deltaUInt32(item.Revision, v12.Revision) >= 0 then
				v3[item.Id] = nil
			else
				flag = false
			end
		end

		if not flag then
			continue
		end

		if p2 == nil then
			bindableEvent:Fire(item.Id)
		else
			p2[item.Id] = true
		end
	end
end

function v.InstallClientResolved(p: number, p2)
	installClientResolved(p, p2, nil)
end

function v.InstallClientDelta(p, p2: number)
	local v8 = {}
	installClientResolved(p2, p, v8)

	for k in v8 do
		bindableEvent:Fire(k)
	end
end

function v.RetireClientDescriptors(items)
	assert(RunService:IsClient(), "client mover retirement is client-only")

	for _, item in items do
		if v2[item] == nil then
			continue
		end

		v2[item] = nil
		v3[item] = nil
		v4[item] = nil
		v6[item] = nil
		bindableEvent:Fire(item)
	end
end

function v.ResetClientDescriptors()
	assert(RunService:IsClient(), "client mover reset is client-only")
	local v8 = {}

	for k in v2 do
		v8[#v8 + 1] = k
	end

	table.clear(v2)
	table.clear(v3)
	table.clear(v4)
	table.clear(v6)
	v5 = false

	for _, v9 in v8 do
		bindableEvent:Fire(v9)
	end
end

function v.Publish(instance, data)
	local v8, v9 = v.Validate(data)
	assert(v8, v9)
	local attributes = v.Attributes
	instance:SetAttribute(attributes.Revision, nil)
	instance:SetAttribute(attributes.Id, data.Id)
	instance:SetAttribute(attributes.Size, data.Size)
	instance:SetAttribute(attributes.CollisionOffset, data.CollisionOffset)
	instance:SetAttribute(attributes.SurfaceFriction, data.SurfaceFriction)
	instance:SetAttribute(attributes.StartPose, data.StartPose)
	instance:SetAttribute(attributes.TargetPose, data.TargetPose)
	instance:SetAttribute(attributes.EffectiveTick, data.EffectiveTick)
	instance:SetAttribute(attributes.StartTick, data.StartTick)
	instance:SetAttribute(attributes.DurationTicks, data.DurationTicks)
	instance:SetAttribute(attributes.StartServerTime, data.StartServerTime)
	instance:SetAttribute(attributes.DurationSeconds, data.DurationSeconds)
	instance:SetAttribute(attributes.Moving, data.Moving)
	instance:SetAttribute(attributes.Active, data.Active)
	instance:SetAttribute(attributes.Behavior, data.Behavior)
	instance:SetAttribute(attributes.Revision, data.Revision)
end

function v.TickAlpha(data, p: number)
	if not data.Moving then
		return 1
	end

	assert(Serial.isUInt32(p), "mover endpoint tick must be a u32")
	return (math.clamp((Serial.deltaUInt32(p, data.StartTick) + 1) / data.DurationTicks, 0, 1))
end

function v.EvaluateTick(p, p2: number)
	return v.EvaluateProgress(p, v.QuantizeProgress(v.TickAlpha(p, p2)))
end

function v.TimeAlpha(data, value: number)
	if not data.Moving then
		return 1
	end

	assert(isFiniteNumber(value), "mover presentation time must be finite") -- inferred equivalent call
	return (math.clamp((value - data.StartServerTime) / data.DurationSeconds, 0, 1))
end

function v.EvaluateTime(p, p2: number)
	return p.StartPose:Lerp(p.TargetPose, v.TimeAlpha(p, p2))
end

function v.PresentationMoving(data, value: number)
	assert(isFiniteNumber(value), "mover presentation time must be finite") -- inferred equivalent call

	if RunService:IsClient() then
		local v8 = v3[data.Id]

		if v8 ~= nil and v8.Revision == data.Revision then
			return true
		end
	end

	return data.Moving and v.TimeAlpha(data, value) < 1
end

function v.CollisionPose(p, cframe: CFrame)
	return cframe * p.CollisionOffset
end

return table.freeze(v)