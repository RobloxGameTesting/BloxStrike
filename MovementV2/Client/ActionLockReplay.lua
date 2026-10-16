local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.RuntimeTypes)
return table.freeze({
	queue = function(object, p)
		local mapping = object._mapping

		if mapping == nil or mapping.Generation ~= p.Generation then
			if object._retiredGeneration ~= p.Generation then
				object:_sendMappingRequest(p.Generation)
			end
		else
			local actionLocks = object._actionLocks

			if actionLocks ~= nil and Serial.deltaUInt32(p.History.Revision, actionLocks.Revision) <= 0 then
				return
			end

			object._actionLocks = p.History
			local pendingReconciliationInstall = object._pendingReconciliationInstall
			local reconciler = object._reconciler

			if pendingReconciliationInstall ~= nil and reconciler ~= nil then
				object._pendingActionLockReplay = not reconciler:invalidatePendingReplayFromTick(Serial.addUInt32(
					pendingReconciliationInstall.Snapshot.ServerTick,
					1
				))
			elseif object._state ~= nil then
				object._pendingActionLockReplay = true
			end
		end
	end,
	flush = function(object)
		if not object._pendingActionLockReplay or object._pendingReconciliationInstall ~= nil then
			return false
		end

		local mapping = object._mapping
		local lastAcceptedOwnerSnapshot = object._lastAcceptedOwnerSnapshot

		if mapping == nil or lastAcceptedOwnerSnapshot == nil or object._state == nil then
			return false
		end

		object._pendingActionLockReplay = false
		local pendingOwnerSnapshot = object._pendingOwnerSnapshot

		if pendingOwnerSnapshot ~= nil then
			object._pendingOwnerSnapshot = nil

			if
				object:_handleOwnerSnapshot(pendingOwnerSnapshot, true)
				or object._pendingReconciliationInstall ~= nil
			then
				return true
			end
		end

		local v, v2 = object:_installSnapshot(lastAcceptedOwnerSnapshot, false, true, true)

		if v or v2 == "ReplayPending" then
			return true
		end

		object:_setStatus("WaitingForAuthority", "ActionLockChangedInsidePrediction")
		object:_sendMappingRequest(mapping.Generation)
		object:_warn(`could not replay action lock: {v2}`)
		return false
	end
})