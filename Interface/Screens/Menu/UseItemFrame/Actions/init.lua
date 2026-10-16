local Actions = {}
game:GetService("ReplicatedStorage")
require(script.Types)
local AttachCharm = require(script.AttachCharm)
local v = {}

function Actions.Register(p)
	if v[p.ActionType] then
		warn(`[Actions] Action "{p.ActionType}" is already registered`)
	else
		v[p.ActionType] = p
	end
end

function Actions.Get(p: string)
	return v[p]
end

function Actions.InitializeAll()
	for _, v2 in pairs(v) do
		if v2.Initialize then
			v2.Initialize()
		end
	end
end

Actions.Register(AttachCharm)
return Actions