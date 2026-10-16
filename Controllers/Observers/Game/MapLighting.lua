local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SceneLighting = require(ReplicatedStorage.Components.Common.SceneLighting)
local Players = game:GetService("Players")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local LocalPlayer = Players.LocalPlayer
local v = nil
local v2 = nil
local v3 = nil
local v4 = nil
local v5 = nil

local function applyMapLighting(p: string) -- 3 equivalent calls inferred from this helper
	v5 = SceneLighting.RestoreMap(p, v5)
end

local function getMapNameFromInstance(instance) -- 2 equivalent calls inferred from this helper
	local mapName = instance:GetAttribute("MapName")

	if typeof(mapName) == "string" then
		return mapName
	end

	return nil
end

local function shouldApplyMapLighting()
	v = v or require(ReplicatedStorage.Controllers.MenuSceneController)
	v2 = v2 or require(ReplicatedStorage.Controllers.CaseSceneController)
	v4 = v4 or require(ReplicatedStorage.Controllers.InspectController)
	v3 = v3 or require(ReplicatedStorage.Controllers.BlackMarketSceneController)
	return not (v.IsActive() or v.IsTeamSelectSceneActive() or v2.IsActive() or v3.IsActive() or v4.IsActive())
end

local function handleMapLoaded(object)
	if not shouldApplyMapLighting() then
		return
	end

	local mapNameFromInstance = getMapNameFromInstance(object) -- inferred equivalent call

	if mapNameFromInstance then
		applyMapLighting(mapNameFromInstance) -- inferred equivalent call
		return
	end

	local mapNameChangedConnection = nil
	mapNameChangedConnection = object:GetAttributeChangedSignal("MapName"):Connect(function()
		if not shouldApplyMapLighting() then
			mapNameChangedConnection:Disconnect()
			return
		end

		local mapNameFromInstance2 = getMapNameFromInstance(object) -- inferred equivalent call

		if mapNameFromInstance2 then
			mapNameChangedConnection:Disconnect()
			applyMapLighting(mapNameFromInstance2) -- inferred equivalent call
		end
	end)
end

local function handleMapAttributeChanged()
	if not shouldApplyMapLighting() then
		return
	end

	local map = workspace:GetAttribute("Map")

	if typeof(map) == "string" and map ~= "" then
		applyMapLighting(map) -- inferred equivalent call
	end
end

DataController.CreateListener(LocalPlayer, "Settings.Video.Presets.Global Shadows", function()
	SceneLighting.ApplyGlobalShadows(v5)
end)
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Map" then
		task.defer(handleMapLoaded, child)
	end
end)
workspace:GetAttributeChangedSignal("Map"):Connect(function()
	task.defer(handleMapAttributeChanged)
end)
local Map = workspace:FindFirstChild("Map")

if Map then
	task.defer(handleMapLoaded, Map)
end

task.defer(handleMapAttributeChanged)
return nil