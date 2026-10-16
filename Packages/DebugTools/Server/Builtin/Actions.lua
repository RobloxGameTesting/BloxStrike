local Module = require(script.Parent.Parent.Module)
local Networking = require(script.Parent.Parent.Networking)
local Action = require(script.Parent.Parent.Parent.Shared.Action)
local actions = Module.new("Actions")
local v = { ActionListeners = {} }

function v:SendActionsList(p)
	local actionListener = v.ActionListeners[p]

	if not actionListener then
		actionListener = { Listening = true, SentActions = {} }
		v.ActionListeners[p] = actionListener
	end

	local v2 = {}

	for _, v3 in Action:GetAll() do
		if actionListener.SentActions[v3.Name] then
			continue
		end

		actionListener.SentActions[v3.Name] = true
		table.insert(v2, v3)
	end

	if #v2 == 0 then
		return
	end

	Networking:SendMessageToPlayer(p, "actions_update", v2)
end

function actions.Init()
	Action.ActionAdded:Connect(function(p: string)
		local definition = Action:GetDefinition(p)

		for k, actionListener in v.ActionListeners do
			if not actionListener.Listening then
				continue
			end

			actionListener.SentActions[p] = true
			Networking:SendMessageToPlayer(k, "actions_update", { definition })
		end
	end)
	Action.ActionRemoved:Connect(function(p: string)
		for k, actionListener in v.ActionListeners do
			if not actionListener.Listening then
				continue
			end

			actionListener.SentActions[p] = nil
			Networking:SendMessageToPlayer(k, "actions_remove", p)
		end
	end)
	Networking:SubscribeToTopic("actions_listening", function(p, flag: boolean)
		if flag then
			v:SendActionsList(p)
		else
			v.ActionListeners[p].Listening = false
		end
	end)
	Networking:SubscribeToTopic("actions_execute", function(_, p: string, p2)
		Action:Execute(p, p2)
	end)
end

return actions