local Settings = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
require(script:WaitForChild("Types"))
local BindDisplay = require(script:WaitForChild("BindDisplay"))
local LocalPlayer = Players.LocalPlayer
local settings = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("Settings")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local CloseButtonRegistry = require(ReplicatedStorage.Shared.CloseButtonRegistry)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Profiler = require(ReplicatedStorage.Shared.Profiler)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Pages = require(ReplicatedStorage.Database.Custom.GameStats.UI.Settings.Pages)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local EditMobile = require(ReplicatedStorage.Interface.Screens.Menu.Dashboard.EditMobile)
local CrosshairPreview = require(script.Templates.CrosshairPreview)
local Dropdown = require(script.Templates.Dropdown)
local Keybind = require(script.Templates.Keybind)
local Number = require(script.Templates.Number)
local Toggle = require(script.Templates.Toggle)
local Slider = require(script.Templates.Slider)
local color = Color3.fromRGB(34, 38, 47)
local color2 = Color3.fromRGB(125, 206, 243)
local v = { "Global Shadows", "Glass Shatter", "First Person Tracers", "Muzzle Flash", "Ragdolls" }
local color3 = Color3.fromRGB(255, 255, 255)
local v2 = { "Info" }
local v3 = {
	Keybinds = {
		"Keyboard & Mouse Settings",
		"Movement Keys",
		"Weapon Keys",
		"UI Keys",
		"Communication Options"
	},
	Game = { "Item", "HUD", "Crosshair", "Viewmodel", "Radar/Tablet", "Other" },
	Audio = { "Audio", "Music", "Voice Chat", "Other" }
}
local v4 = { "Video", "Audio", "Game", "Keybinds" }
local v5 = { Video = "Video", Audio = "Audio", Game = "Game", Keybinds = "Keyboard/Mouse" }
local v6 = nil
local v7 = {}
local batch = nil
local count = 0
local v8 = nil
local v9 = {}
local v10 = {}
local v11 = {}
local v12 = {}
local v13 = nil
local v14 = {}
local v15 = nil
local v16 = nil
local v17 = nil
local v18 = nil
local v19 = nil
local v20 = 0
local selectedObject = nil
local v21 = "Video"
local v22 = {
	CrosshairPreviewTemplate = nil,
	DropdownTemplate = nil,
	KeybindTemplate = nil,
	NumberTemplate = nil,
	ToggleTemplate = nil,
	SliderTemplate = nil
}

local function NOOP() end

local function DeepCopy(items)
	if type(items) ~= "table" then
		return items
	end

	local result = {}

	for k, item in pairs(items) do
		result[k] = DeepCopy(item)
	end

	return result
end

local function ResolveSettingPath(result, value: string)
	local v23 = string.split(value, ".")

	for i = 2, #v23 - 1 do
		local v24 = v23[i]

		if type(result[v24]) ~= "table" then
			result[v24] = {}
		end

		result = result[v24]
	end

	return result, v23[#v23]
end

local function DeepEqual(items, items2)
	if items == items2 then
		return true
	end

	if not (type(items) == type(items2) and type(items) == "table") then
		return false
	end

	local v23 = {}

	for k, item in pairs(items) do
		if not DeepEqual(item, items2[k]) then
			return false
		end

		v23[k] = true
	end

	for k in pairs(items2) do
		if not v23[k] then
			return false
		end
	end

	return true
end

local function GetDatabasePageName(p: string) -- 4 equivalent calls inferred from this helper
	return v5[p] or p
end

local function BuildSettingPath(p: string, p2: string, p3: string) -- 2 equivalent calls inferred from this helper
	return `Settings.{GetDatabasePageName(p)}.{p2}.{p3}` -- inferred equivalent call
end

local function RegisterSettingMetadata(childName: string, category: string, name: string) -- 1 equivalent call inferred from this helper
	local settingPath = BuildSettingPath(childName, category, name) -- inferred equivalent call
	v10[name] = {
		pageName = childName,
		categoryName = category,
		settingName = name,
		settingPath = settingPath
	}
end

local function CaptureSelectedControl(scroll)
	local selectedObject2 = GuiService.SelectedObject

	if not (selectedObject2 and selectedObject2:IsDescendantOf(scroll)) then
		return nil
	end

	local path = {}

	while selectedObject2 and selectedObject2.Parent ~= scroll do
		table.insert(path, 1, selectedObject2.Name)
		selectedObject2 = selectedObject2.Parent
	end

	if selectedObject2 then
		return { row = selectedObject2.Name, path = path }
	end

	return nil
end

local function RestoreSelectedControl(scroll, p)
	if not p then
		return
	end

	local folder = scroll:FindFirstChild(p.row)

	if not folder then
		return
	end

	local guiObject = folder

	for _, childName in ipairs(p.path) do
		guiObject = guiObject and guiObject:FindFirstChild(childName)
	end

	if guiObject and guiObject:IsA("GuiObject") and guiObject.Selectable and guiObject.Visible then
		GuiService.SelectedObject = guiObject
		return
	end

	for _, guiObject2 in ipairs(folder:GetDescendants()) do
		if not (guiObject2:IsA("GuiObject") and guiObject2.Selectable and guiObject2.Visible) then
			continue
		end

		GuiService.SelectedObject = guiObject2
		break
	end
end

local function ClearContainer(scroll)
	local v23 = v21

	if v11[v23] then
		v11[v23]:Cleanup()
		v11[v23] = nil
	end

	if v23 == "Keybinds" then
		table.clear(v12)
		v6 = nil
	end

	for _, guiObject in ipairs(scroll:GetChildren()) do
		if guiObject:IsA("GuiObject") and guiObject.Name ~= "Header" and guiObject.Name ~= "Title" then
			guiObject:Destroy()
		end
	end
end

local function GetSettingValue(p: string, p2: string) -- 11 equivalent calls inferred from this helper
	if not v13 then
		return nil
	end

	local databasePageName = GetDatabasePageName(p) -- inferred equivalent call
	local v23 = v13[databasePageName]

	if not v23 then
		return nil
	end

	local function searchInTable(items)
		for k, item in pairs(items) do
			if k == p2 then
				return item
			end

			if type(item) ~= "table" then
				continue
			end

			local v24 = searchInTable(item)

			if v24 ~= nil then
				return v24
			end
		end

		return nil
	end

	return (searchInTable(v23))
end

local function CreateCategoryHeader(category: string, scroll, layoutOrder: number)
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = `Category_{category}`
	textLabel.Text = string.upper(category)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 14
	textLabel.TextColor3 = color2
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextYAlignment = Enum.TextYAlignment.Bottom
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.new(1, 0, 0, 35)
	textLabel.LayoutOrder = layoutOrder
	textLabel.Parent = scroll
	return textLabel
end

local function CreateDivider(scroll, layoutOrder: number) -- 1 equivalent call inferred from this helper
	local clone = settings:WaitForChild("Divider"):Clone()
	clone.LayoutOrder = layoutOrder
	clone.Parent = scroll
	return clone
end

local function UpdateCanvasSize(scroll) -- 1 equivalent call inferred from this helper
	local uiListLayout = scroll:FindFirstChildOfClass("UIListLayout")

	if uiListLayout then
		scroll.CanvasSize = UDim2.new(0, 0, 0, uiListLayout.AbsoluteContentSize.Y + 50)
	end
end

local function CheckKeybindConflict(p: string, p2: string, p3: string)
	if p == "" or p == "None" then
		return nil
	end

	local v23 = v12[`{p3}:{p}`]

	if v23 and v23 ~= p2 then
		return v23
	end

	return nil
end

local function RegisterKeybind(p: string, p2: string, p3: string)
	if p == "" or p == "None" then
		return
	end

	local formatted = `{p3}:{p}`
	v12[formatted] = p2
end

local function UnregisterKeybind(p: string, p2: string)
	if p == "" or p == "None" then
		return
	end

	local formatted = `{p2}:{p}`
	v12[formatted] = nil
end

local function GetKeybindPlatformFrame(instance, childName: string)
	local right = instance:FindFirstChild("Right")

	if not (right and right:IsA("Frame")) then
		return nil
	end

	local guiObject = right:FindFirstChild(childName)

	if guiObject and guiObject:IsA("GuiObject") then
		return guiObject
	end

	return nil
end

local function GetKeybindTextBox(guiObject) -- 2 equivalent calls inferred from this helper
	return BindDisplay.GetTextBox(guiObject)
end

local function GetKeybindPlatformFromTextBox(p)
	local parent = p.Parent

	while parent do
		local parent2 = parent.Parent

		if parent2 and parent2.Name == "Right" and parent:IsA("GuiObject") then
			return parent
		else
			parent = parent2
		end
	end

	return nil
end

local function GetKeybindSettingTemplate(p)
	local parent = p.Parent

	if not parent or parent.Name ~= "Right" then
		return nil
	end

	local parent2 = parent.Parent

	if not (parent2 and parent2:IsA("GuiObject")) then
		return nil
	end

	local keybinds = v9.Keybinds

	if keybinds and keybinds[parent2.Name] == parent2 then
		return parent2
	end

	return nil
end

local function GetRenderedKeybindBox(p: string, childName: string)
	if not (v9.Keybinds and v9.Keybinds[p]) then
		return nil, nil
	end

	local right = v9.Keybinds[p]:FindFirstChild("Right")
	local guiObject

	if right and right:IsA("Frame") then
		guiObject = right:FindFirstChild(childName)

		if not (guiObject and guiObject:IsA("GuiObject")) then
			guiObject = nil
		end
	end

	if guiObject then
		return guiObject, GetKeybindTextBox(guiObject)
	end

	return nil, nil
end

local function RememberKeybindTextColor(instance) -- 3 equivalent calls inferred from this helper
	if instance:GetAttribute("DefaultTextColor") == nil then
		instance:SetAttribute("DefaultTextColor", instance.TextColor3)
	end
end

local function GetKeybindTextColor(instance) -- 3 equivalent calls inferred from this helper
	local defaultTextColor = instance:GetAttribute("DefaultTextColor")

	if typeof(defaultTextColor) == "Color3" then
		return defaultTextColor
	end

	return instance.TextColor3
end

local function HighlightReplacedKeybind(p: string, childName: string) -- 3 equivalent calls inferred from this helper
	local guiObject, v23

	if v9.Keybinds and v9.Keybinds[p] then
		local right = v9.Keybinds[p]:FindFirstChild("Right")

		if right and right:IsA("Frame") then
			guiObject = right:FindFirstChild(childName)

			if not (guiObject and guiObject:IsA("GuiObject")) then
				guiObject = nil
			end
		end

		if guiObject then
			v23 = GetKeybindTextBox(guiObject) -- inferred equivalent call
		else
			guiObject = nil
		end
	end

	if not v23 then
		return
	end

	RememberKeybindTextColor(v23) -- inferred equivalent call
	v23.TextColor3 = Color3.fromRGB(255, 90, 90)
	BindDisplay.SetConflict(guiObject, true)
end

local function ClearKeybindHighlight(name: string, name2: string)
	local guiObject, v23

	if v9.Keybinds and v9.Keybinds[name] then
		local right = v9.Keybinds[name]:FindFirstChild("Right")

		if right and right:IsA("Frame") then
			guiObject = right:FindFirstChild(name2)

			if not (guiObject and guiObject:IsA("GuiObject")) then
				guiObject = nil
			end
		end

		if guiObject then
			v23 = GetKeybindTextBox(guiObject) -- inferred equivalent call
		else
			guiObject = nil
		end
	end

	if not v23 then
		return
	end

	RememberKeybindTextColor(v23) -- inferred equivalent call
	TweenService:Create(v23, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextColor3 = GetKeybindTextColor(v23) -- inferred equivalent call
	}):Play()
	BindDisplay.SetConflict(guiObject, false)
end

local function ScrollToTemplate(p: string)
	if not (v9.Keybinds and v9.Keybinds[p]) then
		return
	end

	local keybind = v9.Keybinds[p]
	local parent = keybind.Parent

	if not (parent and parent:IsA("ScrollingFrame")) then
		return
	end

	local y = keybind.AbsolutePosition.Y
	local y2 = parent.AbsolutePosition.Y
	local y3 = parent.AbsoluteSize.Y
	local v23 = y - y2 + parent.CanvasPosition.Y
	local y4 = keybind.AbsoluteSize.Y
	local v24 = math.min(math.max(0, v23 - y3 / 2 + y4 / 2), parent.CanvasSize.Y.Offset - y3)
	TweenService:Create(parent, TweenInfo.new(0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		CanvasPosition = Vector2.new(0, v24)
	}):Play()
end

local function SwapKeybinds(name: string, p: string, p2: string, name2: string, value: string?)
	if value == p2 then
		value = nil
	end

	local settingValue = GetSettingValue("Keybinds", p) -- inferred equivalent call
	local v23 = type(settingValue) ~= "table" and {} or table.clone(settingValue)
	v23[name2] = value or ""
	Settings.SettingChanged("Keybinds", p, v23)

	if value and value ~= "" and value ~= "" and value ~= "None" then
		local formatted = `{name2}:{value}`
		v12[formatted] = p
	end

	if v9.Keybinds and v9.Keybinds[p] then
		local right = v9.Keybinds[p]:FindFirstChild("Right")
		local guiObject

		if right and right:IsA("Frame") then
			guiObject = right:FindFirstChild(name2)

			if not (guiObject and guiObject:IsA("GuiObject")) then
				guiObject = nil
			end
		end

		if guiObject then
			BindDisplay.Apply(guiObject, value or "")
		end
	end

	HighlightReplacedKeybind(name, name2) -- inferred equivalent call
	HighlightReplacedKeybind(p, name2) -- inferred equivalent call
	ScrollToTemplate(p)
end

local function IsAnyGamepadButtonDown(p)
	for _, v23 in UserInputService:GetConnectedGamepads() do
		if UserInputService:IsGamepadButtonDown(v23, p) then
			return true
		end
	end

	return false
end

local function RestoreListeningSelection(value: string?)
	local selectedObject2 = selectedObject
	selectedObject = nil

	if not selectedObject2 then
		return
	end

	local v23 = value and string.match(value, "^Enum%.KeyCode%.(.+)$")
	local success, result = pcall(function()
		return Enum.KeyCode[v23]
	end)

	if not (v23 and success) then
		result = nil
	end

	task.spawn(function()
		local v24 = os.clock() + 1

		while result and os.clock() < v24 and IsAnyGamepadButtonDown(result) do
			task.wait()
		end

		if selectedObject2.Parent and GuiService.SelectedObject == nil then
			GuiService.SelectedObject = selectedObject2
		end
	end)
end

local function ReenableScrolling() -- 5 equivalent calls inferred from this helper
	if v21 ~= "Keybinds" then
		return
	end

	local keybinds = v17.Frame.List:FindFirstChild("Keybinds")
	local scroll = keybinds and keybinds.Bottom.Scroll

	if scroll then
		scroll.ScrollingEnabled = true
	end
end

local function HandleKeybindCapture(instance, p: string)
	if not v19 then
		return
	end

	local parent = instance.Parent
	local parent2

	if parent and parent.Name == "Right" then
		parent2 = parent.Parent

		if parent2 and parent2:IsA("GuiObject") then
			local keybinds = v9.Keybinds

			if not keybinds or keybinds[parent2.Name] ~= parent2 then
				parent2 = nil
			end
		else
			parent2 = nil
		end
	end

	if parent2 then
		local name = parent2.Name
		local name2 = instance.Name
		local v23

		if not (p == "" or p == "None") then
			v23 = v12[`{name2}:{p}`]

			if not v23 or v23 == name then
				v23 = nil
			end
		end

		local v24 = v23 ~= nil
		local v25 = GetSettingValue(v21, name) or {} -- inferred equivalent call
		local v26 = {
			Computer = type(v25) ~= "table" and "" or v25.Computer,
			Console = type(v25) ~= "table" and "" or v25.Console
		}
		local v27 = v26[name2]

		if v27 and v27 ~= "" and v27 ~= "" and v27 ~= "None" then
			local formatted = `{name2}:{v27}`
			v12[formatted] = nil
		end

		v26[name2] = p

		if p ~= "" and p ~= "None" then
			local formatted = `{name2}:{p}`
			v12[formatted] = name
		end

		BindDisplay.Apply(instance, p)
		BindDisplay.SetConflict(instance, v24)

		if v24 then
			v19.TextColor3 = Color3.fromRGB(255, 90, 90)
		else
			v19.TextColor3 = GetKeybindTextColor(v19) -- inferred equivalent call
			ClearKeybindHighlight(name, name2)
		end

		if v24 then
			count += 1
			batch = count
			v8 = name2
		end

		Settings.SettingChanged(v21, name, v26, false, v24)

		if v24 and v23 then
			SwapKeybinds(name, v23, p, name2, v27)
		end

		batch = nil
		v8 = nil
		local v28 = v19
		v16 = nil
		v19 = nil
		v28:ReleaseFocus()
		ReenableScrolling() -- inferred equivalent call
		RestoreListeningSelection(p)
	else
		local v23 = v19
		v16 = nil
		v19 = nil
		v23:ReleaseFocus()
		ReenableScrolling() -- inferred equivalent call
		RestoreListeningSelection(p)
	end
end

local function CancelKeybindListening()
	if not v19 then
		return
	end

	local v23 = v19
	local keybindPlatformFromTextBox = GetKeybindPlatformFromTextBox(v23)

	if keybindPlatformFromTextBox then
		BindDisplay.Apply(keybindPlatformFromTextBox, v16 or "")
	else
		v23.Text = ""
	end

	v23.TextColor3 = GetKeybindTextColor(v23) -- inferred equivalent call
	v16 = nil
	v19 = nil
	v23:ReleaseFocus()
	ReenableScrolling() -- inferred equivalent call
	RestoreListeningSelection()
end

local function AddToHistory(settingPath: string, oldValue, newValue)
	table.insert(v7, { path = settingPath, oldValue = oldValue, newValue = newValue, batch = batch })

	while #v7 > 50 do
		table.remove(v7, 1)
	end
end

function Settings.RenderPage(childName: string)
	Profiler.mark("UI.Settings.RenderPage")

	if not Pages.GetPage(childName) then
		warn(`[Settings] Page '{childName}' not found in configuration`)
		return
	end

	local child = v17.Frame.List:FindFirstChild(childName)

	if not child then
		warn(`[Settings] Page frame '{childName}' not found in UI`)
		return
	end

	local scroll = child.Bottom.Scroll
	local captureSelectedControl = CaptureSelectedControl(scroll)
	ClearContainer(scroll)
	local header = child.Header.Heading.Header

	if header then
		header.Text = string.upper(childName) .. " SETTINGS"
	end

	local title = child.Header.Title

	if title then
		title.Text = Pages.Descriptions[childName] or ""
	end

	local categories = Pages.GetCategories(childName)
	local v23 = v3[childName]

	if v23 then
		table.sort(categories, function(a, b)
			return (table.find(v23, a) or 999) < (table.find(v23, b) or 999)
		end)
	end

	v9[childName] = {}

	if not v11[childName] then
		v11[childName] = Janitor.new()
	end

	local count2 = 0

	for _, category in ipairs(categories) do
		CreateCategoryHeader(category, scroll, count2)
		count2 += 1
		local category2 = Pages.GetCategory(childName, category)
		local v24 = {}

		for k, config in pairs(category2) do
			if not k:match("^_Divider_") then
				table.insert(v24, { name = k, config = config })
			end
		end

		table.sort(v24, function(a, b)
			local order = a.config.Order or 999
			local order2 = b.config.Order or 999

			if order == order2 then
				return a.name < b.name
			end

			return order < order2
		end)
		local clone

		if childName == "Game" and category == "Crosshair" then
			if child:FindFirstChild("ChangeColor") then
				child.ChangeColor:Destroy()
			end

			if child.Bottom.Scroll:FindFirstChild("ColorPickerTemplate") then
				child.Bottom.Scroll.ColorPickerTemplate:Destroy()
			end

			local function clampChannel(p: number) -- 7 equivalent calls inferred from this helper
				return (math.clamp(math.round(p), 0, 255))
			end

			local v25 = { Red = 0, Green = 0, Blue = 0 }
			local v26

			if v13 then
				local v27 = v5[childName] or childName
				local v28 = v13[v27]

				if v28 then
					local v29 = "Red"
					local function searchInTable(items)
						for k, item in pairs(items) do
							if k == v29 then
								return item
							end

							if type(item) ~= "table" then
								continue
							end

							local v30 = searchInTable(item)

							if v30 ~= nil then
								return v30
							end
						end

						return nil
					end

					v26 = searchInTable(v28)
				end
			end

			v25.Red = clampChannel(tonumber(v26) or 0) -- inferred equivalent call
			local v27

			if v13 then
				local v28 = v5[childName] or childName
				local v29 = v13[v28]

				if v29 then
					local v30 = "Green"
					local function searchInTable(items)
						for k, item in pairs(items) do
							if k == v30 then
								return item
							end

							if type(item) ~= "table" then
								continue
							end

							local v31 = searchInTable(item)

							if v31 ~= nil then
								return v31
							end
						end

						return nil
					end

					v27 = searchInTable(v29)
				end
			end

			v25.Green = clampChannel(tonumber(v27) or 255) -- inferred equivalent call
			local v28

			if v13 then
				local v29 = v5[childName] or childName
				local v30 = v13[v29]

				if v30 then
					local v31 = "Blue"
					local function searchInTable(items)
						for k, item in pairs(items) do
							if k == v31 then
								return item
							end

							if type(item) ~= "table" then
								continue
							end

							local v32 = searchInTable(item)

							if v32 ~= nil then
								return v32
							end
						end

						return nil
					end

					v28 = searchInTable(v30)
				end
			end

			v25.Blue = clampChannel(tonumber(v28) or 0) -- inferred equivalent call

			local function saveColors() -- 2 equivalent calls inferred from this helper
				Settings.SettingChanged(childName, "Red", v25.Red)
				Settings.SettingChanged(childName, "Green", v25.Green)
				Settings.SettingChanged(childName, "Blue", v25.Blue)
			end

			local function setColorsFromColor3(color4: Color3) -- 2 equivalent calls inferred from this helper
				v25.Red = clampChannel(color4.R * 255) -- inferred equivalent call
				v25.Green = clampChannel(color4.G * 255) -- inferred equivalent call
				v25.Blue = clampChannel(color4.B * 255) -- inferred equivalent call
			end

			local clone2 = v22.ChangeColor:Clone()
			clone2.Parent = child
			clone = v22.ColorPickerTemplate:Clone()
			clone.Parent = child.Bottom.Scroll
			local label = clone:FindFirstChild("Label", true)

			if label and label:IsA("TextLabel") then
				label.Text = "Crosshair Color"
			end

			local updateColorPicker = clone2:FindFirstChild("UpdateColorPicker", true)
			local colorPicker = clone2:FindFirstChild("ColorPicker", true)
			local hue = clone2:FindFirstChild("Hue", true)
			local v29 = nil
			local v30 = nil

			if colorPicker then
				local pick = colorPicker:FindFirstChild("Pick", true)

				if pick and pick:IsA("GuiObject") then
					v29 = pick
				end
			end

			if hue then
				local arrow = hue:FindFirstChild("Arrow", true)

				if arrow and arrow:IsA("GuiObject") then
					v30 = arrow
				end
			end

			local function color3ToHex(color4: Color3) -- 1 equivalent call inferred from this helper
				return string.format(
					"#%02X%02X%02X",
					math.round(color4.R * 255),
					math.round(color4.G * 255),
					(math.round(color4.B * 255))
				)
			end

			local hsv, v31, v32 = Color3.toHSV(Color3.fromRGB(v25.Red, v25.Green, v25.Blue))

			local function setColorsFromHSV() -- 4 equivalent calls inferred from this helper
				setColorsFromColor3(Color3.fromHSV( -- inferred equivalent call
					math.clamp(hsv, 0, 1),
					math.clamp(v31, 0, 1),
					(math.clamp(v32, 0, 1))
				))
			end

			local function syncHSVFromRGB() -- 2 equivalent calls inferred from this helper
				local hsv2, v35, v36 = Color3.toHSV(Color3.fromRGB(v25.Red, v25.Green, v25.Blue))

				if v35 > 0 then
					hsv = hsv2
				end

				v31 = v35
				v32 = v36
			end

			local function signalUpdateColorPicker() -- 1 equivalent call inferred from this helper
				if updateColorPicker and updateColorPicker:IsA("BindableEvent") then
					updateColorPicker:Fire(v25.Red, v25.Green, v25.Blue)
				end
			end

			local function setIndicatorFromAbsolutePoint(instance, guiObject, point: Vector2, flag: boolean, flag2: boolean)
				local parent = instance.Parent

				if not (parent and parent:IsA("GuiObject")) then
					return
				end

				local absolutePosition = guiObject.AbsolutePosition
				local absoluteSize = guiObject.AbsoluteSize
				local absoluteSize2 = instance.AbsoluteSize
				local absolutePosition2 = parent.AbsolutePosition

				if absoluteSize.X <= 0 or absoluteSize.Y <= 0 or absoluteSize2.X <= 0 or absoluteSize2.Y <= 0 then
					return
				end

				local v35 = absoluteSize2.X * 0.5
				local v36 = absoluteSize2.Y * 0.5
				local v37 = math.clamp(point.X, absolutePosition.X, absolutePosition.X + absoluteSize.X)
				local v38 = math.clamp(point.Y, absolutePosition.Y, absolutePosition.Y + absoluteSize.Y)
				local offset = v37 - v35 - absolutePosition2.X
				local offset2 = v38 - v36 - absolutePosition2.Y
				local v39 = flag and 0 or instance.Position.X.Scale

				if not flag then
					offset = instance.Position.X.Offset
				end

				local v40 = flag2 and 0 or instance.Position.Y.Scale

				if not flag2 then
					offset2 = instance.Position.Y.Offset
				end

				instance.Position = UDim2.new(v39, offset, v40, offset2)
			end

			local guiObject = colorPicker
			local guiObject2 = hue

			local function updateColorPicker2()
				local color4 = Color3.fromRGB(v25.Red, v25.Green, v25.Blue)
				clone2.Hue.BackgroundColor3 = Color3.fromHSV(hsv, math.max(v31, 0.01), 1)
				clone.ColorPreview.BackgroundColor3 = color4
				clone2.Preview.BackgroundColor3 = color4
				clone2.Hex.Container.Left.Title.Text = color3ToHex(color4) -- inferred equivalent call

				for _, child2 in clone.Right:GetChildren() do
					if v25[child2.Name] ~= nil then
						child2.Container.Left.Title.Text = tostring(v25[child2.Name])
					end
				end

				for _, frame in clone2.RGB:GetChildren() do
					if frame:IsA("Frame") then
						frame.Container.Left.Title.Text = tostring(v25[frame.Name])
					end
				end

				if guiObject and guiObject:IsA("GuiObject") and v29 then
					local absoluteSize = guiObject.AbsoluteSize

					if absoluteSize.X > 0 and absoluteSize.Y > 0 then
						local v35 = math.clamp(hsv, 0, 1) * absoluteSize.X
						local v36 = (1 - math.clamp(v31, 0, 1)) * absoluteSize.Y
						setIndicatorFromAbsolutePoint(
							v29,
							guiObject,
							guiObject.AbsolutePosition + Vector2.new(v35, v36),
							true,
							true
						)
					end
				end

				if guiObject2 and guiObject2:IsA("GuiObject") and v30 then
					local absoluteSize = guiObject2.AbsoluteSize

					if absoluteSize.Y > 0 then
						local v35 = (1 - math.clamp(v32, 0, 1)) * absoluteSize.Y
						setIndicatorFromAbsolutePoint(
							v30,
							guiObject2,
							guiObject2.AbsolutePosition + Vector2.new(absoluteSize.X * 0.5, v35),
							false,
							true
						)
					end
				end
			end

			local function commitColorChange() -- 7 equivalent calls inferred from this helper
				updateColorPicker2()
				signalUpdateColorPicker() -- inferred equivalent call
			end

			local function getMouseLocation() -- 3 equivalent calls inferred from this helper
				local guiInset = GuiService:GetGuiInset()
				return UserInputService:GetMouseLocation() - guiInset
			end

			local guiObject3 = colorPicker

			local function setPickerFromMouse(mouseLocation: Vector2)
				if not (guiObject3 and guiObject3:IsA("GuiObject")) then
					return
				end

				local absoluteSize = guiObject3.AbsoluteSize

				if absoluteSize.X <= 0 or absoluteSize.Y <= 0 then
					return
				end

				local absolutePosition = guiObject3.AbsolutePosition
				local v35 = math.clamp((mouseLocation.X - absolutePosition.X) / absoluteSize.X, 0, 1)
				local v36 = math.clamp((mouseLocation.Y - absolutePosition.Y) / absoluteSize.Y, 0, 1)
				hsv = v35
				v31 = 1 - v36
				setColorsFromHSV() -- inferred equivalent call
				commitColorChange() -- inferred equivalent call
			end

			local guiObject4 = hue

			local function setHueFromMouse(mouseLocation: Vector2)
				if not (guiObject4 and guiObject4:IsA("GuiObject")) then
					return
				end

				local absoluteSize = guiObject4.AbsoluteSize

				if absoluteSize.Y <= 0 then
					return
				end

				v32 = 1 - math.clamp((mouseLocation.Y - guiObject4.AbsolutePosition.Y) / absoluteSize.Y, 0, 1)
				setColorsFromHSV() -- inferred equivalent call
				commitColorChange() -- inferred equivalent call
			end

			local flag = false
			local flag2 = false

			local function bindDragStart(guiObject5, fn)
				if guiObject5 and guiObject5:IsA("GuiObject") then
					v11[childName]:Add(guiObject5.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							fn()
						end
					end), "Disconnect")
				end
			end

			bindDragStart(colorPicker, function()
				flag = true
				setPickerFromMouse(getMouseLocation()) -- inferred equivalent call
			end)
			bindDragStart(hue, function()
				flag2 = true
				setHueFromMouse(getMouseLocation()) -- inferred equivalent call
			end)
			v11[childName]:Add(UserInputService.InputChanged:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then
					return
				end

				local mouseLocation = getMouseLocation() -- inferred equivalent call

				if flag then
					setPickerFromMouse(mouseLocation)
				elseif flag2 then
					setHueFromMouse(mouseLocation)
				end
			end), "Disconnect")
			v11[childName]:Add(UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					flag = false
					flag2 = false
				end
			end), "Disconnect")
			updateColorPicker2()

			local function bindChannelInput(p, flag3: boolean) -- 2 equivalent calls inferred from this helper
				p.Container.Left.Title.FocusLost:Connect(function()
					local text = tonumber(p.Container.Left.Title.Text) or v25[p.Name]
					v25[p.Name] = clampChannel(text) -- inferred equivalent call

					if flag3 then
						saveColors() -- inferred equivalent call
					end

					syncHSVFromRGB() -- inferred equivalent call
					commitColorChange() -- inferred equivalent call
				end)
			end

			local titles = { [clone2.Hex] = clone2.Hex.Container.Left.Title }

			for _, button in clone.Right:GetChildren() do
				if v25[button.Name] == nil then
					continue
				end

				bindChannelInput(button, true) -- inferred equivalent call
				local title2 = button.Container.Left.Title
				title2.Selectable = false

				if button:IsA("GuiButton") then
					button.Activated:Connect(function()
						title2:CaptureFocus()
					end)
				end
			end

			for _, frame in clone2.RGB:GetChildren() do
				if not frame:IsA("Frame") then
					continue
				end

				bindChannelInput(frame, false) -- inferred equivalent call
				titles[frame] = frame.Container.Left.Title
			end

			local guiButton = clone.ColorPreview:FindFirstChildWhichIsA("GuiButton") or clone.ColorPreview

			if not (colorPicker and colorPicker:IsA("GuiObject")) then
				colorPicker = nil
			end

			if not (hue and hue:IsA("GuiObject")) then
				hue = nil
			end

			local red = clone2.RGB:FindFirstChild("Red")
			local green = clone2.RGB:FindFirstChild("Green")
			local blue = clone2.RGB:FindFirstChild("Blue")
			local now = 0

			if colorPicker then
				colorPicker.Selectable = true
			end

			if hue then
				hue.Selectable = true
			end

			clone2.SelectionGroup = true
			clone2.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
			clone2.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
			clone2.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
			clone2.SelectionBehaviorRight = Enum.SelectionBehavior.Stop

			local function getGamepadDirection()
				local zero = Vector2.zero

				for _, v35 in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
					if v35.KeyCode ~= Enum.KeyCode.Thumbstick1 then
						continue
					end

					local vector = Vector2.new(v35.Position.X, -v35.Position.Y)

					if vector.Magnitude >= 0.2 then
						zero += vector
					end
				end

				if IsAnyGamepadButtonDown(Enum.KeyCode.DPadLeft) then
					zero -= Vector2.xAxis
				end

				if IsAnyGamepadButtonDown(Enum.KeyCode.DPadRight) then
					zero += Vector2.xAxis
				end

				if IsAnyGamepadButtonDown(Enum.KeyCode.DPadUp) then
					zero -= Vector2.yAxis
				end

				if IsAnyGamepadButtonDown(Enum.KeyCode.DPadDown) then
					zero += Vector2.yAxis
				end

				if zero.Magnitude > 1 then
					return zero.Unit
				end

				return zero
			end

			local function setNextSelection(state, nextSelectionUp, nextSelectionDown, nextSelectionLeft, nextSelectionRight) -- 8 equivalent calls inferred from this helper
				if not state then
					return
				end

				if state.NextSelectionUp ~= nextSelectionUp then
					state.NextSelectionUp = nextSelectionUp
				end

				if state.NextSelectionDown ~= nextSelectionDown then
					state.NextSelectionDown = nextSelectionDown
				end

				if state.NextSelectionLeft ~= nextSelectionLeft then
					state.NextSelectionLeft = nextSelectionLeft
				end

				if state.NextSelectionRight ~= nextSelectionRight then
					state.NextSelectionRight = nextSelectionRight
				end
			end

			local hex = clone2.Hex
			local apply = clone2.Buttons.Buttons.Apply
			local close = clone2.Buttons.Buttons.Close
			setNextSelection(red, colorPicker, hex, red, green) -- inferred equivalent call
			setNextSelection(green, colorPicker, hex, red, blue) -- inferred equivalent call
			setNextSelection(blue, hue or colorPicker, hex, green, blue) -- inferred equivalent call
			setNextSelection(hex, green, apply, hex, hex) -- inferred equivalent call
			setNextSelection(apply, hex, apply, apply, close) -- inferred equivalent call
			setNextSelection(close, hex, close, apply, close) -- inferred equivalent call

			local function movePicker(point: Vector2) -- 1 equivalent call inferred from this helper
				hsv = math.clamp(hsv + point.X, 0, 1)
				v31 = math.clamp(v31 - point.Y, 0, 1)
				setColorsFromHSV() -- inferred equivalent call
				commitColorChange() -- inferred equivalent call
			end

			local function moveBrightness(point: Vector2) -- 1 equivalent call inferred from this helper
				v32 = math.clamp(v32 - point.Y, 0, 1)
				setColorsFromHSV() -- inferred equivalent call
				commitColorChange() -- inferred equivalent call
			end

			v11[childName]:Add(RunService.Heartbeat:Connect(function(dt: number)
				local selectedObject2 = GuiService.SelectedObject

				if not (clone2.Visible and selectedObject2) then
					return
				end

				local v37 = getGamepadDirection() * (dt / 2)

				if selectedObject2 == colorPicker then
					if v37 ~= Vector2.zero then
						movePicker(v37) -- inferred equivalent call
					end

					local v38

					if v31 > 0 then
						v38 = selectedObject2
					else
						v38 = red
					end

					local v39

					if hsv < 1 then
						v39 = selectedObject2
					else
						v39 = hue
					end

					setNextSelection(selectedObject2, selectedObject2, v38, selectedObject2, v39) -- inferred equivalent call
				elseif selectedObject2 == hue then
					if v37.Y ~= 0 then
						moveBrightness(v37) -- inferred equivalent call
					end

					local v38

					if v32 > 0 then
						v38 = selectedObject2
					else
						v38 = blue
					end

					setNextSelection(selectedObject2, selectedObject2, v38, colorPicker, selectedObject2) -- inferred equivalent call
				end
			end), "Disconnect")

			local function hideColorPopup() -- 2 equivalent calls inferred from this helper
				local focusedTextBox = UserInputService:GetFocusedTextBox()

				if focusedTextBox and focusedTextBox:IsDescendantOf(clone2) then
					focusedTextBox:ReleaseFocus()
				end

				clone2.Visible = false
			end

			local function closeColorPopup()
				local selectedObject2 = GuiService.SelectedObject
				local v37

				if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
					v37 = selectedObject2 == nil or selectedObject2:IsDescendantOf(clone2)
				else
					v37 = false
				end

				hideColorPopup() -- inferred equivalent call

				if v37 and guiButton:IsA("GuiButton") and guiButton:IsDescendantOf(game) then
					GuiService.SelectedObject = guiButton
				end
			end

			CloseButtonRegistry.Add(clone2, nil, closeColorPopup)
			v11[childName]:Add(function()
				CloseButtonRegistry.Remove(clone2)
			end, true)
			local parent = clone2.Parent

			while parent and parent:IsA("GuiObject") do
				local v37 = parent
				v11[childName]:Add(parent:GetPropertyChangedSignal("Visible"):Connect(function()
					if clone2.Visible and not v37.Visible then
						hideColorPopup() -- inferred equivalent call
					end
				end), "Disconnect")
				parent = parent.Parent
			end

			local v37 = { colorPicker, hue, red, green, blue, hex, apply }
			local v38 = nil
			local v39 = {}

			for i = 1, #v37 do
				local v40 = v37[i]

				if not v40 then
					continue
				end

				if v38 then
					v39[v38] = v40
				end

				v38 = v40
			end

			local v40 = nil
			v11[childName]:Add(UserInputService.InputBegan:Connect(function(input)
				if not clone2.Visible or UserInputService:GetFocusedTextBox() then
					return
				end

				local selectedObject2 = GuiService.SelectedObject

				if input.KeyCode == Enum.KeyCode.ButtonA then
					if not (os.clock() - now >= 0.1) then
						selectedObject2 = nil
					end

					v40 = selectedObject2
				elseif input.KeyCode == Enum.KeyCode.ButtonY and selectedObject2 and titles[selectedObject2] then
					titles[selectedObject2]:CaptureFocus()
				end
			end), "Disconnect")
			v11[childName]:Add(UserInputService.InputEnded:Connect(function(input)
				if input.KeyCode ~= Enum.KeyCode.ButtonA then
					return
				end

				local v41 = v40
				v40 = nil
				local selectedObject2 = v41 and v39[v41]

				if not selectedObject2 then
					return
				end

				task.defer(function()
					if clone2.Visible and GuiService.SelectedObject == v41 then
						GuiService.SelectedObject = selectedObject2
					end
				end)
			end), "Disconnect")

			if guiButton:IsA("GuiButton") then
				ActivateButton(guiButton)
				local selectedObject2 = colorPicker
				guiButton.MouseButton1Click:Connect(function()
					local v42 = GuiService.SelectedObject ~= nil
					child.ChangeColor.Visible = true
					updateColorPicker2()

					if v42 and selectedObject2 then
						now = os.clock()
						GuiService.SelectedObject = selectedObject2
					end
				end)
			end

			ActivateButton(child.ChangeColor.Buttons.Buttons.Close)
			child.ChangeColor.Buttons.Buttons.Close.MouseButton1Click:Connect(closeColorPopup)
			clone2.Hex.Container.Left.Title.FocusLost:Connect(function()
				local success, result = pcall(Color3.fromHex, clone2.Hex.Container.Left.Title.Text)

				if success and result then
					setColorsFromColor3(result) -- inferred equivalent call
					syncHSVFromRGB() -- inferred equivalent call
					commitColorChange() -- inferred equivalent call
				end
			end)
			ActivateButton(child.ChangeColor.Buttons.Buttons.Apply)
			child.ChangeColor.Buttons.Buttons.Apply.MouseButton1Click:Connect(function()
				closeColorPopup()
				commitColorChange() -- inferred equivalent call
				saveColors() -- inferred equivalent call
			end)
		else
			clone = nil
		end

		for _, v25 in ipairs(v24) do
			if v25.name == "Red" or v25.name == "Green" or v25.name == "Blue" then
				clone.LayoutOrder = count2
			else
				local config = v25.config
				local name = v25.name
				local clone2 = nil
				local v26 = nil

				if config.Platform then
					local userPlatform = GetUserPlatform()

					if table.find(userPlatform, config.Platform) == nil then
						continue
					end
				end

				RegisterSettingMetadata(childName, category, name) -- inferred equivalent call

				if config.Type == "CrosshairPreview" then
					if v22.CrosshairPreviewTemplate then
						clone2 = v22.CrosshairPreviewTemplate:Clone()
						v26 = CrosshairPreview(scroll, count2, clone2, v17.Share, function()
							return v13 and v13.Game and v13.Game.Crosshair
						end, NOOP, NOOP, NOOP)
					else
						warn("[Settings] CrosshairPreviewTemplate not loaded")
						continue
					end
				elseif config.Type == "Toggle" then
					assert(v22.ToggleTemplate, "ToggleTemplate not loaded")
					clone2 = v22.ToggleTemplate:Clone()
					local default = GetSettingValue(v21, name) -- inferred equivalent call

					if default == nil then
						default = config.Default
					end

					v26 = Toggle(name, config, scroll, count2, clone2, default, Settings.SettingChanged, v21)
				elseif config.Type == "Number" then
					assert(v22.NumberTemplate, "NumberTemplate not loaded")
					clone2 = v22.NumberTemplate:Clone()
					v26 = Number(
						name,
						config,
						scroll,
						count2,
						clone2,
						tonumber(GetSettingValue(v21, name) or config.Default) or config.Default, -- inferred equivalent call
						Settings.SettingChanged,
						v21
					)
				elseif config.Type == "Slider" then
					assert(v22.SliderTemplate, "SliderTemplate not loaded")
					clone2 = v22.SliderTemplate:Clone()
					local enabled = nil
					local value

					if config.HasEnabledToggle then
						local settingValue = GetSettingValue(v21, name) -- inferred equivalent call

						if type(settingValue) == "table" then
							value = tonumber(settingValue.Value) or config.Default
							enabled = settingValue.Enabled

							if enabled == nil then
								if config.DefaultEnabled == nil then
									enabled = true
								else
									enabled = config.DefaultEnabled
								end
							end
						else
							value = tonumber(settingValue) or config.Default

							if config.DefaultEnabled == nil then
								enabled = true
							else
								enabled = config.DefaultEnabled
							end
						end
					else
						value = tonumber(GetSettingValue(v21, name) or config.Default) or config.Default -- inferred equivalent call
					end

					v26 = Slider(name, config, scroll, count2, clone2, value, enabled, Settings.SettingChanged, v21)
				elseif config.Type == "Dropdown" then
					assert(v22.DropdownTemplate, "DropdownTemplate not loaded")
					clone2 = v22.DropdownTemplate:Clone()
					v26 = Dropdown(
						name,
						config,
						scroll,
						count2,
						clone2,
						GetSettingValue(v21, name) or config.Default, -- inferred equivalent call
						Settings.SettingChanged,
						v21,
						settings,
						function()
							return v18
						end,
						function(p)
							v18 = p
						end
					)
				elseif config.Type == "Keybind" then
					assert(v22.KeybindTemplate, "KeybindTemplate not loaded")
					clone2 = v22.KeybindTemplate:Clone()
					local v27 = GetSettingValue(v21, name) or {} -- inferred equivalent call

					if type(v27) == "table" then
						for _, v28 in ipairs({ "Computer", "Console" }) do
							local keybind = v27[v28]

							if not (keybind and keybind ~= "") then
								continue
							end

							local action

							if not (keybind == "" or keybind == "None") then
								action = v12[`{v28}:{keybind}`]

								if not action or action == name then
									action = nil
								end
							end

							if action then
								local v29 = v6 or {}
								v6 = v29
								v29[v28] = v29[v28] or {}
								table.insert(v29[v28], { action = name, keybind = keybind })
								table.insert(v29[v28], { action = action, keybind = keybind })
							end

							if not (keybind ~= "" and keybind ~= "None") then
								continue
							end

							local formatted = `{v28}:{keybind}`
							v12[formatted] = name
						end
					end

					local v28 = clone2

					local function saveResetKeybinds(p: string, p2: string, p3)
						local settingValue = GetSettingValue(p, p2) -- inferred equivalent call
						local v29 = {}

						for _, childName2 in ipairs({ "Computer", "Console" }) do
							local right = v28:FindFirstChild("Right")
							local guiObject

							if right and right:IsA("Frame") then
								guiObject = right:FindFirstChild(childName2)

								if not (guiObject and guiObject:IsA("GuiObject")) then
									guiObject = nil
								end
							end

							local v30

							if guiObject then
								v30 = BindDisplay.GetReset(guiObject)
							end

							local v31

							if type(settingValue) == "table" then
								v31 = settingValue[childName2]
							end

							if p3[childName2] == "" and v30 and not v30.Visible then
								v29[childName2] = ""
							elseif v31 == nil then
								v29[childName2] = p3[childName2]
							else
								v29[childName2] = v31
							end
						end

						Settings.SettingChanged(p, p2, v29)
					end

					v26 = Keybind(
						name,
						config,
						scroll,
						count2,
						clone2,
						v27,
						saveResetKeybinds,
						v21,
						function(object, p: string, p2: number)
							local keybindPlatformFromTextBox = GetKeybindPlatformFromTextBox(object)
							local settingValue = GetSettingValue(v21, name) -- inferred equivalent call
							local v29

							if keybindPlatformFromTextBox and type(settingValue) == "table" then
								v29 = settingValue[keybindPlatformFromTextBox.Name]
							end

							v19 = object

							if type(v29) == "string" then
								p = v29
							end

							v16 = p
							v20 = p2
							object.Text = "Press a key..."
							RememberKeybindTextColor(object) -- inferred equivalent call
							object.TextColor3 = color2

							if keybindPlatformFromTextBox then
								BindDisplay.HideIcon(keybindPlatformFromTextBox)
							end

							scroll.ScrollingEnabled = false

							if not string.match(UserInputService:GetLastInputType().Name, "^Gamepad%d+$") then
								object.FocusLost:Once(function()
									task.defer(function()
										if v19 == object then
											CancelKeybindListening()
										end
									end)
								end)
								return
							end

							selectedObject = GuiService.SelectedObject
							GuiService.SelectedObject = nil
							object:ReleaseFocus()
						end,
						NOOP
					)
				end

				if clone2 then
					v9[childName][name] = clone2
					count2 += 1
				end

				if v26 then
					v11[childName]:Add(v26, true, `Template_{name}`)
				end

				CreateDivider(scroll, count2) -- inferred equivalent call
			end

			count2 += 1
		end
	end

	UpdateCanvasSize(scroll) -- inferred equivalent call
	RestoreSelectedControl(scroll, captureSelectedControl)

	if childName == "Keybinds" and v6 then
		Profiler.defer("UI.Settings.HighlightDuplicateKeybindsDeferred", function()
			local v24 = {}

			for k, list in pairs(v6) do
				for _, v25 in ipairs(list) do
					local formatted = `{v25.action}:{k}`

					if v24[formatted] then
						continue
					end

					HighlightReplacedKeybind(v25.action, k) -- inferred equivalent call
					v24[formatted] = true
				end
			end

			v6 = nil
		end)
	end
end

local function UpdateTabHighlight(button, visible: boolean)
	button:SetAttribute("Selected", visible and true or nil)
	local selected = button:FindFirstChild("Selected")

	if selected and selected:IsA("GuiObject") then
		selected.Visible = visible
		local backgroundColor

		if visible then
			backgroundColor = color2
		else
			backgroundColor = color
		end

		button.BackgroundColor3 = backgroundColor
	else
		local v23

		if visible then
			v23 = color2
		else
			v23 = color3
		end

		local title = button:FindFirstChild("Title", true)

		if title and title:IsA("TextLabel") then
			title.TextColor3 = v23
		end

		local icon = button:FindFirstChild("Icon", true)

		if icon and icon:IsA("ImageLabel") then
			icon.ImageColor3 = v23
		end

		local uiStroke = button:FindFirstChildOfClass("UIStroke")

		if uiStroke then
			uiStroke.Color = v23
		end
	end
end

local function GetSidebarColumn() -- 1 equivalent call inferred from this helper
	local categories = v17.Frame:FindFirstChild("Categories")

	if categories and categories:IsA("GuiObject") then
		return categories
	end

	return nil
end

local function GetTabContainers() -- 2 equivalent calls inferred from this helper
	return { v17.Top.Categories }
end

function Settings.Open(childName: string)
	Profiler.mark("UI.Settings.Open")
	v21 = childName

	for _, frame in ipairs(v17.Frame.List:GetChildren()) do
		if frame:IsA("Frame") then
			frame.Visible = false
		end
	end

	local child = v17.Frame.List:FindFirstChild(childName)

	if child then
		child.Visible = true

		if not v9[childName] then
			Settings.RenderPage(childName)
		end
	end

	for _, v23 in ipairs(GetTabContainers()) do -- inferred equivalent call
		for _, button in ipairs(v23:GetChildren()) do
			if button:IsA("ImageButton") then
				UpdateTabHighlight(button, button.Name == childName)
			end
		end
	end
end

function Settings.SettingChanged(pageName: string, settingName: string, newValue, flag: boolean?, flag2: boolean?)
	Profiler.mark("UI.Settings.SettingChanged")

	if not v13 then
		warn("[Settings] CurrentSettings is nil")
		return
	end

	local v23 = v10[settingName]

	if not v23 then
		local setting = Pages.GetSetting(pageName, settingName)

		if setting and setting.Category then
			v23 = {
				pageName = pageName,
				categoryName = setting.Category,
				settingName = settingName,
				settingPath = 0
			}
			v23.settingPath = BuildSettingPath(pageName, setting.Category, settingName) -- inferred equivalent call
		else
			warn(`[Settings] Could not find metadata or config for setting: {settingName}`)
			return
		end
	end

	local settingPath = v23.settingPath

	if settingPath == "Settings.Audio.Music.Bomb/Hostage Volume" then
		local SoundController = require(ReplicatedStorage.Controllers.SoundController)
		SoundController.SetBombPlantedMusicVolume(newValue)
	elseif settingPath == "Settings.Video.Advanced.Aspect Ratio" then
		local CameraController = require(ReplicatedStorage.Controllers.CameraController)
		CameraController.SetAspectRatio(newValue)
	end

	if flag then
		return
	end

	if pageName == "Video" and newValue == true and table.find(v, settingName) then
		local v24

		if v13 then
			local databasePageName = GetDatabasePageName("Video") -- inferred equivalent call
			local v25 = v13[databasePageName]

			if v25 then
				local v26 = "Potato Mode"
				local function searchInTable(items)
					for k, item in pairs(items) do
						if k == v26 then
							return item
						end

						if type(item) ~= "table" then
							continue
						end

						local v27 = searchInTable(item)

						if v27 ~= nil then
							return v27
						end
					end

					return nil
				end

				v24 = searchInTable(v25)
			end
		end

		if v24 == true then
			Router.broadcastRouter(
				"CreateMenuNotification",
				"Error",
				"You can't turn this on while Potato Mode is enabled"
			)

			if v21 == "Video" and v9[v21] then
				task.defer(Settings.RenderPage, v21)
			end

			return
		end
	end

	local oldValue = GetSettingValue(pageName, settingName) -- inferred equivalent call

	if DeepEqual(oldValue, newValue) and not flag2 then
		return
	end

	local v24 = v13
	local databasePageName = GetDatabasePageName(pageName) -- inferred equivalent call

	if not v24[databasePageName] then
		v24[databasePageName] = {}
	end

	local v25 = v24[databasePageName]

	if not v25[v23.categoryName] then
		v25[v23.categoryName] = {}
	end

	v25[v23.categoryName][settingName] = newValue

	if pageName == "Keybinds" and type(oldValue) == "table" and type(newValue) == "table" then
		for _, v26 in ipairs({ "Computer", "Console" }) do
			local v27 = oldValue[v26]
			local v28

			if type(v27) == "string" then
				v28 = v27 ~= newValue[v26]
			else
				v28 = false
			end

			if not (v28 and v12[`{v26}:{v27}`] == settingName and v27 ~= "" and v27 ~= "None") then
				continue
			end

			local formatted = `{v26}:{v27}`
			v12[formatted] = nil
		end
	end

	local v26 = pageName == "Keybinds" and v13[databasePageName]

	if v26 then
		local InputController = require(ReplicatedStorage.Controllers.InputController)
		InputController.loadActionsFromDatabase(v26)
	end

	if pageName == "Keybinds" and type(newValue) == "table" then
		for _, v27 in ipairs({ "Computer", "Console" }) do
			local v28 = newValue[v27]
			local v29 = not v28 or v28 == ""

			if not v29 then
				local v30

				if not (v28 == "" or v28 == "None") then
					v30 = v12[`{v27}:{v28}`]

					if not v30 or v30 == settingName then
						v30 = nil
					end
				end

				v29 = not v30
			end

			if v29 and v27 ~= v8 then
				Profiler.defer("UI.Settings.ClearKeybindHighlightDeferred", ClearKeybindHighlight, settingName, v27)
			end
		end
	end

	AddToHistory(settingPath, oldValue, newValue)
	v14[settingPath] = { Value = DeepCopy(newValue), SentAt = os.clock() }

	if v15 then
		local v27, v28 = ResolveSettingPath(v15, settingPath)
		v27[v28] = DeepCopy(newValue)
	end

	Remotes.Player.UpdatePlayerSettings.Send({ Value = newValue, Path = settingPath })

	if pageName == "Video" and settingName == "Potato Mode" and newValue == true and oldValue ~= true then
		count += 1
		batch = count
		v7[#v7].batch = batch

		for _, v27 in ipairs(v) do
			Settings.SettingChanged("Video", v27, false)
		end

		batch = nil

		if v21 == "Video" and v9[v21] then
			Settings.RenderPage(v21)
		end
	end

	if pageName == "Video" and settingName == "Potato Mode" and newValue == false and oldValue == true then
		Router.broadcastRouter(
			"CreateMenuNotification",
			"Error",
			"Potato mode has been disabled. Please rejoin for this change to take effect"
		)
	end
end

function Settings.UpdateSettings(p)
	Profiler.mark("UI.Settings.UpdateSettings")
	v13 = p
	local now = os.clock()

	for k, v23 in v14 do
		local v24, v25 = ResolveSettingPath(p, k)

		if DeepEqual(v24[v25], v23.Value) or now - v23.SentAt > 5 then
			v14[k] = nil
		else
			v24[v25] = DeepCopy(v23.Value)
		end
	end

	if v15 and DeepEqual(p, v15) then
		return
	end

	v15 = DeepCopy(p)

	if v21 and v9[v21] then
		Settings.RenderPage(v21)
	end
end

function Settings.ResetCrosshair()
	for k, v23 in pairs({
		["Crosshair Style"] = "Classic",
		["Crosshair Image"] = 0,
		["Follow Recoil"] = true,
		["Center Dot"] = true,
		["T Style"] = false,
		Red = 0,
		Green = 255,
		Blue = 0,
		Length = 5,
		Thickness = 1,
		Gap = 0,
		Outline = { Enabled = true, Value = 1 },
		Alpha = { Enabled = false, Value = 200 },
		["Friendly Fire Reticle Warning"] = true,
		["Use Crosshair Color for Scope Dot"] = true,
		["Show my crosshair when spectating bots"] = false,
		["Show Player Crosshairs"] = false
	}) do
		Settings.SettingChanged("Game", k, v23)
	end

	Settings.RenderPage("Game")
end

function Settings.ShareCrosshair()
	if not (v13 and v13.Game and v13.Game.Crosshair) then
		warn("[Settings] No crosshair settings to share")
		return
	end

	local HttpService = game:GetService("HttpService")
	local crosshair = v13.Game.Crosshair
	local success, result = pcall(function()
		return HttpService:JSONEncode(crosshair)
	end)

	if not (success and result) then
		warn("[Settings] Failed to encode crosshair settings:", result)
		return
	end

	v17.Share.Visible = true
	v17.Share.TextBox.Text = result
	v17.Share.TextBox:CaptureFocus()
	v17.Share.TextBox.CursorPosition = #result + 1
end

function Settings.ImportCrosshair(json: string)
	local HttpService = game:GetService("HttpService")
	local success, result = pcall(function()
		return HttpService:JSONDecode(json)
	end)

	if not success or not result or type(result) ~= "table" then
		warn("[Settings] Failed to import crosshair settings - invalid code")
		return
	end

	for k, v23 in pairs(result) do
		Settings.SettingChanged("Game", k, v23)
	end

	Settings.RenderPage("Game")
	v17.Share.Visible = false
end

function Settings.ResetPage(p: string)
	local page = Pages.GetPage(p)

	if not page then
		warn(`[Settings] Page '{p}' not found`)
		return
	end

	local function resetSetting(value: string, data)
		if not value:match("^_Divider_") and data.Default ~= nil then
			local default = data.Default
			local v23 = data.HasEnabledToggle and {
				Enabled = data.DefaultEnabled or false,
				Value = data.Default
			} or default
			Settings.SettingChanged(p, value, v23)
		end
	end

	local potatoMode

	if p == "Video" then
		potatoMode = page["Potato Mode"]
	end

	if potatoMode then
		resetSetting("Potato Mode", potatoMode)
	end

	for k, v23 in pairs(page) do
		if not potatoMode or k ~= "Potato Mode" then
			resetSetting(k, v23)
		end
	end

	Settings.RenderPage(p)
end

function Settings.UndoLastChange()
	if #v7 == 0 then
		warn("[Settings] No changes to undo")
		return
	end

	local v23 = table.remove(v7)

	if not v23 then
		return
	end

	local function undoChange(data)
		Remotes.Player.UpdatePlayerSettings.Send({ Path = data.path, Value = data.oldValue })
		local v24 = string.split(data.path, ".")

		if #v24 >= 3 then
			local oldValues = v13

			for i = 2, #v24 - 1 do
				local v25 = v24[i]

				if not oldValues[v25] then
					return
				end

				oldValues = oldValues[v25]
			end

			oldValues[v24[#v24]] = data.oldValue
		end

		if data.path == "Settings.Video.Advanced.Aspect Ratio" then
			local CameraController = require(ReplicatedStorage.Controllers.CameraController)
			CameraController.SetAspectRatio(data.oldValue)
		end

		if data.path == "Settings.Video.Presets.Potato Mode" and data.newValue == true and data.oldValue ~= true then
			Router.broadcastRouter(
				"CreateMenuNotification",
				"Error",
				"Potato mode has been disabled. Please rejoin for this change to take effect"
			)
		end
	end

	undoChange(v23)

	while v23.batch and #v7 > 0 and v7[#v7].batch == v23.batch do
		undoChange(table.remove(v7))
	end

	if v21 then
		Settings.RenderPage(v21)
	end
end

local function SetupEditMobileTabButton(button)
	local function UpdateButtonVisibility(p) -- 2 equivalent calls inferred from this helper
		button.Visible = EditMobile.ShouldShowEntryButton(p)
	end

	UpdateButtonVisibility(nil) -- inferred equivalent call
	UserInputService.LastInputTypeChanged:Connect(UpdateButtonVisibility)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		UpdateButtonVisibility(nil) -- inferred equivalent call
	end)
	ActivateButton(button)
	button.MouseButton1Click:Connect(function()
		local Top = require(ReplicatedStorage.Interface.Screens.Menu.Top)
		Top.openFrame("Dashboard")

		if MenuState.GetCurrentScreen() ~= "Dashboard" then
			return
		end

		EditMobile.Open()
	end)
end

function Settings.Initialize(_, p)
	Profiler.mark("UI.Settings.Initialize")
	v17 = p
	v22.CrosshairPreviewTemplate = settings:WaitForChild("CrosshairPreviewTemplate")
	v22.ColorPickerTemplate = settings:WaitForChild("ColorPickerTemplate")
	v22.ChangeColor = settings:WaitForChild("ChangeColor")
	v22.ToggleTemplate = settings:WaitForChild("ToggleTemplate")
	v22.DropdownTemplate = settings:WaitForChild("DropdownTemplate")
	v22.NumberTemplate = settings:WaitForChild("NumberTemplate")
	v22.SliderTemplate = settings:WaitForChild("SliderTemplate")
	v22.KeybindTemplate = settings:WaitForChild("KeybindTemplate")
	local sidebarColumn = GetSidebarColumn() -- inferred equivalent call

	if sidebarColumn then
		sidebarColumn.Visible = false
	end

	for _, childName in ipairs(v2) do
		local guiObject = v17.Frame:FindFirstChild(childName)

		if guiObject and guiObject:IsA("GuiObject") then
			guiObject.Visible = false
		end
	end

	for _, v23 in ipairs(GetTabContainers()) do -- inferred equivalent call
		for _, button in ipairs(v23:GetChildren()) do
			if not button:IsA("ImageButton") then
				continue
			end

			if button.Name == "EditMobile" then
				SetupEditMobileTabButton(button)
			else
				ActivateButton(button)
				local v24 = button
				button.MouseButton1Click:Connect(function()
					Settings.Open(v24.Name)
				end)
			end
		end
	end

	MenuState.RegisterBumperOverride(v17, function(flag: boolean)
		if v19 then
			return true
		end

		local nextBumperTab = MenuState.GetNextBumperTab(v17.Top.Categories, v4, v21, flag)

		if nextBumperTab and nextBumperTab ~= v21 then
			Settings.Open(nextBumperTab)
		end

		local guiObject = v17.Top.Categories:FindFirstChild(v21)

		if guiObject and guiObject:IsA("GuiObject") then
			GuiService.SelectedObject = guiObject
		end

		return true
	end)
	v17.Reset.MouseButton1Click:Connect(function()
		Settings.ResetPage(v21)
	end)

	if v17:FindFirstChild("Share") then
		v17.Share.Visible = false
		v17.Share.List.Cancel.MouseButton1Click:Connect(function()
			v17.Share.Visible = false
		end)
		v17.Share.List.Copy.MouseButton1Click:Connect(function()
			v17.Share.TextBox:CaptureFocus()
			v17.Share.TextBox.CursorPosition = #v17.Share.TextBox.Text + 1
		end)
		v17.Share.List.Import.MouseButton1Click:Connect(function()
			Settings.ImportCrosshair(v17.Share.TextBox.Text)
		end)
	end

	UserInputService.InputBegan:Connect(function(input, _: boolean)
		if not v19 or input.UserInputState ~= Enum.UserInputState.Begin or tick() - v20 < 0.1 then
			return
		end

		if v19.Parent then
			local keybindPlatformFromTextBox = GetKeybindPlatformFromTextBox(v19)

			if not keybindPlatformFromTextBox then
				CancelKeybindListening()
				return
			end

			local v23 = ""

			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					CancelKeybindListening()
					return
				else
					v23 = `Enum.KeyCode.{input.KeyCode.Name}`
				end
			elseif
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3
			then
				v23 = `Enum.UserInputType.{input.UserInputType.Name}`
			elseif string.match(input.UserInputType.Name, "^Gamepad%d+$") then
				v23 = `Enum.KeyCode.{input.KeyCode.Name}`
				CloseButtonRegistry.MarkUsed()
			end

			if v23 ~= "" then
				HandleKeybindCapture(keybindPlatformFromTextBox, v23)
			end
		else
			v19 = nil
			v16 = nil
			ReenableScrolling() -- inferred equivalent call
			RestoreListeningSelection()
		end
	end)
	UserInputService.InputChanged:Connect(function(input, _: boolean)
		if not v19 or input.UserInputType ~= Enum.UserInputType.MouseWheel or tick() - v20 < 0.1 then
			return
		end

		if v19.Parent then
			local keybindPlatformFromTextBox = GetKeybindPlatformFromTextBox(v19)

			if not keybindPlatformFromTextBox then
				CancelKeybindListening()
				return
			end

			local z = input.Position.Z

			if z > 0 then
				HandleKeybindCapture(keybindPlatformFromTextBox, "Enum.CustomInputType.ScrollWheelUp")
			elseif z < 0 then
				HandleKeybindCapture(keybindPlatformFromTextBox, "Enum.CustomInputType.ScrollWheelDown")
			end
		else
			v16 = nil
			v19 = nil
			ReenableScrolling() -- inferred equivalent call
			RestoreListeningSelection()
		end
	end)
	UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.ButtonB or v19 then
			return
		end

		local v23 = v18

		if not (v23 and v23.Visible) then
			return
		end

		CloseButtonRegistry.MarkUsed()
		v23.Visible = false
		local parent = v23.Parent

		if parent then
			parent.Visible = false
		end

		for _, button in ipairs(v23:GetChildren()) do
			if button:IsA("TextButton") then
				button:Destroy()
			end
		end

		v18 = nil
		local parent2 = parent and parent.Parent

		if parent2 and parent2:IsA("GuiButton") then
			GuiService.SelectedObject = parent2
		end
	end)
	UserInputService.InputBegan:Connect(function(input, _: boolean)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		local v23 = v18

		if not (v23 and v23.Visible) then
			return
		end

		local position = input.Position

		if not (v23.Parent and v23.Parent.Parent) then
			return
		end

		local options = v23.Parent.Parent:FindFirstChild("Options")

		if not options then
			return
		end

		local button = options.Button

		if not button then
			return
		end

		local function isInside(p2) -- 2 equivalent calls inferred from this helper
			local absolutePosition = p2.AbsolutePosition
			local absoluteSize = p2.AbsoluteSize
			return position.X >= absolutePosition.X
				and position.X <= absolutePosition.X + absoluteSize.X
				and position.Y >= absolutePosition.Y
				and position.Y <= absolutePosition.Y + absoluteSize.Y
		end

		if not isInside(button) and not isInside(v23) then -- inferred equivalent call
			v23.Visible = false
			v18 = nil
		end
	end)
end

function Settings.Start()
	debug.setmemorycategory("UI.Settings.Start")
	Profiler.mark("UI.Settings.Start")
	Settings.Open("Video")
	DataController.CreateListener(LocalPlayer, "Settings", function(p)
		Settings.UpdateSettings(p)
	end)
end

return Settings