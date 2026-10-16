local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Parent.Types)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
require(ReplicatedStorage.Database.Custom.GameStats.UI.Settings.Pages)
local color = Color3.fromRGB(77, 77, 77)
local color2 = Color3.fromRGB(255, 255, 255)
local v = { "1", "2" }
return function(name: string, p, parent, layoutOrder: number, state, flag: boolean, callback, p2: string)
	state.Name = name
	state.Left.Label.Text = p.DisplayName or name
	state.LayoutOrder = layoutOrder
	local v2 = flag
	local maid = Janitor.new()
	maid:Add(state, "Destroy")
	local switch = state.Right.Switch
	local selection = switch.Selection
	local title = selection.Title
	local frame = selection:FindFirstChild("Frame")

	local function UpdateToggleVisual(flag2: boolean)
		title.Text = flag2 and "ON" or "OFF"

		if not frame then
			return
		end

		for i, childName in ipairs(v) do
			local guiObject = frame:FindFirstChild(childName)

			if not (guiObject and guiObject:IsA("GuiObject")) then
				continue
			end

			local backgroundColor

			if (i == 2) == flag2 then
				backgroundColor = color2
			else
				backgroundColor = color
			end

			guiObject.BackgroundColor3 = backgroundColor
		end
	end

	UpdateToggleVisual(v2)

	local function SetEnabled(flag2: boolean) -- 1 equivalent call inferred from this helper
		if flag2 == v2 then
			return
		end

		v2 = flag2
		UpdateToggleVisual(v2)
		callback(p2, name, v2)
	end

	local function Toggle()
		SetEnabled(not v2) -- inferred equivalent call
	end

	maid:Add(switch.MouseButton1Click:Connect(Toggle), "Disconnect")

	for _, childName in { "Left", "Right" } do
		local button = switch:FindFirstChild(childName)

		if button and button:IsA("GuiButton") then
			maid:Add(button.MouseButton1Click:Connect(Toggle), "Disconnect")
		end
	end

	state.Parent = parent
	return function()
		maid:Cleanup()
	end
end