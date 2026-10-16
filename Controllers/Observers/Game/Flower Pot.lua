local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local debris = workspace:WaitForChild("Debris")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Sound = require(ReplicatedStorage.Classes.Sound)

local function createDuplicateFlowerPot(instance)
	local pivot = instance:GetPivot()
	instance:SetAttribute("Broken", false)
	instance:RemoveTag("Flower Pot")
	instance:RemoveTag("Interactable")
	local clone = instance:Clone()
	clone:PivotTo(pivot)
	clone.Parent = debris

	for _, part in ipairs(clone:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanCollide = part.Name ~= "Unbroken"
		part.Transparency = part.Name == "Unbroken" and 1 or 0
	end

	return clone
end

local function createBreakPoints(duplicateFlowerPot)
	local direction = duplicateFlowerPot:GetAttribute("Direction")

	for _, part in ipairs(duplicateFlowerPot:GetChildren()) do
		if not (part:IsA("BasePart") and part.Name ~= "Unbroken") then
			continue
		end

		part.CollisionGroup = "Debris"
		part.Anchored = false
		part.Massless = true
	end

	for _, part in ipairs(duplicateFlowerPot:GetChildren()) do
		if part:IsA("BasePart") then
			part:ApplyImpulse(direction * math.random(2, 3))
		end
	end

	Debris:AddItem(duplicateFlowerPot, 5)
	Sound.new("Bullet"):playOneTime({
		Name = "Break Flower Pot",
		Parent = duplicateFlowerPot.PrimaryPart
	})
end

return Observers.observeTag("Flower Pot", function(instance)
	if instance:IsDescendantOf(workspace) then
		return Observers.observeAttribute(instance, "Broken", function(p)
			if p then
				createBreakPoints(createDuplicateFlowerPot(instance))
			end
		end)
	end
end)