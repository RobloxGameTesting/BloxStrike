local MenuState = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local Signal = require(ReplicatedStorage.Packages.Signal)
MenuState.OnScreenChanged = Signal.new()
MenuState.OnInspectStateChanged = Signal.new()
MenuState.OnCaseSceneStateChanged = Signal.new()
MenuState.OnTradeUpStateChanged = Signal.new()
local v = nil
local flag = false
local flag2 = false
local flag3 = false
local v2 = nil
local v3 = nil
local v4 = false
local v5 = {}
local v6 = {
	Loadout = true,
	Inventory = true,
	Gamemodes = true,
	Settings = true,
	Store = true,
	Career = true,
	Progression = true,
	GlobalMarketPlace = true,
	Blackmarket = true
}
local v7 = { Blackmarket = true }
local mainGui = nil
local menu = nil

local function getMenuBlur() -- 2 equivalent calls inferred from this helper
	if menu then
		return menu
	end

	menu = Lighting:FindFirstChild("Menu")
	return menu
end

local function getMainGui() -- 1 equivalent call inferred from this helper
	if not mainGui then
		mainGui = PlayerGui:FindFirstChild("MainGui")
	end

	return mainGui
end

local function getMenuFrame() -- 1 equivalent call inferred from this helper
	local mainGui2 = getMainGui() -- inferred equivalent call

	if mainGui2 then
		return (mainGui2:FindFirstChild("Menu"))
	end

	return nil
end

local function isEffectivelyVisible(parent)
	if not parent:IsDescendantOf(PlayerGui) then
		return false
	end

	while parent and parent:IsA("GuiObject") do
		if not parent.Visible then
			return false
		end

		parent = parent.Parent
	end

	return true
end

function MenuState.Initialize(p)
	mainGui = p
	menu = getMenuBlur() -- inferred equivalent call
end

function MenuState.GetCurrentScreen()
	return v
end

function MenuState.IsPreservableScreen(p: string?)
	return p ~= nil and v6[p] == true
end

function MenuState.IsSceneScreen(p: string?)
	return p ~= nil and v7[p] == true
end

function MenuState.IsInspectActive()
	return flag
end

function MenuState.IsStoreEnabled()
	return ReplicatedStorage:GetAttribute("Environment") == "Production"
end

function MenuState.SetScreen(p: string?)
	if p == v or p == "Store" and not MenuState.IsStoreEnabled() then
		return
	end

	local v8 = v
	v = p
	MenuState.OnScreenChanged:Fire(v8, p)
end

function MenuState.SetWantsMainMenu(flag4: boolean)
	v4 = flag4 == true
end

function MenuState.WantsMainMenu()
	return v4
end

function MenuState.HideMenu()
	local menuFrame = getMenuFrame() -- inferred equivalent call

	if menuFrame then
		menuFrame.Visible = false
	end

	MenuState.SetScreen(nil)
end

function MenuState.EnterInspect()
	if flag then
		return
	end

	v2 = v
	flag = true
	MenuState.OnInspectStateChanged:Fire(true)
end

function MenuState.ExitInspect()
	if not flag then
		return
	end

	flag = false
	MenuState.OnInspectStateChanged:Fire(false)
	v2 = nil
end

function MenuState.GetScreenBeforeInspect()
	return v2
end

function MenuState.IsCaseSceneActive()
	return flag2
end

function MenuState.EnterCaseScene()
	if flag2 then
		return
	end

	v3 = v
	flag2 = true
	MenuState.OnCaseSceneStateChanged:Fire(true)
end

function MenuState.ExitCaseScene()
	if not flag2 then
		return
	end

	flag2 = false
	MenuState.OnCaseSceneStateChanged:Fire(false)
	v3 = nil
end

function MenuState.GetScreenBeforeCaseScene()
	return v3
end

function MenuState.IsTradeUpActive()
	return flag3
end

function MenuState.EnterTradeUp()
	if flag3 then
		return
	end

	flag3 = true
	MenuState.OnTradeUpStateChanged:Fire(true)
end

function MenuState.ExitTradeUp()
	if not flag3 then
		return
	end

	flag3 = false
	MenuState.OnTradeUpStateChanged:Fire(false)
end

local v8 = nil

function MenuState.HoldNavigationSelection(p)
	v8 = p
end

function MenuState.IsNavigationSelectionHeld()
	return v8 ~= nil and GuiService.SelectedObject == v8
end

function MenuState.IsSelectionWithin(ancestor)
	local selectedObject = GuiService.SelectedObject
	return selectedObject ~= nil and (selectedObject == ancestor or selectedObject:IsDescendantOf(ancestor))
end

local function isUsableSelection(p) -- 2 equivalent calls inferred from this helper
	return p.Selectable and p.Interactable and isEffectivelyVisible(p)
end

function MenuState.RegisterBumperOverride(frame, handler, selectionScope, refocusTarget, isActive)
	for _, v9 in ipairs(v5) do
		if v9.frame ~= frame then
			continue
		end

		v9.handler = handler
		v9.selectionScope = selectionScope
		v9.refocusTarget = refocusTarget
		v9.isActive = isActive
		return
	end

	table.insert(v5, {
		frame = frame,
		handler = handler,
		selectionScope = selectionScope,
		refocusTarget = refocusTarget,
		isActive = isActive
	})
end

function MenuState.HandleBumperInput(flag4: boolean)
	for _, v9 in ipairs(v5) do
		local selectionScope = v9.selectionScope
		local v10

		if v9.isActive == nil then
			v10 = false
		else
			v10 = v9.isActive()
		end

		if not (isEffectivelyVisible(v9.frame) and (not selectionScope or v10 or MenuState.IsSelectionWithin(selectionScope)) and v9.handler(flag4)) then
			continue
		end

		if selectionScope then
			local refocusTarget = v9.refocusTarget or selectionScope
			task.defer(function()
				local selectedObject = GuiService.SelectedObject

				if
					selectedObject
					and selectedObject:IsDescendantOf(selectionScope)
					and isUsableSelection(selectedObject) -- inferred equivalent call
				then
					return
				end

				for _, guiObject in ipairs(refocusTarget:GetDescendants()) do
					if not (guiObject:IsA("GuiObject") and isUsableSelection(guiObject)) then -- inferred equivalent call
						continue
					end

					GuiService.SelectedObject = guiObject
					break
				end
			end)
		end

		return true
	end

	return false
end

function MenuState.GetNextBumperTab(instance, list, p: string?, flag4: boolean)
	local childNames = {}

	for _, childName in ipairs(list) do
		local guiObject = instance:FindFirstChild(childName)

		if guiObject and guiObject:IsA("GuiObject") and guiObject.Visible then
			table.insert(childNames, childName)
		end
	end

	local count = #childNames

	if count == 0 then
		return nil
	end

	local index

	if p then
		index = table.find(childNames, p)
	end

	if index then
		return childNames[(index - 1 + (flag4 and -1 or 1)) % count + 1]
	end

	return childNames[1]
end

function MenuState.SetBlurEnabled(enabled: boolean)
	local menuBlur = getMenuBlur() -- inferred equivalent call

	if menuBlur then
		menuBlur.Enabled = enabled
	end
end

MenuState.GetMenuFrame = getMenuFrame
MenuState.GetMainGui = getMainGui
return MenuState