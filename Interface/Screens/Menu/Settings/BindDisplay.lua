local BindDisplay = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetBindIcon = require(ReplicatedStorage.Components.Common.GetBindIcon)
local KeybindParser = require(ReplicatedStorage.Controllers.InputController.KeybindParser)
local color = Color3.fromRGB(255, 90, 90)
local color2 = Color3.fromRGB(255, 255, 255)

function BindDisplay.GetTextBox(instance)
	local textBox = instance:FindFirstChild("TextBox", true)

	if textBox and textBox:IsA("TextBox") then
		return textBox
	end

	return nil
end

function BindDisplay.GetIcon(instance)
	local bind = instance:FindFirstChild("Bind", true)

	if bind and bind:IsA("ImageLabel") then
		return bind
	end

	return nil
end

function BindDisplay.GetReset(instance)
	local reset = instance:FindFirstChild("Reset", true)

	if reset and reset:IsA("GuiObject") then
		return reset
	end

	return nil
end

function BindDisplay.FormatText(value: string)
	if value == "" then
		return ""
	end

	return value:gsub("Enum%.KeyCode%.", ""):gsub("Enum%.UserInputType%.", ""):gsub("Enum%.CustomInputType%.", "")
end

function BindDisplay.GetIconImage(p: string)
	if p == "" then
		return nil
	end

	local parsed = KeybindParser.parse(p)

	if typeof(parsed) == "EnumItem" then
		return GetBindIcon(parsed)
	end

	return nil
end

function BindDisplay.Apply(p, p2: string)
	local textBox = BindDisplay.GetTextBox(p)

	if not textBox then
		return
	end

	local v = p2 == ""
	local iconImage = BindDisplay.GetIconImage(p2)
	local icon = BindDisplay.GetIcon(p)

	if icon then
		icon.Image = iconImage or ""
		icon.ImageColor3 = color2
		icon.Visible = iconImage ~= nil
	end

	local v2

	if icon == nil then
		v2 = false
	else
		v2 = iconImage ~= nil
	end

	textBox.TextEditable = false
	textBox.Active = true
	textBox.PlaceholderText = v and "None" or ""
	textBox.Text = (v or v2) and "" or BindDisplay.FormatText(p2)
	local reset = BindDisplay.GetReset(p)

	if reset then
		reset.Visible = not v
	end
end

function BindDisplay.HideIcon(p)
	local icon = BindDisplay.GetIcon(p)

	if icon then
		icon.Visible = false
	end
end

function BindDisplay.SetConflict(p, flag: boolean)
	local icon = BindDisplay.GetIcon(p)

	if icon then
		local imageColor

		if flag then
			imageColor = color
		else
			imageColor = color2
		end

		icon.ImageColor3 = imageColor
	end
end

return BindDisplay