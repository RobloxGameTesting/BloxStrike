local DeathCard = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local GetBadgeIcon = require(ReplicatedStorage.Components.Common.GetBadgeIcon)
local GetBadgeName = require(ReplicatedStorage.Components.Common.GetBadgeName)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local CurrentCamera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local bloodScreen = nil
local transition = nil
local v = nil
local v2 = nil
local count = 0

local function GetWeaponIcon(p, p2: number)
	return Skins.GetWearImageForFloat(p, p2) or p.imageAssetId or ""
end

local function CancelTransitionTween() -- 2 equivalent calls inferred from this helper
	local v3 = v2
	v2 = nil

	if v3 then
		v3:Cancel()
	end
end

local function PlayTransitionTween(duration: number, backgroundTransparency: number)
	CancelTransitionTween() -- inferred equivalent call
	local tween = TweenService:Create(
		transition,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = backgroundTransparency }
	)
	v2 = tween
	tween:Play()
	return tween
end

local function TweenBloodScreen(duration: number, backgroundTransparency: number, imageTransparency: number)
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(bloodScreen, tweenInfo, { BackgroundTransparency = backgroundTransparency }):Play()
	TweenService:Create(bloodScreen.ImageLabel, tweenInfo, { ImageTransparency = imageTransparency }):Play()
end

local function GetCharacterCameraSubject()
	local v3 = -1e999
	local v4 = nil

	for _, model in CollectionService:GetTagged("Ragdoll") do
		if not (model:IsA("Model") and model.Name == LocalPlayer.Name and model:IsDescendantOf(workspace)) then
			continue
		end

		local ragdollCreatedAt = model:GetAttribute("RagdollCreatedAt")
		local v5 = typeof(ragdollCreatedAt) ~= "number" and 0 or ragdollCreatedAt

		if not (v3 < v5) then
			continue
		end

		v4 = model
		v3 = v5
	end

	if v4 then
		return CharacterResolver.getCameraPart(v4)
			or CharacterResolver.getRootPart(v4)
			or v4:FindFirstChildOfClass("Humanoid")
	end

	return nil
end

function DeathCard.updateFrame(data)
	local v3 = Participants.FromKey(data.Killer)

	if v3 and v3.Parent then
		local skinInformation = Skins.GetSkinInformation(data.Weapon, data.Skin)
		local skinDisplayName = GetSkinDisplayName(data.Skin)
		v.Killed.Text = `<font color="rgb(255,34,16)">Killed you with their</font> <b>{data.Weapon} | {skinDisplayName}</b>`
		v.BadgeFrame.TextLabel.Text = GetBadgeName(v3, (v3:GetAttribute("Team")))
		v.BadgeIcon.Image = GetBadgeIcon(v3, (v3:GetAttribute("Team")))
		v.Profile.Avatar.Image = Participants.HeadshotImage(v3)
		v.Username.Text = Participants.DisplayName(v3)
		local icon = v.ViewportFrame.Icon
		local image

		if skinInformation then
			local float = data.Float or 0.9999
			image = Skins.GetWearImageForFloat(skinInformation, float) or skinInformation.imageAssetId or ""
		else
			image = ""
		end

		icon.Image = image
		return true
	else
		v.Killed.Text = ""
		v.BadgeFrame.TextLabel.Text = ""
		v.BadgeIcon.Image = ""
		v.Profile.Avatar.Image = ""
		v.Username.Text = ""
		v.ViewportFrame.Icon.Image = ""
		return false
	end
end

function DeathCard.openFrame(flag: boolean?)
	count += 1
	local v3 = count

	local function isSequenceStale() -- 4 equivalent calls inferred from this helper
		return count ~= v3
	end

	local cameraSubject = GetCharacterCameraSubject()

	if cameraSubject then
		CurrentCamera.CameraSubject = cameraSubject
	end

	CurrentCamera.CameraType = Enum.CameraType.Follow
	CameraController.setPerspective(false, false)
	task.wait(0.15)

	if isSequenceStale() then -- inferred equivalent call
		return
	end

	bloodScreen.ImageLabel.ImageTransparency = 1
	bloodScreen.BackgroundTransparency = 1
	bloodScreen.Visible = true
	v.Position = UDim2.fromScale(0.5, -v.Size.Y.Scale)
	v.Visible = flag ~= false
	CancelTransitionTween() -- inferred equivalent call
	transition.BackgroundTransparency = 1
	transition.Visible = true
	TweenBloodScreen(0.75, 0.75, 0)
	task.wait(0.25)

	if isSequenceStale() then -- inferred equivalent call
		return
	end

	if v.Visible then
		TweenService:Create(v, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(0.5, 0.7)
		}):Play()
	end

	task.wait(0.35)

	if isSequenceStale() then -- inferred equivalent call
		return
	end

	PlayTransitionTween(0.25, 0)
	TweenBloodScreen(0.25, 1, 1)
	local v4 = workspace:GetAttribute("Gamemode") == "Deathmatch" and 8 or 2
	task.delay(v4, function()
		if isSequenceStale() then -- inferred equivalent call
			return
		end

		DeathCard.closeFrame()
	end)
end

function DeathCard.closeFrame()
	count += 1
	bloodScreen.ImageLabel.ImageTransparency = 1
	bloodScreen.BackgroundTransparency = 1
	bloodScreen.Visible = false
	v.Position = UDim2.fromScale(0.5, -v.Size.Y.Scale)
	v.Visible = false
	local playTransitionTween = PlayTransitionTween(1, 1)
	playTransitionTween.Completed:Connect(function()
		if v2 ~= playTransitionTween then
			return
		end

		v2 = nil
		transition.BackgroundTransparency = 1
		transition.Visible = false
	end)
end

function DeathCard.Initialize(p, p2)
	bloodScreen = p.Gameplay.Middle.BloodScreen
	transition = p.Gameplay.Middle.Transition
	v = p2
	LocalPlayer.CharacterAdded:Connect(function()
		DeathCard.closeFrame()
	end)
end

function DeathCard.Start()
	Remotes.UI.UIPlayerKilled.Listen(function(p)
		if LocalPlayer.UserId == tonumber(p.Victim) then
			DeathCard.openFrame(DeathCard.updateFrame(p))
		end
	end)
	Remotes.UI.ShowDeathCard.Listen(function(p)
		if LocalPlayer.UserId == tonumber(p.Victim) then
			DeathCard.updateFrame(p)
		end
	end)
end

return DeathCard