local Ammo = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local HudTarget = require(script:WaitForChild("HudTarget"))
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local identifier = nil
local v = nil
local v2 = nil
local folder = nil
local v3 = nil
local maid = Janitor.new()

local function shouldShowAmmoFrame(properties) -- 2 equivalent calls inferred from this helper
	return properties ~= nil and properties.Class == "Weapon" and properties.MuzzleType ~= "Zeus x27"
end

function Ammo.tweenAnimation(p)
	if identifier == p.Identifier then
		return
	end

	identifier = p.Identifier
	folder.Size = UDim2.new(folder.Size.X.Scale, -25, folder.Size.Y.Scale, -25)

	if v then
		v:Play()
	end
end

function Ammo.updateFrame(data)
	local properties = data.Properties
	folder.Visible = shouldShowAmmoFrame(properties) -- inferred equivalent call

	if folder.Visible then
		Ammo.tweenAnimation(data)
		local rounds = data.Rounds
		local capacity = data.Capacity
		folder.Capacity.Amount.Text = tostring(capacity)
		folder.Rounds.Amount.Text = tostring(rounds)
		local v4 = GetPreferenceColor()
		folder.Capacity.Amount.TextColor3 = v4
		folder.Rounds.Amount.TextColor3 = v4
		folder.Divider.BackgroundColor3 = v4
		folder.SemiAuto.ImageColor3 = v4
		folder.Auto.ImageColor3 = v4
		local v5 = rounds / properties.Rounds
		folder.Rounds.Glow.ImageTransparency = 1

		if v5 <= 0.2 then
			folder.Rounds.Glow.ImageTransparency = math.max(v5, 0.3)
		end

		if properties.ShootingOptions == "Default" then
			folder.SemiAuto.Visible = not properties.Automatic
			folder.Auto.Visible = properties.Automatic
		elseif properties.ShootingOptions == "Burst" then
			folder.SemiAuto.Visible = data.AlternativeShootingOption == "Default"
			folder.Auto.Visible = data.AlternativeShootingOption == "Burst"
		elseif properties.ShootingOptions == "Revolver" then
			folder.SemiAuto.Visible = false
			folder.Auto.Visible = false
		end
	elseif v then
		v:Cancel()
	end

	folder.Visible = folder.Visible and not v3.Gameplay.Middle.BuyMenu.Visible
end

local function showSpectatedEquipped(currentEquipped)
	local v4

	if currentEquipped then
		v4 = HttpService:JSONDecode(currentEquipped)
	end

	if not (v4 and v4.Name) then
		folder.Visible = false
		return
	end

	local v5 = {
		Properties = GetWeaponProperties(v4.Name),
		Identifier = v4.Identifier or "",
		Rounds = v4.Rounds or 0,
		Capacity = v4.Capacity or 0,
		AlternativeShootingOption = "Default"
	}

	if shouldShowAmmoFrame(v5.Properties) then -- inferred equivalent call
		Ammo.updateFrame(v5)
	else
		folder.Visible = false
	end
end

local function trackPlayerState(instance)
	maid:Cleanup()
	v2 = instance

	if instance == LocalPlayer then
		local identifier2 = nil
		local rounds = nil
		local capacity = nil
		local alternativeShootingOption = nil
		local v4 = nil
		maid:Add(RunServiceController.BindToStepped("UI.Ammo.LocalPlayerUpdate", function()
			local currentEquipped = InventoryController.getCurrentEquipped()

			if not currentEquipped then
				return
			end

			local visible = v3.Gameplay.Middle.BuyMenu.Visible

			if
				currentEquipped.Identifier == identifier2
				and currentEquipped.Rounds == rounds
				and currentEquipped.Capacity == capacity
				and currentEquipped.AlternativeShootingOption == alternativeShootingOption
				and visible == v4
			then
				return
			end

			identifier2 = currentEquipped.Identifier
			rounds = currentEquipped.Rounds
			capacity = currentEquipped.Capacity
			alternativeShootingOption = currentEquipped.AlternativeShootingOption
			v4 = visible
			Ammo.updateFrame(currentEquipped)
		end))
	else
		maid:Add(instance:GetAttributeChangedSignal("CurrentEquipped"):Connect(function()
			showSpectatedEquipped(instance:GetAttribute("CurrentEquipped"))
		end))
		showSpectatedEquipped(instance:GetAttribute("CurrentEquipped"))
	end
end

function Ammo.Initialize(p, p2)
	v3 = p
	folder = p2
	folder.Active = false
	folder.AutoLocalize = false

	for _, guiObject in ipairs(folder:GetDescendants()) do
		if not guiObject:IsA("GuiObject") then
			continue
		end

		guiObject.Active = false
		guiObject.AutoLocalize = false
	end

	v = TweenService:Create(folder, TweenInfo.new(0.25), {
		Size = UDim2.fromScale(folder.Size.X.Scale, folder.Size.Y.Scale)
	})
	LocalPlayer.CharacterRemoving:Connect(function()
		if v2 == LocalPlayer then
			maid:Cleanup()
		end
	end)
	Observers.observeProperty(folder.Rounds.Amount, "Text", function()
		local tween = TweenService:Create(folder.Rounds.Amount.UIScale, TweenInfo.new(0.05), {
			Scale = 1.2
		})
		tween:Play()
		tween.Completed:Once(function()
			TweenService:Create(folder.Rounds.Amount.UIScale, TweenInfo.new(0.05, Enum.EasingStyle.Elastic), {
				Scale = 1
			}):Play()
		end)
	end)

	local function refreshPreferenceColor()
		local currentEquipped = InventoryController.getCurrentEquipped()

		if currentEquipped then
			Ammo.updateFrame(currentEquipped)
		end
	end

	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", refreshPreferenceColor)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(refreshPreferenceColor)
end

function Ammo.Start()
	HudTarget.Follow(trackPlayerState)
end

return Ammo