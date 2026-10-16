local Team = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local color = Color3.fromRGB(36, 41, 47)
local color2 = Color3.fromRGB(89, 79, 50)
local color3 = Color3.fromRGB(135, 155, 177)
local v = nil
local v2 = nil

local function getPlateColor() -- 2 equivalent calls inferred from this helper
	if LocalPlayer:GetAttribute("Team") == "Terrorists" then
		return color2
	end

	return color
end

local function applyPreferenceColorToFrame(imageColor: Color3) -- 1 equivalent call inferred from this helper
	v.Team.Outline.ImageColor3 = imageColor
	v.Line1.ImageColor3 = imageColor
	v.Line2.ImageColor3 = imageColor
end

local function applyTeamPresentation() -- 2 equivalent calls inferred from this helper
	applyPreferenceColorToFrame(GetPreferenceColor()) -- inferred equivalent call
	local team = LocalPlayer:GetAttribute("Team")
	v.Team.Team.CT.Visible = team == "Counter-Terrorists"
	v.Team.Team.T.Visible = team == "Terrorists"
	local team2 = v.Team.Team
	team2.ImageColor3 = getPlateColor() -- inferred equivalent call
end

local function applyPreferenceColorToCard(object, color4: Color3)
	object.Amount.TextColor3 = color4
	object.ImageColor3 = color4

	for _, uiStroke in object:QueryDescendants("UIStroke, ImageLabel") do
		if uiStroke:IsA("UIStroke") then
			uiStroke.Color = color4
		else
			uiStroke.ImageColor3 = color4
		end
	end
end

local function tweenKillHighlight(clone, imageTransparency: number, color4: Color3)
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(clone.Animation, tweenInfo, { ImageTransparency = imageTransparency }):Play()
	TweenService:Create(v.Team.Team, tweenInfo, { ImageColor3 = color4 }):Play()
end

function Team.createAnimationFrame(_)
	local team = LocalPlayer:GetAttribute("Team")

	if not team or team == "Spectators" then
		return
	end

	local v3 = #v.Cards:GetChildren() + 1

	if v3 > 5 then
		return
	end

	local ctCard = team == "Counter-Terrorists" and ReplicatedStorage.Assets.UI.Team.CTCard

	if not ctCard then
		if team == "Terrorists" then
			ctCard = ReplicatedStorage.Assets.UI.Team.TCard
		else
			ctCard = false
		end
	end

	local clone = ctCard:Clone()
	clone.Amount.Text = tostring(v3)
	clone.Position = UDim2.fromScale(0.5, 1)
	clone.Name = tostring(v3)
	clone.Animation.ImageTransparency = 1
	clone.Animation.Visible = false
	clone.Parent = v.Cards
	clone.Rotation = -10
	clone.Visible = true
	applyPreferenceColorToCard(clone, GetPreferenceColor())

	for _, child in v.Cards:GetChildren() do
		local v4 = tonumber(child.Name) - math.floor((v3 + 1) / 2)
		local v5 = v3 == 1 and 0 or v4 * 0.2617993877991494 or 0
		local v6

		if not (v3 >= 3) then
			v6 = 0.85
		elseif child.Name == "1" then
			v6 = 0.75
		elseif child.Name == "2" then
			v6 = 0.75
		else
			v6 = 0.85
		end

		local v7

		if not (v3 >= 3) then
			v7 = 0.05
		elseif child.Name == "1" then
			v7 = 0.25
		elseif child.Name == "2" then
			v7 = 0.125
		else
			v7 = 0.05
		end

		TweenService:Create(child, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.fromScale(math.sin(v5) * v6 + 0.5, math.cos(v5) * v7 + 0.45),
			Rotation = math.deg(v5)
		}):Play()
	end

	tweenKillHighlight(clone, 0.2, color3)
	task.delay(0.5, function()
		if not (clone and clone:FindFirstChild("Animation")) then
			return
		end

		tweenKillHighlight(clone, 1, getPlateColor()) -- inferred equivalent call
	end)
end

function Team.OpenFrame()
	v2.Gameplay.Bottom.Middle.Spectate.Visible = false
	v.Cards.Visible = true
	v.Visible = true
	applyTeamPresentation() -- inferred equivalent call
end

function Team.CloseFrame()
	v.Cards:ClearAllChildren()
	v.Cards.Visible = false
	v.Visible = false
end

function Team.Initialize(p, p2)
	v2 = p
	v = p2

	local function refreshTeamColors()
		applyTeamPresentation() -- inferred equivalent call
		local v3 = GetPreferenceColor()

		for _, image in v.Cards:GetChildren() do
			if not (image:IsA("ImageLabel") and image:FindFirstChild("Amount") and image:FindFirstChild("Skull1") and image:FindFirstChild("Skull2")) then
				continue
			end

			if not image:FindFirstChild("Animation") then
				continue
			end

			applyPreferenceColorToCard(image, v3)
		end
	end

	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", refreshTeamColors)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(refreshTeamColors)
end

function Team.Start()
	LocalPlayer.CharacterAdded:Connect(Team.OpenFrame)
	LocalPlayer.CharacterRemoving:Connect(Team.CloseFrame)

	if LocalPlayer.Character and not LocalPlayer:GetAttribute("IsSpectating") then
		Team.OpenFrame()
	else
		Team.CloseFrame()
	end

	Remotes.UI.UIPlayerKilled.Listen(function(p)
		if v.Visible and LocalPlayer.UserId == tonumber(p.Killer) then
			Team.createAnimationFrame(p)
		end
	end)
end

return Team