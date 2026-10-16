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

local function Activate(p, _)
	local add = p.Janitor:Add(script.FinisherGui:Clone(), "Destroy", "FinisherGui")
	add.Parent = LocalPlayer.PlayerGui
	local v = finishers:play({ Parent = LocalPlayer.PlayerGui, Name = "LeSunshine" })

	if not v then
		return
	end

	p.Janitor:Add(v.Ended:Once(function()
		p.Janitor:Remove("FinisherGui")
	end))
end

return {
	Replication = "All",
	Finisher = function(p, p2)
		local v = Ragdoll.new(p, p2)

		if IsLocalPlayer(p2.Victim) then -- inferred equivalent call
			Activate(v, p2)
		end

		return {
			OnDestroy = v.OnDestroy,
			Destroy = function()
				v:Destroy()
			end
		}
	end
}