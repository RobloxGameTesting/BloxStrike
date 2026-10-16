local Buttons = require(script.Parent.Buttons)
local Config = require(script.Parent.Config)
local Quantization = require(script.Parent.Quantization)
local Serial = require(script.Parent.Serial)
require(script.Parent.Types)
local v = {
	Version = 5,
	HeaderSize = 10,
	CommandSize = 6,
	MaxDeltaCommandSize = 7,
	MaxWeaponSelectionSize = 200
}

local function resolveConfig(p) -- 2 equivalent calls inferred from this helper
	return p or Config.Default
end

function v.validateCommand(p, data)
	if not Serial.isUInt32(p) then
		return false, "InvalidCommandNumber"
	end

	if typeof(data) ~= "table" then
		return false, "CommandNotTable"
	end

	if not Quantization.isFiniteVector2(data.Move) then
		return false, "InvalidMove"
	end

	if not Quantization.isFinite(data.LookYaw) then
		return false, "InvalidLookYaw"
	end

	if not Quantization.isFinite(data.VerticalLook) then
		return false, "InvalidVerticalLook"
	end

	if not Buttons.isValid(data.Buttons) then
		return false, "InvalidButtons"
	end

	local weaponSelectRequestId = data.WeaponSelectRequestId
	local weaponSelectIdentifier = data.WeaponSelectIdentifier
	local grenadeThrowIdentifier = data.GrenadeThrowIdentifier
	local grenadeThrowAnimation = data.GrenadeThrowAnimation

	if
		weaponSelectRequestId == nil
		and weaponSelectIdentifier == nil
		and grenadeThrowIdentifier == nil
		and grenadeThrowAnimation == nil
	then
		return true, nil
	end

	if
		not Serial.isUInt32(weaponSelectRequestId)
		or weaponSelectRequestId == 0
		or typeof(weaponSelectIdentifier) ~= "string"
		or #weaponSelectIdentifier > 96
	then
		return false, "InvalidWeaponSelection"
	end

	if grenadeThrowIdentifier ~= nil or grenadeThrowAnimation ~= nil then
		if
			type(grenadeThrowIdentifier) ~= "string"
			or #grenadeThrowIdentifier < 1
			or #grenadeThrowIdentifier > 96
			or grenadeThrowAnimation ~= "Far" and grenadeThrowAnimation ~= "Near"
		then
			return false, "InvalidGrenadeThrowSelection"
		end
	elseif #weaponSelectIdentifier < 1 then
		return false, "InvalidWeaponSelection"
	end

	return true, nil
end

function v:canonicalizeCommandInto(commandNumber, data)
	if typeof(self) ~= "table" or table.isfrozen(self) then
		return nil, "InvalidCanonicalCommandTarget"
	end

	local v2, v3 = v.validateCommand(commandNumber, data)

	if not v2 then
		return nil, v3
	end

	local canonicalMove = Quantization.canonicalMove(data.Move)
	local quantizeSignedUnit = Quantization.quantizeSignedUnit(canonicalMove.X)
	local quantizeSignedUnit2 = Quantization.quantizeSignedUnit(canonicalMove.Y)
	local vector = Vector2.new(
		Quantization.dequantizeSignedUnit(quantizeSignedUnit),
		Quantization.dequantizeSignedUnit(quantizeSignedUnit2)
	)
	local canonicalMove2 = Quantization.canonicalMove(vector)
	self.CommandNumber = commandNumber
	self.Move = canonicalMove2
	self.LookYaw = Quantization.dequantizeYaw(Quantization.quantizeYaw(data.LookYaw))
	self.VerticalLook = Quantization.dequantizeSignedUnit(Quantization.quantizeSignedUnit(data.VerticalLook))
	self.Buttons = data.Buttons
	self.WeaponSelectRequestId = data.WeaponSelectRequestId
	self.WeaponSelectIdentifier = data.WeaponSelectIdentifier
	self.GrenadeThrowIdentifier = data.GrenadeThrowIdentifier
	self.GrenadeThrowAnimation = data.GrenadeThrowAnimation
	self.PredictedBaseMoveSpeed = data.PredictedBaseMoveSpeed
	self.PredictedWeaponMoveSpeed = data.PredictedWeaponMoveSpeed
	self.PredictedWeaponScopedMoveSpeed = data.PredictedWeaponScopedMoveSpeed
	return self, nil
end

function v.canonicalizeCommand(p, p2)
	return v.canonicalizeCommandInto({}, p, p2)
end

function v.validatePacket(data, p)
	local config = resolveConfig(p) -- inferred equivalent call

	if typeof(data) ~= "table" then
		return false, "PacketNotTable"
	end

	if not Serial.isNonZeroUInt16(data.Generation) then
		return false, "InvalidGeneration"
	end

	if not Serial.isUInt32(data.FirstCommandNumber) then
		return false, "InvalidFirstCommandNumber"
	end

	if
		typeof(data.RedundantCommandCount) ~= "number"
		or data.RedundantCommandCount % 1 ~= 0
		or data.RedundantCommandCount < 0
		or data.RedundantCommandCount > config.TargetRedundantCommandCount
	then
		return false, "InvalidRedundantCommandCount"
	end

	if
		typeof(data.NewCommandCount) ~= "number"
		or data.NewCommandCount % 1 ~= 0
		or data.NewCommandCount < 1
		or data.NewCommandCount > config.MaxNewCommandsPerPacket
	then
		return false, "InvalidNewCommandCount"
	end

	if typeof(data.Commands) ~= "table" then
		return false, "CommandsNotTable"
	end

	local v2 = data.RedundantCommandCount + data.NewCommandCount

	if v2 ~= #data.Commands or config.MaxCommandsPerPacket < v2 or v2 > 255 then
		return false, "CommandCountMismatch"
	end

	for i = 1, v2 do
		local v3 = Serial.addUInt32(data.FirstCommandNumber, i - 1)
		local command = data.Commands[i]

		if typeof(command) ~= "table" or command.CommandNumber ~= v3 then
			return false, "NonSequentialCommands"
		end

		local v4, v5 = v.validateCommand(v3, command)

		if not v4 then
			return false, v5
		end
	end

	return true, nil
end

function v.makePacket(generation, commands, newCommandCount, p)
	if typeof(commands) ~= "table" or #commands == 0 then
		return nil, "CommandsNotTable"
	end

	if typeof(newCommandCount) ~= "number" or newCommandCount % 1 ~= 0 then
		return nil, "InvalidNewCommandCount"
	end

	local v2 = commands[1]

	if typeof(v2) ~= "table" or not Serial.isUInt32(v2.CommandNumber) then
		return nil, "InvalidFirstCommandNumber"
	end

	local v3 = {
		Generation = generation,
		FirstCommandNumber = v2.CommandNumber,
		RedundantCommandCount = #commands - newCommandCount,
		NewCommandCount = newCommandCount,
		Commands = commands
	}
	local v4, v5 = v.validatePacket(v3, p)

	if v4 then
		return v3, nil
	end

	return nil, v5
end

local function commandFields(data) -- 4 equivalent calls inferred from this helper
	local canonicalMove = Quantization.canonicalMove(data.Move)
	return
		Quantization.quantizeSignedUnit(canonicalMove.X),
		Quantization.quantizeSignedUnit(canonicalMove.Y),
		Quantization.quantizeYaw(data.LookYaw),
		Quantization.quantizeSignedUnit(data.VerticalLook),
		data.Buttons
end

local function changedFieldMask(p: number, p2: number, p3: number, p4: number, p5: number, p6: number, p7: number, p8: number, p9: number, p10: number) -- 2 equivalent calls inferred from this helper
	local v2 = 0

	if p ~= p6 then
		v2 = bit32.bor(v2, 1)
	end

	if p2 ~= p7 then
		v2 = bit32.bor(v2, 2)
	end

	if p3 ~= p8 then
		v2 = bit32.bor(v2, 4)
	end

	if p4 ~= p9 then
		v2 = bit32.bor(v2, 8)
	end

	if p5 ~= p10 then
		return (bit32.bor(v2, 16))
	end

	return v2
end

local function changedFieldWireSize(p: number) -- 2 equivalent calls inferred from this helper
	local total = 0

	if bit32.band(p, 1) ~= 0 then
		total += 1
	end

	if bit32.band(p, 2) ~= 0 then
		total += 1
	end

	if bit32.band(p, 4) ~= 0 then
		total += 2
	end

	if bit32.band(p, 8) ~= 0 then
		total += 1
	end

	if bit32.band(p, 16) ~= 0 then
		total += 1
	end

	return total
end

local function writeFullCommand(buf: buffer, offset: number, value: number, value2: number, value3: number, value4: number, value5: number)
	buffer.writei8(buf, offset, value)
	buffer.writei8(buf, offset + 1, value2)
	buffer.writeu16(buf, offset + 2, value3)
	buffer.writei8(buf, offset + 4, value4)
	buffer.writeu8(buf, offset + 5, value5)
	return offset + 6
end

local function writeChangedFields(buf: buffer, offset: number, p: number, value: number, value2: number, value3: number, value4: number, value5: number)
	if bit32.band(p, 1) ~= 0 then
		buffer.writei8(buf, offset, value)
		offset += 1
	end

	if bit32.band(p, 2) ~= 0 then
		buffer.writei8(buf, offset, value2)
		offset += 1
	end

	if bit32.band(p, 4) ~= 0 then
		buffer.writeu16(buf, offset, value3)
		offset += 2
	end

	if bit32.band(p, 8) ~= 0 then
		buffer.writei8(buf, offset, value4)
		offset += 1
	end

	if bit32.band(p, 16) ~= 0 then
		buffer.writeu8(buf, offset, value5)
		offset += 1
	end

	return offset
end

function v.encode(data, p)
	local v2, v3 = v.validatePacket(data, p)

	if not v2 then
		return nil, v3
	end

	local v4 = data.RedundantCommandCount + data.NewCommandCount
	local v5, v6, v7, v8, v9 = commandFields(data.Commands[1]) -- inferred equivalent call
	local total = 16
	local count = 0

	for i = 2, v4 do
		local v10, v11, v12, v13, v14 = commandFields(data.Commands[i]) -- inferred equivalent call
		total += changedFieldWireSize(changedFieldMask(v10, v11, v12, v13, v14, v5, v6, v7, v8, v9)) + 1 -- inferred equivalent call
		v9 = v14
		v8 = v13
		v7 = v12
		v6 = v11
		v5 = v10
	end

	for _, command in data.Commands do
		local weaponSelectIdentifier = command.WeaponSelectIdentifier

		if weaponSelectIdentifier == nil then
			continue
		end

		local grenadeThrowIdentifier = command.GrenadeThrowIdentifier
		local v10 = grenadeThrowIdentifier == nil and 0 or #grenadeThrowIdentifier
		count += 1
		total += #weaponSelectIdentifier + 8 + v10
	end

	local buf = buffer.create(total)
	buffer.writeu8(buf, 0, 5)
	buffer.writeu16(buf, 1, data.Generation)
	buffer.writeu32(buf, 3, data.FirstCommandNumber)
	buffer.writeu8(buf, 7, data.NewCommandCount)
	buffer.writeu8(buf, 8, data.RedundantCommandCount)
	buffer.writeu8(buf, 9, count)
	local v10, v11, v12, v13, v14 = commandFields(data.Commands[1]) -- inferred equivalent call
	buffer.writei8(buf, 10, v10)
	buffer.writei8(buf, 11, v11)
	buffer.writeu16(buf, 12, v12)
	buffer.writei8(buf, 14, v13)
	buffer.writeu8(buf, 15, v14)
	local v15 = 16

	for i = 2, v4 do
		local v16, v17, v18, v19, v20 = commandFields(data.Commands[i]) -- inferred equivalent call
		local v21 = changedFieldMask(v16, v17, v18, v19, v20, v10, v11, v12, v13, v14) -- inferred equivalent call
		buffer.writeu8(buf, v15, v21)
		v15 = writeChangedFields(buf, v15 + 1, v21, v16, v17, v18, v19, v20)
		v14 = v20
		v13 = v19
		v12 = v18
		v11 = v17
		v10 = v16
	end

	for k, command in data.Commands do
		local weaponSelectIdentifier = command.WeaponSelectIdentifier

		if weaponSelectIdentifier == nil then
			continue
		end

		local grenadeThrowIdentifier = command.GrenadeThrowIdentifier
		local grenadeThrowAnimation = command.GrenadeThrowAnimation
		local v16 = grenadeThrowIdentifier == nil and 0 or #grenadeThrowIdentifier
		local v17 = grenadeThrowAnimation == "Far" and 1 or grenadeThrowAnimation == "Near" and 2 or 0
		buffer.writeu8(buf, v15, k - 1)
		buffer.writeu32(buf, v15 + 1, command.WeaponSelectRequestId)
		buffer.writeu8(buf, v15 + 5, #weaponSelectIdentifier)
		buffer.writeu8(buf, v15 + 6, v16)
		buffer.writeu8(buf, v15 + 7, v17)
		buffer.writestring(buf, v15 + 8, weaponSelectIdentifier)

		if grenadeThrowIdentifier ~= nil then
			buffer.writestring(buf, v15 + 8 + #weaponSelectIdentifier, grenadeThrowIdentifier)
		end

		v15 += #weaponSelectIdentifier + 8 + v16
	end

	assert(v15 == buffer.len(buf), "MovementV2 command wire size drift")
	return buf, nil
end

function v.decode(buf, p)
	local config = resolveConfig(p) -- inferred equivalent call

	if typeof(buf) ~= "buffer" then
		return nil, "CommandPayloadNotBuffer"
	end

	local v2 = buffer.len(buf)

	if v2 < 10 then
		return nil, "CommandPayloadTruncated"
	end

	if buffer.readu8(buf, 0) ~= 5 then
		return nil, "CommandVersion"
	end

	local generation = buffer.readu16(buf, 1)
	local firstCommandNumber = buffer.readu32(buf, 3)
	local newCommandCount = buffer.readu8(buf, 7)
	local redundantCommandCount = buffer.readu8(buf, 8)
	local v3 = buffer.readu8(buf, 9)
	local v4 = newCommandCount + redundantCommandCount

	if not Serial.isNonZeroUInt16(generation) then
		return nil, "InvalidGeneration"
	end

	if newCommandCount < 1 or config.MaxNewCommandsPerPacket < newCommandCount then
		return nil, "InvalidNewCommandCount"
	end

	if config.TargetRedundantCommandCount < redundantCommandCount then
		return nil, "InvalidRedundantCommandCount"
	end

	if config.MaxCommandsPerPacket < v4 then
		return nil, "CommandCountTooLarge"
	end

	if v4 < v3 then
		return nil, "InvalidWeaponSelectionCount"
	end

	local v5 = math.max(0, v4 - 1) * 1 + 16 + v3 * 8
	local v6 = math.max(0, v4 - 1) * 7 + 16 + v3 * 200

	if v2 < v5 or v6 < v2 then
		return nil, "CommandPayloadSize"
	end

	local commands = table.create(v4)
	local v7 = 10
	local v8 = buffer.readi8(buf, v7)
	local v9 = buffer.readi8(buf, v7 + 1)
	local v10 = buffer.readu16(buf, v7 + 2)
	local v11 = buffer.readi8(buf, v7 + 4)
	local buttons = buffer.readu8(buf, v7 + 5)
	local v12 = v7 + 6

	for i = 1, v4 do
		if i > 1 then
			if v2 - v12 < 1 then
				return nil, "CommandPayloadSize"
			end

			local v13 = buffer.readu8(buf, v12)
			v12 += 1

			if bit32.band(v13, 4294967264) ~= 0 then
				return nil, "InvalidCommandDeltaMask"
			end

			local total = changedFieldWireSize(v13) -- inferred equivalent call

			if v2 - v12 < total then
				return nil, "CommandPayloadSize"
			end

			if bit32.band(v13, 1) ~= 0 then
				v8 = buffer.readi8(buf, v12)
				v12 += 1
			end

			if bit32.band(v13, 2) ~= 0 then
				v9 = buffer.readi8(buf, v12)
				v12 += 1
			end

			if bit32.band(v13, 4) ~= 0 then
				v10 = buffer.readu16(buf, v12)
				v12 += 2
			end

			if bit32.band(v13, 8) ~= 0 then
				v11 = buffer.readi8(buf, v12)
				v12 += 1
			end

			if bit32.band(v13, 16) ~= 0 then
				buttons = buffer.readu8(buf, v12)
				v12 += 1
			end
		end

		local vector = Vector2.new(Quantization.dequantizeSignedUnit(v8), Quantization.dequantizeSignedUnit(v9))
		local canonicalMove = Quantization.canonicalMove(vector)

		if not Buttons.isValid(buttons) then
			return nil, "InvalidButtons"
		end

		commands[i] = {
			CommandNumber = Serial.addUInt32(firstCommandNumber, i - 1),
			Move = canonicalMove,
			LookYaw = Quantization.dequantizeYaw(v10),
			VerticalLook = Quantization.dequantizeSignedUnit(v11),
			Buttons = buttons
		}
	end

	local v13 = {}

	for _ = 1, v3 do
		if v2 - v12 < 8 then
			return nil, "CommandPayloadSize"
		end

		local v14 = buffer.readu8(buf, v12) + 1
		local weaponSelectRequestId = buffer.readu32(buf, v12 + 1)
		local v15 = buffer.readu8(buf, v12 + 5)
		local v16 = buffer.readu8(buf, v12 + 6)
		local v17 = buffer.readu8(buf, v12 + 7)
		local v18 = v12 + 8 + v15 + v16
		local v19 = v17 ~= 0 or v16 ~= 0

		if
			v4 < v14
			or v13[v14] == true
			or weaponSelectRequestId == 0
			or v15 > 96
			or v16 > 96
			or not v19 and v15 < 1
			or v19 and v16 < 1
			or v19 and v17 ~= 1 and v17 ~= 2
			or v2 < v18
		then
			return nil, "InvalidWeaponSelection"
		end

		local v20 = commands[v14]
		v20.WeaponSelectRequestId = weaponSelectRequestId
		v20.WeaponSelectIdentifier = buffer.readstring(buf, v12 + 8, v15)

		if v19 then
			v20.GrenadeThrowIdentifier = buffer.readstring(buf, v12 + 8 + v15, v16)
			v20.GrenadeThrowAnimation = v17 == 1 and "Far" or "Near"
		end

		v13[v14] = true
		v12 = v18
	end

	if v12 ~= v2 then
		return nil, "CommandPayloadSize"
	end

	for _, list in commands do
		table.freeze(list)
	end

	table.freeze(commands)
	return table.freeze({
		Generation = generation,
		FirstCommandNumber = firstCommandNumber,
		RedundantCommandCount = redundantCommandCount,
		NewCommandCount = newCommandCount,
		Commands = commands
	}), nil
end

return table.freeze(v)