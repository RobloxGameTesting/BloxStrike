local parent = script.Parent.Parent.Parent
local Tab = require(parent.Tab)
local Networking = require(parent.Networking)
local Action = require(parent.Parent.Shared.Action)
local Value = require(parent.Parent.Shared.Value)
local ActionsList = require(script.Interface.ActionsList)
local ActionGroupsExplorer = require(script.Interface.ActionGroupsExplorer)
local v = {
	internal = {
		ActionGroups = Value.new({}),
		Actions = Value.new({}),
		SelectedGroup = Value.new(false),
		ActionsListDestroyer = nil,
		ActionGroupsExplorerDestroyer = nil
	}
}

function v.internal.executeServerAction(p: string, p2)
	Networking:SendMessage("actions_execute", p, p2)
	return true
end

function v.internal.addAction(data)
	local serverAction = string.sub(data.Name, 1, 7) == "Server/"
	local v2 = serverAction and string.sub(data.Name, 8, #data.Name) or data.Name
	local v3 = string.find(v2, "/")
	local name

	if v3 then
		name = string.sub(v2, v3 + 1, #v2) or v2
	else
		name = v2
	end

	local v4 = v3 and string.sub(v2, 1, v3 - 1) or "Uncategorized"
	local v5 = v.internal.ActionGroups:Get()

	if not table.find(v5, v4) then
		table.insert(v5, v4)
		v.internal.ActionGroups:Set(v5, true)
	end

	local v6 = v.internal.Actions:Get()

	if not v6[v4] then
		v6[v4] = {}
	end

	table.insert(v6[v4], {
		Name = name,
		RawName = data.Name,
		Description = data.Description,
		Arguments = data.Arguments,
		ServerAction = serverAction
	})
	v.internal.Actions:Set(v6, true)

	if not v.internal.SelectedGroup:Get() then
		v.internal.SelectedGroup:Set(v4)
	end
end

function v.internal.removeAction(p: string)
	local v2 = v.internal.Actions:Get()
	local v3 = {}

	for k, v4 in v2 do
		local v5 = {}

		for _, v6 in v4 do
			if v6.RawName ~= p and v6.RawName ~= `Server/{p}` then
				v5[v6.Name] = v6
			end
		end

		v3[k] = v5
	end

	v.internal.Actions:Set(v3, true)
end

function v.internal:Init()
	Networking:SubscribeToTopic("actions_update", function(items)
		for _, item in items do
			local v2 = item
			Action.new(`Server/{item.Name}`, item.Description, function(...)
				return v.internal.executeServerAction(v2.Name, { ... })
			end, item.Arguments)
		end
	end)
	Networking:SubscribeToTopic("actions_remove", v.internal.removeAction)

	for _, v2 in Action:GetAll() do
		v.internal.addAction(v2)
	end

	Action.ActionAdded:Connect(function(p: string)
		local definition = Action:GetDefinition(p)
		v.internal.addAction(definition)
	end)
	Action.ActionRemoved:Connect(v.internal.removeAction)
end

function v.internal:MountInterface(p)
	v.internal.ActionsListDestroyer = ActionsList(p, v.internal.SelectedGroup, v.internal.Actions)
	v.internal.ActionGroupsExplorerDestroyer = ActionGroupsExplorer(
		p,
		v.internal.ActionGroups,
		v.internal.SelectedGroup,
		function(p2: string)
			v.internal.SelectedGroup:Set(p2)
		end
	)
	Networking:SendMessage("actions_listening", true)
end

function v.internal:UnmountInterface()
	if v.internal.ActionsListDestroyer then
		v.internal.ActionsListDestroyer()
		v.internal.ActionsListDestroyer = nil
	end

	if v.internal.ActionGroupsExplorerDestroyer then
		v.internal.ActionGroupsExplorerDestroyer()
		v.internal.ActionGroupsExplorerDestroyer = nil
	end

	Networking:SendMessage("actions_listening", false)
end

v.internal:Init()
Tab.new("Actions", function(p)
	v.internal:MountInterface(p)
	return function()
		v.internal:UnmountInterface()
	end
end)
return nil