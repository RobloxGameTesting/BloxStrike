local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Observers = require(ReplicatedStorage.Packages.Observers)
local GraphicsQualityController = require(ReplicatedStorage.Controllers.GraphicsQualityController)

local function getNoiseInstances(instance)
	local children = {}
	local screen = instance:FindFirstChild("Screen")

	if screen then
		for _, child in ipairs(screen:GetChildren()) do
			if child.Name == "Noise" then
				table.insert(children, child)
			end
		end
	end

	return children
end

local function updateScreen(noiseInstances)
	for _, v in ipairs(noiseInstances) do
		v.Transparency = math.clamp(math.random(), 0.2, 0.7)
		v.Color3 = Color3.fromRGB(192 + math.random(-10, 10), 216 + math.random(-10, 10), 255 + math.random(-10, 10))
	end
end

local function breakScreen(instance)
	local screen = instance:FindFirstChild("Screen")

	if not screen then
		return
	end

	TweenService:Create(screen, TweenInfo.new(2.15), { Color = Color3.fromRGB(0, 0, 0) }):Play()
	local pointLight = screen.ScreenLight.PointLight

	for _ = 1, 8 do
		pointLight.Enabled = not pointLight.Enabled
		task.wait(math.random(1, 4) / 10)
	end

	pointLight.Enabled = false

	for _, child in ipairs(screen:GetChildren()) do
		if child.Name == "Noise" then
			child.Transparency = 1
		end
	end
end

return Observers.observeTag("Television", function(instance)
	local v = 0

	if not instance:IsDescendantOf(workspace) then
		return
	end

	local noiseInstances = getNoiseInstances(instance)
	local v2 = GraphicsQualityController.RunAnimatedProp(function()
		local bindingName = RunServiceController.CreateBindingName("Observers.Game.Television.Noise")
		local connection = RunServiceController.BindToHeartbeat(bindingName, function(p: number)
			v += p

			if v >= 0.05 then
				v %= 0.05

				if instance:IsDescendantOf(workspace) then
					updateScreen(noiseInstances)
				end
			end
		end)
		return function()
			if connection.Connected then
				connection:Disconnect()
			end
		end
	end)

	local function stopNoise() -- 2 equivalent calls inferred from this helper
		if v2 then
			v2()
		end
	end

	local v3 = Observers.observeAttribute(instance, "Broken", function(_)
		breakScreen(instance)
		stopNoise() -- inferred equivalent call
	end)
	return function()
		v3()
		stopNoise() -- inferred equivalent call
	end
end)