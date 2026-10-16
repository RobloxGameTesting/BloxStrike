local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
require(ReplicatedStorage.Database.Custom.Types)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Collections = require(ReplicatedStorage.Database.Components.Libraries.Collections)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local MarketPlacePrices = require(ReplicatedStorage.Database.Components.MarketPlacePrices)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local CommaNumber = require(ReplicatedStorage.Components.Common.CommaNumber)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local frozen = table.freeze({
	Stock = 0,
	Blue = 1,
	Purple = 2,
	Pink = 3,
	Red = 4,
	Special = 5,
	Forbidden = 6
})
local v = {}
local v2 = nil
local v3 = nil
local collectionNameTemplate = nil
local inputBeganConnection = nil
local v4 = nil
local v5 = {}
local v6 = nil
local v7 = nil
local v8 = nil
local v9 = nil
local v10 = nil
local count = 0
local connections = {}
local MarketplaceHover = { Visible = false }
local LocalPlayer = Players.LocalPlayer

local function setHoverVisible(visible: boolean) -- 10 equivalent calls inferred from this helper
	MarketplaceHover.Visible = visible

	if v2 then
		v2.Visible = visible
	end
end

local function resetHoverLayoutState() -- 3 equivalent calls inferred from this helper
	v9 = nil
	v10 = nil
end

local function disconnectTemplateConnections() -- 2 equivalent calls inferred from this helper
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end

	table.clear(connections)
end

local function isWearType(kind: string) -- 2 equivalent calls inferred from this helper
	return kind == "Weapon" or kind == "Melee" or kind == "Glove" or kind == "Zeus x27"
end

local function isPointInGui(p, vector: Vector2) -- 2 equivalent calls inferred from this helper
	local absolutePosition = p.AbsolutePosition
	local absoluteSize = p.AbsoluteSize
	return vector.X >= absolutePosition.X
		and vector.X <= absolutePosition.X + absoluteSize.X
		and vector.Y >= absolutePosition.Y
		and vector.Y <= absolutePosition.Y + absoluteSize.Y
end

local function findCaseCollectionName(name: string)
	for _, v11 in ipairs(v) do
		for _, v12 in ipairs(v11.cases or {}) do
			if v12 == name then
				return v11.name
			end
		end
	end

	return nil
end

local function getHoverPosition(p)
	local v11 = v2
	local parent = v11.Parent
	local zero = Vector2.zero
	local viewportSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

	if parent and parent:IsA("GuiObject") then
		zero = parent.AbsolutePosition
		viewportSize = parent.AbsoluteSize
	end

	local absolutePosition = p.AbsolutePosition
	local absoluteSize = p.AbsoluteSize
	local absoluteSize2 = v11.AbsoluteSize
	local guiInset = GuiService:GetGuiInset()
	local v12 = absolutePosition.X + absoluteSize.X + 8
	local v13 = absolutePosition.X - absoluteSize2.X - 8

	if not (v12 + absoluteSize2.X > zero.X + viewportSize.X - 8) then
		v13 = v12
	end

	local v14 = zero.X + 8
	local v15 = math.max(v14, zero.X + viewportSize.X - absoluteSize2.X - 8)
	local v16 = math.max(zero.Y + 8, guiInset.Y + 8)
	local v17 = math.max(v16, zero.Y + viewportSize.Y - absoluteSize2.Y - 8)
	local v18 = absolutePosition.Y + absoluteSize.Y / 2
	local anchorPoint = v11.AnchorPoint
	local vector = Vector2.new(math.clamp(v13, v14, v15), (math.clamp(v18, v16, v17)))
	return UDim2.fromOffset(
		math.floor(vector.X - zero.X + absoluteSize2.X * anchorPoint.X + 0.5),
		(math.floor(vector.Y - zero.Y + absoluteSize2.Y * anchorPoint.Y + 0.5))
	)
end

local function clearCollectionEntries()
	for _, frame in ipairs(v5.Collection:GetChildren()) do
		if frame:IsA("Frame") and frame.Name ~= "UIListLayout" then
			frame:Destroy()
		end
	end
end

local function setCollectionVisible(visible: boolean, p: string?) -- 1 equivalent call inferred from this helper
	v5.CollectionName.Visible = visible
	v5.CollectionName.Text = visible and `{p}:` or ""
	v5.CollectionSpacer.Visible = visible
	v5.Collection.Visible = visible
end

local function getPackageDescription(p)
	local v11 = "This package contains the "

	for i, content in ipairs(p.contents) do
		local weaponName = content.skin.weaponName

		if content.skin.type == "Melee" then
			weaponName = `★ {weaponName}`
		end

		local skinDisplayName = GetSkinDisplayName.GetSkinDisplayName(content.skin.skinName, true)

		if skinDisplayName ~= "" then
			weaponName = `{weaponName} | {skinDisplayName}`
		end

		if i > 1 then
			v11 ..= " and "
		end

		v11 ..= weaponName
	end

	return v11 .. "."
end

local function getDescription(data, p, p2)
	if p then
		if p.caseType == "Package" then
			return (getPackageDescription(p))
		end

		return p.description
	elseif isWearType(data.Type) then -- inferred equivalent call
		local v11 = data.Type == "Melee" and "T Knife" or data.Type == "Glove" and "T Glove" or data.Name
		local skinInformation = Skins.GetSkinInformation(v11, "Stock")

		if skinInformation then
			return skinInformation.description
		end

		return ""
	elseif p2 then
		return p2.description
	else
		return ""
	end
end

local function formatPrice(p) -- 4 equivalent calls inferred from this helper
	return CommaNumber((math.floor(p.recentAveragePriceTradeTokens)))
end

local function resolveHoverData(data)
	local v11 = nil
	local skinInfo = nil
	local caseType = nil
	local displayName, skinName, caseRarity, collection

	if
		data.Type == "Case"
		or data.Type == "Package"
		or data.Type == "Charm Capsule"
		or data.Type == "Sticker Capsule"
	then
		v11 = Cases.GetCaseByName(data.Skin)

		if not v11 then
			warn(`Failed to find case info for {data.Name} | {data.Skin}`)
			return nil
		end

		caseType = v11.caseType
		displayName = caseType == "Charm Capsule" and "Charm Pack" or caseType
		skinName = GetSkinDisplayName.GetSkinDisplayName(v11.name, true)
		caseRarity = v11.caseRarity

		if caseType == "Case" then
			collection = findCaseCollectionName(v11.name) or nil
		end
	else
		skinInfo = Skins.GetSkinInformation(data.Name, data.Skin)

		if not skinInfo then
			warn(`Failed to find skin info for {data.Name} | {data.Skin}`)
			return nil
		end

		displayName = GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag)

		if data.StatTrack then
			displayName = `KillTrak™ {displayName}` or displayName
		end

		skinName = GetSkinDisplayName.GetSkinDisplayName(data.Skin, true)
		caseRarity = skinInfo.rarity
		collection = skinInfo.collection
	end

	if data.Type == "Melee" then
		displayName = `★ {displayName}`
	end

	local itemValue = nil
	local v12 = data.StatTrack and true or false

	if data.ShowFullPriceRange then
		local itemPrice = MarketPlacePrices.GetItemPrice(
			data.Name,
			data.Skin,
			skinInfo and skinInfo.floatRange.min or data.Float,
			v12
		)
		local itemPrice2 = MarketPlacePrices.GetItemPrice(
			data.Name,
			data.Skin,
			skinInfo and skinInfo.floatRange.max or data.Float,
			v12
		)

		if
			itemPrice
			and itemPrice2
			and itemPrice.recentAveragePriceTradeTokens ~= itemPrice2.recentAveragePriceTradeTokens
		then
			itemValue = `{formatPrice(itemPrice2)} - {formatPrice(itemPrice)}` -- inferred equivalent call
		elseif itemPrice or itemPrice2 then
			itemValue = formatPrice(itemPrice or itemPrice2) -- inferred equivalent call
		end
	else
		local itemPrice = MarketPlacePrices.GetItemPrice(data.Name, data.Skin, data.Float, v12)

		if itemPrice then
			itemValue = formatPrice(itemPrice) -- inferred equivalent call
		end
	end

	return {
		skinInfo = skinInfo,
		isCase = caseType == "Case" or caseType == "Package",
		isCaseLike = v11 ~= nil,
		displayName = displayName,
		skinName = skinName,
		description = getDescription(data, v11, skinInfo),
		rarityName = caseRarity,
		collectionName = collection,
		itemValue = itemValue
	}
end

local function buildCollectionList(collectionName: string?, isCase: boolean)
	clearCollectionEntries()
	local v11 = not isCase and collectionName and Collections.GetCollectionByName(collectionName)

	if v11 then
		local inventory = DataController.Get(LocalPlayer, "Inventory") or {}
		local v12 = {}

		for _, item in ipairs(v11.items) do
			local itemName = item.itemName
			local skinName = item.skinName
			local skinInformation = Skins.GetSkinInformation(itemName, skinName)
			local rarity = skinInformation and skinInformation.rarity or "Stock"
			local isOwned = false

			for _, v13 in inventory do
				if not (v13.Name == itemName and v13.Skin == skinName) then
					continue
				end

				isOwned = true
				break
			end

			table.insert(v12, {
				itemName = itemName,
				skinName = skinName,
				rarity = rarity,
				rarityOrder = frozen[rarity],
				isOwned = isOwned
			})
		end

		table.sort(v12, function(a, b)
			if a.rarity == "Stock" or b.rarity == "Stock" then
				return a.rarity ~= "Stock"
			end

			if a.rarityOrder == b.rarityOrder then
				return a.itemName < b.itemName
			end

			return a.rarityOrder < b.rarityOrder
		end)

		for k, v13 in v12 do
			local clone = collectionNameTemplate:Clone()
			clone.Parent = v5.Collection
			clone.LayoutOrder = k
			clone.Visible = true
			clone.gun.Text = `[{v13.itemName}] | {v13.skinName}`
			clone.gun.TextColor3 = Rarities[v13.rarity].Color
			clone.ImageLabel.Visible = v13.isOwned
		end

		setCollectionVisible(true, collectionName) -- inferred equivalent call
	else
		v5.CollectionName.Visible = false
		v5.CollectionName.Text = ""
		v5.CollectionSpacer.Visible = false
		v5.Collection.Visible = false
	end
end

local function setTeamDisplay(visible: boolean, visible2: boolean, text: string?) -- 4 equivalent calls inferred from this helper
	local team = v5.Team
	team.CT.Visible = visible
	team.T.Visible = visible2
	team.Label.Visible = text ~= nil

	if text then
		team.Label.Text = text
	end
end

local function updateTeamDisplay(data)
	v5.TeamTitle.Text = "Team:"

	if
		data.Type == "Melee"
		or data.Type == "Glove"
		or data.Type == "Badge"
		or data.Type == "Charm"
		or data.Type == "Zeus x27"
	then
		local team = v5.Team
		team.CT.Visible = true
		team.T.Visible = true
		team.Label.Visible = true
		team.Label.Text = "Both"
	else
		local v11

		if data.Type == "Weapon" then
			v11 = GetWeaponProperties(data.Name)
		else
			v11 = false
		end

		if v11 then
			local team = v11.Team

			if team == "Counter-Terrorists" then
				setTeamDisplay(true, false, "Counter-Terrorists") -- inferred equivalent call
			elseif team == "Terrorists" then
				setTeamDisplay(false, true, "Terrorists") -- inferred equivalent call
			else
				local team2 = v5.Team
				team2.CT.Visible = true
				team2.T.Visible = true
				team2.Label.Visible = true
				team2.Label.Text = "Both"
			end
		else
			setTeamDisplay(false, false) -- inferred equivalent call
		end
	end
end

local function updateFloatDisplay(data) -- 1 equivalent call inferred from this helper
	if data.HideWearDetails then
		v5.Team.Visible = false
		v5.TeamTitle.Visible = false
	else
		v5.TeamTitle.Text = "Float:"
		v5.TeamTitle.Visible = true
		setTeamDisplay(false, false, data.Float and string.format("%.14f", data.Float) or "N/A") -- inferred equivalent call
		v5.Team.Visible = true
	end
end

local function applyHoverData(data, hoverData, flag: boolean)
	local v11 = hoverData.skinName == "Vanilla" and "" or ` | {hoverData.skinName}`
	local collectionName = hoverData.collectionName
	GetSkinDisplayName.ApplyNameLabel(v5.ItemName, hoverData.displayName .. v11, data.NameTag)
	v5.PriceLabel.Text = hoverData.itemValue or "N/A"
	v5.Information.Visible = not hoverData.isCaseLike

	if flag then
		v5.CollectionLabel.Visible = false
		v5.Description.Visible = false
		v5.CollectionName.Visible = false
		v5.CollectionName.Text = ""
		v5.CollectionSpacer.Visible = false
		v5.Collection.Visible = false
		v4 = nil
	else
		v5.CollectionLabel.Text = collectionName or ""
		v5.CollectionLabel.Visible = collectionName ~= nil
		v5.Description.Text = hoverData.description
		v5.Description.Visible = hoverData.description ~= ""
		local v12 = collectionName and Collections.GetCollectionByName(collectionName)

		if v12 then
			v5.CollectionIcon.Image = v12.imageAssetId
		end

		v5.CollectionIcon.Visible = v12 ~= nil
		local formatted = `{collectionName or ""}|{hoverData.isCase}`

		if v4 ~= formatted then
			buildCollectionList(collectionName, hoverData.isCase)
			v4 = formatted
		end
	end

	v5.Rarity.Text = (hoverData.rarityName == "Special" or hoverData.rarityName == "Forbidden") and "★ Special"
		or hoverData.rarityName
	v5.Rarity.TextColor3 = Rarities[hoverData.rarityName].Color
	local skinInfo = hoverData.skinInfo

	if skinInfo then
		skinInfo = isWearType(data.Type) -- inferred equivalent call
	end

	if skinInfo then
		local _, text = Skins.GetWearNameForFloat(hoverData.skinInfo, data.Float or hoverData.skinInfo.floatRange.max)
		v5.ExteriorLabel.Text = text
	end

	v5.Exterior.Visible = skinInfo == true

	if not flag then
		updateTeamDisplay(data)
		return
	end

	updateFloatDisplay(data) -- inferred equivalent call
end

local function prepareCurrentHoverContent()
	if not (v2 and v6) then
		return false
	end

	local hoverData = resolveHoverData(v6)

	if hoverData then
		local v11 = v8 == "TradeInfo"
		local joined = table.concat({
			v6._id,
			hoverData.displayName,
			hoverData.skinName,
			hoverData.description,
			hoverData.rarityName or "",
			hoverData.collectionName or "",
			tostring(hoverData.itemValue or ""),
			tostring(hoverData.isCase),
			tostring(hoverData.isCaseLike),
			(tostring(v11))
		}, "\0")

		if v9 ~= joined then
			setHoverVisible(false) -- inferred equivalent call
			applyHoverData(v6, hoverData, v11)
			v9 = joined
		end

		return true
	else
		v9 = nil
		setHoverVisible(false) -- inferred equivalent call
		return false
	end
end

local function updateHoverPosition(p) -- 3 equivalent calls inferred from this helper
	local hoverPosition = getHoverPosition(p)

	if v10 == hoverPosition then
		return
	end

	v2.Position = hoverPosition
	v10 = hoverPosition
end

local function canShowCurrentHover(flag: boolean)
	if v2 and v6 and v7 then
		if v7.Parent == nil or not v7.Visible then
			MarketplaceHover:Close(v7)
			return false
		end

		if flag or v3 and v3.Visible then
			return true
		end

		MarketplaceHover:Close()
	else
		setHoverVisible(false) -- inferred equivalent call
	end

	return false
end

local function showCurrentHover(flag: boolean) -- 1 equivalent call inferred from this helper
	if not canShowCurrentHover(flag) or v9 == nil and not prepareCurrentHoverContent() then
		return false
	end

	if v7 then
		updateHoverPosition(v7) -- inferred equivalent call
	end

	setHoverVisible(true) -- inferred equivalent call
	return true
end

local function bindTemplateInvalidation(instance)
	disconnectTemplateConnections() -- inferred equivalent call
	connections[1] = instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
		MarketplaceHover:Close(instance)
	end)
	connections[2] = instance:GetPropertyChangedSignal("Visible"):Connect(function()
		if not instance.Visible then
			MarketplaceHover:Close(instance)
		end
	end)
	connections[3] = instance.AncestryChanged:Connect(function()
		if instance.Parent == nil then
			MarketplaceHover:Close(instance)
		end
	end)
end

local function closeTradeInfoFromInput(p)
	if v8 ~= "TradeInfo" or not (MarketplaceHover.Visible and v2) then
		return
	end

	local userInputType = p.UserInputType

	if userInputType ~= Enum.UserInputType.MouseButton1 and userInputType ~= Enum.UserInputType.Touch then
		return
	end

	local vector = Vector2.new(p.Position.X, p.Position.Y)

	if isPointInGui(v2, vector) or v7 and v7.Parent and isPointInGui(v7, vector) then -- inferred equivalent call
		return
	end

	MarketplaceHover:Close()
end

function MarketplaceHover.Initialize(_, p, p2)
	v2 = p
	v3 = p2
	collectionNameTemplate = ReplicatedStorage.Assets.TradingUI.Templates:WaitForChild("CollectionNameTemplate")
	v5 = {
		ItemName = v2.ItemName.Frame.ItemName,
		CollectionLabel = v2.ItemName.Frame.Collection,
		CollectionIcon = v2.ItemName.CollectionIcon,
		Description = v2.Description,
		PriceLabel = v2.Price.PriceHolder.Team.Label,
		Information = v2.Information,
		Rarity = v2.Information.Rarity.Label,
		Exterior = v2.Information.Exterior,
		ExteriorLabel = v2.Information.Exterior.Label,
		Team = v2.Information.Team.Team,
		TeamTitle = v2.Information.Team.Team.Label.Parent.Parent.Title,
		Collection = v2.Collection,
		CollectionName = v2.CollectionName,
		CollectionSpacer = v2.CollectionSpacer
	}
	setHoverVisible(false) -- inferred equivalent call
	Collections.ObserveAvailableCollections(function(p3)
		v = p3
	end)
	Router.observerRouter("OpenTradeInfo", function(p3, p4)
		MarketplaceHover:OpenTradeInfo(p3, p4)
	end)
end

function MarketplaceHover.Start()
	if inputBeganConnection then
		return
	end

	inputBeganConnection = UserInputService.InputBegan:Connect(closeTradeInfoFromInput)
end

function MarketplaceHover.Open(_, p, p2)
	count += 1
	local v11 = count
	v6 = p
	v7 = p2
	v8 = "Inventory"
	resetHoverLayoutState() -- inferred equivalent call
	bindTemplateInvalidation(p2)

	if not (prepareCurrentHoverContent() and canShowCurrentHover(false)) then
		MarketplaceHover:Close(p2)
		return
	end

	updateHoverPosition(p2) -- inferred equivalent call
	setHoverVisible(false) -- inferred equivalent call
	task.delay(0.33, function()
		if count ~= v11 or v7 ~= p2 or v8 ~= "Inventory" then
			return
		end

		showCurrentHover(false) -- inferred equivalent call
	end)
end

function MarketplaceHover:OpenTradeInfo(p, p2)
	if MarketplaceHover.Visible and v8 == "TradeInfo" and v6 == p and v7 == p2 then
		MarketplaceHover:Close(p2)
		return
	end

	count += 1
	v6 = p
	v7 = p2
	v8 = "TradeInfo"
	resetHoverLayoutState() -- inferred equivalent call
	bindTemplateInvalidation(p2)
	setHoverVisible(false) -- inferred equivalent call
	local v11

	if v2 and v6 and v7 then
		if v7.Parent == nil or not v7.Visible then
			MarketplaceHover:Close(v7)
			v11 = false
		else
			v11 = true
		end
	else
		setHoverVisible(false) -- inferred equivalent call
		v11 = false
	end

	local v12

	if v11 and (v9 ~= nil or prepareCurrentHoverContent()) then
		if v7 then
			updateHoverPosition(v7) -- inferred equivalent call
		end

		setHoverVisible(true) -- inferred equivalent call
		v12 = true
	else
		v12 = false
	end

	if not v12 then
		MarketplaceHover:Close(p2)
	end
end

function MarketplaceHover:Close(p)
	if p and v7 ~= p then
		return
	end

	count += 1
	v6 = nil
	v7 = nil
	v8 = nil
	v4 = nil
	disconnectTemplateConnections() -- inferred equivalent call
	resetHoverLayoutState() -- inferred equivalent call
	setHoverVisible(false) -- inferred equivalent call
end

return MarketplaceHover