local Store = {}
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PolicyService = game:GetService("PolicyService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local Constants = require(ReplicatedStorage.Database.Custom.Constants)
require(ReplicatedStorage.Database.Custom.ConsoleTypes)
local CaseSceneController = require(ReplicatedStorage.Controllers.CaseSceneController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local CommaNumber = require(ReplicatedStorage.Components.Common.CommaNumber)
local FormatDuration = require(ReplicatedStorage.Components.Common.FormatDuration)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local TradeTokens = require(ReplicatedStorage.Database.Custom.GameStats.Monetization.TradeTokens)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Spring = require(ReplicatedStorage.Shared.Spring)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local GamepadNavigation = require(ReplicatedStorage.Interface.GamepadNavigation)
local CaseScroll = require(script.CaseScroll)
local Hover = require(script.Hover)
local StarterPack = require(script.StarterPack)
local DevProducts = require(ReplicatedStorage.Database.Custom.GameStats.Monetization.DevProducts)
local Gamepasses = require(ReplicatedStorage.Database.Custom.GameStats.Monetization.Gamepasses)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Cases2 = require(ReplicatedStorage.Database.Custom.GameStats.Monetization.Cases)
local v = Spring.new(1, 8, 0)
local v2 = Spring.new(1, 8, 0)
local v3 = Spring.new(1, 8, 0)
local LocalPlayer = Players.LocalPlayer
local v4 = true
local selectedObject = nil
local v5 = 1
local v6 = -1
local v7 = nil
local v8 = nil
local v9 = "Console"
local v10 = {
	TAB_ORDER = { "Console", "Cases", "Credits", "TradeTokens", "CreatorCode" },
	TRADE_TOKEN_PACKAGES = table.freeze({
		{ Amount = 400, ProductName = "+ 400 Trade Tokens" },
		{ Amount = 800, ProductName = "+ 800 Trade Tokens" },
		{ Amount = 1700, ProductName = "+ 1,700 Trade Tokens" },
		{ Amount = 4500, ProductName = "+ 4,500 Trade Tokens" },
		{ Amount = 10000, ProductName = "+ 10,000 Trade Tokens" },
		{ Amount = 22500, ProductName = "+ 22,500 Trade Tokens" }
	}),
	TRADE_TOKEN_CASE_MARKUP = 1.15,
	CASE_SCROLL_ITEM_COUNT = 75,
	CASE_SCROLL_WINNING_INDEX = 55,
	CASE_SCROLL_DURATION = 7,
	CASE_SCROLL_ITEM_PADDING = 8,
	CASE_SCROLL_ITEM_WIDTH = 215,
	OPEN_CASE_REQUEST_TIMEOUT = 12,
	PROGRESS_BAR_LOOPS = 4,
	MINT_RESERVE_HIDDEN_CREDITS_HEIGHT_RATIO = 0.738575,
	INSPECTABLE_ITEM_TAGS = { "StoreBonusItem", "ConsoleItemTemplate" },
	STORE_HOVER_BUTTON_TAG = "StoreHoverButton",
	STORE_HOVER_MOUSE_OFFSET = Vector2.new(16, 16),
	STORE_HOVER_PADDING = 8,
	DEFAULT_CASE_ICON = "rbxassetid://132217734282843",
	SPECIAL_CASE_ICONS = {
		apex_case = "rbxassetid://110520095994318",
		chrysalis = "rbxassetid://127888213250008"
	},
	RARITY_PRIORITY = {
		Blue = 1,
		Purple = 2,
		Pink = 3,
		Red = 4,
		Special = 5
	}
}
local parent3 = nil
local parent4 = nil
local v11 = { Source = "FeaturedConsoleTimer", Label = nil, Tick = 0, ReceivedAt = 0 }
local v12 = {}
local v13 = {
	isOpening = false,
	isPendingOpenRequest = false,
	isQuickUnlock = false,
	currentTween = nil,
	currentZoomTween = nil,
	renderConnection = nil,
	viewportConnection = nil,
	currentInventoryItem = nil,
	currentCaseIdentifier = nil,
	pendingOpenRequestId = nil,
	progressRightTween = nil,
	progressRightProxy = nil
}
local count = 0
local v14 = {}
local v15 = {}
local v16 = nil
local v17 = nil
local v18 = {}
local fn
v10.RARITY_TO_DROP_SOUND = {
	Special = "Drop Gold",
	Red = "Drop Red",
	Pink = "Drop Pink",
	Purple = "Drop Purple",
	Blue = "Drop Blue"
}
local v19 = {
	inventoryItems = nil,
	bulkIdentifier = nil,
	caseId = nil,
	isBulkOpening = false,
	currentIndex = 0,
	skipped = false,
	total = 0
}
local color = Color3.fromRGB(255, 244, 200)
local fn2
local fn3
local fn4
local fn5
local fn6

local function LoadProductInfo(p, fn7)
	if v12[p] then
		table.insert(v12[p], fn7)
		return
	end

	v12[p] = { fn7 }
	task.spawn(function()
		local success, result = pcall(function()
			return MarketplaceService:GetProductInfoAsync(p, Enum.InfoType.Product)
		end)
		local v20 = v12[p]
		v12[p] = nil

		for _, callback in v20 do
			task.defer(callback, success and result or nil)
		end
	end)
end

local function LoadProductPrice(devProduct, fn7) -- 2 equivalent calls inferred from this helper
	if devProduct.Price and fn7 then
		fn7(devProduct.Price)
	end

	LoadProductInfo(devProduct.DevProductId, function(p)
		if not (p and p.PriceInRobux) then
			return
		end

		devProduct.BasePrice = p.UserBasePriceInRobux or devProduct.Price
		devProduct.Price = p.PriceInRobux

		if fn7 then
			fn7(devProduct.Price)
		end
	end)
end

local function GetCaseTokenPrice(p) -- 3 equivalent calls inferred from this helper
	local basePrice = p.BasePrice

	if not (basePrice and basePrice > 0) then
		basePrice = p.Price or 0
	end

	return (math.floor(basePrice * v10.TRADE_TOKEN_CASE_MARKUP))
end

local function DoCreditPurchase(text: string, data, quantity: number?, quantity2: number?)
	if parent3:FindFirstChild("CurrentConfirm") then
		return
	end

	local devProductId = data.DevProductId or data.ID

	if devProductId == nil then
		return
	end

	local tradeTokens = DataController.Get(LocalPlayer, "TradeTokens") or 0
	local clone = parent3.Purchase:Clone()
	clone.Name = "CurrentConfirm"
	clone.Main.Header.Title.Text = text
	clone.Main.Info.Frame.Credits.TextLabel.Text = CommaNumber(tradeTokens)
	clone.Main.Info.Robux.Credits.Amount.Text = CommaNumber(data.Price or 0)
	local amount = clone.Main.Info.TradeTokens.Credits.Amount
	local text2

	if quantity or quantity2 then
		text2 = CommaNumber(GetCaseTokenPrice(data)) -- inferred equivalent call

		if not text2 then
			text2 = clone.Main.Info.Robux.Credits.Amount.Text
		end
	else
		text2 = clone.Main.Info.Robux.Credits.Amount.Text
	end

	amount.Text = text2
	clone.Visible = true
	clone.Parent = parent3

	if TradeTokens[text] and TradeTokens[text].Price then
		clone.Main.Info.TradeTokens.Credits.Amount.Text = CommaNumber(TradeTokens[text].Price)
	end

	ActivateButton(clone.Main.Action.Frame.Close)
	clone.Main.Action.Frame.Close.MouseButton1Click:Connect(function()
		clone:Destroy()
	end)
	ActivateButton(clone.Main.Info.Robux)
	clone.Main.Info.Robux.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(LocalPlayer, devProductId)
		clone:Destroy()
	end)
	ActivateButton(clone.Main.Info.TradeTokens)
	clone.Main.Info.TradeTokens.MouseButton1Click:Connect(function()
		if quantity2 then
			Remotes.Store.PurchaseConsoleTradeTokens.Send({
				ProductName = text,
				Quantity = quantity2
			})
		elseif quantity then
			Remotes.Store.PurchaseTradeTokensCase.Send({
				ProductName = v8.name,
				Quantity = quantity
			})
		else
			Remotes.Store.PurchaseTradeTokensProduct.Send({ ProductName = text })
		end

		clone:Destroy()
	end)
end

local function MultiplyUdim2(size: UDim2, p: number) -- 1 equivalent call inferred from this helper
	return UDim2.fromScale(size.X.Scale * p, size.Y.Scale * p)
end

local function ClearFrame(instance, list)
	for _, child in ipairs(instance:GetChildren()) do
		if not table.find(list, child.Name) then
			child:Destroy()
		end
	end
end

local function CreateSpecialShimmer(content)
	local frame = Instance.new("Frame")
	frame.Name = "Shimmer"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = color
	frame.BorderSizePixel = 0
	frame.ZIndex = 3
	frame.Visible = false
	local uiGradient = Instance.new("UIGradient")
	uiGradient.Rotation = 25
	uiGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.38, 1),
		NumberSequenceKeypoint.new(0.5, 0.55),
		NumberSequenceKeypoint.new(0.62, 1),
		NumberSequenceKeypoint.new(1, 1)
	})
	uiGradient.Parent = frame
	frame.Parent = content
	return frame, uiGradient
end

local function CreateSpecialGlint(content)
	local frame = Instance.new("Frame")
	frame.Name = "Glint"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = UDim2.fromOffset(11, 11)
	frame.BackgroundTransparency = 1
	frame.ZIndex = 4
	frame.Visible = false
	local numberSequence = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 1)
	})

	for _, v20 in { false, true } do
		local frame2 = Instance.new("Frame")
		frame2.AnchorPoint = Vector2.new(0.5, 0.5)
		frame2.Position = UDim2.fromScale(0.5, 0.5)
		local size

		if v20 then
			size = UDim2.new(0, 2, 1, 0)
		else
			size = UDim2.new(1, 0, 0, 2)
		end

		frame2.Size = size
		frame2.BackgroundColor3 = color
		frame2.BorderSizePixel = 0
		frame2.ZIndex = 4
		local uiGradient = Instance.new("UIGradient")
		uiGradient.Rotation = v20 and 90 or 0
		uiGradient.Transparency = numberSequence
		uiGradient.Parent = frame2
		frame2.Parent = frame
	end

	frame.Parent = content
	return frame
end

local function ApplySpecialCardEffect(clone)
	local content = clone:FindFirstChild("Content")

	if not content then
		return
	end

	local uiGradient = content:FindFirstChildOfClass("UIGradient")
	local transparency

	if uiGradient then
		transparency = uiGradient.Transparency
	else
		transparency = NumberSequence.new(0)
	end

	local rarity = content:FindFirstChild("Rarity")
	local v20 = not rarity and 0 or rarity.Rotation

	if rarity and not rarity:FindFirstChildOfClass("UIAspectRatioConstraint") then
		local uiAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		uiAspectRatioConstraint.AspectRatio = 1
		uiAspectRatioConstraint.AspectType = Enum.AspectType.FitWithinMaxSize
		uiAspectRatioConstraint.Parent = rarity
	end

	local parent, v21 = CreateSpecialShimmer(content)
	local random = Random.new()
	local v22 = {}

	for i = 1, 4 do
		table.insert(v22, {
			Frame = CreateSpecialGlint(content),
			CycleStart = os.clock() + (i - 1) * 0.45
		})
	end

	local bindingName = RunServiceController.CreateBindingName("UI.Store.SpecialCardEffect")
	local connection = RunServiceController.BindToRenderStep(bindingName, function()
		if not (parent3.Visible and parent3.CaseContent.Visible and parent3.CaseContent.Main.CaseContent.Visible) then
			return
		end

		if GuiService.ReducedMotionEnabled then
			parent.Visible = false

			for _, v23 in v22 do
				v23.Frame.Visible = false
			end
		else
			local now = os.clock()

			if uiGradient then
				local v23 = (1 - math.cos(now * 2 * 3.141592653589793 / 2.5)) / 2
				local numberSequenceKeypoints = {}

				for _, keypoint in transparency.Keypoints do
					local v24 = keypoint.Value + (1 - keypoint.Value) * 0.15 * v23
					table.insert(numberSequenceKeypoints, NumberSequenceKeypoint.new(keypoint.Time, v24))
				end

				uiGradient.Transparency = NumberSequence.new(numberSequenceKeypoints)
			end

			if rarity then
				rarity.Rotation = v20 + now * 30 % 360
			end

			local v23 = now % 2.8 / 0.9
			parent.Visible = v23 <= 1

			if parent.Visible then
				v21.Offset = Vector2.new(-1 + 2 * v23, 0)
			end

			for _, v24 in v22 do
				local v25 = now - v24.CycleStart

				if v25 >= 1.8 then
					v24.CycleStart = now
					v24.Frame.Position = UDim2.fromScale(random:NextNumber(0.12, 0.88), random:NextNumber(0.12, 0.8))
					v25 = 0
				end

				local v26 = v25 / 1.1
				local frame = v24.Frame
				frame.Visible = v26 >= 0 and v26 <= 1

				if not v24.Frame.Visible then
					continue
				end

				local v27 = math.sin(v26 * 3.141592653589793)
				v24.Frame.Size = UDim2.fromOffset(v27 * 11, v27 * 11)
				v24.Frame.Rotation = v26 * 45
			end
		end
	end)
	clone.Destroying:Connect(function()
		connection:Disconnect()
	end)
end

local function UpdateCreatorCodeResponse(p: string, text: string)
	local guid = HttpService:GenerateGUID(false)
	local response = parent3.CreatorCode.Container.Body.Response
	local color2 = p == "Success" and Color3.fromRGB(86, 228, 21)

	if not color2 then
		if p == "Error" then
			color2 = Color3.fromRGB(232, 59, 82)
		else
			color2 = false
		end
	end

	response.TextColor3 = color2
	parent3.CreatorCode.Container.Action.Confirm.Title.Text = "CONFIRM"
	parent3.CreatorCode:SetAttribute("ResponseId", guid)
	parent3.CreatorCode.Container.Body.Response.Text = text
	task.delay(5, function()
		if parent3.CreatorCode:GetAttribute("ResponseId") == guid then
			parent3.CreatorCode.Container.Body.CreatorName.TextBox.Text = ""
			parent3.CreatorCode.Container.Body.Response.Text = ""
		end
	end)
end

local function ScrollToBottom(state) -- 2 equivalent calls inferred from this helper
	Profiler.defer("UI.Store.ScrollToBottomDeferred", function()
		local v20 = math.max(0, state.AbsoluteCanvasSize.Y - state.AbsoluteWindowSize.Y)
		state.CanvasPosition = Vector2.new(state.CanvasPosition.X, v20)
	end)
end

local function ScrollToFeaturedSection(childName: string)
	local container = parent3.Tabs.Container.Featured.Container
	local child = container:FindFirstChild(childName)

	if not child then
		return false
	end

	local y = container.AbsolutePosition.Y
	local y2 = child.AbsolutePosition.Y
	local v20 = math.max(0, container.CanvasPosition.Y + (y2 - y))
	local tween = TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CanvasPosition = Vector2.new(0, v20)
	})
	tween:Play()
	tween.Completed:Wait()
	tween:Destroy()
	return true
end

local function NotifyCaseOpenSequenceFinished() -- 4 equivalent calls inferred from this helper
	local currentCaseIdentifier = v13.currentCaseIdentifier

	if currentCaseIdentifier then
		Remotes.Store.CaseOpenSequenceFinished.Send({ CaseIdentifier = currentCaseIdentifier })
		v13.currentCaseIdentifier = nil
	end
end

local function ClearPendingOpenRequest() -- 2 equivalent calls inferred from this helper
	v13.isPendingOpenRequest = false
	v13.pendingOpenRequestId = nil
	v13.isQuickUnlock = false
end

local function CreateOpenCaseRequestId() -- 1 equivalent call inferred from this helper
	count += 1
	return (tostring(count))
end

local function FailOpenCaseRequest(p: string?) -- 3 equivalent calls inferred from this helper
	if not p then
		return
	end

	if v13.pendingOpenRequestId == p then
		ClearPendingOpenRequest() -- inferred equivalent call
	end

	v14[p] = nil
end

local function CompleteOpenCaseRequest(requestId: string?) -- 2 equivalent calls inferred from this helper
	local selected = requestId and v14[requestId]

	if not selected then
		return nil
	end

	FailOpenCaseRequest(requestId) -- inferred equivalent call
	return selected
end

local function BeginOpenCaseRequest(isQuickUnlock: boolean) -- 2 equivalent calls inferred from this helper
	local pendingOpenRequestId = CreateOpenCaseRequestId() -- inferred equivalent call
	v14[pendingOpenRequestId] = { IsQuickUnlock = isQuickUnlock }
	v13.isPendingOpenRequest = true
	v13.pendingOpenRequestId = pendingOpenRequestId
	v13.isQuickUnlock = isQuickUnlock
	return pendingOpenRequestId
end

local function IsResolvedCaseOpenBusy() -- 2 equivalent calls inferred from this helper
	return v13.isPendingOpenRequest or v13.isOpening or v19.isBulkOpening or MenuState.IsInspectActive()
end

local function StartResolvedCaseOpenJob(data)
	if data.IsConsole then
		if #data.InventoryItems > 1 then
			fn6(data.CaseId, data.InventoryItems, data.ConsoleOutcomes or {}, data.CaseIdentifier)
		else
			fn(data.InventoryItems[1], data.CaseIdentifier)
		end
	elseif #data.InventoryItems > 1 then
		fn5(data.CaseId, data.InventoryItems, data.CaseIdentifier)
	else
		fn3(data.CaseId, data.InventoryItems[1], data.CaseIdentifier, data.IsQuickUnlock, data.RequestId)
	end
end

local function TryProcessResolvedCaseOpenQueue()
	Profiler.mark("UI.Store.TryProcessResolvedCaseOpenQueue")

	if IsResolvedCaseOpenBusy() then -- inferred equivalent call
		return false
	end

	local v20 = false

	while true do
		local v21 = not IsResolvedCaseOpenBusy() and table.remove(v15, 1) -- inferred equivalent call

		if not v21 then
			break
		end

		StartResolvedCaseOpenJob(v21)
		v20 = true
	end

	return v20
end

local function ReturnToStoreTabs() -- 6 equivalent calls inferred from this helper
	parent3.Tabs.Container.Visible = true
	parent3.CaseContent.Visible = false
	parent4.Menu.Top.Visible = true
	parent3.Top.Visible = true
	parent3.Visible = false
end

local function ShowCaseContentView() -- 3 equivalent calls inferred from this helper
	parent3.Visible = true
	parent3.Tabs.Container.Visible = false
	parent3.CaseContent.Visible = true
	parent4.Menu.Top.Visible = false
	parent3.Top.Visible = false
end

local function InspectInventoryItem(data) -- 4 equivalent calls inferred from this helper
	Router.broadcastRouter(
		"WeaponInspect",
		data.Name,
		data.Skin,
		data.Float,
		data.StatTrack,
		data.NameTag,
		data.Charm,
		data.Stickers,
		data.Type,
		data.Pattern,
		data._id,
		data.Serial,
		data.IsTradeable
	)
end

local function InspectStoreSkin(p: string, p2: string, p3: string?) -- 2 equivalent calls inferred from this helper
	Router.broadcastRouter("WeaponInspect", p, p2, 0, nil, nil, nil, nil, p3, 1, nil, 1, nil, true, true)
end

local function SetConsoleOverlay(flag: boolean)
	local openCase = parent4.Menu.OpenCase
	local contents = openCase.Contents
	local close = contents.Close

	if flag then
		if v17 then
			return
		end

		local guiObjects = {}

		for _, v20 in ipairs({ openCase, contents }) do
			for _, guiObject in ipairs(v20:GetChildren()) do
				if not (guiObject:IsA("GuiObject") and guiObject ~= contents and guiObject ~= close and guiObject.Visible) then
					continue
				end

				table.insert(guiObjects, guiObject)
				guiObject.Visible = false
			end
		end

		v17 = guiObjects
		close.TextLabel.Text = "SKIP"
		close.Visible = true
		contents.Visible = true
		openCase.Visible = true
	elseif v17 then
		for _, v20 in ipairs(v17) do
			v20.Visible = true
		end

		close.TextLabel.Text = "CLOSE"
		v17 = nil
	end
end

local function ResetConsoleOpening() -- 2 equivalent calls inferred from this helper
	v13.isOpening = false
	v13.currentInventoryItem = nil
	v13.currentCaseIdentifier = nil
	CaseSceneController.CancelConsoleOpening()
	local close = parent4.Menu.OpenCase.Contents.Close

	if v17 then
		for _, v20 in ipairs(v17) do
			v20.Visible = true
		end

		close.TextLabel.Text = "CLOSE"
		v17 = nil
	end

	parent4.Menu.OpenCase.Visible = false
	ShowCaseContentView() -- inferred equivalent call
	Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
end

function Store._RunConsoleInspectSweep(callback)
	local consoleInspectSweep = parent4:FindFirstChild("ConsoleInspectSweep")

	if consoleInspectSweep then
		consoleInspectSweep:Destroy()
	end

	local frame = Instance.new("Frame")
	frame.Name = "ConsoleInspectSweep"
	frame.Active = true
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromScale(-0.8, 0.5)
	frame.Rotation = 4
	frame.Size = UDim2.fromScale(1.2, 1.25)
	frame.ZIndex = 1000000
	frame.Parent = parent4
	local tween = TweenService:Create(frame, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(0.5, 0.5)
	})
	tween:Play()
	tween.Completed:Wait()
	local success, result = pcall(callback)
	RunService.RenderStepped:Wait()
	local tween2 = TweenService:Create(frame, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		Position = UDim2.fromScale(1.8, 0.5)
	})
	tween2:Play()
	tween2.Completed:Wait()
	frame:Destroy()

	if not success then
		error(result)
	end
end

local function GetInventoryItemDropSound(p) -- 2 equivalent calls inferred from this helper
	local v20 = (p.Type == "Melee" or p.Type == "Glove") and "Special" or p.Rarity or "Blue"
	return v10.RARITY_TO_DROP_SOUND[v20] or "Drop Blue"
end

fn = function(data, caseIdentifier: string, flag: boolean?)
	v16 = nil
	v13.isOpening = false
	v13.currentInventoryItem = nil
	v13.currentCaseIdentifier = caseIdentifier
	NotifyCaseOpenSequenceFinished() -- inferred equivalent call

	local function showInspect()
		CaseSceneController.HideCaseScene()
		local close = parent4.Menu.OpenCase.Contents.Close

		if v17 then
			for _, v20 in ipairs(v17) do
				v20.Visible = true
			end

			close.TextLabel.Text = "CLOSE"
			v17 = nil
		end

		parent4.Menu.OpenCase.Visible = false
		ReturnToStoreTabs() -- inferred equivalent call
		MenuState.SetScreen("Inventory")
		InspectInventoryItem(data) -- inferred equivalent call

		if MenuState.IsInspectActive() and not flag then
			Router.broadcastRouter("RunStoreSound", GetInventoryItemDropSound(data)) -- inferred equivalent call
		end
	end

	Store._RunConsoleInspectSweep(showInspect)
	Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
end

local function CleanupCaseOpeningTweens()
	if v13.currentTween then
		v13.currentTween:Cancel()
		v13.currentTween = nil
	end

	if v13.currentZoomTween then
		v13.currentZoomTween:Cancel()
		v13.currentZoomTween = nil
	end

	if v13.renderConnection then
		v13.renderConnection:Disconnect()
		v13.renderConnection = nil
	end

	if v13.viewportConnection then
		v13.viewportConnection:Disconnect()
		v13.viewportConnection = nil
	end
end

v10.CREDIT_PACKAGE_TIERS = { 400, 950, 3100, 6500, 13250 }

local function GetDeveloperProductNameForAmount(p: number)
	for _, v20 in v10.CREDIT_PACKAGE_TIERS do
		if p <= v20 then
			return `+ {CommaNumber(v20)} Credits`
		end
	end

	return "+ 27,000 Credits"
end

function Store.IsStarterPackAvailable()
	return StarterPack.IsAvailable()
end

function Store.IsStarterPackShown()
	return StarterPack.IsShown()
end

function Store.GetStarterPackRemainingSeconds()
	return StarterPack.GetState().RemainingSeconds
end

function Store.GetStarterPackWindowSeconds()
	return StarterPack.WINDOW_SECONDS
end

function Store.GetActiveBundleRemainingSeconds(p: number?)
	local TimerController = require(ReplicatedStorage.Controllers.TimerController)
	local receivedAt2 = p or math.floor((workspace:GetServerTimeNow()))
	local tick = v11.Tick

	if tick <= 0 then
		tick = TimerController.GetTimer(v11.Source)

		if tick > 0 then
			v11.Tick = tick
			v11.ReceivedAt = receivedAt2
		else
			return 0
		end
	end

	if tick > 1000000000000 then
		return (math.max(0, (math.floor(tick / 1000 - receivedAt2))))
	end

	if tick > 1000000000 then
		return (math.max(0, (math.floor(tick - receivedAt2))))
	end

	local receivedAt = v11.ReceivedAt

	if receivedAt <= 0 then
		v11.ReceivedAt = receivedAt2
		receivedAt = receivedAt2
	end

	return (math.max(0, (math.floor(tick - (receivedAt2 - receivedAt)))))
end

function Store.GetFeaturedConsoleTimerText(p: number?)
	local activeBundleRemainingSeconds = Store.GetActiveBundleRemainingSeconds(p)

	if activeBundleRemainingSeconds <= 0 then
		return "LIMITED TIME!"
	end

	return FormatDuration(activeBundleRemainingSeconds, "Always")
end

function Store.RefreshFeaturedConsoleTimer(p: number?)
	if v11.Label then
		v11.Label.Text = Store.GetFeaturedConsoleTimerText(p)
	end
end

local function ActivateCategoryButton(button)
	local size = button.Size
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, tweenInfo, { Size = MultiplyUdim2(size, 0.9) }):Play() -- inferred equivalent call
		Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, tweenInfo, { Size = size }):Play()
	end)
	button.MouseButton1Click:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
	end)
end

local function IsLimitedSpecialCase(p) -- 4 equivalent calls inferred from this helper
	return p.caseRarity == "Special" and Cases.IsLimited(p)
end

local function CountMatchingCases(name: string)
	local count2 = 0

	for _, v20 in ipairs(DataController.Get(LocalPlayer, "Inventory") or {}) do
		if (v20.Type == "Case" or v20.Type == "Package") and v20.Skin == name then
			count2 += 1
		end
	end

	return count2
end

local function CollectCaseIdentifiers(name: string, text: number)
	local inventory = DataController.Get(LocalPlayer, "Inventory")
	local ids = {}

	for _, v20 in ipairs(inventory or {}) do
		if text <= #ids then
			break
		end

		if (v20.Type == "Case" or v20.Type == "Package") and v20.Skin == name then
			table.insert(ids, v20._id)
		end
	end

	return ids
end

local function FilterAmountButtons(scroll, p: number)
	for _, button in ipairs(scroll:GetChildren()) do
		if button:IsA("TextButton") then
			button.Visible = (tonumber(button.Name) or 0) <= p
		end
	end
end

local function SelectAmountButton(instance, p)
	for _, button in ipairs(instance:GetChildren()) do
		if not button:IsA("TextButton") then
			continue
		end

		local v20 = button == p or button.Name == p
		button.Frame.BackgroundTransparency = v20 and 0 or 1
		button:SetAttribute("Selected", v20)
	end
end

local function RefreshCaseAmountButtons()
	local v20 = v8

	if not (v20 and parent3.CaseContent.Visible) then
		return
	end

	local amount = parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount
	local scroll = amount.Container.Scroll
	local v21

	if parent3.CaseContent:GetAttribute("State") == "Open" then
		v21 = CountMatchingCases(v20.name)
	else
		v21 = math.max(
			1,
			(math.floor((tonumber(DataController.Get(LocalPlayer, "Credits")) or 0) / math.max(v20.price, 1)))
		)
	end

	FilterAmountButtons(scroll, v21)
	local v22 = nil

	for _, button in scroll:GetChildren() do
		if not (button:IsA("TextButton") and button:GetAttribute("Selected")) then
			continue
		end

		v22 = button
		break
	end

	if v22 and not v22.Visible then
		SelectAmountButton(scroll, "1")
		amount.Header.TextLabel.Text = "1"
	end
end

local function ResetBulkOpeningState() -- 2 equivalent calls inferred from this helper
	v19.isBulkOpening = false
	v19.inventoryItems = nil
	v19.bulkIdentifier = nil
	v19.currentIndex = 0
	v19.skipped = false
	v19.caseId = nil
	v19.total = 0
end

local function GetUnboxedItemRarity(currentInventoryItem, case)
	if currentInventoryItem.Type == "Melee" or currentInventoryItem.Type == "Glove" then
		return "Special"
	end

	for _, content in ipairs(case.contents) do
		if
			content.skin.skinName == currentInventoryItem.Skin
			and content.skin.weaponName == currentInventoryItem.Name
		then
			return content.rarity or "Blue"
		end
	end

	return "Blue"
end

local function purchaseCase(p, text: number)
	local credits = DataController.Get(LocalPlayer, "Credits")
	local v20 = p.price * text

	if v20 <= credits then
		Remotes.Store.PurchaseCase.Send({ CaseId = p.caseId, Amount = text })
	elseif v4 then
		MarketplaceService:PromptProductPurchase(
			LocalPlayer,
			DevProducts[GetDeveloperProductNameForAmount(v20 - credits)].DevProductId
		)
		fn2("Store")
		Store.OpenTab("Credits")
	end
end

local function createCaseTemplate(data, cases, layoutOrder: number, flag: boolean)
	if cases:FindFirstChild(data.caseId) then
		return
	end

	Profiler.mark("UI.Store.CreateCaseTemplate")
	local rarity = Rarities[data.caseRarity]

	if rarity then
		local clone = ReplicatedStorage.Assets.UI.Store.CaseTemplate:Clone()
		local v20

		if Cases2[data.name] then
			v20 = Cases2[data.name].Amounts[1] or nil
		end

		if v20 and v20.BasePrice and v20.Price < v20.BasePrice then
			local v21 = math.floor((v20.BasePrice - v20.Price) / ((v20.BasePrice + v20.Price) / 2) * 100)
			clone.Discount.Discount.Title.Text = `-{v21}%`
		end

		clone.Discount.Visible = false

		if IsLimitedSpecialCase(data) then -- inferred equivalent call
			clone.Discount.Discount.Title.Text = "LIMITED"
			clone.Discount.Visible = true
		elseif flag then
			clone.Discount.Discount.Title.Text = "NEW"
			clone.Discount.Visible = true
		end

		clone.Contents.Glow.ImageColor3 = rarity.Color
		clone.Contents.Pattern.ImageColor3 = rarity.Color
		clone.Contents.Rarity.BackgroundColor3 = rarity.Color
		clone.Contents.Icon.Image = data.imageAssetId
		clone.Footer.CaseName.Text = data.name
		clone.LayoutOrder = layoutOrder
		clone.Parent = cases
		clone.Name = data.caseId
		ActivateButton(clone.Purchase)
		clone.Purchase.MouseButton1Click:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			Store.OpenCaseContent(data.caseId, "Inspect")
		end)
		ActivateButton(clone.Gift)
		clone.Gift.MouseButton1Click:Connect(function()
			fn4(data.caseId, "Case")
		end)
	end
end

local function activateGiftTemplate(clone, p)
	local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	clone.Button.MouseEnter:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Highlight")
		TweenService:Create(clone.Player.Username, tweenInfo, {
			TextColor3 = Color3.fromRGB(255, 200, 0)
		}):Play()
	end)
	clone.Button.MouseLeave:Connect(function()
		TweenService:Create(clone.Player.Username, tweenInfo, {
			TextColor3 = Color3.fromRGB(190, 190, 190)
		}):Play()
	end)
	clone.Button.MouseButton1Click:Connect(function()
		if p == LocalPlayer.UserId then
			return
		end

		local giftProductName = parent3:GetAttribute("GiftProductName")
		local giftProductType = parent3:GetAttribute("GiftProductType")
		Router.broadcastRouter("RunInterfaceSound", "UI Click")

		if giftProductType == "Case" then
			local credits = DataController.Get(LocalPlayer, "Credits")
			local case = Cases.GetCase(giftProductName)
			local text = tonumber(parent3.Gift.Amount.Header.TextLabel.Text) or 1

			if credits < case.price * text then
				return
			end

			parent3.Gift.Visible = false
			Remotes.Store.GiftCase.Send({
				RecipientUserId = tostring(p),
				CaseId = giftProductName,
				Amount = text
			})
		else
			Remotes.Store.CreateGift.Send({
				RecipientUserId = tostring(p),
				ProductName = giftProductName,
				ProductType = giftProductType
			})

			if giftProductType == "Gamepass" then
				MarketplaceService:PromptGamePassPurchase(LocalPlayer, Gamepasses[giftProductName].GamepassId)
			elseif giftProductType == "DevProduct" then
				local tradeTokens = DataController.Get(LocalPlayer, "TradeTokens")

				if
					string.find(giftProductName, "Trade Tokens", 1, true) ~= nil
					or not (DevProducts[giftProductName].Price and DevProducts[giftProductName].Price <= tradeTokens)
				then
					MarketplaceService:PromptProductPurchase(LocalPlayer, DevProducts[giftProductName].DevProductId)
				else
					DoCreditPurchase(giftProductName, DevProducts[giftProductName])
				end
			end
		end
	end)
end

local function CanInspect()
	return next(v14) == nil
end

local function WireCaseItemInspect(button, weaponName: string, p: string, p2: string?)
	local itemContent = button:FindFirstChild("ItemContent")

	for _, childName in { "Inspect", "MobileInspect" } do
		local guiObject = itemContent and itemContent:FindFirstChild(childName)

		if guiObject and guiObject:IsA("GuiObject") then
			guiObject.Visible = false
		end
	end

	if button:IsA("GuiButton") then
		button.Active = true
		button.Selectable = true
		button.Activated:Connect(function()
			if next(v14) ~= nil then
				return
			end

			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			InspectStoreSkin(weaponName, p, p2) -- inferred equivalent call
		end)
	end
end

local function GetItemArtBounds(guiObject)
	local icon = guiObject:FindFirstChild("Icon")

	if not (icon and icon:IsA("GuiObject")) then
		return nil, nil
	end

	local icon2 = icon:FindFirstChild("Icon") or icon:FindFirstChild("Placeholder")

	if icon2 then
		if not icon2:IsA("GuiObject") then
			icon2 = icon
		end
	else
		icon2 = icon
	end

	local absoluteSize = icon2.AbsoluteSize
	local v20 = math.min(absoluteSize.X, absoluteSize.Y)

	if v20 <= 0 then
		return nil, nil
	end

	return icon2.AbsolutePosition + absoluteSize / 2, Vector2.new(v20, v20) / 2
end

local function ResolvePressedItem(p, items, point: Vector2)
	local v20 = 1e999

	for guiObject, item in items do
		local v21, v22 = GetItemArtBounds(guiObject)

		if not (guiObject:IsA("GuiObject") and guiObject.Visible and v21 and v22) then
			continue
		end

		local v23 = (point - v21) / v22
		local v24 = math.max(math.abs(v23.X), (math.abs(v23.Y)))

		if not (v24 < v20) then
			continue
		end

		p = item
		v20 = v24
	end

	return p
end

local function SetupTaggedInspectButtons(tag: string)
	local v20 = {}

	for _, v21 in ipairs(CollectionService:GetTagged(tag)) do
		if not v21:IsDescendantOf(parent3) then
			continue
		end

		local weaponName = v21:GetAttribute("WeaponName")
		local skinName = v21:GetAttribute("SkinName")

		if typeof(weaponName) == "string" and typeof(skinName) == "string" then
			local inspect = v21:FindFirstChild("Inspect")

			if inspect and inspect:IsA("GuiObject") then
				inspect.Visible = false
			end

			local hoverFrame = v21:FindFirstChild("HoverFrame")

			if hoverFrame and hoverFrame:IsA("GuiButton") then
				local v22 = { WeaponName = weaponName, SkinName = skinName }
				local parent = v21.Parent
				local v23 = v20[parent]

				if not v23 then
					v23 = {}
					v20[parent] = v23
				end

				v23[v21] = v22
				hoverFrame.Activated:Connect(function(p)
					if next(v14) ~= nil then
						return
					end

					local v24 = v22
					local v25

					if p == nil then
						v25 = false
					else
						v25 = p.UserInputType == Enum.UserInputType.MouseButton1
							or p.UserInputType == Enum.UserInputType.Touch
					end

					if p and v25 then
						v24 = ResolvePressedItem(v22, v23, Vector2.new(p.Position.X, p.Position.Y))
					end

					Router.broadcastRouter("RunInterfaceSound", "UI Click")
					InspectStoreSkin(v24.WeaponName, v24.SkinName, nil) -- inferred equivalent call
				end)
			else
				warn(`[Store] {v21:GetFullName()} is missing its HoverFrame button.`)
			end
		else
			warn(`[Store] {v21:GetFullName()} is missing WeaponName/SkinName attributes.`)
		end
	end
end

local function setupCurrencyFrame(frame, flag: boolean)
	local devProduct = DevProducts[frame.Name]
	local purchase_Button = frame:FindFirstChild("Purchase_Button", true)

	if purchase_Button and purchase_Button:IsA("GuiButton") then
		local function fn7(p)
			if flag then
				local title = purchase_Button:FindFirstChild("Title", true)

				if title and title:IsA("TextLabel") then
					title.Text = `{utf8.char(57346)}{CommaNumber(p)}`
				end
			else
				purchase_Button.Container.Title.Text = `{utf8.char(57346)} {CommaNumber(p)}`
			end
		end

		LoadProductPrice(devProduct, fn7) -- inferred equivalent call
		ActivateButton(purchase_Button)
		purchase_Button.MouseButton1Click:Connect(function()
			if v4 then
				local tradeTokens = DataController.Get(LocalPlayer, "TradeTokens")

				if flag or not (devProduct.Price and devProduct.Price <= tradeTokens) then
					MarketplaceService:PromptProductPurchase(LocalPlayer, devProduct.DevProductId)
				else
					DoCreditPurchase(frame.Name, devProduct)
				end

				Router.broadcastRouter("RunInterfaceSound", "UI Click")
			end
		end)
	end

	local gift_Button = frame:FindFirstChild("Gift_Button", true)

	if gift_Button and gift_Button:IsA("GuiButton") then
		ActivateButton(gift_Button)
		gift_Button.MouseButton1Click:Connect(function()
			fn4("Gift " .. frame.Name, "DevProduct")
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
		end)
	end
end

local function sortCasesByNewest(p, p2)
	local limitedSpecialCase = IsLimitedSpecialCase(p) -- inferred equivalent call

	if limitedSpecialCase ~= IsLimitedSpecialCase(p2) then -- inferred equivalent call
		return limitedSpecialCase
	end

	local creationTimestamp = Cases.GetCreationTimestamp(p)
	local creationTimestamp2 = Cases.GetCreationTimestamp(p2)

	if creationTimestamp and creationTimestamp2 then
		if creationTimestamp ~= creationTimestamp2 then
			return creationTimestamp2 < creationTimestamp
		end
	elseif creationTimestamp or creationTimestamp2 then
		return creationTimestamp ~= nil
	end

	if p.displayOrder == p2.displayOrder then
		return Cases.GetBackendOrder(p) < Cases.GetBackendOrder(p2)
	end

	return p.displayOrder < p2.displayOrder
end

local v20 = nil

local function fitCaseGrid(cases)
	local uiGridLayout = cases:FindFirstChildOfClass("UIGridLayout")
	local parent = cases.Parent
	local parent2 = parent.Parent
	local frame = parent2:FindFirstChild("Frame")
	local uiListLayout = parent2:FindFirstChildOfClass("UIListLayout")
	local uiPadding = parent:FindFirstChildOfClass("UIPadding")
	local absoluteSize = cases.AbsoluteSize

	if not uiGridLayout or not uiListLayout or not uiPadding or absoluteSize.X <= 0 then
		return
	end

	local v21 = uiGridLayout.CellSize.X.Scale * absoluteSize.X + uiGridLayout.CellSize.X.Offset

	if v21 <= 0 then
		return
	end

	local v22 = v20

	if not v22 then
		if absoluteSize.Y <= 0 then
			return
		end

		local function pixels(udim: UDim, y: number) -- 5 equivalent calls inferred from this helper
			return (udim.Scale * y + udim.Offset) / v21
		end

		v22 = {
			cellAspect = 0,
			rowPadding = 0,
			header = 0,
			sectionPadding = 0,
			holderPaddingTop = 0,
			holderPaddingBottom = 0
		}
		v22.cellAspect = pixels(uiGridLayout.CellSize.Y, absoluteSize.Y) -- inferred equivalent call
		v22.rowPadding = pixels(uiGridLayout.CellPadding.Y, absoluteSize.Y) -- inferred equivalent call
		v22.header = not frame and 0 or frame.AbsoluteSize.Y / v21
		v22.sectionPadding = pixels(uiListLayout.Padding, parent2.AbsoluteSize.Y) -- inferred equivalent call
		v22.holderPaddingTop = pixels(uiPadding.PaddingTop, parent.AbsoluteSize.Y) -- inferred equivalent call
		v22.holderPaddingBottom = pixels(uiPadding.PaddingBottom, parent.AbsoluteSize.Y) -- inferred equivalent call
		v20 = v22
	end

	local count2 = 0

	for _, guiObject in ipairs(cases:GetChildren()) do
		if guiObject:IsA("GuiObject") then
			count2 += 1
		end
	end

	local v23 = uiGridLayout.CellPadding.X.Scale * absoluteSize.X + uiGridLayout.CellPadding.X.Offset
	local v24 = math.max(
		1,
		(math.ceil(count2 / math.max(1, (math.floor((absoluteSize.X + v23) / (v21 + v23) + 0.001)))))
	)
	local v25 = math.round(v21 * v22.cellAspect)
	local v26 = math.round(v21 * v22.rowPadding)
	local v27 = v24 * v25 + (v24 - 1) * v26
	local v28 = math.round(v21 * v22.holderPaddingTop)
	local v29 = math.round(v21 * v22.holderPaddingBottom)
	uiGridLayout.CellSize = UDim2.new(uiGridLayout.CellSize.X, UDim.new(0, v25))
	uiGridLayout.CellPadding = UDim2.new(uiGridLayout.CellPadding.X, UDim.new(0, v26))
	cases.Size = UDim2.new(cases.Size.X, UDim.new(0, v27))
	uiPadding.PaddingTop = UDim.new(0, v28)
	uiPadding.PaddingBottom = UDim.new(0, v29)
	parent.AutomaticSize = Enum.AutomaticSize.None
	parent.Size = UDim2.new(parent.Size.X, UDim.new(0, v27 + v28 + v29))
	local v30 = math.round(v21 * v22.sectionPadding)
	local v31 = not frame and 0 or math.round(v21 * v22.header)
	uiListLayout.Padding = UDim.new(0, v30)

	if frame then
		frame.Size = UDim2.new(frame.Size.X, UDim.new(0, v31))
	end

	local v32 = v27 + v28 + v29
	parent2.AutomaticSize = Enum.AutomaticSize.None
	parent2.Size = UDim2.new(parent2.Size.X, UDim.new(0, v32 + (not frame and 0 or v31 + v30)))
end

local function updateCases()
	Profiler.mark("UI.Store.UpdateCases")
	local cases = parent3.Tabs.Container.Featured.Container.Cases.Container.Cases
	ClearFrame(cases, { "UIListLayout", "UIGridLayout" })
	local v21 = {}

	for _, v22 in ipairs(Cases.GetCases()) do
		if v22.caseType ~= "Package" and v22.caseType ~= "Console" then
			table.insert(v21, v22)
		end
	end

	table.sort(v21, sortCasesByNewest)
	local v22 = -1e999
	local v23 = nil

	for _, v24 in ipairs(v21) do
		local creationTimestamp = Cases.GetCreationTimestamp(v24)

		if not creationTimestamp or not (v22 < creationTimestamp) or IsLimitedSpecialCase(v24) then -- inferred equivalent call
			continue
		end

		v23 = v24
		v22 = creationTimestamp
	end

	for i, v24 in ipairs(v21) do
		local v25

		if v23 then
			v25 = v24 == v23
		else
			v25 = v24.isFeatured
		end

		createCaseTemplate(v24, cases, i, v25)
	end
end

local function GetRarityChance(p: string, items)
	for _, item in items do
		if item.rarity == p then
			return item.chance
		end
	end

	return 0
end

local function FormatOdds(p: number)
	local v21 = math.round(p * 10000) / 10000

	if v21 == math.floor(v21) then
		return string.format("%.1f", v21)
	end

	if math.abs(v21 * 100 - math.round(v21 * 100)) < 1e-6 then
		return string.format("%.2f", v21)
	end

	return (string.gsub(string.format("%.4f", v21), "0+$", ""))
end

local function GetBaseSkinName(value: string) -- 2 equivalent calls inferred from this helper
	if value:find("_PATTERN_") then
		return value:split("_PATTERN_")[1]
	end

	return value
end

local function buildItemOdds(skinInformation, items, p)
	local itemOddsFrame = parent3.CaseContent.Main.ItemOddsFrame
	local container = itemOddsFrame.Container

	if itemOddsFrame:FindFirstChild("List") then
		itemOddsFrame.List.Visible = false
	end

	container.AutomaticCanvasSize = Enum.AutomaticSize.Y
	container.CanvasSize = UDim2.fromScale(0, 0)
	container.ScrollingDirection = Enum.ScrollingDirection.Y
	local v21 = {
		KillTrakHeader = container.KillTrakHeader,
		ConditionsHeader = container.ConditionsHeader,
		PatternsHeader = container.PatternsHeader,
		KillTrakTemplate = container.KillTrakTemplate,
		PatternTemplate = container.PatternTemplate,
		FactoryNew = container:FindFirstChild("Factory New"),
		MinimalWear = container:FindFirstChild("Minimal Wear"),
		FieldTested = container:FindFirstChild("Field-Tested"),
		WellWorn = container:FindFirstChild("Well-Worn"),
		BattleScarred = container:FindFirstChild("Battle-Scarred")
	}
	local v22 = {}

	for _, frame in pairs(v21) do
		if not (frame and frame:IsA("Frame")) then
			continue
		end

		v22[frame] = true
		frame.Visible = false
	end

	for _, frame in ipairs(container:GetChildren()) do
		if not frame:IsA("Frame") or v22[frame] then
			continue
		end

		frame:Destroy()
	end

	local total = 0

	local function nextLayoutOrder() -- 1 equivalent call inferred from this helper
		total += 10
		return total
	end

	local function setOddsRow(instance, text: string, p2: number, color2: Color3)
		instance.Visible = true
		local left = instance:FindFirstChild("Left")

		if left then
			local label = left:FindFirstChild("Label") or left:FindFirstChild("Title")

			if label and label:IsA("TextLabel") then
				label.Text = text
				label.TextColor3 = color2
			end

			local percent = left:FindFirstChild("Percent")

			if percent and percent:IsA("TextLabel") then
				percent.Text = string.format("%.2f%%", p2)
			end
		end

		local bar = instance:FindFirstChild("Bar")
		local current = bar and bar:FindFirstChild("Current")

		if current and current:IsA("Frame") then
			current.Size = UDim2.new(math.clamp(p2 / 100, 0, 1), 0, 1, 0)
			current.BackgroundColor3 = color2
		end
	end

	local function cloneTemplate(instance, wear: string) -- 6 equivalent calls inferred from this helper
		local clone = instance:Clone()
		clone.Name = wear
		clone.LayoutOrder = nextLayoutOrder() -- inferred equivalent call
		clone.Visible = true
		clone.Parent = container
		return clone
	end

	local function setHeaderText(instance, text: string) -- 3 equivalent calls inferred from this helper
		local textLabel = instance:FindFirstChildWhichIsA("TextLabel", true)

		if textLabel then
			textLabel.Text = text
		end
	end

	if skinInformation.type ~= "Glove" then
		setHeaderText(cloneTemplate(v21.KillTrakHeader, "KillTrakHeader"), "General:") -- inferred equivalent call
		setOddsRow(
			cloneTemplate(v21.KillTrakTemplate, "KillTrak"), -- inferred equivalent call
			"KillTrak™",
			skinInformation.statTrakChance,
			Color3.fromRGB(255, 132, 32)
		)
	end

	setHeaderText(cloneTemplate(v21.ConditionsHeader, "ConditionsHeader"), "Conditions:") -- inferred equivalent call
	local v23 = {
		["Factory New"] = { v21.FactoryNew, "Mint Condition", Color3.fromRGB(0, 255, 127) },
		["Minimal Wear"] = { v21.MinimalWear, "Near-Mint", Color3.fromRGB(0, 170, 255) },
		["Field-Tested"] = { v21.FieldTested, "Standard-Grade", Color3.fromRGB(255, 255, 0) },
		["Well-Worn"] = { v21.WellWorn, "Combat-Worn", Color3.fromRGB(255, 85, 0) },
		["Battle-Scarred"] = { v21.BattleScarred, "War-Torn", Color3.fromRGB(255, 0, 0) }
	}

	for _, floatChance in ipairs(skinInformation.floatChances) do
		local v24 = v23[floatChance.wear]

		if not v24 or not v24[1] or floatChance.chance <= 0 then
			continue
		end

		setOddsRow(cloneTemplate(v24[1], floatChance.wear), v24[2], floatChance.chance, v24[3]) -- inferred equivalent call
	end

	local v24 = {}
	local count2 = 0

	for _, item in items do
		if not (item.skin.skinName:find("_PATTERN_") and p.representativeSkinName:find("_PATTERN_")) then
			continue
		end

		v24[item.skin.skinName] = true
		count2 += 1
	end

	if count2 > 0 then
		setHeaderText(cloneTemplate(v21.PatternsHeader, "PatternsHeader"), "Patterns:") -- inferred equivalent call
		local v25 = 1 / count2 * 100
		local v26 = total

		for k in v24 do
			local _, v27 = table.unpack(k:split("_PATTERN_"))
			local template = cloneTemplate(v21.PatternTemplate, "PatternTemplate") -- inferred equivalent call
			template.LayoutOrder = v26 + (tonumber(v27) or 0)
			setOddsRow(template, `Pattern #{v27}`, v25, Color3.fromRGB(255, 255, 255))
		end
	end

	local title = itemOddsFrame.Header.Title
	title.Text = `ITEM ODDS - "{p.weaponName} | {GetBaseSkinName(p.representativeSkinName)}"` -- inferred equivalent call
	itemOddsFrame.Visible = true
end

local function RenderGroupedOdds(list, callback, container, p: string)
	if list == nil then
		return
	end

	if typeof(list) ~= "table" then
		warn(`[Store.RenderGroupedOdds] Expected {p} to be a table; no odds rows were rendered`)
		return
	end

	local count2 = 0
	local v21 = {}
	local v22 = {}
	local v23 = {}

	for _, v24 in ipairs(list) do
		local skin

		if typeof(v24) == "table" and typeof(v24.skin) == "table" then
			skin = v24.skin
		end

		if
			skin
			and typeof(skin.weaponName) == "string"
			and skin.weaponName ~= ""
			and typeof(skin.skinName) == "string"
			and skin.skinName ~= ""
			and Rarities[v24.rarity]
		then
			table.insert(v21, v24)
			local baseSkinName = GetBaseSkinName(skin.skinName) -- inferred equivalent call
			local formatted = `{skin.weaponName}|{baseSkinName}`

			if not v22[formatted] then
				local v25 = {
					weaponName = skin.weaponName,
					baseSkinName = baseSkinName,
					representativeSkinName = skin.skinName,
					rarity = v24.rarity,
					itemType = skin.type == "Charm" and "Charm" or nil
				}
				v22[formatted] = v25
				table.insert(v23, v25)
			end
		else
			count2 += 1
		end
	end

	if count2 > 0 then
		warn(`[Store.RenderGroupedOdds] Skipped {count2} malformed {p}; each entry must contain skin.weaponName, skin.skinName, and a known rarity`)
	end

	for _, v24 in ipairs(v23) do
		local v25 = callback(v24, v23)
		local text = GetSkinDisplayName(v24.baseSkinName, false)
		local rarity = Rarities[v24.rarity]
		local skinInformation = Skins.GetSkinInformation(v24.weaponName, v24.representativeSkinName)
		local storeItemIcon = CaseScroll.GetStoreItemIcon(skinInformation)
		local clone = ReplicatedStorage.Assets.UI.Store.OddTemplate:Clone()
		clone.ItemTemplate.ItemContent.Content.Icon.Image = storeItemIcon
		clone.ItemTemplate.ItemContent.Content.Rarity.ImageColor3 = rarity.Color
		clone.ItemTemplate.ItemContent.Rarity.BackgroundColor3 = rarity.Color
		clone.ItemTemplate.ItemContent.SkinName.Text = text
		clone.ItemTemplate.ItemContent.WeaponName.Text = v24.weaponName
		clone.Label.Text = `{FormatOdds(v25)}%`
		clone.Label.UIGradient.Color = rarity.ColorSequence
		clone.LayoutOrder = 100 - v25
		clone.Parent = container
		local itemOdds = clone:FindFirstChild("ItemOdds")

		if itemOdds and skinInformation then
			ActivateButton(itemOdds)
			local v26 = v24
			itemOdds.MouseButton1Click:Connect(function()
				buildItemOdds(skinInformation, v21, v26)
			end)
		elseif itemOdds and itemOdds:IsA("GuiObject") then
			itemOdds.Visible = false
		end

		WireCaseItemInspect(clone.ItemTemplate, v24.weaponName, v24.representativeSkinName, v24.itemType)
	end
end

local function UpdateCasePurchaseButtons(p)
	local subButtons = parent3.CaseContent.Main.Bottom.SubButtons
	local cas = Cases2[p.name]
	local isCaseForSale = Cases.IsCaseForSale(p.caseId)
	local visible = false

	for _, button in ipairs(subButtons.CenterButtons:GetChildren()) do
		if button:IsA("GuiButton") then
			button.Visible = false
		end
	end

	if cas and v4 and (isCaseForSale or RunService:IsStudio()) then
		for k, amount in cas.Amounts do
			local button = subButtons.CenterButtons:FindFirstChild((tostring(k)))

			if not (button and button:IsA("GuiButton")) then
				continue
			end

			button.Visible = amount.Offsale == false
			visible = visible or button.Visible
			button.Container.Title.Text = `{CommaNumber(amount.Price)}`
		end
	end

	subButtons.Visible = visible
end

local function RefreshCaseListings() -- 1 equivalent call inferred from this helper
	updateCases()

	if v8 and parent3.CaseContent.Visible then
		UpdateCasePurchaseButtons(v8)
	end
end

local function StartBackgroundProductLoading()
	for _, devProduct in DevProducts do
		local _price = devProduct.Price
		local v21 = nil
		local v22 = devProduct
		LoadProductInfo(devProduct.DevProductId, function(p)
			if not (p and p.PriceInRobux) then
				return
			end

			v22.BasePrice = p.UserBasePriceInRobux or v22.Price
			v22.Price = p.PriceInRobux

			if v21 then
				v21(v22.Price)
			end
		end)
	end

	local v21 = 0

	local function CompleteRequest() -- 1 equivalent call inferred from this helper
		v21 -= 1

		if v21 == 0 then
			RefreshCaseListings() -- inferred equivalent call
		end
	end

	for _, cas in Cases2 do
		for _, amount in cas.Amounts do
			v21 += 1
			local v22 = amount
			LoadProductInfo(amount.ID, function(data)
				if data then
					v22.Offsale = not (data.IsForSale and data.PriceInRobux)

					if data.IsForSale and data.PriceInRobux then
						v22.BasePrice = data.UserBasePriceInRobux or v22.BasePrice
						v22.Price = data.PriceInRobux
					end
				end

				CompleteRequest() -- inferred equivalent call
			end)
		end
	end
end

function Store.OpenCaseContent(p: string, state: string, p2: string?)
	Profiler.mark("UI.Store.OpenCaseContent")
	local case = Cases.GetCase(p)
	v7 = p2
	v8 = case

	if case then
		UpdateCasePurchaseButtons(case)
		local visible = parent3.Visible
		local currentScreen = MenuState.GetCurrentScreen()
		local v21 = visible or currentScreen == "Store"

		if v21 then
			MenuState.SetScreen("Store")
		end

		parent3.CaseContent:SetAttribute("WasVisibleBeforeInspect", v21)
		parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Position = state == "Open"
			and UDim2.new(0.687, 0, 0.465, 0)
			or UDim2.new(0.575, 0, 0.465, 0)
		parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Buy.Container.Title.Text = `BUY <font color="#ffda0f">({CommaNumber(case.price)})</font>`
		local v22 = case.caseType == "Console"
		parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Visible = not v22 or state == "Open"
		parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Header.TextLabel.Text = "1"
		parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Buy.Visible = state == "Inspect"
		parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Open.Visible = state == "Open"
		parent3.CaseContent:SetAttribute("State", state)
		parent3.Tabs.Container.Visible = false
		parent3.CaseContent.Visible = true
		parent4.Menu.Top.Visible = false
		parent3.Top.Visible = false
		parent3.Visible = true
		SelectAmountButton(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Container.Scroll, "1")
		RefreshCaseAmountButtons()

		for _, frame in ipairs(parent3.CaseContent.Main.Odds.Frame.Container:GetChildren()) do
			if not (frame.Name ~= "INVIS" and frame:IsA("Frame")) then
				continue
			end

			if frame.Name == "Special" then
				frame.Visible = false
			else
				frame:Destroy()
			end
		end

		local v23 = {}
		local v24 = {}

		for _, content in case.contents do
			v23[content.rarity] = (v23[content.rarity] or 0) + 1
		end

		local v25 = {}
		local v26 = false

		for k in pairs(v23) do
			local flag = true
			local chance

			for _, rarityChance in case.rarityChances do
				if rarityChance.rarity ~= k then
					continue
				end

				chance = rarityChance.chance
				flag = false
				break
			end

			if flag then
				chance = 0
			end

			local v27 = chance or 0
			v25[k] = v27

			if v27 > 0 then
				v26 = true
			end
		end

		if not v26 then
			local total = 0
			local v27 = {}

			for _, content in ipairs(case.contents) do
				local weight = content.weight or 0
				total += weight
				v27[content.rarity] = (v27[content.rarity] or 0) + weight
			end

			local v28 = #case.contents

			for k, v29 in pairs(v23) do
				if total > 0 then
					v25[k] = (v27[k] or 0) / total * 100
				else
					v25[k] = v29 / math.max(v28, 1) * 100
				end
			end
		end

		local function GetDisplayRarityChance(p3) -- 3 equivalent calls inferred from this helper
			return v25[p3] or 0
		end

		local container = parent3.CaseContent.Main.Odds.Frame.Container
		parent3.CaseContent.Main.Odds.Visible = false

		local function getContentGroupOdds(p3, list)
			local count2 = 0

			for _, v27 in ipairs(list) do
				if v27.rarity == p3.rarity then
					count2 += 1
				end
			end

			return GetDisplayRarityChance(p3.rarity) / math.max(count2, 1) -- inferred equivalent call
		end

		local function getSpecialGroupOdds(_, list)
			return case.specialChance / math.max(#list, 1)
		end

		for _, content in ipairs(case.contents) do
			v24[`{content.skin.weaponName}_{content.skin.skinName}`] = GetDisplayRarityChance(content.rarity) / v23[content.rarity] -- inferred equivalent call
		end

		RenderGroupedOdds(case.contents, getContentGroupOdds, container, `contents for case "{p}"`)
		RenderGroupedOdds(case.specialContents, getSpecialGroupOdds, container, `special contents for case "{p}"`)
		local v27 = {}

		for _, content in ipairs(case.contents) do
			if content.rarity then
				v27[content.rarity] = true
			end
		end

		local function SetChanceRowText(instance, text) -- 2 equivalent calls inferred from this helper
			local right = instance:FindFirstChild("Right")
			local label = right and right:FindFirstChild("Label")

			if label then
				label.Text = text
			end
		end

		for childName in pairs(v10.RARITY_PRIORITY) do
			if childName == "Special" then
				continue
			end

			local child = parent3.CaseContent.Main.CaseChances:FindFirstChild(childName)

			if not child then
				continue
			end

			child.Visible = v27[childName] == true
			SetChanceRowText(child, `{math.round(GetDisplayRarityChance(childName) * 100) / 100}%`) -- inferred equivalent call
		end

		local visible2

		if case.specialContents == nil then
			visible2 = false
		else
			visible2 = #case.specialContents > 0
		end

		local special = parent3.CaseContent.Main.CaseChances:FindFirstChild("Special")

		if special then
			special.Visible = visible2
			SetChanceRowText(special, `{case.specialChance or 0}%`) -- inferred equivalent call
		end

		if parent4 and parent4.Menu then
			parent4.Menu.Visible = true
		end

		CaseSceneController.ShowCaseScene(case.caseType, case.name)
		Profiler.defer("UI.Store.CaseContentVisibilityDeferred", function()
			parent3.Visible = true
			parent3.CaseContent.Visible = true
		end)
		ClearFrame(parent3.CaseContent.Main.CaseContent.Container, { "UIGridLayout", "UIPadding" })

		if not parent3.CaseContent.Main.CaseContent.Visible then
			parent3.CaseContent.Main.CaseContent.Visible = true
		end

		local clone = table.clone(case.contents)
		table.sort(clone, function(a, b)
			return (v10.RARITY_PRIORITY[a.rarity] or 0) < (v10.RARITY_PRIORITY[b.rarity] or 0)
		end)

		for _, v28 in ipairs(clone) do
			local skinInformation = Skins.GetSkinInformation(v28.skin.weaponName, v28.skin.skinName)
			local rarity = Rarities[v28.rarity]
			local storeItemIcon = CaseScroll.GetStoreItemIcon(skinInformation)
			local text = GetSkinDisplayName(v28.skin.skinName, true)
			local clone2 = ReplicatedStorage.Assets.UI.Store.ItemTemplate:Clone()
			clone2.ItemContent.Content.Odds.Text = `{FormatOdds(v24[`{v28.skin.weaponName}_{v28.skin.skinName}`] or 0)}%`
			clone2.Bottom.Footer.WeaponName.Text = GetSkinDisplayName.GetWeaponDisplayName(v28.skin.weaponName)
			clone2.ItemContent.Rarity.BackgroundColor3 = rarity.Color
			clone2.ItemContent.Content.Rarity.ImageColor3 = rarity.Color
			clone2.Bottom.Footer.SkinName.Text = text
			clone2.Parent = parent3.CaseContent.Main.CaseContent.Container
			clone2.ItemContent.Content.Icon.Image = storeItemIcon
			local charm = clone2.ItemContent:FindFirstChild("Charm")

			if charm and charm:IsA("ImageLabel") then
				charm.Visible = false
			end

			local v29 = v28.skin.type == "Charm" and "Charm" or nil
			WireCaseItemInspect(clone2, v28.skin.weaponName, v28.skin.skinName, v29)
		end

		local specialContents = case.specialContents
		local v28 = case.caseType == "Case"

		if v28 or specialContents and #specialContents > 0 then
			local clone2 = ReplicatedStorage.Assets.UI.Store.GoldTemplate:Clone()
			clone2.Selectable = true
			clone2.Content.Content.Odds.Text = v28 and "0.26%" or `{FormatOdds(case.specialChance or 0)}%`
			clone2.Content.Icon.Image = v10.SPECIAL_CASE_ICONS[case.caseId] or v10.DEFAULT_CASE_ICON
			clone2.Parent = parent3.CaseContent.Main.CaseContent.Container
			ApplySpecialCardEffect(clone2)
		end
	end
end

local function GetGiftRecipientButtons()
	local buttons = {}

	for _, guiObject in ipairs(parent3.Gift.Container:GetChildren()) do
		local button = guiObject:IsA("GuiObject") and guiObject.Visible and guiObject:FindFirstChild("Button")

		if button and button:IsA("GuiButton") then
			table.insert(buttons, button)
		end
	end

	return buttons
end

local function IsSelectionUsable(parent)
	if not (parent and parent.Parent and parent.Selectable) then
		return false
	end

	while parent and not parent:IsA("ScreenGui") do
		if parent:IsA("GuiObject") and not parent.Visible then
			return false
		else
			parent = parent.Parent
		end
	end

	return parent ~= nil
end

local function refreshGiftNavigation()
	local gift = parent3.Gift
	local v21 = { gift.Search.TextBox }

	for _, v22 in ipairs((GetGiftRecipientButtons())) do
		table.insert(v21, v22)
	end

	if gift.Amount.Visible then
		table.insert(v21, gift.Amount)

		if gift.Amount.Container.Visible then
			for _, button in ipairs(gift.Amount.Container:GetChildren()) do
				if button:IsA("TextButton") then
					table.insert(v21, button)
				end
			end
		end
	end

	table.insert(v21, gift.Close)

	for i, v22 in ipairs(v21) do
		v22.NextSelectionUp = v21[i - 1] or v21[#v21]
		v22.NextSelectionDown = v21[i + 1] or v21[1]
		v22.NextSelectionLeft = v22
		v22.NextSelectionRight = v22
	end

	if not (selectedObject and gift.Visible) then
		return
	end

	local selectedObject2 = GuiService.SelectedObject

	if not (selectedObject2 and selectedObject2:IsDescendantOf(gift) and IsSelectionUsable(selectedObject2)) then
		GuiService.SelectedObject = GetGiftRecipientButtons()[1] or gift.Search.TextBox
	end
end

fn4 = function(giftProductName: string, giftProductType: string)
	parent3:SetAttribute("GiftProductName", giftProductName)
	parent3:SetAttribute("GiftProductType", giftProductType)
	local amount = parent3.Gift.Amount
	amount.Header.TextLabel.Text = "1"
	amount.Visible = giftProductType == "Case"
	amount.Container.Visible = false
	SelectAmountButton(amount.Container, "1")
	parent3.Gift.Visible = true
	selectedObject = GuiService.SelectedObject
	refreshGiftNavigation()
end

local function PopulateGiftSearchResult(text: string)
	local searchResult = parent3.Gift.Container:FindFirstChild("SearchResult")

	if searchResult then
		searchResult:Destroy()
	end

	local v21 = tonumber(text)

	if text == "" or not v21 then
		return
	end

	for _, frame in ipairs(parent3.Gift.Container:GetChildren()) do
		if frame:IsA("Frame") then
			frame.Visible = false
		end
	end

	local success, result = pcall(function()
		return Players:GetNameFromUserIdAsync(v21)
	end)

	if success then
		local clone = ReplicatedStorage.Assets.UI.Store.PlayerTemplate:Clone()
		clone.Player.Avatar.Image = `rbxthumb://type=AvatarHeadShot&id={v21}&w=420&h=420`
		clone.Player.Username.Text = `@{result}`
		clone.Parent = parent3.Gift.Container
		clone.Name = "SearchResult"
		activateGiftTemplate(clone, v21)
	end
end

function Store.OpenTab(p: string)
	Profiler.mark("UI.Store.OpenTab")

	if (p == "Credits" or p == "TradeTokens") and not v4 then
		Router.broadcastRouter("CreateMenuNotification", "Error", "Paid random items are not allowed in your region.")
		return
	end

	v9 = p
	ScrollToFeaturedSection(p)
end

function Store.CanBuyPaidCurrency()
	return v4
end

function Store.OpenBundleSection()
	Profiler.mark("UI.Store.OpenBundleSection")
	ScrollToFeaturedSection("StarterPack")
end

function Store.PromptTradeTokenPackageForItemPrice(p: number)
	if v10.TRADE_TOKEN_PACKAGES[#v10.TRADE_TOKEN_PACKAGES].Amount < p then
		return
	end

	local v21 = p - (DataController.Get(LocalPlayer, "TradeTokens") or 0)

	if v21 <= 0 then
		return
	end

	for _, v22 in v10.TRADE_TOKEN_PACKAGES do
		if not (v21 <= v22.Amount) then
			continue
		end

		local devProduct = DevProducts[v22.ProductName]

		if devProduct then
			MarketplaceService:PromptProductPurchase(LocalPlayer, devProduct.DevProductId)
		end

		break
	end
end

function Store.OpenFeaturedBundleSection()
	Profiler.mark("UI.Store.OpenFeaturedBundleSection")
	ScrollToFeaturedSection("Console")
end

fn3 = function(caseId: string, currentInventoryItem, caseIdentifier: string?, isQuickUnlock: boolean?, requestId: string?)
	Profiler.mark("UI.Store.OpenCase")

	if isQuickUnlock == nil then
		isQuickUnlock = v13.isQuickUnlock
	end

	v13.currentCaseIdentifier = caseIdentifier
	CleanupCaseOpeningTweens()
	local case = Cases.GetCase(caseId)

	if not case then
		return
	end

	if isQuickUnlock then
		if caseIdentifier then
			Remotes.Store.CaseOpenSequenceFinished.Send({ CaseIdentifier = caseIdentifier })
		end

		CaseSceneController.HideCaseScene()
		ReturnToStoreTabs() -- inferred equivalent call
		MenuState.SetScreen("Inventory")
		local v21 = v10.RARITY_TO_DROP_SOUND[GetUnboxedItemRarity(currentInventoryItem, case)] or "Drop Blue"
		Router.broadcastRouter("RunStoreSound", v21)
		Router.broadcastRouter("RunStoreSound", "Case Close")
		Router.broadcastRouter("QuickOpenResolved", requestId)
		Router.broadcastRouter("ShowNewItemNotification", currentInventoryItem)
		Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
	else
		v13.isOpening = true
		v13.currentInventoryItem = currentInventoryItem
		parent3.CaseContent.Visible = false
		local v21 = case.caseType == "Charm Capsule"
		local v22 = case.caseType == "Package"

		local function startRollAnimation()
			if not v13.isOpening then
				return
			end

			parent4.Menu.OpenCase.CaseName.Text = `Unlock {case.name}`
			parent4.Menu.OpenCase.Visible = true
			parent3.Visible = false
			parent4.Menu.OpenCase.Contents.Close.TextLabel.Text = "CLOSE"
			local v23 = CaseScroll.RunScrollAnimation(case, currentInventoryItem)

			if not v13.isOpening then
				return
			end

			Router.broadcastRouter("RunInterfaceSound", "UI Notification")
			task.wait(0.5)

			if not v13.isOpening then
				return
			end

			v13.isOpening = false
			v13.currentInventoryItem = nil
			NotifyCaseOpenSequenceFinished() -- inferred equivalent call
			parent4.Menu.OpenCase.Visible = false
			CaseSceneController.HideCaseScene()
			ReturnToStoreTabs() -- inferred equivalent call
			MenuState.SetScreen("Inventory")
			local rarity = v23 and v23.rarity or "Blue"
			Router.broadcastRouter("RunStoreSound", v10.RARITY_TO_DROP_SOUND[rarity] or "Drop Blue")
			Router.broadcastRouter("RunStoreSound", "Case Close")
			InspectInventoryItem(currentInventoryItem) -- inferred equivalent call
		end

		if v21 then
			CaseSceneController.TransitionToUnboxing(startRollAnimation)
		elseif v22 then
			CaseSceneController.TransitionToUnboxing()
			CaseSceneController.WaitForOpeningAnimation()

			if v13.isOpening then
				v13.isOpening = false
				v13.currentInventoryItem = nil
				NotifyCaseOpenSequenceFinished() -- inferred equivalent call
				CaseSceneController.HideCaseScene()
				ReturnToStoreTabs() -- inferred equivalent call
				MenuState.SetScreen("Inventory")
				local v23 = v10.RARITY_TO_DROP_SOUND[GetUnboxedItemRarity(currentInventoryItem, case)] or "Drop Blue"
				Router.broadcastRouter("RunStoreSound", v23)
				Router.broadcastRouter("RunStoreSound", "Case Close")
				InspectInventoryItem(currentInventoryItem) -- inferred equivalent call
			end
		else
			CaseSceneController.TransitionToUnboxing()
			task.wait(0.8)
			startRollAnimation()
		end
	end
end

local function stopCaseOpening() -- 1 equivalent call inferred from this helper
	if v13.isOpening then
		Router.broadcastRouter("RunStoreSound", "Case Close")
	end

	CleanupCaseOpeningTweens()
	ResetBulkOpeningState() -- inferred equivalent call
	CaseScroll.ResetProgressBar()
	local currentInventoryItem = v13.currentInventoryItem
	v13.isOpening = false
	v13.currentInventoryItem = nil
	CaseSceneController.HideCaseScene()
	return currentInventoryItem
end

local function finishBulkOpening()
	local inventoryItems = v19.inventoryItems or {}
	local bulkIdentifier = v19.bulkIdentifier
	CleanupCaseOpeningTweens()
	CaseScroll.ResetProgressBar()
	v13.isOpening = false
	v13.currentInventoryItem = nil
	CaseSceneController.HideCaseScene()
	local close = parent4.Menu.OpenCase.Contents.Close

	if v17 then
		for _, v21 in ipairs(v17) do
			v21.Visible = true
		end

		close.TextLabel.Text = "CLOSE"
		v17 = nil
	end

	parent4.Menu.OpenCase.Visible = false
	ReturnToStoreTabs() -- inferred equivalent call
	parent4.Menu.OpenCase.Contents.Close.TextLabel.Text = "CLOSE"
	Router.broadcastRouter("RunStoreSound", "Case Close")

	if bulkIdentifier then
		Remotes.Store.CaseOpenSequenceFinished.Send({ CaseIdentifier = bulkIdentifier })
	end

	MenuState.SetScreen("Inventory")

	if inventoryItems[1] then
		Router.broadcastRouter("ShowNewItemNotification", inventoryItems[1])
	end

	ResetBulkOpeningState() -- inferred equivalent call
	Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
end

local function skipBulkOpening() -- 1 equivalent call inferred from this helper
	v19.skipped = true
	CleanupCaseOpeningTweens()
	finishBulkOpening()
end

local function BeginBulkOpeningState(caseId: string, inventoryItems, bulkIdentifier: string?) -- 2 equivalent calls inferred from this helper
	v19.isBulkOpening = true
	v19.inventoryItems = inventoryItems
	v19.bulkIdentifier = bulkIdentifier
	v19.caseId = caseId
	v19.total = #inventoryItems
	v19.currentIndex = 0
	v19.skipped = false
end

local function IsBulkOpeningInterrupted() -- 6 equivalent calls inferred from this helper
	return not v13.isOpening or v19.skipped
end

local function HoldBulkReveal(p: number)
	local lastTime = tick()

	while tick() - lastTime < p and v13.isOpening and not v19.skipped do
		task.wait(0.1)
	end
end

fn5 = function(caseId: string, inventoryItems, bulkIdentifier: string?)
	Profiler.mark("UI.Store.StartBulkOpening")
	local case = Cases.GetCase(caseId)

	if not case then
		return
	end

	BeginBulkOpeningState(caseId, inventoryItems, bulkIdentifier) -- inferred equivalent call
	CleanupCaseOpeningTweens()
	v13.isOpening = true
	v13.currentInventoryItem = nil
	parent3.CaseContent.Visible = false
	local v21 = case.caseType == "Charm Capsule"

	local function waitForDrag(fn7)
		local v22 = false
		fn7(function()
			v22 = true
		end)

		while not v22 and v13.isOpening and not v19.skipped do
			task.wait()
		end
	end

	if v21 then
		waitForDrag(function(p)
			CaseSceneController.TransitionToUnboxing(p)
		end)
	else
		CaseSceneController.TransitionToUnboxing()
		task.wait(0.8)
	end

	if IsBulkOpeningInterrupted() then -- inferred equivalent call
		return
	end

	parent4.Menu.OpenCase.CaseName.Text = `Unlock {case.name}`
	parent4.Menu.OpenCase.Visible = true
	parent3.Visible = false

	for i = 1, #inventoryItems do
		if IsBulkOpeningInterrupted() then -- inferred equivalent call
			break
		end

		v19.currentIndex = i
		local v22 = inventoryItems[i]
		local v23 = i == #inventoryItems
		parent4.Menu.OpenCase.Contents.Close.TextLabel.Text = "CLOSE"

		if v21 and i > 1 then
			waitForDrag(function(callback)
				if not CaseSceneController.ArmDragOpening(callback) then
					callback()
				end
			end)

			if IsBulkOpeningInterrupted() then -- inferred equivalent call
				break
			end
		end

		local v24 = CaseScroll.RunScrollAnimation(case, v22)

		if IsBulkOpeningInterrupted() then -- inferred equivalent call
			break
		end

		Router.broadcastRouter("RunInterfaceSound", "UI Notification")
		local rarity = v24 and v24.rarity or "Blue"
		Router.broadcastRouter("RunStoreSound", v10.RARITY_TO_DROP_SOUND[rarity] or "Drop Blue")

		if v23 then
			task.wait(0.5)
		else
			HoldBulkReveal(1.5)
		end
	end

	if v13.isOpening and not v19.skipped then
		finishBulkOpening()
	end
end

fn6 = function(caseId: string, inventoryItems, list, caseIdentifier: string?)
	Profiler.mark("UI.Store.StartBulkConsoleOpening")

	if #list == #inventoryItems then
		BeginBulkOpeningState(caseId, inventoryItems, caseIdentifier) -- inferred equivalent call
		v16 = nil
		CleanupCaseOpeningTweens()
		v13.isOpening = true
		v13.currentInventoryItem = nil
		parent3.CaseContent.Visible = false
		parent3.Visible = false
		SetConsoleOverlay(true)

		for i, v21 in ipairs(inventoryItems) do
			if IsBulkOpeningInterrupted() then -- inferred equivalent call
				break
			end

			v19.currentIndex = i

			if i > 1 or not CaseSceneController.IsConsoleOpening() then
				CaseSceneController.BeginConsoleOpening()
			end

			local v22 = false
			local v23 = false

			if not CaseSceneController.ResolveConsoleOpening(list[i], function(p)
				v22 = true
				v23 = p
			end, Cases.GetCase(caseId), v21) then
				break
			end

			while v13.isOpening and not (v19.skipped or v22) do
				task.wait()
			end

			if IsBulkOpeningInterrupted() then -- inferred equivalent call
				break
			end

			Router.broadcastRouter("RunInterfaceSound", "UI Notification")

			if not v23 then
				Router.broadcastRouter("RunStoreSound", GetInventoryItemDropSound(v21)) -- inferred equivalent call
			end

			HoldBulkReveal(i == #inventoryItems and 0.5 or 1.5)
		end

		if v13.isOpening and not v19.skipped then
			finishBulkOpening()
		end
	else
		v16 = nil
		CaseSceneController.CancelConsoleOpening()
		local close = parent4.Menu.OpenCase.Contents.Close

		if v17 then
			for _, v21 in ipairs(v17) do
				v21.Visible = true
			end

			close.TextLabel.Text = "CLOSE"
			v17 = nil
		end

		fn5(caseId, inventoryItems, caseIdentifier)
	end
end

function Store.BeginOpenCaseRequest(isQuickUnlock: boolean)
	return BeginOpenCaseRequest(isQuickUnlock) -- inferred equivalent call
end

function Store.ClearPendingOpenCaseRequest(p: string)
	if v13.pendingOpenRequestId ~= p then
		return false
	end

	ClearPendingOpenRequest() -- inferred equivalent call
	return true
end

local function openCreatorCode()
	parent3.CreatorCode:SetAttribute("ResponseId", nil)
	parent3.CreatorCode.Container.Body.Response.Text = ""
	parent3.CreatorCode.Container.Action.Confirm.Title.Text = "CONFIRM"
	parent3.CreatorCode.Container.Body.CreatorName.TextBox.Text = DataController.Get(LocalPlayer, "CreatorCode") or ""
	parent3.CreatorCode.Position = UDim2.fromScale(0.5, -1)
	parent3.CreatorCode.Visible = true
	parent3.Tabs.Visible = false
	TweenService:Create(parent3.CreatorCode, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, 0.5)
	}):Play()
end

local function closeCreatorCode()
	TweenService:Create(parent3.CreatorCode, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.fromScale(0.5, -1)
	}):Play()
	task.wait(0.35)

	if parent3.CreatorCode.Visible then
		parent3.CreatorCode.Visible = false
		parent3.Tabs.Visible = true
	end
end

fn2 = function(p: string)
	CaseSceneController.HideCaseScene()
	v8 = nil
	v7 = nil
	parent3.CaseContent:SetAttribute("WasVisibleBeforeInspect", false)

	if p == "Inventory" then
		MenuState.SetScreen("Inventory")
	end

	parent3.Tabs.Container.Visible = true
	parent3.CaseContent.Visible = false
	parent4.Menu.Top.Visible = true
	parent3.Top.Visible = true

	if p ~= "Inventory" then
		parent3.Visible = true
		return
	end

	parent4.Menu.Inventory.Visible = true
	parent3.Visible = false
end

function Store.Initialize(p, p2)
	Profiler.mark("UI.Store.Initialize")
	parent4 = p
	parent3 = p2
	CaseScroll.Bind(parent4, v13, v10)
	StarterPack.Bind(parent3, parent4)
	v11.Label = parent3.Tabs.Container.Featured.Container.Console.Pack.Container.Top.Title.Top.Timer
	local cases = parent3.Tabs.Container.Featured.Container.Cases.Container.Cases
	local flag = false

	local function queueCaseGridFit() -- 1 equivalent call inferred from this helper
		if flag then
			return
		end

		flag = true
		task.defer(function()
			flag = false
			fitCaseGrid(cases)
		end)
	end

	cases.ChildAdded:Connect(queueCaseGridFit)
	cases.ChildRemoved:Connect(queueCaseGridFit)
	cases:GetPropertyChangedSignal("AbsoluteSize"):Connect(queueCaseGridFit)
	queueCaseGridFit() -- inferred equivalent call

	if parent3.Top.Categories.Visible then
		parent3.Top.Categories.Visible = false
	end

	local container = parent3.Tabs.Container.Featured.Container
	local visibleChangedConnection = nil
	visibleChangedConnection = parent3:GetPropertyChangedSignal("Visible"):Connect(function()
		if parent3.Visible and visibleChangedConnection then
			visibleChangedConnection:Disconnect()
			visibleChangedConnection = nil
			container.CanvasPosition = Vector2.zero
		end
	end)
	ActivateButton(parent3.Tabs.Container.Featured.Container.CreatorCode.CreatorCodeButton)
	parent3.Tabs.Container.Featured.Container.CreatorCode.CreatorCodeButton.MouseButton1Click:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		openCreatorCode()
	end)
	CloseButtonRegistry.Add(parent4.Menu.OpenCase, parent4.Menu.OpenCase.Contents.Close, function()
		if v16 then
			CaseSceneController.SkipConsoleOpening()
		elseif v19.isBulkOpening then
			skipBulkOpening() -- inferred equivalent call
		else
			local currentInventoryItem = stopCaseOpening() -- inferred equivalent call
			parent4.Menu.OpenCase.Visible = false
			NotifyCaseOpenSequenceFinished() -- inferred equivalent call
			ReturnToStoreTabs() -- inferred equivalent call
			MenuState.SetScreen("Inventory")

			if currentInventoryItem then
				InspectInventoryItem(currentInventoryItem) -- inferred equivalent call
				return
			end

			parent4.Menu.Inventory.Visible = true
			Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
		end
	end)
	ActivateButton(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Open)
	parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Open.MouseButton1Click:Connect(function()
		if not v8 or v13.isOpening or v13.isPendingOpenRequest then
			return
		end

		if not Cases.HasCaseModel(v8.caseId) then
			Router.broadcastRouter("CreateMenuNotification", "Error", "This case can't be opened right now.")
			return
		end

		if not v7 then
			Router.broadcastRouter(
				"CreateMenuNotification",
				"Error",
				"Case identifier missing. Please reopen the case."
			)
			return
		end

		local v21 = v8.caseType == "Console"
		local text = tonumber(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Header.TextLabel.Text) or 1
		local caseIdentifiers

		if text > 1 then
			caseIdentifiers = CollectCaseIdentifiers(v8.name, text)

			if #caseIdentifiers < 2 then
				Router.broadcastRouter("CreateMenuNotification", "Error", "Not enough cases in your inventory.")
				return
			end
		else
			caseIdentifiers = { v7 }
		end

		local isQuickUnlock = not v21

		if isQuickUnlock then
			if text == 1 then
				isQuickUnlock = v13.isQuickUnlock
			else
				isQuickUnlock = false
			end
		end

		local openType = text > 1 and "Bulk" or isQuickUnlock and "Quick Open" or "Standard"
		local requestId = BeginOpenCaseRequest(isQuickUnlock) -- inferred equivalent call

		if v21 then
			v16 = requestId
			v13.isOpening = true
			v13.currentCaseIdentifier = caseIdentifiers[1]
			parent3.CaseContent.Visible = false
			parent3.Visible = false
			SetConsoleOverlay(true)
			CaseSceneController.BeginConsoleOpening()
			Remotes.Store.OpenConsole.Send({
				CaseIdentifiers = caseIdentifiers,
				CaseId = v8.caseId,
				RequestId = requestId
			})
		else
			Remotes.Store.OpenCase.Send({
				CaseIdentifiers = caseIdentifiers,
				OpenType = openType,
				CaseId = v8.caseId,
				RequestId = requestId
			})
		end

		task.delay(v10.OPEN_CASE_REQUEST_TIMEOUT * (text > 1 and 2 or 1), function()
			if v13.isPendingOpenRequest and v13.pendingOpenRequestId == requestId then
				FailOpenCaseRequest(requestId) -- inferred equivalent call

				if v16 == requestId then
					v18[requestId] = true
					v16 = nil
					ResetConsoleOpening() -- inferred equivalent call
				else
					Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
				end

				Router.broadcastRouter("CreateMenuNotification", "Error", "Opening case timed out. Please try again.")
			end
		end)
	end)
	ActivateButton(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Buy)
	parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Buy.MouseButton1Click:Connect(function()
		if v8 then
			purchaseCase(
				v8,
				tonumber(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Header.TextLabel.Text)
			)
		end
	end)
	ActivateButton(parent3.CaseContent.Main.Bottom.Buttons.Close)
	CloseButtonRegistry.Add(parent3.CaseContent, parent3.CaseContent.Main.Bottom.Buttons.Close, function()
		if not v13.isPendingOpenRequest then
			fn2(parent3.CaseContent:GetAttribute("State") == "Inspect" and "Store" or "Inventory")
		end
	end)
	ActivateButton(parent3.CreatorCode.Container.Action.Close)
	CloseButtonRegistry.Add(parent3.CreatorCode, parent3.CreatorCode.Container.Action.Close, closeCreatorCode)
	ActivateButton(parent3.CreatorCode.Container.Body.CreatorName.Clear)
	parent3.CreatorCode.Container.Body.CreatorName.Clear.MouseButton1Click:Connect(function()
		parent3.CreatorCode.Container.Body.CreatorName.TextBox.Text = ""
		Remotes.UI.EquipCreatorCode.Send({ CreatorCode = "" })
	end)
	ActivateButton(parent3.CreatorCode.Container.Action.Confirm)
	parent3.CreatorCode.Container.Action.Confirm.MouseButton1Click:Connect(function()
		local text = parent3.CreatorCode.Container.Body.CreatorName.TextBox.Text
		parent3.CreatorCode.Container.Action.Confirm.Title.Text = "SEARCHING.."
		Router.broadcastRouter("RunInterfaceSound", "UI Click")

		if text and text ~= "" then
			Remotes.UI.EquipCreatorCode.Send({ CreatorCode = text })
		else
			UpdateCreatorCodeResponse("Error", "Creator code cannot be empty.")
		end
	end)
	ClearFrame(parent3.Gift.Container, { "UICorner", "UIListLayout" })
	CloseButtonRegistry.Add(parent3.Gift, parent3.Gift.Close, function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		parent3.Gift.Visible = false
	end)
	parent3.Gift:GetPropertyChangedSignal("Visible"):Connect(function()
		if parent3.Gift.Visible or not selectedObject then
			return
		end

		local v21 = GuiService
		local selectedObject2

		if IsSelectionUsable(selectedObject) then
			selectedObject2 = selectedObject
		else
			selectedObject2 = parent3.Top.Currency.Credits.Buy
		end

		v21.SelectedObject = selectedObject2
		selectedObject = nil
	end)
	ActivateButton(parent3.Top.Currency.Credits.Buy)
	parent3.Top.Currency.Credits.Buy.MouseButton1Click:Connect(function()
		Store.OpenTab("Credits")
	end)
	local tradeTokens = parent3.Top.Currency.TradeTokens
	tradeTokens.Visible = true
	local purchaseMore = tradeTokens.PurchaseMore
	ActivateButton(purchaseMore)
	purchaseMore.MouseButton1Click:Connect(function()
		Store.OpenTab("TradeTokens")
	end)

	for _, button in parent3.CaseContent.Main.Bottom.SubButtons.CenterButtons:GetChildren() do
		if not button:IsA("ImageButton") then
			continue
		end

		ActivateButton(button)
		local v21 = button
		button.MouseButton1Click:Connect(function()
			if not (v8 and (Cases.IsCaseForSale(v8.caseId) or RunService:IsStudio()) and Cases.HasCaseModel(v8.caseId)) then
				return
			end

			local cas = Cases2[v8.name]

			if not cas then
				return
			end

			local amount = cas.Amounts[tonumber(v21.Name)]

			if not amount or amount.Offsale ~= false then
				return
			end

			local tradeTokens2 = DataController.Get(LocalPlayer, "TradeTokens")

			if GetCaseTokenPrice(amount) <= tradeTokens2 then -- inferred equivalent call
				DoCreditPurchase(v8.name, amount, (tonumber(v21.Name)))
			else
				MarketplaceService:PromptProductPurchase(LocalPlayer, amount.ID)
			end
		end)
	end

	for _, v21 in { "Credits", "TradeTokens" } do
		for _, frame in ipairs(parent3.Tabs.Container.Featured.Container[v21]:GetChildren()) do
			if frame:IsA("Frame") then
				setupCurrencyFrame(frame, v21 == "TradeTokens")
			end
		end
	end

	StarterPack.Setup(LoadProductPrice, DoCreditPurchase, function()
		return v4
	end)
	local button = parent3.Tabs.Container.Featured.Container.Console.Pack:FindFirstChild("Button")

	if button and button:IsA("GuiButton") then
		button.Selectable = false
		button.Active = false
	end

	for _, button2 in parent3.Tabs.Container.Featured.Container.Console.Pack.CenterButtons:GetChildren() do
		if not button2:IsA("ImageButton") then
			continue
		end

		local devProduct = DevProducts[`{button2.Name} Consoles`]

		if not devProduct then
			continue
		end

		local v21 = button2

		local function fn7(p3)
			v21.Container.Title.Text = `{utf8.char(57346)} {CommaNumber(p3)}`
		end

		LoadProductPrice(devProduct, fn7) -- inferred equivalent call
		ActivateButton(button2)
		local v22 = button2
		button2.MouseButton1Click:Connect(function()
			if v4 then
				local tradeTokens2 = DataController.Get(LocalPlayer, "TradeTokens")

				if GetCaseTokenPrice(devProduct) <= tradeTokens2 then -- inferred equivalent call
					DoCreditPurchase(`{v22.Name} Consoles`, devProduct, nil, tonumber(v22.Name))
				else
					MarketplaceService:PromptProductPurchase(LocalPlayer, devProduct.DevProductId)
				end

				Router.broadcastRouter("RunInterfaceSound", "UI Click")
			end
		end)
	end

	Hover.Setup(parent3, v10)

	for _, v21 in ipairs(v10.INSPECTABLE_ITEM_TAGS) do
		SetupTaggedInspectButtons(v21)
	end

	updateCases()
	StartBackgroundProductLoading()
	RunServiceController.BindToHeartbeat("UI.Store.Rotaters", function(p3)
		Profiler.mark("UI.Store.RotaterHeartbeat")

		if not parent4.Menu.Visible then
			return
		end

		if parent3.Visible or parent4.Menu.Dashboard.Visible then
			for _, v21 in ipairs(CollectionService:GetTagged("StoreRotaterFrame")) do
				v21.Rotation += p3 * 25
			end
		end
	end)
	parent3.Gift.Search.TextBox.Focused:Connect(function()
		local searchResult = parent3.Gift.Container:FindFirstChild("SearchResult")

		if searchResult then
			searchResult:Destroy()
		end

		for _, frame in ipairs(parent3.Gift.Container:GetChildren()) do
			if frame:IsA("Frame") then
				frame.Visible = true
			end
		end

		refreshGiftNavigation()
	end)
	parent3.Gift.Search.TextBox.FocusLost:Connect(function()
		PopulateGiftSearchResult(parent3.Gift.Search.TextBox.Text)
		refreshGiftNavigation()
	end)
	RunServiceController.BindToHeartbeat("UI.Store.TimersAndCredits", function(p3)
		local visible = parent3.Visible
		local visible2 = parent4 and parent4.Menu and parent4.Menu.Visible

		if visible or visible2 then
			if visible then
				local serverTimeNow = math.floor((workspace:GetServerTimeNow()))

				if serverTimeNow ~= v6 then
					v6 = serverTimeNow
					Store.RefreshFeaturedConsoleTimer(serverTimeNow)
				end
			end

			v5 += p3

			if v5 >= 1 then
				v5 %= 1
				local serverTimeNow = math.floor((workspace:GetServerTimeNow()))
				StarterPack.Refresh(serverTimeNow)
			end

			if not visible then
				return
			end

			Profiler.mark("UI.Store.CreditsHeartbeat")

			if not parent4.Menu.Visible then
				return
			end

			parent3.Top.Currency.Credits.TextLabel.Text = CommaNumber((math.round((v:getPosition()))))
			v:update(p3)
			parent3.Top.Currency.TradeTokens.TextLabel.Text = CommaNumber((math.round((v2:getPosition()))))
			v2:update(p3)
			parent3.Top.Currency.Tickets.TextLabel.Text = CommaNumber((math.round((v3:getPosition()))))
			v3:update(p3)
		else
			v6 = -1
			v5 = 1
		end
	end)
end

local function hidePaidCurrencyPurchaseEntryPoints()
	parent3.Top.Categories.Credits.Visible = false
	parent3.Top.Currency.Credits.Buy.Visible = false
	parent3.Top.Categories.TradeTokens.Visible = false
	parent3.Top.Currency.TradeTokens.PurchaseMore.Visible = false
	parent3.Tabs.Container.Featured.Container.Credits.Visible = false
	parent3.Tabs.Container.Featured.Container.TradeTokens.Visible = false
end

function Store.GetConsoleVignetteGradient()
	local v21 = rawget(Store, "ConsoleVignetteGradient")

	if v21 then
		return v21
	end

	local console = parent3.Tabs.Container.Featured.Container:FindFirstChild("Console")
	local animatedVignette = console and console:FindFirstChild("AnimatedVignette", true)

	if not (animatedVignette and animatedVignette:IsA("ImageLabel")) then
		return nil
	end

	local uiGradient = animatedVignette:FindFirstChildOfClass("UIGradient")

	if not uiGradient then
		return nil
	end

	rawset(Store, "ConsoleVignetteImage", animatedVignette)
	rawset(Store, "ConsoleVignetteGradient", uiGradient)
	rawset(Store, "ConsoleVignetteDefaultRotation", uiGradient.Rotation)
	rawset(Store, "ConsoleVignetteDefaultTransparency", uiGradient.Transparency)
	rawset(Store, "ConsoleVignetteDefaultImageTransparency", animatedVignette.ImageTransparency)
	return uiGradient
end

function Store.SetConsoleVignettePulse(p: number)
	local v21 = rawget(Store, "ConsoleVignetteGradient")

	if v21 then
		v21.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.18, 0.9 - p * 0.1),
			NumberSequenceKeypoint.new(0.45, 0.55 - p * 0.3),
			NumberSequenceKeypoint.new(0.58, 0.38 - p * 0.22),
			NumberSequenceKeypoint.new(0.82, 0.78 - p * 0.16),
			NumberSequenceKeypoint.new(1, 1)
		})
	end

	local v22 = rawget(Store, "ConsoleVignetteImage")

	if v22 then
		v22.ImageTransparency = 0.58 - p * 0.16
	end
end

v10.CONSOLE_VIGNETTE_CLEANUP = {
	{ "ConsoleVignetteTween", "Cancel" },
	{ "ConsoleVignettePulseTween", "Cancel" },
	{ "ConsoleVignettePulseConnection", "Disconnect" },
	{ "ConsoleVignettePulseValue", "Destroy" }
}

function Store.StopConsoleVignetteTween()
	for _, v21 in v10.CONSOLE_VIGNETTE_CLEANUP do
		local v22 = v21[1]
		local v23 = v21[2]
		local v24 = rawget(Store, v22)

		if not v24 then
			continue
		end

		v24[v23](v24)
		rawset(Store, v22, nil)
	end

	local v21 = rawget(Store, "ConsoleVignetteGradient")

	if v21 then
		v21.Rotation = rawget(Store, "ConsoleVignetteDefaultRotation") or -180
		v21.Transparency = rawget(Store, "ConsoleVignetteDefaultTransparency") or v21.Transparency
	end

	local v22 = rawget(Store, "ConsoleVignetteImage")

	if v22 then
		v22.ImageTransparency = rawget(Store, "ConsoleVignetteDefaultImageTransparency") or 0.5
	end
end

function Store.UpdateConsoleVignetteTween()
	if not parent3.Visible then
		Store.StopConsoleVignetteTween()
		return
	end

	if rawget(Store, "ConsoleVignetteTween") then
		return
	end

	local consoleVignetteGradient = Store.GetConsoleVignetteGradient()

	if not consoleVignetteGradient then
		return
	end

	consoleVignetteGradient.Rotation = rawget(Store, "ConsoleVignetteDefaultRotation") or -180
	local tween = TweenService:Create(
		consoleVignetteGradient,
		TweenInfo.new(14, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{
			Rotation = consoleVignetteGradient.Rotation + 360
		}
	)
	rawset(Store, "ConsoleVignetteTween", tween)
	tween:Play()
	local numberValue = Instance.new("NumberValue")
	numberValue.Value = 0
	rawset(Store, "ConsoleVignettePulseValue", numberValue)
	rawset(Store, "ConsoleVignettePulseConnection", numberValue:GetPropertyChangedSignal("Value"):Connect(function()
		Store.SetConsoleVignettePulse(numberValue.Value)
	end))
	Store.SetConsoleVignettePulse(0)
	local tween2 = TweenService:Create(
		numberValue,
		TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Value = 1 }
	)
	rawset(Store, "ConsoleVignettePulseTween", tween2)
	tween2:Play()
end

local function BindAmountButtonHover(button)
	button.MouseEnter:Connect(function()
		if not button:GetAttribute("Selected") then
			button.Frame.BackgroundTransparency = 0.5
		end
	end)
	button.MouseLeave:Connect(function()
		if not button:GetAttribute("Selected") then
			button.Frame.BackgroundTransparency = 1
		end
	end)
end

function Store.Start()
	debug.setmemorycategory("UI.Store.Start")
	Profiler.mark("UI.Store.Start.Begin")
	DataController.WaitForDataLoaded(LocalPlayer)
	Profiler.mark("UI.Store.Start.DataLoaded")
	local TimerController = require(ReplicatedStorage.Controllers.TimerController)
	TimerController.ListenToTimerChanged(v11.Source, function(tick)
		v11.Tick = tick
		v11.ReceivedAt = math.floor((workspace:GetServerTimeNow()))
		Store.RefreshFeaturedConsoleTimer(v11.ReceivedAt)
	end)
	local success, result = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(LocalPlayer)
	end)
	Profiler.mark("UI.Store.Start.PolicyLoaded")

	if success and result then
		v4 = not result.ArePaidRandomItemsRestricted
	end

	if not v4 then
		hidePaidCurrencyPurchaseEntryPoints()
	end

	parent3:GetPropertyChangedSignal("Visible"):Connect(Store.UpdateConsoleVignetteTween)
	Store.UpdateConsoleVignetteTween()

	for _, button in ipairs(parent3.Top.Categories:GetChildren()) do
		if not button:IsA("ImageButton") then
			continue
		end

		ActivateCategoryButton(button)
		local v21 = button
		button.MouseButton1Click:Connect(function()
			Store.OpenTab(v21.Name)
		end)
	end

	MenuState.RegisterBumperOverride(parent3, function(flag: boolean)
		if not parent3.Tabs.Visible then
			return false
		end

		local v21 = v9
		local starterPack = parent3.Tabs.Container.Featured.Container:FindFirstChild("StarterPack")

		if starterPack and MenuState.IsSelectionWithin(starterPack) then
			v21 = nil
		end

		local nextBumperTab = MenuState.GetNextBumperTab(parent3.Top.Categories, v10.TAB_ORDER, v21, flag)

		if nextBumperTab and nextBumperTab ~= v21 then
			task.spawn(function()
				Store.OpenTab(nextBumperTab)
				local child = parent3.Tabs.Container.Featured.Container:FindFirstChild(nextBumperTab)

				if
					v9 == nextBumperTab
					and child
					and MenuState.IsSelectionWithin(parent3.Tabs)
					and not MenuState.IsSelectionWithin(child)
				then
					GamepadNavigation.Focus(child)
				end
			end)
		end

		return true
	end, parent3, parent3.Tabs)
	ActivateButton(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount)
	parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.MouseButton1Click:Connect(function()
		local container = parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Container
		container.Visible = not container.Visible

		if not container.Visible then
			parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Header.ImageLabel.Rotation = 180
			return
		end

		parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Header.ImageLabel.Rotation = 0
		ScrollToBottom(container.Scroll) -- inferred equivalent call
	end)
	ActivateButton(parent3.CaseContent.Main.Odds.Frame.Close)
	ActivateButton(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Odds)
	parent3.CaseContent.Main.Odds.Frame.Close.MouseButton1Click:Connect(function()
		parent3.CaseContent.Main.Odds.Visible = false
	end)
	parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Odds.MouseButton1Click:Connect(function()
		parent3.CaseContent.Main.Odds.Visible = true
	end)

	for _, button in ipairs(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Container.Scroll:GetChildren()) do
		if not button:IsA("TextButton") then
			continue
		end

		BindAmountButtonHover(button)
		local v21 = button
		button.MouseButton1Click:Connect(function()
			local v22 = v8.price * tonumber(v21.Name)
			parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Buy.Container.Title.Text = `BUY <font color="#ffda0f">({CommaNumber(v22)})</font>`
			parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Header.TextLabel.Text = tostring(v21.Name)
			parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Container.Visible = false
			SelectAmountButton(parent3.CaseContent.Main.Bottom.Buttons.CenterButtons.Amount.Container.Scroll, v21)
		end)
	end

	parent3.Gift.Amount.MouseButton1Click:Connect(function()
		local container = parent3.Gift.Amount.Container
		container.Visible = not container.Visible

		if container.Visible then
			parent3.Gift.Amount.Header.ImageLabel.Rotation = 0
			ScrollToBottom(container) -- inferred equivalent call
		else
			parent3.Gift.Amount.Header.ImageLabel.Rotation = 180
		end

		refreshGiftNavigation()
	end)

	for _, button in ipairs(parent3.Gift.Amount.Container:GetChildren()) do
		if not button:IsA("TextButton") then
			continue
		end

		BindAmountButtonHover(button)
		local v21 = button
		button.MouseButton1Click:Connect(function()
			parent3.Gift.Amount.Header.TextLabel.Text = tostring(v21.Name)
			local v22 = GuiService.SelectedObject == v21
			parent3.Gift.Amount.Container.Visible = false
			SelectAmountButton(parent3.Gift.Amount.Container, v21)

			if v22 then
				GuiService.SelectedObject = parent3.Gift.Amount
			end

			refreshGiftNavigation()
		end)
	end

	DataController.CreateListener(LocalPlayer, "Statistics.OpenShopTime", function(p)
		StarterPack.OnOpenShopTimeChanged(p)
	end)
	DataController.CreateListener(LocalPlayer, "Gamepasses", function()
		StarterPack.Refresh()
	end)
	MenuState.OnScreenChanged:Connect(function(_, p)
		if p == "Store" then
			StarterPack.HandleStoreOpened()
		end
	end)

	if MenuState.GetCurrentScreen() == "Store" then
		StarterPack.HandleStoreOpened()
	else
		StarterPack.Refresh()
	end

	DataController.CreateListener(LocalPlayer, "Credits", function(p)
		v:setGoal(p)
		RefreshCaseAmountButtons()
	end)
	DataController.CreateListener(LocalPlayer, "TradeTokens", function(p)
		v2:setGoal(p)
	end)
	DataController.CreateListener(LocalPlayer, "Exclusive Raffle Ticket", function(p)
		v3:setGoal(p)
	end)
	task.defer(function()
		local credits = parent3.Tabs.Container.Featured.Container:WaitForChild("Credits")
		local _67500Credits = credits:FindFirstChild("+ 67,500 Credits")

		if not _67500Credits then
			return
		end

		local size = credits.Size
		local udim = UDim2.new(
			size.X.Scale,
			size.X.Offset,
			size.Y.Scale * v10.MINT_RESERVE_HIDDEN_CREDITS_HEIGHT_RATIO,
			size.Y.Offset * v10.MINT_RESERVE_HIDDEN_CREDITS_HEIGHT_RATIO
		)

		local function SetMintReserveVisible(visible: boolean) -- 1 equivalent call inferred from this helper
			local v21 = credits
			local size2

			if visible then
				size2 = size
			else
				size2 = udim
			end

			v21.Size = size2
			_67500Credits.Visible = visible
		end

		credits.Size = udim
		_67500Credits.Visible = false
		DataController.CreateListener(LocalPlayer, "Statistics.RobuxSpent", function(p)
			SetMintReserveVisible((tonumber(p) or 0) >= Constants.MINIMUM_CREDITS_FOR_SPECIAL_CREDITS_OPTION) -- inferred equivalent call
		end)
	end)
	Cases.ObserveAvailableCases(RefreshCaseListings)
	Remotes.UI.UpdateCreatorCode.Listen(function(p)
		parent3.CreatorCode.Container.Action.Confirm.Title.Text = "CONFIRM"
		UpdateCreatorCodeResponse(p.Type, p.Text)

		if p.Type == "Success" and parent3.CreatorCode.Visible then
			task.delay(1, function()
				if parent3.CreatorCode.Visible then
					closeCreatorCode()
				end
			end)
		end
	end)
	Remotes.Store.CaseOpened.Listen(function(data)
		Profiler.mark("UI.Store.CaseOpenedRemote")

		if data.InventoryItems and #data.InventoryItems > 0 then
			DataController.ApplyInventoryDelta(LocalPlayer, data.InventoryItems, data.DeletedCaseIds)
		end

		local requestId

		if typeof(data.RequestId) == "string" then
			requestId = data.RequestId
		end

		local completeOpenCaseRequest = CompleteOpenCaseRequest(requestId) -- inferred equivalent call

		if requestId and not completeOpenCaseRequest then
			return
		end

		table.insert(v15, {
			CaseId = data.CaseId,
			InventoryItems = data.InventoryItems,
			CaseIdentifier = data.CaseIdentifier,
			IsQuickUnlock = completeOpenCaseRequest and completeOpenCaseRequest.IsQuickUnlock or false,
			RequestId = requestId
		})
		Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
	end)
	Remotes.Store.ConsoleOpened.Listen(function(data)
		Profiler.mark("UI.Store.ConsoleOpenedRemote")
		DataController.ApplyInventoryDelta(LocalPlayer, data.InventoryItems, data.DeletedCaseIds)
		local consoleOutcomes = data.ConsoleOutcomes

		if not consoleOutcomes or #consoleOutcomes == 0 then
			consoleOutcomes = data.ConsoleOutcome and { data.ConsoleOutcome } or consoleOutcomes
		end

		local requestId = data.RequestId
		local v21 = requestId and v18[requestId] == true

		if v16 ~= requestId and not v21 then
			return
		end

		if v21 then
			v18[requestId] = nil
		elseif not CompleteOpenCaseRequest(requestId) then -- inferred equivalent call
			return
		end

		local inventoryItem = data.InventoryItems[1]

		if v21 then
			table.insert(v15, {
				CaseId = data.CaseId,
				InventoryItems = data.InventoryItems,
				CaseIdentifier = data.CaseIdentifier,
				IsQuickUnlock = false,
				RequestId = requestId,
				IsConsole = true,
				ConsoleOutcomes = consoleOutcomes
			})
			Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
		elseif #data.InventoryItems > 1 then
			v16 = nil
			fn6(data.CaseId, data.InventoryItems, consoleOutcomes or {}, data.CaseIdentifier)
		else
			v13.currentInventoryItem = inventoryItem
			v13.currentCaseIdentifier = data.CaseIdentifier
			local v22 = consoleOutcomes and consoleOutcomes[1]

			if not v22 then
				fn(inventoryItem, data.CaseIdentifier)
			elseif not CaseSceneController.ResolveConsoleOpening(v22, function(p)
				fn(inventoryItem, data.CaseIdentifier, p)
			end, Cases.GetCase(data.CaseId), inventoryItem) then
				fn(inventoryItem, data.CaseIdentifier)
			end
		end
	end)
	Remotes.Store.CaseOpenDenied.Listen(function(p)
		local requestId = p.RequestId
		FailOpenCaseRequest(requestId) -- inferred equivalent call

		if requestId then
			v18[requestId] = nil
		end

		if v16 ~= requestId then
			Profiler.defer("UI.Store.ResolvedQueueDeferred", TryProcessResolvedCaseOpenQueue)
			return
		end

		v16 = nil
		ResetConsoleOpening() -- inferred equivalent call
	end)
	MenuState.OnInspectStateChanged:Connect(function(p)
		if not p then
			Profiler.defer("UI.Store.InspectClosedDeferred", function()
				if TryProcessResolvedCaseOpenQueue() then
					return
				end

				local currentScreen = MenuState.GetCurrentScreen()
				local wasVisibleBeforeInspect = parent3.CaseContent:GetAttribute("WasVisibleBeforeInspect") == true
				local isActive = CaseSceneController.IsActive()

				if v8 and currentScreen == "Store" and wasVisibleBeforeInspect and isActive then
					ShowCaseContentView() -- inferred equivalent call
					MenuState.SetBlurEnabled(false)
					local menuFrame = MenuState.GetMenuFrame()

					if menuFrame then
						menuFrame.BackgroundTransparency = 1
					end
				elseif parent3.CaseContent.Visible and currentScreen == "Inventory" then
					ShowCaseContentView() -- inferred equivalent call
					local inventory = parent4.Menu:FindFirstChild("Inventory")

					if inventory then
						inventory.Visible = false
					end

					MenuState.SetBlurEnabled(false)
					local menuFrame = MenuState.GetMenuFrame()

					if menuFrame then
						menuFrame.BackgroundTransparency = 1
					end

					if not CaseSceneController.IsActive() and v8 then
						CaseSceneController.ShowCaseScene(v8.caseType, v8.name)
					end
				end
			end)
		end
	end)
	ActivateButton(parent3.CaseContent.Main.ItemOddsFrame.Close)
	parent3.CaseContent.Main.ItemOddsFrame.Close.MouseButton1Click:Connect(function()
		parent3.CaseContent.Main.ItemOddsFrame.Visible = false
	end)
	local main = parent3.CaseContent.Main
	local odds = main.Odds
	local itemOddsFrame = main.ItemOddsFrame
	local container = odds.Frame.Container
	local v21 = nil
	itemOddsFrame.Active = true

	local function refreshCoveredContent() -- 3 equivalent calls inferred from this helper
		main.CaseContent.Container.Interactable = not (odds.Visible or itemOddsFrame.Visible)
		container.Interactable = not itemOddsFrame.Visible
	end

	odds:GetPropertyChangedSignal("Visible"):Connect(refreshCoveredContent)
	itemOddsFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		local selectedObject2 = GuiService.SelectedObject

		if itemOddsFrame.Visible then
			if selectedObject2 and selectedObject2:IsDescendantOf(container) then
				v21 = selectedObject2
				GuiService.SelectedObject = itemOddsFrame.Close
			end

			refreshCoveredContent() -- inferred equivalent call
		else
			refreshCoveredContent() -- inferred equivalent call
			local selectedObject3 = v21
			v21 = nil

			if
				(selectedObject2 == nil or selectedObject2:IsDescendantOf(itemOddsFrame))
				and IsSelectionUsable(selectedObject3)
			then
				GuiService.SelectedObject = selectedObject3
			end
		end
	end)
	refreshCoveredContent() -- inferred equivalent call
	Observers.observePlayer(function(p)
		if LocalPlayer == p then
			return function() end
		end

		local clone = ReplicatedStorage.Assets.UI.Store.PlayerTemplate:Clone()
		clone.Player.Avatar.Image = `rbxthumb://type=AvatarHeadShot&id={p.UserId}&w=420&h=420`
		clone.Player.Username.Text = `@{p.Name}`
		clone.Parent = parent3.Gift.Container
		clone.Name = tostring(p.UserId)
		activateGiftTemplate(clone, p.UserId)
		refreshGiftNavigation()
		return function()
			clone:Destroy()
			refreshGiftNavigation()
		end
	end)
end

return Store