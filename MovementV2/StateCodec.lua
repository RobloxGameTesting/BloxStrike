local Buttons = require(script.Parent.Buttons)
local Enums = require(script.Parent.Enums)
local Quantization = require(script.Parent.Quantization)
require(script.Parent.Types)
local v = { Version = 6, WireSize = 91 }
local isVector3Within = Quantization.isVector3Within
local writeVector3F32 = Quantization.writeVector3F32
local readVector3F32 = Quantization.readVector3F32

local function numberWithin(p, p2: number, p3: number)
	local finite = Quantization.isFinite(p)

	if finite then
		if p2 <= p then
			finite = p <= p3
		else
			finite = false
		end
	end

	return finite
end

function v.validate(data)
	if typeof(data) ~= "table" then
		return false, "StateNotTable"
	end

	local movementTick = data.MovementTick
	local finite = Quantization.isFinite(movementTick)

	if finite then
		if movementTick >= 0 then
			finite = movementTick <= 4294967295
		else
			finite = false
		end
	end

	if not finite or data.MovementTick % 1 ~= 0 then
		return false, "InvalidMovementTick"
	end

	if not isVector3Within(data.Position, 1000000) then
		return false, "InvalidPosition"
	end

	if not isVector3Within(data.Velocity, 100000) then
		return false, "InvalidVelocity"
	end

	if not Quantization.isFinite(data.LookYaw) then
		return false, "InvalidLookYaw"
	end

	local verticalLook = data.VerticalLook
	local finite2 = Quantization.isFinite(verticalLook)

	if finite2 then
		if verticalLook >= -1 then
			finite2 = verticalLook <= 1
		else
			finite2 = false
		end
	end

	if not finite2 then
		return false, "InvalidVerticalLook"
	end

	local baseMoveSpeed = data.BaseMoveSpeed
	local finite3 = Quantization.isFinite(baseMoveSpeed)

	if finite3 then
		if baseMoveSpeed >= 0 then
			finite3 = baseMoveSpeed <= 10000
		else
			finite3 = false
		end
	end

	if not finite3 then
		return false, "InvalidBaseMoveSpeed"
	end

	local weaponMoveSpeed = data.WeaponMoveSpeed
	local finite4 = Quantization.isFinite(weaponMoveSpeed)

	if finite4 then
		if weaponMoveSpeed >= 0 then
			finite4 = weaponMoveSpeed <= 10000
		else
			finite4 = false
		end
	end

	if not finite4 then
		return false, "InvalidWeaponMoveSpeed"
	end

	local weaponScopedMoveSpeed = data.WeaponScopedMoveSpeed
	local finite5 = Quantization.isFinite(weaponScopedMoveSpeed)

	if finite5 then
		if weaponScopedMoveSpeed >= 0 then
			finite5 = weaponScopedMoveSpeed <= 10000
		else
			finite5 = false
		end
	end

	if not finite5 then
		return false, "InvalidWeaponScopedMoveSpeed"
	end

	local velocityModifier = data.VelocityModifier
	local finite6 = Quantization.isFinite(velocityModifier)

	if finite6 then
		if velocityModifier >= 0 then
			finite6 = velocityModifier <= 1
		else
			finite6 = false
		end
	end

	if not finite6 then
		return false, "InvalidVelocityModifier"
	end

	if data.MovementMode ~= "Walking" and data.MovementMode ~= "Ladder" then
		return false, "InvalidMovementMode"
	end

	if data.Stance ~= "Standing" and data.Stance ~= "Ducking" then
		return false, "InvalidStance"
	end

	if typeof(data.OnGround) ~= "boolean" then
		return false, "InvalidOnGround"
	end

	if not isVector3Within(data.GroundNormal, 2) then
		return false, "InvalidGroundNormal"
	end

	if data.OnGround and data.GroundNormal.Magnitude <= 1e-8 then
		return false, "MissingGroundNormal"
	end

	if not isVector3Within(data.WallNormal, 2) then
		return false, "InvalidWallNormal"
	end

	local groundSurfaceFriction = data.GroundSurfaceFriction
	local finite7 = Quantization.isFinite(groundSurfaceFriction)

	if finite7 then
		if groundSurfaceFriction >= 0 then
			finite7 = groundSurfaceFriction <= 100
		else
			finite7 = false
		end
	end

	if not finite7 then
		return false, "InvalidGroundSurfaceFriction"
	end

	local duckAmount = data.DuckAmount
	local finite8 = Quantization.isFinite(duckAmount)

	if finite8 then
		if duckAmount >= 0 then
			finite8 = duckAmount <= 1
		else
			finite8 = false
		end
	end

	if not finite8 then
		return false, "InvalidDuckAmount"
	end

	local duckTimeMsecs = data.DuckTimeMsecs
	local finite9 = Quantization.isFinite(duckTimeMsecs)

	if finite9 then
		if duckTimeMsecs >= 0 then
			finite9 = duckTimeMsecs <= 60000
		else
			finite9 = false
		end
	end

	if not finite9 then
		return false, "InvalidDuckTimeMsecs"
	end

	if typeof(data.IsDucking) ~= "boolean" then
		return false, "InvalidIsDucking"
	end

	local duckSpeed = data.DuckSpeed
	local finite10 = Quantization.isFinite(duckSpeed)

	if finite10 then
		if duckSpeed >= 0 then
			finite10 = duckSpeed <= 100
		else
			finite10 = false
		end
	end

	if not finite10 then
		return false, "InvalidDuckSpeed"
	end

	local duckCooldownSeconds = data.DuckCooldownSeconds
	local finite11 = Quantization.isFinite(duckCooldownSeconds)

	if finite11 then
		if duckCooldownSeconds >= 0 then
			finite11 = duckCooldownSeconds <= 60
		else
			finite11 = false
		end
	end

	if not finite11 then
		return false, "InvalidDuckCooldownSeconds"
	end

	local stamina = data.Stamina
	local finite12 = Quantization.isFinite(stamina)

	if finite12 then
		if stamina >= 0 then
			finite12 = stamina <= 10000
		else
			finite12 = false
		end
	end

	if not finite12 then
		return false, "InvalidStamina"
	end

	local lastJumpCommandNumber = data.LastJumpCommandNumber
	local finite13 = Quantization.isFinite(lastJumpCommandNumber)

	if finite13 then
		if lastJumpCommandNumber >= 0 then
			finite13 = lastJumpCommandNumber <= 4294967295
		else
			finite13 = false
		end
	end

	if not finite13 or data.LastJumpCommandNumber % 1 ~= 0 then
		return false, "InvalidLastJumpCommandNumber"
	end

	if not Buttons.isValid(data.PreviousButtons) then
		return false, "InvalidPreviousButtons"
	end

	local jumpBufferTicksRemaining = data.JumpBufferTicksRemaining
	local finite14 = Quantization.isFinite(jumpBufferTicksRemaining)

	if finite14 then
		if jumpBufferTicksRemaining >= 0 then
			finite14 = jumpBufferTicksRemaining <= 255
		else
			finite14 = false
		end
	end

	if not finite14 or data.JumpBufferTicksRemaining % 1 ~= 0 then
		return false, "InvalidJumpBufferTicksRemaining"
	end

	if typeof(data.JumpHullActive) ~= "boolean" then
		return false, "InvalidJumpHullActive"
	end

	local stuckStepTicks = data.StuckStepTicks
	local finite15 = Quantization.isFinite(stuckStepTicks)

	if finite15 then
		if stuckStepTicks >= 0 then
			finite15 = stuckStepTicks <= 255
		else
			finite15 = false
		end
	end

	if finite15 and data.StuckStepTicks % 1 == 0 then
		return true, nil
	end

	return false, "InvalidStuckStepTicks"
end

local function writeNormal(buf: buffer, offset: number, vector: Vector3) -- 2 equivalent calls inferred from this helper
	local quantizeNormal, v2, v3 = Quantization.quantizeNormal(vector)
	buffer.writei16(buf, offset, quantizeNormal)
	buffer.writei16(buf, offset + 2, v2)
	buffer.writei16(buf, offset + 4, v3)
	return offset + 6
end

local function readNormal(buf: buffer, offset: number) -- 2 equivalent calls inferred from this helper
	return
		Quantization.dequantizeNormal(
			buffer.readi16(buf, offset),
			buffer.readi16(buf, offset + 2),
			(buffer.readi16(buf, offset + 4))
		),
		offset + 6
end

function v.writeValidated(buf: buffer, offset: number, data)
	local v2 = offset % 1 == 0 and offset >= 0
	assert(v2, "invalid state write offset")
	local v3 = buffer.len(buf)
	assert(offset + 91 <= v3, "state write exceeds target buffer")
	buffer.writeu8(buf, offset, 6)
	local v4 = writeVector3F32(buf, writeVector3F32(buf, offset + 1, data.Position), data.Velocity)
	buffer.writeu16(buf, v4, (Quantization.quantizeYaw(data.LookYaw)))
	local v5 = v4 + 2
	buffer.writei8(buf, v5, (Quantization.quantizeSignedUnit(data.VerticalLook)))
	local v6 = v5 + 1
	local v7 = 0

	if data.OnGround then
		v7 = bit32.bor(v7, 1)
	end

	if data.IsDucking then
		v7 = bit32.bor(v7, 2)
	end

	if data.JumpHullActive then
		v7 = bit32.bor(v7, 4)
	end

	buffer.writeu8(buf, v6, v7)
	local v8 = v6 + 1
	local v9

	if data.MovementMode == "Ladder" then
		v9 = Enums.MovementMode.Ladder
	else
		v9 = Enums.MovementMode.Walking
	end

	buffer.writeu8(buf, v8, v9)
	local v10 = v8 + 1
	local v11

	if data.Stance == "Ducking" then
		v11 = Enums.Stance.Ducking
	else
		v11 = Enums.Stance.Standing
	end

	buffer.writeu8(buf, v10, v11)
	local v12 = writeNormal(buf, writeNormal(buf, v10 + 1, data.GroundNormal), data.WallNormal) -- inferred equivalent call
	buffer.writef32(buf, v12, data.GroundSurfaceFriction)
	local v13 = v12 + 4
	buffer.writef32(buf, v13, data.BaseMoveSpeed)
	local v14 = v13 + 4
	buffer.writeu8(buf, v14, (Quantization.quantizeUnitByte(data.DuckAmount)))
	local v15 = v14 + 1
	buffer.writef32(buf, v15, data.DuckTimeMsecs)
	local v16 = v15 + 4
	buffer.writef32(buf, v16, data.DuckSpeed)
	local v17 = v16 + 4
	buffer.writef32(buf, v17, data.DuckCooldownSeconds)
	local v18 = v17 + 4
	buffer.writef32(buf, v18, data.Stamina)
	local v19 = v18 + 4
	buffer.writeu32(buf, v19, data.LastJumpCommandNumber)
	local v20 = v19 + 4
	buffer.writeu8(buf, v20, data.PreviousButtons)
	local v21 = v20 + 1
	buffer.writeu8(buf, v21, data.JumpBufferTicksRemaining)
	local v22 = v21 + 1
	buffer.writeu8(buf, v22, data.StuckStepTicks)
	local v23 = v22 + 1
	buffer.writef32(buf, v23, data.WeaponMoveSpeed)
	local v24 = v23 + 4
	buffer.writef32(buf, v24, data.WeaponScopedMoveSpeed)
	local v25 = v24 + 4
	buffer.writef32(buf, v25, data.VelocityModifier)
	local v26 = v25 + 4
	buffer.writeu32(buf, v26, data.MovementTick)
	local v27 = v26 + 4
	assert(v27 - offset == 91, "MovementV2 state wire size drift")
	return v27
end

function v.encode(p)
	local v2, v3 = v.validate(p)

	if not v2 then
		return nil, v3
	end

	local buf = buffer.create(91)
	v.writeValidated(buf, 0, p)
	return buf, nil
end

function v.decodeFrom(buf, offset)
	if typeof(buf) ~= "buffer" then
		return nil, nil, "StatePayloadNotBuffer"
	end

	if typeof(offset) ~= "number" or offset % 1 ~= 0 or offset < 0 then
		return nil, nil, "InvalidStateOffset"
	end

	if buffer.len(buf) < offset + 91 then
		return nil, nil, "StatePayloadSize"
	end

	if buffer.readu8(buf, offset) ~= 6 then
		return nil, nil, "StateVersion"
	end

	local position, v2 = readVector3F32(buf, offset + 1)
	local velocity, v3 = readVector3F32(buf, v2)
	local dequantizeYaw = Quantization.dequantizeYaw((buffer.readu16(buf, v3)))
	local v4 = v3 + 2
	local dequantizeSignedUnit = Quantization.dequantizeSignedUnit((buffer.readi8(buf, v4)))
	local v5 = v4 + 1
	local v6 = buffer.readu8(buf, v5)
	local v7 = v5 + 1

	if bit32.band(v6, 4294967288) ~= 0 then
		return nil, nil, "InvalidStateFlags"
	end

	local v8 = buffer.readu8(buf, v7)
	local v9 = v7 + 1

	if Enums.MovementMode.Ladder < v8 then
		return nil, nil, "InvalidMovementMode"
	end

	local v10 = buffer.readu8(buf, v9)
	local v11 = v9 + 1

	if Enums.Stance.Ducking < v10 then
		return nil, nil, "InvalidStance"
	end

	local groundNormal, v12 = readNormal(buf, v11) -- inferred equivalent call
	local wallNormal, v13 = readNormal(buf, v12) -- inferred equivalent call
	local groundSurfaceFriction = buffer.readf32(buf, v13)
	local v14 = v13 + 4
	local baseMoveSpeed = buffer.readf32(buf, v14)
	local v15 = v14 + 4
	local dequantizeUnitByte = Quantization.dequantizeUnitByte((buffer.readu8(buf, v15)))
	local v16 = v15 + 1
	local duckTimeMsecs = buffer.readf32(buf, v16)
	local v17 = v16 + 4
	local duckSpeed = buffer.readf32(buf, v17)
	local v18 = v17 + 4
	local duckCooldownSeconds = buffer.readf32(buf, v18)
	local v19 = v18 + 4
	local stamina = buffer.readf32(buf, v19)
	local v20 = v19 + 4
	local lastJumpCommandNumber = buffer.readu32(buf, v20)
	local v21 = v20 + 4
	local previousButtons = buffer.readu8(buf, v21)
	local v22 = v21 + 1
	local jumpBufferTicksRemaining = buffer.readu8(buf, v22)
	local v23 = v22 + 1
	local stuckStepTicks = buffer.readu8(buf, v23)
	local v24 = v23 + 1
	local weaponMoveSpeed = buffer.readf32(buf, v24)
	local v25 = v24 + 4
	local weaponScopedMoveSpeed = buffer.readf32(buf, v25)
	local v26 = v25 + 4
	local velocityModifier = buffer.readf32(buf, v26)
	local v27 = v26 + 4
	local movementTick = buffer.readu32(buf, v27)
	local v28 = v27 + 4
	assert(v28 - offset == 91, "MovementV2 state wire size drift")
	local v29 = {
		Position = position,
		Velocity = velocity,
		LookYaw = dequantizeYaw,
		VerticalLook = dequantizeSignedUnit,
		BaseMoveSpeed = baseMoveSpeed,
		WeaponMoveSpeed = weaponMoveSpeed,
		WeaponScopedMoveSpeed = weaponScopedMoveSpeed,
		VelocityModifier = velocityModifier,
		MovementTick = movementTick,
		MovementMode = v8 == Enums.MovementMode.Ladder and "Ladder" or "Walking",
		Stance = v10 == Enums.Stance.Ducking and "Ducking" or "Standing",
		OnGround = bit32.band(v6, 1) ~= 0,
		GroundNormal = groundNormal,
		WallNormal = wallNormal,
		GroundSurfaceFriction = groundSurfaceFriction,
		DuckAmount = dequantizeUnitByte,
		DuckTimeMsecs = duckTimeMsecs,
		IsDucking = bit32.band(v6, 2) ~= 0,
		DuckSpeed = duckSpeed,
		DuckCooldownSeconds = duckCooldownSeconds,
		Stamina = stamina,
		LastJumpCommandNumber = lastJumpCommandNumber,
		PreviousButtons = previousButtons,
		JumpBufferTicksRemaining = jumpBufferTicksRemaining,
		JumpHullActive = bit32.band(v6, 4) ~= 0,
		StuckStepTicks = stuckStepTicks
	}
	local v30, v31 = v.validate(v29)

	if v30 then
		return v29, v28, nil
	end

	return nil, nil, v31
end

function v.decode(buf)
	if typeof(buf) ~= "buffer" then
		return nil, "StatePayloadNotBuffer"
	end

	if buffer.len(buf) ~= 91 then
		return nil, "StatePayloadSize"
	end

	local decodeFrom, _, v2 = v.decodeFrom(buf, 0)
	return decodeFrom, v2
end

function v.canonicalize(p)
	local encoded, v2 = v.encode(p)

	if encoded == nil then
		return nil, v2
	end

	return v.decode(encoded)
end

return table.freeze(v)