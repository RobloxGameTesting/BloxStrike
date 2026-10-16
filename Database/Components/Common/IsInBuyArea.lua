local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage.Database.Custom.Types)
local CharacterResolver = require(ReplicatedStorage.Components.Common.CharacterResolver)
local TutorialPurchaseLock = require(ReplicatedStorage.Components.Common.TutorialPurchaseLock)
local tagged = CollectionService:GetTagged("BuyArea")
CollectionService:GetInstanceAddedSignal("BuyArea"):Connect(function(p)
	table.insert(tagged, p)
end)
CollectionService:GetInstanceRemovedSignal("BuyArea"):Connect(function(p)
	local index = table.find(tagged, p)

	if index then
		table.remove(tagged, index)
	end
end)

local function IsInZone(vector: Vector3, instance) -- 1 equivalent call inferred from this helper
	local size = instance.Size
	local pointToObjectSpace = instance.CFrame:PointToObjectSpace(vector)
	return math.abs(pointToObjectSpace.X) <= size.X / 2
		and math.abs(pointToObjectSpace.Y) <= size.Y / 2
		and math.abs(pointToObjectSpace.Z) <= size.Z / 2
end

local function IsInTeamBuyArea(vector: Vector3, team)
	for _, v in ipairs(tagged) do
		if v:GetAttribute("Team") == team and v:IsDescendantOf(workspace) and IsInZone(vector, v) then -- inferred equivalent call
			return true
		end
	end

	return false
end

return function(player, callback)
	if not (workspace:GetAttribute("Gamemode") ~= "Deathmatch" and TutorialPurchaseLock.getRequiredItems(player) == nil) then
		return true
	end

	local team = player:GetAttribute("Team")

	if player:IsA("Player") then
		local character = player.Character

		if not (character and character:IsDescendantOf(workspace)) then
			return false
		end

		local position

		if callback then
			position = callback(player)
		end

		if position then
			return (IsInTeamBuyArea(position, team))
		end

		local primaryPart = character.PrimaryPart or CharacterResolver.getRootPart(character)

		if not primaryPart then
			return false
		end

		position = primaryPart.Position
		return (IsInTeamBuyArea(position, team))
	else
		local v

		if callback then
			v = callback(player)
		end

		return v ~= nil and IsInTeamBuyArea(v, team)
	end
end