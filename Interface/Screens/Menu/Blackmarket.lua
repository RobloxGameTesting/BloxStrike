local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local CommaNumber = require(ReplicatedStorage.Components.Common.CommaNumber)
local BlackMarketSceneController = require(ReplicatedStorage.Controllers.BlackMarketSceneController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local MenuSceneController = require(ReplicatedStorage.Controllers.MenuSceneController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local InspectController = require(ReplicatedStorage.Controllers.InspectController)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local DevProducts = require(ReplicatedStorage.Database.Custom.GameStats.Monetization.DevProducts)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local GamepadNavigation = require(ReplicatedStorage.Interface.GamepadNavigation)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local BlackMarketDealer = Remotes.BlackMarketDealer
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 1e999)
local v = {
	[Enum.KeyCode.DPadUp] = true,
	[Enum.KeyCode.DPadDown] = true,
	[Enum.KeyCode.DPadLeft] = true,
	[Enum.KeyCode.DPadRight] = true
}
local tweenInfo2 = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local color = Color3.fromRGB(255, 244, 200)
local tweenInfo3 = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfo4 = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local tweenInfo5 = TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local random = Random.new()
local v2 = {}
local v3 = false
local devProductId = nil
local v4 = false
local v5 = nil
local v6 = nil
local v7 = nil
local v8 = nil
local v9 = { case = true, package = true, console = true }
local v10 = {}
local v11 = nil
local v12 = {}
local v13 = nil
local v14 = nil
local v15 = nil
local v16 = {}
local v17 = -1e999
local v18 = nil
local v19 = {}
local v20 = nil
local v21 = nil
local v22 = {}
local v23 = {}
local buttonsBySlot = {}
local buttonsBySlot2 = {}
local v24 = {}
local slot = nil
local v25 = nil
local v26 = false
local v27 = {}
local connection = nil
local connection2 = nil
local flag = false
local v28 = false
local v29 = false
local count = 0
local v30 = true
local v31 = {}
local total = 0
local connection3 = nil
local Blackmarket = {}
local v32 = nil

for k, devProduct in DevProducts do
	local v33 = string.match(k, "^%+ ([%d,]+) Trade Tokens$")

	if not (v33 and typeof(devProduct) == "table" and typeof(devProduct.DevProductId) == "number") then
		continue
	end

	table.insert(v2, {
		Amount = tonumber((string.gsub(v33, ",", ""))),
		DevProductId = devProduct.DevProductId
	})
end

table.sort(v2, function(a, b)
	return a.Amount < b.Amount
end)
local v33 = false

local function notify(p: string) -- 7 equivalent calls inferred from this helper
	Router.broadcastRouter("CreateNotification", "Black Market", p, 5)
end

local function isPointerBlocked() -- 2 equivalent calls inferred from this helper
	return v3 or devProductId ~= nil or v4 or GuiService.MenuIsOpen
end

local function setWaitingForDeal(visible: boolean)
	local v34 = v5

	if not v34 or visible == v33 then
		return
	end

	v33 = visible
	v34.Visible = visible
	local v35 = v6

	if not v35 then
		return
	end

	if visible then
		v35:Play()
	elseif v7 then
		v35:Cancel()
		v7.Rotation = 0
	end
end

local function setNavigationVisible(visible: boolean)
	local top = v8 and v8:FindFirstChild("Top")

	if not top then
		return
	end

	for _, childName in ipairs({ "Top", "Bottom" }) do
		local guiObject = top:FindFirstChild(childName)

		if guiObject and guiObject:IsA("GuiObject") then
			guiObject.Visible = visible
		end
	end
end

local function escapeRichText(name: string) -- 1 equivalent call inferred from this helper
	return (name:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function getRarityColor(p: string?) -- 2 equivalent calls inferred from this helper
	local v34 = p and Rarities[p]
	return v34 and v34.Color or Rarities.Stock.Color
end

local function formatCountdown(p: number) -- 1 equivalent call inferred from this helper
	local v34 = math.max(math.floor(p), 0)
	return string.format("%02d:%02d:%02d", v34 // 3600, v34 % 3600 // 60, v34 % 60)
end

local function canInspectCard(card) -- 1 equivalent call inferred from this helper
	if v9[tostring(card.offerKind)] or typeof(card.float) ~= "number" then
		return false
	end

	return Skins.GetSkinInformation(card.name, card.skin) ~= nil
end

local function isCardPurchased(card) -- 2 equivalent calls inferred from this helper
	if v10[tostring(card.cardId)] then
		return true
	end

	return (typeof(v11) ~= "table" or v11.buyEnabled ~= false) and card.status ~= "available"
end

local function toPreviewItem(card)
	return {
		_id = card.cardId,
		Type = card.type,
		Name = card.name,
		Skin = card.skin,
		Rarity = card.rarity,
		Float = card.float,
		StatTrack = card.isStattrak and 0 or false,
		Serial = 0,
		IsTradeable = true,
		NameTag = false,
		Charm = false,
		Stickers = {},
		MetaData = {
			Owner = LocalPlayer.UserId,
			OriginalOwner = LocalPlayer.UserId,
			CreatedAt = os.time(),
			LastTradeAt = 0,
			TradeHistory = {},
			Origin = "Other"
		}
	}
end

local function resolveCardImage(p, p2, flag2: boolean)
	if not p2 then
		local case = Cases.GetCaseByName(p.skin)
		return case and case.imageAssetId or ""
	end

	local v34

	if flag2 then
		v34 = Skins.GetWearImageForFloat(p2, p.float) or nil
	end

	return v34 or p2.imageAssetId or ""
end

local function tintCard(back, rarity: string?)
	local rarityColor = getRarityColor(rarity) -- inferred equivalent call
	local bg = back:FindFirstChild("BG")

	if bg and bg:IsA("ImageLabel") then
		bg.ImageColor3 = rarityColor
	end

	local pattern = back:FindFirstChild("Pattern")

	if pattern and pattern:IsA("ImageLabel") then
		pattern.ImageColor3 = rarityColor
	end

	local effects = back:FindFirstChild("Effects")
	local effect = effects and effects:FindFirstChild("Effect")

	if effect and effect:IsA("ImageLabel") then
		effect.ImageColor3 = rarityColor
	end

	local itemTemplate = back:FindFirstChild("ItemTemplate")

	if not itemTemplate then
		return
	end

	local uiShadow = itemTemplate:FindFirstChildOfClass("UIShadow")

	if uiShadow then
		uiShadow.Color = rarityColor
	end

	local glow = itemTemplate:FindFirstChild("Glow")

	if glow and glow:IsA("ImageLabel") then
		glow.ImageColor3 = rarityColor
	end

	local itemContent = itemTemplate:FindFirstChild("ItemContent")
	local content = itemContent and itemContent:FindFirstChild("Content")
	local rarity2 = content and content:FindFirstChild("Rarity")

	if rarity2 and rarity2:IsA("ImageLabel") then
		rarity2.ImageColor3 = rarityColor
	end
end

local function renderSlot(state, card)
	state.Card = card

	if not card then
		BlackMarketSceneController.SetCardVisible(state.Part, false)
		return
	end

	BlackMarketSceneController.SetCardVisible(state.Part, true)
	local back = state.Back
	local skinInformation = Skins.GetSkinInformation(card.name, card.skin)
	local v34 = not v9[tostring(card.offerKind)] and typeof(card.float) == "number"
	tintCard(back, card.rarity)
	local itemTemplate = back:FindFirstChild("ItemTemplate")
	local itemContent = itemTemplate and itemTemplate:FindFirstChild("ItemContent")
	local content = itemContent and itemContent:FindFirstChild("Content")
	local icon = content and content:FindFirstChild("Icon")

	if icon and icon:IsA("ImageLabel") then
		local imageAssetId

		if skinInformation then
			local v35

			if v34 then
				v35 = Skins.GetWearImageForFloat(skinInformation, card.float) or nil
			end

			imageAssetId = v35 or skinInformation.imageAssetId or ""
		else
			local case = Cases.GetCaseByName(card.skin)
			imageAssetId = case and case.imageAssetId or ""
		end

		icon.Image = imageAssetId
	end

	local inspect = itemContent and itemContent:FindFirstChild("Inspect")

	if inspect and inspect:IsA("GuiObject") then
		inspect.Visible = canInspectCard(card) -- inferred equivalent call
	end

	local bottom = back:FindFirstChild("Bottom")

	if bottom then
		local skin = bottom:FindFirstChild("Skin")

		if skin and skin:IsA("TextLabel") then
			local name = GetSkinDisplayName.GetFullItemDisplayName(card.name, card.skin, false, true)

			if name == "" then
				local case = Cases.GetCaseByName(card.skin)

				if case then
					name = case.name
				else
					name = `{GetSkinDisplayName.GetWeaponDisplayName(card.name)} | {GetSkinDisplayName.GetSkinDisplayName(card.skin, true)}`
				end
			end

			skin.RichText = true
			local text = escapeRichText(name) -- inferred equivalent call

			if card.isStattrak then
				text = `<font color="rgb(255,132,32)">KillTrak™</font> {text}`
			end

			skin.Text = text
		end

		local rap = bottom:FindFirstChild("RAP")

		if rap and rap:IsA("TextLabel") then
			rap.Text = `RAP: {CommaNumber((math.floor(tonumber(card.rapPrice) or 0)))}`
		end

		local floatNumber = bottom:FindFirstChild("FloatNumber")

		if floatNumber and floatNumber:IsA("TextLabel") then
			floatNumber.Visible = true
			floatNumber.Text = not v34 and "" or string.format("%.13f", card.float)
		end

		if rap and floatNumber then
			rap.LayoutOrder = v34 and 3 or 1
			floatNumber.LayoutOrder = v34 and 1 or 3
		end

		local v35

		if typeof(v11) == "table" then
			v35 = v11.buyEnabled == false
		else
			v35 = false
		end

		local v36

		if card.status == "available" then
			v36 = not v35
		else
			v36 = false
		end

		local cardPurchased = isCardPurchased(card) -- inferred equivalent call
		local interact = bottom:FindFirstChild("Interact")
		local buy = interact and interact:FindFirstChild("Buy")
		local amount = buy and buy:FindFirstChild("Amount")

		if amount and amount:IsA("TextLabel") then
			amount.Text = cardPurchased and "PURCHASED"
				or `BUY ({CommaNumber((math.floor(tonumber(card.price) or 0)))})`
		end

		local decline = interact and interact:FindFirstChild("Decline")

		if decline and decline:IsA("GuiObject") then
			decline.Visible = false
		end

		local buyWideLayout = state.BuyWideLayout

		if buy and buy:IsA("GuiObject") then
			if buyWideLayout then
				buy.Position = buyWideLayout.Position
				buy.Size = buyWideLayout.Size
			end

			buy.Visible = v36 or cardPurchased
		end
	end

	local discount = back:FindFirstChild("Discount")
	local title = discount and discount:FindFirstChild("Title")
	local discount2 = tonumber(card.discount) or 0

	if discount and discount:IsA("GuiObject") then
		discount.Visible = discount2 > 0
	end

	if title and title:IsA("TextLabel") then
		title.Text = `- {math.floor(discount2 * 100 + 0.5)}%`
	end

	local v35 = v12[tostring(card.cardId)]

	if v35 == nil then
		v35 = isCardPurchased(card) and true or nil -- inferred equivalent call
	end

	if v35 ~= nil then
		BlackMarketSceneController.SetCardFaceUp(state.Part, v35, false)
	end
end

local function updateCountdown()
	local v34 = v13

	if not v34 then
		return
	end

	local v35 = formatCountdown(v34 - os.clock()) -- inferred equivalent call

	if v35 == v14 then
		return
	end

	v14 = v35
	local title = v15:FindFirstChild("Title")

	if title and title:IsA("TextLabel") then
		title.Text = `<font color="rgb(255,223,0)">{v35}</font> LEFT`
	end

	for _, v36 in v16 do
		local expires = v36.Card and v36.Back:FindFirstChild("Expires")
		local textLabel = expires and expires:FindFirstChild("TextLabel")

		if textLabel and textLabel:IsA("TextLabel") then
			textLabel.Text = `<font color="rgb(167,167,167)">EXPIRES IN</font> <font color="rgb(255,255,255)">{v35}</font>`
		end
	end
end

local function setDealDeadline(p)
	local msRemaining = typeof(p) == "table" and tonumber(p.msRemaining) or nil
	local v34

	if msRemaining then
		v34 = os.clock() + msRemaining / 1000
	end

	v13 = v34
	v14 = nil
end

local function preloadCardArt()
	local icons = {}

	for _, v34 in v16 do
		local itemTemplate = v34.Back:FindFirstChild("ItemTemplate")
		local itemContent = itemTemplate and itemTemplate:FindFirstChild("ItemContent")
		local content = itemContent and itemContent:FindFirstChild("Content")
		local icon = content and content:FindFirstChild("Icon")

		if icon and icon:IsA("ImageLabel") and icon.Image ~= "" then
			table.insert(icons, icon)
		end
	end

	if #icons > 0 then
		task.spawn(function()
			ContentProvider:PreloadAsync(icons)
		end)
	end
end

local function dealSignature(p)
	if typeof(p) ~= "table" or typeof(p.cards) ~= "table" then
		return ""
	end

	local v34 = {}

	for k, card in p.cards do
		v34[k] = tostring(typeof(card) ~= "table" and "" or card.cardId or "")
	end

	return table.concat(v34, "|")
end

local function renderDeal(p)
	v11 = p
	local cards = typeof(p) == "table" and typeof(p.cards) == "table" and p.cards or {}

	for k, v34 in v16 do
		renderSlot(v34, cards[k])
	end

	BlackMarketSceneController.NotifyDealRendered()
	preloadCardArt()
	v14 = nil
	updateCountdown()
end

local function requestDeal() -- 2 equivalent calls inferred from this helper
	if v13 and v13 - os.clock() > 0 then
		return
	end

	local now = os.clock()

	if now - v17 < 10 then
		return
	end

	v17 = now
	BlackMarketDealer.RequestDeal.Send()
end

local function regionRect(p)
	local element = p.Element
	local absolutePosition = element.AbsolutePosition
	local absoluteSize = element.AbsoluteSize
	local scale = p.Scale.Scale

	if scale <= 0 or scale >= 1 then
		return absolutePosition, absoluteSize
	end

	local anchorPoint = element.AnchorPoint
	local v34 = absoluteSize / scale
	return absolutePosition + absoluteSize * anchorPoint - v34 * anchorPoint, v34
end

local function regionBounds(p, p2)
	local absoluteSize = p.Back.AbsoluteSize

	if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
		return nil, nil
	end

	local element = p2.Element
	local absolutePosition = element.AbsolutePosition
	local absoluteSize2 = element.AbsoluteSize
	local scale = p2.Scale.Scale
	local v34

	if scale <= 0 or scale >= 1 then
		v34 = absoluteSize2
	else
		local anchorPoint = element.AnchorPoint
		v34 = absoluteSize2 / scale
		absolutePosition = absolutePosition + absoluteSize2 * anchorPoint - v34 * anchorPoint
	end

	local v35 = absolutePosition - p.Back.AbsolutePosition
	return v35 / absoluteSize, (v35 + v34) / absoluteSize
end

local function isRegionVisible(parent, back)
	while parent and parent ~= back do
		if parent:IsA("GuiObject") and not parent.Visible then
			return false
		else
			parent = parent.Parent
		end
	end

	return true
end

local function projectCardRect(part, point: Vector2, point2: Vector2, flag2: boolean)
	local currentCamera = workspace.CurrentCamera

	if not currentCamera then
		return nil, nil, false
	end

	local size = part.Size
	local cframe = part.CFrame
	local v34 = 1e999
	local v35 = -1e999
	local v36 = 1e999
	local v37 = -1e999
	local x = 0
	local x2 = 0

	for i = 1, 4 do
		local v38 = i == 2 or i == 3
		local v39 = i == 3 or i == 4
		local x3

		if v38 then
			x3 = point2.X
		else
			x3 = point.X
		end

		local y

		if v39 then
			y = point2.Y
		else
			y = point.Y
		end

		local v40

		if flag2 then
			v40 = 0.5 - x3
		else
			v40 = x3 - 0.5
		end

		local worldToViewportPoint = currentCamera:WorldToViewportPoint(cframe:PointToWorldSpace((Vector3.new(v40 * size.X, (0.5 - y) * size.Y, 0))))

		if worldToViewportPoint.Z <= 0 then
			return nil, nil, false
		end

		v34 = math.min(v34, worldToViewportPoint.X)
		v35 = math.max(v35, worldToViewportPoint.X)
		v36 = math.min(v36, worldToViewportPoint.Y)
		v37 = math.max(v37, worldToViewportPoint.Y)

		if i == 1 then
			x = worldToViewportPoint.X
		elseif i == 2 then
			x2 = worldToViewportPoint.X
		end
	end

	return Vector2.new(v34, v36), Vector2.new(v35 - v34, v37 - v36), x < x2
end

local function setHoveredRegion(data) -- 4 equivalent calls inferred from this helper
	if v18 == data then
		return
	end

	local v34 = v18
	v18 = data

	if v34 then
		v34.HoverOut:Play()
	end

	if data then
		data.HoverIn:Play()
		Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
	end
end

local function clearCardHover()
	local function rest(data) -- 2 equivalent calls inferred from this helper
		data.HoverIn:Cancel()
		data.HoverOut:Cancel()
		data.Press:Cancel()
		data.Scale.Scale = 1
	end

	for _, v34 in v16 do
		for _, region in v34.Regions do
			rest(region) -- inferred equivalent call
		end

		if v34.FlipRegion then
			rest(v34.FlipRegion) -- inferred equivalent call
		end
	end

	v18 = nil
end

local function pressRegion(data) -- 1 equivalent call inferred from this helper
	data.Press:Play()
	task.delay(0.15, function()
		if v18 == data then
			data.HoverIn:Play()
		else
			data.HoverOut:Play()
		end
	end)
end

local function isCardDiscontinued(card) -- 1 equivalent call inferred from this helper
	if typeof(card) ~= "table" then
		return false
	end

	local case = Cases.GetCaseByName(card.skin)

	if case then
		return not Cases.IsCaseForSale(case.caseId)
	end

	return false
end

local function flipCardUp(state)
	BlackMarketSceneController.SetCardFaceUp(state.Part, true, true)
	local cardId = tostring(state.Card.cardId)

	if not BlackMarketSceneController.IsCardFaceUp(state.Part) or v19[cardId] then
		return
	end

	v19[cardId] = true

	if isCardDiscontinued(state.Card) then -- inferred equivalent call
		BlackMarketSceneController.PlayDiscontinuedLine()
	else
		BlackMarketSceneController.PlayRarityLine(state.Card.rarity)
	end
end

local function promptTradeTokens(p: number)
	if v3 or devProductId or v4 then
		return
	end

	local v34 = nil

	for _, v36 in v2 do
		if p <= v36.Amount then
			v34 = v36
			break
		else
			v34 = v36
		end
	end

	local Store = require(ReplicatedStorage.Interface.Screens.Menu.Store)

	if not (v34 and Store.CanBuyPaidCurrency()) then
		notify("You do not have enough Trade Tokens.") -- inferred equivalent call
		return
	end

	notify(`You need {CommaNumber(p)} more Trade {p == 1 and "Token" or "Tokens"}.`) -- inferred equivalent call
	devProductId = v34.DevProductId
	setHoveredRegion(nil) -- inferred equivalent call
	MarketplaceService:PromptProductPurchase(LocalPlayer, v34.DevProductId)
	Router.broadcastRouter("RunInterfaceSound", "UI Click")
end

local function promptRefresh()
	if v3 or devProductId or v4 then
		return
	end

	local blackMarketRefresh = DevProducts["Black Market Refresh"]

	if not (blackMarketRefresh and blackMarketRefresh.DevProductId and blackMarketRefresh.DevProductId > 0) then
		notify("Refreshing the deal is not available yet.") -- inferred equivalent call
		return
	end

	if v11 and v11.refreshEnabled == false then
		notify("The dealer is not taking refreshes right now.") -- inferred equivalent call
		return
	end

	v3 = true
	setHoveredRegion(nil) -- inferred equivalent call
	MarketplaceService:PromptProductPurchase(LocalPlayer, blackMarketRefresh.DevProductId)
	Router.broadcastRouter("RunInterfaceSound", "UI Click")
end

local function ensureTargetLayer()
	if v20 then
		return v20
	end

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

	if not playerGui then
		return nil
	end

	local screenGui = v15:FindFirstAncestorWhichIsA("ScreenGui")
	local screenGui2 = Instance.new("ScreenGui")
	screenGui2.Name = "BlackmarketCardTargets"
	screenGui2.ResetOnSpawn = false
	screenGui2.IgnoreGuiInset = true
	screenGui2.DisplayOrder = (not screenGui and 0 or screenGui.DisplayOrder) - 1
	screenGui2.Enabled = false
	screenGui2:SetAttribute(GamepadNavigation.NO_FALLBACK_ATTRIBUTE, true)
	screenGui2.Parent = playerGui
	local frame = Instance.new("Frame")
	frame.Name = "Targets"
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = screenGui2
	v21 = screenGui2
	v20 = frame
	return frame
end

local function isCanvasMirrored(instance) -- 1 equivalent call inferred from this helper
	local surfaceGui = instance:FindFirstAncestorOfClass("SurfaceGui")
	return surfaceGui ~= nil and surfaceGui.Face == Enum.NormalId.Front
end

local function getPressPoint(p, p2)
	if p2 and (p2.UserInputType == Enum.UserInputType.MouseButton1 or p2.UserInputType == Enum.UserInputType.Touch) then
		return Vector2.new(p2.Position.X, p2.Position.Y) + GuiService:GetGuiInset()
	end

	if p2 or not UserInputService.MouseEnabled then
		return p.AbsolutePosition + p.AbsoluteSize / 2
	end

	return UserInputService:GetMouseLocation()
end

local function createCircle(frame, name: string)
	local frame2 = Instance.new("Frame")
	frame2.Name = name
	frame2.AnchorPoint = Vector2.new(0.5, 0.5)
	frame2.Position = UDim2.fromScale(0.5, 0.5)
	frame2.BorderSizePixel = 0
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = frame2
	frame2.Parent = frame
	return frame2
end

local function createFlipBurst(parent)
	local frame = Instance.new("Frame")
	frame.Name = "FlipBurst"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 5
	frame.Visible = false
	local circle = createCircle(frame, "Flash")
	circle.BackgroundColor3 = Color3.new(1, 1, 1)
	local circle2 = createCircle(frame, "Ring")
	circle2.BackgroundTransparency = 1
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Parent = circle2
	local tweens = {
		TweenService:Create(circle, tweenInfo3, {
			Size = UDim2.fromScale(0.4, 0.4),
			BackgroundTransparency = 1
		}),
		TweenService:Create(circle2, tweenInfo4, { Size = UDim2.fromScale(1, 1) })
	}
	local tween = TweenService:Create(uiStroke, tweenInfo4, { Thickness = 0, Transparency = 1 })
	table.insert(tweens, tween)
	local numberSequence = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0.15),
		NumberSequenceKeypoint.new(1, 0)
	})
	local streaks = {}

	for i = 1, 10 do
		local v36 = i / 10 * 3.141592653589793 * 2 + random:NextNumber(-0.25, 0.25)
		local vector = Vector2.new(math.cos(v36), (math.sin(v36)))
		local v37 = random:NextNumber(0.9, 1.5) / 2
		local v38 = random:NextNumber(0.35, 0.6) / 2
		local frame2 = Instance.new("Frame")
		frame2.Name = "Streak"
		frame2.AnchorPoint = Vector2.new(0.5, 0.5)
		frame2.BorderSizePixel = 0
		frame2.Rotation = math.deg(v36)
		local uiCorner = Instance.new("UICorner")
		uiCorner.CornerRadius = UDim.new(1, 0)
		uiCorner.Parent = frame2
		local uiGradient = Instance.new("UIGradient")
		uiGradient.Transparency = numberSequence
		uiGradient.Parent = frame2
		frame2.Parent = frame
		local v39 = vector * 0.1
		local v40 = vector * v37
		table.insert(streaks, {
			Frame = frame2,
			Start = UDim2.fromScale(0.5 + v39.X, 0.5 + v39.Y),
			StartSize = UDim2.fromScale(v38, 0.03)
		})
		table.insert(tweens, TweenService:Create(frame2, tweenInfo5, {
			Position = UDim2.fromScale(0.5 + v40.X, 0.5 + v40.Y),
			Size = UDim2.fromScale(v38 * 0.15, 0.015),
			BackgroundTransparency = 1
		}))
	end

	local tween2 = TweenService:Create(uiStroke, tweenInfo4, { Transparency = 1 })
	local v36 = {
		Holder = frame,
		Flash = circle,
		Ring = circle2,
		RingStroke = uiStroke,
		Streaks = streaks,
		Tweens = tweens,
		FadeTween = tween2,
		IsBusy = false
	}

	local function release()
		frame.Visible = false
		v36.IsBusy = false
	end

	tween.Completed:Connect(release)
	tween2.Completed:Connect(release)
	frame.Parent = parent
	return v36
end

local function acquireFlipBurst(parent)
	for _, v34 in v22 do
		if not v34.IsBusy then
			return v34
		end
	end

	local flipBurst = createFlipBurst(parent)
	table.insert(v22, flipBurst)
	return flipBurst
end

local function playFlipBurst(pressPoint: Vector2, p: number, rarityColor: Color3, reducedMotionEnabled: boolean)
	local parent = v20

	if not parent then
		return
	end

	local v35 = nil
	local flag2 = true

	for _, v36 in v22 do
		if v36.IsBusy then
			continue
		end

		v35 = v36
		flag2 = false
		break
	end

	if flag2 then
		v35 = createFlipBurst(parent)
		table.insert(v22, v35)
	end

	v35.IsBusy = true
	local holder = v35.Holder
	holder.Position = UDim2.fromOffset(pressPoint.X, pressPoint.Y)
	holder.Size = UDim2.fromOffset(p * 2, p * 2)
	holder.Rotation = reducedMotionEnabled and 0 or random:NextNumber(0, 360)
	local ringStroke = v35.RingStroke
	ringStroke.Transparency = 0
	v35.Flash.Visible = not reducedMotionEnabled

	for _, streak in v35.Streaks do
		streak.Frame.Visible = not reducedMotionEnabled
	end

	if reducedMotionEnabled then
		v35.Ring.Size = UDim2.fromScale(0.6, 0.6)
		ringStroke.Color = rarityColor
		ringStroke.Thickness = 2
		holder.Visible = true
		v35.FadeTween:Play()
	else
		v35.Flash.Size = UDim2.fromScale(0.125, 0.125)
		v35.Flash.BackgroundTransparency = 0.05
		v35.Ring.Size = UDim2.fromScale(0.15, 0.15)
		ringStroke.Color = rarityColor:Lerp(Color3.new(1, 1, 1), 0.25)
		ringStroke.Thickness = math.max(p * 0.09, 2)

		for k, streak in v35.Streaks do
			streak.Frame.Position = streak.Start
			streak.Frame.Size = streak.StartSize
			streak.Frame.BackgroundTransparency = 0
			local frame = streak.Frame
			local backgroundColor

			if k % 2 == 0 then
				backgroundColor = Color3.new(1, 1, 1)
			else
				backgroundColor = rarityColor
			end

			frame.BackgroundColor3 = backgroundColor
		end

		holder.Visible = true

		for _, tween in v35.Tweens do
			tween:Play()
		end
	end
end

local function getCardPointUnder(part, pressPoint: Vector2)
	local currentCamera = workspace.CurrentCamera

	if not currentCamera then
		return part.Position
	end

	local viewportPointToRay = currentCamera:ViewportPointToRay(pressPoint.X, pressPoint.Y)
	local lookVector = part.CFrame.LookVector
	local dot = viewportPointToRay.Direction:Dot(lookVector)

	if math.abs(dot) < 0.001 then
		return part.Position
	end

	local v34 = (part.Position - viewportPointToRay.Origin):Dot(lookVector) / dot
	return viewportPointToRay.Origin + viewportPointToRay.Direction * v34
end

local function playFlipEffect(state, imageButton, p)
	local rarityColor = getRarityColor(state.Card and state.Card.rarity) -- inferred equivalent call
	local pressPoint = getPressPoint(imageButton, p)
	local v34 = math.clamp(imageButton.AbsoluteSize.Y * 0.28, 36, 110)
	local reducedMotionEnabled = GuiService.ReducedMotionEnabled
	playFlipBurst(pressPoint, v34, rarityColor, reducedMotionEnabled)

	if reducedMotionEnabled then
		return
	end

	local sparkles = state.Sparkles
	local parent = sparkles and sparkles.Parent

	if not (sparkles and parent and parent:IsA("Attachment") and parent.Parent) then
		local v37 = state.Part.Size.Y * 0.075
		parent = Instance.new("Attachment")
		parent.Name = "FlipSparkleOrigin"
		parent.Parent = state.Part
		sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "FlipSparkles"
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Rate = 0
		sparkles.Lifetime = NumberRange.new(0.35, 0.7)
		sparkles.Speed = NumberRange.new(state.Part.Size.Y * 1.2, state.Part.Size.Y * 2.4)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Drag = 6
		sparkles.Rotation = NumberRange.new(0, 360)
		sparkles.RotSpeed = NumberRange.new(-240, 240)
		sparkles.LightEmission = 1
		sparkles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, v37),
			NumberSequenceKeypoint.new(0.25, v37 * 1.2),
			NumberSequenceKeypoint.new(1, 0)
		})
		sparkles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.7, 0.2),
			NumberSequenceKeypoint.new(1, 1)
		})
		sparkles.Parent = parent
		state.Sparkles = sparkles
	end

	if parent and parent:IsA("Attachment") then
		parent.WorldPosition = getCardPointUnder(state.Part, pressPoint)
	end

	sparkles.Color = ColorSequence.new(Color3.new(1, 1, 1), rarityColor)
	sparkles:Emit(14)
end

local function createTarget(slot2, data, flag2: boolean, name: string)
	local targetLayer = ensureTargetLayer()

	if not targetLayer then
		return
	end

	local imageButton = Instance.new("ImageButton")
	imageButton.Name = name
	imageButton.BackgroundTransparency = 1
	imageButton.ImageTransparency = 1
	imageButton.AutoButtonColor = false
	imageButton.AnchorPoint = Vector2.zero
	imageButton.ZIndex = flag2 and 0 or 1
	imageButton.Visible = false
	imageButton.Parent = targetLayer

	local function hover()
		if flag2 and BlackMarketSceneController.IsCardFaceUp(slot2.Part) then
			return
		end

		setHoveredRegion(data) -- inferred equivalent call
	end

	imageButton.MouseEnter:Connect(hover)
	imageButton.SelectionGained:Connect(hover)

	local function release()
		if v18 == data then
			setHoveredRegion(nil) -- inferred equivalent call
		end
	end

	imageButton.MouseLeave:Connect(release)
	imageButton.SelectionLost:Connect(release)
	imageButton.Activated:Connect(function(p)
		if isPointerBlocked() then -- inferred equivalent call
			return
		end

		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		pressRegion(data) -- inferred equivalent call

		if flag2 then
			playFlipEffect(slot2, imageButton, p)
		end

		data.Activate()
	end)
	local v35 = {
		Button = imageButton,
		Slot = slot2,
		Region = data,
		IsFlip = flag2,
		IsMirrored = 0
	}
	local v36

	if flag2 then
		v36 = slot2.Front
	else
		v36 = slot2.Back
	end

	v35.IsMirrored = isCanvasMirrored(v36) -- inferred equivalent call
	table.insert(v23, v35)
end

local function targetRect(data)
	local slot2 = data.Slot

	if slot2.Card == nil or not BlackMarketSceneController.IsCardShown(slot2.Part) then
		return nil, nil
	end

	if data.IsFlip then
		local vector, vector2 = projectCardRect(slot2.Part, Vector2.zero, Vector2.one, false)

		if not (vector and vector2 and vector2.Y > 0) then
			return nil, nil
		end

		if vector2.X < 12 then
			vector = Vector2.new(vector.X + (vector2.X - 12) / 2, vector.Y)
			vector2 = Vector2.new(12, vector2.Y)
		end

		return vector, vector2
	else
		if not (BlackMarketSceneController.IsCardFaceUp(slot2.Part) and isRegionVisible(data.Region.Element, slot2.Back)) then
			return nil, nil
		end

		local region = data.Region
		local absoluteSize = slot2.Back.AbsoluteSize
		local v34, v35

		if not (absoluteSize.X <= 0 or absoluteSize.Y <= 0) then
			local element = region.Element
			local absolutePosition = element.AbsolutePosition
			local absoluteSize2 = element.AbsoluteSize
			local scale = region.Scale.Scale
			local v36

			if scale <= 0 or scale >= 1 then
				v36 = absoluteSize2
			else
				local anchorPoint = element.AnchorPoint
				v36 = absoluteSize2 / scale
				absolutePosition = absolutePosition + absoluteSize2 * anchorPoint - v36 * anchorPoint
			end

			local v37 = absolutePosition - slot2.Back.AbsolutePosition
			v34 = v37 / absoluteSize
			v35 = (v37 + v36) / absoluteSize
		end

		if not (v34 and v35) then
			return nil, nil
		end

		local v36, v37, v38 = projectCardRect(slot2.Part, v34, v35, data.IsMirrored)

		if v36 and v37 and v38 and v37.X >= 12 and v37.Y > 0 then
			return v36, v37
		end

		return nil, nil
	end
end

local function refreshCardTargets()
	local v34 = isPointerBlocked() or BlackMarketSceneController.IsPresenting() -- inferred equivalent call
	table.clear(buttonsBySlot)
	table.clear(buttonsBySlot2)
	table.clear(v24)
	local selectedObject2 = nil
	local v36 = nil
	local v37 = false

	for _, v38 in v23 do
		local slot2 = v38.Slot
		local button = v38.Button
		local v39, v40

		if not v34 then
			v39, v40 = targetRect(v38)
		end

		if v39 and v40 then
			button.Position = UDim2.fromOffset(v39.X, v39.Y)
			button.Size = UDim2.fromOffset(v40.X, v40.Y)
			button.Visible = true
			selectedObject2 = selectedObject2 or button

			if slot2 == slot then
				v36 = v36 or button
			end

			if v38.IsFlip then
				buttonsBySlot[slot2] = button
			elseif v39.Y < (v24[slot2] or 1e999) then
				v24[slot2] = v39.Y
				buttonsBySlot2[slot2] = button
			end
		else
			button.Visible = false

			if v18 == v38.Region then
				v37 = true
			end
		end
	end

	for k, v38 in buttonsBySlot do
		v38.NextSelectionDown = buttonsBySlot2[k]
	end

	for _, v38 in v23 do
		local button = v38.Button

		if v38.IsFlip or not button.Visible then
			continue
		end

		local slot2 = v38.Slot
		local nextSelectionUp

		if buttonsBySlot2[slot2] == button then
			nextSelectionUp = buttonsBySlot[slot2]
		end

		if button.NextSelectionUp ~= nextSelectionUp then
			button.NextSelectionUp = nextSelectionUp
		end
	end

	local nextSelectionDown = nil
	local v39 = v25
	local v40

	if v39 == nil then
		v40 = false
	else
		v40 = GamepadNavigation.IsUsable(v39)
	end

	if v39 and v40 then
		local v41 = v39.AbsolutePosition.X + v39.AbsoluteSize.X / 2
		local v42 = 1e999

		for _, v43 in buttonsBySlot do
			local v44 = math.abs(v43.AbsolutePosition.X + v43.AbsoluteSize.X / 2 - v41)

			if not (v44 < v42) then
				continue
			end

			nextSelectionDown = v43
			v42 = v44
		end
	end

	for _, v41 in buttonsBySlot do
		local nextSelectionUp

		if v40 then
			nextSelectionUp = v39
		end

		v41.NextSelectionUp = nextSelectionUp
	end

	if v39 then
		v39.NextSelectionDown = nextSelectionDown
	end

	if v37 and v18 ~= nil then
		local v41 = v18
		v18 = nil

		if v41 then
			v41.HoverOut:Play()
		end
	end

	if v34 then
		return
	end

	if v26 and selectedObject2 then
		v26 = false
		GuiService.SelectedObject = selectedObject2
	else
		local selectedObject = GuiService.SelectedObject

		if selectedObject then
			slot = nil

			for _, v41 in v23 do
				if v41.Button ~= selectedObject then
					continue
				end

				slot = v41.Slot
				return
			end
		elseif slot then
			GuiService.SelectedObject = v36 or selectedObject2

			if not (v36 or selectedObject2) then
				slot = nil
			end
		end
	end
end

local function createGlint(frame)
	local frame2 = Instance.new("Frame")
	frame2.Name = "Glint"
	frame2.AnchorPoint = Vector2.new(0.5, 0.5)
	frame2.BackgroundTransparency = 1
	frame2.Visible = false
	local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
	uiAspectRatioConstraint.DominantAxis = Enum.DominantAxis.Height
	uiAspectRatioConstraint.Parent = frame2
	local numberSequence = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1)
	})

	for _, v34 in { false, true } do
		local frame3 = Instance.new("Frame")
		frame3.AnchorPoint = Vector2.new(0.5, 0.5)
		frame3.Position = UDim2.fromScale(0.5, 0.5)
		local size

		if v34 then
			size = UDim2.fromScale(0.14, 1)
		else
			size = UDim2.fromScale(1, 0.14)
		end

		frame3.Size = size
		frame3.BackgroundColor3 = color
		frame3.BorderSizePixel = 0
		local uiGradient = Instance.new("UIGradient")
		uiGradient.Rotation = v34 and 90 or 0
		uiGradient.Transparency = numberSequence
		uiGradient.Parent = frame3
		frame3.Parent = frame2
	end

	frame2.Parent = frame
	return frame2
end

local function scheduleGlint(p, glint, startsAt: number)
	local zero = Vector2.zero
	local v34 = -1

	for _ = 1, 12 do
		local vector = Vector2.new(random:NextNumber(0.12, 0.88), random:NextNumber(0.15, 0.85))
		local v35 = 1e999

		for _, glint2 in p.Glints do
			if glint2 ~= glint and glint2.Lifetime > 0 then
				v35 = math.min(v35, (glint2.Spot - vector).Magnitude)
			end
		end

		if v34 < v35 then
			zero = vector
			v34 = v35
		end

		if v35 >= 0.22 then
			break
		end
	end

	glint.StartsAt = startsAt
	glint.Lifetime = random:NextNumber(1.4, 2.6)
	glint.Size = random:NextNumber(0.09, 0.17)
	glint.Spot = zero
	glint.Frame.Position = UDim2.fromScale(zero.X, zero.Y)
end

local function scatterCardGlints()
	local now = os.clock()

	for _, v34 in v16 do
		for _, glint in v34.Glints do
			scheduleGlint(v34, glint, now + random:NextNumber(0, 4.2))
		end
	end
end

local function updateCardGlints()
	local now = os.clock()
	local reducedMotionEnabled = GuiService.ReducedMotionEnabled

	for _, v34 in v16 do
		local v35 = not reducedMotionEnabled

		if v35 then
			if v34.Card == nil then
				v35 = false
			else
				v35 = BlackMarketSceneController.IsCardFaceUp(v34.Part)
			end
		end

		for _, glint in v34.Glints do
			if v35 then
				if glint.StartsAt + glint.Lifetime < now then
					scheduleGlint(v34, glint, now + random:NextNumber(0.2, 1.6))
				end

				local v36 = (now - glint.StartsAt) / glint.Lifetime
				local visible

				if v36 >= 0 then
					visible = v36 <= 1
				else
					visible = false
				end

				glint.Frame.Visible = visible

				if visible then
					local v38 = math.sin(v36 * 3.141592653589793)
					glint.Frame.Size = UDim2.fromScale(glint.Size * v38, glint.Size * v38)
					glint.Frame.Rotation = v36 * 45
				end
			else
				glint.Frame.Visible = false
			end
		end
	end
end

local function shouldSelectOnOpen() -- 1 equivalent call inferred from this helper
	if UserInputService.GamepadEnabled and not UserInputService.MouseEnabled then
		return true
	end

	return UserInputService:GetLastInputType() == Enum.UserInputType.Gamepad1
end

local function startCardInput()
	ensureTargetLayer()

	if v21 then
		v21.Enabled = true
	end

	local function skipForPad() -- 2 equivalent calls inferred from this helper
		BlackMarketSceneController.SkipPresentation()
		v26 = true
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
	end

	local lastTime = os.clock()
	local v34 = false
	local inputBeganConnection = UserInputService.InputBegan:Connect(function(input)
		if
			not BlackMarketSceneController.IsPresenting()
			or v3
			or devProductId ~= nil
			or v4
			or GuiService.MenuIsOpen
			or os.clock() - lastTime < 0.3
		then
			return
		end

		local userInputType = input.UserInputType
		local keyCode = input.KeyCode

		if v[keyCode] then
			skipForPad() -- inferred equivalent call
		elseif
			userInputType == Enum.UserInputType.MouseButton1
			or userInputType == Enum.UserInputType.Touch
			or keyCode == Enum.KeyCode.ButtonA
			or keyCode == Enum.KeyCode.Return
			or keyCode == Enum.KeyCode.Space
		then
			BlackMarketSceneController.SkipPresentation()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
		end
	end)
	table.insert(v27, inputBeganConnection)
	local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick1 then
			return
		end

		local magnitude = Vector2.new(input.Position.X, input.Position.Y).Magnitude

		if magnitude < 0.2 then
			v34 = true
			return
		end

		if
			not v34
			or magnitude < 0.5
			or os.clock() - lastTime < 0.3
			or not BlackMarketSceneController.IsPresenting()
			or v3
			or devProductId ~= nil
			or v4
			or GuiService.MenuIsOpen
		then
			return
		end

		skipForPad() -- inferred equivalent call
	end)
	table.insert(v27, inputChangedConnection)
	v26 = shouldSelectOnOpen() -- inferred equivalent call
	connection = RunServiceController.BindToHeartbeat("UI.Blackmarket.CardTargets", refreshCardTargets)
	refreshCardTargets()
	scatterCardGlints()
	connection2 = RunServiceController.BindToRenderStep("UI.Blackmarket.CardGlints", updateCardGlints)
end

local function bindSlot(state)
	local regions = {}

	local function addRegion(guiObject, fn)
		if not (guiObject and guiObject:IsA("GuiObject")) then
			return
		end

		local uiScale = guiObject:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		uiScale.Parent = guiObject
		local region = {
			Element = guiObject,
			Activate = fn,
			Scale = uiScale,
			HoverIn = TweenService:Create(uiScale, tweenInfo2, { Scale = 0.95 }),
			HoverOut = TweenService:Create(uiScale, tweenInfo2, { Scale = 1 }),
			Press = TweenService:Create(uiScale, tweenInfo2, { Scale = 0.9 })
		}
		table.insert(regions, region)
		createTarget(state, region, false, guiObject.Name)
	end

	if
		state.Front.AnchorPoint == Vector2.zero
		and state.Front.Position == UDim2.fromScale(0, 0)
		and state.Front.Size == UDim2.fromScale(1, 1)
	then
		state.Front.AnchorPoint = Vector2.new(0.5, 0.5)
		state.Front.Position = UDim2.fromScale(0.5, 0.5)
	end

	local uiScale = state.Front:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	uiScale.Parent = state.Front
	local flipRegion = {
		Element = state.Front,
		Activate = function()
			if BlackMarketSceneController.IsCardFaceUp(state.Part) then
				BlackMarketSceneController.SetCardFaceUp(state.Part, false, true)
			else
				flipCardUp(state)
			end

			if state.Card then
				v12[tostring(state.Card.cardId)] = BlackMarketSceneController.IsCardFaceUp(state.Part)
			end
		end,
		Scale = uiScale,
		HoverIn = TweenService:Create(uiScale, tweenInfo2, { Scale = 0.95 }),
		HoverOut = TweenService:Create(uiScale, tweenInfo2, { Scale = 1 }),
		Press = TweenService:Create(uiScale, tweenInfo2, { Scale = 0.9 })
	}
	state.FlipRegion = flipRegion
	createTarget(state, flipRegion, true, "Flip")
	local itemTemplate = state.Back:FindFirstChild("ItemTemplate")
	local itemContent = itemTemplate and itemTemplate:FindFirstChild("ItemContent")
	local content = itemContent and itemContent:FindFirstChild("Content")
	local icon = content and content:FindFirstChild("Icon")
	local parent = state.Back.Parent

	if icon and icon:IsA("GuiObject") and parent and parent:IsA("SurfaceGui") then
		local frame = Instance.new("Frame")
		frame.Name = "Glints"
		frame.BackgroundTransparency = 1
		frame.Active = false
		frame.ZIndex = state.Back.ZIndex + 1
		frame.Parent = parent

		local function fitGlintLayer() -- 1 equivalent call inferred from this helper
			local v36 = icon.AbsolutePosition - parent.AbsolutePosition
			frame.Position = UDim2.fromOffset(v36.X, v36.Y)
			frame.Size = UDim2.fromOffset(icon.AbsoluteSize.X, icon.AbsoluteSize.Y)
		end

		icon:GetPropertyChangedSignal("AbsolutePosition"):Connect(fitGlintLayer)
		icon:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitGlintLayer)
		fitGlintLayer() -- inferred equivalent call

		for _ = 1, 6 do
			table.insert(state.Glints, {
				Frame = createGlint(frame),
				StartsAt = -1e999,
				Lifetime = 0,
				Size = 0,
				Spot = Vector2.zero
			})
		end
	end

	addRegion(itemContent and itemContent:FindFirstChild("Inspect"), function()
		local card = state.Card

		if card then
			flag = true
			InspectController.ShowInspect((toPreviewItem(card)))
		end
	end)
	local bottom = state.Back:FindFirstChild("Bottom")
	local interact = bottom and bottom:FindFirstChild("Interact")

	if interact then
		local buy = interact:FindFirstChild("Buy")
		local view = interact:FindFirstChild("View")
		local title = view and view:FindFirstChild("Title")

		if title and title:IsA("TextLabel") then
			title.Text = "VIEW ON MARKETPLACE"
		end

		if buy and buy:IsA("GuiObject") and view and view:IsA("GuiObject") then
			state.BuyWideLayout = {
				Position = UDim2.new(
					view.Position.X.Scale,
					view.Position.X.Offset,
					buy.Position.Y.Scale,
					buy.Position.Y.Offset
				),
				Size = UDim2.new(view.Size.X.Scale, view.Size.X.Offset, buy.Size.Y.Scale, buy.Size.Y.Offset)
			}
		end

		addRegion(interact:FindFirstChild("View"), function()
			local card = state.Card

			if not card then
				return
			end

			local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
			local GlobalMarketPlace = require(ReplicatedStorage.Interface.Screens.Menu.GlobalMarketPlace)
			flag = true
			GlobalMarketPlace.SetReturnScreen("Blackmarket")
			local v36 = not v9[tostring(card.offerKind)] and typeof(card.float) == "number"
			local searchForItem = GlobalMarketPlace.SearchForItem
			local name = card.name
			local skin = card.skin
			local float

			if v36 then
				float = card.float
			end

			searchForItem(name, skin, {
				Float = float,
				StatTrak = card.isStattrak == true
			})
			Top.openFrame("GlobalMarketPlace")
		end)
		addRegion(interact:FindFirstChild("Buy"), function()
			local card = state.Card

			if not card or card.status ~= "available" or v10[tostring(card.cardId)] then
				return
			end

			if v11 and v11.buyEnabled == false then
				notify("The dealer is not taking Trade Tokens right now.") -- inferred equivalent call
				return
			end

			local price = math.floor(tonumber(card.price) or 0)
			local tradeTokens = DataController.Get(LocalPlayer, "TradeTokens")

			if typeof(tradeTokens) == "number" and tradeTokens < price then
				promptTradeTokens(price - tradeTokens)
			else
				BlackMarketDealer.BuyCard.Send(card.cardId)
			end
		end)
	end

	state.Regions = regions
end

local function ensureSlots()
	if v28 then
		return
	end

	local cards = BlackMarketSceneController.GetCards()

	if #cards == 0 then
		return
	end

	for k, card in cards do
		local guiObject, guiObject2 = BlackMarketSceneController.GetCardFaces(card)

		if not (guiObject and guiObject:IsA("GuiObject") and guiObject2 and guiObject2:IsA("GuiObject")) then
			continue
		end

		local slot2 = {
			Part = card,
			Back = guiObject,
			Front = guiObject2,
			Card = nil,
			Regions = {},
			Glints = {}
		}
		v16[k] = slot2
		bindSlot(slot2)
	end

	v28 = #v16 > 0
end

local function beginPaidRoll() -- 1 equivalent call inferred from this helper
	v4 = true

	if v29 then
		local v34 = v5

		if v34 and v33 ~= true then
			v33 = true
			v34.Visible = true
			local v35 = v6

			if v35 then
				v35:Play()
			end
		end
	end

	count += 1
	local v34 = count
	task.delay(60, function()
		if v34 ~= count then
			return
		end

		v4 = false
		local v35 = v5

		if v35 then
			if v33 == false then
				return
			end

			v33 = false
			v35.Visible = false
			local v36 = v6

			if not v36 then
				return
			end

			if v7 then
				v36:Cancel()
				v7.Rotation = 0
			end
		end
	end)
end

local function finishPaidRoll()
	count += 1
	v4 = false
	local v34 = v5

	if v34 then
		if v33 == false then
			return
		end

		v33 = false
		v34.Visible = false
		local v35 = v6

		if not v35 then
			return
		end

		if v7 then
			v35:Cancel()
			v7.Rotation = 0
		end
	end
end

local function playPaidRoll() -- 1 equivalent call inferred from this helper
	if not BlackMarketSceneController.IsActive() then
		return
	end

	clearCardHover()
	BlackMarketSceneController.Redeal()
	BlackMarketSceneController.PlayRefreshLine()
end

local function applyDeal(deal, flag2: boolean)
	local v34 = dealSignature(deal) ~= dealSignature(v11)

	if v34 or flag2 then
		table.clear(v10)
		table.clear(v12)
		table.clear(v19)
	end

	if flag2 then
		count += 1
		v4 = false
		local v35 = v5

		if v35 and v33 ~= false then
			v33 = false
			v35.Visible = false
			local v36 = v6

			if v36 and v7 then
				v36:Cancel()
				v7.Rotation = 0
			end
		end

		playPaidRoll() -- inferred equivalent call
	elseif v34 and BlackMarketSceneController.IsActive() then
		BlackMarketSceneController.ResetCards()
	end

	renderDeal(deal)
end

local function openFrame()
	local v34 = flag
	flag = false
	MenuSceneController.HideMenuScene(true, true)
	setNavigationVisible(false)
	BlackMarketSceneController.Show(v34 or not v30)
	ensureSlots()

	if v34 then
		for _, v35 in v16 do
			if v31[v35.Part] then
				BlackMarketSceneController.SetCardFaceUp(v35.Part, true, false)
			end
		end
	end

	table.clear(v31)
	startCardInput()
	renderDeal(v11)
	requestDeal() -- inferred equivalent call
	local visible = v4
	local v36 = v5

	if v36 and visible ~= v33 then
		v33 = visible
		v36.Visible = visible
		local v37 = v6

		if v37 then
			if visible then
				v37:Play()
			elseif v7 then
				v37:Cancel()
				v7.Rotation = 0
			end
		end
	end

	total = 1e999
	connection3 = RunServiceController.BindToHeartbeat("UI.Blackmarket.Countdown", function(p: number)
		total += p

		if total < 0.25 then
			return
		end

		total = 0
		updateCountdown()
		requestDeal() -- inferred equivalent call
	end)
end

local function closeFrame()
	for _, connection4 in v27 do
		connection4:Disconnect()
	end

	table.clear(v27)

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if connection2 then
		connection2:Disconnect()
		connection2 = nil
	end

	clearCardHover()

	if v21 then
		v21.Enabled = false
	end

	for _, v34 in v23 do
		v34.Button.Visible = false
	end

	local v34 = v5

	if v34 and v33 ~= false then
		v33 = false
		v34.Visible = false
		local v35 = v6

		if v35 and v7 then
			v35:Cancel()
			v7.Rotation = 0
		end
	end

	devProductId = nil
	v26 = false
	slot = nil

	if connection3 then
		connection3:Disconnect()
		connection3 = nil
	end

	table.clear(v31)

	if flag then
		for _, v35 in v16 do
			v31[v35.Part] = BlackMarketSceneController.IsCardFaceUp(v35.Part)
		end
	end

	BlackMarketSceneController.Hide()

	if not flag then
		setNavigationVisible(true)
	end

	if v8 and v8.Visible then
		MenuSceneController.ShowMenuScene()
	end
end

local function syncScreenState() -- 1 equivalent call inferred from this helper
	local v34 = v15.Visible and (v8 == nil or v8.Visible)

	if v34 == v29 then
		return
	end

	v29 = v34

	if v34 then
		openFrame()
	else
		closeFrame()
	end
end

function Blackmarket.SetIntroEnabled(flag2: boolean)
	v30 = flag2 ~= false
end

function Blackmarket.Initialize(instance, instance2)
	v15 = instance2

	if not Constants.BLACK_MARKET_ENABLED then
		instance2.Visible = false
		return
	end

	local parent = instance2.Parent

	if not (parent and parent:IsA("GuiObject") and parent) then
		parent = nil
	end

	v8 = parent
	local loading = instance:FindFirstChild("Loading")
	local loading2 = loading and loading:FindFirstChild("Loading")

	if loading and loading:IsA("GuiObject") and loading2 and loading2:IsA("GuiObject") then
		v5 = loading
		v7 = loading2
		v6 = TweenService:Create(loading2, tweenInfo, { Rotation = 359 })
	end

	local function goBack()
		local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
		Top.openFrame("Dashboard")
	end

	local back = instance2:FindFirstChild("Back")

	if back and back:IsA("GuiButton") then
		ActivateButton(back)
		back.Activated:Connect(goBack)
	end

	CloseButtonRegistry.Add(instance2, nil, goBack)
	local refresh = instance2:FindFirstChild("Refresh")

	if refresh and refresh:IsA("GuiButton") then
		ActivateButton(refresh)
		refresh.Activated:Connect(promptRefresh)
		v25 = refresh
	end

	local tradeTokens = instance2:FindFirstChild("TradeTokens")
	local textLabel = tradeTokens and tradeTokens:FindFirstChild("TextLabel")

	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.Text = "0"
		DataController.CreateListener(LocalPlayer, "TradeTokens", function(p)
			textLabel.Text = CommaNumber((math.floor(tonumber(p) or 0)))
			return nil
		end)
	end

	local purchaseMore = tradeTokens and tradeTokens:FindFirstChild("PurchaseMore")

	if purchaseMore and purchaseMore:IsA("GuiButton") then
		ActivateButton(purchaseMore)
		purchaseMore.Activated:Connect(function()
			local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
			local Store = require(ReplicatedStorage.Interface.Screens.Menu.Store)
			Top.openFrame("Store")

			if MenuState.GetCurrentScreen() == "Store" then
				Store.OpenTab("TradeTokens")
			end
		end)
		instance2:GetPropertyChangedSignal("Visible"):Connect(function()
			if instance2.Visible then
				local Store = require(ReplicatedStorage.Interface.Screens.Menu.Store)
				purchaseMore.Visible = Store.CanBuyPaidCurrency()
			end
		end)
	end

	instance2:GetPropertyChangedSignal("Visible"):Connect(syncScreenState)

	if v8 then
		v8:GetPropertyChangedSignal("Visible"):Connect(syncScreenState)
	end

	syncScreenState() -- inferred equivalent call
end

function Blackmarket.Start()
	if not Constants.BLACK_MARKET_ENABLED then
		return
	end

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(_: number, p: number, flag2: boolean)
		if p == devProductId then
			devProductId = nil
			return
		end

		local blackMarketRefresh = DevProducts["Black Market Refresh"]

		if not blackMarketRefresh or p ~= blackMarketRefresh.DevProductId then
			return
		end

		v3 = false
		local v34 = v32
		v32 = nil

		if v34 then
			if v34.success then
				applyDeal(v34.deal, true)
			end
		elseif flag2 then
			beginPaidRoll() -- inferred equivalent call
		end
	end)
	BlackMarketDealer.DealData.Listen(function(data)
		local v34

		if typeof(data) == "table" then
			v34 = data.isRefresh == true
		else
			v34 = false
		end

		local v35 = v34 and v3 and not v4

		if v35 and (data.success or not (v32 and v32.success)) then
			v32 = data
		end

		if typeof(data) == "table" and data.success then
			local deal = data.deal
			local msRemaining

			if typeof(deal) == "table" then
				msRemaining = tonumber(deal.msRemaining) or nil
			end

			local v36

			if msRemaining then
				v36 = os.clock() + msRemaining / 1000
			end

			v13 = v36
			v14 = nil

			if v35 then
				return
			end

			local v37 = dealSignature(data.deal) ~= dealSignature(v11)
			applyDeal(data.deal, v34 and (v4 or v37))
		else
			if v4 and v34 then
				count += 1
				v4 = false
				local v36 = v5

				if v36 and v33 ~= false then
					v33 = false
					v36.Visible = false
					local v37 = v6

					if v37 and v7 then
						v37:Cancel()
						v7.Rotation = 0
					end
				end
			end

			notify(typeof(data) == "table" and data.message or "The Black Market is unavailable.") -- inferred equivalent call
		end
	end)
	BlackMarketDealer.BuyCardResult.Listen(function(data)
		if typeof(data) == "table" and data.success then
			local cardId = data.cardId

			if cardId ~= nil then
				v10[tostring(cardId)] = true

				for _, v34 in v16 do
					if not (v34.Card and tostring(v34.Card.cardId) == tostring(cardId)) then
						continue
					end

					renderSlot(v34, v34.Card)
				end
			end

			Router.broadcastRouter("RunStoreSound", "Successful Purchase")
			BlackMarketSceneController.PlayPurchaseLine()
		else
			notify(typeof(data) == "table" and data.message or "The purchase failed.") -- inferred equivalent call
		end
	end)
end

return Blackmarket