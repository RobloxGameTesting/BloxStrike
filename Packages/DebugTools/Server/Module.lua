local Shared = script.Parent.Parent.Shared
local Signal = require(Shared.Signal)
local v = {
	internal = { Modules = {} },
	prototype = {},
	interface = { ModuleAdded = Signal.new() }
}

function v.prototype:Init() end

function v.interface.new(name: string)
	assert(type(name) == "string", `Expected parameter #1 'name' to be a string, got {type(name)}`)
	local object = setmetatable({ Name = name }, { __index = v.prototype })
	task.defer(function()
		table.insert(v.internal.Modules, name)
		object:Init()
		v.interface.ModuleAdded:Fire(object)
	end)
	return object
end

function v.interface.getAllModules()
	return table.clone(v.internal.Modules)
end

return v.interface