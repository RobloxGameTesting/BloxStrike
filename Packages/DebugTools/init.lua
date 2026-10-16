local RunService = game:GetService("RunService")
local v = {}

if RunService:IsClient() then
	v.Client = require(script.Client)
	return v
else
	v.Server = require(script.Server)
	return v
end