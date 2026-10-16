local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(script.Parent.Parent.Types)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
require(ReplicatedStorage.Database.Custom.GameStats.UI.Settings.Pages)
local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(255, 201, 14)

local function AnimateButton(p, flag: boolean)
	local textColor

	if flag then
		textColor = color2
	else
		textColor = color
	end

	p.TextColor3 = textColor
end

return function(name: string, p, parent, layoutOrder: number, instance, p2: string, callback, p3: string, instance2, callback2, callback3)
	local maid = Janitor.new()
	local text = p2
	instance:SetAttribute("IsDropdown", true)
	instance.LayoutOrder = layoutOrder
	instance.Left.Label.Text = p.DisplayName or name
	instance.Name = name
	local dropdownContent = instance.Right.Dropdown.DropdownContent
	local scroll = dropdownContent.Scroll
	local scale = dropdownContent.Size.Y.Scale
	instance.Right.Dropdown.Container.Left.Title.Text = text
	dropdownContent.Active = false
	dropdownContent.Visible = false
	scroll.Visible = false

	local function ClearOptions()
		maid:Cleanup()

		for _, button in ipairs(scroll:GetChildren()) do
			if button:IsA("TextButton") then
				button:Destroy()
			end
		end
	end

	local maid2 = Janitor.new()
	maid2:Add(instance, "Destroy")
	maid2:Add(ClearOptions)
	maid2:Add(instance.Right.Dropdown.MouseButton1Click:Connect(function()
		local v = callback2()
		local v2 = not scroll.Visible

		if v and v ~= scroll then
			v.Visible = false
			local parent2 = v.Parent

			if parent2 then
				parent2.Visible = false
			end

			for _, button in ipairs(v:GetChildren()) do
				if button:IsA("TextButton") then
					button:Destroy()
				end
			end
		end

		for _, child in ipairs(instance.Parent:GetChildren()) do
			if child:GetAttribute("IsDropdown") then
				child.ZIndex = v2 and child.Name == instance.Name and 125 or 15
			end
		end

		ClearOptions()

		if v2 and p.Enums then
			local v3 = math.min(#p.Enums, 7)

			for i, enum in ipairs(p.Enums) do
				local clone = instance2:WaitForChild("OptionTemplate"):Clone()
				clone.Size = UDim2.fromScale(1, 1 / v3)
				clone.Name = `Option_{enum}`
				clone.Frame.TextButton.Text = enum
				clone.LayoutOrder = i
				clone.Visible = true
				clone.Parent = scroll
				local v4 = instance.Right.Dropdown.Container.Left.Title.Text == enum
				clone.Frame.BackgroundTransparency = v4 and 0.3 or 1
				clone.TextColor3 = color
				maid:Add(clone.MouseEnter:Connect(function()
					clone.Frame.BackgroundTransparency = v4 and 0.3 or 0.65
				end), "Disconnect", `Option_{enum}_1`)
				maid:Add(clone.MouseLeave:Connect(function()
					clone.Frame.BackgroundTransparency = v4 and 0.3 or 1
				end), "Disconnect", `Option_{enum}_2`)
				local text2 = enum
				maid:Add(clone.MouseButton1Click:Connect(function()
					local v5

					if GuiService.SelectedObject == nil then
						v5 = false
					else
						v5 = GuiService.SelectedObject:IsDescendantOf(scroll)
					end

					text = text2
					instance.Right.Dropdown.Container.Left.Title.Text = text2
					scroll.Visible = false
					dropdownContent.Visible = false
					callback3(nil)
					callback(p3, name, text)
					ClearOptions()
					local dropdown = instance.Right.Dropdown

					if v5 and dropdown:IsDescendantOf(game) then
						GuiService.SelectedObject = dropdown
					end
				end), "Disconnect", `Option_{enum}_3`)
				maid:Add(clone, "Destroy")
			end

			dropdownContent.Size = UDim2.new(dropdownContent.Size.X, UDim.new(scale * v3 / 7, 0))
			dropdownContent.Visible = true
			scroll.Visible = true
			callback3(scroll)
		else
			scroll.Visible = false
			dropdownContent.Visible = false
			callback3(nil)
		end
	end), "Disconnect")
	instance.Parent = parent
	return function()
		maid:Cleanup()
		maid2:Cleanup()
	end
end