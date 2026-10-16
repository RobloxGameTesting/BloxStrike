local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = script.Parent.Parent.Shared
local Signal = require(Shared.Signal)
local Constants = require(Shared.Constants)
local v = {
	internal = { Players = {} },
	interface = { PlayerAuthorized = Signal.new() }
}

function v.internal.playerAdded(object)
	v.internal.Players[object] = { Authorized = false, Authorizing = true }
	local authorized = RunService:IsStudio() or object:GetRankInGroup(Constants.GROUP_ID) >= Constants.GROUP_RANK

	if not v.internal.Players[object] then
		return
	end

	v.internal.Players[object].Authorized = authorized
	v.internal.Players[object].Authorizing = false

	if not authorized then
		return
	end

	v.interface.PlayerAuthorized:Fire(object)
end

function v.internal.playerRemoved(p)
	if not v.internal.Players[p] then
		return
	end

	v.internal.Players[p] = nil
end

function v.internal.listenToPlayers()
	Players.PlayerAdded:Connect(function(player)
		v.internal.playerAdded(player)
	end)

	for _, v2 in Players:GetPlayers() do
		v.internal.playerAdded(v2)
	end

	Players.PlayerRemoving:Connect(function(player)
		v.internal.playerRemoved(player)
	end)
end

function v.interface.isPlayerAuthorized(p)
	if RunService:IsStudio() then
		return true
	end

	local player = v.internal.Players[p]

	if not player then
		return false
	end

	while v.internal.Players[p] and player.Authorizing do
		task.wait()
	end

	return v.internal.Players[p] and player.Authorized
end

v.internal.listenToPlayers()
return v.interface