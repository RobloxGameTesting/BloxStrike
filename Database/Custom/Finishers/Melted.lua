local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Classes.Ragdoll.Types)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local Rig = require(ReplicatedStorage.Classes.Ragdoll.Rig)
local Goop = ReplicatedStorage.Assets.Finishers.Goop

local function Activate(p, _)
	local lowerTorso = p.CharacterModel:FindFirstChild("LowerTorso")

	if not lowerTorso then
		return
	end

	Rig.DisableJoint(p.CharacterModel, "Waist")
	local upperTorso = p.CharacterModel:FindFirstChild("UpperTorso")

	if upperTorso and upperTorso:IsA("BasePart") then
		upperTorso.AssemblyLinearVelocity += Vector3.new(math.random(-3, 3), math.random(0, 3), math.random(-3, 3))
	end

	local clone = Goop:Clone()
	clone.Weld.Part1 = lowerTorso
	clone.Parent = p.CharacterModel
end

return {
	Replication = "All",
	Finisher = function(p, p2)
		local v = Ragdoll.new(p, p2)
		Activate(v, p2)
		return {
			OnDestroy = v.OnDestroy,
			Destroy = function()
				v:Destroy()
			end
		}
	end
}