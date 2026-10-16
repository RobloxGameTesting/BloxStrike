local CaseSceneController = {}
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local mainGui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainGui", 1e999)
local SceneRegistry = require(script:WaitForChild("SceneRegistry"))
local ConsoleBoardAnimator = require(script:WaitForChild("ConsoleBoardAnimator"))
require(script:WaitForChild("ConsoleItemRoller"))
require(ReplicatedStorage.Database.Custom.ConsoleTypes)
require(ReplicatedStorage.Database.Custom.Types)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local SceneParking = require(ReplicatedStorage.Components.Common.SceneParking)
local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local CurrentCamera = workspace.CurrentCamera
local v = false
local clonesByAssetFolder = {}
local v2 = nil
local v3 = nil
local v4 = nil
local maid = Janitor.new()
local flag = false
local v5 = nil
local folders = {}
local v6 = false
local v7 = nil
local cframe = nil
local now = 0
local v8 = nil
local tracks = {}
local v9 = nil
local v10 = nil

local function DebugLog(...) end

local flag2 = false
local v11 = nil
local position = nil
local position2 = nil
local now2 = 0
local magnitude = 1
local length = 0
local v12 = nil
local flag3 = false
local flag4 = false

local function getSceneSound(p: string, p2: string)
	local sounds = v4 and v4.Sounds

	if sounds then
		p2 = sounds[p] or p2
	end

	return p2
end

local function getDragSettings() -- 3 equivalent calls inferred from this helper
	return v4 and v4.DragSettings
end

local function isConsoleScene() -- 4 equivalent calls inferred from this helper
	return v4 ~= nil and v4.ConsoleColumnCount ~= nil
end

local function clearConsoleOpeningState() -- 4 equivalent calls inferred from this helper
	if v9 then
		maid:Remove("ConsoleAnimator")
		v9 = nil
	end
end

local function hideMenuFrames()
	MenuState.EnterCaseScene()
	local menuFrame = MenuState.GetMenuFrame()

	if not menuFrame then
		return
	end

	v = MenuSceneController.IsActive()

	if v then
		MenuSceneController.HideMenuScene(true, true)
		MenuSceneController.SetMusicVolumeMultiplier(0.5, 0.5)
	end

	MenuState.SetBlurEnabled(false)
	menuFrame.BackgroundTransparency = 1
	local pattern = menuFrame:FindFirstChild("Pattern")

	if pattern then
		pattern.Visible = false
	end

	local top = menuFrame:FindFirstChild("Top")

	if top then
		top.Visible = false
	end

	local store = menuFrame:FindFirstChild("Store")

	if store then
		store.Visible = true
	end

	for _, frame in menuFrame:GetChildren() do
		if not (frame:IsA("Frame") and frame.Name ~= "Top" and frame.Name ~= "Store" and frame.Name ~= "OpenCase") then
			continue
		end

		frame.Visible = false
	end
end

local function hideViewmodel(folder)
	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Texture") then
			if descendant.Transparency < 1 then
				descendant:SetAttribute("_CaseScenePrevTransparency", descendant.Transparency)
				descendant.Transparency = 1
			end
		elseif descendant:IsA("SurfaceGui") and descendant.Enabled then
			descendant:SetAttribute("_CaseScenePrevSurfaceGuiEnabled", true)
			descendant.Enabled = false
		end
	end

	table.insert(folders, folder)
end

local function hideViewmodels()
	folders = {}
	local assetFolder = v4 and v4.AssetFolder or nil

	for _, model in CurrentCamera:GetChildren() do
		if model:IsA("Model") and model.Name ~= assetFolder then
			hideViewmodel(model)
		end
	end
end

local function showViewmodels()
	for _, folder in folders do
		if not (folder and folder.Parent) then
			continue
		end

		for _, descendant in folder:GetDescendants() do
			if descendant:IsA("BasePart") or descendant:IsA("Texture") then
				local caseScenePrevTransparency = descendant:GetAttribute("_CaseScenePrevTransparency")

				if caseScenePrevTransparency == nil then
					if descendant:IsA("Texture") then
						descendant.Transparency = 0.3
					end
				else
					descendant.Transparency = caseScenePrevTransparency
					descendant:SetAttribute("_CaseScenePrevTransparency", nil)
				end
			elseif
				descendant:IsA("SurfaceGui")
				and descendant:GetAttribute("_CaseScenePrevSurfaceGuiEnabled") ~= nil
			then
				descendant.Enabled = true
				descendant:SetAttribute("_CaseScenePrevSurfaceGuiEnabled", nil)
			end
		end
	end

	folders = {}
end

local function applyCaseFog(instance)
	local caseFog = instance:FindFirstChild("CaseFog", true)

	if not (caseFog and caseFog:IsA("Atmosphere")) then
		return
	end

	for _, atmosphere in Lighting:GetChildren() do
		if atmosphere:IsA("Atmosphere") then
			atmosphere:Destroy()
		end
	end

	local clone = caseFog:Clone()
	clone.Parent = Lighting
end

local function restoreLightingAfterSkippedFrameRestore()
	if workspace:FindFirstChild("Map") then
		MenuSceneController.ApplyMapLighting()
	elseif v then
		MenuSceneController.ApplyMenuSceneLighting()
	end
end

local function restoreMenuFrames()
	local menuFrame = MenuState.GetMenuFrame()

	if menuFrame and menuFrame.Visible then
		local screenBeforeCaseScene = MenuState.GetScreenBeforeCaseScene()
		local v13 = v
		v = false
		MenuState.ExitCaseScene()

		if v13 then
			MenuSceneController.ShowMenuScene()
			MenuSceneController.SetMusicVolumeMultiplier(1, 0.5)
		else
			MenuSceneController.ApplyMapLighting()
		end

		local top = menuFrame:FindFirstChild("Top")

		if top then
			top.Visible = true
		end

		local child = menuFrame:FindFirstChild(screenBeforeCaseScene or "Dashboard")

		if child then
			child.Visible = true
		elseif screenBeforeCaseScene then
			return
		end

		local v14

		if screenBeforeCaseScene == nil or screenBeforeCaseScene == "Dashboard" then
			v14 = false
		else
			v14 = screenBeforeCaseScene ~= "Play"
		end

		MenuState.SetBlurEnabled(v14)
		menuFrame.BackgroundTransparency = v14 and 0.15 or 1
		local pattern = menuFrame:FindFirstChild("Pattern")

		if pattern then
			pattern.Visible = not v14
		end
	else
		v = false
		MenuState.ExitCaseScene()
		MenuSceneController.ApplyMapLighting()
	end
end

local function cleanupCaseModel(instance) -- 2 equivalent calls inferred from this helper
	local caseMod = instance:FindFirstChild("CaseMod")

	if caseMod and caseMod:GetAttribute("IsDynamicModel") then
		caseMod:Destroy()
	end
end

local function setupCaseModel(parent, childName: string)
	cleanupCaseModel(parent) -- inferred equivalent call
	local caseModels = ReplicatedStorage.Assets:FindFirstChild("CaseModels")

	if not caseModels then
		warn("[CaseSceneController]: CaseModels folder not found in ReplicatedStorage.Assets")
		return nil
	end

	local child = caseModels:FindFirstChild(childName)

	if not child then
		warn("[CaseSceneController]: Case model not found for case: " .. childName)
		return nil
	end

	local clone = child:Clone()
	clone.Name = "CaseMod"
	clone:SetAttribute("IsDynamicModel", true)
	local casePivot = parent:FindFirstChild("CasePivot")

	if casePivot then
		clone:PivotTo(casePivot.CFrame)
	else
		warn("[CaseSceneController]: CasePivot not found in CaseScene")
	end

	clone.Parent = parent
	return clone
end

local function getCameraPosition(childName: string?) -- 2 equivalent calls inferred from this helper
	local camera = v2 and v2:FindFirstChild("Camera")

	if camera and (childName == "Inspecting" or childName == "Unboxing") then
		return (camera:FindFirstChild(childName))
	end

	return nil
end

local function startCameraLerp(p, callback) -- 3 equivalent calls inferred from this helper
	local cameraPosition = getCameraPosition(v5) -- inferred equivalent call
	v6 = true
	local v13

	if cameraPosition then
		v13 = cameraPosition.CFrame
	else
		v13 = CurrentCamera.CFrame
	end

	v7 = v13
	cframe = p.CFrame
	now = tick()
	v8 = callback
end

local function ensureAnimator(parent)
	local v13 = parent:FindFirstChildOfClass("Animator")

	if not v13 then
		v13 = Instance.new("Animator")
		v13.Parent = parent
	end

	return v13
end

local function findAnimationController(instance, p)
	local v13 = p.ConsoleColumnCount ~= nil
	local consoleLaptop

	if v13 then
		consoleLaptop = instance:FindFirstChild("ConsoleLaptop", true)
	elseif p.InteractionType == "Drag" then
		consoleLaptop = instance:FindFirstChild("Pack")
	else
		consoleLaptop = instance:FindFirstChild("CaseMod")
	end

	if not consoleLaptop then
		return nil
	end

	local animationController

	if v13 then
		animationController = consoleLaptop:FindFirstChildWhichIsA("AnimationController", true)
	else
		animationController = consoleLaptop:FindFirstChildOfClass("AnimationController")
	end

	local v14

	if animationController then
		v14 = animationController:FindFirstChildOfClass("Animator")

		if not v14 then
			v14 = Instance.new("Animator")
			v14.Parent = animationController
		end
	else
		return animationController
	end

	return v14
end

local function loadAnimations(p, config, instance)
	local animationController

	if config.InteractionType == "Click" then
		animationController = instance and instance:FindFirstChildOfClass("AnimationController")
	else
		animationController = false
	end

	local v13

	if animationController then
		v13 = animationController:FindFirstChildOfClass("Animator")

		if not v13 then
			v13 = Instance.new("Animator")
			v13.Parent = animationController
		end
	else
		v13 = findAnimationController(p, config)
	end

	if not v13 then
		warn("[CaseSceneController]: No animator found for scene")
		return
	end

	for k, animation in config.Animations do
		if not animation then
			continue
		end

		local animation2 = Instance.new("Animation")
		animation2.AnimationId = animation
		tracks[k] = v13:LoadAnimation(animation2)
		animation2:Destroy()
	end
end

local function setEffectsEnabled(folder, enabled: boolean)
	if not folder then
		return
	end

	for _, effect in folder:GetDescendants() do
		if effect:IsA("Beam") or effect:IsA("ParticleEmitter") then
			effect.Enabled = enabled
		end
	end
end

local function setCaseEffects(flag5: boolean, flag6: boolean, flag7: boolean?)
	local caseMod = v2 and v2:FindFirstChild("CaseMod")

	if not caseMod then
		return
	end

	setEffectsEnabled(caseMod:FindFirstChild("IdleEffect"), flag5)
	setEffectsEnabled(caseMod:FindFirstChild("OpeningEffect"), flag6)

	if flag7 ~= nil then
		setEffectsEnabled(caseMod:FindFirstChild("EffectsPart"), flag7)
	end
end

local function getKeyframeSounds(p: string) -- 2 equivalent calls inferred from this helper
	local animationKeyframeSounds = v4 and v4.AnimationKeyframeSounds
	return animationKeyframeSounds and animationKeyframeSounds[p]
end

local function setupKeyframeSounds(object, keyframeSounds)
	for k, item in keyframeSounds do
		local v13 = item
		maid:Add((object:GetMarkerReachedSignal(k):Connect(function()
			Router.broadcastRouter("RunStoreSound", v13)
		end)))
	end
end

local function playConsoleAnimationSound(p: string, p2: string)
	maid:Remove(p2)
	local v13 = Router.broadcastRouter("RunStoreSound", p)

	if not v13 then
		return
	end

	maid:Add(v13, "Destroy", p2)
	v13.Destroying:Once(function()
		maid:RemoveNoClean(p2)
	end)
end

local function freezeAtEnd(object, p: string, p2: string?) -- 2 equivalent calls inferred from this helper
	local connection = nil
	connection = RunServiceController.BindToHeartbeat(RunServiceController.CreateBindingName(p), function()
		if object.Length > 0 and object.TimePosition >= object.Length - 0.05 then
			object:AdjustSpeed(0)
			connection:Disconnect()
		end
	end)
	maid:Add(connection, "Disconnect", p2)
end

local function playInspectAnimations()
	if tracks.CaseFall and (isConsoleScene() or tracks.CloseIdle) then -- inferred equivalent call
		setCaseEffects(true, false, true)
		local caseFall = tracks.CaseFall

		if isConsoleScene() then -- inferred equivalent call
			local sounds = v4 and v4.Sounds
			playConsoleAnimationSound(sounds and sounds.Enter or "Console Enter Animation", "ConsoleEnterSound")
			caseFall:Play()
			freezeAtEnd(caseFall, "CaseSceneController.ConsoleEnterAnimationFreeze", "ConsoleEnterAnimationFreeze") -- inferred equivalent call
		else
			local keyframeSounds = getKeyframeSounds("CaseFall") -- inferred equivalent call

			if keyframeSounds then
				setupKeyframeSounds(caseFall, keyframeSounds)
			else
				local sounds = v4 and v4.Sounds
				local drop = sounds and sounds.Drop or "Case Fall"
				maid:Add((caseFall:GetMarkerReachedSignal("Dropped"):Connect(function()
					Router.broadcastRouter("RunStoreSound", drop)
				end)))
			end

			maid:Add((caseFall:GetMarkerReachedSignal(keyframeSounds and keyframeSounds.Drop and "Drop" or "Dropped"):Connect(function()
				local dropParticle = v2 and v2:FindFirstChild("DropParticle")

				if not dropParticle then
					return
				end

				for _, emitter in dropParticle:GetChildren() do
					if not emitter:IsA("ParticleEmitter") then
						continue
					end

					local emitCount = emitter:GetAttribute("EmitCount")

					if typeof(emitCount) == "number" and emitCount > 0 then
						emitter:Emit(emitCount)
					end
				end
			end)))
			caseFall:Play()
			tracks.CloseIdle.Looped = true
			tracks.CloseIdle:Play()
		end
	end
end

local function playOpeningAnimations()
	if not tracks.CaseOpening then
		return
	end

	if tracks.CloseIdle then
		tracks.CloseIdle:Stop()
	end

	local caseOpening = tracks.CaseOpening

	if isConsoleScene() then -- inferred equivalent call
		maid:Remove("ConsoleEnterSound")
		local sounds = v4 and v4.Sounds
		playConsoleAnimationSound(sounds and sounds.Opening or "Console Open Animation", "ConsoleOpenSound")
		local caseMod = v2 and v2:FindFirstChild("CaseMod")

		if caseMod then
			setEffectsEnabled(caseMod:FindFirstChild("IdleEffect"), false)
			setEffectsEnabled(caseMod:FindFirstChild("OpeningEffect"), true)
		end

		caseOpening:Play(0.1, 1, 1)
		freezeAtEnd(caseOpening, "CaseSceneController.ConsoleAnimationFreeze", nil) -- inferred equivalent call
	else
		local keyframeSounds = getKeyframeSounds("CaseOpening") -- inferred equivalent call

		if keyframeSounds then
			setupKeyframeSounds(caseOpening, keyframeSounds)
		else
			local broadcastRouter = Router.broadcastRouter
			local sounds = v4 and v4.Sounds
			broadcastRouter("RunStoreSound", sounds and sounds.Opening or "Case Opening")
		end

		local caseMod = v2 and v2:FindFirstChild("CaseMod")

		if caseMod then
			setEffectsEnabled(caseMod:FindFirstChild("IdleEffect"), false)
			setEffectsEnabled(caseMod:FindFirstChild("OpeningEffect"), true)
		end

		caseOpening:Play()

		if tracks.OpenIdle then
			tracks.OpenIdle.Looped = true
			tracks.OpenIdle:Play()
		end
	end
end

local function stopAllAnimations()
	for _, v13 in tracks do
		if v13.IsPlaying then
			v13:Stop()
		end
	end

	if v10 then
		v10:Stop()
		v10:Destroy()
		v10 = nil
	end
end

local function runCharmDragCallback() -- 2 equivalent calls inferred from this helper
	local v13 = v11

	if v13 then
		v11 = nil
		v13()
	end
end

local function finishCharmOpeningAndStartRoll()
	DebugLog("finishCharmOpeningAndStartRoll called")

	if v10 then
		v10:Stop()
	end

	position2 = nil

	if v12 then
		v12.Enabled = false
	end

	local cameraPerspective = mainGui:FindFirstChild("CameraPerspective")

	if cameraPerspective then
		cameraPerspective.Interactable = true
	end

	local packOpening = tracks.PackOpening
	DebugLog("  packOpeningTrack:", packOpening and "exists" or "nil")
	DebugLog("  CharmDragCallback:", v11 and "exists" or "nil")

	if packOpening then
		local broadcastRouter = Router.broadcastRouter
		local sounds = v4 and v4.Sounds
		broadcastRouter("RunStoreSound", sounds and sounds.DragLoop or "Charm Drag Loop")

		if not packOpening.IsPlaying then
			packOpening:Play()
		end

		packOpening:AdjustSpeed(1)
		packOpening.Looped = false
		local v13 = math.max(0, packOpening.Length - packOpening.TimePosition - 0.1)
		task.delay(v13, function()
			if not packOpening.IsPlaying then
				return
			end

			packOpening:AdjustSpeed(0)
			packOpening.TimePosition = packOpening.Length * 0.99
			runCharmDragCallback() -- inferred equivalent call
		end)
	else
		DebugLog("  No packOpeningTrack, calling callback directly")

		if v11 then
			DebugLog("  Calling CharmDragCallback")
		end

		runCharmDragCallback() -- inferred equivalent call
	end
end

local function updateCharmAnimationProgress(value: number, position3: Vector3?)
	local packOpening = tracks.PackOpening

	if not packOpening then
		return
	end

	local v13 = math.clamp(value, 0, 1)
	local length2

	if length > 0 then
		length2 = length
	else
		length2 = packOpening.Length
	end

	if not packOpening.IsPlaying then
		packOpening:Play()
		packOpening:AdjustSpeed(0)
	end

	packOpening.TimePosition = length2 * v13

	if v13 >= 1 then
		flag2 = false
		finishCharmOpeningAndStartRoll()
	end

	if v10 and position3 then
		local v14 = not position2 and 0 or (position3 - position2).Magnitude
		position2 = position3

		if v14 > 0.001 then
			now2 = tick()

			if not v10.IsPlaying then
				v10:Play()
			end

			v10.PlaybackSpeed = math.clamp(v14 * 20, 0, 0.7) + 0.8
		end
	end
end

local function setupCharmDragDetector(callback)
	if not v2 then
		return
	end

	local pack = v2:FindFirstChild("Pack")

	if not pack then
		warn("[CaseSceneController]: Pack not found in CharmScene")
		return
	end

	local drag = pack:FindFirstChild("Drag")

	if not drag then
		warn("[CaseSceneController]: Drag part not found in Pack")
		return
	end

	local dragDetector = drag:FindFirstChildOfClass("DragDetector")

	if not dragDetector then
		warn("[CaseSceneController]: DragDetector not found on Drag part")
		return
	end

	ContextActionService:UnbindAction("Fire")
	ContextActionService:UnbindAction("Secondary Fire")
	flag3 = true
	v11 = callback
	flag2 = false
	position = drag.Position
	magnitude = dragDetector.MaxDragTranslation.Magnitude

	if magnitude <= 0 then
		magnitude = 1
	end

	local packOpening = tracks.PackOpening

	if packOpening then
		local dragSettings = getDragSettings() -- inferred equivalent call
		local endKeyframe = dragSettings and dragSettings.EndKeyframe or "DragEndPoint"
		local success, result = pcall(function()
			return packOpening:GetTimeOfKeyframe(endKeyframe)
		end)

		if success and result then
			length = result
		else
			length = packOpening.Length
			warn("[CaseSceneController]: " .. endKeyframe .. " keyframe not found, using full animation length")
		end
	end

	dragDetector.Enabled = true
	local cameraPerspective = mainGui:FindFirstChild("CameraPerspective")

	if cameraPerspective then
		cameraPerspective.Interactable = false
	end

	local surfaceGui = drag:FindFirstChildOfClass("SurfaceGui")

	if surfaceGui then
		surfaceGui.Enabled = true
		v12 = surfaceGui
		local frame = surfaceGui:FindFirstChildOfClass("Frame")
		local imageLabel = frame and frame:FindFirstChildOfClass("ImageLabel")

		if frame and imageLabel then
			maid:Add(frame.MouseEnter:Connect(function()
				flag4 = true
				imageLabel.ImageTransparency = 1
			end), "Disconnect", "CharmImageHoverEnter")
			maid:Add(frame.MouseLeave:Connect(function()
				flag4 = false
				imageLabel.ImageTransparency = 0
			end), "Disconnect", "CharmImageHoverLeave")
			local total = 0
			maid:Add(RunServiceController.BindToRenderStep("CaseSceneController.CharmImageBreathing", function(p)
				if flag4 then
					return
				end

				total += p * 2
				imageLabel.ImageTransparency = (math.sin(total) + 1) / 2 * 0.2
			end), "Disconnect", "CharmImageBreathing")
		end
	end

	maid:Add(dragDetector.DragStart:Connect(function()
		flag2 = true
		position2 = drag.Position
		now2 = tick()

		if not v10 then
			local Store = require(ReplicatedStorage.Database.Audio.Store)
			local sounds = v4 and v4.Sounds
			local v13 = Store[sounds and sounds.DragStart or "Charm Drag Start"]

			if v13 and v13.Identifiers and v13.Identifiers[1] then
				local sound = Instance.new("Sound")
				sound.Name = "DragProgress"
				sound.SoundId = "rbxassetid://" .. v13.Identifiers[1]
				sound.Volume = v13.Properties.Volume or 1
				sound.Looped = true
				sound.PlaybackSpeed = 0.8
				sound.Parent = pack
				v10 = sound
				maid:Add(sound, "Destroy")
			end
		end
	end), "Disconnect", "CharmDragStart")
	maid:Add(RunServiceController.BindToHeartbeat("CaseSceneController.CharmDragSoundCheck", function()
		if flag2 and v10 and v10.IsPlaying and tick() - now2 > 0.05 then
			v10:Stop()
		end
	end), "Disconnect", "CharmDragSoundCheck")
	maid:Add(dragDetector.DragContinue:Connect(function()
		if not (flag2 and position) then
			return
		end

		local v13 = math.clamp((drag.Position - position).Magnitude / magnitude, 0, 1)
		local dragSettings = getDragSettings() -- inferred equivalent call

		if not ((dragSettings and dragSettings.Threshold or 0.5) <= v13) then
			updateCharmAnimationProgress(v13, drag.Position)
			return
		end

		flag2 = false
		dragDetector.Enabled = false
		drag.Position = position
		finishCharmOpeningAndStartRoll()
	end), "Disconnect", "CharmDragContinue")
	maid:Add(dragDetector.DragEnd:Connect(function()
		if not (flag2 and position) then
			return
		end

		flag2 = false

		if v10 then
			v10:Stop()
		end

		local v13 = math.clamp((drag.Position - position).Magnitude / magnitude, 0, 1)
		drag.Position = position
		local dragSettings = getDragSettings() -- inferred equivalent call

		if math.max(dragSettings and dragSettings.Threshold or 0.8, 0.8) <= v13 then
			dragDetector.Enabled = false
			finishCharmOpeningAndStartRoll()
		else
			if tracks.PackOpening then
				tracks.PackOpening.TimePosition = 0
			end

			position2 = nil
		end
	end), "Disconnect", "CharmDragEnd")
	maid:Add(UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not flag or v5 ~= "Unboxing" then
			return
		end

		local v13 = input.UserInputType == Enum.UserInputType.Gamepad1
		local v14 = input.UserInputType == Enum.UserInputType.Keyboard

		if v14 and gameProcessed then
			return
		end

		local v15 = v13 and (input.KeyCode == Enum.KeyCode.ButtonX or input.KeyCode == Enum.KeyCode.ButtonA)
		local v16 = v14 and (input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space)

		if not (v15 or v16) then
			return
		end

		dragDetector.Enabled = false

		if flag2 then
			flag2 = false

			if position then
				drag.Position = position
			end
		end

		if v10 then
			v10:Stop()
		end

		local broadcastRouter = Router.broadcastRouter
		local sounds = v4 and v4.Sounds
		broadcastRouter("RunStoreSound", sounds and sounds.DragStart or "Charm Drag Start")
		finishCharmOpeningAndStartRoll()
	end), "Disconnect", "CharmControllerSkip")
end

local function rearmCharmDrag(callback) -- 2 equivalent calls inferred from this helper
	local packOpening = tracks.PackOpening

	if packOpening and packOpening.IsPlaying then
		packOpening:Stop()
	end

	setupCharmDragDetector(callback)
end

local function cleanupCharmDrag() -- 1 equivalent call inferred from this helper
	if flag3 then
		Router.broadcastRouter("RebindKeybinds")
		flag3 = false
	end

	flag2 = false
	v11 = nil
	position = nil
	position2 = nil
	now2 = 0
	magnitude = 1
	length = 0
	v12 = nil
	flag4 = false
end

function CaseSceneController.ShowCaseScene(value: string?, value2: string?)
	DebugLog("ShowCaseScene called")
	DebugLog("  caseType:", value or "nil")
	DebugLog("  caseName:", value2 or "nil")
	DebugLog("  IsCaseSceneActive:", flag)

	if flag then
		DebugLog("  BLOCKED: Scene already active")
		return
	end

	local getSceneForCase = SceneRegistry.GetSceneForCase
	local v13

	if value2 then
		v13 = Cases.GetCaseByName(value2)
	end

	local sceneForCase = getSceneForCase(value or "Case", v13)
	DebugLog("  sceneName:", sceneForCase)
	local config = SceneRegistry.GetConfig(sceneForCase)

	if config then
		DebugLog("  config.AssetFolder:", config.AssetFolder)
		DebugLog("  config.InteractionType:", config.InteractionType)
		local parent = clonesByAssetFolder[config.AssetFolder]

		if not parent then
			warn("[CaseSceneController]: Scene was never staged: " .. config.AssetFolder)
			return
		end

		SceneParking.Unpark(parent)
		v3 = sceneForCase
		v4 = config
		v2 = parent

		if config.InteractionType == "Drag" then
			local pack = parent:FindFirstChild("Pack")
			local drag = pack and pack:FindFirstChild("Drag")
			local surfaceGui = drag and drag:FindFirstChildOfClass("SurfaceGui")

			if surfaceGui then
				surfaceGui.Enabled = false
			end
		end

		v5 = "Inspecting"
		local camera = v2 and v2:FindFirstChild("Camera")
		local inspecting

		if camera then
			inspecting = camera:FindFirstChild("Inspecting")
		end

		if inspecting then
			CurrentCamera.CameraType = Enum.CameraType.Scriptable
			CurrentCamera.CFrame = inspecting.CFrame
			CurrentCamera.Focus = inspecting.CFrame
			hideMenuFrames()

			if not v then
				MenuSceneController.ApplyMenuSceneLighting()
			end

			applyCaseFog(parent)
			hideViewmodels()
			maid:Add(CurrentCamera.ChildAdded:Connect(function(model)
				if model:IsA("Model") and model.Name ~= config.AssetFolder then
					hideViewmodel(model)
				end
			end), "Disconnect", "ViewmodelListener")
			local v14 = nil

			if value2 and config.InteractionType == "Click" and not isConsoleScene() then -- inferred equivalent call
				v14 = setupCaseModel(parent, value2)
			end

			loadAnimations(parent, config, v14)

			if config.InteractionType == "Click" then
				playInspectAnimations()
			end

			CameraController.setFOVLock("CaseScene", true, 50)
			CameraController.setForceLockOverride("CaseScene", true)
			local v15 = Enum.RenderPriority.Camera.Value + 10
			RunServiceController.BindToRenderStep("CaseSceneController.CameraUpdate", v15, function()
				if not v2 then
					return
				end

				CurrentCamera.CameraType = Enum.CameraType.Scriptable

				if v6 and v7 and cframe then
					local v16 = math.min((tick() - now) / 0.8, 1)
					local value3 = TweenService:GetValue(v16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
					CurrentCamera.CFrame = v7:Lerp(cframe, value3)
					CurrentCamera.Focus = CurrentCamera.CFrame

					if v16 >= 1 then
						v6 = false
						CurrentCamera.CFrame = cframe

						if v8 then
							local v17 = v8
							v8 = nil
							v17()
						end

						v7 = nil
						cframe = nil
					end
				else
					local cameraPosition = getCameraPosition(v5) -- inferred equivalent call

					if cameraPosition then
						CurrentCamera.CFrame = cameraPosition.CFrame
						CurrentCamera.Focus = cameraPosition.CFrame
					end
				end
			end)
			maid:Add(function()
				RunServiceController.UnbindFromRenderStep("CaseSceneController.CameraUpdate")
			end, true, "CameraUpdate")
			maid:Add(function()
				DebugLog("CaseSceneCleanup running")
				v5 = nil
				v6 = false
				v7 = nil
				cframe = nil
				v8 = nil
				setCaseEffects(false, false, false)
				cleanupCharmDrag() -- inferred equivalent call

				if v2 then
					cleanupCaseModel(v2) -- inferred equivalent call
				end

				stopAllAnimations()
				tracks = {}
				DebugLog("CaseSceneCleanup complete")
			end, true, "CaseSceneCleanup")
			flag = true
			DebugLog("ShowCaseScene complete, IsCaseSceneActive = true")
		else
			warn("[CaseSceneController]: Scene missing Camera.Inspecting")
			SceneParking.Park(parent)
			v2 = nil
			v3 = nil
			v4 = nil
			v5 = nil
		end
	else
		warn("[CaseSceneController]: No config found for scene: " .. sceneForCase)
		DebugLog("  BLOCKED: No config found")
	end
end

function CaseSceneController.TransitionToUnboxing(callback)
	DebugLog("TransitionToUnboxing called")
	DebugLog("  IsCaseSceneActive:", flag)
	DebugLog("  CurrentScene:", v2 and "exists" or "nil")
	DebugLog("  CurrentSceneConfig:", v4 and "exists" or "nil")
	DebugLog("  CurrentCaseSceneState:", v5 or "nil")
	DebugLog("  callback:", callback and "provided" or "nil")

	if not (flag and v2 and v4) then
		DebugLog("  BLOCKED: Scene not active or missing config")
		return
	end

	if v5 == "Unboxing" then
		DebugLog("  BLOCKED: Already in Unboxing state")
		return
	end

	local camera = v2 and v2:FindFirstChild("Camera")
	local unboxing

	if camera then
		unboxing = camera:FindFirstChild("Unboxing")
	end

	if unboxing then
		DebugLog("  InteractionType:", v4.InteractionType)

		if v4.InteractionType == "Click" then
			DebugLog("  Playing opening animations and starting camera lerp")
			playOpeningAnimations()
			startCameraLerp(unboxing, callback) -- inferred equivalent call
		else
			DebugLog("  Starting camera lerp, will setup drag detector after")

			local function fn()
				DebugLog("  Camera lerp complete, setting up drag detector")
				setupCharmDragDetector(callback)
			end

			startCameraLerp(unboxing, fn) -- inferred equivalent call
		end

		v5 = "Unboxing"
		DebugLog("  TransitionToUnboxing complete, CurrentCaseSceneState = Unboxing")
	else
		warn("[CaseSceneController]: Scene missing Camera.Unboxing")
		DebugLog("  BLOCKED: Missing Camera.Unboxing")
	end
end

function CaseSceneController.TransitionToInspecting(callback)
	if not (flag and v2 and v5 ~= "Inspecting") then
		return
	end

	local camera = v2 and v2:FindFirstChild("Camera")
	local inspecting

	if camera then
		inspecting = camera:FindFirstChild("Inspecting")
	end

	if not inspecting then
		warn("[CaseSceneController]: Scene missing Camera.Inspecting")
		return
	end

	startCameraLerp(inspecting, callback) -- inferred equivalent call
	v5 = "Inspecting"
end

function CaseSceneController.BeginConsoleOpening()
	local v13 = v9

	if v13 then
		v13:PlayReset()

		if v9 ~= v13 then
			return
		end
	end

	clearConsoleOpeningState() -- inferred equivalent call
	local v14 = v4
	local v15 = ConsoleBoardAnimator.new(v2, v14.ConsoleColumnCount)
	maid:Add(v15, "Cancel", "ConsoleAnimator")
	v9 = v15
	v15:Start()
	RunService.RenderStepped:Wait()
	local caseFall = tracks.CaseFall
	maid:Remove("ConsoleEnterAnimationFreeze")

	if caseFall and caseFall.IsPlaying then
		caseFall:Stop(0.1)
	end

	maid:Remove("ConsoleEnterSound")

	local function setSceneReady()
		if v9 == v15 then
			v15:SetSceneReady()
		end
	end

	if v5 ~= "Unboxing" then
		CaseSceneController.TransitionToUnboxing(setSceneReady)
		return
	end

	if not v4 or v4.InteractionType ~= "Drag" then
		v15:SetSceneReady()
		return
	end

	rearmCharmDrag(setSceneReady) -- inferred equivalent call
end

local v13 = {
	Special = "Drop Gold",
	Red = "Drop Red",
	Pink = "Drop Pink",
	Purple = "Drop Purple",
	Blue = "Drop Blue"
}

local function getRollerItem(data)
	local skinInformation = Skins.GetSkinInformation(data.skin.weaponName, data.skin.skinName)
	local assetId

	if skinInformation then
		if skinInformation.wearImages and skinInformation.wearImages[1] then
			assetId = skinInformation.wearImages[1].assetId
		elseif skinInformation.charmImages and skinInformation.charmImages[1] then
			assetId = skinInformation.charmImages[1].assetId
		else
			assetId = skinInformation.imageAssetId or ""
		end
	else
		assetId = ""
	end

	return {
		Image = assetId,
		Color = (Rarities[data.isSpecial and "Special" or data.rarity] or Rarities.Stock).Color
	}
end

local function isConsoleRarity(p, p2)
	if p2 == "Special" then
		return p.isSpecial or p.rarity == "Special"
	end

	return p.rarity == p2 and not p.isSpecial
end

local function findGrantedContent(data, p, p2)
	local name

	if p2 then
		name = string.lower((tostring(p2.Name)))
	end

	local skin

	if p2 then
		skin = string.lower((tostring(p2.Skin)))
	end

	local v14 = nil

	for _, v15 in { p.contents, p.specialContents or {} } do
		for _, v16 in v15 do
			if data.grantedSkinId ~= nil and v16.skinId == data.grantedSkinId then
				return v16
			end

			if v14 or string.lower(v16.skin.weaponName) ~= name or string.lower(v16.skin.skinName) ~= skin then
				continue
			end

			v14 = v16
		end
	end

	return v14
end

local function getConsoleRarity(p) -- 2 equivalent calls inferred from this helper
	if p.isSpecial or p.rarity == "Special" then
		return "Special"
	end

	return p.rarity
end

local function buildRollerPlan(p, p2)
	if not (p and p2) then
		return nil
	end

	local consoleRarity = getConsoleRarity(p) -- inferred equivalent call
	local v14 = {}
	local v15 = {}

	for _, v16 in { p2.contents, p2.specialContents or {} } do
		for _, v17 in v16 do
			local formatted = `{v17.skin.weaponName}|{v17.skin.skinName}`
			local isSpecial

			if consoleRarity == "Special" then
				isSpecial = v17.isSpecial or v17.rarity == "Special"
			elseif v17.rarity == consoleRarity then
				isSpecial = not v17.isSpecial
			else
				isSpecial = false
			end

			if not isSpecial or v14[formatted] then
				continue
			end

			v14[formatted] = true
			table.insert(v15, v17)
		end
	end

	if #v15 < 2 then
		return nil
	end

	local rollerItems = {}
	local winner = nil

	for _, v16 in v15 do
		local rollerItem = getRollerItem(v16)
		table.insert(rollerItems, rollerItem)

		if v16 == p then
			winner = rollerItem
		end
	end

	if winner then
		return { Pool = rollerItems, Winner = winner, LandingSound = v13[consoleRarity] }
	end

	return nil
end

function CaseSceneController.ResolveConsoleOpening(data, callback, p, p2)
	local v14 = v9

	if not v14 then
		return false
	end

	local v15

	if data.finalColumnIndex < v14.ColumnCount then
		v15 = data.columnCount == nil or data.columnCount == v14.ColumnCount
	else
		v15 = false
	end

	for _, v16 in data.path do
		if v16.columnIndex >= v14.ColumnCount then
			v15 = false
		end
	end

	if v15 then
		local v16

		if p then
			v16 = findGrantedContent(data, p, p2)
		end

		local rollerPlan = buildRollerPlan(v16, p)
		local v17

		if v16 then
			v17 = getConsoleRarity(v16) -- inferred equivalent call
		end

		v14:Resolve(data, callback, rollerPlan, v17)
		return true
	else
		warn(`[CaseSceneController]: Console outcome doesn't fit the {v14.ColumnCount}-column board (columnCount {data.columnCount})`)
		clearConsoleOpeningState() -- inferred equivalent call
		return false
	end
end

function CaseSceneController.SkipConsoleOpening()
	if v9 then
		v9:Skip()
	end
end

function CaseSceneController.CancelConsoleOpening()
	clearConsoleOpeningState() -- inferred equivalent call
	maid:Remove("ConsoleOpenSound")
	local caseOpening = tracks.CaseOpening

	if caseOpening and caseOpening.IsPlaying then
		caseOpening:Stop(0.1)
	end

	if v5 == "Unboxing" then
		CaseSceneController.TransitionToInspecting()
	end
end

function CaseSceneController.IsConsoleOpening()
	return v9 ~= nil
end

function CaseSceneController.ArmDragOpening(callback)
	if not flag or not v2 or not v4 or v4.InteractionType ~= "Drag" or v5 ~= "Unboxing" then
		return false
	end

	rearmCharmDrag(callback) -- inferred equivalent call
	return true
end

function CaseSceneController.HideCaseScene(flag5: boolean?)
	DebugLog("HideCaseScene called")
	DebugLog("  IsCaseSceneActive:", flag)
	DebugLog("  skipFrameRestore:", flag5 or false)

	if not flag then
		DebugLog("  BLOCKED: Scene not active")
		return
	end

	clearConsoleOpeningState() -- inferred equivalent call
	DebugLog("  Running CaseSceneJanitor:Cleanup()")
	maid:Cleanup()
	CurrentCamera.CameraType = Enum.CameraType.Custom
	CameraController.setFOVLock("CaseScene", false)
	CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
	local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

	if currentSpectateInstance then
		currentSpectateInstance:UpdateScopeState()
	end

	CameraController.setForceLockOverride("CaseScene", false)

	if flag5 then
		if workspace:FindFirstChild("Map") then
			MenuSceneController.ApplyMapLighting()
		elseif v then
			MenuSceneController.ApplyMenuSceneLighting()
		end

		MenuState.ExitCaseScene()
		v = false
	else
		restoreMenuFrames()
	end

	showViewmodels()

	if v2 then
		SceneParking.Park(v2)
	end

	v2 = nil
	v3 = nil
	v4 = nil
	flag = false
	v5 = nil
	DebugLog("HideCaseScene complete, IsCaseSceneActive = false")
end

function CaseSceneController.IsActive()
	return flag
end

function CaseSceneController.ApplyCaseSceneLighting()
	if flag and v2 then
		MenuSceneController.ApplyMenuSceneLighting()
		applyCaseFog(v2)
	end
end

function CaseSceneController.WaitForOpeningAnimation()
	local caseOpening = tracks.CaseOpening

	if caseOpening and caseOpening.IsPlaying then
		caseOpening.Stopped:Wait()
	end
end

function CaseSceneController.Initialize()
	local assets = ReplicatedStorage:FindFirstChild("Assets")

	if not assets then
		warn("[CaseSceneController]: Assets folder not found in ReplicatedStorage")
		return
	end

	for _, v14 in SceneRegistry.GetAllSceneNames() do
		local config = SceneRegistry.GetConfig(v14)
		local child = config and assets:FindFirstChild(config.AssetFolder)

		if not (config and child) then
			continue
		end

		local model = child:FindFirstChildWhichIsA("Model")

		if model then
			local clone = model:Clone()
			clone.Name = config.AssetFolder
			clonesByAssetFolder[config.AssetFolder] = clone
			SceneParking.Park(clone)
		else
			warn("[CaseSceneController]: No model found in Assets." .. config.AssetFolder)
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.KeyCode ~= Enum.KeyCode.Escape or not flag then
			return
		end

		if CaseSceneController.IsConsoleOpening() then
			CaseSceneController.SkipConsoleOpening()
		else
			CaseSceneController.HideCaseScene()
		end
	end)
	Router.observerRouter("CaseSceneCloseForGameEnd", function()
		CaseSceneController.HideCaseScene(true)
	end)
end

function CaseSceneController.Start() end

Router.observerRouter("IsCaseSceneRolling", function()
	return flag and v5 == "Unboxing"
end)
return CaseSceneController