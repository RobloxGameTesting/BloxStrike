local createVector = vector.create
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Character = require(ReplicatedStorage.Classes.Character)
local Ragdoll = require(ReplicatedStorage.Classes.Ragdoll)
local Sound = require(ReplicatedStorage.Classes.Sound)
local CharacterGeneration = require(ReplicatedStorage.Components.Common.CharacterGeneration)
local ClientCharacterPresentation = require(ReplicatedStorage.Components.Common.ClientCharacterPresentation)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local Runtime = require(ReplicatedStorage.MovementV2.Client.Runtime)
local Catalog = require(ReplicatedStorage.MovementV2.Collision.Catalog)
local MoverComposer = require(ReplicatedStorage.MovementV2.Client.MoverComposer)
local DiagnosticProtocol = require(ReplicatedStorage.MovementV2.DiagnosticProtocol)
local DoorSwing = require(ReplicatedStorage.MovementV2.DoorSwing)
local MoverTrajectory = require(ReplicatedStorage.MovementV2.MoverTrajectory)
local RootFrame = require(ReplicatedStorage.MovementV2.RootFrame)
local RuntimeKinematics = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
local Serial = require(ReplicatedStorage.MovementV2.Serial)
local SpeedProfile = require(ReplicatedStorage.MovementV2.SpeedProfile)
local HitFlinch = require(script.Parent.HitFlinch)
local RemoteCharacters = require(script.Parent.RemoteCharacters)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local NetStatsController = require(ReplicatedStorage.Controllers.NetStatsController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local GameState = require(ReplicatedStorage.Database.Components.GameState)
local LocalPlayer = Players.LocalPlayer
local PlayerModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local controls = PlayerModule:GetControls()
local LocalCharacter = {}
local v = nil
local flag = false
local flag2 = false
local v2 = false
local collisionComposer = MoverComposer.new()
local v3 = nil
local v4 = nil
local v5 = false
local v6 = 0
local v7 = {}

local function movementDiagnosticWarning(p: string) -- 3 equivalent calls inferred from this helper
	if DiagnosticProtocol.shouldOutputForPlayer(LocalPlayer) then
		warn(p)
	end
end

local function movementWeaponWalkSpeed(name: string?) -- 1 equivalent call inferred from this helper
	if v5 and v3 == name then
		return v4
	end

	v3 = name
	v5 = true
	local v8

	if name ~= nil then
		v8 = GetWeaponProperties(name)
	end

	local v9

	if not (v8 == nil or typeof(v8.WalkSpeed) ~= "number") then
		v9 = v8.WalkSpeed
	end

	v4 = v9
	return v4
end

local function resolveScopedState()
	local v8 = InventoryController.peekCurrentEquippedForMovement()

	if v8 == nil then
		return false
	elseif v8.IsAiming == true then
		return true
	elseif v8.Name == "R8 Revolver" then
		return v8.IsChargeFiring == true
	else
		return false
	end
end

local function resolveWeaponSpeedProfile(p)
	if p.Identifier == "" and p.GrenadeThrowIdentifier ~= nil then
		return SpeedProfile.resolveWeaponSpeeds(nil, nil)
	end

	local v8 = InventoryController.peekInventoryItemForMovement(p.Identifier)

	if v8 == nil or typeof(v8.Name) ~= "string" then
		return nil, nil
	end

	return SpeedProfile.resolveWeaponSpeeds(v8.Name, movementWeaponWalkSpeed(v8.Name)) -- inferred equivalent call
end

local function resolveBaseMoveSpeed(_: number, p: number, p2: number, p3: number, flag3: boolean)
	if GameState.GetStateAtTime(p) == "Buy Period" then
		return 0
	end

	if LocalPlayer:GetAttribute("IsPlantingBomb") ~= true then
		return SpeedProfile.resolveFromWeaponSpeeds(
			p2,
			p3,
			flag3,
			LocalPlayer:GetAttribute("IsCarryingHostage") == true
		)
	end

	local bombPlantMovementLockAt = LocalPlayer:GetAttribute("BombPlantMovementLockAt")
	local v8

	if typeof(bombPlantMovementLockAt) == "number" and bombPlantMovementLockAt == bombPlantMovementLockAt then
		v8 = p < bombPlantMovementLockAt
	else
		v8 = false
	end

	if not v8 then
		return 0
	end

	return SpeedProfile.resolveFromWeaponSpeeds(p2, p3, flag3, LocalPlayer:GetAttribute("IsCarryingHostage") == true)
end

local function resetMovementInputState() -- 1 equivalent call inferred from this helper
	local activeController = controls.activeController

	if activeController == nil then
		return
	end

	activeController.moveVector = createVector(0, 0, 0)
	activeController.backwardValue = 0
	activeController.forwardValue = 0
	activeController.rightValue = 0
	activeController.leftValue = 0
end

local function moveCharacter(_, vector: Vector3, flag3: boolean)
	local v8 = v

	if v8 ~= nil then
		v8:MoveFunction(vector, flag3)
	end
end

local function resolveControllerRig(instance)
	if not CharacterResolver.isPlayerCharacter(instance) or CharacterGeneration.Get(instance) == nil then
		return nil
	end

	local resolved = CharacterResolver.resolve(instance)

	if resolved == nil or resolved.Head == nil or resolved.Animator == nil then
		return nil
	end

	return resolved
end

local v8 = Runtime.new({
	PrepareInputFrame = function()
		local v8 = v

		if v8 ~= nil then
			v8:PrepareInputFrame()
		end
	end,
	SampleInput = function(self)
		local v8 = v

		if v8 == nil then
			return nil
		end

		return (v8:SampleInput(self))
	end,
	ConsumePendingWeaponSelection = InventoryController.ConsumePendingMovementWeaponSelect,
	GetUnresolvedWeaponSelection = InventoryController.GetUnresolvedMovementWeaponSelectForResend,
	RestorePendingWeaponSelection = InventoryController.RestorePendingMovementWeaponSelect,
	ResolveWeaponSpeedProfile = resolveWeaponSpeedProfile,
	ResolveBaseMoveSpeed = resolveBaseMoveSpeed,
	ResolveScopedState = resolveScopedState,
	ResolveMovementDiagnosticContext = function(p)
		local v8 = v
		return {
			GameStateAtSnapshot = GameState.GetStateAtTime(p),
			CurrentGameState = GameState.GetState(),
			LocalPlanting = v8 ~= nil and v8.IsPlantingBomb == true,
			ReplicatedPlanting = LocalPlayer:GetAttribute("IsPlantingBomb") == true,
			LocalDefusing = LocalPlayer:GetAttribute("IsLocallyDefusingBomb") == true,
			ReplicatedDefusing = LocalPlayer:GetAttribute("IsDefusingBomb") == true,
			ReplicatedRescuing = LocalPlayer:GetAttribute("IsRescuingHostage") == true,
			CarryingHostage = LocalPlayer:GetAttribute("IsCarryingHostage") == true,
			BombPlantMovementLockAt = LocalPlayer:GetAttribute("BombPlantMovementLockAt")
		}
	end,
	ResolveGeneration = function()
		local v8 = v

		if v8 == nil then
			return nil
		end

		return v8.Generation
	end,
	ResolveMapRoot = function(p)
		return Catalog.FindReplica(p.TopologyEpoch, p.TopologyFingerprint) or Workspace:FindFirstChild("Map")
	end,
	CollisionComposer = collisionComposer,
	PresentLocal = function(p, p2, p3, p4)
		NetStatsController.ObservePresentation(p3)
		MoverTrajectory.SetClientPresentationClock(p3.ServerTick, p3.TickFraction or 0)
		local v8 = v

		if v8 ~= nil then
			v8:Present(p, p2, p3, p4)
		end
	end,
	PresentRemotes = RemoteCharacters.Present,
	OnStepEvents = function(self)
		local v8 = v

		if v8 ~= nil then
			v8:OnStepEvents(self)
		end
	end,
	OnOwnerSnapshotReceived = NetStatsController.ObserveOwnerSnapshot,
	OnRemoteSnapshotReceived = NetStatsController.ObserveRemoteSnapshot,
	OnCommandPacketSent = NetStatsController.ObserveCommandPacket,
	OnReconciled = function(self, p)
		NetStatsController.ObserveReconciliation(self, p)
		local v8 = v

		if v8 ~= nil then
			v8:OnReconciled(self)
		end
	end,
	OnPlayerContactCorrection = function(self, _, p)
		local v8 = v

		if v8 ~= nil then
			v8:OnPlayerContactCorrection(self, p)
		end
	end,
	OnPredictionHitch = function(p)
		NetStatsController.ObservePredictionHitch(p)
	end,
	OnWarning = function(p)
		movementDiagnosticWarning(`[MovementV2] {p}`) -- inferred equivalent call
	end
})

local function clearPendingDoorUses() -- 1 equivalent call inferred from this helper
	for _, v9 in v7 do
		v8:rejectDoorPrediction(v9.MoverId, v9.Revision)
	end

	table.clear(v7)
end

local function requestCurrentMapping() -- 1 equivalent call inferred from this helper
	local v9 = v

	if not v2 or v9 == nil then
		return
	end

	local mapping, v10 = v8:requestMapping(v9.Generation)

	if not mapping then
		movementDiagnosticWarning(`[MovementV2] could not request mapping for generation {v9.Generation}: {v10 or "Unknown"}`) -- inferred equivalent call
	end
end

local function characterAdded(instance, controllerRig)
	local rootPart = controllerRig.RootPart

	if instance:GetAttribute("Dead") == true then
		Ragdoll.ActivateCharacter(instance, RuntimeKinematics.getVelocity(instance, rootPart))
		return nil
	end

	assert(v == nil, "local character rebound before the previous binding was cleaned up")
	resetMovementInputState() -- inferred equivalent call
	rootPart.Anchored = true
	rootPart.AssemblyLinearVelocity = createVector(0, 0, 0)
	rootPart.AssemblyAngularVelocity = createVector(0, 0, 0)

	if not (CaseSceneController.IsActive() or BlackMarketSceneController.IsActive()) then
		local currentCamera = Workspace.CurrentCamera

		if currentCamera ~= nil then
			currentCamera.CameraType = Enum.CameraType.Custom
			currentCamera.CameraSubject = controllerRig.CameraPart
		end
	end

	LocalPlayer.ReplicationFocus = rootPart
	local v9 = Character.new(instance, rootPart)
	v = v9
	v9.Janitor:Add(v9.Landed:Connect(function(p: number?, p2: number?)
		CameraController.OnLanded(p, p2)
	end))
	requestCurrentMapping() -- inferred equivalent call
	local flag3 = false
	local deadChangedConnection = nil

	local function cleanup()
		if flag3 then
			return
		end

		flag3 = true

		if deadChangedConnection ~= nil then
			deadChangedConnection:Disconnect()
		end

		if v ~= v9 then
			return
		end

		clearPendingDoorUses() -- inferred equivalent call
		local generation = v9.Generation
		v8:retireGeneration(generation)
		v = nil
		v9:Destroy()
		task.defer(function()
			local v10

			if LocalPlayer.Character == instance then
				v10 = instance:IsDescendantOf(Workspace) and instance:GetAttribute("Dead") ~= true
			else
				v10 = false
			end

			if not v10 then
				InventoryController.CleanupCurrentLoadout(generation)
			end
		end)
	end

	deadChangedConnection = instance:GetAttributeChangedSignal("Dead"):Connect(function()
		if instance:GetAttribute("Dead") == true then
			Ragdoll.ActivateCharacter(instance, RuntimeKinematics.getVelocity(instance, rootPart))
			cleanup()
		end
	end)
	task.spawn(function()
		if instance.Parent ~= nil and instance:GetAttribute("Dead") ~= true then
			local success, result = pcall(Ragdoll.PrepareCharacter, instance)

			if not success then
				warn(`[LocalCharacter] Ragdoll preparation failed: {result}`)
			end
		end
	end)
	return cleanup
end

local function observeCharacterReady(instance)
	local v9 = nil
	local v10 = nil
	local rootPart = nil
	local animator = nil
	local v11 = false
	local flag3 = false
	local v12 = false

	local function unbind() -- 4 equivalent calls inferred from this helper
		local v13 = v9
		v9 = nil
		v10 = nil
		rootPart = nil
		animator = nil

		if v13 ~= nil then
			v13()
		end
	end

	local function refreshBinding()
		if flag3 then
			return
		end

		local controllerRig = resolveControllerRig(instance)
		local v13 = CharacterGeneration.Get(instance)

		if instance.Parent == nil or controllerRig == nil or v13 == nil then
			unbind() -- inferred equivalent call
		elseif instance:GetAttribute("Dead") == true then
			unbind() -- inferred equivalent call

			if not v11 then
				v11 = true
				characterAdded(instance, controllerRig)
			end
		else
			v11 = false

			if
				v9 ~= nil
				and v10 == v13
				and rootPart == controllerRig.RootPart
				and animator == controllerRig.Animator
			then
				return
			end

			unbind() -- inferred equivalent call
			v9 = characterAdded(instance, controllerRig)

			if v9 ~= nil then
				v10 = v13
				rootPart = controllerRig.RootPart
				animator = controllerRig.Animator
			end
		end
	end

	local function queueRefresh()
		if v12 or flag3 then
			return
		end

		v12 = true
		task.defer(function()
			v12 = false
			refreshBinding()
		end)
	end

	local v13 = {
		instance.DescendantAdded:Connect(refreshBinding),
		instance.DescendantRemoving:Connect(queueRefresh),
		instance:GetAttributeChangedSignal("CharacterType"):Connect(refreshBinding),
		instance:GetAttributeChangedSignal(CharacterGeneration.AttributeName):Connect(refreshBinding),
		instance:GetAttributeChangedSignal("Dead"):Connect(refreshBinding)
	}
	refreshBinding()
	return function()
		flag3 = true

		for _, connection in v13 do
			connection:Disconnect()
		end

		table.clear(v13)
		unbind() -- inferred equivalent call
	end
end

function LocalCharacter.getCurrentCharacter()
	return v
end

function LocalCharacter.GetMovementRuntimeStatus()
	return v8:getStatus()
end

function LocalCharacter.GetRemoteViewTick()
	return v8:getRemoteViewTick()
end

function LocalCharacter.GetWalkState()
	return v ~= nil and v.IsWalking
end

function LocalCharacter.GetCrouchState()
	return v ~= nil and v.IsCrouching
end

function LocalCharacter.walk(flag3: boolean)
	if v ~= nil then
		v:ToggleWalkState(flag3)
	end
end

function LocalCharacter.crouch(flag3: boolean)
	if v ~= nil then
		v:ToggleCrouchInput(flag3)
	end
end

function LocalCharacter.jump(flag3: boolean?)
	if v ~= nil then
		v:SetJumpInput(flag3)
	end
end

function LocalCharacter.PlantBomb()
	if v ~= nil then
		v:PlantBomb()
	end
end

function LocalCharacter.CancelBombPlant()
	if v ~= nil then
		v:CancelBombPlant()
	end
end

function LocalCharacter.IsDoorInUseRange(instance)
	local predictedState = v8:getPredictedState()
	local doorClosedPivot = instance:GetAttribute("DoorClosedPivot")

	if predictedState == nil or typeof(doorClosedPivot) ~= "CFrame" then
		return false
	end

	return (RootFrame.cframe(predictedState).Position - doorClosedPivot.Position).Magnitude <= DoorSwing.InteractRange
end

function LocalCharacter:PredictDoorUse()
	if self:GetAttribute("CanOpen") == false then
		return nil, "DoorLocked"
	end

	local mapping = v8:getMapping()
	local predictedState, _, v9 = v8:getPredictedState()

	if mapping == nil or predictedState == nil or v9 == nil then
		return nil, "MovementPredictionUnavailable"
	end

	local predictDoorUse, v10 = collisionComposer:PredictDoorUse(
		self,
		predictedState.Position,
		v9,
		mapping.SimulationHz
	)

	if predictDoorUse == nil then
		return nil, v10
	end

	local requestId = v6
	v6 = Serial.addUInt32(v6, 1)
	v7[requestId] = {
		Model = self,
		MoverId = predictDoorUse.MoverId,
		Revision = predictDoorUse.Revision
	}
	task.delay(1, function()
		local v11 = v7[requestId]

		if v11 == nil or v11.Model ~= self or v11.Revision ~= predictDoorUse.Revision then
			return
		end

		v7[requestId] = nil
		v8:rejectDoorPrediction(v11.MoverId, v11.Revision)
	end)
	return
		{
			ServerTick = predictDoorUse.ServerTick,
			TargetAngle = predictDoorUse.TargetAngle,
			RequestId = requestId
		},
		nil
end

function LocalCharacter.Initialize()
	if flag then
		return
	end

	flag = true
	controls.moveFunction = moveCharacter
	v8:start()
	v2 = true
	ClientCharacterPresentation.ObserveLocalPlayer()
	Remotes.BreakableDoor.Resolved.Listen(function(data)
		local v9 = v7[data.RequestId]

		if v9 == nil or data.Model ~= v9.Model then
			return
		end

		v7[data.RequestId] = nil

		if data.Accepted then
			return
		end

		local v10, v11 = v8:rejectDoorPrediction(v9.MoverId, v9.Revision)

		if not v10 then
			movementDiagnosticWarning(`[MovementV2] could not reject speculative door use: {v11 or "Unknown"}`) -- inferred equivalent call
		end
	end)
	CharacterResolver.observeCharacter(LocalPlayer, function(p)
		if p == nil then
			return nil
		end

		return (observeCharacterReady(p))
	end)
	Remotes.Character.CharacterDamaged.Listen(function(data)
		if data.VictimUserId == LocalPlayer.UserId then
			if v ~= nil then
				Sound.new("Character"):playOneTime({
					Parent = LocalPlayer.PlayerGui,
					Name = "Character Damaged"
				})
			end
		else
			if data.Melee == true or data.Direction == nil then
				return
			end

			local character = Participants.Character(Participants.FromKey(data.VictimUserId))

			if character ~= nil then
				if data.Headshot == true then
					HitFlinch.flickHead(character, data.Direction)
				else
					HitFlinch.flinchBody(character, data.Direction)
				end
			end
		end
	end)
end

function LocalCharacter.Start()
	if flag2 then
		return
	end

	flag2 = true
	Router.observerRouter("Plant Bomb", LocalCharacter.PlantBomb)
	Router.observerRouter("Cancel Bomb Plant", LocalCharacter.CancelBombPlant)
	Router.observerRouter("GetCurrentCharacter", LocalCharacter.getCurrentCharacter)
	Router.observerRouter("GetRemoteViewTick", LocalCharacter.GetRemoteViewTick)
end

return LocalCharacter