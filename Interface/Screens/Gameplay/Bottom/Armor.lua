local Armor = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local HudTarget = require(ReplicatedStorage.Interface.Screens.Gameplay.Bottom.Ammo.HudTarget)
local LocalPlayer = Players.LocalPlayer
local GetPreferenceColor = require(ReplicatedStorage.Components.Common.GetPreferenceColor)
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Observers = require(ReplicatedStorage.Packages.Observers)
local Janitor = require(ReplicatedStorage.Shared.Janitor)
local v = nil
local maid = Janitor.new()

local function ParseArmorAttribute(json)
	if typeof(json) ~= "string" or json == "" then
		return nil
	end

	local success, result = pcall(function()
		return HttpService:JSONDecode(json)
	end)

	if success and typeof(result) == "table" then
		return {
			Type = tostring(result.Type or ""),
			Health = tonumber(result.Health) or 0
		}
	end

	return nil
end

local function UpdateArmorUIFromAttribute(armor) -- 1 equivalent call inferred from this helper
	local parseArmorAttribute = ParseArmorAttribute(armor)
	local visible

	if parseArmorAttribute == nil then
		visible = false
	else
		visible = parseArmorAttribute.Health > 0
	end

	v.Visible = visible

	if visible and parseArmorAttribute then
		Armor.updateFrame(parseArmorAttribute)
	end
end

function Armor.updateFrame(p)
	local v2 = GetPreferenceColor()
	v.Helmet.Visible = p.Type == "Kevlar + Helmet"
	v.Amount.Text = tostring((math.round(p.Health)))
	v.Helmet.ImageColor3 = v2
	v.Amount.TextColor3 = v2
	v.Armor.ImageColor3 = v2
end

local function updateArmorFromPlayer(instance)
	maid:Cleanup()
	maid:Add(Observers.observeAttribute(instance, "Armor", UpdateArmorUIFromAttribute))
	UpdateArmorUIFromAttribute(instance:GetAttribute("Armor")) -- inferred equivalent call
end

function Armor.Initialize(_, p)
	v = p
	HudTarget.DisableInput(v)

	local function refreshPreferenceColor()
		local parseArmorAttribute = ParseArmorAttribute(LocalPlayer:GetAttribute("Armor"))

		if parseArmorAttribute and parseArmorAttribute.Health > 0 then
			Armor.updateFrame(parseArmorAttribute)
		end
	end

	DataController.CreateListener(LocalPlayer, "Settings.Game.HUD.Color", refreshPreferenceColor)
	LocalPlayer:GetAttributeChangedSignal("Team"):Connect(refreshPreferenceColor)
end

function Armor.Start()
	HudTarget.Follow(updateArmorFromPlayer)
end

return Armor