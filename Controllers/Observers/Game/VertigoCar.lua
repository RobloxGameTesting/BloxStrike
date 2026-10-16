local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Observers = require(ReplicatedStorage.Packages.Observers)
local GraphicsQualityController = require(ReplicatedStorage.Controllers.GraphicsQualityController)
local Janitor = require(ReplicatedStorage.Shared.Janitor)

local function CreateTween(maid, instance)
	if not instance:IsDescendantOf(workspace) then
		return
	end

	local pointA = instance:WaitForChild("PointA", 5)
	local pointB = instance:WaitForChild("PointB", 5)

	if not (pointA and pointB) then
		warn(`[VertigoCar] Model "{instance.Name}" is missing PointA or PointB attachments`)
		return
	end

	if not instance:IsDescendantOf(workspace) then
		return
	end

	local worldPosition = pointA.WorldPosition
	local worldPosition2 = pointB.WorldPosition
	local magnitude = (worldPosition2 - worldPosition).Magnitude

	if magnitude <= 0 then
		return
	end

	local v = magnitude / 42
	local tween = TweenService:Create(instance, TweenInfo.new(v, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Position = worldPosition2
	})
	maid:Add(tween, "Cancel")

	while instance:IsDescendantOf(workspace) do
		instance.Position = worldPosition
		tween:Play()
		tween.Completed:Wait()
	end
end

return Observers.observeTag("VertigoCar", function(instance)
	instance.Anchored = true

	if not instance:IsDescendantOf(workspace) then
		return nil
	end

	local v = GraphicsQualityController.RunAnimatedProp(function()
		local maid = Janitor.new()
		maid:Add(instance)
		maid:Add(task.spawn(function()
			CreateTween(maid, instance)
		end))
		return function()
			maid:Destroy()
		end
	end)

	if not v then
		instance:Destroy()
	end

	return v
end)