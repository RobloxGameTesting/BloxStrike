local CenterScreenRaycast = {}
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local LocalPlayer = Players.LocalPlayer
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true
local count = 0
local v = -1
local v2 = nil
local v3 = nil
local v4 = nil
local v5 = 0
local raycastResult = nil
RunServiceController.BindToHeartbeat("Components.CenterScreenRaycast.InvalidateCache", function()
	count += 1
end)

local function ClearCache() -- 1 equivalent call inferred from this helper
	v = -1
	v2 = nil
	v3 = nil
	v4 = nil
	v5 = 0
	raycastResult = nil
end

local function ResolveRaycast(p: number)
	local currentCamera = Workspace.CurrentCamera
	local localCharacter = CharacterResolver.getLocalCharacter()

	if currentCamera and localCharacter then
		local cframe = currentCamera.CFrame
		local v6

		if v == count and v2 == currentCamera and v4 == localCharacter and v3 == cframe then
			v6 = p <= v5
		else
			v6 = false
		end

		if v6 then
			return raycastResult
		end

		local map = Workspace:FindFirstChild("Map")
		local barriers

		if map then
			barriers = map:FindFirstChild("Barriers")
		end

		raycastParams.FilterDescendantsInstances = barriers and { localCharacter, currentCamera, barriers }
			or { localCharacter, currentCamera }
		raycastResult = Workspace:Raycast(cframe.Position, cframe.LookVector * p, raycastParams)
		v = count
		v2 = currentCamera
		v3 = cframe
		v4 = localCharacter
		v5 = p
		return raycastResult
	else
		ClearCache() -- inferred equivalent call
		return nil
	end
end

function CenterScreenRaycast.GetResult(value: number?)
	local v6 = value or 10
	local raycast = ResolveRaycast(v6)

	if raycast and not (v6 < raycast.Distance) then
		return raycast
	end

	return nil
end

function CenterScreenRaycast.GetInstance(p: number?)
	local result = CenterScreenRaycast.GetResult(p)

	if result then
		return result.Instance
	end

	return nil
end

function CenterScreenRaycast.FindTaggedAncestor(tag: string, p: number?)
	local parent = CenterScreenRaycast.GetInstance(p)

	while parent do
		if CollectionService:HasTag(parent, tag) then
			return parent
		else
			parent = parent.Parent
		end
	end

	return nil
end

local function RayEntersBox(boundingBox: CFrame, vector: Vector3, position: Vector3, lookVector: Vector3, p: number)
	local pointToObjectSpace = boundingBox:PointToObjectSpace(position)
	local vectorToObjectSpace = boundingBox:VectorToObjectSpace(lookVector)
	local v6 = vector / 2
	local v7 = 0

	for _, v8 in { "X", "Y", "Z" } do
		local v9 = pointToObjectSpace[v8]
		local v10 = vectorToObjectSpace[v8]
		local v11 = v6[v8]

		if math.abs(v10) < 1e-6 then
			if v11 < math.abs(v9) then
				return nil
			end
		else
			local v12 = (-v11 - v9) / v10
			local v13 = (v11 - v9) / v10

			if v13 < v12 then
				v13, v12 = v12, v13
			end

			v7 = math.max(v7, v12)
			p = math.min(p, v13)

			if p < v7 then
				return nil
			end
		end
	end

	return v7
end

function CenterScreenRaycast.FindTaggedModelInSight(tag: string, value: number?)
	local v6 = value or 10
	local model = CenterScreenRaycast.FindTaggedAncestor(tag, v6)

	if model and model:IsA("Model") then
		return model
	end

	local currentCamera = Workspace.CurrentCamera

	if not (currentCamera and CharacterResolver.getLocalCharacter()) then
		return nil
	end

	local position = currentCamera.CFrame.Position
	local lookVector = currentCamera.CFrame.LookVector
	local result = CenterScreenRaycast.GetResult(v6)
	local v7 = 1e999
	local v8 = nil

	for _, model2 in CollectionService:GetTagged(tag) do
		if not (model2:IsA("Model") and model2:GetAttribute("Destroyed") ~= true) then
			continue
		end

		local boundingBox, v9 = model2:GetBoundingBox()

		if (boundingBox.Position - position).Magnitude > v6 + v9.Magnitude / 2 then
			continue
		end

		local rayEntersBox = RayEntersBox(boundingBox, v9, position, lookVector, v6)

		if
			rayEntersBox == nil
			or v7 <= rayEntersBox
			or not (not result or not (result.Distance < rayEntersBox - 0.25) or result.Instance:IsDescendantOf(model2))
		then
			continue
		end

		v8 = model2
		v7 = rayEntersBox
	end

	return v8
end

function CenterScreenRaycast.GetHoveredHostage(value: number?)
	if LocalPlayer:GetAttribute("Team") ~= "Counter-Terrorists" then
		return nil
	end

	local model = CenterScreenRaycast.FindTaggedAncestor("Hostage", value or 5)

	if not (model and model:IsA("Model") and model:GetAttribute("CanRescue") == true) then
		return nil
	end

	local rescuingPlayer = model:GetAttribute("RescuingPlayer")

	if rescuingPlayer and rescuingPlayer ~= LocalPlayer.Name or model:GetAttribute("CarryingPlayer") then
		return nil
	end

	return model
end

return CenterScreenRaycast