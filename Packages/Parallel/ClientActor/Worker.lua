local actor = script:GetActor()
local Runnable = require(script.Parent.Runnable)
local Event = script.Parent.Parent.Event
local v = false
local v2 = {}
actor:BindToMessageParallel("Parallel:Run", function(...)
	assert(Runnable, "Parallel not initialized")
	assert(not v, "Parallel destroyed")
	Runnable(...)
end)
actor:BindToMessage("Parallel:SubmitTask", function(p: string, ...)
	assert(Runnable, "Parallel not initialized")
	assert(not v, "Parallel destroyed")
	local v3 = { ... }

	if v2[p] ~= nil then
		task.cancel(v2[p])
		v2[p] = nil
	end

	v2[p] = task.spawn(function()
		task.desynchronize()
		Event:Fire(p, Runnable(table.unpack(v3)))
		v2[p] = nil
	end)
end)
actor:BindToMessage("Parallel:CancelTask", function(p: string)
	assert(Runnable, "Parallel not initialized")
	assert(not v, "Parallel destroyed")

	if v2[p] ~= nil then
		task.cancel(v2[p])
		v2[p] = nil
	end
end)
actor:BindToMessage("Parallel:Destroy", function()
	assert(Runnable, "Parallel not initialized")
	assert(not v, "Parallel destroyed")
	v = true

	for _, v3 in v2 do
		task.cancel(v3)
	end

	v2 = {}
	Runnable = nil
	Event = nil
end)
script.Parent:SetAttribute("Initialized", true)