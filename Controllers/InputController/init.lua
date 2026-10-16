local createVector = vector.create
local InputController = {}
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local DataController = require(ReplicatedStorage.Controllers.DataController)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local MenuState = require(ReplicatedStorage.Interface.MenuState)
local Router = require(ReplicatedStorage.Database.Security.Router)
local Pages = require(ReplicatedStorage.Database.Custom.GameStats.UI.Settings.Pages)
local KeybindParser = require(script:WaitForChild("KeybindParser"))
local Actions = script:WaitForChild("Actions")
local LocalPlayer = Players.LocalPlayer
local v = {}
local v2 = {}
local v3 = {}
local v4 = {}
local v5 = { "Computer", "Console" }

local function handleInput(p: string, p2, p3)
	local v6 = v3[p]

	if not v6 then
		return
	end

	local menuFrame = MenuState.GetMenuFrame()
	local currentScreen = MenuState.GetCurrentScreen()
	local mainGui = MenuState.GetMainGui()
	local gameplay = mainGui and mainGui:FindFirstChild("Gameplay")
	local bottom = gameplay and gameplay:FindFirstChild("Bottom")
	local middle = gameplay and gameplay:FindFirstChild("Middle")
	local teamSelection = middle and middle:FindFirstChild("TeamSelection")
	local v7 = teamSelection
		and teamSelection:IsA("GuiObject")
		and teamSelection.Visible
		and bottom
		and bottom:IsA("GuiObject")
		and not bottom.Visible
	local v8 = (currentScreen ~= nil or menuFrame and menuFrame.Visible == true) and true or v7 == true
	local v9 = v6.Category == "UI Keys" or v6.Category == "Communication Options"

	if v8 and not v9 and p2 == Enum.UserInputState.Begin then
		v6.IsActive = false
	elseif v2[v6.Group] == true then
		v6.IsActive = p2 == Enum.UserInputState.Begin
		task.spawn(v6.Callback, p2, p3)
	elseif p2 ~= Enum.UserInputState.Begin and v6.IsActive then
		v6.IsActive = false
		task.spawn(v6.Callback, p2, p3)
	end
end

local function newWheelInput(p: number) -- 2 equivalent calls inferred from this helper
	return { UserInputType = Enum.UserInputType.MouseWheel, Delta = Vector3.new(0, p, 0) }
end

local function handleScrollWheelInput(p: string?, p2: number)
	if not p then
		return
	end

	handleInput(p, Enum.UserInputState.Begin, newWheelInput(p2)) -- inferred equivalent call
	task.defer(handleInput, p, Enum.UserInputState.End, newWheelInput(p2)) -- inferred equivalent call
end

local function unbindActionKeys(p: string)
	local v6 = v3[p]

	if not v6 then
		return
	end

	ContextActionService:UnbindAction(p)

	for _, keybind in ipairs(v6.Keybinds) do
		if typeof(keybind) == "string" then
			if v4[keybind] == p then
				v4[keybind] = nil
			end
		elseif v[keybind] == p then
			v[keybind] = nil
		end
	end

	v6.Keybinds = {}
end

function InputController.registerAction(data)
	v3[data.Name] = {
		Category = data.Category,
		Callback = data.Callback,
		Group = data.Group,
		BindPriority = data.BindPriority,
		Name = data.Name,
		IsActive = false,
		Keybinds = {}
	}
end

function InputController.bindKeybinds(p: string, list)
	local v6 = v3[p]

	if not v6 then
		return
	end

	unbindActionKeys(p)
	local keybinds = {}
	local v7 = {}

	for _, v8 in ipairs(list) do
		if typeof(v8) == "string" then
			if v8 == "ScrollWheelUp" or v8 == "ScrollWheelDown" then
				local v9 = v4[v8]

				if v9 then
					warn(`[InputController] {p}: {v8} is already bound to {v9}, keybind dropped`)
				else
					table.insert(keybinds, v8)
					v4[v8] = p
				end
			end
		else
			local v9 = v[v8]

			if v9 then
				warn(`[InputController] {p}: {tostring(v8)} is already bound to {v9}, keybind dropped`)
			else
				table.insert(keybinds, v8)
				table.insert(v7, v8)
				v[v8] = p
			end
		end
	end

	v6.Keybinds = keybinds

	if #v7 > 0 then
		local function fn(_, p2, p3)
			handleInput(p, p2, p3)
		end

		if v6.BindPriority == nil then
			ContextActionService:BindAction(p, fn, false, table.unpack(v7))
		else
			ContextActionService:BindActionAtPriority(p, fn, false, v6.BindPriority, table.unpack(v7))
		end
	end
end

function InputController.loadActionsFromDatabase(items)
	local v6 = {}

	for _, item in pairs(items) do
		for k, v7 in pairs(item) do
			if typeof(v7) ~= "table" then
				continue
			end

			local setting = Pages.GetSetting("Keybinds", k)

			if setting and setting.IsEnabled == false then
				unbindActionKeys(k)
			else
				local values = {}

				for _, v8 in ipairs(v5) do
					local v9 = v7[v8]

					if not (v9 and v9 ~= "") then
						continue
					end

					local parsed = KeybindParser.parse(v9)

					if parsed then
						table.insert(values, parsed)
					end
				end

				v6[k] = values
			end
		end
	end

	local v7 = v6["Switch Viewmodel Left/Right Hand"] == nil

	if v7 then
		unbindActionKeys("Switch Viewmodel Left/Right Hand")
	end

	for k in pairs(v6) do
		unbindActionKeys(k)
	end

	for k, v8 in pairs(v6) do
		InputController.bindKeybinds(k, v8)
	end

	if v7 then
		local setting = Pages.GetSetting("Keybinds", "Switch Viewmodel Left/Right Hand")
		local parsed = setting and KeybindParser.parse(setting.Default.Computer)

		if typeof(parsed) == "EnumItem" and v[parsed] == nil then
			InputController.bindKeybinds("Switch Viewmodel Left/Right Hand", { parsed })
		end
	end
end

function InputController.isActionActive(p: string)
	local v6 = v3[p]
	return v6 and v6.IsActive or false
end

function InputController.enableGroup(p: string)
	v2[p] = true
end

function InputController.disableGroup(p: string)
	v2[p] = nil
end

function InputController.GetActionKeybind(p: string)
	local v6 = v3[p]

	if not v6 or #v6.Keybinds == 0 then
		return nil
	end

	local keybind = v6.Keybinds[1]

	if typeof(keybind) == "string" then
		return keybind
	end

	return tostring(keybind):match("%.(%w+)$") or tostring(keybind)
end

function InputController.Initialize()
	for _, moduleScript in ipairs(Actions:GetChildren()) do
		if not moduleScript:IsA("ModuleScript") then
			continue
		end

		local registerAction = InputController.registerAction
		local module = require(moduleScript)
		registerAction(module)
	end

	InputController.enableGroup("Default")
	CharacterResolver.observeCharacter(LocalPlayer, function(p)
		if p then
			ContextActionService:UnbindAction("jumpAction")
		end

		return function() end
	end)
	DataController.CreateListener(LocalPlayer, "Settings.Keyboard/Mouse", function(p)
		if p then
			InputController.loadActionsFromDatabase(p)
		end
	end)
	Router.observerRouter("RebindKeybinds", function()
		local v6 = DataController.Get(LocalPlayer, "Settings.Keyboard/Mouse")

		if not v6 then
			return false
		end

		InputController.loadActionsFromDatabase(v6)
		return true
	end)
end

function InputController.getActionKeybinds(p: string)
	local keybinds = {}
	local v6 = v3[p]

	if v6 then
		for _, keybind in ipairs(v6.Keybinds) do
			if typeof(keybind) ~= "string" then
				table.insert(keybinds, keybind)
			end
		end
	end

	return keybinds
end

function InputController.isBindingPressed(p)
	if typeof(p) ~= "EnumItem" then
		return false
	end

	if p.EnumType == Enum.KeyCode then
		if p == Enum.KeyCode.ButtonR2 or p == Enum.KeyCode.ButtonL2 then
			for _, v6 in UserInputService:GetConnectedGamepads() do
				for _, v7 in UserInputService:GetGamepadState(v6) do
					if v7.KeyCode == p and v7.Position.Z > 0.3 then
						return true
					end
				end
			end

			return false
		else
			local name = p.Name

			if not (string.match(name, "^Button") or string.match(name, "^DPad")) then
				return UserInputService:IsKeyDown(p)
			end

			for _, v6 in UserInputService:GetConnectedGamepads() do
				if UserInputService:IsGamepadButtonDown(v6, p) then
					return true
				end
			end

			return false
		end
	elseif p.EnumType == Enum.UserInputType then
		return UserInputService:IsMouseButtonPressed(p)
	else
		return false
	end
end

function InputController.isActionPressed(p: string, p2)
	local actionKeybinds = InputController.getActionKeybinds(p)

	if #actionKeybinds == 0 then
		actionKeybinds = p2 or actionKeybinds
	end

	for _, actionKeybind in ipairs(actionKeybinds) do
		if InputController.isBindingPressed(actionKeybind) then
			return true
		end
	end

	return false
end

function InputController.Start()
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then
			return
		end

		local z = input.Position.Z

		if z > 0 then
			local scrollWheelUp = v4.ScrollWheelUp

			if not scrollWheelUp then
				return
			end

			handleInput(scrollWheelUp, Enum.UserInputState.Begin, {
				UserInputType = Enum.UserInputType.MouseWheel,
				Delta = createVector(0, 1, 0)
			})
			task.defer(handleInput, scrollWheelUp, Enum.UserInputState.End, {
				UserInputType = Enum.UserInputType.MouseWheel,
				Delta = createVector(0, 1, 0)
			})
		elseif z < 0 then
			local scrollWheelDown = v4.ScrollWheelDown

			if not scrollWheelDown then
				return
			end

			handleInput(scrollWheelDown, Enum.UserInputState.Begin, {
				UserInputType = Enum.UserInputType.MouseWheel,
				Delta = createVector(0, -1, 0)
			})
			task.defer(handleInput, scrollWheelDown, Enum.UserInputState.End, {
				UserInputType = Enum.UserInputType.MouseWheel,
				Delta = createVector(0, -1, 0)
			})
		end
	end)
end

return InputController