local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Classes.Ragdoll.Types)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local fire = Instance.new("Fire", nil)
fire.Color = Color3.fromRGB(235, 135, 65)
fire.Heat = 12
fire.Size = 10

local function Activate(p, _)
	local add = p.Janitor:Add(fire:Clone())
	add.Parent = p.CharacterModel.PrimaryPart

	if p.CharacterModel:FindFirstChild("CharacterArmor") then
		p.CharacterModel.CharacterArmor:Destroy()
	end

	for _, descendant in ipairs(p.CharacterModel:GetDescendants()) do
		if descendant:IsA("Shirt") or descendant:IsA("Pants") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Material = Enum.Material.CorrodedMetal
			descendant.Color = Color3.fromRGB(60, 30, 5)
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