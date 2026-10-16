local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.RuntimeTypes)
return table.freeze({
	flush = function(object)
		local pendingDamageTagReplayMovementTick = object._pendingDamageTagReplayMovementTick

		if pendingDamageTagReplayMovementTick == nil or object._pendingReconciliationInstall ~= nil then
			return false
		end

		local mapping = object._mapping
		local lastAcceptedOwnerSnapshot = object._lastAcceptedOwnerSnapshot
		local movementTick

		if object._state ~= nil then
			movementTick = object._state.MovementTick
		end

		if mapping == nil or lastAcceptedOwnerSnapshot == nil or movementTick == nil then
			return false
		end

		if Serial.deltaUInt32(lastAcceptedOwnerSnapshot.State.MovementTick, pendingDamageTagReplayMovementTick) >= 0 then
			object:_pruneDamageTagsThrough(lastAcceptedOwnerSnapshot.State.MovementTick)
			return false
		end

		if Serial.deltaUInt32(movementTick, pendingDamageTagReplayMovementTick) < 0 then
			object._pendingDamageTagReplayMovementTick = nil
			return false
		end

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

		object._pendingDamageTagReplayMovementTick = nil
		local v, v2 = object:_installSnapshot(
			lastAcceptedOwnerSnapshot,
			false,
			true,
			nil,
			nil,
			(Serial.addUInt32(
				lastAcceptedOwnerSnapshot.ServerTick,
				Serial.deltaUInt32(pendingDamageTagReplayMovementTick, lastAcceptedOwnerSnapshot.State.MovementTick)
			))
		)

		if v or v2 == "ReplayPending" then
			return true
		end

		object:_setStatus("WaitingForAuthority", "DamageTagChangedInsidePrediction")
		object:_sendMappingRequest(mapping.Generation)
		object:_warn(`could not replay late damage tag: {v2}`)
		return false
	end
})