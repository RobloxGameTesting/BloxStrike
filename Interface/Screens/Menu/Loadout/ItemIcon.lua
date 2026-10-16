local ItemIcon = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
require(script.Parent:WaitForChild("Types"))
local WeaponDropShadows = require(ReplicatedStorage.Database.Custom.GameStats.UI.Inventory.WeaponDropShadows)
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local udim = UDim2.new(0, 0, -0.05, 0)

local function NormalizeAssetId(value: string?) -- 1 equivalent call inferred from this helper
	if typeof(value) == "string" and value ~= "" then
		return value:gsub("^rbxassetid://", "")
	end

	return nil
end

function ItemIcon.PreloadDropShadows()
	local weaponDropShadows = {}

	for _, weaponDropShadow in pairs(WeaponDropShadows) do
		table.insert(weaponDropShadows, weaponDropShadow)
	end

	ContentProvider:PreloadAsync(weaponDropShadows)
end

function ItemIcon.GetDropShadowImageForItem(p, value: string?)
	local assetId = NormalizeAssetId(value) -- inferred equivalent call
	return WeaponDropShadows[p.Name]
		or WeaponDropShadows[p.Skin]
		or value and WeaponDropShadows[value]
		or assetId and WeaponDropShadows[assetId]
end

function ItemIcon.CreateIconDropShadow(instance, image: string?, parent)
	if not image then
		return nil
	end

	local clone = instance:Clone()
	clone.Name = "DropShadow"
	clone.Image = image
	clone.ImageTransparency = 1
	clone.ZIndex = instance.ZIndex - 1
	clone.Parent = parent
	return clone
end

function ItemIcon.CreateIconHoverTweens(p, p2)
	local position = p.Position

	local function playHover()
		TweenService:Create(p, tweenInfo, {
			Position = UDim2.new(
				position.X.Scale + udim.X.Scale,
				position.X.Offset + udim.X.Offset,
				position.Y.Scale + udim.Y.Scale,
				position.Y.Offset + udim.Y.Offset
			)
		}):Play()

		if p2 then
			TweenService:Create(p2, tweenInfo, { ImageTransparency = 0.3 }):Play()
		end
	end

	local function playUnhover()
		TweenService:Create(p, tweenInfo, { Position = position }):Play()

		if p2 then
			TweenService:Create(p2, tweenInfo, { ImageTransparency = 1 }):Play()
		end
	end

	return playHover, playUnhover
end

return ItemIcon