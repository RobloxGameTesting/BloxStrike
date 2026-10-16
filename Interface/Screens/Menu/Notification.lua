local Notification = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Router = require(ReplicatedStorage.Database.Security.Router)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local GamepadNavigation = require(ReplicatedStorage.Interface.GamepadNavigation)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local v = nil
local v2 = nil

local function BlockClickThrough(parent) -- 1 equivalent call inferred from this helper
	parent.Active = true
	local textButton = Instance.new("TextButton")
	textButton.Name = "ClickBlocker"
	textButton.Size = UDim2.fromScale(1, 1)
	textButton.BackgroundTransparency = 1
	textButton.Text = ""
	textButton.AutoButtonColor = false
	textButton.Selectable = false
	textButton.ZIndex = 0
	textButton.Parent = parent
end

local function IsUsableSelection(parent)
	if not (parent and parent.Parent and parent.Selectable and parent.Interactable) then
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

local function SelectCloseButton() -- 1 equivalent call inferred from this helper
	local close = v.Footer.Close

	if GamepadNavigation.IsGamepadActive() and IsUsableSelection(close) then
		GuiService.SelectedObject = close
	end
end

function Notification.CreateNotification(p: string, text: string)
	Router.broadcastRouter("RunInterfaceSound", "Notification " .. p)
	v.TextLabel.Text = text

	if not v.Visible then
		local selectedObject = GuiService.SelectedObject

		if not selectedObject or selectedObject:IsDescendantOf(v) then
			selectedObject = nil
		end

		v2 = selectedObject
	end

	v.Visible = true
	CloseButtonRegistry.BringToFront(v)
	SelectCloseButton() -- inferred equivalent call
end

function Notification.CloseNotification()
	v.Visible = false
	local v3 = v2
	v2 = nil
	task.defer(function()
		if v.Visible then
			v2 = v2 or v3
			return
		end

		local selectedObject = GuiService.SelectedObject

		if selectedObject == nil or selectedObject:IsDescendantOf(v) then
			local v4 = GuiService
			local selectedObject2

			if GamepadNavigation.IsGamepadActive() and IsUsableSelection(v3) then
				selectedObject2 = v3
			end

			v4.SelectedObject = selectedObject2
		end
	end)
end

function Notification.IsMenuOpen()
	local menuFrame = MenuState.GetMenuFrame()
	return menuFrame ~= nil and menuFrame.Visible
end

function Notification.Initialize(_, parent)
	v = parent
	BlockClickThrough(parent) -- inferred equivalent call
	CloseButtonRegistry.Add(v, v.Footer.Close, function()
		Notification.CloseNotification()
	end)
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		local selectedObject = GuiService.SelectedObject

		if v.Visible and not (selectedObject and selectedObject:IsDescendantOf(v)) then
			task.defer(SelectCloseButton)
		end
	end)
	Router.observerRouter("CreateMenuNotification", function(p: string, p2: string)
		Notification.CreateNotification(p, p2)
	end)
	Remotes.UI.CreateMenuNotification.Listen(function(data)
		if data.skipWhenMenuClosed and not Notification.IsMenuOpen() then
			return
		end

		Notification.CreateNotification(data.notificationType, data.text)
	end)
end

return Notification