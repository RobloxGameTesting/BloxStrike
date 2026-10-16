local createVector = vector.create
local Radar = {}
Radar.__index = Radar
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local CharacterController = require(ReplicatedStorage.Controllers.CharacterController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Colors = require(ReplicatedStorage.Database.Custom.GameStats.Settings.Colors)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local CreateVoxelSmoke = require(ReplicatedStorage.Components.Common.VFXLibary.CreateVoxelSmoke)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local v = table.find(GetUserPlatform(), "Mobile") and #GetUserPlatform() <= 1
local radar = ReplicatedStorage.Assets.UI.Radar

local function GetCurrentCamera() -- 5 equivalent calls inferred from this helper
	return Workspace.CurrentCamera
end

local v2 = v and 120 or 200
local color = Color3.fromRGB(255, 255, 255)

local function GetEffectiveScale(scale: number) -- 3 equivalent calls inferred from this helper
	if v then
		return (scale - 1) * 0.5 + 1
	end

	return scale
end

local function RoundToPixel(p: number) -- 2 equivalent calls inferred from this helper
	return (math.floor(p + 0.5))
end

local v3 = v and 30 or 50
local v4 = v and 21 or 35
local v5 = {
	DeadTeammate = 13,
	LocalPlayer = 15,
	Teammate = 14,
	Enemy = 17,
	Bomb = 19,
	Site = 16,
	EnemyQuestionMark = 20,
	Hostage = 18
}
local v6 = { Vertigo = 387, ["Winter Vertigo"] = 387, Reactor = 67.388 }

local function GetUpperLayerHeight(map: string?) -- 2 equivalent calls inferred from this helper
	if map then
		return v6[map]
	end

	return nil
end

local function IsDeathmatchGamemode() -- 2 equivalent calls inferred from this helper
	return Workspace:GetAttribute("Gamemode") == "Deathmatch"
		or Workspace:GetAttribute("ServerGamemode") == "Deathmatch"
end

local v7 = {
	A = { -0.02, 0.04 },
	B = { -0.015, -0.005 }
}
local v8 = {
	A = { 0.0425, 0.005 },
	B = { -0.01, -0.01 }
}
local v9 = {
	Mirage = v7,
	["Winter Mirage"] = v7,
	Vertigo = v8,
	["Winter Vertigo"] = v8,
	Seaside = {
		A = { -0.01, -0.01 },
		B = { 0, 0.02 }
	},
	["Dust 2"] = {
		A = { -0.06, -0.04 },
		B = { -0.065, -0.02 }
	}
}
local color2 = Color3.fromRGB(255, 0, 0)
local color3 = Color3.fromRGB(255, 0, 0)
local color4 = Color3.fromRGB(255, 255, 255)
local v10 = nil
local v11 = {
	{ "Radar Centers The Player", "CentersPlayer" },
	{ "Radar Hud Size", "Scale" },
	{ "Radar Is Rotating", "Rotation" },
	{ "Radar Map Zoom", "Zoom" }
}
local settings2 = { CentersPlayer = true, Rotation = false, Zoom = 0.7, Scale = 1 }
local v12 = nil
local v13 = nil

local function getRadarCharacter(player)
	if not player then
		return nil
	end

	if player:IsA("Player") then
		local playerCharacter = CharacterResolver.getPlayerCharacter(player)

		if playerCharacter and playerCharacter:IsDescendantOf(workspace) then
			return playerCharacter
		end

		return nil
	else
		local character = Participants.Character(player)

		if character and character:IsDescendantOf(workspace) then
			return character
		end

		return nil
	end
end

local function getRadarObserverCharacter(instance) -- 1 equivalent call inferred from this helper
	local radarCharacter = getRadarCharacter(instance)

	if radarCharacter and CharacterResolver.isAliveCharacter(radarCharacter) then
		if instance and instance:GetAttribute("Dead") == true then
			return nil
		end

		return radarCharacter
	else
		return nil
	end
end

local function GetMinimapReference()
	local map = workspace:FindFirstChild("Map")

	if not map then
		return nil
	end

	for _, part in ipairs(CollectionService:GetTagged("Minimap")) do
		if not (part:IsA("BasePart") and part:IsDescendantOf(map)) then
			continue
		end

		local textureSize = part:GetAttribute("TextureSize")
		local textureSize2 = (typeof(textureSize) ~= "number" or not (textureSize > 0)) and 1024 or textureSize
		return {
			Size = part.Size,
			Upper = part:FindFirstChild("Upper"),
			Lower = part:FindFirstChild("Lower"),
			Part = part,
			TextureSize = textureSize2
		}
	end

	return nil
end

local function GetTeammateDisplayColor(p, team: string?) -- 6 equivalent calls inferred from this helper
	if not team then
		return nil
	end

	local radarCharacter = getRadarCharacter(p)
	return radarCharacter and radarCharacter:GetAttribute("CompetitivePlayerColor") or Colors["Team Color"][team]
end

local function createRadarInstance(instance, player, flag: boolean?)
	Profiler.mark("UI.Radar.CreateRadarForCharacter")

	if v12 then
		v12:Destroy()
		v12 = nil
	end

	local v14 = Radar.new(v10, instance)
	v12 = v14
	v14.LocalPlayer = player
	v14.Team = player:GetAttribute("Team")
	v14.IsSpectating = flag or false

	if flag then
		v14.MapImage.Rotation = 90

		if v14.UpperMapImage then
			v14.UpperMapImage.Rotation = 90
		end
	end

	if instance then
		v14.Janitor:Add(instance:GetAttributeChangedSignal("Dead"):Connect(function()
			if v12 and instance:GetAttribute("Dead") then
				v12:Destroy()
				v12 = nil
			end
		end))
	end
end

local function GetSiteParts()
	local result = {}

	for _, part in ipairs(CollectionService:GetTagged("PlantArea")) do
		if not part:IsA("BasePart") then
			continue
		end

		local site = part:GetAttribute("Site")

		if not (site == "A" or site == "B") then
			continue
		end

		if not result[site] then
			result[site] = {}
		end

		table.insert(result[site], part.CFrame)
	end

	return result
end

local function GetSiteCenter(sitePart) -- 1 equivalent call inferred from this helper
	if #sitePart == 0 then
		return createVector(0, 0, 0)
	end

	local v14 = createVector(0, 0, 0)

	for _, v15 in ipairs(sitePart) do
		v14 += v15.Position
	end

	return v14 / #sitePart
end

local v14 = {}
local count = 0

local function PlayerHasBomb(instance)
	local slot5 = instance:GetAttribute("Slot5")

	if not slot5 then
		return false
	end

	local v15 = v14[slot5]

	if v15 ~= nil then
		return v15
	end

	local jsonDecode = HttpService:JSONDecode(slot5)
	local v16

	if jsonDecode == nil then
		v16 = false
	else
		v16 = jsonDecode.Weapon == "C4"
	end

	if count >= 64 then
		table.clear(v14)
		count = 0
	end

	v14[slot5] = v16
	count += 1
	return v16
end

local function PlayerIsCarryingHostage(instance) -- 2 equivalent calls inferred from this helper
	return instance:GetAttribute("IsCarryingHostage") == true
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.CollisionGroup = "Bullet"
raycastParams.IgnoreWater = true

local function GetObserverSpottingRay(instance, radarObserverCharacter, p, vector: Vector3)
	local position, lookVector

	if instance == p then
		local currentCamera = GetCurrentCamera() -- inferred equivalent call

		if not currentCamera then
			return nil, nil, nil
		end

		local cframe = currentCamera.CFrame
		position = cframe.Position
		lookVector = cframe.LookVector
	else
		local head = CharacterResolver.getHead(radarObserverCharacter)

		if head then
			position = head.Position
			lookVector = head.CFrame.LookVector
		else
			local rootPart = CharacterResolver.getRootPart(radarObserverCharacter)

			if not rootPart then
				return nil, nil, nil
			end

			position = rootPart.Position + createVector(0, 1.5, 0)
			lookVector = rootPart.CFrame.LookVector
		end
	end

	local v15 = vector - position
	local magnitude = v15.Magnitude

	if magnitude <= 1e-6 or magnitude > 200 then
		return nil, nil, nil
	end

	local unit = v15.Unit

	if unit:Dot(lookVector) <= 0.65 then
		return nil, nil, nil
	end

	return position, unit, magnitude
end

local function HasClearSpottingLine(vector: Vector3, vector2: Vector3, p: number, filterDescendantsInstances) -- 1 equivalent call inferred from this helper
	if CreateVoxelSmoke.DoesRayIntersectActiveSmoke(vector, vector2, p) then
		return false
	end

	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	return Workspace:Raycast(vector, vector2 * p, raycastParams) == nil
end

local filterDescendantsInstances = {}
local object = setmetatable({}, { __mode = "k" })

local function CanObserverSpot(instance, p: string, vector: Vector3, p2, p3)
	if instance == p3 or instance:GetAttribute("Team") ~= p then
		return false
	end

	local radarObserverCharacter = getRadarObserverCharacter(instance) -- inferred equivalent call

	if not radarObserverCharacter then
		return false
	end

	local v15, v16, v17 = GetObserverSpottingRay(instance, radarObserverCharacter, p2, vector)

	if not (v15 and v16 and v17) then
		return false
	end

	filterDescendantsInstances[1] = radarObserverCharacter
	return HasClearSpottingLine(v15, v16, v17, filterDescendantsInstances) -- inferred equivalent call
end

local function IsVisibleToTeam(p: string, vector: Vector3, p2, localPlayer, p3)
	table.clear(filterDescendantsInstances)
	filterDescendantsInstances[1] = Workspace
	local map = Workspace:FindFirstChild("Map")
	local barriers

	if map then
		barriers = map:FindFirstChild("Barriers")
	end

	if barriers then
		table.insert(filterDescendantsInstances, barriers)
	end

	if p2 then
		table.insert(filterDescendantsInstances, p2)
	end

	for _, model in ipairs(CollectionService:GetTagged("Hostage")) do
		if model:IsA("Model") and model ~= p2 then
			table.insert(filterDescendantsInstances, model)
		end
	end

	local v15

	if p2 then
		v15 = object[p2]
	end

	if v15 and CanObserverSpot(v15, p, vector, localPlayer, p3) then
		return true
	end

	for _, v16 in ipairs(Participants.GetAll()) do
		if not (v16 ~= v15 and CanObserverSpot(v16, p, vector, localPlayer, p3)) then
			continue
		end

		if p2 then
			object[p2] = v16
		end

		return true
	end

	return false
end

local function ReadCachedVisibility(p, p2: number) -- 4 equivalent calls inferred from this helper
	if p and p2 - p.UpdatedAt <= 0.1 then
		return p.Visible
	end

	return nil
end

local function GetEnemyVisibility(player, p: string, radarCharacter, p2, now: number)
	local v15 = player.EnemyVisibilityCache[p]
	local readCachedVisibility = ReadCachedVisibility(v15, now) -- inferred equivalent call

	if readCachedVisibility ~= nil then
		return readCachedVisibility
	end

	if player.EnemyVisibilityChecksRemaining <= 0 then
		if v15 then
			return v15.Visible
		end

		return false
	else
		player.EnemyVisibilityChecksRemaining -= 1
		local rootPart = CharacterResolver.getRootPart(radarCharacter)
		local visible

		if rootPart then
			local head = CharacterResolver.getHead(radarCharacter)
			local v16

			if head then
				v16 = head.Position
			else
				v16 = rootPart.Position + createVector(0, 1.5, 0)
			end

			visible = IsVisibleToTeam(player.Team, v16, radarCharacter, player.LocalPlayer, p2)
		else
			visible = false
		end

		player.EnemyVisibilityCache[p] = { Visible = visible, UpdatedAt = now }
		return visible
	end
end

local function GetBombVisibility(state, vector: Vector3, p, updatedAt: number)
	local readCachedVisibility = ReadCachedVisibility(state.BombVisibilityCache, updatedAt) -- inferred equivalent call

	if readCachedVisibility ~= nil then
		return readCachedVisibility
	end

	local visible = IsVisibleToTeam("Counter-Terrorists", vector, p, state.LocalPlayer)
	state.BombVisibilityCache = { Visible = visible, UpdatedAt = updatedAt }
	return visible
end

local function GetHostageVisibility(object2, p: string, position: Vector3, model, now: number)
	local readCachedVisibility = ReadCachedVisibility(object2.HostageVisibilityCache[p], now) -- inferred equivalent call

	if readCachedVisibility ~= nil then
		return readCachedVisibility
	end

	local visible = IsVisibleToTeam("Terrorists", position, model, object2.LocalPlayer)
	object2.HostageVisibilityCache[p] = { Visible = visible, UpdatedAt = now }
	return visible
end

local function HideDirectionIndicators(clone)
	for _, image in ipairs(clone:GetChildren()) do
		if image.Name == "Direction" and image:IsA("ImageLabel") then
			image.Visible = false
		end
	end
end

local v15 = { Teammate = "Player", Enemy = "Enemy", DeadTeammate = "Dead" }

local function CreateIcon(radarContainer, p: string, p2: number)
	local v16 = v15[p]

	if not v16 then
		error(`Invalid icon type: {p}`)
	end

	local clone = radar[v16]:Clone()
	clone.ZIndex = v5[p]
	clone.Position = UDim2.fromScale(0.5, 0.5)
	clone.AnchorPoint = Vector2.new(0.5, 0.5)
	clone.Size = UDim2.fromOffset(p2, p2)
	clone.Parent = radarContainer
	HideDirectionIndicators(clone)
	return clone
end

local function GetHostageAsset() -- 3 equivalent calls inferred from this helper
	local hostage = radar:FindFirstChild("Hostage")

	if hostage and hostage:IsA("ImageLabel") then
		return hostage
	end

	return radar.Player
end

local function ApplyEnemyIconImage(p, instance)
	if PlayerHasBomb(instance) then
		p.Image = radar.Bomb.Image
		p.Size = UDim2.fromOffset(14, 14)
	elseif PlayerIsCarryingHostage(instance) then -- inferred equivalent call
		p.Image = GetHostageAsset().Image -- inferred equivalent call
		p.Size = UDim2.fromOffset(30, 30)
	else
		p.Image = radar.Player.Image
		p.Size = UDim2.fromOffset(12, 12)
	end
end

local function GetYawUIDeg(lookVector: Vector3, part) -- 2 equivalent calls inferred from this helper
	local vector = Vector3.new(lookVector.X, 0, lookVector.Z)
	local v16 = vector.Magnitude < 1e-6 and createVector(0, 0, 1) or vector.Unit

	if part then
		v16 = part.CFrame:VectorToObjectSpace(v16)
	end

	local x = v16.X
	local z = v16.Z
	local v17 = -x
	return (math.deg((math.atan2(-z, v17))) + 90) % 360
end

local function ProjectToRadar(p, data, vector: Vector3, p2: number?, p3: number?)
	local size = data.Size
	local textureSize = data.TextureSize
	local pointToObjectSpace = data.Part.CFrame:PointToObjectSpace(vector)
	local x = pointToObjectSpace.X
	local z = pointToObjectSpace.Z
	local v16 = -x
	local v17 = -z
	local v18 = v16 / size.X + 0.5
	local v19 = v17 / size.Z + 0.5
	local imageRectOffset = p.MapImage.ImageRectOffset
	local imageRectSize = p.MapImage.ImageRectSize

	if p2 and p3 then
		v18 += p2 * imageRectSize.X / textureSize
		v19 += p3 * imageRectSize.Y / textureSize
	end

	local v20 = v18 * textureSize
	local v21 = v19 * textureSize
	local v22 = v20 - imageRectOffset.X
	local v23 = v21 - imageRectOffset.Y
	local v24 = v22 / imageRectSize.X
	local v25 = v23 / imageRectSize.Y

	if p.MapImage.Rotation == 0 then
		return v24, v25
	end

	local rotation = math.rad(p.MapImage.Rotation)
	local v26 = math.cos(rotation)
	local v27 = math.sin(rotation)
	local v28 = v24 - 0.5
	local v29 = v25 - 0.5
	v24 = 0.5 + (v28 * v26 - v29 * v27)
	v25 = 0.5 + (v28 * v27 + v29 * v26)
	return v24, v25
end

local function ClampToRadarCircle(p: number, p2: number, p3: number)
	local v16 = p - 0.5
	local v17 = p2 - 0.5
	local v18 = math.sqrt(v16 * v16 + v17 * v17)

	if v18 > 0.5 then
		local v19 = v16 / v18
		local v20 = v17 / v18
		return v19 * p3 + 0.5, v20 * p3 + 0.5, v18
	else
		return p, p2, v18
	end
end

local function GetClampedRadarPosition(p, p2, vector: Vector3)
	local v16, v17 = ProjectToRadar(p, p2, vector)
	return ClampToRadarCircle(v16, v17, 0.5)
end

local function ScheduleDeadIconFade(object2, p: string) -- 1 equivalent call inferred from this helper
	task.delay(2, function()
		local icon = object2.Icons[p]

		if icon and icon.Instance and icon.Instance.Parent then
			object2.FadedDeadIcons[p] = true
			local tween = TweenService:Create(
				icon.Instance,
				TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
				{ ImageTransparency = 1 }
			)
			tween:Play()
			tween.Completed:Connect(function()
				if object2.Icons[p] then
					object2:RemoveIcon(p)
				end
			end)
		end
	end)
end

local function CreateRadarCircle(p, name: string, flag: boolean)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.ZIndex = 14
	frame.Parent = p.RadarContainer

	if flag then
		frame.Visible = false
	end

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = color4
	uiStroke.Thickness = 2
	uiStroke.Transparency = 1
	uiStroke.Parent = frame
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = frame
	return frame
end

local function GetCircleRadius(settings, p: number) -- 2 equivalent calls inferred from this helper
	local v16 = math.clamp(settings.Zoom or 0.5, 0.1, 1)
	local effectiveScale = GetEffectiveScale(settings.Scale or 1) -- inferred equivalent call
	local v17 = p * (0.5 / v16) * effectiveScale
	local v18 = v2 / 2 * effectiveScale
	return math.min(v17, v18), v18
end

local function IsCharacterMoving(p) -- 2 equivalent calls inferred from this helper
	if not p then
		return false
	end

	local globalDirection = p.GlobalDirection
	local globalVelocity = p.GlobalVelocity

	if globalDirection and globalVelocity then
		local magnitude = Vector3.new(globalVelocity.X, 0, globalVelocity.Z).Magnitude
		return globalDirection.Magnitude > 0.1 or magnitude > 0.1
	else
		return false
	end
end

local function GetSiteShift(p: string?, p2: string)
	local v16

	if p then
		v16 = v9[p]
	end

	local v17 = v16 and v16[p2]

	if v17 then
		return v17[1], v17[2]
	end

	return nil, nil
end

local function ClearEnemyTracking(p, p2: string) -- 4 equivalent calls inferred from this helper
	p.EnemyVisibilityState[p2] = nil
	p.EnemyLastSeenPositions[p2] = nil
	p.EnemyLastSeenPositions[p2 .. "_Frozen"] = nil
end

local function CreateDeadIcon(object2, player, p: string, imageColor: Color3?)
	local instance = CreateIcon(object2.RadarContainer, "DeadTeammate", 12)
	instance.Name = Participants.Name(player) .. "_Dead"
	instance.ImageTransparency = 0

	if imageColor then
		instance.ImageColor3 = imageColor
	end

	object2.Icons[p] = {
		Instance = instance,
		Player = player,
		Type = "DeadTeammate",
		DefaultSize = radar.Dead.Size
	}
	ScheduleDeadIconFade(object2, p) -- inferred equivalent call
	return instance
end

function Radar:GetTrackedPosition()
	local v16 = SpectateController.IsFreecamActive() and GetCurrentCamera() -- inferred equivalent call

	if v16 then
		return v16.CFrame.Position
	end

	local character = self.Character
	local primaryPart = character and character.PrimaryPart
	return primaryPart and primaryPart.Position
end

function Radar:WorldToRadar(vector: Vector3)
	if not (self.MinimapReference and (SpectateController.IsFreecamActive() or CharacterResolver.getRootPart(self.Character))) then
		return nil
	end

	local minimapReference = self.MinimapReference
	local size = minimapReference.Size

	if size.X == 0 or size.Z == 0 then
		return nil
	end

	local imageRectSize = self.MapImage.ImageRectSize

	if imageRectSize.X == 0 or imageRectSize.Y == 0 then
		return nil
	end

	local v16, v17 = ProjectToRadar(self, minimapReference, vector)
	return Vector2.new(v16, v17)
end

local function CalculateClampedPosition(frame, p: number, udim: UDim2)
	local currentCamera = GetCurrentCamera() -- inferred equivalent call
	local viewportSize

	if currentCamera then
		viewportSize = currentCamera.ViewportSize
	else
		viewportSize = frame.AbsoluteSize
	end

	local x = viewportSize.X
	local y = viewportSize.Y
	local x2 = GuiService:GetGuiInset().X
	local v16 = x2 + 50
	local anchorPoint = frame.AnchorPoint
	local v17 = udim.X.Scale * x + udim.X.Offset
	local v18 = udim.Y.Scale * y + udim.Y.Offset
	local v19, v20, v21, v22

	if anchorPoint.X == 0.5 and anchorPoint.Y == 0.5 then
		v19 = v17 - p / 2
		v20 = v18 - p / 2
		v21 = v17 + p / 2
		v22 = v18 + p / 2
	else
		v19 = v17 - anchorPoint.X * p
		v20 = v18 - anchorPoint.Y * p
		v21 = v19 + p
		v22 = v20 + p
	end

	local v23 = 0
	local v24 = not (v19 < x2 + 10) and 0 or x2 + 10 - v19

	if x - 10 < v21 then
		v24 = x - 10 - v21
	end

	if v20 < v16 + 10 then
		v23 = v16 + 10 - v20
	end

	if y - 10 < v22 then
		v23 = y - 10 - v22
	end

	return UDim2.new(UDim.new(0, v17 + v24), UDim.new(0, v18 + v23))
end

function Radar:UpdateIcon(p: string, vector: Vector3, p2: number?)
	local icon = self.Icons[p]

	if not icon then
		return
	end

	local worldToRadar = self:WorldToRadar(vector)

	if not worldToRadar then
		icon.Instance.Visible = false
		return
	end

	local x = worldToRadar.X
	local y = worldToRadar.Y
	local v16 = x - 0.5
	local v17 = y - 0.5
	local v18 = math.sqrt(v16 * v16 + v17 * v17)

	if v18 > 0.5 then
		local v19 = v16 / v18
		local v20 = v17 / v18
		x = v19 * 0.5 + 0.5
		y = v20 * 0.5 + 0.5
	end

	icon.Instance.Visible = true
	icon.Instance.Position = UDim2.fromScale(x, y)

	if p2 then
		icon.Instance.Rotation = math.deg(p2)
	end
end

function Radar:UpdateTeammateIcon(p: string, vector: Vector3, p2: number?)
	local icon = self.Icons[p]

	if not icon then
		return
	end

	local instance = icon.Instance

	if not (instance and instance:IsA("GuiObject")) then
		return
	end

	if not self.MinimapReference then
		instance.Visible = false
		return
	end

	local v16, v17 = ProjectToRadar(self, self.MinimapReference, vector)
	local v18 = v16 - 0.5
	local v19 = v17 - 0.5
	local v20 = math.sqrt(v18 * v18 + v19 * v19)

	if v20 > 0.5 then
		local v21 = v18 / v20
		local v22 = v19 / v20
		v16 = v21 * 0.5 + 0.5
		v17 = v22 * 0.5 + 0.5
	end

	instance.Position = UDim2.fromScale(v16, v17)
	instance.Visible = true

	if p2 and instance:IsA("ImageLabel") then
		instance.Rotation = math.deg(p2)
	end
end

function Radar:CreatePlayerIcon(instance, p: string)
	local clone

	if p == "Enemy" then
		local playerHasBomb = PlayerHasBomb(instance)
		local playerIsCarryingHostage = PlayerIsCarryingHostage(instance) -- inferred equivalent call

		if playerHasBomb then
			clone = radar.Bomb:Clone()
			clone.Size = UDim2.fromOffset(14, 14)
		elseif playerIsCarryingHostage then
			clone = GetHostageAsset():Clone() -- inferred equivalent call
			clone.Size = UDim2.fromOffset(30, 30)
		else
			clone = radar.Player:Clone()
			clone.Size = UDim2.fromOffset(12, 12)
		end

		clone.ImageColor3 = color3
		clone.ZIndex = 17
		clone.Position = UDim2.fromScale(0.5, 0.5)
		clone.AnchorPoint = Vector2.new(0.5, 0.5)
		clone.Parent = self.RadarContainer
		HideDirectionIndicators(clone)
	else
		local imageColor = GetTeammateDisplayColor(instance, instance:GetAttribute("Team")) -- inferred equivalent call
		clone = CreateIcon(self.RadarContainer, p, 12)

		if imageColor then
			clone.ImageColor3 = imageColor
		end
	end

	clone.Name = Participants.Name(instance)
	local v16 = Participants.Key(instance) .. "_" .. p
	self.Icons[v16] = { Instance = clone, Player = instance, Type = p }
	return v16
end

function Radar:RemoveIcon(p: string)
	local icon = self.Icons[p]

	if icon then
		icon.Instance:Destroy()
		self.Icons[p] = nil
	end
end

function Radar:RefreshPlayerIcon(p)
	local key = Participants.Key(p)
	local v16 = key .. "_Player"
	local v17 = key .. "_Dead"
	self:RemoveIcon(v16)
	self:RemoveIcon(v17)
	self.EnemyVisibilityCache[v16] = nil
	ClearEnemyTracking(self, v16) -- inferred equivalent call
	self.DeadPlayerPositions[key] = nil
	self.FadedDeadIcons[v17] = nil
end

function Radar:RefreshIconsOnTeamChange()
	local team = self.Team
	local team2 = LocalPlayer:GetAttribute("Team")

	if not team2 then
		return
	end

	self.Team = team2

	if self.Team == team then
		return
	end

	for k, icon in pairs(self.Icons) do
		if icon.Player and icon.Player ~= LocalPlayer then
			self:RemoveIcon(k)
		end
	end

	table.clear(self.EnemyVisibilityCache)
	table.clear(self.HostageVisibilityCache)
	self.BombVisibilityCache = nil
	self.EnemyVisibilityState = {}
	self.EnemyLastSeenPositions = {}
	self.DeadPlayerPositions = {}
	self.FadedDeadIcons = {}

	if self.Icons.LocalPlayer then
		local instance = self.Icons.LocalPlayer.Instance
		local imageColor = GetTeammateDisplayColor(self.LocalPlayer, self.Team) -- inferred equivalent call

		if imageColor then
			instance.ImageColor3 = imageColor
		end
	end
end

function Radar:UpdatePlayerIcons()
	Profiler.mark("UI.Radar.UpdatePlayerIcons")
	local deathmatchGamemode = IsDeathmatchGamemode() -- inferred equivalent call
	local now = tick()
	local rootPart = CharacterResolver.getRootPart(self.Character)
	local cframe

	if SpectateController.IsFreecamActive() then
		local currentCamera = GetCurrentCamera() -- inferred equivalent call
		cframe = currentCamera and currentCamera.CFrame
	end

	local v16 = cframe ~= nil

	for k, icon in pairs(self.Icons) do
		if icon.Instance.Parent == nil then
			self.Icons[k] = nil
		end
	end

	local part = self.MinimapReference and self.MinimapReference.Part
	local v17 = cframe or rootPart and rootPart.CFrame

	if v17 then
		if not self.Icons.LocalPlayer then
			local clone = radar.Player:Clone()
			clone.Position = UDim2.fromScale(0.5, 0.5)
			clone.AnchorPoint = Vector2.new(0.5, 0.5)
			clone.ZIndex = 15
			clone.Parent = self.RadarContainer
			clone.Name = "LocalPlayer"
			self.Icons.LocalPlayer = {
				Instance = clone,
				Player = self.LocalPlayer,
				Type = "Teammate"
			}
		end

		local instance = self.Icons.LocalPlayer.Instance
		instance.Visible = true

		if v16 then
			instance.ImageColor3 = GetTeammateDisplayColor(LocalPlayer, LocalPlayer:GetAttribute("Team")) or color -- inferred equivalent call
		else
			local imageColor = GetTeammateDisplayColor(self.LocalPlayer, self.Team) -- inferred equivalent call

			if imageColor then
				instance.ImageColor3 = imageColor
			end
		end

		if not v16 and PlayerHasBomb(self.LocalPlayer) then
			instance.Image = radar.Bomb.Image
			instance.Size = UDim2.fromOffset(14, 14)
		else
			instance.Image = radar.Player.Image
			instance.Size = UDim2.fromOffset(12, 12)
		end

		local v18

		if part then
			v18 = GetYawUIDeg(v17.LookVector, part) + self.MapImage.Rotation + 0 -- inferred equivalent call
		else
			v18 = 0
		end

		self:UpdateIcon("LocalPlayer", v17.Position, (math.rad(v18)))
	end

	for _, v18 in ipairs(Participants.GetAll()) do
		local key = Participants.Key(v18)
		local v19 = key .. "_Player"

		if v16 or v18 ~= self.LocalPlayer then
			local v20 = key .. "_Dead"
			local radarCharacter = getRadarCharacter(v18)
			local rootPart2 = CharacterResolver.getRootPart(radarCharacter)
			local team = v18:GetAttribute("Team")

			if team and team ~= "Spectators" then
				local position = self.DeadPlayerPositions[key]
				local v21

				if position == nil then
					if radarCharacter == nil then
						v21 = false
					else
						v21 = radarCharacter:GetAttribute("Dead") == true
					end
				else
					v21 = true
				end

				local v22 = v18:GetAttribute("Dead") == true or v21
				local v23

				if deathmatchGamemode then
					v23 = deathmatchGamemode
				else
					v23 = not v16 and team ~= self.Team
				end

				if v22 then
					self:RemoveIcon(v19)

					if not position and rootPart2 then
						position = rootPart2.Position
						self.DeadPlayerPositions[key] = position
					end

					if position and not (self.Icons[v20] or self.FadedDeadIcons[v20]) then
						local v24

						if v23 then
							v24 = color3
						else
							v24 = GetTeammateDisplayColor(v18, team) -- inferred equivalent call
						end

						CreateDeadIcon(self, v18, v20, v24)
					end

					if v23 then
						ClearEnemyTracking(self, v19) -- inferred equivalent call
					end
				else
					if radarCharacter and rootPart2 then
						self:RemoveIcon(v20)
						self.DeadPlayerPositions[key] = nil
						self.FadedDeadIcons[v20] = nil
						local icon = self.Icons[v19]

						if icon and v23 ~= (icon.Type ~= "Teammate") then
							self:RemoveIcon(v19)
						end

						if not self.Icons[v19] then
							local playerIcon = self:CreatePlayerIcon(v18, v23 and "Enemy" or "Teammate")
							self.Icons[v19] = self.Icons[playerIcon]
							self.Icons[playerIcon] = nil

							if v23 then
								self.Icons[v19].Instance.Visible = false
							end
						end
					end

					local icon = self.Icons[v19]

					if v23 then
						if icon then
							local isAlive = Participants.IsAlive(v18)

							if radarCharacter or isAlive then
								local v24

								if v16 then
									v24 = v16
								elseif radarCharacter == nil then
									v24 = false
								else
									v24 = GetEnemyVisibility(self, v19, radarCharacter, v18, now)
								end

								if v24 then
									if icon.Type == "EnemyQuestionMark" then
										local fadeTween = icon.FadeTween

										if fadeTween then
											fadeTween:Cancel()
											icon.FadeTween = nil
										end

										local instance = icon.Instance

										if instance:IsA("TextLabel") then
											local position2 = instance.Position
											local anchorPoint = instance.AnchorPoint
											instance:Destroy()
											local imageLabel = Instance.new("ImageLabel")
											imageLabel.Name = Participants.Name(v18) .. "_Enemy"
											ApplyEnemyIconImage(imageLabel, v18)
											imageLabel.ImageColor3 = color3
											imageLabel.BackgroundTransparency = 1
											imageLabel.BorderSizePixel = 0
											imageLabel.Position = position2
											imageLabel.AnchorPoint = anchorPoint
											imageLabel.ZIndex = 17
											imageLabel.Visible = true
											imageLabel.Parent = self.RadarContainer
											icon.Instance = imageLabel
											icon.Type = "Enemy"
											self.EnemyLastSeenPositions[v19 .. "_Frozen"] = nil
										end
									end

									if rootPart2 then
										local instance = icon.Instance
										instance.Visible = true
										instance.ImageColor3 = color3
										ApplyEnemyIconImage(instance, v18)
										self:UpdateTeammateIcon(v19, rootPart2.Position, nil)
										self.EnemyLastSeenPositions[v19] = rootPart2.Position
									else
										self:RemoveIcon(v19)
									end
								else
									if self.EnemyVisibilityState[v19] then
										local instance = icon.Instance
										local position2 = nil
										local anchorPoint = nil
										local fadeTween = icon.FadeTween

										if fadeTween then
											fadeTween:Cancel()
											icon.FadeTween = nil
										end

										if instance:IsA("ImageLabel") or instance:IsA("TextLabel") then
											position2 = instance.Position
											anchorPoint = instance.AnchorPoint
											instance:Destroy()
										end

										local clone = radar.EnemySeen:Clone()
										clone.Name = Participants.Name(v18) .. "_QuestionMark"
										clone.Position = position2
										clone.AnchorPoint = anchorPoint
										clone.ZIndex = 20
										clone.TextTransparency = 0
										clone.Visible = true
										clone.Parent = self.RadarContainer
										icon.Instance = clone
										icon.Type = "EnemyQuestionMark"

										if self.EnemyLastSeenPositions[v19] then
											self.EnemyLastSeenPositions[v19 .. "_Frozen"] = self.EnemyLastSeenPositions[v19]
										end

										task.delay(0.1, function()
											local icon2 = self.Icons[v19]

											if icon2 and icon2.Instance == clone and clone:IsA("TextLabel") then
												local instance2 = clone
												instance2.TextTransparency = 0
												local tween = TweenService:Create(
													instance2,
													TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
													{ TextTransparency = 1 }
												)
												tween:Play()
												icon2.FadeTween = tween
												tween.Completed:Connect(function(p)
													local icon3 = self.Icons[v19]

													if
														p == Enum.PlaybackState.Completed
														and icon3
														and icon3.Instance == instance2
														and icon3.FadeTween == tween
													then
														self:RemoveIcon(v19)
														self.EnemyLastSeenPositions[v19 .. "_Frozen"] = nil
													end
												end)
											end
										end)
									end

									if icon.Type == "EnemyQuestionMark" then
										local enemyLastSeenPosition = self.EnemyLastSeenPositions[v19 .. "_Frozen"]

										if enemyLastSeenPosition then
											self:UpdateQuestionMarkIcon(v19, enemyLastSeenPosition)
										end
									else
										icon.Instance.Visible = false
									end
								end

								if self.Icons[v19] then
									self.EnemyVisibilityState[v19] = v24
								end
							else
								self:RemoveIcon(v19)
								local v24 = self.EnemyLastSeenPositions[v19]
									or self.EnemyLastSeenPositions[v19 .. "_Frozen"]

								if v24 then
									self.DeadPlayerPositions[key] = v24

									if not (self.Icons[v20] or self.FadedDeadIcons[v20]) then
										CreateDeadIcon(self, v18, v20, color3)
									end
								end

								ClearEnemyTracking(self, v19) -- inferred equivalent call
							end
						end
					elseif rootPart2 then
						self:UpdateTeammateIcon(v19, rootPart2.Position, nil)
					else
						self:RemoveIcon(v19)
					end
				end
			else
				self:RemoveIcon(v19)
				self:RemoveIcon(v20)
				ClearEnemyTracking(self, v19) -- inferred equivalent call
				self.DeadPlayerPositions[key] = nil
				self.FadedDeadIcons[v20] = nil
			end
		else
			self:RemoveIcon(v19)
		end
	end

	for k, deadPlayerPosition in pairs(self.DeadPlayerPositions) do
		local icon = self.Icons[k .. "_Dead"]

		if not (icon and self.MinimapReference) then
			continue
		end

		local v18, v19 = ProjectToRadar(self, self.MinimapReference, deadPlayerPosition)
		local v20 = v18 - 0.5
		local v21 = v19 - 0.5
		local v22 = math.sqrt(v20 * v20 + v21 * v21)

		if v22 > 0.5 then
			local v23 = v20 / v22
			local v24 = v21 / v22
			v18 = v23 * 0.5 + 0.5
			v19 = v24 * 0.5 + 0.5
		end

		icon.Instance.Position = UDim2.fromScale(v18, v19)
		icon.Instance.Visible = true
	end
end

local function SetBombIconAppearance(guiObject, p: number, imageColor: Color3?)
	if guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
		guiObject.ImageTransparency = p

		if imageColor then
			guiObject.ImageColor3 = imageColor
		end
	elseif guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") then
		guiObject.TextTransparency = p
	end
end

function Radar:UpdateBombIcon()
	Profiler.mark("UI.Radar.UpdateBombIcon")
	local v16 = nil
	local v17 = self.Team == "Counter-Terrorists"
	local model = CollectionService:GetTagged("Bomb")[1]

	if Workspace:GetAttribute("ServerGamemode") == "Competitive" then
		model = nil
	end

	if model and model:IsA("Model") and model.PrimaryPart then
		v16 = model
	else
		for _, model2 in ipairs(CollectionService:GetTagged("WeaponDropped")) do
			if not (model2:IsA("Model") and model2.PrimaryPart and model2:GetAttribute("Weapon") == "C4") then
				continue
			end

			v16 = model2
			break
		end
	end

	if v16 then
		if not self.Icons.Bomb then
			local clone = radar.Bomb:Clone()
			clone.Position = UDim2.fromScale(0.5, 0.5)
			clone.AnchorPoint = Vector2.new(0.5, 0.5)
			clone.Parent = self.RadarContainer
			clone.Size = UDim2.fromOffset(14, 14)
			clone.ZIndex = 19
			clone.Name = "Bomb"
			self.Icons.Bomb = { Instance = clone, Player = nil, Type = "Bomb" }
		end

		local instance = self.Icons.Bomb.Instance

		if not self.MinimapReference then
			instance.Visible = false
			return
		end

		local position = v16.PrimaryPart.Position
		local v18, v19 = ProjectToRadar(self, self.MinimapReference, position)
		local v20 = v18 - 0.5
		local v21 = v19 - 0.5
		local v22 = math.sqrt(v20 * v20 + v21 * v21)

		if v22 > 0.5 then
			local v23 = v20 / v22
			local v24 = v21 / v22
			v18 = v23 * 0.5 + 0.5
			v19 = v24 * 0.5 + 0.5
		end

		instance.Position = UDim2.fromScale(v18, v19)

		if v17 and not model then
			local now = tick()
			local visible = ReadCachedVisibility(self.BombVisibilityCache, now) -- inferred equivalent call

			if visible == nil then
				visible = IsVisibleToTeam("Counter-Terrorists", position, v16, self.LocalPlayer)
				self.BombVisibilityCache = { Visible = visible, UpdatedAt = now }
			end

			if visible then
				if not self.BombIsVisible then
					self.BombFadeStartTime = nil
				end

				self.BombIsVisible = true
				instance.Visible = true
				SetBombIconAppearance(instance, 0, color2)
			else
				if self.BombIsVisible then
					self.BombFadeStartTime = now
				end

				self.BombIsVisible = false

				if self.BombFadeStartTime then
					local v23 = math.clamp((now - self.BombFadeStartTime) / 8, 0, 1)

					if v23 >= 1 then
						instance.Visible = false
						return
					end

					instance.Visible = true

					if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
						instance.ImageTransparency = v23
					elseif instance:IsA("TextLabel") or instance:IsA("TextButton") then
						instance.TextTransparency = v23
					end
				else
					instance.Visible = false
				end
			end
		else
			instance.Visible = true
			local v23

			if model and v17 and v22 > 0.5 then
				v23 = color2
			end

			SetBombIconAppearance(instance, 0, v23)
		end
	else
		if self.Icons.Bomb then
			self.Icons.Bomb.Instance.Visible = false
			self.BombIsVisible = false
			self.BombFadeStartTime = nil
		end

		self.BombVisibilityCache = nil
	end
end

function Radar:UpdateQuestionMarkIcon(p: string, vector: Vector3)
	local icon = self.Icons[p]

	if not (icon and self.MinimapReference) then
		return
	end

	local instance = icon.Instance

	if not (instance and instance:IsA("TextLabel")) then
		return
	end

	local v16, v17 = ProjectToRadar(self, self.MinimapReference, vector)
	local v18 = v16 - 0.5
	local v19 = v17 - 0.5
	local v20 = math.sqrt(v18 * v18 + v19 * v19)

	if v20 > 0.5 then
		local v21 = v18 / v20
		local v22 = v19 / v20
		v16 = v21 * 0.5 + 0.5
		v17 = v22 * 0.5 + 0.5
	end

	instance.Position = UDim2.fromScale(v16, v17)
	instance.Visible = true
end

function Radar:UpdateSiteIcons()
	Profiler.mark("UI.Radar.UpdateSiteIcons")

	for childName, sitePart in pairs(self.SiteParts) do
		local v16 = "Site_" .. childName
		local siteCenter = GetSiteCenter(sitePart) -- inferred equivalent call

		if not self.Icons[v16] then
			local child = radar:FindFirstChild(childName)

			if not child then
				warn(`Site icon template not found for: {childName}`)
				continue
			end

			local clone = child:Clone()
			clone.Name = childName .. "_Icon"
			clone.Position = UDim2.fromScale(0.5, 0.5)
			clone.AnchorPoint = Vector2.new(0.5, 0.5)
			clone.ZIndex = 16
			clone.Visible = true

			if clone:IsA("TextLabel") then
				clone.TextXAlignment = Enum.TextXAlignment.Center
				clone.TextYAlignment = Enum.TextYAlignment.Center
			end

			clone.Parent = self.RadarContainer
			self.Icons[v16] = {
				Instance = clone,
				Player = nil,
				Type = "Site",
				DefaultSize = child.Size
			}
		end

		local icon = self.Icons[v16]

		if self.MinimapReference then
			local v17 = 0.5 / math.clamp(self.Settings.Zoom or 0.5, 0.1, 1)
			local map = workspace:GetAttribute("Map")
			local v18

			if map then
				v18 = v9[map]
			end

			local v19 = v18 and v18[childName]
			local v20, v21

			if v19 then
				v20 = v19[1]
				v21 = v19[2]
			end

			if v20 and v21 then
				v20 *= v17
				v21 *= v17
			end

			local v22, v23 = ProjectToRadar(self, self.MinimapReference, siteCenter, v20, v21)
			local v24 = v22 - 0.5
			local v25 = v23 - 0.5
			local v26 = math.sqrt(v24 * v24 + v25 * v25)

			if v26 > 0.5 then
				local v27 = v24 / v26
				local v28 = v25 / v26
				v22 = v27 * 0.485 + 0.5
				v23 = v28 * 0.485 + 0.5
			end

			icon.Instance.Position = UDim2.fromScale(v22, v23)
			icon.Instance.Visible = true
			local defaultSize = icon.DefaultSize

			if defaultSize then
				if v26 > 0.5 then
					icon.Instance.Size = defaultSize
				else
					icon.Instance.Size = UDim2.new(
						defaultSize.X.Scale * v17,
						defaultSize.X.Offset * v17,
						defaultSize.Y.Scale * v17,
						defaultSize.Y.Offset * v17
					)
				end
			end
		else
			icon.Instance.Visible = false
		end
	end
end

function Radar:UpdateHostageIcons()
	Profiler.mark("UI.Radar.UpdateHostageIcons")
	local now = tick()
	local v16 = {}

	for _, model in ipairs(CollectionService:GetTagged("Hostage")) do
		if not (model:IsA("Model") and model.PrimaryPart) then
			continue
		end

		local name = model.Name
		local v17 = "Hostage_" .. name
		v16[v17] = true

		if not self.Icons[v17] then
			local clone = GetHostageAsset():Clone() -- inferred equivalent call
			clone.Position = UDim2.fromScale(0.5, 0.5)
			clone.AnchorPoint = Vector2.new(0.5, 0.5)
			clone.Parent = self.RadarContainer
			clone.Size = UDim2.fromOffset(30, 30)
			clone.ZIndex = 18
			clone.Name = "Hostage_" .. name
			clone.Visible = true
			HideDirectionIndicators(clone)
			self.Icons[v17] = { Instance = clone, Player = nil, Type = "Hostage" }
		end

		local icon = self.Icons[v17]

		if self.MinimapReference then
			local position = model.PrimaryPart.Position
			local carryingPlayer = model:GetAttribute("CarryingPlayer")

			if carryingPlayer then
				local player = Players:FindFirstChild(carryingPlayer)
				local v18

				if player and player:IsA("Player") then
					v18 = getRadarCharacter(player)
				end

				if v18 and v18.PrimaryPart then
					position = v18.PrimaryPart.Position
				end
			end

			local v18, v19 = ProjectToRadar(self, self.MinimapReference, position)
			local v20 = v18 - 0.5
			local v21 = v19 - 0.5
			local v22 = math.sqrt(v20 * v20 + v21 * v21)

			if v22 > 0.5 then
				local v23 = v20 / v22
				local v24 = v21 / v22
				v18 = v23 * 0.5 + 0.5
				v19 = v24 * 0.5 + 0.5
			end

			icon.Instance.Position = UDim2.fromScale(v18, v19)
			local team = self.Team

			if carryingPlayer == nil then
				icon.Instance.Visible = team == "Terrorists"
			elseif team == "Terrorists" then
				icon.Instance.Visible = GetHostageVisibility(self, v17, position, model, now)
			else
				icon.Instance.Visible = true
			end
		else
			icon.Instance.Visible = false
		end
	end

	for k, icon in pairs(self.Icons) do
		if icon.Type ~= "Hostage" or v16[k] then
			continue
		end

		self.HostageVisibilityCache[k] = nil
		self:RemoveIcon(k)
	end
end

function Radar:UpdateMinimapTexture()
	Profiler.mark("UI.Radar.UpdateMinimapTexture")

	if not self.MinimapReference then
		return
	end

	local minimapReference = self.MinimapReference
	local part = minimapReference.Part

	if part then
		local lower = part:FindFirstChild("Lower")
		local upper = part:FindFirstChild("Upper")

		if lower and lower:IsA("Decal") then
			minimapReference.Lower = lower
		end

		if upper and upper:IsA("Decal") then
			minimapReference.Upper = upper
		end
	end

	local lower = minimapReference.Lower or minimapReference.Upper

	if not lower then
		return
	end

	self.MapImage.Image = lower.Texture
	self.MapImage.ImageTransparency = 0

	if not lower.Texture:match("%d+") then
		return
	end

	local textureSize = minimapReference.TextureSize
	local upperLayerHeight = GetUpperLayerHeight(workspace:GetAttribute("Map")) -- inferred equivalent call
	local upper = minimapReference.Upper
	local upperMapImage = self.UpperMapImage
	local v16

	if upperLayerHeight == nil or upper == nil then
		v16 = false
	else
		v16 = upperMapImage ~= nil
	end

	local trackedPosition = self:GetTrackedPosition()

	if v16 and upperMapImage and upper then
		upperMapImage.Image = upper.Texture

		if trackedPosition then
			upperMapImage.ImageTransparency = upperLayerHeight ~= nil and upperLayerHeight <= trackedPosition.Y and 0
				or 1
		end
	end

	local rotation = 90
	local vector, vector2

	if trackedPosition then
		local pointToObjectSpace = part.CFrame:PointToObjectSpace(trackedPosition)
		local size = minimapReference.Size
		local x = pointToObjectSpace.X
		local z = pointToObjectSpace.Z
		local v17 = -x
		local v18 = -z
		local v19 = v17 / size.X + 0.5
		local v20 = v18 / size.Z + 0.5
		local v21 = textureSize * math.clamp(self.Settings.Zoom or 0.7, 0.1, 1) * 0.5
		local v22 = math.clamp(v19 * textureSize - v21 / 2, 0, textureSize - v21)
		local v23 = math.clamp(v20 * textureSize - v21 / 2, 0, textureSize - v21)
		vector = Vector2.new(RoundToPixel(v22), RoundToPixel(v23)) -- inferred equivalent call
		vector2 = Vector2.new(v21, v21)

		if not self.IsSpectating and self.Settings.Rotation then
			local currentCamera = GetCurrentCamera() -- inferred equivalent call

			if currentCamera then
				rotation = -GetYawUIDeg(currentCamera.CFrame.LookVector, part) + 90 - 90 -- inferred equivalent call
			end
		end
	else
		vector = Vector2.new(0, 0)
		vector2 = Vector2.new(textureSize, textureSize)
	end

	self.MapImage.ImageRectOffset = vector
	self.MapImage.ImageRectSize = vector2
	self.MapImage.Rotation = rotation

	if v16 and upperMapImage then
		upperMapImage.ImageRectOffset = vector
		upperMapImage.ImageRectSize = vector2
		upperMapImage.Rotation = rotation
	end
end

function Radar:ApplySettings()
	Profiler.mark("UI.Radar.ApplySettings")
	self.MapImage.Size = UDim2.fromScale(1, 1)

	if self.UpperMapImage then
		self.UpperMapImage.Size = UDim2.fromScale(1, 1)
	end

	local v16 = v2 * GetEffectiveScale(self.Settings.Scale or 1) -- inferred equivalent call
	self.Frame.Size = UDim2.fromOffset(v16, v16)
	self.RadarContainer.Size = UDim2.fromOffset(v16, v16)
	local udim = UDim2.new(0, 10, 0, 10)
	self.Frame.Position = CalculateClampedPosition(self.Frame, v16, udim)
	self:UpdateMinimapTexture()
end

function Radar:FlashRadarBorder()
	if not (v10 and v10.Radar) then
		return
	end

	local uiStroke = v10.Radar.UIStroke

	if not uiStroke then
		return
	end

	uiStroke.Color = color4

	if self.BorderRestoreTask then
		task.cancel(self.BorderRestoreTask)
		self.BorderRestoreTask = nil
	end

	self.BorderRestoreTask = task.delay(0.2, function()
		if v10 and v10.Radar and v10.Radar.UIStroke then
			v10.Radar.UIStroke.Color = GetPreferenceColor()
		end

		self.BorderRestoreTask = nil
	end)
end

function Radar:ShowWeaponCircle()
	local weaponCircle = self.WeaponCircle

	if not weaponCircle then
		weaponCircle = CreateRadarCircle(self, "WeaponCircle", true)
		self.WeaponCircle = weaponCircle
	end

	local uiStroke = weaponCircle:FindFirstChildOfClass("UIStroke")

	if not uiStroke then
		return
	end

	local v16 = v2 / 2 * GetEffectiveScale(self.Settings.Scale or 1) * 2 -- inferred equivalent call
	weaponCircle.Size = UDim2.fromOffset(v16, v16)
	uiStroke.Thickness = 2
	uiStroke.Transparency = 0
	weaponCircle.Visible = true

	if self.WeaponCircleHideTask then
		task.cancel(self.WeaponCircleHideTask)
		self.WeaponCircleHideTask = nil
	end

	self.WeaponCircleHideTask = task.delay(0.2, function()
		uiStroke.Transparency = 1
		weaponCircle.Visible = false
		self.WeaponCircleHideTask = nil
	end)
end

function Radar:ShowKnifeCircle()
	local knifeCircle = self.KnifeCircle

	if not knifeCircle then
		knifeCircle = CreateRadarCircle(self, "KnifeCircle", true)
		self.KnifeCircle = knifeCircle
	end

	local uiStroke = knifeCircle:FindFirstChildOfClass("UIStroke")

	if not uiStroke then
		return
	end

	local circleRadius, v16 = GetCircleRadius(self.Settings, v4) -- inferred equivalent call
	local v17 = circleRadius * 2
	knifeCircle.Size = UDim2.fromOffset(v17, v17)
	local v18 = circleRadius == v16
	uiStroke.Thickness = v18 and 2 or 1
	uiStroke.Transparency = v18 and 0 or 0.5
	knifeCircle.Visible = true
	task.delay(0.2, function()
		uiStroke.Transparency = 1
		knifeCircle.Visible = false
	end)
end

local function CancelRunningCircleDelay(p) -- 4 equivalent calls inferred from this helper
	if p.RunningCircleDelayTask then
		task.cancel(p.RunningCircleDelayTask)
		p.RunningCircleDelayTask = nil
	end
end

function Radar:UpdateRunningCircle()
	if not (self.Character and self.Character.PrimaryPart and CharacterResolver.isAliveCharacter(self.Character)) then
		return
	end

	local currentCharacter = CharacterController.getCurrentCharacter()
	local characterMoving = IsCharacterMoving(currentCharacter) -- inferred equivalent call
	local v16 = CharacterController.GetWalkState() or false
	local v17 = characterMoving and not v16
	local isJumping = currentCharacter and currentCharacter.IsJumping or false
	local wasRunning = v17 or isJumping
	local runningCircle = self.RunningCircle

	if not runningCircle then
		runningCircle = CreateRadarCircle(self, "RunningCircle", false)
		self.RunningCircle = runningCircle
	end

	local uiStroke = runningCircle:FindFirstChildOfClass("UIStroke")

	if not uiStroke then
		return
	end

	local circleRadius, v18 = GetCircleRadius(self.Settings, v3) -- inferred equivalent call
	local v19 = circleRadius * 2
	runningCircle.Size = UDim2.fromOffset(v19, v19)
	local v20 = circleRadius == v18
	uiStroke.Thickness = v20 and 2 or 1

	if wasRunning then
		uiStroke.Transparency = v20 and 0 or 0.5

		if isJumping then
			CancelRunningCircleDelay(self) -- inferred equivalent call
			runningCircle.Visible = true
		elseif v17 then
			if self.WasRunning then
				if not self.RunningCircleDelayTask then
					runningCircle.Visible = true
				end
			else
				CancelRunningCircleDelay(self) -- inferred equivalent call
				runningCircle.Visible = false
				uiStroke.Transparency = 1
				self.RunningCircleDelayTask = task.delay(0.4, function()
					if not (self.Character and self.Character.PrimaryPart) then
						self.RunningCircleDelayTask = nil
						return
					end

					local characterMoving2 = IsCharacterMoving(CharacterController.getCurrentCharacter()) -- inferred equivalent call
					local v21 = CharacterController.GetWalkState() or false

					if characterMoving2 and not v21 and self.RunningCircle then
						local runningCircle2 = self.RunningCircle
						local uiStroke2 = runningCircle2:FindFirstChildOfClass("UIStroke")

						if uiStroke2 then
							local settings = self.Settings
							local v22 = math.clamp(settings.Zoom or 0.5, 0.1, 1)
							local scale = settings.Scale or 1

							if v then
								scale = (scale - 1) * 0.5 + 1
							end

							local v23 = v3 * (0.5 / v22) * scale
							local v24 = v2 / 2 * scale
							uiStroke2.Transparency = math.min(v23, v24) == v24 and 0 or 0.5
							runningCircle2.Visible = true
						end
					end

					self.RunningCircleDelayTask = nil
				end)
			end
		end
	else
		CancelRunningCircleDelay(self) -- inferred equivalent call
		runningCircle.Visible = false
		uiStroke.Transparency = 1
	end

	self.WasRunning = wasRunning
end

function Radar:CreateDeadIconForPlayer(instance, vector: Vector3)
	self:RemoveIcon(Participants.Key(instance) .. "_Player")
	local v16 = Participants.Key(instance) .. "_Dead"

	if self.Icons[v16] or self.FadedDeadIcons[v16] then
		return
	end

	local team = instance:GetAttribute("Team")
	local v17

	if IsDeathmatchGamemode() or team ~= self.Team then -- inferred equivalent call
		v17 = color3
	else
		v17 = GetTeammateDisplayColor(instance, team) -- inferred equivalent call
	end

	local deadIcon = CreateDeadIcon(self, instance, v16, v17)

	if vector and self.MinimapReference then
		local v18, v19 = ProjectToRadar(self, self.MinimapReference, vector)
		local v20 = v18 - 0.5
		local v21 = v19 - 0.5
		local v22 = math.sqrt(v20 * v20 + v21 * v21)

		if v22 > 0.5 then
			local v23 = v20 / v22
			local v24 = v21 / v22
			v18 = v23 * 0.5 + 0.5
			v19 = v24 * 0.5 + 0.5
		end

		deadIcon.Position = UDim2.fromScale(v18, v19)
		deadIcon.Visible = true
	end
end

function Radar:Render(_: number)
	Profiler.mark("UI.Radar.Render")
	self.EnemyVisibilityChecksRemaining = 2
	self:UpdateMinimapTexture()
	self:UpdatePlayerIcons()
	self:UpdateBombIcon()
	self:UpdateSiteIcons()
	self:UpdateHostageIcons()
	self:UpdateRunningCircle()
end

local function DestroyUpperMapImages(object2)
	if object2.UpperMapImage then
		object2.UpperMapImage:Destroy()
		object2.UpperMapImage = nil
	end

	for _, image in ipairs(object2.RadarContainer:GetChildren()) do
		if image.Name == "UpperMap" and image:IsA("ImageLabel") then
			image:Destroy()
		end
	end
end

local function CreateUpperMapImage(object2)
	if
		GetUpperLayerHeight(workspace:GetAttribute("Map")) == nil -- inferred equivalent call
		or not (object2.MinimapReference and object2.MinimapReference.Upper)
	then
		return nil
	end

	local clone = object2.MapImage:Clone()
	clone.Name = "UpperMap"
	clone.ZIndex = 2
	clone.Parent = object2.RadarContainer
	return clone
end

function Radar.new(frame, character)
	Profiler.mark("UI.Radar.New")
	local object2 = setmetatable({}, Radar)
	object2.Janitor = Janitor.new()
	object2.Frame = frame
	object2.RadarContainer = frame.Radar
	object2.MapImage = frame.Radar.Map
	object2.MapImage.AnchorPoint = Vector2.new(0.5, 0.5)
	object2.MapImage.Position = UDim2.fromScale(0.5, 0.5)
	object2.MapImage.ZIndex = 1
	object2.LocalPlayer = LocalPlayer
	object2.Character = character
	object2.Team = LocalPlayer:GetAttribute("Team")
	object2.MinimapReference = GetMinimapReference()
	object2.UpperMapImage = CreateUpperMapImage(object2)

	if object2.UpperMapImage then
		object2.UpperMapImage.BackgroundTransparency = 1
	end

	object2.Frame.Visible = not IsTutorialMode()
	object2.Janitor:Add(function()
		object2.Frame.Visible = not IsTutorialMode()
	end)
	object2.Settings = settings2
	object2.IsSpectating = false
	object2.Icons = {}
	object2.SiteParts = GetSiteParts()
	object2.DeadPlayerPositions = {}
	object2.FadedDeadIcons = {}
	object2.EnemyVisibilityState = {}
	object2.EnemyLastSeenPositions = {}
	object2.EnemyVisibilityCache = {}
	object2.EnemyVisibilityChecksRemaining = 0
	object2.HostageVisibilityCache = {}
	object2.WasRunning = false
	object2.BombIsVisible = false
	object2:ApplySettings()
	local broadcastRouter = Router.broadcastRouter

	function Router.broadcastRouter(p: string, ...)
		local v16 = broadcastRouter(p, ...)

		if p ~= "UpdatePlayerNoiseCone" then
			return v16
		end

		local v17, v18 = ...

		if not (v18 and object2.Character and object2.Character.PrimaryPart and (v18 - object2.Character.PrimaryPart.Position).Magnitude < 5) then
			return v16
		end

		if v17 == "Melee" then
			object2:ShowKnifeCircle()
			return v16
		end

		if v17 == "Weapon" then
			object2:ShowWeaponCircle()
			object2:FlashRadarBorder()
		end

		return v16
	end

	object2.Janitor:Add(function()
		Router.broadcastRouter = broadcastRouter
	end)
	local v16 = 0
	object2.Janitor:Add(RunServiceController.BindToRenderStep("UI.Radar.Update", function(p: number)
		Profiler.mark("UI.Radar.RenderStepped")
		v16 += p

		if v16 >= 1 / 60 then
			object2:Render(p)
			v16 = math.min(v16 - 1 / 60, 1 / 120)
		end
	end))
	object2.Janitor:Add(LocalPlayer:GetAttributeChangedSignal("Team"):Connect(function()
		object2:RefreshIconsOnTeamChange()
	end))

	local function setupPlayerListeners(object3)
		if object3 == object2.LocalPlayer then
			return
		end

		object2.Janitor:Add(object3:GetAttributeChangedSignal("Team"):Connect(function()
			object2:RefreshPlayerIcon(object3)
		end))
		object2.Janitor:Add(CharacterResolver.observeCharacter(object3, function(p, p2)
			if p ~= p2 then
				object2:RefreshPlayerIcon(object3)
			end

			return nil
		end))
	end

	for _, v17 in ipairs(Players:GetPlayers()) do
		setupPlayerListeners(v17)
	end

	object2.Janitor:Add(Players.PlayerAdded:Connect(setupPlayerListeners))
	object2.Janitor:Add(Players.PlayerRemoving:Connect(function(player)
		for k, icon in pairs(object2.Icons) do
			if icon.Player == player then
				object2:RemoveIcon(k)
			end
		end

		object2.DeadPlayerPositions[player.UserId] = nil
		object2.FadedDeadIcons[player.UserId .. "_Dead"] = nil
		object2.EnemyVisibilityCache[player.UserId .. "_Player"] = nil
	end))
	local v17 = {}
	object2.Janitor:Add(Participants.Observe(function(player)
		if player:IsA("Player") or v17[player] then
			return
		end

		local function refresh()
			object2:RefreshPlayerIcon(player)
		end

		v17[player] = {
			player:GetAttributeChangedSignal("Team"):Connect(refresh),
			player:GetAttributeChangedSignal("Generation"):Connect(refresh)
		}
	end, function(player)
		if player:IsA("Player") then
			return
		end

		local v18 = v17[player]

		if v18 then
			for _, connection in v18 do
				connection:Disconnect()
			end

			v17[player] = nil
		end

		for k, icon in pairs(object2.Icons) do
			if icon.Player == player then
				object2:RemoveIcon(k)
			end
		end

		object2:RefreshPlayerIcon(player)
	end))
	object2.Janitor:Add(function()
		for _, v18 in v17 do
			for _, connection in v18 do
				connection:Disconnect()
			end
		end

		table.clear(v17)
	end)
	object2.Janitor:Add(Remotes.UI.UIPlayerKilled.Listen(function(p)
		local v18 = Participants.FromKey(p.Victim)

		if not v18 or v18 == LocalPlayer then
			return
		end

		local deathPosition = p.DeathPosition

		if not deathPosition then
			return
		end

		object2.DeadPlayerPositions[Participants.Key(v18)] = deathPosition
		object2:CreateDeadIconForPlayer(v18, deathPosition)
	end))
	object2.Janitor:Add(workspace:GetAttributeChangedSignal("Map"):Connect(function()
		object2.MinimapReference = GetMinimapReference()
		object2.SiteParts = GetSiteParts()
		DestroyUpperMapImages(object2)
		object2.MapImage.Image = ""
		object2.MapImage.ImageTransparency = 0
		object2.MapImage.ImageRectOffset = Vector2.new(0, 0)
		object2.MapImage.ImageRectSize = Vector2.new(1024, 1024)
		object2.MapImage.Rotation = 0
		object2.MapImage.Visible = true
		object2.MapImage.Size = UDim2.fromScale(1, 1)
		object2.UpperMapImage = CreateUpperMapImage(object2)
		object2:UpdateMinimapTexture()

		for k in pairs(object2.Icons) do
			object2:RemoveIcon(k)
		end

		table.clear(object2.EnemyVisibilityState)
		table.clear(object2.EnemyLastSeenPositions)
		table.clear(object2.EnemyVisibilityCache)
		table.clear(object2.HostageVisibilityCache)
		object2.BombVisibilityCache = nil
		table.clear(object2.DeadPlayerPositions)
		table.clear(object2.FadedDeadIcons)
	end))
	object2.Janitor:Add(function()
		for _, icon in pairs(object2.Icons) do
			if icon.Instance and icon.Instance.Parent then
				icon.Instance:Destroy()
			end
		end

		table.clear(object2.Icons)
		table.clear(object2.EnemyVisibilityState)
		table.clear(object2.EnemyLastSeenPositions)
		DestroyUpperMapImages(object2)
		CancelRunningCircleDelay(object2) -- inferred equivalent call

		if object2.RunningCircle then
			object2.RunningCircle:Destroy()
			object2.RunningCircle = nil
		end

		if object2.KnifeCircle then
			object2.KnifeCircle:Destroy()
			object2.KnifeCircle = nil
		end

		if object2.WeaponCircleHideTask then
			task.cancel(object2.WeaponCircleHideTask)
			object2.WeaponCircleHideTask = nil
		end

		if object2.WeaponCircle then
			object2.WeaponCircle:Destroy()
			object2.WeaponCircle = nil
		end

		local v18 = object2

		if v18.BorderRestoreTask then
			task.cancel(v18.BorderRestoreTask)
			v18.BorderRestoreTask = nil
		end
	end)
	return object2
end

function Radar:Destroy()
	self.Janitor:Destroy()
end

function Radar.Initialize(_, p)
	Profiler.mark("UI.Radar.Initialize")
	v10 = p

	local function syncTutorialVisibility() -- 1 equivalent call inferred from this helper
		if IsTutorialMode() then
			v10.Visible = false
		end
	end

	syncTutorialVisibility() -- inferred equivalent call
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(syncTutorialVisibility)
	workspace:GetAttributeChangedSignal("ServerGamemode"):Connect(syncTutorialVisibility)

	for _, v16 in v11 do
		local v17 = v16
		DataController.CreateListener(LocalPlayer, "Settings.Game.Radar/Tablet." .. v16[1], function(p2)
			settings2[v17[2]] = p2

			if v12 then
				v12:ApplySettings()
			end
		end)
	end

	v10.Radar.UIStroke.Color = GetPreferenceColor()
	CharacterResolver.observeCharacter(LocalPlayer, function()
		v10.Radar.UIStroke.Color = GetPreferenceColor()
		return nil
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", function()
		if v10 and v10.Radar and v10.Radar.UIStroke then
			local uiStroke = v10.Radar.UIStroke
			local v16

			if v12 == nil then
				v16 = false
			else
				v16 = v12.BorderRestoreTask ~= nil
			end

			if not v16 or uiStroke.Color ~= color4 then
				uiStroke.Color = GetPreferenceColor()
			end
		end
	end)
end

local function observeBotCharacter(player, onCharacter)
	local radarCharacter = getRadarCharacter(player)
	onCharacter(radarCharacter)

	local function refresh()
		local radarCharacter2 = getRadarCharacter(player)

		if radarCharacter2 ~= radarCharacter then
			radarCharacter = radarCharacter2
			onCharacter(radarCharacter2)
		end
	end

	local connections = { player:GetAttributeChangedSignal("Generation"):Connect(refresh) }
	local characters = workspace:FindFirstChild("Characters")

	if characters then
		table.insert(connections, characters.ChildAdded:Connect(refresh))
		table.insert(connections, characters.ChildRemoved:Connect(refresh))
	end

	return function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end
end

local function observeRadarTarget(player, flag: boolean)
	if v13 then
		v13()
		v13 = nil
	end

	local function onCharacter(instance)
		if instance and instance:IsDescendantOf(workspace) then
			createRadarInstance(instance, player, flag)
		elseif SpectateController.IsFreecamActive() then
			local localPlayer = LocalPlayer
			Profiler.mark("UI.Radar.CreateRadarForCharacter")

			if v12 then
				v12:Destroy()
				v12 = nil
			end

			local v16 = Radar.new(v10, nil)
			v12 = v16
			v16.LocalPlayer = localPlayer
			v16.Team = localPlayer:GetAttribute("Team")
			v16.IsSpectating = true
			v16.MapImage.Rotation = 90

			if v16.UpperMapImage then
				v16.UpperMapImage.Rotation = 90
			end
		elseif v12 and v12.LocalPlayer == player then
			v12:Destroy()
			v12 = nil
		end
	end

	if player:IsA("Player") then
		v13 = CharacterResolver.observeCharacter(player, function(instance)
			onCharacter(instance)

			if not instance then
				return nil
			end

			local isDescendant = instance:IsDescendantOf(workspace)
			local ancestryChangedConnection = instance.AncestryChanged:Connect(function()
				local isDescendant2 = instance:IsDescendantOf(workspace)

				if isDescendant2 ~= isDescendant then
					isDescendant = isDescendant2
					onCharacter(instance)
				end
			end)
			return function()
				ancestryChangedConnection:Disconnect()
			end
		end)
	else
		v13 = observeBotCharacter(player, onCharacter)
	end
end

function Radar.Start()
	observeRadarTarget(LocalPlayer, false)
	SpectateController.ListenToSpectate:Connect(function(localPlayer)
		if localPlayer then
			observeRadarTarget(localPlayer, true)
		else
			observeRadarTarget(LocalPlayer, false)
		end
	end)
	SpectateController.ListenToFreecam:Connect(function()
		if not v12 then
			local localPlayer = LocalPlayer
			Profiler.mark("UI.Radar.CreateRadarForCharacter")

			if v12 then
				v12:Destroy()
				v12 = nil
			end

			local v16 = Radar.new(v10, nil)
			v12 = v16
			v16.LocalPlayer = localPlayer
			v16.Team = localPlayer:GetAttribute("Team")
			v16.IsSpectating = true
			v16.MapImage.Rotation = 90

			if v16.UpperMapImage then
				v16.UpperMapImage.Rotation = 90
			end
		end
	end)
end

return Radar