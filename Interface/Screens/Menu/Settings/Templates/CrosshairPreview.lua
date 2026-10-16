local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ActivateButton = require(ReplicatedStorage.Components.Common.InterfaceAnimations.ActivateButton)
require(script.Parent.Parent.Types)
local LocalPlayer = Players.LocalPlayer
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local v = {}
local v2 = 1
local v3 = { "rbxassetid://99157237752211", "rbxassetid://123264229164215", "rbxassetid://93651340552187" }

local function applyOutline(p, flag: boolean, borderSizePixel: number) -- 2 equivalent calls inferred from this helper
	if not flag then
		p.BorderSizePixel = 0
		return
	end

	p.BorderSizePixel = borderSizePixel
	p.BorderColor3 = Color3.new(0, 0, 0)
end

local function updateCrosshairPreview(crosshair, data, value: number?)
	if not (data and crosshair.Visible and crosshair:IsDescendantOf(game)) then
		return
	end

	local v4 = value or 1
	local alpha = data.Alpha
	local v5 = (not alpha or type(alpha) ~= "table" or not alpha.Enabled or type(alpha.Value) ~= "number") and 1
		or alpha.Value / 255
	local red = data.Red or 0
	local green = data.Green or 255
	local blue = data.Blue or 0
	local color = Color3.fromRGB(tonumber(red) or 0, tonumber(green) or 255, tonumber(blue) or 0)
	local crosshairStyle = data["Crosshair Style"]
	local visible = crosshairStyle == "Image"
	local v6 = crosshairStyle == "Classic"
	local ticks = crosshair:FindFirstChild("Ticks")
	local dot = crosshair:FindFirstChild("Dot")
	local crosshair2 = crosshair:FindFirstChild("Crosshair")

	if not (ticks and dot and crosshair2) then
		return
	end

	ticks.Visible = not visible
	dot.Visible = not visible and data["Center Dot"] == true
	crosshair2.Visible = visible

	if visible then
		local v7 = "rbxassetid://" .. tostring(data["Crosshair Image"])
		local success, result = pcall(function()
			return v[data["Crosshair Image"]]
				or MarketplaceService:GetProductInfoAsync(tonumber(data["Crosshair Image"]), Enum.InfoType.Asset)
		end)

		if success then
			v[data["Crosshair Image"]] = result

			if result.AssetTypeId == 13 then
				v7 = `https://www.roblox.com/asset-thumbnail/image?assetId={data["Crosshair Image"]}&width=420&height=420&format=png`
			end
		end

		crosshair2.Image = type(v7) == "string" and v7 or "rbxassetid://00000000"
		crosshair2.ImageColor3 = color
		crosshair2.ImageTransparency = 1 - v5
	else
		local outline = data.Outline
		local v7, value2

		if outline and type(outline) == "table" then
			v7 = outline.Enabled == true
			value2 = tonumber(outline.Value) or 1
		else
			v7 = false
			value2 = 1
		end

		for _, childName in ipairs({ "Up", "Down", "Left", "Right" }) do
			local child = ticks:FindFirstChild(childName)

			if not child then
				continue
			end

			child.BackgroundColor3 = color
			child.BackgroundTransparency = 1 - v5
			child.Visible = true
			local length = tonumber(data.Length) or 5
			local thickness = tonumber(data.Thickness) or 1
			local v8 = 15 * (length / 5)
			local v9 = 2 * (thickness / 1)

			if childName == "Up" or childName == "Down" then
				child.Size = UDim2.new(0, v9, 0, v8)
			else
				child.Size = UDim2.new(0, v8, 0, v9)
			end

			applyOutline(child, v7, value2) -- inferred equivalent call
		end

		local up = ticks:FindFirstChild("Up")

		if up then
			up.Visible = data["T Style"] ~= true
		end

		if dot and data["Center Dot"] == true then
			dot.BackgroundColor3 = color
			dot.BackgroundTransparency = 1 - v5
			applyOutline(dot, v7, value2) -- inferred equivalent call
		end

		local v8 = 5 + (tonumber(data.Gap) or -1) * 5 / 5

		if v6 then
			v8 *= v4
		end

		local right = ticks:FindFirstChild("Right")
		local down = ticks:FindFirstChild("Down")
		local left = ticks:FindFirstChild("Left")
		local up2 = ticks:FindFirstChild("Up")

		if right then
			right.Position = UDim2.new(0.5, v8, 0.5, 0)
		end

		if down then
			down.Position = UDim2.new(0.5, 0, 0.5, v8)
		end

		if left then
			left.Position = UDim2.new(0.5, -v8, 0.5, 0)
		end

		if up2 then
			up2.Position = UDim2.new(0.5, 0, 0.5, -v8)
		end
	end
end

return function(parent, layoutOrder: number, instance, _, callback, _, _, _)
	instance.LayoutOrder = layoutOrder
	ActivateButton(instance.Left)
	ActivateButton(instance.Right)
	local clones = {}

	local function swapToIndex()
		for k, v4 in clones do
			v4.BackgroundColor3 = k == v2 and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(38, 38, 38)
		end

		instance.ImageLabel.Image = v3[v2]
	end

	for k, _ in v3 do
		local clone = ReplicatedStorage.Assets.UI.Settings.Dot:Clone()
		clone.LayoutOrder = k
		clone.Parent = instance.Switch
		clones[k] = clone
		ActivateButton(clone)
		local v4 = k
		clone.MouseButton1Click:Connect(function()
			v2 = v4
			swapToIndex()
		end)
	end

	instance.Left.Selectable = true
	instance.Right.Selectable = true
	instance.Left.Active = true
	instance.Right.Active = true
	instance.Left.Activated:Connect(function()
		local v4

		if v2 <= 1 then
			v4 = #v3
		else
			v4 = v2 - 1
		end

		v2 = v4
		swapToIndex()
	end)
	instance.Right.Activated:Connect(function()
		v2 = v2 >= #v3 and 1 or v2 + 1
		swapToIndex()
	end)
	swapToIndex()
	local maid = Janitor.new()
	maid:Add(instance, "Destroy")
	local crosshair = instance.Crosshair
	local total = 0
	local connection = nil

	local function isPreviewVisible()
		local scrollingFrame = instance:FindFirstAncestorOfClass("ScrollingFrame")

		if not (scrollingFrame and scrollingFrame:IsDescendantOf(LocalPlayer.PlayerGui)) then
			return false
		end

		local parent2 = instance

		while parent2 and parent2 ~= LocalPlayer.PlayerGui do
			if parent2:IsA("GuiObject") and not parent2.Visible then
				return false
			else
				parent2 = parent2.Parent
			end
		end

		return true
	end

	local function stopPreviewUpdate() -- 2 equivalent calls inferred from this helper
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end

	local function updatePreviewStep(_: number, p: number)
		if isPreviewVisible() then
			local v4 = callback()

			if not v4 then
				return
			end

			local v5 = 1

			if v4["Crosshair Style"] == "Classic" then
				total += p
				v5 = math.max(math.sin(total * 3.141592653589793 * 2 * 0.25) * 2 + 1, 0.75)
			else
				total = 0
			end

			updateCrosshairPreview(crosshair, v4, v5)
		else
			stopPreviewUpdate() -- inferred equivalent call
		end
	end

	instance.Parent = parent

	local function syncPreviewUpdate() -- 2 equivalent calls inferred from this helper
		if isPreviewVisible() then
			if connection then
				return
			end

			connection = RunServiceController.BindToStepped(`UI.CrosshairPreview.{layoutOrder}`, updatePreviewStep)
			updatePreviewStep(0, 0)
		else
			stopPreviewUpdate() -- inferred equivalent call
		end
	end

	local connections = {}

	local function clearVisibilityConnections() -- 1 equivalent call inferred from this helper
		for _, connection2 in ipairs(connections) do
			connection2:Disconnect()
		end

		table.clear(connections)
	end

	local function refreshVisibilityConnections()
		clearVisibilityConnections() -- inferred equivalent call
		local parent2 = instance

		while parent2 and parent2 ~= LocalPlayer.PlayerGui do
			if parent2:IsA("GuiObject") then
				table.insert(connections, parent2:GetPropertyChangedSignal("Visible"):Connect(syncPreviewUpdate))
			end

			parent2 = parent2.Parent
		end
	end

	refreshVisibilityConnections()
	maid:Add(instance.AncestryChanged:Connect(function()
		refreshVisibilityConnections()
		syncPreviewUpdate() -- inferred equivalent call
	end), "Disconnect")
	maid:Add(clearVisibilityConnections, true)
	maid:Add(stopPreviewUpdate, true)
	syncPreviewUpdate() -- inferred equivalent call
	return function()
		maid:Cleanup()
	end
end