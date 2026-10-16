local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local debris = workspace:WaitForChild("Debris")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Sound = require(ReplicatedStorage.Classes.Sound)

local function createDuplicateVent(instance)
	local pivot = instance:GetPivot()
	local clone = instance:Clone()
	clone:SetAttribute("Broken", false)
	clone:RemoveTag("Interactable")
	clone:RemoveTag("Vent")
	clone:PivotTo(pivot)

	for _, part in ipairs(clone:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		if part.Name == "BreakPoint" then
			part.CanCollide = true
			part.CanQuery = false
			part.Transparency = 0
		else
			part:Destroy()
		end
	end

	clone.Parent = debris
	return clone
end

local function createBreakPoints(duplicateVent)
	local position = duplicateVent:GetPivot().Position
	local direction = duplicateVent:GetAttribute("Direction")

	for _, part in ipairs(duplicateVent:GetChildren()) do
		if not part:IsA("BasePart") then
			continue
		end

		part.CollisionGroup = "Debris"
		part.Anchored = false
		part:ApplyImpulse((Vector3.new(
			direction.X * math.random(15, 20),
			direction.Y * math.random(15, 20),
			direction.Z * math.random(15, 20)
		)))
	end

	Debris:AddItem(duplicateVent, 5)
	Sound.new("Bullet"):PlaySoundAtPosition({
		Name = "Break Metal Vent",
		Class = "Bullet",
		Position = position
	})
end

return Observers.observeTag("Vent", function(instance)
	if instance:IsDescendantOf(workspace) then
		return Observers.observeAttribute(instance, "Broken", function(p)
			if p then
				createBreakPoints(createDuplicateVent(instance))
			end
		end)
	end
end)