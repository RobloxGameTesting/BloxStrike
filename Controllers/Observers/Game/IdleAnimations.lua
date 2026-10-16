local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Observers = require(ReplicatedStorage.Packages.Observers)
local GraphicsQualityController = require(ReplicatedStorage.Controllers.GraphicsQualityController)
local v = {}

for _, v2 in {
	{
		Tag = "Ceiling Fan",
		AnimationId = "rbxassetid://82806563298602",
		AnimatorPath = { "AnimationController", "Animator" },
		RequireWorkspace = true
	},
	{
		Tag = "Flag",
		AnimationId = "rbxassetid://103823379066850",
		AnimationName = "FLAG_IDLE",
		AnimatorPath = { "csFlag", "AnimationController", "Animator" },
		Ancestors = { workspace }
	},
	{
		Tag = "VertigoCrane",
		AnimationId = "rbxassetid://75914758947993",
		AnimationName = "CRANE_IDLE",
		AnimatorPath = { "AnimationController", "Animator" },
		RequireWorkspace = true
	},
	{
		Tag = "VertigoGenerator",
		AnimationId = "rbxassetid://106431666932790",
		AnimationName = "GENERATOR_IDLE",
		AnimatorPath = { "AnimationController", "Animator" },
		RequireWorkspace = true
	}
} do
	local animation = Instance.new("Animation")
	animation.AnimationId = v2.AnimationId

	if v2.AnimationName then
		animation.Name = v2.AnimationName
	end

	local v3 = v2
	table.insert(v, Observers.observeTag(v2.Tag, function(instance)
		local child = instance

		for _, childName in v3.AnimatorPath do
			child = child:WaitForChild(childName)
		end

		if v3.RequireWorkspace and not instance:IsDescendantOf(workspace) then
			return nil
		end

		return GraphicsQualityController.RunAnimatedProp(function()
			local track = child:LoadAnimation(animation)
			track:Play()
			return function()
				track:Destroy()
			end
		end)
	end, v2.Ancestors))
end

return function()
	for _, v2 in v do
		v2()
	end
end