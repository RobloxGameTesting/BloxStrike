local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Classes.Ragdoll.Types)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
return {
	Replication = "All",
	Finisher = function(p, p2)
		local v = Ragdoll.new(p, p2)
		return {
			OnDestroy = v.OnDestroy,
			Destroy = function()
				v:Destroy()
			end
		}
	end
}