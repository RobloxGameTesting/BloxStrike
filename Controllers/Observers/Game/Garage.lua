local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MoverTrajectory = require(ReplicatedStorage.MovementV2.MoverTrajectory)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Sound = require(ReplicatedStorage.Classes.Sound)

local function playGarageSound(handle, flag: boolean) -- 1 equivalent call inferred from this helper
	Sound.new("Miscellaneous"):playOneTime({
		Parent = handle,
		Name = flag and "Open Garage" or "Close Garage"
	})
end

return Observers.observeTag("Garage", function(instance)
	if not instance:IsDescendantOf(workspace) then
		return nil
	end

	local handle = instance:FindFirstChild("Handle")

	if handle == nil or not handle:IsA("BasePart") then
		return nil
	end

	local v = nil
	local renderSteppedConnection = nil
	local v2 = true

	local function disconnectRender() -- 3 equivalent calls inferred from this helper
		if renderSteppedConnection ~= nil then
			renderSteppedConnection:Disconnect()
			renderSteppedConnection = nil
		end
	end

	local function applyPose()
		if v == nil or handle.Parent == nil then
			disconnectRender() -- inferred equivalent call
		else
			local serverTimeNow = workspace:GetServerTimeNow()
			handle.CFrame = MoverTrajectory.EvaluateTime(v, serverTimeNow)

			if
				(not v.Moving or MoverTrajectory.TimeAlpha(v, serverTimeNow) >= 1)
				and renderSteppedConnection ~= nil
			then
				renderSteppedConnection:Disconnect()
				renderSteppedConnection = nil
			end
		end
	end

	local function refreshTrajectory() -- 2 equivalent calls inferred from this helper
		local v3 = MoverTrajectory.Read(handle)

		if v3 == nil then
			return
		end

		v = v3
		disconnectRender() -- inferred equivalent call

		if v3.Moving then
			renderSteppedConnection = RunService.RenderStepped:Connect(applyPose)
		end

		applyPose()
	end

	local connection = handle:GetAttributeChangedSignal(MoverTrajectory.Attributes.Revision):Connect(refreshTrajectory)
	local connection2 = handle:GetAttributeChangedSignal(MoverTrajectory.Attributes.Id):Connect(refreshTrajectory)
	local clientDescriptorChangedConnection = MoverTrajectory.ClientDescriptorChanged:Connect(function(p)
		if handle:GetAttribute(MoverTrajectory.Attributes.Id) == p then
			refreshTrajectory() -- inferred equivalent call
		end
	end)
	local currentStateChangedConnection = instance:GetAttributeChangedSignal("CurrentState"):Connect(function()
		if not v2 then
			playGarageSound(handle, instance:GetAttribute("CurrentState") == true) -- inferred equivalent call
		end

		v2 = false
	end)
	refreshTrajectory() -- inferred equivalent call
	v2 = false
	return function()
		disconnectRender() -- inferred equivalent call
		connection:Disconnect()
		connection2:Disconnect()
		clientDescriptorChangedConnection:Disconnect()
		currentStateChangedConnection:Disconnect()
	end
end)