local Money = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HudTarget = require(ReplicatedStorage.Interface.Screens.Gameplay.Bottom.Ammo.HudTarget)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local IsInBuyArea = require(ReplicatedStorage.Database.Components.Common.IsInBuyArea)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Spring = require(ReplicatedStorage.Shared.Spring)
local maid = Janitor.new()
local v = Spring.new(1, 8, 0)
local v2 = nil
local v3 = nil
local v4 = nil
local v5 = nil

local function commaNumber(p: number) -- 1 equivalent call inferred from this helper
	return tostring(p):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function getTargetPlayer()
	if LocalPlayer:GetAttribute("IsSpectating") then
		local player = SpectateController.GetPlayer()

		if player and player ~= LocalPlayer then
			return player
		end
	end

	return LocalPlayer
end

local function refreshPreferenceColor() -- 1 equivalent call inferred from this helper
	local textColor = GetPreferenceColor()

	if v4 == textColor then
		return
	end

	v4 = textColor

	if v5 then
		v5.Amount.TextColor3 = textColor
	end
end

function Money.CreatePlayerObserver(instance)
	maid:Cleanup()
	v2 = instance
	local money = tonumber(instance:GetAttribute("Money"))

	if money then
		v:setGoal(money)
	end

	local function noop() end

	maid:Add(Observers.observeAttribute(instance, "Money", function(p)
		if v2 ~= instance then
			return noop
		end

		local v6 = tonumber(p)

		if v6 then
			v:setGoal(v6)
		end

		return noop
	end))
end

local function refreshTrackedPlayer() -- 1 equivalent call inferred from this helper
	local v6

	if LocalPlayer:GetAttribute("IsSpectating") then
		v6 = SpectateController.GetPlayer()

		if not v6 or v6 == LocalPlayer then
			v6 = LocalPlayer
		end
	else
		v6 = LocalPlayer
	end

	if v2 == v6 then
		return
	end

	Money.CreatePlayerObserver(v6)
end

function Money.Initialize(_, p)
	v5 = p
	HudTarget.DisableInput(v5)
	LocalPlayer.CharacterAdded:Connect(refreshTrackedPlayer)
	LocalPlayer.CharacterRemoving:Connect(refreshTrackedPlayer)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(refreshPreferenceColor)
	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", refreshPreferenceColor)
	refreshPreferenceColor() -- inferred equivalent call
end

function Money.Start()
	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(refreshTrackedPlayer)
	SpectateController.ListenToSpectate:Connect(refreshTrackedPlayer)
	refreshTrackedPlayer() -- inferred equivalent call
	local v6 = nil
	local total = 1e999
	RunServiceController.BindToHeartbeat("UI.Money.Update", function(p: number)
		local v7 = math.round((v:getPosition()))

		if v7 ~= v6 then
			v6 = v7
			local text = "$" .. commaNumber(v7) -- inferred equivalent call

			if text ~= v3 then
				v3 = text
				v5.Amount.Text = text
			end
		end

		v:update(p)

		if LocalPlayer:GetAttribute("BuyMenu") then
			total += p

			if total < 0.1 then
				return
			end

			total = 0
			local visible = v5.Buy.Visible
			local visible2 = IsInBuyArea(LocalPlayer)

			if visible ~= visible2 then
				v5.Buy.Visible = visible2
			end

			if visible and not visible2 then
				Router.broadcastRouter(
					"CreateNotification",
					"You have left the buy zone",
					"You have left the buy zone",
					2
				)
			end
		else
			total = 1e999

			if v5.Buy.Visible then
				v5.Buy.Visible = false
			end
		end
	end)
end

return Money