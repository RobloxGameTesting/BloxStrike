local ServerBrowser = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
require(ReplicatedStorage.Database.Custom.Types)
local RemoveFromArray = require(ReplicatedStorage.Database.Components.Common.RemoveFromArray)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Signal = require(ReplicatedStorage.Packages.Signal)
local onServerBrowserUpdated = Signal.new()
ServerBrowser.OnServerBrowserUpdated = onServerBrowserUpdated
local v = {}
local v2 = {}

function ServerBrowser.GetServerNameFromMatchId(value: string)
	return value:gsub("[^%a]", ""):upper()
end

function ServerBrowser.GetActiveGameServers()
	return v2
end

function ServerBrowser.GetServerByMatchId(p: string)
	return v[p]
end

function ServerBrowser.UpdateActiveGameServers(value)
	local removeFromArray = RemoveFromArray(HttpService:JSONDecode(value or "[]"), function(_, p)
		return not RunService:IsStudio() and p.JobId == "Studio"
	end)
	local v3 = {}

	for _, v4 in ipairs(removeFromArray) do
		v3[v4.MatchId] = v4
	end

	for k in v do
		if not v3[k] then
			v[k] = nil
		end
	end

	for k, v4 in v3 do
		v[k] = v4
	end

	v2 = removeFromArray
	onServerBrowserUpdated:Fire(v2)
end

function ServerBrowser.ObserverServerBrowser(callback)
	local connection = onServerBrowserUpdated:Connect(callback)

	if #v2 > 0 then
		callback(v2)
	end

	return function()
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end
end

Remotes.Modes.FetchServers.Listen(function(p)
	ServerBrowser.UpdateActiveGameServers(p)
end)
return ServerBrowser