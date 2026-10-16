local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local CommaNumber = require(script.Parent.CommaNumber)
local v = { Case = true, Package = true }

local function GetWearAbbreviation(float: number?, p)
	if typeof(float) ~= "number" or (typeof(p) ~= "table" or typeof(p.floatRange) ~= "table") then
		return nil
	end

	local _, v2 = Skins.GetWearNameForFloat(p, float)

	if typeof(v2) == "string" then
		return Skins.GetAbbreviatedWearName(v2)
	end

	return nil
end

return function(instance, data, p)
	local itemContent = instance:FindFirstChild("ItemContent")

	if not itemContent then
		return
	end

	local rarity = itemContent:FindFirstChild("Rarity")

	if not rarity then
		return
	end

	local text = GetWearAbbreviation(tonumber(data.Float), p)
	local condition = rarity:FindFirstChild("Condition")

	if condition and condition:IsA("ImageLabel") then
		for _, uiGradient in condition:GetChildren() do
			if uiGradient:IsA("UIGradient") then
				uiGradient.Enabled = false
			end
		end

		condition.Visible = text ~= nil

		if text then
			local wearAbbreviation = condition:FindFirstChild("WearAbbreviation")

			if wearAbbreviation and wearAbbreviation:IsA("TextLabel") then
				wearAbbreviation.Text = text
			end

			local uiGradient = condition:FindFirstChild(text .. "Gradient")

			if uiGradient and uiGradient:IsA("UIGradient") then
				uiGradient.Enabled = true
			end
		end
	end

	local serial = rarity:FindFirstChild("Serial")

	if serial and serial:IsA("ImageLabel") then
		local serial2

		if not v[data.Type] then
			serial2 = tonumber(data.Serial)
		end

		serial.Visible = serial2 ~= nil and serial2 > 0
		local serialText = serial:FindFirstChild("SerialText")

		if serialText and serialText:IsA("TextLabel") then
			if serial2 then
				serialText.Text = `#{CommaNumber(serial2)}`
			end

			serialText.Size = UDim2.fromScale(text and 0.557 or 1, serialText.Size.Y.Scale)
		end
	end
end