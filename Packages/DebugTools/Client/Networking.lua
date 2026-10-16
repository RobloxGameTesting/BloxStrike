local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = script.Parent.Parent.Shared
local Constants = require(Shared.Constants)
local v = {
	internal = { TopicCallbacks = {}, NetworkTrafficRemote = nil, MessageQueue = {} },
	interface = {}
}

function v.internal.listenToNetworkTraffic()
	local child = ReplicatedStorage:WaitForChild(Constants.NETWORK_TRAFFIC_REMOTE_NAME)
	child.OnClientEvent:Connect(function(items)
		for _, item in items do
			local v2 = item[1]
			local v3 = item[2]

			if v2 and v3 then
				v.internal.invokeTopic(v2, table.unpack(v3))
			end
		end
	end)
	v.internal.NetworkTrafficRemote = child
	child:FireServer("_ready_")
end

function v.internal.initiateTrafficHeartbeat()
	if not v.internal.NetworkTrafficRemote then
		return
	end

	RunService.Heartbeat:Connect(function()
		if #v.internal.MessageQueue <= 0 then
			return
		end

		v.internal.NetworkTrafficRemote:FireServer(v.internal.MessageQueue)
		v.internal.MessageQueue = {}
	end)
end

function v.internal.invokeTopic(p: string, ...)
	local topicCallback = v.internal.TopicCallbacks[p]

	if not topicCallback then
		return
	end

	for _, v2 in topicCallback do
		v2(...)
	end
end

function v.interface.SendMessage(_, p: string, ...)
	table.insert(v.internal.MessageQueue, {
		p,
		{ ... }
	})
end

function v.interface.SubscribeToTopic(_, p: string, callback)
	if not v.internal.TopicCallbacks[p] then
		v.internal.TopicCallbacks[p] = {}
	end

	local topicCallback = v.internal.TopicCallbacks[p]
	table.insert(topicCallback, callback)
	return function()
		local index = table.find(topicCallback, callback)
		table.remove(topicCallback, index)
	end
end

v.internal.listenToNetworkTraffic()
v.internal.initiateTrafficHeartbeat()
return v.interface