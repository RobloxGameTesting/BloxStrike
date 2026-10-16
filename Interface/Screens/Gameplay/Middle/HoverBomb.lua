local HoverBomb = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local RunServiceController = require(ReplicatedStorage.Controllers.RunServiceController)
local Router = require(ReplicatedStorage.Database.Security.Router)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local IsTutorialMode = require(ReplicatedStorage.Components.Common.IsTutorialMode)
local Tips = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Tips)
local v = table.find(GetUserPlatform(), "Mobile") and #GetUserPlatform() <= 1
local v2 = nil
local flag = false
local v3 = nil
local connection = nil

local function IsCharacterAlive(localPlayer) -- 2 equivalent calls inferred from this helper
	return CharacterResolver.isAliveCharacter(localPlayer.Character)
end

local function GetPromptParts()
	if not v3 then
		return nil, nil
	end

	local textLabel = v3:FindFirstChild("TextLabel")
	local keybind = v3:FindFirstChild("Keybind")

	if textLabel and textLabel:IsA("TextLabel") then
		if not (keybind and keybind:IsA("ImageButton") and keybind) then
			keybind = nil
		end

		return textLabel, keybind
	else
		warn(`[HoverBomb]: {v3:GetFullName()} has no TextLabel child; the defuse prompt cannot render`)
		return nil, nil
	end
end

local function RefreshPrompt() -- 1 equivalent call inferred from this helper
	local v4, v5 = GetPromptParts()

	if not v4 then
		return
	end

	if v then
		v4.Text = "Hold to Defuse"

		if v5 then
			v5.Visible = false
		end
	else
		v4.Text = "Defuse Bomb"

		if v5 then
			v5.Visible = Tips.ApplyBindingToKeybind(v5, Tips.ResolveActionBinding("Use"))
		end
	end
end

local function LayoutKeybind()
	local v4, v5 = GetPromptParts()

	if not (v4 and v5) then
		return
	end

	local x = v3.AbsoluteSize.X

	if x <= 0 then
		return
	end

	local v6 = v4.TextBounds.X / x / 2
	v5.Position = UDim2.fromScale(v4.Position.X.Scale - v6 - 0.006, v4.Position.Y.Scale)
end

local function IsBombResolved(instance) -- 3 equivalent calls inferred from this helper
	if instance then
		return instance:GetAttribute("Defused") == true
			or instance:GetAttribute("Exploding") == true
			or instance:GetAttribute("Exploded") == true
	end

	return false
end

local function GetActiveBomb() -- 3 equivalent calls inferred from this helper
	local v4 = CollectionService:GetTagged("Bomb")[1]

	if v4 and not IsBombResolved(v4) then -- inferred equivalent call
		return v4
	end

	return nil
end

local function ShouldRunUpdate() -- 2 equivalent calls inferred from this helper
	return workspace:GetAttribute("Gamemode") == "Bomb Defusal"
		and LocalPlayer:GetAttribute("Team") == "Counter-Terrorists"
		and GetActiveBomb() ~= nil -- inferred equivalent call
end

local function StopUpdateConnection() -- 2 equivalent calls inferred from this helper
	if connection then
		connection:Disconnect()
		connection = nil
	end
end

local function CancelMobileDefuseIfNeeded() -- 2 equivalent calls inferred from this helper
	if not (v and flag) then
		return
	end

	local bombResolved = IsBombResolved(CollectionService:GetTagged("Bomb")[1]) -- inferred equivalent call
	flag = false
	v2 = nil

	if not bombResolved then
		Router.broadcastRouter("Cancel Defuse Bomb")
	end
end

local function SyncUpdateConnection() -- 1 equivalent call inferred from this helper
	if ShouldRunUpdate() then -- inferred equivalent call
		if connection then
			return
		end

		connection = RunServiceController.BindToHeartbeat("UI.HoverBomb.Update", function(_)
			if ShouldRunUpdate() then -- inferred equivalent call
				if IsCharacterAlive(LocalPlayer) then -- inferred equivalent call
					local hoverState = HoverBomb.GetHoverState()
					v3.Visible = hoverState

					if hoverState then
						LayoutKeybind()
					end

					if v and flag and not hoverState and v then
						if not flag then
							return
						end

						local bombResolved = IsBombResolved(CollectionService:GetTagged("Bomb")[1]) -- inferred equivalent call
						flag = false
						v2 = nil

						if not bombResolved then
							Router.broadcastRouter("Cancel Defuse Bomb")
						end
					end
				else
					v3.Visible = false

					if v and flag then
						flag = false
						v2 = nil
					end
				end
			else
				v3.Visible = false
				CancelMobileDefuseIfNeeded() -- inferred equivalent call
				StopUpdateConnection() -- inferred equivalent call
			end
		end)
	else
		v3.Visible = false
		CancelMobileDefuseIfNeeded() -- inferred equivalent call
		StopUpdateConnection() -- inferred equivalent call
	end
end

function HoverBomb.IsDefuseAllowed()
	return not IsTutorialMode() or LocalPlayer:GetAttribute("TutorialStep") == "DefuseB"
end

function HoverBomb.IsInDefuseRange()
	if LocalPlayer:GetAttribute("Team") ~= "Counter-Terrorists" then
		return false
	end

	local model = GetActiveBomb() -- inferred equivalent call
	local character = LocalPlayer.Character
	local primaryPart = character and character.PrimaryPart
	local primaryPart2 = model and model:IsA("Model") and model.PrimaryPart

	if primaryPart and primaryPart2 then
		return (primaryPart.Position - primaryPart2.Position).Magnitude <= 5
	end

	return false
end

function HoverBomb.GetHoverState()
	if LocalPlayer:GetAttribute("Team") ~= "Counter-Terrorists" or not HoverBomb.IsDefuseAllowed() then
		return false
	end

	local activeBomb = GetActiveBomb() -- inferred equivalent call

	if not activeBomb then
		return false
	end

	if
		v and (flag or LocalPlayer:GetAttribute("IsDefusingBomb") == true)
		or activeBomb:GetAttribute("CanDefuse") and not activeBomb:GetAttribute("IsGettingDefused")
	then
		return true
	end

	return false
end

function HoverBomb.Initialize(_, p)
	v3 = p
	RefreshPrompt() -- inferred equivalent call
	DataController.CreateListener(LocalPlayer, "Settings.Keyboard/Mouse", function(p2)
		if not p2 then
			return
		end

		task.defer(RefreshPrompt)
	end)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(RefreshPrompt)
	LocalPlayer:GetAttributeChangedSignal("Dead"):Connect(function()
		if LocalPlayer:GetAttribute("Dead") then
			v3.Visible = false
		end
	end)
	LocalPlayer.CharacterRemoving:Connect(function()
		v3.Visible = false
	end)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(SyncUpdateConnection)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(SyncUpdateConnection)
	LocalPlayer.CharacterAdded:Connect(SyncUpdateConnection)
	LocalPlayer.CharacterRemoving:Connect(SyncUpdateConnection)
	CollectionService:GetInstanceAddedSignal("Bomb"):Connect(SyncUpdateConnection)
	CollectionService:GetInstanceRemovedSignal("Bomb"):Connect(SyncUpdateConnection)
	SyncUpdateConnection() -- inferred equivalent call

	if v then
		UserInputService.TouchStarted:Connect(function(p2, flag2: boolean)
			if flag2 then
				return
			end

			if HoverBomb.GetHoverState() and IsCharacterAlive(LocalPlayer) and not flag then -- inferred equivalent call
				v2 = p2
				flag = true
				Router.broadcastRouter("Start Defuse Bomb")
			end
		end)
		UserInputService.TouchEnded:Connect(function(otherPart, _: boolean)
			if otherPart == v2 then
				v2 = nil

				if flag then
					flag = false
					Router.broadcastRouter("Cancel Defuse Bomb")
				end
			end
		end)
	end
end

return HoverBomb