local DamageIndicator = {}
DamageIndicator.__index = DamageIndicator
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local v = { Top = 90, Bottom = 270, Left = 0, Right = 180 }
local parent = nil
local v2 = {}

local function GetRelativeRotation(vector: Vector3, vector2: Vector3, vector3: Vector3) -- 1 equivalent call inferred from this helper
	return math.atan2(vector3.Z - vector.Z, vector3.X - vector.X) - math.atan2(vector2.Z - vector.Z, vector2.X - vector.X)
end

local function GetQuadrantPosition(p: string, screenSize: number)
	local v3 = screenSize / 3
	return ({
		Top = UDim2.new(0.5, 0, 0, v3),
		Bottom = UDim2.new(0.5, 0, 1, -v3),
		Left = UDim2.new(0, v3, 0.5, 0),
		Right = UDim2.new(1, -v3, 0.5, 0)
	})[p]
end

local function NormalizeAngle(p: number) -- 1 equivalent call inferred from this helper
	local v3 = math.deg(p) % 360

	if v3 > 180 then
		return v3 - 360
	end

	if v3 < -180 then
		return v3 + 360
	end

	return v3
end

local function GetQuadrant(vector: Vector3, vector2: Vector3, vector3: Vector3) -- 2 equivalent calls inferred from this helper
	local angle = NormalizeAngle(GetRelativeRotation(vector, vector + vector2, vector3)) -- inferred equivalent call

	if angle >= -45 and angle < 45 then
		return "Top"
	end

	if angle >= 45 and angle < 135 then
		return "Right"
	end

	if angle >= 135 or angle < -135 then
		return "Bottom"
	end

	return "Left"
end

local function scheduleCleanup(object)
	local thread = task.delay(2, function()
		object:cleanup()
	end)
	object.Janitor:Add(function()
		if thread then
			pcall(task.cancel, thread)
		end
	end)
	object.CleanupThread = thread
end

function DamageIndicator:construct()
	local quadrant = GetQuadrant(self.CameraPosition, self.CameraLookVector, self.Position) -- inferred equivalent call
	self.Template.Position = GetQuadrantPosition(quadrant, self.ScreenSize)
	self.Template.Rotation = v[quadrant]
	self.Quadrant = quadrant
	scheduleCleanup(self)
end

function DamageIndicator:cleanup()
	if self.Template and self.Template:IsDescendantOf(LocalPlayer.PlayerGui) then
		self.Janitor:Add(TweenService:Create(
			self.Template,
			TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			{ ImageTransparency = 1 }
		)):Play()
		task.wait(0.5)
		self:destroy()
	end
end

function DamageIndicator:refresh()
	if self.CleanupThread then
		pcall(task.cancel, self.CleanupThread)
		self.CleanupThread = nil
	end

	if self.FadeTween then
		self.FadeTween:Cancel()
		self.FadeTween = nil
	end

	if self.SizeTween then
		self.SizeTween:Cancel()
		self.SizeTween = nil
	end

	local imageTransparency = math.max(0, self.Template.ImageTransparency - 0.1)
	self.Template.ImageTransparency = imageTransparency
	scheduleCleanup(self)
	local sizeTween = self.Janitor:Add(TweenService:Create(
		self.Template,
		TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromOffset(self.ScreenSize / 3, self.ScreenSize / 3),
			ImageTransparency = imageTransparency
		}
	))
	sizeTween:Play()
	self.SizeTween = sizeTween
end

function DamageIndicator.new(character, position: Vector3, cameraLookVector: Vector3, cameraPosition: Vector3, p: string)
	local object = setmetatable({}, DamageIndicator)
	object.Janitor = Janitor.new()
	object.Template = object.Janitor:Add(ReplicatedStorage.Assets.UI.DamageIndicator.Template:Clone())
	object.Template.Parent = parent
	object.Template.ImageTransparency = 1
	object.Template.Name = "Indicator"
	object.Character = character
	object.ScreenSize = parent.AbsoluteSize.X
	object.Position = position
	object.CameraLookVector = cameraLookVector
	object.CameraPosition = cameraPosition
	object.Janitor:Add(Remotes.Character.CharacterDied.Listen(function()
		object:destroy()
	end))
	parent.Visible = true
	object:construct()
	object.SizeTween = object.Janitor:Add(TweenService:Create(
		object.Template,
		TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromOffset(object.ScreenSize / 3, object.ScreenSize / 3),
			ImageTransparency = 0.2
		}
	))
	object.SizeTween:Play()
	v2[p] = object
	return object
end

function DamageIndicator:destroy()
	local quadrant = self.Quadrant
	self.Janitor:Destroy()

	if quadrant then
		v2[quadrant] = nil
	end
end

function DamageIndicator.Initialize(_, p)
	parent = p
	Remotes.UI.CreateDamageIndicator.Listen(function(vector: Vector3)
		if LocalPlayer.Character then
			local position = CurrentCamera.CFrame.Position
			local lookVector = CurrentCamera.CFrame.LookVector
			local quadrant = GetQuadrant(position, lookVector, vector) -- inferred equivalent call
			local v3 = v2[quadrant]

			if v3 then
				v3:refresh()
			else
				DamageIndicator.new(LocalPlayer.Character, vector, lookVector, position, quadrant)
			end
		end
	end)
end

return DamageIndicator