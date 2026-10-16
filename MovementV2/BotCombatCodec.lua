local Serial = require(script.Parent.Serial)
local v = {}
local frozen = table.freeze({
	Shoot = 1,
	Reload = 2,
	StartThrow = 3,
	Throw = 4,
	CancelThrow = 5
})
local frozen2 = table.freeze({ "Shoot", "Reload", "StartThrow", "Throw", "CancelThrow" })
v.Version = 1
v.MaxEvents = 8
v.MaxWireSize = 674
v.MaxEventAgeSeconds = 0.75

local function finite(serverTime) -- 1 equivalent call inferred from this helper
	return type(serverTime) == "number" and serverTime == serverTime and serverTime > -1e999 and serverTime < 1e999
end

function v.validateEvent(data)
	if
		type(data) ~= "table"
		or not Serial.isUInt32(data.ActorId)
		or data.ActorId == 0
		or not (Serial.isNonZeroUInt16(data.Generation) and Serial.isUInt32(data.WeaponRevision) and Serial.isUInt32(data.Sequence))
	then
		return false
	end

	if not (finite(data.ServerTime) and not (data.ServerTime < 0) and type(data.WeaponName) == "string" and not (#data.WeaponName < 1 or #data.WeaponName > 48)) then -- inferred equivalent call
		return false
	end

	if data.Kind == "Shoot" then
		local target = data.Target
		local v2

		if data.Kind == "Shoot" and typeof(target) == "Vector3" then
			local x = target.X

			if type(x) == "number" and x == x and x > -1e999 then
				v2 = x < 1e999
			else
				v2 = false
			end

			if v2 then
				local y = target.Y

				if type(y) == "number" and y == y and y > -1e999 then
					v2 = y < 1e999
				else
					v2 = false
				end

				if v2 then
					local z = target.Z

					if type(z) == "number" and z == z and z > -1e999 then
						v2 = z < 1e999
					else
						v2 = false
					end

					if v2 then
						if math.abs(target.X) <= 1000000 and math.abs(target.Y) <= 1000000 then
							return math.abs(target.Z) <= 1000000
						else
							return false
						end
					end
				end
			end
		else
			return false
		end

		return v2
	else
		return frozen[data.Kind] ~= nil and data.Target == nil
	end

	return false
end

function v.encode(list)
	if type(list) ~= "table" or #list < 1 or #list > 8 then
		return nil, "InvalidEventCount"
	end

	local count = 0
	local total = 2

	for k, v2 in list do
		if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or #list < k or not v.validateEvent(v2) then
			return nil, "InvalidEvent"
		end

		count += 1
		total += #v2.WeaponName + 24 + (v2.Kind == "Shoot" and 12 or 0)
	end

	if count ~= #list then
		return nil, "EventsNotDense"
	end

	local buf = buffer.create(total)
	buffer.writeu8(buf, 0, 1)
	buffer.writeu8(buf, 1, #list)
	local v2 = 2

	for _, v3 in list do
		buffer.writeu32(buf, v2, v3.ActorId)
		buffer.writeu16(buf, v2 + 4, v3.Generation)
		buffer.writeu32(buf, v2 + 6, v3.WeaponRevision)
		buffer.writeu32(buf, v2 + 10, v3.Sequence)
		buffer.writef64(buf, v2 + 14, v3.ServerTime)
		buffer.writeu8(buf, v2 + 22, frozen[v3.Kind])
		buffer.writeu8(buf, v2 + 23, #v3.WeaponName)
		local v4 = v2 + 24
		buffer.writestring(buf, v4, v3.WeaponName)
		v2 = v4 + #v3.WeaponName

		if v3.Kind ~= "Shoot" then
			continue
		end

		local target = v3.Target
		buffer.writef32(buf, v2, target.X)
		buffer.writef32(buf, v2 + 4, target.Y)
		buffer.writef32(buf, v2 + 8, target.Z)
		v2 += 12
	end

	return buf, nil
end

function v.decode(buf)
	if typeof(buf) ~= "buffer" then
		return nil, "PayloadNotBuffer"
	end

	local v2 = buffer.len(buf)

	if v2 < 2 or v.MaxWireSize < v2 then
		return nil, "InvalidPayloadSize"
	end

	if buffer.readu8(buf, 0) ~= 1 then
		return nil, "VersionMismatch"
	end

	local v3 = buffer.readu8(buf, 1)

	if v3 < 1 or v3 > 8 then
		return nil, "InvalidEventCount"
	end

	local result = table.create(v3)
	local total = 2

	for _ = 1, v3 do
		if v2 < total + 24 then
			return nil, "TruncatedEvent"
		end

		local v4 = buffer.readu8(buf, total + 22)
		local v5 = buffer.readu8(buf, total + 23)

		if frozen2[v4] == nil or v5 < 1 or v5 > 48 or v2 < total + 24 + v5 + (v4 == 1 and 12 or 0) then
			return nil, "InvalidEventBody"
		end

		local v6 = {
			ActorId = buffer.readu32(buf, total),
			Generation = buffer.readu16(buf, total + 4),
			WeaponRevision = buffer.readu32(buf, total + 6),
			Sequence = buffer.readu32(buf, total + 10),
			ServerTime = buffer.readf64(buf, total + 14),
			Kind = frozen2[v4],
			WeaponName = buffer.readstring(buf, total + 24, v5),
			Target = nil
		}
		total += v5 + 24

		if v4 == 1 then
			v6.Target = Vector3.new(
				buffer.readf32(buf, total),
				buffer.readf32(buf, total + 4),
				(buffer.readf32(buf, total + 8))
			)
			total += 12
		end

		if not v.validateEvent(v6) then
			return nil, "InvalidEvent"
		end

		result[#result + 1] = v6
	end

	if total == v2 then
		return result, nil
	end

	return nil, "TrailingBytes"
end

function v.canPresent(data, data2, flag: boolean, p: number?, value: number)
	if not flag then
		return flag
	end

	if data2 == nil then
		flag = false
	else
		flag = not data2.Dead

		if flag then
			if
				data2.Health > 0
				and data.ActorId == data2.ActorId
				and data.Generation == data2.Generation
				and data.WeaponName == data2.WeaponName
				and data.WeaponRevision == data2.WeaponRevision
			then
				if type(value) == "number" and value == value and value > -1e999 then
					flag = value < 1e999
				else
					flag = false
				end

				if flag then
					if value - data.ServerTime >= -0.25 and value - data.ServerTime <= v.MaxEventAgeSeconds then
						flag = p == nil or Serial.isNewerUInt32(data.Sequence, p)
					else
						flag = false
					end
				end
			else
				flag = false
			end
		end
	end

	return flag
end

return table.freeze(v)