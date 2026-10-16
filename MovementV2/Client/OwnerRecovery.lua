local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
require(script.Parent.CommandStream)
require(script.Parent.PredictionRing)
require(script.Parent.RuntimeTypes)
local v = {}

local function orderedAfter(lastResyncOwnerSnapshot, data, flag: boolean)
	if data == nil then
		return nil
	end

	if lastResyncOwnerSnapshot.Sequence == data.Sequence then
		if not flag then
			return "SnapshotNotNewer"
		end

		if
			lastResyncOwnerSnapshot.ServerTick ~= data.ServerTick
			or lastResyncOwnerSnapshot.LastProcessedCommand ~= data.LastProcessedCommand
			or lastResyncOwnerSnapshot.Topology.DestructibleRevision ~= data.Topology.DestructibleRevision
			or lastResyncOwnerSnapshot.Topology.MoverRevision ~= data.Topology.MoverRevision
		then
			return "RecoverySnapshotIdentityMismatch"
		end
	elseif not Serial.isNewerUInt32(lastResyncOwnerSnapshot.Sequence, data.Sequence) then
		return "SnapshotNotNewer"
	end

	if Serial.deltaUInt32(lastResyncOwnerSnapshot.ServerTick, data.ServerTick) < 0 then
		return "ServerTickRegressed"
	end

	if Serial.deltaUInt32(lastResyncOwnerSnapshot.LastProcessedCommand, data.LastProcessedCommand) < 0 then
		return "AcknowledgementRegressed"
	end

	if Serial.deltaUInt32(lastResyncOwnerSnapshot.Topology.DestructibleRevision, data.Topology.DestructibleRevision) < 0 then
		return "TopologyRevisionRegressed"
	end

	if Serial.deltaUInt32(lastResyncOwnerSnapshot.Topology.MoverRevision, data.Topology.MoverRevision) < 0 then
		return "MoverRevisionRegressed"
	end

	return nil
end

function v.retirementCutoff(object, object2, data, p: number)
	local v2

	if object ~= nil then
		v2 = object:lastSampledCommandNumber()
	end

	if v2 == nil or data == nil then
		return nil
	end

	local deltaUInt32 = Serial.deltaUInt32(v2, p)

	if deltaUInt32 < data.CommandLeadResyncTicks then
		return nil
	end

	local v3 = Serial.addUInt32(p, 1)

	if
		deltaUInt32 < math.min(data.CommandHistoryTicks, data.PredictionReplayTicks, data.MaxPendingCommandLeadTicks)
		and object:getCommand(v3) ~= nil
		and object2 ~= nil
		and object2:get(v3) ~= nil
	then
		return nil
	end

	return Serial.addUInt32(p, (math.min(deltaUInt32, data.MaxPendingCommandLeadTicks)))
end

function v:prepare(lastResyncOwnerSnapshot)
	local selected = orderedAfter(lastResyncOwnerSnapshot, self._lastAcceptedOwnerSnapshot, false)
		or orderedAfter(lastResyncOwnerSnapshot, self._lastResyncOwnerSnapshot, true)

	if selected ~= nil then
		return false, selected
	end

	local pendingCommandResyncThrough = self._pendingCommandResyncThrough

	if pendingCommandResyncThrough ~= nil then
		if Serial.deltaUInt32(lastResyncOwnerSnapshot.LastProcessedCommand, pendingCommandResyncThrough) < 0 then
			return false, "CommandLeadResync"
		end

		self._pendingCommandResyncThrough = nil
		self._commandResyncRequestedAt = 0
		self._lastResyncOwnerSnapshot = lastResyncOwnerSnapshot
	end

	local retirementCutoff = v.retirementCutoff(
		self._commandStream,
		self._predictionRing,
		self._config,
		lastResyncOwnerSnapshot.LastProcessedCommand
	)

	if retirementCutoff == nil then
		return true, nil
	end

	self._lastResyncOwnerSnapshot = lastResyncOwnerSnapshot
	self:_sendCommandResyncRequest(retirementCutoff)
	return false, "CommandLeadResync"
end

function v:observe(data)
	local mapping = self._mapping
	local pendingCommandResyncThrough = self._pendingCommandResyncThrough

	if
		self._pendingReconciliationInstall == nil
		or pendingCommandResyncThrough == nil
		or mapping == nil
		or data.Generation ~= mapping.Generation
		or data.Topology.Epoch ~= mapping.TopologyEpoch
		or data.Topology.Fingerprint ~= mapping.TopologyFingerprint
		or Serial.deltaUInt32(data.LastProcessedCommand, pendingCommandResyncThrough) < 0
	then
		return
	end

	local v2 = self._commandStream and self._commandStream:lastSampledCommandNumber()

	if v2 == nil or Serial.deltaUInt32(data.LastProcessedCommand, v2) > 0 then
		return
	end

	v.prepare(self, data)
end

return table.freeze(v)