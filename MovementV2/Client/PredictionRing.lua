local createVector = vector.create
local CommandCodec = require(script.Parent.Parent.CommandCodec)
local Config = require(script.Parent.Parent.Config)
local Enums = require(script.Parent.Parent.Enums)
local Mapping = require(script.Parent.Parent.Mapping)
local Quantization = require(script.Parent.Parent.Quantization)
local Serial = require(script.Parent.Parent.Serial)
local StateCodec = require(script.Parent.Parent.StateCodec)
require(script.Parent.Parent.Types)
local State = require(script.Parent.Parent.Simulation.State)
local class = {}
class.__index = class
class.Dependency = table.freeze({ Player = 1, Mover = 2, ValidMask = 3 })

local function slotIndex(data, p: number) -- 3 equivalent calls inferred from this helper
	local newestCommandNumber = data._newestCommandNumber

	if newestCommandNumber == nil then
		return 1
	end

	return (data._newestSlotIndex - 1 + Serial.deltaUInt32(p, newestCommandNumber)) % data._capacity + 1
end

local function copyStateInto(postState, data)
	postState.Position = data.Position
	postState.Velocity = data.Velocity
	postState.LookYaw = data.LookYaw
	postState.VerticalLook = data.VerticalLook
	postState.BaseMoveSpeed = data.BaseMoveSpeed
	postState.WeaponMoveSpeed = data.WeaponMoveSpeed
	postState.WeaponScopedMoveSpeed = data.WeaponScopedMoveSpeed
	postState.VelocityModifier = data.VelocityModifier
	postState.MovementTick = data.MovementTick
	postState.MovementMode = data.MovementMode
	postState.Stance = data.Stance
	postState.OnGround = data.OnGround
	postState.GroundNormal = data.GroundNormal
	postState.WallNormal = data.WallNormal
	postState.GroundSurfaceFriction = data.GroundSurfaceFriction
	postState.DuckAmount = data.DuckAmount
	postState.DuckTimeMsecs = data.DuckTimeMsecs
	postState.IsDucking = data.IsDucking
	postState.DuckSpeed = data.DuckSpeed
	postState.DuckCooldownSeconds = data.DuckCooldownSeconds
	postState.Stamina = data.Stamina
	postState.LastJumpCommandNumber = data.LastJumpCommandNumber
	postState.PreviousButtons = data.PreviousButtons
	postState.JumpBufferTicksRemaining = data.JumpBufferTicksRemaining
	postState.JumpHullActive = data.JumpHullActive
	postState.StuckStepTicks = data.StuckStepTicks
end

local function copySupportInto(postSupport, data) -- 2 equivalent calls inferred from this helper
	postSupport.Kind = data.Kind
	postSupport.SourceId = data.SourceId
	postSupport.Anchor = data.Anchor
	postSupport.Velocity = data.Velocity
end

local function newSlot()
	return {
		Active = false,
		Command = {
			CommandNumber = 0,
			Move = Vector2.zero,
			LookYaw = 0,
			VerticalLook = 0,
			Buttons = 0,
			WeaponSelectRequestId = nil,
			WeaponSelectIdentifier = nil,
			GrenadeThrowIdentifier = nil,
			GrenadeThrowAnimation = nil,
			PredictedBaseMoveSpeed = nil,
			PredictedWeaponMoveSpeed = nil,
			PredictedWeaponScopedMoveSpeed = nil
		},
		ServerTick = 0,
		PostState = State.new(createVector(0, 0, 0)),
		PostSupport = State.noneSupport(),
		TopologyRevision = 0,
		DependencyMask = 0
	}
end

local function createSlots(predictionReplayTicks: number) -- 1 equivalent call inferred from this helper
	local result = table.create(predictionReplayTicks)

	for i = 1, predictionReplayTicks do
		result[i] = newSlot()
	end

	return result
end

local function validateSupport(data)
	if typeof(data) ~= "table" then
		return false, "SupportNotTable"
	end

	if
		type(data.Kind) ~= "number"
		or data.Kind % 1 ~= 0
		or data.Kind < Enums.SupportKind.None
		or data.Kind > Enums.SupportKind.Max
	then
		return false, "InvalidSupportKind"
	end

	if not Serial.isUInt32(data.SourceId) then
		return false, "InvalidSupportSourceId"
	end

	if (data.Kind == Enums.SupportKind.None) ~= (data.SourceId == 0) then
		return false, "InvalidEmptySupport"
	end

	if Quantization.isFiniteVector3(data.Anchor) and Quantization.isFiniteVector3(data.Velocity) then
		return true, nil
	end

	return false, "InvalidSupportVector"
end

local function validateStoredValues(serverTick: number, p, p2, topologyRevision: number, p3: number)
	if not Serial.isUInt32(serverTick) then
		return false, "InvalidServerTick"
	end

	if not Serial.isUInt32(topologyRevision) then
		return false, "InvalidTopologyRevision"
	end

	if not Serial.isUInt32(p3) or bit32.band(p3, (bit32.bnot(class.Dependency.ValidMask))) ~= 0 then
		return false, "InvalidPredictionDependencyMask"
	end

	local v, v2 = StateCodec.validate(p)

	if not v then
		return false, v2
	end

	local v3, v4 = validateSupport(p2)

	if v3 then
		return true, nil
	end

	return false, v4
end

local function writeSlot(slot, p, serverTick: number, p2, data, topologyRevision: number, dependencyMask: number) -- 1 equivalent call inferred from this helper
	local canonicalizeCommandInto, v = CommandCodec.canonicalizeCommandInto(slot.Command, p.CommandNumber, p)

	if canonicalizeCommandInto == nil then
		return false, v
	end

	copyStateInto(slot.PostState, p2)
	copySupportInto(slot.PostSupport, data) -- inferred equivalent call
	slot.ServerTick = serverTick
	slot.TopologyRevision = topologyRevision
	slot.DependencyMask = dependencyMask
	slot.Active = true
	return true, nil
end

function class.new(p)
	local v, v2 = Mapping.validate(p)
	assert(v, v2 or "invalid command mapping")
	local predictionReplayTicks = Config.derive(p.SimulationHz).PredictionReplayTicks
	local slots = table.create(predictionReplayTicks)
	local v3 = { _capacity = predictionReplayTicks, _slots = 0, _count = 0, _newestSlotIndex = 1 }

	for i = 1, predictionReplayTicks do
		slots[i] = newSlot()
	end

	v3._slots = slots
	return (setmetatable(v3, class))
end

function class:clear()
	for _, slot in self._slots do
		slot.Active = false
	end

	self._count = 0
	self._newestCommandNumber = nil
	self._newestSlotIndex = 1
end

function class:reset(p)
	local v, v2 = Mapping.validate(p)
	assert(v, v2 or "invalid command mapping")
	local predictionReplayTicks = Config.derive(p.SimulationHz).PredictionReplayTicks

	if predictionReplayTicks ~= self._capacity then
		self._capacity = predictionReplayTicks
		self._slots = createSlots(predictionReplayTicks) -- inferred equivalent call
	end

	self:clear()
end

function class:isFull()
	return self._count >= self._capacity
end

function class:count()
	return self._count
end

function class:capacity()
	return self._capacity
end

function class:newestCommandNumber()
	return self._newestCommandNumber
end

function class:get(p: number)
	if not Serial.isUInt32(p) then
		return nil
	end

	local slot = self._slots[slotIndex(self, p)] -- inferred equivalent call

	if slot.Active and slot.Command.CommandNumber == p then
		return slot
	end

	return nil
end

function class:anyEntryAtOrAfterServerTick(p: number, callback)
	if not Serial.isUInt32(p) then
		return false
	end

	for _, slot in self._slots do
		if slot.Active and Serial.deltaUInt32(slot.ServerTick, p) >= 0 and callback(slot) then
			return true
		end
	end

	return false
end

function class:push(p, serverTick: number, p2, p3, topologyRevision: number, flag: boolean?, value: number?)
	local v, v2 = CommandCodec.validateCommand(p.CommandNumber, p)

	if not v then
		return false, v2
	end

	local dependencyMask = value or 0
	local v3, v4 = validateStoredValues(serverTick, p2, p3, topologyRevision, dependencyMask)

	if not v3 then
		return false, v4
	end

	local newestCommandNumber = self._newestCommandNumber

	if newestCommandNumber ~= nil then
		local deltaUInt32 = Serial.deltaUInt32(p.CommandNumber, newestCommandNumber)

		if deltaUInt32 < 0 then
			return false, "CommandOlderThanTail"
		end

		if deltaUInt32 > 1 then
			return false, "NonSequentialCommand"
		end
	end

	local newestSlotIndex = slotIndex(self, p.CommandNumber) -- inferred equivalent call
	local slot = self._slots[newestSlotIndex]

	if
		slot.Active
		and slot.Command.CommandNumber ~= p.CommandNumber
		and (flag ~= true or Serial.deltaUInt32(p.CommandNumber, slot.Command.CommandNumber) ~= self._capacity)
	then
		return false, "PredictionHistoryOverflow"
	end

	if not slot.Active then
		self._count += 1
	end

	local v5, v6 = writeSlot(slot, p, serverTick, p2, p3, topologyRevision, dependencyMask) -- inferred equivalent call

	if not v5 then
		return false, v6
	end

	if newestCommandNumber == nil or Serial.isNewerUInt32(p.CommandNumber, newestCommandNumber) then
		self._newestCommandNumber = p.CommandNumber
		self._newestSlotIndex = newestSlotIndex
	end

	return true, nil
end

function class:replacePrediction(p: number, serverTick: number, p2, data, topologyRevision: number, p3: number?)
	if not Serial.isUInt32(p) then
		return false, "InvalidCommandNumber"
	end

	local slot = self._slots[slotIndex(self, p)] -- inferred equivalent call

	if not slot.Active or slot.Command.CommandNumber ~= p then
		return false, "CommandNotBuffered"
	end

	local dependencyMask = p3 or slot.DependencyMask
	local v, v2 = validateStoredValues(serverTick, p2, data, topologyRevision, dependencyMask)

	if not v then
		return false, v2
	end

	copyStateInto(slot.PostState, p2)
	copySupportInto(slot.PostSupport, data) -- inferred equivalent call
	slot.ServerTick = serverTick
	slot.TopologyRevision = topologyRevision
	slot.DependencyMask = dependencyMask
	return true, nil
end

function class:entriesAfter(p: number, options)
	local result = options or {}
	table.clear(result)

	if not Serial.isUInt32(p) then
		return result
	end

	local newestCommandNumber = self._newestCommandNumber

	if newestCommandNumber == nil then
		return result
	end

	for i = 1, math.min(math.max(Serial.deltaUInt32(newestCommandNumber, p), 0), self._capacity) do
		local v = self:get(Serial.addUInt32(p, i))

		if v == nil then
			break
		else
			result[#result + 1] = v
		end
	end

	return result
end

function class.cloneEntry(data)
	local canonicalizeCommand, v = CommandCodec.canonicalizeCommand(data.Command.CommandNumber, data.Command)
	assert(canonicalizeCommand ~= nil, v or "prediction entry command became invalid")
	return {
		Command = canonicalizeCommand,
		ServerTick = data.ServerTick,
		PostState = State.clone(data.PostState),
		PostSupport = State.cloneSupport(data.PostSupport),
		TopologyRevision = data.TopologyRevision,
		DependencyMask = data.DependencyMask
	}
end

function class:shiftServerTicksAfter(p: number, value: number)
	if not Serial.isUInt32(p) or type(value) ~= "number" or value % 1 ~= 0 then
		return false, "InvalidPredictionTickShift"
	end

	if math.abs(value) > self._capacity then
		return false, "PredictionTickShiftTooLarge"
	end

	local newestCommandNumber = self._newestCommandNumber

	if newestCommandNumber == nil then
		return true, nil
	end

	for i = 1, math.min(math.max(Serial.deltaUInt32(newestCommandNumber, p), 0), self._capacity) do
		local v = self:get(Serial.addUInt32(p, i))

		if v == nil then
			return false, "PredictionHistoryGap"
		else
			v.ServerTick = Serial.addUInt32(v.ServerTick, value)
		end
	end

	return true, nil
end

function class:dropThrough(p: number)
	if not Serial.isUInt32(p) then
		return 0
	end

	local count = 0

	for _, slot in self._slots do
		if not (slot.Active and Serial.deltaUInt32(slot.Command.CommandNumber, p) <= 0) then
			continue
		end

		slot.Active = false
		self._count -= 1
		count += 1
	end

	if self._count == 0 then
		self._newestCommandNumber = nil
	end

	return count
end

return table.freeze(class)