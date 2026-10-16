local createVector = vector.create
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local MovementV2 = ReplicatedStorage.MovementV2
local Buttons = require(MovementV2.Buttons)
local JumpInputSampler = require(MovementV2.JumpInputSampler)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local PlayerContacts = require(MovementV2.Simulation.PlayerContacts)
local PredictionErrorSmoother = require(MovementV2.Client.PredictionErrorSmoother)
local Config = require(MovementV2.Simulation.Config)
local State = require(MovementV2.Simulation.State)
local RootFrame = require(MovementV2.RootFrame)
local RuntimeKinematics = require(MovementV2.RuntimeKinematics)
local Signal = require(ReplicatedStorage.Packages.Signal)
local CharacterAnimator = require(script.Classes.CharacterAnimator)
local LocalPlayer = Players.LocalPlayer
local Character = {}
Character.__index = Character
local v = 150 * Config.Default.HammerUnitToStud
local ContactMinDistance = PredictionErrorSmoother.ContactMinDistance

local function smoothStep(value: number) -- 3 equivalent calls inferred from this helper
	local v2 = math.clamp(value, 0, 1)
	return v2 * v2 * (3 - v2 * 2)
end

local function cameraYawAndPitch()
	local currentCamera = Workspace.CurrentCamera

	if currentCamera == nil then
		return 0, 0, CFrame.identity
	end

	local _, v2, _ = currentCamera.CFrame:ToEulerAnglesYXZ()
	local cframe = CFrame.Angles(0, v2, 0)
	return v2, math.clamp(currentCamera.CFrame.LookVector.Y, -1, 1), cframe
end

local function finiteHorizontalInput(vector: Vector3)
	if
		vector.X == vector.X
		and vector.Y == vector.Y
		and vector.Z == vector.Z
		and math.abs(vector.X) ~= 1e999
		and math.abs(vector.Y) ~= 1e999
		and math.abs(vector.Z) ~= 1e999
	then
		return (Vector3.new(vector.X, 0, vector.Z))
	end

	return createVector(0, 0, 0)
end

local function shortestAngleDelta(p: number, p2: number) -- 2 equivalent calls inferred from this helper
	return (math.atan2(math.sin(p2 - p), (math.cos(p2 - p))))
end

local function applyAutomaticAirStrafe(currentFrameMoveVector: Vector2, lastSampledLookYaw: number, p: number, state)
	local preferredInput = UserInputService.PreferredInput

	if
		preferredInput ~= Enum.PreferredInput.Touch and preferredInput ~= Enum.PreferredInput.Gamepad
		or state.OnGround
		or state.MovementMode ~= "Walking"
		or math.abs(currentFrameMoveVector.X) > 0.2
	then
		return currentFrameMoveVector
	end

	local v2 = shortestAngleDelta(lastSampledLookYaw, p) -- inferred equivalent call

	if math.abs(v2) <= 0.00017453292519943296 then
		return currentFrameMoveVector
	end

	local v3 = v2 < 0 and 1 or -1
	return Vector2.new(v3, currentFrameMoveVector.Y)
end

local function syncCameraPart(data)
	local cameraPart = data.CameraPart
	local humanoidRootPart = data.HumanoidRootPart

	if not (cameraPart.Parent and humanoidRootPart.Parent) then
		return
	end

	local v2 = Vector3.new(0, 2 + data.StepCameraOffsetY, 0) + data.CameraOffset
	local cameraPartWeld = cameraPart:FindFirstChild("CameraPartWeld")

	if cameraPartWeld == nil or not cameraPartWeld:IsA("Weld") then
		cameraPart.CFrame = humanoidRootPart.CFrame * CFrame.new(v2)
		return
	end

	cameraPartWeld.Part0 = humanoidRootPart
	cameraPartWeld.Part1 = cameraPart
	cameraPartWeld.C0 = CFrame.new(v2)
	cameraPartWeld.C1 = CFrame.identity
end

local function approachVisualDuck(p: number, p2: number, p3: number) -- 2 equivalent calls inferred from this helper
	local v2 = 1 - math.exp(math.max(p3, 0) * -20)
	local v3 = p + (p2 - p) * v2

	if math.abs(p2 - v3) <= 0.001 then
		return p2
	end

	return v3
end

local function updateCameraOffset(state, p: number, p2: number?)
	local v2 = state.IsPlantingBomb and 1 or 0
	local v3 = p / 0.12

	if state.VisualPlantCameraAlpha < v2 then
		state.VisualPlantCameraAlpha = math.min(v2, state.VisualPlantCameraAlpha + v3)
	else
		state.VisualPlantCameraAlpha = math.max(v2, state.VisualPlantCameraAlpha - v3)
	end

	local v4 = math.clamp(state.MovementState.DuckAmount, 0, 1)
	state.VisualDuckAmount = approachVisualDuck(state.VisualDuckAmount, v4, p) -- inferred equivalent call
	local visualDuckRootAmount = state.MovementState.OnGround and 0 or v4
	visualDuckRootAmount = approachVisualDuck(state.VisualDuckRootAmount, visualDuckRootAmount, p) -- inferred equivalent call
	state.VisualDuckRootAmount = visualDuckRootAmount
	local v5 = p2 or RootFrame.getDuckRootVerticalOffset(v4, state.MovementState.OnGround)
	state.CameraDuckRootCompensationY = RootFrame.getDuckRootVerticalOffset(
		smoothStep(state.VisualDuckRootAmount), -- inferred equivalent call
		false
	) - v5
	local v6 = smoothStep(state.VisualDuckAmount) -- inferred equivalent call
	local defaultCameraOffset = state.DefaultCameraOffset
	state.CameraOffset = (defaultCameraOffset:Lerp(defaultCameraOffset + state.CrouchCameraOffset, v6) + Vector3.new(0, state.CameraDuckRootCompensationY, 0)):Lerp(
		defaultCameraOffset + createVector(0, -0.9, 0),
		smoothStep(state.VisualPlantCameraAlpha) -- inferred equivalent call
	)
	syncCameraPart(state)
end

local function updateStepCameraOffset(player, movementState, y: number, p: number, snapNextPresentation: boolean)
	local stepSmoothRootY = player.StepSmoothRootY
	local v2 = player.StepSmoothLastDuckAmount ~= movementState.DuckAmount
	local v3 = player.StepSmoothWasOnGround ~= movementState.OnGround
	player.StepSmoothLastDuckAmount = movementState.DuckAmount
	player.StepSmoothWasOnGround = movementState.OnGround
	local maxStepHeight = Config.Default.MaxStepHeight

	if
		not snapNextPresentation
		and typeof(stepSmoothRootY) == "number"
		and movementState.OnGround
		and not (v3 or v2)
	then
		local v4 = math.abs(y - stepSmoothRootY)

		if not (maxStepHeight * 2 < v4) then
			if stepSmoothRootY < y then
				stepSmoothRootY = math.max(math.min(stepSmoothRootY + v * p, y), y - maxStepHeight)
			elseif y < stepSmoothRootY then
				stepSmoothRootY = math.min(math.max(stepSmoothRootY - v * p, y), y + maxStepHeight)
			end

			player.StepSmoothRootY = stepSmoothRootY
			player.StepCameraOffsetY = stepSmoothRootY - y
			return
		end
	end

	player.StepSmoothRootY = y
	player.StepCameraOffsetY = 0
end

function Character.new(instance, instance2)
	local cameraPart = assert(CharacterResolver.getCameraPart(instance), `{instance:GetFullName()} has no CameraPart`)
	local generation = assert(CharacterGeneration.Get(instance), "local shell has no CharacterGeneration")
	local currentCamera = Workspace.CurrentCamera
	local v2, currentFrameVerticalLook

	if currentCamera == nil then
		local _identity = CFrame.identity
		v2 = 0
		currentFrameVerticalLook = 0
	else
		local _, v3
		_, v2, v3 = currentCamera.CFrame:ToEulerAnglesYXZ()
		CFrame.Angles(0, v2, 0)
		currentFrameVerticalLook = math.clamp(currentCamera.CFrame.LookVector.Y, -1, 1)
	end

	local movementState = State.new(
		RootFrame.rootToSimulationPosition(instance2.Position, "Standing"),
		nil,
		select(2, instance2.CFrame:ToEulerAnglesYXZ()),
		0
	)
	local object = setmetatable({
		Janitor = Janitor.new(),
		Character = instance,
		Player = LocalPlayer,
		Generation = generation,
		HumanoidRootPart = instance2,
		CameraPart = cameraPart,
		CharacterAnimator = CharacterAnimator.new(instance),
		MovementState = movementState,
		Support = State.noneSupport(),
		GlobalVelocity = createVector(0, 0, 0),
		GlobalDirection = createVector(0, 0, 0),
		LatestMoveVector = Vector2.zero,
		PreviousFrameMoveVector = Vector2.zero,
		CurrentFrameMoveVector = Vector2.zero,
		PreviousFrameLookYaw = v2,
		CurrentFrameLookYaw = v2,
		LastSampledLookYaw = v2,
		CurrentFrameVerticalLook = currentFrameVerticalLook,
		InputFramePrepared = false,
		CrouchInputDown = false,
		JumpInputDown = false,
		JumpPulsePending = false,
		JumpPulseNeedsRelease = false,
		IsWalking = false,
		IsCrouching = false,
		IsClimbing = false,
		IsJumping = false,
		IsPlantingBomb = false,
		OnGround = true,
		DefaultCameraOffset = LocalPlayer:GetAttribute("DefaultCameraOffset") or createVector(0, -0.15, 0),
		CrouchCameraOffset = LocalPlayer:GetAttribute("CrouchCameraOffset") or createVector(0, -1.4, 0),
		CameraOffset = createVector(0, 0, 0),
		VisualDuckAmount = movementState.DuckAmount,
		VisualDuckRootAmount = 0,
		CameraDuckRootCompensationY = 0,
		VisualPlantCameraAlpha = 0,
		StepSmoothRootY = instance2.Position.Y,
		StepSmoothLastDuckAmount = movementState.DuckAmount,
		StepSmoothWasOnGround = movementState.OnGround,
		StepCameraOffsetY = 0,
		LastPresentedAt = os.clock(),
		LastExactPresentationTick = nil,
		SnapNextPresentation = true,
		PredictionErrorOffset = createVector(0, 0, 0),
		PredictionErrorElapsedSeconds = 0,
		PreservePredictionPresentation = false,
		PendingPredictionPositionDelta = createVector(0, 0, 0),
		IsDestroyed = false,
		Crouching = Signal.new(),
		Climbing = Signal.new(),
		Walking = Signal.new(),
		Landed = Signal.new()
	}, Character)
	object.CharacterAnimator.Player = LocalPlayer
	instance2.Anchored = true
	instance2.AssemblyLinearVelocity = createVector(0, 0, 0)
	instance2.AssemblyAngularVelocity = createVector(0, 0, 0)
	object.Janitor:Add(object.Crouching)
	object.Janitor:Add(object.Climbing)
	object.Janitor:Add(object.Walking)
	object.Janitor:Add(object.Landed)
	object.Janitor:Add(function()
		object.CharacterAnimator:destroy()
		RuntimeKinematics.clear(instance)
	end)
	object.Janitor:Add(LocalPlayer:GetAttributeChangedSignal("DefaultCameraOffset"):Connect(function()
		object.DefaultCameraOffset = LocalPlayer:GetAttribute("DefaultCameraOffset") or createVector(0, -0.15, 0)
	end))
	object.Janitor:Add(LocalPlayer:GetAttributeChangedSignal("CrouchCameraOffset"):Connect(function()
		object.CrouchCameraOffset = LocalPlayer:GetAttribute("CrouchCameraOffset") or createVector(0, -1.4, 0)
	end))
	updateCameraOffset(object, 0)
	RuntimeKinematics.write(instance, createVector(0, 0, 0), true, instance2.Position)
	return object
end

function Character:MatchesGeneration(p: number)
	local v2 = not self.IsDestroyed

	if v2 then
		if self.Character.Parent == nil or self.Character:GetAttribute("Dead") == true or self.Generation ~= p then
			return false
		else
			return CharacterGeneration.Get(self.Character) == p
		end
	end

	return v2
end

function Character:MoveFunction(vector: Vector3, flag: boolean)
	if self.IsDestroyed then
		return
	end

	local currentCamera = Workspace.CurrentCamera
	local identity

	if currentCamera == nil then
		identity = CFrame.identity
	else
		local _, v2, _ = currentCamera.CFrame:ToEulerAnglesYXZ()
		identity = CFrame.Angles(0, v2, 0)
		math.clamp(currentCamera.CFrame.LookVector.Y, -1, 1)
	end

	local v2 = finiteHorizontalInput(vector)

	if not flag then
		v2 = identity:VectorToObjectSpace(v2)
	end

	local vector2 = Vector3.new(math.clamp(v2.X, -1, 1), 0, (math.clamp(v2.Z, -1, 1)))
	self.GlobalDirection = identity:VectorToWorldSpace(vector2)
	self.LatestMoveVector = Vector2.new(vector2.X, vector2.Z)
end

function Character:PrepareInputFrame()
	if self.IsDestroyed then
		return
	end

	local currentCamera = Workspace.CurrentCamera
	local v2, currentFrameVerticalLook

	if currentCamera == nil then
		local _identity = CFrame.identity
		v2 = 0
		currentFrameVerticalLook = 0
	else
		local _, v3
		_, v2, v3 = currentCamera.CFrame:ToEulerAnglesYXZ()
		CFrame.Angles(0, v2, 0)
		currentFrameVerticalLook = math.clamp(currentCamera.CFrame.LookVector.Y, -1, 1)
	end

	if self.InputFramePrepared then
		self.PreviousFrameMoveVector = self.CurrentFrameMoveVector
		self.CurrentFrameMoveVector = self.LatestMoveVector
		self.PreviousFrameLookYaw = self.CurrentFrameLookYaw
		self.CurrentFrameLookYaw = v2
		self.CurrentFrameVerticalLook = currentFrameVerticalLook
	else
		self.PreviousFrameMoveVector = self.LatestMoveVector
		self.CurrentFrameMoveVector = self.LatestMoveVector
		self.PreviousFrameLookYaw = v2
		self.CurrentFrameLookYaw = v2
		self.CurrentFrameVerticalLook = currentFrameVerticalLook
		self.InputFramePrepared = true
	end
end

function Character:ToggleWalkState(isWalking: boolean)
	if self.IsWalking == isWalking then
		return
	end

	self.IsWalking = isWalking
	self.Walking:Fire(isWalking)
end

function Character:ToggleCrouchInput(crouchInputDown: boolean)
	self.CrouchInputDown = crouchInputDown
end

function Character:SetJumpInput(jumpInputDown: boolean?)
	if jumpInputDown == nil then
		self.JumpPulsePending = true
	else
		self.JumpInputDown = jumpInputDown
	end
end

function Character:PlantBomb()
	self.IsPlantingBomb = true
end

function Character:CancelBombPlant()
	self.IsPlantingBomb = false
end

function Character:SampleInput(data)
	if not self:MatchesGeneration(data.Mapping.Generation) then
		return nil
	end

	local v2 = math.clamp(data.FrameSampleAlpha or 1, 0, 1)
	local previousFrameMoveVector = self.PreviousFrameMoveVector
	local currentFrameMoveVector = self.CurrentFrameMoveVector

	if
		math.sign(previousFrameMoveVector.X) ~= math.sign(currentFrameMoveVector.X)
		or math.sign(previousFrameMoveVector.Y) ~= math.sign(currentFrameMoveVector.Y)
	then
		if v2 < 0.5 then
			currentFrameMoveVector = previousFrameMoveVector
		end
	else
		currentFrameMoveVector = previousFrameMoveVector:Lerp(currentFrameMoveVector, v2)
	end

	local v3 = self.PreviousFrameLookYaw + shortestAngleDelta(self.PreviousFrameLookYaw, self.CurrentFrameLookYaw) * v2 -- inferred equivalent call
	local move = applyAutomaticAirStrafe(currentFrameMoveVector, self.LastSampledLookYaw, v3, data.State)
	self.LastSampledLookYaw = v3
	local v4 = Buttons.with(0, Buttons.Walk, self.IsWalking)
	local v5 = Buttons.with(v4, Buttons.Duck, self.CrouchInputDown)
	local sample, jumpPulsePending, jumpPulseNeedsRelease = JumpInputSampler.sample(
		self.JumpInputDown,
		self.JumpPulsePending,
		self.JumpPulseNeedsRelease
	)
	self.JumpPulsePending = jumpPulsePending
	self.JumpPulseNeedsRelease = jumpPulseNeedsRelease
	local buttons = Buttons.with(v5, Buttons.Jump, sample)
	return {
		Move = move,
		LookYaw = v3,
		VerticalLook = self.CurrentFrameVerticalLook,
		Buttons = buttons
	}
end

function Character:Present(movementState, support, data, p)
	local mapping = data.Mapping
	local v2

	if mapping == nil then
		v2 = self.Generation
	else
		v2 = mapping.Generation
	end

	if not self:MatchesGeneration(v2) then
		return
	end

	local now = os.clock()
	local v3 = math.clamp(now - self.LastPresentedAt, 0, 0.1)
	self.LastPresentedAt = now
	local cframe = RootFrame.cframe(movementState)
	local cframe2 = RootFrame.cframe(p or movementState)
	local snapNextPresentation = self.SnapNextPresentation

	if snapNextPresentation then
		self.LastExactPresentationTick = data.ServerTick
	end

	local v4

	if snapNextPresentation then
		v4 = snapNextPresentation
	elseif self.LastExactPresentationTick == nil then
		v4 = false
	else
		v4 = data.ServerTick == self.LastExactPresentationTick
	end

	local v5 = math.clamp(data.TickFraction or 0, 0, 1)
	local cframe3

	if v4 then
		cframe3 = cframe
	else
		cframe3 = cframe2:Lerp(cframe, v5)
	end

	if not v4 then
		self.LastExactPresentationTick = nil
	end

	self.SnapNextPresentation = false
	local preservePredictionPresentation = self.PreservePredictionPresentation == true
	self.PreservePredictionPresentation = false
	local pendingPredictionPositionDelta = self.PendingPredictionPositionDelta
	self.PendingPredictionPositionDelta = createVector(0, 0, 0)

	if v4 then
		self.PredictionErrorOffset = createVector(0, 0, 0)
		self.PredictionErrorElapsedSeconds = 0
	elseif preservePredictionPresentation then
		local v6 = PredictionErrorSmoother.remainingOffset(
			self.PredictionErrorOffset,
			self.PredictionErrorElapsedSeconds
		) - pendingPredictionPositionDelta
		self.PredictionErrorOffset = PredictionErrorSmoother.clampOffset(v6)
		self.PredictionErrorElapsedSeconds = 0
	end

	local remainingOffset = PredictionErrorSmoother.remainingOffset(
		self.PredictionErrorOffset,
		self.PredictionErrorElapsedSeconds
	)

	if not v4 and remainingOffset.Magnitude > PredictionErrorSmoother.Epsilon then
		cframe3 += remainingOffset
		self.PredictionErrorElapsedSeconds += v3

		if PredictionErrorSmoother.remainingOffset(self.PredictionErrorOffset, self.PredictionErrorElapsedSeconds).Magnitude <= PredictionErrorSmoother.Epsilon then
			self.PredictionErrorOffset = createVector(0, 0, 0)
			self.PredictionErrorElapsedSeconds = 0
		end
	end

	updateStepCameraOffset(self, movementState, cframe3.Position.Y, v3, snapNextPresentation)
	self.HumanoidRootPart.CFrame = cframe3
	self.HumanoidRootPart.AssemblyLinearVelocity = createVector(0, 0, 0)
	self.HumanoidRootPart.AssemblyAngularVelocity = createVector(0, 0, 0)
	local worldVelocity = PlayerContacts.toWorldVelocity(movementState.Velocity, support)
	self.MovementState = movementState
	self.Support = support
	self.GlobalVelocity = Vector3.new(worldVelocity.X, 0, worldVelocity.Z)
	self.OnGround = movementState.OnGround
	self.IsJumping = not movementState.OnGround and worldVelocity.Y > 0
	local isCrouching = movementState.DuckAmount > 0.5

	if isCrouching ~= self.IsCrouching then
		self.IsCrouching = isCrouching
		self.Crouching:Fire(isCrouching)
	end

	local isClimbing = movementState.MovementMode == "Ladder"

	if isClimbing ~= self.IsClimbing then
		self.IsClimbing = isClimbing
		self.Climbing:Fire(isClimbing)
	end

	RuntimeKinematics.write(self.Character, worldVelocity, movementState.OnGround, cframe.Position)
	self.CharacterAnimator:updateLocomotion(worldVelocity, movementState.OnGround, isCrouching, isClimbing)
	local v6 = p or movementState
	local duckRootVerticalOffset = RootFrame.getDuckRootVerticalOffset(v6.DuckAmount, v6.OnGround)
	local duckRootVerticalOffset2 = RootFrame.getDuckRootVerticalOffset(
		movementState.DuckAmount,
		movementState.OnGround
	)

	if not v4 then
		duckRootVerticalOffset2 = duckRootVerticalOffset + (duckRootVerticalOffset2 - duckRootVerticalOffset) * v5
	end

	updateCameraOffset(self, v3, duckRootVerticalOffset2)
end

function Character.OnStepEvents(data, data2)
	if data2.Jumped then
		data.CharacterAnimator:noteJumpEvent()
	end

	if data2.Landed then
		local v2 = typeof(data2.ImpactVelocityY) ~= "number" and 0 or data2.ImpactVelocityY
		data.Landed:Fire(math.max(0, -v2), data.MovementState.DuckAmount)
	end
end

function Character:OnReconciled(p)
	if PredictionErrorSmoother.isHardSnapCorrection(p) then
		self.SnapNextPresentation = true
		self.PreservePredictionPresentation = false
		self.PendingPredictionPositionDelta = createVector(0, 0, 0)
		self.PredictionErrorOffset = createVector(0, 0, 0)
		self.PredictionErrorElapsedSeconds = 0
		self.StepSmoothRootY = nil
		self.StepCameraOffsetY = 0
	elseif
		typeof(p.PresentationPositionDelta) == "Vector3"
		and p.PresentationPositionDelta.Magnitude > PredictionErrorSmoother.Epsilon
	then
		self.PendingPredictionPositionDelta += p.PresentationPositionDelta
		self.PreservePredictionPresentation = true
	end
end

function Character:OnPlayerContactCorrection(p: number, vector: Vector3)
	if ContactMinDistance < p then
		self.PreservePredictionPresentation = true
		self.PendingPredictionPositionDelta += vector
	end
end

function Character:Destroy()
	if self.IsDestroyed then
		return
	end

	self.IsDestroyed = true
	self.Janitor:Destroy()
end

return Character