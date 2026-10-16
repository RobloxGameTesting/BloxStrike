local createVector = vector.create
local BlackMarketSceneController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local BakedViewmodelMirror = require(ReplicatedStorage.Shared.BakedViewmodelMirror)
local SceneParking = require(ReplicatedStorage.Components.Common.SceneParking)
local Signal = require(ReplicatedStorage.Packages.Signal)
BlackMarketSceneController.OnActiveChanged = Signal.new()
local Router = require(ReplicatedStorage.Database.Security.Router)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local DealerLines = require(script.DealerLines)
local v = Enum.RenderPriority.Camera.Value + 10
local Sine = Enum.EasingStyle.Sine
local random = Random.new()
local Cubic = Enum.EasingStyle.Cubic
local Back = Enum.EasingStyle.Back
local v2 = {
	Ambient = Color3.fromRGB(68, 68, 68),
	OutdoorAmbient = Color3.fromRGB(120, 128, 143),
	ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
	ColorShift_Top = Color3.fromRGB(208, 168, 108),
	Brightness = 4.5,
	EnvironmentDiffuseScale = 1,
	EnvironmentSpecularScale = 1,
	GlobalShadows = true,
	ShadowSoftness = 0.06,
	ClockTime = 9.8,
	GeographicLatitude = 50,
	ExposureCompensation = 0,
	FogStart = 100000,
	FogEnd = 100000
}
local CurrentCamera = workspace.CurrentCamera
local v3 = nil
local parts = {}
local v4 = {}
local v5 = {}
local v6 = {}
local v7 = {}
local cframes = {}
local sizes = {}
local pixelsPerStudsBySurfaceGui = {}
local v8 = nil
local position = nil
local v9 = 1
local v10 = {}
local v11 = {}
local v12 = false
local v13 = false
local maid = Janitor.new()
local flag = false
local v14 = false
local v15 = false
local v16 = {}
local v17 = true
local count = 0
local v18 = nil
local tracks = {}
local v19 = nil
local v20 = nil
local v21 = nil
local v22 = nil
local cframe = nil
local v23 = nil
local v24 = nil
local now = 0

local function applySceneLighting()
	for k, v25 in v2 do
		Lighting[k] = v25
	end

	for _, child in Lighting:GetChildren() do
		if child.Name ~= "Menu" then
			child:Destroy()
		end
	end
end

local function setPerspectiveSinksInput(flag2: boolean)
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
	local cameraPerspective = mainGui and mainGui:FindFirstChild("CameraPerspective")

	if cameraPerspective and cameraPerspective:IsA("GuiButton") then
		cameraPerspective.Active = flag2
		cameraPerspective.Interactable = flag2
		return true
	else
		warn("[BlackMarketSceneController]: MainGui.CameraPerspective was not found, card clicks may be swallowed")
		return false
	end
end

local localTransparencyModifiersByInstance = {}
local instances = {}

local function hideInstance(instance)
	if instance:IsA("BasePart") or instance:IsA("Decal") then
		if localTransparencyModifiersByInstance[instance] == nil then
			localTransparencyModifiersByInstance[instance] = instance.LocalTransparencyModifier
		end

		instance.LocalTransparencyModifier = 1
	elseif instance:IsA("SurfaceGui") and instance.Enabled then
		instance.Enabled = false
		table.insert(instances, instance)
	end
end

local function hideViewmodel(folder) -- 2 equivalent calls inferred from this helper
	hideInstance(folder)

	for _, descendant in folder:GetDescendants() do
		hideInstance(descendant)
	end
end

local function showViewmodels()
	for k, localTransparencyModifier in localTransparencyModifiersByInstance do
		if k.Parent then
			k.LocalTransparencyModifier = localTransparencyModifier
		end
	end

	table.clear(localTransparencyModifiersByInstance)

	for _, v25 in instances do
		if v25.Parent then
			v25.Enabled = true
		end
	end

	table.clear(instances)
end

local function isCameraAttachment(child) -- 2 equivalent calls inferred from this helper
	return child:IsA("Model") or child:IsA("BasePart")
end

local function applyCardVisibility(instance, enabled: boolean)
	for _, surfaceGui in instance:GetChildren() do
		if surfaceGui:IsA("SurfaceGui") then
			surfaceGui.Enabled = enabled
		end
	end
end

local function isCardShown(p) -- 1 equivalent call inferred from this helper
	return v11[p] == true and not (v12 or v13) and (not (v14 or v15) or v16[p] == true)
end

local function refreshCardFaces(p) -- 5 equivalent calls inferred from this helper
	applyCardVisibility(p, isCardShown(p)) -- inferred equivalent call
end

local function syncCardVisibility() -- 8 equivalent calls inferred from this helper
	for _, v25 in parts do
		refreshCardFaces(v25) -- inferred equivalent call
	end
end

local function getMarker(childName: string) -- 6 equivalent calls inferred from this helper
	local camera = v3 and v3:FindFirstChild("Camera")
	local part = camera and camera:FindFirstChild(childName)

	if not (part and part:IsA("BasePart") and part) then
		part = nil
	end

	return part
end

local function moveCameraTo(childName: string)
	local marker = getMarker(childName) -- inferred equivalent call

	if not marker then
		warn(`[BlackMarketSceneController]: scene is missing Camera.{childName}`)
		return
	end

	cframe = marker.CFrame
	v23 = nil
	v24 = nil
end

local function startIntroArc() -- 2 equivalent calls inferred from this helper
	local v25 = cframe

	if not v25 then
		return
	end

	v23 = -v25.LookVector * 6
	v24 = createVector(0, 4, 0)
	now = os.clock()
end

local v25 = {
	face = "TopMost",
	["Cube.002"] = "Tie",
	["Cube.012"] = "UpperBody.001",
	UpperTorso = "UpperBody.001",
	["Cube.003"] = "UpperLeg.L"
}

local function attachUnskinnedParts(parent)
	for childName, childName2 in v25 do
		local part = parent:FindFirstChild(childName)
		local bone = parent:FindFirstChild(childName2, true)

		if not (part and part:IsA("MeshPart") and bone and bone:IsA("Bone")) then
			continue
		end

		if part.HasSkinnedMesh then
			continue
		end

		for _, motor6D in part:GetChildren() do
			if motor6D:IsA("Motor6D") and motor6D.Part1 == part then
				motor6D.Enabled = false
			end
		end

		local attachment = Instance.new("Attachment")
		attachment.Name = "BoneFollow"
		attachment.CFrame = part.CFrame:ToObjectSpace(bone.WorldCFrame)
		attachment.Parent = part
		local rigidConstraint = Instance.new("RigidConstraint")
		rigidConstraint.Name = "BoneFollow"
		rigidConstraint.Attachment0 = attachment
		rigidConstraint.Attachment1 = bone
		rigidConstraint.Parent = part
		part.Anchored = false
	end
end

local function bindDealer(clone) -- 1 equivalent call inferred from this helper
	local animationController = clone:FindFirstChildWhichIsA("AnimationController", true)
	local animator = animationController and animationController:FindFirstChildOfClass("Animator")

	if not animator then
		warn("[BlackMarketSceneController]: the scene's dealer has no Animator, so he will not move")
		return
	end

	v18 = animator
	attachUnskinnedParts(animationController.Parent)
end

local function getDealerTrack(animationId: string)
	local animator = v18

	if not animator then
		return nil
	end

	local v26 = tracks[animationId]

	if v26 then
		return v26
	end

	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	local track = animator:LoadAnimation(animation)
	tracks[animationId] = track
	return track
end

local function startDealerIdle() -- 1 equivalent call inferred from this helper
	local IDLE_ANIMATION = DealerLines.IDLE_ANIMATION
	local animator = v18
	local track

	if animator then
		track = tracks[IDLE_ANIMATION]

		if not track then
			local animation = Instance.new("Animation")
			animation.AnimationId = IDLE_ANIMATION
			track = animator:LoadAnimation(animation)
			tracks[IDLE_ANIMATION] = track
		end
	end

	if not track then
		return
	end

	track.Looped = true
	track.Priority = Enum.AnimationPriority.Idle

	if not track.IsPlaying then
		track:Play(0.15)
	end

	v19 = track
end

local function stopDealerBody() -- 3 equivalent calls inferred from this helper
	local v26 = v22
	v22 = nil

	if v26 and v26.IsPlaying then
		v26:Stop(0.15)
	end
end

local function playDealerBody(INTRO_ANIMATION: string) -- 2 equivalent calls inferred from this helper
	local animator = v18
	local track

	if animator then
		track = tracks[INTRO_ANIMATION]

		if not track then
			local animation = Instance.new("Animation")
			animation.AnimationId = INTRO_ANIMATION
			track = animator:LoadAnimation(animation)
			tracks[INTRO_ANIMATION] = track
		end
	end

	if not track then
		return
	end

	stopDealerBody() -- inferred equivalent call
	track.Looped = false
	track.Priority = Enum.AnimationPriority.Movement
	track:Stop(0)
	track:Play(0.15)
	v22 = track
end

local function stopCurrentLine()
	local v26 = v21
	v21 = nil

	if v26 and v26.Parent then
		v26:Stop()

		if v26:GetAttribute("Persistent") ~= true then
			v26:Destroy()
		end
	end

	local v27 = v20
	v20 = nil

	if v27 and v27.IsPlaying then
		v27:Stop(0.15)
	end
end

local function stopDealer() -- 1 equivalent call inferred from this helper
	stopCurrentLine()
	stopDealerBody() -- inferred equivalent call

	if v19 then
		v19:Stop(0.15)
		v19 = nil
	end
end

local function playDealerLine(p)
	local v26 = DealerLines.Pick(p)

	if not v26 then
		return nil
	end

	stopCurrentLine()
	stopDealerBody() -- inferred equivalent call
	local sound = Router.broadcastRouter("RunArmsDealerSound", v26.Sound)

	if typeof(sound) == "Instance" and sound:IsA("Sound") then
		v21 = sound
	end

	local animation = v26.Animation
	local animator = v18
	local track

	if animator then
		track = tracks[animation]

		if not track then
			local animation2 = Instance.new("Animation")
			animation2.AnimationId = animation
			track = animator:LoadAnimation(animation2)
			tracks[animation] = track
		end
	end

	if not track then
		return v21
	end

	track.Looped = false
	track.Priority = Enum.AnimationPriority.Action
	track:Stop(0)
	track:Play(0.15)
	v20 = track
	return v21
end

local function getSettledPose(p) -- 3 equivalent calls inferred from this helper
	local v26 = v4[p]

	if not v26 then
		return nil
	end

	if v5[p] then
		return v26
	end

	return v26 * CFrame.Angles(0, 3.141592653589793, 0)
end

local function floatTowardLens(cframe2: CFrame, p: number) -- 2 equivalent calls inferred from this helper
	local v26 = position

	if v26 then
		return cframe2 - cframe2.Position + (v26 + (cframe2.Position - v26) * p)
	end

	return cframe2
end

local function setCardScale(instance, p: number)
	local v26 = sizes[instance]

	if not v26 then
		return
	end

	instance.Size = Vector3.new(v26.X * p, v26.Y * p, v26.Z)

	for _, surfaceGui in instance:GetChildren() do
		if not surfaceGui:IsA("SurfaceGui") then
			continue
		end

		local v27 = pixelsPerStudsBySurfaceGui[surfaceGui]

		if v27 then
			surfaceGui.PixelsPerStud = v27 / p
		end
	end
end

local function getCardSpin(p)
	local v26 = v6[p]

	if v26 then
		return v26
	end

	local numberValue = Instance.new("NumberValue")
	numberValue.Value = v5[p] and 0 or 3.141592653589793
	local v27 = {
		Angle = numberValue,
		Target = numberValue.Value,
		IsTurning = false,
		Direction = -1
	}
	numberValue.Changed:Connect(function(p2: number)
		local v28 = v4[p]

		if v27.IsTurning and v28 then
			p.CFrame = v28 * CFrame.Angles(0, p2, 0)
		end
	end)
	v6[p] = v27
	return v27
end

local function settleCardSpin(p) -- 3 equivalent calls inferred from this helper
	maid:Remove(`CardFlip_{v7[p] or 0}`)
	local v26 = v6[p]

	if v26 then
		v26.IsTurning = false
		v26.Target = v5[p] and 0 or 3.141592653589793
		v26.Angle.Value = v26.Target
	end
end

local function isDealInProgress() -- 1 equivalent call inferred from this helper
	return v14 or v15
end

local function getDealPose(p, p2: number)
	local v26 = v10[p]
	local v27 = sizes[p]

	if not (v26 and v27) then
		return nil, v9
	end

	if not v5[p] then
		v26 *= CFrame.Angles(0, 3.141592653589793, 0)
	end

	local v28 = v27 * v9
	local v29 = cframe or CurrentCamera.CFrame
	local vector = Vector3.new(v29.RightVector.X, 0, v29.RightVector.Z)
	local v30 = not (vector.Magnitude > 0.001) and createVector(1, 0, 0) or vector.Unit
	local cross = (createVector(0, 1, 0)):Cross(v30)
	local position2 = v26.Position
	local v31 = -v30 * (v28.X * 1.4) + cross * 3
	local v32 = position2 - createVector(0, 4, 0) + v31
	local value = TweenService:GetValue(p2, Cubic, Enum.EasingDirection.Out)
	local value2 = TweenService:GetValue(math.min(value / 0.4, 1), Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local value3 = TweenService:GetValue(
		math.clamp((value - 0.3) / 0.7, 0, 1),
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)
	local v34 = v28.Y * 0.3 * math.sin(3.141592653589793 * value3)
	local v35 = v32 + createVector(0, 1, 0) * (4 * value2 + v34) - v31 * value3
	local v36 = 1 - TweenService:GetValue(p2, Back, Enum.EasingDirection.Out)
	local v37 = CFrame.fromAxisAngle(cross, -0.4188790204786391 * v36) * CFrame.fromAxisAngle(
		createVector(0, 1, 0),
		-0.6108652381980153 * v36
	)
	local v38 = math.clamp((value - 0.4) / 0.6, 0, 1) * -0.30000000000000004 + 1
	return floatTowardLens(CFrame.new(v35) * v37 * v26.Rotation, v38), v9 * v38 -- inferred equivalent call
end

local function settleDeal()
	count += 1
	v14 = false
	v15 = false

	for _, v26 in parts do
		maid:Remove(`CardDeal_{v7[v26] or 0}`)
		local settledPose = getSettledPose(v26) -- inferred equivalent call

		if settledPose then
			setCardScale(v26, v9 * 0.7)
			v26.CFrame = settledPose
		end

		v16[v26] = true
	end

	syncCardVisibility() -- inferred equivalent call
end

local function runDeal()
	count += 1
	local v26 = count
	local v27 = v17
	v14 = true
	v15 = false
	v17 = true

	for _, v28 in parts do
		v16[v28] = false
		local dealPose, v29 = getDealPose(v28, 0)

		if not dealPose then
			continue
		end

		setCardScale(v28, v29)
		v28.CFrame = dealPose
	end

	syncCardVisibility() -- inferred equivalent call
	task.spawn(function()
		if v27 then
			playDealerLine(DealerLines.Open)
		end

		task.wait(0.25)

		if count ~= v26 then
			return
		end

		for k, v28 in parts do
			if count ~= v26 then
				return
			end

			if getSettledPose(v28) then -- inferred equivalent call
				v16[v28] = true
				refreshCardFaces(v28) -- inferred equivalent call
				local numberValue = Instance.new("NumberValue")
				local v29 = v28
				numberValue.Changed:Connect(function(p: number)
					local dealPose, v30 = getDealPose(v29, p)

					if dealPose then
						setCardScale(v29, v30)
						v29.CFrame = dealPose
					end
				end)
				local tween = TweenService:Create(numberValue, TweenInfo.new(0.8, Enum.EasingStyle.Linear), {
					Value = 1
				})
				maid:Add(function()
					tween:Destroy()
					numberValue:Destroy()
				end, true, `CardDeal_{v7[v28] or k}`)
				tween:Play()
			end

			if k < #parts then
				task.wait(0.14)
			end
		end

		task.wait(0.8)

		if count ~= v26 then
			return
		end

		settleDeal()
	end)
end

local function startDealIfReady()
	if not v15 or not flag or v12 or v13 then
		return
	end

	local v26 = false

	for _, v27 in parts do
		if v11[v27] ~= true then
			continue
		end

		v26 = true
		break
	end

	if not v26 then
		return
	end

	runDeal()
end

local function makeSceneInert(folder)
	local cards = folder:FindFirstChild("Cards")

	for _, part in folder:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = part.Parent == cards
	end
end

local function captureDesignRow()
	for _, v26 in parts do
		if cframes[v26] then
			continue
		end

		cframes[v26] = v26.CFrame
		sizes[v26] = v26.Size

		for _, surfaceGui in v26:GetChildren() do
			if surfaceGui:IsA("SurfaceGui") then
				pixelsPerStudsBySurfaceGui[surfaceGui] = surfaceGui.PixelsPerStud
			end
		end
	end

	local v26 = parts[1]
	local v27 = parts[#parts]
	local v28 = v26 and cframes[v26]
	local v29 = v27 and cframes[v27]

	if not (v28 and v29) then
		v8 = nil
		return
	end

	v8 = (v28.Position + v29.Position) / 2 - v28.UpVector * (sizes[v26].Y / 2)
	local marker = getMarker("Cards") -- inferred equivalent call
	position = marker and marker.Position
end

local function applyRowFit()
	local v26 = v8

	if not v26 then
		return
	end

	local viewportSize = CurrentCamera.ViewportSize

	if viewportSize.Y <= 0 then
		return
	end

	local v27 = math.min(1, viewportSize.X / viewportSize.Y / (16 / 9))
	v9 = v27

	for _, v28 in parts do
		local v29 = cframes[v28]

		if not v29 then
			continue
		end

		local cframe2 = v29 - v29.Position + (v26 + (v29.Position - v26) * v27)
		v10[v28] = cframe2
		cframe2 = floatTowardLens(cframe2, 0.7) -- inferred equivalent call
		v4[v28] = cframe2
		local v30 = v7[v28] or 0
		settleCardSpin(v28) -- inferred equivalent call
		maid:Remove(`CardDeal_{v30}`)
		setCardScale(v28, v27 * 0.7)

		if not v5[v28] then
			cframe2 *= CFrame.Angles(0, 3.141592653589793, 0)
		end

		v28.CFrame = cframe2
		refreshCardFaces(v28) -- inferred equivalent call
	end
end

local function collectCards(instance)
	parts = {}
	v4 = {}
	v10 = {}
	v5 = {}

	for _, v26 in v6 do
		v26.Angle:Destroy()
	end

	v6 = {}
	v11 = {}
	v7 = {}
	local cards = instance:FindFirstChild("Cards")

	if not cards then
		warn("[BlackMarketSceneController]: scene is missing its Cards folder")
		return
	end

	for _, part in cards:GetChildren() do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	table.sort(parts, function(a, b)
		return a.Position.Z < b.Position.Z
	end)

	for k, v26 in parts do
		v7[v26] = k
	end

	captureDesignRow()
	applyRowFit()
end

function BlackMarketSceneController.IsActive()
	return flag
end

function BlackMarketSceneController.GetCards()
	return parts
end

function BlackMarketSceneController.GetCardFaces(instance)
	local back = instance:FindFirstChild("Back")
	local front = instance:FindFirstChild("Front")
	return back and back:FindFirstChild("Main"), front and front:FindFirstChild("Main")
end

function BlackMarketSceneController.IsCardFaceUp(p)
	return v5[p] == true
end

function BlackMarketSceneController:SetCardFaceUp(flag2: boolean, flag3: boolean?)
	local cframe2 = v4[self]

	if not cframe2 or v5[self] == flag2 or flag3 and (v14 or v15) then
		return
	end

	if flag3 then
		local cardSpin = getCardSpin(self)
		local isTurning = cardSpin.IsTurning

		if not isTurning then
			cardSpin.Angle.Value = v5[self] and 0 or 3.141592653589793
			cardSpin.Target = cardSpin.Angle.Value
			cardSpin.Direction = random:NextInteger(0, 1) == 0 and -1 or 1
		end

		cardSpin.Target += cardSpin.Direction * 3.141592653589793
		local v26 = math.abs(cardSpin.Target - cardSpin.Angle.Value)
		local angle = cardSpin.Angle
		local v27 = v26 * 0.42 / 3.141592653589793
		local quad = Enum.EasingStyle.Quad
		local v28

		if isTurning then
			v28 = Enum.EasingDirection.Out
		else
			v28 = Enum.EasingDirection.InOut
		end

		local v29 = TweenService:Create(angle, TweenInfo.new(v27, quad, v28), {
			Value = cardSpin.Target
		})
		v29.Completed:Once(function(p)
			if p ~= Enum.PlaybackState.Completed then
				return
			end

			cardSpin.IsTurning = false
			cardSpin.Target = v5[self] and 0 or 3.141592653589793
			cardSpin.Angle.Value = cardSpin.Target
		end)
		maid:Add(v29, "Destroy", `CardFlip_{v7[self] or 0}`)
		v5[self] = flag2
		cardSpin.IsTurning = true
		v29:Play()
	else
		v5[self] = flag2
		settleCardSpin(self) -- inferred equivalent call

		if not flag2 then
			cframe2 *= CFrame.Angles(0, 3.141592653589793, 0)
		end

		self.CFrame = cframe2
		refreshCardFaces(self) -- inferred equivalent call
	end
end

function BlackMarketSceneController.ResetCards()
	for _, v26 in parts do
		local v27 = v6[v26]

		if v27 and v27.IsTurning then
			settleCardSpin(v26) -- inferred equivalent call
			local settledPose = getSettledPose(v26) -- inferred equivalent call

			if settledPose then
				v26.CFrame = settledPose
			end
		end

		BlackMarketSceneController.SetCardFaceUp(v26, false, false)
	end
end

function BlackMarketSceneController.SetCardVisible(p, flag2: boolean)
	v11[p] = flag2
	refreshCardFaces(p) -- inferred equivalent call
end

function BlackMarketSceneController.IsCardShown(p)
	return v11[p] == true and not (v12 or v13) and (not (v14 or v15) or v16[p] == true)
end

function BlackMarketSceneController.SetRevealHeld(flag2: boolean)
	if v13 == flag2 then
		return
	end

	v13 = flag2
	syncCardVisibility() -- inferred equivalent call
	startDealIfReady()
end

function BlackMarketSceneController.ReplayIntro()
	if not flag then
		return
	end

	BlackMarketSceneController.ResetCards()
	v12 = true
	v15 = true
	v17 = true
	table.clear(v16)
	syncCardVisibility() -- inferred equivalent call
	local marker = getMarker("Cards") -- inferred equivalent call

	if marker then
		cframe = marker.CFrame
		v23 = nil
		v24 = nil
	else
		warn("[BlackMarketSceneController]: scene is missing Camera.Cards")
	end

	startIntroArc() -- inferred equivalent call
	playDealerBody(DealerLines.INTRO_ANIMATION) -- inferred equivalent call
end

function BlackMarketSceneController.Redeal()
	if not flag then
		return
	end

	BlackMarketSceneController.ResetCards()
	count += 1

	for _, v26 in parts do
		maid:Remove(`CardDeal_{v7[v26] or 0}`)
	end

	v14 = false
	v15 = true
	v17 = false
	table.clear(v16)
	syncCardVisibility() -- inferred equivalent call
end

function BlackMarketSceneController.SkipIntro()
	if not flag then
		return
	end

	local marker = getMarker("Cards") -- inferred equivalent call

	if marker then
		cframe = marker.CFrame
		v23 = nil
		v24 = nil
	else
		warn("[BlackMarketSceneController]: scene is missing Camera.Cards")
	end

	v12 = false
	syncCardVisibility() -- inferred equivalent call
	startDealIfReady()
end

function BlackMarketSceneController.IsPresenting()
	return v12 or isDealInProgress() -- inferred equivalent call
end

function BlackMarketSceneController.SkipPresentation()
	if not flag then
		return
	end

	if v12 or v23 then
		local marker = getMarker("Cards") -- inferred equivalent call

		if marker then
			cframe = marker.CFrame
			v23 = nil
			v24 = nil
		else
			warn("[BlackMarketSceneController]: scene is missing Camera.Cards")
		end

		v12 = false
	end

	settleDeal()
end

function BlackMarketSceneController.PlayPurchaseLine()
	playDealerLine(DealerLines.Purchase)
end

function BlackMarketSceneController.PlayDeclineLine()
	playDealerLine(DealerLines.Declined)
end

function BlackMarketSceneController.PlayRefreshLine()
	playDealerLine(DealerLines.Refresh)
end

function BlackMarketSceneController.PlayDiscontinuedLine()
	playDealerLine(DealerLines.Discontinued)
end

function BlackMarketSceneController.PlayRarityLine(value: string?)
	if typeof(value) ~= "string" then
		return
	end

	playDealerLine(DealerLines.Rarity[value])
end

function BlackMarketSceneController.NotifyDealRendered()
	startDealIfReady()
end

function BlackMarketSceneController.Show(flag2: boolean?)
	if flag then
		return
	end

	local v26 = v3

	if not v26 then
		warn("[BlackMarketSceneController]: scene was never staged")
		return
	end

	SceneParking.Unpark(v26)
	flag = true
	v13 = false
	collectCards(v26)
	BlackMarketSceneController.ResetCards()
	syncCardVisibility() -- inferred equivalent call
	applySceneLighting()
	startDealerIdle() -- inferred equivalent call
	v15 = not flag2
	v17 = true
	table.clear(v16)
	CurrentCamera.CameraType = Enum.CameraType.Scriptable
	CameraController.setFOVLock("BlackMarketScene", true, 70)
	CameraController.setForceLockOverride("BlackMarketScene", true)
	setPerspectiveSinksInput(false)
	v12 = not flag2
	local marker = getMarker("Cards") -- inferred equivalent call

	if marker then
		cframe = marker.CFrame
		v23 = nil
		v24 = nil
	else
		warn("[BlackMarketSceneController]: scene is missing Camera.Cards")
	end

	if not flag2 then
		startIntroArc() -- inferred equivalent call
		playDealerBody(DealerLines.INTRO_ANIMATION) -- inferred equivalent call
	end

	RunServiceController.BindToRenderStep("BlackMarketSceneController.CameraUpdate", v, function()
		local cframe2 = cframe

		if not cframe2 then
			return
		end

		CurrentCamera.CameraType = Enum.CameraType.Scriptable
		local v27 = v23
		local v28 = v24

		if v27 and v28 then
			local v29 = math.clamp((os.clock() - now - 0.2) / 1.4, 0, 1)
			local v30 = 1.5707963267948966 * TweenService:GetValue(v29, Sine, Enum.EasingDirection.InOut)
			CurrentCamera.CFrame = cframe2 + v27 * math.cos(v30) + v28 * (1 - math.sin(v30))

			if v29 >= 1 then
				v23 = nil
				v24 = nil

				if v12 then
					v12 = false
					syncCardVisibility() -- inferred equivalent call
					startDealIfReady()
				end
			end
		else
			CurrentCamera.CFrame = cframe2
		end

		CurrentCamera.Focus = CurrentCamera.CFrame
	end)
	maid:Add(function()
		RunServiceController.UnbindFromRenderStep("BlackMarketSceneController.CameraUpdate")
	end, true, "CameraUpdate")
	maid:Add(CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyRowFit), "Disconnect", "ViewportFit")
	BakedViewmodelMirror.SetSuppressed(true)

	for _, child in CurrentCamera:GetChildren() do
		if isCameraAttachment(child) then -- inferred equivalent call
			hideViewmodel(child) -- inferred equivalent call
		end
	end

	maid:Add(CurrentCamera.ChildAdded:Connect(function(child)
		if isCameraAttachment(child) then -- inferred equivalent call
			hideViewmodel(child) -- inferred equivalent call
		end
	end), "Disconnect", "ViewmodelListener")
	BlackMarketSceneController.OnActiveChanged:Fire(true)
end

function BlackMarketSceneController.Hide()
	if not flag then
		return
	end

	flag = false
	v12 = false
	v13 = false
	count += 1
	v14 = false
	v15 = false
	stopDealer() -- inferred equivalent call
	maid:Cleanup()
	cframe = nil
	v23 = nil
	v24 = nil
	CurrentCamera.CameraType = Enum.CameraType.Custom
	CameraController.setFOVLock("BlackMarketScene", false)
	CameraController.updateCameraFOV(Constants.DEFAULT_CAMERA_FOV)
	local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

	if currentSpectateInstance then
		currentSpectateInstance:UpdateScopeState()
	end

	CameraController.setForceLockOverride("BlackMarketScene", false)
	setPerspectiveSinksInput(true)
	showViewmodels()
	BakedViewmodelMirror.SetSuppressed(false)
	local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
	local MenuState = require(ReplicatedStorage.Interface.MenuState)

	if not MenuState.IsInspectActive() then
		if workspace:FindFirstChild("Map") then
			MenuSceneController.ApplyMapLighting()
		else
			MenuSceneController.ApplyMenuSceneLighting()
		end
	end

	if v3 then
		SceneParking.Park(v3)
	end

	BlackMarketSceneController.OnActiveChanged:Fire(false)
end

function BlackMarketSceneController.Initialize()
	if not Constants.BLACK_MARKET_ENABLED then
		return
	end

	local blackMarketScene = ReplicatedStorage.Assets:FindFirstChild("BlackMarketScene")

	if not blackMarketScene then
		warn("[BlackMarketSceneController]: Assets.BlackMarketScene is missing")
		return
	end

	local model = blackMarketScene:FindFirstChildOfClass("Model")

	if not model then
		warn("[BlackMarketSceneController]: no model inside Assets.BlackMarketScene")
		return
	end

	local clone = model:Clone()
	clone.Name = "BlackMarketScene"
	SceneParking.Park(clone)
	v3 = clone
	makeSceneInert(clone)
	bindDealer(clone) -- inferred equivalent call
	collectCards(clone)
	BlackMarketSceneController.ResetCards()
end

return BlackMarketSceneController