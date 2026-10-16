local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Schema = require(ReplicatedStorage.MovementV2.Collision.Schema)
local debris = workspace:WaitForChild("Debris")
local Observers = require(ReplicatedStorage.Packages.Observers)

local function createDuplicateSnowman(instance)
	local pivot = instance:GetPivot()
	local clone = instance:Clone()
	clone:SetAttribute("Broken", false)
	clone:RemoveTag("Snowman")
	clone:RemoveTag("Interactable")

	for _, descendant in clone:GetDescendants() do
		descendant:RemoveTag(Schema.Tags.Destructible)
	end

	clone:PivotTo(pivot)

	for _, child in ipairs(clone:GetChildren()) do
		if child.Name ~= "Head" then
			continue
		end

		child.CanCollide = true
		child.Transparency = 0
	end

	clone.Parent = debris
	return clone
end

local function createBreakPoints(duplicateSnowman)
	local direction = duplicateSnowman:GetAttribute("Direction")

	for _, child in ipairs(duplicateSnowman:GetChildren()) do
		if child.Name ~= "Head" then
			continue
		end

		child.CollisionGroup = "Debris"
		child.Anchored = false
		child.Massless = true

		if direction then
			child:ApplyImpulse(math.random(30, 40) * direction)
		end
	end

	Debris:AddItem(duplicateSnowman, 10)
end

return Observers.observeTag("Snowman", function(instance)
	if instance:IsDescendantOf(workspace) then
		return Observers.observeAttribute(instance, "Broken", function(p)
			if p then
				createBreakPoints(createDuplicateSnowman(instance))
			end
		end)
	end
end)