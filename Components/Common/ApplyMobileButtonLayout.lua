local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.GameStats.UI.Mobile)

local function GetBaseline(instance, attributeName: string, p: number)
	local attribute = instance:GetAttribute(attributeName)

	if typeof(attribute) ~= "number" then
		instance:SetAttribute(attributeName, p)
		attribute = p
	end

	return attribute
end

local function BlendProperty(instance, attributeName: string, p: string, p2: number) -- 6 equivalent calls inferred from this helper
	local v = instance[p]
	local attribute = instance:GetAttribute(attributeName)

	if typeof(attribute) == "number" then
		v = attribute
	else
		instance:SetAttribute(attributeName, v)
	end

	instance[p] = v + (1 - v) * p2
end

local function ApplyTransparency(folder, transparency: number)
	local v = math.clamp(transparency, 0, 1)

	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			BlendProperty(descendant, "_MobileHUDBaseImageTransparency", "ImageTransparency", v) -- inferred equivalent call
			BlendProperty(descendant, "_MobileHUDBaseBackgroundTransparency", "BackgroundTransparency", v) -- inferred equivalent call
		elseif descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
			BlendProperty(descendant, "_MobileHUDBaseTextTransparency", "TextTransparency", v) -- inferred equivalent call
			BlendProperty(descendant, "_MobileHUDBaseBackgroundTransparency", "BackgroundTransparency", v) -- inferred equivalent call
		elseif descendant:IsA("UIStroke") then
			BlendProperty(descendant, "_MobileHUDBaseImageTransparency", "Transparency", v) -- inferred equivalent call
		end
	end

	BlendProperty(folder, "_MobileHUDBaseBackgroundTransparency", "BackgroundTransparency", v) -- inferred equivalent call
end

return function(p, data)
	p.Position = UDim2.fromScale(data.Position.X, data.Position.Y)
	p.Size = UDim2.fromScale(data.Size.X, data.Size.Y)
	ApplyTransparency(p, data.Transparency)
end