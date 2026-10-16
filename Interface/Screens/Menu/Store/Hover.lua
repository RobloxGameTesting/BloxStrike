local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local CommaNumber = require(ReplicatedStorage.Components.Common.CommaNumber)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local MarketPlacePrices = require(ReplicatedStorage.Database.Components.MarketPlacePrices)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local v = nil
local v2 = nil
local v3 = nil
local count = 0
local text = ""
local flag = false
local v4 = {}

local function GetStoreHoverFrame() -- 4 equivalent calls inferred from this helper
	local storeHoverFrame = v and v:FindFirstChild("StoreHoverFrame")

	if storeHoverFrame and storeHoverFrame:IsA("Frame") then
		return storeHoverFrame
	end

	return nil
end

local function GetStoreHoverTextLabel(...)
	local label = GetStoreHoverFrame() -- inferred equivalent call

	for _, childName in { ... } do
		if not label then
			return nil
		end

		label = label:FindFirstChild(childName)
	end

	if label and label:IsA("TextLabel") then
		return label
	end

	return nil
end

local function GetStoreHoverPriceLabel() -- 2 equivalent calls inferred from this helper
	return GetStoreHoverTextLabel("Info", "Price", "Frame", "TextLabel")
end

local function SetStoreHoverVisible(visible: boolean) -- 3 equivalent calls inferred from this helper
	local storeHoverFrame = GetStoreHoverFrame() -- inferred equivalent call

	if storeHoverFrame then
		storeHoverFrame.Visible = visible
	end
end

local function UpdateStoreHoverPosition()
	local storeHoverFrame = GetStoreHoverFrame() -- inferred equivalent call

	if not storeHoverFrame then
		return
	end

	local parent = storeHoverFrame.Parent

	if not (parent and parent:IsA("GuiObject")) then
		return
	end

	local v5 = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
	local absolutePosition = parent.AbsolutePosition
	local absoluteSize = parent.AbsoluteSize
	local absoluteSize2 = storeHoverFrame.AbsoluteSize
	local anchorPoint = storeHoverFrame.AnchorPoint
	local v6 = absolutePosition.X + v2.STORE_HOVER_PADDING
	local v7 = absolutePosition.Y + v2.STORE_HOVER_PADDING
	local v8 = math.max(v6, absolutePosition.X + absoluteSize.X - absoluteSize2.X - v2.STORE_HOVER_PADDING)
	local v9 = math.max(v7, absolutePosition.Y + absoluteSize.Y - absoluteSize2.Y - v2.STORE_HOVER_PADDING)
	local v10 = math.clamp(v5.X + v2.STORE_HOVER_MOUSE_OFFSET.X, v6, v8)
	local v11 = math.clamp(v5.Y + v2.STORE_HOVER_MOUSE_OFFSET.Y, v7, v9)
	storeHoverFrame.Position = UDim2.fromOffset(
		math.floor(v10 - absolutePosition.X + absoluteSize2.X * anchorPoint.X + 0.5),
		(math.floor(v11 - absolutePosition.Y + absoluteSize2.Y * anchorPoint.Y + 0.5))
	)
end

local function GetStoreHoverPriceText(weaponName: string, skinName: string, skinInformation)
	if not skinInformation then
		return "N/A-N/A"
	end

	local function GetWearTradeTokens(p: number) -- 2 equivalent calls inferred from this helper
		local itemPrice = MarketPlacePrices.GetItemPrice(weaponName, skinName, p, false)
		local recentAveragePriceTradeTokens = itemPrice and math.floor(itemPrice.recentAveragePriceTradeTokens)

		if recentAveragePriceTradeTokens and recentAveragePriceTradeTokens <= 0 then
			return nil
		end

		return recentAveragePriceTradeTokens
	end

	local wearTradeTokens = GetWearTradeTokens(skinInformation.floatRange.min) -- inferred equivalent call
	local wearTradeTokens2 = GetWearTradeTokens(skinInformation.floatRange.max) -- inferred equivalent call

	if wearTradeTokens and wearTradeTokens2 then
		return `{CommaNumber((math.min(wearTradeTokens, wearTradeTokens2)))}-{CommaNumber((math.max(wearTradeTokens, wearTradeTokens2)))}`
	end

	if wearTradeTokens2 then
		return CommaNumber(wearTradeTokens2) .. "-N/A"
	end

	if wearTradeTokens then
		return "N/A-" .. CommaNumber(wearTradeTokens)
	end

	return "N/A-N/A"
end

local function UpdateStoreHoverContent(button)
	local parent = button.Parent

	if not parent then
		return false
	end

	local weaponName = parent:GetAttribute("WeaponName")
	local skinName = parent:GetAttribute("SkinName")

	if typeof(weaponName) ~= "string" or typeof(skinName) ~= "string" then
		warn(`[Store] {parent:GetFullName()} is missing WeaponName/SkinName attributes.`)
		return false
	end

	local skinInformation = Skins.GetSkinInformation(weaponName, skinName)
	local v5 = not skinInformation and "Stock" or skinInformation.rarity
	local rarity = Rarities[v5]
	local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(weaponName)
	local skinDisplayName = GetSkinDisplayName.GetSkinDisplayName(skinName, true)
	local storeHoverPriceLabel = GetStoreHoverPriceLabel() -- inferred equivalent call
	local v6 = count
	local storeHoverTextLabel = GetStoreHoverTextLabel("Info", "ItemName")

	if storeHoverTextLabel then
		storeHoverTextLabel.Text = `{weaponDisplayName} | {skinDisplayName}`
		local textColor

		if rarity then
			textColor = rarity.Color
		else
			textColor = Color3.fromRGB(243, 243, 243)
		end

		storeHoverTextLabel.TextColor3 = textColor
	end

	local storeHoverTextLabel2 = GetStoreHoverTextLabel("Info", "RarityName")

	if storeHoverTextLabel2 then
		storeHoverTextLabel2.Text = string.upper(v5)

		if rarity then
			storeHoverTextLabel2.TextColor3 = rarity.Color
		end
	end

	local storeHoverTextLabel3 = GetStoreHoverTextLabel("Info", "Description", "TextLabel")

	if storeHoverTextLabel3 then
		storeHoverTextLabel3.Text = not skinInformation and "" or skinInformation.description
	end

	if storeHoverPriceLabel then
		storeHoverPriceLabel.Text = text
		task.spawn(function()
			local text2 = GetStoreHoverPriceText(weaponName, skinName, skinInformation)

			if v3 == button and count == v6 then
				storeHoverPriceLabel.Text = text2
			end
		end)
	end

	return true
end

local function BindStoreHoverButton(button)
	if v4[button] or not (v and button:IsDescendantOf(v) and button:IsA("GuiButton")) then
		return
	end

	v4[button] = true
	button.MouseEnter:Connect(function()
		count += 1
		v3 = button
		UpdateStoreHoverPosition()

		if UpdateStoreHoverContent(button) then
			SetStoreHoverVisible(true) -- inferred equivalent call
		end
	end)
	button.MouseLeave:Connect(function()
		if v3 ~= button then
			return
		end

		count += 1
		v3 = nil
		SetStoreHoverVisible(false) -- inferred equivalent call
	end)
end

local function SetupStoreHoverButtons()
	local storeHoverFrame = GetStoreHoverFrame() -- inferred equivalent call

	if storeHoverFrame then
		local storeHoverPriceLabel = GetStoreHoverPriceLabel() -- inferred equivalent call
		text = storeHoverPriceLabel and storeHoverPriceLabel.Text or ""
		storeHoverFrame.Visible = false
	end

	for _, v5 in ipairs(CollectionService:GetTagged(v2.STORE_HOVER_BUTTON_TAG)) do
		BindStoreHoverButton(v5)
	end

	if flag then
		return
	end

	flag = true
	CollectionService:GetInstanceAddedSignal(v2.STORE_HOVER_BUTTON_TAG):Connect(BindStoreHoverButton)
	RunServiceController.BindToRenderStep("UI.Store.HoverFrameFollow", function()
		if not v3 then
			return
		end

		if v and v.Visible and v3:IsDescendantOf(v) then
			UpdateStoreHoverPosition()
			return
		end

		v3 = nil
		SetStoreHoverVisible(false) -- inferred equivalent call
	end)
end

return {
	Setup = function(p, p2)
		v = p
		v2 = p2
		SetupStoreHoverButtons()
	end
}