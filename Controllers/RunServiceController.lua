local RunServiceController = {}
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local v = {}
local count = 0
local count2 = 0

local function newScheduler(eventName: string)
	return {
		EventName = eventName,
		ProfileLabel = `RunServiceController.{eventName}`,
		Bindings = {},
		BindingsByName = {},
		StepBindings = {},
		RenderPriorityBindings = {},
		Connection = nil,
		RenderStepNames = {},
		NeedsCompact = false,
		NeedsSort = false,
		Stepping = false
	}
end

local v2 = {
	Heartbeat = newScheduler("Heartbeat"),
	RenderStepped = newScheduler("RenderStepped"),
	Stepped = newScheduler("Stepped"),
	PostSimulation = newScheduler("PostSimulation")
}

local function getTraceback(p)
	return debug.traceback(tostring(p), 2)
end

local function isDynamicNameSegment(value: string) -- 1 equivalent call inferred from this helper
	if tonumber(value) == nil and string.find(value, "-", 1, true) == nil then
		if #value >= 8 then
			return string.find(value, "%d") ~= nil
		else
			return false
		end
	else
		return true
	end
end

local function getBindingProfileLabel(p: string, value: string)
	local v3 = table.create(8)

	for _, v4 in ipairs(string.split(value, ".")) do
		table.insert(v3, isDynamicNameSegment(v4) and "#" or v4) -- inferred equivalent call
	end

	return `RunService.{p}.{table.concat(v3, ".")}`
end

local function syncSchedulerConnections(state)
	if #state.StepBindings == 0 and state.Connection then
		state.Connection:Disconnect()
		state.Connection = nil
	end

	for k, renderStepName in pairs(state.RenderStepNames) do
		local renderPriorityBinding = state.RenderPriorityBindings[k]

		if not (not renderPriorityBinding or #renderPriorityBinding == 0) then
			continue
		end

		RunService:UnbindFromRenderStep(renderStepName)
		state.RenderStepNames[k] = nil
	end
end

local function rebuildScheduler(state)
	local v3 = 1

	for i = 1, #state.Bindings do
		local binding = state.Bindings[i]

		if not binding.Connected then
			continue
		end

		state.Bindings[v3] = binding
		v3 += 1
	end

	for i = v3, #state.Bindings do
		state.Bindings[i] = nil
	end

	table.sort(state.Bindings, function(a, b)
		if a.Priority == b.Priority then
			return a.Sequence < b.Sequence
		end

		return a.Priority < b.Priority
	end)
	table.clear(state.StepBindings)
	table.clear(state.RenderPriorityBindings)

	for _, binding in ipairs(state.Bindings) do
		if binding.UsesRenderPriority then
			local bindings = state.RenderPriorityBindings[binding.Priority]

			if not bindings then
				bindings = {}
				state.RenderPriorityBindings[binding.Priority] = bindings
			end

			table.insert(bindings, binding)
		else
			table.insert(state.StepBindings, binding)
		end
	end

	state.NeedsCompact = false
	state.NeedsSort = false
	syncSchedulerConnections(state)
end

local count3 = 0

local function invokeBinding(stepBinding, ...)
	debug.profilebegin(stepBinding.ProfileLabel)
	local v3 = count3
	local success, result = xpcall(stepBinding.Callback, getTraceback, ...)

	if v3 == count3 then
		debug.profileend()
	end

	if not success then
		warn(`[RunServiceController] {stepBinding.EventName} binding "{stepBinding.Name}" failed:\n{result}`)
	end
end

local function stepScheduler(state, p: number?, ...)
	count3 += 1
	Profiler.mark(state.ProfileLabel)

	if state.NeedsCompact or state.NeedsSort then
		rebuildScheduler(state)
	end

	state.Stepping = true
	local stepBindings

	if p == nil then
		stepBindings = state.StepBindings
	else
		stepBindings = state.RenderPriorityBindings[p] or v
	end

	for i = 1, #stepBindings do
		local stepBinding = stepBindings[i]

		if stepBinding and stepBinding.Connected then
			invokeBinding(stepBinding, ...)
		end
	end

	state.Stepping = false

	if state.NeedsCompact or state.NeedsSort then
		rebuildScheduler(state)
	end
end

local function ensureSchedulerConnection(state, value: number, flag: boolean)
	if flag then
		if state.RenderStepNames[value] then
			return
		end

		local formatted = `RunServiceController.RenderStepped.{value}`
		state.RenderStepNames[value] = formatted
		RunService:BindToRenderStep(formatted, value, function(p: number)
			stepScheduler(state, value, p)
		end)
	elseif not (state.Connection and state.Connection.Connected) then
		state.Connection = RunService[state.EventName]:Connect(function(...)
			stepScheduler(state, nil, ...)
		end)
	end
end

local function disconnectBinding(state, state2) -- 2 equivalent calls inferred from this helper
	if not state2.Connected then
		return
	end

	state2.Connected = false

	if state.BindingsByName[state2.Name] == state2 then
		state.BindingsByName[state2.Name] = nil
	end

	state.NeedsCompact = true

	if not state.Stepping then
		rebuildScheduler(state)
	end
end

local function createBinding(eventName: string, name: string, value: number, callback, usesRenderPriority: boolean)
	local v3 = type(name) == "string" and name ~= ""
	assert(v3, "RunServiceController binding name must be a non-empty string")
	assert(type(value) == "number", "RunServiceController binding priority must be a number")
	assert(type(callback) == "function", "RunServiceController callback must be a function")
	local v4 = v2[eventName]
	local v5 = v4.BindingsByName[name]

	if v5 and v5.Connected then
		v5.Connected = false

		if v4.BindingsByName[v5.Name] == v5 then
			v4.BindingsByName[v5.Name] = nil
		end

		v4.NeedsCompact = true

		if not v4.Stepping then
			rebuildScheduler(v4)
		end
	end

	count += 1
	local v6 = {
		Name = name,
		EventName = eventName,
		Priority = value,
		Connected = true,
		Callback = callback,
		ProfileLabel = getBindingProfileLabel(eventName, name),
		Sequence = count,
		UsesRenderPriority = usesRenderPriority
	}

	function v6:Disconnect()
		disconnectBinding(v4, v6) -- inferred equivalent call
	end

	v6.Destroy = v6.Disconnect
	table.insert(v4.Bindings, v6)
	v4.BindingsByName[name] = v6
	v4.NeedsSort = true
	ensureSchedulerConnection(v4, value, usesRenderPriority)
	return v6
end

function RunServiceController.CreateBindingName(value: string)
	local v3 = type(value) == "string" and value ~= ""
	assert(v3, "RunServiceController binding prefix must be a non-empty string")
	count2 += 1
	return `{value}.{count2}`
end

function RunServiceController.BindToHeartbeat(name: string, callback, value: number?)
	return (createBinding("Heartbeat", name, value or 0, callback, false))
end

function RunServiceController:BindToRenderStep(p, callback)
	if callback == nil then
		return (createBinding("RenderStepped", self, 0, p, false))
	end

	return (createBinding("RenderStepped", self, p, callback, true))
end

function RunServiceController.BindToRenderSteppedEvent(name: string, callback, value: number?)
	return (createBinding("RenderStepped", name, value or 0, callback, false))
end

function RunServiceController.BindToStepped(name: string, callback, value: number?)
	return (createBinding("Stepped", name, value or 0, callback, false))
end

function RunServiceController.BindToPostSimulation(name: string, callback, value: number?)
	return (createBinding("PostSimulation", name, value or 0, callback, false))
end

function RunServiceController.Unbind(p: string, p2: string)
	local v3 = v2[p].BindingsByName[p2]

	if v3 then
		disconnectBinding(v2[p], v3) -- inferred equivalent call
	end
end

function RunServiceController:UnbindFromRenderStep()
	RunServiceController.Unbind("RenderStepped", self)
end

return RunServiceController