local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Signal = require(ReplicatedStorage.Packages.Signal)
local CollectionServiceUtility = require(ReplicatedStorage.Shared.CollectionServiceUtility)
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local tweenInfo2 = TweenInfo.new(0.36, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local InventoryDropdownTemplate = ReplicatedStorage.Assets.TradingUI.Templates:WaitForChild("InventoryDropdownTemplate")
local v = nil
local MarketplaceDropdown = {}
MarketplaceDropdown.__index = MarketplaceDropdown

local function findDropdownRow(instance)
	while true do
		local parent = instance.Parent

		if
			not parent
			or not parent:IsA("GuiObject")
			or parent:IsA("ScrollingFrame")
			or parent.ClipsDescendants
			or parent:FindFirstChildWhichIsA("UIGridStyleLayout") ~= nil
		then
			break
		end

		instance = parent
	end

	return instance
end

local function getTopSiblingZIndex(dropdownRow)
	local zIndex = dropdownRow.ZIndex

	for _, guiObject in dropdownRow.Parent:GetChildren() do
		if guiObject ~= dropdownRow and guiObject:IsA("GuiObject") then
			zIndex = math.max(zIndex, guiObject.ZIndex + 1)
		end
	end

	return zIndex
end

function MarketplaceDropdown:new(list, options, p)
	assert(#list > 0, "Marketplace dropdowns require at least one option")
	local config = options or {}
	local object = setmetatable({}, MarketplaceDropdown)
	object.Instance = self
	object._config = config
	object._template = p or InventoryDropdownTemplate
	object.OptionSelected = Signal.new()
	object.Option = list[1] or ""
	object._expanded = false
	object._expandedSize = UDim2.fromScale(1, 2)
	object._hiddenSize = UDim2.fromScale(1, 0)
	self.Activated:Connect(function()
		object:Toggle()
	end)
	object._pointer = CollectionServiceUtility.FindDescendantWithTag(self, "DropdownPointer")

	if object._pointer then
		object._pointer.Rotation = 0
	end

	self.ClipsDescendants = false
	local frame = Instance.new("Frame")
	frame.Name = "Dropdown"
	local size

	if config.tweenVisibility then
		size = object._hiddenSize
	else
		size = object._expandedSize
	end

	frame.Size = size
	frame.AnchorPoint = config.AnchorPoint or Vector2.new(0.5, 0)
	frame.Position = config.Position or UDim2.new(0.5, 0, 1, 2)
	frame.BackgroundTransparency = 1
	frame.ZIndex = self.ZIndex + 1
	frame.Visible = false
	local uiListLayout = Instance.new("UIListLayout")
	uiListLayout.FillDirection = Enum.FillDirection.Vertical
	uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	if config.VerticalAlignment then
		uiListLayout.VerticalAlignment = config.VerticalAlignment
	end

	uiListLayout.Parent = frame
	frame.Parent = self
	local descendant = CollectionServiceUtility.FindDescendantWithTag(self, "SelectedOptionText")

	if descendant then
		descendant.Text = object.Option
	end

	object._selectedOptionText = descendant
	object._optionInstances = {}
	object.OptionSelected:Connect(function(p2: string)
		object:SelectOption(p2)
		object:Hide()
	end)
	object._expandTween = TweenService:Create(frame, tweenInfo2, { Size = object._expandedSize })
	object._closeTween = TweenService:Create(frame, tweenInfo, { Size = object._hiddenSize })
	object._closeTween.Completed:Connect(function(p2)
		if p2 == Enum.PlaybackState.Completed and not object._expanded then
			frame.Visible = false
			object:_lowerRow()
		end
	end)
	object._dropdownFrame = frame
	object:SetOptions(list)
	return object
end

function MarketplaceDropdown:SelectOption(p: string)
	self.Option = p

	for k, optionInstance in self._optionInstances do
		optionInstance.Visible = k ~= p
	end

	if self._selectedOptionText then
		self._selectedOptionText.Text = p
	end
end

function MarketplaceDropdown:SetOptions(list)
	for _, optionInstance in self._optionInstances do
		optionInstance:Destroy()
	end

	self._optionInstances = {}

	for _, v2 in list do
		local clone = self._template:Clone()
		clone.Name = v2
		clone.Size = UDim2.fromScale(1, 0.5)
		local descendant = CollectionServiceUtility.FindDescendantWithTag(clone, "OptionText")

		if descendant then
			descendant.Text = v2
		end

		local v3 = v2
		clone.Activated:Connect(function()
			self.OptionSelected:Fire(v3)
		end)
		self._optionInstances[v2] = clone
		clone.Parent = self._dropdownFrame
	end

	self.OptionSelected:Fire(list[1])
end

function MarketplaceDropdown:Expand()
	if self._expanded then
		return
	end

	self._expanded = true

	if v and v ~= self then
		v:Hide()
	end

	v = self

	if self._pointer then
		self._pointer.Rotation = 180
	end

	self:_raiseRow()
	self._dropdownFrame.Visible = true

	if not self._config.tweenVisibility then
		self._dropdownFrame.Size = self._expandedSize
		return
	end

	self._closeTween:Cancel()
	self._expandTween:Play()
end

function MarketplaceDropdown:Hide()
	if not self._expanded then
		return
	end

	self._expanded = false

	if v == self then
		v = nil
	end

	if self._pointer then
		self._pointer.Rotation = 0
	end

	if self._config.tweenVisibility then
		self._expandTween:Cancel()
		self._closeTween:Play()
	else
		self._dropdownFrame.Size = self._hiddenSize
		self._dropdownFrame.Visible = false
		self:_lowerRow()
	end
end

function MarketplaceDropdown:_raiseRow()
	local dropdownRow = findDropdownRow(self.Instance)

	if self._raisedRow ~= dropdownRow then
		self:_lowerRow()
		self._raisedRow = dropdownRow
		self._rowZIndex = dropdownRow.ZIndex
	end

	dropdownRow.ZIndex = getTopSiblingZIndex(dropdownRow)
end

function MarketplaceDropdown:_lowerRow()
	local raisedRow = self._raisedRow

	if raisedRow and self._rowZIndex then
		raisedRow.ZIndex = self._rowZIndex
	end

	self._raisedRow = nil
	self._rowZIndex = nil
end

function MarketplaceDropdown:Toggle()
	if self._expanded then
		self:Hide()
	else
		self:Expand()
	end
end

return MarketplaceDropdown