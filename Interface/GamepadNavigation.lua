local GamepadNavigation = {}
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local v = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
	[Enum.UserInputType.Gamepad5] = true,
	[Enum.UserInputType.Gamepad6] = true,
	[Enum.UserInputType.Gamepad7] = true,
	[Enum.UserInputType.Gamepad8] = true
}
local v2 = {
	[Enum.UserInputType.Keyboard] = true,
	[Enum.UserInputType.MouseMovement] = true,
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseButton2] = true,
	[Enum.UserInputType.MouseButton3] = true,
	[Enum.UserInputType.MouseWheel] = true,
	[Enum.UserInputType.Touch] = true
}
GamepadNavigation.NO_FALLBACK_ATTRIBUTE = "GamepadNavigationNoFallback"
local v3 = Enum.ContextActionPriority.High.Value + 1000
local Thumbstick2 = Enum.KeyCode.Thumbstick2
local vectors = {
	[Enum.KeyCode.DPadUp] = Vector2.new(0, -1),
	[Enum.KeyCode.DPadDown] = Vector2.new(0, 1),
	[Enum.KeyCode.DPadLeft] = Vector2.new(-1, 0),
	[Enum.KeyCode.DPadRight] = Vector2.new(1, 0)
}
local flag = false
local v4 = false
local v5 = false
local v6 = nil
local now = 0
local now2 = 0
local zero = Vector2.zero
local v7 = nil
local v8 = "Y"
local zero2 = Vector2.zero
local now3 = 0
local v9 = nil
local v10 = 0

local function isGamepadInput(p) -- 2 equivalent calls inferred from this helper
	return v[p] == true
end

local function isEffectivelyVisible(parent)
	while parent do
		if parent:IsA("GuiObject") and not parent.Visible then
			return false
		end

		if parent:IsA("LayerCollector") then
			return parent.Enabled and parent:IsDescendantOf(LocalPlayer)
		else
			parent = parent.Parent
		end
	end

	return false
end

local function isUsable(guiObject)
	if not (guiObject and guiObject.Parent and guiObject:IsA("GuiObject")) then
		return false
	end

	if not (guiObject.Selectable and guiObject.Interactable) then
		return false
	end

	local absoluteSize = guiObject.AbsoluteSize
	return absoluteSize.X > 1 and absoluteSize.Y > 1 and isEffectivelyVisible(guiObject)
end

local function isWithin(instance, ancestor) -- 7 equivalent calls inferred from this helper
	return instance ~= nil and (instance == ancestor or instance:IsDescendantOf(ancestor))
end

local function getNavigatedSelection() -- 5 equivalent calls inferred from this helper
	local selectedObject = GuiService.SelectedObject

	if isUsable(selectedObject) then
		return selectedObject
	end

	return nil
end

local function isMenuUp() -- 1 equivalent call inferred from this helper
	local menuFrame = MenuState.GetMenuFrame()
	return menuFrame ~= nil and isEffectivelyVisible(menuFrame)
end

local function getSelectionBehavior(data, point: Vector2) -- 1 equivalent call inferred from this helper
	if point.X < 0 then
		return data.SelectionBehaviorLeft
	end

	if point.X > 0 then
		return data.SelectionBehaviorRight
	end

	if point.Y < 0 then
		return data.SelectionBehaviorUp
	end

	return data.SelectionBehaviorDown
end

local function isTrappingGroup(parent, point: Vector2?)
	if not parent.SelectionGroup then
		return false
	end

	if not point then
		return parent.SelectionBehaviorUp == Enum.SelectionBehavior.Stop
			or parent.SelectionBehaviorDown == Enum.SelectionBehavior.Stop
			or parent.SelectionBehaviorLeft == Enum.SelectionBehavior.Stop
			or parent.SelectionBehaviorRight == Enum.SelectionBehavior.Stop
	end

	return getSelectionBehavior(parent, point) == Enum.SelectionBehavior.Stop -- inferred equivalent call
end

local function getLayer(navigatedSelection, point: Vector2?)
	local menuFrame = MenuState.GetMenuFrame()
	local parent = navigatedSelection.Parent

	while parent do
		if parent:IsA("LayerCollector") then
			return parent
		end

		if parent:IsA("GuiObject") then
			if isTrappingGroup(parent, point) or menuFrame and parent.Parent == menuFrame then
				return parent
			end
		end

		parent = parent.Parent
	end

	return nil
end

local function isFallbackDisabled(parent)
	while parent and not parent:IsA("LayerCollector") do
		if parent:GetAttribute("GamepadNavigationNoFallback") == true then
			return true
		else
			parent = parent.Parent
		end
	end

	return parent ~= nil and parent:GetAttribute("GamepadNavigationNoFallback") == true
end

local function scrollIntoView(data)
	local parent = data.Parent

	while parent and not parent:IsA("LayerCollector") do
		if parent:IsA("ScrollingFrame") then
			local absolutePosition = parent.AbsolutePosition
			local absoluteWindowSize = parent.AbsoluteWindowSize
			local v11 = data.AbsolutePosition - absolutePosition
			local v12 = v11 + data.AbsoluteSize

			local function shift(p: number, p2: number, p3: number) -- 2 equivalent calls inferred from this helper
				if p < 0 then
					return p
				end

				if p3 < p2 then
					return (math.min(p2 - p3, p))
				end

				return 0
			end

			local v13 = shift(v11.X, v12.X, absoluteWindowSize.X) -- inferred equivalent call
			local v14 = shift(v11.Y, v12.Y, absoluteWindowSize.Y) -- inferred equivalent call

			if v13 ~= 0 or v14 ~= 0 then
				local canvasPosition = parent.CanvasPosition
				local v15 = parent.AbsoluteCanvasSize - absoluteWindowSize
				parent.CanvasPosition = Vector2.new(
					math.clamp(canvasPosition.X + v13, 0, (math.max(0, v15.X))),
					(math.clamp(canvasPosition.Y + v14, 0, (math.max(0, v15.Y))))
				)
			end
		end

		parent = parent.Parent
	end
end

local function setSelection(scrollingFrame) -- 1 equivalent call inferred from this helper
	if scrollingFrame then
		scrollIntoView(scrollingFrame)
	end

	if GuiService.SelectedObject == scrollingFrame then
		return true
	end

	return pcall(function()
		GuiService.SelectedObject = scrollingFrame
	end) and GuiService.SelectedObject == scrollingFrame
end

local function getNextSelectionProperty(point: Vector2) -- 1 equivalent call inferred from this helper
	if point.X == 0 then
		if point.Y < 0 then
			return "NextSelectionUp"
		end

		return "NextSelectionDown"
	elseif point.X < 0 then
		return "NextSelectionLeft"
	else
		return "NextSelectionRight"
	end
end

local function navigateFallback(point: Vector2, now4: number)
	local navigatedSelection = getNavigatedSelection() -- inferred equivalent call

	if not navigatedSelection or GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then
		return
	end

	if navigatedSelection[getNextSelectionProperty(point)] ~= nil or isFallbackDisabled(navigatedSelection) then -- inferred equivalent call
		return
	end

	local now5 = os.clock()
	task.delay(0.06, function()
		if GuiService.SelectedObject == navigatedSelection then
			local v11 = now

			if
				not (now4 - 0.05 <= v11)
				and not GuiService.MenuIsOpen
				and not v7
				and not (now5 < now2)
				and GamepadNavigation.IsGamepadActive()
			then
				local layer = getLayer(navigatedSelection, point)

				if not layer then
					return
				end

				local v12 = navigatedSelection.AbsolutePosition + navigatedSelection.AbsoluteSize / 2
				local v13 = 1e999
				local selectedObject = nil

				for _, guiObject in layer:GetDescendants() do
					if
						guiObject == navigatedSelection
						or not guiObject:IsA("GuiObject")
						or guiObject:IsA("ScrollingFrame")
						or not isUsable(guiObject)
					then
						continue
					end

					local vector = guiObject.AbsolutePosition + guiObject.AbsoluteSize / 2 - v12
					local dot = vector:Dot(point)

					if dot <= 1 then
						continue
					end

					local v14 = dot + (vector - point * dot).Magnitude * 2

					if not (v14 < v13) then
						continue
					end

					selectedObject = guiObject
					v13 = v14
				end

				if selectedObject then
					if selectedObject then
						scrollIntoView(selectedObject)
					end

					if GuiService.SelectedObject == selectedObject then
						return
					end

					if pcall(function()
						GuiService.SelectedObject = selectedObject
					end) then
						local _ = GuiService.SelectedObject == selectedObject
					end
				end
			end
		end
	end)
end

local function refreshCameraStickHold()
	local menuUp = isMenuUp() -- inferred equivalent call

	if menuUp == v4 then
		return
	end

	v4 = menuUp

	if menuUp then
		ContextActionService:BindActionAtPriority("GamepadNavigationMenuCameraStick", function(_, p, p2)
			if
				p ~= Enum.UserInputState.End
				and p ~= Enum.UserInputState.Cancel
				and not (p2.Position.Magnitude < 0.1)
				and (getNavigatedSelection() ~= nil or v7) -- inferred equivalent call
			then
				return Enum.ContextActionResult.Sink
			end

			return Enum.ContextActionResult.Pass
		end, false, v3, Thumbstick2)
	else
		ContextActionService:UnbindAction("GamepadNavigationMenuCameraStick")
	end
end

local function getMaxCanvas(p, p2: string) -- 2 equivalent calls inferred from this helper
	local absoluteCanvasSize = p.AbsoluteCanvasSize
	local absoluteWindowSize = p.AbsoluteWindowSize
	local v11

	if p2 == "X" then
		v11 = absoluteCanvasSize.X - absoluteWindowSize.X
	else
		v11 = absoluteCanvasSize.Y - absoluteWindowSize.Y
	end

	return (math.max(0, v11))
end

local function canScrollAlong(p, p2: string)
	local scrollingDirection = p.ScrollingDirection
	local v11

	if scrollingDirection == Enum.ScrollingDirection.XY then
		v11 = true
	else
		local v12

		if p2 == "X" then
			v12 = Enum.ScrollingDirection.X
		else
			v12 = Enum.ScrollingDirection.Y
		end

		v11 = scrollingDirection == v12
	end

	local scrollingEnabled = p.ScrollingEnabled

	if not scrollingEnabled then
		return scrollingEnabled
	end

	if v11 then
		scrollingEnabled = false

		if getMaxCanvas(p, p2) > 1 then -- inferred equivalent call
			scrollingEnabled = isEffectivelyVisible(p)
		end
	else
		scrollingEnabled = v11
	end

	return scrollingEnabled
end

local function getStickAxis() -- 2 equivalent calls inferred from this helper
	local x = math.abs(zero.X)
	local y = math.abs(zero.Y)

	if y > 0.3 and x <= y then
		return "Y"
	end

	if x > 0.3 and y < x then
		return "X"
	end

	return nil
end

local function findTallestList(folder)
	local v11 = nil

	for _, scrollingFrame in folder:GetDescendants() do
		if not (scrollingFrame:IsA("ScrollingFrame") and canScrollAlong(scrollingFrame, "Y") and (not v11 or scrollingFrame.AbsoluteWindowSize.Y > v11.AbsoluteWindowSize.Y)) then
			continue
		end

		v11 = scrollingFrame
	end

	return v11
end

local function getOpenScreenOutside(navigatedSelection)
	local menuFrame = MenuState.GetMenuFrame()
	local currentScreen = MenuState.GetCurrentScreen()

	if menuFrame and currentScreen and isWithin(navigatedSelection, menuFrame) then -- inferred equivalent call
		local guiObject = menuFrame:FindFirstChild(currentScreen)

		if
			guiObject
			and guiObject:IsA("GuiObject")
			and isEffectivelyVisible(guiObject)
			and not isWithin(navigatedSelection, guiObject) -- inferred equivalent call
		then
			return guiObject
		end

		return nil
	end

	return nil
end

local function getStickScrollFrame(stickAxis: string)
	local navigatedSelection = getNavigatedSelection() -- inferred equivalent call

	if not navigatedSelection then
		return nil
	end

	local parent = navigatedSelection.Parent

	while parent and not parent:IsA("LayerCollector") do
		if parent:IsA("ScrollingFrame") and canScrollAlong(parent, stickAxis) then
			return parent
		else
			parent = parent.Parent
		end
	end

	if stickAxis == "X" or isFallbackDisabled(navigatedSelection) then
		return nil
	end

	local layer = getLayer(navigatedSelection)
	local selected = layer and findTallestList(layer)

	if selected then
		return selected
	end

	local openScreenOutside = getOpenScreenOutside(navigatedSelection)
	return openScreenOutside and findTallestList(openScreenOutside)
end

local function canStartStickScroll()
	local isGamepadActive = GamepadNavigation.IsGamepadActive()

	if isGamepadActive then
		isGamepadActive = false

		if getNavigatedSelection() ~= nil then -- inferred equivalent call
			isGamepadActive = not (GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() or MenuState.IsInspectActive() or MenuState.IsCaseSceneActive())
		end
	end

	return isGamepadActive
end

local function isInView(p, p2) -- 2 equivalent calls inferred from this helper
	local absolutePosition = p2.AbsolutePosition
	local v11 = absolutePosition + p2.AbsoluteWindowSize
	local absolutePosition2 = p.AbsolutePosition
	local v12 = absolutePosition2 + p.AbsoluteSize
	return absolutePosition2.X >= absolutePosition.X - 1
		and absolutePosition2.Y >= absolutePosition.Y - 1
		and v12.X <= v11.X + 1
		and v12.Y <= v11.Y + 1
end

local function findButtonInView(folder, navigatedSelection, p: string)
	local vector = folder.AbsolutePosition + folder.AbsoluteWindowSize / 2

	if navigatedSelection and isWithin(navigatedSelection, folder) then -- inferred equivalent call
		local v11 = navigatedSelection.AbsolutePosition + navigatedSelection.AbsoluteSize / 2

		if p == "Y" then
			vector = Vector2.new(v11.X, vector.Y)
		else
			vector = Vector2.new(vector.X, v11.Y)
		end
	end

	local v11 = 1e999
	local v12 = nil

	for _, descendant in folder:GetDescendants() do
		if
			not descendant:IsA("GuiObject")
			or (descendant:IsA("ScrollingFrame") or descendant:IsA("TextBox"))
			or not isUsable(descendant)
		then
			continue
		end

		if not isInView(descendant, folder) then -- inferred equivalent call
			continue
		end

		local magnitude = (descendant.AbsolutePosition + descendant.AbsoluteSize / 2 - vector).Magnitude

		if not (magnitude < v11) then
			continue
		end

		v12 = descendant
		v11 = magnitude
	end

	return v12
end

local function startStickScroll(stickScrollFrame, stickAxis: string)
	v7 = stickScrollFrame
	v8 = stickAxis
	zero2 = stickScrollFrame.CanvasPosition
	now3 = os.clock()
	GuiService.GuiNavigationEnabled = false
	ContextActionService:BindActionAtPriority("GamepadNavigationStickScrollSink", function()
		return Enum.ContextActionResult.Sink
	end, false, v3, Enum.KeyCode.Thumbstick1, Enum.KeyCode.ButtonA)
end

local function stopStickScroll()
	local v11 = v7
	v7 = nil
	GuiService.GuiNavigationEnabled = true
	ContextActionService:UnbindAction("GamepadNavigationStickScrollSink")

	if
		not v11
		or (not GamepadNavigation.IsGamepadActive() or now3 < now2 or (v11.CanvasPosition - zero2).Magnitude < 1)
	then
		return
	end

	local navigatedSelection = getNavigatedSelection() -- inferred equivalent call

	if navigatedSelection and isWithin(navigatedSelection, v11) and isInView(navigatedSelection, v11) then -- inferred equivalent call
		return
	end

	local buttonInView = findButtonInView(v11, navigatedSelection, v8)

	if buttonInView then
		now2 = os.clock()

		if buttonInView then
			scrollIntoView(buttonInView)
		end

		if GuiService.SelectedObject == buttonInView then
			return
		end

		if pcall(function()
			GuiService.SelectedObject = buttonInView
		end) then
			local _ = GuiService.SelectedObject == buttonInView
		end
	end
end

local function updateStickScroll(p: number)
	local v11 = v7

	if not v11 then
		return
	end

	local v12 = v8
	local success, result = pcall(function()
		return GamepadNavigation.IsGamepadActive()
			and not GuiService.MenuIsOpen
			and not MenuState.IsInspectActive()
			and canScrollAlong(v11, v12)
	end)

	if getStickAxis() ~= v12 or not (success and result) then -- inferred equivalent call
		stopStickScroll()
		return
	end

	local y

	if v12 == "Y" then
		y = zero.Y
	else
		y = zero.X
	end

	local v13 = math.clamp((math.abs(y) - 0.3) / 0.7, 0, 1)
	local absoluteWindowSize = v11.AbsoluteWindowSize
	local v14 = math.sign(y) * v13 * v13 * 1.6
	local v15

	if v12 == "Y" then
		v15 = absoluteWindowSize.Y
	else
		v15 = absoluteWindowSize.X
	end

	local v16 = v14 * v15 * p
	local canvasPosition = v11.CanvasPosition
	local maxCanvas = getMaxCanvas(v11, v12) -- inferred equivalent call
	local canvasPosition2

	if v12 == "Y" then
		canvasPosition2 = Vector2.new(canvasPosition.X, (math.clamp(canvasPosition.Y - v16, 0, maxCanvas)))
	else
		canvasPosition2 = Vector2.new(math.clamp(canvasPosition.X + v16, 0, maxCanvas), canvasPosition.Y)
	end

	v11.CanvasPosition = canvasPosition2
end

function GamepadNavigation.IsGamepadActive()
	local lastInputType = UserInputService:GetLastInputType()

	if isGamepadInput(lastInputType) then -- inferred equivalent call
		return true
	end

	return not v2[lastInputType] and UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
end

GamepadNavigation.IsUsable = isUsable
GamepadNavigation.ScrollIntoView = scrollIntoView

function GamepadNavigation.FindFirstSelectable(folder)
	local v11 = 1e999
	local v12 = nil

	for _, descendant in folder:GetDescendants() do
		if not descendant:IsA("GuiObject") or descendant:IsA("ScrollingFrame") or not isUsable(descendant) then
			continue
		end

		local absolutePosition = descendant.AbsolutePosition
		local v13 = math.floor(absolutePosition.Y / 8) * 100000 + absolutePosition.X

		if descendant:IsA("TextBox") then
			v13 += 1000000000
		end

		if not (v13 < v11) then
			continue
		end

		v12 = descendant
		v11 = v13
	end

	return v12
end

function GamepadNavigation.Focus(scrollingFrame)
	if not (scrollingFrame and GamepadNavigation.IsGamepadActive()) then
		return false
	end

	if not isUsable(scrollingFrame) or scrollingFrame:IsA("ScrollingFrame") then
		scrollingFrame = GamepadNavigation.FindFirstSelectable(scrollingFrame)
	end

	if not scrollingFrame then
		return false
	end

	now2 = os.clock()
	return setSelection(scrollingFrame) -- inferred equivalent call
end

function GamepadNavigation:TrapPopup(callback)
	self.SelectionGroup = true
	self.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	self.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	self.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	self.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	local v11 = nil

	local function onVisibilityChanged()
		if self.Visible and self.Parent then
			local selectedObject = GuiService.SelectedObject

			if selectedObject then
				if isWithin(selectedObject, self) then -- inferred equivalent call
					selectedObject = nil
				end
			else
				selectedObject = nil
			end

			v11 = selectedObject
			task.defer(function()
				if self.Visible and self.Parent and not isWithin(GuiService.SelectedObject, self) then -- inferred equivalent call
					local v12 = callback and callback()

					if not (v12 and GamepadNavigation.Focus(v12)) then
						GamepadNavigation.Focus(self)
					end
				end
			end)
		else
			local v12 = v11
			v11 = nil
			local selectedObject = GuiService.SelectedObject

			if selectedObject == nil then
				if isUsable(v12) then
					GamepadNavigation.Focus(v12)
				end
			elseif (isWithin(selectedObject, self) or not isUsable(selectedObject)) and isUsable(v12) then -- inferred equivalent call
				GamepadNavigation.Focus(v12)
			end
		end
	end

	self:GetPropertyChangedSignal("Visible"):Connect(onVisibilityChanged)
	self.AncestryChanged:Connect(function()
		if self.Parent == nil and v11 then
			task.defer(onVisibilityChanged)
		end
	end)

	if self.Visible then
		onVisibilityChanged()
	end
end

function GamepadNavigation.Initialize()
	if flag then
		return
	end

	flag = true
	UserInputService.InputBegan:Connect(function(input)
		local v11 = vectors[input.KeyCode]

		if v11 and isGamepadInput(input.UserInputType) then -- inferred equivalent call
			navigateFallback(v11, os.clock())
		end
	end)
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		now = os.clock()
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			local vector = Vector2.new(input.Position.X, input.Position.Y)

			if vector.Magnitude <= 0.2 then
				v5 = false
				v6 = nil
			else
				local v11 = v6 or os.clock()
				v6 = v11

				if not v5 and vector.Magnitude >= 0.8 then
					v5 = true
					local v12

					if math.abs(vector.X) > math.abs(vector.Y) then
						v12 = Vector2.new(math.sign(vector.X), 0)
					else
						v12 = Vector2.new(0, -math.sign(vector.Y))
					end

					navigateFallback(v12, v11)
				end
			end
		else
			if input.KeyCode ~= Thumbstick2 then
				return
			end

			zero = Vector2.new(input.Position.X, input.Position.Y)
			local stickAxis = getStickAxis() -- inferred equivalent call

			if not stickAxis then
				v9 = nil
			elseif not v7 and (stickAxis ~= v9 or os.clock() - v10 > 0.25) and canStartStickScroll() then
				local now4 = os.clock()
				v9 = stickAxis
				v10 = now4
				local stickScrollFrame = getStickScrollFrame(stickAxis)

				if stickScrollFrame then
					startStickScroll(stickScrollFrame, stickAxis)
				end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick1 then
			v5 = false
			v6 = nil
		elseif input.KeyCode == Thumbstick2 then
			zero = Vector2.zero
			v9 = nil
		end
	end)
	UserInputService.GamepadDisconnected:Connect(function()
		zero = Vector2.zero
		v9 = nil
		v5 = false
		v6 = nil
	end)
	RunService.RenderStepped:Connect(updateStickScroll)
	task.spawn(function()
		while true do
			refreshCameraStickHold()
			task.wait(0.25)
		end
	end)
end

return GamepadNavigation