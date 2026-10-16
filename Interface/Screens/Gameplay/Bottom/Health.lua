local Health = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer
local HudTarget = require(ReplicatedStorage.Interface.Screens.Gameplay.Bottom.Ammo.HudTarget)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local maid = Janitor.new()
local v = 0
local v2 = nil
local parent = nil

function Health.animateFrame()
	local clone = parent.Amount:Clone()
	clone.TextColor3 = Color3.fromRGB(255, 0, 4)
	clone.ZIndex = parent.ZIndex - 1
	clone.Parent = parent
	TweenService:Create(parent.Amount.UIScale, TweenInfo.new(0.07), { Scale = 1.1 }):Play()
	task.wait(0.07)
	TweenService:Create(parent.Amount.UIScale, TweenInfo.new(0.07, Enum.EasingStyle.Elastic), {
		Scale = 1
	}):Play()
	TweenService:Create(clone, TweenInfo.new(0.5), {
		Position = clone.Position + UDim2.fromScale(0, 0.25)
	}):Play()
	TweenService:Create(clone, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
	Debris:AddItem(clone, 0.5)
end

function Health.updateFrame(p: number, p2: number)
	if p2 <= 0 then
		return
	end

	local v3 = p / p2
	parent.Amount.Text = tostring((math.ceil(p)))
	parent.Frame.Bar.BackgroundColor3 = GetPreferenceColor()
	parent.Amount.TextColor3 = GetPreferenceColor()
	parent.Glow.ImageTransparency = 1
	TweenService:Create(parent.Frame.Bar, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(v3, 1)
	}):Play()

	if v3 <= 0.5 then
		parent.Glow.ImageTransparency = math.max((0.5 - v3) * 2, 0.3)
	end

	if p < v then
		task.spawn(Health.animateFrame)
	end

	v = p
end

local function updateFromAttributes(instance) -- 2 equivalent calls inferred from this helper
	local health = instance:GetAttribute("Health")
	local maxHealth = instance:GetAttribute("MaxHealth")

	if typeof(health) == "number" and typeof(maxHealth) == "number" and maxHealth > 0 then
		Health.updateFrame(math.max(health, 0), maxHealth)
	end
end

local function trackPlayer(instance)
	maid:Cleanup()
	v2 = instance

	local function update() -- 1 equivalent call inferred from this helper
		updateFromAttributes(instance) -- inferred equivalent call
	end

	local health = instance:GetAttribute("Health")
	v = typeof(health) ~= "number" and 0 or health
	maid:Add(instance:GetAttributeChangedSignal("Health"):Connect(update))
	maid:Add(instance:GetAttributeChangedSignal("MaxHealth"):Connect(update))
	update() -- inferred equivalent call
end

function Health.Initialize(_, p)
	parent = p
	HudTarget.DisableInput(parent)

	local function refreshPreferenceColor()
		if v2 then
			updateFromAttributes(v2) -- inferred equivalent call
		end
	end

	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", refreshPreferenceColor)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(refreshPreferenceColor)
end

function Health.Start()
	HudTarget.Follow(trackPlayer)
end

return Health