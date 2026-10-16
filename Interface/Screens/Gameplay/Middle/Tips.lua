local createVector = vector.create
local Tips = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local GetWeaponProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local GetBindIcon = require(ReplicatedStorage.Components.Common.GetBindIcon)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local KeybindParser = require(ReplicatedStorage.Controllers.InputController.KeybindParser)
local Pages = require(ReplicatedStorage.Database.Custom.GameStats.UI.Settings.Pages)
local udim = UDim2.fromScale(0.985, 0.62)
local v = { "Primary", "Secondary", "Melee", "Grenade" }
local v2 = {
	Menu = "Main Menu",
	ChooseTeam = "Choose Team",
	Scoreboard = "Scoreboard",
	Reload = "Reload",
	WeaponMod = "Secondary Fire",
	Plant = "Fire"
}
local v3 = { "Menu", "ChooseTeam", "Scoreboard", "Plant", "WeaponMod", "Reload" }
local v4 = {
	SpectatePrevious = {
		Computer = Enum.UserInputType.MouseButton1,
		Console = Enum.KeyCode.ButtonL1
	},
	SpectateNext = { Computer = Enum.UserInputType.MouseButton2, Console = Enum.KeyCode.ButtonR1 },
	SpectateCamera = { Computer = Enum.KeyCode.Space, Console = Enum.KeyCode.ButtonA }
}
local _ = { Scope = "Scope", Suppressor = "Suppressor", Burst = "Burst Fire" }
local v5 = {
	[Enum.KeyCode.LeftControl] = "CTRL",
	[Enum.KeyCode.RightControl] = "CTRL",
	[Enum.KeyCode.LeftShift] = "SHIFT",
	[Enum.KeyCode.RightShift] = "SHIFT",
	[Enum.KeyCode.LeftAlt] = "ALT",
	[Enum.KeyCode.RightAlt] = "ALT",
	[Enum.KeyCode.Tab] = "TAB",
	[Enum.KeyCode.CapsLock] = "CAPS",
	[Enum.KeyCode.Space] = "SPACE",
	[Enum.KeyCode.Return] = "ENTER",
	[Enum.KeyCode.Backspace] = "BACK"
}
local v6 = {
	[Enum.UserInputType.MouseButton1] = "LMB",
	[Enum.UserInputType.MouseButton2] = "RMB",
	[Enum.UserInputType.MouseButton3] = "MMB"
}
local v7 = {
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonL1] = "LB",
	[Enum.KeyCode.ButtonR1] = "RB",
	[Enum.KeyCode.ButtonL2] = "LT",
	[Enum.KeyCode.ButtonR2] = "RT",
	[Enum.KeyCode.ButtonL3] = "LS",
	[Enum.KeyCode.ButtonR3] = "RS"
}
local parent2 = nil
local v8 = nil
local guiObjects = {}
local v9 = {}
local v10 = {}
local v11 = table.find(GetUserPlatform(), "Mobile") ~= nil
local v12 = true
local flag = false
local thread = nil
local v13 = false
local v14 = false
local text = nil
local v15 = { Plant = false, Reload = false }
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.IgnoreWater = true

local function decodeJSON(value)
	if typeof(value) ~= "string" then
		return nil
	end

	local success, result = pcall(HttpService.JSONDecode, HttpService, value)

	if success and typeof(result) == "table" then
		return result
	end

	return nil
end

local function isAlive() -- 1 equivalent call inferred from this helper
	return CharacterResolver.isAliveCharacter(LocalPlayer.Character)
end

local function updateHasBomb() -- 1 equivalent call inferred from this helper
	local slot5 = LocalPlayer:GetAttribute("Slot5")
	local result

	if typeof(slot5) == "string" then
		local success
		success, result = pcall(HttpService.JSONDecode, HttpService, slot5)

		if not success or typeof(result) ~= "table" then
			result = nil
		end
	end

	v13 = result ~= nil and result.Weapon == "C4"
end

local function updateEquippedState()
	local currentEquipped = LocalPlayer:GetAttribute("CurrentEquipped")
	local result

	if typeof(currentEquipped) == "string" then
		local success
		success, result = pcall(HttpService.JSONDecode, HttpService, currentEquipped)

		if not success or typeof(result) ~= "table" then
			result = nil
		end
	end

	local v16 = result and result.Name and GetWeaponProperties(result.Name)
	local v17

	if v16 == nil then
		v17 = false
	else
		v17 = v16.Class == "Weapon"
	end

	v14 = v17 and v16.MuzzleType ~= "Zeus x27"
	local v18

	if v17 then
		if v16.HasScope then
			v18 = "Scope"
		elseif v16.HasSuppressor then
			v18 = "Suppressor"
		elseif v16.ShootingOptions == "Burst" then
			v18 = "Burst Fire"
		else
			v18 = nil
		end
	end

	text = v18
end

local function isInPlantZone()
	local character = LocalPlayer.Character
	local primaryPart = character and (character.PrimaryPart or character:FindFirstChild("HumanoidRootPart"))

	if not primaryPart then
		return false
	end

	local filterDescendantsInstances = { workspace.CurrentCamera }

	for _, v16 in ipairs(Players:GetPlayers()) do
		if v16.Character then
			table.insert(filterDescendantsInstances, v16.Character)
		end
	end

	local map = workspace:FindFirstChild("Map")
	local barriers = map and map:FindFirstChild("Barriers")

	if barriers then
		table.insert(filterDescendantsInstances, barriers)
	end

	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	local raycastResult = workspace:Raycast(primaryPart.Position, createVector(-0, -5, -0), raycastParams)
	return raycastResult ~= nil
		and raycastResult.Instance:HasTag("PlantArea")
		and raycastResult.Instance:GetAttribute("Site") ~= nil
end

local function canReload()
	local currentEquipped = InventoryController.getCurrentEquipped()
	local properties = currentEquipped and currentEquipped.Properties

	if not properties or not properties.Rounds or properties.RechargeTime then
		return false
	end

	if currentEquipped.IsReloading or currentEquipped.Rounds >= properties.Rounds then
		return false
	end

	if
		(workspace:GetAttribute("Gamemode") == "Deathmatch" or IsTutorialMode())
		and properties.ReloadAnimationCount == 1
	then
		return true
	end

	return (currentEquipped.Capacity or 0) > 0
end

local function updateAvailability()
	local plant = v13 and isInPlantZone()
	local reload = v14 and canReload()
	local v16 = plant ~= v15.Plant or reload ~= v15.Reload
	local v17 = v15
	v15.Plant = plant
	v17.Reload = reload
	return v16
end

local function bindingToText(p)
	if p.EnumType == Enum.UserInputType then
		return v6[p]
	end

	local v16 = v5[p]

	if v16 then
		return v16
	end

	local stringForKeyCode = UserInputService:GetStringForKeyCode(p)

	if stringForKeyCode and stringForKeyCode ~= "" then
		return string.upper(stringForKeyCode)
	end

	return string.upper(p.Name)
end

local function getBindLabels(instance)
	local v16 = nil
	local v17 = nil

	for _, guiObject in ipairs(instance:GetChildren()) do
		if guiObject.Name ~= "Bind" then
			continue
		end

		if guiObject:IsA("TextLabel") then
			v16 = guiObject
		elseif guiObject:IsA("ImageLabel") then
			v17 = guiObject
		end
	end

	return v16, v17
end

function Tips.IsGamepadPreferred()
	return UserInputService.PreferredInput == Enum.PreferredInput.Gamepad
end

function Tips.ResolveActionBinding(p: string)
	local v16 = Tips.IsGamepadPreferred() and "Console" or "Computer"
	local v17 = nil
	local v18 = false
	local v19 = DataController.Get(LocalPlayer, "Settings.Keyboard/Mouse")

	if typeof(v19) == "table" then
		for _, v20 in pairs(v19) do
			if not (typeof(v20) == "table" and typeof(v20[p]) == "table") then
				continue
			end

			v17 = v20[p][v16]
			v18 = true
			break
		end
	end

	if not v18 then
		local setting = Pages.GetSetting("Keybinds", p)
		local default = setting and setting.Default

		if typeof(default) == "table" then
			v17 = default[v16]
		end
	end

	if typeof(v17) ~= "string" or v17 == "" then
		return nil
	end

	local parsed = KeybindParser.parse(v17)

	if typeof(parsed) == "EnumItem" then
		return parsed
	end

	return nil
end

function Tips.GetActionKeyText(p: string)
	local actionBinding = Tips.ResolveActionBinding(p)

	if not actionBinding then
		return nil
	end

	local v16 = v7[actionBinding]

	if v16 then
		return v16
	end

	if Tips.IsGamepadPreferred() then
		return nil
	end

	return bindingToText(actionBinding)
end

function Tips.ApplyBindingToKeybind(p, p2)
	local bindLabels, v16 = getBindLabels(p)
	local image = GetBindIcon(p2)

	if v16 and image then
		v16.Image = image
		v16.Visible = true

		if bindLabels then
			bindLabels.Visible = false
		end

		return true
	else
		local text2 = p2 and bindingToText(p2)

		if bindLabels and text2 then
			bindLabels.Text = text2
			bindLabels.Visible = true

			if v16 then
				v16.Visible = false
			end

			return true
		else
			if bindLabels then
				bindLabels.Visible = false
			end

			if v16 then
				v16.Visible = false
			end

			return false
		end
	end
end

local function mirrorX(point: Vector2, udim2: UDim2)
	return
		Vector2.new(1 - point.X, point.Y),
		UDim2.new(1 - udim2.X.Scale, -udim2.X.Offset, udim2.Y.Scale, udim2.Y.Offset)
end

function Tips.MirrorRow(instance)
	local keybind = instance:FindFirstChild("Keybind")

	if keybind and keybind:IsA("GuiObject") then
		local anchorPoint = keybind.AnchorPoint
		local position = keybind.Position
		local vector = Vector2.new(1 - anchorPoint.X, anchorPoint.Y)
		local udim2 = UDim2.new(1 - position.X.Scale, -position.X.Offset, position.Y.Scale, position.Y.Offset)
		keybind.AnchorPoint = vector
		keybind.Position = udim2
	end

	local title = instance:FindFirstChild("Title")

	if title and title:IsA("TextLabel") then
		local anchorPoint = title.AnchorPoint
		local position = title.Position
		local vector = Vector2.new(1 - anchorPoint.X, anchorPoint.Y)
		local udim2 = UDim2.new(1 - position.X.Scale, -position.X.Offset, position.Y.Scale, position.Y.Offset)
		title.AnchorPoint = vector
		title.Position = udim2
		title.TextXAlignment = Enum.TextXAlignment.Right
	end

	local uiGradient = instance:FindFirstChildOfClass("UIGradient")

	if uiGradient then
		uiGradient.Rotation += 180
	end
end

local function mirrorRow(p) -- 1 equivalent call inferred from this helper
	Tips.MirrorRow(p.Frame)
end

local function createChooseTeamRow()
	local menu = parent2:FindFirstChild("Menu")

	if parent2:FindFirstChild("ChooseTeam") or not (menu and menu:IsA("GuiObject")) then
		return
	end

	local clone = menu:Clone()
	clone.Name = "ChooseTeam"
	local title = clone:FindFirstChild("Title")

	if title and title:IsA("TextLabel") then
		title.Text = "Choose Team"
	end

	clone.Parent = parent2
end

local function hideUnusedRows()
	for _, guiObject in ipairs(parent2:GetChildren()) do
		if not guiObject:IsA("GuiObject") or (v2[guiObject.Name] or v4[guiObject.Name]) then
			continue
		end

		guiObject.Visible = false
	end
end

local function loadRows(items, p)
	for childName in pairs(items) do
		local guiObject = parent2:FindFirstChild(childName)
		local keybind = guiObject and guiObject:FindFirstChild("Keybind")
		local title = guiObject and guiObject:FindFirstChild("Title")

		if
			guiObject
			and guiObject:IsA("GuiObject")
			and keybind
			and keybind:IsA("GuiButton")
			and title
			and title:IsA("TextLabel")
		then
			local v16 = { Frame = guiObject, Keybind = keybind, Title = title, HasBind = false }
			guiObject.Visible = false
			mirrorRow(v16) -- inferred equivalent call
			p[childName] = v16
		else
			warn(`[Tips] Row "{childName}" is missing or malformed`)
		end
	end
end

local function renderBinds()
	for k, v16 in pairs(v9) do
		v16.HasBind = Tips.ApplyBindingToKeybind(v16.Keybind, Tips.ResolveActionBinding(v2[k]))
	end

	local v16 = Tips.IsGamepadPreferred() and "Console" or "Computer"

	for k, v17 in pairs(v10) do
		v17.HasBind = Tips.ApplyBindingToKeybind(v17.Keybind, v4[k][v16])
	end
end

local function applyGameplayRows()
	if text and v9.WeaponMod then
		v9.WeaponMod.Title.Text = text
	end

	local v16 = {
		Reload = v15.Reload,
		WeaponMod = text ~= nil,
		Plant = v15.Plant
	}

	for k, v17 in pairs(v9) do
		v17.Frame.Visible = v17.HasBind and v16[k] ~= false
	end
end

local function setRowsVisible(items, flag2: boolean) -- 1 equivalent call inferred from this helper
	for _, item in pairs(items) do
		item.Frame.Visible = flag2 and item.HasBind
	end
end

local function applySpectateRows(flag2: boolean)
	local v16 = SpectateController.GetCurrentSpectateInstance() ~= nil
	local v17 = {
		SpectatePrevious = v16,
		SpectateNext = v16,
		SpectateCamera = SpectateController.CanSwitchPerspective()
	}

	for k, v18 in pairs(v10) do
		v18.Frame.Visible = flag2 and v18.HasBind and v17[k] ~= false
	end
end

local function setPolling(flag2: boolean)
	if flag2 == (thread ~= nil) then
		return
	end

	if flag2 then
		thread = task.spawn(function()
			while true do
				local plant = v13 and isInPlantZone()
				local reload = v14 and canReload()
				local v16 = plant ~= v15.Plant or reload ~= v15.Reload
				local v17 = v15
				v15.Plant = plant
				v17.Reload = reload

				if v16 then
					applyGameplayRows()
				end

				task.wait(0.25)
			end
		end)
		return
	end

	task.cancel(thread)
	thread = nil
	local v16 = v15
	v15.Plant = false
	v16.Reload = false
end

local function getMode() -- 1 equivalent call inferred from this helper
	if v11 or not v12 then
		return "Hidden"
	end

	if LocalPlayer:GetAttribute("IsSpectating") then
		return "Spectate"
	end

	if isAlive() then -- inferred equivalent call
		return "Gameplay"
	end

	return "Hidden"
end

local function refresh()
	flag = false
	local mode = getMode() -- inferred equivalent call
	parent2.Visible = mode ~= "Hidden"
	applySpectateRows(mode == "Spectate")
	setPolling(mode == "Gameplay")

	if mode == "Gameplay" then
		local plant = v13 and isInPlantZone()
		local reload = v14 and canReload()

		if plant == v15.Plant then
			local _ = reload == v15.Reload
		end

		local v16 = v15
		v15.Plant = plant
		v16.Reload = reload
		applyGameplayRows()
	else
		setRowsVisible(v9, false) -- inferred equivalent call
	end
end

local function queueRefresh() -- 2 equivalent calls inferred from this helper
	if flag then
		return
	end

	flag = true
	task.defer(refresh)
end

local function onCharacterAdded(character)
	character:GetAttributeChangedSignal("Dead"):Connect(queueRefresh)
	character:GetAttributeChangedSignal("Health"):Connect(queueRefresh)
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid.Died:Connect(queueRefresh)
	end

	queueRefresh() -- inferred equivalent call
end

local function positionAboveHotbar()
	local parent = parent2.Parent

	if not (parent and parent:IsA("GuiObject")) then
		return
	end

	local y = nil

	if v8 and v8.Visible then
		for _, v16 in ipairs(guiObjects) do
			if v16.Visible and (y == nil or v16.AbsolutePosition.Y < y) then
				y = v16.AbsolutePosition.Y
			end
		end
	end

	if y == nil then
		return
	end

	local v16 = y - parent.AbsolutePosition.Y - 0.01 * parent.AbsoluteSize.Y
	parent2.Position = UDim2.new(udim.X, UDim.new(0, v16))
end

local function followHotbar(instance)
	local gameplay = instance:FindFirstChild("Gameplay")
	local bottom = gameplay and gameplay:FindFirstChild("Bottom")
	local inventory = bottom and bottom:FindFirstChild("Inventory")

	if not (inventory and inventory:IsA("GuiObject")) then
		warn("[Tips] Inventory hotbar not found; the tips keep their default position")
		return
	end

	v8 = inventory
	inventory:GetPropertyChangedSignal("Visible"):Connect(positionAboveHotbar)

	for _, childName in ipairs(v) do
		local guiObject = inventory:FindFirstChild(childName)

		if not (guiObject and guiObject:IsA("GuiObject")) then
			continue
		end

		table.insert(guiObjects, guiObject)
		guiObject:GetPropertyChangedSignal("AbsolutePosition"):Connect(positionAboveHotbar)
		guiObject:GetPropertyChangedSignal("Visible"):Connect(positionAboveHotbar)
	end

	local parent = parent2.Parent

	if parent and parent:IsA("GuiObject") then
		parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(positionAboveHotbar)
	end

	positionAboveHotbar()
end

function Tips.Initialize(p, p2)
	parent2 = p2
	parent2.Visible = false

	if v11 then
		return
	end

	parent2.AnchorPoint = Vector2.new(1, 1)
	parent2.Position = udim
	followHotbar(p)
	local uiListLayout = parent2:FindFirstChildOfClass("UIListLayout")

	if uiListLayout then
		uiListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	end

	createChooseTeamRow()
	hideUnusedRows()
	loadRows(v2, v9)

	for i, v16 in ipairs(v3) do
		local v17 = v9[v16]

		if v17 then
			v17.Frame.LayoutOrder = i
		end
	end

	loadRows(v4, v10)
end

function Tips.Start()
	if v11 then
		return
	end

	updateHasBomb() -- inferred equivalent call
	updateEquippedState()
	renderBinds()
	DataController.CreateListener(
		LocalPlayer,
		"Settings.Game.HUD.Enable Game Instructor Messages",
		function(flag2: boolean?)
			v12 = flag2 ~= false
			queueRefresh() -- inferred equivalent call
		end
	)

	local function onBindsChanged()
		renderBinds()

		if flag then
			return
		end

		flag = true
		task.defer(refresh)
	end

	DataController.CreateListener(LocalPlayer, "Settings.Keyboard/Mouse", onBindsChanged)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(onBindsChanged)
	LocalPlayer:GetAttributeChangedSignal("CurrentEquipped"):Connect(function()
		updateEquippedState()

		if flag then
			return
		end

		flag = true
		task.defer(refresh)
	end)
	LocalPlayer:GetAttributeChangedSignal("Slot5"):Connect(updateHasBomb)
	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(queueRefresh)
	SpectateController.ListenToSpectate:Connect(queueRefresh)
	SpectateController.ListenToFreecam:Connect(queueRefresh)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(queueRefresh)
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
	LocalPlayer.CharacterRemoving:Connect(function()
		if not LocalPlayer:GetAttribute("IsSpectating") then
			parent2.Visible = false

			if (thread ~= nil) == false then
				return
			end

			task.cancel(thread)
			thread = nil
			local v16 = v15
			v15.Plant = false
			v16.Reload = false
		end
	end)

	if LocalPlayer.Character then
		onCharacterAdded(LocalPlayer.Character)
	end

	refresh()
end

return Tips