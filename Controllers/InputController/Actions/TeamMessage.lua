local Players = game:GetService("Players")
local ActionTemplates = require(script.Parent.Parent.ActionTemplates)
local LocalPlayer = Players.LocalPlayer
return ActionTemplates.chat("Team Message", function()
	local team = LocalPlayer:GetAttribute("Team")

	if not team or team == "Spectators" then
		return 1
	end

	return 0
end)