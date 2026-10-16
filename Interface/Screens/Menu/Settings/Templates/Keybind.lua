local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Parent.Types)
local BindDisplay = require(script.Parent.Parent.BindDisplay)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
require(ReplicatedStorage.Database.Custom.GameStats.UI.Settings.Pages)
local v = { "Computer", "Console" }

local function GetKeybindTextBox(child) -- 1 equivalent call inferred from this helper
	return BindDisplay.GetTextBox(child)
end

local function GetKeybindReset(child) -- 1 equivalent call inferred from this helper
	local button = BindDisplay.GetReset(child)

	if button and button:IsA("GuiButton") then
		return button
	end

	return nil
end

return function(name: string, p, parent, layoutOrder: number, state, p2, callback, p3: string, callback2, callback3)
	state.LayoutOrder = layoutOrder
	state.Left.Label.Text = p.DisplayName or name
	state.Name = name
	local maid = Janitor.new()
	maid:Add(state, "Destroy")
	local v2 = {}

	for _, v3 in v do
		local v4 = p2[v3]

		if v4 == nil then
			if p.Default then
				local default = p.Default
				v2[v3] = typeof(default) ~= "table" and "" or default[v3] or ""
			else
				v2[v3] = ""
			end
		else
			v2[v3] = v4
		end
	end

	local function UpdateKeybindUI(child, p4: string) -- 2 equivalent calls inferred from this helper
		BindDisplay.Apply(child, p4)
	end

	local function SaveKeybinds() -- 1 equivalent call inferred from this helper
		callback(p3, name, { Computer = v2.Computer, Console = v2.Console })
	end

	for _, childName in v do
		local child = state.Right:FindFirstChild(childName)

		if not child then
			continue
		end

		UpdateKeybindUI(child, v2[childName]) -- inferred equivalent call
		local keybindTextBox = GetKeybindTextBox(child) -- inferred equivalent call

		if keybindTextBox then
			local v3 = childName
			maid:Add(keybindTextBox.Focused:Connect(function()
				callback2(keybindTextBox, v2[v3], tick())
			end), "Disconnect")
		end

		local keybindReset = GetKeybindReset(child) -- inferred equivalent call

		if keybindReset then
			local v3 = childName
			maid:Add(keybindReset.MouseButton1Click:Connect(function()
				v2[v3] = ""
				UpdateKeybindUI(child, v2[v3]) -- inferred equivalent call
				SaveKeybinds() -- inferred equivalent call
			end), "Disconnect")
		end

		callback3(childName, v2[childName])
	end

	state.Parent = parent
	return function()
		maid:Cleanup()
	end
end