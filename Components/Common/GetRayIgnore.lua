local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrentCamera = workspace.CurrentCamera
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local Debris = workspace:WaitForChild("Debris")
local v = { "Cameras", "Barriers", "Ambience" }
local v2 = { "Spawns", "Sites" }

local function addChildren(children, instance, items) -- 2 equivalent calls inferred from this helper
	for _, childName in items do
		local child = instance:FindFirstChild(childName)

		if child then
			table.insert(children, child)
		end
	end
end

return function()
	local localCharacters = { Debris, CurrentCamera }
	local map = workspace:FindFirstChild("Map")

	if map then
		addChildren(localCharacters, map, v) -- inferred equivalent call
		local zones = map:FindFirstChild("Zones")

		if zones then
			addChildren(localCharacters, zones, v2) -- inferred equivalent call
		end
	end

	local localCharacter = CharacterResolver.getLocalCharacter()

	if localCharacter and localCharacter:IsDescendantOf(workspace) then
		table.insert(localCharacters, localCharacter)
	end

	return localCharacters
end