local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Observers = require(ReplicatedStorage.Packages.Observers)
local GraphicsQualityController = require(ReplicatedStorage.Controllers.GraphicsQualityController)
local Janitor = require(ReplicatedStorage.Shared.Janitor)

local function UpdateBoat(instance, p: number, list, cframes)
	list[1] += p
	local handle = instance.Handle

	if not (handle and handle:IsDescendantOf(workspace)) then
		return
	end

	if not cframes[1] then
		cframes[1] = handle.CFrame
	end

	local v = cframes[1]
	local v2 = list[1]
	local v3 = math.sin(v2 * 0.8) * 0.05235987755982989
	local v4 = math.cos(v2 * 0.8 * 0.7) * 0.05235987755982989 * 0.8
	local v5 = math.sin(v2 * 0.5) * 0.15
	local v6 = math.sin(v2 * 1.2) * 0.1
	local v7 = v.LookVector * v5 + Vector3.new(0, v6, 0)
	local v8 = v.Position + v7
	local cframe = CFrame.Angles(v3, 0, 0)
	local cframe2 = CFrame.Angles(0, 0, v4)
	local v9 = v * cframe * cframe2
	handle.CFrame = v9 + (v8 - v9.Position)
end

return Observers.observeTag("TugBoat", function(instance)
	if instance:IsDescendantOf(workspace) then
		return GraphicsQualityController.RunAnimatedProp(function()
			local maid = Janitor.new()
			local v = { nil }
			local v2 = { 0 }
			local bindingName = RunServiceController.CreateBindingName("Observers.Game.TugBoat.Update")
			maid:Add(RunServiceController.BindToHeartbeat(bindingName, function(p: number)
				UpdateBoat(instance, p, v2, v)
			end))
			return function()
				maid:Destroy()
			end
		end)
	end
end)