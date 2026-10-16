local PickupItem = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local Tips = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Tips)
local HoverBomb = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.HoverBomb)
local BuyMenuHint = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.BuyMenuHint)
require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Notification.Types)
local udim = UDim2.fromScale(0.9, 0.12)
local udim2 = UDim2.fromScale(0.225, 0.054)
local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local parent = nil
local v = nil
local vector = Vector2.new(0.5, 0.5)
local v2 = false
local connection = nil
local deadChangedConnection = nil
local childAddedConnection = nil

local function computePriority(instance, instance2)
	local character = LocalPlayer.Character

	if not (character and character.PrimaryPart) then
		return false
	end

	if instance:GetAttribute("HoveringState") == "Hovering" then
		return true
	end

	if not (instance2:GetAttribute("HoveringState") ~= "Hovering" and instance:GetAttribute("CanPickup") ~= false) then
		return false
	end

	if instance2:GetAttribute("CanPickup") == false then
		return true
	end

	if instance.PrimaryPart and instance2.PrimaryPart then
		return (character.PrimaryPart.Position - instance.PrimaryPart.Position).Magnitude < (character.PrimaryPart.Position - instance2.PrimaryPart.Position).Magnitude
	end

	return false
end

local function hasHoveredInteractables() -- 1 equivalent call inferred from this helper
	return #CollectionService:GetTagged("IsHoveringInteractable") > 0
end

local function createCard(button)
	local notification = ReplicatedStorage.Assets.UI.Notification
	local keybind = notification:FindFirstChild("Keybind") or notification:FindFirstChild("Default")

	if not (keybind and keybind:IsA("GuiObject")) then
		warn("[PickupItem]: ReplicatedStorage.Assets.UI.Notification has no \"Keybind\" template")
		return nil
	end

	local clone = keybind:Clone()
	clone.Name = "PickupItem"
	clone.LayoutOrder = -1
	clone.Visible = false
	vector = clone.AnchorPoint

	if not clone:FindFirstChild("Keybind") and button and button:IsA("ImageButton") then
		local clone2 = button:Clone()
		clone2.Name = "Keybind"
		clone2.AnchorPoint = Vector2.new(0, 0.5)
		clone2.Size = UDim2.fromScale(0.66, 0.66)
		clone2.SizeConstraint = Enum.SizeConstraint.RelativeYY
		clone2.Parent = clone
	end

	local textLabel = clone:FindFirstChild("TextLabel")

	if textLabel and textLabel:IsA("TextLabel") then
		textLabel.RichText = true
		textLabel.TextWrapped = false
		textLabel.TextScaled = false
	end

	return clone
end

local function paintAccent() -- 1 equivalent call inferred from this helper
	local v3 = v

	if not v3 then
		return
	end

	local backgroundColor = GetPreferenceColor()
	v3.Left.BackgroundColor3 = backgroundColor
	v3.Right.BackgroundColor3 = backgroundColor
end

local function refreshKeybind() -- 1 equivalent call inferred from this helper
	local keybind = v and v:FindFirstChild("Keybind")

	if keybind and keybind:IsA("ImageButton") then
		keybind.Visible = Tips.ApplyBindingToKeybind(keybind, Tips.ResolveActionBinding("Use"))
	end
end

local function setCardShown(visible: boolean)
	local canvasGroup = v

	if not canvasGroup or visible == v2 then
		return
	end

	v2 = visible
	canvasGroup.Visible = visible

	if not visible then
		return
	end

	paintAccent() -- inferred equivalent call

	if canvasGroup:IsA("CanvasGroup") then
		canvasGroup.GroupTransparency = 1
		TweenService:Create(canvasGroup, tweenInfo, { GroupTransparency = 0 }):Play()
	end
end

local function placeCard(p) -- 1 equivalent call inferred from this helper
	local parent2 = parent

	if not parent2 then
		return
	end

	local floatingSlot = BuyMenuHint.GetFloatingSlot()

	if floatingSlot then
		p.Parent = parent2
		p.AnchorPoint = Vector2.new(0.5, 1)
		p.Position = floatingSlot
		p.Size = udim2
	else
		local notification = parent2:FindFirstChild("Notification")

		if notification then
			p.Parent = notification
			p.AnchorPoint = vector
			p.Size = udim
		end
	end
end

local object = setmetatable({}, { __mode = "k" })

local function layoutCard(instance)
	local x = instance.AbsoluteSize.X

	if x <= 0 then
		return
	end

	local textLabel = instance.TextLabel
	local keybind = instance:FindFirstChild("Keybind")
	local visible

	if keybind == nil then
		visible = false
	else
		visible = keybind:IsA("GuiObject") and keybind.Visible
	end

	local v3 = not visible and 0 or keybind.AbsoluteSize.X / x
	local v4 = visible and 0.02 or 0
	local v5 = 0.88 - v3 - v4
	textLabel.Size = UDim2.fromScale(v5, 1)
	local y = instance.AbsoluteSize.Y
	local room = v5 * x
	local v6 = object[instance]

	if v6 and v6.Text == textLabel.Text and v6.Height == y and v6.Room == room then
		if textLabel.TextSize ~= v6.Size then
			textLabel.TextSize = v6.Size
		end
	else
		textLabel.TextSize = math.max(math.floor(y * 0.7), 8)

		if room < textLabel.TextBounds.X then
			textLabel.TextSize = math.max(math.floor(textLabel.TextSize * room / textLabel.TextBounds.X), 8)
		end

		object[instance] = {
			Text = textLabel.Text,
			Height = y,
			Room = room,
			Size = textLabel.TextSize
		}
	end

	local v7 = math.min(textLabel.TextBounds.X / x, v5)
	local v8 = 0.5 - (v3 + v4 + v7) / 2

	if visible then
		keybind.Position = UDim2.fromScale(v8 + v3 * keybind.AnchorPoint.X, 0.5)
	end

	textLabel.Position = UDim2.fromScale(v8 + v3 + v4 + v7 / 2, 0.5)
end

local function shouldRunUpdate() -- 8 equivalent calls inferred from this helper
	local aliveCharacter = CharacterResolver.isAliveCharacter(LocalPlayer.Character)

	if aliveCharacter then
		if LocalPlayer:GetAttribute("IsSpectating") == true then
			aliveCharacter = false
		else
			aliveCharacter = hasHoveredInteractables() -- inferred equivalent call
		end
	end

	return aliveCharacter
end

local function stopUpdateConnection() -- 8 equivalent calls inferred from this helper
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function syncUpdateConnection()
	if shouldRunUpdate() then -- inferred equivalent call
		if connection then
			return
		end

		connection = RunServiceController.BindToHeartbeat("UI.PickupItem.Update", function(p)
			if shouldRunUpdate() then -- inferred equivalent call
				PickupItem.Render(p)
				return
			end

			local v3 = v

			if v3 and v2 ~= false then
				v2 = false
				v3.Visible = false
			end

			stopUpdateConnection() -- inferred equivalent call
		end)
	else
		local v3 = v

		if v3 and v2 ~= false then
			v2 = false
			v3.Visible = false
		end

		stopUpdateConnection() -- inferred equivalent call
	end
end

local function trackCharacter(character)
	if deadChangedConnection then
		deadChangedConnection:Disconnect()
		deadChangedConnection = nil
	end

	if childAddedConnection then
		childAddedConnection:Disconnect()
		childAddedConnection = nil
	end

	if character then
		deadChangedConnection = character:GetAttributeChangedSignal("Dead"):Connect(syncUpdateConnection)
		childAddedConnection = character.ChildAdded:Connect(function(humanoid)
			if humanoid:IsA("Humanoid") then
				if shouldRunUpdate() then -- inferred equivalent call
					if connection then
						return
					end

					connection = RunServiceController.BindToHeartbeat("UI.PickupItem.Update", function(p)
						if shouldRunUpdate() then -- inferred equivalent call
							PickupItem.Render(p)
							return
						end

						local v3 = v

						if v3 and v2 ~= false then
							v2 = false
							v3.Visible = false
						end

						stopUpdateConnection() -- inferred equivalent call
					end)
				else
					local v3 = v

					if v3 and v2 ~= false then
						v2 = false
						v3.Visible = false
					end

					stopUpdateConnection() -- inferred equivalent call
				end
			end
		end)
	end

	if shouldRunUpdate() then -- inferred equivalent call
		if connection then
			return
		end

		connection = RunServiceController.BindToHeartbeat("UI.PickupItem.Update", function(p)
			if shouldRunUpdate() then -- inferred equivalent call
				PickupItem.Render(p)
				return
			end

			local v3 = v

			if v3 and v2 ~= false then
				v2 = false
				v3.Visible = false
			end

			stopUpdateConnection() -- inferred equivalent call
		end)
	else
		local v3 = v

		if v3 and v2 ~= false then
			v2 = false
			v3.Visible = false
		end

		stopUpdateConnection() -- inferred equivalent call
	end
end

function PickupItem.Render(_)
	local v3 = v

	if not v3 then
		return
	end

	if HoverBomb.GetHoverState() then
		local v4 = v

		if v4 then
			if v2 == false then
				return
			end

			v2 = false
			v4.Visible = false
		end
	else
		local tagged = CollectionService:GetTagged("IsHoveringInteractable")
		table.sort(tagged, computePriority)
		local v4 = tagged[1]

		if v4 then
			local weapon = v4:GetAttribute("Weapon")
			local skin = v4:GetAttribute("Skin")
			local skinDisplayName = GetSkinDisplayName(skin)
			local nameTag = v4:GetAttribute("NameTag")
			local formatNameLabelText = GetSkinDisplayName.FormatNameLabelText(
				GetSkinDisplayName.GetWeaponDisplayName(weapon, nameTag),
				nameTag
			)
			local skinInformation = Skins.GetSkinInformation(weapon, skin)
			assert(skinInformation, "Skin data not found for weapon: " .. weapon .. " and skin: " .. skin)
			local rarity = Rarities[skinInformation.rarity]
			local v5 = math.floor(rarity.Color.R * 255)
			local v6 = math.floor(rarity.Color.G * 255)
			local v7 = math.floor(rarity.Color.B * 255)
			local textLabel = v3.TextLabel
			local text

			if weapon == "C4" then
				text = `Pick up <font color = "rgb({v5}, {v6}, {v7})"><b>C4</b></font>`
			else
				text = `Swap for <font color = "rgb({v5}, {v6}, {v7})"><b>{formatNameLabelText} | {skinDisplayName}</b></font>`
			end

			textLabel.Text = text
			placeCard(v3) -- inferred equivalent call
			setCardShown(true)
			layoutCard(v3)
		else
			local v5 = v

			if v5 then
				if v2 == false then
					return
				end

				v2 = false
				v5.Visible = false
			end
		end
	end
end

function PickupItem.Initialize(_, instance)
	parent = instance.Parent
	instance.Visible = false
	v = createCard(instance:FindFirstChild("Keybind"))
	CollectionService:GetInstanceAddedSignal("IsHoveringInteractable"):Connect(syncUpdateConnection)
	CollectionService:GetInstanceRemovedSignal("IsHoveringInteractable"):Connect(syncUpdateConnection)
	LocalPlayer:GetAttributeChangedSignal("IsSpectating"):Connect(syncUpdateConnection)
	LocalPlayer.CharacterAdded:Connect(trackCharacter)
	LocalPlayer.CharacterRemoving:Connect(function()
		if deadChangedConnection then
			deadChangedConnection:Disconnect()
			deadChangedConnection = nil
		end

		if childAddedConnection then
			childAddedConnection:Disconnect()
			childAddedConnection = nil
		end

		if shouldRunUpdate() then -- inferred equivalent call
			if connection then
				return
			end

			connection = RunServiceController.BindToHeartbeat("UI.PickupItem.Update", function(p)
				if shouldRunUpdate() then -- inferred equivalent call
					PickupItem.Render(p)
					return
				end

				local v3 = v

				if v3 and v2 ~= false then
					v2 = false
					v3.Visible = false
				end

				stopUpdateConnection() -- inferred equivalent call
			end)
		else
			local v3 = v

			if v3 and v2 ~= false then
				v2 = false
				v3.Visible = false
			end

			stopUpdateConnection() -- inferred equivalent call
		end
	end)
	trackCharacter(LocalPlayer.Character)
	DataController.CreateListener(LocalPlayer, "Settings.Keyboard/Mouse", refreshKeybind)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(refreshKeybind)
	refreshKeybind() -- inferred equivalent call
	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", paintAccent)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(paintAccent)
end

return PickupItem