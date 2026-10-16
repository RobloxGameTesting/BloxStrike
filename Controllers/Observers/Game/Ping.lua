local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local LocalPlayer = Players.LocalPlayer
local SpectateController = require(ReplicatedStorage.Controllers.SpectateController)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Skins = require(ReplicatedStorage.Database.Components.Libraries.Skins)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Colors = require(ReplicatedStorage.Database.Custom.GameStats.Settings.Colors)
local Rarities = require(ReplicatedStorage.Database.Custom.GameStats.Rarities)
local v = {}

local function GetWeaponProperties(childName: string)
	local moduleScript = ReplicatedStorage.Database.Custom.Weapons:FindFirstChild(childName)

	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return nil
	end

	local success, result = pcall(require, moduleScript)

	if success and result then
		return result
	end

	return nil
end

local function UpdateVisibility(data, p)
	local v2 = p or LocalPlayer:GetAttribute("Team")

	if DataController.Get(LocalPlayer, "Settings.Game.HUD.Player Pings") == "Disabled" or v2 ~= data.CurrentTeam then
		data.Model.Parent = nil
	elseif data.Model.Parent == nil and data.OriginalParent then
		data.Model.Parent = data.OriginalParent
	end
end

local function UpdateAllMarkers(p) -- 3 equivalent calls inferred from this helper
	for _, v2 in pairs(v) do
		UpdateVisibility(v2, p)
	end
end

local function GetSpectatedTeam() -- 2 equivalent calls inferred from this helper
	local player = SpectateController.GetPlayer()

	if player and player ~= LocalPlayer then
		return (player:GetAttribute("Team"))
	end

	return nil
end

local function RefreshAllMarkers()
	UpdateAllMarkers(GetSpectatedTeam()) -- inferred equivalent call
end

local function StyleBillboard(data)
	local imageColor = Colors["Team Color"][data.CurrentTeam]
	data.Model.Name = data.Identifier

	if not imageColor then
		return
	end

	local billboardGui = data.Model:FindFirstChildOfClass("BillboardGui")

	if not (billboardGui and billboardGui:IsDescendantOf(workspace)) then
		return
	end

	local isDanger = data.IsDanger
	local visible

	if typeof(data.Weapon) == "string" and data.Weapon ~= "" and typeof(data.Skin) == "string" then
		visible = data.Skin ~= ""
	else
		visible = false
	end

	billboardGui.Info.Visible = not (isDanger or visible)
	billboardGui.Danger.Visible = isDanger and not visible
	billboardGui.Weapon.Visible = visible

	if billboardGui.Info.Visible then
		billboardGui.Info.ImageColor3 = imageColor
		return
	end

	if not visible then
		return
	end

	local weapon = data.Weapon
	local skinInformation = Skins.GetSkinInformation(weapon, data.Skin)
	local moduleScript = ReplicatedStorage.Database.Custom.Weapons:FindFirstChild(weapon)
	local v2

	if moduleScript and moduleScript:IsA("ModuleScript") then
		local success, result = pcall(require, moduleScript)
		v2 = success and result or nil
	end

	local v3 = skinInformation and Rarities[skinInformation.rarity]

	if skinInformation and v2 and v3 then
		billboardGui.Weapon.Icon.ImageColor3 = v3.Color
		billboardGui.Weapon.Icon.Image = v2.Icon
	else
		billboardGui.Weapon.Visible = false
		billboardGui.Info.Visible = not isDanger
		billboardGui.Danger.Visible = isDanger

		if billboardGui.Info.Visible then
			billboardGui.Info.ImageColor3 = imageColor
		end
	end
end

local function CreatePositionPing(instance, identifier: string)
	local v2 = {
		Weapon = instance:GetAttribute("Weapon"),
		Skin = instance:GetAttribute("Skin"),
		Identifier = identifier,
		CurrentTeam = instance:GetAttribute("Team"),
		IsDanger = instance:GetAttribute("IsDanger"),
		OriginalParent = instance.Parent,
		Model = instance
	}
	UpdateVisibility(v2, GetSpectatedTeam()) -- inferred equivalent call
	task.delay(1 / 60, StyleBillboard, v2)
	v[identifier] = v2
	return function()
		v[identifier] = nil
	end
end

LocalPlayer.CharacterAdded:Connect(function()
	UpdateAllMarkers(nil) -- inferred equivalent call
end)
LocalPlayer:GetAttributeChangedSignal("Team"):Connect(RefreshAllMarkers)
DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Player Pings", RefreshAllMarkers)
SpectateController.ListenToSpectate:Connect(function(instance)
	UpdateAllMarkers(instance and instance:GetAttribute("Team")) -- inferred equivalent call
end)
return Observers.observeTag("PlayerPositionMarker", function(instance)
	if instance:IsDescendantOf(workspace) then
		return (CreatePositionPing(instance, HttpService:GenerateGUID(false)))
	end

	return nil
end)