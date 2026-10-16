local Router = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
require(ReplicatedStorage.Shared.Promise)
local v = {}

local function waitForRouter(p: string, p2: number) -- 1 equivalent call inferred from this helper
	local total = 0

	while v[p] == nil and total <= p2 do
		total += task.wait()
	end

	return v[p]
end

function Router.broadcastRouter(p: string, ...)
	local v2 = waitForRouter(p, 1) -- inferred equivalent call

	if v2 then
		return Profiler.scope(`Router.{p}`, v2, ...)
	end

	warn(`{p} is not cached in local copy.`)
end

function Router.observerRouter(p: string, callback)
	if v[p] then
		warn(`{p} already has a router cached in local copy.`)
	else
		v[p] = callback
	end
end

return Router