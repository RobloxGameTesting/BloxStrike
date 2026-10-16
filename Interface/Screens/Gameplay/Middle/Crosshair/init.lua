local createVector = vector.create
local Crosshair = {}
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local InventoryController = require(ReplicatedStorage.Controllers.InventoryController)
local CameraController = require(ReplicatedStorage.Controllers.CameraController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Remotes = require(ReplicatedStorage.Database.Security.Remotes)
local CurrentCamera = Workspace.CurrentCamera
local Settings = require(script:WaitForChild("Settings"))
local v = {}
local v2 = { "Up", "Down", "Left", "Right" }
local parent2 = nil
local innerTicks = nil

local function rotationToPx(value) -- 2 equivalent calls inferred from this helper
	local viewportSize = CurrentCamera.ViewportSize
	local maxAxisFieldOfView, fieldOfView

	if viewportSize.X > viewportSize.Y then
		maxAxisFieldOfView = CurrentCamera.MaxAxisFieldOfView
		fieldOfView = CurrentCamera.FieldOfView
	else
		maxAxisFieldOfView = CurrentCamera.FieldOfView
		fieldOfView = CurrentCamera.MaxAxisFieldOfView
	end

	if typeof(value) == "number" then
		return value / fieldOfView * viewportSize.Y
	end

	return value / Vector2.new(maxAxisFieldOfView, fieldOfView) * viewportSize
end

local function shouldShowCrosshair(p) -- 1 equivalent call inferred from this helper
	local showCrosshair = p.Properties.ShowCrosshair
	local parent = parent2.Parent
	return showCrosshair
		and not parent.TeamSelection.Visible
		and not (parent.Leaderboard.Visible or parent.EndScreen.Visible or parent.BuyMenu.Visible or p.IsAiming)
end

local function calculateBloomScaleFromSpread(p: number) -- 2 equivalent calls inferred from this helper
	return rotationToPx(math.clamp(p / 2, 0, 30)) / 15 + 1 -- inferred equivalent call
end

local function getCrosshairDisplayState(object)
	if object and object.getCrosshairDisplayState then
		return object:getCrosshairDisplayState()
	end

	return nil
end

local function getDisplayedOuterSpread(object, p) -- 1 equivalent call inferred from this helper
	if p and type(p.OuterSpread) == "number" then
		return p.OuterSpread
	end

	if object.getSpread then
		return object:getSpread() or 0
	end

	return 0
end

local function getDynamicSpreadPixels(p: number) -- 2 equivalent calls inferred from this helper
	return (math.max(0, (p - 1) * 15))
end

local function getConfiguredGapPixels(gap: number?) -- 3 equivalent calls inferred from this helper
	return (gap or Settings.Gap) * 5 / 5
end

local function getRestingGapPixels(p)
	local configuredGapPixels = getConfiguredGapPixels(p and p.Gap) -- inferred equivalent call

	if p and p["Crosshair Style"] == "Classic" then
		return configuredGapPixels
	end

	return configuredGapPixels + 5
end

local v3 = nil

local function getRecoilAssistScale()
	if v3 then
		return v3.GetRecoilAssistScale()
	end

	local success, result = pcall(function()
		return require(ReplicatedStorage.Controllers.AimAssistController)
	end)

	if not success then
		return createVector(1, 1, 1)
	end

	v3 = result
	return v3.GetRecoilAssistScale()
end

local function calculateRecoilOffset(p)
	if not (p.Recoil and p.Properties and p.Properties.Recoil and Settings["Follow Recoil"]) then
		return UDim2.new()
	end

	local v4 = 1 - p.Properties.Recoil.CameraScale
	local weaponKickRotation = CameraController.getWeaponKickRotation()
	local rotationValue = p.Recoil.RotationValue
	local v5

	if v3 then
		v5 = v3.GetRecoilAssistScale()
	else
		local success, result = pcall(function()
			return require(ReplicatedStorage.Controllers.AimAssistController)
		end)

		if success then
			v3 = result
			v5 = v3.GetRecoilAssistScale()
		else
			v5 = createVector(1, 1, 1)
		end
	end

	local v6 = rotationValue * v5
	local v7 = rotationToPx(Vector2.new(v6.Y - weaponKickRotation.Y, v6.X - weaponKickRotation.X) * 57.29577951308232) * Vector2.new(CameraController.getAspectRatioStretch(), 1) * -v4 / CurrentCamera.ViewportSize -- inferred equivalent call
	return UDim2.fromScale(v7.X, v7.Y)
end

local function updateAutomaticScope(object, udim: UDim2)
	if not object.IsAiming or object.Properties.AimingOptions ~= "AutomaticScope" or not object.getBaseSpread then
		return
	end

	local scopeReticlePart = object.Viewmodel.Bobble.ScopeReticlePart

	if not scopeReticlePart then
		return
	end

	local v4 = object:getBaseSpread() or 0
	local frame = scopeReticlePart.SurfaceGui.Frame.Frame
	local v5 = math.tan((math.rad(CurrentCamera.FieldOfView / 2))) * 2 * 0.15
	local viewportSize = CurrentCamera.ViewportSize
	local v6 = viewportSize.X / viewportSize.Y / CameraController.getAspectRatioStretch() * v5 / 0.15
	local v7 = v5 / 0.15
	local v8 = math.clamp(v4, 0, 2) * 2
	frame.Size = UDim2.fromScale(v8 + 2.5, v8 + 2.5)
	frame.Position = UDim2.fromScale(0.5, 0.5) + UDim2.new(udim.X.Scale * v6, 0, udim.Y.Scale * v7, 0)
end

local function updateTickPositions(data, p: number, p2, value: number?)
	if not data then
		return
	end

	local configuredGapPixels = getConfiguredGapPixels(p2 and p2.Gap) -- inferred equivalent call

	if not p2 or p2["Crosshair Style"] ~= "Classic" then
		configuredGapPixels += 5
	end

	local v4 = configuredGapPixels + (value or 0) + (p - 1) * 15
	data.Right.Position = UDim2.new(0.5, v4, 0.5, 0)
	data.Down.Position = UDim2.new(0.5, 0, 0.5, v4)
	data.Left.Position = UDim2.new(0.5, -v4, 0.5, 0)
	data.Up.Position = UDim2.new(0.5, 0, 0.5, -v4)
end

local function resetTickPositions(p, p2) -- 4 equivalent calls inferred from this helper
	updateTickPositions(p, 1, p2)
end

local function applyTickVisuals(innerTicks2, color: Color3, p: number, data, p2: number)
	if not innerTicks2 then
		return
	end

	for _, childName in ipairs(v2) do
		local child = innerTicks2:FindFirstChild(childName)

		if not child then
			continue
		end

		child.BackgroundColor3 = color
		child.BackgroundTransparency = 1 - p
		child.Visible = childName ~= "Up" or not data["T Style"]
		local v4 = 15 * (data.Length / 5) * p2
		local v5 = 2 * (data.Thickness / 1)

		if childName == "Up" or childName == "Down" then
			child.Size = UDim2.new(0, v5, 0, v4)
		else
			child.Size = UDim2.new(0, v4, 0, v5)
		end

		if data.Outline.Enabled then
			child.BorderSizePixel = data.Outline.Value
			child.BorderColor3 = Color3.new(0, 0, 0)
		else
			child.BorderSizePixel = 0
		end
	end
end

local function hideTickFrames(instance)
	if not instance then
		return
	end

	for _, frame in pairs(instance:GetChildren()) do
		if frame:IsA("Frame") then
			frame.Visible = false
		end
	end
end

function Crosshair.ResetCrosshair()
	if not parent2 then
		return
	end

	parent2.Position = UDim2.fromScale(0.5, 0.5)
	resetTickPositions(parent2.Ticks, Settings) -- inferred equivalent call
	resetTickPositions(innerTicks, Settings) -- inferred equivalent call
	local currentEquipped = InventoryController.getCurrentEquipped()

	if not currentEquipped or typeof(currentEquipped) ~= "table" then
		return
	end

	if
		currentEquipped.IsAiming
		and currentEquipped.Properties
		and currentEquipped.Properties.AimingOptions == "AutomaticScope"
	then
		local viewmodel = currentEquipped.Viewmodel

		if viewmodel and viewmodel.Bobble then
			local scopeReticlePart = viewmodel.Bobble.ScopeReticlePart
			local frame = scopeReticlePart
				and scopeReticlePart.SurfaceGui
				and scopeReticlePart.SurfaceGui.Frame
				and scopeReticlePart.SurfaceGui.Frame:FindFirstChild("Frame")

			if frame then
				frame.Position = UDim2.fromScale(0.5, 0.5)
				frame.Size = UDim2.fromScale(2.5, 2.5)
			end
		end
	end

	local recoil = currentEquipped.Recoil

	if recoil then
		recoil.Value = Vector2.zero
		recoil.RecoveryStartTime = 0
		recoil.Time = 0
		recoil.RotationValue = createVector(0, 0, 0)
	end
end

function Crosshair.UpdateCrosshair(_: number)
	local isSpectating = LocalPlayer:GetAttribute("IsSpectating") == true
	local v4 = false
	local v5 = nil

	if isSpectating then
		local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
		local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()

		if
			currentSpectateInstance
			and not currentSpectateInstance.IsBot
			and Settings["Show Player Crosshairs"] == true
		then
			v5 = DataController.Get(currentSpectateInstance.Player, "Settings.Game.Crosshair")

			if v5 then
				v4 = true
			end
		end

		if
			currentSpectateInstance
			and currentSpectateInstance.PerspectiveState == "First-Person"
			and currentSpectateInstance.CurrentEquipped
		then
			local name = currentSpectateInstance.CurrentEquipped.Name
			local v6 = name == "AWP" or name == "SSG 08"
			local v7 = name == "AUG" or name == "SG 553"
			local v8 = (currentSpectateInstance.Player:GetAttribute("ScopeIncrement") or 0) > 0

			if v6 or v7 and v8 then
				parent2.Visible = false
				hideTickFrames(parent2.Ticks)
				hideTickFrames(innerTicks)

				if parent2.Dot then
					parent2.Dot.Visible = false
				end

				if parent2.Crosshair then
					parent2.Crosshair.Visible = false
				end

				return
			else
				local v9 = v4 and v5 or Settings
				local visible = v9["Crosshair Style"] == "Image"

				if parent2.Ticks then
					parent2.Ticks.Visible = not visible

					for _, frame in pairs(parent2.Ticks:GetChildren()) do
						if frame:IsA("Frame") then
							frame.Visible = true
						end
					end
				end

				if parent2.Dot then
					parent2.Dot.Visible = not visible and v9["Center Dot"]
				end

				if parent2.Crosshair then
					parent2.Crosshair.Visible = visible
				end
			end
		elseif currentSpectateInstance and currentSpectateInstance.PerspectiveState == "First-Person" then
			parent2.Visible = true
		end
	end

	local character = LocalPlayer.Character
	local currentEquipped = InventoryController.getCurrentEquipped()
	local v6 = isSpectating and not currentEquipped and {
		Properties = { ShowCrosshair = true, AimingOptions = "None" },
		IsAiming = false
	} or currentEquipped

	if not (isSpectating or character and v6) then
		return
	end

	local v7 = v4 and v5 or Settings
	local v8 = not v7.Alpha.Enabled and 1 or v7.Alpha.Value / 255 or 1
	local color = Color3.fromRGB(v7.Red, v7.Green, v7.Blue)
	local v9

	if v7["Crosshair Style"] == "Classic" and v6 and v6.getCrosshairDisplayState then
		v9 = v6:getCrosshairDisplayState()
	end

	local visible = v7["Crosshair Style"] == "Image"
	local visible2 = not visible
	local visible3 = false
	parent2.Dot.Visible = not visible and v7["Center Dot"]
	parent2.Crosshair.Visible = visible

	if visible then
		local image = "rbxassetid://" .. tostring(v7["Crosshair Image"])
		local success, result = pcall(function()
			return v[v7["Crosshair Image"]]
				or MarketplaceService:GetProductInfoAsync(tonumber(v7["Crosshair Image"]), Enum.InfoType.Asset)
		end)

		if success then
			v[v7["Crosshair Image"]] = result

			if result.AssetTypeId == 13 then
				image = `https://www.roblox.com/asset-thumbnail/image?assetId={v7["Crosshair Image"]}&width=420&height=420&format=png`
			end
		end

		parent2.Crosshair.Image = image
		parent2.Crosshair.ImageColor3 = color
		parent2.Crosshair.ImageTransparency = 1 - v8
	else
		local v10 = v8 * 1
		local v11 = v8 * 0.5
		local ticks = parent2.Ticks

		if v7["Crosshair Style"] ~= "Classic" then
			v11 = v8
		end

		applyTickVisuals(ticks, color, v11, v7, v7["Crosshair Style"] == "Classic" and 0.35 or 1)
		applyTickVisuals(innerTicks, color, v10, v7, 0.65)

		if parent2.Dot and v7["Center Dot"] then
			parent2.Dot.BackgroundColor3 = color
			parent2.Dot.BackgroundTransparency = 1 - v8

			if v7.Outline.Enabled then
				parent2.Dot.BorderSizePixel = v7.Outline.Value
				parent2.Dot.BorderColor3 = Color3.new(0, 0, 0)
			else
				parent2.Dot.BorderSizePixel = 0
			end
		end
	end

	parent2.Visible = shouldShowCrosshair(v6) -- inferred equivalent call
	local udim = UDim2.new()
	local v10 = 1

	if parent2.Visible or v6.Properties.AimingOptions == "AutomaticScope" then
		if v7["Crosshair Style"] == "Classic" then
			v10 = calculateBloomScaleFromSpread(getDisplayedOuterSpread(v6, v9)) -- inferred equivalent call
		end

		udim = calculateRecoilOffset(v6)
	end

	updateAutomaticScope(v6, udim)
	parent2.Position = UDim2.fromScale(0.5, 0.5) + udim

	if not visible then
		if v7["Crosshair Style"] == "Classic" then
			local dynamicSpreadPixels = getDynamicSpreadPixels(v10) -- inferred equivalent call
			local innerSpread = v9 and v9.InnerSpread
			local v11

			if type(innerSpread) == "number" then
				v11 = getDynamicSpreadPixels(calculateBloomScaleFromSpread(innerSpread)) -- inferred equivalent call
			else
				v11 = math.min(dynamicSpreadPixels, 7)
			end

			local configuredGapPixels = getConfiguredGapPixels(v7 and v7.Gap) -- inferred equivalent call

			if not v7 or v7["Crosshair Style"] ~= "Classic" then
				configuredGapPixels += 5
			end

			local v12 = v7["Center Dot"] and configuredGapPixels + v11 <= 0
			local v13 = v7["Center Dot"] and configuredGapPixels + dynamicSpreadPixels <= 0
			visible3 = not v12

			if innerTicks and not v12 then
				updateTickPositions(innerTicks, v11 / 15 + 1, v7)
			end

			if v13 then
				resetTickPositions(parent2.Ticks, v7) -- inferred equivalent call
				visible2 = false
			else
				updateTickPositions(parent2.Ticks, dynamicSpreadPixels / 15 + 1, v7)
				visible2 = true
			end
		else
			visible2 = true
			updateTickPositions(parent2.Ticks, v10, v7)

			if innerTicks then
				resetTickPositions(innerTicks, v7) -- inferred equivalent call
			end
		end
	end

	parent2.Ticks.Visible = visible2

	if innerTicks then
		innerTicks.Visible = visible3
	end
end

function Crosshair.Initialize(_, p)
	parent2 = p
	innerTicks = parent2:FindFirstChild("InnerTicks")

	if not innerTicks and parent2.Ticks then
		local clone = parent2.Ticks:Clone()
		clone.Name = "InnerTicks"
		clone.Visible = false
		clone.Parent = parent2
		innerTicks = clone
	end

	DataController.CreateListener(LocalPlayer, "Settings.Game.Crosshair", function(p2)
		Settings = p2
		task.delay(0.1, function()
			Crosshair.UpdateCrosshair(0)
		end)
	end)
	RunServiceController.BindToRenderStep("UI.Crosshair.Update", Crosshair.UpdateCrosshair)
	Remotes.Character.CharacterDied.Listen(Crosshair.ResetCrosshair)
end

return Crosshair