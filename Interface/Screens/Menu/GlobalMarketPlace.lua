local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PolicyService = game:GetService("PolicyService")
local guiInset = GuiService:GetGuiInset()
local LocalPlayer = Players.LocalPlayer
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Store = require(ReplicatedStorage.Interface.Screens.Menu.Store)
local MarketplaceButton = require(ReplicatedStorage.Components.Common.MarketplaceButton)
local MarketplaceDropdown = require(ReplicatedStorage.Components.Common.MarketplaceDropdown)
local MarketplaceHover = require(ReplicatedStorage.Components.Common.MarketplaceHover)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local FuzzySearch = require(ReplicatedStorage.Shared.FuzzySearch)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local GuiShown = require(ReplicatedStorage.Components.Common.InterfaceAnimations.GuiShown)
local CollectionServiceUtility = require(ReplicatedStorage.Shared.CollectionServiceUtility)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local GamepadNavigation = require(ReplicatedStorage.Interface.GamepadNavigation)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local InspectController = require(ReplicatedStorage.Controllers.InspectController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local CommaNumber = require(ReplicatedStorage.Components.Common.CommaNumber)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local MarketPlacePrices = require(ReplicatedStorage.Database.Components.MarketPlacePrices)
local UserCache = require(ReplicatedStorage.Database.Custom.UserCache)
local Collections = require(ReplicatedStorage.Database.Components.Libraries.Collections)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local GlobalMarketplace = Remotes.GlobalMarketplace
require(ReplicatedStorage.Database.Custom.Types)
local v = {}

for k, v2 in {
	"Zero",
	"One",
	"Two",
	"Three",
	"Four",
	"Five",
	"Six",
	"Seven",
	"Eight",
	"Nine"
} do
	v[Enum.KeyCode[v2]] = tostring(k - 1)
	v[Enum.KeyCode[`Keypad{v2}`]] = tostring(k - 1)
end

local frozen = table.freeze({ Badge = true, Booth = true })
local frozen2 = table.freeze({ Package = true, Console = true, Case = true })
local frozen3 = table.freeze({
	"Karambit | Wemby",
	"Butterfly Knife | Lebron James",
	"CT Knife | Lebron James",
	"Wemby",
	"Lebron James"
})
local v2 = { 0, Constants.MARKETPLACE_MAX_LISTING_PRICE }
local v3 = {
	{ scale = 0.5, valueRatio = 0.001 },
	{ scale = 0.85, valueRatio = 0.01 },
	{ scale = 1, valueRatio = 1 }
}
local v4 = {
	{ "ITEM_NOT_MARKETABLE", "This item is not available on the marketplace" },
	{ "ITEM_HAS_CHARM", "Remove the charm before listing this item" },
	{ "ITEM_IS_CHARM", "Charms cannot be listed on the marketplace" }
}
local color = Color3.fromRGB(32, 255, 28)
local v5 = false
local v6 = false
local now = 0
local v7 = {
	search_bar_query = "",
	price_range = { v2[1], v2[2] },
	pattern_range = { 0, 11 },
	wear_range = { 0, 1 },
	statTrak = nil,
	rarity = nil,
	Collection = nil,
	page = 1
}
local v8 = {}
local v9 = nil
local v10 = {}
local v11 = 1
local v12 = false
local v13 = {}
local v14 = {
	{ key = "FactoryNew", max = 0.07, wear = "Factory New" },
	{ key = "MinimalWear", max = 0.15, wear = "Minimal Wear" },
	{ key = "FieldTested", max = 0.38, wear = "Field-Tested" },
	{ key = "WellWorn", max = 0.45, wear = "Well-Worn" },
	{ key = "BattleScarred", max = 1, wear = "Battle-Scarred" }
}
local fn
local v15 = {}
local v16 = false
local fn2
local v17 = { "Market", "Sell", "Profile" }
local v18 = {
	pageSize = 10,
	filters = { "Tradable", "MarketplaceListable", "All" },
	sort = "Quality",
	searchTerm = nil,
	sortReversed = false
}
local v19 = nil
local v20 = nil
local id = nil
local v21 = {}
local count = 0
local v22 = nil
local v23 = nil
local flag = false
local v24 = nil
local flag2 = false
local v25 = nil
local abandonSearchAfterTimeout
local selectQuickItem
local resetQuickSearchFilters
local folder = nil
local clone = nil
local clone2 = nil
local clone3 = nil
local clone4 = nil
local clone5 = nil
local v26 = nil
local v27 = nil
local v28 = nil
local v29 = nil
local v30 = nil
local GlobalMarketPlace = { tweenVisibility = false }

local function setLoading(visible: boolean) -- 15 equivalent calls inferred from this helper
	folder.Parent.Parent.Loading.Visible = visible

	if visible then
		v27:Play()
	else
		v27:Pause()
	end
end

local function getHeadshot(p: number, size420x420) -- 2 equivalent calls inferred from this helper
	return Players:GetUserThumbnailAsync(p, Enum.ThumbnailType.HeadShot, size420x420 or Enum.ThumbnailSize.Size180x180)
end

local function itemTypeHidesInspect(kind: string?) -- 3 equivalent calls inferred from this helper
	return kind == "Case" or kind == "Package"
end

local function showInspect(p)
	if itemTypeHidesInspect(p.Type) then -- inferred equivalent call
		return
	end

	local market = folder.Market
	local v31

	if MenuState.IsSelectionWithin(market.PurchaseMenu) or MenuState.IsSelectionWithin(market.Header.Guns) then
		v31 = GuiService.SelectedObject
	end

	v25 = v31
	local inspect = folder.Parent:FindFirstChild("Inspect")

	if inspect then
		CloseButtonRegistry.BringToFront(inspect)
	end

	InspectController.ShowInspect(p)
end

local function openTradeTokensStore() -- 1 equivalent call inferred from this helper
	local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
	Top.openFrame("Store")

	if MenuState.GetCurrentScreen() == "Store" then
		Store.OpenTab("TradeTokens")
	end
end

local function showNewItemsNotification(list) -- 1 equivalent call inferred from this helper
	local count2 = #list
	Router.broadcastRouter(
		"CreateNotification",
		"Marketplace",
		count2 == 1 and "Your marketplace item was added to your inventory." or `{count2} marketplace items were added to your inventory.`,
		4
	)
end

local function sendMarketSearch() -- 6 equivalent calls inferred from this helper
	local pattern_range = v7.pattern_range

	if pattern_range and pattern_range[1] <= 0 then
		v7.pattern_range = nil
	end

	GlobalMarketplace.SearchMarket.Send(v7)
	v7.pattern_range = pattern_range
	abandonSearchAfterTimeout()
end

abandonSearchAfterTimeout = function()
	count += 1
	local v31 = count
	task.delay(15, function()
		if v31 ~= count or not folder then
			return
		end

		v12 = false
		setLoading(false) -- inferred equivalent call
	end)
end

local function pruneOldestListingFrames(container, p: number)
	local guiObjects = {}

	for _, guiObject in container:GetChildren() do
		if guiObject:IsA("GuiObject") and guiObject.Name ~= ".space" then
			table.insert(guiObjects, guiObject)
		end
	end

	if #guiObjects <= p then
		return
	end

	table.sort(guiObjects, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for i = 1, #guiObjects - p do
		guiObjects[i]:Destroy()
	end
end

local function hydrateSellerNameAsync(seller, owner: number) -- 1 equivalent call inferred from this helper
	seller.Text = "Seller: ..."
	task.spawn(function()
		local success, result = pcall(UserCache.Fetch, owner)
		local v31 = not (success and result and result.Username) and "Unknown User" or result.Username

		if seller.Parent then
			seller.Text = `Seller: {v31}`
		end
	end)
end

local function stopOnlineStatusPulse(instance) -- 3 equivalent calls inferred from this helper
	if v30 then
		v30()
		v30 = nil
	end

	if v29 then
		v29:Cancel()
		v29 = nil
	end

	instance.TextTransparency = 0
	local onlinePulseDot = instance:FindFirstChild("OnlinePulseDot")

	if onlinePulseDot and onlinePulseDot:IsA("GuiObject") then
		onlinePulseDot.Visible = false
	end
end

local function getOnlineStatusDot(parent)
	local parent2 = parent:FindFirstChild("OnlinePulseDot")

	if parent2 and not parent2:IsA("Frame") then
		parent2:Destroy()
		parent2 = nil
	end

	if not parent2 then
		parent2 = Instance.new("Frame")
		parent2.Name = "OnlinePulseDot"
		parent2.BorderSizePixel = 0
		parent2.Parent = parent
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(1, 0)
		uiCorner.Parent = parent2
	end

	parent2.AnchorPoint = Vector2.new(0.5, 0.5)
	parent2.Position = UDim2.new(0, -7, 0.5, 0)
	parent2.Size = UDim2.fromOffset(6, 6)
	parent2.ZIndex = parent.ZIndex + 1
	return parent2
end

local function setOnlineStatus(last)
	stopOnlineStatusPulse(last) -- inferred equivalent call
	last.Text = "Online"
	last.TextColor3 = color
	local onlineStatusDot = getOnlineStatusDot(last)
	onlineStatusDot.Visible = true
	onlineStatusDot.BackgroundColor3 = color
	onlineStatusDot.BackgroundTransparency = 0.05
	local tween = TweenService:Create(
		onlineStatusDot,
		TweenInfo.new(0.85, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ BackgroundColor3 = color, BackgroundTransparency = 0.42 }
	)
	v29 = tween
	v30 = GuiShown.Observe(onlineStatusDot, function(flag3: boolean)
		if flag3 then
			tween:Play()
		else
			tween:Pause()
		end
	end)
end

local function prepareMarketplaceListingReveal(marketListing) -- 1 equivalent call inferred from this helper
	marketListing:SetAttribute("StaggerRevealReady", false)
	marketListing.Visible = false
end

local function revealMarketplaceListings(marketListings, shouldShowMarketListing) -- 1 equivalent call inferred from this helper
	task.spawn(function()
		for _, item in marketListings do
			if item.Parent then
				item:SetAttribute("StaggerRevealReady", true)
				item.Visible = shouldShowMarketListing(item)
			end

			task.wait(0.018)
		end
	end)
end

for _, child in ReplicatedStorage.Assets.Skins:GetChildren() do
	local lower = GetSkinDisplayName.GetWeaponDisplayName(child.Name):lower()
	table.insert(v21, lower)

	for _, child2 in child:GetChildren() do
		table.insert(v21, child2.Name:lower())
		table.insert(v21, `{lower} {child2.Name:lower()}`)
	end
end

local PredictSearch = require(ReplicatedStorage.Components.Common.PredictSearch)

local function predictSearch()
	local text = folder.Market.Filters.Container.Search.Frame.SearchBox.Text:lower()
	folder.Market.Filters.Container.Search.Frame.SearchBox.Text = text
	local predictSearch2 = PredictSearch(v21, text, 3)

	if predictSearch2 then
		local text2 = predictSearch2:gsub("m9", ""):gsub("TKnife", "Knife"):gsub("CTKnife", "Knife"):gsub(
			"_PATTERN_%d+",
			""
		):gsub(
			"The",
			""
		):gsub(
			"_pattern_%d+",
			""
		)
		v20 = text2
		folder.Market.Filters.Container.Search.Frame.Auto.Text = text2
	else
		v20 = nil
		folder.Market.Filters.Container.Search.Frame.Auto.Text = ""
	end
end

local count2 = 0

local function schedulePredictSearch()
	count2 += 1
	local v31 = count2
	task.delay(0.12, function()
		if v31 ~= count2 then
			return
		end

		predictSearch()
	end)
end

local function getSkinValue(name: string, skin: string, float: number, flag3: boolean) -- 4 equivalent calls inferred from this helper
	local itemPrice = MarketPlacePrices.GetItemPrice(name, skin, float, flag3)
	local recentAveragePriceTradeTokens = itemPrice and itemPrice.recentAveragePriceTradeTokens

	if recentAveragePriceTradeTokens and recentAveragePriceTradeTokens > 0 then
		return (math.floor(recentAveragePriceTradeTokens))
	end

	return nil
end

local function formatSkinValue(p: number?) -- 4 equivalent calls inferred from this helper
	if p then
		return (CommaNumber(p))
	end

	return "N/A"
end

local function getRarityData(rarity: string?)
	local v31 = nil

	for k, rarity2 in Rarities do
		if tostring(k) == "Stock" then
			v31 = rarity2
		end

		if tostring(k) == rarity then
			return rarity2
		end
	end

	return v31
end

local function itemTypeShowsFloat(kind: string?) -- 3 equivalent calls inferred from this helper
	return kind ~= "Case" and kind ~= "Charm Capsule" and kind ~= "Sticker Capsule" and kind ~= "Package"
end

local function formatSaleDate(date: number)
	return `{`{os.date("%B", date)} {os.date("%d", date)}, {os.date("%Y", date)}`}, {os.date("%I:%M %p", date)}`
end

local function isPurchaseRestrictedForItem(kind: string?) -- 2 equivalent calls inferred from this helper
	local v31 = v6

	if v31 then
		if kind == nil then
			return false
		else
			return frozen2[kind] == true
		end
	end

	return v31
end

local function getMarketplaceErrorMessage(p)
	if type(p) ~= "table" then
		return nil
	end

	for _, v31 in {
		"code",
		"errorCode",
		"error_code",
		"errorMessage",
		"error_message",
		"error",
		"message",
		"detail",
		"details"
	} do
		local v32 = p[v31]

		for _, v33 in v4 do
			if v32 == v33[1] or v32 == v33[2] then
				return v33[2]
			end
		end

		if type(v32) ~= "table" then
			continue
		end

		local v33 = getMarketplaceErrorMessage(v32)

		if v33 then
			return v33
		end
	end

	if type(p.results) ~= "table" then
		return nil
	end

	for _, result in p.results do
		local v31 = getMarketplaceErrorMessage(result)

		if v31 then
			return v31
		end
	end

	return nil
end

local function showMarketplaceError(p) -- 1 equivalent call inferred from this helper
	local marketplaceErrorMessage = getMarketplaceErrorMessage(p)

	if not marketplaceErrorMessage then
		return false
	end

	Router.broadcastRouter("CreateNotification", "Error", marketplaceErrorMessage)
	return true
end

local function openTradeTokensStoreFromMarketplace(priceTradeTokens: number) -- 1 equivalent call inferred from this helper
	task.spawn(function()
		local err = ReplicatedStorage.Assets.Sounds:FindFirstChild("Error")

		if err and err:IsA("Sound") then
			err:Play()
		end

		task.wait(0.1)
		openTradeTokensStore() -- inferred equivalent call
		task.wait(0.3)
		Store.PromptTradeTokenPackageForItemPrice(priceTradeTokens)
	end)
end

local function hideQuickPick()
	v9 = nil
	folder.Market.Header.Guns.Visible = false

	for _, button in folder.Market.Header.Filters:GetChildren() do
		if button:IsA("TextButton") then
			button.ImageLabel.Rotation = 0
		end
	end
end

local function closeSellPopups() -- 5 equivalent calls inferred from this helper
	folder.Sell.Confirm.Visible = false

	if v26 then
		v26:Destroy()
	end
end

local function switchTab(p: string)
	for _, v31 in v17 do
		folder[v31].Visible = v31 == p
	end

	if p ~= "Market" then
		hideQuickPick()
	end

	if p ~= "Sell" then
		closeSellPopups() -- inferred equivalent call
	end
end

local function destroyListingCard(guiObject)
	local v31 = MenuState.IsSelectionWithin(guiObject) and GamepadNavigation.IsUsable(GuiService.SelectedObject)
	local v32

	if guiObject:IsA("GuiObject") then
		v32 = guiObject.AbsolutePosition + guiObject.AbsoluteSize / 2
	end

	guiObject:Destroy()

	if not v31 then
		return
	end

	local container = folder.Market.Container
	local v33 = nil
	local v34 = 1e999

	if v32 then
		for _, guiObject2 in container:GetDescendants() do
			if not (guiObject2:IsA("GuiObject") and GamepadNavigation.IsUsable(guiObject2)) then
				continue
			end

			local magnitude = (guiObject2.AbsolutePosition + guiObject2.AbsoluteSize / 2 - v32).Magnitude

			if not (magnitude < v34) then
				continue
			end

			v33 = guiObject2
			v34 = magnitude
		end
	end

	if v33 and GamepadNavigation.Focus(v33) then
		return
	end

	if not GamepadNavigation.Focus(container) then
		GamepadNavigation.Focus(folder.Top.Frame:FindFirstChild("Market"))
	end
end

local function roundToDecimals(p: number) -- 2 equivalent calls inferred from this helper
	return math.floor(p * 1000000 + 0.5) / 1000000
end

local function deepCopy(items)
	if type(items) ~= "table" then
		return items
	end

	local result = {}

	for k, item in items do
		result[k] = deepCopy(item)
	end

	return result
end

local function getPriceSliderSegments(p: number)
	if p <= 1 then
		return {
			{ scale = 1, value = p }
		}
	end

	local result = {}

	for _, v31 in v3 do
		local v32 = math.min(math.max(1, (math.floor(p * v31.valueRatio + 0.5))), p)

		if #result == 0 or result[#result].value < v32 then
			table.insert(result, { scale = v31.scale, value = v32 })
		end

		if p <= v32 then
			break
		end
	end

	if result[#result].value < p then
		table.insert(result, { scale = 1, value = p })
	end

	return result
end

local function sliderScaleToValue(value: number, p: number)
	if p <= 1 then
		return value * p
	end

	local v31 = math.clamp(value, 0, 1)
	local priceSliderSegments = getPriceSliderSegments(p)
	local scale = 0
	local value2 = 0

	for _, priceSliderSegment in priceSliderSegments do
		if v31 <= priceSliderSegment.scale or priceSliderSegment.scale >= 1 then
			local v32 = priceSliderSegment.scale - scale

			if v32 == 0 then
				return priceSliderSegment.value
			end

			local v33 = (v31 - scale) / v32
			return (math.floor(value2 + (priceSliderSegment.value - value2) * v33 + 0.5))
		else
			scale = priceSliderSegment.scale
			value2 = priceSliderSegment.value
		end
	end

	return p
end

local function sliderValueToScale(value: number, max: number)
	if max <= 1 then
		return value / max
	end

	local v31 = math.clamp(value, 0, max)
	local priceSliderSegments = getPriceSliderSegments(max)
	local value2 = 0
	local scale = 0

	for _, priceSliderSegment in priceSliderSegments do
		if
			not (priceSliderSegment.value <= value2)
			and (v31 <= priceSliderSegment.value or priceSliderSegment.scale >= 1)
		then
			return scale + (priceSliderSegment.scale - scale) * (v31 - value2) / (priceSliderSegment.value - value2)
		end

		scale = priceSliderSegment.scale
		value2 = priceSliderSegment.value
	end

	return 1
end

local function setDrag(p, p2: number, childName: string, p3: number)
	local v31 = tonumber(p2)

	if not v31 then
		return
	end

	local name = p.Name
	local v32 = v7[name]

	if type(v32) ~= "table" then
		return
	end

	local v33 = math.clamp(v31, childName == "StartPin" and 0 or v32[1], childName == "EndPin" and p3 or v32[2])
	p.Slider[childName].Position = UDim2.fromScale(sliderValueToScale(v33, p3), 1.2)
	v7[name] = {
		sliderScaleToValue(p.Slider.StartPin.Position.X.Scale, p3),
		(sliderScaleToValue(p.Slider.EndPin.Position.X.Scale, p3))
	}
	local v34 = v7[name]

	for _, v35 in CollectionService:GetTagged(name) do
		local slider = v35:FindFirstChild("Slider")
		local content = v35:FindFirstChild("Content")

		if not (slider and content) then
			continue
		end

		local inputs = content:FindFirstChild("Inputs")

		if not inputs then
			continue
		end

		local startPin = slider:FindFirstChild("StartPin")
		local endPin = slider:FindFirstChild("EndPin")
		local child = slider:FindFirstChild(childName)
		local startPin2 = inputs:FindFirstChild("StartPin")
		local endPin2 = inputs:FindFirstChild("EndPin")

		if not (child and startPin and endPin and startPin2) then
			continue
		end

		if not endPin2 then
			continue
		end

		child.Position = p.Slider[childName].Position
		startPin2.TextBox.Text = p3 > 1 and CommaNumber((math.floor(v34[1]))) or roundToDecimals(v34[1]) -- inferred equivalent call
		endPin2.TextBox.Text = p3 > 1 and CommaNumber((math.floor(v34[2]))) or roundToDecimals(v34[2]) -- inferred equivalent call
		local span = slider:FindFirstChild("Span")

		if not span then
			continue
		end

		local scale = startPin.Position.X.Scale
		local scale2 = endPin.Position.X.Scale
		span.Position = UDim2.new(scale, 0, span.Position.Y.Scale, span.Position.Y.Offset)
		span.Size = UDim2.new(math.max(scale2 - scale, 0), 0, span.Size.Y.Scale, span.Size.Y.Offset)
	end

	if name == "wear_range" and not v16 then
		fn2()
	end
end

local function getWearTierMin(k: number) -- 2 equivalent calls inferred from this helper
	if k == 1 then
		return 0
	end

	return v14[k - 1].max
end

local function isFullWearRange(p: number, p2: number) -- 1 equivalent call inferred from this helper
	return p <= 1e-9 and p2 >= 0.999999999
end

local function setWearTierVisual(childName: string, visible: boolean)
	for _, v31 in CollectionService:GetTagged("wear_range") do
		local child = v31.List:FindFirstChild(childName)

		if not (child and child:FindFirstChild("Button")) then
			continue
		end

		local imageLabel = child.Button:FindFirstChild("ImageLabel")

		if imageLabel then
			imageLabel.Visible = visible
		end
	end
end

local function setWearRange(p: number, p2: number)
	if not folder then
		return
	end

	local wear_range = folder.Market.Filters.Container:FindFirstChild("wear_range")

	if not wear_range then
		return
	end

	v16 = true
	v7.wear_range = { p, p2 }
	setDrag(wear_range, p, "StartPin", 1)
	setDrag(wear_range, p2, "EndPin", 1)
	v16 = false
end

fn2 = function()
	local v31 = v7.wear_range[1]
	local v32 = v7.wear_range[2]

	if isFullWearRange(v31, v32) then -- inferred equivalent call
		for _, v33 in v14 do
			v15[v33.key] = false
			setWearTierVisual(v33.key, false)
		end
	else
		for k, v33 in v14 do
			local wearTierMin = getWearTierMin(k) -- inferred equivalent call
			local max = v33.max
			local v34

			if v31 <= wearTierMin + 1e-9 then
				v34 = max - 1e-9 <= v32
			else
				v34 = false
			end

			v15[v33.key] = v34
			setWearTierVisual(v33.key, v34)
		end
	end
end

local function getWearSearchRangeFromSelection()
	local v31 = 1
	local v32 = 0
	local v33 = false

	for k, v34 in v14 do
		if not v15[v34.key] then
			continue
		end

		v31 = math.min(v31, getWearTierMin(k)) -- inferred equivalent call
		v32 = math.max(v32, v34.max)
		v33 = true
	end

	if not v33 then
		return { 0, 1 }
	end

	if v32 < 1 then
		v32 -= 1e-12
	end

	return { v31, v32 }
end

local function refreshWearRangeInSearchPayload() -- 10 equivalent calls inferred from this helper
	v7.wear_range = getWearSearchRangeFromSelection()
end

local function anyWearTiersSelected() -- 4 equivalent calls inferred from this helper
	for _, v31 in v14 do
		if v15[v31.key] then
			return true
		end
	end

	return false
end

local function wearNameMatchesSelectedTiers(p: string)
	for _, v31 in v14 do
		if v15[v31.key] and v31.wear == p then
			return true
		end
	end

	return false
end

local function listingFrameMatchesSelectedWearTiers(instance)
	if not anyWearTiersSelected() then -- inferred equivalent call
		return true
	end

	local wear = instance:GetAttribute("Wear")

	if typeof(wear) == "string" then
		for _, v31 in v14 do
			if v15[v31.key] and v31.wear == wear then
				return true
			end
		end
	end

	return false
end

local function listingMatchesSelectedWearTiers(listing)
	if not anyWearTiersSelected() then -- inferred equivalent call
		return true
	end

	local inventoryItem = listing.inventoryItem

	if not inventoryItem or inventoryItem.Float == nil then
		return false
	end

	local skinInformation = Skins.GetSkinInformation(inventoryItem.Name, inventoryItem.Skin)

	if not skinInformation then
		return false
	end

	local wearNameForFloat = Skins.GetWearNameForFloat(skinInformation, inventoryItem.Float)

	if not wearNameForFloat then
		return false
	end

	for _, v31 in v14 do
		if v15[v31.key] and v31.wear == wearNameForFloat then
			return true
		end
	end

	return false
end

local function syncWearRangeFromTierSelection() -- 6 equivalent calls inferred from this helper
	local wearSearchRangeFromSelection = getWearSearchRangeFromSelection()
	local v31 = wearSearchRangeFromSelection[2]

	if v31 < 1 then
		v31 += 1e-12
	end

	setWearRange(wearSearchRangeFromSelection[1], v31)
end

local function toggleWearTier(key: string) -- 1 equivalent call inferred from this helper
	v15[key] = not v15[key]
	setWearTierVisual(key, v15[key])
	syncWearRangeFromTierSelection() -- inferred equivalent call
	fn()
end

local function setupWearTierButtons()
	for _, v31 in v14 do
		v15[v31.key] = false
		setWearTierVisual(v31.key, false)

		for _, v32 in CollectionService:GetTagged("wear_range") do
			local child = v32.List:FindFirstChild(v31.key)

			if not (child and child:FindFirstChild("Button")) then
				continue
			end

			local v33 = v31
			MarketplaceButton.new(child.Button, {
				hoverSizeMultiplier = 0.9,
				onActivated = function()
					toggleWearTier(v33.key) -- inferred equivalent call
				end
			})
		end
	end
end

local function dragSlider(data, p, p2: number, input)
	repeat
		local v31

		if input.UserInputType == Enum.UserInputType.Touch then
			v31 = Vector2.new(input.Position.X, input.Position.Y)
		else
			v31 = UserInputService:GetMouseLocation()
		end

		local v32 = math.clamp(((v31 - guiInset).X - data.AbsolutePosition.X) / data.AbsoluteSize.X, 0, 1)
		local scale = data.StartPin.Position.X.Scale
		local scale2 = data.EndPin.Position.X.Scale
		local v33 = math.clamp(v32, p.Name ~= "EndPin" and 0 or scale, p.Name ~= "StartPin" and 1 or scale2)
		setDrag(data.Parent, sliderScaleToValue(v33, p2), p.Name, p2)
		RunService.RenderStepped:Wait()
	until input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel
end

local v31 = {}
local count3 = 0
local v32 = 0

local function nudgeSliderPin(selectedObject, p: number)
	local v33 = v31[selectedObject]

	if not v33 then
		return
	end

	local maxValue = v33.maxValue
	local scale = selectedObject.Position.X.Scale
	local v34

	if maxValue <= 1 then
		v34 = math.clamp(sliderScaleToValue(scale, maxValue) + p * 0.01, 0, maxValue)
	elseif maxValue <= 20 then
		v34 = math.clamp(math.floor(sliderScaleToValue(scale, maxValue) + 0.5) + p, 0, maxValue)
	else
		v34 = sliderScaleToValue(math.clamp(scale + p * 0.01, 0, 1), maxValue)
	end

	setDrag(v33.fill.Parent, v34, selectedObject.Name, maxValue)
end

local function startSliderNudge(p: number, fn3)
	local selectedObject = GuiService.SelectedObject

	if not (selectedObject and v31[selectedObject]) then
		return
	end

	count3 += 1
	local v33 = count3
	nudgeSliderPin(selectedObject, p)
	task.delay(0.35, function()
		while
			v33 == count3
			and fn3()
			and GuiService.SelectedObject == selectedObject
			and GamepadNavigation.IsUsable(selectedObject)
		do
			nudgeSliderPin(selectedObject, p)
			task.wait(0.05)
		end
	end)
end

UserInputService.InputBegan:Connect(function(input)
	local keyCode = input.KeyCode

	if keyCode ~= Enum.KeyCode.DPadLeft and keyCode ~= Enum.KeyCode.DPadRight then
		return
	end

	local userInputType = input.UserInputType
	startSliderNudge(keyCode == Enum.KeyCode.DPadLeft and -1 or 1, function()
		return UserInputService:IsGamepadButtonDown(userInputType, keyCode)
	end)
end)
UserInputService.InputChanged:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.Thumbstick1 then
		return
	end

	local x = input.Position.X
	local v33 = x > 0.6 and 1 or x < -0.6 and -1 or 0

	if v33 == v32 then
		return
	end

	v32 = v33

	if v33 ~= 0 then
		startSliderNudge(v33, function()
			return v32 == v33
		end)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Thumbstick1 then
		v32 = 0
	end
end)
UserInputService.GamepadDisconnected:Connect(function()
	v32 = 0
	count3 += 1
end)

local function bindSliderPin(slider, p, maxValue: number)
	MarketplaceButton.new(p, { hoverSizeMultiplier = 0.9 })
	v31[p] = { fill = slider, maxValue = maxValue }
	p.NextSelectionLeft = p
	p.NextSelectionRight = p
	p.InputBegan:Connect(function(input)
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		dragSlider(slider, p, maxValue, input)
	end)
end

local function createMarketListing(parent, name: string, clone6, p, layoutOrder: number?)
	if not (type(name) == "string" and clone6) then
		return
	end

	local child = parent:FindFirstChild(name)

	if child then
		return child
	end

	if not (p and p.inventoryItem) then
		return
	end

	local skinInformation = Skins.GetSkinInformation(p.inventoryItem.Name, p.inventoryItem.Skin)

	if not skinInformation then
		return
	end

	local weaponProperties = GetWeaponProperties(p.inventoryItem.Name)
	local kind

	if weaponProperties then
		kind = weaponProperties.Type
	else
		kind = p.inventoryItem.Type
	end

	local wearNameForFloat, v34 = Skins.GetWearNameForFloat(skinInformation, p.inventoryItem.Float)
	local abbreviatedWearName = Skins.GetAbbreviatedWearName(v34)
	local rarityData = getRarityData(skinInformation.rarity)
	local v35 = p.inventoryItem.StatTrack and true or false
	local fullItemDisplayName = GetSkinDisplayName.GetFullItemDisplayName(
		p.inventoryItem.Name,
		p.inventoryItem.Skin,
		v35,
		true,
		p.inventoryItem.NameTag
	)
	local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(p.inventoryItem.Name, p.inventoryItem.NameTag)
	local clone7 = clone6:Clone()
	clone7.Name = name
	clone7.Main.ItemIcon.Image = Skins.GetItemIconImage(skinInformation, p.inventoryItem)
	GetSkinDisplayName.ApplyNameLabel(clone7.Main.Skin, fullItemDisplayName, p.inventoryItem.NameTag)
	clone7.Main.Status.Text = v34 or ""
	clone7.Main.FloatNumber.Text = p.inventoryItem.Float
	clone7.Main.FloatBar.Frame.Position = UDim2.fromScale(p.inventoryItem.Float, 0.5)
	clone7.Main.RarityFrame.Serial.SerialText.Text = `#{CommaNumber(p.inventoryItem.Serial)}`

	if p.inventoryItem.MetaData then
		for k, v36 in p.inventoryItem.MetaData do
			if type(v36) ~= "table" then
				clone7:SetAttribute(k, v36)
			end
		end
	end

	clone7:SetAttribute("Gun", weaponDisplayName)
	clone7:SetAttribute("InternalGun", p.inventoryItem.Name)
	clone7:SetAttribute("Skin", p.inventoryItem.Skin)
	clone7:SetAttribute("InventoryItemId", p.inventoryItem._id)
	clone7:SetAttribute("Wear", wearNameForFloat)
	clone7:SetAttribute("Type", kind)
	clone7:SetAttribute("OtherType", skinInformation.type)
	clone7:SetAttribute("Float", p.inventoryItem.Float)
	clone7:SetAttribute("Collection", skinInformation.collection)
	hydrateSellerNameAsync(clone7.Main.Seller, p.inventoryItem.MetaData.Owner) -- inferred equivalent call

	if clone7.Main:FindFirstChild("RAP") and skinInformation.paintId then
		local skinValue = getSkinValue(p.inventoryItem.Name, p.inventoryItem.Skin, p.inventoryItem.Float, v35) -- inferred equivalent call
		clone7.Main.RAP.TextLabel.Text = `RAP: {formatSkinValue(skinValue)}` -- inferred equivalent call
		clone7:SetAttribute("RAP", skinValue or 0)
	end

	local marketPlaceItem = MarketPlacePrices.GetMarketPlaceItem(p.inventoryItem.Name, p.inventoryItem.Skin)

	if marketPlaceItem and clone7.Main:FindFirstChild("Projected") then
		local statTrack

		if v35 then
			statTrack = marketPlaceItem.statTrack
		else
			statTrack = marketPlaceItem.standard
		end

		local v36 = statTrack[wearNameForFloat] or statTrack.Default
		local projected = clone7.Main.Projected
		projected.Visible = v36 ~= nil and v36.projected
		clone7.Main.Projected.MouseEnter:Connect(function()
			clone7.Main.Projected.Display.Visible = true
		end)
		clone7.Main.Projected.MouseLeave:Connect(function()
			clone7.Main.Projected.Display.Visible = false
		end)
		clone7.Main.Projected.SelectionGained:Connect(function()
			clone7.Main.Projected.Display.Visible = true
		end)
		clone7.Main.Projected.SelectionLost:Connect(function()
			clone7.Main.Projected.Display.Visible = false
		end)
	end

	if not itemTypeShowsFloat(p.inventoryItem.Type) then -- inferred equivalent call
		clone7.Main.FloatNumber.Visible = false
		clone7.Main.FloatBar.Visible = false
	end

	if clone7.Main.ItemIcon:FindFirstChild("Worth") and skinInformation.paintId then
		local serialText = clone7.Main.ItemIcon.Worth.SerialText
		serialText.Text = `RAP: {formatSkinValue(getSkinValue(p.inventoryItem.Name, p.inventoryItem.Skin, p.inventoryItem.Float, v35))}` -- inferred equivalent call
	end

	if rarityData and rarityData.ColorSequence then
		clone7.Main.RarityFrame.RarityBarGradient.Color = rarityData.ColorSequence
		clone7.Main.RarityBG.RarityBarGradient.Color = rarityData.ColorSequence
	end

	clone7.Main.RarityFrame.Condition.Tag.Text = abbreviatedWearName
	clone7.Main.RarityFrame.Condition[`{abbreviatedWearName}Gradient`].Enabled = true
	clone7.Main.Credits.Visible = p.priceTradeTokens ~= nil
	clone7.Main.Credits.TextLabel.Text = not p.priceTradeTokens and "" or CommaNumber(p.priceTradeTokens)

	if layoutOrder ~= nil then
		clone7.LayoutOrder = layoutOrder
	end

	clone7.Parent = parent
	local tools = clone7:FindFirstChild("Main") and clone7.Main:FindFirstChild("Tools")
	local inspect

	if tools then
		inspect = tools:FindFirstChild("Inspect") or nil
	end

	if inspect then
		MarketplaceButton.new(inspect, {
			hoverSizeMultiplier = 0.9,
			onActivated = function()
				if folder.Market.PurchaseMenu.Visible then
					return
				end

				showInspect(p.inventoryItem)
			end
		})

		if itemTypeHidesInspect(p.inventoryItem.Type) then -- inferred equivalent call
			inspect.Visible = false
		end
	end

	local userDescription = tools and tools:FindFirstChild("UserDescription") or nil

	if not userDescription then
		return clone7
	end

	MarketplaceButton.new(userDescription, {
		hoverSizeMultiplier = 0.9,
		onActivated = function()
			if not folder.Market.PurchaseMenu.Visible then
				MarketplaceHover:OpenTradeInfo(p.inventoryItem, clone7)
			end
		end
	})

	if not UserInputService.TouchEnabled then
		userDescription.MouseEnter:Connect(function()
			MarketplaceHover:Open(p.inventoryItem, clone7)
		end)
		userDescription.MouseLeave:Connect(function()
			MarketplaceHover:Close(clone7)
		end)
	end

	return clone7
end

local function removeYourListingByInventoryItemId(p: string)
	for _, frame in folder.Profile.Main.Frame.YourListings.YourListings:GetChildren() do
		if not (frame:IsA("Frame") and frame:GetAttribute("InventoryItemId") == p) then
			continue
		end

		frame:Destroy()
		break
	end
end

local function addYourListing(data)
	if not (data.inventoryItem and data.listing_reference_id and clone and Skins.HasSkinTextures(
		data.inventoryItem.Name,
		data.inventoryItem.Skin
	)) then
		return
	end

	local yourListings = folder.Profile.Main.Frame.YourListings.YourListings

	if yourListings:FindFirstChild(data.listing_reference_id) then
		return
	end

	local marketListing = createMarketListing(yourListings, data.listing_reference_id, clone, data)

	if not marketListing then
		return
	end

	local priceTradeTokens = data.priceTradeTokens or data.tradeTokens
	marketListing.Main.Credits.TextLabel.Text = formatSkinValue(priceTradeTokens) -- inferred equivalent call
	marketListing.Main.Credits.Visible = true
	marketListing.Main.Delist.Visible = true
	marketListing.Main.Delist.Visible = data.inventoryItem.MetaData.Owner == LocalPlayer.UserId
	local _id = data.inventoryItem._id
	MarketplaceButton.new(marketListing.Main.Delist, {
		hoverSizeMultiplier = 0.9,
		onActivated = function()
			setLoading(true) -- inferred equivalent call
			GlobalMarketplace.DelistItem.Send(_id)
			marketListing:Destroy()
			local child = folder.Sell.Container:FindFirstChild(_id)

			if child then
				child.Visible = true
				child.Main.Sell.Visible = true
				child.Main.Delist.Visible = false
			end
		end
	})
	return marketListing
end

local function getInventoryItemById(p: string)
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not inventory then
		return nil
	end

	for _, v33 in inventory do
		if v33._id == p then
			return v33
		end
	end

	return nil
end

local function withListingReference(inventoryItem, listing_reference_id: string)
	if inventoryItem.MetaData and inventoryItem.MetaData.GlobalMarketPlaceListingReference == listing_reference_id then
		return inventoryItem
	end

	local clone6 = table.clone(inventoryItem)
	clone6.MetaData = table.clone(inventoryItem.MetaData or {})
	clone6.MetaData.GlobalMarketPlaceListingReference = listing_reference_id
	return clone6
end

local function syncListedItemToProfile(result)
	local inventoryItemId = result.inventoryItemId or result.inventory_item_id

	if typeof(inventoryItemId) ~= "string" then
		return false
	end

	local v33 = v13[inventoryItemId]
	local listing_reference_id = result.listing_reference_id
		or result.listingReferenceId
		or v33 and v33.listingReferenceId
	local inventoryItem = result.inventoryItem

	if not inventoryItem then
		inventoryItem = v33 and v33.inventoryItem

		if not inventoryItem then
			local inventory = DataController.Get(LocalPlayer, "Inventory")

			if inventory then
				local flag3 = true

				for _, v34 in inventory do
					if v34._id ~= inventoryItemId then
						continue
					end

					inventoryItem = v34
					flag3 = false
					break
				end

				if flag3 then
					inventoryItem = nil
				end
			else
				inventoryItem = nil
			end
		end
	end

	if inventoryItem and not listing_reference_id and inventoryItem.MetaData then
		listing_reference_id = inventoryItem.MetaData.GlobalMarketPlaceListingReference
	end

	if typeof(inventoryItem) ~= "table" or typeof(listing_reference_id) ~= "string" or listing_reference_id == "" then
		return false
	end

	local priceTradeTokens = result.priceTradeTokens or result.price_trade_tokens or v33 and v33.Price
	return addYourListing({
		listing_reference_id = listing_reference_id,
		priceTradeTokens = priceTradeTokens,
		tradeTokens = priceTradeTokens or 0,
		date = os.time(),
		inventoryItem = withListingReference(inventoryItem, listing_reference_id)
	}) ~= nil
end

local function setupMarket()
	clone = folder.Market.Container.Template:Clone()
	folder.Market.Container.Template:Destroy()
	MarketplaceButton.new(folder.Top.TradeTokens.PurchaseMore, {
		hoverSizeMultiplier = 0.9,
		onActivated = openTradeTokensStore
	})
	local v33 = nil
	local main = folder.Market.PurchaseMenu.Main

	local function clearPurchaseMenuTransactions()
		for _, frame in main.Main.Transactions.Listings:GetChildren() do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end

		for _, frame in main.Main.Similar.Listings:GetChildren() do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end
	end

	v28 = TweenService:Create(
		main.Main.SalesGraph.Loading,
		TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 1e999),
		{ Rotation = 359 }
	)
	main.Main.Template.Projected.MouseEnter:Connect(function()
		main.Main.Template.Projected.Display.Visible = true
	end)
	main.Main.Template.Projected.MouseLeave:Connect(function()
		main.Main.Template.Projected.Display.Visible = false
	end)
	main.Main.Template.Projected.SelectionGained:Connect(function()
		main.Main.Template.Projected.Display.Visible = true
	end)
	main.Main.Template.Projected.SelectionLost:Connect(function()
		main.Main.Template.Projected.Display.Visible = false
	end)

	local function getSalesGraphDotted()
		local salesGraph = main.Main.SalesGraph
		local dotted = salesGraph:FindFirstChild("Dotted")

		if dotted and dotted:IsA("GuiObject") then
			return dotted
		end

		local dotted2 = salesGraph.GraphVisual:FindFirstChild("Dotted")

		if dotted2 and dotted2:IsA("GuiObject") then
			return dotted2
		end

		return nil
	end

	local function hideSalesGraphHover() -- 3 equivalent calls inferred from this helper
		local saleInfo = main.Main.SalesGraph:FindFirstChild("SaleInfo")

		if saleInfo and saleInfo:IsA("GuiObject") then
			saleInfo.Visible = false
		end

		local salesGraph = main.Main.SalesGraph
		local dotted = salesGraph:FindFirstChild("Dotted")

		if not (dotted and dotted:IsA("GuiObject")) then
			dotted = salesGraph.GraphVisual:FindFirstChild("Dotted")

			if not (dotted and dotted:IsA("GuiObject")) then
				dotted = nil
			end
		end

		if dotted then
			dotted.Visible = false
		end
	end

	local function clearGraphVisual()
		hideSalesGraphHover() -- inferred equivalent call
		local graphVisual = main.Main.SalesGraph.GraphVisual

		for _, child in graphVisual:GetChildren() do
			if child.Name ~= "Dotted" then
				child:Destroy()
			end
		end

		graphVisual.ImageContent = Content.none
	end

	local function alignDottedToGraphX(p: number)
		local salesGraph = main.Main.SalesGraph
		local dotted = salesGraph:FindFirstChild("Dotted")

		if not (dotted and dotted:IsA("GuiObject")) then
			dotted = salesGraph.GraphVisual:FindFirstChild("Dotted")

			if not (dotted and dotted:IsA("GuiObject")) then
				dotted = nil
			end
		end

		if not dotted then
			return
		end

		local parent = dotted.Parent
		local graphVisual = main.Main.SalesGraph.GraphVisual

		if parent == graphVisual then
			dotted.Position = UDim2.new(p, 0, dotted.Position.Y.Scale, dotted.Position.Y.Offset)
		elseif parent and parent:IsA("GuiObject") and parent.AbsoluteSize.X > 0 then
			local v34 = (graphVisual.AbsolutePosition.X + p * graphVisual.AbsoluteSize.X - parent.AbsolutePosition.X) / parent.AbsoluteSize.X
			dotted.Position = UDim2.new(v34, 0, dotted.Position.Y.Scale, dotted.Position.Y.Offset)
		end

		dotted.ZIndex = math.max(dotted.ZIndex, 21)
		dotted.Visible = true
	end

	local function plotGraph(sales_graph, rapGraphReference)
		if v19 then
			v19:Destroy()
			v19 = nil
		end

		clearGraphVisual()

		if #sales_graph == 0 then
			return
		end

		local vector = Vector2.new(
			math.clamp(main.Main.SalesGraph.GraphVisual.AbsoluteSize.X, 0, 1024),
			(math.clamp(main.Main.SalesGraph.GraphVisual.AbsoluteSize.Y, 0, 1024))
		)
		local success, result = pcall(function()
			return AssetService:CreateEditableImage({ Size = vector })
		end)

		if not success then
			result = nil
		end

		v19 = result
		local absoluteSize = main.Main.SalesGraph.GraphVisual.AbsoluteSize
		local v34 = -1e999
		local priorAverageTradeTokens

		if rapGraphReference and type(rapGraphReference.priorAverageTradeTokens) == "number" then
			priorAverageTradeTokens = rapGraphReference.priorAverageTradeTokens or nil
		end

		for _, v35 in sales_graph do
			v34 = math.max(v34, v35.averageTradeTokens)
		end

		if priorAverageTradeTokens then
			v34 = math.max(v34, priorAverageTradeTokens)
		end

		local function roundUpTo5(p: number) -- 1 equivalent call inferred from this helper
			return math.ceil(p / 5) * 5
		end

		local v35 = roundUpTo5(v34) -- inferred equivalent call
		local v36 = v35 - 0
		local v37 = v36 == 0 and 1 or v36

		local function toScreen(p: number, p2: number, p3: number)
			local size = vector
			local v39 = size.X - 10
			local v40 = size.Y - 10
			local v41

			if p2 <= 1 then
				v41 = 5 + v39 / 2
			else
				v41 = 5 + (p - 1) / (p2 - 1) * v39
			end

			local v42 = size.Y - 5 - (p3 - 0) / v37 * v40
			return Vector2.new(v41, v42)
		end

		local count4 = #sales_graph
		local vectors = {}

		for k, v38 in sales_graph do
			local averageTradeTokens = v38.averageTradeTokens
			local v39 = vector.X - 10
			local v40 = vector.Y - 10
			local v41

			if count4 <= 1 then
				v41 = 5 + v39 / 2
			else
				v41 = 5 + (k - 1) / (count4 - 1) * v39
			end

			local v42 = vector.Y - 5 - (averageTradeTokens - 0) / v37 * v40
			vectors[k] = Vector2.new(v41, v42)
		end

		local size = v19.Size
		local x = size.X
		local y = size.Y
		local v38 = y - 5

		if v19 then
			local buf = buffer.create(x * y * 4)

			for i = 0, x * y * 4 - 1 do
				buffer.writeu8(buf, i, 0)
			end

			local color2 = Color3.new(0, 0.8, 1)

			for i = 1, #vectors - 1 do
				local v39 = vectors[i]
				local v40 = vectors[i + 1]
				local x2 = math.floor(v39.X)
				local x3 = math.floor(v40.X)

				if x3 < x2 then
					local v41 = x3
					x3 = x2
					x2 = v41
					v41 = v39
					v39 = v40
					v40 = v41
				end

				local v41 = v40.X - v39.X

				if v41 == 0 then
					continue
				end

				for j = x2, x3 do
					local v42 = (j - v39.X) / v41

					if not (v42 >= 0 and v42 <= 1) then
						continue
					end

					for k = math.floor(v39.Y + (v40.Y - v39.Y) * v42), v38 do
						if not (k >= 0 and k < y) then
							continue
						end

						local v43 = (k * x + j) * 4
						buffer.writeu8(buf, v43, color2.R * 255)
						buffer.writeu8(buf, v43 + 1, color2.G * 255)
						buffer.writeu8(buf, v43 + 2, color2.B * 255)
						buffer.writeu8(buf, v43 + 3, 80)
					end
				end
			end

			if pcall(function()
				v19:WritePixelsBuffer(Vector2.zero, size, buf)
			end) then
				clearGraphVisual()
			else
				v19:Destroy()
				v19 = nil
			end
		end

		local function createPointFrame(point: Vector2)
			local vector2 = Vector2.new(point.X / vector.X, point.Y / vector.Y)
			local frame = Instance.new("Frame")
			frame.Name = "GraphPoint"
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.fromScale(vector2.X, vector2.Y)
			frame.Size = UDim2.fromOffset(12, 12)
			frame.BackgroundColor3 = Color3.new(0, 0.403921, 0.733333)
			frame.BackgroundTransparency = 0
			frame.BorderSizePixel = 0
			frame.ZIndex = 6
			local uiCorner = Instance.new("UICorner")
			uiCorner.CornerRadius = UDim.new(1, 0)
			uiCorner.Parent = frame
			frame.Parent = main.Main.SalesGraph.GraphVisual
		end

		local function createLineFrame(point: Vector2, point2: Vector2, p: number)
			local vector2 = Vector2.new(point.X / vector.X, point.Y / vector.Y)
			local vector3 = Vector2.new(point2.X / vector.X, point2.Y / vector.Y)
			local v39 = vector3.X - vector2.X
			local v40 = vector3.Y - vector2.Y
			local v41 = math.sqrt((v39 * absoluteSize.X) ^ 2 + (v40 * absoluteSize.Y) ^ 2)

			if v41 == 0 then
				return
			end

			local vector4 = Vector2.new((vector2.X + vector3.X) / 2, (vector2.Y + vector3.Y) / 2)
			local rotation = math.deg((math.atan2(
				(vector3.Y - vector2.Y) * absoluteSize.Y,
				(vector3.X - vector2.X) * absoluteSize.X
			)))
			local frame = Instance.new("Frame")
			frame.Name = "GraphLine"
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.fromScale(vector4.X, vector4.Y)
			frame.Size = UDim2.new(UDim.new(v41 / absoluteSize.X, 0), UDim.new(0, p * 2 + 1))
			frame.Rotation = rotation
			frame.BackgroundColor3 = Color3.new(0, 0.349019, 0.631372)
			frame.BackgroundTransparency = 0
			frame.BorderSizePixel = 0
			frame.ZIndex = 5
			frame.Parent = main.Main.SalesGraph.GraphVisual
		end

		for i = 1, #vectors - 1 do
			createLineFrame(vectors[i], vectors[i + 1], 2)
		end

		for _, v39 in vectors do
			createPointFrame(v39)
		end

		local saleInfo = main.Main.SalesGraph.SaleInfo
		local info = saleInfo.Info
		hideSalesGraphHover() -- inferred equivalent call
		local imageButton = Instance.new("ImageButton")
		imageButton.Name = "HoverCatch"
		imageButton.BackgroundTransparency = 1
		imageButton.ImageTransparency = 1
		imageButton.AutoButtonColor = false
		imageButton.Size = UDim2.fromScale(1, 1)
		imageButton.ZIndex = 20
		imageButton.Parent = main.Main.SalesGraph.GraphVisual
		local v39 = nil

		local function showNearestPoint(p: number)
			local v40 = vectors[p]
			local v41 = sales_graph[p]

			if not (v40 and v41) then
				return
			end

			local v42 = v40.X / vector.X
			alignDottedToGraphX(v42)

			if v39 == p and saleInfo.Visible then
				return
			end

			v39 = p
			local salesGraph = main.Main.SalesGraph
			local graphVisual = salesGraph.GraphVisual
			local vector2 = Vector2.new(v42 * graphVisual.AbsoluteSize.X, v40.Y / vector.Y * graphVisual.AbsoluteSize.Y)
			local v43 = graphVisual.AbsolutePosition + vector2 - salesGraph.AbsolutePosition
			local absoluteSize2 = saleInfo.AbsoluteSize
			local v44 = v43.X < salesGraph.AbsoluteSize.X / 2
			local v45

			if v44 then
				v45 = v43.X + absoluteSize2.X + 10
			else
				v45 = v43.X - absoluteSize2.X - 10
			end

			saleInfo.AnchorPoint = Vector2.new(v44 and 1 or 0, 1)
			saleInfo.Position = UDim2.fromOffset(v45, v43.Y + 10)
			info.Amount.Text = `Sold {v41.amount_sold}`
			info.Credits.TextLabel.Text = CommaNumber((math.floor(v41.averageTradeTokens)))
			info.Date.Text = formatSaleDate(v41.date)
			saleInfo.Visible = true
		end

		imageButton.MouseMoved:Connect(function()
			if #vectors == 0 or vector.X <= 0 or vector.Y <= 0 then
				return
			end

			local graphVisual = main.Main.SalesGraph.GraphVisual
			local absoluteSize2 = graphVisual.AbsoluteSize

			if absoluteSize2.X <= 0 or absoluteSize2.Y <= 0 then
				return
			end

			local v40 = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			local v41 = 1e999
			local v42 = 1

			for k, v43 in vectors do
				local v44 = v40 - (graphVisual.AbsolutePosition + Vector2.new(
					v43.X / vector.X * absoluteSize2.X,
					v43.Y / vector.Y * absoluteSize2.Y
				))
				local v45 = v44.X * v44.X + v44.Y * v44.Y

				if not (v45 < v41) then
					continue
				end

				v42 = k
				v41 = v45
			end

			showNearestPoint(v42)
		end)
		imageButton.MouseLeave:Connect(function()
			v39 = nil
			hideSalesGraphHover() -- inferred equivalent call
		end)

		local function getIndex(i: number) -- 1 equivalent call inferred from this helper
			if i == 1 then
				return 1
			elseif i == 6 then
				return count4
			end

			return (math.floor((i - 1) / 5 * (count4 - 1) + 1 + 0.5))
		end

		local function createAxisLabel(text: string, p: number) -- 2 equivalent calls inferred from this helper
			local textLabel = Instance.new("TextLabel")
			textLabel.Name = "AxisLabel"
			textLabel.BackgroundTransparency = 1
			textLabel.Text = text
			textLabel.TextSize = 10
			textLabel.TextColor3 = Color3.new(1, 1, 1)
			textLabel.Size = UDim2.fromOffset(p, 15)
			return textLabel
		end

		for i = 1, 6 do
			local index = getIndex(i) -- inferred equivalent call
			local v40 = vectors[index]

			if not v40 then
				continue
			end

			local axisLabel = createAxisLabel(os.date("%x", sales_graph[index].date), 60) -- inferred equivalent call
			axisLabel.AnchorPoint = Vector2.new(0.5, 1)
			axisLabel.Position = UDim2.new(UDim.new(v40.X / vector.X, 0), UDim.new(1, 0))
			axisLabel.Parent = main.Main.SalesGraph.GraphVisual
		end

		for i = 0, 5 do
			local v40 = math.floor((i / 5 * v35 + 2.5) / 5) * 5
			local v41 = (v40 - 0) / v37
			local v42 = y - 5 - v41 * (y - 10)
			local axisLabel = createAxisLabel(CommaNumber(v40), 30) -- inferred equivalent call
			axisLabel.AnchorPoint = Vector2.new(1, 0.5)
			axisLabel.TextXAlignment = Enum.TextXAlignment.Right
			axisLabel.Position = UDim2.fromOffset(1, v42)
			axisLabel.Parent = main.Main.SalesGraph.GraphVisual

			if not (v40 > 99) then
				continue
			end

			axisLabel.AnchorPoint = Vector2.new(0, 0.5)
			axisLabel.TextXAlignment = Enum.TextXAlignment.Left
		end

		if v19 then
			main.Main.SalesGraph.GraphVisual.ImageContent = Content.fromObject(v19)
		end
	end

	local function confirmBuy(marketListing)
		local fetched = UserCache.Fetch(v33.inventoryItem.MetaData.Owner)
		main.Main.Credits.TextLabel.Text = v33.priceTradeTokens and CommaNumber(v33.priceTradeTokens) or "N/A"
		main.Main.FloatBar.Frame.Position = UDim2.fromScale(v33.inventoryItem.Float, 0.5)
		main.Main.FloatNum.Text = v33.inventoryItem.Float
		main.Main.SerialNum.Text = `#{CommaNumber(v33.inventoryItem.Serial)}`
		main.Main.Info.Status.Text = marketListing.Main.Status.Text
		main.Main.Info.Skin.Text = marketListing.Main.Skin.Text
		local player = main.Main.Player.Player
		player.Image = Players:GetUserThumbnailAsync(
			v33.inventoryItem.MetaData.Owner,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size180x180
		)
		main.Main.Player.DisplayName.Text = fetched.DisplayName
		main.Main.Player.Username.Text = fetched.Username
		main.Main.Template.ItemIcon.Image = marketListing.Main.ItemIcon.Image
		main.Main.Template.Projected.Visible = marketListing.Main.Projected.Visible
		main.Main.Template.RarityBG.RarityBarGradient.Color = marketListing.Main.RarityBG.RarityBarGradient.Color
		local clone6 = marketListing.Main.RarityFrame:Clone()
		clone6.Size = main.Main.Template.RarityFrame.Size
		clone6.Position = main.Main.Template.RarityFrame.Position
		main.Main.Template.RarityFrame:Destroy()
		clone6.Parent = main.Main.Template
		hideQuickPick()
		main.Parent.Visible = true
		main.Main.Purchase.Visible = v33.priceTradeTokens ~= nil

		if v19 then
			v19:Destroy()
		end

		clearPurchaseMenuTransactions()
		clearGraphVisual()
		main.Main.SalesGraph.Loading.Visible = true
		v28:Play()
		id = v33.inventoryItem._id
		GlobalMarketplace.FetchRAP.Send(id)
	end

	local function fillSimilarListingRow(clone6, data, p: number)
		local fetched = UserCache.Fetch(p)
		clone6.Name = data.listing_reference_id
		local float = clone6.Float
		float.Text = not itemTypeShowsFloat(data.inventoryItem.Type) and "N/A" or tostring(data.inventoryItem.Float) -- inferred equivalent call
		clone6.Serial.Text = not data.inventoryItem.Serial and "N/A" or `#{CommaNumber(data.inventoryItem.Serial)}`
		clone6.Credits.TextLabel.Text = CommaNumber(data.priceTradeTokens)
		clone6.Player.DisplayName.Text = fetched.DisplayName
		clone6.Player.Player.Image = Players:GetUserThumbnailAsync(
			p,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size180x180
		)
		local inspect = clone6.Inspect
		local kind = data.inventoryItem.Type
		inspect.Visible = kind ~= "Case" and kind ~= "Package"
	end

	GlobalMarketplace.FetchedRAP.Listen(function(p)
		if not p or p.inventoryItemId ~= id then
			return
		end

		local itemData = p.itemData
		clearPurchaseMenuTransactions()

		if itemData and itemData.next_inventory_items then
			for k, next_inventory_item in itemData.next_inventory_items do
				local clone6 = clone4:Clone()
				fillSimilarListingRow(clone6, next_inventory_item, next_inventory_item.sellerUserId)
				clone6.Parent = main.Main.Similar.Listings
				local v34 = next_inventory_item
				MarketplaceButton.new(clone6.Inspect, {
					hoverSizeMultiplier = 0.9,
					onActivated = function()
						showInspect(v34.inventoryItem)
					end
				})
				local v35 = k
				MarketplaceButton.new(clone6.View, {
					hoverSizeMultiplier = 0.9,
					onActivated = function()
						local v36 = deepCopy(v33)
						v36.sellerUserId = v33.inventoryItem.MetaData.Owner
						v33 = deepCopy(itemData.next_inventory_items[v35])
						itemData.next_inventory_items[v35] = v36
						fillSimilarListingRow(clone6, v36, v36.inventoryItem.MetaData.Owner)
						local fetched = UserCache.Fetch(v33.inventoryItem.MetaData.Owner)
						main.Main.Template.RarityFrame.Serial.SerialText.Text = `#{CommaNumber(v33.inventoryItem.Serial)}`
						main.Main.SerialNum.Text = `#{CommaNumber(v33.inventoryItem.Serial)}`
						main.Main.Credits.TextLabel.Text = not v33.priceTradeTokens and "N/A"
							or CommaNumber(v33.priceTradeTokens)
						main.Main.Player.DisplayName.Text = fetched.DisplayName
						main.Main.Player.Username.Text = fetched.Username
						local player = main.Main.Player.Player
						player.Image = Players:GetUserThumbnailAsync(
							v33.inventoryItem.MetaData.Owner,
							Enum.ThumbnailType.HeadShot,
							Enum.ThumbnailSize.Size180x180
						)
						local skinInformation = Skins.GetSkinInformation(v33.inventoryItem.Name, v33.inventoryItem.Skin)
						local _, v37 = Skins.GetWearNameForFloat(skinInformation, v33.inventoryItem.Float)
						local abbreviatedWearName = Skins.GetAbbreviatedWearName(v37)

						for _, uiGradient in main.Main.Template.RarityFrame.Condition:GetChildren() do
							if uiGradient:IsA("UIGradient") then
								uiGradient.Enabled = false
							end
						end

						main.Main.Template.RarityFrame.Condition.Tag.Text = abbreviatedWearName
						main.Main.Template.RarityFrame.Condition[`{abbreviatedWearName}Gradient`].Enabled = true
						main.Main.FloatBar.Frame.Position = UDim2.fromScale(v33.inventoryItem.Float, 0.5)
						main.Main.FloatNum.Text = tostring(v33.inventoryItem.Float)
						main.Main.Purchase.Visible = v33.priceTradeTokens ~= nil
					end
				})
			end
		end

		if itemData and itemData.latest_sales then
			for _, latest_sale in itemData.latest_sales do
				local clone6 = clone3:Clone()
				clone6.Name = latest_sale.listingReferenceId
				clone6.Float.Text = not latest_sale.float and 0 or latest_sale.float or 0
				local float = clone6.Float
				local kind = v33.inventoryItem and v33.inventoryItem.Type
				float.Visible = itemTypeShowsFloat(kind) -- inferred equivalent call
				clone6.Date.Text = formatSaleDate(latest_sale.date)
				clone6.Serial.Text = not latest_sale.serial and "N/A" or CommaNumber(latest_sale.serial)
				clone6.Credits.TextLabel.Text = CommaNumber(latest_sale.tradeTokens)
				clone6.Parent = main.Main.Transactions.Listings
				local v34 = {}

				for k, v35 in v33.inventoryItem do
					if k ~= "Float" then
						v34[k] = v35
					end
				end

				v34.Float = not latest_sale.float and 0 or latest_sale.float or 0
				v34.Serial = latest_sale.serial and latest_sale.serial or 0
				local inspect = clone6.Inspect
				local kind2 = v34.Type
				inspect.Visible = kind2 ~= "Case" and kind2 ~= "Package"
				MarketplaceButton.new(clone6.Inspect, {
					hoverSizeMultiplier = 0.9,
					onActivated = function()
						showInspect(v34)
					end
				})
			end
		end

		if itemData and itemData.sales_graph then
			plotGraph(itemData.sales_graph, itemData.rapGraphReference)
		end

		main.Main.SalesGraph.Loading.Visible = false
		v28:Pause()
	end)
	GlobalMarketplace.NewItem.Listen(function(list)
		showNewItemsNotification(list) -- inferred equivalent call
	end)
	GlobalMarketplace.PurchaseItemResult.Listen(function(p)
		local marketplaceErrorMessage = getMarketplaceErrorMessage(p)

		if not marketplaceErrorMessage then
			return
		end

		Router.broadcastRouter("CreateNotification", "Error", marketplaceErrorMessage)
	end)
	MarketplaceButton.new(folder.Market.PurchaseMenu.Confirm.Action.Frame.Accept, {
		hoverSizeMultiplier = 0.95,
		onActivated = function()
			local kind = v33.inventoryItem and v33.inventoryItem.Type

			if isPurchaseRestrictedForItem(kind) then -- inferred equivalent call
				Router.broadcastRouter(
					"CreateNotification",
					"Error",
					"Paid random items are not allowed in your region."
				)
				return
			end

			local tradeTokens = DataController.Get(LocalPlayer, "TradeTokens") or 0
			local priceTradeTokens = v33.priceTradeTokens or 1e999

			if tradeTokens < priceTradeTokens then
				openTradeTokensStoreFromMarketplace(priceTradeTokens) -- inferred equivalent call
				return
			end

			if not LocalPlayer:GetAttribute("PinVerified") then
				return
			end

			setLoading(true) -- inferred equivalent call
			GlobalMarketplace.PurchaseItem.Send(v33)
			id = nil
			folder.Market.PurchaseMenu.Visible = false
			folder.Market.PurchaseMenu.Confirm.Visible = false
		end
	})
	local purchaseMenu = folder.Market.PurchaseMenu
	local confirm = purchaseMenu.Confirm
	local confirm2 = folder.Market.Confirm

	local function closePurchaseConfirm() -- 1 equivalent call inferred from this helper
		confirm.Visible = false
	end

	local function closePurchaseMenu()
		id = nil

		if v19 then
			v19:Destroy()
			v19 = nil
		end

		clearPurchaseMenuTransactions()
		clearGraphVisual()
		v28:Pause()
		main.Main.SalesGraph.Loading.Visible = false
		closePurchaseConfirm() -- inferred equivalent call
		purchaseMenu.Visible = false
	end

	local function closeLegacyConfirm()
		confirm2.Visible = false
	end

	MarketplaceButton.new(confirm.Action.Frame.Decline, {
		hoverSizeMultiplier = 0.9,
		onActivated = closePurchaseConfirm
	})
	MarketplaceButton.new(purchaseMenu.Main.Main.Purchase, {
		hoverSizeMultiplier = 0.9,
		onActivated = function()
			confirm.Visible = true
		end
	})
	MarketplaceButton.new(purchaseMenu.Main.Header.Close, {
		hoverSizeMultiplier = 0.9,
		onActivated = closePurchaseMenu
	})
	MarketplaceButton.new(confirm2.Action.Frame.Decline, {
		hoverSizeMultiplier = 0.9,
		onActivated = closeLegacyConfirm
	})
	local main2 = purchaseMenu.Main.Main
	local container = main2.Header.TopSelect.Container
	local v34 = {
		{ "SalesGraph", "SalesGraph" },
		{ "SimilarListings", "Similar" },
		{ "LatestSales", "Transactions" }
	}

	local function showPurchaseMenuTab(p)
		for _, v35 in v34 do
			main2[v35[2]].Visible = v35 == p
			container[v35[1]].Frame.Visible = v35 == p
		end
	end

	for _, v35 in v34 do
		local v36 = v35
		MarketplaceButton.new(container[v35[1]], {
			hoverSizeMultiplier = 0.9,
			onActivated = function()
				showPurchaseMenuTab(v36)
			end
		})
	end

	CloseButtonRegistry.Add(purchaseMenu, nil, closePurchaseMenu)
	CloseButtonRegistry.Add(confirm, nil, closePurchaseConfirm)
	CloseButtonRegistry.Add(confirm2, nil, closeLegacyConfirm)
	GamepadNavigation.TrapPopup(purchaseMenu, function()
		local purchase = purchaseMenu.Main.Main.Purchase

		if purchase.Visible then
			return purchase
		end

		return container.SalesGraph
	end)
	GamepadNavigation.TrapPopup(confirm, function()
		return confirm.Action.Frame.Decline
	end)
	GamepadNavigation.TrapPopup(confirm2, function()
		return confirm2.Action.Frame.Decline
	end)
	MenuState.RegisterBumperOverride(purchaseMenu, function(flag3: boolean)
		if confirm.Visible then
			return true
		end

		local v35 = 1

		for k, v37 in v34 do
			if not main2[v37[2]].Visible then
				continue
			end

			v35 = k
			break
		end

		local v37 = v34[(v35 - 1 + (flag3 and -1 or 1)) % #v34 + 1]
		showPurchaseMenuTab(v37)
		GamepadNavigation.Focus(container[v37[1]])
		return true
	end, purchaseMenu)
	local descendant = CollectionServiceUtility.FindDescendantWithTag(folder.Market.Header.Filters, "SearchBox")
	local descendant2 = CollectionServiceUtility.FindDescendantWithTag(
		folder.Market.Header.Filters,
		"Dropdown_Category"
	)
	local v35 = "All"
	local v36 = "Quality"
	local v37 = true
	local v38 = {
		["Factory New"] = 0,
		["Minimal Wear"] = 1,
		["Field-Tested"] = 2,
		["Well-Worn"] = 3,
		["Battle-Scarred"] = 4
	}
	local v39 = {
		["Sticker Capsule"] = 14,
		["Charm Capsule"] = 13,
		["Music Kit"] = 8,
		Graffiti = 11,
		Grenade = 16,
		Sticker = 10,
		["Zeus x27"] = 3,
		Charm = 9,
		Melee = 1,
		Glove = 2,
		Badge = 7,
		Case = 12,
		C4 = 15,
		Miscellaneous = 18,
		Equipment = 17,
		Pistol = 3,
		Rifle = 6,
		Heavy = 5,
		SMG = 4
	}

	local function getMarketHeaderSearchTerm()
		if not descendant then
			return nil
		end

		local text = descendant.Text

		if text == "" then
			return nil
		end

		return text
	end

	local function listingMatchesHeaderSearch(instance)
		local text

		if descendant then
			text = descendant.Text

			if text == "" then
				text = nil
			end
		end

		if not text then
			return true
		end

		local internalGun = instance:GetAttribute("InternalGun")
		local skin = instance:GetAttribute("Skin")

		if typeof(internalGun) ~= "string" or typeof(skin) ~= "string" then
			return false
		end

		local v40 = GetSkinDisplayName.GetSearchIdentity(internalGun, skin):lower() .. " " .. string.lower((tostring(instance:GetAttribute("Wear") or ""))) .. " " .. string.lower((tostring(instance:GetAttribute("Type") or ""))) .. " " .. string.lower((tostring(instance:GetAttribute("OtherType") or ""))) .. " " .. string.lower((tostring(instance:GetAttribute("Collection") or "")))
		return FuzzySearch.MatchesQuery(v40, text)
	end

	local function shouldShowMarketListing(instance)
		local v40 = (v35 == "All" or v35 == instance:GetAttribute("Type")) and listingMatchesHeaderSearch(instance)

		if not v40 then
			return v40
		end

		if instance:GetAttribute("StaggerRevealReady") == false then
			v40 = false
			return false
		end

		if not anyWearTiersSelected() then -- inferred equivalent call
			return true
		end

		local wear = instance:GetAttribute("Wear")

		if typeof(wear) == "string" then
			for _, v41 in v14 do
				if v15[v41.key] and v41.wear == wear then
					return true
				end
			end
		end

		v40 = false
		return false
	end

	local function showCategory(flag3: boolean?)
		local v40 = flag3 ~= false

		local function getSortValue(instance)
			if v36 == "Quality" then
				local wear = instance:GetAttribute("Wear")

				if typeof(wear) == "string" then
					return v38[wear] or 0
				end

				return 0
			elseif v36 == "Newest" then
				local createdAt = instance:GetAttribute("CreatedAt")

				if typeof(createdAt) == "number" then
					return createdAt
				end

				return 0
			elseif v36 == "RAP" then
				local rap = instance:GetAttribute("RAP")

				if typeof(rap) == "number" then
					return rap
				end

				return 0
			elseif v36 == "Alphabetical" then
				local internalGun = instance:GetAttribute("InternalGun")
				local skin = instance:GetAttribute("Skin")

				if typeof(internalGun) == "string" and typeof(skin) == "string" then
					return (GetSkinDisplayName.GetSearchIdentity(internalGun, skin):lower())
				end

				return ""
			elseif v36 == "Float" then
				local float = instance:GetAttribute("Float")

				if typeof(float) == "number" then
					return float
				end

				return 0
			elseif v36 == "Serial" then
				local serial = instance:GetAttribute("Serial")

				if typeof(serial) == "number" then
					return serial
				end

				return 0
			elseif v36 == "Type" then
				local otherType = instance:GetAttribute("OtherType")

				if typeof(otherType) == "string" then
					return v39[otherType] or 0
				end

				return 0
			else
				if v36 ~= "Collection" then
					return 0
				end

				local collection = instance:GetAttribute("Collection")

				if typeof(collection) == "string" then
					return (collection:lower())
				end

				return ""
			end
		end

		local frames = {}

		for _, frame in folder.Market.Container:GetChildren() do
			if not frame:IsA("Frame") then
				continue
			end

			local visible = v35 == "All" or v35 == frame:GetAttribute("Type")

			if visible then
				visible = listingMatchesHeaderSearch(frame)

				if visible then
					if frame:GetAttribute("StaggerRevealReady") == false then
						visible = false
					elseif anyWearTiersSelected() then -- inferred equivalent call
						local wear = frame:GetAttribute("Wear")

						if typeof(wear) == "string" then
							local flag4 = true

							for _, v42 in v14 do
								if not (v15[v42.key] and v42.wear == wear) then
									continue
								end

								visible = true
								flag4 = false
								break
							end

							if flag4 then
								visible = false
							end
						else
							visible = false
						end
					else
						visible = true
					end
				end
			end

			frame.Visible = visible

			if frame.Visible and v40 then
				table.insert(frames, frame)
			end
		end

		table.sort(frames, function(a, b)
			local sortValue = getSortValue(a)
			local sortValue2 = getSortValue(b)

			if sortValue == sortValue2 then
				return a.Name < b.Name
			end

			if v37 then
				return sortValue2 < sortValue
			end

			return sortValue < sortValue2
		end)

		for k, v41 in frames do
			v41.LayoutOrder = k
		end
	end

	fn = function()
		showCategory(true)
	end

	local function getNextMarketLayoutOrder()
		local v40 = 0

		for _, guiObject in folder.Market.Container:GetChildren() do
			if guiObject:IsA("GuiObject") then
				v40 = math.max(v40, guiObject.LayoutOrder)
			end
		end

		return v40 + 1
	end

	local function captureMarketScrollAnchor()
		local container2 = folder.Market.Container
		local y = container2.AbsolutePosition.Y
		local v40 = y + container2.AbsoluteSize.Y
		local anchor = nil
		local offsetInView = 0

		for _, guiObject in container2:GetChildren() do
			if not (guiObject:IsA("GuiObject") and guiObject.Visible) then
				continue
			end

			local y2 = guiObject.AbsolutePosition.Y
			local v43 = y2 + guiObject.AbsoluteSize.Y

			if not (y2 < v40 and y < v43 and (not anchor or anchor.AbsolutePosition.Y <= y2)) then
				continue
			end

			offsetInView = y2 - y
			anchor = guiObject
		end

		return { canvas = container2.CanvasPosition, anchor = anchor, offsetInView = offsetInView }
	end

	local function restoreMarketScrollAnchor(data) -- 1 equivalent call inferred from this helper
		local container2 = folder.Market.Container
		local anchor = data.anchor

		if anchor and anchor.Parent then
			local v40 = anchor.AbsolutePosition.Y - container2.AbsolutePosition.Y
			container2.CanvasPosition = Vector2.new(
				data.canvas.X,
				container2.CanvasPosition.Y + (v40 - data.offsetInView)
			)
		else
			container2.CanvasPosition = data.canvas
		end
	end

	GlobalMarketplace.SearchMarketResults.Listen(function(data)
		count += 1
		local listings = data and data.Listings
		local totalPages = data and data.TotalPages
		local onCooldown = data and data.OnCooldown

		if listings == nil then
			setLoading(false) -- inferred equivalent call
			v12 = false
		elseif onCooldown then
			setLoading(false) -- inferred equivalent call
			v12 = false
			showCategory()
		else
			if totalPages then
				v11 = totalPages
			end

			local v40

			if v7.page == nil then
				v40 = false
			else
				v40 = v7.page > 1
			end

			local v41

			if v40 then
				v41 = captureMarketScrollAnchor()
			else
				v41 = nil
			end

			local v42

			if v40 then
				v42 = getNextMarketLayoutOrder()
			end

			if not v40 then
				for _, frame in folder.Market.Container:GetChildren() do
					if frame:IsA("Frame") then
						frame:Destroy()
					end
				end
			end

			local marketListings = {}

			for _, listing in listings do
				if not (listing.inventoryItem and Skins.HasSkinTextures(
					listing.inventoryItem.Name,
					listing.inventoryItem.Skin
				) and (listing.ForceConfirm or listingMatchesSelectedWearTiers(listing))) then
					continue
				end

				if folder.Market.Container:FindFirstChild(listing.inventoryItem._id) then
					continue
				end

				local v43

				if v42 then
					v43 = v42 + 1
				else
					v43 = v42
					v42 = nil
				end

				local marketListing = createMarketListing(
					folder.Market.Container,
					listing.inventoryItem._id,
					clone,
					listing,
					v42
				)

				if marketListing then
					if v40 then
						marketListing:SetAttribute("StaggerRevealReady", true)
					else
						prepareMarketplaceListingReveal(marketListing) -- inferred equivalent call
					end

					table.insert(marketListings, marketListing)

					if listing.inventoryItem.MetaData.GlobalMarketPlaceListingReference then
						if LocalPlayer.UserId == listing.inventoryItem.MetaData.Owner then
							marketListing.Main.Delist.Visible = true
							local v44 = listing
							MarketplaceButton.new(marketListing.Main.Delist, {
								hoverSizeMultiplier = 0.9,
								onActivated = function()
									if not (LocalPlayer.UserId == v44.inventoryItem.MetaData.Owner and LocalPlayer:GetAttribute("PinVerified")) then
										return
									end

									setLoading(true) -- inferred equivalent call
									GlobalMarketplace.DelistItem.Send(v44.inventoryItem._id)
									local child = folder.Sell.Container:FindFirstChild(v44.inventoryItem._id)

									if child then
										child.Visible = true
										child.Main.Sell.Visible = true
										child.Main.Delist.Visible = false
									end

									removeYourListingByInventoryItemId(v44.inventoryItem._id)
									destroyListingCard(marketListing)
								end
							})

							if not folder.Profile.Main.Frame.YourListings.YourListings:FindFirstChild(listing.listing_reference_id) then
								addYourListing(listing)
							end
						else
							marketListing.Main.Purchase.Visible = true
							local v44 = listing
							MarketplaceButton.new(marketListing.Main.Purchase, {
								hoverSizeMultiplier = 0.9,
								onActivated = function()
									if
										LocalPlayer.UserId == v44.inventoryItem.MetaData.Owner
										or main.Parent.Visible
									then
										return
									end

									if isPurchaseRestrictedForItem(v44.inventoryItem.Type) then -- inferred equivalent call
										Router.broadcastRouter(
											"CreateNotification",
											"Error",
											"Paid random items are not allowed in your region."
										)
										return
									end

									v33 = v44
									confirmBuy(marketListing)
								end
							})
						end

						if listing.ForceConfirm then
							v33 = listing
							confirmBuy(marketListing)
							folder.Visible = true
							MenuState.SetScreen("GlobalMarketPlace")
						end
					else
						marketListing.Visible = false
					end
				end

				v42 = v43
			end

			local function finishResults()
				showCategory(not v40)

				if v40 then
					pruneOldestListingFrames(folder.Market.Container, 96)
				end

				setLoading(false) -- inferred equivalent call

				if v40 then
					if v41 then
						local function restoreScroll() -- 2 equivalent calls inferred from this helper
							restoreMarketScrollAnchor(v41) -- inferred equivalent call
						end

						restoreScroll() -- inferred equivalent call
						local absoluteCanvasSizeChangedConnection = folder.Market.Container:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(restoreScroll)
						task.delay(0.15, function()
							if absoluteCanvasSizeChangedConnection then
								absoluteCanvasSizeChangedConnection:Disconnect()
							end

							restoreScroll() -- inferred equivalent call
						end)
					end
				else
					revealMarketplaceListings(marketListings, shouldShowMarketListing) -- inferred equivalent call
				end

				v12 = false
			end

			finishResults()
		end
	end)
	local lastTime = os.clock()
	folder.Market.Container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local container2 = folder.Market.Container
		local v40 = math.max(0, container2.AbsoluteCanvasSize.Y - container2.AbsoluteSize.Y)
		local v41 = math.max(1, container2.AbsoluteSize.Y * 0.05)
		local y = container2.CanvasPosition.Y

		if v40 - v41 <= y and os.clock() - lastTime > 0.75 and v7.page < v11 and not v12 then
			v12 = true
			v7.page += 1
			refreshWearRangeInSearchPayload() -- inferred equivalent call
			setLoading(true) -- inferred equivalent call
			sendMarketSearch() -- inferred equivalent call
			lastTime = os.clock()
		end
	end)
	GlobalMarketplace.ClearListing.Listen(function(childName: string)
		local child = folder.Market.Container:FindFirstChild(childName, true)

		if child then
			destroyListingCard(child)
		end

		removeYourListingByInventoryItemId(childName)
	end)

	local function bindRangeFilter(p, p2, maxValue: number, callback)
		bindSliderPin(p.Slider, p.Slider.StartPin, maxValue)
		bindSliderPin(p.Slider, p.Slider.EndPin, maxValue)
		p.Content.Inputs.StartPin.TextBox.FocusLost:Connect(function()
			setDrag(p2, p.Content.Inputs.StartPin.TextBox.Text, "StartPin", maxValue)
		end)
		p.Content.Inputs.EndPin.TextBox.FocusLost:Connect(function()
			local text = p.Content.Inputs.EndPin.TextBox.Text

			if callback then
				text = callback(text)
			end

			setDrag(p2, text, "EndPin", maxValue)
		end)
	end

	local function parseMaxInput(p: number) -- 2 equivalent calls inferred from this helper
		return function(value: string)
			return tonumber((string.gsub(value, ",", ""))) or p
		end
	end

	for _, v40 in CollectionService:GetTagged("pattern_range") do
		bindRangeFilter(v40, v40, 11, parseMaxInput(11)) -- inferred equivalent call
	end

	local price_range = folder.Market.Filters.Container.price_range

	for _, v40 in CollectionService:GetTagged("price_range") do
		bindRangeFilter(v40, price_range, Constants.MARKETPLACE_MAX_LISTING_PRICE, parseMaxInput(v2[2])) -- inferred equivalent call
	end

	setDrag(price_range, v2[2], "EndPin", Constants.MARKETPLACE_MAX_LISTING_PRICE)
	setDrag(price_range, v2[1], "StartPin", Constants.MARKETPLACE_MAX_LISTING_PRICE)

	for _, v40 in CollectionService:GetTagged("wear_range") do
		bindRangeFilter(v40, v40, 1)
	end

	setupWearTierButtons()
	local special_dropdown = folder.Market.Filters.Container:FindFirstChild("special_dropdown")
	local list = special_dropdown and special_dropdown:FindFirstChild("List")
	local killtrack = list and list:FindFirstChild("Killtrack")
	local button = killtrack and killtrack:FindFirstChild("Button")
	local imageLabel = button and button:FindFirstChild("ImageLabel")

	if button and button:IsA("GuiButton") and imageLabel and imageLabel:IsA("GuiObject") then
		MarketplaceButton.new(button, {
			hoverSizeMultiplier = 0.9,
			onActivated = function()
				imageLabel.Visible = not imageLabel.Visible
				v7.statTrak = imageLabel.Visible and true or nil
			end
		})
		v24 = imageLabel
	end

	for _, v40 in CollectionService:GetTagged("Dropdown_Category") do
		if not v40:IsDescendantOf(folder.Market.Filters.Container) then
			continue
		end

		local category = v40:GetAttribute("category")
		local guiObject = category and v40.Parent:FindFirstChild(category)

		if not (guiObject and guiObject:IsA("GuiObject")) then
			continue
		end

		local v41 = v40
		v40.Activated:Connect(function()
			guiObject.Visible = not guiObject.Visible
			local imageLabel2 = v41:FindFirstChild("ImageLabel")

			if imageLabel2 and imageLabel2:IsA("GuiObject") then
				imageLabel2.Rotation = guiObject.Visible and 180 or 0
			end
		end)
	end

	folder.Market.Filters.Container.Search.Frame.SearchBox:GetPropertyChangedSignal("Text"):Connect(schedulePredictSearch)
	folder.Market.Filters.Container.Search.Frame.SearchBox.FocusLost:Connect(function()
		folder.Market.Filters.Container.Search.Frame.Auto.Text = ""
		v7.search_bar_query = folder.Market.Filters.Container.Search.Frame.SearchBox.Text
	end)
	MarketplaceButton.new(folder.Market.Filters.Container.ApplyFilter, {
		hoverSizeMultiplier = 0.9,
		onActivated = function()
			refreshWearRangeInSearchPayload() -- inferred equivalent call
			showCategory()

			if os.clock() - now < 10 or folder.Market.Filters.Container.ApplyFilter.Frame.Timer.Visible then
				return
			end

			now = os.clock()
			v7.page = 1
			v12 = true
			sendMarketSearch() -- inferred equivalent call
			setLoading(true) -- inferred equivalent call
			folder.Market.Filters.Container.ApplyFilter.Frame.Timer.Visible = true

			for i = 10, 0, -1 do
				folder.Market.Filters.Container.ApplyFilter.Frame.Timer.Text = i
				task.wait(1)
			end

			folder.Market.Filters.Container.ApplyFilter.Frame.Timer.Visible = false
		end
	})

	if descendant2 then
		MarketplaceDropdown.new(descendant2, Constants.ITEM_CATEGORIES).OptionSelected:Connect(function(p)
			v35 = tostring(p)
			showCategory()
		end)
	end

	local descendant3 = CollectionServiceUtility.FindDescendantWithTag(
		folder.Market.Header.Filters,
		"Dropdown_SortType"
	)

	if descendant3 then
		local v40 = {}

		for _, v41 in Constants.MARKETPLACE_SORTING_OPTIONS do
			if v41 ~= "Equipped" then
				table.insert(v40, v41)
			end
		end

		MarketplaceDropdown.new(descendant3, v40).OptionSelected:Connect(function(p)
			v36 = tostring(p)
			showCategory()
		end)
	end

	local descendant4 = CollectionServiceUtility.FindDescendantWithTag(folder.Market.Header.Filters, "ReverseSort")

	if descendant4 then
		local function toggleReverseSorting()
			v37 = not v37
			local imageLabel2 = descendant4:FindFirstChildOfClass("ImageLabel")

			if imageLabel2 then
				imageLabel2.Rotation = v37 and 180 or 0
			end

			showCategory()
		end

		descendant4.Activated:Connect(toggleReverseSorting)
	end

	if descendant then
		local count4 = 0
		descendant:GetPropertyChangedSignal("Text"):Connect(function()
			count4 += 1
			local v40 = count4
			task.delay(0.12, function()
				if v40 ~= count4 then
					return
				end

				showCategory()
			end)
		end)
		descendant.FocusLost:Connect(function(_)
			showCategory()
		end)
	end
end

local function setupSell()
	clone2 = folder.Sell.SellInfo.Container.Template:Clone()
	folder.Sell.SellInfo.Container.Template:Destroy()

	local function confirmSell() -- 1 equivalent call inferred from this helper
		folder.Sell.Confirm.Visible = true
	end

	local function isSetPriceOpen() -- 2 equivalent calls inferred from this helper
		return v26 ~= nil and v26.Parent ~= nil
	end

	MarketplaceButton.new(folder.Sell.Confirm.Action.Frame.Accept, {
		hoverSizeMultiplier = 0.9,
		onActivated = function()
			local v33 = {}

			for _, v34 in v13 do
				table.insert(v33, v34)
			end

			if #v33 < 1 or not LocalPlayer:GetAttribute("PinVerified") then
				return
			end

			setLoading(true) -- inferred equivalent call
			GlobalMarketplace.ListItem.Send(v33)
			v12 = true
			v7.page = 1
			refreshWearRangeInSearchPayload() -- inferred equivalent call
			sendMarketSearch() -- inferred equivalent call
			folder.Sell.Confirm.Visible = false
		end
	})

	local function closeSellConfirm()
		folder.Sell.Confirm.Visible = false
	end

	MarketplaceButton.new(folder.Sell.Confirm.Action.Frame.Decline, {
		hoverSizeMultiplier = 0.9,
		onActivated = closeSellConfirm
	})
	CloseButtonRegistry.Add(folder.Sell.Confirm, nil, closeSellConfirm)
	GamepadNavigation.TrapPopup(folder.Sell.Confirm, function()
		return folder.Sell.Confirm.Action.Frame.Decline
	end)
	local v33 = 1
	local flag3 = false
	local count4 = 0

	local function generatePage(page: number)
		if flag3 then
			return
		end

		flag3 = true
		local v34 = count4
		local v35 = { page = page }

		for k, v36 in v18 do
			v35[k] = v36
		end

		local tradableInventoryPage = InventoryController:GetTradableInventoryPage(LocalPlayer, v35)

		if v34 ~= count4 or #tradableInventoryPage == 0 then
			flag3 = false
			return
		end

		for _, inventoryItem in tradableInventoryPage do
			if not inventoryItem._id then
				continue
			end

			local v37 = folder.Sell.Container:FindFirstChild(inventoryItem._id) ~= nil
			local marketListing = createMarketListing(folder.Sell.Container, inventoryItem._id, clone, {
				inventoryItem = inventoryItem
			})

			if not marketListing then
				continue
			end

			local inventoryItem2 = inventoryItem

			local function listItem(price: number)
				if v13[inventoryItem2._id] then
					return
				end

				v13[inventoryItem2._id] = {
					ItemID = inventoryItem2._id,
					Price = price,
					inventoryItem = inventoryItem2
				}
				marketListing.Visible = false
				local text2 = inventoryItem2.Skin:split("_PATTERN_")[1]
				local clone6 = clone2:Clone()
				clone6.Name = inventoryItem2._id
				clone6.Skin.Text = text2
				GetSkinDisplayName.ApplyNameLabel(
					clone6.Gun,
					GetSkinDisplayName.GetWeaponDisplayName(inventoryItem2.Name, inventoryItem2.NameTag),
					inventoryItem2.NameTag
				)
				clone6.Min.TextBox.Text = CommaNumber(price)
				clone6.GunSkin.ItemIcon.Image = marketListing.Main.ItemIcon.Image
				clone6.GunSkin.RarityFrame.RarityBarGradient.Color = marketListing.Main.RarityFrame.RarityBarGradient.Color
				clone6.GunSkin.Serial.SerialText.Text = marketListing.Main.RarityFrame.Serial.SerialText.Text
				clone6.GunSkin.Condition.Tag.Text = marketListing.Main.RarityFrame.Condition.Tag.Text
				clone6.GunSkin.Condition[`{marketListing.Main.RarityFrame.Condition.Tag.Text}Gradient`].Enabled = true
				clone6.Parent = folder.Sell.SellInfo.Container
				clone6.Min.TextBox.FocusLost:Connect(function()
					local text = tonumber(clone6.Min.TextBox.Text)

					if not text then
						clone6.Min.TextBox.Text = CommaNumber(v13[inventoryItem2._id].Price)
						return
					end

					local price2 = math.clamp(text, 1, Constants.MARKETPLACE_MAX_LISTING_PRICE)
					v13[inventoryItem2._id].Price = price2
					clone6.Min.TextBox.Text = CommaNumber(v13[inventoryItem2._id].Price)
				end)
				MarketplaceButton.new(clone6.Return, {
					hoverSizeMultiplier = 0.9,
					onActivated = function()
						v13[inventoryItem2._id] = nil
						clone6:Destroy()
						local child = folder.Sell.Container:FindFirstChild(inventoryItem2._id)

						if child then
							child.Visible = true
						end
					end
				})
			end

			marketListing.Visible = v13[inventoryItem._id] == nil
			marketListing.Main.Sell.Visible = not (inventoryItem.MetaData and inventoryItem.MetaData.GlobalMarketPlaceListingReference)
			marketListing.Main.Delist.Visible = not marketListing.Main.Sell.Visible

			if v37 or marketListing:GetAttribute("_sellActionsWired") then
				continue
			end

			marketListing:SetAttribute("_sellActionsWired", true)
			local v39 = inventoryItem
			MarketplaceButton.new(marketListing.Main.Sell, {
				hoverSizeMultiplier = 0.9,
				onActivated = function()
					if isSetPriceOpen() or v13[v39._id] then -- inferred equivalent call
						return
					end

					if v26 then
						v26:Destroy()
					end

					local v40 = 25
					local clone6 = folder.Sell.SetPrice:Clone()
					v26 = clone6
					clone6.Visible = true
					clone6.Parent = folder.Sell

					local function declineSetPrice()
						clone6:Destroy()
					end

					MarketplaceButton.new(clone6.Action.Frame.Decline, {
						hoverSizeMultiplier = 0.9,
						onActivated = declineSetPrice
					})
					CloseButtonRegistry.Add(clone6, nil, declineSetPrice)
					clone6.Destroying:Connect(function()
						CloseButtonRegistry.Remove(clone6)
					end)
					GamepadNavigation.TrapPopup(clone6, function()
						return clone6.Action.Frame.Accept
					end)
					MarketplaceButton.new(v26.Action.Frame.Accept, {
						hoverSizeMultiplier = 0.9,
						onActivated = function()
							listItem(v40)
							v26:Destroy()
							GamepadNavigation.Focus(folder.Sell.SellInfo.Sell)
						end
					})

					local function applyTypedPrice(text: number, flag4: boolean)
						v40 = math.clamp(text, 1, Constants.MARKETPLACE_MAX_LISTING_PRICE)
						local v41 = math.floor(v40 * (Constants.MARKET_TAX_PERCENT / 100))

						if flag4 then
							v26.Price.Frame.SearchBox.Text = CommaNumber(v40)
						end

						v26.List.ListedPrice.TextLabel.Text = CommaNumber(v40)
						v26.List.Tax.TextLabel.Text = `-{CommaNumber(v41)}`
						v26.List.Total.TextLabel.Text = CommaNumber(v40 - v41)
					end

					v26.Price.Frame.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
						local text = tonumber(v26.Price.Frame.SearchBox.Text)

						if text then
							applyTypedPrice(text, false)
						end
					end)
					v26.Price.Frame.SearchBox.FocusLost:Connect(function()
						local text = tonumber(v26.Price.Frame.SearchBox.Text)

						if text then
							applyTypedPrice(text, true)
						else
							v26.Price.Frame.SearchBox.Text = CommaNumber(v40)
						end
					end)
				end
			})
			local v40 = inventoryItem
			MarketplaceButton.new(marketListing.Main.Delist, {
				hoverSizeMultiplier = 0.9,
				onActivated = function()
					if not LocalPlayer:GetAttribute("PinVerified") then
						return
					end

					setLoading(true) -- inferred equivalent call
					GlobalMarketplace.DelistItem.Send(v40._id)
					removeYourListingByInventoryItemId(v40._id)
					local isSelectionWithin = MenuState.IsSelectionWithin(marketListing.Main.Delist)
					marketListing.Main.Sell.Visible = true
					marketListing.Main.Delist.Visible = false

					if isSelectionWithin then
						GamepadNavigation.Focus(marketListing.Main.Sell)
					end
				end
			})
		end

		v33 = page + 1
		pruneOldestListingFrames(folder.Sell.Container, 96)

		if v34 == count4 then
			flag3 = false
		end
	end

	folder.Sell.SetPrice.List.Tax.text.Text = `Tax ({Constants.MARKET_TAX_PERCENT}%)`
	local lastTime = os.clock()
	folder.Sell.Container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local v34 = math.max(0, folder.Sell.Container.AbsoluteCanvasSize.Y - folder.Sell.Container.AbsoluteSize.Y)
		local y = folder.Sell.Container.CanvasPosition.Y

		if v34 - 5 <= y and os.clock() - lastTime > 0.25 then
			generatePage(v33)
			lastTime = os.clock()
		end
	end)
	MarketplaceButton.new(folder.Sell.SellInfo.Sell, {
		hoverSizeMultiplier = 0.9,
		onActivated = function()
			if isSetPriceOpen() then -- inferred equivalent call
				return
			end

			confirmSell() -- inferred equivalent call
		end
	})
	GlobalMarketplace.ListItemResult.Listen(function(p)
		local flag4 = false

		if p and p.results then
			for _, result in p.results do
				if not result.success then
					continue
				end

				flag4 = true
				local inventoryItemId = result.inventoryItemId or result.inventory_item_id

				if typeof(inventoryItemId) ~= "string" then
					continue
				end

				if folder.Sell.SellInfo.Container:FindFirstChild(inventoryItemId) then
					folder.Sell.SellInfo.Container[inventoryItemId]:Destroy()
				end

				local listing_reference_id = result.listing_reference_id or result.listingReferenceId

				if typeof(listing_reference_id) == "string" and v13[inventoryItemId] then
					v13[inventoryItemId].listingReferenceId = listing_reference_id
				end

				syncListedItemToProfile(result)
				v13[inventoryItemId] = nil
				local child = folder.Sell.Container:FindFirstChild(inventoryItemId)

				if not child then
					continue
				end

				child.Visible = true
				child.Main.Sell.Visible = false
				child.Main.Delist.Visible = true
			end
		end

		if flag4 then
			GlobalMarketplace.RequestProfileInfo.Send(LocalPlayer.UserId)
		end

		showMarketplaceError(p) -- inferred equivalent call
	end)

	local function refreshInventory()
		count4 += 1
		flag3 = false
		folder.Sell.Container.CanvasPosition = Vector2.new(0, 0)

		for _, frame in folder.Sell.Container:GetChildren() do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end

		v33 = 1
		generatePage(v33)
	end

	local descendant = CollectionServiceUtility.FindDescendantWithTag(folder.Sell.Header.Filters, "Dropdown_Category")

	if descendant then
		MarketplaceDropdown.new(descendant, Constants.ITEM_CATEGORIES).OptionSelected:Connect(function(p)
			v18.filters = { "Tradable", "MarketplaceListable", p }
			refreshInventory()
		end)
	end

	local descendant2 = CollectionServiceUtility.FindDescendantWithTag(folder.Sell.Header.Filters, "Dropdown_SortType")

	if descendant2 then
		MarketplaceDropdown.new(descendant2, Constants.INVENTORY_SORTING_OPTIONS).OptionSelected:Connect(function(sort)
			v18.sort = sort
			refreshInventory()
		end)
	end

	local descendant3 = CollectionServiceUtility.FindDescendantWithTag(folder.Sell.Header.Filters, "ReverseSort")

	if descendant3 then
		local function toggleReverseSorting()
			v18.sortReversed = not v18.sortReversed
			local imageLabel = descendant3:FindFirstChildOfClass("ImageLabel")

			if imageLabel then
				imageLabel.Rotation = v18.sortReversed and 180 or 0
			end

			refreshInventory()
		end

		descendant3.Activated:Connect(toggleReverseSorting)
		local imageLabel = descendant3:FindFirstChildOfClass("ImageLabel")

		if imageLabel then
			imageLabel.Rotation = v18.sortReversed and 180 or 0
		end
	end

	local descendant4 = CollectionServiceUtility.FindDescendantWithTag(folder.Sell.Header.Filters, "SearchBox")

	if descendant4 then
		descendant4.FocusLost:Connect(function(_)
			v18.searchTerm = descendant4.Text
			refreshInventory()
		end)
	end

	GlobalMarketplace.RefreshInventory.Listen(function()
		refreshInventory()
	end)
	folder.Sell:GetPropertyChangedSignal("Visible"):Connect(function()
		if folder.Sell.Visible then
			refreshInventory()
		end
	end)
	refreshInventory()
end

local function setupProfile()
	clone3 = ReplicatedStorage.Assets.TradingUI.Templates.SaleTemplate:Clone()
	clone4 = ReplicatedStorage.Assets.TradingUI.Templates.ListingTemplate:Clone()
	clone5 = ReplicatedStorage.Assets.TradingUI.Templates.SaleTemplate_Old:Clone()
	folder.Profile.Main.Frame.YourListings.Transactions.Listings.Template:Destroy()
	local header = folder.Profile.Main.Frame.Header

	local function setProfileBadge(imageAssetId)
		local badge = folder.Profile.Main.ProfileInfo.Player:FindFirstChild("Badge")

		if badge and (badge:IsA("ImageLabel") or badge:IsA("ImageButton")) then
			badge.Image = not imageAssetId and "" or `rbxassetid://{imageAssetId}`
		end
	end

	local function filterListings(name: string)
		for _, frame in folder.Profile.Main.Frame.YourListings.Transactions.Listings:GetChildren() do
			if not (frame:IsA("Frame") and frame:FindFirstChild("State")) then
				continue
			end

			local visible

			if name == "ALL" or name == "SOLD" and frame.State.Text == "Sold" then
				visible = true
			elseif name == "PURCHASED" then
				visible = frame.State.Text == "Purchased"
			else
				visible = false
			end

			frame.Visible = visible
		end

		for _, button in folder.Profile.Main.Frame.YourListings.Transactions.TopSelect.Container:GetChildren() do
			if button:IsA("TextButton") then
				button.Frame.Visible = button.Name == name
			end
		end
	end

	GlobalMarketplace.ProfileInfo.Listen(function(data)
		if not data.success then
			return
		end

		for _, frame in folder.Profile.Main.Frame.YourListings.Transactions.Listings:GetChildren() do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end

		folder.Profile.Main.ProfileInfo.Earnings.List.Purchases.Credits.TextLabel.Text = CommaNumber(data.purchases)
		folder.Profile.Main.ProfileInfo.Earnings.List.Sales.Credits.TextLabel.Text = CommaNumber(data.sales_revenue)
		folder.Profile.Main.ProfileInfo.Earnings.List.Net.Credits.TextLabel.Text = CommaNumber(data.net_revenue)
		folder.Profile.Main.ProfileInfo.Earnings.List.Net.Credits.TextLabel.TextColor3 = data.net_revenue > 0
			and Color3.fromRGB(0, 255, 0)
			or Color3.fromRGB(255, 0, 0)

		for _, transaction in data.transactions do
			if folder.Profile.Main.Frame.YourListings.Transactions.Listings:FindFirstChild(transaction.listing_reference_id) then
				continue
			end

			local clone6 = clone5:Clone()
			clone6.Name = transaction.listing_reference_id
			clone6.State.Text = transaction.role == "seller" and "Sold" or "Purchased"
			local inventoryItem = transaction.inventoryItem
			local listing_reference_id = transaction.listing_reference_id

			if inventoryItem then
				local v33 = inventoryItem.StatTrack and true or false
				listing_reference_id = GetSkinDisplayName.GetFullItemDisplayName(
					inventoryItem.Name,
					inventoryItem.Skin,
					v33,
					true,
					inventoryItem.NameTag
				)

				if listing_reference_id == "" then
					listing_reference_id = `{v33 and "KillTrak™ " or ""}{GetSkinDisplayName.GetWeaponDisplayName(inventoryItem.Name, inventoryItem.NameTag)} | {inventoryItem.Skin}`
				end
			end

			GetSkinDisplayName.ApplyNameLabel(
				clone6.GunName,
				listing_reference_id,
				inventoryItem and inventoryItem.NameTag
			)
			clone6.Serial.Text = not (inventoryItem and inventoryItem.Serial) and "N/A"
				or `#{CommaNumber(inventoryItem.Serial)}`
			clone6.Date.Text = formatSaleDate(transaction.date)
			clone6.Credits.TextLabel.Text = CommaNumber(transaction.tradeTokens)
			clone6.Parent = folder.Profile.Main.Frame.YourListings.Transactions.Listings
			local visible

			if inventoryItem == nil then
				visible = false
			else
				visible = not itemTypeHidesInspect(inventoryItem.Type) -- inferred equivalent call
			end

			local info = clone6:FindFirstChild("Info")
			local extraHide = clone6:FindFirstChild("ExtraHide")

			if info and info:IsA("GuiButton") then
				info.Visible = visible

				if inventoryItem and visible then
					MarketplaceButton.new(info, {
						hoverSizeMultiplier = 0.9,
						onActivated = function()
							showInspect(inventoryItem)
						end
					})
				end
			end

			if extraHide and extraHide:IsA("GuiObject") then
				extraHide.Visible = not visible
			end
		end

		for _, listing in data.listings do
			if listing.inventoryItem then
				addYourListing(listing)
			end
		end

		local searchedUser = tonumber(data.SearchedUser) or LocalPlayer.UserId
		local fetched = UserCache.Fetch(searchedUser)
		folder.Profile.Main.ProfileInfo.Player.Player.Image = getHeadshot(searchedUser, Enum.ThumbnailSize.Size420x420) -- inferred equivalent call
		folder.Profile.Main.ProfileInfo.Player.DisplayName.Text = fetched.DisplayName
		folder.Profile.Main.ProfileInfo.Player.Username.Text = `@{fetched.Username}`
		setProfileBadge(data.equippedBadge and data.equippedBadge.imageAssetId)
		local last = folder.Profile.Main.ProfileInfo.Player.Last
		local status = data.status

		if status and status.isActiveSession then
			setOnlineStatus(last)
		elseif status and status.lastSessionAt then
			local lastSessionAt = status.lastSessionAt
			local formatted = `{os.date("%B", lastSessionAt)} {os.date("%d", lastSessionAt)}, {os.date("%Y", lastSessionAt)}`
			stopOnlineStatusPulse(last) -- inferred equivalent call
			last.Text = `Last Online: {formatted}`
			last.TextColor3 = Color3.fromRGB(136, 136, 136)
		else
			stopOnlineStatusPulse(last) -- inferred equivalent call
			last.Text = "Never Active"
			last.TextColor3 = Color3.fromRGB(100, 0, 0)
		end
	end)

	for _, button in folder.Profile.Main.Frame.YourListings.Transactions.TopSelect.Container:GetChildren() do
		if not button:IsA("TextButton") then
			continue
		end

		local v33 = button
		MarketplaceButton.new(button, {
			hoverSizeMultiplier = 0.9,
			onActivated = function()
				filterListings(v33.Name)
			end
		})
	end

	GlobalMarketplace.PurchasedItem.Listen(function(childName: string)
		GlobalMarketplace.RequestProfileInfo.Send(LocalPlayer.UserId)
		local child = folder.Market.Container:FindFirstChild(childName)

		if child then
			child:Destroy()
		end
	end)
	folder.Profile.Main.ProfileInfo.Player.Player.Image = getHeadshot( -- inferred equivalent call
		LocalPlayer.UserId,
		Enum.ThumbnailSize.Size420x420
	)
	folder.Profile.Main.ProfileInfo.Player.DisplayName.Text = LocalPlayer.DisplayName
	folder.Profile.Main.ProfileInfo.Player.Username.Text = `@{LocalPlayer.Name}`
	local v33 = { "Transactions", "YourListings" }

	for _, v34 in v33 do
		local v35 = v34
		MarketplaceButton.new(header.TopSelect.Container[v34], {
			hoverSizeMultiplier = 0.9,
			onActivated = function()
				for _, v36 in v33 do
					header.TopSelect.Container[v36].Frame.Visible = v36 == v35
					folder.Profile.Main.Frame.YourListings[v36].Visible = v36 == v35
				end

				for _, label in folder.Profile.Main.Frame.YourListings.Header:GetChildren() do
					if label:IsA("TextLabel") then
						label.Visible = v35 == "Transactions"
					end
				end
			end
		})
	end

	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Tab and v20 then
			local text = v20
			task.wait(0.1)
			folder.Market.Filters.Container.Search.Frame.SearchBox.Text = text
			v20 = nil
		end
	end)
end

local function fetchMarketOnOpen()
	if v5 or not (folder and v27) then
		return
	end

	v5 = true
	v7.page = 1
	setLoading(true) -- inferred equivalent call
	v12 = true
	refreshWearRangeInSearchPayload() -- inferred equivalent call
	sendMarketSearch() -- inferred equivalent call
end

local function focusMarketplaceOnOpen()
	if not folder.Visible or folder.Pin.Visible then
		return
	end

	local v33 = v25
	v25 = nil

	if MenuState.IsNavigationSelectionHeld() or MenuState.IsSelectionWithin(folder) then
		return
	end

	if v33 and GamepadNavigation.IsUsable(v33) and GamepadNavigation.Focus(v33) then
		return
	end

	local purchaseMenu = folder.Market.PurchaseMenu

	if purchaseMenu.Visible and GamepadNavigation.Focus(purchaseMenu) then
		return
	end

	for _, childName in v17 do
		if not folder[childName].Visible then
			continue
		end

		GamepadNavigation.Focus(folder.Top.Frame:FindFirstChild(childName))
		break
	end
end

local function closeMarketPopups() -- 1 equivalent call inferred from this helper
	v25 = nil
	id = nil

	if v19 then
		v19:Destroy()
		v19 = nil
	end

	folder.Market.PurchaseMenu.Confirm.Visible = false
	folder.Market.PurchaseMenu.Visible = false
	folder.Market.Confirm.Visible = false
	hideQuickPick()
	closeSellPopups() -- inferred equivalent call
end

local function onVisibilityChanged(visible: boolean)
	if not folder then
		return
	end

	if visible then
		local v33 = v23
		v23 = nil

		if not (v33 and selectQuickItem(v33.ItemName, v33.SkinName, v33.Details)) and not v5 and folder and v27 then
			v5 = true
			v7.page = 1
			setLoading(true) -- inferred equivalent call
			v12 = true
			refreshWearRangeInSearchPayload() -- inferred equivalent call
			sendMarketSearch() -- inferred equivalent call
		end

		folder.Pin.Visible = LocalPlayer:GetAttribute("PinVerified") == false
		task.defer(focusMarketplaceOnOpen)
	else
		v22 = nil
		v23 = nil

		if flag then
			flag = false
			resetQuickSearchFilters()
		end

		if not MenuState.IsInspectActive() then
			closeMarketPopups() -- inferred equivalent call
		end

		if v27 then
			folder.Pin.Visible = false
			MarketplaceHover:Close()
			setLoading(false) -- inferred equivalent call
		end
	end
end

local function isExcludedIndexSchema(p)
	return frozen[p.name] == true or frozen[p.type] == true
end

local function setQuickFilterDropdownSelection(p: string, p2: string) -- 6 equivalent calls inferred from this helper
	local v33 = v10[p]

	if v33 then
		v33:SelectOption(p2)
	end
end

local function setQuickPatternRange(p: string?)
	local v33 = tonumber(p)
	v7.pattern_range = v33 and { v33, v33 } or { 0, 11 }

	for _, v34 in CollectionService:GetTagged("pattern_range") do
		if v33 then
			setDrag(v34, v33, "StartPin", 11)
			setDrag(v34, v33, "EndPin", 11)
		else
			setDrag(v34, 0, "StartPin", 11)
			setDrag(v34, 11, "EndPin", 11)
		end
	end
end

local function setQuickWearTier(data, float: number?)
	local v33

	if float then
		v33 = Skins.GetWearNameForFloat(data, float)
	end

	for _, v34 in v14 do
		local v35 = v15
		local key = v34.key
		v35[key] = v33 ~= nil and v34.wear == v33
		setWearTierVisual(v34.key, v15[v34.key])
	end

	syncWearRangeFromTierSelection() -- inferred equivalent call
	refreshWearRangeInSearchPayload() -- inferred equivalent call
end

local function setQuickStatTrak(statTrak: boolean?) -- 5 equivalent calls inferred from this helper
	v7.statTrak = statTrak and true or nil

	if v24 then
		v24.Visible = statTrak == true
	end
end

local function clearQuickNarrowing()
	if not flag2 then
		return
	end

	flag2 = false

	for _, v33 in v14 do
		v15[v33.key] = false
		setWearTierVisual(v33.key, v15[v33.key])
	end

	syncWearRangeFromTierSelection() -- inferred equivalent call
	refreshWearRangeInSearchPayload() -- inferred equivalent call
	setQuickStatTrak() -- inferred equivalent call
end

resetQuickSearchFilters = function()
	v7.search_bar_query = ""
	v7.rarity = nil
	v7.Collection = nil
	v7.page = 1
	setQuickPatternRange(nil)

	if flag2 then
		flag2 = false

		for _, v33 in v14 do
			v15[v33.key] = false
			setWearTierVisual(v33.key, v15[v33.key])
		end

		syncWearRangeFromTierSelection() -- inferred equivalent call
		refreshWearRangeInSearchPayload() -- inferred equivalent call
		setQuickStatTrak() -- inferred equivalent call
	end

	if folder then
		folder.Market.Filters.Container.Search.Frame.SearchBox.Text = ""
		folder.Market.Filters.Container.Search.Frame.Auto.Text = ""
	end

	setQuickFilterDropdownSelection("collection_dropdown", "All") -- inferred equivalent call
	setQuickFilterDropdownSelection("rarity_dropdown", "All") -- inferred equivalent call
	v5 = false
end

local function dispatchQuickSearch()
	v7.page = 1
	v7.uiCategorySearch = true
	v12 = true
	v5 = true
	flag = true
	local isSelectionWithin = MenuState.IsSelectionWithin(folder.Market.Header.Guns)
	local v33 = v9
	hideQuickPick()

	if isSelectionWithin and v33 then
		GamepadNavigation.Focus(folder.Market.Header.Filters:FindFirstChild(v33))
	end

	setLoading(true) -- inferred equivalent call
	sendMarketSearch() -- inferred equivalent call
	v7.uiCategorySearch = nil
end

local function requestQuickItemSearch(skinInformation, p: string?, p2)
	local v33 = v7
	local collection

	if skinInformation.collection and skinInformation.collection ~= "" then
		collection = skinInformation.collection
	end

	v33.Collection = collection
	setQuickFilterDropdownSelection("collection_dropdown", v7.Collection or "All") -- inferred equivalent call
	v7.search_bar_query = skinInformation.paintId:gsub(" | ", " ")
	folder.Market.Filters.Container.Search.Frame.SearchBox.Text = v7.search_bar_query
	v7.rarity = skinInformation.rarity
	setQuickFilterDropdownSelection("rarity_dropdown", skinInformation.rarity) -- inferred equivalent call
	setQuickPatternRange(p)

	if p2 then
		flag2 = true
		setQuickWearTier(skinInformation, p2.Float)
		setQuickStatTrak(p2.StatTrak) -- inferred equivalent call
	elseif flag2 then
		flag2 = false

		for _, v35 in v14 do
			v15[v35.key] = false
			setWearTierVisual(v35.key, v15[v35.key])
		end

		syncWearRangeFromTierSelection() -- inferred equivalent call
		refreshWearRangeInSearchPayload() -- inferred equivalent call
		setQuickStatTrak() -- inferred equivalent call
	end

	dispatchQuickSearch()
end

local function requestQuickCaseSearch(case)
	v7.Collection = nil
	setQuickFilterDropdownSelection("collection_dropdown", "All") -- inferred equivalent call
	v7.search_bar_query = case.name
	folder.Market.Filters.Container.Search.Frame.SearchBox.Text = v7.search_bar_query
	v7.rarity = nil
	setQuickFilterDropdownSelection("rarity_dropdown", "All") -- inferred equivalent call

	if flag2 then
		flag2 = false

		for _, v33 in v14 do
			v15[v33.key] = false
			setWearTierVisual(v33.key, v15[v33.key])
		end

		syncWearRangeFromTierSelection() -- inferred equivalent call
		refreshWearRangeInSearchPayload() -- inferred equivalent call
		setQuickStatTrak() -- inferred equivalent call
	end

	v7.statTrak = nil
	v7.wear_range = { 0, 1 }
	setQuickPatternRange(nil)
	dispatchQuickSearch()
end

local function isQuickSearchable(p: string, p2: string) -- 1 equivalent call inferred from this helper
	return Skins.GetSkinInformation(p, p2) ~= nil or Cases.GetCaseByName(p2) ~= nil
end

selectQuickItem = function(p: string, p2: string, p3)
	local skinInformation = Skins.GetSkinInformation(p, p2)

	if skinInformation then
		local _, v33 = table.unpack(skinInformation.skin:split("_PATTERN_"))
		requestQuickItemSearch(skinInformation, v33, p3)
		return true
	else
		local case = Cases.GetCaseByName(p2)

		if not case then
			return false
		end

		requestQuickCaseSearch(case)
		return true
	end
end

function GlobalMarketPlace.SearchForItem(itemName: string, skinName: string, details)
	if not (folder and isQuickSearchable(itemName, skinName)) then -- inferred equivalent call
		return false
	end

	if folder.Visible then
		return selectQuickItem(itemName, skinName, details)
	end

	v23 = { ItemName = itemName, SkinName = skinName, Details = details }
	return true
end

function GlobalMarketPlace.SetReturnScreen(p: string?)
	v22 = p
end

local function buildGuns(p: string, p2: string)
	local guns = folder.Market.Header.Guns

	for _, button in guns.TopSelect.Container:GetChildren() do
		if button:IsA("TextButton") then
			button.Frame.Visible = button.Name == p2
		end
	end

	for _, button in guns.Frame:GetChildren() do
		if button:IsA("ImageButton") then
			button:Destroy()
		end
	end

	local v33 = {}

	for k, v34 in v8[p] do
		if not (p2 == "ALL" or k == p2) then
			continue
		end

		for _, v35 in v34 do
			table.insert(v33, v35)
		end
	end

	local v34 = {}

	for _, v35 in v33 do
		local _id = v35._id
		v34[_id] = getSkinValue(v35.Name, v35.Skin, v35.Float, false) or 0 -- inferred equivalent call
	end

	table.sort(v33, function(a, b)
		local v35 = v34[a._id] or 0
		local v36 = v34[b._id] or 0

		if v35 == v36 then
			return string.lower(`{a.Name} | {a.Skin}`) < string.lower(`{b.Name} | {b.Skin}`)
		end

		return v36 < v35
	end)

	for _, v35 in v33 do
		local skinInformation = Skins.GetSkinInformation(v35.Name, v35.Skin)

		if not skinInformation then
			continue
		end

		local v36, v37 = table.unpack(skinInformation.skin:split("_PATTERN_"))
		local rarityData = getRarityData(skinInformation.rarity)
		local clone6 = ReplicatedStorage.Assets.TradingUI.Templates.QuickTemplate:Clone()
		clone6.Name = v35._id
		local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(v35.Name, v35.NameTag)
		local applyNameLabel = GetSkinDisplayName.ApplyNameLabel
		local skin = clone6.Skin
		local v38

		if v37 then
			v38 = `{weaponDisplayName} | {v36} {v37}`
		else
			v38 = `{weaponDisplayName} | {v36}`
		end

		applyNameLabel(skin, v38, v35.NameTag)
		clone6.RarityBG.RarityBarGradient.Color = rarityData.ColorSequence
		clone6.RarityFrame.RarityBarGradient.Color = rarityData.ColorSequence
		local status = clone6.Status
		status.Text = `RAP: {formatSkinValue(getSkinValue(v35.Name, v35.Skin, v35.Float, false))}` -- inferred equivalent call
		local v40 = {
			Charm = false,
			Float = v35.Float or 0,
			IsTradeable = true,
			MetaData = {
				CreatedAt = os.time(),
				LastTradeAt = os.time(),
				TradeHistory = {},
				Origin = "Unboxed",
				OriginalOwner = LocalPlayer.UserId,
				Owner = LocalPlayer.UserId
			},
			Name = skinInformation.name,
			Skin = skinInformation.skin,
			Serial = 1,
			Pattern = tonumber(v37) or 1,
			Rarity = skinInformation.rarity,
			Type = skinInformation.type,
			__v = 0,
			_id = v35._id,
			StatTrack = false,
			NameTag = false,
			Stickers = {},
			HideWearDetails = true,
			ShowFullPriceRange = true
		}
		clone6.ItemIcon.Image = Skins.GetItemIconImage(skinInformation, v40)
		clone6.Active = true
		clone6.Selectable = true
		clone6.Parent = guns.Frame
		local userDescription = clone6.Tools:FindFirstChild("UserDescription")

		if userDescription and userDescription:IsA("GuiButton") then
			userDescription.Visible = true
			MarketplaceButton.new(userDescription, {
				hoverSizeMultiplier = 0.9,
				onActivated = function()
					MarketplaceHover:OpenTradeInfo(v40, clone6)
				end
			})

			if not UserInputService.TouchEnabled then
				userDescription.MouseEnter:Connect(function()
					MarketplaceHover:Open(v40, clone6)
				end)
				userDescription.MouseLeave:Connect(function()
					MarketplaceHover:Close(clone6)
				end)
			end
		end

		local inspect = clone6.Tools.Inspect
		local kind = v40.Type
		inspect.Visible = kind ~= "Case" and kind ~= "Package"
		local v41 = v35
		clone6.Activated:Connect(function()
			selectQuickItem(v41.Name, v41.Skin)
		end)
		MarketplaceButton.new(clone6.Tools.Inspect, {
			hoverSizeMultiplier = 0.9,
			onActivated = function()
				showInspect(v40)
			end
		})
	end
end

local function switchQuickTab(p: string)
	if not v8[p] then
		return
	end

	local guns = folder.Market.Header.Guns

	for _, button in guns.Frame:GetChildren() do
		if button:IsA("ImageButton") then
			button:Destroy()
		end
	end

	for _, button in guns.TopSelect.Container:GetChildren() do
		if button:IsA("TextButton") then
			button:Destroy()
		end
	end

	local v33 = {}

	for k in v8[p] do
		table.insert(v33, k)
	end

	table.sort(v33, function(a, b)
		return a == "ALL" or b ~= "ALL" and a:lower() < b:lower()
	end)

	for _, v34 in v33 do
		local clone6 = ReplicatedStorage.Assets.TradingUI.Templates.GunTemplate:Clone()
		clone6.LayoutOrder = v34 == "ALL" and 0 or 1
		clone6.Name = v34
		clone6.Title.Text = v34
		clone6.Parent = guns.TopSelect.Container
		local v35 = v34
		MarketplaceButton.new(clone6, {
			hoverSizeMultiplier = 0.9,
			onActivated = function()
				buildGuns(p, v35)
			end
		})
	end

	buildGuns(p, "ALL")
	guns.Frame.CanvasPosition = Vector2.zero
	guns.Visible = true
end

local function openQuickCategory(name: string)
	if not v8[name] then
		return false
	end

	v9 = name
	switchQuickTab(name)

	for _, button in folder.Market.Header.Filters:GetChildren() do
		if button:IsA("TextButton") then
			button.ImageLabel.Rotation = button.Name == name and 180 or 0
		end
	end

	return true
end

local function closeMarketplace()
	MarketplaceHover:Close()
	local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
	Top.openFrame(v22 or "Dashboard")
end

function GlobalMarketPlace:Initialize(p)
	folder = p
	local textLabel = folder.Top.TradeTokens:FindFirstChild("TextLabel")
	assert(textLabel and textLabel:IsA("TextLabel"), "Marketplace TradeTokens is missing its balance label")

	local function updateTradeTokensBalance(tradeTokens) -- 1 equivalent call inferred from this helper
		textLabel.Text = CommaNumber((math.floor(tonumber(tradeTokens) or 0)))
	end

	updateTradeTokensBalance(DataController.Get(LocalPlayer, "TradeTokens")) -- inferred equivalent call
	DataController.CreateListener(LocalPlayer, "TradeTokens", updateTradeTokensBalance)
	local success, policyInfoForPlayerAsync = pcall(
		PolicyService.GetPolicyInfoForPlayerAsync,
		PolicyService,
		LocalPlayer
	)

	if success and policyInfoForPlayerAsync then
		v6 = policyInfoForPlayerAsync.ArePaidRandomItemsRestricted == true
	end

	local parent = folder.Parent.Parent
	local hover = parent:FindFirstChild("Hover")

	if hover and hover:IsA("GuiObject") then
		MarketplaceHover:Initialize(hover, folder)
		MarketplaceHover.Start()
	else
		warn("Marketplace hover UI is missing from MainGui")
	end

	v27 = TweenService:Create(
		parent.Loading.Loading,
		TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 1e999),
		{ Rotation = 359 }
	)
	GlobalMarketplace.EndLoad.Listen(function()
		folder.Parent.Parent.Loading.Visible = false
		v27:Pause()
	end)
	CloseButtonRegistry.Add(folder, nil, closeMarketplace)
	setupProfile()
	setupMarket()
	setupSell()
	Skins.ObserveItemStockSchemas(function(items)
		v8 = {}

		for _, item in items do
			for _, v33 in item do
				if frozen[v33.name] == true or frozen[v33.type] == true or table.find(frozen3, v33.skin) then
					continue
				end

				local weaponProperties = GetWeaponProperties(v33.name)

				if not ((not weaponProperties or weaponProperties.Class ~= "Grenade") and Skins.IsSkinAvailable(v33.name, v33.skin)) then
					continue
				end

				local v35

				if weaponProperties then
					v35 = weaponProperties.Type
				else
					v35 = v33.type
				end

				local v36 = v33.type == "Glove" and "Glove" or v35

				if not (v33.rarity ~= "Stock" and v36) then
					continue
				end

				v8[v36] = v8[v36] or { ALL = {} }
				v8[v36][v33.name] = v8[v36][v33.name] or {}
				local v37 = v8[v36][v33.name]
				local v38 = {
					_id = `index_{v33.name}_{v33.skin}`,
					Float = v33.floatRange.min,
					Rarity = v33.rarity,
					Name = v33.name,
					Skin = v33.skin,
					Type = 0,
					HideWearDetails = true,
					ShowFullPriceRange = true
				}
				local v39

				if weaponProperties then
					v39 = weaponProperties.Class
				else
					v39 = v33.type
				end

				v38.Type = v39
				table.insert(v37, v38)
			end
		end
	end)
	local guns = folder.Market.Header.Guns

	local function closeQuickPick() -- 1 equivalent call inferred from this helper
		local v33 = v9
		local isSelectionWithin = MenuState.IsSelectionWithin(guns)
		hideQuickPick()

		if isSelectionWithin and v33 then
			GamepadNavigation.Focus(folder.Market.Header.Filters:FindFirstChild(v33))
		end
	end

	for _, button in folder.Market.Header.Filters:GetChildren() do
		if not button:IsA("TextButton") then
			continue
		end

		button.ImageLabel.Rotation = 0
		local v33 = button
		button.Activated:Connect(function()
			if v9 == v33.Name then
				closeQuickPick() -- inferred equivalent call
			elseif openQuickCategory(v33.Name) then
				task.defer(function()
					if guns.Visible then
						GamepadNavigation.Focus(GamepadNavigation.FindFirstSelectable(guns.Frame))
					end
				end)
			end
		end)
	end

	CloseButtonRegistry.Add(guns, nil, closeQuickPick)
	guns.SelectionGroup = true
	guns.SelectionBehaviorUp = Enum.SelectionBehavior.Escape
	guns.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	guns.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	guns.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	MenuState.RegisterBumperOverride(guns, function(flag3: boolean)
		local v33 = v9

		if not v33 then
			return false
		end

		local buttons = {}

		for _, button in guns.TopSelect.Container:GetChildren() do
			if button:IsA("TextButton") and button.Visible then
				table.insert(buttons, button)
			end
		end

		if #buttons == 0 then
			return false
		end

		table.sort(buttons, function(a, b)
			return a.AbsolutePosition.X < b.AbsolutePosition.X
		end)
		local v34 = 1

		for k, v36 in buttons do
			if not v36.Frame.Visible then
				continue
			end

			v34 = k
			break
		end

		local v36 = buttons[(v34 - 1 + (flag3 and -1 or 1)) % #buttons + 1]
		buildGuns(v33, v36.Name)
		guns.Frame.CanvasPosition = Vector2.zero
		GamepadNavigation.Focus(v36)
		return true
	end, guns)
	GlobalMarketplace.RequestProfileInfo.Send(LocalPlayer.UserId)
	local textBox = folder.Market.Filters.Container.seller_id.Inputs.Id.TextBox
	textBox.FocusLost:Connect(function()
		if tonumber(textBox.Text) then
			v7.sellerUserId = tonumber(textBox.Text)
			return
		end

		if v7.sellerUserId then
			v7.sellerUserId = nil
		end

		textBox.Text = ""
	end)

	local function buildCollectionOptions(items)
		local names = { "All" }

		for _, item in items do
			if item.name ~= "First Edition" then
				table.insert(names, item.name)
			end
		end

		return names
	end

	local container = folder.Market.Filters.Container
	local rarity_dropdown = container:FindFirstChild("rarity_dropdown")
	local dropdown = rarity_dropdown and rarity_dropdown:FindFirstChild("Dropdown")

	if dropdown and dropdown:IsA("GuiButton") then
		local v33 = { "All" }

		for k in Rarities do
			table.insert(v33, k)
		end

		table.sort(v33, function(a, b)
			return a == "All" or b ~= "All" and a:lower() < b:lower()
		end)
		local rarity_dropdown2 = MarketplaceDropdown.new(dropdown, v33)
		v10.rarity_dropdown = rarity_dropdown2
		rarity_dropdown2.OptionSelected:Connect(function(rarity)
			local v35 = v7

			if rarity == "All" then
				rarity = nil
			end

			v35.rarity = rarity
		end)
	end

	local dropdown2 = container.collection_dropdown.Dropdown

	if dropdown2 and dropdown2:IsA("GuiButton") then
		local function applyCollectionOptionLayoutOrder(items)
			local dropdown3 = dropdown2:FindFirstChild("Dropdown")

			if not dropdown3 then
				return
			end

			for _, item in items do
				local guiObject = dropdown3:FindFirstChild(item.name)

				if guiObject and guiObject:IsA("GuiObject") then
					guiObject.LayoutOrder = tonumber(item.createdAt) or 0
				end
			end
		end

		local allCollections = Collections.GetAllCollections()
		local collection_dropdown = MarketplaceDropdown.new(dropdown2, (buildCollectionOptions(allCollections)))
		v10.collection_dropdown = collection_dropdown
		applyCollectionOptionLayoutOrder(allCollections)
		collection_dropdown.OptionSelected:Connect(function(collection)
			local v34 = v7

			if collection == "All" or not collection then
				collection = nil
			end

			v34.Collection = collection
		end)
		Collections.ObserveAvailableCollections(function(p2)
			collection_dropdown:SetOptions((buildCollectionOptions(p2)))
			applyCollectionOptionLayoutOrder(p2)
		end)
	end

	for _, button in folder.Top.Frame:GetChildren() do
		if not button:IsA("TextButton") then
			continue
		end

		local v33 = button
		MarketplaceButton.new(button, {
			hoverSizeMultiplier = 0.9,
			onActivated = function()
				local name = v33.Name

				for _, v34 in v17 do
					folder[v34].Visible = v34 == name
				end

				if name ~= "Market" then
					hideQuickPick()
				end

				if name ~= "Sell" then
					closeSellPopups() -- inferred equivalent call
				end
			end
		})
	end

	folder.Profile.Main.ProfileInfo.Search.SearchBox.FocusLost:Connect(function()
		local text = folder.Profile.Main.ProfileInfo.Search.SearchBox.Text
		local v33 = tonumber(text)

		if not v33 and text ~= "" then
			local success2, userIdFromNameAsync = pcall(Players.GetUserIdFromNameAsync, Players, text)

			if success2 then
				v33 = userIdFromNameAsync or v33
			end
		end

		folder.Profile.Main.ProfileInfo.Search.SearchBox.Text = not v33 and "Search User..." or tostring(v33)

		if v33 then
			GlobalMarketplace.RequestProfileInfo.Send(v33)
		end
	end)
	local v33 = 3
	local v34 = ""
	local pin = folder.Pin
	pin.Active = false
	local clone6 = pin.SetupCode.Main.Wrap.Settings_List.Pin_Setup_Template.Main.Pin_Setup.Wrap.Pin_Holder["1"]:Clone()

	local function formatPin(pin_Holder, value: string)
		for _, frame in pin_Holder:GetChildren() do
			if frame:IsA("Frame") and frame.Name ~= "Ghost_Template" then
				frame:Destroy()
			end
		end

		local ghost_Template = pin_Holder.Ghost_Template
		ghost_Template.Visible = value:len() >= 4 and value:len() < 8

		for i = 1, math.clamp(value:len(), 4, 8) do
			local clone7 = clone6:Clone()
			clone7.Slot_Filled.Visible = i <= value:len()
			clone7.Slot_Empty.Visible = not clone7.Slot_Filled.Visible

			if clone7.Slot_Filled.Visible then
				clone7.Slot_Filled.TextLabel.Text = "*"
			end

			clone7.Parent = pin_Holder
		end
	end

	local function submitPin()
		if v34:len() < 4 or v34:len() > 8 then
			return
		end

		Remotes.PlayerData.SubmitPin.Send(v34)
		v33 -= 1
		pin.InputCode.Wrap.Title.Text = `Enter your PIN number ({v33} attempts left)`
		v34 = ""
		formatPin(pin.InputCode.Wrap.Pin_Holder, v34)
	end

	local function setupInput()
		for _, button in pin.InputCode.Wrap.Number_Pad:GetChildren() do
			if not (button:IsA("TextButton") and button.Name ~= "Submit") then
				continue
			end

			local v35 = button
			MarketplaceButton.new(button, {
				onActivated = function()
					if v35.Name == "Backspace" and v34:len() > 0 then
						v34 = v34:sub(1, #v34 - 1)
					elseif v35.Name ~= "Backspace" and v34:len() < 8 then
						v34 ..= v35.Title.Text
					end

					formatPin(pin.InputCode.Wrap.Pin_Holder, v34)
				end
			})
		end

		MarketplaceButton.new(pin.InputCode.Wrap.Number_Pad.Submit, { onActivated = submitPin })
	end

	setupInput()
	UserInputService.InputBegan:Connect(function(input)
		if not pin.Visible then
			return
		end

		if v[input.KeyCode] or input.KeyCode == Enum.KeyCode.Backspace then
			if Enum.KeyCode.Backspace == input.KeyCode and v34:len() > 0 then
				v34 = v34:sub(1, #v34 - 1)
			elseif Enum.KeyCode.Backspace == input.KeyCode or not (v34:len() < 8) then
				return
			else
				v34 ..= v[input.KeyCode]
			end

			formatPin(pin.InputCode.Wrap.Pin_Holder, v34)
		elseif
			(input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.KeypadEnter)
			and pin.InputCode.Visible
		then
			submitPin()
		end
	end)
	pin.Visible = folder.Visible and LocalPlayer:GetAttribute("PinVerified") == false
	LocalPlayer:GetAttributeChangedSignal("PinVerified"):Connect(function()
		pin.Visible = folder.Visible and LocalPlayer:GetAttribute("PinVerified") == false
	end)
	GamepadNavigation.TrapPopup(pin)
	MenuState.RegisterBumperOverride(folder, function(flag3: boolean)
		local sell = folder.Sell

		if pin.Visible or sell.Visible and (sell.Confirm.Visible or v26 ~= nil and v26.Parent ~= nil) then
			return true
		end

		local v35 = 1

		for k, v37 in v17 do
			if not folder[v37].Visible then
				continue
			end

			v35 = k
			break
		end

		local v37 = v17[(v35 - 1 + (flag3 and -1 or 1)) % #v17 + 1]

		for _, v38 in v17 do
			folder[v38].Visible = v38 == v37
		end

		if v37 ~= "Market" then
			hideQuickPick()
		end

		if v37 ~= "Sell" then
			closeSellPopups() -- inferred equivalent call
		end

		GamepadNavigation.Focus(folder.Top.Frame:FindFirstChild(v37))
		return true
	end, folder)

	for _, button in folder:GetDescendants() do
		if not (button:IsA("TextButton") and (button.Name == "Search" or button.Name == "Price") and button:FindFirstChildWhichIsA("TextBox", true)) then
			continue
		end

		button.Selectable = false
	end

	folder:GetPropertyChangedSignal("Visible"):Connect(function()
		onVisibilityChanged(folder.Visible)
	end)
	MenuState.OnInspectStateChanged:Connect(function(flag3: boolean)
		if flag3 then
			return
		end

		task.defer(function()
			if not (folder.Visible or MenuState.IsInspectActive()) then
				v25 = nil
				id = nil

				if v19 then
					v19:Destroy()
					v19 = nil
				end

				folder.Market.PurchaseMenu.Confirm.Visible = false
				folder.Market.PurchaseMenu.Visible = false
				folder.Market.Confirm.Visible = false
				hideQuickPick()
				closeSellPopups() -- inferred equivalent call
			end
		end)
	end)
	onVisibilityChanged(folder.Visible)
end

return GlobalMarketPlace