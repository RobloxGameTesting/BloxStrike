local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local DataController = require(ReplicatedStorage.Controllers.DataController)
local Maps = ReplicatedStorage.Database.Custom.GameStats.Maps
local v = {
	"Ambient",
	"Brightness",
	"ColorShift_Bottom",
	"ColorShift_Top",
	"EnvironmentDiffuseScale",
	"EnvironmentSpecularScale",
	"GlobalShadows",
	"OutdoorAmbient",
	"ShadowSoftness",
	"ClockTime",
	"GeographicLatitude",
	"ExposureCompensation"
}
local v2 = {}
local SceneLighting = {}

for _, v3 in v do
	v2[v3] = Lighting[v3]
end

local function replaceAssets(instance)
	for _, child in Lighting:GetChildren() do
		if child.Name ~= "Menu" then
			child:Destroy()
		end
	end

	if instance then
		for _, child in instance:GetChildren() do
			local clone = child:Clone()
			clone.Parent = Lighting
		end
	end
end

function SceneLighting.ApplyGlobalShadows(globalShadows: boolean?)
	if DataController.Get(Players.LocalPlayer, "Settings.Video.Presets.Global Shadows") == false then
		Lighting.GlobalShadows = false
	elseif globalShadows ~= nil then
		Lighting.GlobalShadows = globalShadows
	end
end

function SceneLighting.RestoreMap(map: string?, globalShadows: boolean?)
	if map == nil then
		map = workspace:GetAttribute("Map")

		if typeof(map) ~= "string" then
			local map2 = workspace:FindFirstChild("Map")

			if map2 then
				map = map2:GetAttribute("MapName")
			else
				map = nil
			end
		end
	end

	if typeof(map) ~= "string" then
		return globalShadows
	end

	local moduleScript = Maps:FindFirstChild(map)

	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return globalShadows
	end

	local module = require(moduleScript)
	local lighting = module.Lighting

	if not lighting then
		return globalShadows
	end

	local properties = lighting.Properties

	if properties then
		globalShadows = properties.GlobalShadows

		for _, v3 in v do
			Lighting[v3] = properties[v3]
		end
	end

	replaceAssets(lighting.Assets)
	SceneLighting.ApplyGlobalShadows(globalShadows)
	return globalShadows
end

function SceneLighting.ApplyScene(childName: string, p)
	local moduleScript = Maps:FindFirstChild(childName)
	local lighting

	if moduleScript and moduleScript:IsA("ModuleScript") then
		local module = require(moduleScript)
		lighting = module.Lighting
	end

	local properties

	if lighting and lighting.Properties then
		properties = lighting.Properties
	else
		properties = v2
	end

	for _, v3 in v do
		Lighting[v3] = properties[v3]
	end

	replaceAssets(p)
	SceneLighting.ApplyGlobalShadows(properties.GlobalShadows)
	return properties.GlobalShadows
end

return SceneLighting