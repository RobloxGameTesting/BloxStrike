local Missions = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local modulesByMissionId = {}
local modules = {}

function Missions.GetMissionDefinition(p: string)
	return modulesByMissionId[p]
end

function Missions.GetMissionCategory(p: string)
	local v = modulesByMissionId[p]
	return v and v.Category or nil
end

function Missions.GetMissionDisplayName(displayName: string)
	local v = modulesByMissionId[displayName]

	if v then
		displayName = v.DisplayName or displayName
	end

	return displayName
end

function Missions.GetMissionDefinitions()
	return table.clone(modules)
end

function Missions.IsMissionAvailableForGamemode(p, p2, flag: boolean?)
	if not p.Gamemodes then
		return true
	end

	if p2 then
		return table.find(p.Gamemodes, p2) ~= nil
	end

	return flag == true
end

for _, moduleScript in ipairs(script:GetDescendants()) do
	if not moduleScript:IsA("ModuleScript") then
		continue
	end

	local module = require(moduleScript)

	if not (module and module.MissionId) then
		continue
	end

	modulesByMissionId[module.MissionId] = module
	table.insert(modules, module)
end

return Missions