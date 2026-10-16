local StarterPack = {}
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local CommaNumber = require(ReplicatedStorage.Components.Common.CommaNumber)
local FormatDuration = require(ReplicatedStorage.Components.Common.FormatDuration)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local DevProducts = require(ReplicatedStorage.Database.Custom.GameStats.Monetization.DevProducts)
local Timestamps = require(script.Parent.Timestamps)
local NormalizeUnixTimestamp = Timestamps.NormalizeUnixTimestamp
local LocalPlayer = Players.LocalPlayer
local isStudio = RunService:IsStudio()
local v = nil
local v2 = nil
local v3 = nil
local starterPack = nil
local timer = nil
local purchase = nil
local timer2 = nil
local v4 = false
local v5 = 0
local flag = false
local v6 = false
local devProductId = nil

local function NormalizeOpenShopTime(value) -- 3 equivalent calls inferred from this helper
	if typeof(value) ~= "number" then
		if typeof(value) == "string" then
			value = tonumber(value)
		else
			value = nil
		end
	end

	if value == nil then
		return nil
	end

	return (NormalizeUnixTimestamp(value))
end

local function GetStarterPackRemainingSeconds(value, p: number?) -- 1 equivalent call inferred from this helper
	local openShopTime = NormalizeOpenShopTime(value) -- inferred equivalent call

	if openShopTime == nil then
		return 0
	end

	return (math.max(0, (math.floor(86400 - math.max(0, (p or workspace:GetServerTimeNow()) - openShopTime)))))
end

local function PlayerOwnsStarterPack()
	if not DataController.IsDataLoaded(LocalPlayer) then
		return false
	end

	local gamepasses = DataController.Get(LocalPlayer, "Gamepasses")
	return typeof(gamepasses) == "table" and table.find(gamepasses, "Credits StarterPack") ~= nil
end

local function GetStarterPackState(p: number?)
	if not DataController.IsDataLoaded(LocalPlayer) then
		return {
			IsDataLoaded = false,
			OpenShopTime = nil,
			OwnsStarterPack = false,
			RemainingSeconds = 0
		}
	end

	local openShopTime = NormalizeOpenShopTime(DataController.Get(LocalPlayer, "Statistics.OpenShopTime")) -- inferred equivalent call
	local ownsStarterPack

	if DataController.IsDataLoaded(LocalPlayer) then
		local gamepasses = DataController.Get(LocalPlayer, "Gamepasses")

		if typeof(gamepasses) == "table" then
			ownsStarterPack = table.find(gamepasses, "Credits StarterPack") ~= nil
		else
			ownsStarterPack = false
		end
	else
		ownsStarterPack = false
	end

	return {
		IsDataLoaded = true,
		OpenShopTime = openShopTime,
		OwnsStarterPack = ownsStarterPack,
		RemainingSeconds = GetStarterPackRemainingSeconds(openShopTime, p) -- inferred equivalent call
	}
end

local function RefreshStarterPackState(p: number?)
	Profiler.mark("UI.Store.RefreshStarterPackState")
	local starterPackState = GetStarterPackState(p)
	local v7

	if starterPackState.RemainingSeconds > 0 then
		v7 = not starterPackState.OwnsStarterPack
	else
		v7 = false
	end

	if timer2 then
		timer2.Text = not v7 and "NEW!" or FormatDuration(starterPackState.RemainingSeconds, "Never")
	end

	starterPack.Visible = v7 or isStudio
	timer.Text = v7 and FormatDuration(starterPackState.RemainingSeconds, "Never") or "00:00:00"
end

function StarterPack.IsAvailable()
	local starterPackState = GetStarterPackState()

	if starterPackState.IsDataLoaded and not starterPackState.OwnsStarterPack then
		return starterPackState.OpenShopTime == nil or starterPackState.RemainingSeconds > 0
	end

	return false
end

function StarterPack.IsShown()
	return isStudio or StarterPack.IsAvailable()
end

local function HandleStoreOpened()
	Profiler.mark("UI.Store.HandleStoreOpened")
	local starterPackState = GetStarterPackState()

	if not starterPackState.IsDataLoaded then
		RefreshStarterPackState()
	elseif starterPackState.OpenShopTime == nil then
		local now = tick()

		if not v4 or now - v5 >= 5 then
			v4 = true
			v5 = now
			Remotes.Store.OpenedShop.Send({})
		end

		RefreshStarterPackState()
	else
		v4 = true
		RefreshStarterPackState()
	end
end

local function setupStarterPackFrame()
	if flag then
		return
	end

	flag = true
	starterPack.Visible = false
	ActivateButton(purchase)
	local creditsStarterPack = DevProducts["Credits Starter Pack"]

	if creditsStarterPack then
		v(creditsStarterPack, function(p)
			purchase.Container.Title.Text = `{utf8.char(57346)} {CommaNumber(p)}`
		end)
	end

	purchase.MouseButton1Click:Connect(function()
		if v6 or not StarterPack.IsAvailable() then
			RefreshStarterPackState()
		elseif v3() then
			local creditsStarterPack2 = DevProducts["Credits Starter Pack"]

			if not creditsStarterPack2 then
				warn("[Store] Missing dev product configuration for Credits Starter Pack")
				return
			end

			v6 = true
			devProductId = creditsStarterPack2.DevProductId
			local tradeTokens = DataController.Get(LocalPlayer, "TradeTokens") or 0

			if creditsStarterPack2.Price and creditsStarterPack2.Price <= tradeTokens then
				v2("Credits Starter Pack", creditsStarterPack2)
				v6 = false
			else
				MarketplaceService:PromptProductPurchase(LocalPlayer, creditsStarterPack2.DevProductId)
				task.delay(1, function()
					v6 = false
				end)
			end

			Router.broadcastRouter("RunInterfaceSound", "UI Click")
		end
	end)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(p, p2)
		if p2 == devProductId and p == LocalPlayer.UserId then
			v6 = false
		end
	end)
end

function StarterPack.Bind(p, p2)
	starterPack = p.Tabs.Container.Featured.Container.StarterPack
	timer = starterPack.Pack.Container.Top.Title.Top.Timer
	purchase = starterPack.Pack.Container.Bottom.Purchase
	timer2 = p2.Menu.Top.Bottom.Buttons.Store.Timer.Timer
end

function StarterPack.Setup(callback, callback2, callback3)
	v = callback
	v2 = callback2
	v3 = callback3
	setupStarterPackFrame()
end

function StarterPack.OnOpenShopTimeChanged(value)
	if NormalizeOpenShopTime(value) ~= nil then -- inferred equivalent call
		v4 = true
	end

	RefreshStarterPackState()
end

StarterPack.WINDOW_SECONDS = 86400
StarterPack.GetState = GetStarterPackState
StarterPack.Refresh = RefreshStarterPackState
StarterPack.HandleStoreOpened = HandleStoreOpened
return StarterPack