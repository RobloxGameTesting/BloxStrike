local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(ReplicatedStorage.Classes.Ragdoll.Types)
local LocalPlayer = Players.LocalPlayer
local Sound = require(ReplicatedStorage.Classes.Sound)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local finishers = Sound.new("Finishers")

local function IsLocalPlayer(victim) -- 1 equivalent call inferred from this helper
	return tostring(victim) == tostring(LocalPlayer.UserId)
end

return {
	Replication = "All",
	Finisher = function(p, p2)
		local v = Ragdoll.new(p, p2)

		if IsLocalPlayer(p2.Victim) then -- inferred equivalent call
			finishers:play({ Parent = LocalPlayer.PlayerGui, Name = "Fling" })
		end

		return {
			OnDestroy = v.OnDestroy,
			Destroy = function()
				v:Destroy()
			end
		}
	end
}