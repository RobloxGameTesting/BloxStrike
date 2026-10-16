local CloseButtonRegistry = {}
local UserInputService = game:GetService("UserInputService")
local v = {}
local v2 = {}
local now = 0

local function isOnScreen(parent)
	while parent do
		if parent:IsA("GuiObject") then
			if not parent.Visible then
				return false
			end
		elseif parent:IsA("LayerCollector") then
			return parent.Enabled
		end

		parent = parent.Parent
	end

	return false
end

function CloseButtonRegistry.IsDoublePressed()
	return tick() - now < 0.1
end

function CloseButtonRegistry.MarkUsed()
	now = tick()
end

function CloseButtonRegistry.Add(frame, closeButton, onClose)
	table.insert(v, { closeButton = closeButton, onClose = onClose, frame = frame })

	if not closeButton then
		return
	end

	closeButton.MouseButton1Click:Connect(function()
		onClose(frame, closeButton)
	end)
	closeButton.Activated:Connect(function(p)
		if p and p.UserInputType == Enum.UserInputType.Gamepad1 then
			onClose(frame, closeButton)
		end
	end)
end

function CloseButtonRegistry.Remove(p)
	for i = #v, 1, -1 do
		if v[i].frame == p then
			table.remove(v, i)
		end
	end
end

function CloseButtonRegistry.BringToFront(p)
	for i = #v, 1, -1 do
		if v[i].frame ~= p then
			continue
		end

		table.insert(v, (table.remove(v, i)))
		break
	end
end

function CloseButtonRegistry.AddHandler(isActive, onClose)
	table.insert(v2, { isActive = isActive, onClose = onClose })
end

function CloseButtonRegistry.CloseFrame()
	if CloseButtonRegistry.IsDoublePressed() then
		return true
	end

	for i = #v2, 1, -1 do
		local v3 = v2[i]

		if not v3.isActive() then
			continue
		end

		v3.onClose()
		now = tick()
		return true
	end

	for i = #v, 1, -1 do
		local v3 = v[i]

		if not isOnScreen(v3.frame) then
			continue
		end

		v3.onClose(v3.frame, v3.closeButton)
		now = tick()
		return true
	end

	return false
end

UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode == Enum.KeyCode.ButtonB then
		CloseButtonRegistry.CloseFrame()
	end
end)
return CloseButtonRegistry