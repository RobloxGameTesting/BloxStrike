local createVector = vector.create
local v = {}
local buf = buffer.create(4)
local class = {}
class.__index = class
local values = {}
local v2 = {}
local frozen = table.freeze({
	[0] = "unknown",
	[1] = "ReplicatedStorage.MovementV2.Simulation.ProvenSimulator",
	[2] = "ReplicatedStorage.MovementV2.Simulation.ProvenCollisionAdapter",
	[3] = "ReplicatedStorage.MovementV2.Simulation.PlayerContacts",
	[4] = "ReplicatedStorage.MovementV2.Simulation",
	[5] = "ReplicatedStorage.MovementV2.Client.PlayerContactAdapter",
	[6] = "ServerScriptService.MovementV2.AuthorityRuntime",
	[7] = "ReplicatedStorage.MovementV2.Client.Runtime"
})

local function sourceId(value: string)
	local v3 = v2[value]

	if v3 ~= nil then
		return v3
	end

	local v4

	if string.find(value, "ProvenSimulator", 1, true) ~= nil then
		v4 = 1
	elseif string.find(value, "ProvenCollisionAdapter", 1, true) ~= nil then
		v4 = 2
	elseif string.find(value, "PlayerContacts", 1, true) ~= nil then
		v4 = 3
	elseif string.find(value, "Client.PlayerContactAdapter", 1, true) ~= nil then
		v4 = 5
	elseif string.find(value, "AuthorityRuntime", 1, true) ~= nil then
		v4 = 6
	elseif string.find(value, "Client.Runtime", 1, true) ~= nil then
		v4 = 7
	elseif string.find(value, "MovementV2.Simulation", 1, true) == nil then
		v4 = 0
	else
		v4 = 4
	end

	v2[value] = v4
	return v4
end

local function finite(value)
	return typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
end

local function mix(p: number, p2: number)
	return (bit32.band(bit32.lrotate(bit32.bxor(p, p2), 5) + 2654435769, 4294967295))
end

local function floatWord(value)
	local v3 = typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
	buffer.writef32(buf, 0, not v3 and 0 or value)
	return (buffer.readu32(buf, 0))
end

local function boolWord(p)
	if p == true then
		return 1
	end

	return 0
end

local function stringWord(value)
	if typeof(value) ~= "string" then
		return 0
	end

	local v3 = 2166136261

	for i = 1, #value do
		v3 = bit32.band(bit32.lrotate(bit32.bxor(v3, (string.byte(value, i))), 5) + 2654435769, 4294967295)
	end

	return v3
end

local function vectorHash(p: number, data)
	if typeof(data) ~= "Vector3" then
		return (bit32.band(bit32.lrotate(bit32.bxor(p, 0), 5) + 2654435769, 4294967295))
	end

	local x = data.X
	local v3 = typeof(x) == "number" and x == x and x > -1e999 and x < 1e999
	buffer.writef32(buf, 0, not v3 and 0 or x)
	local v4 = bit32.band(bit32.lrotate(bit32.bxor(p, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local y = data.Y
	local v5 = typeof(y) == "number" and y == y and y > -1e999 and y < 1e999
	buffer.writef32(buf, 0, not v5 and 0 or y)
	local v6 = bit32.band(bit32.lrotate(bit32.bxor(v4, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local z = data.Z
	local v7 = typeof(z) == "number" and z == z and z > -1e999 and z < 1e999
	buffer.writef32(buf, 0, not v7 and 0 or z)
	return (bit32.band(bit32.lrotate(bit32.bxor(v6, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295))
end

local function vector2Hash(p: number, p2)
	if typeof(p2) ~= "Vector2" then
		return (bit32.band(bit32.lrotate(bit32.bxor(p, 0), 5) + 2654435769, 4294967295))
	end

	local x = p2.X
	local v3 = typeof(x) == "number" and x == x and x > -1e999 and x < 1e999
	buffer.writef32(buf, 0, not v3 and 0 or x)
	local v4 = bit32.band(bit32.lrotate(bit32.bxor(p, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local y = p2.Y
	local v5 = typeof(y) == "number" and y == y and y > -1e999 and y < 1e999
	buffer.writef32(buf, 0, not v5 and 0 or y)
	return (bit32.band(bit32.lrotate(bit32.bxor(v4, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295))
end

local function registerSite(label: string, source: string)
	local v3

	if typeof(label) == "string" then
		v3 = 2166136261

		for i = 1, #label do
			v3 = bit32.band(bit32.lrotate(bit32.bxor(v3, (string.byte(label, i))), 5) + 2654435769, 4294967295)
		end
	else
		v3 = 0
	end

	local v4 = values[v3]

	if v4 == nil then
		values[v3] = table.freeze({ Label = label, Source = source })
		return v3
	end

	if v4.Label ~= label then
		error(`MovementV2 determinism trace site collision: {v4.Label} / {label}`)
	end

	return v3
end

local function stateHash(data)
	local v3 = vectorHash(vectorHash(2166136261, data.Position), data.Velocity)
	local lookYaw = data.LookYaw
	local v4 = typeof(lookYaw) == "number" and lookYaw == lookYaw and lookYaw > -1e999 and lookYaw < 1e999
	buffer.writef32(buf, 0, not v4 and 0 or lookYaw)
	local v5 = bit32.band(bit32.lrotate(bit32.bxor(v3, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local verticalLook = data.VerticalLook
	local v6 = typeof(verticalLook) == "number"
		and verticalLook == verticalLook
		and verticalLook > -1e999
		and verticalLook < 1e999
	buffer.writef32(buf, 0, not v6 and 0 or verticalLook)
	local v7 = bit32.band(bit32.lrotate(bit32.bxor(v5, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local tick = data.Tick
	local v8 = typeof(tick) == "number" and tick == tick and tick > -1e999 and tick < 1e999
	buffer.writef32(buf, 0, not v8 and 0 or tick)
	local v9 = vectorHash(
		vectorHash(
			bit32.band(
				bit32.lrotate(
					bit32.bxor(
						bit32.band(
							bit32.lrotate(
								bit32.bxor(
									bit32.band(
										bit32.lrotate(bit32.bxor(v7, (buffer.readu32(buf, 0))), 5) + 2654435769,
										4294967295
									),
									data.OnGround == true and 1 or 0
								),
								5
							) + 2654435769,
							4294967295
						),
						data.GroundSupportIsDynamicPlayer == true and 1 or 0
					),
					5
				) + 2654435769,
				4294967295
			),
			data.GroundNormal
		),
		data.WallNormal
	)
	local groundSurfaceFriction = data.GroundSurfaceFriction
	local v10 = typeof(groundSurfaceFriction) == "number"
		and groundSurfaceFriction == groundSurfaceFriction
		and groundSurfaceFriction > -1e999
		and groundSurfaceFriction < 1e999
	buffer.writef32(buf, 0, not v10 and 0 or groundSurfaceFriction)
	local v11 = bit32.band(bit32.lrotate(bit32.bxor(v9, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local duckAmount = data.DuckAmount
	local v12 = typeof(duckAmount) == "number"
		and duckAmount == duckAmount
		and duckAmount > -1e999
		and duckAmount < 1e999
	buffer.writef32(buf, 0, not v12 and 0 or duckAmount)
	local v13 = bit32.band(bit32.lrotate(bit32.bxor(v11, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local duckTimeMsecs = data.DuckTimeMsecs
	local v14 = typeof(duckTimeMsecs) == "number"
		and duckTimeMsecs == duckTimeMsecs
		and duckTimeMsecs > -1e999
		and duckTimeMsecs < 1e999
	buffer.writef32(buf, 0, not v14 and 0 or duckTimeMsecs)
	local v15 = bit32.band(
		bit32.lrotate(
			bit32.bxor(
				bit32.band(
					bit32.lrotate(
						bit32.bxor(
							bit32.band(
								bit32.lrotate(bit32.bxor(v13, (buffer.readu32(buf, 0))), 5) + 2654435769,
								4294967295
							),
							data.IsDucking == true and 1 or 0
						),
						5
					) + 2654435769,
					4294967295
				),
				data.DuckHeld == true and 1 or 0
			),
			5
		) + 2654435769,
		4294967295
	)
	local duckFatigueLevel = data.DuckFatigueLevel or data.DuckSpeed
	local v16 = typeof(duckFatigueLevel) == "number"
		and duckFatigueLevel == duckFatigueLevel
		and duckFatigueLevel > -1e999
		and duckFatigueLevel < 1e999
	buffer.writef32(buf, 0, not v16 and 0 or duckFatigueLevel)
	local v17 = bit32.band(bit32.lrotate(bit32.bxor(v15, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local duckFatigueTimerMsecs = data.DuckFatigueTimerMsecs or data.DuckCooldownSeconds
	local v18 = typeof(duckFatigueTimerMsecs) == "number"
		and duckFatigueTimerMsecs == duckFatigueTimerMsecs
		and duckFatigueTimerMsecs > -1e999
		and duckFatigueTimerMsecs < 1e999
	buffer.writef32(buf, 0, not v18 and 0 or duckFatigueTimerMsecs)
	local v19 = bit32.band(bit32.lrotate(bit32.bxor(v17, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local movementType = data.MovementType or data.MovementMode
	local v20

	if typeof(movementType) == "string" then
		v20 = 2166136261

		for i = 1, #movementType do
			v20 = bit32.band(bit32.lrotate(bit32.bxor(v20, (string.byte(movementType, i))), 5) + 2654435769, 4294967295)
		end
	else
		v20 = 0
	end

	local v21 = bit32.band(bit32.lrotate(bit32.bxor(v19, v20), 5) + 2654435769, 4294967295)
	local stance = data.Stance
	local v22

	if typeof(stance) == "string" then
		v22 = 2166136261

		for i = 1, #stance do
			v22 = bit32.band(bit32.lrotate(bit32.bxor(v22, (string.byte(stance, i))), 5) + 2654435769, 4294967295)
		end
	else
		v22 = 0
	end

	local v23 = bit32.band(bit32.lrotate(bit32.bxor(v21, v22), 5) + 2654435769, 4294967295)
	local stamina = data.Stamina
	local v24 = typeof(stamina) == "number" and stamina == stamina and stamina > -1e999 and stamina < 1e999
	buffer.writef32(buf, 0, not v24 and 0 or stamina)
	local v25 = bit32.band(bit32.lrotate(bit32.bxor(v23, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local lastJumpTick = data.LastJumpTick or data.LastJumpCommandNumber
	local v26 = typeof(lastJumpTick) == "number"
		and lastJumpTick == lastJumpTick
		and lastJumpTick > -1e999
		and lastJumpTick < 1e999
	buffer.writef32(buf, 0, not v26 and 0 or lastJumpTick)
	local v27 = bit32.band(
		bit32.lrotate(
			bit32.bxor(
				bit32.band(bit32.lrotate(bit32.bxor(v25, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295),
				data.JumpHeld == true and 1 or 0
			),
			5
		) + 2654435769,
		4294967295
	)
	local previousButtons = data.PreviousButtons
	local v28 = typeof(previousButtons) == "number"
		and previousButtons == previousButtons
		and previousButtons > -1e999
		and previousButtons < 1e999
	buffer.writef32(buf, 0, not v28 and 0 or previousButtons)
	local v29 = bit32.band(bit32.lrotate(bit32.bxor(v27, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local jumpBufferTicksRemaining = data.JumpBufferTicksRemaining
	local v30 = typeof(jumpBufferTicksRemaining) == "number"
		and jumpBufferTicksRemaining == jumpBufferTicksRemaining
		and jumpBufferTicksRemaining > -1e999
		and jumpBufferTicksRemaining < 1e999
	buffer.writef32(buf, 0, not v30 and 0 or jumpBufferTicksRemaining)
	local v31 = bit32.band(
		bit32.lrotate(
			bit32.bxor(
				bit32.band(bit32.lrotate(bit32.bxor(v29, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295),
				data.JumpHullActive == true and 1 or 0
			),
			5
		) + 2654435769,
		4294967295
	)
	local stuckStepTicks = data.StuckStepTicks
	local v32 = typeof(stuckStepTicks) == "number"
		and stuckStepTicks == stuckStepTicks
		and stuckStepTicks > -1e999
		and stuckStepTicks < 1e999
	buffer.writef32(buf, 0, not v32 and 0 or stuckStepTicks)
	local v36 = bit32.band(bit32.lrotate(bit32.bxor(v31, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local baseMoveSpeed = data.BaseMoveSpeed
	local v37 = typeof(baseMoveSpeed) == "number"
		and baseMoveSpeed == baseMoveSpeed
		and baseMoveSpeed > -1e999
		and baseMoveSpeed < 1e999
	buffer.writef32(buf, 0, not v37 and 0 or baseMoveSpeed)
	local v38 = bit32.band(bit32.lrotate(bit32.bxor(v36, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local weaponMoveSpeed = data.WeaponMoveSpeed
	local v39 = typeof(weaponMoveSpeed) == "number"
		and weaponMoveSpeed == weaponMoveSpeed
		and weaponMoveSpeed > -1e999
		and weaponMoveSpeed < 1e999
	buffer.writef32(buf, 0, not v39 and 0 or weaponMoveSpeed)
	local v40 = bit32.band(bit32.lrotate(bit32.bxor(v38, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local weaponScopedMoveSpeed = data.WeaponScopedMoveSpeed
	local v41 = typeof(weaponScopedMoveSpeed) == "number"
		and weaponScopedMoveSpeed == weaponScopedMoveSpeed
		and weaponScopedMoveSpeed > -1e999
		and weaponScopedMoveSpeed < 1e999
	buffer.writef32(buf, 0, not v41 and 0 or weaponScopedMoveSpeed)
	local v42 = bit32.band(bit32.lrotate(bit32.bxor(v40, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local velocityModifier = data.VelocityModifier
	local v43 = typeof(velocityModifier) == "number"
		and velocityModifier == velocityModifier
		and velocityModifier > -1e999
		and velocityModifier < 1e999
	buffer.writef32(buf, 0, not v43 and 0 or velocityModifier)
	return (bit32.band(bit32.lrotate(bit32.bxor(v42, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295))
end

local function auxiliaryHash(data, data2)
	local v3 = 2166136261

	if data ~= nil then
		local kind = data.Kind
		local v4 = typeof(kind) == "number" and kind == kind and kind > -1e999 and kind < 1e999
		buffer.writef32(buf, 0, not v4 and 0 or kind)
		local v5 = bit32.band(bit32.lrotate(bit32.bxor(v3, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
		local sourceId2 = data.SourceId
		local v6 = typeof(sourceId2) == "number" and sourceId2 == sourceId2 and sourceId2 > -1e999 and sourceId2 < 1e999
		buffer.writef32(buf, 0, not v6 and 0 or sourceId2)
		v3 = vectorHash(
			vectorHash(
				bit32.band(bit32.lrotate(bit32.bxor(v5, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295),
				data.Anchor
			),
			data.Velocity
		)
	end

	if data2 == nil then
		return v3
	end

	local commandNumber = data2.CommandNumber
	local v4 = typeof(commandNumber) == "number"
		and commandNumber == commandNumber
		and commandNumber > -1e999
		and commandNumber < 1e999
	buffer.writef32(buf, 0, not v4 and 0 or commandNumber)
	local v5 = bit32.band(bit32.lrotate(bit32.bxor(v3, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local move = data2.Move
	local v6

	if typeof(move) == "Vector2" then
		local x = move.X
		local v7 = typeof(x) == "number" and x == x and x > -1e999 and x < 1e999
		buffer.writef32(buf, 0, not v7 and 0 or x)
		local v8 = bit32.band(bit32.lrotate(bit32.bxor(v5, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
		local y = move.Y
		local v9 = typeof(y) == "number" and y == y and y > -1e999 and y < 1e999
		buffer.writef32(buf, 0, not v9 and 0 or y)
		v6 = bit32.band(bit32.lrotate(bit32.bxor(v8, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	else
		v6 = bit32.band(bit32.lrotate(bit32.bxor(v5, 0), 5) + 2654435769, 4294967295)
	end

	local lookYaw = data2.LookYaw
	local v7 = typeof(lookYaw) == "number" and lookYaw == lookYaw and lookYaw > -1e999 and lookYaw < 1e999
	buffer.writef32(buf, 0, not v7 and 0 or lookYaw)
	local v8 = bit32.band(bit32.lrotate(bit32.bxor(v6, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local verticalLook = data2.VerticalLook
	local v9 = typeof(verticalLook) == "number"
		and verticalLook == verticalLook
		and verticalLook > -1e999
		and verticalLook < 1e999
	buffer.writef32(buf, 0, not v9 and 0 or verticalLook)
	local v10 = bit32.band(bit32.lrotate(bit32.bxor(v8, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local buttons = data2.Buttons
	local v11 = typeof(buttons) == "number" and buttons == buttons and buttons > -1e999 and buttons < 1e999
	buffer.writef32(buf, 0, not v11 and 0 or buttons)
	local v12 = bit32.band(bit32.lrotate(bit32.bxor(v10, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local kind = data2.Kind
	local v13 = typeof(kind) == "number" and kind == kind and kind > -1e999 and kind < 1e999
	buffer.writef32(buf, 0, not v13 and 0 or kind)
	local v14 = bit32.band(bit32.lrotate(bit32.bxor(v12, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local sourceId2 = data2.SourceId
	local v15 = typeof(sourceId2) == "number" and sourceId2 == sourceId2 and sourceId2 > -1e999 and sourceId2 < 1e999
	buffer.writef32(buf, 0, not v15 and 0 or sourceId2)
	local v16 = bit32.band(bit32.lrotate(bit32.bxor(v14, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local revision = data2.Revision
	local v17 = typeof(revision) == "number" and revision == revision and revision > -1e999 and revision < 1e999
	buffer.writef32(buf, 0, not v17 and 0 or revision)
	return (vectorHash(
		vectorHash(
			bit32.band(bit32.lrotate(bit32.bxor(v16, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295),
			data2.Delta
		),
		data2.Velocity
	))
end

local function eventFlags(data, p)
	local v3 = 0

	if data.OnGround == true then
		v3 = bit32.bor(v3, 1)
	end

	if data.Stance == "Ducking" or data.DuckAmount >= 0.999 then
		v3 = bit32.bor(v3, 2)
	end

	if data.MovementMode == "Ladder" or data.MovementType == "Ladder" then
		v3 = bit32.bor(v3, 4)
	end

	if data.JumpHullActive == true then
		v3 = bit32.bor(v3, 8)
	end

	if data.IsDucking == true then
		v3 = bit32.bor(v3, 16)
	end

	if p ~= nil and p.Kind ~= nil and p.Kind ~= 0 then
		return (bit32.bor(v3, 32))
	end

	return v3
end

local function writeEvent(state, value: number, p: number, value2: number, p2: number, value3: number, value4: number, value5: number, vector: Vector3, vector2: Vector3, value6: number, p3: number)
	if state.Count >= 128 then
		state.Overflow = true
		return
	end

	local v3 = state.BaseOffset + 16 + state.Count * 48
	local buf2 = state.Buffer
	buffer.writeu32(buf2, v3 + 0, value)
	buffer.writeu16(buf2, v3 + 4, (math.clamp(value2, 0, 65535)))
	buffer.writeu8(buf2, v3 + 6, (bit32.bor(p2, (bit32.lshift(p, 2)))))
	buffer.writeu8(buf2, v3 + 7, value3)
	buffer.writeu32(buf2, v3 + 8, value4)
	buffer.writeu32(buf2, v3 + 12, value5)
	buffer.writef32(buf2, v3 + 16, vector.X)
	buffer.writef32(buf2, v3 + 16 + 4, vector.Y)
	buffer.writef32(buf2, v3 + 16 + 8, vector.Z)
	buffer.writef32(buf2, v3 + 28, vector2.X)
	buffer.writef32(buf2, v3 + 28 + 4, vector2.Y)
	buffer.writef32(buf2, v3 + 28 + 8, vector2.Z)
	local v4 = v3 + 40
	local v5 = typeof(value6) == "number" and value6 == value6 and value6 > -1e999 and value6 < 1e999
	buffer.writef32(buf2, v4, not v5 and 0 or value6)
	buffer.writeu32(buf2, v3 + 44, (bit32.band(p3, 4294967295)))
	state.Count += 1
end

function v.checkpoint(p, label: string, data, p2, p3, value: number?, p4: string?, p5: number?)
	if p == nil then
		return
	end

	if p4 == nil or p5 == nil then
		p4, p5 = debug.info(value or 2, "sl")
	end

	local v3 = typeof(data.Position) ~= "Vector3" and createVector(0, 0, 0) or data.Position
	local v4 = typeof(data.Velocity) ~= "Vector3" and createVector(0, 0, 0) or data.Velocity
	writeEvent(
		p,
		registerSite(label, p4),
		sourceId(p4),
		p5,
		1,
		eventFlags(data, p2),
		stateHash(data),
		auxiliaryHash(p2, p3),
		v3,
		v4,
		data.DuckAmount or 0,
		(p2 == nil or typeof(p2.SourceId) ~= "number") and 0 or p2.SourceId
	)
end

function v.vector(p, label: string, vector: Vector3, vector2: Vector3, value: number?, value2: number?, value3: number?, p2: string?, p3: number?)
	if p == nil then
		return
	end

	if p2 == nil or p3 == nil then
		p2, p3 = debug.info(value3 or 2, "sl")
	end

	local v3 = vectorHash(vectorHash(2166136261, vector), vector2)
	local v4 = registerSite(label, p2)
	local v5 = sourceId(p2)
	local v6 = typeof(value) == "number" and value == value and value > -1e999 and value < 1e999
	buffer.writef32(buf, 0, not v6 and 0 or value)
	local v7 = bit32.band(bit32.lrotate(bit32.bxor(2166136261, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local v8 = typeof(value2) == "number" and value2 == value2 and value2 > -1e999 and value2 < 1e999
	buffer.writef32(buf, 0, not v8 and 0 or value2)
	writeEvent(
		p,
		v4,
		v5,
		p3,
		1,
		0,
		v3,
		bit32.band(bit32.lrotate(bit32.bxor(v7, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295),
		vector,
		vector2,
		value or 0,
		value2 or 0
	)
end

function v.collision(p, label: string, vector: Vector3, vector2: Vector3, data, value: number?)
	if p == nil then
		return
	end

	local source, v3 = debug.info(value or 2, "sl")
	local v4 = 0

	if data.startSolid == true or data.StartSolid == true then
		v4 = bit32.bor(v4, 64)
	end

	if data.allSolid == true or data.AllSolid == true then
		v4 = bit32.bor(v4, 128)
	end

	local fraction = data.fraction or data.Fraction or 1
	local endPos = data.endPos or data.ResolvedPosition or vector:Lerp(vector2, fraction)
	local normal = data.normal or data.Normal or createVector(0, 0, 0)
	local hullRecord = data.hullRecord
	local sourceId2 = data.SourceId or not hullRecord and 0 or hullRecord.sourceId or 0
	local v5 = vectorHash(2166136261, normal)
	local v6 = typeof(fraction) == "number" and fraction == fraction and fraction > -1e999 and fraction < 1e999
	buffer.writef32(buf, 0, not v6 and 0 or fraction)
	local v7 = bit32.band(
		bit32.lrotate(
			bit32.bxor(
				bit32.band(bit32.lrotate(bit32.bxor(v5, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295),
				v4
			),
			5
		) + 2654435769,
		4294967295
	)
	local v8 = typeof(sourceId2) == "number" and sourceId2 == sourceId2 and sourceId2 > -1e999 and sourceId2 < 1e999
	buffer.writef32(buf, 0, not v8 and 0 or sourceId2)
	local v9 = bit32.band(bit32.lrotate(bit32.bxor(v7, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local planeId = data.PlaneId or data.planeNum
	local v10 = typeof(planeId) == "number" and planeId == planeId and planeId > -1e999 and planeId < 1e999
	buffer.writef32(buf, 0, not v10 and 0 or planeId)
	local v11 = bit32.band(bit32.lrotate(bit32.bxor(v9, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local kind = data.Kind or hullRecord and hullRecord.kind
	local v12 = typeof(kind) == "number" and kind == kind and kind > -1e999 and kind < 1e999
	buffer.writef32(buf, 0, not v12 and 0 or kind)
	local v13 = bit32.band(bit32.lrotate(bit32.bxor(v11, (buffer.readu32(buf, 0))), 5) + 2654435769, 4294967295)
	local v14 = vectorHash(vectorHash(2166136261, vector), vector2)
	writeEvent(
		p,
		registerSite(label, source),
		sourceId(source),
		v3,
		2,
		v4,
		v14,
		v13,
		endPos,
		normal,
		fraction,
		sourceId2
	)
end

local function resetRecorder(state, value: number, value2: number, value3: number)
	state.Count = 0
	state.Overflow = false
	local buf2 = state.Buffer
	local baseOffset = state.BaseOffset
	buffer.writeu8(buf2, baseOffset, 2)
	buffer.writeu8(buf2, baseOffset + 1, 0)
	buffer.writeu8(buf2, baseOffset + 2, 0)
	buffer.writeu8(buf2, baseOffset + 3, 0)
	buffer.writeu16(buf2, baseOffset + 4, value)
	buffer.writeu16(buf2, baseOffset + 6, 0)
	buffer.writeu32(buf2, baseOffset + 8, value2)
	buffer.writeu32(buf2, baseOffset + 12, value3)
end

function class.new(size: number)
	local v3 = size % 1 == 0 and size > 0
	assert(v3, "determinism trace capacity must be positive")
	local slots = table.create(size)
	local buf2 = buffer.create(size * 6160)

	for i = 1, size do
		slots[i] = {
			Generation = 0,
			CommandNumber = 0,
			ServerTick = 0,
			Recorder = {
				Buffer = buf2,
				BaseOffset = (i - 1) * 6160,
				Count = 0,
				Overflow = false
			}
		}
	end

	return (setmetatable({ Capacity = size, Slots = slots }, class))
end

function class.clear(p)
	for _, slot in p.Slots do
		slot.Generation = 0
		slot.CommandNumber = 0
		slot.ServerTick = 0
		slot.Recorder.Count = 0
		slot.Recorder.Overflow = false
	end
end

function class.begin(p, generation: number, commandNumber: number, serverTick: number)
	local slot = p.Slots[commandNumber % p.Capacity + 1]
	slot.Generation = generation
	slot.CommandNumber = commandNumber
	slot.ServerTick = serverTick
	local recorder = slot.Recorder
	recorder.Count = 0
	recorder.Overflow = false
	local buf2 = recorder.Buffer
	local baseOffset = recorder.BaseOffset
	buffer.writeu8(buf2, baseOffset, 2)
	buffer.writeu8(buf2, baseOffset + 1, 0)
	buffer.writeu8(buf2, baseOffset + 2, 0)
	buffer.writeu8(buf2, baseOffset + 3, 0)
	buffer.writeu16(buf2, baseOffset + 4, generation)
	buffer.writeu16(buf2, baseOffset + 6, 0)
	buffer.writeu32(buf2, baseOffset + 8, commandNumber)
	buffer.writeu32(buf2, baseOffset + 12, serverTick)
	return slot.Recorder
end

function class.finish(_, data)
	local v3 = data.Overflow and 1 or 0
	buffer.writeu8(data.Buffer, data.BaseOffset + 1, v3)
	buffer.writeu8(data.Buffer, data.BaseOffset + 2, data.Count)
end

local function cloneUsed(buf2: buffer, value: number?)
	local v3 = value or 0
	local v4 = buffer.readu8(buf2, v3 + 2) * 48 + 16
	local buf3 = buffer.create(v4)
	buffer.copy(buf3, 0, buf2, v3, v4)
	return buf3
end

function class.get(p, p2: number, p3: number, p4: number)
	local slot = p.Slots[p3 % p.Capacity + 1]

	if slot.Generation ~= p2 or slot.CommandNumber ~= p3 or slot.ServerTick ~= p4 then
		return nil
	end

	local buf2 = slot.Recorder.Buffer
	local baseOffset = slot.Recorder.BaseOffset or 0
	local v3 = buffer.readu8(buf2, baseOffset + 2) * 48 + 16
	local buf3 = buffer.create(v3)
	buffer.copy(buf3, 0, buf2, baseOffset, v3)
	return buf3
end

function v.encodeRequest(value: number, value2: number, value3: number)
	local buf2 = buffer.create(12)
	buffer.writeu8(buf2, 0, 2)
	buffer.writeu8(buf2, 1, 0)
	buffer.writeu16(buf2, 2, value)
	buffer.writeu32(buf2, 4, value2)
	buffer.writeu32(buf2, 8, value3)
	return buf2
end

function v.decodeRequest(buf2)
	if typeof(buf2) == "buffer" and buffer.len(buf2) == 12 and buffer.readu8(buf2, 0) == 2 then
		return buffer.readu16(buf2, 2), buffer.readu32(buf2, 4), (buffer.readu32(buf2, 8))
	end

	return nil, nil, nil
end

function v.unavailable(value: number, value2: number, value3: number)
	local buf2 = buffer.create(16)
	buffer.writeu8(buf2, 0, 2)
	buffer.writeu8(buf2, 1, 2)
	buffer.writeu8(buf2, 2, 0)
	buffer.writeu16(buf2, 4, value)
	buffer.writeu32(buf2, 8, value2)
	buffer.writeu32(buf2, 12, value3)
	return buf2
end

function v.identity(buf2)
	if typeof(buf2) ~= "buffer" or buffer.len(buf2) < 16 or buffer.readu8(buf2, 0) ~= 2 then
		return nil, nil, nil, nil
	end

	local v3 = buffer.readu8(buf2, 2)

	if v3 > 128 or buffer.len(buf2) ~= v3 * 48 + 16 then
		return nil, nil, nil, nil
	end

	return
		buffer.readu16(buf2, 4),
		buffer.readu32(buf2, 8),
		buffer.readu32(buf2, 12),
		bit32.band(buffer.readu8(buf2, 1), 2) ~= 0
end

local function readEvent(buf2: buffer, p: number)
	local v3 = (p - 1) * 48 + 16
	local v4 = buffer.readu8(buf2, v3 + 6)
	return {
		SiteId = buffer.readu32(buf2, v3 + 0),
		SourceId = bit32.rshift(v4, 2),
		Line = buffer.readu16(buf2, v3 + 4),
		Kind = bit32.band(v4, 3),
		Flags = buffer.readu8(buf2, v3 + 7),
		StateHash = buffer.readu32(buf2, v3 + 8),
		AuxHash = buffer.readu32(buf2, v3 + 12),
		Position = Vector3.new(
			buffer.readf32(buf2, v3 + 16),
			buffer.readf32(buf2, v3 + 16 + 4),
			(buffer.readf32(buf2, v3 + 16 + 8))
		),
		Velocity = Vector3.new(
			buffer.readf32(buf2, v3 + 28),
			buffer.readf32(buf2, v3 + 28 + 4),
			(buffer.readf32(buf2, v3 + 28 + 8))
		),
		Scalar = buffer.readf32(buf2, v3 + 40),
		ObjectId = buffer.readu32(buf2, v3 + 44)
	}
end

local function eventClass(data, data2)
	if data.SiteId ~= data2.SiteId or data.Kind ~= data2.Kind then
		return "ControlFlow"
	end

	if data.Position ~= data2.Position then
		return "Position"
	end

	if data.Velocity == data2.Velocity then
		if data.Flags ~= data2.Flags then
			return "StateFlags"
		end

		if data.Scalar == data2.Scalar then
			if data.ObjectId == data2.ObjectId then
				if data.StateHash == data2.StateHash then
					if data.AuxHash == data2.AuxHash then
						return nil
					end

					if data.Kind == 2 then
						return "CollisionResult"
					end

					return "InputOrSupport"
				elseif data.Kind == 2 then
					return "CollisionQueryInput"
				else
					return "HiddenState"
				end
			elseif data.Kind == 2 then
				return "CollisionSource"
			else
				return "SupportSource"
			end
		elseif data.Kind == 2 then
			return "CollisionFraction"
		else
			return "ScalarState"
		end
	elseif data.Kind == 2 then
		return "CollisionNormal"
	else
		return "Velocity"
	end
end

function v.describe(buf2)
	if v.identity(buf2) == nil or typeof(buf2) ~= "buffer" then
		return nil
	end

	local v3 = buffer.readu8(buf2, 2)
	local result = table.create(v3)

	for i = 1, v3 do
		local event = readEvent(buf2, i)
		local v4 = values[event.SiteId]
		local label

		if v4 == nil then
			label = string.format("site-0x%08X", event.SiteId)
		else
			label = v4.Label
		end

		local source

		if v4 == nil then
			source = frozen[event.SourceId] or "unknown"
		else
			source = v4.Source
		end

		result[i] = { Index = i, Label = label, Source = source, Event = event }
	end

	return result
end

function v.compare(buf2: buffer, buf3: buffer)
	local identity, v3, v4 = v.identity(buf2)
	local identity2, v5, v6 = v.identity(buf3)

	if identity == nil or identity2 == nil or identity ~= identity2 or v3 ~= v5 or v4 ~= v6 then
		return nil
	end

	local clientCount = buffer.readu8(buf2, 2)
	local serverCount = buffer.readu8(buf3, 2)
	local clientOverflow = bit32.band(buffer.readu8(buf2, 1), 1) ~= 0
	local serverOverflow = bit32.band(buffer.readu8(buf3, 1), 1) ~= 0
	local eventIndex = math.min(clientCount, serverCount)

	for i = 1, eventIndex do
		local client = readEvent(buf2, i)
		local server = readEvent(buf3, i)
		local classification = eventClass(client, server)

		if classification == nil then
			continue
		end

		local v7 = values[client.SiteId] or values[server.SiteId]
		local label

		if v7 == nil then
			label = string.format("site-0x%08X", client.SiteId)
		else
			label = v7.Label
		end

		return {
			Matched = false,
			Classification = classification,
			EventIndex = i,
			Label = label,
			Source = v7 == nil and "unknown" or v7.Source,
			ClientSource = frozen[client.SourceId] or "unknown",
			ServerSource = frozen[server.SourceId] or "unknown",
			Client = client,
			Server = server,
			ClientCount = clientCount,
			ServerCount = serverCount,
			ClientOverflow = clientOverflow,
			ServerOverflow = serverOverflow
		}
	end

	if clientCount == serverCount and clientOverflow == serverOverflow then
		return {
			Matched = true,
			Classification = "NoRecordedDifference",
			EventIndex = eventIndex,
			Label = "trace-end",
			Source = "MovementV2.Simulation.DeterminismTrace",
			ClientSource = "trace-end",
			ServerSource = "trace-end",
			Client = nil,
			Server = nil,
			ClientCount = clientCount,
			ServerCount = serverCount,
			ClientOverflow = clientOverflow,
			ServerOverflow = serverOverflow
		}
	end

	local v7 = eventIndex + 1
	local client

	if v7 <= clientCount then
		client = readEvent(buf2, v7)
	end

	local server

	if v7 <= serverCount then
		server = readEvent(buf3, v7)
	end

	local v8 = client or server
	local v9

	if v8 ~= nil then
		v9 = values[v8.SiteId]
	end

	local v10 = {
		Matched = false,
		Classification = (clientOverflow or serverOverflow) and "TraceOverflow" or "ControlFlowLength",
		EventIndex = eventIndex + 1,
		Label = 0,
		Source = 0,
		ClientSource = 0,
		ServerSource = 0,
		Client = 0,
		Server = 0,
		ClientCount = 0,
		ServerCount = 0,
		ClientOverflow = 0,
		ServerOverflow = 0
	}
	local label

	if v9 == nil then
		label = v8 == nil and "trace-end" or string.format("site-0x%08X", v8.SiteId)
	else
		label = v9.Label
	end

	v10.Label = label
	v10.Source = v9 == nil and "MovementV2.Simulation.DeterminismTrace" or v9.Source
	v10.ClientSource = client == nil and "trace-end" or frozen[client.SourceId] or "unknown"
	v10.ServerSource = server == nil and "trace-end" or frozen[server.SourceId] or "unknown"
	v10.Client = client
	v10.Server = server
	v10.ClientCount = clientCount
	v10.ServerCount = serverCount
	v10.ClientOverflow = clientOverflow
	v10.ServerOverflow = serverOverflow
	return v10
end

v.Ring = class
v.MaxEvents = 128
return table.freeze(v)