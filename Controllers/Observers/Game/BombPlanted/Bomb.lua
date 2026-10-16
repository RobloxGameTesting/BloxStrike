local Bomb = {}
Bomb.__index = Bomb
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HapticsController = require(ReplicatedStorage.Controllers.HapticsController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Sound = require(ReplicatedStorage.Classes.Sound)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local CurrentCamera = workspace.CurrentCamera
local v = { KillTs = true, DefuseB = true }

local function computeInterval(p: number, timeUntilExplode: number) -- 1 equivalent call inferred from this helper
	local v2 = p / timeUntilExplode * 0.9 + 0.1
	return v2 <= 0.15 and 0.15 or v2
end

local function toggleFlashingLight(flashingLight) -- 2 equivalent calls inferred from this helper
	if
		flashingLight
		and flashingLight:FindFirstChild("Attachment")
		and flashingLight.Attachment:FindFirstChild("PointLight")
	then
		local pointLight = flashingLight.Attachment.PointLight
		pointLight.Enabled = not pointLight.Enabled
	end
end

local function syncTutorialMarkers(object)
	local tutorialStep = LocalPlayer:GetAttribute("TutorialStep")
	local defused = object.Model:GetAttribute("Defused")
	local isDefused = object.IsDefused
		or defused ~= nil and defused ~= false
		or object.Model:GetAttribute("Exploding") == true
	local v2 = IsTutorialMode() and not isDefused and v[tutorialStep] == true
	local tutorialBombOutline = object.Model:FindFirstChild("TutorialBombOutline")

	if v2 and not tutorialBombOutline then
		local highlight = Instance.new("Highlight")
		highlight.Name = "TutorialBombOutline"
		highlight.FillTransparency = 1
		highlight.OutlineColor = Color3.fromRGB(235, 40, 40)
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Adornee = object.Model
		highlight.Parent = object.Model
	elseif not v2 and tutorialBombOutline then
		tutorialBombOutline:Destroy()
	end
end

function Bomb:updateHeartbeat(instance)
	if self.Model:GetAttribute("IsGettingDefused") then
		self.Model:SetAttribute("CanDefuse", false)
		return
	end

	if not (instance.PrimaryPart and self.Model.PrimaryPart) then
		return
	end

	if (instance.PrimaryPart.Position - self.Model.PrimaryPart.Position).Magnitude > 5 then
		self.Model:SetAttribute("CanDefuse", false)
		return
	end

	local position = CurrentCamera.CFrame.Position
	local v2 = self.Model.PrimaryPart.Position - position
	local magnitude = v2.Magnitude

	if not (magnitude > 0) then
		self.Model:SetAttribute("CanDefuse", false)
		return
	end

	local v3 = v2 / magnitude
	local dot = CurrentCamera.CFrame.LookVector:Dot(v3)
	self.Model:SetAttribute("CanDefuse", dot >= 0.966)
end

function Bomb.new(model)
	local object = setmetatable({}, Bomb)
	object.Janitor = Janitor.new()
	object.Sound = Sound.new("C4")
	object.Janitor:Add(function()
		object.Sound:destroy()
	end)
	object.Model = model
	object.Data = HttpService:JSONDecode(model:GetAttribute("BombPlanted"))
	local time = typeof(object.Data.Time) == "number" and object.Data.Time or workspace:GetServerTimeNow()
	object.TimeUntilExplode = math.max(
		typeof(object.Data.TimeUntilExplode) ~= "number" and 40 or object.Data.TimeUntilExplode or 40,
		0.1
	)
	object.ExplodeAt = time + object.TimeUntilExplode
	object.NextBeepAt = workspace:GetServerTimeNow()
	object.IsDefused = false
	local bindingName = RunServiceController.CreateBindingName("Observers.Game.BombPlanted")
	Router.broadcastRouter("CreateNotification", "Bomb", "The bomb has been planted.", 2.5)

	for _, part in ipairs(object.Model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanQuery = true
		end
	end

	object.Janitor:Add(object.Model:GetAttributeChangedSignal("Defused"):Connect(function()
		Router.broadcastRouter("Cancel Defuse Bomb")
		Router.broadcastRouter("CreateNotification", "Bomb", "The bomb has been defused.", 2.5)
		object.IsDefused = true
	end))
	object.Janitor:Add(object.Model:GetAttributeChangedSignal("Exploding"):Connect(function()
		Router.broadcastRouter("Cancel Defuse Bomb")
		local DefuseBomb = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.DefuseBomb)

		if DefuseBomb.SetDefuseBlockedUntil then
			DefuseBomb.SetDefuseBlockedUntil(workspace:GetServerTimeNow() + 5)
		end
	end))
	object.Janitor:Add(object.Model:GetAttributeChangedSignal("Exploded"):Connect(function()
		local localCharacter = CharacterResolver.getLocalCharacter()

		if localCharacter and CharacterResolver.isAliveCharacter(localCharacter) then
			CameraController.BombExploded((object.Model:GetPivot().Position - localCharacter:GetPivot().Position).Magnitude)
			HapticsController.vibrate(Enum.VibrationMotor.Large, 1.5, 0.25)
		end
	end))
	object.Janitor:Add(RunServiceController.BindToHeartbeat(`{bindingName}.DefuseCheck`, function(_: number)
		local localCharacter = CharacterResolver.getLocalCharacter()

		if
			CharacterResolver.isAliveCharacter(localCharacter)
			and LocalPlayer:GetAttribute("Team") == "Counter-Terrorists"
		then
			object:updateHeartbeat(localCharacter)
		end
	end))
	object.Janitor:Add(RunServiceController.BindToHeartbeat(`{bindingName}.Beep`, function(_: number)
		local serverTimeNow = workspace:GetServerTimeNow()
		local v2 = math.max(object.ExplodeAt - serverTimeNow, 0)
		local flashingLight = object.Model:FindFirstChild("Weapon")
			and object.Model.Weapon:FindFirstChild("FlashingLight")

		if object.IsDefused or v2 <= 0 then
			toggleFlashingLight(flashingLight) -- inferred equivalent call
		elseif object.NextBeepAt <= serverTimeNow then
			object.NextBeepAt = serverTimeNow + computeInterval(v2, object.TimeUntilExplode) -- inferred equivalent call
			toggleFlashingLight(flashingLight) -- inferred equivalent call
			local primaryPart = object.Model.PrimaryPart

			if primaryPart then
				object.Sound:play({ Parent = primaryPart, Name = "Beep" })
			end
		end
	end))

	if not IsTutorialMode() then
		return object
	end

	local function sync() -- 1 equivalent call inferred from this helper
		syncTutorialMarkers(object)
	end

	object.Janitor:Add(LocalPlayer:GetAttributeChangedSignal("TutorialStep"):Connect(sync))
	object.Janitor:Add(object.Model:GetAttributeChangedSignal("Defused"):Connect(sync))
	object.Janitor:Add(object.Model:GetAttributeChangedSignal("Exploding"):Connect(sync))
	object.Janitor:Add(function()
		local tutorialBombOutline = object.Model:FindFirstChild("TutorialBombOutline")

		if tutorialBombOutline then
			tutorialBombOutline:Destroy()
		end
	end)
	sync() -- inferred equivalent call
	return object
end

function Bomb:destroy()
	self.Janitor:Destroy()
end

return Bomb