local Workspace = game:GetService("Workspace")
local Config = require(script.Parent.Config)
return table.freeze({
	getMovementConfig = function(p: number?)
		local serverGamemode = Workspace:GetAttribute("ServerGamemode")

		if serverGamemode == "Surf" then
			return Config.resolveServerGamemode("Surf", p)
		end

		local vipCompetitiveMovementEnabled = Workspace:GetAttribute("VIPCompetitiveMovementEnabled")

		if typeof(vipCompetitiveMovementEnabled) == "boolean" then
			return Config.resolveServerGamemode(vipCompetitiveMovementEnabled and "Competitive" or "Casual", p)
		end

		return Config.resolveServerGamemode(serverGamemode, p)
	end
})