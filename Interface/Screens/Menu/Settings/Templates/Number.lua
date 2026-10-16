local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Parent.Types)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
require(ReplicatedStorage.Database.Custom.GameStats.UI.Settings.Pages)
return function(name: string, p, parent, layoutOrder: number, state, p2: number, callback, p3: string)
	state.Name = name
	state.Left.Label.Text = p.DisplayName or name
	state.LayoutOrder = layoutOrder
	local v = p2
	local maid = Janitor.new()
	maid:Add(state, "Destroy")

	local function FormatNumber(p4: number) -- 3 equivalent calls inferred from this helper
		return (tostring((math.floor(p4))))
	end

	local function UpdateValue(text: number) -- 1 equivalent call inferred from this helper
		v = math.floor(text)
		state.Right.Dropdown.Container.Left.Title.Text = FormatNumber(v) -- inferred equivalent call
	end

	v = math.floor(v)
	state.Right.Dropdown.Container.Left.Title.Text = FormatNumber(v) -- inferred equivalent call
	local title = state.Right.Dropdown.Container.Left.Title
	local dropdown = state.Right.Dropdown
	maid:Add(dropdown.MouseButton1Click:Connect(function()
		title:CaptureFocus()
	end), "Disconnect")
	maid:Add(dropdown.Activated:Connect(function()
		title:CaptureFocus()
	end), "Disconnect")
	maid:Add(state.Right.Dropdown.Container.Left.Title.FocusLost:Connect(function()
		local text = tonumber(state.Right.Dropdown.Container.Left.Title.Text)

		if not text then
			state.Right.Dropdown.Container.Left.Title.Text = FormatNumber(v) -- inferred equivalent call
			return
		end

		UpdateValue(text) -- inferred equivalent call
		callback(p3, name, v)
	end), "Disconnect")
	state.Parent = parent
	return function()
		maid:Cleanup()
	end
end