local Resolve = {}

local function GetHorizontalPosition(p) -- 4 equivalent calls inferred from this helper
	return p.Position.X.Scale
end

function Resolve.Caption(instance)
	local left = instance:FindFirstChild("Left") or instance
	local label = left:FindFirstChild("Label")

	for _, label2 in ipairs(left:GetChildren()) do
		if not (label2:IsA("TextLabel") and (label == nil or GetHorizontalPosition(label2) < GetHorizontalPosition(label))) then -- inferred equivalent call
			continue
		end

		label = label2
	end

	return label
end

function Resolve.Value(instance)
	local left = instance:FindFirstChild("Left") or instance
	local value = left:FindFirstChild("Value")

	if value and value:IsA("TextLabel") then
		return value
	end

	local v = nil

	for _, label in ipairs(left:GetChildren()) do
		if not (label:IsA("TextLabel") and (v == nil or GetHorizontalPosition(label) > GetHorizontalPosition(v))) then -- inferred equivalent call
			continue
		end

		v = label
	end

	return v
end

function Resolve.Row(instance, childName: string, p: string)
	local guiObject = instance:FindFirstChild(childName)

	if guiObject and guiObject:IsA("GuiObject") then
		return guiObject
	end

	for _, guiObject2 in ipairs(instance:GetChildren()) do
		if not guiObject2:IsA("GuiObject") then
			continue
		end

		local caption = Resolve.Caption(guiObject2)

		if caption and string.upper(caption.Text) == p then
			return guiObject2
		end
	end

	return nil
end

function Resolve.SetRow(p, p2: string, text: string, text2: string)
	local row = Resolve.Row(p, p2, text)

	if not row then
		return
	end

	local caption = Resolve.Caption(row)
	local value = Resolve.Value(row)

	if caption and caption ~= value then
		caption.Text = text
	end

	if value then
		value.Text = text2
	end
end

return Resolve