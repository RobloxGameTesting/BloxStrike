local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Router = require(ReplicatedStorage.Database.Security.Router)
local frozen = table.freeze({ hoverSizeMultiplier = 1.1 })
local Out = Enum.EasingDirection.Out
local Quad = Enum.EasingStyle.Quad
local MarketplaceButton = {}
MarketplaceButton.__index = MarketplaceButton

local function isPointInGui(p, vector: Vector2) -- 1 equivalent call inferred from this helper
	local absolutePosition = p.AbsolutePosition
	local absoluteSize = p.AbsoluteSize
	return vector.X >= absolutePosition.X
		and vector.X <= absolutePosition.X + absoluteSize.X
		and vector.Y >= absolutePosition.Y
		and vector.Y <= absolutePosition.Y + absoluteSize.Y
end

local function isGuiVisible(parent)
	while parent do
		if parent:IsA("GuiObject") and not parent.Visible then
			return false
		end

		if parent:IsA("LayerCollector") and not parent.Enabled then
			return false
		else
			parent = parent.Parent
		end
	end

	return true
end

function MarketplaceButton:new(options)
	local clone = table.clone(options or {})

	for k, v in frozen do
		if clone[k] == nil then
			clone[k] = v
		end
	end

	local object = setmetatable({ Instance = self, _isHovering = false }, MarketplaceButton)
	local originalSize = self:GetAttribute("OriginalSize") or self.Size

	if self:GetAttribute("OriginalSize") then
		self.Size = originalSize
	else
		self:SetAttribute("OriginalSize", originalSize)
	end

	local udim = clone.hoverSizeMultiplier
		and UDim2.new(
			originalSize.X.Scale * clone.hoverSizeMultiplier,
			originalSize.X.Offset * clone.hoverSizeMultiplier,
			originalSize.Y.Scale * clone.hoverSizeMultiplier,
			originalSize.Y.Offset * clone.hoverSizeMultiplier
		)
	object._originalSize = originalSize
	object._hasHoverSize = udim ~= nil

	local function tweenSize(udim2: UDim2, callback, value: number?)
		self:TweenSize(udim2, Out, Quad, 0.15 * (value or 1), true, callback)
	end

	local function shouldRestoreHoverState()
		if not (object._isHovering and self:IsDescendantOf(game) and isGuiVisible(self)) then
			return false
		end

		local mouseLocation = UserInputService:GetMouseLocation()
		return isPointInGui(self, Vector2.new(mouseLocation.X, mouseLocation.Y)) -- inferred equivalent call
	end

	if udim or clone.onMouseEnter then
		object._mouseEnter = self.MouseEnter:Connect(function(p, p2)
			object._isHovering = true

			if udim then
				self:TweenSize(udim, Out, Quad, 0.15, true, nil)
			end

			if clone.onMouseEnter then
				clone.onMouseEnter(p, p2)
			end

			Router.broadcastRouter("RunInterfaceSound", "Button Hover")
		end)
	end

	if udim or clone.onMouseLeave then
		object._mouseLeave = self.MouseLeave:Connect(function(p, p2)
			object._isHovering = false

			if udim then
				self:TweenSize(originalSize, Out, Quad, 0.15, true, nil)
			end

			if clone.onMouseLeave then
				clone.onMouseLeave(p, p2)
			end
		end)
	end

	if clone.onActivated then
		object._activated = self.Activated:Connect(function()
			Router.broadcastRouter("RunInterfaceSound", "Button Click")

			if udim then
				self:TweenSize(originalSize, Out, Quad, 0.075, true, function()
					object._isHovering = shouldRestoreHoverState()

					if object._isHovering then
						self:TweenSize(udim, Out, Quad, 0.075, true, nil)
					end
				end)
			end

			local fullName = self:GetFullName()

			if
				fullName:find("GlobalMarketPlace")
				and not (fullName:find("Close") or fullName:find("Pin") or fullName:find("Top") or Players.LocalPlayer:GetAttribute("PinVerified"))
			then
				return
			end

			clone.onActivated()
		end)
	end

	object._destroying = self.Destroying:Once(function()
		object:Destroy()
	end)
	return object
end

function MarketplaceButton:Destroy()
	if self._hasHoverSize then
		self.Instance.Size = self._originalSize
	end

	for _, v in { "_mouseEnter", "_mouseLeave", "_activated", "_destroying" } do
		local connection = self[v]

		if connection then
			connection:Disconnect()
		end
	end
end

return MarketplaceButton