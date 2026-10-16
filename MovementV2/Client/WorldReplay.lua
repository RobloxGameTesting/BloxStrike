require(script.Parent.RuntimeTypes)
require(script.Parent.DestructibleTimeline)
local v = {}
local class = {}
class.__index = class

function v:controlVersion()
	return {
		Baseline = self._pendingBaseline,
		Delta = self._pendingDeltas[#self._pendingDeltas],
		MoverBaseline = self._pendingMoverBaseline,
		MoverDelta = self._pendingMoverDeltas[#self._pendingMoverDeltas]
	}
end

function v:controlsUnchanged(data)
	return data ~= nil
		and data.Baseline == self._pendingBaseline
		and data.Delta == self._pendingDeltas[#self._pendingDeltas]
		and data.MoverBaseline == self._pendingMoverBaseline
		and data.MoverDelta == self._pendingMoverDeltas[#self._pendingMoverDeltas]
end

local function consume(object, liveTimeline, liveComposer)
	local baseline = object.Baseline

	if baseline ~= nil then
		local v2, v3 = liveTimeline:consumeBaseline(baseline.ServerTick, baseline.Frame)

		if not v2 then
			return false, v3
		end
	end

	for _, delta in object.Deltas do
		local v2, v3 = liveTimeline:consumeDelta(delta.Epoch, delta.Revision, delta.ServerTick, delta.Indices)

		if not v2 then
			return false, v3
		end
	end

	local moverBaseline = object.MoverBaseline

	if moverBaseline ~= nil then
		if moverBaseline.Epoch ~= object.Epoch then
			return false, "MoverEpochMismatch"
		end

		local v2, v3 = liveComposer:ConsumeBaseline(
			moverBaseline.Epoch,
			moverBaseline.Revision,
			moverBaseline.ServerTick,
			moverBaseline.Descriptors,
			moverBaseline.ProgressAnchors
		)

		if not v2 then
			return false, v3
		end
	end

	for _, moverDelta in object.MoverDeltas do
		if moverDelta.Epoch ~= object.Epoch then
			return false, "MoverEpochMismatch"
		end

		local selected

		if moverDelta.Kind == "MoverProgress" then
			local v2
			v2, selected = liveComposer:ConsumeProgress(
				moverDelta.Epoch,
				moverDelta.Revision,
				moverDelta.ServerTick,
				moverDelta.Streams
			)
		else
			local v2
			v2, selected = liveComposer:ConsumeDelta(
				moverDelta.Epoch,
				moverDelta.Revision,
				moverDelta.ServerTick,
				moverDelta.Descriptors
			)
		end

		if selected ~= nil then
			return false, selected
		end
	end

	return true
end

function class.bind(data)
	data.Runtime:_bindCollisionSources(data.Timeline, data.Composer)
end

function class:restore()
	self.Runtime:_bindCollisionSources(self.LiveTimeline, self.LiveComposer)
end

function class:destroy()
	self:restore()
	self.Timeline:destroy()

	if self.Composer ~= nil then
		self.Composer:Destroy()
	end
end

function class:commit()
	local runtime = self.Runtime
	assert(v.controlsUnchanged(runtime, self.Version), "queued controls changed during owner staging")
	self:restore()
	local v2, v3 = consume(self, self.LiveTimeline, self.LiveComposer)
	assert(v2, v3)
	runtime._pendingBaseline = nil
	runtime._pendingMoverBaseline = nil
	runtime._pendingDeltas = {}
	runtime._pendingMoverDeltas = {}
	local pendingReconciliationInstall = runtime._pendingReconciliationInstall
	local composer = self.Composer

	if composer ~= nil then
		self.MoverRevisionToValidate = composer:Revision()

		if pendingReconciliationInstall == nil or pendingReconciliationInstall.CollisionComposer == nil then
			if pendingReconciliationInstall == nil then
				self.LiveComposer:CommitPrediction(composer)
			end
		else
			self.LiveComposer:AdoptReplay(pendingReconciliationInstall.CollisionComposer, composer)
		end
	end
end

function v:prepare()
	if
		self._pendingBaseline == nil
		and #self._pendingDeltas == 0
		and self._pendingMoverBaseline == nil
		and #self._pendingMoverDeltas == 0
	then
		return nil, nil
	end

	local collisionComposer = self._collisionComposer
	local v2 = self._pendingMoverBaseline ~= nil or #self._pendingMoverDeltas > 0

	if
		collisionComposer == nil and v2
		or collisionComposer ~= nil and type(collisionComposer.ForkControls) ~= "function"
	then
		return nil, "MoverControlForkUnavailable"
	end

	local liveTimeline = assert(self._timeline)
	local v3 = {
		Runtime = self,
		Epoch = assert(self._mapping).TopologyEpoch,
		Version = v.controlVersion(self),
		Baseline = self._pendingBaseline,
		Deltas = table.clone(self._pendingDeltas),
		MoverBaseline = self._pendingMoverBaseline,
		MoverDeltas = table.clone(self._pendingMoverDeltas),
		LiveTimeline = liveTimeline,
		Timeline = liveTimeline:fork(),
		LiveComposer = collisionComposer,
		Composer = 0
	}
	local composer

	if collisionComposer ~= nil then
		composer = collisionComposer:ForkControls()
	end

	v3.Composer = composer
	local object = setmetatable(v3, class)
	local success, result, v4 = pcall(consume, object, object.Timeline, object.Composer)

	if success and result then
		return object, nil
	end

	object:destroy()

	if not success then
		error(result, 0)
	end

	return nil, v4
end

return table.freeze(v)