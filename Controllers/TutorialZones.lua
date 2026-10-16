local createVector = vector.create
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Sound = require(ReplicatedStorage.Classes.Sound)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local LocalPlayer = Players.LocalPlayer
local v = {
	Spot = Color3.fromRGB(255, 236, 60),
	T = Color3.fromRGB(255, 184, 40),
	CT = Color3.fromRGB(80, 170, 255),
	Site = Color3.fromRGB(255, 20, 20),
	Bomb = Color3.fromRGB(255, 20, 20)
}
local numberRange = NumberRange.new(0, 0.2)
local Quint = Enum.EasingStyle.Quint
local Back = Enum.EasingStyle.Back
local v2 = { Spot = 0.5, Bomb = 0.5 }
local _ = { Depth = 0.09, Peak = 0.55, InSeconds = 0.05, OutSeconds = 0.3 }
local v3 = {
	"Characters",
	"Debris",
	"TutorialDummies",
	"TutorialEscorts",
	"TutorialRetakers",
	"TutorialCTSquad",
	"TutorialBAttackers"
}
local v4 = nil
local v5 = nil

local function floorY(position: Vector3)
	local filterDescendantsInstances = { workspace.CurrentCamera }
	local map = workspace:FindFirstChild("Map")

	if map then
		for _, childName in { "Zones", "Geometry", "Barriers" } do
			local child = map:FindFirstChild(childName)

			if child then
				table.insert(filterDescendantsInstances, child)
			end
		end
	end

	for _, childName in v3 do
		local child = workspace:FindFirstChild(childName)

		if child then
			table.insert(filterDescendantsInstances, child)
		end
	end

	local character = LocalPlayer.Character

	if character then
		table.insert(filterDescendantsInstances, character)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	local v6 = position + createVector(0, 6, 0)
	local v7 = 36

	for _ = 1, 4 do
		local raycastResult = workspace:Raycast(v6, Vector3.new(0, -v7, 0), raycastParams)

		if not raycastResult then
			break
		end

		local instance = raycastResult.Instance

		if raycastResult.Normal.Y > 0.7 and instance:IsA("BasePart") and instance.Transparency < 0.9 then
			return raycastResult.Position.Y
		end

		v7 -= v6.Y - raycastResult.Position.Y + 0.05
		v6 = raycastResult.Position - createVector(0, 0.05, 0)

		if v7 <= 0 then
			break
		end
	end

	return position.Y
end

local function floorFrame(cframe: CFrame) -- 2 equivalent calls inferred from this helper
	local vector = Vector3.new(cframe.RightVector.X, 0, cframe.RightVector.Z)
	local v6 = not (vector.Magnitude > 0.01) and createVector(1, 0, 0) or vector.Unit
	local position = cframe.Position
	return CFrame.fromMatrix(Vector3.new(position.X, floorY(position), position.Z), v6, createVector(0, 1, 0))
end

local function buildWall(folder, backgroundColor: Color3, list)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Parent = folder

	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Face = face
		surfaceGui.LightInfluence = 0
		surfaceGui.Brightness = 3
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surfaceGui.PixelsPerStud = 40
		surfaceGui.Parent = part
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = backgroundColor
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		local uiGradient = Instance.new("UIGradient")
		uiGradient.Rotation = 90
		uiGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0.55),
			NumberSequenceKeypoint.new(1, 0)
		})
		uiGradient.Parent = frame
		frame.Parent = surfaceGui
		table.insert(list, frame)
	end

	return part
end

local function layoutWalls(list, cframe: CFrame, p: number, p2: number)
	local v6 = cframe * CFrame.new(0, 0.77, 0)
	local cframe2 = CFrame.Angles(0, 1.5707963267948966, 0)
	local vector = Vector3.new(p * 2, 1.5, 0.01)
	local vector2 = Vector3.new(p2 * 2, 1.5, 0.01)
	local v7 = list[1]
	local v8 = list[1]
	local cframe3 = v6 * CFrame.new(0, 0, -p2)
	v7.Size = vector
	v8.CFrame = cframe3
	local v9 = list[2]
	local v10 = list[2]
	local cframe4 = v6 * CFrame.new(0, 0, p2)
	v9.Size = vector
	v10.CFrame = cframe4
	local v11 = list[3]
	local v12 = list[3]
	local cframe5 = v6 * CFrame.new(-p, 0, 0) * cframe2
	v11.Size = vector2
	v12.CFrame = cframe5
	local v13 = list[4]
	local v14 = list[4]
	local cframe6 = v6 * CFrame.new(p, 0, 0) * cframe2
	v13.Size = vector2
	v14.CFrame = cframe6
end

local function buildWalls(color: Color3)
	local folder = Instance.new("Folder")
	folder.Name = "TutorialZone"
	folder.Parent = workspace.CurrentCamera
	local v6 = {}
	return
		folder,
		{
			buildWall(folder, color, v6),
			buildWall(folder, color, v6),
			buildWall(folder, color, v6),
			(buildWall(folder, color, v6))
		},
		v6
end

local v6 = nil
local result = {}
local count = 0

local function getGlow()
	local v7 = v6

	if v7 and v7.Parent then
		return result
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TutorialArrivalGlow"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 5
	table.clear(result)

	for _, v8 in {
		{ UDim2.fromScale(0.5, 0), UDim2.fromScale(1, 0.09), Vector2.new(0.5, 0), 90 },
		{ UDim2.fromScale(0.5, 1), UDim2.fromScale(1, 0.09), Vector2.new(0.5, 1), -90 },
		{ UDim2.fromScale(0, 0.5), UDim2.fromScale(0.09, 1), Vector2.new(0, 0.5), 0 },
		{ UDim2.fromScale(1, 0.5), UDim2.fromScale(0.09, 1), Vector2.new(1, 0.5), 180 }
	} do
		local frame = Instance.new("Frame")
		local position = v8[1]
		local size = v8[2]
		local anchorPoint = v8[3]
		frame.Position = position
		frame.Size = size
		frame.AnchorPoint = anchorPoint
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		local uiGradient = Instance.new("UIGradient")
		uiGradient.Rotation = v8[4]
		uiGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.35, 0.6),
			NumberSequenceKeypoint.new(1, 1)
		})
		uiGradient.Parent = frame
		frame.Parent = screenGui
		table.insert(result, frame)
	end

	screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	v6 = screenGui
	return result
end

local function playArrival(color: Color3)
	Sound.new("Deathmatch"):playOneTime({
		Parent = workspace.CurrentCamera,
		Name = "Deathmatch HP Bonus"
	})
	local glow = getGlow()
	count += 1
	local v7 = count
	local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	for _, v8 in glow do
		v8.BackgroundColor3 = color
		TweenService:Create(v8, tweenInfo, { BackgroundTransparency = 0.55 }):Play()
	end

	task.delay(0.05, function()
		if v7 ~= count then
			return
		end

		local tweenInfo2 = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

		for _, v8 in glow do
			TweenService:Create(v8, tweenInfo2, { BackgroundTransparency = 1 }):Play()
		end
	end)
end

local function isInZone(data, vector: Vector3)
	local room = data.Room

	if room then
		local pointToObjectSpace = room.CFrame:PointToObjectSpace(vector)

		if
			math.abs(pointToObjectSpace.X) <= room.Half.X
			and math.abs(pointToObjectSpace.Y) <= room.Half.Y
			and math.abs(pointToObjectSpace.Z) <= room.Half.Z
		then
			return true
		end
	end

	local pointToObjectSpace = data.Base:PointToObjectSpace(vector)
	return math.abs(pointToObjectSpace.X) <= data.HalfX + data.Margin
		and math.abs(pointToObjectSpace.Z) <= data.HalfZ + data.Margin
		and pointToObjectSpace.Y > -4
		and pointToObjectSpace.Y < 10
end

local function buildZone(tutorialZone: string, k: string, cframe: CFrame, p: number, p2: number, room)
	local color = v[k] or v.Spot
	local base = floorFrame(cframe) -- inferred equivalent call
	local halfX = p * 0.5
	local halfZ = p2 * 0.5
	local walls, walls2, frames = buildWalls(color)
	layoutWalls(walls2, base, halfX, halfZ)
	return {
		Key = tutorialZone,
		Kind = k,
		Folder = walls,
		Walls = walls2,
		Frames = frames,
		Morph = nil,
		ShownAt = os.clock(),
		Transparency = 1,
		Base = base,
		HalfX = halfX,
		HalfZ = halfZ,
		Margin = v2[k] or 3.5,
		Room = room,
		Color = color,
		WasOutside = false,
		Entered = false
	}
end

local function morphZone(state, tutorialZone: string, k: string, cframe: CFrame, p: number, p2: number)
	state.Morph = {
		Base = state.Base,
		HalfX = state.HalfX,
		HalfZ = state.HalfZ,
		StartedAt = os.clock()
	}
	state.Key = tutorialZone
	state.Kind = k
	local base = floorFrame(cframe) -- inferred equivalent call
	local halfX = p * 0.5
	local halfZ = p2 * 0.5
	state.Base = base
	state.HalfX = halfX
	state.HalfZ = halfZ
	state.Margin = v2[k] or 3.5
	state.Room = nil
	state.WasOutside = false
	state.Entered = false
end

local function draw()
	local v7 = v4

	if not v7 then
		return
	end

	if not v7.Folder.Parent then
		local walls, walls2, frames = buildWalls(v7.Color)
		v7.Folder = walls
		v7.Walls = walls2
		v7.Frames = frames
		v7.Transparency = 1

		if not v7.Morph then
			layoutWalls(v7.Walls, v7.Base, v7.HalfX, v7.HalfZ)
		end
	end

	local morph = v7.Morph

	if morph then
		local v8 = math.clamp((os.clock() - morph.StartedAt) / 0.9, 0, 1)
		local value = TweenService:GetValue(v8, Quint, Enum.EasingDirection.Out)
		local value2 = TweenService:GetValue(v8, Back, Enum.EasingDirection.Out)
		layoutWalls(
			v7.Walls,
			morph.Base:Lerp(v7.Base, value),
			math.max(morph.HalfX + (v7.HalfX - morph.HalfX) * value2, 0.25),
			math.max(morph.HalfZ + (v7.HalfZ - morph.HalfZ) * value2, 0.25)
		)

		if v8 >= 1 then
			v7.Morph = nil
		end
	end

	local localCharacter = CharacterResolver.getLocalCharacter()
	local v8 = localCharacter and CharacterResolver.getRootPart(localCharacter)

	if v8 and not v7.Entered then
		if isInZone(v7, v8.Position) then
			if v7.WasOutside then
				v7.Entered = true
				playArrival(v7.Color)
			end
		else
			v7.WasOutside = true
		end
	end

	local v9 = os.clock() - v7.ShownAt
	local v10 = math.sin(v9 * 3.141592653589793 * 2 / 2.4) * 0.5 + 0.5
	local min

	if v7.Morph then
		min = numberRange.Min
	else
		min = numberRange.Max - (numberRange.Max - numberRange.Min) * v10
	end

	local v11 = math.clamp(v9 / 0.4, 0, 1)
	local v12 = math.floor((1 - (1 - min) * v11) * 50 + 0.5) / 50

	if v12 == v7.Transparency then
		return
	end

	v7.Transparency = v12

	for _, frame in v7.Frames do
		frame.BackgroundTransparency = v12
	end
end

local function clear()
	local v7 = v4
	v4 = nil

	if v7 then
		local folder = v7.Folder
		local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		for _, frame in v7.Frames do
			TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 1 }):Play()
		end

		task.delay(0.6, function()
			folder:Destroy()
		end)
	end

	if v5 then
		RunServiceController.Unbind("Heartbeat", "TutorialZones.Draw")
		v5 = nil
	end
end

local function sync()
	local tutorialZone

	if IsTutorialMode() then
		tutorialZone = LocalPlayer:GetAttribute("TutorialZone")
	end

	if typeof(tutorialZone) ~= "string" or tutorialZone == "" then
		clear()
		return
	end

	if v4 and v4.Key == tutorialZone then
		return
	end

	local success, result2 = pcall(HttpService.JSONDecode, HttpService, tutorialZone)

	if not success or typeof(result2) ~= "table" or typeof(result2.c) ~= "table" or typeof(result2.s) ~= "table" then
		clear()
		return
	end

	local cframe = CFrame.new(table.unpack(result2.c))
	local v7 = tonumber(result2.s[1])
	local v8 = tonumber(result2.s[2])

	if not v7 or not v8 or v7 <= 0 or v8 <= 0 then
		clear()
		return
	end

	local v9 = nil
	local a = result2.a

	if typeof(a) == "table" and typeof(a.c) == "table" and typeof(a.s) == "table" then
		local v10 = tonumber(a.s[1])
		local v11 = tonumber(a.s[2])
		local v12 = tonumber(a.s[3])
		v9 = v10 and v11 and v12 and {
			CFrame = CFrame.new(table.unpack(a.c)),
			Half = Vector3.new(v10, v11, v12) * 0.5
		} or v9
	end

	local k = tostring(result2.k)
	local v10 = v4

	if v10 and v10.Kind == "Site" and k == "Bomb" and v10.Folder.Parent then
		morphZone(v10, tutorialZone, "Bomb", cframe, v7, v8)
		return
	end

	clear()
	v4 = buildZone(tutorialZone, k, cframe, v7, v8, v9)
	draw()
	v5 = RunServiceController.BindToHeartbeat("TutorialZones.Draw", draw)
end

local TutorialZones = {}

function TutorialZones.IsInside(vector: Vector3)
	return v4 ~= nil and isInZone(v4, vector)
end

function TutorialZones.Start()
	LocalPlayer:GetAttributeChangedSignal("TutorialZone"):Connect(sync)
	sync()
end

return TutorialZones