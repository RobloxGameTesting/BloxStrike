local Profiler = {}
local object = setmetatable({}, { __mode = "k" })
local v = 1e999
local v2 = nil
local v3 = 1e999
local v4 = nil
local v5 = false

function Profiler.mark(p: string)
	debug.profilebegin(p)
	debug.profileend()
end

local function returnProtectedResults(flag: boolean, ...)
	if not flag then
		error(select(1, ...), 3)
	end

	return ...
end

function Profiler.scope(p: string, callback, ...)
	Profiler.mark(p)
	return returnProtectedResults(pcall(callback, ...))
end

function Profiler.setSlowScopeReporter(p: number, callback)
	v = math.max(0, p)
	v2 = callback
end

function Profiler.setTimedScopeObserver(p: number, callback)
	v3 = math.max(0, p)
	v4 = callback
	v5 = false
end

function Profiler.timedScope(p: string, callback, ...)
	if v4 == nil and v2 == nil then
		return Profiler.scope(p, callback, ...)
	end

	local now = os.clock()
	local v6 = table.pack(Profiler.scope(p, callback, ...))
	local now2 = os.clock()
	local v7 = now2 - now
	local v8 = v4

	if v8 ~= nil and v3 <= v7 then
		local success, result = pcall(v8, p, v7, now, now2)

		if not (success or v5) then
			v5 = true
			warn(`[Profiler] timed-scope observer failed: {tostring(result)}`)
		end
	end

	local v9 = v2

	if v9 ~= nil and v <= v7 then
		task.defer(function()
			local success, result = pcall(v9, p, v7)

			if not success then
				warn(`[Profiler] slow-scope reporter failed: {tostring(result)}`)
			end
		end)
	end

	return table.unpack(v6, 1, v6.n)
end

function Profiler.wrapTimed(p: string, callback)
	return function(...)
		return Profiler.timedScope(p, callback, ...)
	end
end

function Profiler.getInstancePath(parent, p)
	local v6 = {}

	while parent and parent ~= p do
		table.insert(v6, 1, parent.Name)
		parent = parent.Parent
	end

	return table.concat(v6, ".")
end

function Profiler.getCallbackLabel(p: string, callback)
	local values = object[callback]

	if not values then
		values = {}
		object[callback] = values
	end

	local v6 = values[p]

	if v6 then
		return v6
	end

	local v7 = debug.info(callback, "s")
	local formatted = `{p}.{(not v7 or v7 == "") and "Unknown" or string.gsub(v7, "^@", "")}`
	values[p] = formatted
	return formatted
end

function Profiler.defer(p: string, callback, ...)
	local v6 = table.pack(...)
	task.defer(function()
		debug.setmemorycategory(p)
		Profiler.mark(p)
		callback(table.unpack(v6, 1, v6.n))
	end)
end

function Profiler.spawn(p: string, callback, ...)
	local v6 = table.pack(...)
	task.spawn(function()
		debug.setmemorycategory(p)
		Profiler.mark(p)
		callback(table.unpack(v6, 1, v6.n))
	end)
end

return Profiler