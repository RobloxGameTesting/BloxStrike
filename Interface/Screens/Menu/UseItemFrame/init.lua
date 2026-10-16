local UseItemFrame = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Cases = require(ReplicatedStorage.Database.Components.Libraries.Cases)
local Collections = require(ReplicatedStorage.Database.Components.Libraries.Collections)
local GetResolvedSkinInformation = require(ReplicatedStorage.Components.Common.GetResolvedSkinInformation)
local CalculateGridRenderCount = require(ReplicatedStorage.Components.Common.CalculateGridRenderCount)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local ApplyWearAndSerialBadges = require(ReplicatedStorage.Components.Common.ApplyWearAndSerialBadges)
local Router = require(ReplicatedStorage.Database.Security.Router)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local Signal = require(ReplicatedStorage.Packages.Signal)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Sort = require(ReplicatedStorage.Database.Custom.GameStats.UI.Inventory.Sort)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Grenades = require(ReplicatedStorage.Database.Custom.GameStats.Grenades)
local Actions = require(script.Actions)
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local v = {
	"Alphabetical",
	"Collection",
	"Equipped",
	"Newest",
	"Quality",
	"Type",
	"Float",
	"Serial"
}
local v2 = nil
local v3 = nil
local flag = false
local v4 = nil
local v5 = nil
local v6 = false
local v7 = {}
local v8 = 0
local useItemFrame = nil
local container = nil
local textLabel = nil
local close = nil
local mainGui = nil
local sort = nil
UseItemFrame.OnItemSelected = Signal.new()
UseItemFrame.OnClosed = Signal.new()

local function MultiplyUdim2(size: UDim2, p: number) -- 1 equivalent call inferred from this helper
	return UDim2.new(size.X.Scale * p, size.X.Offset, size.Y.Scale * p, size.Y.Offset)
end

local function ClearFrame(container2, p: string)
	for _, button in ipairs(container2:GetChildren()) do
		if button.ClassName == p or button:IsA("GuiButton") then
			button:Destroy()
		end
	end
end

local function CloseWithoutSelection()
	UseItemFrame.OnClosed:Fire(v2)
	UseItemFrame.Hide()
end

local function OnItemSelected(p)
	if v2 then
		UseItemFrame.OnItemSelected:Fire(p, v2)
		UseItemFrame.Hide()
	end
end

local function AnimateSortButton(options, child, childName: string, textLabel2)
	child.MouseEnter:Connect(function()
		TweenService:Create(child, tweenInfo, { BackgroundTransparency = 0.85 }):Play()
	end)
	child.MouseLeave:Connect(function()
		TweenService:Create(child, tweenInfo, { BackgroundTransparency = 1 }):Play()
	end)
	child.MouseButton1Click:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		v5 = childName
		UseItemFrame.PopulateItems()
		textLabel2.Text = childName

		for _, button in ipairs(options:GetChildren()) do
			if button:IsA("TextButton") then
				button.Frame.BackgroundTransparency = button == child and 0 or 1
			end
		end

		options.Visible = false
	end)
end

local function AnimateButton(clone)
	local size = clone.Size

	local function tweenToScale(p: number) -- 4 equivalent calls inferred from this helper
		TweenService:Create(clone, tweenInfo, { Size = MultiplyUdim2(size, p) }):Play() -- inferred equivalent call
	end

	clone.MouseEnter:Connect(function()
		tweenToScale(0.95) -- inferred equivalent call
	end)
	clone.MouseLeave:Connect(function()
		tweenToScale(1) -- inferred equivalent call
	end)
	clone.MouseButton1Down:Connect(function()
		tweenToScale(0.9) -- inferred equivalent call
	end)
	clone.MouseButton1Up:Connect(function()
		tweenToScale(0.95) -- inferred equivalent call
	end)
end

local function CalculateUseItemFrameInitialRenderCount()
	if container and container.Visible then
		return CalculateGridRenderCount(container)
	end

	return 50
end

local function UseItemFrameLoadMoreItems()
	if not container then
		return
	end

	local v9 = v8 + 1
	local v10 = math.min(v8 + 25, #v7)

	for i = v9, v10 do
		local v11 = v7[i]

		if not v11 or container:FindFirstChild(v11._id) then
			continue
		end

		UseItemFrame.CreateItemTemplate(v11, OnItemSelected)
	end

	v8 = v10
end

local function UseItemFrameOnScrollPositionChanged()
	if not container then
		return
	end

	local y = container.CanvasPosition.Y
	local v9 = container.AbsoluteCanvasSize.Y - container.AbsoluteSize.Y

	if v9 > 0 and v8 < #v7 and v9 - y < 200 then
		UseItemFrameLoadMoreItems()
	end
end

local function FindContainerAndSort(instance)
	local tabs = instance:FindFirstChild("Tabs")

	if not tabs then
		return
	end

	local inventory = tabs:FindFirstChild("Inventory")

	if inventory then
		container = inventory:FindFirstChild("Container")
		sort = inventory:FindFirstChild("Sort")
	end
end

local function SetupSortButton(button)
	local textLabel2 = button:FindFirstChild("Frame"):FindFirstChild("TextLabel")

	if textLabel2 then
		textLabel2.Text = "Newest"
		v5 = "Newest"
	end

	button.MouseButton1Click:Connect(function()
		local options = button:FindFirstChild("Options")

		if options then
			options.Visible = not options.Visible
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
		end
	end)
	local options = button:FindFirstChild("Options")

	if not (options and textLabel2) then
		return
	end

	for _, childName in v do
		local child = options:FindFirstChild(childName)

		if child then
			AnimateSortButton(options, child, childName, textLabel2)
		end
	end
end

local function findReverseSortButton(instance)
	local frame = instance:FindFirstChild("Frame")
	local right = frame and frame:FindFirstChild("Right")
	local top = right and right:FindFirstChild("Top")
	local reverseSort = top and top:FindFirstChild("ReverseSort")

	if reverseSort and reverseSort:IsA("GuiButton") then
		return reverseSort
	end

	local reverseSort2 = sort and sort:FindFirstChild("ReverseSort")

	if reverseSort2 and reverseSort2:IsA("GuiButton") then
		return reverseSort2
	end

	return nil
end

local function setupReverseSortButton(p) -- 2 equivalent calls inferred from this helper
	local reverseSortButton = findReverseSortButton(p)

	if not reverseSortButton then
		return
	end

	local imageLabel = reverseSortButton:FindFirstChildOfClass("ImageLabel")
	reverseSortButton.Selectable = true
	reverseSortButton.Activated:Connect(function()
		v6 = not v6

		if imageLabel then
			imageLabel.Rotation = v6 and 180 or 0
		end

		UseItemFrame.PopulateItems()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
	end)
end

local function SetupTopBar(instance)
	local top = instance:FindFirstChild("Top")

	if not top then
		return true
	end

	textLabel = top:FindFirstChild("TextLabel")
	close = top:FindFirstChild("Close")

	if not close then
		return false
	end

	CloseButtonRegistry.Add(useItemFrame, close, function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		UseItemFrame.OnClosed:Fire(v2)
		UseItemFrame.Hide()
	end)
	return true
end

local function ConnectScrollLoading() -- 2 equivalent calls inferred from this helper
	if container then
		container:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			if not container then
				return
			end

			local y = container.CanvasPosition.Y
			local v9 = container.AbsoluteCanvasSize.Y - container.AbsoluteSize.Y

			if v9 > 0 and v8 < #v7 and v9 - y < 200 then
				UseItemFrameLoadMoreItems()
			end
		end)
	end
end

local function ConnectStateListeners()
	DataController.CreateListener(LocalPlayer, "Inventory", function()
		if UseItemFrame.IsVisible() then
			UseItemFrame.PopulateItems()
		end
	end)
	MenuState.OnScreenChanged:Connect(function()
		if UseItemFrame.IsVisible() then
			UseItemFrame.OnClosed:Fire(v2)
			UseItemFrame.Hide()
		end
	end)

	local function closeWhenActivated(flag2: boolean)
		if flag2 and UseItemFrame.IsVisible() then
			UseItemFrame.OnClosed:Fire(v2)
			UseItemFrame.Hide()
		end
	end

	MenuState.OnInspectStateChanged:Connect(closeWhenActivated)
	MenuState.OnCaseSceneStateChanged:Connect(closeWhenActivated)
end

local function EnsureInitialized()
	if flag then
		return true
	end

	mainGui = PlayerGui:FindFirstChild("MainGui")

	if not mainGui then
		warn("[UseItemFrame] MainGui not found")
		return false
	end

	local menu = mainGui:FindFirstChild("Menu")

	if not menu then
		warn("[UseItemFrame] Menu frame not found")
		return false
	end

	useItemFrame = menu:FindFirstChild("UseItemFrame")

	if not useItemFrame then
		warn("[UseItemFrame] UseItemFrame not found in Menu")
		return false
	end

	local tabs = useItemFrame:FindFirstChild("Tabs")
	local inventory = tabs and tabs:FindFirstChild("Inventory")

	if inventory then
		container = inventory:FindFirstChild("Container")
		sort = inventory:FindFirstChild("Sort")
	end

	local button = sort and sort:FindFirstChild("Button")

	if button then
		SetupSortButton(button)
	end

	setupReverseSortButton(useItemFrame) -- inferred equivalent call

	if not SetupTopBar(useItemFrame) then
		return
	end

	ConnectStateListeners()
	ConnectScrollLoading() -- inferred equivalent call
	flag = true
	return true
end

function UseItemFrame:CreateItemTemplate(callback)
	if not (self and self._id and container) then
		return
	end

	local v9 = self.Type == "Case"
	local v10 = v9 and Cases.GetCaseByName(self.Skin) or GetResolvedSkinInformation(self.Name, self.Skin)

	if not v10 then
		return
	end

	local caseRarity = v9 and v10.caseRarity or v10.rarity
	local rarity = Rarities[caseRarity]
	local imageAssetId = nil

	if v9 then
		imageAssetId = v10.imageAssetId or ""
	elseif self.Type == "Charm" then
		local pattern = self.Pattern

		if pattern and v10.charmImages then
			for _, charmImage in ipairs(v10.charmImages) do
				if charmImage.pattern ~= pattern then
					continue
				end

				imageAssetId = charmImage.assetId
				break
			end
		end

		if not imageAssetId then
			imageAssetId = v10.imageAssetId or ""
		end
	else
		imageAssetId = Skins.GetWearImageForFloat(v10, self.Float or 0.9999) or v10.imageAssetId or ""
	end

	local clone = ReplicatedStorage.Assets.UI.Inventory.ItemTemplate:Clone()
	clone.ItemContent.Rarity.BackgroundColor3 = rarity.Color
	clone.Parent = container
	clone.ItemContent.Content.Icon.Image = imageAssetId
	clone.Name = self._id
	ApplyWearAndSerialBadges(clone, self, v10)
	local charm = clone.ItemContent:FindFirstChild("Charm")

	if charm and charm:IsA("ImageLabel") then
		charm.Visible = false
		charm.Image = ""
	end

	local weaponDisplayName = GetSkinDisplayName.GetWeaponDisplayName(self.Name, self.NameTag)

	if self.StatTrack then
		weaponDisplayName = "KillTrak™ " .. weaponDisplayName or weaponDisplayName
	end

	GetSkinDisplayName.ApplyNameLabel(clone.Bottom.Footer.WeaponName, weaponDisplayName, self.NameTag)
	clone.Bottom.Footer.SkinName.Text = v9 and v10.skin or self.Skin

	if self.Type == "Charm" then
		clone.MouseButton2Click:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "UI Click")
			Router.broadcastRouter(
				"WeaponInspect",
				self.Name,
				self.Skin,
				self.Float,
				self.StatTrack,
				self.NameTag,
				self.Charm,
				self.Stickers,
				self.Type,
				self.Pattern,
				self._id,
				self.Serial,
				self.IsTradeable
			)
		end)
	end

	clone.MouseButton1Click:Connect(function()
		Router.broadcastRouter("RunInterfaceSound", "UI Click")
		callback(self)
	end)
	AnimateButton(clone)
end

function UseItemFrame.PopulateItems()
	if not container then
		return
	end

	ClearFrame(container, "Frame")
	v8 = 0
	v7 = {}
	local inventory = DataController.Get(LocalPlayer, "Inventory")

	if not inventory or type(inventory) ~= "table" then
		return
	end

	for _, v9 in ipairs(inventory) do
		local v10 = v9 and Grenades[v9.Name]
		local v11 = v9 and v9.Type == "Case"

		if not (v9 and v9._id and v9.Name and (v11 or v9.Skin)) then
			continue
		end

		if v10 or v11 or not (not (v3 and v2) or v3(v9, v2)) then
			continue
		end

		table.insert(v7, v9)
	end

	local v9 = v5 or sort and sort.Button.Frame.TextLabel.Text or "Newest"
	local sortComparisonFunction = Sort.GetSortComparisonFunction(v9, LocalPlayer, function()
		return v4
	end)

	if sortComparisonFunction then
		if v6 then
			table.sort(v7, function(a, b)
				local v10, v11 = sortComparisonFunction(a, b)

				if v11 then
					return v10
				end

				return sortComparisonFunction(b, a)
			end)
		else
			table.sort(v7, sortComparisonFunction)
		end
	end

	local v10 = math.min(
		math.max(not (container and container.Visible) and 50 or CalculateGridRenderCount(container), 50),
		#v7
	)

	for i = 1, v10 do
		local v11 = v7[i]

		if v11 then
			UseItemFrame.CreateItemTemplate(v11, OnItemSelected)
		end
	end

	v8 = v10
end

function UseItemFrame.Show(p, p2)
	if not EnsureInitialized() then
		warn("[UseItemFrame] Failed to initialize")
		return
	end

	if not useItemFrame then
		return
	end

	v2 = p
	v3 = p2

	if textLabel then
		local sourceItem = p.SourceItem

		if sourceItem then
			local v9 = (sourceItem.StatTrack and "KillTrak™ " or "") .. sourceItem.Name

			if sourceItem.Skin then
				v9 ..= " | " .. sourceItem.Skin
			end

			textLabel.Text = `Select an item to use with {v9}`
		elseif p.Title then
			textLabel.Text = p.Title
		else
			textLabel.Text = "Select an item"
		end
	end

	UseItemFrame.PopulateItems()
	useItemFrame.Visible = true
end

function UseItemFrame.Hide()
	if useItemFrame then
		useItemFrame.Visible = false
	end

	v2 = nil
	v3 = nil
end

function UseItemFrame.IsVisible()
	return useItemFrame and useItemFrame.Visible or false
end

function UseItemFrame.Initialize(p, instance)
	mainGui = p
	useItemFrame = instance
	local tabs = instance:FindFirstChild("Tabs")
	local inventory = tabs and tabs:FindFirstChild("Inventory")

	if inventory then
		container = inventory:FindFirstChild("Container")
		sort = inventory:FindFirstChild("Sort")
	end

	local button = sort and sort:FindFirstChild("Button")

	if button then
		SetupSortButton(button)
	end

	setupReverseSortButton(instance) -- inferred equivalent call

	if not SetupTopBar(instance) then
		return
	end

	ConnectScrollLoading() -- inferred equivalent call
	instance.Visible = false
	flag = true
end

function UseItemFrame.Start()
	Actions.InitializeAll()
	ConnectStateListeners()
end

Collections.ObserveAvailableCollections(function(p)
	v4 = p
end)

function UseItemFrame.TriggerAction(p: string, p2)
	local v9 = Actions.Get(p)

	if v9 then
		UseItemFrame.Show(v9.GetContext(p2), v9.GetFilter(p2))
	else
		warn(`[UseItemFrame] Unknown action type: {p}`)
	end
end

function UseItemFrame.GetActions()
	return Actions
end

return UseItemFrame