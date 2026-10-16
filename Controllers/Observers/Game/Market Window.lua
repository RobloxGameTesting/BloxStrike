local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Schema = require(ReplicatedStorage.MovementV2.Collision.Schema)
local debris = workspace:WaitForChild("Debris")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Sound = require(ReplicatedStorage.Classes.Sound)

local function createDuplicateWindow(instance)
	local pivot = instance:GetPivot()
	local clone = instance:Clone()
	clone:SetAttribute("Broken", false)
	clone:RemoveTag("Market Window")
	clone:RemoveTag("Interactable")

	for _, descendant in clone:GetDescendants() do
		descendant:RemoveTag(Schema.Tags.Destructible)
	end

	clone:PivotTo(pivot)

	for _, part in ipairs(clone:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanCollide = true
		part.Transparency = 0
	end

	clone.Parent = debris
	return clone
end

local function createBreakPoints(duplicateWindow)
	local direction = duplicateWindow:GetAttribute("Direction")

	for _, part in ipairs(duplicateWindow:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = "Debris"
		part.Anchored = false
		part:ApplyImpulse((Vector3.new(
			direction.X * math.random(7, 12),
			direction.Y * math.random(7, 12),
			direction.Z * math.random(7, 12)
		)))
	end

	Debris:AddItem(duplicateWindow, 5)
	Sound.new("Bullet"):playOneTime({
		Name = "Break Market Window",
		Parent = duplicateWindow.PrimaryPart
	})
end

return Observers.observeTag("Market Window", function(instance)
	if instance:IsDescendantOf(workspace) then
		return Observers.observeAttribute(instance, "Broken", function(p)
			if p then
				createBreakPoints(createDuplicateWindow(instance))
			end
		end)
	end
end)