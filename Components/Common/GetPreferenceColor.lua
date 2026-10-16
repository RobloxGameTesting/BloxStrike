local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
require(ReplicatedStorage.Database.Custom.Types)
local LocalPlayer = Players.LocalPlayer
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Colors = require(ReplicatedStorage.Database.Custom.GameStats.Settings.Colors)
local counterTerrorists = Colors["Team Color"]["Counter-Terrorists"]
return function()
	local v = DataController.Get(LocalPlayer, "Settings.Game.HUD.Color")
	local team = LocalPlayer:GetAttribute("Team")
	return Colors[v] and Colors[v][team] or counterTerrorists
end