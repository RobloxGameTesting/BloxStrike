local Signal = require(script.Parent.Signal)
local v = {
	internal = { Registry = {} },
	interface = { ActionAdded = Signal.new(), ActionRemoved = Signal.new() }
}

function v.interface.new(name: string, value: string?, action, arguments)
	assert(type(name) == "string", `Expected parameter #1 'name' to be a string, got {type(name)}`)

	if value ~= nil then
		assert(type(value) == "string", `Expected parameter #2 'description' to be a string, got {type(value)}`)
	end

	assert(type(action) == "function", `Expected parameter #3 'action' to be a string, got {type(action)}`)

	if v.internal.Registry[name] then
		v.interface:UnregisterAction(name)
	end

	v.internal.Registry[name] = {
		Name = name,
		Description = value,
		Action = action,
		Arguments = arguments
	}
	v.interface.ActionAdded:Fire(name)
end

function v.interface.GetDefinition(_, name: string)
	local v2 = v.internal.Registry[name]
	assert(v2, `Action '{name}' doesn't exist in the registry!`)
	return { Name = name, Description = v2.Description, Arguments = v2.Arguments }
end

function v.interface.GetAll(_)
	local result = {}

	for _, v2 in v.internal.Registry do
		table.insert(result, {
			Name = v2.Name,
			Description = v2.Description,
			Arguments = v2.Arguments
		})
	end

	return result
end

function v.interface.Execute(_, p: string, options)
	local defaults = options or {}
	local v2 = v.internal.Registry[p]
	assert(v2, `Action definition doesn't exist for action '{p}'`)

	if not v2.Arguments then
		return v2.Action(table.unpack(defaults))
	end

	for k, argument in v2.Arguments do
		local v3 = defaults[k]

		if argument.Optional and not v3 then
			defaults[k] = argument.Default
		else
			local typeName = typeof(v3)

			if typeName == "Instance" then
				typeName = v3.ClassName
			end

			assert(
				argument.Type == typeName,
				`Action argument #{k} doesn't match the definition, got '{typeName}' expected '{argument.Type}'`
			)
		end
	end

	return v2.Action(table.unpack(defaults))
end

function v.interface:UnregisterAction(p: string)
	v.internal.Registry[p] = nil
	v.interface.ActionRemoved:Fire(p)
end

return v.interface