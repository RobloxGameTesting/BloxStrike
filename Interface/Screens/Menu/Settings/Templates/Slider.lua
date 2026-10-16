local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
require(script.Parent.Parent.Types)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
require(ReplicatedStorage.Database.Custom.GameStats.UI.Settings.Pages)
return function(name: string, data, parent, layoutOrder: number, instance, p: number, flag: boolean?, callback, p2: string)
	instance.Name = name
	instance.Left.Label.Text = data.DisplayName or name
	instance.LayoutOrder = layoutOrder
	local hasEnabledToggle = data.HasEnabledToggle or false
	local step = data.Step or 1
	local max = data.Max or 100
	local min = data.Min or 0
	local v = p
	local v2 = false
	local v3 = flag == nil or (flag or true)
	local maid = Janitor.new()
	maid:Add(instance, "Destroy")
	local container = instance.Right.Container
	local slider = container.Left.Slider
	local button = slider.Button
	local title = container.Container.Left.Title
	slider.AutoButtonColor = false
	slider.Active = false
	button.AutoButtonColor = false
	button.Active = false
	title.Selectable = true
	container.Active = false

	if instance:FindFirstChild("Check") and not hasEnabledToggle then
		instance.Check.Visible = false
	end

	local function FormatNumber(p3: number) -- 4 equivalent calls inferred from this helper
		local v4 = math.round(p3 * 100) / 100

		if v4 == math.floor(v4) then
			return (tostring((math.floor(v4))))
		end

		return string.format("%.2f", v4):gsub("%.?0+$", "")
	end

	local function UpdateSlider(value: number, flag2: boolean?, flag3: boolean?)
		local v4 = math.clamp(value, min, max)

		if flag3 then
			v4 = math.round(v4 / step) * step
		end

		v = v4
		local v5 = (v4 - min) / (max - min)
		slider.Bar.Size = UDim2.new(v5, 0, 1, 0)
		button.Position = UDim2.new(v5, 0, 0.5, 0)
		title.Text = FormatNumber(v4) -- inferred equivalent call

		if flag2 then
			callback(p2, name, v, true)
		end
	end

	local function UpdateSliderFromMouse(p3: number, flag2: boolean?) -- 3 equivalent calls inferred from this helper
		local x = slider.AbsolutePosition.X
		local x2 = slider.AbsoluteSize.X
		UpdateSlider(min + math.clamp((p3 - x) / x2, 0, 1) * (max - min), flag2, true)
	end

	local function CommitValue() -- 3 equivalent calls inferred from this helper
		if hasEnabledToggle then
			callback(p2, name, { Enabled = v3, Value = v }, false)
		else
			callback(p2, name, v, false)
		end
	end

	local function EndDrag(p3)
		if
			(p3.UserInputType == Enum.UserInputType.MouseButton1 or p3.UserInputType == Enum.UserInputType.Touch)
			and v2
		then
			v2 = false
			CommitValue() -- inferred equivalent call
		end
	end

	local v4 = math.clamp(v, min, max)
	v = v4
	local v5 = (v4 - min) / (max - min)
	slider.Bar.Size = UDim2.new(v5, 0, 1, 0)
	button.Position = UDim2.new(v5, 0, 0.5, 0)
	title.Text = FormatNumber(v4) -- inferred equivalent call
	maid:Add(slider.InputBegan:Connect(function(input)
		if
			(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and v3
		then
			v2 = true
			local guiInset = GuiService:GetGuiInset()
			UpdateSliderFromMouse(input.Position.X - guiInset.X, nil) -- inferred equivalent call
		end
	end), "Disconnect")
	maid:Add(slider.InputEnded:Connect(EndDrag), "Disconnect")
	maid:Add(button.InputBegan:Connect(function(input)
		if
			(input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
			and v3
		then
			v2 = true

			while task.wait(0.01) and v2 do
				local mouseLocation = UserInputService:GetMouseLocation()
				local guiInset = GuiService:GetGuiInset()
				UpdateSliderFromMouse(mouseLocation.X - guiInset.X, true) -- inferred equivalent call
			end
		end
	end), "Disconnect")
	maid:Add(button.InputEnded:Connect(EndDrag), "Disconnect")
	maid:Add(UserInputService.InputChanged:Connect(function(input)
		if
			v2
			and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
		then
			UpdateSliderFromMouse(input.Position.X, true) -- inferred equivalent call
		end
	end), "Disconnect")
	maid:Add(title.FocusLost:Connect(function()
		if not v3 then
			return
		end

		local text = tonumber(title.Text)

		if text then
			local v6 = math.clamp(text, min, max)
			v = v6
			local v7 = (v6 - min) / (max - min)
			slider.Bar.Size = UDim2.new(v7, 0, 1, 0)
			button.Position = UDim2.new(v7, 0, 0.5, 0)
			title.Text = FormatNumber(v6) -- inferred equivalent call
			CommitValue() -- inferred equivalent call
		else
			title.Text = FormatNumber(v) -- inferred equivalent call
		end
	end), "Disconnect")
	slider.Selectable = false
	container.SelectionGroup = true
	container.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	container.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	container.SelectionBehaviorUp = Enum.SelectionBehavior.Escape
	container.SelectionBehaviorDown = Enum.SelectionBehavior.Escape
	local thread = nil

	local function CancelPendingCommit() -- 2 equivalent calls inferred from this helper
		if thread then
			task.cancel(thread)
			thread = nil
		end
	end

	local function CommitValueSoon() -- 1 equivalent call inferred from this helper
		CancelPendingCommit() -- inferred equivalent call
		thread = task.delay(0.35, function()
			thread = nil
			CommitValue() -- inferred equivalent call
		end)
	end

	maid:Add(CancelPendingCommit, true)
	local v6 = 0
	local v7 = "DPad"
	local v8 = 0
	local thread2 = nil

	local function IsSliderSelected() -- 5 equivalent calls inferred from this helper
		local selectedObject = GuiService.SelectedObject
		return selectedObject == slider or selectedObject == title
	end

	local function IsDirectionHeld(p3: number)
		if v7 == "Stick" then
			return math.abs(v8) >= 0.5 and math.sign(v8) == p3
		else
			local dPadLeft

			if p3 < 0 then
				dPadLeft = Enum.KeyCode.DPadLeft
			else
				dPadLeft = Enum.KeyCode.DPadRight
			end

			for _, v9 in UserInputService:GetConnectedGamepads() do
				if UserInputService:IsGamepadButtonDown(v9, dPadLeft) then
					return true
				end
			end

			return false
		end
	end

	local function Nudge(p3: number, p4: number) -- 6 equivalent calls inferred from this helper
		UpdateSlider(v + p3 * p4, true, true)
		CommitValueSoon() -- inferred equivalent call
	end

	local function StopHold() -- 5 equivalent calls inferred from this helper
		v6 = 0

		if thread2 and coroutine.running() ~= thread2 then
			task.cancel(thread2)
		end

		thread2 = nil
	end

	local function StartHold(p3: number, p4: string) -- 1 equivalent call inferred from this helper
		StopHold() -- inferred equivalent call
		v6 = p3
		v7 = p4
		Nudge(p3, step) -- inferred equivalent call
		thread2 = task.spawn(function()
			task.wait(0.35)
			local v9 = math.max(step, (max - min) / 60)

			while v3 and v6 == p3 do
				if not (IsSliderSelected() and IsDirectionHeld(p3)) then -- inferred equivalent call
					break
				end

				Nudge(p3, v9) -- inferred equivalent call
				task.wait(0.05)
			end

			if v6 == p3 then
				v6 = 0
			end

			thread2 = nil
		end)
	end

	maid:Add(StopHold, true)
	maid:Add(UserInputService.InputBegan:Connect(function(input)
		if not (IsSliderSelected() and v3) or title:IsFocused() then -- inferred equivalent call
			return
		end

		if input.KeyCode == Enum.KeyCode.ButtonA and GuiService.SelectedObject == title then
			CancelPendingCommit() -- inferred equivalent call
			title:CaptureFocus()
		elseif input.KeyCode == Enum.KeyCode.DPadLeft then
			StopHold() -- inferred equivalent call
			v6 = -1
			v7 = "DPad"
			Nudge(step, -1) -- inferred equivalent call
			local v9 = -1
			thread2 = task.spawn(function()
				task.wait(0.35)
				local v10 = math.max(step, (max - min) / 60)

				while v3 and v6 == v9 do
					if not (IsSliderSelected() and IsDirectionHeld(v9)) then -- inferred equivalent call
						break
					end

					Nudge(v9, v10) -- inferred equivalent call
					task.wait(0.05)
				end

				if v6 == v9 then
					v6 = 0
				end

				thread2 = nil
			end)
		elseif input.KeyCode == Enum.KeyCode.DPadRight then
			StopHold() -- inferred equivalent call
			v6 = 1
			v7 = "DPad"
			Nudge(step, 1) -- inferred equivalent call
			local v9 = 1
			thread2 = task.spawn(function()
				task.wait(0.35)
				local v10 = math.max(step, (max - min) / 60)

				while v3 and v6 == v9 do
					if not (IsSliderSelected() and IsDirectionHeld(v9)) then -- inferred equivalent call
						break
					end

					Nudge(v9, v10) -- inferred equivalent call
					task.wait(0.05)
				end

				if v6 == v9 then
					v6 = 0
				end

				thread2 = nil
			end)
		end
	end), "Disconnect")
	maid:Add(UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick1 then
			return
		end

		local position = input.Position
		v8 = not (math.abs(position.X) > math.abs(position.Y)) and 0 or position.X
		local v9 = not (math.abs(v8) >= 0.5) and 0 or math.sign(v8)

		if v9 == 0 then
			if v7 == "Stick" and v6 ~= 0 then
				StopHold() -- inferred equivalent call
			end
		else
			if not IsSliderSelected() or not v3 or title:IsFocused() then -- inferred equivalent call
				return
			end

			if v6 ~= v9 or v7 ~= "Stick" then
				StartHold(v9, "Stick") -- inferred equivalent call
			end
		end
	end), "Disconnect")
	maid:Add(UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode ~= Enum.KeyCode.Thumbstick1 then
			return
		end

		v8 = 0

		if v7 == "Stick" and v6 ~= 0 then
			StopHold() -- inferred equivalent call
		end
	end), "Disconnect")

	if instance:FindFirstChild("Check") and hasEnabledToggle then
		instance.Check.ImageLabel.Visible = v3
		instance.Frame.TextBox.TextEditable = v3
		button.Active = v3
		slider.Active = v3
		instance.Slider.Bar.BackgroundTransparency = v3 and 0 or 0.5
		instance.Slider.Button.ImageTransparency = v3 and 0 or 0.5
		instance.Frame.TextBox.TextTransparency = v3 and 0 or 0.5
		instance.Slider.ImageTransparency = v3 and 0 or 0.5
		maid:Add(instance.Check.MouseButton1Click:Connect(function()
			v3 = not v3
			instance.Check.ImageLabel.Visible = v3
			slider.Active = v3
			button.Active = v3
			instance.Frame.TextBox.TextEditable = v3
			instance.Slider.ImageTransparency = v3 and 0 or 0.5
			instance.Slider.Bar.BackgroundTransparency = v3 and 0 or 0.5
			instance.Slider.Button.ImageTransparency = v3 and 0 or 0.5
			instance.Frame.TextBox.TextTransparency = v3 and 0 or 0.5
			callback(p2, name, { Enabled = v3, Value = v }, false)
		end), "Disconnect")
	end

	instance.Parent = parent
	return function()
		v2 = false
		maid:Cleanup()
	end
end