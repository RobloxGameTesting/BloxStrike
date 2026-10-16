local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Classes.Ragdoll.Types)
local Sound = require(ReplicatedStorage.Classes.Sound)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local finishers = Sound.new("Finishers")

local function Activate(p, _)
	finishers:play({ Parent = p.CharacterModel, Name = "Gold" })

	if p.CharacterModel:FindFirstChild("CharacterArmor") then
		p.CharacterModel.CharacterArmor:Destroy()
	end

	for _, descendant in ipairs(p.CharacterModel:GetDescendants()) do
		if descendant:IsA("Shirt") or descendant:IsA("Pants") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Color = Color3.fromRGB(255, 170, 0)
			descendant.Material = Enum.Material.Metal
		end
	end
end

return {
	Replication = "All",
	Finisher = function(p, p2)
		local v = Ragdoll.new(p, p2)
		v:OnceAppearanceReady(function()
			Activate(v, p2)
		end)
		return {
			OnDestroy = v.OnDestroy,
			Destroy = function()
				v:Destroy()
			end
		}
	end
}