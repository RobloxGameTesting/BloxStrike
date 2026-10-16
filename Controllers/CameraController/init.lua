local createVector = vector.create
local CameraController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local DataController = require(ReplicatedStorage.Controllers.DataController)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local Spring = require(ReplicatedStorage.Shared.Spring)
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local CurrentCamera = workspace.CurrentCamera
local v = true
local v2 = 1
local now = 0
local v3 = {}
local v4 = {}
local v5 = false
local v6 = 1
local v7 = 0.5
local v8 = nil
local v9 = nil
local v10 = nil
local v11 = nil
local v12 = nil
local count = 0
local cframe4 = nil
local cframe = nil
local v13 = 0
local v14 = nil
local v15 = nil
local v16 = nil
local fieldOfView = nil
local v17 = {}
local isSpectatingNow = nil
local v18 = Spring.new(1, 100, Constants.DEFAULT_CAMERA_FOV)
local v19 = Spring.new(1, 10, createVector(0, 0, 0))
local v20 = Spring.new(0.4, 25, createVector(0, 0, 0))
local v21 = Spring.new(0.3, 35, createVector(0, 0, 0))
local v22 = Spring.new(1, 1, createVector(0, 0, 0))
local v23 = Spring.new(1, 1, createVector(0, 0, 0))
local v24 = Spring.new(1, 1, createVector(0, 0, 0))

local function setPerspectiveIndicator(visible: boolean) -- 2 equivalent calls inferred from this helper
	local mainGui = PlayerGui:FindFirstChild("MainGui")
	local cameraPerspective = mainGui and mainGui:FindFirstChild("CameraPerspective")

	if cameraPerspective and cameraPerspective.Visible ~= visible then
		cameraPerspective.Visible = visible
	end
end

local function applyMouseEnabled(mouseIconEnabled: boolean) -- 3 equivalent calls inferred from this helper
	UserInputService.MouseBehavior = mouseIconEnabled and Enum.MouseBehavior.Default or Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = mouseIconEnabled
	setPerspectiveIndicator(mouseIconEnabled) -- inferred equivalent call
end

local function getAimAssistController()
	if not v9 then
		local success, result = pcall(function()
			return require(ReplicatedStorage.Controllers.AimAssistController)
		end)

		if success and result then
			v9 = result
		end
	end

	return v9
end

local function getCameraInput()
	if v8 then
		return v8
	end

	local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
	local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
	local cameraModule = playerModule and playerModule:FindFirstChild("CameraModule")
	local cameraInput = cameraModule and cameraModule:FindFirstChild("CameraInput")

	if not (cameraInput and cameraInput:IsA("ModuleScript")) then
		return nil
	end

	local success, result = pcall(require, cameraInput)

	if success and result and result.setTouchSensitivity then
		v8 = result
		return result
	else
		return nil
	end
end

local function setTouchSensitivity(p: number) -- 1 equivalent call inferred from this helper
	if v11 and math.abs(v11 - p) <= 0.0001 then
		return
	end

	local cameraInput = getCameraInput()

	if cameraInput then
		v11 = p
		cameraInput.setTouchSensitivity(p)
	end
end

local function setGamepadAssistMultiplier(p: number) -- 2 equivalent calls inferred from this helper
	if v12 and math.abs(v12 - p) <= 0.0001 then
		return
	end

	local cameraInput = getCameraInput()

	if cameraInput and cameraInput.setGamepadAssistMultiplier then
		v12 = p
		cameraInput.setGamepadAssistMultiplier(p)
	end
end

local function clampFOV(value: number) -- 4 equivalent calls inferred from this helper
	return (math.clamp(value, 1, 80))
end

local function getLockedFOV() -- 4 equivalent calls inferred from this helper
	for _, v25 in pairs(v4) do
		return v25
	end

	return nil
end

local function getCameraCFrame(p: number?)
	if not v9 then
		local success, result = pcall(function()
			return require(ReplicatedStorage.Controllers.AimAssistController)
		end)

		if success and result then
			v9 = result
		end
	end

	local v25 = v9
	local v26 = not v25 and createVector(1, 1, 1) or v25.GetRecoilAssistScale()
	local v27 = v23:getPosition() + v20:getPosition()
	local v28 = v19:getPosition() + v22:getPosition() + v24:getPosition() * (p or v2) * v26 + v21:getPosition()
	return cframe4 * CFrame.new(v27) * CFrame.Angles(v28.X, v28.Y, v28.Z)
end

local function isSceneCameraActive() -- 3 equivalent calls inferred from this helper
	for _, v25 in v17 do
		if v25.IsActive() then
			return true
		end
	end

	return false
end

local function getAspectRatioStretch()
	if v13 <= 0 or not v then
		return 1
	end

	if isSceneCameraActive() then -- inferred equivalent call
		return 1
	end

	local viewportSize = CurrentCamera.ViewportSize

	if viewportSize.X <= 0 or viewportSize.Y <= 0 then
		return 1
	end

	return (math.max(viewportSize.X / viewportSize.Y / (4 / 3), 4 / 3) - 1) * v13 + 1
end

local function applyAspectRatioStretch()
	local v25

	if v13 <= 0 or not v then
		v25 = 1
	elseif isSceneCameraActive() then -- inferred equivalent call
		v25 = 1
	else
		local viewportSize = CurrentCamera.ViewportSize
		v25 = (viewportSize.X <= 0 or viewportSize.Y <= 0) and 1
			or (math.max(viewportSize.X / viewportSize.Y / (4 / 3), 4 / 3) - 1) * v13 + 1
	end

	if v25 <= 1 then
		return
	end

	local v26 = 1 / v25
	local cframe2 = CurrentCamera.CFrame
	local fieldOfView2 = CurrentCamera.FieldOfView
	local cframe3 = cframe2 * CFrame.new(0, 0, 0, 1, 0, 0, 0, v26, 0, 0, 0, 1)
	local fieldOfView3 = math.deg(math.atan(v26 * math.tan(math.rad(fieldOfView2) / 2)) * 2)
	v15 = cframe2
	v16 = fieldOfView2
	CurrentCamera.CFrame = cframe3
	CurrentCamera.FieldOfView = fieldOfView3
	fieldOfView = CurrentCamera.FieldOfView
end

local function restoreAspectRatioStretch()
	local cframe3 = v15
	local fieldOfView2 = v16
	local v25 = fieldOfView

	if not (cframe3 and fieldOfView2 and v25) then
		return
	end

	v15 = nil
	v16 = nil
	fieldOfView = nil
	local cframe2 = CurrentCamera.CFrame

	if cframe2.Position:FuzzyEq(cframe3.Position, 0.001) and cframe2.LookVector:FuzzyEq(cframe3.LookVector, 0.001) then
		CurrentCamera.CFrame = cframe3
	end

	if math.abs(CurrentCamera.FieldOfView - v25) <= 0.001 then
		CurrentCamera.FieldOfView = fieldOfView2
	end
end

local function isCameraAtAppliedFrame()
	local v25 = cframe

	if not v25 then
		return false
	end

	local cframe2 = CurrentCamera.CFrame
	return (cframe2.Position - v25.Position).Magnitude <= 0.001
		and (cframe2.LookVector - v25.LookVector).Magnitude <= 0.0001
end

local function isOwnGameplayView()
	if CurrentCamera.CameraType ~= Enum.CameraType.Custom then
		return false
	end

	if isSceneCameraActive() then -- inferred equivalent call
		return false
	end

	if isSpectatingNow and isSpectatingNow() then
		return false
	end

	local localCharacter = CharacterResolver.getLocalCharacter()
	local cameraSubject = CurrentCamera.CameraSubject
	return localCharacter ~= nil
		and cameraSubject ~= nil
		and cameraSubject:IsDescendantOf(localCharacter)
		and CharacterResolver.isAliveCharacter(localCharacter)
end

local function setTextBoxFocusOverrideActive(flag: boolean) -- 3 equivalent calls inferred from this helper
	CameraController.setForceLockOverride("TextBox", flag)
end

function CameraController.getWeaponKickRotation()
	return v22:getPosition()
end

function CameraController.updateCameraFOV(value: number)
	if getLockedFOV() ~= nil then -- inferred equivalent call
		return
	end

	v18:setGoal(clampFOV(value)) -- inferred equivalent call
end

function CameraController.getTargetFOV()
	return clampFOV(v18:getGoal()) -- inferred equivalent call
end

function CameraController.setFOVLock(p: string, flag: boolean, p2: number?)
	local v25 = v4
	local v26

	if flag then
		v26 = clampFOV(p2 or v18:getGoal()) -- inferred equivalent call
	end

	v25[p] = v26
	local lockedFOV = getLockedFOV() -- inferred equivalent call

	if lockedFOV ~= nil then
		v18:reset(lockedFOV)
	end
end

function CameraController.setMouseEnabled(mouseIconEnabled: boolean)
	v5 = mouseIconEnabled

	if next(v3) == nil then
		applyMouseEnabled(mouseIconEnabled) -- inferred equivalent call
	end
end

function CameraController.setForceLockOverride(p: string, flag: boolean)
	v3[p] = flag and true or nil
	applyMouseEnabled(next(v3) ~= nil or v5) -- inferred equivalent call
end

function CameraController.resetForceLockOverride()
	table.clear(v3)
	v5 = false
	applyMouseEnabled(false) -- inferred equivalent call
end

function CameraController.isForceLockOverrideActive()
	return next(v3) ~= nil
end

function CameraController.SetEnabled(flag: boolean)
	v = flag

	if not flag then
		cframe4 = nil
		cframe = nil
		setGamepadAssistMultiplier(1) -- inferred equivalent call
	end
end

function CameraController.setPerspective(flag: boolean, flag2: boolean, value: number?)
	local v25 = math.max(flag and 0 or value or 5, 0.5)
	CameraController.setMouseEnabled(flag2)

	if LocalPlayer.CameraMaxZoomDistance ~= v25 or LocalPlayer.CameraMinZoomDistance ~= v25 then
		LocalPlayer.CameraMaxZoomDistance = v25
		LocalPlayer.CameraMinZoomDistance = v25
	end

	local lockFirstPerson = flag and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic

	if LocalPlayer.CameraMode ~= lockFirstPerson then
		LocalPlayer.CameraMode = lockFirstPerson
	end
end

function CameraController.toWeaponFirePosition()
	if cframe4 then
		v22:reset(createVector(0, 0, 0))
		v23:reset(createVector(0, 0, 0))
		CurrentCamera.CFrame = cframe4
		CameraController.updateCamera((getCameraCFrame(1)))
	end
end

function CameraController.weaponKick(data, data2)
	v22:setDampingRatio(data.Damper)
	v22:setFrequency(data.Speed)
	v22:setPosition(data.Value * 0.017453292519943295)
	v23:setDampingRatio(data2.Damper)
	v23:setFrequency(data2.Speed)
	v23:setPosition(data2.Value)
	CameraController.updateCamera()
end

function CameraController.setWeaponRecoil(data, p: number)
	v24:setDampingRatio(data.Damper)
	v24:setFrequency(data.Speed)
	v24:setGoal(data.Value)
	v2 = p
end

function CameraController.resetWeaponRecoil()
	v24:reset(createVector(0, 0, 0))
	v2 = 1
end

function CameraController.BombExploded(p: number)
	if getLockedFOV() ~= nil then -- inferred equivalent call
		return
	end

	local v25 = math.max(0.35, 1 - math.min(p / 75, 1))
	v20:impulse(createVector(1.2, 0.5, 0.7) * v25)
	v21:impulse(createVector(0.17453292, 0.06981317, 0.05235988) * v25)
	local goal = v18:getGoal()
	v18:setGoal(goal - v25 * 1.5)
	task.delay(0.15, function()
		v18:setGoal(goal)
	end)
end

function CameraController.updateCamera(cframe2: CFrame?)
	restoreAspectRatioStretch()
	local lockedFOV = getLockedFOV() -- inferred equivalent call

	if lockedFOV ~= nil and v18:getGoal() ~= lockedFOV then
		v18:reset(lockedFOV)
	end

	local fieldOfView2 = clampFOV(lockedFOV or v18:getPosition()) -- inferred equivalent call

	if CurrentCamera.FieldOfViewMode ~= Enum.FieldOfViewMode.Diagonal then
		CurrentCamera.FieldOfViewMode = Enum.FieldOfViewMode.Diagonal
	end

	if math.abs(CurrentCamera.FieldOfView - fieldOfView2) > 0.001 then
		CurrentCamera.FieldOfView = fieldOfView2
	end

	local DEFAULT_CAMERA_FOV = Constants.DEFAULT_CAMERA_FOV
	local v25 = fieldOfView2 / DEFAULT_CAMERA_FOV
	local v26 = v6

	if
		math.abs(fieldOfView2 - (DEFAULT_CAMERA_FOV - 37)) < 0.1
		or math.abs(fieldOfView2 - (DEFAULT_CAMERA_FOV - 60)) < 0.1
	then
		v26 = v6 * v7
	end

	if not v9 then
		local success, result = pcall(function()
			return require(ReplicatedStorage.Controllers.AimAssistController)
		end)

		if success and result then
			v9 = result
		end
	end

	local v27 = not v9 and 1 or v9.GetFrictionMultiplier()
	local mouseDeltaSensitivity = v25 * v26 * v27

	if not v10 or math.abs(v10 - mouseDeltaSensitivity) > 0.0001 then
		v10 = mouseDeltaSensitivity
		UserInputService.MouseDeltaSensitivity = mouseDeltaSensitivity
	end

	local v28 = not (v11 and math.abs(v11 - mouseDeltaSensitivity) <= 0.0001) and getCameraInput()

	if v28 then
		v11 = mouseDeltaSensitivity
		v28.setTouchSensitivity(mouseDeltaSensitivity)
	end

	setGamepadAssistMultiplier(v27) -- inferred equivalent call
	CurrentCamera.CFrame = cframe2 or getCameraCFrame()
	cframe = CurrentCamera.CFrame
end

local function applyAspectRatio(p) -- 2 equivalent calls inferred from this helper
	v13 = (1 - math.clamp(tonumber(p) or 1, 0.5, 1)) / 0.5
end

function CameraController.SetAspectRatio(p)
	v14 = tonumber(p)
	applyAspectRatio(p) -- inferred equivalent call
end

function CameraController.StateChanged(p, p2)
	if p == Enum.HumanoidStateType.Freefall and p2 == Enum.HumanoidStateType.Landed then
		CameraController.OnLanded()
	end
end

function CameraController.OnLanded(value: number?, value2: number?)
	if tick() - now < 0.3 then
		return
	end

	local v25 = math.clamp(((typeof(value) ~= "number" and 12 or math.max(value, 0)) - 2) / 10, 0, 1)

	if v25 <= 0 then
		return
	end

	if typeof(value2) == "number" then
		v25 *= math.clamp(value2, 0, 1) * -0.85 + 1
	end

	now = tick()
	count += 1
	local v26 = count
	v19:setDampingRatio(1)
	v19:setFrequency(10)
	v19:setGoal((Vector3.new(v25 * -0.02181661564992912, 0, 0)))
	task.delay(0.08, function()
		if v26 == count then
			v19:setGoal(createVector(0, 0, 0))
		end
	end)
end

CameraController.clampFOV = clampFOV
CameraController.getAspectRatioStretch = getAspectRatioStretch

function CameraController.Initialize()
	if not v9 then
		local success, result = pcall(function()
			return require(ReplicatedStorage.Controllers.AimAssistController)
		end)

		if success and result then
			v9 = result
		end
	end

	local v25 = v9

	if v25 then
		v25.Initialize()
	end

	RunServiceController.BindToStepped("CameraController.UpdateSprings", function(_, p: number)
		v20:update(p)
		v21:update(p)
		v22:update(p)
		v23:update(p)
		v24:update(p)
		v18:update(p)
		v19:update(p)
	end)
	RunServiceController.BindToRenderStep(
		"CameraController.UpdateCamera",
		Enum.RenderPriority.Camera.Value + 1,
		function(p: number)
			if not v then
				return
			end

			local cframe2 = CurrentCamera.CFrame

			if v9 then
				local magnetismRotation = v9.GetMagnetismRotation(p)

				if
					magnetismRotation.Magnitude > 1e-6
					and magnetismRotation.X == magnetismRotation.X
					and magnetismRotation.Y == magnetismRotation.Y
					and math.abs(magnetismRotation.X) < 3.141592653589793
					and math.abs(magnetismRotation.Y) < 3.141592653589793
				then
					local playerCharacter = CharacterResolver.getPlayerCharacter(LocalPlayer)
					local position

					if playerCharacter and playerCharacter:FindFirstChild("HumanoidRootPart") then
						position = playerCharacter.HumanoidRootPart.Position
					else
						position = cframe2.Position
					end

					local v26 = math.clamp(magnetismRotation.Y, -0.08726646259971647, 0.08726646259971647)
					local v27 = math.clamp(magnetismRotation.X, -0.08726646259971647, 0.08726646259971647)
					local cframe3 = CFrame.fromAxisAngle(cframe2.RightVector, v26) * CFrame.Angles(0, v27, 0)
					local vectorToWorldSpace = cframe3:VectorToWorldSpace(cframe2.Position - position)
					cframe2 = CFrame.new(position + vectorToWorldSpace) * (cframe3 * cframe2.Rotation)
				end
			end

			cframe4 = cframe2
			CameraController.updateCamera((getCameraCFrame()))
			local mouseIconEnabled = next(v3) ~= nil or v5
			local default

			if mouseIconEnabled then
				default = Enum.MouseBehavior.Default
			else
				default = Enum.MouseBehavior.LockCenter
			end

			if UserInputService.MouseBehavior ~= default then
				UserInputService.MouseBehavior = default
			end

			if UserInputService.MouseIconEnabled ~= mouseIconEnabled then
				UserInputService.MouseIconEnabled = mouseIconEnabled
			end

			setPerspectiveIndicator(mouseIconEnabled) -- inferred equivalent call
		end
	)
	RunServiceController.BindToRenderStep(
		"CameraController.ResetCameraShake",
		Enum.RenderPriority.Camera.Value - 1,
		function()
			if v and cframe4 then
				if isOwnGameplayView() then
					CurrentCamera.CFrame = cframe4
				else
					local v26 = cframe
					local v27

					if v26 then
						local cframe2 = CurrentCamera.CFrame

						if (cframe2.Position - v26.Position).Magnitude <= 0.001 then
							v27 = (cframe2.LookVector - v26.LookVector).Magnitude <= 0.0001
						else
							v27 = false
						end
					else
						v27 = false
					end

					if v27 then
						CurrentCamera.CFrame = cframe4
					end
				end
			end
		end
	)
	RunServiceController.BindToRenderSteppedEvent("CameraController.AspectRatioStretch", applyAspectRatioStretch, 1e999)
	RunService.PreAnimation:Connect(restoreAspectRatioStretch)
	RunServiceController.BindToRenderStep(
		"CameraController.UndoAspectRatioStretch",
		Enum.RenderPriority.First.Value,
		restoreAspectRatioStretch
	)
	UserInputService.TextBoxFocused:Connect(function()
		setTextBoxFocusOverrideActive(true) -- inferred equivalent call
	end)
	UserInputService.TextBoxFocusReleased:Connect(function()
		task.defer(function()
			setTextBoxFocusOverrideActive(UserInputService:GetFocusedTextBox() ~= nil) -- inferred equivalent call
		end)
	end)
	setTextBoxFocusOverrideActive(UserInputService:GetFocusedTextBox() ~= nil) -- inferred equivalent call
	local team = LocalPlayer:GetAttribute("Team")
	local v26 = team == "Counter-Terrorists" or team == "Terrorists"

	if not (CharacterResolver.getPlayerCharacter(LocalPlayer) or v26) then
		CameraController.setForceLockOverride("InitialMenu", true)
	end
end

function CameraController.Start()
	local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
	local v25 = { IsActive = MenuSceneController.IsTeamSelectSceneActive }
	local InspectController = require(ReplicatedStorage.Controllers.InspectController)
	v17 = {
		MenuSceneController,
		v25,
		CaseSceneController,
		InspectController,
		require(ReplicatedStorage.Controllers.BlackMarketSceneController)
	}
	local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
	isSpectatingNow = SpectateController.IsSpectatingNow
	local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)

	local function resetFOV() -- 1 equivalent call inferred from this helper
		if not (CaseSceneController.IsActive() or BlackMarketSceneController.IsActive()) then
			CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
		end
	end

	CharacterResolver.observeCharacter(LocalPlayer, function(object)
		if object then
			resetFOV() -- inferred equivalent call
			object:GetAttributeChangedSignal("Dead"):Once(resetFOV)
		end

		return function() end
	end)
	DataController.CreateListener(
		LocalPlayer,
		"Settings.Keyboard/Mouse.Keyboard & Mouse Settings.Mouse Sensitivity",
		function(value: number?)
			v6 = math.clamp(value or 1, 0.1, 10)
			setTouchSensitivity(v6) -- inferred equivalent call
		end
	)
	local v26 = v6
	local v27 = not (v11 and math.abs(v11 - v26) <= 0.0001) and getCameraInput()

	if v27 then
		v11 = v26
		v27.setTouchSensitivity(v26)
	end

	DataController.CreateListener(LocalPlayer, "Settings.Video.Advanced.Aspect Ratio", function(p)
		if v14 ~= nil then
			if math.abs((tonumber(p) or 1) - v14) > 0.0001 then
				return
			else
				v14 = nil
			end
		end

		applyAspectRatio(p) -- inferred equivalent call
	end)
	DataController.CreateListener(
		LocalPlayer,
		"Settings.Keyboard/Mouse.Keyboard & Mouse Settings.Zoom Sensitivity Multiplier",
		function(value: number?)
			v7 = math.clamp(value or 0.5, 0.1, 5)
		end
	)
end

return CameraController