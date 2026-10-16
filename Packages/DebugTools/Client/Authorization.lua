local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Constants = require(script.Parent.Parent.Shared.Constants)
local v = { internal = {}, interface = {} }

function v.interface.isLocalPlayerAuthorized()
	if RunService:IsStudio() then
		return true
	end

	return Players.LocalPlayer:GetRankInGroup(Constants.GROUP_ID) >= Constants.GROUP_RANK
end

return v.interface