local MoverTrajectory = require(script.Parent.MoverTrajectory)
local v = { DescriptorWireSize = 193, MaxDescriptorCount = 64 }

local function fitsF32(p: number) -- 4 equivalent calls inferred from this helper
	return p == p and p >= -3.402823466e38 and p <= 3.402823466e38
end

local function vectorFitsF32(size: Vector3) -- 1 equivalent call inferred from this helper
	local v2 = fitsF32(size.X) -- inferred equivalent call

	if not v2 then
		return v2
	end

	local y = size.Y

	if y == y and y >= -3.402823466e38 then
		v2 = y <= 3.402823466e38
	else
		v2 = false
	end

	if not v2 then
		return v2
	end

	local z = size.Z

	if z == z and z >= -3.402823466e38 then
		return z <= 3.402823466e38
	else
		return false
	end

	return v2
end

local function cframeFitsF32(cframe: CFrame)
	for _, v2 in { cframe:GetComponents() } do
		if not fitsF32(v2) then -- inferred equivalent call
			return false
		end
	end

	return true
end

function v.validateList(list, flag: boolean?)
	if type(list) ~= "table" or #list > 64 or #list == 0 and flag ~= true then
		return false, "InvalidMoverDescriptorCount"
	end

	for k, v2 in list do
		if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or #list < k then
			return false, "MoverDescriptorsNotDense"
		end

		local v3, v4 = MoverTrajectory.Validate(v2)

		if not v3 then
			return false, v4
		end

		if
			vectorFitsF32(v2.Size) -- inferred equivalent call
			and cframeFitsF32(v2.CollisionOffset)
			and fitsF32(v2.SurfaceFriction) -- inferred equivalent call
			and cframeFitsF32(v2.StartPose)
			and cframeFitsF32(v2.TargetPose)
			and fitsF32(v2.DurationSeconds) -- inferred equivalent call
		then
			continue
		end

		return false, "MoverDescriptorOutsideWireRange"
	end

	return true, nil
end

local function writeVector3(buf: buffer, offset: number, size: Vector3) -- 1 equivalent call inferred from this helper
	buffer.writef32(buf, offset, size.X)
	buffer.writef32(buf, offset + 4, size.Y)
	buffer.writef32(buf, offset + 8, size.Z)
	return offset + 12
end

local function readVector3(buf: buffer, offset: number) -- 1 equivalent call inferred from this helper
	return
		Vector3.new(buffer.readf32(buf, offset), buffer.readf32(buf, offset + 4), (buffer.readf32(buf, offset + 8))),
		offset + 12
end

local function writeCFrame(buf: buffer, offset: number, cframe: CFrame)
	for _, value in { cframe:GetComponents() } do
		buffer.writef32(buf, offset, value)
		offset += 4
	end

	return offset
end

local function readCFrame(buf: buffer, offset: number)
	local v2 = table.create(12)

	for i = 1, 12 do
		v2[i] = buffer.readf32(buf, offset)
		offset += 4
	end

	return CFrame.new(table.unpack(v2)), offset
end

function v.writeValidated(buf: buffer, offset: number, items)
	for _, item in items do
		buffer.writeu32(buf, offset, item.Id)
		local v2 = offset + 4
		buffer.writeu32(buf, v2, item.Revision)
		local v3 = v2 + 4
		local v4 = 0

		if item.Moving then
			v4 = bit32.bor(v4, 1)
		end

		if item.Active then
			v4 = bit32.bor(v4, 2)
		end

		if item.Behavior == "Pusher" then
			v4 = bit32.bor(v4, 4)
		end

		buffer.writeu8(buf, v3, v4)
		local v5 = writeVector3(buf, v3 + 1, item.Size) -- inferred equivalent call
		local v6 = offset

		for _, value in { item.CollisionOffset:GetComponents() } do
			buffer.writef32(buf, v5, value)
			v5 += 4
		end

		buffer.writef32(buf, v5, item.SurfaceFriction)
		local v7 = v5 + 4

		for _, value in { item.StartPose:GetComponents() } do
			buffer.writef32(buf, v7, value)
			v7 += 4
		end

		for _, value in { item.TargetPose:GetComponents() } do
			buffer.writef32(buf, v7, value)
			v7 += 4
		end

		buffer.writeu32(buf, v7, item.EffectiveTick)
		local v8 = v7 + 4
		buffer.writeu32(buf, v8, item.StartTick)
		local v9 = v8 + 4
		buffer.writeu32(buf, v9, item.DurationTicks)
		local v10 = v9 + 4
		buffer.writef64(buf, v10, item.StartServerTime)
		local v11 = v10 + 8
		buffer.writef32(buf, v11, item.DurationSeconds)
		offset = v11 + 4
		assert(offset - v6 == 193, "mover descriptor wire size drift")
	end

	return offset
end

function v.readList(buf: buffer, offset: number, p: number)
	if p < 0 or p > 64 or buffer.len(buf) - offset ~= p * 193 then
		return nil, offset, "MoverDescriptorPayloadSize"
	end

	local result = table.create(p)

	for i = 1, p do
		local id = buffer.readu32(buf, offset)
		local v2 = offset + 4
		local revision = buffer.readu32(buf, v2)
		local v3 = v2 + 4
		local v4 = buffer.readu8(buf, v3)
		local v5 = v3 + 1

		if bit32.band(v4, 4294967288) ~= 0 then
			return nil, v5, "InvalidMoverDescriptorFlags"
		end

		local size, v6 = readVector3(buf, v5) -- inferred equivalent call
		local collisionOffset, v7 = readCFrame(buf, v6)
		local surfaceFriction = buffer.readf32(buf, v7)
		local startPose, v8 = readCFrame(buf, v7 + 4)
		local targetPose, v9 = readCFrame(buf, v8)
		local effectiveTick = buffer.readu32(buf, v9)
		local v10 = v9 + 4
		local startTick = buffer.readu32(buf, v10)
		local v11 = v10 + 4
		local durationTicks = buffer.readu32(buf, v11)
		local v12 = v11 + 4
		local startServerTime = buffer.readf64(buf, v12)
		local v13 = v12 + 8
		local durationSeconds = buffer.readf32(buf, v13)
		local v14 = v13 + 4
		assert(v14 - offset == 193, "mover descriptor wire size drift")
		result[i] = {
			Id = id,
			Size = size,
			CollisionOffset = collisionOffset,
			SurfaceFriction = surfaceFriction,
			StartPose = startPose,
			TargetPose = targetPose,
			EffectiveTick = effectiveTick,
			StartTick = startTick,
			DurationTicks = durationTicks,
			StartServerTime = startServerTime,
			DurationSeconds = durationSeconds,
			Moving = bit32.band(v4, 1) ~= 0,
			Active = bit32.band(v4, 2) ~= 0,
			Behavior = bit32.band(v4, 4) == 0 and "StopOnBlock" or "Pusher",
			Revision = revision
		}
		offset = v14
	end

	local v2, v3 = v.validateList(result, true)

	if v2 then
		return result, offset, nil
	end

	return nil, offset, v3
end

function v.canonicalize(p)
	local v2 = { p }
	local v3, v4 = v.validateList(v2)

	if not v3 then
		return nil, v4
	end

	local buf = buffer.create(193)
	v.writeValidated(buf, 0, v2)
	local list, _, v5 = v.readList(buf, 0, 1)

	if list == nil then
		return nil, v5
	end

	return list[1], nil
end

return table.freeze(v)