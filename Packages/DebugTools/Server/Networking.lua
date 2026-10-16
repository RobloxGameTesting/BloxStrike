local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local parent = script.Parent.Parent
local Shared = parent.Shared
local Signal = require(Shared.Signal)
local Constants = require(Shared.Constants)
local Authorization = require(parent.Server.Authorization)
local v = {
	internal = { TopicCallbacks = {}, NetworkTrafficRemote = nil, NetworkTargets = {} },
	interface = { NetworkTargetAdded = Signal.new(), NetworkTargetRemoved = Signal.new() }
}

function v.internal.playerRemoving(p)
	if not v.internal.NetworkTargets[p] then
		return
	end

	v.internal.NetworkTargets[p] = nil
	v.interface.NetworkTargetRemoved:Fire(p)
end

function v.internal.registerNetworkTarget(p)
	if v.internal.NetworkTargets[p] or not Authorization.isPlayerAuthorized(p) then
		return
	end

	v.internal.NetworkTargets[p] = { MessageQueue = {} }
	v.interface.NetworkTargetAdded:Fire(p)
end

function v.internal.createTrafficRemote()
	local remoteEvent = Instance.new("RemoteEvent")
	remoteEvent.Name = Constants.NETWORK_TRAFFIC_REMOTE_NAME
	remoteEvent.Parent = ReplicatedStorage
	v.internal.NetworkTrafficRemote = remoteEvent
end

function v.internal.listenToNetworkTraffic()
	v.internal.NetworkTrafficRemote.OnServerEvent:Connect(function(object, items)
		if not Authorization.isPlayerAuthorized(object) then
			object:Kick("Attempted to perform unauthorized action.")
			return
		end

		if items == "_ready_" then
			v.internal.registerNetworkTarget(object)
			return
		end

		if typeof(items) ~= "table" then
			return
		end

		for _, item in items do
			local v2 = item[1]
			local v3 = item[2]

			if v2 and v3 then
				v.internal.invokeTopic(v2, object, table.unpack(v3))
			end
		end
	end)
end

function v.internal.initiateTrafficHeartbeat()
	RunService.Heartbeat:Connect(function()
		for player, networkTarget in v.internal.NetworkTargets do
			if #networkTarget.MessageQueue <= 0 then
				continue
			end

			v.internal.NetworkTrafficRemote:FireClient(player, networkTarget.MessageQueue)
			networkTarget.MessageQueue = {}
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		v.internal.playerRemoving(player)
	end)
end

function v.internal.invokeTopic(p: string, p2, ...)
	local topicCallback = v.internal.TopicCallbacks[p]

	if not topicCallback then
		return
	end

	for _, v2 in topicCallback do
		v2(p2, ...)
	end
end

function v.interface:SendMessageToPlayer(p, p2: string, ...)
	if not v.internal.NetworkTargets[p] then
		return
	end

	table.insert(v.internal.NetworkTargets[p].MessageQueue, {
		p2,
		{ ... }
	})
end

function v.interface.SendMessage(_, p: string, ...)
	for k in v.internal.NetworkTargets do
		v.interface:SendMessageToPlayer(k, p, ...)
	end
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

function v.interface.GetNetworkTargets(_)
	local result = {}

	for k in v.internal.NetworkTargets do
		table.insert(result, k)
	end

	return result
end

v.internal.createTrafficRemote()
v.internal.listenToNetworkTraffic()
v.internal.initiateTrafficHeartbeat()
return v.interface