local Shared = script.Parent.Parent.Shared
local Signal = require(Shared.Signal)
local v = {
	internal = { Tabs = {} },
	interface = { TabAdded = Signal.new() }
}

function v.interface.new(name: string, createFunction)
	assert(type(name) == "string", `Expected parameter #1 'name' to be a string, got {type(name)}`)
	assert(
		type(createFunction) == "function",
		`Expected parameter #2 'constructorFunction' to be a function, got {type(createFunction)}`
	)
	table.insert(v.internal.Tabs, { Name = name, CreateFunction = createFunction })
	v.interface.TabAdded:Fire(name)
end

function v.interface.getTabConstructor(p: string)
	for _, tab in v.internal.Tabs do
		if tab.Name == p then
			return tab.CreateFunction
		end
	end

	return nil
end

function v.interface.getAllTabs()
	local names = {}

	for _, tab in v.internal.Tabs do
		table.insert(names, tab.Name)
	end

	return names
end

return v.interface