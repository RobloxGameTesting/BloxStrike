local Spectate = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
require(script:WaitForChild("Types"))
local LocalPlayer = Players.LocalPlayer
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local GetSkinDisplayName = require(ReplicatedStorage.Components.Common.GetSkinDisplayName)
local GetBadgeIcon = require(ReplicatedStorage.Components.Common.GetBadgeIcon)
local GetUserPlatform = require(ReplicatedStorage.Components.Common.GetUserPlatform)
local IsPlayingTeam = require(ReplicatedStorage.Components.Common.IsPlayingTeam)
local Participants = require(ReplicatedStorage.Components.Common.Participants)
local Tips = require(ReplicatedStorage.Interface.Screens.Gameplay.Middle.Tips)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local Colors = require(ReplicatedStorage.Database.Custom.GameStats.Settings.Colors)
local v = { Menu = "Main Menu", TeamSelect = "Choose Team" }
local v2 = nil
local v3 = nil
local v4 = table.find(GetUserPlatform(), "Mobile") ~= nil
local v5 = true
local maid = Janitor.new()

local function updateADRDisplay(instance, p: number?)
	local team = instance:GetAttribute("Team")

	if not team then
		return
	end

	if p == nil and Participants.IsBot(instance) and instance:GetAttribute("ADR") == nil then
		v2.ADR.Text = ""
		return
	end

	local v6 = Colors["Team Color"][team]
	local v7 = math.floor((p or instance:GetAttribute("ADR") or 0) * 10) / 10
	local v8 = math.floor(v6.R * 255)
	local v9 = math.floor(v6.G * 255)
	local v10 = math.floor(v6.B * 255)
	v2.ADR.Text = `<font color="rgb({v8}, {v9}, {v10})">ADR:</font> {v7}`
end

local function isRoundBasedGamemode()
	local gamemode = workspace:GetAttribute("Gamemode")
	return gamemode ~= nil and gamemode ~= "Deathmatch"
end

local function updateRespawnNextVisibility() -- 1 equivalent call inferred from this helper
	if not v2 then
		return
	end

	local team = LocalPlayer:GetAttribute("Team")
	local respawnNext = v2.RespawnNext
	local visible = IsPlayingTeam(team)

	if visible then
		local gamemode = workspace:GetAttribute("Gamemode")

		if gamemode == nil then
			visible = false
		else
			visible = gamemode ~= "Deathmatch"
		end
	end

	respawnNext.Visible = visible
end

local function updateSpectateTips()
	if not v2 then
		return
	end

	local tips = v2:FindFirstChild("Tips")

	if not (tips and tips:IsA("GuiObject")) then
		return
	end

	local visible = v5 and not v4
	tips.Visible = visible
	local respawnNext = v2.RespawnNext

	if visible then
		for childName, v6 in pairs(v) do
			local guiObject = tips:FindFirstChild(childName)

			if not (guiObject and guiObject:IsA("GuiObject")) then
				continue
			end

			local keybind = guiObject:FindFirstChild("Keybind")
			local visible2

			if keybind and keybind:IsA("GuiButton") then
				visible2 = Tips.ApplyBindingToKeybind(keybind, Tips.ResolveActionBinding(v6))
			else
				visible2 = false
			end

			guiObject.Visible = visible2
		end
	end

	local v6 = not visible and -0.2 or tips.Position.Y.Scale - respawnNext.Size.Y.Scale / 2
	respawnNext.Position = UDim2.new(respawnNext.Position.X.Scale, respawnNext.Position.X.Offset, v6, 0)
end

function Spectate.UpdateFrame(instance)
	local currentSpectateInstance = SpectateController.GetCurrentSpectateInstance()
	v2.Player.Player.Avatar.Image = Participants.HeadshotImage(instance)
	v2.Username.Text = Participants.Name(instance)
	local team = instance:GetAttribute("Team")

	if team then
		local v6 = Colors["Team Color"][team]
		v2.Username.TextColor3 = v6
		v2.Badge.Image = GetBadgeIcon(instance, team)
		v2.Frame1.BackgroundColor3 = v6
		v2.Frame2.BackgroundColor3 = v6
		v2.Player.Outline.ImageColor3 = v6
	end

	maid:Cleanup()
	maid:Add(Observers.observeAttribute(instance, "ADR", function(value)
		if typeof(value) == "number" then
			updateADRDisplay(instance, value)
		end
	end))
	updateADRDisplay(instance)

	if not currentSpectateInstance then
		return
	end

	if currentSpectateInstance.CurrentEquipped then
		local currentEquipped = currentSpectateInstance.CurrentEquipped
		v2.Skin.Text = GetSkinDisplayName(currentEquipped.Skin)
		GetSkinDisplayName.ApplyNameLabel(
			v2.Weapon,
			GetSkinDisplayName.GetWeaponDisplayName(currentEquipped.Name, currentEquipped.NameTag),
			currentEquipped.NameTag
		)
	end

	maid:Add(currentSpectateInstance.CurrentEquippedChanged:Connect(function(data)
		if data then
			v2.Skin.Text = GetSkinDisplayName(data.Skin or "")
			GetSkinDisplayName.ApplyNameLabel(
				v2.Weapon,
				GetSkinDisplayName.GetWeaponDisplayName(data.Name, data.NameTag),
				data.NameTag
			)
		end
	end))
end

function Spectate.OpenFrame()
	v3.Gameplay.Bottom.Middle.Team.Visible = false
	v2.Visible = true
	updateRespawnNextVisibility() -- inferred equivalent call
	updateSpectateTips()
end

function Spectate.CloseFrame()
	v2.Visible = false
	maid:Cleanup()
	local character = LocalPlayer.Character
	local team = LocalPlayer:GetAttribute("Team")

	if character and character:IsDescendantOf(Workspace) and team and team ~= "Spectators" then
		local Team = require(ReplicatedStorage.Interface.Screens.Gameplay.Bottom.Middle.Team)
		Team.OpenFrame()
	end
end

function Spectate.Initialize(p, p2)
	v3 = p
	v2 = p2
end

function Spectate.Start()
	SpectateController.ListenToSpectate:Connect(function(p)
		if not p then
			Spectate.CloseFrame()
			return
		end

		Spectate.UpdateFrame(p)
		Spectate.OpenFrame()
	end)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(updateRespawnNextVisibility)
	workspace:GetAttributeChangedSignal("Gamemode"):Connect(updateRespawnNextVisibility)
	DataController.CreateListener(
		LocalPlayer,
		"Settings.Game.HUD.Enable Game Instructor Messages",
		function(flag: boolean?)
			v5 = flag ~= false
			updateSpectateTips()
		end
	)
	DataController.CreateListener(LocalPlayer, "Settings.Keyboard/Mouse", updateSpectateTips)
	UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(updateSpectateTips)
end

return Spectate