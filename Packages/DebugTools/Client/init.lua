local UserInputService = game:GetService("UserInputService")
local Authorization = require(script.Authorization)
local Interface = require(script.Interface)

if not Authorization:isLocalPlayerAuthorized() then
	return { Authorized = false }
end

local v = {
	internal = { SwitchKey = Enum.KeyCode.F6 },
	interface = {
		Tab = require(script.Tab),
		Widget = require(script.Widget),
		Action = require(script.Parent.Shared.Action),
		Networking = require(script.Networking),
		Imgui = require(script.Imgui),
		Authorized = true,
		BuiltinTabs = {
			Console = require(script.Builtin.Tabs.Console),
			Widgets = require(script.Builtin.Tabs.Widgets),
			Actions = require(script.Builtin.Tabs.Actions),
			Explorer = require(script.Builtin.Tabs.Explorer),
			Properties = require(script.Builtin.Tabs.Properties),
			Performance = require(script.Builtin.Tabs.Performance)
		},
		BuiltinWidgets = {
			PlaceStats = require(script.Builtin.Widgets.PlaceStats),
			Coordinates = require(script.Builtin.Widgets.Coordinates),
			KeyboardInput = require(script.Builtin.Widgets.KeyboardInput),
			CodeWarnings = require(script.Builtin.Widgets.CodeWarnings)
		},
		Style = require(script.Style),
		Accessible = true
	}
}

function v.internal.observeKeyBinds()
	UserInputService.InputBegan:Connect(function(input, gameProcessed: boolean)
		if gameProcessed or input.KeyCode ~= v.internal.SwitchKey then
			return
		end

		Interface.switchVisibility()
	end)
end

function v.internal.observeMobileGesture()
	local inputs = {}

	local function removeTouchPoint(p)
		for k, v2 in inputs do
			if v2 ~= p then
				continue
			end

			table.remove(inputs, k)
			break
		end
	end

	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local viewportSize = workspace.CurrentCamera.ViewportSize
		local v2 = math.abs((viewportSize.X / 2 - input.Position.X) / viewportSize.X)

		if input.Position.Y / viewportSize.Y > 0 or v2 >= 0.1 then
			return
		end

		table.insert(inputs, input)

		if #inputs >= 3 then
			for _, v3 in inputs do
				removeTouchPoint(v3)
			end

			Interface.switchVisibility()
		end

		task.delay(0.75, function()
			removeTouchPoint(input)
		end)
	end)
end

function v.internal.init()
	Interface.init()
	v.internal.observeKeyBinds()
	v.internal.observeMobileGesture()

	for _, moduleScript in script.Builtin.ImguiWidgets:GetChildren() do
		if moduleScript:IsA("ModuleScript") then
			require(moduleScript)
		end
	end
end

v.internal.init()
return v.interface