local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Sound = require(ReplicatedStorage.Classes.Sound)
local animation = Instance.new("Animation", nil)
animation.AnimationId = "rbxassetid://130065050998927"
animation.Name = "HOSTAGE_IDLE"
local animation2 = Instance.new("Animation", nil)
animation2.AnimationId = "rbxassetid://84183418979817"
animation2.Name = "HOSTAGE_CARRYING"

local function updateAnimation(instance)
	local humanoid = instance:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return nil
	end

	local animator = humanoid:WaitForChild("Animator")
	local track = instance:GetAttribute("State") == "Carrying" and animator:LoadAnimation(animation2)
		or instance:GetAttribute("State") == "Idle" and animator:LoadAnimation(animation)
		or nil

	if track then
		track:Play()
	end

	return track
end

return Observers.observeTag("Hostage", function(instance)
	local humanoidRootPart = instance:WaitForChild("HumanoidRootPart", 10)
	local humanoid = instance:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		local lastTime = tick()

		repeat
			task.wait(0.1)
			humanoid = instance:FindFirstChildOfClass("Humanoid")
		until humanoid or tick() - lastTime > 10
	end

	local head = instance:WaitForChild("Head", 10) or humanoid or humanoidRootPart

	if not (head and instance:IsDescendantOf(workspace)) then
		return
	end

	local maid = Janitor.new()
	local hostage = Sound.new("Hostage")
	local v = nil
	hostage:playOneTime({ Name = "Hostage Idle", Parent = head })
	maid:Add(instance:GetAttributeChangedSignal("State"):Connect(function()
		if v then
			v:Stop()
			v = nil
		end

		v = updateAnimation(instance)
	end))
	v = updateAnimation(instance)
	maid:Add(function()
		hostage:destroy()
	end)
	return function()
		maid:Destroy()
	end
end)