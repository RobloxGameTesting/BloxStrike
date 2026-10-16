local createVector = vector.create
local AimAssistController = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local FlashEffect = require(ReplicatedStorage.Components.Common.VFXLibary.FlashEffect)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local userPlatform = GetUserPlatform()
local v

if table.find(userPlatform, "Mobile") == nil then
	v = false
else
	v = #userPlatform <= 1
end

local CurrentCamera = Workspace.CurrentCamera
local v2 = true
local v3 = true
local player = Constants.AIM_ASSIST_CONFIGS.PLAYER
local v4 = { ["Counter-Terrorists"] = true, Terrorists = true }
local v5 = {
	AimHeight = 0.6,
	PullAngle = 0.17453292519943295,
	PullRate = 3.2,
	IdlePullShare = 0.25,
	MaxPullSpeed = 0.5235987755982988,
	SettleAngle = 0.002617993877991494,
	TrackingStrength = 0.55,
	TrackingAngle = 0.12217304763960307,
	MaxTrackingSpeed = 3,
	StickDeadzone = 0.15
}
local v6 = nil
local v7 = -1e999
local v8 = nil
local v9 = nil
local v10 = 0
local v11 = 0

local function clipSlab(p: number, p2: number, p3: number, p4: number, p5: number, p6: number)
	if math.abs(p2) < 0.0001 then
		if p < p3 or p4 < p then
			return nil, p6
		end

		return p5, p6
	else
		local v12 = 1 / p2
		local v13 = (p3 - p) * v12
		local v14 = (p4 - p) * v12

		if v14 < v13 then
			v14, v13 = v13, v14
		end

		if p5 < v13 then
			p5 = v13
		end

		if v14 < p6 then
			p6 = v14
		end

		if p6 < p5 then
			return nil, p6
		end

		return p5, p6
	end
end

local function rayIntersectsAABB(vector: Vector3, vector2: Vector3, vector3: Vector3, vector4: Vector3, p: number)
	local x = vector.X
	local x2 = vector2.X
	local x3 = vector3.X
	local x4 = vector4.X
	local v12 = 0
	local v13

	if math.abs(x2) < 0.0001 then
		if x < x3 or x4 < x then
			v13 = p
			v12 = nil
		else
			v13 = p
		end
	else
		local v14 = 1 / x2
		local v15 = (x3 - x) * v14
		v13 = (x4 - x) * v14

		if v13 < v15 then
			v13, v15 = v15, v13
		end

		if v12 < v15 then
			v12 = v15
		end

		if not (v13 < p) then
			v13 = p
		end

		if v13 < v12 then
			v12 = nil
		end
	end

	if not v12 then
		return false
	end

	local y = vector.Y
	local y2 = vector2.Y
	local y3 = vector3.Y
	local y4 = vector4.Y

	if math.abs(y2) < 0.0001 then
		if y < y3 or y4 < y then
			v12 = nil
		end
	else
		local v14 = 1 / y2
		local v15 = (y3 - y) * v14
		local v16 = (y4 - y) * v14

		if v16 < v15 then
			v16, v15 = v15, v16
		end

		if not (v12 < v15) then
			v15 = v12
		end

		if not (v16 < v13) then
			v16 = v13
		end

		if v16 < v15 then
			v13 = v16
			v12 = nil
		else
			v13 = v16
			v12 = v15
		end
	end

	if not v12 then
		return false
	end

	local z = vector.Z
	local z2 = vector2.Z
	local z3 = vector3.Z
	local z4 = vector4.Z

	if math.abs(z2) < 0.0001 then
		if z < z3 or z4 < z then
			v12 = nil
		end
	else
		local v14 = 1 / z2
		local v15 = (z3 - z) * v14
		local v16 = (z4 - z) * v14

		if v16 < v15 then
			v16, v15 = v15, v16
		end

		if not (v12 < v15) then
			v15 = v12
		end

		if not (v16 < v13) then
			v16 = v13
		end

		if v16 < v15 then
			v13 = v16
			v12 = nil
		else
			v13 = v16
			v12 = v15
		end
	end

	return v12 ~= nil and v12 >= 0 and v12 <= p
end

local function doesRaycastIntersectSmoke(vector: Vector3, vector2: Vector3, magnitude: number)
	local debris = Workspace:FindFirstChild("Debris")

	if not debris then
		return false
	end

	for _, folder in ipairs(debris:GetChildren()) do
		if not (folder.Name:match("^VoxelSmoke_") and folder:IsA("Folder")) then
			continue
		end

		for _, part in ipairs(folder:GetChildren()) do
			if not (part:IsA("BasePart") and part.Name == "SmokeVoxel") then
				continue
			end

			local size = part.Size
			local position = part.Position

			if rayIntersectsAABB(vector, vector2, position - size / 2, position + size / 2, magnitude) then
				return true
			end
		end
	end

	return false
end

local function isEnemyTeam(team) -- 1 equivalent call inferred from this helper
	local team2 = LocalPlayer:GetAttribute("Team")

	if v4[team2] and v4[team] then
		return workspace:GetAttribute("Gamemode") == "Deathmatch" or team2 ~= team
	end

	return false
end

local function isEnemyValid(instance) -- 2 equivalent calls inferred from this helper
	return isEnemyTeam(instance:GetAttribute("Team")) -- inferred equivalent call
end

local function isBotTarget(model)
	local isA = model:IsA("Model")

	if not isA then
		return isA
	end

	if
		model:GetAttribute("Bot") ~= true
		or model:GetAttribute("Dead") == true
		or not ((tonumber(model:GetAttribute("Health")) or 1) > 0)
		or model:GetAttribute("ClientCharacterPresentationVisible") == false
		or model.PrimaryPart == nil
	then
		isA = false
		return false
	end

	local team = model:GetAttribute("Team")
	local team2 = LocalPlayer:GetAttribute("Team")

	if v4[team2] and v4[team] then
		isA = workspace:GetAttribute("Gamemode") == "Deathmatch" or team2 ~= team
		return isA
	else
		return false
	end
end

local function getTargetCandidates()
	local result = {}

	for _, v12 in ipairs(Players:GetPlayers()) do
		if not (v12 ~= LocalPlayer and isEnemyValid(v12)) then -- inferred equivalent call
			continue
		end

		local playerCharacter = CharacterResolver.getPlayerCharacter(v12)

		if playerCharacter and playerCharacter.PrimaryPart and CharacterResolver.isAliveCharacter(playerCharacter) then
			table.insert(result, playerCharacter)
		end
	end

	local characters = Workspace:FindFirstChild("Characters")

	if characters then
		for _, child in ipairs(characters:GetChildren()) do
			if isBotTarget(child) then
				table.insert(result, child)
			end
		end
	end

	return result
end

local function getLocalRaycastParams()
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local filterDescendantsInstances = {}
	local localCharacter = CharacterResolver.getLocalCharacter()

	if localCharacter then
		table.insert(filterDescendantsInstances, localCharacter)
	end

	local map = Workspace:FindFirstChild("Map")
	local barriers

	if map then
		barriers = map:FindFirstChild("Barriers")
	end

	if barriers then
		table.insert(filterDescendantsInstances, barriers)
	end

	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	return raycastParams
end

local function isTargetVisible(instance, position: Vector3)
	local position2 = instance.PrimaryPart.Position
	local unit = (position2 - position).Unit
	local magnitude = (position2 - position).Magnitude

	if doesRaycastIntersectSmoke(position, unit, magnitude) then
		return false
	end

	local raycastResult = Workspace:Raycast(position, unit * magnitude, (getLocalRaycastParams()))
	return raycastResult == nil or instance:IsAncestorOf(raycastResult.Instance)
end

local function findBestTarget(cframe: CFrame)
	local now = os.clock()

	if now - v7 < 1 / 240 then
		return v6
	end

	local v12 = 0
	local v13 = nil

	for _, v14 in ipairs((getTargetCandidates())) do
		local position = v14.PrimaryPart.Position
		local position2 = cframe.Position
		local magnitude = (position - position2).Magnitude

		if player.TargetSelection.MaxDistance < magnitude then
			continue
		end

		local unit = (position - position2).Unit
		local v15 = math.acos((math.clamp(cframe.LookVector:Dot(unit), -1, 1)))

		if player.TargetSelection.MaxAngle < v15 or not isTargetVisible(v14, position2) then
			continue
		end

		local v16 = v15 / player.TargetSelection.MaxAngle
		local v17 = 1 / (magnitude + 1) * (1 - v16)

		if v14 == v8 then
			v17 *= 1.6
		end

		if not (v12 < v17) then
			continue
		end

		v13 = v14
		v12 = v17
	end

	v8 = v13
	v6 = v13
	v7 = now
	return v13
end

local function calculateFrictionMultiplier(cframe: CFrame, instance)
	if not instance then
		return player.Friction.MaxSensitivity
	end

	local position = instance.PrimaryPart.Position
	local worldToViewportPoint, v12 = CurrentCamera:WorldToViewportPoint(position)

	if not v12 or worldToViewportPoint.Z < 0 then
		return player.Friction.MaxSensitivity
	end

	local halfViewportSize = CurrentCamera.ViewportSize / 2
	local vector = Vector2.new(halfViewportSize.X, halfViewportSize.Y)
	local magnitude = (Vector2.new(worldToViewportPoint.X, worldToViewportPoint.Y) - vector).Magnitude
	local magnitude2 = (position - cframe.Position).Magnitude
	local v13 = 2 / magnitude2 * halfViewportSize.Y * 2
	local v14 = player.Friction.BubbleRadius * (halfViewportSize.Y / magnitude2) * 2

	if v14 + v13 / 2 < magnitude then
		return player.Friction.MaxSensitivity
	end

	local v15 = math.clamp(math.max(0, magnitude - v13 / 2) / math.max(v14, 1), 0, 1)
	local v16 = v15 * v15 * (3 - v15 * 2)
	local minSensitivity = player.Friction.MinSensitivity
	return minSensitivity + (player.Friction.MaxSensitivity - minSensitivity) * v16
end

local function isUsingController() -- 2 equivalent calls inferred from this helper
	return UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
end

local function isAssistEnabled() -- 4 equivalent calls inferred from this helper
	if v or UserInputService.PreferredInput == Enum.PreferredInput.Touch then
		return v2
	end

	if isUsingController() then -- inferred equivalent call
		return v3
	end

	return false
end

local function isFeatureActive(flag: boolean)
	if flag then
		flag = isAssistEnabled() and not FlashEffect.IsFlashed() -- inferred equivalent call
	end

	return flag
end

local function canTarget() -- 3 equivalent calls inferred from this helper
	return CurrentCamera ~= nil and CharacterResolver.getLocalCharacter() ~= nil
end

function AimAssistController.GetFrictionMultiplier()
	local enabled = player.Friction.Enabled

	if enabled then
		enabled = isAssistEnabled() and not FlashEffect.IsFlashed() -- inferred equivalent call
	end

	if enabled and canTarget() then -- inferred equivalent call
		local cframe = CurrentCamera.CFrame
		return (calculateFrictionMultiplier(cframe, findBestTarget(cframe)))
	end

	return player.Friction.MaxSensitivity
end

local function findTargetWithRaycast(cframe: CFrame)
	local position = cframe.Position
	local maxDistance = player.Magnetism.MaxDistance
	local localRaycastParams = getLocalRaycastParams()
	local halfMaxAngleHorizontal = player.Magnetism.MaxAngleHorizontal / 2
	local halfMaxAngleVertical = player.Magnetism.MaxAngleVertical / 2

	for i = -1, 1 do
		for j = -1, 1 do
			local lookVector = (cframe * CFrame.Angles(j * halfMaxAngleVertical, i * halfMaxAngleHorizontal, 0)).LookVector
			local raycastResult = Workspace:Raycast(position, lookVector * maxDistance, localRaycastParams)

			if not raycastResult then
				continue
			end

			local model = raycastResult.Instance:FindFirstAncestorOfClass("Model")

			if not model then
				continue
			end

			local parent = model

			while parent and parent:IsA("Model") do
				if parent:GetAttribute("Bot") == true then
					model = parent
					break
				else
					parent = parent.Parent
				end
			end

			local botTarget = isBotTarget(model)

			if not botTarget and CharacterResolver.isPlayerCharacter(model) then
				local playerFromCharacter = CharacterResolver.getPlayerFromCharacter(model)

				if playerFromCharacter == nil then
					botTarget = false
				else
					botTarget = isEnemyValid(playerFromCharacter) and CharacterResolver.isAliveCharacter(model) -- inferred equivalent call
				end
			end

			if not botTarget then
				continue
			end

			local magnitude = (raycastResult.Position - position).Magnitude

			if magnitude <= maxDistance and not doesRaycastIntersectSmoke(position, lookVector, magnitude) then
				return model
			end
		end
	end

	return nil
end

local function calculateMagnetismRotation(cframe: CFrame, instance, p: number)
	if not instance.PrimaryPart then
		return Vector2.zero
	end

	local position = instance.PrimaryPart.Position
	local position2 = cframe.Position
	local lookVector = cframe.LookVector

	if (position - position2).Magnitude > player.Magnetism.MaxDistance then
		return Vector2.zero
	end

	local unit = (position - position2).Unit
	local v12 = math.acos((math.clamp(
		Vector3.new(lookVector.X, 0, lookVector.Z).Unit:Dot(Vector3.new(unit.X, 0, unit.Z).Unit),
		-1,
		1
	)))

	if
		player.Magnetism.MaxAngleHorizontal < v12
		or v12 <= player.Magnetism.StopThreshold
		or v12 > 1.5707963267948966
	then
		return Vector2.zero
	end

	local v13 = math.atan2(-lookVector.X, -lookVector.Z)
	local v14 = math.atan2(-unit.X, -unit.Z) - v13

	if v14 > 3.141592653589793 then
		v14 -= 6.283185307179586
	elseif v14 < -3.141592653589793 then
		v14 += 6.283185307179586
	end

	local v15 = math.abs(v14)

	if v15 < 0.001 then
		return Vector2.zero
	end

	local v16 = math.min(player.Magnetism.PullStrength * p, v15)
	local v17 = v14 > 0 and 1 or -1
	return Vector2.new(v17 * v16, 0)
end

local function calculateVerticalMagnetismRotation(cframe: CFrame, instance, p: number, flag: boolean)
	local head = instance:FindFirstChild("Head")

	if not head then
		return 0
	end

	local position = head.Position
	local verticalMagnetism = player.VerticalMagnetism
	local position2 = cframe.Position

	if (position - position2).Magnitude > verticalMagnetism.MaxDistance then
		return 0
	end

	local unit = (position - position2).Unit
	local v12 = math.asin((math.clamp(cframe.LookVector.Y, -1, 1)))
	local v13 = math.asin((math.clamp(unit.Y, -1, 1))) - v12
	local v14 = math.abs(v13)

	if
		not flag and verticalMagnetism.MaxAngleVertical < v14
		or (v14 <= verticalMagnetism.StopThreshold or v14 < 0.001)
	then
		return 0
	end

	local v15 = math.min(verticalMagnetism.PullStrength * p, v14)
	return (v13 > 0 and 1 or -1) * v15
end

local function getYawPitch(vector: Vector3) -- 2 equivalent calls inferred from this helper
	return math.atan2(-vector.X, -vector.Z), (math.asin((math.clamp(vector.Y, -1, 1))))
end

local function wrapAngle(p: number) -- 2 equivalent calls inferred from this helper
	return (p + 3.141592653589793) % 6.283185307179586 - 3.141592653589793
end

local function getStickActivity()
	local v12 = 0

	for _, v13 in UserInputService:GetConnectedGamepads() do
		for _, v14 in UserInputService:GetGamepadState(v13) do
			if v14.KeyCode == Enum.KeyCode.Thumbstick1 or v14.KeyCode == Enum.KeyCode.Thumbstick2 then
				v12 = math.max(v12, Vector2.new(v14.Position.X, v14.Position.Y).Magnitude)
			end
		end
	end

	return (math.clamp((v12 - 0.15) / 0.85 * 1.5, 0, 1))
end

local function getAimPoint(instance)
	local primaryPart = instance.PrimaryPart

	if not primaryPart then
		return nil
	end

	local head = instance:FindFirstChild("Head")

	if head and head:IsA("BasePart") then
		return primaryPart.Position:Lerp(head.Position, 0.6)
	end

	return primaryPart.Position
end

local function calculateControllerMagnetism(cframe: CFrame, instance, p: number)
	local primaryPart = instance.PrimaryPart
	local position

	if primaryPart then
		local head = instance:FindFirstChild("Head")

		if head and head:IsA("BasePart") then
			position = primaryPart.Position:Lerp(head.Position, v5.AimHeight)
		else
			position = primaryPart.Position
		end
	end

	if not position then
		v9 = nil
		return Vector2.zero
	end

	local v12 = position - cframe.Position
	local magnitude = v12.Magnitude

	if magnitude < 1 or player.Magnetism.MaxDistance < magnitude then
		v9 = nil
		return Vector2.zero
	end

	local v13 = v12 / magnitude
	local yawPitch, v14 = getYawPitch(v13) -- inferred equivalent call
	local yawPitch2, v15 = getYawPitch(cframe.LookVector) -- inferred equivalent call
	local v16 = math.acos((math.clamp(cframe.LookVector:Dot(v13), -1, 1)))
	local stickActivity = getStickActivity()
	local v17 = 0
	local v18 = 0

	if v9 == instance and v16 < 0.12217304763960307 then
		local angle = wrapAngle(yawPitch - v10) -- inferred equivalent call
		local v19 = v14 - v11
		local v20 = 3 * p

		if math.abs(angle) < v20 and math.abs(v19) < v20 then
			local v21 = 0.55 * stickActivity * (1 - v16 / 0.12217304763960307)
			v17 = angle * v21
			v18 = v19 * v21
		end
	end

	v9 = instance
	v10 = yawPitch
	v11 = v14
	local v19, v20

	if v16 > 0.002617993877991494 and v16 < 0.17453292519943295 then
		local v21 = 1 - (v16 / 0.17453292519943295) ^ 2
		local v22 = 0.25 + 0.75 * stickActivity
		local v23 = (1 - math.exp(-3.2 * p)) * v21 * v22
		v19 = wrapAngle(yawPitch - yawPitch2) * v23 -- inferred equivalent call
		v20 = (v14 - v15) * v23
		local v24 = math.sqrt(v19 * v19 + v20 * v20)
		local v25 = 0.5235987755982988 * p

		if v25 < v24 then
			v19 = v19 * v25 / v24
			v20 = v20 * v25 / v24
		end
	else
		v19 = 0
		v20 = 0
	end

	return Vector2.new(v19 + v17, v20 + v18)
end

function AimAssistController.GetMagnetismRotation(value: number?)
	local enabled = player.Magnetism.Enabled

	if enabled then
		enabled = isAssistEnabled() and not FlashEffect.IsFlashed() -- inferred equivalent call
	end

	if enabled and canTarget() then -- inferred equivalent call
		local v12 = value or 1 / 60
		local cframe = CurrentCamera.CFrame
		local v13 = findBestTarget(cframe) or findTargetWithRaycast(cframe)

		if not v13 then
			v9 = nil
			return Vector2.zero
		end

		if isUsingController() then -- inferred equivalent call
			return calculateControllerMagnetism(cframe, v13, v12)
		end

		v9 = nil
		local v14 = calculateMagnetismRotation(cframe, v13, v12)
		local v15 = math.abs(v14.X) > 0.0001
		local v16 = not player.VerticalMagnetism.Enabled and 0
			or calculateVerticalMagnetismRotation(cframe, v13, v12, v15)
		return Vector2.new(v14.X, v16)
	end

	v9 = nil
	return Vector2.zero
end

function AimAssistController.GetRecoilAssistMultiplier()
	local enabled = player.RecoilAssist.Enabled

	if enabled then
		enabled = isAssistEnabled() and not FlashEffect.IsFlashed() -- inferred equivalent call
	end

	if
		not enabled
		or player.RecoilAssist.RequiresTarget and not (canTarget() and findBestTarget(CurrentCamera.CFrame)) -- inferred equivalent call
	then
		return 0
	end

	return player.RecoilAssist.ReductionAmount
end

function AimAssistController.GetRecoilAssistScale()
	local recoilAssistMultiplier = AimAssistController.GetRecoilAssistMultiplier()

	if recoilAssistMultiplier <= 0 then
		return createVector(1, 1, 1)
	end

	local v12

	if v then
		v12 = math.max(recoilAssistMultiplier, player.RecoilAssist.HorizontalReductionAmount)
	else
		v12 = recoilAssistMultiplier
	end

	return (Vector3.new(1 - recoilAssistMultiplier, 1 - v12, 1))
end

local flag = false

function AimAssistController.Initialize()
	if flag then
		return
	end

	flag = true
	DataController.CreateListener(LocalPlayer, "Settings.Game.Other.Mobile Aim Assist", function(flag2: boolean?)
		v2 = flag2 ~= false
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Game.Other.Controller Aim Assist", function(flag2: boolean?)
		v3 = flag2 ~= false
	end)
end

return AimAssistController