local Serial = require(script.Parent.Parent.Serial)
require(script.Parent.Parent.Types)
local OwnerRecovery = require(script.Parent.OwnerRecovery)
require(script.Parent.Reconciler)
require(script.Parent.RuntimeTypes)
local WorldReplay = require(script.Parent.WorldReplay)

local function markOwnerFailed(p, pendingReconciliationInstall, p2) -- 2 equivalent calls inferred from this helper
	pendingReconciliationInstall.FailedOwnerSequence = p2.Sequence
	pendingReconciliationInstall.FailedOwnerControls = WorldReplay.controlVersion(p)
end

local function restoreOriginalJob(object, reconciler, pendingReconciliationInstall, pendingOwnerSnapshot, pendingCommandResyncThrough: number?, commandResyncRequestedAt: number, lastResyncOwnerSnapshot) -- 2 equivalent calls inferred from this helper
	object._reconciler = reconciler
	object._pendingReconciliationInstall = pendingReconciliationInstall
	object._pendingCommandResyncThrough = pendingCommandResyncThrough
	object._commandResyncRequestedAt = commandResyncRequestedAt
	object._lastResyncOwnerSnapshot = lastResyncOwnerSnapshot
	markOwnerFailed(object, pendingReconciliationInstall, pendingOwnerSnapshot) -- inferred equivalent call
end

return table.freeze({
	invalidateWorld = function(self)
		if self._reconciler ~= nil then
			self._reconciler:discardReplayContinuation()
		end
	end,
	invalidateWorldFromTick = function(self, p: number, p2: number)
		if self._reconciler ~= nil then
			self._reconciler:invalidateWorldReplayFromTick(p, p2)
		end
	end,
	checkWorld = function(self, p, p2: number?)
		local retainedReplayAnchor = assert(self._reconciler):retainedReplayAnchor(p, p2)
		local serverTick

		if retainedReplayAnchor == nil then
			serverTick = p.ServerTick
		else
			serverTick = retainedReplayAnchor.ServerTick
		end

		local destructibleRevision

		if retainedReplayAnchor == nil then
			destructibleRevision = p.Topology.DestructibleRevision
		else
			destructibleRevision = retainedReplayAnchor.TopologyRevision
		end

		local v, v2 = assert(self._timeline):peek(serverTick, destructibleRevision)

		if v == nil then
			return v2
		end

		local collisionComposer = self._collisionComposer
		local moverRevision

		if retainedReplayAnchor == nil then
			moverRevision = p.Topology.MoverRevision
		end

		local v3

		if not (collisionComposer == nil or type(collisionComposer.ValidationView) ~= "function") then
			v3 = collisionComposer:ValidationView()
		end

		local _, v4 = self:_composeWorld(serverTick, destructibleRevision, moverRevision, nil, nil, nil, v3)
		return v4
	end,
	tryAdvance = function(self)
		local pendingReconciliationInstall = self._pendingReconciliationInstall
		local pendingOwnerSnapshot = self._pendingOwnerSnapshot
		local pendingDiscontinuity = self._pendingDiscontinuity

		if
			pendingDiscontinuity ~= nil
			and (pendingOwnerSnapshot == nil or Serial.isNewerUInt32(
				pendingDiscontinuity.Sequence,
				pendingOwnerSnapshot.Sequence
			))
		then
			pendingOwnerSnapshot = pendingDiscontinuity
		end

		local reconciler = self._reconciler
		local config = self._config
		local mapping = self._mapping
		local commandStream = self._commandStream

		if
			pendingReconciliationInstall == nil
			or pendingOwnerSnapshot == nil
			or reconciler == nil
			or config == nil
			or mapping == nil
			or commandStream == nil
			or pendingReconciliationInstall.FailedOwnerSequence == pendingOwnerSnapshot.Sequence
			and WorldReplay.controlsUnchanged(self, pendingReconciliationInstall.FailedOwnerControls)
		then
			return false
		end

		if
			commandStream:lastSampledCommandNumber() == nil
			or OwnerRecovery.retirementCutoff(
				commandStream,
				self._predictionRing,
				config,
				pendingOwnerSnapshot.LastProcessedCommand
			) ~= nil
		then
			return false
		end

		if mapping.PlayerCollisionsEnabled then
			local latestCompleteServerTick = assert(self._remoteBuffer):latestCompleteServerTick()

			if
				latestCompleteServerTick == nil
				or Serial.deltaUInt32(latestCompleteServerTick, pendingOwnerSnapshot.ServerTick) < 0
			then
				return false
			end
		end

		local forkForNewerOwner = reconciler:forkForNewerOwner(pendingOwnerSnapshot)

		if forkForNewerOwner == nil then
			return false
		end

		local v, v2 = WorldReplay.prepare(self)

		if v2 == nil then
			local pendingCommandResyncThrough = self._pendingCommandResyncThrough
			local commandResyncRequestedAt = self._commandResyncRequestedAt
			local lastResyncOwnerSnapshot = self._lastResyncOwnerSnapshot
			self._reconciler = forkForNewerOwner
			self._pendingReconciliationInstall = nil

			if v ~= nil then
				v:bind()
			end

			local success, result, v3 = pcall(function()
				return self:_installSnapshot(pendingOwnerSnapshot, false, nil, true, v ~= nil and function()
					v:commit()
				end or nil)
			end)

			if v ~= nil then
				v:destroy()
			end

			if not success then
				if forkForNewerOwner:lastAcceptedSequence() ~= pendingOwnerSnapshot.Sequence then
					restoreOriginalJob( -- inferred equivalent call
						self,
						reconciler,
						pendingReconciliationInstall,
						pendingOwnerSnapshot,
						pendingCommandResyncThrough,
						commandResyncRequestedAt,
						lastResyncOwnerSnapshot
					)
				end

				error(result, 0)
			end

			if result or v3 == "ReplayPending" then
				self._pendingOwnerSnapshot = nil
				local moverRevisionToValidate = pendingReconciliationInstall.MoverRevisionToValidate
				local moverRevisionToValidate2 = v and v.MoverRevisionToValidate

				if
					moverRevisionToValidate2 ~= nil
					and (moverRevisionToValidate == nil or Serial.deltaUInt32(
						moverRevisionToValidate2,
						moverRevisionToValidate
					) > 0)
				then
					moverRevisionToValidate = moverRevisionToValidate2
				end

				local _pendingReconciliationInstall = self._pendingReconciliationInstall

				if _pendingReconciliationInstall == nil then
					if moverRevisionToValidate ~= nil then
						self:_markMoverRevisionValidated(moverRevisionToValidate)
					end
				else
					_pendingReconciliationInstall.MoverRevisionToValidate = moverRevisionToValidate
				end

				local _pendingDiscontinuity = self._pendingDiscontinuity

				if
					_pendingDiscontinuity == nil
					or _pendingDiscontinuity.Generation ~= pendingOwnerSnapshot.Generation
					or Serial.isNewerUInt32(_pendingDiscontinuity.Sequence, pendingOwnerSnapshot.Sequence)
				then
					return true, result, v3
				end

				local pendingDiscontinuity3

				if not result then
					pendingDiscontinuity3 = pendingOwnerSnapshot
				end

				self._pendingDiscontinuity = pendingDiscontinuity3
				return true, result, v3
			else
				restoreOriginalJob( -- inferred equivalent call
					self,
					reconciler,
					pendingReconciliationInstall,
					pendingOwnerSnapshot,
					pendingCommandResyncThrough,
					commandResyncRequestedAt,
					lastResyncOwnerSnapshot
				)
				return false
			end
		else
			markOwnerFailed(self, pendingReconciliationInstall, pendingOwnerSnapshot) -- inferred equivalent call
			return false
		end
	end
})