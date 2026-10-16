local createVector = vector.create
local TutorialGuide = {}
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local GetRayIgnore = require(ReplicatedStorage.Components.Common.GetRayIgnore)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local TutorialZones = require(ReplicatedStorage.Controllers.TutorialZones)
local LocalPlayer = Players.LocalPlayer
local v = { 3.5, 2 }
local _ = {
	ArrowName = "Arrow",
	ArrowMaxSize = 8,
	Align = 0.98,
	Width = 2,
	Join = 16,
	Reach = 30,
	OffLaneCost = 1.6
}
local color = Color3.fromRGB(255, 236, 60)
local v2 = {
	"Characters",
	"TutorialDummies",
	"TutorialEscorts",
	"TutorialRetakers",
	"TutorialCTSquad",
	"TutorialBAttackers"
}
local v3 = { "Range_Entry", "Range_Exit", "Site_Entry", "Site_Exit" }

local function flat(vector: Vector3) -- 16 equivalent calls inferred from this helper
	return (Vector3.new(vector.X, 0, vector.Z))
end

local function flatDistance(vector: Vector3, vector2: Vector3) -- 10 equivalent calls inferred from this helper
	return flat(vector - vector2).Magnitude -- inferred equivalent call
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
local geometry = nil
local raycastParams2 = RaycastParams.new()
raycastParams2.FilterType = Enum.RaycastFilterType.Include
local v4 = nil

local function isFloorSlab(part) -- 1 equivalent call inferred from this helper
	local size = part.Size
	return part.CFrame.UpVector.Y > 0.99 and size.Y <= 2 and size.X * size.Z >= 300
end

local v5 = {}
local v6 = {}

local function collectLanes(folder)
	table.clear(v5)
	table.clear(v6)

	if not folder then
		return
	end

	for _, part in folder:GetDescendants() do
		if
			not part:IsA("BasePart")
			or part.Name ~= "Arrow"
			or (part.Size.Magnitude > 8 or part.CFrame.UpVector.Y < 0.99)
		then
			continue
		end

		local v7 = flat(part.CFrame.LookVector) -- inferred equivalent call

		if v7.Magnitude < 0.5 then
			continue
		end

		local unit = v7.Unit

		if unit.X < -0.5 or math.abs(unit.X) <= 0.5 and unit.Z < 0 then
			unit = -unit
		end

		local origin = flat(part.Position) -- inferred equivalent call
		local v8 = nil

		for _, v9 in v5 do
			if not (math.abs((v9.Axis:Dot(unit))) >= 0.98) then
				continue
			end

			local vector = origin - v9.Origin

			if not ((vector - v9.Axis * vector:Dot(v9.Axis)).Magnitude <= 2) then
				continue
			end

			v8 = v9
			break
		end

		if v8 then
			local dot = (origin - v8.Origin):Dot(v8.Axis)
			v8.Min = math.min(v8.Min, dot)
			v8.Max = math.max(v8.Max, dot)
		else
			table.insert(v5, {
				Origin = origin,
				Axis = unit,
				Min = 0,
				Max = 0,
				Joins = {}
			})
		end
	end

	for i = 1, #v5 do
		for j = i + 1, #v5 do
			local v7 = v5[i]
			local v8 = v5[j]
			local v9 = v7.Axis.X * v8.Axis.Z - v7.Axis.Z * v8.Axis.X

			if math.abs(v9) < 0.2 then
				continue
			end

			local v10 = v8.Origin - v7.Origin
			local v11 = (v10.X * v8.Axis.Z - v10.Z * v8.Axis.X) / v9
			local v12 = (v10.X * v7.Axis.Z - v10.Z * v7.Axis.X) / v9

			if not (v7.Min - 16 <= v11 and v11 <= v7.Max + 16 and v8.Min - 16 <= v12 and v12 <= v8.Max + 16) then
				continue
			end

			table.insert(v6, v7.Origin + v7.Axis * v11)
			local count = #v6
			table.insert(v7.Joins, { T = v11, Node = count })
			table.insert(v8.Joins, { T = v12, Node = count })
			local min = math.min(v7.Min, v11)
			local max = math.max(v7.Max, v11)
			v7.Min = min
			v7.Max = max
			local min2 = math.min(v8.Min, v12)
			local max2 = math.max(v8.Max, v12)
			v8.Min = min2
			v8.Max = max2
		end
	end
end

local function refreshFloors(folder)
	if folder == v4 then
		return
	end

	v4 = folder
	collectLanes(folder)
	local parts = {}
	local zones = folder and folder:FindFirstChild("Zones")

	if folder then
		for _, part in folder:GetDescendants() do
			if
				not part:IsA("BasePart")
				or not part.CanQuery
				or not (part.Transparency < 0.9)
				or zones and part:IsDescendantOf(zones)
			then
				continue
			end

			if not isFloorSlab(part) then -- inferred equivalent call
				continue
			end

			table.insert(parts, part)
		end
	end

	raycastParams2.FilterDescendantsInstances = parts
end

local function refreshIgnore()
	local map = workspace:FindFirstChild("Map")
	refreshFloors(map)
	geometry = map and map:FindFirstChild("Geometry")
	local children = GetRayIgnore()

	for _, childName in v2 do
		local child = workspace:FindFirstChild(childName)

		if child then
			table.insert(children, child)
		end
	end

	for _, childName in v3 do
		local child = geometry and geometry:FindFirstChild(childName)

		if child then
			table.insert(children, child)
		end
	end

	raycastParams.FilterDescendantsInstances = children
end

local function snapToFloor(vector: Vector3) -- 9 equivalent calls inferred from this helper
	local v7 = vector + createVector(0, 3, 0)
	local raycastResult = workspace:Raycast(v7, createVector(0, -15, 0), raycastParams2)

	if not raycastResult then
		return vector
	end

	local v8 = geometry
	local v9

	if v8 == nil then
		v9 = false
	else
		v9 = raycastResult.Instance:IsDescendantOf(v8)
	end

	return raycastResult.Position + Vector3.new(0, v9 and 0.25 or 0, 0)
end

local function isClearLine(vector: Vector3, vector2: Vector3)
	vector = snapToFloor(vector) -- inferred equivalent call
	local v7 = vector + createVector(0, 2.6, 0)
	vector2 = snapToFloor(vector2) -- inferred equivalent call
	local v8 = vector2 + createVector(0, 2.6, 0) - v7

	if v8.Magnitude < 0.1 then
		return true
	end

	local cframe = CFrame.lookAt(v7, v7 + v8)
	local clone = table.clone(raycastParams.FilterDescendantsInstances)
	local map = workspace:FindFirstChild("Map")
	local zones = map and map:FindFirstChild("Zones")

	if zones then
		table.insert(clone, zones)
	end

	local raycastParams3 = RaycastParams.new()
	raycastParams3.FilterType = Enum.RaycastFilterType.Exclude

	for _ = 1, 6 do
		raycastParams3.FilterDescendantsInstances = clone
		local blockcast = workspace:Blockcast(cframe, createVector(4.5, 4, 0.2), v8, raycastParams3)

		if not blockcast then
			return true
		end

		local instance = blockcast.Instance

		if not instance:IsA("BasePart") or instance.Transparency < 0.9 then
			return false
		end

		table.insert(clone, instance)
	end

	return false
end

local function decodeRoute()
	local tutorialGuide = LocalPlayer:GetAttribute("TutorialGuide")

	if typeof(tutorialGuide) ~= "string" then
		return nil
	end

	local success, result = pcall(HttpService.JSONDecode, HttpService, tutorialGuide)

	if not success or typeof(result) ~= "table" or typeof(result.p) ~= "table" then
		return nil
	end

	local vectors = {}

	for _, v7 in result.p do
		if not (typeof(v7) == "table" and typeof(v7[1]) == "number") then
			continue
		end

		table.insert(vectors, (Vector3.new(v7[1], v7[2], v7[3])))
	end

	if #vectors == 0 then
		return nil
	end

	return {
		Points = vectors,
		Radius = typeof(result.r) ~= "number" and 5 or result.r,
		Key = tutorialGuide
	}
end

local function remainingPoints(points, vector: Vector3)
	local count = #points

	if count <= 1 then
		return table.clone(points)
	end

	local v7 = flat(vector) -- inferred equivalent call
	local magnitudes = {}
	local v8 = {}
	local v9 = 1e999

	for i = 1, count - 1 do
		local v10 = flat(points[i]) -- inferred equivalent call
		local vector2 = flat(points[i + 1]) - v10 -- inferred equivalent call
		local dot = vector2:Dot(vector2)
		local v11 = not (dot > 1e-6) and 0 or (v7 - v10):Dot(vector2) / dot
		magnitudes[i] = (v7 - (v10 + vector2 * math.clamp(v11, 0, 1))).Magnitude
		v8[i] = v11
		v9 = math.min(v9, magnitudes[i])
	end

	local v10 = 1

	for i = count - 1, 1, -1 do
		if not (magnitudes[i] <= v9 + 2) then
			continue
		end

		v10 = i
		break
	end

	local v11 = v10 + 1

	if v10 == 1 and v8[1] <= 0 then
		v11 = 1
	elseif v8[v10] >= 1 then
		v11 = v10 + 2
	end

	local v12 = math.min(v11, count)
	return table.move(points, v12, count, 1, {})
end

local function computePath(vector: Vector3, vector2: Vector3)
	for _, agentRadius in v do
		local path = PathfindingService:CreatePath({
			AgentRadius = agentRadius,
			AgentHeight = 5,
			AgentCanJump = true,
			WaypointSpacing = 4
		})

		if not (pcall(path.ComputeAsync, path, vector, vector2) and path.Status == Enum.PathStatus.Success) then
			continue
		end

		local positions = {}

		for _, v7 in path:GetWaypoints() do
			table.insert(positions, v7.Position)
		end

		return positions
	end

	return nil
end

local function lanePath(vector: Vector3, vector2: Vector3)
	if #v5 == 0 then
		return nil
	end

	local v7 = { flat(vector), flat(vector2) } -- inferred equivalent call

	for k, v8 in v6 do
		v7[k + 2] = v8
	end

	local v8 = {}

	local function link(p: number, p2: number, p3: number)
		v8[p] = v8[p] or {}
		table.insert(v8[p], { p2, p3 })
		v8[p2] = v8[p2] or {}
		table.insert(v8[p2], { p, p3 })
	end

	link(1, 2, flatDistance(vector, vector2) * 1.6) -- inferred equivalent call

	for _, v9 in v5 do
		local v10 = {}

		for _, join in v9.Joins do
			table.insert(v10, {
				T = join.T,
				Node = join.Node + 2
			})
		end

		for k, v11 in { vector, vector2 } do
			local v12 = math.clamp((flat(v11) - v9.Origin):Dot(v9.Axis), v9.Min, v9.Max) -- inferred equivalent call
			local v13 = v9.Origin + v9.Axis * v12
			local vector3 = flatDistance(v11, v13) -- inferred equivalent call

			if not (vector3 <= 30 and (vector3 < 1 or isClearLine(v11, Vector3.new(v13.X, v11.Y, v13.Z)))) then
				continue
			end

			table.insert(v7, v13)
			table.insert(v10, {
				T = v12,
				Node = #v7
			})
			link(k, #v7, vector3 * 1.6)
		end

		table.sort(v10, function(a, b)
			return a.T < b.T
		end)

		for i = 2, #v10 do
			link(v10[i - 1].Node, v10[i].Node, v10[i].T - v10[i - 1].T)
		end
	end

	local v9 = { 0 }
	local v10 = {}
	local v11 = {}

	while true do
		local v12 = 1e999
		local v13 = nil

		for k, v14 in v9 do
			if v10[k] or not (v14 < v12) then
				continue
			end

			v13 = k
			v12 = v14
		end

		if v13 == nil or v13 == 2 then
			break
		end

		v10[v13] = true
		local v14 = v8[v13]

		if not v14 then
			continue
		end

		for _, v15 in v14 do
			local v16 = v15[1]
			local v17 = v12 + v15[2]

			if not (v17 < (v9[v16] or 1e999)) then
				continue
			end

			v9[v16] = v17
			v11[v16] = v13
		end
	end

	if v11[2] == nil or v11[2] == 1 then
		return nil
	end

	local v12 = v11[2]
	local result = { vector2 }

	while v12 and v12 ~= 1 do
		local vector3 = Vector3.new(v7[v12].X, vector.Y, v7[v12].Z)

		if flatDistance(vector3, result[1]) > 0.5 then -- inferred equivalent call
			table.insert(result, 1, vector3)
		end

		v12 = v11[v12]
	end

	if flatDistance(vector, result[1]) > 0.5 then -- inferred equivalent call
		table.insert(result, 1, vector)
		return result
	end

	result[1] = vector
	return result
end

local function walkLeg(vector: Vector3, vector2: Vector3)
	local v7 = lanePath(vector, vector2)

	if v7 then
		return v7
	end

	if isClearLine(vector, vector2) then
		return { vector, vector2 }
	end

	local v8 = snapToFloor(vector) -- inferred equivalent call
	local v9 = computePath(v8, snapToFloor(vector2)) -- inferred equivalent call

	if not v9 then
		local v10 = flat(vector - vector2) -- inferred equivalent call

		if v10.Magnitude > 3 then
			v9 = computePath(v8, snapToFloor(vector2 + v10.Unit * 3)) -- inferred equivalent call

			if v9 then
				table.insert(v9, vector2)
			end
		end
	end

	if not v9 then
		return { vector, vector2 }
	end

	v9[1] = vector
	return v9
end

local function simplify(list)
	if #list < 3 then
		return list
	end

	local v7 = table.create(#list, false)
	local v8 = #list
	v7[1] = true
	v7[v8] = true
	local v9 = {
		{ 1, #list }
	}

	while #v9 > 0 do
		local v10 = table.remove(v9)
		local v11 = v10[1]
		local v12 = v10[2]
		local v13 = flat(list[v11]) -- inferred equivalent call
		local vector = flat(list[v12]) - v13 -- inferred equivalent call
		local magnitude = vector.Magnitude
		local v14 = 0
		local v15 = 0

		for i = v11 + 1, v12 - 1 do
			local v16 = flat(list[i]) -- inferred equivalent call
			local magnitude2

			if magnitude > 0.001 then
				magnitude2 = vector:Cross(v16 - v13).Magnitude / magnitude
			else
				magnitude2 = (v16 - v13).Magnitude
			end

			if not (v14 < magnitude2) then
				continue
			end

			v15 = i
			v14 = magnitude2
		end

		if not (v14 > 0.5) then
			continue
		end

		v7[v15] = true
		table.insert(v9, { v11, v15 })
		table.insert(v9, { v15, v12 })
	end

	local result = {}

	for k, v10 in list do
		if v7[k] then
			table.insert(result, v10)
		end
	end

	return result
end

local function roundCorners(list)
	for _ = 1, 2 do
		if #list < 3 then
			return list
		end

		local v7 = { list[1] }

		for i = 2, #list - 1 do
			local v8 = list[i - 1]
			local v9 = list[i]
			local v10 = list[i + 1]
			local magnitude = (v9 - v8).Magnitude
			local magnitude2 = (v10 - v9).Magnitude

			if magnitude < 0.001 or magnitude2 < 0.001 then
				table.insert(v7, v9)
			else
				local lerped = v9:Lerp(v8, math.min(magnitude * 0.25, 2) / magnitude)
				local lerped2 = v9:Lerp(v10, math.min(magnitude2 * 0.25, 2) / magnitude2)

				if isClearLine(lerped, lerped2) then
					table.insert(v7, lerped)
					table.insert(v7, lerped2)
				else
					table.insert(v7, v9)
				end
			end
		end

		table.insert(v7, list[#list])
		list = v7
	end

	return list
end

local function knotGap(vector: Vector3, vector2: Vector3) -- 3 equivalent calls inferred from this helper
	local v7 = vector - vector2
	return (math.max(flat(v7).Magnitude ^ 0.5, 0.0001)) -- inferred equivalent call
end

local function spline(list)
	local count = #list

	if count < 2 then
		return list
	end

	local result = { list[1] }

	for i = 1, count - 1 do
		local v7 = list[i]
		local v8 = list[i + 1]
		local v9

		if i > 1 then
			v9 = list[i - 1]
		else
			v9 = v7 + (v7 - v8)
		end

		local v10

		if i + 2 <= count then
			v10 = list[i + 2]
		else
			v10 = v8 + (v8 - v7)
		end

		local v11 = knotGap(v9, v7) -- inferred equivalent call
		local v12 = v11 + knotGap(v7, v8) -- inferred equivalent call
		local v13 = v12 + knotGap(v8, v10) -- inferred equivalent call
		local v14 = math.max(1, (math.ceil(flatDistance(v7, v8) / 0.5))) -- inferred equivalent call

		for j = 1, v14 do
			local v15 = v11 + (v12 - v11) * (j / v14)
			local v16 = v9 * ((v11 - v15) / v11) + v7 * (v15 / v11)
			local v17 = v7 * ((v12 - v15) / (v12 - v11)) + v8 * ((v15 - v11) / (v12 - v11))
			local v18 = v8 * ((v13 - v15) / (v13 - v12)) + v10 * ((v15 - v12) / (v13 - v12))
			local v19 = v16 * ((v12 - v15) / v12) + v17 * (v15 / v12)
			local v20 = v17 * ((v13 - v15) / (v13 - v11)) + v18 * ((v15 - v11) / (v13 - v11))
			table.insert(result, v19 * ((v12 - v15) / (v12 - v11)) + v20 * ((v15 - v11) / (v12 - v11)))
		end
	end

	return result
end

local function resample(list)
	local result = { list[1] }
	local v7 = 0
	local total = 0

	for i = 2, #list do
		local v8 = list[i - 1]
		local v9 = list[i]
		local vector = flatDistance(v8, v9) -- inferred equivalent call

		if vector < 0.001 then
			continue
		end

		local v10 = 0.5 - v7

		while v10 <= vector do
			table.insert(result, v8:Lerp(v9, v10 / vector))
			v10 += 0.5
		end

		v7 = vector - (v10 - 0.5)
		total += vector
	end

	if flatDistance(result[#result], list[#list]) > 0.01 then -- inferred equivalent call
		table.insert(result, list[#list])
	end

	return result, total
end

local function sampleCurve(dense, p: number)
	local v7 = p / 0.5 + 1
	local v8 = math.clamp(math.floor(v7), 1, #dense)
	local v9 = math.min(v8 + 1, #dense)
	local lerped = dense[v8]:Lerp(dense[v9], v7 - math.floor(v7))
	local v10 = dense[math.max(v8 - 1, 1)]
	return lerped, flat(dense[math.min(v8 + 2, #dense)] - v10) -- inferred equivalent call
end

local v7 = {}

for _, v8 in { 1, -1 } do
	local vector = Vector3.new(v8 * 0.6691306063588582, 0, 0.7431448254773942)
	local vector2 = Vector3.new(-v8 * 0.7431448254773942, 0, 0.6691306063588582)
	local v9 = createVector(0, 0, -0.83603793) + vector * 0.6996858843423915
	local v10 = v9 + vector2 * 0.315 - vector * 0.34984294217119577
	table.insert(v7, {
		ClassName = "WedgePart",
		Size = createVector(0.05, 0.63, 0.6996859),
		Offset = CFrame.fromMatrix(v10, vector2:Cross(vector), vector2, vector)
	})
	local v11 = v9 + vector * 0.7751570578288043 + vector2 * 0.315
	table.insert(v7, {
		ClassName = "Part",
		Size = createVector(0.63, 0.05, 1.5503141),
		Offset = CFrame.fromMatrix(v11, vector2, createVector(0, 1, 0))
	})
end

local v8 = nil
local v9 = {}

local function ensureFolder() -- 2 equivalent calls inferred from this helper
	if v8 and v8.Parent then
		return v8
	end

	local folder = Instance.new("Folder")
	folder.Name = "TutorialGuide"
	folder.Parent = workspace.CurrentCamera
	v8 = folder
	table.clear(v9)
	return folder
end

local function newPart(className: string?) -- 1 equivalent call inferred from this helper
	local instance = Instance.new(className or "Part")
	instance.Anchored = true
	instance.CanCollide = false
	instance.CanQuery = false
	instance.CanTouch = false
	instance.CastShadow = false
	instance.Material = Enum.Material.Neon
	instance.Color = color
	instance.Transparency = 1
	instance.Parent = ensureFolder() -- inferred equivalent call
	return instance
end

local function getChevron(p: number)
	ensureFolder() -- inferred equivalent call
	local v10 = v9[p]

	if v10 then
		return v10
	end

	local parts = {}

	for _, v11 in v7 do
		local instance = newPart(v11.ClassName) -- inferred equivalent call
		instance.Size = v11.Size
		table.insert(parts, instance)
	end

	local v11 = {
		Parts = parts,
		Trail = nil,
		Along = 0,
		Traveled = 0,
		Stop = 0,
		Active = false,
		Transparency = 1
	}
	v9[p] = v11
	return v11
end

local function setChevronTransparency(state, transparency: number)
	if
		state.Transparency == transparency
		or math.abs(state.Transparency - transparency) < 0.02 and transparency ~= 1
	then
		return
	end

	state.Transparency = transparency

	for _, part in state.Parts do
		part.Transparency = transparency
	end
end

local v10 = {}
local v11 = {}

local function placeChevron(p, vector: Vector3, unit: Vector3)
	local v12 = CFrame.lookAt(vector, vector + unit) * CFrame.new(0, 0.05, 0)

	for k, v13 in v7 do
		table.insert(v10, p.Parts[k])
		table.insert(v11, v12 * v13.Offset)
	end
end

local function hideParts() -- 2 equivalent calls inferred from this helper
	for _, v12 in v9 do
		v12.Active = false

		if v12.Transparency == 1 then
			continue
		end

		local _ = math.abs(v12.Transparency - 1) < 0.02
		v12.Transparency = 1

		for _, part in v12.Parts do
			part.Transparency = 1
		end
	end
end

local count = 0

local function buildTrail(p, position: Vector3, p2: number)
	refreshIgnore()
	local v12 = remainingPoints(p.Points, position)
	local v13 = position
	local v14 = { position }

	for _, v15 in v12 do
		local v16 = walkLeg(v13, v15)

		for i = 2, #v16 do
			table.insert(v14, v16[i])
		end

		v13 = v15
	end

	if p2 ~= count then
		return nil
	end

	for i = 2, #v14 do
		local v15 = flat(v14[i] - position) -- inferred equivalent call

		if not (v15.Magnitude > 0.5) then
			continue
		end

		local v16 = -v15.Unit * 6
		local raycastResult = workspace:Raycast(position, v16, raycastParams)
		local v17 = not raycastResult and 6 or math.max(raycastResult.Distance - 0.5, 0)

		if v17 > 0.5 then
			table.insert(v14, 1, position + v16.Unit * v17)
		end

		break
	end

	for k, v15 in v14 do
		v15 = snapToFloor(v15) -- inferred equivalent call
		v14[k] = v15
	end

	local dense, total = resample(spline(roundCorners(simplify(v14))))

	if #dense < 2 then
		return nil
	end

	return { Dense = dense, Total = total, Floor = {} }
end

local function floorSample(p, p2: number)
	local v12 = p.Floor[p2]

	if v12 then
		return v12
	end

	local v13 = snapToFloor(p.Dense[p2]) -- inferred equivalent call
	p.Floor[p2] = v13
	return v13
end

local function floorPointAt(trail, along: number)
	local _, v12 = sampleCurve(trail.Dense, along)
	local v13 = along / 0.5 + 1
	local v14 = math.clamp(math.floor(v13), 1, #trail.Dense)
	local v15 = math.min(v14 + 1, #trail.Dense)
	local v16 = trail.Floor[v14]

	if not v16 then
		v16 = trail.Dense[v14]
		v16 = snapToFloor(v16) -- inferred equivalent call
		trail.Floor[v14] = v16
	end

	local v17 = trail.Floor[v15]

	if not v17 then
		v17 = trail.Dense[v15]
		v17 = snapToFloor(v17) -- inferred equivalent call
		trail.Floor[v15] = v17
	end

	return v16:Lerp(v17, v13 - math.floor(v13)), v12
end

local function projectOnto(p, position: Vector3, p2: number)
	local dense = p.Dense

	local function search(p3: number, p4: number)
		local v12 = 1e999

		for i = p3, p4 do
			local vector = flatDistance(dense[i], position) -- inferred equivalent call

			if not (vector < v12) then
				continue
			end

			p3 = i
			v12 = vector
		end

		return p3, v12
	end

	local selected, v12 = search(math.max(1, p2 - 80), math.min(#dense, p2 + 80))

	if v12 > 7 then
		selected, v12 = search(1, #dense)
	end

	return (selected - 1) * 0.5, v12, selected
end

local v12 = nil
local v13 = nil
local v14 = nil
local v15 = 0
local v16 = 0
local v17 = 1
local v18 = 0
local v19 = false
local v20 = true
local total = 0
local v21 = false

local function freeChevron() -- 1 equivalent call inferred from this helper
	for _, v22 in v9 do
		if not v22.Active then
			return v22
		end
	end

	return (getChevron(#v9 + 1))
end

local function spawnGroup(trail)
	local v22 = math.max(v15 - 6, 0)
	local stop = trail.Total - 3

	for i = 1, 3 do
		local along = v22 + (3 - i) * 2.6

		if not (stop - along >= 2) then
			continue
		end

		local v23 = freeChevron() -- inferred equivalent call
		v23.Active = true
		v23.Trail = trail
		v23.Along = along
		v23.Traveled = 0
		v23.Stop = stop
	end
end

local function draw(p: number)
	local v22 = v18
	local v23

	if v19 then
		v23 = p
	else
		v23 = -p
	end

	v18 = math.clamp(v22 + v23 * 3, 0, 1)
	v15 += (v16 - v15) * math.min(1, p * 12)
	local v24 = v13

	if v18 <= 0 or not v24 then
		if not v20 then
			v20 = true
			hideParts() -- inferred equivalent call
		end

		total = 1
	else
		v20 = false

		if v19 and not v21 then
			total += p

			if total >= 1 then
				v21 = true
			end
		end

		table.clear(v10)
		table.clear(v11)

		for _, v25 in v9 do
			local trail = v25.Trail

			if not (v25.Active and trail) then
				continue
			end

			local v26 = p * 15
			v25.Along += v26
			v25.Traveled += v26
			local v27 = v25.Stop - v25.Along

			if v27 <= 0 then
				v25.Active = false

				if v25.Transparency ~= 1 then
					local _ = math.abs(v25.Transparency - 1) < 0.02
					v25.Transparency = 1

					for _, part in v25.Parts do
						part.Transparency = 1
					end
				end
			else
				local v28 = math.clamp(v25.Traveled / 2, 0, 1) * math.clamp(v27 / 6, 0, 1) * v18
				local v29, v30 = floorPointAt(trail, v25.Along)

				if v30.Magnitude > 0.01 then
					placeChevron(v25, v29, v30.Unit)
				end

				local transparency = math.floor((1 - v28) / 0.02 + 0.5) * 0.02

				if
					v25.Transparency ~= transparency
					and (not (math.abs(v25.Transparency - transparency) < 0.02) or transparency == 1)
				then
					v25.Transparency = transparency

					for _, part in v25.Parts do
						part.Transparency = transparency
					end
				end
			end
		end

		if #v10 > 0 then
			workspace:BulkMoveTo(v10, v11, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end
end

local flag = false

local function prewarm()
	if flag then
		return
	end

	flag = true

	for i = 1, 24 do
		getChevron(i)

		if i % 4 == 0 then
			task.wait()
		end
	end
end

local function track(p: number)
	local v22 = false
	local v23 = nil

	while p == count do
		local v24 = v12
		local localCharacter = CharacterResolver.getLocalCharacter()
		local v25 = localCharacter and CharacterResolver.getRootPart(localCharacter)

		if v24 and v25 and CharacterResolver.isAliveCharacter(localCharacter) then
			local position = v25.Position
			local vector = flatDistance(position, v24.Points[#v24.Points]) -- inferred equivalent call
			v22 = TutorialZones.IsInside(position)
				or vector <= v24.Radius
				or v22 and vector <= math.max(v24.Radius * 1.6, 20)

			if v22 then
				v19 = false
				v13 = nil
				task.wait(0.1)
			else
				local v26 = v13
				local v27 = v26 == nil or v21

				if v26 then
					local v28, v29, v30 = projectOnto(v26, position, v17)
					v16 = v28
					v17 = v30

					if v29 > 7 then
						v23 = v23 or os.clock()
						v27 = os.clock() - v23 >= 0.75
					else
						v23 = nil
					end
				end

				if v27 then
					v23 = nil
					prewarm()

					if p ~= count then
						break
					end

					local trail = buildTrail(v24, position, p)

					if p ~= count then
						break
					end

					v13 = trail
					v21 = false
					total = 0
					v17 = 1
					v15 = 0
					v16 = 0

					if trail then
						local position2 = v25.Position
						local dense = trail.Dense

						local function search(p2: number, p3: number)
							local v28 = 1e999

							for i = p2, p3 do
								local vector2 = flatDistance(dense[i], position2) -- inferred equivalent call

								if not (vector2 < v28) then
									continue
								end

								p2 = i
								v28 = vector2
							end

							return p2, v28
						end

						local v28, v29 = search(1, math.min(#dense, 81))

						if v29 > 7 then
							v28, v29 = search(1, #dense)
						end

						local v30 = (v28 - 1) * 0.5
						v17 = v28
						v15 = v30
						v16 = v30
						spawnGroup(trail)
					end
				end

				v19 = v13 ~= nil
				task.wait(0.1)
			end
		else
			v19 = false
			task.wait(0.1)
		end
	end
end

local function sync()
	local v22

	if IsTutorialMode() then
		v22 = decodeRoute()
	end

	if v22 and v12 and v22.Key == v12.Key then
		return
	end

	count += 1
	v12 = v22
	v13 = nil

	if not v22 then
		v19 = false
		return
	end

	v18 = 0
	v20 = true
	hideParts() -- inferred equivalent call

	if not v14 then
		v14 = RunServiceController.BindToHeartbeat("TutorialGuide.Draw", draw)
	end

	task.spawn(track, count)
end

function TutorialGuide.Start()
	LocalPlayer:GetAttributeChangedSignal("TutorialGuide"):Connect(sync)
	sync()
end

return TutorialGuide