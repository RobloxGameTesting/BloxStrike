local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local CurrentCamera = Workspace.CurrentCamera
local Debris = Workspace:WaitForChild("Debris")
local CaptureController = require(ReplicatedStorage.Controllers.CaptureController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Sound = require(ReplicatedStorage.Classes.Sound)
local color = Color3.new(1, 1, 1)
local raycastParams = RaycastParams.new()
raycastParams.CollisionGroup = "Barriers"
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local v = nil
local v2 = nil
local v3 = nil
local v4 = nil
local v5 = nil
local v6 = nil
local v7 = nil
local v8 = nil
local v9 = nil
local connection = nil
local v10 = nil
local v11 = nil
local v12 = nil
local count = 0
local v13 = nil
local onFlashRecoveryStarted = Signal.new()
local onFlashCleared = Signal.new()

local function QuadTween(p, duration: number, p2) -- 2 equivalent calls inferred from this helper
	return TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p2)
end

local function CancelTweens() -- 4 equivalent calls inferred from this helper
	if v4 then
		v4:Cancel()
		v4 = nil
	end

	if v5 then
		v5:Cancel()
		v5 = nil
	end
end

local function CancelScreenshotFade() -- 3 equivalent calls inferred from this helper
	if v8 then
		v8:Cancel()
		v8 = nil
	end
end

local function DestroyScreenshotGui() -- 2 equivalent calls inferred from this helper
	if v6 then
		v6:Destroy()
		v6 = nil
		v7 = nil
	end
end

local function FadeScreenshot(p, duration: number)
	local tween = TweenService:Create(p, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		ImageTransparency = 1
	})
	v8 = tween
	tween:Play()
	tween.Completed:Connect(function()
		DestroyScreenshotGui() -- inferred equivalent call

		if v8 == tween then
			v8 = nil
		end
	end)
end

local function StopFlashSound() -- 2 equivalent calls inferred from this helper
	if connection then
		connection:Disconnect()
		connection = nil
	end

	if v9 and v9.Parent then
		v9:Stop()
		v9:Destroy()
	end

	v9 = nil
end

local function CleanupFlash()
	CancelTweens() -- inferred equivalent call

	if v then
		v:Destroy()
		v = nil
		v2 = nil
	end

	if v3 then
		v3:Destroy()
		v3 = nil
	end

	CancelScreenshotFade() -- inferred equivalent call
	DestroyScreenshotGui() -- inferred equivalent call
	v10 = nil
	v11 = nil
	v12 = nil
	onFlashCleared:Fire()
end

local function CreateFlashGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FlashbangEffect"
	screenGui.DisplayOrder = 999
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	local frame = Instance.new("Frame")
	frame.Name = "FlashOverlay"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.ZIndex = 999
	frame.Parent = screenGui
	screenGui.Parent = PlayerGui
	return screenGui, frame
end

local function EnsureFlashInstances() -- 2 equivalent calls inferred from this helper
	local v14 = v
	local v15 = v2
	local v16 = v3

	if not (v14 and v15) then
		v14, v15 = CreateFlashGui()
		v = v14
		v2 = v15
	end

	if v16 then
		return v14, v15, v16
	end

	v16 = Instance.new("ColorCorrectionEffect")
	v16.Name = "FlashbangColorCorrection"
	v16.Parent = Lighting
	v3 = v16
	return v14, v15, v16
end

local function StartDriver(p: number)
	task.wait(0.05)

	while count == p do
		local v14 = v10
		local v15 = v11
		local brightness = v12

		if not (v14 and v15 and brightness) then
			break
		end

		local now = os.clock()

		if v14 <= now then
			break
		end

		local _, v16, v17 = EnsureFlashInstances() -- inferred equivalent call

		if now < v15 then
			CancelTweens() -- inferred equivalent call
			v16.BackgroundTransparency = 1 - brightness
			v17.Brightness = brightness
			v17.Saturation = -brightness
			task.wait()
		else
			local v18 = v14 - now
			onFlashRecoveryStarted:Fire()
			CancelTweens() -- inferred equivalent call
			v4 = TweenService:Create(v16, TweenInfo.new(v18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 1
			})
			v5 = TweenService:Create(v17, TweenInfo.new(v18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Brightness = 0,
				Saturation = 0
			})
			v4:Play()
			v5:Play()

			while count == p do
				local now2 = os.clock()

				if v14 <= now2 or v11 and now2 < v11 then
					break
				else
					task.wait(0.05)
				end
			end
		end
	end

	if count == p then
		CleanupFlash()
	end
end

local function CalculateFlashDuration(lookVector: Vector3, vector: Vector3, magnitude: number) -- 1 equivalent call inferred from this helper
	if vector.Magnitude <= 0 then
		return 0
	end

	local v14 = 3 - magnitude * 0.01309090909090909

	if v14 <= 0 then
		return 0
	end

	local v15 = math.clamp(lookVector:Dot(vector.Unit), -1, 1)
	return v14 * (v15 >= 0.6 and 2.5 or v15 >= 0.3 and 1.75 or v15 >= -0.2 and 1 or 0.5) / 1.4
end

local v14 = { -0.5, 0, 0.5 }
local v15 = nil

local function GetMapBarriers() -- 1 equivalent call inferred from this helper
	if v15 ~= nil and v15.Parent ~= nil then
		return v15
	end

	local map = Workspace:FindFirstChild("Map")
	local v16

	if map then
		v16 = map:FindFirstChild("Barriers")
	end

	v15 = v16
	return v15
end

local function HasLineOfSight(position: Vector3, position2: Vector3)
	debug.profilebegin("VFX.Flash.HasLineOfSight")
	local filterDescendantsInstances = { Debris }
	local localCharacter = CharacterResolver.getLocalCharacter()

	if localCharacter then
		table.insert(filterDescendantsInstances, localCharacter)
	end

	local mapBarriers = GetMapBarriers() -- inferred equivalent call

	if mapBarriers then
		table.insert(filterDescendantsInstances, mapBarriers)
	end

	raycastParams.FilterDescendantsInstances = filterDescendantsInstances

	for _, v16 in ipairs(v14) do
		for _, v17 in ipairs(v14) do
			for _, v18 in ipairs(v14) do
				local v19 = position + Vector3.new(v16, v17, v18)
				local v20 = position2 - v19
				local magnitude = v20.Magnitude

				if magnitude < 0.1 then
					return true
				end

				local raycastResult = Workspace:Raycast(v19, v20, raycastParams)

				if raycastResult then
					local distance = raycastResult.Distance

					if not (magnitude - 0.5 <= distance) then
						continue
					end
				end

				debug.profileend()
				return true
			end
		end
	end

	debug.profileend()
	return false
end

local FlashEffect = {}
FlashEffect.OnFlashRecoveryStarted = onFlashRecoveryStarted
FlashEffect.OnFlashCleared = onFlashCleared

function FlashEffect.Flash(p)
	debug.profilebegin("VFX.Flash")
	local position = p.Position
	local position2 = CurrentCamera.CFrame.Position
	local duration

	if p.Duration then
		duration = p.Duration
	else
		local v16 = position - position2
		local magnitude = v16.Magnitude

		if magnitude > 229.16666666666669 or not HasLineOfSight(position, position2) then
			debug.profileend()
			return false
		end

		debug.profilebegin("VFX.Flash.CalculateDuration")
		duration = CalculateFlashDuration(CurrentCamera.CFrame.LookVector, v16, magnitude) -- inferred equivalent call
		debug.profileend()
	end

	if duration < 0.01 then
		debug.profileend()
		return false
	end

	debug.profilebegin("VFX.Flash.Sound")
	StopFlashSound() -- inferred equivalent call
	local v16 = Sound.new("Flashbang"):play({ Parent = CurrentCamera, Name = "Flashed" })

	if v16 then
		v9 = v16
		local lastTime = tick()
		local volume = v16.Volume
		connection = RunServiceController.BindToHeartbeat("VFX.FlashEffect.SoundFade", function()
			local v17 = tick() - lastTime

			if v17 < 4 and v16.Parent then
				v16.Volume = volume * (1 - v17 * 0.225)
				return
			end

			if connection then
				connection:Disconnect()
				connection = nil
			end

			if v16.Parent then
				v16:Stop()
				v16:Destroy()
			end

			if v9 == v16 then
				v9 = nil
			end
		end)
	end

	debug.profileend()

	local function applyFlashEffect()
		debug.profilebegin("VFX.Flash.Apply")
		local now = os.clock()
		local v17 = math.max(not v10 and 0 or math.max(0, v10 - now) or 0, duration)
		local v18 = math.max(0, v17 - 3)
		local brightness = v17 > 3 and 1 or math.clamp((v17 / 3) ^ 0.6, 0, 1)
		v13 = now
		v10 = now + v17
		v12 = brightness
		local v19 = now + 0.05 + v18
		v11 = math.min(v10, (math.max(v11 or 0, v19)))

		if duration >= 4 and v7 then
			CancelScreenshotFade() -- inferred equivalent call
			v7.ImageTransparency = 0
			FadeScreenshot(v7, v17)
		end

		local _, v20, v21 = EnsureFlashInstances() -- inferred equivalent call
		debug.profilebegin("VFX.Flash.Apply.CreateTweens")
		CancelTweens() -- inferred equivalent call
		local quadTween = QuadTween(v20, 0.05, { -- inferred equivalent call
			BackgroundTransparency = 1 - brightness
		})
		local quadTween2 = QuadTween(v21, 0.05, { -- inferred equivalent call
			Brightness = brightness,
			Saturation = -brightness
		})
		quadTween:Play()
		quadTween2:Play()
		debug.profileend()
		count += 1
		task.spawn(StartDriver, count)
		debug.profileend()
	end

	if duration >= 4 then
		debug.profilebegin("VFX.Flash.CaptureScreenshot")
		CaptureController.CaptureScreenshot(function(image: string)
			debug.profilebegin("VFX.Flash.CaptureScreenshot.Callback")
			CancelScreenshotFade() -- inferred equivalent call

			if v6 then
				if v7 then
					v7.Image = image
					v7.ImageTransparency = 0
				end
			else
				local screenGui = Instance.new("ScreenGui")
				screenGui.Name = "FlashScreenshot"
				screenGui.DisplayOrder = 998
				screenGui.IgnoreGuiInset = true
				screenGui.ResetOnSpawn = false
				screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
				local imageLabel = Instance.new("ImageLabel")
				imageLabel.Name = "ScreenshotImage"
				imageLabel.Size = UDim2.new(1, 0, 1, 0)
				imageLabel.BackgroundTransparency = 1
				imageLabel.BorderSizePixel = 0
				imageLabel.Image = image
				imageLabel.ScaleType = Enum.ScaleType.Fit
				imageLabel.ZIndex = 998
				imageLabel.Parent = screenGui
				screenGui.Parent = PlayerGui
				v6 = screenGui
				v7 = imageLabel
			end

			if v7 then
				local v17 = v10 and math.max(0, v10 - os.clock()) or 0
				FadeScreenshot(v7, math.max(v17, 0.01))
			end

			debug.profileend()
		end):catch(function() end)
		debug.profileend()
		task.delay(0.01, applyFlashEffect)
	else
		applyFlashEffect()
	end

	debug.profileend()
	return true
end

function FlashEffect.CancelFlash()
	debug.profilebegin("VFX.Flash.Cancel")
	count += 1
	CleanupFlash()
	v13 = nil
	StopFlashSound() -- inferred equivalent call
	debug.profileend()
end

function FlashEffect.IsFlashed()
	return v10 ~= nil and os.clock() < v10
end

function FlashEffect.GetAudioFadeMultiplier()
	if not v13 then
		return 1
	end

	local v16 = os.clock() - v13

	if v16 >= 1.5 then
		return 1
	end

	if v16 < 0.5 then
		return 0
	end

	return (math.clamp(v16 - 0.5, 0, 1))
end

return FlashEffect