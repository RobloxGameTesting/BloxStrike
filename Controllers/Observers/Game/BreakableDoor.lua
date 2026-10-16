local createVector = vector.create
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local MoverTrajectory = require(ReplicatedStorage.MovementV2.MoverTrajectory)
local DiagnosticProtocol = require(ReplicatedStorage.MovementV2.DiagnosticProtocol)
local DoorSwing = require(ReplicatedStorage.MovementV2.DoorSwing)
local Serial = require(ReplicatedStorage.MovementV2.Serial)
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Sound = require(ReplicatedStorage.Classes.Sound)
local LocalPlayer = Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local v = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
local v2 = {}
local connection = nil
local SwingRate = DoorSwing.SwingRate

local function diagnosticsEnabled() -- 3 equivalent calls inferred from this helper
	return DiagnosticProtocol.shouldOutputForPlayer(LocalPlayer)
		and Workspace:GetAttribute("MovementV2DoorDebug") == true
end

local v3 = {}

local function captureLayout(folder, state)
	local breakableDoorHingePivot = folder:FindFirstChild("BreakableDoorHingePivot")

	if breakableDoorHingePivot == nil or not breakableDoorHingePivot:IsA("BasePart") then
		return false
	end

	local doorClosedPivot = folder:GetAttribute("DoorClosedPivot")
	local hingePosition

	if typeof(doorClosedPivot) == "CFrame" then
		hingePosition = doorClosedPivot.Position
	else
		hingePosition = breakableDoorHingePivot.Position
	end

	state.HingePosition = hingePosition
	table.clear(state.LayoutParts)
	table.clear(state.LayoutOffsets)

	for _, part in folder:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		state.LayoutParts[#state.LayoutParts + 1] = part
		state.LayoutOffsets[#state.LayoutOffsets + 1] = breakableDoorHingePivot.CFrame:ToObjectSpace(part.CFrame)
	end

	return true
end

local function setPose(instance, state, cframe: CFrame)
	if instance.Parent == nil or state.HingePosition == nil and not captureLayout(instance, state) then
		return
	end

	local hingePosition = state.HingePosition
	local magnitude = (cframe.Position - hingePosition).Magnitude

	if magnitude > 0.25 and not state.WarnedDrift then
		state.WarnedDrift = true
		local descriptor = state.Descriptor
		warn(string.format(
			"[BreakableDoor] presented pose left its hinge by %.2f studs model=%s id=%s revision=%s moving=%s",
			magnitude,
			instance:GetFullName(),
			tostring(descriptor and descriptor.Id),
			tostring(descriptor and descriptor.Revision),
			(tostring(descriptor and descriptor.Moving))
		))
	end

	local v4 = CFrame.new(hingePosition) * cframe.Rotation
	local layoutParts = {}
	local v5 = {}

	for k, layoutPart in state.LayoutParts do
		if layoutPart.Parent == nil then
			continue
		end

		layoutParts[#layoutParts + 1] = layoutPart
		v5[#v5 + 1] = v4 * state.LayoutOffsets[k]
	end

	workspace:BulkMoveTo(layoutParts, v5, Enum.BulkMoveMode.FireCFrameChanged)
end

local function rotationDistance(cframe: CFrame, cframe2: CFrame) -- 3 equivalent calls inferred from this helper
	local _, v4 = cframe.Rotation:ToObjectSpace(cframe2.Rotation):ToAxisAngle()
	return (math.abs(v4))
end

local function posesDiffer(cframe: CFrame, cframe2: CFrame) -- 3 equivalent calls inferred from this helper
	local _, v4 = cframe.Rotation:ToObjectSpace(cframe2.Rotation):ToAxisAngle()
	return math.abs(v4) > 0.0001 or (cframe.Position - cframe2.Position).Magnitude > 0.0001
end

local function swingRate(data) -- 2 equivalent calls inferred from this helper
	if not data.Moving then
		return SwingRate
	end

	local startPose = data.StartPose
	local targetPose = data.TargetPose
	return (math.max(rotationDistance(startPose, targetPose) / math.max(data.DurationSeconds, 0.001), SwingRate)) -- inferred equivalent call
end

local function presentationTarget(descriptor, serverTimeNow: number)
	local clientPresentation = MoverTrajectory.GetClientPresentation(descriptor.Id)
	local clientPresentationClock, v4 = MoverTrajectory.GetClientPresentationClock()

	if clientPresentation == nil or clientPresentationClock == nil then
		local time = MoverTrajectory.EvaluateTime(descriptor, serverTimeNow)
		return {
			Pose = time,
			RestPose = time,
			Predicted = false,
			Moving = MoverTrajectory.PresentationMoving(descriptor, serverTimeNow),
			Discontinuity = 0,
			Descriptor = descriptor
		}
	end

	local deltaUInt32 = Serial.deltaUInt32(clientPresentationClock, clientPresentation.ServerTick)
	local previousPose

	if deltaUInt32 == 0 then
		previousPose = clientPresentation.PreviousPose:Lerp(clientPresentation.Pose, v4)
	elseif deltaUInt32 < 0 then
		previousPose = clientPresentation.PreviousPose
	else
		previousPose = clientPresentation.Pose
	end

	return {
		Pose = previousPose,
		RestPose = clientPresentation.Pose,
		Predicted = true,
		Moving = clientPresentation.PreviousPose ~= clientPresentation.Pose,
		Discontinuity = clientPresentation.Discontinuity,
		Descriptor = clientPresentation.Descriptor
	}
end

local function stepTowardPose(currentPose: CFrame, pose: CFrame, descriptor, p: number)
	local v4 = rotationDistance(currentPose, pose) -- inferred equivalent call
	local magnitude = (pose.Position - currentPose.Position).Magnitude

	if v4 <= 0.0001 and magnitude <= 0.0001 then
		return pose
	end

	local magnitude2 = (descriptor.TargetPose.Position - descriptor.StartPose.Position).Magnitude
	local v5 = math.max(descriptor.DurationSeconds, 0.001)
	local v6 = swingRate(descriptor) -- inferred equivalent call
	local v7 = math.max(magnitude2 / v5, 8)
	local v8 = 1

	if v4 > 0.0001 then
		v8 = math.min(v8, math.min(v6 * 1.5 * math.max(p, 0), 0.20943951023931956) / v4)
	end

	if magnitude > 0.0001 then
		v8 = math.min(v8, v7 * 1.5 * math.max(p, 0) / magnitude)
	end

	return currentPose:Lerp(pose, (math.clamp(v8, 0, 1)))
end

local function correctedPose(state, data, p: number)
	if state.SeenDiscontinuity ~= data.Discontinuity then
		state.SeenDiscontinuity = data.Discontinuity
		local currentPose = state.CurrentPose
		state.CorrectionOffset = nil

		if currentPose ~= nil and posesDiffer(currentPose, data.Pose) then -- inferred equivalent call
			local cframe = data.Pose:ToObjectSpace(currentPose)
			local _, v4 = cframe:ToAxisAngle()
			local v5 = math.abs(v4)
			local v6 = math.max(v5 / swingRate(data.Descriptor), cframe.Position.Magnitude / 8) -- inferred equivalent call
			state.CorrectionOffset = cframe
			state.CorrectionElapsed = 0
			state.CorrectionSeconds = math.min(0.1, v6)
		end
	end

	local correctionOffset = state.CorrectionOffset

	if correctionOffset == nil then
		return data.Pose
	end

	state.CorrectionElapsed += math.max(p, 0)
	local v4 = 1 - state.CorrectionElapsed / math.max(state.CorrectionSeconds, 0.001)

	if v4 <= 0 then
		state.CorrectionOffset = nil
		return data.Pose
	else
		return data.Pose * CFrame.identity:Lerp(correctionOffset, v4)
	end
end

local function stepVisuals(p: number)
	local serverTimeNow = workspace:GetServerTimeNow()
	local v4 = false

	for k, v5 in v3 do
		local descriptor = v5.Descriptor

		if k.Parent == nil then
			v3[k] = nil
		elseif descriptor ~= nil then
			local v6 = presentationTarget(descriptor, serverTimeNow)
			local currentPose = v5.CurrentPose or k:GetPivot()
			local currentPose2

			if v6.Predicted then
				currentPose2 = correctedPose(v5, v6, p)
			else
				currentPose2 = stepTowardPose(currentPose, v6.Pose, descriptor, p)
			end

			if
				diagnosticsEnabled() -- inferred equivalent call
				and descriptor.Moving
				and v5.LoggedMotionRevision ~= descriptor.Revision
				and posesDiffer(currentPose2, currentPose) -- inferred equivalent call
			then
				v5.LoggedMotionRevision = descriptor.Revision
				print(string.format(
					"[MovementV2.Door] visual-start id=%d revision=%d clientTime=%.6f descriptorAge=%.4f",
					descriptor.Id,
					descriptor.Revision,
					serverTimeNow,
					serverTimeNow - descriptor.StartServerTime
				))
			end

			v5.CurrentPose = currentPose2
			setPose(k, v5, currentPose2)

			if
				not v6.Moving
				and v5.CorrectionOffset == nil
				and not MoverTrajectory.PresentationMoving(descriptor, serverTimeNow)
			then
				local restPose = v6.RestPose

				if not (rotationDistance(currentPose2, restPose) > 0.0001 or (currentPose2.Position - restPose.Position).Magnitude > 0.0001) then -- inferred equivalent call
					continue
				end
			end

			v4 = true
		end
	end

	if not v4 and connection ~= nil then
		connection:Disconnect()
		connection = nil
	end
end

local function ensureRenderConnection() -- 2 equivalent calls inferred from this helper
	if connection == nil then
		connection = RunServiceController.BindToRenderStep(
			"Observers.Game.BreakableDoor.StepVisuals",
			Enum.RenderPriority.Last.Value,
			stepVisuals
		)
	end
end

local function refreshTrajectory(model)
	local v4 = v3[model]

	if v4 == nil then
		return
	end

	local descriptor = MoverTrajectory.Read(model)

	if descriptor == nil then
		return
	end

	local v5 = v4.Descriptor == nil
	local revision

	if v4.Descriptor ~= nil then
		revision = v4.Descriptor.Revision
	end

	v4.Descriptor = descriptor
	local serverTimeNow = workspace:GetServerTimeNow()
	local v6 = presentationTarget(descriptor, serverTimeNow)

	if diagnosticsEnabled() and descriptor.Revision ~= revision then -- inferred equivalent call
		print(string.format(
			"[MovementV2.Door] descriptor id=%d revision=%d moving=%s clientTime=%.6f startTime=%.6f descriptorAge=%.4f",
			descriptor.Id,
			descriptor.Revision,
			tostring(descriptor.Moving),
			serverTimeNow,
			descriptor.StartServerTime,
			serverTimeNow - descriptor.StartServerTime
		))
	end

	if v5 then
		v4.CurrentPose = v6.Pose
		v4.SeenDiscontinuity = v6.Discontinuity
		setPose(model, v4, v6.Pose)
	end

	local currentPose = v4.CurrentPose or model:GetPivot()

	if descriptor.Moving or v6.Moving or v6.Discontinuity ~= v4.SeenDiscontinuity then
		ensureRenderConnection() -- inferred equivalent call
	elseif posesDiffer(currentPose, v6.Pose) then -- inferred equivalent call
		ensureRenderConnection() -- inferred equivalent call
	end
end

local function useMouseDoor()
	local target = mouse.Target

	while target ~= nil do
		if target:IsA("Model") and v2[target] then
			if not CharacterController.IsDoorInUseRange(target) then
				break
			end

			if diagnosticsEnabled() then -- inferred equivalent call
				print(string.format(
					"[MovementV2.Door] use-send source=Mouse model=%s clientTime=%.6f",
					target:GetFullName(),
					workspace:GetServerTimeNow()
				))
			end

			local predictDoorUse = CharacterController.PredictDoorUse(target)
			local send = Remotes.BreakableDoor.Use.Send
			local serverTick

			if predictDoorUse ~= nil then
				serverTick = predictDoorUse.ServerTick
			end

			local targetAngle

			if predictDoorUse ~= nil then
				targetAngle = predictDoorUse.TargetAngle
			end

			local requestId

			if predictDoorUse ~= nil then
				requestId = predictDoorUse.RequestId
			end

			send({
				Model = target,
				ServerTick = serverTick,
				TargetAngle = targetAngle,
				RequestId = requestId
			})
			break
		else
			target = target.Parent
		end
	end
end

mouse.Button1Down:Connect(function()
	if not v then
		useMouseDoor()
	end
end)

local function releaseVisualStage(instance, i: number)
	local v4 = v3[instance]

	if v4 == nil then
		return
	end

	local vector = Vector3.new(
		instance:GetAttribute("BreakDirectionX") or 0,
		instance:GetAttribute("BreakDirectionY") or 0,
		instance:GetAttribute("BreakDirectionZ") or 0
	)
	local v5 = not (vector.Magnitude > 0) and createVector(0, 0, 1) or vector.Unit
	local debris = workspace:FindFirstChild("Debris") or workspace

	for _, v6 in v4.StageParts[i] or {} do
		if v6.Parent == nil then
			continue
		end

		local clone = v6:Clone()
		clone.Transparency = v4.Transparencies[v6] or 0
		clone.Anchored = false
		clone.CanCollide = true
		clone.CanQuery = false
		clone.CanTouch = true
		clone.CFrame = v6.CFrame
		clone:SetAttribute("BreakableDoorDebris", true)
		local touchedConnection = nil
		touchedConnection = clone.Touched:Connect(function(otherPart)
			if
				not otherPart.CanCollide
				or otherPart:GetAttribute("BreakableDoorDebris") == true
				or otherPart:IsDescendantOf(instance)
			then
				return
			end

			if touchedConnection ~= nil then
				touchedConnection:Disconnect()
				touchedConnection = nil
			end

			Sound.new("BreakableDoor"):PlaySoundAtPosition({
				Position = clone.Position,
				Class = "BreakableDoor",
				Name = "Part Hit Ground"
			})
		end)
		clone.Parent = debris
		Debris:AddItem(clone, 8)
		clone:ApplyImpulse((v5 + createVector(0, 0.35, 0)) * clone.AssemblyMass * math.random(20, 35))
	end
end

local function applyStage(model)
	local v4 = v3[model]

	if v4 == nil then
		return
	end

	local stage = model:GetAttribute("Stage") or 0

	for i = v4.Stage + 1, stage do
		releaseVisualStage(model, i)
	end

	v4.Stage = stage
end

return Observers.observeTag("BreakableDoor", function(model)
	if not model:IsA("Model") then
		return nil
	end

	local maid = Janitor.new()
	local v4 = {
		Stage = model:GetAttribute("Stage") or 0,
		StageParts = {},
		Transparencies = {},
		CorrectionElapsed = 0,
		CorrectionSeconds = 0,
		LayoutParts = {},
		LayoutOffsets = {},
		WarnedDrift = false
	}
	v2[model] = true
	v3[model] = v4

	for _, part in model:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end

		local v5 = tonumber(part.Name:match("^Stage(%d)Break$"))

		if v5 == nil then
			continue
		end

		v4.StageParts[v5] = v4.StageParts[v5] or {}
		v4.StageParts[v5][#v4.StageParts[v5] + 1] = part
		v4.Transparencies[part] = part.Transparency
	end

	refreshTrajectory(model)
	maid:Add(MoverTrajectory.ClientDescriptorChanged:Connect(function(p)
		if model:GetAttribute(MoverTrajectory.Attributes.Id) == p then
			refreshTrajectory(model)
		end
	end))

	for _, v5 in { MoverTrajectory.Attributes.Id, MoverTrajectory.Attributes.Revision } do
		maid:Add(model:GetAttributeChangedSignal(v5):Connect(function()
			refreshTrajectory(model)
		end))
	end

	maid:Add(model:GetAttributeChangedSignal("Stage"):Connect(function()
		applyStage(model)
	end))
	maid:Add(function()
		v2[model] = nil
		v3[model] = nil

		if next(v3) == nil and connection ~= nil then
			connection:Disconnect()
			connection = nil
		end
	end)
	return function()
		maid:Destroy()
	end
end)